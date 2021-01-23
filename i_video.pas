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

unit i_video;

interface

uses
  SysUtils,
  Windows,
  d_delphi;

// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
procedure I_InitGraphics;


procedure I_ShutDownGraphics;

// Takes full 8 bit values.
procedure I_SetPalette(palette: PByteArray);

procedure I_FinishUpdate;

procedure I_ReadScreen(scr: PByteArray);

var
  fullscreen: boolean = True;

implementation

uses
  doomdef,
  directx,
  i_system,
  i_main,
  v_video;

var
  curpal: array[0..255] of LongWord;
  g_pDD: IDirectDraw7 = nil; // DirectDraw object
  g_pDDSPrimary: IDirectDrawSurface7 = nil;// DirectDraw primary surface
  g_pDDScreen: IDirectDrawSurface7 = nil;   // DirectDraw surface
  screen32: array[0..SCREENWIDTH * SCREENHEIGHT - 1] of LongWord;

var
  s_alttab_disabled: boolean = False;

procedure I_DisableAltTab;
var
  old: boolean;
begin
  if s_alttab_disabled then
    Exit;

  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if isLibrary then
      RegisterHotKey(0, $C000, MOD_ALT, VK_TAB)
    else
      RegisterHotKey(0, 0, MOD_ALT, VK_TAB);
  end
  else
    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @old, 0);

  s_alttab_disabled := True;
end;

procedure I_EnableAltTab;
var
  old: boolean;
begin
  if s_alttab_disabled then
  begin
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      if isLibrary then
        UnregisterHotKey(0, $C000)
      else
        UnregisterHotKey(0, 0);
    end
    else
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @old, 0);

    s_alttab_disabled := False;
  end;
end;

procedure I_ShutdownGraphics;
begin
  if g_pDD <> nil then
  begin
    if g_pDDSPrimary <> nil then
    begin
      g_pDDSPrimary._Release;
    end;
    g_pDD._Release;
  end;
  I_EnableAltTab;
end;

// I_FinishUpdate
procedure I_FinishUpdate;
var
  i: integer;
  srcrect: TRect;
  destrect: TRect;
  dest: PLongWord;
{$IFDEF TRUECOLOR}
  src: PInteger;
{$ELSE}
  src: PByte;
{$ENDIF}

begin
  if hMainWnd = 0 then
    exit;
  if screens[_FG] = nil then
    exit;

  begin
    dest := @screen32;
    src := @(screens[0]^);
    for i := 0 to SCREENWIDTH * SCREENHEIGHT - 1 do
    begin
      dest^ := curpal[src^];
      Inc(dest);
      Inc(src);
    end;
  end;

  srcrect.Left := 0;
  srcrect.Top := 0;
  srcrect.Right := SCREENWIDTH;
  srcrect.Bottom := SCREENHEIGHT;

  destrect.Left := 0;
  destrect.Top := 0;
  destrect.Right := GetSystemMetrics(SM_CXSCREEN);
  destrect.Bottom := GetSystemMetrics(SM_CYSCREEN);
  if g_pDDSPrimary.Blt(destrect, g_pDDScreen, srcrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
    g_pDDSPrimary.Restore;
end;


// Palette stuff.

// I_SetPalette
procedure I_SetPalette(palette: PByteArray);
var
  dest: PLongWord;
  src: PByteArray;
begin
  dest := @curpal[0];
  src := palette;
  while integer(src) < integer(@palette[256 * 3]) do
  begin
    dest^ := (LongWord(gammatable[usegamma, src[0]]) shl 16) or
      (LongWord(gammatable[usegamma, src[1]]) shl 8) or
      (LongWord(gammatable[usegamma, src[2]]));
    Inc(dest);
    incp(pointer(src), 3);
  end;
end;

// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
procedure I_InitGraphics;
var
  hres: HRESULT;
  ddsd: DDSURFACEDESC2;

  procedure I_ErrorInitGraphics(const proc: string);
  begin
    I_Error('I_InitGraphics(): %s failed, result = %d', [proc, hres]);
  end;

begin
  if g_pDD <> nil then
    exit;
  ///////////////////////////////////////////////////////////////////////////
  // Create the main DirectDraw object
  ///////////////////////////////////////////////////////////////////////////
  hres := DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('DirectDrawCreateEx');

  if fullscreen then
    SetWindowPos(hMainWnd, 0, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), SWP_SHOWWINDOW)
  else
    SetWindowPos(hMainWnd, 0, 0, 0, SCREENWIDTH, SCREENHEIGHT, SWP_SHOWWINDOW);

  hres := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_NORMAL);
  if hres <> DD_OK then
    I_ErrorInitGraphics('SetCooperativeLevel');

  ZeroMemory(ddsd, SizeOf(ddsd));
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
  hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('CreateSurface');

  ZeroMemory(ddsd, SizeOf(ddsd));
  ZeroMemory(ddsd.ddpfPixelFormat, SizeOf(ddsd.ddpfPixelFormat));

  ddsd.ddpfPixelFormat.dwSize := SizeOf(ddsd.ddpfPixelFormat);
  g_pDDSPrimary.GetPixelFormat(ddsd.ddpfPixelFormat);

  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_LPSURFACE or
    DDSD_PITCH or DDSD_PIXELFORMAT or DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;

  ddsd.dwWidth := SCREENWIDTH;
  ddsd.dwHeight := SCREENHEIGHT;
  ddsd.lPitch := 4 * SCREENWIDTH; // Display is true color
  ddsd.lpSurface := @screen32;

  hres := g_pDD.CreateSurface(ddsd, g_pDDScreen, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('CreateSurface');
end;

procedure I_ReadScreen(scr: PByteArray);
begin
  memcpy(scr, screens[_FG], SCREENWIDTH * SCREENHEIGHT);
end;

end.
