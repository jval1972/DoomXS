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

uses
  d_delphi,
  m_fixed,
  tables,
  r_defs;

procedure R_RenderMaskedSegRange(ds: Pdrawseg_t; x1, x2: integer);

procedure R_StoreWallRange(start: integer; stop: integer);

var
  maskedtexturecol: PSmallIntArray;
// angle to line origin
  rw_angle1: angle_t;

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

// regular wall
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

  pixhigh: int64; // R_WiggleFix
  pixlow: int64; // R_WiggleFix
  pixhighstep: fixed_t;
  pixlowstep: fixed_t;

  topfrac: int64; // R_WiggleFix
  topstep: fixed_t;

  bottomfrac: int64; // R_WiggleFix
  bottomstep: fixed_t;

  walllights: Plighttable_tPArray;

implementation

uses
  doomtype,
  doomdef,
  doomstat,
  doomdata,
  i_system,
  r_main,
  r_data,
  r_bsp,
  r_sky,
  r_things,
  r_draw,
  r_plane;

// OPTIMIZE: closed two sided lines as single sided

// R_RenderMaskedSegRange
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
    walllights := @scalelight[0, 0]
  else if lightnum >= LIGHTLEVELS then
    walllights := @scalelight[LIGHTLEVELS - 1, 0]
  else
    walllights := @scalelight[lightnum];

  maskedtexturecol := ds.maskedtexturecol;

  rw_scalestep := ds.scalestep;
  spryscale := ds.scale1 + (x1 - ds.x1) * rw_scalestep;
  mfloorclip := ds.sprbottomclip;
  mceilingclip := ds.sprtopclip;

  // find positioning
  if curline.linedef.flags and ML_DONTPEGBOTTOM <> 0 then
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

  if fixedcolormap <> nil then
    dc_colormap := fixedcolormap;

  // draw the columns
  for i := x1 to x2 do
  begin
    dc_x := i;
    // calculate lighting
    if maskedtexturecol[dc_x] <> MAXSHORT then
    begin
      if fixedcolormap = nil then
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
// Draws zero, one, or two textures (and possibly a masked texture) for walls.
// Can draw or mark the starting pixel of floor and ceiling textures.
// CALLED: CORE LOOPING ROUTINE.
//
var
  HEIGHTBITS: integer = 12;
  HEIGHTUNIT: integer = 1 shl 12;
  WORLDBITS: integer = 4;
  WORLDUNIT: integer = 1 shl 4;

//
// R_FixWiggle()
// Dynamic wall/texture rescaler, AKA "WiggleHack II"
//  by Kurt "kb1" Baumgardner ("kb")
//
//  [kb] When the rendered view is positioned, such that the viewer is
//   looking almost parallel down a wall, the result of the scale
//   calculation in R_ScaleFromGlobalAngle becomes very large. And, the
//   taller the wall, the larger that value becomes. If these large
//   values were used as-is, subsequent calculations would overflow
//   and crash the program.
//
//  Therefore, vanilla Doom clamps this scale calculation, preventing it
//   from becoming larger than 0x400000 (64*FRACUNIT). This number was
//   chosen carefully, to allow reasonably-tight angles, with reasonably
//   tall sectors to be rendered, within the limits of the fixed-point
//   math system being used. When the scale gets clamped, Doom cannot
//   properly render the wall, causing an undesirable wall-bending
//   effect that I call "floor wiggle".
//
//  Modern source ports offer higher video resolutions, which worsens
//   the issue. And, Doom is simply not adjusted for the taller walls
//   found in many PWADs.
//
//  WiggleHack II attempts to correct these issues, by dynamically
//   adjusting the fixed-point math, and the maximum scale clamp,
//   on a wall-by-wall basis. This has 2 effects:
//
//  1. Floor wiggle is greatly reduced and/or eliminated.
//  2. Overflow is not longer possible, even in levels with maximum
//     height sectors.
//
//  It is not perfect across all situations. Some floor wiggle can be
//   seen, and some texture strips may be slight misaligned in extreme
//   cases. These effects cannot be corrected without increasing the
//   precision of various renderer variables, and, possibly, suffering
//   a performance penalty.
//

var
  lastheight: integer = 0;

type
  wiggle_t = record
    clamp: integer;
    heightbits: integer;
  end;

var
  scale_values: array[0..8] of wiggle_t = (
    (clamp: 2048 * FRACUNIT; heightbits: 12),
    (clamp: 1024 * FRACUNIT; heightbits: 12),
    (clamp: 1024 * FRACUNIT; heightbits: 11),
    (clamp:  512 * FRACUNIT; heightbits: 11),
    (clamp:  512 * FRACUNIT; heightbits: 10),
    (clamp:  256 * FRACUNIT; heightbits: 10),
    (clamp:  256 * FRACUNIT; heightbits:  9),
    (clamp:  128 * FRACUNIT; heightbits:  9),
    (clamp:   64 * FRACUNIT; heightbits:  9)
  );

procedure R_WiggleFix(sec: Psector_t);
var
  height: integer;
begin
  height := (sec.ceilingheight - sec.floorheight) div FRACUNIT;

  // disallow negative heights, force cache initialization
  if height < 1 then
    height := 1;

  // early out?
  if height <> lastheight then
  begin
    lastheight := height;

    // initialize, or handle moving sector
    if height <> sec.cachedheight then
    begin
      frontsector.cachedheight := height;
      frontsector.scaleindex := 0;
      height := height shr  7;
      // calculate adjustment
      while true do
      begin
        height := height shr 1;
        if height <> 0 then
          inc(frontsector.scaleindex)
        else
          break;
      end;
    end;

    // fine-tune renderer for this wall
    MAX_RWSCALE := scale_values[frontsector.scaleindex].clamp;
    HEIGHTBITS := scale_values[frontsector.scaleindex].heightbits;
    HEIGHTUNIT := 1 shl HEIGHTBITS;
    WORLDBITS := 16 - HEIGHTBITS;
    WORLDUNIT := 1 shl WORLDBITS;
  end;
end;


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
      // SoM: this should be set here
      if bottom > viewheight then
        bottom := viewheight
      else if bottom < 0 then
        bottom := -1;
      ceilingclip[rw_x] := bottom;
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
      // SoM: this should be set here to prevent overdraw
      if top > viewheight then
        top := viewheight
      else if top < -1 then
        top := -1;
      floorclip[rw_x] := top;
    end;

    // texturecolumn and lighting are independent of wall tiers
    if segtextured then
    begin
      // calculate texture offset
      angle := (rw_centerangle + xtoviewangle[rw_x]) shr ANGLETOFINESHIFT;
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
    if midtexture <> 0 then
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
      if toptexture <> 0 then
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

      if bottomtexture <> 0 then
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
  pds: Pdrawseg_t;
begin
  // don't overflow and crash
  if ds_p = MAXDRAWSEGS then
    exit;

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
  sineval := finesine[distangle shr ANGLETOFINESHIFT];
  rw_distance := FixedMul(hyp, sineval);

  rw_x := start;
  pds := @drawsegs[ds_p];
  pds.x1 := rw_x;
  pds.x2 := stop;
  pds.curline := curline;
  rw_stopx := stop + 1;

  // calculate scale at both ends and step
  rw_scale := R_ScaleFromGlobalAngle(viewangle + xtoviewangle[start]);
  pds.scale1 := rw_scale;

  if stop > start then
  begin
    pds.scale2 := R_ScaleFromGlobalAngle(viewangle + xtoviewangle[stop]);
    rw_scalestep := (pds.scale2 - rw_scale) div (stop - start);
    pds.scalestep := rw_scalestep
  end
  else
    pds.scale2 := pds.scale1;

  // calculate texture boundaries
  //  and decide if floor / ceiling marks are needed
  worldtop := frontsector.ceilingheight - viewz;
  worldbottom := frontsector.floorheight - viewz;

  R_WiggleFix(frontsector);

  midtexture := 0;
  toptexture := 0;
  bottomtexture := 0;
  maskedtexture := false;
  pds.maskedtexturecol := nil;

  if backsector = nil then
  begin
    // single sided line
    midtexture := texturetranslation[sidedef.midtexture];
    // a single sided line is terminal, so it must mark ends
    markfloor := true;
    markceiling := true;
    if linedef.flags and ML_DONTPEGBOTTOM <> 0 then
    begin
      vtop := frontsector.floorheight + textureheight[sidedef.midtexture];
      // bottom of texture at bottom
      rw_midtexturemid := vtop - viewz;
    end
    else
      rw_midtexturemid := worldtop; // top of texture at top
    rw_midtexturemid := rw_midtexturemid + sidedef.rowoffset;

    pds.silhouette := SIL_BOTH;
    pds.sprtopclip := @screenheightarray;
    pds.sprbottomclip := @negonearray;
    pds.bsilheight := MAXINT;
    pds.tsilheight := MININT;
  end
  else
  begin
    // two sided line
    pds.sprtopclip := nil;
    pds.sprbottomclip := nil;
    pds.silhouette := 0;

    if frontsector.floorheight > backsector.floorheight then
    begin
      pds.silhouette := SIL_BOTTOM;
      pds.bsilheight := frontsector.floorheight;
    end
    else if backsector.floorheight > viewz then
    begin
      pds.silhouette := SIL_BOTTOM;
      pds.bsilheight := MAXINT;
    end;

    if frontsector.ceilingheight < backsector.ceilingheight then
    begin
      pds.silhouette := pds.silhouette or SIL_TOP;
      pds.tsilheight := frontsector.ceilingheight;
    end
    else if backsector.ceilingheight < viewz then
    begin
      pds.silhouette := pds.silhouette or SIL_TOP;
      pds.tsilheight := MININT;
    end;

    if backsector.ceilingheight <= frontsector.floorheight then
    begin
      pds.sprbottomclip := @negonearray;
      pds.bsilheight := MAXINT;
      pds.silhouette := pds.silhouette or SIL_BOTTOM;
    end;

    if backsector.floorheight >= frontsector.ceilingheight then
    begin
      pds.sprtopclip := @screenheightarray;
      pds.tsilheight := MININT;
      pds.silhouette := pds.silhouette or SIL_TOP;
    end;

    worldhigh := backsector.ceilingheight - viewz;
    worldlow := backsector.floorheight - viewz;

    // hack to allow height changes in outdoor areas
    if (frontsector.ceilingpic = skyflatnum) and
       (backsector.ceilingpic = skyflatnum) then
      worldtop := worldhigh;

    if (backsector.ceilingheight <= frontsector.floorheight) or
       (backsector.floorheight >= frontsector.ceilingheight) then
    begin
      // closed door
      markceiling := true;
      markfloor := true;
    end
    else
    begin
      markfloor := (worldlow <> worldbottom) or
                   (backsector.floorpic <> frontsector.floorpic) or
                   (backsector.lightlevel <> frontsector.lightlevel);

      markceiling := (worldhigh <> worldtop) or
                     (backsector.ceilingpic <> frontsector.ceilingpic) or
                     (backsector.lightlevel <> frontsector.lightlevel);
    end;

    if worldhigh < worldtop then
    begin
      // top texture
      toptexture := texturetranslation[sidedef.toptexture];
      if linedef.flags and ML_DONTPEGTOP <> 0 then
        rw_toptexturemid := worldtop  // top of texture at top
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

      if linedef.flags and ML_DONTPEGBOTTOM <> 0 then
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
    if sidedef.midtexture <> 0 then
    begin
      // masked midtexture
      maskedtexture := true;
      maskedtexturecol := PSmallIntArray(@openings[lastopening - rw_x]);
      pds.maskedtexturecol := maskedtexturecol;
      lastopening := lastopening + rw_stopx - rw_x;
    end;
  end;

  // calculate rw_offset (only needed for textured lines)
  segtextured := (midtexture <> 0) or (toptexture <> 0) or (bottomtexture <> 0) or maskedtexture;

  if segtextured then
  begin
    offsetangle := rw_normalangle - rw_angle1;

    if offsetangle > ANG180 then
      offsetangle := -offsetangle;

    if offsetangle > ANG90 then
      offsetangle := ANG90;

    sineval := finesine[offsetangle shr ANGLETOFINESHIFT];
    rw_offset := FixedMul(hyp, sineval);

    if rw_normalangle - rw_angle1 < ANG180 then
      rw_offset := -rw_offset;

    rw_offset := rw_offset + sidedef.textureoffset + curline.offset;
    rw_centerangle := ANG90 + viewangle - rw_normalangle;

    // calculate light table
    //  use different light tables
    //  for horizontal / vertical / diagonal
    // OPTIMIZE: get rid of LIGHTSEGSHIFT globally
    if fixedcolormap = nil then
    begin
      lightnum := _SHR(frontsector.lightlevel, LIGHTSEGSHIFT) + extralight;

      if curline.v1.y = curline.v2.y then
        dec(lightnum)
      else if curline.v1.x = curline.v2.x then
        inc(lightnum);

      if lightnum < 0 then
        walllights := @scalelight[0, 0]
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
    markfloor := false; // above view plane

  if (frontsector.ceilingheight <= viewz) and
     (frontsector.ceilingpic <> skyflatnum) then
    markceiling := false; // below view plane

  // calculate incremental stepping values for texture edges
  worldtop := _SHR(worldtop, WORLDBITS);
  worldbottom := _SHR(worldbottom, WORLDBITS);

  topstep := -FixedMul(rw_scalestep, worldtop);
  topfrac := _SHR(centeryfrac, WORLDBITS) - FixedMul(worldtop, rw_scale);

  bottomstep := -FixedMul(rw_scalestep, worldbottom);
  bottomfrac := _SHR(centeryfrac, WORLDBITS) - FixedMul(worldbottom, rw_scale);

  if backsector <> nil then
  begin
    worldhigh := _SHR(worldhigh, WORLDBITS);
    worldlow := _SHR(worldlow, WORLDBITS);

    if worldhigh < worldtop then
    begin
      pixhigh := _SHR(centeryfrac, WORLDBITS) - FixedMul(worldhigh, rw_scale);
      pixhighstep := -FixedMul(rw_scalestep, worldhigh);
    end;

    if worldlow > worldbottom then
    begin
      pixlow := _SHR(centeryfrac, WORLDBITS) - FixedMul(worldlow, rw_scale);
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
  if ((pds.silhouette and SIL_TOP <> 0) or maskedtexture) and
     (pds.sprtopclip = nil) then
  begin
    memcpy(@openings[lastopening], @ceilingclip[start], SizeOf(ceilingclip[0]) * (rw_stopx - start));
    pds.sprtopclip := PSmallIntArray(@openings[lastopening - start]);
    lastopening := lastopening + rw_stopx - start;
  end;

  if ((pds.silhouette and SIL_BOTTOM <> 0) or maskedtexture) and
     (pds.sprbottomclip = nil) then
  begin
    memcpy(@openings[lastopening], @floorclip[start], SizeOf(floorclip[0]) * (rw_stopx - start));
    pds.sprbottomclip := PSmallIntArray(@openings[lastopening - start]);
    lastopening := lastopening + rw_stopx - start;
  end;

  if maskedtexture and (pds.silhouette and SIL_TOP = 0) then
  begin
    pds.silhouette := pds.silhouette or SIL_TOP;
    pds.tsilheight := MININT;
  end;
  if maskedtexture and (pds.silhouette and SIL_BOTTOM = 0) then
  begin
    pds.silhouette := pds.silhouette or SIL_BOTTOM;
    pds.bsilheight := MAXINT;
  end;
  inc(ds_p);
end;

end.
