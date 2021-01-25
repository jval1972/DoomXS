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
  doomdef,
  d_event,
  d_main,
  i_main,
  i_system;

function TranslateKey(keycode: integer): integer;
begin
  case keycode of
    VK_LEFT,
    VK_NUMPAD4: Result := KEY_LEFTARROW;
    VK_RIGHT,
    VK_NUMPAD6: Result := KEY_RIGHTARROW;
    VK_DOWN,
    VK_NUMPAD2: Result := KEY_DOWNARROW;
    VK_UP,
    VK_NUMPAD8: Result := KEY_UPARROW;
    VK_ESCAPE: Result := KEY_ESCAPE;
    VK_RETURN: Result := KEY_ENTER;
    VK_TAB: Result := KEY_TAB;
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

procedure I_InitInput;
begin
  curkeys := malloc(SizeOf(TKeyboardState));
  oldkeys := malloc(SizeOf(TKeyboardState));
end;

procedure I_ShutDownInput;
begin
  FreeMem(curkeys);
  FreeMem(oldkeys);
end;

procedure I_ProcessInput;
var
  i: integer;
  ev: event_t;
  key: integer;
  p: PKeyboardState;
begin
  if I_GameFinished then
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
          ev._type := ev_keydown
        else
          ev._type := ev_keyup;
        ev.data1 := key;
        D_PostEvent(@ev);
      end;

      key := TranslateSysKey(i);
      if key <> 0 then
      begin
        if curkeys[i] and $80 <> 0 then
          ev._type := ev_keydown
        else
          ev._type := ev_keyup;
        ev.data1 := key;
        D_PostEvent(@ev);
      end;
    end;
  end;

  p := oldkeys;
  oldkeys := curkeys;
  curkeys := p;
end;

procedure I_SynchronizeInput(active: boolean);
begin
end;

end.
