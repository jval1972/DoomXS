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

unit r_plane;

interface

uses m_fixed,
  doomdef, 
  r_data, r_defs;

{
    r_plane.h, r_plane.c
}

// Emacs style mode select   -*- C++ -*- 
//-----------------------------------------------------------------------------
//
// $Id:$
//
// Copyright (C) 1993-1996 by id Software, Inc.
//
// This source is available for distribution and/or modification
// only under the terms of the DOOM Source Code License as
// published by id Software. All rights reserved.
//
// The source is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License
// for more details.
//
// DESCRIPTION:
//	Refresh, visplane stuff (floor, ceilings).
//	Here is a core component: drawing the floors and ceilings,
//	 while maintaining a per column clipping list only.
//	Moreover, the sky areas have to be determined.
//
//-----------------------------------------------------------------------------

procedure R_InitPlanes;
procedure R_ClearPlanes;

procedure R_MapPlane(y: integer; x1: integer; x2: integer);

procedure R_MakeSpans(x: integer; t1: integer; b1: integer; t2: integer; b2: integer);

procedure R_DrawPlanes;

function R_FindPlane(height: fixed_t; picnum: integer; lightlevel: integer): Pvisplane_t;

function R_CheckPlane(pl: Pvisplane_t; start: integer; stop: integer): Pvisplane_t;

var
//
// Clip values are the solid pixel bounding the range.
//  floorclip starts out SCREENHEIGHT
//  ceilingclip starts out -1
//
  floorclip: packed array[0..SCREENWIDTH - 1] of smallint;
  ceilingclip: packed array[0..SCREENWIDTH - 1] of smallint;
{  floorclip: array[0..SCREENWIDTH - 1] of integer;
  ceilingclip: array[0..SCREENWIDTH - 1] of integer;}

var
  floorplane: Pvisplane_t;
  ceilingplane: Pvisplane_t;

//
// opening
//

// ?
const
  MAXOPENINGS = SCREENWIDTH * 64;

var
  openings: packed array[0..MAXOPENINGS - 1] of smallint; // VJ maybe not packed
  lastopening: integer;

  yslope: array[0..SCREENHEIGHT - 1] of fixed_t;
  distscale: array[0..SCREENWIDTH - 1] of fixed_t;

implementation

uses d_delphi,
  doomstat,
  d_player,
  tables,
  i_system,
  r_sky, r_draw, r_main, r_things,
  z_zone, w_wad;

// Here comes the obnoxious "visplane".
const
  MAXVISPLANES = 256; // VJ was = 128

var
  visplanes: array[0..MAXVISPLANES - 1] of visplane_t;
  lastvisplane: integer;

//
// spanstart holds the start of a plane span
// initialized to 0 at start
//
  spanstart: array[0..SCREENHEIGHT - 1] of integer;

//
// texture mapping
//
  planezlight: Plighttable_tPArray;
  planeheight: fixed_t;

  basexscale: fixed_t;
  baseyscale: fixed_t;

  cachedheight: array[0..SCREENHEIGHT - 1] of fixed_t;
  cacheddistance: array[0..SCREENHEIGHT -1] of fixed_t;
  cachedxstep: array[0..SCREENHEIGHT -1] of fixed_t;
  cachedystep: array[0..SCREENHEIGHT - 1] of fixed_t;


//
// R_InitPlanes
// Only at game startup.
//
procedure R_InitPlanes;
begin
  // Doh!
end;

//
// R_MapPlane
//
// Uses global vars:
//  planeheight
//  ds_source
//  basexscale
//  baseyscale
//  viewx
//  viewy
//
// BASIC PRIMITIVE
//
procedure R_MapPlane(y: integer; x1: integer; x2: integer);
var
  angle: angle_t;
  distance: fixed_t;
  length: fixed_t;
  index: LongWord;
begin
(*
#ifdef RANGECHECK
    if (x2 < x1
	|| x1<0
	|| x2>=viewwidth
	|| (unsigned)y>viewheight)
    {
	I_Error ("R_MapPlane: %i, %i at %i",x1,x2,y);
    }
#endif
*)
  if planeheight <> cachedheight[y] then
  begin
    cachedheight[y] := planeheight;
    cacheddistance[y] := FixedMul(planeheight, yslope[y]);
    distance := cacheddistance[y];
    cachedxstep[y] := FixedMul(distance, basexscale);
    ds_xstep := cachedxstep[y];
    cachedystep[y] := FixedMul(distance, baseyscale);
    ds_ystep := cachedystep[y];
  end
  else
  begin
    distance := cacheddistance[y];
    ds_xstep := cachedxstep[y];
    ds_ystep := cachedystep[y];
  end;

  length := FixedMul(distance, distscale[x1]);
  angle := _SHRW(viewangle + xtoviewangle[x1], ANGLETOFINESHIFT);
  ds_xfrac := viewx + FixedMul(finecosine[angle], length);
  ds_yfrac := -viewy - FixedMul(finesine[angle], length);

  if boolval(fixedcolormap) then
    ds_colormap := fixedcolormap
  else
  begin
    index := _SHR(distance, LIGHTZSHIFT);

    if index >= MAXLIGHTZ then
      index := MAXLIGHTZ - 1;

    ds_colormap := planezlight[index];
  end;

  ds_y := y;
  ds_x1 := x1;
  ds_x2 := x2;

  // high or low detail
  spanfunc;
end;

//
// R_ClearPlanes
// At begining of frame.
//
procedure R_ClearPlanes;
var
  i: integer;
  angle: angle_t;
begin
  // opening / clipping determination
  for i := 0 to viewwidth - 1 do
  begin
    floorclip[i] := viewheight;
    ceilingclip[i] := -1;
  end;

  lastvisplane := 0; // VJ (= visplanes);
  lastopening := 0; // VJ (= openings);

  // texture calculation
  memset(@cachedheight, 0, SizeOf(cachedheight));

  // left to right mapping
  angle := _SHRW(viewangle - ANG90, ANGLETOFINESHIFT);

  // scale will be unit scale at SCREENWIDTH/2 distance
  basexscale := FixedDiv(finecosine[angle], centerxfrac);
  baseyscale := -FixedDiv(finesine[angle], centerxfrac);
end;

//
// R_NewVisPlane
//
function R_NewVisPlane: integer;
begin
  if lastvisplane = MAXVISPLANES then
    I_Error('R_NewVisPlane(): no more visplanes');

  if lastvisplane > maxvisplane then
  begin
    visplanes[lastvisplane].top := Pvisindex_tArray(
      Z_Malloc((SCREENWIDTH + 1) * SizeOf(visindex_t), PU_LEVEL, nil));
    visplanes[lastvisplane].bottom := Pvisindex_tArray(
      Z_Malloc((SCREENWIDTH + 1) * SizeOf(visindex_t), PU_LEVEL, nil));
    maxvisplane := lastvisplane;
  end;

  inc(lastvisplane);
  result := lastvisplane;
end;

//
// R_FindPlane
//
function R_FindPlane(height: fixed_t; picnum: integer; lightlevel: integer): Pvisplane_t;
var
  check: integer;
  i: integer;
begin
  if picnum = skyflatnum then
  begin
    height := 0; // all skys map together
    lightlevel := 0;
  end;

  check := 0;
  while check < lastvisplane do
  begin
    if (height = visplanes[check].height) and
       (picnum = visplanes[check].picnum) and
       (lightlevel = visplanes[check].lightlevel) then
      break;
    inc(check);
  end;

  if check < lastvisplane then
  begin
    result := @visplanes[check];
//    result := visplanes[check];
    exit;
  end;

  if lastvisplane = MAXVISPLANES then
    I_Error('R_FindPlane(): no more visplanes');

//  inc(lastvisplane);
  lastvisplane := R_NewVisPlane;

//  visplanes[check] := Z_Malloc(SizeOf(visplane_t), PU_LEVEL, nil); // z_alloc

  visplanes[check].height := height;
  visplanes[check].picnum := picnum;
  visplanes[check].lightlevel := lightlevel;
  visplanes[check].minx := SCREENWIDTH;
  visplanes[check].maxx := -1;

  for i := 0 to SCREENWIDTH - 1 do
    visplanes[check].top[i] := VISEND;

  result := @visplanes[check];
//  result := visplanes[check];
end;

//
// R_CheckPlane
//
function R_CheckPlane(pl: Pvisplane_t; start: integer; stop: integer): Pvisplane_t;
var
  intrl: integer;
  intrh: integer;
  unionl: integer;
  unionh: integer;
  x: integer;
  i: integer;
begin
  if start < pl.minx then
  begin
    intrl := pl.minx;
    unionl := start;
  end
  else
  begin
    unionl := pl.minx;
    intrl := start;
  end;

  if stop > pl.maxx then
  begin
    intrh := pl.maxx;
    unionh := stop;
  end
  else
  begin
    unionh := pl.maxx;
    intrh := stop;
  end;

  x := intrl;
  while x <= intrh do
  begin
    if pl.top[x] <> VISEND then
      break
    else
      inc(x);
  end;

  if x > intrh then
  begin
    pl.minx := unionl;
    pl.maxx := unionh;

    // use the same one
    result := pl;
    exit;
  end;

    // make a new visplane
//  visplanes[lastvisplane] := Z_Malloc(SizeOf(visplane_t), PU_LEVEL, nil); // z_alloc

  if lastvisplane = MAXVISPLANES then
    I_Error('R_CheckPlane(): no more visplanes');

  visplanes[lastvisplane].height := pl.height;
  visplanes[lastvisplane].picnum := pl.picnum;
  visplanes[lastvisplane].lightlevel := pl.lightlevel;

  pl := @visplanes[lastvisplane];
//  pl := visplanes[lastvisplane];

//  inc(lastvisplane);
  lastvisplane := R_NewVisPlane;

  pl.minx := start;
  pl.maxx := stop;

  for i := 0 to SCREENWIDTH - 1 do
    pl.top[i] := VISEND;

  result := pl;
end;

//
// R_MakeSpans
//
procedure R_MakeSpans(x: integer; t1: integer; b1: integer; t2: integer; b2: integer);
begin
  while (t1 < t2) and (t1 <= b1) do
  begin
  // VJ 9/7/05
    if (t1 >= 0) and (t1 <= Length(spanstart)) then
      R_MapPlane(t1, spanstart[t1], x - 1);
    inc(t1);
  end;
  while (b1 > b2) and (b1 >= t1) do
  begin
  // VJ 9/7/05
    if (b1 >= 0) and (b1 <= Length(spanstart)) then
      R_MapPlane(b1, spanstart[b1], x - 1);
    dec(b1);
  end;

  while (t2 < t1) and (t2 <= b2) do
  begin
  // VJ 9/7/05
    if (t2 >= 0) and (t2 <= Length(spanstart)) then
      spanstart[t2] := x;
    inc(t2);
  end;
  while (b2 > b1) and (b2 >= t2) do
  begin
  // VJ 9/7/05
    if (b2 >= 0) and (b2 <= Length(spanstart)) then
      spanstart[b2] := x;
    dec(b2);
  end;
end;

//
// R_DrawPlanes
// At the end of each frame.
//
procedure R_DrawPlanes;
var
  pl: Pvisplane_t;
  i: integer;
  light: integer;
  x: integer;
  stop: integer;
  angle: integer;
begin
(*
#ifdef RANGECHECK
    if (ds_p - drawsegs > MAXDRAWSEGS)
	I_Error ("R_DrawPlanes: drawsegs overflow (%i)",
		 ds_p - drawsegs);

    if (lastvisplane - visplanes > MAXVISPLANES)
	I_Error ("R_DrawPlanes: visplane overflow (%i)",
		 lastvisplane - visplanes);

    if (lastopening - openings > MAXOPENINGS)
	I_Error ("R_DrawPlanes: opening overflow (%i)",
		 lastopening - openings);
#endif
*)
  for i := 0 to lastvisplane - 1 do
  begin
    pl := @visplanes[i];
//    pl := visplanes[i];
    if pl.minx > pl.maxx then
      continue;


    // sky flat
    if pl.picnum = skyflatnum then
    begin
//      dc_iscale := _SHR(pspriteiscale, detailshift);
      dc_iscale := pspriteiscale;

      // Sky is allways drawn full bright,
      //  i.e. colormaps[0] is used.
      // Because of this hack, sky is not affected
      //  by INVUL inverse mapping.
      dc_colormap := Plighttable_tArray(colormaps);
      dc_texturemid := skytexturemid;
      for x := pl.minx to pl.maxx do
      begin
        dc_yl := pl.top[x];
        dc_yh := pl.bottom[x];

        if dc_yl <= dc_yh then
        begin
          angle := _SHR(viewangle + xtoviewangle[x], ANGLETOSKYSHIFT);
          dc_x := x;
          dc_source := R_GetColumn(skytexture, angle);
        // VJ
        // call skycolfunc(), not colfunc()
          skycolfunc;
        end;
      end;
	    continue;
    end;

    // regular flat
    ds_source := W_CacheLumpNum(firstflat + flattranslation[pl.picnum], PU_STATIC);

    planeheight := abs(pl.height - viewz);
    light := _SHR(pl.lightlevel, LIGHTSEGSHIFT) + extralight;

    if light >= LIGHTLEVELS then
      light := LIGHTLEVELS - 1;

    if light < 0 then
      light := 0;

    planezlight := @zlight[light]; // VJ ???

    pl.top[pl.maxx + 1] := VISEND;
    pl.top[pl.minx - 1] := VISEND;

    stop := pl.maxx + 1;

    for x := pl.minx to stop do
      R_MakeSpans(x, pl.top[x - 1], pl.bottom[x - 1], pl.top[x], pl.bottom[x]);

    Z_ChangeTag(ds_source, PU_CACHE);
  end;
end;


end.
