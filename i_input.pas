//------------------------------------------------------------------------------
//
//  DoomXS - A basic Windows source port of Doom
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2021-2022 by Jim Valavanis
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

unit i_input;

interface

procedure I_InitInput;

procedure I_ProcessInput;

procedure I_ShutDownInput;

procedure I_SynchronizeInput(active: boolean);

implementation

uses
  Windows,
  d_delphi,
  MMSystem, // For joystick support
  doomdef,
  d_event,
  d_main,
  i_main,
  i_system;

function TranslateKey(keycode: integer): integer;
begin
  case keycode of
    VK_LEFT, VK_NUMPAD4: Result := KEY_LEFTARROW;
    VK_RIGHT, VK_NUMPAD6: Result := KEY_RIGHTARROW;
    VK_DOWN, VK_NUMPAD2: Result := KEY_DOWNARROW;
    VK_UP, VK_NUMPAD8: Result := KEY_UPARROW;
    VK_ESCAPE: Result := KEY_ESCAPE;
    VK_RETURN: Result := KEY_ENTER;
    VK_TAB: Result := KEY_TAB;
    VK_SNAPSHOT: result := KEY_PRNT;
    VK_F1: Result := KEY_F1;
    VK_F2: Result := KEY_F2;
    VK_F3: Result := KEY_F3;
    VK_F4: Result := KEY_F4;
    VK_F5: Result := KEY_F5;
    VK_F6: Result := KEY_F6;
    VK_F7: Result := KEY_F7;
    VK_F8: Result := KEY_F8;
    VK_F9: Result := KEY_F9;
    VK_F10: Result := KEY_F10;
    VK_F11: Result := KEY_F11;
    VK_F12: Result := KEY_F12;
    189: Result := KEY_MINUS;
    187: Result := KEY_EQUALS;
    VK_BACK: Result := KEY_BACKSPACE;
    VK_PAUSE: Result := KEY_PAUSE;
    VK_NUMPAD3: Result := KEY_PAGEDOWN;
    VK_NUMPAD9: Result := KEY_PAGEUP;
    VK_NUMPAD0: Result := KEY_INS;
    else
      if (keycode >= Ord('A')) and (keycode <= Ord('Z')) then
        Result := Ord(tolower(Chr(keycode)))
      else if keycode < 128 then
        Result := keycode
      else
        Result := 0;
  end;
end;

function TranslateSysKey(keycode: integer): integer;
begin
  case keycode of
    VK_SHIFT: Result := KEY_RSHIFT;
    VK_CONTROL: Result := KEY_RCTRL;
    VK_MENU: Result := KEY_RALT;
    else
      Result := 0;
  end;
end;

var
  curkeys: PKeyboardState;
  oldkeys: PKeyboardState;
// Mouse support
  mlastx,
  mlasty: integer;
  mflags: byte;
// Joystick support
  jInfo: TJoyInfoEx;
  jPresent: boolean;
  jwXpos: UINT;
  jwYpos: UINT;

type
  setcursorposfunc_t = function(x, y:Integer): BOOL; stdcall;
  getcursorposfunc_t = function(var lpPoint: TPoint): BOOL; stdcall;

var
  getcursorposfunc: getcursorposfunc_t;
  setcursorposfunc: setcursorposfunc_t;
  user32inst: THandle;

procedure I_InitMouse;
begin
  user32inst := LoadLibrary(user32);
  getcursorposfunc := GetProcAddress(user32inst, 'GetPhysicalCursorPos');
  if not assigned(getcursorposfunc) then
    getcursorposfunc := GetProcAddress(user32inst, 'GetCursorPos');
  setcursorposfunc := GetProcAddress(user32inst, 'SetPhysicalCursorPos');
  if not assigned(setcursorposfunc) then
    setcursorposfunc := GetProcAddress(user32inst, 'SetCursorPos');
end;

procedure I_ShutDownMouse;
begin
  FreeLibrary(user32inst);
end;

procedure I_ResetMouse;
begin
  mlastx := SCREENWIDTH div 2;
  mlasty := SCREENHEIGHT div 2;
  setcursorposfunc(mlastx, mlasty);
  mflags := 0;
end;

procedure I_InitInput;
begin
  curkeys := malloc(SizeOf(TKeyboardState));
  oldkeys := malloc(SizeOf(TKeyboardState));

  I_InitMouse;
  I_ResetMouse;
  printf(' Mouse initialized'#13#10);

  jPresent := joyGetNumDevs > 0;
  if jPresent then
    jPresent := joySetCapture(hMainWnd, JOYSTICKID1, 0, False) = JOYERR_NOERROR;

  // Get initial joystic position
  if jPresent then
  begin
    ZeroMemory(@jInfo, SizeOf(TJoyInfoEx));
    jInfo.dwSize := SizeOf(TJoyInfoEx);
    jInfo.dwFlags := JOY_RETURNALL;
    if joyGetPosEx(JOYSTICKID1, @jInfo) = JOYERR_NOERROR then
    begin
      jwXpos := jInfo.wXpos;
      jwYpos := jInfo.wYpos;
    end;
    printf(' Joystick initialized'#13#10);
  end
  else
    printf(' Joystick not found'#13#10);

end;

procedure I_ShutDownInput;
begin
  FreeMem(curkeys);
  FreeMem(oldkeys);

  joyReleaseCapture(JOYSTICKID1);

  I_ShutDownMouse;
end;

var
  input_active: boolean;

procedure I_ProcessInput;
var
  i: integer;
  ev: event_t;
  key: integer;
  p: PKeyboardState;
  pt: TPoint;
begin
  if I_GameFinished or not input_active then
    Exit;

  GetKeyboardState(curkeys^);

  ZeroMemory(@ev, SizeOf(ev));

  for i := 0 to SizeOf(curkeys^) - 1 do
  begin
    if (oldkeys[i] and $80) <> (curkeys[i] and $80) then
    begin
      key := TranslateKey(i);
      if key <> 0 then
      begin
        if curkeys[i] and $80 <> 0 then
          ev.typ := ev_keydown
        else
          ev.typ := ev_keyup;
        ev.data1 := key;
        D_PostEvent(@ev);
      end;

      key := TranslateSysKey(i);
      if key <> 0 then
      begin
        if curkeys[i] and $80 <> 0 then
          ev.typ := ev_keydown
        else
          ev.typ := ev_keyup;
        ev.data1 := key;
        D_PostEvent(@ev);
      end;
    end;
  end;

  p := oldkeys;
  oldkeys := curkeys;
  curkeys := p;

// Mouse
  if GetKeyState(VK_LBUTTON) < 0 then
    mflags := mflags or 1;
  if GetKeyState(VK_RBUTTON) < 0 then
    mflags := mflags or 2;
  if GetKeyState(VK_MBUTTON) < 0 then
    mflags := mflags or 4;

  getcursorposfunc(pt);

  ev.typ := ev_mouse;
  ev.data1 := mflags;
  ev.data2 := mlastx - pt.x;
  ev.data3 := mlasty - pt.y;
  D_PostEvent(@ev);

  I_ResetMouse;

// Joystick
  if jPresent then
  begin
    ZeroMemory(@jInfo, SizeOf(TJoyInfoEx));
    jInfo.dwSize := SizeOf(TJoyInfoEx);
    jInfo.dwFlags := JOY_RETURNALL;
    if joyGetPosEx(JOYSTICKID1, @jInfo) = JOYERR_NOERROR then
    begin
      ev.typ := ev_joystick;
      if jInfo.dwButtonNumber > 0 then
        ev.data1 := jInfo.wButtons and ((1 shl NUMJOYBUTTONS) - 1) // Only first NUMJOYBUTTONS buttons of joystic in use
      else
        ev.data1 := 0;
      ev.data2 := jInfo.wXpos - jwXpos;
      ev.data3 := jInfo.wYpos - jwYpos;
      D_PostEvent(@ev);
    end;
  end;
end;

procedure I_SynchronizeInput(active: boolean);
begin
  input_active := active;
end;

end.
