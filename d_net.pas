//------------------------------------------------------------------------------
//
//  DoomXS - A basic Windows source port of Doom
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2021 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/doomxs/
//------------------------------------------------------------------------------

unit d_net;

interface

uses
  d_delphi,
  doomdef,
  d_player,
  d_ticcmd;


// Network play related stuff.
// There is a data struct that stores network
//  communication related stuff, and another
//  one that defines the actual packets to
//  be transmitted.


const
  DOOMCOM_ID = $12345678;

  // Max computers/players in a game.
  MAXNETNODES = 8;

  // Networking and tick handling related.
  BACKUPTICS = 12;

  CMD_SEND = 1;
  CMD_GET = 2;

type
  Tcmds = packed array[0..(BACKUPTICS) - 1] of ticcmd_t;

  // Network packet data.

  doomdata_t = record
    // High bit is retransmit request.
    checksum: LongWord;
    // Only valid if NCMD_RETRANSMIT.
    retransmitfrom: byte;

    starttic: byte;
    player: byte;
    numtics: byte;
    cmds: Tcmds;
  end;
  Pdoomdata_t = ^doomdata_t;

  doomcom_t = record
    // Supposed to be DOOMCOM_ID?
    id: integer;

    // DOOM executes an int to execute commands.
    intnum: smallint;

    // Communication between DOOM and the driver.
    // Is CMD_SEND or CMD_GET.
    command: smallint;
    // Is dest for send, set by get (-1 = no packet).
    remotenode: smallint;

    // Number of bytes in doomdata to be sent
    datalength: smallint;

    // Info common to all nodes.
    // Console is allways node 0.
    numnodes: smallint;
    // Flag: 1 = no duplication, 2-5 = dup for slow nets.
    ticdup: smallint;
    // Flag: 1 = send a backup tic in every packet.
    extratics: smallint;
    // Flag: 1 = deathmatch.
    deathmatch: smallint;
    // Flag: -1 = new game, 0-5 = load savegame
    savegame: smallint;
    episode: smallint; // 1-3
    map: smallint; // 1-9
    skill: smallint; // 1-5

    // Info specific to this node.
    consoleplayer: smallint;
    numplayers: smallint;

    // These are related to the 3-display mode,
    //  in which two drones looking left and right
    //  were used to render two additional views
    //  on two additional computers.
    // Probably not operational anymore.
    // 1 = left, 0 = center, -1 = right
    angleoffset: smallint;

    // 1 = drone
    drone: smallint;
    // The packet data to be sent.
    Data: doomdata_t;
  end;
  Pdoomcom_t = ^doomcom_t;

{ Create any new ticcmds and broadcast to other players. }
procedure NetUpdate;

{ Broadcasts special packets to other players }
{  to notify of game exit }
procedure D_QuitNetGame;

{? how many ticks to run? }
procedure TryRunTics;

procedure CheckAbort;

procedure D_CheckNetGame;

var
  netcmds: array[0..MAXPLAYERS - 1] of array[0..(BACKUPTICS) - 1] of ticcmd_t;

  maketic: integer;

  doomcom: Pdoomcom_t;
  ticdup: integer;

implementation

uses
  m_menu,
  i_system,
  i_net,
  i_io,
  d_main,
  d_event,
  g_game,
  doomstat;

const
  NCMD_EXIT = $80000000;
  NCMD_RETRANSMIT = $40000000;
  NCMD_SETUP = $20000000;
  NCMD_KILL = $10000000;  // kill game
  NCMD_CHECKSUM = $0fffffff;

var
  netbuffer: Pdoomdata_t; // points inside doomcom


// NETWORKING

// gametic is the tic about to (or currently being) run
// maketic is the tick that hasn't had control made for it yet
// nettics[] has the maketics for all players

// a gametic cannot be run until nettics[] > gametic for all players

const
  CRESENDCOUNT = 10;
  PL_DRONE = $80; // bit flag in doomdata->player

var
  localcmds: array[0..(BACKUPTICS) - 1] of ticcmd_t;

  nettics: array[0..(MAXNETNODES) - 1] of integer;
  nodeingame: array[0..(MAXNETNODES) - 1] of boolean; // set false as nodes leave game
  remoteresend: array[0..(MAXNETNODES) - 1] of boolean; // set when local needs tics
  resendto: array[0..(MAXNETNODES) - 1] of integer; // set when remote needs tics
  resendcount: array[0..(MAXNETNODES) - 1] of integer;

  nodeforplayer: array[0..(MAXPLAYERS) - 1] of integer;

  skiptics: integer;
  maxsend: integer; // BACKUPTICS/(2*ticdup)-1

var
  reboundpacket: boolean;
  reboundstore: doomdata_t;


function NetbufferSize: integer;
begin
  Result := SizeOf(doomdata_t) - SizeOf(Tcmds) + netbuffer.numtics * SizeOf(ticcmd_t);
end;

// Checksum
function NetbufferChecksum: LongWord;
var
  i: integer;
  p: PLongWordArray;
begin
  Result := $1234567;

  p := PLongWordArray(pointer(netbuffer));

  // Hack: first position of doomdata_t is checksum (LongWord)
  for i := 1 to NetbufferSize div 4 do
    Result := Result + p[i];

  Result := Result and NCMD_CHECKSUM;
end;

function ExpandTics(low: integer): integer;
var
  delta: integer;
begin
  delta := low - (maketic and $ff);

  if (delta >= -64) and (delta <= 64) then
  begin
    Result := (maketic and not $ff) + low;
    exit;
  end;

  if delta > 64 then
  begin
    Result := (maketic and not $ff) - 256 + low;
    exit;
  end;

  if delta < -64 then
  begin
    Result := (maketic and not $ff) + 256 + low;
    exit;
  end;

  I_Error('ExpandTics(): strange value %d at maketic %d', [low, maketic]);
  Result := 0;
end;

// HSendPacket
procedure HSendPacket(node: integer; flags: LongWord);
var
  i: integer;
  realretrans: integer;
  p: PByteArray;
begin
  netbuffer.checksum := NetbufferChecksum or flags;

  if node = 0 then
  begin
    reboundstore := netbuffer^;
    reboundpacket := True;
    exit;
  end;

  if demoplayback then
    exit;

  if not netgame then
    I_Error('HSendPacket(): Tried to transmit to another node');

  doomcom.command := CMD_SEND;
  doomcom.remotenode := node;
  doomcom.datalength := NetbufferSize;

  if debugfile <> nil then
  begin
    if (netbuffer.checksum and NCMD_RETRANSMIT) <> 0 then
      realretrans := ExpandTics(netbuffer.retransmitfrom)
    else
      realretrans := -1;

    fprintf(debugfile, 'send (%d + %d, R %d) [%d] ',
      [ExpandTics(netbuffer.starttic), netbuffer.numtics, realretrans,
      doomcom.datalength]);

    p := PByteArray(pointer(netbuffer));
    for i := 0 to doomcom.datalength - 1 do
      fprintf(debugfile, '%d ', [p[i]]);

    fprintf(debugfile, #13#10);
  end;

  I_NetCmd;
end;

// HGetPacket
// Returns false if no packet is waiting
function HGetPacket: boolean;
var
  realretrans: integer;
  i: integer;
  p: PByteArray;
begin
  if reboundpacket then
  begin
    netbuffer^ := reboundstore;
    doomcom.remotenode := 0;
    reboundpacket := False;
    Result := True;
    exit;
  end;

  if not netgame then
  begin
    Result := False;
    exit;
  end;

  if demoplayback then
  begin
    Result := False;
    exit;
  end;

  doomcom.command := CMD_GET;
  I_NetCmd;

  if doomcom.remotenode = -1 then
  begin
    Result := False;
    exit;
  end;

  if doomcom.datalength <> NetbufferSize then
  begin
    fprintf(debugfile, 'bad packet length %d' + #13#10, [doomcom.datalength]);
    Result := False;
    exit;
  end;

  if NetbufferChecksum <> (netbuffer.checksum and NCMD_CHECKSUM) then
  begin
    fprintf(debugfile, 'bad packet checksum' + #13#10);
    Result := False;
    exit;
  end;

  if debugfile <> nil then
  begin
    if (netbuffer.checksum and NCMD_SETUP) <> 0 then
      fprintf(debugfile, 'setup packet' + #13#10)
    else
    begin
      if (netbuffer.checksum and NCMD_RETRANSMIT) <> 0 then
        realretrans := ExpandTics(netbuffer.retransmitfrom)
      else
        realretrans := -1;

      fprintf(debugfile, 'get %d = (%d + %d, R %d)[%d] ',
        [doomcom.remotenode, ExpandTics(netbuffer.starttic),
        netbuffer.numtics, realretrans, doomcom.datalength]);

      p := PByteArray(pointer(netbuffer));
      for i := 0 to doomcom.datalength - 1 do
        fprintf(debugfile, '%d ', [p[i]]);
      fprintf(debugfile, #13#10);
    end;
  end;
  Result := True;
end;


// GetPackets

var
  exitmsg: string;

procedure GetPackets;
var
  netconsole: integer;
  netnode: integer;
  src, dest: Pticcmd_t;
  realend: integer;
  realstart: integer;
  start: integer;
begin
  while HGetPacket do
  begin
    if (netbuffer.checksum and NCMD_SETUP) <> 0 then
      continue;    // extra setup packet

    netconsole := netbuffer.player and not PL_DRONE;
    netnode := doomcom.remotenode;

    // to save bytes, only the low byte of tic numbers are sent
    // Figure out what the rest of the bytes are
    realstart := ExpandTics(netbuffer.starttic);
    realend := realstart + netbuffer.numtics;

    // check for exiting the game
    if (netbuffer.checksum and NCMD_EXIT) <> 0 then
    begin
      if not nodeingame[netnode] then
        continue;
      nodeingame[netnode] := False;
      playeringame[netconsole] := False;
      exitmsg := 'Player 1 left the game';
      exitmsg[7] := chr(Ord(exitmsg[7]) + netconsole);
      players[consoleplayer]._message := exitmsg;
      if demorecording then
        G_CheckDemoStatus;
      continue;
    end;

    // check for a remote game kill
    if (netbuffer.checksum and NCMD_KILL) <> 0 then
      I_Error('GetPackets(): Killed by network driver');

    nodeforplayer[netconsole] := netnode;

    // check for retransmit request
    if (resendcount[netnode] <= 0) and
      ((netbuffer.checksum and NCMD_RETRANSMIT) <> 0) then
    begin
      resendto[netnode] := ExpandTics(netbuffer.retransmitfrom);
      if debugfile <> nil then
        fprintf(debugfile, 'retransmit from %d' + #13#10, [resendto[netnode]]);
      resendcount[netnode] := CRESENDCOUNT;
    end
    else
      resendcount[netnode] := resendcount[netnode] - 1;

    // check for out of order / duplicated packet
    if realend = nettics[netnode] then
      continue;

    if realend < nettics[netnode] then
    begin
      fprintf(debugfile, 'out of order packet (%d + %d)' + #13#10,
        [realstart, netbuffer.numtics]);
      continue;
    end;

    // check for a missed packet
    if realstart > nettics[netnode] then
    begin
      // stop processing until the other system resends the missed tics
      fprintf(debugfile, 'missed tics from %d (%d - %d)' + #13#10,
        [netnode, realstart, nettics[netnode]]);
      remoteresend[netnode] := True;
      continue;
    end;

    // update command store from the packet
    remoteresend[netnode] := False;

    start := nettics[netnode] - realstart;
    src := @netbuffer.cmds[start];

    while nettics[netnode] < realend do
    begin
      dest := @netcmds[netconsole][nettics[netnode] mod BACKUPTICS];
      nettics[netnode] := nettics[netnode] + 1;
      dest^ := src^;
      src := Pticcmd_t(pointer(integer(src) + SizeOf(ticcmd_t)));
    end;
  end;
end;


// NetUpdate
// Builds ticcmds for console player,
// sends out a packet

var
  gametime: integer;

procedure NetUpdate;
var
  nowtime: integer;
  newtics: integer;
  i, j: integer;
  realstart: integer;
  gameticdiv: integer;
begin
  // check time
  nowtime := I_GetTime div ticdup;
  newtics := nowtime - gametime;
  gametime := nowtime;

  if newtics <= 0 then // nothing new to update
  begin
    GetPackets;
    exit;
  end;

  if skiptics <= newtics then
  begin
    newtics := newtics - skiptics;
    skiptics := 0;
  end
  else
  begin
    skiptics := skiptics - newtics;
    newtics := 0;
  end;

  netbuffer.player := consoleplayer;

  // build new ticcmds for console player
  gameticdiv := gametic div ticdup;
  for i := 0 to newtics - 1 do
  begin
    D_ProcessEvents;

    if I_GameFinished then
      exit;

    if maketic - gameticdiv >= BACKUPTICS div 2 - 1 then
      break;          // can't hold any more

    //printf ("mk:%i ",maketic);
    G_BuildTiccmd(@localcmds[maketic mod BACKUPTICS]);
    Inc(maketic);
  end;


  if singletics then
    exit;         // singletic update is syncronous

  // send the packet to the other nodes
  for i := 0 to doomcom.numnodes - 1 do
    if nodeingame[i] then
    begin
      netbuffer.starttic := resendto[i];
      realstart := resendto[i];
      netbuffer.numtics := maketic - realstart;
      if netbuffer.numtics > BACKUPTICS then
        I_Error('NetUpdate(): netbuffer.numtics > BACKUPTICS');

      resendto[i] := maketic - doomcom.extratics;

      for j := 0 to netbuffer.numtics - 1 do
        netbuffer.cmds[j] :=
          localcmds[(realstart + j) mod BACKUPTICS];

      if remoteresend[i] then
      begin
        netbuffer.retransmitfrom := nettics[i];
        HSendPacket(i, NCMD_RETRANSMIT);
      end
      else
      begin
        netbuffer.retransmitfrom := 0;
        HSendPacket(i, 0);
      end;
    end;

  // listen for other packets
  GetPackets;
end;

// CheckAbort
procedure CheckAbort;
var
  ev: Pevent_t;
  stoptic: integer;
begin
  stoptic := I_GetTime + 2;
  while I_GetTime < stoptic do
  begin
    I_WaitVBL(1);
    I_ProcessWindows;
  end;

  repeat
    ev := @events[eventtail];
    if (ev._type = ev_keydown) and (ev.data1 = KEY_ESCAPE) then
      I_Error('CheckAbort(): Network game synchronization aborted.');

    eventtail := (eventtail + 1) and (MAXEVENTS - 1);
  until eventtail = eventhead;
end;

// D_ArbitrateNetStart
procedure D_ArbitrateNetStart;
var
  i: integer;
  gotinfo: array[0..MAXNETNODES - 1] of boolean;
begin
  autostart := True;
  ZeroMemory(@gotinfo, SizeOf(gotinfo));

  if doomcom.consoleplayer <> 0 then
  begin
    // listen for setup info from key player
    printf('listening for network start info...' + #13#10);
    while True do
    begin
      CheckAbort;
      if not HGetPacket then
        continue;
      if (netbuffer.checksum and NCMD_SETUP) <> 0 then
      begin
        if netbuffer.player <> VERSION then
          I_Error('D_ArbitrateNetStart(): Different DOOM versions cannot play a net game!');
        startskill := skill_t(netbuffer.retransmitfrom and 15);
        deathmatch := _SHR((netbuffer.retransmitfrom and $C0), 6);
        nomonsters := (netbuffer.retransmitfrom and $20) > 0;
        respawnparm := (netbuffer.retransmitfrom and $10) > 0;
        startmap := netbuffer.starttic and $3f;
        startepisode := _SHR(netbuffer.starttic, 6);
        exit;
      end;
    end; // while
  end
  else
  begin
    // key player, send the setup info
    printf('sending network start info...' + #13#10);
    repeat
      CheckAbort;
      for i := 0 to doomcom.numnodes - 1 do
      begin
        netbuffer.retransmitfrom := Ord(startskill);
        if deathmatch <> 0 then
          netbuffer.retransmitfrom := netbuffer.retransmitfrom or _SHL(deathmatch, 6);
        if nomonsters then
          netbuffer.retransmitfrom := netbuffer.retransmitfrom or $20;
        if respawnparm then
          netbuffer.retransmitfrom := netbuffer.retransmitfrom or $10;
        netbuffer.starttic := startepisode * 64 + startmap;
        netbuffer.player := VERSION;
        netbuffer.numtics := 0;
        HSendPacket(i, NCMD_SETUP);
      end;

      i := 10;
      while (i > 0) and HGetPacket do
      begin
        if (netbuffer.player and $7f) < MAXNETNODES then
          gotinfo[netbuffer.player and $7f] := True;
      end;

      i := 1;
      while (i < doomcom.numnodes) and gotinfo[i] do
        Inc(i);

    until i >= doomcom.numnodes;
  end;
end;

// D_CheckNetGame
// Works out player numbers among the net participants
procedure D_CheckNetGame;
var
  i: integer;
begin
  for i := 0 to MAXNETNODES - 1 do
  begin
    nodeingame[i] := False;
    nettics[i] := 0;
    remoteresend[i] := False; // set when local needs tics
    resendto[i] := 0;         // which tic to start sending
  end;

  // I_InitNetwork sets doomcom and netgame
  I_InitNetwork;
  if doomcom.id <> DOOMCOM_ID then
    I_Error('D_CheckNetGame(): Doomcom buffer invalid!');

  netbuffer := @doomcom.Data;
  consoleplayer := doomcom.consoleplayer;
  displayplayer := doomcom.consoleplayer;
  if netgame then
    D_ArbitrateNetStart;

  printf('startskill %d  deathmatch: %d  startmap: %d  startepisode: %d' + #13#10,
    [Ord(startskill), deathmatch, startmap, startepisode]);

  // read values out of doomcom
  ticdup := doomcom.ticdup;
  maxsend := BACKUPTICS div (2 * ticdup) - 1;
  if maxsend < 1 then
    maxsend := 1;

  for i := 0 to doomcom.numplayers - 1 do
    playeringame[i] := True;
  for i := 0 to doomcom.numnodes - 1 do
    nodeingame[i] := True;

  printf('player %d of %d (%d nodes)' + #13#10,
    [consoleplayer + 1, doomcom.numplayers, doomcom.numnodes]);
end;


// D_QuitNetGame
// Called before quitting to leave a net game
// without hanging the other players

procedure D_QuitNetGame;
var
  i, j: integer;
begin
  if not netgame or not usergame or (consoleplayer = -1) or demoplayback then
    exit;

  // send a bunch of packets for security
  netbuffer.player := consoleplayer;
  netbuffer.numtics := 0;
  for i := 0 to 3 do
  begin
    for j := 1 to doomcom.numnodes - 1 do
      if nodeingame[j] then
        HSendPacket(j, NCMD_EXIT);
    I_WaitVBL(1);
  end;
end;

// TryRunTics
var
  frameon: integer = 0;
  frameskip: array[0..3] of boolean;
  oldnettics: integer;
  oldentertics: integer = 0;

procedure TryRunTics;
var
  i, j: integer;
  lowtic: integer;
  entertic: integer;
  realtics: integer;
  availabletics: integer;
  counts: integer;
  cmd: Pticcmd_t;
  buf: integer;
begin
  // get real tics
  entertic := I_GetTime div ticdup;
  realtics := entertic - oldentertics;
  oldentertics := entertic;

  // get available tics
  NetUpdate;

  if I_GameFinished then
    exit;

  lowtic := MAXINT;
  for i := 0 to doomcom.numnodes - 1 do
  begin
    if nodeingame[i] then
    begin
      if nettics[i] < lowtic then
        lowtic := nettics[i];
    end;
  end;
  availabletics := lowtic - gametic div ticdup;

  // decide how many tics to run
  if realtics < availabletics - 1 then
    counts := realtics + 1
  else if realtics < availabletics then
    counts := realtics
  else
    counts := availabletics;

  if counts < 1 then
    counts := 1;

  Inc(frameon);

  if not demoplayback then
  begin
    // ideally nettics[0] should be 1 - 3 tics above lowtic
    // if we are consistantly slower, speed up time
    i := 0;
    while (i < MAXPLAYERS) and not playeringame[i] do
      Inc(i);
    if consoleplayer = i then
    begin
      // the key player does not adapt
    end
    else
    begin
      if nettics[0] <= nettics[nodeforplayer[i]] then
      begin
        Dec(gametime);
      end;
      frameskip[frameon and 3] := (oldnettics > nettics[nodeforplayer[i]]);
      oldnettics := nettics[0];
      if (frameskip[0] and frameskip[1] and frameskip[2] and frameskip[3]) then
      begin
        skiptics := 1;
      end;
    end;
  end; // demoplayback

  // wait for new tics if needed
  while lowtic < gametic / ticdup + counts do
  begin
    NetUpdate;
    lowtic := MAXINT;

    for i := 0 to doomcom.numnodes - 1 do
      if nodeingame[i] and (nettics[i] < lowtic) then
        lowtic := nettics[i];

    if lowtic < gametic / ticdup then
      I_Error('TryRunTics(): lowtic < gametic');

    // don't stay in here forever -- give the menu a chance to work
    if I_GetTime / ticdup - entertic >= 20 then
    begin
      M_Ticker;
      exit;
    end;
  end;

  // run the count * ticdup dics
  while counts <> 0 do
  begin
    Dec(counts);

    for i := 0 to ticdup - 1 do
    begin
      if gametic / ticdup > lowtic then
        I_Error('TryRunTics(): gametic > lowtic');
      if advancedemo then
        D_DoAdvanceDemo;
      M_Ticker;
      G_Ticker;
      Inc(gametic);

      // modify command for duplicated tics
      if i <> ticdup - 1 then
      begin
        buf := (gametic div ticdup) mod BACKUPTICS;
        for j := 0 to MAXPLAYERS - 1 do
        begin
          cmd := @netcmds[j][buf];
          cmd.chatchar := 0;
          if cmd.buttons and BT_SPECIAL <> 0 then
            cmd.buttons := 0;
        end;
      end;
    end;
    NetUpdate;  // check for new console commands
  end;
end;

end.
