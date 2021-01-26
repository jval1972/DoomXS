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

unit r_draw;

interface

uses
  d_delphi,
  m_fixed,
  r_defs;

// The span blitting interface.
// Hook in assembler or system specific BLT
//  here.
procedure R_DrawColumn;
procedure R_DrawColumnLow;
procedure R_DrawSkyColumn;

// The Spectre/Invisibility effect.
procedure R_DrawFuzzColumn;
//procedure R_DrawFuzzColumnLow; // VJ ??? not implement ???

// Draw with color translation tables,
//  for player sprite rendering,
//  Green/Red/Blue/Indigo shirts.
procedure R_DrawTranslatedColumn;

procedure R_VideoErase(const ofs: integer; const count: integer);

// Span blitting for rows, floor/ceiling.
// No Sepctre effect needed.
procedure R_DrawSpan;

// Low resolution mode, 160x200?
procedure R_DrawSpanLow;


procedure R_InitBuffer(width, height: integer);


// Initialize color translation tables,
//  for player rendering etc.
procedure R_InitTranslationTables;



// Rendering function.
procedure R_FillBackScreen;

// If the view size is not full screen, draws a border around it.
procedure R_DrawViewBorder;

var
//
// R_DrawColumn
// Source is the top of the column to scale.
//
  dc_colormap: Plighttable_tArray;
  dc_iscale: fixed_t;
  dc_texturemid: fixed_t;
  dc_x: integer;
  dc_yl: integer;
  dc_yh: integer;

// first pixel in a column (possibly virtual)
  dc_source: PByteArray;

  translationtables: PByteArray;
  dc_translation: PByteArray;

  viewwidth: integer;

var
  ds_y: integer;
  ds_x1: integer;
  ds_x2: integer;

  ds_colormap: Plighttable_tArray;

  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;

// start of a 64*64 tile image
  ds_source: PByteArray;

// just for profiling
  dscount: integer;

  viewheight: integer;
  scaledviewwidth: integer;

  viewwindowx: integer;
  viewwindowy: integer;

implementation

uses
  doomdef,
  w_wad,
  z_memory,
  i_system,
  r_data,
  r_main,
  st_stuff,
// Needs access to LFB (guess what).
  v_video,
// State.
  doomstat;

//
// All drawing to the view buffer is accomplished in this file.
// The other refresh files only know about ccordinates,
//  not the architecture of the frame buffer.
// Conveniently, the frame buffer is a linear one,
//  and we need only the base address,
//  and the total size == width*height*depth/8.,
//

var
  ylookup: array[0..SCREENHEIGHT - 1] of PByteArray;
  columnofs: array[0..SCREENWIDTH - 1] of integer;

{// Color tables for different players,
//  translate a limited part to another
//  (color ramps used for  suit colors).
//
  translations: array[0..2,0..255] of byte;}

//
// A column is a vertical slice/span from a wall texture that,
//  given the DOOM style restrictions on the view orientation,
//  will always have constant z depth.
// Thus a special case loop for very fast rendering can
//  be used. It has also been used with Wolfenstein 3D.
//
procedure R_DrawColumn;
var
  count: integer;
  i: integer;
  dest: PByte;
  frac: fixed_t;
  fracstep: fixed_t;
begin
  count := dc_yh - dc_yl;

  // Zero length, column does not exceed a pixel.
  if count < 0 then
    exit;

  // Framebuffer destination address.
  // Use ylookup LUT to avoid multiply with ScreenWidth.
  // Use columnofs LUT for subwindows?
  dest := @((ylookup[dc_yl]^)[columnofs[dc_x]]);

  // Determine scaling,
  //  which is the only mapping to be done.
  fracstep := dc_iscale;
  frac := dc_texturemid + (dc_yl - centery) * fracstep;

  // Inner loop that does the actual texture mapping,
  //  e.g. a DDA-lile scaling.
  // This is as fast as it gets.
  for i := 0 to count do
  begin
    // Re-map color indices from wall texture column
    //  using a lighting/special effects LUT.
    dest^ := dc_colormap[dc_source[(frac div FRACUNIT) and 127]];
    inc(dest, SCREENWIDTH);
    frac := frac + fracstep;
  end;
end;

procedure R_DrawColumnLow;
var
  count: integer;
  i: integer;
  dest: PByte;
  bdest: byte;
  frac: fixed_t;
  fracstep: fixed_t;
begin
  count := (dc_yh - dc_yl) div 3;

  // Zero length.
  if count < 0 then
    exit;

  dest := @((ylookup[dc_yl]^)[columnofs[dc_x]]);

  frac := dc_texturemid + (dc_yl - centery) * dc_iscale;
  fracstep := 3 * dc_iscale;

  for i := 0 to count do
  begin
    // Hack. Does not work corretly.
    bdest := dc_colormap[dc_source[(frac div FRACUNIT) and 127]];
    dest^ := bdest;
    inc(dest, SCREENWIDTH);
    dest^ := bdest;
    inc(dest, SCREENWIDTH);
    dest^ := bdest;
    inc(dest, SCREENWIDTH);
    frac := frac + fracstep;
  end;
end;

procedure R_DrawSkyColumn;
var
  count: integer;
  i: integer;
  dest: PByte;
  frac: fixed_t;
  fracstep: fixed_t;
begin
  count := dc_yh - dc_yl;

  // Zero length, column does not exceed a pixel.
  if count < 0 then
    exit;

  // Framebuffer destination address.
  // Use ylookup LUT to avoid multiply with ScreenWidth.
  // Use columnofs LUT for subwindows?
  dest := @((ylookup[dc_yl]^)[columnofs[dc_x]]);

  // Determine scaling,
  //  which is the only mapping to be done.
  fracstep := FRACUNIT * 200 div SCREENHEIGHT;
  frac := dc_texturemid + (dc_yl - centery) * fracstep;

  // Inner loop that does the actual texture mapping,
  //  e.g. a DDA-lile scaling.
  // This is as fast as it gets.
  for i := 0 to count do
  begin
    // Re-map color indices from wall texture column
    //  using a lighting/special effects LUT.
    dest^ := dc_source[(frac div FRACUNIT) and 127]; // JVAL removed colormap, sky is full bright

    inc(dest, SCREENWIDTH);
    frac := frac + fracstep;
  end;
end;

//
// Spectre/Invisibility.
//
const
  FUZZTABLE = 50;
  FUZZOFF = SCREENWIDTH;


  fuzzoffset: array[0..FUZZTABLE - 1] of integer = (
    FUZZOFF,-FUZZOFF, FUZZOFF,-FUZZOFF, FUZZOFF, FUZZOFF,-FUZZOFF,
    FUZZOFF, FUZZOFF,-FUZZOFF, FUZZOFF, FUZZOFF, FUZZOFF,-FUZZOFF,
    FUZZOFF, FUZZOFF, FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,
    FUZZOFF,-FUZZOFF,-FUZZOFF, FUZZOFF, FUZZOFF, FUZZOFF, FUZZOFF,-FUZZOFF,
    FUZZOFF,-FUZZOFF, FUZZOFF, FUZZOFF,-FUZZOFF,-FUZZOFF, FUZZOFF,
    FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF, FUZZOFF, FUZZOFF,
    FUZZOFF, FUZZOFF,-FUZZOFF, FUZZOFF, FUZZOFF,-FUZZOFF, FUZZOFF
  );

var
  fuzzpos: integer = 0;

//
// Framebuffer postprocessing.
// Creates a fuzzy image by copying pixels
//  from adjacent ones to left and right.
// Used with an all black colormap, this
//  could create the SHADOW effect,
//  i.e. spectres and invisible players.
//
procedure R_DrawFuzzColumn;
var
  count: integer;
  i: integer;
  dest: PByteArray;
begin
  // Adjust borders. Low...
  if dc_yl = 0 then
    dc_yl := 1;

  // .. and high.
  if dc_yh = viewheight - 1 then
    dc_yh := viewheight - 2;

  count := dc_yh - dc_yl;

  // Zero length.
  if count < 0 then
    exit;

  // Does not work with blocky mode.
  dest := PByteArray(integer(ylookup[dc_yl]) + columnofs[dc_x]);

  // Looks like an attempt at dithering,
  //  using the colormap #6 (of 0-31, a bit
  //  brighter than average).
  for i := 0 to count do
  begin
    // Lookup framebuffer, and retrieve
    //  a pixel that is either one column
    //  left or right of the current one.
    // Add index from colormap to index.
    dest[0] := colormaps[6 * 256 + dest[fuzzoffset[fuzzpos]]];

    // Clamp table lookup index.
    inc(fuzzpos);
    if fuzzpos = FUZZTABLE then
      fuzzpos := 0;

    incp(pointer(dest), SCREENWIDTH);

  end;
end;

//
// R_DrawTranslatedColumn
// Used to draw player sprites
//  with the green colorramp mapped to others.
// Could be used with different translation
//  tables, e.g. the lighter colored version
//  of the BaronOfHell, the HellKnight, uses
//  identical sprites, kinda brightened up.
//

procedure R_DrawTranslatedColumn;
var
  count: integer;
  dest: PByte;
  frac: fixed_t;
  fracstep: fixed_t;
  i: integer;
begin
  count := dc_yh - dc_yl;
  if count < 0 then
    exit;

  // FIXME. As above.
  dest := PByte(integer(ylookup[dc_yl]) + columnofs[dc_x]);

  // Looks familiar.
  fracstep := dc_iscale;
  frac := dc_texturemid + (dc_yl - centery) * fracstep;

  // Here we do an additional index re-mapping.
  for i := 0 to count do
  begin
    // Translation tables are used
    //  to map certain colorramps to other ones,
    //  used with PLAY sprites.
    // Thus the "green" ramp of the player 0 sprite
    //  is mapped to gray, red, black/indigo.
    dest^ := dc_colormap[dc_translation[dc_source[frac div FRACUNIT]]];
    inc(dest, SCREENWIDTH);

    frac := frac + fracstep;
  end;
end;

//
// R_InitTranslationTables
// Creates the translation tables to map
//  the green color ramp to gray, brown, red.
// Assumes a given structure of the PLAYPAL.
// Could be read from a lump instead.
//
procedure R_InitTranslationTables;
var
  i: integer;
begin
  translationtables := Z_Malloc (256 * 3 + 255, PU_STATIC, nil);
  translationtables := PByteArray((integer(translationtables) + 255 ) and (not 255));

  // translate just the 16 green colors
  for i := 0 to 255 do
    if (i >= $70) and (i <= $7f) then
    begin
      // map green ramp to gray, brown, red
      translationtables[i] := $60 + (i and $f);
      translationtables[i + 256] := $40 + (i and $f);
      translationtables[i + 512] := $20 + (i and $f);
    end
    else
    begin
      // Keep all other colors as is.
      translationtables[i] := i;
      translationtables[i + 256] := i;
      translationtables[i + 512] := i;
    end;
end;

//
// R_DrawSpan
// With DOOM style restrictions on view orientation,
//  the floors and ceilings consist of horizontal slices
//  or spans with constant z depth.
// However, rotation around the world z axis is possible,
//  thus this mapping, while simpler and faster than
//  perspective correct texture mapping, has to traverse
//  the texture at an angle in all but a few cases.
// In consequence, flats are not stored by column (like walls),
//  and the inner loop has to step in texture space u and v.
//

//
// Draws the actual span.
procedure R_DrawSpan;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  dest: PByte;
  count: integer;
  i: integer;
  spot: integer;
begin
  xfrac := ds_xfrac;
  yfrac := ds_yfrac;

  dest := PByte(integer(ylookup[ds_y]) + columnofs[ds_x1]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;

  for i := 0 to count do
  begin
    // Current texture index in u,v.
    spot := (yfrac div 1024) and (63 * 64) + (xfrac div FRACUNIT) and 63;

    // Lookup pixel from flat texture tile,
    //  re-index using light/colormap.

    dest^ := ds_colormap[ds_source[spot]];
    inc(dest);

    // Next step in u,v.
    xfrac := xfrac + ds_xstep;
    yfrac := yfrac + ds_ystep;
  end;
end;

//
// Again..
//
procedure R_DrawSpanLow;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  dest: PByte;
  bdest: byte;
  ds_xstep2: fixed_t;
  ds_ystep2: fixed_t;
  count: integer;
  i: integer;
  spot: integer;
begin
  xfrac := ds_xfrac;
  yfrac := ds_yfrac;


  dest := PByte(integer(ylookup[ds_y]) + columnofs[ds_x1]);

  // Blocky mode, multiply by 3 (!!).
  ds_xstep2 := ds_xstep * 3;
  ds_ystep2 := ds_ystep * 3;

  count := (ds_x2 - ds_x1) div 3;
  for i := 0 to count do
  begin
    spot := (yfrac div 1024) and (63 * 64) + (xfrac div FRACUNIT) and 63;
    // Lowres/blocky mode does it twice,
    //  while scale is adjusted appropriately.
    bdest := ds_colormap[ds_source[spot]];
    dest^ := bdest;
    inc(dest);
    dest^ := bdest;
    inc(dest);
    dest^ := bdest;
    inc(dest);

    xfrac := xfrac + ds_xstep2;
    yfrac := yfrac + ds_ystep2;
  end;
end;

//
// R_InitBuffer
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//
procedure R_InitBuffer(width, height: integer);
var
  i: integer;
begin
  // Handle resize,
  //  e.g. smaller view windows
  //  with border and/or status bar.
  viewwindowx := _SHR(SCREENWIDTH - width, 1);

  // Column offset. For windows.
  for i := 0 to width - 1 do
    columnofs[i] := viewwindowx + i;

  // Samw with base row offset.
  if width = SCREENWIDTH then
    viewwindowy := 0
  else
    viewwindowy := _SHR(V_PreserveY(200 - ST_HEIGHT) - height, 1);

  // Preclaculate all row offsets.
  for i := 0 to height - 1 do
    ylookup[i] := PByteArray(integer(screens[_FG]) + (i + viewwindowy) * SCREENWIDTH);
end;

//
// R_FillBackScreen
// Fills the back screen with a pattern
//  for variable screen sizes
// Also draws a beveled edge.
//
procedure R_FillBackScreen;
var
  src: PByteArray;
  dest: PByteArray;
  x: integer;
  y: integer;
  patch: Ppatch_t;
  name: string;
  pscaledviewwidth: integer;
  pviewwindowx: integer;
  pviewwindowy: integer;
  pviewheight: integer;
begin
  if scaledviewwidth = SCREENWIDTH then
    exit;

  if gamemode = commercial then
    name := 'GRNROCK'   // DOOM II border patch.
  else
    name := 'FLOOR7_2'; // DOOM border patch.

  src := W_CacheLumpName(name, PU_CACHE);
  dest := screens[_TMP];

  for y := 0 to 200 - ST_HEIGHT - 1 do
  begin
    for x := 0 to 320 div 64 - 1 do
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 64);
      incp(pointer(dest), 64);
    end;
    if 320 and 63 <> 0 then
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 320 and 63);
      incp(pointer(dest), (320 and 63));
    end;
  end;

  patch := W_CacheLumpName('brdr_t', PU_CACHE);
  x := 0;
  pscaledviewwidth := scaledviewwidth * 320 div SCREENWIDTH;
  pviewwindowx := viewwindowx * 320 div SCREENWIDTH;
  pviewwindowy := viewwindowy * 200 div SCREENHEIGHT;
  pviewheight := viewheight * 200 div SCREENHEIGHT;

  while x < pscaledviewwidth do
  begin
    V_DrawPatch(pviewwindowx + x, pviewwindowy - 8, _TMP, patch, false);
    x := x + 8;
  end;

  patch := W_CacheLumpName('brdr_b', PU_CACHE);
  x := 0;
  while x < pscaledviewwidth do
  begin
    V_DrawPatch(pviewwindowx + x, pviewwindowy + pviewheight, _TMP, patch, false);
    x := x + 8;
  end;

  patch := W_CacheLumpName('brdr_l', PU_CACHE);
  y := 0;
  while y < pviewheight do
  begin
    V_DrawPatch(pviewwindowx - 8, pviewwindowy + y, _TMP, patch, false);
    y := y + 8;
  end;

  patch := W_CacheLumpName('brdr_r', PU_CACHE);
  y := 0;
  while y < pviewheight do
  begin
    V_DrawPatch (pviewwindowx + pscaledviewwidth, pviewwindowy + y, _TMP, patch, false);
    y := y + 8;
  end;

  // Draw beveled edge.
  V_DrawPatch(pviewwindowx - 8, pviewwindowy - 8, _TMP,
    W_CacheLumpName('brdr_tl', PU_CACHE), false);

  V_DrawPatch(pviewwindowx + pscaledviewwidth, pviewwindowy - 8, _TMP,
    W_CacheLumpName('brdr_tr', PU_CACHE), false);

  V_DrawPatch(pviewwindowx - 8, pviewwindowy + pviewheight, _TMP,
    W_CacheLumpName('brdr_bl', PU_CACHE), false);

  V_DrawPatch(pviewwindowx + pscaledviewwidth, pviewwindowy + pviewheight, _TMP,
    W_CacheLumpName('brdr_br', PU_CACHE), false);

  V_CopyRect(0, 0, _TMP, 320, 200, 0, 0, 1, true);
end;

//
// Copy a screen buffer.
//
procedure R_VideoErase(const ofs: integer; const count: integer);
begin
  // LFB copy.
  // This might not be a good idea if memcpy
  //  is not optiomal, e.g. byte by byte on
  //  a 32bit CPU, as GNU GCC/Linux libc did
  //  at one point.
  memcpy(Pointer(integer(screens[_FG]) + ofs), Pointer(integer(screens[1]) + ofs), count);
end;

//
// R_DrawViewBorder
// Draws the border around the view
//  for different size windows?
//
procedure R_DrawViewBorder;
var
  top: integer;
  bottom: integer;
  side: integer;
  ofs: integer;
  i: integer;
begin
  if scaledviewwidth = SCREENWIDTH then
    exit;

  top := (SCREENHEIGHT - V_PreserveY(ST_HEIGHT) - viewheight) div 2;
  bottom := SCREENHEIGHT - V_PreserveY(ST_HEIGHT) - top - viewheight;
  side := (SCREENWIDTH - scaledviewwidth) div 2;

  // copy top and one line of left side
  R_VideoErase(0, top * SCREENWIDTH + side);

  // copy one line of right side and bottom
  if odd(bottom) then
    ofs := (viewheight + bottom - 1) * SCREENWIDTH - side
  else
    ofs := (viewheight + bottom) * SCREENWIDTH - side;
  R_VideoErase(ofs, bottom * SCREENWIDTH + side);

  // copy sides using wraparound
  ofs := top * SCREENWIDTH + SCREENWIDTH - side;
  side := _SHL(side, 1);

  for i := 1 to viewheight - 1 do
  begin
    R_VideoErase(ofs, side);
    ofs := ofs + SCREENWIDTH;
  end;

  V_MarkRect(0, 0, 320, 200 - ST_HEIGHT, true);
end;

end.
