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

unit m_menu;

interface

uses d_event;

{
    m_menu.h, m_menu.c
}

  { Emacs style mode select   -*- C++ -*-  }
  {----------------------------------------------------------------------------- }
  { }
  { $Id:$ }
  { }
  { Copyright (C) 1993-1996 by id Software, Inc. }
  { }
  { This source is available for distribution and/or modification }
  { only under the terms of the DOOM Source Code License as }
  { published by id Software. All rights reserved. }
  { }
  { The source is distributed in the hope that it will be useful, }
  { but WITHOUT ANY WARRANTY; without even the implied warranty of }
  { FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License }
  { for more details. }
  { }
  { DESCRIPTION: }
  {   Menu widget stuff, episode selection and such. }
  {     }
  {----------------------------------------------------------------------------- }

  { }
  { MENUS }
  { }

{ Called by main loop, }
{ saves config file and calls I_Quit when user exits. }
{ Even when the menu is not displayed, }
{ this can resize the view and change game parameters. }
{ Does all the real work of the menu interaction. }

function M_Responder(ev: Pevent_t): boolean;

{ Called by main loop, }
{ only used for menu (skull cursor) animation. }
procedure M_Ticker;

{ Called by main loop, }
{ draws the menus directly into the screen buffer. }
procedure M_Drawer;

{ Called by D_DoomMain, }
{ loads the config file. }
procedure M_Init;

{ Called by intro code to force menu up upon a keypress, }
{ does nothing if menu is already up. }
procedure M_StartControlPanel;

var
//
// defaulted values
//
  mouseSensitivity: integer;  // has default

// Show messages has default, 0 = off, 1 = on
  showMessages: integer;

  menuactive: boolean;

  inhelpscreens: boolean;

// Blocky mode, has default, 0 = high, 1 = normal
  detailLevel: integer;
  screenblocks: integer;  // has default

procedure M_InitMenus;

implementation

uses d_delphi,
  doomdef,
  am_map,
  dstrings, d_englsh,
  d_main, d_player,
  g_game,
  m_argv,
  i_system, i_io, i_video,
  r_main,
  z_zone,
  v_video,
  w_wad,
  hu_stuff,
  s_sound,
  doomstat,
// Data.
  sounds;

var
// temp for screenblocks (0-9)
  screenSize: integer;

// -1 = no quicksave slot picked!
  quickSaveSlot: integer;

 // 1 = message to be printed
  messageToPrint: integer;
// ...and here is the message string!
  messageString: string;

  messageLastMenuActive: boolean;

// timed message = no input from user
  messageNeedsInput: boolean;

type
  PmessageRoutine = function(i: integer): pointer;

var
  messageRoutine: PmessageRoutine;

const
  SAVESTRINGSIZE = 24;

var
  gammamsg: array[0..4] of string;

// we are going to be entering a savegame string
  saveStringEnter: integer;
  saveSlot: integer;  // which slot to save in
  saveCharIndex: integer; // which char we're editing
// old save description before edit
  saveOldString: string;

const
  SKULLXOFF = -32;
  LINEHEIGHT = 16;

var
  savegamestrings: array[0..9] of string;
  endstring: string;

type
  menuitem_t = record
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    status: smallint;

    name: string[10];

    // choice = menu item #.
    // if status = 2,
    //   choice=0:leftarrow,1:rightarrow
    routine: PmessageRoutine;

    // hotkey in menu
    alphaKey: char;
  end;
  Pmenuitem_t = ^menuitem_t;
  menuitem_tArray = packed array[0..$FFFF] of menuitem_t;
  Pmenuitem_tArray = ^menuitem_tArray;

  Pmenu_t = ^menu_t;
  menu_t = record
    numitems: smallint; // # of menu items
    prevMenu:Pmenu_t;   // previous menu
    menuitems: Pmenuitem_tArray;  // menu items
    routine: PProcedure;  // draw routine
    x: smallint;
    y: smallint;		// x,y of menu
    lastOn: smallint; // last item user was on in menu
  end;

var
  itemOn: smallint; // menu item skull is on
  skullAnimCounter: smallint; // skull animation counter
  whichSkull: smallint; // which skull to draw

// graphic name of skulls
// warning: initializer-string for array of chars is too long
  skullName: array[0..1] of string;

// current menudef
  currentMenu: Pmenu_t;

//
// PROTOTYPES
//
procedure M_NewGame(choice: integer); forward;
procedure M_Episode(choice: integer); forward;
procedure M_ChooseSkill(choice: integer); forward;
procedure M_LoadGame(choice: integer); forward;
procedure M_SaveGame(choice: integer); forward;
procedure M_Options(choice: integer); forward;
procedure M_EndGame(choice: integer); forward;
procedure M_ReadThis(choice: integer); forward;
procedure M_ReadThis2(choice: integer); forward;
procedure M_QuitDOOM(choice: integer); forward;

procedure M_ChangeMessages(choice: integer); forward;
procedure M_ChangeSensitivity(choice: integer); forward;
procedure M_SfxVol(choice: integer); forward;
procedure M_MusicVol(choice: integer); forward;
procedure M_ChangeDetail(choice: integer); forward;
procedure M_SizeDisplay(choice: integer); forward;
procedure M_Sound(choice: integer); forward;

procedure M_FinishReadThis(choice: integer); forward;
procedure M_LoadSelect(choice: integer); forward;
procedure M_SaveSelect(choice: integer); forward;
procedure M_ReadSaveStrings; forward;
procedure M_QuickSave; forward;
procedure M_QuickLoad; forward;

procedure M_DrawMainMenu; forward;
procedure M_DrawReadThis1; forward;
procedure M_DrawReadThis2; forward;
procedure M_DrawNewGame; forward;
procedure M_DrawEpisode; forward;
procedure M_DrawOptions; forward;
procedure M_DrawSound; forward;
procedure M_DrawLoad; forward;
procedure M_DrawSave; forward;

procedure M_DrawSaveLoadBorder(x, y: integer); forward;
procedure M_SetupNextMenu(menudef: Pmenu_t); forward;
procedure M_DrawThermo(x, y, thermWidth, thermDot: integer); forward;
procedure M_DrawEmptyCell(menu: Pmenu_t; item: integer); forward;
procedure M_DrawSelCell(menu: Pmenu_t; item: integer); forward;
procedure M_WriteText(x, y: integer;const _string: string); forward;
function  M_StringWidth(const _string: string): integer; forward;
function  M_StringHeight(const _string: string): integer; forward;
procedure M_StartMessage(const _string: string; routine: PmessageRoutine; input: boolean); forward;
procedure M_StopMessage; forward;
procedure M_ClearMenus; forward;

type
//
// DOOM MENU
//
  main_e = (
    newgame,
    options,
    loadgame,
    savegame,
    readthis,
    quitdoom,
    main_end
  );

var
  MainMenu: array[0..5] of menuitem_t;
  MainDef: menu_t;

type
//
// EPISODE SELECT
//
  episodes_e = (
    ep1,
    ep2,
    ep3,
    ep4,
    ep_end
  );

var
  EpisodeMenu: array[0..3] of menuitem_t;
  EpiDef: menu_t;

type
//
// NEW GAME
//
  newgame_e = (
    killthings,
    toorough,
    hurtme,
    violence,
    nightmare,
    newg_end
  );

var
  NewGameMenu: array[0..4] of menuitem_t;
  NewDef: menu_t;

type
//
// OPTIONS MENU
//
  options_e = (
    endgame,
    messages,
    detail,
    scrnsize,
    option_empty1,
    mousesens,
    option_empty2,
    soundvol,
    opt_end
  );

var
  OptionsMenu: array[0..7] of menuitem_t;
  OptionsDef: menu_t;

type
//
// Read This! MENU 1 & 2
//
  read_e = (
    rdthsempty1,
    read1_end
  );

var
  ReadMenu1: array[0..0] of menuitem_t;
  ReadDef1: menu_t;

type
  read_e2 = (
    rdthsempty2,
    read2_end
  );

var
  ReadMenu2: array[0..0] of menuitem_t;
  ReadDef2: menu_t;

type
//
// SOUND VOLUME MENU
//
  sound_e = (
    sfx_vol,
    sfx_empty1,
    music_vol,
    sfx_empty2,
    sound_end
  );

var
  SoundMenu: array[0..3] of menuitem_t;
  SoundDef: menu_t;

type
//
// LOAD GAME MENU
//
  load_e = (
    load1,
    load2,
    load3,
    load4,
    load5,
    load6,
    load_end
  );

var
  LoadMenu: array[0..5] of menuitem_t;
  LoadDef: menu_t;
  SaveMenu: array[0..5] of menuitem_t;
  SaveDef: menu_t;

//
// M_ReadSaveStrings
//  read the strings from the savegame files
//
procedure M_ReadSaveStrings;
var
  handle: file;
  i: integer;
  name: string;
begin
  for i := 0 to Ord(load_end) - 1 do
  begin
    if M_CheckParmCDROM then
      sprintf(name, 'c:\doomdata\' + SAVEGAMENAME + '%d.dsg', [i])
    else
      sprintf(name, SAVEGAMENAME + '%d.dsg', [i]);

    assign(handle, name);
    {$I-}
    reset(handle, 1);
    {$I+}
    if IOResult <> 0 then
    begin
      savegamestrings[i] := '';
      LoadMenu[i].status := 0;
      continue;
    end;
    SetLength(savegamestrings[i], SAVESTRINGSIZE);
    BlockRead(handle, (@savegamestrings[i][1])^, SAVESTRINGSIZE);
    close(handle);
    LoadMenu[i].status := 1;
  end;
end;

//
// M_LoadGame & Cie.
//
procedure M_DrawLoad;
var
  i: integer;
begin
  V_DrawPatch(72, 28, _FG, W_CacheLumpName('M_LOADG', PU_CACHE), true);
  for i := 0 to Ord(load_end) - 1 do
  begin
    M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + LINEHEIGHT * i);
    M_WriteText(LoadDef.x, LoadDef.y + LINEHEIGHT * i, savegamestrings[i]);
  end;
end;

//
// Draw border for the savegame description
//
procedure M_DrawSaveLoadBorder(x, y: integer);
var
  i: integer;
begin
  V_DrawPatch(x - 8, y + 7, _FG, W_CacheLumpName('M_LSLEFT', PU_CACHE), true);

  for i := 0 to 23 do
  begin
    V_DrawPatch (x, y + 7, _FG, W_CacheLumpName('M_LSCNTR', PU_CACHE), true);
    x := x + 8;
  end;

  V_DrawPatch(x, y + 7, _FG, W_CacheLumpName('M_LSRGHT', PU_CACHE), true);
end;

//
// User wants to load this game
//
procedure M_LoadSelect(choice: integer);
var
  name: string;
begin
  if M_CheckParmCDROM then
    sprintf(name, 'c:\doomdata\' + SAVEGAMENAME + '%d.dsg', [choice])
  else
    sprintf(name,SAVEGAMENAME + '%d.dsg', [choice]);
  G_LoadGame(name);
  M_ClearMenus;
end;

//
// Selected from DOOM menu
//
procedure M_LoadGame(choice: integer);
begin
  if netgame then
  begin
    M_StartMessage(LOADNET, nil, false);
    exit;
  end;

  M_SetupNextMenu(@LoadDef);
  M_ReadSaveStrings;
end;

//
//  M_SaveGame & Cie.
//
procedure M_DrawSave;
var
  i: integer;
begin
  V_DrawPatch(72, 28, _FG, W_CacheLumpName('M_SAVEG', PU_CACHE), true);
  for i := 0 to Ord(load_end) - 1 do
  begin
    M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + LINEHEIGHT * i);
    M_WriteText(LoadDef.x, LoadDef.y + LINEHEIGHT * i, savegamestrings[i]);
  end;

  if saveStringEnter <> 0 then
  begin
    i := M_StringWidth(savegamestrings[saveSlot]);
    M_WriteText(LoadDef.x + i, LoadDef.y + LINEHEIGHT * saveSlot, '_');
  end;
end;

//
// M_Responder calls this when user is finished
//
procedure M_DoSave(slot: integer);
begin
  G_SaveGame(slot, savegamestrings[slot]);
  M_ClearMenus;

  // PICK QUICKSAVE SLOT YET?
  if (quickSaveSlot = -2) then
    quickSaveSlot := slot;
end;

//
// User wants to save. Start string input for M_Responder
//
procedure M_SaveSelect(choice: integer);
begin
  // we are going to be intercepting all chars
  saveStringEnter := 1;

  saveSlot := choice;
  saveOldString := savegamestrings[choice];
  if savegamestrings[choice] <> '' then
    savegamestrings[choice] := '';
  saveCharIndex := Length(savegamestrings[choice]);
end;

//
// Selected from DOOM menu
//
procedure M_SaveGame(choice: integer);
begin
  if not usergame then
  begin
    M_StartMessage(SAVEDEAD, nil, false);
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  M_SetupNextMenu(@SaveDef);
  M_ReadSaveStrings;
end;

//
//      M_QuickSave
//
var
  tempstring: string;

procedure M_QuickSaveResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_DoSave(quickSaveSlot);
    S_StartSound(nil, Ord(sfx_swtchx));
  end;
end;

procedure M_QuickSave;
begin
  if not usergame then
  begin
    S_StartSound(nil, Ord(sfx_oof));
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  if quickSaveSlot < 0 then
  begin
    M_StartControlPanel;
    M_ReadSaveStrings;
    M_SetupNextMenu(@SaveDef);
    quickSaveSlot := -2;	// means to pick a slot now
    exit;
  end;
  sprintf(tempstring, QSPROMPT, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickSaveResponse, true);
end;

//
// M_QuickLoad
//
procedure M_QuickLoadResponse(ch: integer);
begin
  if ch = ord('y') then
  begin
    M_LoadSelect(quickSaveSlot);
    S_StartSound(nil, Ord(sfx_swtchx));
  end;
end;

procedure M_QuickLoad;
begin
  if netgame then
  begin
    M_StartMessage(QLOADNET, nil, false);
    exit;
  end;

  if quickSaveSlot < 0 then
  begin
    M_StartMessage(QSAVESPOT, nil, false);
    exit;
  end;
  sprintf(tempstring, QLPROMPT, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickLoadResponse, true);
end;

//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
procedure M_DrawReadThis1;
begin
  inhelpscreens := true;
  case gamemode of
    commercial:
      V_DrawPatch(0, 0, _FG, W_CacheLumpName('HELP', PU_CACHE), true);
    shareware,
    registered,
    retail:
      V_DrawPatch(0, 0, _FG, W_CacheLumpName('HELP1', PU_CACHE), true);
  end;
end;

//
// Read This Menus - optional second page.
//
procedure M_DrawReadThis2;
begin
  inhelpscreens := true;
  case gamemode of
    retail,
    commercial:
      // This hack keeps us from having to change menus.
      V_DrawPatch(0, 0, _FG, W_CacheLumpName('CREDIT', PU_CACHE), true);
    shareware,
    registered:
      V_DrawPatch(0, 0, _FG, W_CacheLumpName('HELP2', PU_CACHE), true);
  end;
end;

//
// Change Sfx & Music volumes
//
procedure M_DrawSound;
begin
  V_DrawPatch(60, 38, _FG, W_CacheLumpName('M_SVOL', PU_CACHE), true);

  M_DrawThermo(
    SoundDef.x, SoundDef.y + LINEHEIGHT * (Ord(sfx_vol) + 1), 16, snd_SfxVolume);

  M_DrawThermo(
    SoundDef.x, SoundDef.y + LINEHEIGHT * (Ord(music_vol) + 1), 16, snd_MusicVolume);
end;

procedure M_Sound(choice: integer);
begin
  M_SetupNextMenu(@SoundDef);
end;

procedure M_SfxVol(choice: integer);
begin
  case choice of
    0: if snd_SfxVolume <> 0 then dec(snd_SfxVolume);
    1: if snd_SfxVolume < 15 then inc(snd_SfxVolume);
  end;
  S_SetSfxVolume(snd_SfxVolume);
end;

procedure M_MusicVol(choice: integer);
begin
  case choice of
    0: if snd_MusicVolume <> 0 then dec(snd_MusicVolume);
    1: if snd_MusicVolume < 15 then inc(snd_MusicVolume);
  end;
  S_SetMusicVolume(snd_MusicVolume);
end;

//
// M_DrawMainMenu
//
procedure M_DrawMainMenu;
begin
  V_DrawPatch(94, 2, _FG, W_CacheLumpName('M_DOOM', PU_CACHE), true);
end;

//
// M_NewGame
//
procedure M_DrawNewGame;
begin
  V_DrawPatch(96, 14, _FG, W_CacheLumpName('M_NEWG', PU_CACHE), true);
  V_DrawPatch(54, 38, _FG, W_CacheLumpName('M_SKILL', PU_CACHE), true);
end;

procedure M_NewGame(choice: integer);
begin
  if netgame and (not demoplayback) then
  begin
    M_StartMessage(SNEWGAME, nil, false);
    exit;
  end;

  if gamemode = commercial then
    M_SetupNextMenu(@NewDef)
  else
    M_SetupNextMenu(@EpiDef);
end;

//
//      M_Episode
//
var
  epi: integer;

procedure M_DrawEpisode;
begin
  V_DrawPatch(54, 38, _FG, W_CacheLumpName('M_EPISOD', PU_CACHE), true);
end;

procedure M_VerifyNightmare(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  G_DeferedInitNew(sk_nightmare, epi + 1, 1); // VJ nightmare become sk_nightmare
  M_ClearMenus;
end;

procedure M_ChooseSkill(choice: integer);
begin
  if choice = Ord(nightmare) then
  begin
    M_StartMessage(SNIGHTMARE, @M_VerifyNightmare, true);
    exit;
  end;

  G_DeferedInitNew(skill_t(choice), epi + 1, 1);
  M_ClearMenus;
end;

procedure M_Episode(choice: integer);
begin
  if (gamemode = shareware) and boolval(choice) then
  begin
    M_StartMessage(SWSTRING, nil, false);
    M_SetupNextMenu(@ReadDef1);
    exit;
  end;

  // Yet another hack...
  if (gamemode = registered) and (choice > 2) then
  begin
    fprintf(stderr, 'M_Episode(): 4th episode requires UltimateDOOM' + #13#10);
    choice := 0;
  end;

  epi := choice;
  M_SetupNextMenu(@NewDef);
end;

//
// M_Options
//
var
  detailNames: array[0..1] of string;
  msgNames: array[0..1] of string;

procedure M_DrawOptions;
begin
  V_DrawPatch(108, 15, _FG, W_CacheLumpName('M_OPTTTL', PU_CACHE), true);

  V_DrawPatch(OptionsDef.x + 175, OptionsDef.y + LINEHEIGHT * Ord(detail), _FG,
      W_CacheLumpName(detailNames[detailLevel], PU_CACHE), true);

  V_DrawPatch(OptionsDef.x + 120, OptionsDef.y + LINEHEIGHT * Ord(messages), _FG,
      W_CacheLumpName(msgNames[showMessages], PU_CACHE), true);

  M_DrawThermo(
    OptionsDef.x, OptionsDef.y + LINEHEIGHT * (Ord(mousesens) + 1), 10, mouseSensitivity);

  M_DrawThermo(
    OptionsDef.x, OptionsDef.y + LINEHEIGHT * (Ord(scrnsize) + 1), 9, screenSize);
end;

procedure M_Options(choice: integer);
begin
  M_SetupNextMenu(@OptionsDef);
end;

//
//      Toggle messages on/off
//
procedure M_ChangeMessages(choice: integer);
begin
  showMessages := 1 - showMessages;

  if not boolval(showMessages) then
    players[consoleplayer]._message := MSGOFF
  else
    players[consoleplayer]._message := MSGON;

  message_dontfuckwithme := true;
end;

//
// M_EndGame
//
procedure M_EndGameResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  currentMenu.lastOn := itemOn;
  M_ClearMenus;
  D_StartTitle;
end;

procedure M_EndGame(choice: integer);
begin
  if not usergame then
  begin
    S_StartSound(nil, Ord(sfx_oof));
    exit;
  end;

  if netgame then
  begin
    M_StartMessage(NETEND, nil, false);
    exit;
  end;

  M_StartMessage(SENDGAME, @M_EndGameResponse, true);
end;

//
// M_ReadThis
//
procedure M_ReadThis(choice: integer);
begin
  M_SetupNextMenu(@ReadDef1);
end;

procedure M_ReadThis2(choice: integer);
begin
  M_SetupNextMenu(@ReadDef2);
end;

procedure M_FinishReadThis(choice: integer);
begin
  M_SetupNextMenu(@MainDef);
end;

//
// M_QuitDOOM
//
const
  quitsounds: array[0..7] of integer = (
    Ord(sfx_pldeth),
    Ord(sfx_dmpain),
    Ord(sfx_popain),
    Ord(sfx_slop),
    Ord(sfx_telept),
    Ord(sfx_posit1),
    Ord(sfx_posit3),
    Ord(sfx_sgtatk)
  );

  quitsounds2: array[0..7] of integer = (
    Ord(sfx_vilact),
    Ord(sfx_getpow),
    Ord(sfx_boscub),
    Ord(sfx_slop),
    Ord(sfx_skeswg),
    Ord(sfx_kntdth),
    Ord(sfx_bspact),
    Ord(sfx_sgtatk)
  );


procedure M_QuitResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;
  if not netgame then
  begin
    if gamemode = commercial then
      S_StartSound(nil, quitsounds2[_SHR(gametic, 2) and 7])
    else
      S_StartSound(nil, quitsounds[_SHR(gametic, 2) and 7]);
//    I_WaitVBL(105);
    I_WaitVBL(1000);
  end;
  I_Quit;
end;

procedure M_QuitDOOM(choice: integer);
begin
  // We pick index 0 which is language sensitive,
  //  or one at random, between 1 and maximum number.
  if language <> english then
    sprintf(endstring, '%s' + #13#10#13#10 + DOSY, [endmsg[0]])
  else
    sprintf(endstring,'%s' + #13#10#13#10 + DOSY, [endmsg[(gametic mod (NUM_QUITMESSAGES - 2)) + 1]]);

  M_StartMessage(endstring, @M_QuitResponse, true);
end;

procedure M_ChangeSensitivity(choice: integer);
begin
  case choice of
    0: if mouseSensitivity <> 0 then dec(mouseSensitivity);
    1: if mouseSensitivity < 9 then inc(mouseSensitivity);
  end;
end;

procedure M_ChangeDetail(choice: integer);
begin
// FIXME - does not work. Remove anyway?
{  fprintf(stderr, 'M_ChangeDetail(): low detail mode n.a.' + #13#10);
  exit;}

  detailLevel := 1 - detailLevel;


  R_SetViewSize(screenblocks, detailLevel);

  if not boolval(detailLevel) then
    players[consoleplayer]._message := DETAILHI
  else
    players[consoleplayer]._message := DETAILLO;

end;

procedure M_SizeDisplay(choice: integer);
begin
  case choice of
    0:
      begin
        if screenSize > 0 then
        begin
          dec(screenblocks);
          dec(screenSize);
        end;
      end;
    1:
      begin
        if screenSize < 8 then
        begin
          inc(screenblocks);
          inc(screenSize);
        end;
      end;
  end;

  R_SetViewSize(screenblocks, detailLevel);
end;

//
//      Menu Functions
//
procedure M_DrawThermo(x, y, thermWidth, thermDot: integer);
var
  xx: integer;
  i: integer;
begin
  xx := x;
  V_DrawPatch(xx, y, _FG, W_CacheLumpName('M_THERML', PU_CACHE), true);
  xx := xx + 8;
  for i := 0 to thermWidth - 1 do
  begin
    V_DrawPatch(xx, y, _FG, W_CacheLumpName('M_THERMM', PU_CACHE), true);
    xx := xx + 8;
  end;
  V_DrawPatch(xx, y, _FG, W_CacheLumpName('M_THERMR', PU_CACHE), true);

  V_DrawPatch((x + 8) + thermDot * 8, y, _FG,
    W_CacheLumpName('M_THERMO', PU_CACHE), true);
end;

procedure M_DrawEmptyCell(menu: Pmenu_t; item: integer);
begin
  V_DrawPatch(menu.x - 10, menu.y + item * LINEHEIGHT - 1, _FG,
    W_CacheLumpName('M_CELL1', PU_CACHE), true);
end;

procedure M_DrawSelCell(menu: Pmenu_t; item: integer);
begin
  V_DrawPatch(menu.x - 10, menu.y + item * LINEHEIGHT - 1, _FG,
    W_CacheLumpName('M_CELL2', PU_CACHE), true);
end;

procedure M_StartMessage(const _string: string; routine: PmessageRoutine; input: boolean);
begin
  messageLastMenuActive := menuactive;
  messageToPrint := 1;
  messageString := _string;
  if Assigned(routine) then
    @messageRoutine := @routine
  else
    messageRoutine := nil;
  messageNeedsInput := input;
  menuactive := true;
end;

procedure M_StopMessage;
begin
  menuactive := messageLastMenuActive;
  messageToPrint := 0;
end;

//
// Find string width from hu_font chars
//
function  M_StringWidth(const _string: string): integer;
var
  i: integer;
  c: integer;
begin
  result := 0;
  for i := 1 to Length(_string) do
  begin
    c := Ord(toupper(_string[i])) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
      result := result + 4
    else
      result := result + hu_font[c].width;
  end;
end;

//
//      Find string height from hu_font chars
//
function  M_StringHeight(const _string: string): integer;
var
  i: integer;
  height: integer;
begin
  height := hu_font[0].height;

  result := height;
  for i := 1 to Length(_string) do
    if _string[i] = #13 then
	    result := result + height;
end;

//
//      Write a string using the hu_font
//
procedure M_WriteText(x, y: integer;const _string: string);
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(_string);
  if len = 0 then
    exit;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;
      
    c := Ord(_string[ch]);
    inc(ch);

    if not boolval(c) then
	    break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
	    cy := cy + 12;
	    continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
    begin
      cx := cx + 4;
	    continue;
    end;

    w := hu_font[c].width;
//    if (cx + w) > SCREENWIDTH then
    if (cx + w) > 320 then
      break;
    V_DrawPatch(cx, cy, _FG, hu_font[c], true);
    cx := cx + w;
  end;
end;

//
// CONTROL PANEL
//

//
// M_Responder
//
var
  joywait: integer;
  mousewait: integer;
  mousey: integer;
  lasty: integer;
  mousex: integer;
  lastx: integer;

function M_Responder(ev: Pevent_t): boolean;
var
  ch: integer;
  i: integer;
begin
  ch := -1;

  if (ev._type = ev_joystick) and (joywait < I_GetTime) then
  begin
    if ev.data3 = -1 then
    begin
      ch := KEY_UPARROW;
	    joywait := I_GetTime + 5;
    end
    else if ev.data3 = 1 then
    begin
      ch := KEY_DOWNARROW;
      joywait := I_GetTime + 5;
    end;

    if ev.data2 = -1 then
    begin
      ch := KEY_LEFTARROW;
	    joywait := I_GetTime + 2;
    end
    else if ev.data2 = 1 then
    begin
      ch := KEY_RIGHTARROW;
      joywait := I_GetTime + 2;
    end;

    if boolval(ev.data1 and 1) then
    begin
      ch := KEY_ENTER;
      joywait := I_GetTime + 5;
    end;
    if boolval(ev.data1 and 2) then
    begin
      ch := KEY_BACKSPACE;
      joywait := I_GetTime + 5;
    end;
  end
  else if (ev._type = ev_mouse) and (mousewait < I_GetTime) then
  begin
    mousey := mousey + ev.data3;
    if mousey < lasty - 30 then
    begin
      ch := KEY_DOWNARROW;
      mousewait := I_GetTime + 5;
      lasty := lasty - 30;
      mousey := lasty;
    end
    else if mousey > lasty + 30 then
    begin
      ch := KEY_UPARROW;
      mousewait := I_GetTime + 5;
      lasty := lasty + 30;
      mousey := lasty;
    end;

    mousex := mousex + ev.data2;
    if mousex < lastx - 30 then
    begin
      ch := KEY_LEFTARROW;
      mousewait := I_GetTime + 5;
      lastx := lastx - 30;
      mousex := lastx;
    end
    else if mousex > lastx + 30 then
    begin
      ch := KEY_RIGHTARROW;
      mousewait := I_GetTime + 5;
      lastx := lastx + 30;
      mousex := lastx;
    end;

    if boolval(ev.data1 and 1) then
    begin
      ch := KEY_ENTER;
      mousewait := I_GetTime + 15;
    end;

    if boolval(ev.data1 and 2) then
    begin
      ch := KEY_BACKSPACE;
      mousewait := I_GetTime + 15;
    end
  end
	else if ev._type = ev_keydown then
    ch := ev.data1;

  if ch = -1 then
  begin
    result := false;
    exit;
  end;

  // Save Game string input
  if boolval(saveStringEnter) then
  begin
    case ch of
      KEY_BACKSPACE:
        begin
          if saveCharIndex > 0 then
          begin
            dec(saveCharIndex);
            SetLength(savegamestrings[saveSlot], saveCharIndex);
          end;
        end;
      KEY_ESCAPE:
        begin
          saveStringEnter := 0;
          savegamestrings[saveSlot] := saveOldString;
        end;
      KEY_ENTER:
        begin
          saveStringEnter := 0;
          if savegamestrings[saveSlot] <> '' then
            M_DoSave(saveSlot);
        end
    else
      begin
        ch := Ord(toupper(Chr(ch)));
        if ch <> 32 then
        if (ch - Ord(HU_FONTSTART) < 0) or (ch - Ord(HU_FONTSTART) >= HU_FONTSIZE) then
        else
        begin
          if (ch >= 32) and (ch <= 127) and
             (saveCharIndex < SAVESTRINGSIZE - 1) and
             (M_StringWidth(savegamestrings[saveSlot]) < (SAVESTRINGSIZE - 2) * 8) then
          begin
            inc(saveCharIndex);
            savegamestrings[saveSlot] := savegamestrings[saveSlot] + Chr(ch);
          end;
        end;
      end;
    end;
    result := true;
    exit;
  end;

  // Take care of any messages that need input
  if boolval(messageToPrint) then
  begin
    if messageNeedsInput and ( not(
	    (ch = Ord(' ')) or (ch = Ord('n')) or (ch = Ord('y')) or (ch = KEY_ESCAPE))) then
    begin
      result := false;
      exit;
    end;

    menuactive := messageLastMenuActive;
    messageToPrint := 0;
    if Assigned(messageRoutine) then
      messageRoutine(ch);

    result := true;

    if I_GameFinished then
      exit;
      
    menuactive := false;
    S_StartSound(nil, Ord(sfx_swtchx));
    exit;
  end;

  if devparm and (ch = KEY_F1) then
  begin
    G_ScreenShot;
    result := true;
    exit;
  end;

  // F-Keys
  if not menuactive then
    case ch of
      KEY_MINUS:    // Screen size down
        begin
          if automapactive or chat_on then
          begin
            result := false;
            exit;
          end;
          M_SizeDisplay(0);
          S_StartSound(nil, Ord(sfx_stnmov));
          result := true;
          exit;
        end;
      KEY_EQUALS:   // Screen size up
        begin
          if automapactive or chat_on then
          begin
            result := false;
            exit;
          end;
          M_SizeDisplay(1);
          S_StartSound(nil, Ord(sfx_stnmov));
          result := true;
          exit;
        end;
      KEY_F1:      // Help key
        begin
          M_StartControlPanel;
          if gamemode = retail then
            currentMenu := @ReadDef2
          else
            currentMenu := @ReadDef1;

          itemOn := 0;
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      KEY_F2:  // Save
        begin
          M_StartControlPanel;
          S_StartSound(nil, Ord(sfx_swtchn));
          M_SaveGame(0);
          result := true;
          exit;
        end;
      KEY_F3:  // Load
        begin
          M_StartControlPanel;
          S_StartSound(nil, Ord(sfx_swtchn));
          M_LoadGame(0);
          result := true;
          exit;
        end;
      KEY_F4:   // Sound Volume
        begin
          M_StartControlPanel;
          currentMenu := @SoundDef;
          itemOn := Ord(sfx_vol);
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      KEY_F5:   // Detail toggle
        begin
          M_ChangeDetail(0);
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      KEY_F6:   // Quicksave
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_QuickSave;
          result := true;
          exit;
        end;
      KEY_F7:   // End game
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_EndGame(0);
          result := true;
          exit;
        end;
      KEY_F8:   // Toggle messages
        begin
          M_ChangeMessages(0);
          S_StartSound(nil, Ord(sfx_swtchn));
          result := true;
          exit;
        end;
      KEY_F9:   // Quickload
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_QuickLoad;
          result := true;
          exit;
        end;
      KEY_F10:  // Quit DOOM
        begin
          S_StartSound(nil, Ord(sfx_swtchn));
          M_QuitDOOM(0);
          result := true;
          exit;
        end;
      KEY_F11:  // gamma toggle
        begin
          inc(usegamma);
          if usegamma > 4 then
            usegamma := 0;
          players[consoleplayer]._message := gammamsg[usegamma];
          I_SetPalette(W_CacheLumpName('PLAYPAL', PU_CACHE));
          result := true;
          exit;
        end;
    end;

  // Pop-up menu?
  if not menuactive then
  begin
    if ch = KEY_ESCAPE then
    begin
      M_StartControlPanel;
      S_StartSound(nil, Ord(sfx_swtchn));
	    result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  // Keys usable within menu
  case ch of
    KEY_DOWNARROW:
      begin
        repeat
          if itemOn + 1 > currentMenu.numitems - 1 then
            itemOn := 0
          else
            inc(itemOn);
          S_StartSound(nil, Ord(sfx_pstop));
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_UPARROW:
      begin
        repeat
          if not boolval(itemOn) then
            itemOn := currentMenu.numitems - 1
          else
            dec(itemOn);
          S_StartSound(nil, Ord(sfx_pstop));
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_LEFTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          S_StartSound(nil, Ord(sfx_stnmov));
          currentMenu.menuitems[itemOn].routine(0);
        end;
        result := true;
        exit;
      end;
    KEY_RIGHTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          S_StartSound(nil, Ord(sfx_stnmov));
          currentMenu.menuitems[itemOn].routine(1);
        end;
        result := true;
        exit;
      end;
    KEY_ENTER:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          boolval(currentMenu.menuitems[itemOn].status) then
        begin
          currentMenu.lastOn := itemOn;
          if currentMenu.menuitems[itemOn].status = 2 then
          begin
            currentMenu.menuitems[itemOn].routine(1); // right arrow
            S_StartSound(nil, Ord(sfx_stnmov));
          end
          else
          begin
            currentMenu.menuitems[itemOn].routine(itemOn);
            S_StartSound(nil, Ord(sfx_pistol));
          end;
        end;
        result := true;
        exit;
      end;
    KEY_ESCAPE:
      begin
        currentMenu.lastOn := itemOn;
        M_ClearMenus;
        S_StartSound(nil, Ord(sfx_swtchx));
        result := true;
        exit;
      end;
    KEY_BACKSPACE:
      begin
        currentMenu.lastOn := itemOn;
        if currentMenu.prevMenu <> nil then
        begin
          currentMenu := currentMenu.prevMenu;
          itemOn := currentMenu.lastOn;
          S_StartSound(nil, Ord(sfx_swtchn));
        end;
        result := true;
        exit;
      end;
  else
    begin
      for i := itemOn + 1 to currentMenu.numitems - 1 do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          S_StartSound(nil, Ord(sfx_pstop));
          result := true;
          exit;
        end;
      for i := 0 to itemOn do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          S_StartSound(nil, Ord(sfx_pstop));
          result := true;
          exit;
        end;
    end;
  end;
  
  result := false;
end;

//
// M_StartControlPanel
//
procedure M_StartControlPanel;
begin
  // intro might call this repeatedly
  if menuactive then
    exit;

  menuactive := true;
  currentMenu := @MainDef;// JDC
  itemOn := currentMenu.lastOn; // JDC
end;

//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//
var
  x, y: smallint;

procedure M_Drawer;
var
  i: smallint;
  max: smallint;
  _string: string;
  len: integer;
begin
  inhelpscreens := false;

  // Horiz. & Vertically center string and print it.
  if boolval(messageToPrint) then
  begin
//    y := (SCREENHEIGHT - M_StringHeight(messageString)) div 2;
    y := (200 - M_StringHeight(messageString)) div 2;
    len := Length(messageString);
    _string := '';
    for i := 1 to len do
    begin
      if messageString[i] = #13 then
        y := y + hu_font[0].height
      else if messageString[i] = #10 then
      begin
//        x := (SCREENWIDTH - M_StringWidth(_string)) div 2;
        x := (320 - M_StringWidth(_string)) div 2;
        M_WriteText(x, y, _string);
        _string := '';
      end
      else
        _string := _string + messageString[i];
    end;
    if _string <> '' then
    begin
//      x := (SCREENWIDTH - M_StringWidth(_string)) div 2;
      x := (320 - M_StringWidth(_string)) div 2;
      y := y + hu_font[0].height;
      M_WriteText(x, y, _string);
    end;
    exit;
  end;

  if not menuactive then
    exit;

  if Assigned(currentMenu.routine) then
    currentMenu.routine; // call Draw routine

  // DRAW MENU
  x := currentMenu.x;
  y := currentMenu.y;
  max := currentMenu.numitems;

  for i := 0 to max - 1 do
  begin
    if currentMenu.menuitems[i].name <> '' then
      V_DrawPatch(x, y, _FG,
        W_CacheLumpName(currentMenu.menuitems[i].name, PU_CACHE), true);
    y := y + LINEHEIGHT;
  end;

  // DRAW SKULL
  V_DrawPatch(x + SKULLXOFF, currentMenu.y - 5 + itemOn * LINEHEIGHT, _FG,
    W_CacheLumpName(skullName[whichSkull], PU_CACHE), true);
end;

//
// M_ClearMenus
//
procedure M_ClearMenus;
begin
  menuactive := false;
    // if (!netgame && usergame && paused)
    //       sendpause = true;
end;

//
// M_SetupNextMenu
//
procedure M_SetupNextMenu(menudef: Pmenu_t);
begin
  currentMenu := menudef;
  itemOn := currentMenu.lastOn;
end;

//
// M_Ticker
//
procedure M_Ticker;
begin
  dec(skullAnimCounter);
  if skullAnimCounter <= 0 then
  begin
    whichSkull := whichSkull xor 1;
    skullAnimCounter := 8;
  end;
end;

//
// M_Init
//
procedure M_Init;
begin
  currentMenu := @MainDef;
  menuactive := false;
  itemOn := currentMenu.lastOn;
  whichSkull := 0;
  skullAnimCounter := 10;
  screenSize := screenblocks - 3;
  messageToPrint := 0;
  messageString := '';
  messageLastMenuActive := menuactive;
  quickSaveSlot := -1;

  // Here we could catch other version dependencies,
  //  like HELP1/2, and four episodes.

  case gamemode of
    commercial:
      begin
        // This is used because DOOM 2 had only one HELP
        //  page. I use CREDIT as second page now, but
        //  kept this hack for educational purposes.
        MainMenu[Ord(readthis)] := MainMenu[Ord(quitdoom)];
        dec(MainDef.numitems);
        MainDef.y := MainDef.y + 8;
        NewDef.prevMenu := @MainDef;
        ReadDef1.routine := M_DrawReadThis1;
        ReadDef1.x := 330;
        ReadDef1.y := 165;
        ReadMenu1[0].routine := @M_FinishReadThis;
      end;
    shareware,
      // Episode 2 and 3 are handled,
      // branching to an ad screen.
    registered:
      begin
        // We need to remove the fourth episode.
        dec(EpiDef.numitems);
      end;
  end;
end;


procedure M_InitMenus;
begin
////////////////////////////////////////////////////////////////////////////////
//gammamsg
  gammamsg[0] := GAMMALVL0;
  gammamsg[1] := GAMMALVL1;
  gammamsg[2] := GAMMALVL2;
  gammamsg[3] := GAMMALVL3;
  gammamsg[4] := GAMMALVL4;

////////////////////////////////////////////////////////////////////////////////
//skullName
  skullName[0] := 'M_SKULL1';
  skullName[1] := 'M_SKULL2';

////////////////////////////////////////////////////////////////////////////////
// MainMenu
  MainMenu[0].status := 1;
  MainMenu[0].name := 'M_NGAME';
  MainMenu[0].routine := @M_NewGame;
  MainMenu[0].alphaKey := 'n';

  MainMenu[1].status := 1;
  MainMenu[1].name := 'M_OPTION';
  MainMenu[1].routine := @M_Options;
  MainMenu[1].alphaKey := 'o';

  MainMenu[2].status := 1;
  MainMenu[2].name := 'M_LOADG';
  MainMenu[2].routine := @M_LoadGame;
  MainMenu[2].alphaKey := 'l';

  MainMenu[3].status := 1;
  MainMenu[3].name := 'M_SAVEG';
  MainMenu[3].routine := @M_SaveGame;
  MainMenu[3].alphaKey := 's';

  // Another hickup with Special edition.
  MainMenu[4].status := 1;
  MainMenu[4].name := 'M_RDTHIS';
  MainMenu[4].routine := @M_ReadThis;
  MainMenu[4].alphaKey := 'r';

  MainMenu[5].status := 1;
  MainMenu[5].name := 'M_QUITG';
  MainMenu[5].routine := @M_QuitDOOM;
  MainMenu[5].alphaKey := 'q';

////////////////////////////////////////////////////////////////////////////////
//MainDef
  MainDef.numitems := ord(main_end);
  MainDef.prevMenu := nil;
  MainDef.menuitems := Pmenuitem_tArray(@MainMenu);
  MainDef.routine := @M_DrawMainMenu;  // draw routine
  MainDef.x := 97;
  MainDef.y := 64;
  MainDef.lastOn := 0;

////////////////////////////////////////////////////////////////////////////////
//EpisodeMenu
  EpisodeMenu[0].status := 1;
  EpisodeMenu[0].name := 'M_EPI1';
  EpisodeMenu[0].routine := @M_Episode;
  EpisodeMenu[0].alphaKey := 'k';

  EpisodeMenu[1].status := 1;
  EpisodeMenu[1].name := 'M_EPI2';
  EpisodeMenu[1].routine := @M_Episode;
  EpisodeMenu[1].alphaKey := 't';

  EpisodeMenu[2].status := 1;
  EpisodeMenu[2].name := 'M_EPI3';
  EpisodeMenu[2].routine := @M_Episode;
  EpisodeMenu[2].alphaKey := 'i';

  EpisodeMenu[3].status := 1;
  EpisodeMenu[3].name := 'M_EPI4';
  EpisodeMenu[3].routine := @M_Episode;
  EpisodeMenu[3].alphaKey := 't';

////////////////////////////////////////////////////////////////////////////////
//EpiDef
  EpiDef.numitems := Ord(ep_end); // # of menu items
  EpiDef.prevMenu := @MainDef; // previous menu
  EpiDef.menuitems := Pmenuitem_tArray(@EpisodeMenu);  // menu items
  EpiDef.routine := @M_DrawEpisode;  // draw routine
  EpiDef.x := 48;
  EpiDef.y := 63; // x,y of menu
  EpiDef.lastOn := Ord(ep1); // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//NewGameMenu
  NewGameMenu[0].status := 1;
  NewGameMenu[0].name := 'M_JKILL';
  NewGameMenu[0].routine := @M_ChooseSkill;
  NewGameMenu[0].alphaKey := 'i';

  NewGameMenu[1].status := 1;
  NewGameMenu[1].name := 'M_ROUGH';
  NewGameMenu[1].routine := @M_ChooseSkill;
  NewGameMenu[1].alphaKey := 'h';

  NewGameMenu[2].status := 1;
  NewGameMenu[2].name := 'M_HURT';
  NewGameMenu[2].routine := @M_ChooseSkill;
  NewGameMenu[2].alphaKey := 'h';

  NewGameMenu[3].status := 1;
  NewGameMenu[3].name := 'M_ULTRA';
  NewGameMenu[3].routine := @M_ChooseSkill;
  NewGameMenu[3].alphaKey := 'u';

  NewGameMenu[4].status := 1;
  NewGameMenu[4].name := 'M_NMARE';
  NewGameMenu[4].routine := @M_ChooseSkill;
  NewGameMenu[4].alphaKey := 'n';

////////////////////////////////////////////////////////////////////////////////
//NewDef
  NewDef.numitems := Ord(newg_end); // # of menu items
  NewDef.prevMenu := @EpiDef; // previous menu
  NewDef.menuitems := Pmenuitem_tArray(@NewGameMenu);  // menu items
  NewDef.routine := @M_DrawNewGame;  // draw routine
  NewDef.x := 48;
  NewDef.y := 63; // x,y of menu
  NewDef.lastOn := Ord(hurtme); // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//OptionsMenu
  OptionsMenu[0].status := 1;
  OptionsMenu[0].name := 'M_ENDGAM';
  OptionsMenu[0].routine := @M_EndGame;
  OptionsMenu[0].alphaKey := 'e';

  OptionsMenu[1].status := 1;
  OptionsMenu[1].name := 'M_MESSG';
  OptionsMenu[1].routine := @M_ChangeMessages;
  OptionsMenu[1].alphaKey := 'm';

  OptionsMenu[2].status := 1;
  OptionsMenu[2].name := 'M_DETAIL';
  OptionsMenu[2].routine := @M_ChangeDetail;
  OptionsMenu[2].alphaKey := 'g';

  OptionsMenu[3].status := 2;
  OptionsMenu[3].name := 'M_SCRNSZ';
  OptionsMenu[3].routine := @M_SizeDisplay;
  OptionsMenu[3].alphaKey := 's';

  OptionsMenu[4].status := -1;
  OptionsMenu[4].name := '';
  OptionsMenu[4].routine := nil;
  OptionsMenu[4].alphaKey := #0;

  OptionsMenu[5].status := 2;
  OptionsMenu[5].name := 'M_MSENS';
  OptionsMenu[5].routine := @M_ChangeSensitivity;
  OptionsMenu[5].alphaKey := 'm';

  OptionsMenu[6].status := -1;
  OptionsMenu[6].name := '';
  OptionsMenu[6].routine := nil;
  OptionsMenu[6].alphaKey := #0;

  OptionsMenu[7].status := 1;
  OptionsMenu[7].name := 'M_SVOL';
  OptionsMenu[7].routine := @M_Sound;
  OptionsMenu[7].alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//OptionsDef
  OptionsDef.numitems := Ord(opt_end); // # of menu items
  OptionsDef.prevMenu := @MainDef; // previous menu
  OptionsDef.menuitems := Pmenuitem_tArray(@OptionsMenu);  // menu items
  OptionsDef.routine := @M_DrawOptions;  // draw routine
  OptionsDef.x := 60;
  OptionsDef.y := 37; // x,y of menu
  OptionsDef.lastOn := 0; // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//ReadMenu1
  ReadMenu1[0].status := 1;
  ReadMenu1[0].name := '';
  ReadMenu1[0].routine := @M_ReadThis2;
  ReadMenu1[0].alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef1
  ReadDef1.numitems := Ord(read1_end); // # of menu items
  ReadDef1.prevMenu := @MainDef; // previous menu
  ReadDef1.menuitems := Pmenuitem_tArray(@ReadMenu1);  // menu items
  ReadDef1.routine := @M_DrawReadThis1;  // draw routine
  ReadDef1.x := 280;
  ReadDef1.y := 185; // x,y of menu
  ReadDef1.lastOn := 0; // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//ReadMenu2
  ReadMenu2[0].status := 1;
  ReadMenu2[0].name := '';
  ReadMenu2[0].routine := @M_FinishReadThis;
  ReadMenu2[0].alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef2
  ReadDef2.numitems := Ord(read2_end); // # of menu items
  ReadDef2.prevMenu := @ReadDef1; // previous menu
  ReadDef2.menuitems := Pmenuitem_tArray(@ReadMenu2);  // menu items
  ReadDef2.routine := @M_DrawReadThis2;  // draw routine
  ReadDef2.x := 330;
  ReadDef2.y := 175; // x,y of menu
  ReadDef2.lastOn := 0; // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//SoundMenu
  SoundMenu[0].status := 2;
  SoundMenu[0].name := 'M_SFXVOL';
  SoundMenu[0].routine := @M_SfxVol;
  SoundMenu[0].alphaKey := 's';

  SoundMenu[1].status := -1;
  SoundMenu[1].name := '';
  SoundMenu[1].routine := nil;
  SoundMenu[1].alphaKey := #0;

  SoundMenu[2].status := 2;
  SoundMenu[2].name := 'M_MUSVOL';
  SoundMenu[2].routine := @M_MusicVol;
  SoundMenu[2].alphaKey := 'm';

  SoundMenu[3].status := -1;
  SoundMenu[3].name := '';
  SoundMenu[3].routine := nil;
  SoundMenu[3].alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SoundDef
  SoundDef.numitems := Ord(sound_end); // # of menu items
  SoundDef.prevMenu := @OptionsDef; // previous menu
  SoundDef.menuitems := Pmenuitem_tArray(@SoundMenu);  // menu items
  SoundDef.routine := @M_DrawSound;  // draw routine
  SoundDef.x := 80;
  SoundDef.y := 64; // x,y of menu
  SoundDef.lastOn := 0; // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//LoadMenu
  LoadMenu[0].status := 1;
  LoadMenu[0].name := '';
  LoadMenu[0].routine := @M_LoadSelect;
  LoadMenu[0].alphaKey := '1';

  LoadMenu[1].status := 1;
  LoadMenu[1].name := '';
  LoadMenu[1].routine := @M_LoadSelect;
  LoadMenu[1].alphaKey := '2';

  LoadMenu[2].status := 1;
  LoadMenu[2].name := '';
  LoadMenu[2].routine := @M_LoadSelect;
  LoadMenu[2].alphaKey := '3';

  LoadMenu[3].status := 1;
  LoadMenu[3].name := '';
  LoadMenu[3].routine := @M_LoadSelect;
  LoadMenu[3].alphaKey := '4';

  LoadMenu[4].status := 1;
  LoadMenu[4].name := '';
  LoadMenu[4].routine := @M_LoadSelect;
  LoadMenu[4].alphaKey := '5';

  LoadMenu[5].status := 1;
  LoadMenu[5].name := '';
  LoadMenu[5].routine := @M_LoadSelect;
  LoadMenu[5].alphaKey := '6';

////////////////////////////////////////////////////////////////////////////////
//LoadDef
  LoadDef.numitems := Ord(load_end); // # of menu items
  LoadDef.prevMenu := @MainDef; // previous menu
  LoadDef.menuitems := Pmenuitem_tArray(@LoadMenu);  // menu items
  LoadDef.routine := @M_DrawLoad;  // draw routine
  LoadDef.x := 80;
  LoadDef.y := 54; // x,y of menu
  LoadDef.lastOn := 0; // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
//SaveMenu
  SaveMenu[0].status := 1;
  SaveMenu[0].name := '';
  SaveMenu[0].routine := @M_SaveSelect;
  SaveMenu[0].alphaKey := '1';

  SaveMenu[1].status := 1;
  SaveMenu[1].name := '';
  SaveMenu[1].routine := @M_SaveSelect;
  SaveMenu[1].alphaKey := '2';

  SaveMenu[2].status := 1;
  SaveMenu[2].name := '';
  SaveMenu[2].routine := @M_SaveSelect;
  SaveMenu[2].alphaKey := '3';

  SaveMenu[3].status := 1;
  SaveMenu[3].name := '';
  SaveMenu[3].routine := @M_SaveSelect;
  SaveMenu[3].alphaKey := '4';

  SaveMenu[4].status := 1;
  SaveMenu[4].name := '';
  SaveMenu[4].routine := @M_SaveSelect;
  SaveMenu[4].alphaKey := '5';

  SaveMenu[5].status := 1;
  SaveMenu[5].name := '';
  SaveMenu[5].routine := @M_SaveSelect;
  SaveMenu[5].alphaKey := '6';

////////////////////////////////////////////////////////////////////////////////
//SaveDef
  SaveDef.numitems := Ord(load_end); // # of menu items
  SaveDef.prevMenu := @MainDef; // previous menu
  SaveDef.menuitems := Pmenuitem_tArray(@SaveMenu);  // menu items
  SaveDef.routine := M_DrawSave;  // draw routine
  SaveDef.x := 80;
  SaveDef.y := 54; // x,y of menu
  SaveDef.lastOn := 0; // last item user was on in menu

////////////////////////////////////////////////////////////////////////////////
  detailNames[0] := 'M_GDHIGH';
  detailNames[1] := 'M_GDLOW';
  msgNames[0] := 'M_MSGOFF';
  msgNames[1] := 'M_MSGON';

////////////////////////////////////////////////////////////////////////////////
  joywait := 0;
  mousewait := 0;
  mousey := 0;
  lasty := 0;
  mousex := 0;
  lastx := 0;

end;

end.

