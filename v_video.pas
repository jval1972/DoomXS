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

unit v_video;

interface

uses
  d_delphi,
  doomtype,
  doomdef,
// Needed because we are refering to patches.
  r_defs;

const
// VIDEO

// drawing stuff
//
// Background and foreground screen numbers
  SCN_FG = 0;
  SCN_BG = 1;
  SCN_WIPE_START = 2;
  SCN_WIPE_END = 3;
  SCN_SCRF = 4; // Finale Screen Buffer 320x200
  SCN_TMP = 5;  // Temporary Screen Buffer 320x200
  SCN_ST = 6;   // Status Bar Screen Buffer

var
// Screen 0 is the screen updated by I_Update screen.
// Screen 1 is an extra buffer.
// Screen 4 is an extra buffer for finale.
// Screen 5 is used by status line
  screens: array[0..SCN_ST] of PByteArray;

// Allocates buffer screens, call before R_Init.
procedure V_Init;

procedure V_CopyRect(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);

procedure V_DrawPatch(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
procedure V_DrawPatchFlipped(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);

function V_PreserveX(x: integer): integer;

function V_PreserveY(y: integer): integer;

function V_PreserveW(x: integer; w: integer): integer;

function V_PreserveH(y: integer; h: integer): integer;

const
// Now where did these came from?
  gammatable: array[0..4,  0..255] of byte = (
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 
     17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 
     33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 
     49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 
     65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 
     81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 
     97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 
     113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 
     128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 
     144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 
     160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 
     176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 
     192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 
     208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 
     224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 
     240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255), 

    (2, 4, 5, 7, 8, 10, 11, 12, 14, 15, 16, 18, 19, 20, 21, 23, 24, 25, 26, 27, 29, 30, 31, 
     32, 33, 34, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 54, 55,
     56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 70, 71, 72, 73, 74, 75, 76, 77, 
     78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 
     99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 
     115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 129, 
     130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 
     146, 147, 148, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 
     161, 162, 163, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 
     175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 186, 187, 188, 189, 
     190, 191, 192, 193, 194, 195, 196, 196, 197, 198, 199, 200, 201, 202, 203, 204, 
     205, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 218, 
     219, 220, 221, 222, 222, 223, 224, 225, 226, 227, 228, 229, 230, 230, 231, 232, 
     233, 234, 235, 236, 237, 237, 238, 239, 240, 241, 242, 243, 244, 245, 245, 246, 
     247, 248, 249, 250, 251, 252, 252, 253, 254, 255), 

    (4, 7, 9, 11, 13, 15, 17, 19, 21, 22, 24, 26, 27, 29, 30, 32, 33, 35, 36, 38, 39, 40, 42, 
     43, 45, 46, 47, 48, 50, 51, 52, 54, 55, 56, 57, 59, 60, 61, 62, 63, 65, 66, 67, 68, 69, 
     70, 72, 73, 74, 75, 76, 77, 78, 79, 80, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 
     94, 95, 96, 97, 98, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 
     113, 114, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 
     129, 130, 131, 132, 133, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 
     144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 153, 154, 155, 156, 157, 158, 159,
     160, 160, 161, 162, 163, 164, 165, 166, 166, 167, 168, 169, 170, 171, 172, 172, 173, 
     174, 175, 176, 177, 178, 178, 179, 180, 181, 182, 183, 183, 184, 185, 186, 187, 188, 
     188, 189, 190, 191, 192, 193, 193, 194, 195, 196, 197, 197, 198, 199, 200, 201, 201, 
     202, 203, 204, 205, 206, 206, 207, 208, 209, 210, 210, 211, 212, 213, 213, 214, 215, 
     216, 217, 217, 218, 219, 220, 221, 221, 222, 223, 224, 224, 225, 226, 227, 228, 228, 
     229, 230, 231, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 241, 
     242, 243, 244, 244, 245, 246, 247, 247, 248, 249, 250, 251, 251, 252, 253, 254, 254, 
     255), 

    (8, 12, 16, 19, 22, 24, 27, 29, 31, 34, 36, 38, 40, 41, 43, 45, 47, 49, 50, 52, 53, 55, 
     57, 58, 60, 61, 63, 64, 65, 67, 68, 70, 71, 72, 74, 75, 76, 77, 79, 80, 81, 82, 84, 85, 
     86, 87, 88, 90, 91, 92, 93, 94, 95, 96, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 
     108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 
     125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 135, 136, 137, 138, 139, 140, 
     141, 142, 143, 143, 144, 145, 146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155, 
     155, 156, 157, 158, 159, 160, 160, 161, 162, 163, 164, 165, 165, 166, 167, 168, 169, 
     169, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 180, 180, 181, 182, 
     183, 183, 184, 185, 186, 186, 187, 188, 189, 189, 190, 191, 192, 192, 193, 194, 195, 
     195, 196, 197, 197, 198, 199, 200, 200, 201, 202, 202, 203, 204, 205, 205, 206, 207, 
     207, 208, 209, 210, 210, 211, 212, 212, 213, 214, 214, 215, 216, 216, 217, 218, 219, 
     219, 220, 221, 221, 222, 223, 223, 224, 225, 225, 226, 227, 227, 228, 229, 229, 230,
     231, 231, 232, 233, 233, 234, 235, 235, 236, 237, 237, 238, 238, 239, 240, 240, 241, 
     242, 242, 243, 244, 244, 245, 246, 246, 247, 247, 248, 249, 249, 250, 251, 251, 252, 
     253, 253, 254, 254, 255), 

    (16, 23, 28, 32, 36, 39, 42, 45, 48, 50, 53, 55, 57, 60, 62, 64, 66, 68, 69, 71, 73, 75, 76, 
     78, 80, 81, 83, 84, 86, 87, 89, 90, 92, 93, 94, 96, 97, 98, 100, 101, 102, 103, 105, 106, 
     107, 108, 109, 110, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 
     125, 126, 128, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 
     142, 143, 143, 144, 145, 146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155, 155, 
     156, 157, 158, 159, 159, 160, 161, 162, 163, 163, 164, 165, 166, 166, 167, 168, 169, 
     169, 170, 171, 172, 172, 173, 174, 175, 175, 176, 177, 177, 178, 179, 180, 180, 181, 
     182, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 189, 190, 191, 191, 192, 193, 
     193, 194, 195, 195, 196, 196, 197, 198, 198, 199, 200, 200, 201, 202, 202, 203, 203, 
     204, 205, 205, 206, 207, 207, 208, 208, 209, 210, 210, 211, 211, 212, 213, 213, 214, 
     214, 215, 216, 216, 217, 217, 218, 219, 219, 220, 220, 221, 221, 222, 223, 223, 224, 
     224, 225, 225, 226, 227, 227, 228, 228, 229, 229, 230, 230, 231, 232, 232, 233, 233, 
     234, 234, 235, 235, 236, 236, 237, 237, 238, 239, 239, 240, 240, 241, 241, 242, 242, 
     243, 243, 244, 244, 245, 245, 246, 246, 247, 247, 248, 248, 249, 249, 250, 250, 251, 
     251, 252, 252, 253, 254, 254, 255, 255)
  );

var
  usegamma: integer;

implementation

uses
  i_system,
  m_fixed,
  m_bbox;

// x and y translation tables for stretcing
var
  preserveX: array[0..319] of integer;
  preserveY: array[0..199] of integer;

// preserve x coordinates
function V_PreserveX(x: integer): integer;
begin
  if x <= 0 then
    result := 0
  else if x >= 320 then
    result := SCREENWIDTH
  else
    result := preserveX[x];
end;

// preserve y coordinates
function V_PreserveY(y: integer): integer;
begin
  if y <= 0 then
    result := 0
  else if y >= 200 then
    result := SCREENHEIGHT
  else
    result := preserveY[y];
end;

// preserve width coordinates
function V_PreserveW(x: integer; w: integer): integer;
begin
  result := V_PreserveX(x + w) - V_PreserveX(x);
end;

// preserve height coordinates
function V_PreserveH(y: integer; h: integer): integer;
begin
  result := V_PreserveY(y + h) - V_PreserveY(y);
end;

//
// V_CopyRect
//
procedure V_CopyRect(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  src: PByteArray;
  dest: PByteArray;
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  fracx: fixed_t;
  fracy: fixed_t;
  col: integer;
  row: integer;
begin
  if preserve then
  begin
    destw := V_PreserveW(destx, width);

    desth := V_PreserveH(desty, height);

    destx := V_PreserveX(destx);

    desty := V_PreserveY(desty);

    fracy := srcy * FRACUNIT;
    fracxstep := FRACUNIT * width div destw;
    fracystep := FRACUNIT * height div desth;

    for row := desty to desty + desth - 1 do
    begin
      fracx := 0;
      dest := PByteArray(integer(screens[destscrn]) + SCREENWIDTH * row + destx);
      // Source is a 320 width screen
      src := PByteArray(integer(screens[srcscrn]) + 320 * (fracy div FRACUNIT) + srcx);
      for col := 0 to destw - 1 do
      begin
        dest[col] := src[fracx div FRACUNIT];
        fracx := fracx + fracxstep;
      end;
      fracy := fracy + fracystep;
    end;

  end
  else
  begin
    src := PByteArray(integer(screens[srcscrn]) + SCREENWIDTH * srcy + srcx);
    dest := PByteArray(integer(screens[destscrn]) + SCREENWIDTH * desty + destx);

    while height > 0 do
    begin
      memcpy(dest, src, width);
      src := PByteArray(integer(src) + SCREENWIDTH);
      dest := PByteArray(integer(dest) + SCREENWIDTH);
      dec(height);
    end;
  end;
end;

function V_GetScreenWidth(scrn: integer): integer;
begin
  if scrn in [0..3] then
    result := SCREENWIDTH
  else
    result := 320;
end;

procedure V_DrawPatch(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
var
  count: integer;
  col: integer;
  column: Pcolumn_t;
  desttop: PByte;
  dest: PByte;
  source: PByte;
  w: integer;
  pw: integer;
  ph: integer;
  fracx: fixed_t;
  fracy: fixed_t;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  lasty: integer;
  swidth: integer;
begin
  if not preserve then
  begin
    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    col := 0;

    swidth := V_GetScreenWidth(scrn);
    desttop := PByte(integer(screens[scrn]) + y * swidth + x);

    w := patch.width;

    while col < w do
    begin
      column := Pcolumn_t(integer(patch) + patch.columnofs[col]);

    // step through the posts in a column
      while column.topdelta <> $ff do
      begin
        source := PByte(integer(column) + 3);
        dest := PByte(integer(desttop) + column.topdelta * swidth);
        count := column.length;

        while count > 0 do
        begin
          dest^ := source^;
          inc(source);
          dest := PByte(integer(dest) + swidth);
          dec(count);
        end;
        column := Pcolumn_t(integer(column) + column.length + 4);
      end;
      inc(col);
      inc(desttop);
    end;
  end
////////////////////////////////////////////////////
// Streching Draw, preserving original dimentions
////////////////////////////////////////////////////
  else
  begin

    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    pw := V_PreserveW(x, patch.width);
    ph := V_PreserveH(y, patch.height);

    x := V_PreserveX(x);
    y := V_PreserveY(y);

    fracx := 0;
    fracxstep := FRACUNIT * patch.width div pw;
    fracystep := FRACUNIT * patch.height div ph;

    col := 0;
    swidth := V_GetScreenWidth(scrn);
    desttop := PByte(integer(screens[scrn]) + y * swidth + x);

    while col < pw do
    begin
      column := Pcolumn_t(integer(patch) + patch.columnofs[fracx div FRACUNIT]);

    // step through the posts in a column
      while column.topdelta <> $ff do
      begin
        source := PByte(integer(column) + 3);
        dest := PByte(integer(desttop) + ((column.topdelta * SCREENHEIGHT) div 200) * SCREENWIDTH);
        count := column.length;
        fracy := 0;
        lasty := 0;

        while count > 0 do
        begin
          dest^ := source^;
          inc(dest, SCREENWIDTH);
          fracy := fracy + fracystep;
          if fracy div FRACUNIT > lasty then
          begin
            lasty := fracy div FRACUNIT;
            inc(source);
            dec(count);
          end;
        end;
        column := Pcolumn_t(integer(column) + column.length + 4);
      end;
      inc(col);
      inc(desttop);

      fracx := fracx + fracxstep;
    end;
  end;
end;


//
// V_DrawPatchFlipped
// Masks a column based masked pic to the screen.
// Flips horizontally, e.g. to mirror face.
//
procedure V_DrawPatchFlipped(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
var
  count: integer;
  col: integer;
  column: Pcolumn_t;
  desttop: PByte;
  dest: PByte;
  source: PByte;
  w, w1: integer;
  pw: integer;
  ph: integer;
  fracx: fixed_t;
  fracy: fixed_t;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  lasty: integer;
  swidth: integer;
begin
  if not preserve then
  begin
    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    col := 0;

    swidth := V_GetScreenWidth(scrn);
    desttop := PByte(integer(screens[scrn]) + y * swidth + x);

    w := patch.width;

    while col < w do
    begin
      column := Pcolumn_t(integer(patch) + patch.columnofs[w - 1 - col]);

    // step through the posts in a column
      while column.topdelta <> $ff do
      begin
        source := PByte(integer(column) + 3);
        dest := PByte(integer(desttop) + column.topdelta * swidth);
        count := column.length;

        while count > 0 do
        begin
          dest^ := source^;
          inc(source);
          inc(dest, swidth);
          dec(count);
        end;
        column := Pcolumn_t(integer(column) + column.length + 4);
      end;
      inc(col);
      inc(desttop);
    end;
  end
////////////////////////////////////////////////////
// Streching Draw, preserving original dimentions
////////////////////////////////////////////////////
  else
  begin
    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    pw := V_PreserveW(x, patch.width);
    ph := V_PreserveH(y, patch.height);

    x := V_PreserveX(x);
    y := V_PreserveY(y);

    fracx := 0;
    fracxstep := FRACUNIT * patch.width div pw;
    fracystep := FRACUNIT * patch.height div ph;

    col := 0;
    desttop := PByte(integer(screens[scrn]) + y * SCREENWIDTH + x);

    w := patch.width;

    while col < pw do
    begin
      w1 := w - 1 - (fracx div FRACUNIT);
      if w1 >= w then
        w1 := w - 1
      else if w1 < 0 then
        w := 0;
      column := Pcolumn_t(integer(patch) + patch.columnofs[w1]);

    // step through the posts in a column
      while column.topdelta <> $ff do
      begin
        source := PByte(integer(column) + 3);
        dest := PByte(integer(desttop) + ((column.topdelta * SCREENHEIGHT) div 200) * SCREENWIDTH);
        count := column.length;
        fracy := 0;
        lasty := 0;

        while count > 0 do
        begin
          dest^ := source^;
          dest := PByte(integer(dest) + SCREENWIDTH);
          fracy := fracy + fracystep;
          if fracy div FRACUNIT > lasty then
          begin
            lasty := fracy div FRACUNIT;
            inc(source);
            dec(count);
          end;
        end;
        column := Pcolumn_t(integer(column) + column.length + 4);
      end;
      inc(col);
      inc(desttop);

      fracx := fracx + fracxstep;
    end;
  end;
end;

//
// V_Init
//
procedure V_Init;
var
  i: integer;
  base: PByteArray;
  st: integer;
begin
  // stick these in low dos memory on PCs
  base := malloc(SCREENWIDTH * SCREENHEIGHT * 4 + 2 * 320 * 200);

  st := 0;
  for i := 0 to 5 do
  begin
    screens[i] := @base[st];
    if i < 4 then
      st := st + SCREENWIDTH * SCREENHEIGHT
    else
      st := st + 320 * 200;
  end;

  // initialize translation tables
  for i := 0 to 319 do
    preserveX[i] := Trunc(i * SCREENWIDTH / 320);

  for i := 0 to 199 do
    preserveY[i] := Trunc(i * SCREENHEIGHT / 200);

end;

end.
