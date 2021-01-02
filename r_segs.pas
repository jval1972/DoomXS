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

unit r_segs;

interface

uses d_delphi,
  m_fixed, tables,
  r_defs;

{
    r_segs.h, r_segs.c
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
//	Refresh module, drawing LineSegs from BSP.
//	All the clipping: columns, horizontal spans, sky columns.
//
//-----------------------------------------------------------------------------

procedure R_RenderMaskedSegRange(ds: Pdrawseg_t; x1, x2: integer);

procedure R_StoreWallRange(start: integer; stop: integer);

var
  maskedtexturecol: PSmallIntArray; // VJ : declared in r_defs
// angle to line origin
  rw_angle1: angle_t; // VJ was integer

var
// True if any of the segs textures might be visible.
  segtextured: boolean;

// False if the back side is the same plane.
  markfloor: boolean;
  markceiling: boolean;

  maskedtexture: boolean;
  toptexture: integer;
  bottomtexture: integer;
  midtexture: integer;


//
// regular wall
//
  rw_x: integer;
  rw_stopx: integer;
  rw_centerangle: angle_t;
  rw_offset: fixed_t;
  rw_distance: fixed_t;
  rw_normalangle: angle_t;
  rw_scale: fixed_t;
  rw_scalestep: fixed_t;
  rw_midtexturemid: fixed_t;
  rw_toptexturemid: fixed_t;
  rw_bottomtexturemid: fixed_t;

  worldtop: integer;
  worldbottom: integer;
  worldhigh: integer;
  worldlow: integer;

  pixhigh: fixed_t;
  pixlow: fixed_t;
  pixhighstep: fixed_t;
  pixlowstep: fixed_t;

  topfrac: fixed_t;
  topstep: fixed_t;

  bottomfrac: fixed_t;
  bottomstep: fixed_t;


  walllights: Plighttable_tPArray;


implementation

uses doomtype, doomdef, doomstat, doomdata,
  i_system,
  r_main, r_data, r_bsp, r_sky, r_things, r_draw, r_plane;

// OPTIMIZE: closed two sided lines as single sided

//
// R_RenderMaskedSegRange
//
procedure R_RenderMaskedSegRange(ds: Pdrawseg_t; x1, x2: integer);
var
  index: LongWord;
  col: Pcolumn_t;
  lightnum: integer;
  texnum: integer;
  i: integer;
begin
  // Calculate light table.
  // Use different light tables
  //   for horizontal / vertical / diagonal. Diagonal?
  // OPTIMIZE: get rid of LIGHTSEGSHIFT globally
  curline := ds.curline;
  frontsector := curline.frontsector;
  backsector := curline.backsector;
  texnum := texturetranslation[curline.sidedef.midtexture];

  lightnum := _SHR(frontsector.lightlevel, LIGHTSEGSHIFT) + extralight;

  if curline.v1.y = curline.v2.y then
    dec(lightnum)
  else if curline.v1.x = curline.v2.x then
    inc(lightnum);

  if lightnum < 0 then
    walllights := @scalelight[0, 0] // VJ ??? maybe @scalelight[0] ????
  else if lightnum >= LIGHTLEVELS then
    walllights := @scalelight[LIGHTLEVELS - 1, 0] // VJ ???
  else
    walllights := @scalelight[lightnum]; // VJ ???

  maskedtexturecol := ds.maskedtexturecol;

  rw_scalestep := ds.scalestep;
  spryscale := ds.scale1 + (x1 - ds.x1) * rw_scalestep;
  mfloorclip := ds.sprbottomclip;
  mceilingclip := ds.sprtopclip;

  // find positioning
  if boolval(curline.linedef.flags and ML_DONTPEGBOTTOM) then
  begin
    if frontsector.floorheight > backsector.floorheight then
      dc_texturemid := frontsector.floorheight
    else
      dc_texturemid := backsector.floorheight;
    dc_texturemid := dc_texturemid + textureheight[texnum] - viewz;
  end
  else
  begin
    if frontsector.ceilingheight < backsector.ceilingheight then
      dc_texturemid := frontsector.ceilingheight
     else
      dc_texturemid := backsector.ceilingheight;
    dc_texturemid := dc_texturemid - viewz;
  end;
  dc_texturemid := dc_texturemid + curline.sidedef.rowoffset;

  if boolval(fixedcolormap) then
    dc_colormap := fixedcolormap;

  // draw the columns
  for i := x1 to x2 do
  begin
    dc_x := i;
    // calculate lighting
    if maskedtexturecol[dc_x] <> MAXSHORT then
    begin
      if not boolval(fixedcolormap) then
      begin
        index := _SHR(spryscale, LIGHTSCALESHIFT);

        if index >=  MAXLIGHTSCALE then
          index := MAXLIGHTSCALE - 1;

        dc_colormap := walllights[index];
      end;

      sprtopscreen := centeryfrac - FixedMul(dc_texturemid, spryscale);
      dc_iscale := LongWord($ffffffff) div LongWord(spryscale);

      // draw the texture
      col := Pcolumn_t(integer(R_GetColumn(texnum, maskedtexturecol[dc_x])) - 3);

      R_DrawMaskedColumn(col);
      maskedtexturecol[dc_x] := MAXSHORT;
    end;
    spryscale := spryscale + rw_scalestep;
  end;
end;

//
// R_RenderSegLoop
// Draws zero, one, or two textures (and possibly a masked
//  texture) for walls.
// Can draw or mark the starting pixel of floor and ceiling
//  textures.
// CALLED: CORE LOOPING ROUTINE.
//
const
  HEIGHTBITS = 12;
  HEIGHTUNIT = 1 shl HEIGHTBITS;

procedure R_RenderSegLoop;
var
  angle: angle_t;
  index: LongWord;
  yl: integer;
  yh: integer;
  mid: integer;
  texturecolumn: fixed_t;
  top: integer;
  bottom: integer;
begin
  texturecolumn := 0; // shut up compiler warning
  while rw_x < rw_stopx do
  begin
    // mark floor / ceiling areas
    yl := _SHR(topfrac + HEIGHTUNIT - 1, HEIGHTBITS);

    // no space above wall?
    if yl < ceilingclip[rw_x] + 1 then
      yl := ceilingclip[rw_x] + 1;

    if markceiling then
    begin
      top := ceilingclip[rw_x] + 1;
      bottom := yl - 1;

      if bottom >= floorclip[rw_x] then
        bottom := floorclip[rw_x] - 1;

      if top <= bottom then
      begin
        ceilingplane.top[rw_x] := top;
        ceilingplane.bottom[rw_x] := bottom;
      end;
    end;


    yh := _SHR(bottomfrac, HEIGHTBITS);

    if yh >= floorclip[rw_x] then
      yh := floorclip[rw_x] - 1;

    if markfloor then
    begin
      top := yh + 1;
      bottom := floorclip[rw_x] - 1;
      if top <= ceilingclip[rw_x] then
        top := ceilingclip[rw_x] + 1;
      if top <= bottom then
      begin
        floorplane.top[rw_x] := top;
        floorplane.bottom[rw_x] := bottom;
      end;
    end;

    // texturecolumn and lighting are independent of wall tiers
    if segtextured then
    begin
      // calculate texture offset
      angle := _SHRW(rw_centerangle + xtoviewangle[rw_x], ANGLETOFINESHIFT);
      texturecolumn := rw_offset - FixedMul(finetangent[angle], rw_distance);
      texturecolumn := texturecolumn div FRACUNIT;
      // calculate lighting
      index := _SHR(rw_scale, LIGHTSCALESHIFT);

      if index >=  MAXLIGHTSCALE then
        index := MAXLIGHTSCALE - 1;

      dc_colormap := walllights[index];
      dc_x := rw_x;
      dc_iscale := LongWord($ffffffff) div LongWord(rw_scale);
    end;

    // draw the wall tiers
    if boolval(midtexture) then
    begin
      // single sided line
      dc_yl := yl;
      dc_yh := yh;
      dc_texturemid := rw_midtexturemid;
      dc_source := R_GetColumn(midtexture, texturecolumn);
      colfunc;
      ceilingclip[rw_x] := viewheight;
      floorclip[rw_x] := -1;
    end
    else
    begin
      // two sided line
      if boolval(toptexture) then
      begin
        // top wall
        mid := _SHR(pixhigh, HEIGHTBITS);
        pixhigh := pixhigh + pixhighstep;

        if mid >= floorclip[rw_x] then
          mid := floorclip[rw_x] - 1;

        if mid >= yl then
        begin
          dc_yl := yl;
          dc_yh := mid;
          dc_texturemid := rw_toptexturemid;
          dc_source := R_GetColumn(toptexture, texturecolumn);
          colfunc;
          ceilingclip[rw_x] := mid;
        end
        else
          ceilingclip[rw_x] := yl - 1;
      end
      else
      begin
        // no top wall
        if markceiling then
          ceilingclip[rw_x] := yl - 1;
      end;

	    if boolval(bottomtexture) then
      begin
        // bottom wall
        mid := _SHR(pixlow + HEIGHTUNIT - 1, HEIGHTBITS);
        pixlow := pixlow + pixlowstep;

        // no space above wall?
        if mid <= ceilingclip[rw_x] then
          mid := ceilingclip[rw_x] + 1;

        if mid <= yh then
        begin
          dc_yl := mid;
          dc_yh := yh;
          dc_texturemid := rw_bottomtexturemid;
          dc_source := R_GetColumn(bottomtexture, texturecolumn);
          colfunc;
          floorclip[rw_x] := mid;
        end
        else
          floorclip[rw_x] := yh + 1;
      end
      else
      begin
        // no bottom wall
        if markfloor then
          floorclip[rw_x] := yh + 1;
      end;

      if maskedtexture then
      begin
        // save texturecol
        // for backdrawing of masked mid texture
        maskedtexturecol[rw_x] := texturecolumn;
      end;
    end;

    rw_scale := rw_scale + rw_scalestep;
    topfrac := topfrac + topstep;
    bottomfrac := bottomfrac + bottomstep;
    inc(rw_x);
  end;
end;

//
// R_StoreWallRange
// A wall segment will be drawn
//  between start and stop pixels (inclusive).
//
procedure R_StoreWallRange(start: integer; stop: integer);
var
  hyp: fixed_t;
  sineval: fixed_t;
  distangle,
  offsetangle: angle_t;
  vtop: fixed_t;
  lightnum: integer;
begin
  // don't overflow and crash
  if ds_p = MAXDRAWSEGS then
    exit;
(*
#ifdef RANGECHECK
    if (start >=viewwidth || start > stop)
	I_Error ("Bad R_RenderWallRange: %i to %i", start , stop);
#endif
*)
  sidedef := curline.sidedef;
  linedef := curline.linedef;

  // mark the segment as visible for auto map
  linedef.flags := linedef.flags or ML_MAPPED;

  // calculate rw_distance for scale calculation
  rw_normalangle := curline.angle + ANG90;
  offsetangle := abs(rw_normalangle - rw_angle1);

  if offsetangle > ANG90 then
    offsetangle := ANG90;

  distangle := ANG90 - offsetangle;
  hyp := R_PointToDist(curline.v1.x, curline.v1.y);
  sineval := finesine[_SHRW(distangle, ANGLETOFINESHIFT)];
  rw_distance := FixedMul(hyp, sineval);


  rw_x := start;
  drawsegs[ds_p].x1 := rw_x;
  drawsegs[ds_p].x2 := stop;
  drawsegs[ds_p].curline := curline;
  rw_stopx := stop + 1;

  // calculate scale at both ends and step
  rw_scale := R_ScaleFromGlobalAngle(viewangle + xtoviewangle[start]);
  drawsegs[ds_p].scale1 := rw_scale;

  if stop > start then
  begin
    drawsegs[ds_p].scale2 := R_ScaleFromGlobalAngle(viewangle + xtoviewangle[stop]);
    rw_scalestep := (drawsegs[ds_p].scale2 - rw_scale) div (stop - start);
    drawsegs[ds_p].scalestep := rw_scalestep
  end
  else
  begin
    // UNUSED: try to fix the stretched line bug
(*
#if 0
	if (rw_distance < FRACUNIT/2)
	{
	    fixed_t		trx,try;
	    fixed_t		gxt,gyt;

	    trx = curline->v1->x - viewx;
	    try = curline->v1->y - viewy;

	    gxt = FixedMul(trx,viewcos);
	    gyt = -FixedMul(try,viewsin);
	    ds_p->scale1 = FixedDiv(projection, gxt-gyt)<<detailshift;
	}
#endif
*)
    drawsegs[ds_p].scale2 := drawsegs[ds_p].scale1;
  end;

  // calculate texture boundaries
  //  and decide if floor / ceiling marks are needed
  worldtop := frontsector.ceilingheight - viewz;
  worldbottom := frontsector.floorheight - viewz;

  midtexture := 0;
  toptexture := 0;
  bottomtexture := 0;
  maskedtexture := boolval(0);
  drawsegs[ds_p].maskedtexturecol := nil;

  if not boolval(backsector) then
  begin
    // single sided line
    midtexture := texturetranslation[sidedef.midtexture];
    // a single sided line is terminal, so it must mark ends
    markfloor := true;
    markceiling := true;
    if boolval(linedef.flags and ML_DONTPEGBOTTOM) then
    begin
	    vtop := frontsector.floorheight + textureheight[sidedef.midtexture];
	    // bottom of texture at bottom
	    rw_midtexturemid := vtop - viewz;
    end
    else
    begin
	    // top of texture at top
	    rw_midtexturemid := worldtop;
    end;
    rw_midtexturemid := rw_midtexturemid + sidedef.rowoffset;

    drawsegs[ds_p].silhouette := SIL_BOTH;
    drawsegs[ds_p].sprtopclip := @screenheightarray;
    drawsegs[ds_p].sprbottomclip := @negonearray;
    drawsegs[ds_p].bsilheight := MAXINT;
    drawsegs[ds_p].tsilheight := MININT;
  end
  else
  begin
    // two sided line
    drawsegs[ds_p].sprtopclip := nil;
    drawsegs[ds_p].sprbottomclip := nil;
    drawsegs[ds_p].silhouette := 0;

    if frontsector.floorheight > backsector.floorheight then
    begin
      drawsegs[ds_p].silhouette := SIL_BOTTOM;
      drawsegs[ds_p].bsilheight := frontsector.floorheight;
    end
    else if backsector.floorheight > viewz then
    begin
      drawsegs[ds_p].silhouette := SIL_BOTTOM;
	    drawsegs[ds_p].bsilheight := MAXINT;
	    // ds_p->sprbottomclip = negonearray;
    end;

    if frontsector.ceilingheight < backsector.ceilingheight then
    begin
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette or SIL_TOP;
      drawsegs[ds_p].tsilheight := frontsector.ceilingheight;
    end
    else if backsector.ceilingheight < viewz then
    begin
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette or SIL_TOP;
      drawsegs[ds_p].tsilheight := MININT;
      // ds_p->sprtopclip = screenheightarray;
    end;

    if backsector.ceilingheight <= frontsector.floorheight then
    begin
      drawsegs[ds_p].sprbottomclip := @negonearray;
      drawsegs[ds_p].bsilheight := MAXINT;
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette or SIL_BOTTOM;
    end;

    if backsector.floorheight >= frontsector.ceilingheight then
    begin
      drawsegs[ds_p].sprtopclip := @screenheightarray;
	    drawsegs[ds_p].tsilheight := MININT;
	    drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette or SIL_TOP;
    end;

    worldhigh := backsector.ceilingheight - viewz;
    worldlow := backsector.floorheight - viewz;

    // hack to allow height changes in outdoor areas
    if (frontsector.ceilingpic = skyflatnum) and
       (backsector.ceilingpic = skyflatnum) then
    begin
      worldtop := worldhigh;
    end;


    if (worldlow <> worldbottom) or
       (backsector.floorpic <> frontsector.floorpic) or
       (backsector.lightlevel <> frontsector.lightlevel) then
    begin
      markfloor := true;
    end
    else
    begin
      // same plane on both sides
      markfloor := false;
    end;


    if (worldhigh <> worldtop) or
       (backsector.ceilingpic <> frontsector.ceilingpic) or
       (backsector.lightlevel <> frontsector.lightlevel) then
    begin
      markceiling := true;
    end
    else
    begin
      // same plane on both sides
      markceiling := false;
    end;

    if (backsector.ceilingheight <= frontsector.floorheight) or
       (backsector.floorheight >= frontsector.ceilingheight) then
    begin
      // closed door
      markceiling := true;
      markfloor := true;
    end;


    if worldhigh < worldtop then
    begin
      // top texture
      toptexture := texturetranslation[sidedef.toptexture];
      if boolval(linedef.flags and ML_DONTPEGTOP) then
      begin
        // top of texture at top
        rw_toptexturemid := worldtop;
      end
      else
      begin
        vtop := backsector.ceilingheight + textureheight[sidedef.toptexture];

        // bottom of texture
        rw_toptexturemid := vtop - viewz;
      end
    end;

    if worldlow > worldbottom then
    begin
      // bottom texture
      bottomtexture := texturetranslation[sidedef.bottomtexture];

      if boolval(linedef.flags and ML_DONTPEGBOTTOM) then
      begin
        // bottom of texture at bottom
        // top of texture at top
        rw_bottomtexturemid := worldtop;
      end
      else // top of texture at top
        rw_bottomtexturemid := worldlow;
    end;
    rw_toptexturemid := rw_toptexturemid + sidedef.rowoffset;
    rw_bottomtexturemid := rw_bottomtexturemid + sidedef.rowoffset;

    // allocate space for masked texture tables
    if boolval(sidedef.midtexture) then
    begin
      // masked midtexture
      maskedtexture := true;
      maskedtexturecol := PSmallIntArray(@openings[lastopening - rw_x]);
      drawsegs[ds_p].maskedtexturecol := maskedtexturecol;
	    lastopening := lastopening + rw_stopx - rw_x;
    end;
  end;

  // calculate rw_offset (only needed for textured lines)
  segtextured := boolval(midtexture or toptexture or bottomtexture) or maskedtexture;

  if segtextured then
  begin
    offsetangle := rw_normalangle - rw_angle1;

    if offsetangle > ANG180 then
      offsetangle := -offsetangle;

    if offsetangle > ANG90 then
      offsetangle := ANG90;

    sineval := finesine[_SHRW(offsetangle, ANGLETOFINESHIFT)];
    rw_offset := FixedMul(hyp, sineval);

    if rw_normalangle - rw_angle1 < ANG180 then
      rw_offset := -rw_offset;

    rw_offset := rw_offset + sidedef.textureoffset + curline.offset;
    rw_centerangle := ANG90 + viewangle - rw_normalangle;

    // calculate light table
    //  use different light tables
    //  for horizontal / vertical / diagonal
    // OPTIMIZE: get rid of LIGHTSEGSHIFT globally
    if not boolval(fixedcolormap) then
    begin
      lightnum := _SHR(frontsector.lightlevel, LIGHTSEGSHIFT) + extralight;

      if curline.v1.y = curline.v2.y then
        dec(lightnum)
      else if curline.v1.x = curline.v2.x then
        inc(lightnum);

      if lightnum < 0 then
        walllights := @scalelight[0, 0] // VJ ???
      else if lightnum >= LIGHTLEVELS then
        walllights := @scalelight[LIGHTLEVELS - 1, 0]
      else
        walllights := @scalelight[lightnum, 0];
    end;
  end;

  // if a floor / ceiling plane is on the wrong side
  //  of the view plane, it is definitely invisible
  //  and doesn't need to be marked.


  if frontsector.floorheight >= viewz then
  begin
    // above view plane
    markfloor := false;
  end;

  if (frontsector.ceilingheight <= viewz) and
     (frontsector.ceilingpic <> skyflatnum) then
  begin
    // below view plane
    markceiling := false;
  end;


  // calculate incremental stepping values for texture edges
  worldtop := _SHR(worldtop, 4);
  worldbottom := _SHR(worldbottom, 4);

  topstep := -FixedMul(rw_scalestep, worldtop);
  topfrac := _SHR(centeryfrac, 4) - FixedMul(worldtop, rw_scale);

  bottomstep := -FixedMul(rw_scalestep, worldbottom);
  bottomfrac := _SHR(centeryfrac, 4) - FixedMul(worldbottom, rw_scale);

  if boolval(backsector) then
  begin
    worldhigh := _SHR(worldhigh, 4);
    worldlow := _SHR(worldlow, 4);

    if worldhigh < worldtop then
    begin
      pixhigh := _SHR(centeryfrac, 4) - FixedMul(worldhigh, rw_scale);
      pixhighstep := -FixedMul(rw_scalestep, worldhigh);
    end;

    if worldlow > worldbottom then
    begin
      pixlow := _SHR(centeryfrac, 4) - FixedMul(worldlow, rw_scale);
	    pixlowstep := -FixedMul(rw_scalestep, worldlow);
    end;
  end;

  // render it
  if markceiling then
    ceilingplane := R_CheckPlane(ceilingplane, rw_x, rw_stopx - 1);

  if markfloor then
    floorplane := R_CheckPlane(floorplane, rw_x, rw_stopx - 1);

  R_RenderSegLoop;


  // save sprite clipping info
  if (boolval(drawsegs[ds_p].silhouette and SIL_TOP) or maskedtexture) and
	   (not boolval(drawsegs[ds_p].sprtopclip)) then
  begin
    memcpy(@openings[lastopening], @ceilingclip[start], SizeOf(ceilingclip[0]) * (rw_stopx - start));
    drawsegs[ds_p].sprtopclip := PSmallIntArray(@openings[lastopening - start]);
    lastopening := lastopening + rw_stopx - start;
  end;

  if (boolval(drawsegs[ds_p].silhouette and SIL_BOTTOM) or maskedtexture) and
     (not boolval(drawsegs[ds_p].sprbottomclip)) then
  begin
    memcpy(@openings[lastopening], @floorclip[start], SizeOf(floorclip[0]) * (rw_stopx - start));
    drawsegs[ds_p].sprbottomclip := PSmallIntArray(@openings[lastopening - start]);
    lastopening := lastopening + rw_stopx - start;
  end;

  if maskedtexture and (not boolval(drawsegs[ds_p].silhouette and SIL_TOP)) then
  begin
    drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette or SIL_TOP;
    drawsegs[ds_p].tsilheight := MININT;
  end;
  if maskedtexture and (not boolval(drawsegs[ds_p].silhouette and SIL_BOTTOM)) then
  begin
    drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette or SIL_BOTTOM;
    drawsegs[ds_p].bsilheight := MAXINT;
  end;
  inc(ds_p);
end;


end.
