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

unit r_bsp;

interface

uses
  r_defs;

// BSP?
procedure R_ClearClipSegs;
procedure R_ClearDrawSegs;


procedure R_RenderBSPNode(bspnum: integer);

type
  drawfunc_t = procedure(start: integer; stop: integer);

var
  ds_p: integer;

  curline: Pseg_t;
  frontsector: Psector_t;
  backsector: Psector_t;

  sidedef: Pside_t;
  linedef: Pline_t;
  drawsegs: array[0..MAXDRAWSEGS - 1] of drawseg_t;


implementation

uses
  d_delphi,
  doomdata,
  m_fixed,
  tables,
  doomdef,
  m_bbox,
  i_system,
  p_setup,
  r_segs,
  r_main,
  r_plane,
  r_things,
  r_draw,
  r_sky,
  // State.
  doomstat;


// R_ClearDrawSegs

procedure R_ClearDrawSegs;
begin
  ds_p := 0;
end;


// ClipWallSegment
// Clips the given range of columns
// and includes it in the new clip list.

type
  cliprange_t = record
    First: integer;
    last: integer;
  end;
  Pcliprange_t = ^cliprange_t;

const
  MAXSEGS = 32;

var
  // newend is one past the last valid seg
  newend: integer;
  solidsegs: array[0..MAXSEGS - 1] of cliprange_t;


// R_ClipSolidWallSegment
// Does handle solid walls,
//  e.g. single sided LineDefs (middle texture)
//  that entirely block the view.

procedure R_ClipSolidWallSegment(First, last: integer);
var
  next: integer;
  start: integer;

  procedure crunch;
  begin
    if next = start then
      // Post just extended past the bottom of one post.
      exit;
    while next <> newend do
    begin
      // Remove a post.
      Inc(start);
      Inc(next);       // VJ maybe after????
      solidsegs[start] := solidsegs[next];
    end;
    newend := start + 1;
  end;

begin
  // Find the first range that touches the range
  //  (adjacent pixels are touching).
  start := 0;
  while solidsegs[start].last < First - 1 do
    Inc(start);

  if First < solidsegs[start].First then
  begin
    if last < solidsegs[start].First - 1 then
    begin
      // Post is entirely visible (above start),
      //  so insert a new clippost.
      R_StoreWallRange(First, last);
      next := newend;
      Inc(newend);

      while next <> start do
      begin
        solidsegs[next] := solidsegs[next - 1];
        Dec(next);
      end;
      solidsegs[next].First := First;
      solidsegs[next].last := last;
      exit;
    end;

    // There is a fragment above *start.
    R_StoreWallRange(First, solidsegs[start].First - 1);
    // Now adjust the clip size.
    solidsegs[start].First := First;
  end;

  // Bottom contained in start?
  if last <= solidsegs[start].last then
    exit;

  next := start;
  while last >= solidsegs[next + 1].First - 1 do
  begin
    // There is a fragment between two posts.
    R_StoreWallRange(solidsegs[next].last + 1, solidsegs[next + 1].First - 1);
    Inc(next);

    if last <= solidsegs[next].last then
    begin
      // Bottom is contained in next.
      // Adjust the clip size.
      solidsegs[start].last := solidsegs[next].last;
      crunch;
      exit;
    end;
  end;

  // There is a fragment after *next.
  R_StoreWallRange(solidsegs[next].last + 1, last);
  // Adjust the clip size.
  solidsegs[start].last := last;

  // Remove start+1 to next from the clip list,
  // because start now covers their area.
  crunch;
end;


// R_ClipPassWallSegment
// Clips the given range of columns,
//  but does not includes it in the clip list.
// Does handle windows,
//  e.g. LineDefs with upper and lower texture.

procedure R_ClipPassWallSegment(First, last: integer);
var
  start: integer;
begin
  // Find the first range that touches the range
  //  (adjacent pixels are touching).
  start := 0;
  while solidsegs[start].last < First - 1 do
    Inc(start);

  if First < solidsegs[start].First then
  begin
    if last < solidsegs[start].First - 1 then
    begin
      // Post is entirely visible (above start).
      R_StoreWallRange(First, last);
      exit;
    end;
    // There is a fragment above *start.
    R_StoreWallRange(First, solidsegs[start].First - 1);
  end;

  // Bottom contained in start?
  if last <= solidsegs[start].last then
    exit;

  while last >= solidsegs[start + 1].First - 1 do
  begin
    // There is a fragment between two posts.
    R_StoreWallRange(solidsegs[start].last + 1, solidsegs[start + 1].First - 1);
    Inc(start);

    if last <= solidsegs[start].last then
      exit;
  end;

  // There is a fragment after *next.
  R_StoreWallRange(solidsegs[start].last + 1, last);
end;


// R_ClearClipSegs

procedure R_ClearClipSegs;
begin
  solidsegs[0].First := -$7fffffff;
  solidsegs[0].last := -1;
  solidsegs[1].First := viewwidth;
  solidsegs[1].last := $7fffffff;
  newend := 2;
end;


// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.

procedure R_AddLine(line: Pseg_t);
var
  x1: integer;
  x2: integer;
  angle1: angle_t;
  angle2: angle_t;
  span: angle_t;
  tspan: angle_t;
begin
  curline := line;

  // OPTIMIZE: quickly reject orthogonal back sides.
  angle1 := R_PointToAngle(line.v1.x, line.v1.y);
  angle2 := R_PointToAngle(line.v2.x, line.v2.y);

  // Clip to view edges.
  // OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
  span := angle1 - angle2;

  // Back side? I.e. backface culling?
  if span >= ANG180 then
    exit;

  // Global angle needed by segcalc.
  rw_angle1 := angle1;
  angle1 := angle1 - viewangle;
  angle2 := angle2 - viewangle;

  tspan := angle1 + clipangle;
  if tspan > 2 * clipangle then
  begin
    tspan := tspan - 2 * clipangle;

    // Totally off the left edge?
    if tspan >= span then
      exit;

    angle1 := clipangle;
  end;

  tspan := clipangle - angle2;
  if tspan > 2 * clipangle then
  begin
    tspan := tspan - 2 * clipangle;

    // Totally off the left edge?
    if tspan >= span then
      exit;

    angle2 := -clipangle;
  end;

  // The seg is in the view range,
  // but not necessarily visible.
  angle1 := _SHRW(angle1 + ANG90, ANGLETOFINESHIFT);
  angle2 := _SHRW(angle2 + ANG90, ANGLETOFINESHIFT);
  x1 := viewangletox[angle1];
  x2 := viewangletox[angle2];

  // Does not cross a pixel?
  if x1 = x2 then
    exit;

  backsector := line.backsector;

  // Single sided line?
  if backsector = nil then
  begin
    R_ClipSolidWallSegment(x1, x2 - 1);
    exit;
  end;

  // Closed door.
  if (backsector.ceilingheight <= frontsector.floorheight) or
    (backsector.floorheight >= frontsector.ceilingheight) then
  begin
    R_ClipSolidWallSegment(x1, x2 - 1);
    exit;
  end;

  // Window.
  if (backsector.ceilingheight <> frontsector.ceilingheight) or
    (backsector.floorheight <> frontsector.floorheight) then
  begin
    R_ClipPassWallSegment(x1, x2 - 1);
    exit;
  end;

  // Reject empty lines used for triggers
  //  and special events.
  // Identical floor and ceiling on both sides,
  // identical light levels on both sides,
  // and no middle texture.
  if (backsector.ceilingpic = frontsector.ceilingpic) and
    (backsector.floorpic = frontsector.floorpic) and
    (backsector.lightlevel = frontsector.lightlevel) and
    (curline.sidedef.midtexture = 0) then
    exit;

  R_ClipPassWallSegment(x1, x2 - 1);
end;


// R_CheckBBox
// Checks BSP node/subtree bounding box.
// Returns true
//  if some part of the bbox might be visible.

const
  checkcoord: array[0..11, 0..3] of integer = (
    (3, 0, 2, 1),
    (3, 0, 2, 0),
    (3, 1, 2, 0),
    (0, 0, 0, 0),
    (2, 0, 2, 1),
    (0, 0, 0, 0),
    (3, 1, 3, 0),
    (0, 0, 0, 0),
    (2, 0, 3, 1),
    (2, 1, 3, 1),
    (2, 1, 3, 0),
    (0, 0, 0, 0)
    );

function R_CheckBBox(bspcoordA: Pfixed_tArray; const side: integer): boolean;
var
  bspcoord: array[0..3] of fixed_t; // VJ
  boxx: integer;
  boxy: integer;
  boxpos: integer;
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
  angle1: angle_t;
  angle2: angle_t;
  span: angle_t;
  tspan: angle_t;
  start: integer;
  sx1: integer;
  sx2: integer;
begin
  if side = 0 then
  begin
    bspcoord[0] := bspcoordA[0];
    bspcoord[1] := bspcoordA[1];
    bspcoord[2] := bspcoordA[2];
    bspcoord[3] := bspcoordA[3];
  end
  else
  begin
    bspcoord[0] := bspcoordA[4];
    bspcoord[1] := bspcoordA[5];
    bspcoord[2] := bspcoordA[6];
    bspcoord[3] := bspcoordA[7];
  end;

  // Find the corners of the box
  // that define the edges from current viewpoint.
  if viewx <= bspcoord[BOXLEFT] then
    boxx := 0
  else if viewx < bspcoord[BOXRIGHT] then
    boxx := 1
  else
    boxx := 2;

  if viewy >= bspcoord[BOXTOP] then
    boxy := 0
  else if viewy > bspcoord[BOXBOTTOM] then
    boxy := 1
  else
    boxy := 2;

  boxpos := _SHL(boxy, 2) + boxx;
  if boxpos = 5 then
  begin
    Result := True;
    exit;
  end;

  x1 := bspcoord[checkcoord[boxpos][0]];
  y1 := bspcoord[checkcoord[boxpos][1]];
  x2 := bspcoord[checkcoord[boxpos][2]];
  y2 := bspcoord[checkcoord[boxpos][3]];

  // check clip list for an open space
  angle1 := R_PointToAngle(x1, y1) - viewangle;
  angle2 := R_PointToAngle(x2, y2) - viewangle;

  span := angle1 - angle2;

  // Sitting on a line?
  if span >= ANG180 then
  begin
    Result := True;
    exit;
  end;

  tspan := angle1 + clipangle;

  if tspan > 2 * clipangle then
  begin
    tspan := tspan - 2 * clipangle;

    // Totally off the left edge?
    if tspan >= span then
    begin
      Result := False;
      exit;
    end;

    angle1 := clipangle;
  end;

  tspan := clipangle - angle2;
  if tspan > 2 * clipangle then
  begin
    tspan := tspan - 2 * clipangle;

    // Totally off the left edge?
    if tspan >= span then
    begin
      Result := False;
      exit;
    end;

    angle2 := -clipangle;
  end;


  // Find the first clippost
  //  that touches the source post
  //  (adjacent pixels are touching).
  angle1 := _SHRW(angle1 + ANG90, ANGLETOFINESHIFT);
  angle2 := _SHRW(angle2 + ANG90, ANGLETOFINESHIFT);
  sx1 := viewangletox[angle1];
  sx2 := viewangletox[angle2];

  // Does not cross a pixel.
  if sx1 = sx2 then
  begin
    Result := False;
    exit;
  end;

  Dec(sx2);

  start := 0;
  while solidsegs[start].last < sx2 do
    Inc(start);

  if (sx1 >= solidsegs[start].First) and (sx2 <= solidsegs[start].last) then
    // The clippost contains the new span.
    Result := False
  else
    Result := True;
end;


// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.

procedure R_Subsector(num: integer);
var
  count: integer;
  line: Pseg_t;
  i_line: integer;
  sub: Psubsector_t;
begin
  Inc(sscount);
  sub := @subsectors[num];
  frontsector := sub.sector;
  count := sub.numlines;
  i_line := sub.firstline;
  line := @segs[i_line];

  if frontsector.floorheight < viewz then
  begin
    floorplane := R_FindPlane(frontsector.floorheight,
      frontsector.floorpic,
      frontsector.lightlevel);
  end
  else
    floorplane := nil;

  if (frontsector.ceilingheight > viewz) or (frontsector.ceilingpic =
    skyflatnum) then
  begin
    ceilingplane := R_FindPlane(frontsector.ceilingheight,
      frontsector.ceilingpic,
      frontsector.lightlevel);
  end
  else
    ceilingplane := nil;

  R_AddSprites(frontsector);

  while count <> 0 do
  begin
    R_AddLine(line);
    Inc(i_line);
    line := @segs[i_line];
    Dec(count);
  end;
end;



// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.
procedure R_RenderBSPNode(bspnum: integer);
var
  bsp: Pnode_t;
  side: integer;
begin
  // Found a subsector?
  if bspnum and NF_SUBSECTOR <> 0 then
  begin
    if bspnum = -1 then
      R_Subsector(0)
    else
      R_Subsector(bspnum and not NF_SUBSECTOR);
    exit;
  end;

  bsp := @nodes[bspnum];

  // Decide which side the view point is on.

  if R_PointOnSide(viewx, viewy, bsp) then
    side := 1
  else
    side := 0;

  // Recursively divide front space.
  R_RenderBSPNode(bsp.children[side]);

  // Possibly divide back space.
  if R_CheckBBox(Pfixed_tArray(@(bsp^.bbox)), side xor 1) then
    R_RenderBSPNode(bsp.children[side xor 1]);
end;

end.
