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

unit d_main;

interface

uses
  d_event,
  doomdef;

const
  MAXWADFILES = 20;

var
  wadfiles: array[0..(MAXWADFILES) - 1] of string;
  numwadfiles: integer = 0;

procedure D_ProcessEvents;
procedure D_DoAdvanceDemo;


procedure D_AddFile(_file: string);


// D_DoomMain()
// Not a globally visible function, just included for source reference,
// calls all startup code, parses command line options.
// If not overrided by user input, calls N_AdvanceDemo.

procedure D_DoomMain;

// Called by IO functions when input is detected.
procedure D_PostEvent(ev: Pevent_t);


// BASE LEVEL

procedure D_PageTicker;

procedure D_PageDrawer;

procedure D_AdvanceDemo;

procedure D_StartTitle;

// wipegamestate can be set to -1 to force a wipe on the next draw
var
  wipegamestate: integer = Ord(GS_DEMOSCREEN);

  nomonsters: boolean;        // checkparm of -nomonsters
  fastparm: boolean;          // checkparm of -fast
  devparm: boolean;       // started game with -devparm
  singletics: boolean = False; // debug flag to cancel adaptiveness
  autostart: boolean;
  startskill: skill_t;
  respawnparm: boolean;   // checkparm of -respawn

  startepisode: integer;
  startmap: integer;
  advancedemo: boolean;

  basedefault: string;  // default file


implementation

uses d_delphi,
  Classes,
  doomstat, dstrings, d_englsh,
  sounds, z_zone, w_wad, s_sound, v_video,
  f_finale, f_wipe,
  m_argv, m_misc, m_menu,
  info,
  i_system, i_sound, i_video, i_io,
  d_ticcmd, d_player, d_net,
  g_game,
  hu_stuff, wi_stuff, st_stuff,
  am_map,
  p_setup,
  r_draw, r_main;

const
  BGCOLOR = 7;
  FGCOLOR = 8;


// D-DoomLoop()
// Not a globally visible function,
//  just included for source reference,
//  called by D_DoomMain, never exits.
// Manages timing and IO,
//  calls all ?_Responder, ?_Ticker, and ?_Drawer,
//  calls I_GetTime, I_StartFrame, and I_StartTic

procedure D_DoomLoop; forward;



// D_PostEvent
// Called by the I/O functions when input is detected

procedure D_PostEvent(ev: Pevent_t);
begin
  events[eventhead] := ev^;
  Inc(eventhead);
  eventhead := eventhead and (MAXEVENTS - 1);
end;


// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain

procedure D_ProcessEvents;
var
  ev: Pevent_t;
begin
  // IF STORE DEMO, DO NOT ACCEPT INPUT
  if (gamemode = commercial) and (W_CheckNumForName('map01') < 0) then
    exit;

  if I_GameFinished then
    exit;

  while eventtail <> eventhead do
  begin
    ev := @events[eventtail];
    if M_Responder(ev) then
    // menu ate the event
    else
      G_Responder(ev);
    if I_GameFinished then
    begin
      eventtail := eventhead;
      exit;
    end;
    Inc(eventtail);
    eventtail := eventtail and (MAXEVENTS - 1);
  end;
end;


// D_Display
//  draw current display, possibly wiping it from the previous


var
  viewactivestate: boolean = False;
  menuactivestate: boolean = False;
  inhelpscreensstate: boolean = False;
  oldgamestate: integer = -1;
  borderdrawcount: integer;

procedure D_Display;
var
  nowtime: integer;
  tics: integer;
  wipestart: integer;
  y: integer;
  done: boolean;
  wipe: boolean;
  redrawsbar: boolean;
begin
  if nodrawers then
    exit; // for comparative timing / profiling

  redrawsbar := False;

  // change the view size if needed
  if setsizeneeded then
  begin
    R_ExecuteSetViewSize;
    oldgamestate := -1; // force background redraw
    borderdrawcount := 3;
  end;

  // save the current screen if about to wipe
  if Ord(gamestate) <> wipegamestate then
  begin
    wipe := True;
    wipe_StartScreen(0, 0, SCREENWIDTH, SCREENHEIGHT);
  end
  else
    wipe := False;

  if (gamestate = GS_LEVEL) and (gametic <> 0) then
    HU_Erase;

  // do buffered drawing
  case gamestate of
    GS_LEVEL:
    begin
      if gametic <> 0 then
      begin
        if automapactive then
          AM_Drawer;
        if wipe or ((viewheight <> SCREENHEIGHT) and fullscreen) then
          redrawsbar := True;
        if inhelpscreensstate and (not inhelpscreens) then
          redrawsbar := True; // just put away the help screen
        ST_Drawer(viewheight = SCREENHEIGHT{200}, redrawsbar);
//        fullscreen := viewheight = SCREENHEIGHT{200};
      end;
    end;
    GS_INTERMISSION:
      WI_Drawer;
    GS_FINALE:
      F_Drawer;
    GS_DEMOSCREEN:
      D_PageDrawer;
  end;

  // draw the view directly
  if (gamestate = GS_LEVEL) and (not automapactive) and (gametic <> 0) then
    R_RenderPlayerView(@players[displayplayer]);

  if (gamestate = GS_LEVEL) and (gametic <> 0) then
    HU_Drawer;

  // clean up border stuff
  if (Ord(gamestate) <> oldgamestate) and (gamestate <> GS_LEVEL) then
    I_SetPalette(W_CacheLumpName('PLAYPAL', PU_CACHE));

  // see if the border needs to be initially drawn
  if (gamestate = GS_LEVEL) and (oldgamestate <> Ord(GS_LEVEL)) then
  begin
    viewactivestate := False; // view was not active
    R_FillBackScreen;         // draw the pattern into the back screen
  end;

  // see if the border needs to be updated to the screen
  if (gamestate = GS_LEVEL) and (not automapactive) and
    (scaledviewwidth <> SCREENWIDTH{320}) then
  begin
    if menuactive or menuactivestate or (not viewactivestate) then
      borderdrawcount := 3;
    if borderdrawcount > 0 then
    begin
      R_DrawViewBorder; // erase old menu stuff
      Dec(borderdrawcount);
    end;
  end;

  menuactivestate := menuactive;
  viewactivestate := viewactive;
  inhelpscreensstate := inhelpscreens;
  oldgamestate := Ord(gamestate);
  wipegamestate := Ord(gamestate);

  // draw pause pic
  if paused then
  begin
    if automapactive then
      y := 4
    else
      y := viewwindowy + 4;
    V_DrawPatch(viewwindowx + (scaledviewwidth - 68) div 2,
      y, 0, W_CacheLumpName('M_PAUSE', PU_CACHE), False);
  end;

  // menus go directly to the screen
  M_Drawer;  // menu is drawn even on top of everything
  NetUpdate; // send out any new accumulation

  // normal update
  if not wipe then
  begin
    I_FinishUpdate; // page flip or blit buffer
    exit;
  end;

  // wipe update
  wipe_EndScreen(0, 0, SCREENWIDTH, SCREENHEIGHT);

  wipestart := I_GetTime - 1;

  repeat
    repeat
      nowtime := I_GetTime;
      tics := nowtime - wipestart;
    until (tics <> 0);
    wipestart := nowtime;
    done := wipe_ScreenWipe(Ord(wipe_Melt), 0, 0, SCREENWIDTH, SCREENHEIGHT, tics);
    M_Drawer;         // menu is drawn even on top of wipes
    I_FinishUpdate;   // page flip or blit buffer
  until done;
end;

//  D_DoomLoop
procedure D_DoomLoop;
begin
  if demorecording then
    G_BeginRecording;

  I_InitGraphics;

  while True do
  begin
    // frame syncronous IO operations
    I_StartFrame;

    // process one or more tics
    if singletics then
    begin
      I_StartTic;
      D_ProcessEvents;
      G_BuildTiccmd(@netcmds[consoleplayer][maketic mod BACKUPTICS]);
      if advancedemo then
        D_DoAdvanceDemo;
      M_Ticker;
      G_Ticker;
      Inc(gametic);
      Inc(maketic);
    end
    else
      TryRunTics; // will run at least one tic

    if I_GameFinished then
      break;
    S_UpdateSounds(players[consoleplayer].mo);// move positional sounds

    // Update display, next frame, with current state.
    D_Display;
  end;
end;


//  DEMO LOOP

var
  demosequence: integer;
  pagetic: integer;
  pagename: string;


// D_PageTicker
// Handles timing for warped projection

procedure D_PageTicker;
begin
  Dec(pagetic);
  if pagetic < 0 then
    D_AdvanceDemo;
end;


// D_PageDrawer

procedure D_PageDrawer;
begin
  V_DrawPatch(0, 0, 0, W_CacheLumpName(pagename, PU_CACHE), True);
end;


// D_AdvanceDemo
// Called after each demo or intro demosequence finishes

procedure D_AdvanceDemo;
begin
  advancedemo := True;
end;


// This cycles through the demo sequences.
// FIXME - version dependend demo numbers?

procedure D_DoAdvanceDemo;
begin
  players[consoleplayer].playerstate := PST_LIVE;  // not reborn
  advancedemo := False;
  usergame := False;               // no save / end game here
  paused := False;
  gameaction := ga_nothing;

  if gamemode = retail then
    demosequence := (demosequence + 1) mod 7
  else
    demosequence := (demosequence + 1) mod 6;

  case demosequence of
    0:
    begin
      if gamemode = commercial then
        pagetic := 35 * 11
      else
        pagetic := 170;
      gamestate := GS_DEMOSCREEN;
      pagename := 'TITLEPIC';
      if gamemode = commercial then
        S_StartMusic(Ord(mus_dm2ttl))
      else
        S_StartMusic(Ord(mus_intro));
    end;
    1:
    begin
      G_DeferedPlayDemo('demo1');
    end;
    2:
    begin
      pagetic := 200;
      gamestate := GS_DEMOSCREEN;
      pagename := 'CREDIT';
    end;
    3:
    begin
      G_DeferedPlayDemo('demo2');
    end;
    4:
    begin
      gamestate := GS_DEMOSCREEN;
      if gamemode = commercial then
      begin
        pagetic := 35 * 11;
        pagename := 'TITLEPIC';
        S_StartMusic(Ord(mus_dm2ttl));
      end
      else
      begin
        pagetic := 200;
        if gamemode = retail then
          pagename := 'CREDIT'
        else
          pagename := 'HELP2';
      end;
    end;
    5:
    begin
      G_DeferedPlayDemo('demo3');
    end;
    // THE DEFINITIVE DOOM Special Edition demo
    6:
    begin
      G_DeferedPlayDemo('demo4');
    end;
  end;
end;


// D_StartTitle

procedure D_StartTitle;
begin
  gameaction := ga_nothing;
  demosequence := -1;
  D_AdvanceDemo;
end;

//      print title for every printed line
var
  title: string;

// D_AddFile
procedure D_AddFile(_file: string);
var
  i: integer;
begin
  for i := 0 to MAXWADFILES - 1 do
    if wadfiles[i] = '' then
    begin
      wadfiles[i] := _file;
      numwadfiles := i + 1;
      exit;
    end;
end;


// IdentifyVersion
// Checks availability of IWAD files by name,
// to determine whether registered/commercial features
// should be executed (notably loading PWAD's).

procedure IdentifyVersion;
var
  doom1wad: string;
  doomwad: string;
  doomuwad: string;
  doom2wad: string;

  doom2fwad: string;
  plutoniawad: string;
  tntwad: string;
  doomwaddir: string;
begin
  doomwaddir := getenv('DOOMWADDIR');
  if doomwaddir = '' then
    doomwaddir := '.';

  // Commercial.
  sprintf(doom2wad, '%s\doom2.wad', [doomwaddir]);

  // Retail.
  sprintf(doomuwad, '%s\doomu.wad', [doomwaddir]);

  // Registered.
  sprintf(doomwad, '%s\doom.wad', [doomwaddir]);

  // Shareware.
  sprintf(doom1wad, '%s\doom1.wad', [doomwaddir]);

  // plutonia pack
  sprintf(plutoniawad, '%s\plutonia.wad', [doomwaddir]);

  // tnt pack
  sprintf(tntwad, '%s\tnt.wad', [doomwaddir]);


  // French stuff.
  sprintf(doom2fwad, '%s\doom2f.wad', [doomwaddir]);

  if M_CheckParm('-shdev') > 0 then
  begin
    gamemode := shareware;
    devparm := True;
    D_AddFile(DEVDATA + 'doom1.wad');
    D_AddFile(DEVMAPS + 'data_se/texture1.lmp');
    D_AddFile(DEVMAPS + 'data_se/pnames.lmp');
    basedefault := DEVDATA + 'default.cfg';
    exit;
  end;

  if M_CheckParm('-regdev') > 0 then
  begin
    gamemode := registered;
    devparm := True;
    D_AddFile(DEVDATA + 'doom.wad');
    D_AddFile(DEVMAPS + 'data_se/texture1.lmp');
    D_AddFile(DEVMAPS + 'data_se/texture2.lmp');
    D_AddFile(DEVMAPS + 'data_se/pnames.lmp');
    basedefault := DEVDATA + 'default.cfg';
    exit;
  end;

  if M_CheckParm('-comdev') > 0 then
  begin
    gamemode := commercial;
    devparm := True;
  (* I don't bother
  if(plutonia)
      D_AddFile (DEVDATA"plutonia.wad");
  else if(tnt)
      D_AddFile (DEVDATA"tnt.wad");
  else*)
    D_AddFile(DEVDATA + 'doom2.wad');

    D_AddFile(DEVMAPS + 'cdata/texture1.lmp');
    D_AddFile(DEVMAPS + 'cdata/pnames.lmp');
    basedefault := DEVDATA + 'default.cfg';
    exit;
  end;

  basedefault := 'default.cfg';

  if fexists(doom2fwad) then
  begin
    gamemode := commercial;
    // C'est ridicule!
    // Let's handle languages in config files, okay?
    language := french;
    printf('French version' + #13#10);
    D_AddFile(doom2fwad);
    exit;
  end;

  if fexists(doom2wad) then
  begin
    gamemode := commercial;
    D_AddFile(doom2wad);
    exit;
  end;

  if fexists(plutoniawad) then
  begin
    gamemode := commercial;
    D_AddFile(plutoniawad);
    exit;
  end;

  if fexists(tntwad) then
  begin
    gamemode := commercial;
    D_AddFile(tntwad);
    exit;
  end;

  if fexists(doomuwad) then
  begin
    gamemode := retail;
    D_AddFile(doomuwad);
    exit;
  end;

  if fexists(doomwad) then
  begin
    gamemode := registered;
    D_AddFile(doomwad);
    exit;
  end;

  if fexists(doom1wad) then
  begin
    gamemode := shareware;
    D_AddFile(doom1wad);
    exit;
  end;

  printf('Game mode indeterminate.' + #13#10);
  gamemode := indetermined;
end;


// Find a Response File

// JVAL: Changed to handle more that 1 response files
procedure FindResponseFile;
var
  i: integer;
  handle: file;
  size: integer;
  index: integer;
  myargv1: string;
  infile: string;
  _file: string;
  s: TStringList;
begin
  s := TStringList.Create;
  try
    s.Add(myargv[0]);

    for i := 1 to myargc - 1 do
    begin
      if myargv[i][1] = '@' then
      begin
        // READ THE RESPONSE FILE INTO MEMORY
        myargv1 := Copy(myargv[i], 2, length(myargv[i]) - 1);
        {$I-}
        Assign(handle, myargv1);
        reset(handle, 1);
        {$I+}
        if IOResult <> 0 then
        begin
          printf(#13#10 + 'No such response file: %s!' + #13#10, [myargv1]);
          halt(1);
        end;
        printf('Found response file %s!' + #13#10, [myargv1]);

        size := FileSize(handle);
        seek(handle, 0);
        SetLength(_file, size);
        BlockRead(handle, (@_file[1])^, size);
        Close(handle);

        infile := '';
        for index := 1 to Length(_file) do
          if _file[index] = ' ' then
            infile := infile + #13#10
          else
            infile := infile + _file[i];

        s.Text := s.Text + infile;
      end
      else
        s.Add(myargv[i]);
    end;

    index := 0;
    for i := 0 to s.Count - 1 do
      if s.Strings[i] <> '' then
      begin
        myargv[index] := s.Strings[i];
        Inc(index);
      end;
    myargc := index;
  finally
    s.Free;
  end;
end;


// D_DoomMain

procedure D_DoomMain;
var
  p: integer;
  _file: string;
  scale: integer;
  _time: integer;
  s_error: string;
  i: integer;
  j: integer;
  oldoutproc: TOutProc;
begin
  outproc := @I_IOprintf;

  printf('M_InitArgv: Initializing command line parameters.' + #13#10);
  M_InitArgv;

  FindResponseFile;

  IdentifyVersion;

  printf('I_InitializeIO: Initializing input/output streams.' + #13#10);
  I_InitializeIO;

  modifiedgame := False;

  nomonsters := boolval(M_CheckParm('-nomonsters'));
  respawnparm := boolval(M_CheckParm('-respawn'));
  fastparm := boolval(M_CheckParm('-fast'));
  devparm := boolval(M_CheckParm('-devparm'));

  if M_CheckParm('-altdeath') > 0 then
    deathmatch := 2
  else if M_CheckParm('-deathmatch') > 0 then
    deathmatch := 1;

  case gamemode of
    retail:
    begin
      sprintf(title,
        '                         ' + 'The Ultimate DOOM Startup v%d.%d' +
        '                           ',
        [VERSION div 100, VERSION mod 100]);
    end;
    shareware:
    begin
      sprintf(title,
        '                            ' + 'DOOM Shareware Startup v%d.%d' +
        '                           ',
        [VERSION div 100, VERSION mod 100]);
    end;
    registered:
    begin
      sprintf(title,
        '                            ' + 'DOOM Registered Startup v%d.%d' +
        '                           ',
        [VERSION div 100, VERSION mod 100]);
    end;
    commercial:
    begin
      sprintf(title,
        '                         ' + 'DOOM 2: Hell on Earth v%d.%d' +
        '                           ',
        [VERSION div 100, VERSION mod 100]);
    end;
    else
    begin
      sprintf(title,
        '                         ' + 'Public DOOM - v%d.%d' +
        '                           ',
        [VERSION div 100, VERSION mod 100]);
    end;
  end;

  printf('%s' + #13#10, [title]);

  if devparm then
    printf(D_DEVSTR);

  if M_CheckParmCDROM then
  begin
    printf(D_CDROM);
    mkdir('c:\doomdata');
    basedefault := 'c:\doomdata\default.cfg';
  end;

  // turbo option
  p := M_CheckParm('-turbo');
  if p <> 0 then
  begin
    scale := 200;
    if p < myargc - 1 then
      scale := atoi(myargv[p + 1]);
    if scale < 10 then
      scale := 10
    else if scale > 400 then
      scale := 400;
    printf('turbo scale: %d%' + #13#10, [scale]);
    forwardmove[0] := forwardmove[0] * scale div 100;
    forwardmove[1] := forwardmove[1] * scale div 100;
    sidemove[0] := sidemove[0] * scale div 100;
    sidemove[1] := sidemove[1] * scale div 100;
  end;

  // add any files specified on the command line with -file wadfile
  // to the wad list

  // convenience hack to allow -wart e m to add a wad file
  // prepend a tilde to the filename so wadfile will be reloadable
  p := M_CheckParm('-wart');
  if p <> 0 then
  begin
    myargv[p][5] := 'p';     // big hack, change to -warp

    // Map name handling.
    case gamemode of
      shareware,
      retail,
      registered:
      begin
        sprintf(_file, '~' + DEVMAPS + 'E%sM%s.wad',
          [myargv[p + 1][1], myargv[p + 2][1]]);
        printf('Warping to Episode %s, Map %s.' + #13#10,
          [myargv[p + 1], myargv[p + 2]]);
      end;
      else
      begin
        p := atoi(myargv[p + 1]);
        if p < 10 then
          sprintf(_file, '~' + DEVMAPS + 'cdata/map0%i.wad', [p])
        else
          sprintf(_file, '~' + DEVMAPS + 'cdata/map%i.wad', [p]);
      end;
    end;

    D_AddFile(_file);
  end;

  p := M_CheckParm('-file');
  if p <> 0 then
  begin
    // the parms after p are wadfile/lump names,
    // until end of parms or another - preceded parm
    modifiedgame := True;            // homebrew levels
    Inc(p);
    while (p <> myargc) and (myargv[p][1] <> '-') do
    begin
      D_AddFile(myargv[p]);
      Inc(p);
    end;
  end;

  p := M_CheckParm('-playdemo');

  if p = 0 then
    p := M_CheckParm('-timedemo');

  if (p <> 0) and (p < myargc - 1) then
  begin
    sprintf(_file, '%s.lmp', [myargv[p + 1]]);
    D_AddFile(_file);
    printf('Playing demo %s.lmp.' + #13#10, [myargv[p + 1]]);
  end;

  // get skill / episode / map from parms
  startskill := sk_medium;
  startepisode := 1;
  startmap := 1;
  autostart := False;

  p := M_CheckParm('-skill');
  if (p <> 0) and (p < myargc - 1) then
  begin
    startskill := skill_t(Ord(myargv[p + 1][1]) - Ord('1'));
    autostart := True;
  end;

  p := M_CheckParm('-episode');
  if (p <> 0) and (p < myargc - 1) then
  begin
    startepisode := Ord(myargv[p + 1][1]) - Ord('0');
    startmap := 1;
    autostart := True;
  end;

  p := M_CheckParm('-timer');
  if (p <> 0) and (p < myargc - 1) and boolval(deathmatch) then
  begin
    _time := atoi(myargv[p + 1]);
    if _time > 1 then
      printf('Levels will end after %d minutes' + #13#10, [_time])
    else
      printf('Levels will end after %d minute' + #13#10, [_time]);
  end;

  p := M_CheckParm('-avg');
  if (p <> 0) and (p <= myargc - 1) and boolval(deathmatch) then
    printf('Austin Virtual Gaming: Levels will end after 20 minutes' + #13#10);

  p := M_CheckParm('-warp');
  if (p <> 0) and (p < myargc - 1) then
  begin
    if gamemode = commercial then
      startmap := atoi(myargv[p + 1])
    else
    begin
      startepisode := Ord(myargv[p + 1][1]) - Ord('0');
      startmap := Ord(myargv[p + 2][1]) - Ord('0');
    end;
    autostart := True;
  end;

  p := M_CheckParm('-fullscreen');
  if (p <> 0) and (p <= myargc - 1) then
    fullscreen := True;

  p := M_CheckParm('-nofullscreen');
  if (p <> 0) and (p <= myargc - 1) then
    fullscreen := False;

  p := M_CheckParm('-zone');
  if (p <> 0) and (p < myargc - 1) then
  begin
    mb_used := atoi(myargv[p + 1]);
    if mb_used < 6 then
    begin
      printf('Zone memory allocation needs at least 6MB (%d).' + #13#10, [mb_used]);
      mb_used := 6;
    end;
  end;

  // init subsystems
  printf('Z_Init: Init zone memory allocation daemon, allocation %dMB.' +
    #13#10, [mb_used]);
  Z_Init;

  printf('I_InitInfo: Initialize information tables.' + #13#10);
  I_InitInfo;

  printf('V_Init: allocate screens.' + #13#10);
  V_Init;

  printf('M_LoadDefaults: Load system defaults.' + #13#10);
  M_LoadDefaults;              // load before initing other systems

  printf('M_InitMenus: Initializing menus.' + #13#10);
  M_InitMenus;


  printf('W_Init: Init WADfiles.' + #13#10);
  W_InitMultipleFiles(@wadfiles);

  if gamemode = registered then
    if W_CheckNumForName('e4m1') >= 0 then
      gamemode := retail;

  // Check for -file in shareware
  if modifiedgame then
  begin
    if gamemode = shareware then
      I_Error(#13#10 +
        'D_DoomMain(): You cannot -file with the shareware version. Register!');
    // Check for fake IWAD with right name,
    // but w/o all the lumps of the registered version.
    if gamemode in [registered, retail] then
    begin
      // These are the lumps that will be checked in IWAD,
      // if any one is not present, execution will be aborted.
      s_error := #13#10 + 'D_DoomMain(): This is not the registered version.';
      for i := 2 to 3 do
        for j := 1 to 9 do
          if W_CheckNumForName('e' + itoa(i) + 'm' + itoa(j)) < 0 then
            I_Error(s_error);
      if W_CheckNumForName('dphoof') < 0 then
        I_Error(s_error);
      if W_CheckNumForName('bfgga0') < 0 then
        I_Error(s_error);
      if W_CheckNumForName('heada1') < 0 then
        I_Error(s_error);
      if W_CheckNumForName('cybra1') < 0 then
        I_Error(s_error);
      if W_CheckNumForName('spida1d1') < 0 then
        I_Error(s_error);
    end;

    // If additonal PWAD files are used, print modified banner
    oldoutproc := outproc;
    outproc := @I_IOMessageBox;
    printf(MSG_MODIFIEDGAME);
    outproc := oldoutproc;
    printf(MSG_MODIFIEDGAME); // Print the message again to console
  end;

  case gamemode of
    shareware,
    indetermined:
      printf(MSG_SHAREWARE);
    registered,
    retail,
    commercial:
      printf(MSG_COMMERCIAL);
    else
    begin
      printf(MSG_UNDETERMINED);
    end;
  end;

  printf('M_Init: Init miscellaneous info.' + #13#10);
  M_Init;

  printf('R_Init: Init DOOM refresh daemon - ');
  R_Init;

  printf(#13#10 + 'P_Init: Init Playloop state.' + #13#10);
  P_Init;

  printf('I_Init: Setting up machine state.' + #13#10);
  I_Init;

  printf('D_CheckNetGame: Checking network game status.' + #13#10);
  D_CheckNetGame;

  printf('S_Init: Setting up sound.' + #13#10);
  S_Init(snd_SfxVolume, snd_MusicVolume);

  printf('HU_Init: Setting up heads up display.' + #13#10);
  HU_Init;

  printf('ST_Init: Init status bar.' + #13#10);
  ST_Init;

  // start the apropriate game based on parms
  p := M_CheckParm('-record');

  if (p <> 0) and (p < myargc - 1) then
  begin
    G_RecordDemo(myargv[p + 1]);
    autostart := True;
  end;

  p := M_CheckParm('-playdemo');
  if (p <> 0) and (p < myargc - 1) then
  begin
    singledemo := True;              // quit after one demo
    G_DeferedPlayDemo(myargv[p + 1]);
    D_DoomLoop;  // never returns
  end;

  p := M_CheckParm('-timedemo');
  if (p <> 0) and (p < myargc - 1) then
  begin
    G_TimeDemo(myargv[p + 1]);
    D_DoomLoop;  // never returns
  end;

  p := M_CheckParm('-loadgame');
  if (p <> 0) and (p <= myargc - 1) then
  begin
    if M_CheckParmCDROM then
    begin
      sprintf(_file, 'c:\doomdata\' + SAVEGAMENAME + '%s.dsg', [myargv[p + 1][1]]);
      G_LoadGame(_file);
    end
    else if p <> myargc - 1 then
    begin
      sprintf(_file, SAVEGAMENAME + '%s.dsg', [myargv[p + 1][1]]);
      G_LoadGame(_file);
    end;
  end;

  if gameaction <> ga_loadgame then
  begin
    if autostart or netgame then
      G_InitNew(startskill, startepisode, startmap)
    else
      D_StartTitle;                // start up intro loop
  end;

  D_DoomLoop;  // never returns
end;

var
  i: integer;

initialization
  for i := 0 to MAXWADFILES - 1 do
    wadfiles[i] := '';

end.
