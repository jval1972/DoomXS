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

unit i_midi;

interface

procedure I_PlayMidi;

procedure I_StopMidi;

procedure AddMidiFileToPlayList(MidiFile: string);

function I_IsMidiPlaying: boolean;

procedure I_ResumeMidi;

procedure I_PauseMidi;

function _mciGetErrorString(const code: LongWord): string;

var
  MidiFileName: string;

implementation

uses
  d_delphi,
  Windows,
  Messages,
  MMSystem;

var
  wDeviceID: DWORD;
  Window: HWnd;
  fIsPlaying: boolean;
  WindowClass: TWndClass;

const
  rsAppName = 'MIDIPLAYERWNDNOTIFY';
  rsSequencer = 'sequencer';
  rsWndTitle = 'Notify Window';
  rsErrNoMIDIMapper = 'MIDI mapper unavailable';

// Plays a specified MIDI file by using MCI_OPEN and MCI_PLAY. Returns
// as soon as playback begins. The window procedure function for the
// specified window will be notified when playback is complete.
// Returns 0L on success; otherwise, it returns an MCI error code.
function playMIDIFile(hWndNotify: HWnd; lpszMIDIFileName: string;
  doCheckMidiMapper: boolean = False): DWORD;
var
  mciOpenParms: MCI_OPEN_PARMS;
  mciPlayParms: MCI_PLAY_PARMS;
  mciStatusParms: MCI_STATUS_PARMS;
begin
  // Open the device by specifying the device and filename.
  // MCI will attempt to choose the MIDI mapper as the output port.
  FillChar(mciOpenParms, SizeOf(mciOpenParms), Chr(0));
  mciOpenParms.lpstrDeviceType := PAnsiChar(rssequencer);
  mciOpenParms.lpstrElementName := PChar(lpszMIDIFileName);
  Result := mciSendCommand(0, MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,
    DWORD(@mciOpenParms));
  // Failed to open device. Don't close it; just return error.
  if Result <> 0 then
    exit;

  // The device opened successfully; get the device ID.
  wDeviceID := mciOpenParms.wDeviceID;

  if doCheckMidiMapper then
  begin
    // Check if the output port is the MIDI mapper.
    mciStatusParms.dwItem := MCI_SEQ_STATUS_PORT;
    Result := mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM,
      DWORD(@mciStatusParms));
    if Result <> 0 then
    begin
      mciSendCommand(wDeviceID, MCI_CLOSE, 0, 0);
      exit;
    end
    else if LOWORD(mciStatusParms.dwReturn) <> word(MIDI_MAPPER) then
      // The output port is not the MIDI mapper.
    begin
      printf(rsErrNoMIDIMapper);
      exit;
    end;
  end;

  // Begin playback. The window procedure function for the parent
  // window will be notified with an MM_MCINOTIFY message when
  // playback is complete. At this time, the window procedure closes
  // the device.
  FillChar(mciPlayParms, SizeOf(mciPlayParms), Chr(0));
  mciPlayParms.dwCallback := DWORD(hWndNotify);
  Result := mciSendCommand(wDeviceID, MCI_PLAY, MCI_NOTIFY, DWORD(@mciPlayParms));
  if Result > 0 then
    mciSendCommand(wDeviceID, MCI_CLOSE, 0, 0);
end;

procedure StopPlaying;
begin
  mciSendCommand(wDeviceID, MCI_STOP, 0, 0);
  mciSendCommand(wDeviceID, MCI_CLOSE, 0, 0);
end;

function WindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
  stdcall; export;
begin
  Result := 0;
  case Msg of
    MM_MCINOTIFY:
      if (wParam = MCI_NOTIFY_SUCCESSFUL) then
      begin
        StopPlaying;
        playMIDIFile(Window, MidiFileName);
      end;
    WM_CLOSE:
    begin
      DestroyWindow(hWnd);
      Window := 0;
      exit;
    end;
  end;
  Result := DefWindowProc(hWnd, Msg, WParam, LParam);
end;

procedure AddMidiFileToPlayList(MidiFile: string);
begin
  MidiFileName := MidiFile;
end;

procedure I_PlayMidi;
begin
  I_StopMidi;
  FillChar(WindowClass, SizeOf(WindowClass), Chr(0));
  if Window = 0 then
  begin
    WindowClass.style := CS_DBLCLKS;
    WindowClass.lpfnWndProc := @WindowProc;
    WindowClass.lpszClassName := PChar(rsAppName);
    if HPrevInst = 0 then
    begin
      WindowClass.hInstance := HInstance;
      WindowClass.hCursor := LoadCursor(0, idc_Arrow);
      RegisterClass(WindowClass);
    end;
    Window := CreateWindowEx(0, WindowClass.lpszClassName,
      PChar(rsWndTitle), ws_OverlappedWindow, integer(CW_USEDEFAULT),
      integer(CW_USEDEFAULT), integer(CW_USEDEFAULT),
      integer(CW_USEDEFAULT), 0, 0, HInstance, nil);
    ShowWindow(Window, SW_HIDE);
  end;

  playMIDIFile(Window, MidiFileName, True);
end;

procedure I_StopMidi;
begin
  if Window <> 0 then
  begin
    StopPlaying;
    SendMessage(Window, WM_CLOSE, 0, 0);
    Window := 0;
    fIsPlaying := False;
  end;
end;

function I_IsMidiPlaying: boolean;
begin
  Result := fIsPlaying;
end;

procedure I_ResumeMidi;
begin
  mciSendCommand(wDeviceID, MCI_RESUME, 0, 0);
end;

procedure I_PauseMidi;
begin
  mciSendCommand(wDeviceID, MCI_PAUSE, 0, 0);
end;

function _mciGetErrorString(const code: LongWord): string;
var
  buf: array[0..127] of char;
  i: integer;
begin
  Result := '';
  FillChar(buf, 128, Chr(0));
  if mciGetErrorString(code, buf, 128) then
    for i := 0 to 127 do
    begin
      if buf[i] = #0 then
        break;
      Result := Result + buf[i];
    end;
end;

initialization
  Window := 0;
  fIsPlaying := False;

finalization
  StopPlaying;

end.
