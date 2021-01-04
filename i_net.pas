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

unit i_net;

interface

procedure I_InitNetwork;

procedure I_NetCmd;

implementation

uses
  WinSock,
  d_delphi,
  doomtype,
  d_event,
  d_net,
  d_player,
  g_game,
  i_system,
  m_argv,
  doomstat;

const
  IPPORT_USERRESERVED = 5000;

type
  socklen_t = integer;


// NETWORKING

var
  DOOMPORT: word;
  mysocket: TSocket;
  sendaddress: array[0..MAXNETNODES - 1] of sockaddr_in;
  sendplayer: array[0..MAXNETNODES] of byte;

var
  netget: PProcedure;
  netsend: PProcedure;

var
  sendsocket: integer;
  insocket: integer;

function neterror: string; forward;

const
  PRE_CONNECT = 0;
  PRE_DISCONNECT = 1;
  PRE_ALLHERE = 2;
  PRE_CONACK = 3;
  PRE_ALLHEREACK = 4;
  PRE_GO = 5;

  // Set PreGamePacket.fake to this so that the game rejects any pregame packets
  // after it starts. This translates to NCMD_SETUP|NCMD_MULTI.
  PRE_FAKE = $30;

type
  machine_t = record
    address: longword;
    port: word;
    player: byte;
    pad: byte;
  end;

  PreGamePacket_t = record
    fake: byte;
    _message: byte;
    numnodes: byte;
    consolenum: byte;
    machines: array[0..MAXNETNODES - 1] of machine_t;
  end;


// UDPsocket

function UDPsocket: TSocket;
begin
  // allocate a socket
  Result := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if Result = INVALID_SOCKET then
    I_Error('UDPsocket(): Can not create socket: %s', [neterror]);
end;


// BindToLocalPort

procedure BindToLocalPort(s: TSocket; port: word);
var
  v: integer;
  address: sockaddr_in;
begin
  memset(@address, 0, SizeOf(address));
  address.sin_family := AF_INET;
  address.sin_addr.s_addr := INADDR_ANY;
  address.sin_port := htons(port);

  v := bind(s, address, SizeOf(address));
  if v = SOCKET_ERROR then
    I_Error('BindToLocalPort(): %s', [neterror]);
end;

function FindNode(const address: sockaddr_in): integer;
var
  i: integer;
begin
  // find remote node number
  i := 0;
  while i < doomcom.numnodes do
  begin
    if (address.sin_addr.s_addr = sendaddress[i].sin_addr.s_addr) and
      (address.sin_port = sendaddress[i].sin_port) then
      break;
    Inc(i);
  end;

  if i = doomcom.numnodes then
    // packet is not from one of the players (new game broadcast?)
    i := -1;

  Result := i;
end;


// PacketSend

procedure PacketSend;
var
  c: integer;
begin
  //printf ("sending %i\n",gametic);
  c := sendto(mysocket, doomcom.Data, doomcom.datalength, 0,
    sendaddress[doomcom.remotenode], SizeOf(sendaddress[doomcom.remotenode]));

  if c = -1 then
    I_Error('PacketSend(): sendto() returned -1');
end;

const
  BACKUPTICS = 36;
  MAX_MSGLEN = BACKUPTICS * 10;


// PacketGet

procedure PacketGet;
var
  c: integer;
  fromlen: socklen_t;
  fromaddress: sockaddr_in;
  node: integer;
  err: integer;
begin
  fromlen := SizeOf(fromaddress);
  c := recvfrom(mysocket, doomcom.Data, MAX_MSGLEN, 0, fromaddress, fromlen);
  node := FindNode(fromaddress);

  if c = SOCKET_ERROR then
  begin
    err := WSAGetLastError;

    if (err = WSAECONNRESET) and (node >= 0) then
    begin
      // The remote node aborted unexpectedly, so pretend it sent an exit packet
      printf('The connection from player %d was dropped' + #13#10,
        [sendplayer[node]]);

      // VJ      doomcom.data[0] = $80;  // NCMD_EXIT
      c := 1;
    end
    else if err <> WSAEWOULDBLOCK then
    begin
      I_Error('PacketGet(): %s', [neterror]);
    end
    else
    begin
      doomcom.remotenode := -1; // no packet
      exit;
    end;
  end;

  doomcom.remotenode := node;
  doomcom.datalength := c;
end;

var
  fromaddress_pg: sockaddr_in;

function PreGet(buffer: pointer; bufferlen: integer; noabort: boolean): PSOCKADDR;
var
  fromlen: socklen_t;
  c: integer;
  err: integer;
begin
  fromlen := SizeOf(fromaddress_pg);
  c := recvfrom(mysocket, buffer^, bufferlen, 0, fromaddress_pg, fromlen);

  if c = SOCKET_ERROR then
  begin
    err := WSAGetLastError;
    if (err = WSAEWOULDBLOCK) or (noabort and (err = WSAECONNRESET)) then
    begin
      Result := nil; // no packet
      exit;
    end;
    I_Error('PreGet(): %s', [neterror]);
  end;
  Result := @fromaddress_pg;
end;

procedure PreSend(buffer: pointer; bufferlen: integer; _to: PSOCKADDR);
begin
  sendto(mysocket, buffer^, bufferlen, 0, _to^, SizeOf(_to^));
end;

procedure BuildAddress(address: PSOCKADDR; var Name: string);
var
  hostentry: PHostEnt;  // host information entry
  port: word;
  portpart: string;
  isnamed: boolean;
  _pos: integer;
  i: integer;
begin
  isnamed := False;

  address.sin_family := AF_INET;

  _pos := Pos(':', Name);
  if _pos > 0 then
  begin
    portpart := '';
    for i := _pos + 1 to Length(Name) do
      portpart := portpart + Name[i];
    port := atoi(portpart);
    if port = 0 then
    begin
      printf('Weird port: %s (using %d)' + #13#10, [portpart, DOOMPORT]);
      port := DOOMPORT;
    end;
  end
  else
    port := DOOMPORT;

  address.sin_port := htons(port);

  for i := 1 to Length(Name) do
  begin
    if not (Name[i] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']) then
    begin
      isnamed := True;
      break;
    end;
  end;

  if not isnamed then
  begin
    address.sin_addr.s_addr := inet_addr(PChar(Name));
    printf('Node number %d address %s' + #13#10, [doomcom.numnodes, Name]);
  end
  else
  begin
    hostentry := gethostbyname(PChar(Name));
    if hostentry = nil then
      I_Error('gethostbyname(): Could not find %s' + #13#10 + '%s',
        [Name, neterror]);
    address.sin_addr.s_addr := longword(hostentry.h_addr_list);
    printf('Node number %d hostname %s' + #13#10,
      [doomcom.numnodes, StringVal(hostentry.h_name)]);
  end;
end;

procedure CloseNetwork;
begin
  if mysocket <> INVALID_SOCKET then
  begin
    closesocket(mysocket);
    mysocket := INVALID_SOCKET;
  end;
  WSACleanup;
end;

procedure StartNetwork(autoPort: boolean);
var
  trueval: integer;
  wsad: WSADATA;
begin
  trueval := 1;
  if WSAStartup($0101, wsad) <> 0 then
    I_Error('StartNetwork(): Could not initialize Windows Sockets');

  //  atterm (CloseNetwork);
  CloseNetwork;

  netsend := PacketSend;
  netget := PacketGet;
  netgame := True;
  //  multiplayer := true; // VJ -> removed

  // create communication socket
  mysocket := UDPsocket;
  if autoPort then
    BindToLocalPort(mysocket, 0)
  else
    BindToLocalPort(mysocket, DOOMPORT);
  ioctlsocket(mysocket, FIONBIO, trueval);
end;

procedure WaitForPlayers(i: integer);
begin
  if i = myargc then
    I_Error('WaitForPlayers(): Not enough parameters after -net');

  StartNetwork(False);

  // parse player number and host list
  doomcom.consoleplayer := Ord(myargv[i + 1][1]) - Ord('1');
  printf('Console player number: %d' + #13#10, [doomcom.consoleplayer]);

  doomcom.numnodes := 1;    // this node for sure

  Inc(i, 2);
  while (i <= myargc) and (myargv[i][1] <> '-') and (myargv[i][1] <> '+') do
  begin
    BuildAddress(@sendaddress[doomcom.numnodes], myargv[i]);
    Inc(doomcom.numnodes);
    Inc(i);
  end;

  printf('Total players: %d' + #13#10, [doomcom.numnodes]);

  doomcom.id := DOOMCOM_ID;
  doomcom.numplayers := doomcom.numnodes;
end;

procedure SendAbort;
var
  dis: array[0..1] of byte;
begin
  dis[0] := PRE_FAKE;
  dis[1] := PRE_DISCONNECT;

  Dec(doomcom.numnodes);
  while doomcom.numnodes > 0 do
  begin
    PreSend(@dis, 2, @sendaddress[doomcom.numnodes]);
    PreSend(@dis, 2, @sendaddress[doomcom.numnodes]);
    PreSend(@dis, 2, @sendaddress[doomcom.numnodes]);
    PreSend(@dis, 2, @sendaddress[doomcom.numnodes]);
    Dec(doomcom.numnodes);
  end;
end;


procedure I_InitNetwork;
var
  trueval: integer;
  i: integer;
  j: integer;
  p: integer;
  hostentry: PHostEnt; // host information entry
  addr: string;
begin
  trueval := 1;
  doomcom := malloc(SizeOf(doomcom^));
  memset(doomcom, 0, SizeOf(doomcom^));

  // set up for network
  i := M_CheckParm('-dup');
  if (i <> 0) and (i < myargc - 1) then
  begin
    doomcom.ticdup := Ord(myargv[i + 1][1]) - Ord('0');
    if doomcom.ticdup < 1 then
      doomcom.ticdup := 1
    else if doomcom.ticdup > 9 then
      doomcom.ticdup := 9;
  end
  else
    doomcom.ticdup := 1;

  if M_CheckParm('-extratic') <> 0 then
    doomcom.extratics := 1
  else
    doomcom.extratics := 0;

  p := M_CheckParm('-port');
  if (p <> 0) and (p < myargc - 1) then
  begin
    DOOMPORT := atoi(myargv[p + 1]);
    printf('using alternate port %d' + #13#10, [DOOMPORT]);
  end;

  // parse network game options,
  //  -net <consoleplayer> <host> <host> ...
  i := M_CheckParm('-net');
  if i = 0 then
  begin
    // single player game
    netgame := False;
    doomcom.id := DOOMCOM_ID;
    doomcom.numplayers := 1;
    doomcom.numnodes := 1;
    doomcom.deathmatch := 0;
    doomcom.consoleplayer := 0;
    exit;
  end;

  netsend := PacketSend;
  netget := PacketGet;
  netgame := True;

  // parse player number and host list
  doomcom.consoleplayer := Ord(myargv[i + 1][1]) - Ord('1');

  doomcom.numnodes := 1; // this node for sure

  Inc(i);
  while (i < myargc - 1) and (myargv[i + 1][1] <> '-') do
  begin
    Inc(i);
    sendaddress[doomcom.numnodes].sin_family := AF_INET;
    sendaddress[doomcom.numnodes].sin_port := htons(DOOMPORT);
    if myargv[i][1] = '.' then
    begin
      addr := '';
      for j := 2 to Length(myargv[i]) do
        addr := addr + myargv[i][j];
      sendaddress[doomcom.numnodes].sin_addr.s_addr := inet_addr(PChar(addr));
    end
    else
    begin
      hostentry := gethostbyname(PChar(myargv[i]));
      if hostentry = nil then
        I_Error('I_InitNetwork(): gethostbyname: couldn''t find %s', [myargv[i]]);
      sendaddress[doomcom.numnodes].sin_addr.s_addr := PLongWord(hostentry.h_addr_list)^;
    end;
    doomcom.numnodes := doomcom.numnodes + 1;
  end;

  doomcom.id := DOOMCOM_ID;
  doomcom.numplayers := doomcom.numnodes;

  // build message to receive
  insocket := UDPsocket;
  BindToLocalPort(insocket, htons(DOOMPORT));
  ioctlsocket(insocket, FIONBIO, trueval);

  sendsocket := UDPsocket;
end;

procedure I_NetCmd;
begin
  if doomcom.command = CMD_SEND then
    netsend
  else if doomcom.command = CMD_GET then
    netget
  else
    I_Error('I_NetCmd(): Bad net cmd: %d', [doomcom.command]);
end;

function neterror: string;
begin
  Result := '';
end;

initialization
  DOOMPORT := (IPPORT_USERRESERVED + 29);
  mysocket := INVALID_SOCKET;

end.
