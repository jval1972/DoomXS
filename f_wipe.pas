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

unit f_wipe;

interface

function wipe_StartScreen(x, y, width, height: integer): integer;

function wipe_EndScreen(x, y, width, height: integer): integer;

function wipe_ScreenWipe(wipeno, x, y, width, height, ticks: integer): boolean;

type
  wipe_t = (
    // simple gradual pixel change for 8-bit only
    wipe_ColorXForm,
    // weird screen melt
    wipe_Melt,
    wipe_NUMWIPES
  );

implementation

uses
  doomdef,
  d_delphi,
  m_rnd,
  m_fixed,
  i_video,
  v_video,
  z_memory;

//
//                       SCREEN WIPE PACKAGE
//

// when zero, stop the wipe
var
  go: boolean = false;

var
  wipe_scr_start: PByteArray;
  wipe_scr_end: PByteArray;
  wipe_scr: PByteArray;

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

function wipe_initColorXForm(width, height, ticks: integer): integer;
begin
  memcpy(wipe_scr, wipe_scr_start, width * height);
  result := 0;
end;

function wipe_doColorXForm(width, height, ticks: integer): integer;
var
  changed: boolean;
  w: integer;
  e: integer;
  newval: integer;
begin
  changed := false;
  w := 0;
  e := 0;

  while w < width * height do
  begin
    if wipe_scr[w] <> wipe_scr_end[e] then
    begin
      if wipe_scr[w] > wipe_scr_end[e] then
      begin
        newval := wipe_scr[w] - ticks;
        if newval < wipe_scr_end[e] then
          wipe_scr[w] := wipe_scr_end[e]
        else
          wipe_scr[w] := newval;
      end
      else if wipe_scr[w] < wipe_scr_end[e] then
      begin
        newval := wipe_scr[w] + ticks;
        if newval > wipe_scr_end[e] then
          wipe_scr[w] := wipe_scr_end[e]
        else
          wipe_scr[w] := newval;
      end;
      changed := true;
    end;
    inc(w);
    inc(e);
  end;

  result := intval(not changed);
end;

function wipe_exitColorXForm(width, height, ticks: integer): integer;
begin
  result := 0;
end;

var
  yy: Pfixed_tArray;
  vy: fixed_t;

function wipe_initMelt(width, height, ticks: integer): integer;
var
  i, r: integer;
begin
  // copy start screen to main screen
  memcpy(wipe_scr, wipe_scr_start, width * height);

  wipe_shittyColMajorXform(wipe_scr_start, width, height);
  wipe_shittyColMajorXform(wipe_scr_end, width, height);

  // setup initial column positions
  // (y<0 => not ready to scroll yet)
  yy := Z_Malloc(width * SizeOf(integer), PU_STATIC, nil);
  yy[0] := -(M_Random mod 16);
  for i := 1 to width - 1 do
  begin
    r := (M_Random mod 3) - 1;
    yy[i] := yy[i - 1] + r;
    if yy[i] > 0 then
      yy[i] := 0
    else if yy[i] = -16 then
      yy[i] := -15;
  end;

  // VJ change wipe timing
  vy := FRACUNIT * SCREENWIDTH div 200;
  for i := 0 to width - 1 do
    yy[i] := yy[i] * vy;

  result := 0;
end;

function wipe_doMelt(width, height, ticks: integer): integer;
var
  i: integer;
  j: integer;
  dy: fixed_t;
  idx: integer;
  s: PByteArray;
  d: PByteArray;
begin
  result := 1;

  while ticks > 0 do
  begin
    for i := 0 to width - 1 do
    begin
      if yy[i] < 0 then
      begin
        yy[i] := yy[i] + vy;
        result := 0;
      end
      else if yy[i] < height * FRACUNIT then
      begin
        if yy[i] <= 15 * vy then
          dy := yy[i] + vy
        else
          dy := 8 * vy;
        if (yy[i] + dy) div FRACUNIT >= height then
          dy := height * FRACUNIT - yy[i];
        s := PByteArray(integer(wipe_scr_end) + i * height + yy[i] div FRACUNIT);
        d := PByteArray(integer(wipe_scr) + yy[i] div FRACUNIT * width + i);
        idx := 0;
        for j := 0 to dy div FRACUNIT do //- 1 do
        begin
          d[idx] := s[j];
          idx := idx + width;
        end;
        yy[i] := yy[i] + dy;
        s := PByteArray(integer(wipe_scr_start) + i * height);
        d := PByteArray(integer(wipe_scr) + yy[i] div FRACUNIT * width + i);

        idx := 0;
        for j := 0 to height - yy[i] div FRACUNIT - 1 do
        begin
          d[idx] := s[j];
          idx := idx + width;
        end;
        result := 0;
      end;
    end;
    dec(ticks);
  end;
end;

function wipe_exitMelt(width, height, ticks: integer): integer;
begin
  Z_Free(yy);
  result := 0;
end;

function wipe_StartScreen(x, y, width, height: integer): integer;
begin
  wipe_scr_start := screens[2];
  I_ReadScreen(wipe_scr_start);
  result := 0;
end;

function wipe_EndScreen(x, y, width, height: integer): integer;
begin
  wipe_scr_end := screens[3];
  I_ReadScreen(wipe_scr_end);
  V_DrawBlock(x, y, 0, width, height, wipe_scr_start); // restore start scr.
  result := 0;
end;

function wipe_ScreenWipe(wipeno, x, y, width, height, ticks: integer): boolean;
var
  rc: integer;

  function WIPES(index: integer): integer;
  begin
    case index of
      0: result := wipe_initColorXForm(width, height, ticks);
      1: result := wipe_doColorXForm(width, height, ticks);
      2: result := wipe_exitColorXForm(width, height, ticks);
      3: result := wipe_initMelt(width, height, ticks);
      4: result := wipe_doMelt(width, height, ticks);
      5: result := wipe_exitMelt(width, height, ticks);
    else
      result := 0; // Ouch
    end;
  end;

begin
  // initial stuff
  if not go then
  begin
    go := true;
    wipe_scr := screens[SCN_FG];

    WIPES(wipeno * 3)
  end;

  // do a piece of wipe-in
  rc := WIPES(wipeno * 3 + 1);

  // final stuff
  if rc <> 0 then
  begin
    go := false;
    WIPES(wipeno * 3 + 2);
  end;

  result := not go;
end;

end.

