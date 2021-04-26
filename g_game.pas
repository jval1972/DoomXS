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

unit g_game;

interface

uses
  doomdef,
  m_fixed,
  d_event,
  d_player,
  d_ticcmd;

procedure G_DeathMatchSpawnPlayer(playernum:integer);

procedure G_InitNew(skill:skill_t; episode:integer; map:integer);

{ Can be called by the startup code or M_Responder. }
{ A normal game starts at map 1, }
{ but a warp test can start elsewhere }
procedure G_DeferedInitNew(skill:skill_t; episode: integer; map: integer);

procedure G_DeferedPlayDemo(const name: string);

{ Can be called by the startup code or M_Responder, }
{ calls P_SetupLevel or W_EnterWorld. }
procedure G_LoadGame(const name: string);

procedure G_DoLoadGame;

{ Called by M_Responder. }
procedure G_SaveGame(slot: integer; const description: string);

{ Only called by startup code. }
procedure G_RecordDemo(const name: string);

procedure G_BeginRecording;

procedure G_TimeDemo(const name: string);

function G_CheckDemoStatus: boolean;

procedure G_ExitLevel;

procedure G_SecretExitLevel;

procedure G_WorldDone;

procedure G_Ticker;

function G_Responder(ev: Pevent_t): boolean;

procedure G_ScreenShot;

var
  sendpause: boolean;        // send a pause event next tic
  paused: boolean;

//
// controls (have defaults)
//
  key_right: integer;
  key_left: integer;

  key_up: integer;
  key_down: integer;

  key_strafeleft: integer;
  key_straferight: integer;
  key_fire: integer;
  key_use: integer;
  key_strafe: integer;
  key_speed: integer;

  usemouse: integer;
  mousebfire: integer;
  mousebstrafe: integer;
  mousebforward: integer;

  usejoystick: integer;
  joybfire: integer;
  joybstrafe: integer;
  joybuse: integer;
  joybspeed: integer;

  demoplayback: boolean;

  gameepisode: integer;
  gamemap: integer;

  deathmatch: integer; // only if started as net death
  netgame: boolean; // only true if packets are broadcast
  playeringame: array[0..MAXPLAYERS - 1] of boolean;

  consoleplayer: integer; // player taking events and displaying
  displayplayer: integer; // view being displayed
  gametic: integer;

  // https://www.doomworld.com/forum/topic/95719-a_tracer-and-gametic/?do=findComment&comment=1788516
  demostarttic: integer; // JVAL: Thanks fabian :)

  totalkills, totalitems, totalsecret: integer; // for intermission

  wminfo: wbstartstruct_t; // parms for world map / intermission

  gameskill: skill_t;

  bodyqueslot: integer;

  precache: boolean = true; // if true, load all graphics at start

  respawnmonsters: boolean;

  viewactive: boolean;

  singledemo: boolean; // quit after playing a demo from cmdline

  nodrawers: boolean; // for comparative timing purposes

  gamestate: gamestate_t;

  demorecording: boolean;

  gameaction: gameaction_t;

  usergame: boolean; // ok to save / end game

procedure G_PlayerReborn(player: integer);

procedure G_BuildTiccmd(cmd: Pticcmd_t);

var
  forwardmove: array[0..1] of fixed_t = ($19, $32);
  sidemove: array[0..1] of fixed_t = ($18, $28);
  angleturn: array[0..2] of fixed_t = (640, 1280, 320);

implementation

uses
  d_delphi,
  z_memory,
  doomstat,
  doomdata,
  am_map,
  d_net,
  d_main,
  f_finale,
  info_h,
  info,
  i_system,
  i_io,
  m_argv,
  m_misc,
  m_menu,
  m_rnd,
  p_setup,
  p_saveg,
  p_tick,
  p_local,
  p_mobj_h,
  p_mobj,
  p_inter,
  p_map,
  wi_stuff,
  hu_stuff,
  st_stuff,
// Needs access to LFB.
  v_video,
  w_wad,
  s_sound,
// Data.
  d_englsh,
  sounds,
// SKY handling - still the wrong place.
  r_data,
  r_sky,
  r_defs,
  r_main,
  r_draw,
  tables;

const
  SAVEGAMESIZE = 3 * SCREENWIDTH * SCREENHEIGHT;
  SAVESTRINGSIZE = 24;

procedure G_ReadDemoTiccmd(cmd: Pticcmd_t); forward;
procedure G_WriteDemoTiccmd (cmd: Pticcmd_t); forward;

procedure G_DoReborn(playernum: integer); forward;

procedure G_DoNewGame; forward;
procedure G_DoPlayDemo; forward;
procedure G_DoCompleted; forward;
procedure G_DoWorldDone; forward;
procedure G_DoSaveGame; forward;

var
  sendsave: boolean;         // send a save event next tic

  timingdemo: boolean;       // if true, exit with report on completion
  noblit: boolean;           // for comparative timing purposes
  starttime: integer;        // for comparative timing purposes

  levelstarttic: integer;          // gametic at level start

  demoname: string;
  netdemo: boolean;
  demobuffer: PByteArray;
  demo_p: PByteArray;
  demoend: PByteArray;

  consistancy: array[0..MAXPLAYERS - 1] of array[0..BACKUPTICS - 1] of smallint;

  savebuffer: PByteArray;

const
  TURBOTHRESHOLD = $32;

function MAXPLMOVE: fixed_t;
begin
  result := forwardmove[1];
end;

const
  SLOWTURNTICS = 6;
  NUMKEYS = 256;

var
  gamekeydown: array[0..NUMKEYS - 1] of boolean;
  turnheld: integer;

  mousearray: array[0..2] of boolean;
  mousebuttons: PBooleanArray;

// mouse values are used once 
  mousex: integer;
  mousey: integer;

  dclicktime: integer;
  dclickstate: integer;
  dclicks: integer;
  dclicktime2: integer;
  dclickstate2: integer;
  dclicks2: integer;

// joystick values are repeated
  joyxmove: integer;
  joyymove: integer;
  joyarray: array[0..NUMJOYBUTTONS - 1] of boolean;
  joybuttons: PBooleanArray;

  savegameslot: integer;
  savedescription: string;

const
  BODYQUESIZE  = 32;

var
  bodyque: array[0..BODYQUESIZE - 1] of Pmobj_t;

  statcopy: pointer;        // for statistics driver

function G_CmdChecksum(cmd: Pticcmd_t): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to sizeof(cmd^) div 4 - 2 do
    result := result + PIntegerArray(cmd)[i];
end;

//
// G_BuildTiccmd
// Builds a ticcmd from all of the available inputs
// or reads it from the demo buffer.
// If recording a demo, write it out
//
procedure G_BuildTiccmd(cmd: Pticcmd_t);
var
  i: integer;
  strafe: boolean;
  bstrafe: boolean;
  speed: integer;
  tspeed: integer;
  _forward: integer;
  side: integer;
  base: Pticcmd_t;
begin
  base := I_BaseTiccmd;    // empty, or external driver

  memcpy(cmd, base, SizeOf(cmd^));

  cmd.consistancy := consistancy[consoleplayer][maketic mod BACKUPTICS];

  strafe := gamekeydown[key_strafe] or
            ((usemouse <> 0) and mousebuttons[mousebstrafe]) or
            ((usejoystick <> 0) and joybuttons[joybstrafe]);
  speed := intval(gamekeydown[key_speed] or joybuttons[joybspeed]);

  _forward := 0;
  side := 0;

  // use two stage accelerative turning
  // on the keyboard and joystick
  if (joyxmove <> 0) or
     (gamekeydown[key_right]) or
     (gamekeydown[key_left]) then
    turnheld := turnheld + ticdup
  else
    turnheld := 0;

  if turnheld < SLOWTURNTICS then
    tspeed := 2             // slow turn
  else
    tspeed := speed;

  // let movement keys cancel each other out
  if strafe then
  begin
    if gamekeydown[key_right] then
      side := side + sidemove[speed];
    if gamekeydown[key_left] then
      side := side - sidemove[speed];
    if joyxmove > 0 then
      side := side + sidemove[speed];
    if joyxmove < 0 then
      side := side - sidemove[speed];
  end
  else
  begin
    if gamekeydown[key_right] then
      cmd.angleturn := cmd.angleturn - angleturn[tspeed];
    if gamekeydown[key_left] then
      cmd.angleturn := cmd.angleturn + angleturn[tspeed];
    if joyxmove > 0 then
      cmd.angleturn := cmd.angleturn - angleturn[tspeed];
    if joyxmove < 0 then
      cmd.angleturn := cmd.angleturn + angleturn[tspeed];
  end;

  if gamekeydown[key_up] then
    _forward := _forward + forwardmove[speed];

  if gamekeydown[key_down] then
    _forward := _forward - forwardmove[speed];

  if joyymove < 0 then
    _forward := _forward + forwardmove[speed];

  if joyymove > 0 then
    _forward := _forward - forwardmove[speed];

  if gamekeydown[key_straferight] then
    side := side + sidemove[speed];

  if gamekeydown[key_strafeleft] then
    side := side - sidemove[speed];

  // buttons
  cmd.chatchar := Ord(HU_dequeueChatChar);

  if gamekeydown[key_fire] or
     ((usemouse <> 0) and mousebuttons[mousebfire]) or
     ((usejoystick <> 0) and joybuttons[joybfire]) then
    cmd.buttons := cmd.buttons or BT_ATTACK;

  if gamekeydown[key_use] or ((usejoystick <> 0) and joybuttons[joybuse]) then
  begin
    cmd.buttons := cmd.buttons or BT_USE;
  // clear double clicks if hit use button
    dclicks := 0;
  end;

  // chainsaw overrides
  for i := 0 to Ord(NUMWEAPONS) - 2 do
    if gamekeydown[ord('1') + i] then
    begin
      cmd.buttons := cmd.buttons or BT_CHANGE;
      cmd.buttons := cmd.buttons or _SHL(i, BT_WEAPONSHIFT);
      break;
    end;

  // mouse
  if ((usemouse <> 0) and mousebuttons[mousebforward]) then
    _forward := _forward + forwardmove[speed];

  // forward double click
  if (usemouse <> 0) and (mousebuttons[mousebforward] <> (dclickstate <> 0)) and (dclicktime > 1) then
  begin
    dclickstate := intval(mousebuttons[mousebforward]);
    if dclickstate <> 0 then
      inc(dclicks);
    if dclicks = 2 then
    begin
      cmd.buttons := cmd.buttons or BT_USE;
      dclicks := 0;
    end
    else
      dclicktime := 0;
  end
  else
  begin
    dclicktime := dclicktime + ticdup;
    if dclicktime > 20 then
    begin
      dclicks := 0;
      dclickstate := 0;
    end
  end;

  // strafe double click
  bstrafe := ((usemouse <> 0) and mousebuttons[mousebstrafe]) or
             ((usejoystick <> 0) and joybuttons[joybstrafe]);
  if (bstrafe <> (dclickstate2 <> 0)) and (dclicktime2 > 1) then
  begin
    dclickstate2 := intval(bstrafe);
    if dclickstate2 <> 0 then
      inc(dclicks2);
    if dclicks2 = 2 then
    begin
      cmd.buttons := cmd.buttons or BT_USE;
      dclicks2 := 0;
    end
    else
      dclicktime2 := 0;
  end
  else
  begin
    dclicktime2 := dclicktime2 + ticdup;
    if dclicktime2 > 20 then
    begin
      dclicks2 := 0;
      dclickstate2 := 0;
    end;
  end;

  _forward := _forward + mousey;
  if strafe then
    side := side - mousex * 2
  else
    cmd.angleturn := cmd.angleturn + mousex * $8;

  mousex := 0;
  mousey := 0;

  if _forward > MAXPLMOVE then
    _forward := MAXPLMOVE
  else if _forward < -MAXPLMOVE then
    _forward := -MAXPLMOVE;

  if side > MAXPLMOVE then
    side := MAXPLMOVE
  else if side < -MAXPLMOVE then
    side := -MAXPLMOVE;

  cmd.forwardmove := cmd.forwardmove + _forward;
  cmd.sidemove := cmd.sidemove + side;

  // special buttons
  if sendpause then
  begin
    sendpause := false;
    cmd.buttons := BT_SPECIAL or BTS_PAUSE;
  end;

  if sendsave then
  begin
    sendsave := false;
    cmd.buttons := BT_SPECIAL or BTS_SAVEGAME or _SHL(savegameslot, BTS_SAVESHIFT);
  end;
end;

//
// G_DoLoadLevel
//
procedure G_DoLoadLevel;
var
  i: integer;
  ep: integer;
begin
  // Set the sky map.
  // First thing, we have a dummy sky texture name,
  //  a flat. The data is in the WAD only because
  //  we look for an actual index, instead of simply
  //  setting one.
  skyflatnum := R_FlatNumForName(SKYFLATNAME);

  // DOOM determines the sky texture to be used
  // depending on the current episode, and the game version.
  if (gamemode = commercial) or
     (gamemission = pack_tnt) or
     (gamemission = pack_plut) then
  begin
    if gamemap < 12 then
      ep := 1
    else if gamemap < 21 then
      ep := 2
    else
      ep := 3;
  end
  else
    ep := gameepisode;

  skytexture := R_TextureNumForName('SKY' + Chr(Ord('0') + ep));

  levelstarttic := gametic;        // for time calculation
  if wipegamestate = Ord(GS_LEVEL) then
    wipegamestate := -1;  // force a wipe

  gamestate := GS_LEVEL;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] and (players[i].playerstate = PST_DEAD) then
      players[i].playerstate := PST_REBORN;
    memset(@players[i].frags, 0, SizeOf(players[i].frags));
  end;

  P_SetupLevel(gameepisode, gamemap, 0, gameskill);
  displayplayer := consoleplayer;    // view the guy you are playing
  starttime := I_GetTime;
  gameaction := ga_nothing;

  // clear cmd building stuff
  memset(@gamekeydown, 0, SizeOf(gamekeydown));
  joyxmove := 0;
  joyymove := 0;
  mousex := 0;
  mousey := 0;
  sendpause := false;
  sendsave := false;
  paused := false;
  memset(mousebuttons, 0, SizeOf(mousebuttons));
  memset(joybuttons, 0, SizeOf(joybuttons));
end;

//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//
function G_Responder(ev: Pevent_t): boolean;
var
  bmask: integer;
  i: integer;
begin
  // allow spy mode changes even during the demo
  if (gamestate = GS_LEVEL) and (ev._type = ev_keydown) and
     (ev.data1 = KEY_F12) and (singledemo or (deathmatch = 0)) then
  begin
  // spy mode
    repeat
      inc(displayplayer);
      if displayplayer = MAXPLAYERS then
        displayplayer := 0;
    until not (not playeringame[displayplayer] and (displayplayer <> consoleplayer));
    result := true;
    exit;
  end;

  // any other key pops up menu if in demos
  if (gameaction = ga_nothing) and not singledemo and
     (demoplayback or (gamestate = GS_DEMOSCREEN)) then
  begin
    if (ev._type = ev_keydown) or
       ((ev._type = ev_mouse) and (ev.data1 <> 0)) or
       ((ev._type = ev_joystick) and (ev.data1 <> 0)) then
    begin
      M_StartControlPanel;
      result := true;
    end
    else
      result := false;
    exit;
  end;

  if gamestate = GS_LEVEL then
  begin
    if HU_Responder(ev) then
    begin
      result := true; // chat ate the event
      exit;
    end;
    if ST_Responder(ev) then
    begin
      result := true; // status window ate it
      exit;
    end;
    if AM_Responder(ev) then
    begin
      result := true; // automap ate it
      exit;
    end;
  end;

  if gamestate = GS_FINALE then
  begin
    if F_Responder(ev) then
    begin
      result := true; // finale ate the event
      exit;
    end;
  end;

  case ev._type of
    ev_keydown:
      begin
        if ev.data1 = KEY_PAUSE then
        begin
          sendpause := true;
          result := true;
          exit;
        end;
        if ev.data1 < NUMKEYS then
          gamekeydown[ev.data1] := true;
        result := true; // eat key down events
        exit;
      end;
    ev_keyup:
      begin
        if ev.data1 < NUMKEYS then
          gamekeydown[ev.data1] := false;
        result := false; // always let key up events filter down
        exit;
      end;
    ev_mouse:
      begin
        if usemouse <> 0 then
        begin
          mousebuttons[0] := ev.data1 and 1 <> 0;
          mousebuttons[1] := ev.data1 and 2 <> 0;
          mousebuttons[2] := ev.data1 and 4 <> 0;
          mousex := ev.data2 * (mouseSensitivity + 5) div 10;
          mousey := ev.data3 * (mouseSensitivity + 5) div 10;
        end
        else
        begin
          mousebuttons[0] := false;
          mousebuttons[1] := false;
          mousebuttons[2] := false;
          mousex := 0;
          mousey := 0;
        end;
        result := true;    // eat events
        exit;
      end;
    ev_joystick:
      begin
        if usejoystick <> 0 then
        begin
          bmask := 1;
          for i := 0 to NUMJOYBUTTONS - 1 do
          begin
            joybuttons[i] := ev.data1 and bmask <> 0;
            bmask := bmask * 2;
          end;
          joyxmove := ev.data2;
          joyymove := ev.data3;
        end
        else
        begin
          for i := 0 to NUMJOYBUTTONS - 1 do
            joybuttons[i] := false;
          joyxmove := 0;
          joyymove := 0;
        end;
        result := true;    // eat events
        exit;
      end;
  end;

  result := false;
end;

//
// G_Ticker
// Make ticcmd_ts for the players.
//
procedure G_Ticker;
var
  i: integer;
  buf: integer;
  cmd: Pticcmd_t;
  msg: string;
begin
  // do player reborns if needed
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] and (players[i].playerstate = PST_REBORN) then
      G_DoReborn(i);

  // do things to change the game state
  while (gameaction <> ga_nothing) do
  begin
    case gameaction of
      ga_loadlevel:
        G_DoLoadLevel;
      ga_newgame:
        G_DoNewGame;
      ga_loadgame:
        G_DoLoadGame;
      ga_savegame:
        G_DoSaveGame;
      ga_playdemo:
        G_DoPlayDemo;
      ga_completed:
        G_DoCompleted;
      ga_victory:
        F_StartFinale;
      ga_worlddone:
        G_DoWorldDone;
      ga_screenshot:
        begin
          M_ScreenShot;
          gameaction := ga_nothing;
        end;
    end;
  end;

  // get commands, check consistancy,
  // and build new consistancy check
  buf := (gametic div ticdup) mod BACKUPTICS;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      cmd := @players[i].cmd;

      memcpy(cmd, @netcmds[i][buf], SizeOf(ticcmd_t));

      if demoplayback then
        G_ReadDemoTiccmd(cmd);
      if demorecording then
        G_WriteDemoTiccmd(cmd);

      // check for turbo cheats
      if (cmd.forwardmove > TURBOTHRESHOLD) and
         ((gametic and 31) = 0) and
         (((_SHR(gametic, 5)) and 3) = i) then
      begin
        sprintf(msg, '%s is turbo!', [player_names[i]]);
        players[consoleplayer]._message := msg;
      end;

      if netgame and not netdemo and (gametic mod ticdup = 0) then
      begin
        if (gametic > BACKUPTICS) and
           (consistancy[i][buf] <> cmd.consistancy) then
          I_Error('G_Ticker(): consistency failure (%d should be %d)',
            [cmd.consistancy, consistancy[i][buf]]);
        if players[i].mo <> nil then
          consistancy[i][buf] := players[i].mo.x
        else
          consistancy[i][buf] := rndindex;
      end;
    end;
  end;

  // check for special buttons
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      if players[i].cmd.buttons and BT_SPECIAL <> 0 then
      begin
        case players[i].cmd.buttons and BT_SPECIALMASK of
          BTS_PAUSE:
            begin
              paused := not paused;
              if paused then
                S_PauseSound
              else
                S_ResumeSound;
            end;
          BTS_SAVEGAME:
            begin
              if savedescription = '' then
                savedescription := 'NET GAME';
              savegameslot :=
                _SHR((players[i].cmd.buttons and BTS_SAVEMASK), BTS_SAVESHIFT);
              gameaction := ga_savegame;
            end;
        end;
      end;
    end;
  end;

  // do main actions
  case gamestate of
    GS_LEVEL:
      begin
        P_Ticker;
        ST_Ticker;
        AM_Ticker;
        HU_Ticker;
      end;
    GS_INTERMISSION:
      begin
        WI_Ticker;
      end;
    GS_FINALE:
      begin
        F_Ticker;
      end;
    GS_DEMOSCREEN:
      begin
        D_PageTicker;
      end;
  end;
end;

//
// PLAYER STRUCTURE FUNCTIONS
// also see P_SpawnPlayer in P_Things
//

//
// G_PlayerFinishLevel
// Can when a player completes a level.
//
procedure G_PlayerFinishLevel(player: integer);
var
  p: Pplayer_t;
begin
  p := @players[player];

  memset(@p.powers, 0, SizeOf(p.powers));
  memset(@p.cards, 0, SizeOf(p.cards));
  p.mo.flags := p.mo.flags and not MF_SHADOW; // cancel invisibility
  p.extralight := 0;    // cancel gun flashes
  p.fixedcolormap := 0; // cancel ir gogles
  p.damagecount := 0;   // no palette changes
  p.bonuscount := 0;
end;

//
// G_PlayerReborn
// Called after a player dies
// almost everything is cleared and initialized
//
procedure G_PlayerReborn(player: integer);
var
  p: Pplayer_t;
  i: integer;
  frags: array[0..MAXPLAYERS - 1] of integer;
  killcount: integer;
  itemcount: integer;
  secretcount: integer;
begin
  memcpy(@frags, @players[player].frags, SizeOf(frags));
  killcount := players[player].killcount;
  itemcount := players[player].itemcount;
  secretcount := players[player].secretcount;

  p := @players[player];
  memset(p, 0, SizeOf(player_t));

  memcpy(@players[player].frags, @frags, SizeOf(players[player].frags));
  players[player].killcount := killcount;
  players[player].itemcount := itemcount;
  players[player].secretcount := secretcount;

  p.usedown := true;
  p.attackdown := true;  // don't do anything immediately
  p.playerstate := PST_LIVE;
  p.health := MAXHEALTH;
  p.readyweapon := wp_pistol;
  p.pendingweapon := wp_pistol;
  p.weaponowned[Ord(wp_fist)] := 1;
  p.weaponowned[Ord(wp_pistol)] := 1;
  p.ammo[Ord(am_clip)] := 50;

  for i := 0 to Ord(NUMAMMO) - 1 do
    p.maxammo[i] := maxammo[i];
end;

//
// G_CheckSpot
// Returns false if the player cannot be respawned
// at the given mapthing_t spot
// because something is occupying it
//
function G_CheckSpot(playernum: integer; mthing: Pmapthing_t): boolean;
var
  x: fixed_t;
  y: fixed_t;
  ss: Psubsector_t;
  an: angle_t;
  mo: Pmobj_t;
  i: integer;
begin
  if players[playernum].mo = nil then
  begin
    // first spawn of level, before corpses
    for i := 0 to playernum - 1 do
      if (players[i].mo.x = (mthing.x * FRACUNIT)) and
         (players[i].mo.y = (mthing.y * FRACUNIT)) then
      begin
        result := false;
        exit;
      end;
    result := true;
    exit;
  end;

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  if not P_CheckPosition(players[playernum].mo, x, y) then
  begin
    result := false;
    exit;
  end;

  // flush an old corpse if needed
  if bodyqueslot >= BODYQUESIZE then
    P_RemoveMobj(bodyque[bodyqueslot mod BODYQUESIZE]);
  bodyque[bodyqueslot mod BODYQUESIZE] := players[playernum].mo;
  inc(bodyqueslot);

  // spawn a teleport fog
  ss := R_PointInSubsector(x, y);
  an := (ANG45 * (mthing.angle div 45)) shr ANGLETOFINESHIFT;

  mo := P_SpawnMobj(x + 20 * finecosine[an], y + 20 * finesine[an],
          ss.sector.floorheight, MT_TFOG);

  if players[consoleplayer].viewz <> 1 then
    S_StartSound(mo, Ord(sfx_telept));  // don't start sound on first frame

  result := true;
end;

//
// G_DeathMatchSpawnPlayer
// Spawns a player at one of the random death match spots
// called at level load and each death
//
procedure G_DeathMatchSpawnPlayer(playernum: integer);
var
  i, j: integer;
  selections: integer;
begin
  selections := deathmatch_p; // JVAL - deathmatchstarts;
  if selections < 4 then
    I_Error('G_DeathMatchSpawnPlayer(): Only %d deathmatch spots, 4 required', [selections]);

  for j := 0 to 19 do
  begin
    i := P_Random mod selections;
    if G_CheckSpot(playernum, @deathmatchstarts[i]) then
    begin
      deathmatchstarts[i]._type := playernum + 1;
      P_SpawnPlayer(@deathmatchstarts[i]);
      exit;
    end;
  end;

  // no good spot, so the player will probably get stuck
  P_SpawnPlayer(@playerstarts[playernum]);
end;

//
// G_DoReborn
//
procedure G_DoReborn(playernum: integer);
var
  i: integer;
begin
  if not netgame then
    // reload the level from scratch
    gameaction := ga_loadlevel
  else
  begin
    // respawn at the start

    // first dissasociate the corpse
    players[playernum].mo.player := nil;

    // spawn at random spot if in death match
    if deathmatch <> 0 then
    begin
      G_DeathMatchSpawnPlayer(playernum);
      exit;
    end;

    if G_CheckSpot(playernum, @playerstarts[playernum]) then
    begin
      P_SpawnPlayer(@playerstarts[playernum]);
      exit;
    end;

    // try to spawn at one of the other players spots
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if G_CheckSpot (playernum, @playerstarts[i]) then
      begin
        playerstarts[i]._type := playernum + 1; // fake as other player
        P_SpawnPlayer(@playerstarts[i]);
        playerstarts[i]._type := i + 1; // restore
        exit;
      end;
      // he's going to be inside something.  Too bad.
    end;
    P_SpawnPlayer(@playerstarts[playernum]);
  end;
end;

procedure G_ScreenShot;
begin
  gameaction := ga_screenshot;
end;

var
// DOOM Par Times
  pars: array[1..3, 1..9] of integer = (
    (30, 75, 120, 90, 165, 180, 180, 30, 165),
    (90, 90, 90, 120, 90, 360, 240, 30, 170),
    (90, 45, 90, 150, 90, 90, 165, 30, 135)
  );

// DOOM II Par Times
  cpars: array[0..31] of integer = (
    30, 90, 120, 120, 90, 150, 120, 120, 270, 90, 210, 150, 150, 150, 210, 150,
    420, 150, 210, 150, 240, 150, 180, 150, 150, 300, 330, 420, 300, 180, 120, 30
  );

//
// G_DoCompleted
//
  secretexit: boolean;

procedure G_ExitLevel;
begin
  secretexit := false;
  gameaction := ga_completed;
end;

// Here's for the german edition.
procedure G_SecretExitLevel;
begin
  // IF NO WOLF3D LEVELS, NO SECRET EXIT!
  if (gamemode = commercial) and (W_CheckNumForName('map31') < 0) then
    secretexit := false
  else
    secretexit := true;
  gameaction := ga_completed;
end;

procedure G_DoCompleted;
var
  i: integer;
begin
  gameaction := ga_nothing;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      G_PlayerFinishLevel(i); // take away cards and stuff

  if automapactive then
    AM_Stop;

  if gamemode <> commercial then
  begin
    case gamemap of
      8:
        begin
          gameaction := ga_victory;
          exit;
        end;
      9:
        begin
          for i := 0 to MAXPLAYERS - 1 do
            players[i].didsecret := true;
        end;
    end;
  end;


  wminfo.didsecret := players[consoleplayer].didsecret;
  wminfo.epsd := gameepisode - 1;
  wminfo.last := gamemap - 1;

  // wminfo.next is 0 biased, unlike gamemap
  if gamemode = commercial then
  begin
    if secretexit then
    begin
      case gamemap of
        15: wminfo.next := 30;
        31: wminfo.next := 31;
      end
    end
    else
    begin
      case gamemap of
        31,
        32: wminfo.next := 15;
      else
        wminfo.next := gamemap;
      end;
    end
  end
  else
  begin
    if secretexit then
      wminfo.next := 8  // go to secret level
    else if gamemap = 9 then
    begin
      // returning from secret level
      case gameepisode of
        1: wminfo.next := 3;
        2: wminfo.next := 5;
        3: wminfo.next := 6;
        4: wminfo.next := 2;
      end
    end
    else
      wminfo.next := gamemap; // go to next level
  end;

  wminfo.maxkills := totalkills;
  wminfo.maxitems := totalitems;
  wminfo.maxsecret := totalsecret;
  wminfo.maxfrags := 0;
  if gamemode = commercial then
    wminfo.partime := TICRATE * cpars[gamemap - 1]
  else
    wminfo.partime := TICRATE * pars[gameepisode][gamemap];
  wminfo.pnum := consoleplayer;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    wminfo.plyr[i]._in := playeringame[i];
    wminfo.plyr[i].skills := players[i].killcount;
    wminfo.plyr[i].sitems := players[i].itemcount;
    wminfo.plyr[i].ssecret := players[i].secretcount;
    wminfo.plyr[i].stime := leveltime;
    memcpy(@wminfo.plyr[i].frags, @players[i].frags, SizeOf(wminfo.plyr[i].frags));
  end;

  gamestate := GS_INTERMISSION;
  viewactive := false;
  automapactive := false;

  if statcopy <> nil then
    memcpy(statcopy, @wminfo, SizeOf(wminfo));

  WI_Start(@wminfo);
end;

//
// G_WorldDone 
//
procedure G_WorldDone;
begin
  gameaction := ga_worlddone;

  if secretexit then
    players[consoleplayer].didsecret := true;

  if gamemode = commercial then
  begin
    if secretexit then
    begin
      if gamemap in [15, 31, 6, 11, 20, 30] then
        F_StartFinale
    end
    else if gamemap in [6, 11, 20, 30] then
      F_StartFinale;
  end;
end;

procedure G_DoWorldDone;
begin
  gamestate := GS_LEVEL;
  gamemap := wminfo.next + 1;
  G_DoLoadLevel;
  gameaction := ga_nothing;
  viewactive := true;
end;

//
// G_InitFromSavegame
// Can be called by the startup code or the menu task.
//
var
  savename: string;

procedure G_LoadGame(const name: string);
begin
  savename := name;
  gameaction := ga_loadgame;
end;

const
  VERSIONSIZE = 16;

procedure G_DoLoadGame;
var
  len: integer;
  i: integer;
  a, b, c: integer;
  vcheck: string;
begin
  gameaction := ga_nothing;

  len := M_ReadFile(savename, pointer(savebuffer));
  save_p := @savebuffer[SAVESTRINGSIZE];

  // skip the description field
  vcheck := '';
  sprintf(vcheck, 'version %d', [VERSION]);

  if len < Length(vcheck) then
    exit; // bad version

  for i := 0 to Length(vcheck) - 1 do
    if save_p[i] <> Ord(vcheck[i + 1]) then
      exit; // bad version

  save_p := @save_p[VERSIONSIZE];

  gameskill := skill_t(save_p[0]);
  save_p := @save_p[1];

  gameepisode := save_p[0];
  save_p := @save_p[1];

  gamemap := save_p[0];
  save_p := @save_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := save_p[0] <> 0;
    save_p := @save_p[1];
  end;

  // load a base level
  G_InitNew(gameskill, gameepisode, gamemap);

  // get the times
  a := save_p[0];
  save_p := @save_p[1];

  b := save_p[0];
  save_p := @save_p[1];

  c := save_p[0];
  save_p := @save_p[1];

  leveltime := _SHL(a, 16) + _SHL(b, 8) + c;

  // dearchive all the modifications
  P_UnArchivePlayers;
  P_UnArchiveWorld;
  P_UnArchiveThinkers;
  P_UnArchiveSpecials;

  if save_p[0] <> $1d then
    I_Error('G_DoLoadGame(): Bad savegame');

  // done
  Z_Free(savebuffer);

  if setsizeneeded then
    R_ExecuteSetViewSize;

  // draw the pattern into the back screen
  R_FillBackScreen;
end;

//
// G_SaveGame
// Called by the menu task.
// Description is a 24 byte text string
//
procedure G_SaveGame(slot: integer; const description: string);
begin
  savegameslot := slot;
  savedescription := description;
  sendsave := true;
end;

procedure G_DoSaveGame;
var
  name: string;
  name2: string;
  description: string;
  len: integer;
  i: integer;
  fmt: string;
begin
  fmt := SAVEGAMENAME + '%d.dsg';
  if M_CheckParmCDROM then
    fmt := 'c:\doomdata\' + fmt;
  sprintf(name, fmt, [savegameslot]);
  description := savedescription;

  save_p := PByteArray(integer(screens[1]) + $4000);
  savebuffer := save_p;

  memcpy(save_p, @description[1], SAVESTRINGSIZE);

  save_p := PByteArray(integer(save_p) + SAVESTRINGSIZE);
  name2 := '';

  sprintf(name2, 'version %d', [VERSION]);
  memcpy(save_p, @name2[1], VERSIONSIZE);
  save_p := @save_p[VERSIONSIZE];

  save_p[0] := Ord(gameskill);
  save_p := @save_p[1];

  save_p[0] := gameepisode;
  save_p := @save_p[1];

  save_p[0] := gamemap;
  save_p := @save_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    save_p[0] := intval(playeringame[i]);
  save_p := @save_p[1];
  end;

  save_p[0] := _SHR(leveltime, 16);
  save_p := @save_p[1];

  save_p[0] := _SHR(leveltime, 8);
  save_p := @save_p[1];

  save_p[0] := leveltime;
  save_p := @save_p[1];

  P_ArchivePlayers;
  P_ArchiveWorld;
  P_ArchiveThinkers;
  P_ArchiveSpecials;

  save_p[0] := $1d; // consistancy marker
  save_p := @save_p[1];

  len := integer(save_p) - integer(savebuffer);
  if len > SAVEGAMESIZE then
    I_Error('G_DoSaveGame(): Savegame buffer overrun');
  M_WriteFile(name, savebuffer, len);
  gameaction := ga_nothing;
  savedescription := '';

  players[consoleplayer]._message := GGSAVED;

  // draw the pattern into the back screen
  R_FillBackScreen;
end;

//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set.
//
var
  d_skill: skill_t;
  d_episode: integer;
  d_map: integer;

procedure G_DeferedInitNew(skill: skill_t; episode, map: integer);
begin
  d_skill := skill;
  d_episode := episode;
  d_map := map;
  gameaction := ga_newgame;
end;

procedure G_DoNewGame;
var
  i: integer;
begin
  demoplayback := false;
  netdemo := false;
  netgame := false;
  deathmatch := 0;
  for i := 1 to MAXPLAYERS - 1 do
    playeringame[i] := false;
  respawnparm := false;
  fastparm := false;
  nomonsters := false;
  consoleplayer := 0;
  G_InitNew(d_skill, d_episode, d_map);
  gameaction := ga_nothing;
end;

procedure G_InitNew(skill: skill_t; episode, map: integer);
var
  i: integer;
begin
  if paused then
  begin
    paused := false;
    S_ResumeSound;
  end;

  if skill > sk_nightmare then
    skill := sk_nightmare;

  // This was quite messy with SPECIAL and commented parts.
  // Supposedly hacks to make the latest edition work.
  // It might not work properly.
  if episode < 1 then
    episode := 1;

  if gamemode = retail then
  begin
    if episode > 4 then
      episode := 4;
  end
  else if gamemode = shareware then
  begin
    if episode > 1 then
     episode := 1;  // only start episode 1 on shareware
  end
  else
  begin
    if episode > 3 then
      episode := 3;
  end;

  if map < 1 then
    map := 1;

  if (map > 9) and (gamemode <> commercial) then
    map := 9;

  M_ClearRandom;

  if (skill = sk_nightmare) or respawnparm then
    respawnmonsters := true
  else
    respawnmonsters := false;

  if fastparm or ((skill = sk_nightmare) and (gameskill <> sk_nightmare)) then
  begin
    for i := Ord(S_SARG_RUN1) to Ord(S_SARG_PAIN2) do
      states[i].tics := _SHR(states[i].tics, 1);
    mobjinfo[Ord(MT_BRUISERSHOT)].speed := 20 * FRACUNIT;
    mobjinfo[Ord(MT_HEADSHOT)].speed := 20 * FRACUNIT;
    mobjinfo[Ord(MT_TROOPSHOT)].speed := 20 * FRACUNIT;
  end
  else if (skill <> sk_nightmare) and (gameskill = sk_nightmare) then
  begin
    for i := Ord(S_SARG_RUN1) to Ord(S_SARG_PAIN2) do
      states[i].tics := _SHL(states[i].tics, 1);
    mobjinfo[Ord(MT_BRUISERSHOT)].speed := 15 * FRACUNIT;
    mobjinfo[Ord(MT_HEADSHOT)].speed := 10 * FRACUNIT;
    mobjinfo[Ord(MT_TROOPSHOT)].speed := 10 * FRACUNIT;
  end;


  // force players to be initialized upon first level load
  for i := 0 to MAXPLAYERS - 1 do
    players[i].playerstate := PST_REBORN;

  usergame := true;  // will be set false if a demo
  paused := false;
  demoplayback := false;
  automapactive := false;
  viewactive := true;
  gameepisode := episode;
  gamemap := map;
  gameskill := skill;

  viewactive := true;
  demostarttic := 0;

  G_DoLoadLevel;
end;

//
// DEMO RECORDING
//
const
  DEMOMARKER = $80;

procedure G_ReadDemoTiccmd(cmd: Pticcmd_t);
begin
  if demo_p[0] = DEMOMARKER then
  begin
    // end of demo data stream
    G_CheckDemoStatus;
    exit;
  end;
  cmd.forwardmove := demo_p[0];
  demo_p := @demo_p[1];

  cmd.sidemove := demo_p[0];
  demo_p := @demo_p[1];

  cmd.angleturn := _SHL(demo_p[0], 8);
  demo_p := @demo_p[1];

  cmd.buttons := demo_p[0];
  demo_p := @demo_p[1];
end;

procedure G_WriteDemoTiccmd(cmd: Pticcmd_t);
begin
  if gamekeydown[Ord('q')] then // press q to end demo recording
    G_CheckDemoStatus;

  demo_p[0] := Ord(cmd.forwardmove);
  demo_p := @demo_p[1];

  demo_p[0] := Ord(cmd.sidemove);
  demo_p := @demo_p[1];

  demo_p[0] := _SHR((cmd.angleturn + 128), 8);
  demo_p := @demo_p[1];

  demo_p[0] := cmd.buttons;
  demo_p := @demo_p[1];

  demo_p := PByteArray(integer(demo_p) - 4);

  if integer(demo_p) > integer(demoend) - 16 then
  begin
    // no more space
    G_CheckDemoStatus;
    exit;
  end;
  G_ReadDemoTiccmd(cmd);  // make SURE it is exactly the same
end;

//
// G_RecordDemo
//
procedure G_RecordDemo(const name: string);
var
  i: integer;
  maxsize: integer;
begin
  usergame := false;
  demoname := name + '.lmp';

  i := M_CheckParm ('-maxdemo');
  if (i <> 0) and (i < myargc - 1) then
    maxsize := atoi(myargv[i + 1]) * 1024
  else
    maxsize := $20000;

  demobuffer := Z_Malloc(maxsize, PU_STATIC, nil);
  demoend := @demobuffer[maxsize];

  demorecording := true;
end;

procedure G_BeginRecording;
var
  i: integer;
begin
  demo_p := demobuffer;

  demo_p[0] := VERSION;
  demo_p := @demo_p[1];

  demo_p[0] := Ord(gameskill);
  demo_p := @demo_p[1];

  demo_p[0] := gameepisode;
  demo_p := @demo_p[1];

  demo_p[0] := gamemap;
  demo_p := @demo_p[1];

  demo_p[0] := deathmatch;
  demo_p := @demo_p[1];

  demo_p[0] := intval(respawnparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(fastparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(nomonsters);
  demo_p := @demo_p[1];

  demo_p[0] := consoleplayer;
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    demo_p[0] := intval(playeringame[i]);
    demo_p := @demo_p[1];
  end;
end;

//
// G_PlayDemo
//
var
  defdemoname: string;

procedure G_DeferedPlayDemo(const name: string);
begin
  defdemoname := name;
  gameaction := ga_playdemo;
end;

procedure G_DoPlayDemo;
var
  skill: skill_t;
  i, episode, map: integer;
begin
  gameaction := ga_nothing;
  demobuffer := W_CacheLumpName(defdemoname, PU_STATIC);
  demo_p := demobuffer;

  if demo_p[0] <> VERSION then
  begin
    fprintf(stderr, 'G_DoPlayDemo(): Demo is from a different game version = %d.%d!' + #13#10,
      [demo_p[0] div 100, demo_p[0] mod 100]);
    gameaction := ga_nothing;
    exit;
  end;
  demo_p := @demo_p[1];

  skill := skill_t(demo_p[0]);
  demo_p := @demo_p[1];

  episode := demo_p[0];
  demo_p := @demo_p[1];

  map := demo_p[0];
  demo_p := @demo_p[1];

  deathmatch := demo_p[0];
  demo_p := @demo_p[1];

  respawnparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  fastparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  nomonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  consoleplayer := demo_p[0];
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;

  if playeringame[1] then
  begin
    netgame := true;
    netdemo := true;
  end;

  // don't spend a lot of time in loadlevel
  precache := false;
  G_InitNew(skill, episode, map);
  precache := true;

  usergame := false;
  demoplayback := true;
end;

//
// G_TimeDemo 
//
procedure G_TimeDemo(const name: string);
begin
  nodrawers := M_CheckParm('-nodraw') > 0;
  noblit := M_CheckParm ('-noblit') > 0;
  timingdemo := true;
  singletics := true;

  defdemoname := name;
  gameaction := ga_playdemo;
end;

(*
===================
=
= G_CheckDemoStatus
=
= Called after a death or level completion to allow demos to be cleaned up
= Returns true if a new demo loop action will take place
===================
*)

function G_CheckDemoStatus: boolean;
var
  endtime: integer;
  i: integer;
begin
  if timingdemo then
  begin
    endtime := I_GetTime;
    I_Error('G_CheckDemoStatus(): timed %d gametics in %d realtics', [gametic, endtime - starttime]);
  end;

  if demoplayback then
  begin
    if singledemo then
      I_Quit;

    Z_ChangeTag(demobuffer, PU_CACHE);
    demoplayback := false;
    netdemo := false;
    netgame := false;
    deathmatch := 0;
    for i := 1 to MAXPLAYERS - 1 do
      playeringame[i] := false;
    respawnparm := false;
    fastparm := false;
    nomonsters := false;
    consoleplayer := 0;
    D_AdvanceDemo;
    result := true;
    exit;
  end;

  if demorecording then
  begin
    demo_p[0] := DEMOMARKER;
    demo_p := @demo_p[1];

    M_WriteFile(demoname, demobuffer, POperation(demo_p, demobuffer, '-', SizeOf(byte)));
    Z_Free(demobuffer);
    demorecording := false;
    I_Error('G_CheckDemoStatus(): Demo %s recorded', [demoname]);
  end;

  result := false;
end;

initialization
  mousebuttons := @mousearray[0];
  joybuttons := @joyarray[0];

end.

