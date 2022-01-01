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

unit f_wipe;

interface

procedure wipe_StartScreen;

procedure wipe_EndScreen;

function wipe_Ticker(ticks: integer): boolean;

implementation

uses
  doomdef,
  d_delphi,
  m_rnd,
  m_fixed,
  i_video,
  v_video,
  z_memory;

// SCREEN WIPE PACKAGE

var
  wipe_scr_start: PByteArray;
  wipe_scr_end: PByteArray;

procedure wipe_shittyColMajorXform(_array: PByteArray; width, height: integer);
var
  x, y: integer;
  dest: PByteArray;
begin
  dest := Z_Malloc(width * height, PU_STATIC, nil);

  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
      dest[x * height + y] := _array[y * width + x];

  memcpy(_array, dest, width * height);

  Z_Free(dest);
end;

var
  yy: Pfixed_tArray;
  vy: fixed_t;

procedure wipe_initMelt;
var
  i, r: integer;
  SHEIGHTS: array[0..SCREENWIDTH - 1] of integer;
  RANDOMS: array[0..319] of byte;
begin
  for i := 0 to SCREENWIDTH - 1 do
    SHEIGHTS[i] := Trunc(i * 320 / SCREENWIDTH);
  for i := 0 to 319 do
    RANDOMS[i] := M_Random;

  // copy start screen to main screen
  memcpy(screens[SCN_FG], wipe_scr_start, SCREENWIDTH * SCREENHEIGHT);

  wipe_shittyColMajorXform(wipe_scr_start, SCREENWIDTH, SCREENHEIGHT);
  wipe_shittyColMajorXform(wipe_scr_end, SCREENWIDTH, SCREENHEIGHT);

  // setup initial column positions
  // (y<0 => not ready to scroll yet)
  yy := Z_Malloc(SCREENWIDTH * SizeOf(integer), PU_STATIC, nil);
  yy[0] := -(M_Random mod 16);
  for i := 1 to SCREENWIDTH - 1 do
  begin
    r := (RANDOMS[SHEIGHTS[i]] mod 3) - 1;
    yy[i] := yy[i - 1] + r;
    if yy[i] > 0 then
      yy[i] := 0
    else if yy[i] = -16 then
      yy[i] := -15;
  end;

  // JVAL change wipe timing
  vy := FRACUNIT * SCREENWIDTH div 200;
  for i := 0 to SCREENWIDTH - 1 do
    yy[i] := yy[i] * vy;

  for i := 1 to SCREENWIDTH - 1 do
    if SHEIGHTS[i - 1] = SHEIGHTS[i] then
      yy[i] := yy[i - 1];
end;

function wipe_doMelt(ticks: integer): integer;
var
  i: integer;
  j: integer;
  dy: fixed_t;
  idx: integer;
  s: PByteArray;
  d: PByteArray;
begin
  Result := 1;

  while ticks > 0 do
  begin
    for i := 0 to SCREENWIDTH - 1 do
    begin
      if yy[i] < 0 then
      begin
        yy[i] := yy[i] + vy;
        Result := 0;
      end
      else if yy[i] < SCREENHEIGHT * FRACUNIT then
      begin
        if yy[i] <= 15 * vy then
          dy := yy[i] + vy
        else
          dy := 8 * vy;
        if (yy[i] + dy) div FRACUNIT >= SCREENHEIGHT then
          dy := SCREENHEIGHT * FRACUNIT - yy[i];
        s := PByteArray(integer(wipe_scr_end) + i * SCREENHEIGHT + yy[i] div FRACUNIT);
        d := PByteArray(integer(screens[SCN_FG]) + yy[i] div FRACUNIT * SCREENWIDTH + i);
        idx := 0;
        for j := 0 to dy div FRACUNIT do //- 1 do
        begin
          d[idx] := s[j];
          idx := idx + SCREENWIDTH;
        end;
        yy[i] := yy[i] + dy;
        s := PByteArray(integer(wipe_scr_start) + i * SCREENHEIGHT);
        d := PByteArray(integer(screens[SCN_FG]) + yy[i] div FRACUNIT * SCREENWIDTH + i);

        idx := 0;
        for j := 0 to SCREENHEIGHT - yy[i] div FRACUNIT - 1 do
        begin
          d[idx] := s[j];
          idx := idx + SCREENWIDTH;
        end;
        Result := 0;
      end;
    end;
    dec(ticks);
  end;
end;

procedure wipe_exitMelt;
begin
  Z_Free(yy);
end;

procedure wipe_StartScreen;
begin
  wipe_scr_start := screens[SCN_WIPE_START];
  I_ReadScreen(wipe_scr_start);
end;

procedure wipe_EndScreen;
begin
  wipe_scr_end := screens[SCN_WIPE_END];
  I_ReadScreen(wipe_scr_end);
end;

var
  wiping: boolean = False;

// when zero, stop the wipe
function wipe_Ticker(ticks: integer): boolean;
begin
  // initial stuff
  if not wiping then
  begin
    wiping := True;
    wipe_initMelt;
  end;

  // do a piece of wipe-in
  if wipe_doMelt(ticks) <> 0 then
  begin
    // final stuff
    wiping := False;
    wipe_exitMelt;
  end;

  Result := not wiping;
end;

end.
