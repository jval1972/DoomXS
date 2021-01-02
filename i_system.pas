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

unit i_system;

interface

uses d_delphi,
  d_ticcmd, d_event;

{
    i_system.h, i_system.c
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
  {	System specific interface stuff. }
  { }
  {----------------------------------------------------------------------------- }

procedure I_Init;

{ Called by startup code }
{ to get the ammount of memory to malloc }
{ for the zone management. }
function I_ZoneBase(var size: integer): pointer;

{ Called by D_DoomLoop, }
{ returns current time in tics. }
function I_GetTime: integer;

{ }
{ Called by D_DoomLoop, }
{ called before processing any tics in a frame }
{ (just after displaying a frame). }
{ Time consuming syncronous operations }
{ are performed here (joystick reading). }
{ Can call D_PostEvent. }
{ }
procedure I_StartFrame;

{ }
{ Called by D_DoomLoop, }
{ called before processing each tic in a frame. }
{ Quick syncronous operations are performed here. }
{ Can call D_PostEvent. }
procedure I_StartTic;

{ Asynchronous interrupt functions should maintain private queues }
{ that are read by the synchronous functions }
{ to be converted into events. }
{ Either returns a null ticcmd, }
{ or calls a loadable driver to build it. }
{ This ticcmd will then be modified by the gameloop }
{ for normal input. }
function I_BaseTiccmd: Pticcmd_t;

{ Called by M_Responder when quit is selected. }
{ Clean exit, displays sell blurb. }
procedure I_Quit;

procedure I_Destroy;

{ Allocates from low memory under dos, }
{ just mallocs under unix, win32 }
function I_AllocLow(length: integer): pointer;

procedure I_Error(const error: string; const Args: array of const); overload;

procedure I_Error(const error: string); overload;

procedure I_ProcessWindows;

function I_GameFinished: boolean;

procedure I_WaitVBL(const count: integer);

var
  mb_used: integer = 6;

implementation

uses Windows, Messages,
  doomdef, m_misc,
  i_main, i_video, i_sound, i_music, i_input, i_io,
  d_net, g_game;

var
  finished: boolean = false;

function I_GameFinished: boolean;
begin
  result := finished;
end;

procedure I_ProcessWindows;
var
  msg: TMsg;
begin
  while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do
  begin
    if msg.message <> WM_QUIT then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
end;

//
// I_StartFrame
//
procedure I_StartFrame;
begin
  I_ProcessWindows;
  I_ProcessMusic;
  I_ProcessInput;
end;

//
// I_StartTic
//
procedure I_StartTic;
begin
//  if not InBackground then   // VJ ?
//    I_ProcessInput;          // VJ ?
end;

var
  emptycmd: ticcmd_t;

function I_BaseTiccmd: Pticcmd_t;
begin
  result := @emptycmd;
end;

function I_GetHeapSize: integer;
begin
  result := mb_used * 1024 * 1024;
end;

function I_ZoneBase(var size: integer): pointer;
begin
  size := I_GetHeapSize;
  result := malloc(size);
end;

//
// I_GetTime
// returns time in 1/70th second tics
//
var
  basetime: int64;
  Freq: int64;

function I_GetTime: integer;
var
  _time: int64;
begin
  if Freq = 1000 then
    _time := GetTickCount
  else
  begin
    if not QueryPerformanceCounter(_time) then
      _time := GetTickCount;
  end;
  if basetime = 0 then
    basetime := _time;
  result := round(((_time - basetime) / Freq) * TICRATE);
end;

//
// I_Init
//
procedure I_Init;
begin
  printf('I_InitSound: Initializing DirectSound.' + #13#10);
  I_InitSound;
  printf('I_InitMusic: Initializing music.' + #13#10);
  I_InitMusic;
  printf('I_InitInput: Initializing DirectInput.' + #13#10);
  I_InitInput;
end;

//
// I_Quit
//
procedure I_Quit;
begin
//  finished := true;
  PostMessage(hMainWnd, WM_DESTROY, 0, 0);
end;

procedure I_Destroy;
begin
  finished := true;
  D_QuitNetGame;
//  I_ShutdownSound;
  I_ShutdownMusic;
  I_ShutdownInput;
  M_SaveDefaults;
//  I_ShutdownGraphics;
  I_ShutdownIO;
  Halt(0);
end;

// Wait for vertical retrace or pause a bit.
procedure I_WaitVBL(const count: integer);
begin
  sleep(count);
end;

function I_AllocLow(length: integer): pointer;
begin
  result := malloc(length);
  memset(result, 0, length);
end;

//
// I_Error
//
procedure I_Error(const error: string; const Args: array of const);
var
  soutproc: TOutProc;
begin
  fprintf(stderr, 'I_Error: ');
  fprintf(stderr, error, Args);
  fprintf(stderr, #13#10);

  // Shutdown. Here might be other errors.
  if G_IsDemoRecording then
    G_CheckDemoStatus;

  soutproc := outproc;
  outproc := I_IOErrorMessageBox;
  printf(error, Args);
  outproc := soutproc;

  I_Destroy;
end;

procedure I_Error(const error: string);
begin
  I_Error(error, []);
end;

initialization
  basetime := 0;

  if not QueryPerformanceFrequency(Freq) then
    Freq := 1000;

end.
