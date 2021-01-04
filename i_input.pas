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

procedure I_ShutdownInput;

procedure I_SynchronizeInput(active: boolean);

var
  usedirectinput: boolean = False;

implementation

uses
  Windows,
  directx,
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
  g_pDI: IDirectInputA = nil;
  g_pdidKeyboard: IDirectInputDevice = nil;
  dikb: TDIKeyboardState; // DirectInput keyboard state buffer
  curkeys: PKeyboardState;
  oldkeys: PKeyboardState;

//-----------------------------------------------------------------------------
// Name: CreateDInput()
// Desc: Initialize the DirectInput variables using:
//           DirectInputCreate
//           IDirectInput::CreateDevice
//           IDirectInputDevice::SetDataFormat
//           IDirectInputDevice::SetCooperativeLevel
//-----------------------------------------------------------------------------
procedure I_InitInput;
var
  hres: HRESULT;

  procedure I_ErrorInitInput(const msg: string);
  begin
    I_Error('I_InitInput(): %s failed, result = %d', [msg, hres]);
  end;

begin
  if usedirectinput then
  begin
    // Register with the DirectInput subsystem and get a pointer
    // to a IDirectInput interface we can use
    hres := DirectInputCreate(hInstance, DIRECTINPUT_VERSION, g_pDI, nil);
    if hres <> DD_OK then
      I_ErrorInitInput('DirectInputCreate');

    // Obtain an interface to the keybord device
    hres := g_pDI.CreateDevice(GUID_SysKeyboard, g_pdidKeyboard, nil);
    if hres <> DD_OK then
      I_ErrorInitInput('CreateDevice');

    // Set the data format to "keyboard format". A data format specifies which
    // controls on a device we are interested in, and how they should be
    // reported. This tells DirectInput that we will be passing an array of 256
    // bytes to IDirectInputDevice::GetDeviceState().
    hres := g_pdidKeyboard.SetDataFormat(c_dfDIKeyboard);
    if hres <> DD_OK then
      I_ErrorInitInput('SetDataFormat');

    // Set the cooperative level to let DirectInput know how this device
    // should interact with the system and with other DirectInput applications.
    // Use DISCL_NONEXCLUSIVE to retrieve device data when acquired, not
    // interfering with any other applications which are reading mouse data.
    // Use DISCL_FOREGROUND so that if the user switches away from our app,
    // automatically release the device back to the system.
    hres := g_pdidKeyboard.SetCooperativeLevel(hMainWnd, DISCL_NONEXCLUSIVE or
      DISCL_FOREGROUND);
    if hres <> DD_OK then
      I_ErrorInitInput('SetCooperativeLevel');

  end;

  curkeys := I_AllocLow(SizeOf(TKeyboardState));
  oldkeys := I_AllocLow(SizeOf(TKeyboardState));

end;

//-----------------------------------------------------------------------------
// Name: I_ShutdownInput
// Desc: Terminate our usage of DirectInput
//-----------------------------------------------------------------------------
procedure I_ShutdownInput;
begin
  if usedirectinput then
  begin
    if g_pDI <> nil then
    begin
      // Destroy the keyboard object
      if g_pdidKeyboard <> nil then
      begin
        // Unacquire the device (just in case) before exitting.
        g_pdidKeyboard.Unacquire;
        g_pdidKeyboard._Release;
      end;

      // Destroy the DInput object
      g_pDI._Release;
    end;
  end;

  FreeMem(curkeys);
  FreeMem(oldkeys);
end;

//-----------------------------------------------------------------------------
// Name: I_ProcessInput;
// Desc: The game plays here. Read keyboard data and displaying it.
//-----------------------------------------------------------------------------
procedure I_ProcessInput;

  function DIKEYtoVK(Key: byte): integer;
  begin
    Result := 0;
    case Key of
      DIK_ESCAPE: Result := VK_ESCAPE;
      DIK_1: Result := Ord('1');
      DIK_2: Result := Ord('2');
      DIK_3: Result := Ord('3');
      DIK_4: Result := Ord('4');
      DIK_5: Result := Ord('5');
      DIK_6: Result := Ord('6');
      DIK_7: Result := Ord('7');
      DIK_8: Result := Ord('8');
      DIK_9: Result := Ord('9');
      DIK_0: Result := Ord('0');
      DIK_EQUALS: Result := Ord('=');
      DIK_BACK: Result := VK_BACK;
      DIK_TAB: Result := VK_TAB;
      DIK_Q: Result := Ord('Q');
      DIK_W: Result := Ord('W');
      DIK_E: Result := Ord('E');
      DIK_R: Result := Ord('R');
      DIK_T: Result := Ord('T');
      DIK_Y: Result := Ord('Y');
      DIK_U: Result := Ord('U');
      DIK_I: Result := Ord('I');
      DIK_O: Result := Ord('O');
      DIK_P: Result := Ord('P');
      DIK_LBRACKET: Result := Ord('[');
      DIK_RBRACKET: Result := Ord(']');
      DIK_RETURN: Result := VK_RETURN;
      DIK_LCONTROL: Result := VK_CONTROL;
      DIK_A: Result := Ord('A');
      DIK_S: Result := Ord('S');
      DIK_D: Result := Ord('D');
      DIK_F: Result := Ord('F');
      DIK_G: Result := Ord('G');
      DIK_H: Result := Ord('H');
      DIK_J: Result := Ord('J');
      DIK_K: Result := Ord('K');
      DIK_L: Result := Ord('L');
      DIK_SEMICOLON: Result := Ord(';');
      DIK_APOSTROPHE: Result := Ord('''');
      DIK_LSHIFT: Result := VK_SHIFT;
      DIK_BACKSLASH: Result := Ord('\');
      DIK_Z: Result := Ord('Z');
      DIK_X: Result := Ord('X');
      DIK_C: Result := Ord('C');
      DIK_V: Result := Ord('V');
      DIK_B: Result := Ord('B');
      DIK_N: Result := Ord('N');
      DIK_M: Result := Ord('M');
      DIK_COMMA: Result := Ord(',');
      DIK_PERIOD: Result := Ord('.');
      DIK_SLASH: Result := Ord('/');
      DIK_RSHIFT: Result := VK_SHIFT;
      DIK_MULTIPLY: Result := Ord('*');
      DIK_LMENU: Result := VK_MENU;
      DIK_SPACE: Result := VK_SPACE;
      DIK_CAPITAL: Result := VK_CAPITAL;
      DIK_F1: Result := VK_F1;
      DIK_F2: Result := VK_F2;
      DIK_F3: Result := VK_F3;
      DIK_F4: Result := VK_F4;
      DIK_F5: Result := VK_F5;
      DIK_F6: Result := VK_F6;
      DIK_F7: Result := VK_F7;
      DIK_F8: Result := VK_F8;
      DIK_F9: Result := VK_F9;
      DIK_F10: Result := VK_F10;
      DIK_NUMLOCK: Result := VK_NUMLOCK;
      DIK_SCROLL: Result := VK_SCROLL;
      DIK_NUMPAD7: Result := VK_NUMPAD7;
      DIK_NUMPAD8: Result := VK_NUMPAD8;
      DIK_NUMPAD9: Result := VK_NUMPAD9;
      DIK_SUBTRACT: Result := VK_SUBTRACT;
      DIK_NUMPAD4: Result := VK_NUMPAD4;
      DIK_NUMPAD5: Result := VK_NUMPAD5;
      DIK_NUMPAD6: Result := VK_NUMPAD6;
      DIK_ADD: Result := VK_ADD;
      DIK_NUMPAD1: Result := VK_NUMPAD1;
      DIK_NUMPAD2: Result := VK_NUMPAD2;
      DIK_NUMPAD3: Result := VK_NUMPAD3;
      DIK_NUMPAD0: Result := VK_NUMPAD0;
      DIK_DECIMAL: Result := VK_DECIMAL;
      DIK_F11: Result := VK_F11;
      DIK_F12: Result := VK_F12;
      DIK_NUMPADENTER: Result := VK_RETURN;
      DIK_RCONTROL: Result := VK_CONTROL;
      DIK_DIVIDE: Result := VK_DIVIDE;
      DIK_RMENU: Result := VK_MENU;
      DIK_HOME: Result := VK_HOME;
      DIK_UP: Result := VK_UP;
      DIK_PRIOR: Result := VK_PRIOR;
      DIK_LEFT: Result := VK_LEFT;
      DIK_RIGHT: Result := VK_RIGHT;
      DIK_END: Result := VK_END;
      DIK_DOWN: Result := VK_DOWN;
      DIK_NEXT: Result := VK_NEXT;
      DIK_INSERT: Result := VK_INSERT;
      DIK_DELETE: Result := VK_DELETE;
      DIK_LWIN: Result := VK_LWIN;
      DIK_RWIN: Result := VK_RWIN;
      DIK_APPS: Result := VK_APPS;
    end;
  end;

var
  hres: HRESULT;
  i: integer;
  ev: event_t;
  key: integer;
  p: PKeyboardState;
begin
  if I_GameFinished then
    exit;

  // VJ -> DirectInput does not work
  if usedirectinput and (g_pdidKeyboard <> nil) then
  begin
    hres := g_pdidKeyboard.GetDeviceState(SizeOf(dikb), dikb);
    if hres = DIERR_INPUTLOST then
    begin
      // DirectInput is telling us that the input stream has been
      // interrupted. Re-acquire and try again.
      hres := g_pdidKeyboard.Acquire;
      if hres = DD_OK then
        I_ProcessInput;
      exit;
    end;

    //  The DirectInput key code is converted into the Windows virtual key code.
    for i := Low(dikb) to High(dikb) do
      if dikb[i] and $80 <> 0 then
        curkeys[byte(DIKEYtoVK(i))] := $80;
  end
  else
    GetKeyboardState(curkeys^);

  ZeroMemory(ev, SizeOf(ev));

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
  if usedirectinput and (g_pdidKeyboard <> nil) then
  begin
    if active then
      g_pdidKeyboard.Acquire
    else
      g_pdidKeyboard.Unacquire;
  end;
end;

end.
