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

unit i_main;

interface

uses Windows,
    d_delphi;

{
    i_main.c
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
  {   Main program, simply calls D_DoomMain high level loop. }
  {  }
  {----------------------------------------------------------------------------- }

var
  hMainWnd: HWND = 0;

const
  AppTitle = 'Delphi Doom';

procedure DoomMain;

implementation

uses Messages,
  doomdef, d_main,
  i_input, i_system,
  m_argv;

function WindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;
begin
  if not I_GameFinished then
  begin
    case Msg of
      WM_SETCURSOR:
        begin
          SetCursor(0);
        end;
      WM_SYSCOMMAND:
        begin
          if (wParam = SC_SCREENSAVE) then
          begin
            result := 0;
            exit;
          end;
        end;
      WM_ACTIVATE:
        begin
          I_SynchronizeInput(wparam <> WA_INACTIVE);
        end;
      WM_CLOSE:
        begin
          result := 0; // Preserve closing window by pressing Alt + F4
          exit;
        end;
      WM_DESTROY:
        begin
          I_Destroy;
        end;
    end;
  end;

  result := DefWindowProc(hWnd, Msg, WParam, LParam);
end;

procedure DoomMain;
var
  WindowClass: TWndClass;
begin
  ZeroMemory(WindowClass, SizeOf(WindowClass));
  WindowClass.lpfnWndProc := @WindowProc;
  WindowClass.hbrBackground := GetStockObject(WHITE_BRUSH);
  WindowClass.lpszClassName := 'Doom32';
  if HPrevInst = 0 then
  begin
    WindowClass.hInstance := HInstance;
    WindowClass.hIcon := LoadIcon(HInstance, 'MAINICON');
    WindowClass.hCursor := LoadCursor(0, nil);
    if RegisterClass(WindowClass) = 0 then
      Halt(1);
  end;
  hMainWnd := CreateWindowEx(
    CS_HREDRAW or CS_VREDRAW,
    WindowClass.lpszClassName,
    AppTitle,
    WS_OVERLAPPED,
    0,
    0,
    SCREENWIDTH,
    SCREENHEIGHT,
    0,
    0,
    HInstance,
    nil);
  ShowWindow(hMainWnd, CmdShow);
  UpdateWindow(hMainWnd);
  D_DoomMain;
end;

end.