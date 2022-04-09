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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/doomxs/
//------------------------------------------------------------------------------

unit p_maputl;

interface

uses
  m_bbox,
  p_local,
  p_mobj_h,
  m_fixed,
  r_defs;

function P_AproxDistance(dx: fixed_t; dy: fixed_t): fixed_t;

function P_PointOnLineSide(x: fixed_t; y: fixed_t; line: Pline_t): integer;

function P_BoxOnLineSide(tmbox: Pfixed_tArray; ld: Pline_t): integer;

function P_InterceptVector(v2: Pdivline_t; v1: Pdivline_t): fixed_t;

procedure P_LineOpening(linedef: Pline_t);

procedure P_UnsetThingPosition(thing: Pmobj_t);

procedure P_SetThingPosition(thing: Pmobj_t);

function P_BlockLinesIterator(x, y: integer; func: ltraverser_t): boolean;

function P_BlockThingsIterator(x, y: integer; func: ttraverser_t): boolean;

function P_PathTraverse(x1, y1, x2, y2: fixed_t; flags: integer;
  trav: traverser_t): boolean;

var
  opentop: fixed_t;
  openbottom: fixed_t;
  openrange: fixed_t;
  lowfloor: fixed_t;
  trace: divline_t;

implementation

uses
  d_delphi,
  i_system,
  p_setup,
  r_main;

// P_AproxDistance
// Gives an estimation of distance (not exact)
function P_AproxDistance(dx: fixed_t; dy: fixed_t): fixed_t;
begin
  dx := abs(dx);
  dy := abs(dy);
  if dx < dy then
    Result := dx + dy - _SHR(dx, 1)
  else
    Result := dx + dy - _SHR(dy, 1);
end;

// P_PointOnLineSide
// Returns 0 or 1
function P_PointOnLineSide(x: fixed_t; y: fixed_t; line: Pline_t): integer;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if line.dx = 0 then
  begin
    if x <= line.v1.x then
      Result := intval(line.dy > 0)
    else
      Result := intval(line.dy < 0);
    Exit;
  end;

  if line.dy = 0 then
  begin
    if y <= line.v1.y then
      Result := intval(line.dx < 0)
    else
      Result := intval(line.dx > 0);
    Exit;
  end;

  dx := x - line.v1.x;
  dy := y - line.v1.y;

  left := FixedMul(_SHR(line.dy, FRACBITS), dx);
  right := FixedMul(dy, _SHR(line.dx, FRACBITS));

  if right < left then
    Result := 0  // front side
  else
    Result := 1; // back side
end;

// P_BoxOnLineSide
// Considers the line to be infinite
// Returns side 0 or 1, -1 if box crosses the line.
function P_BoxOnLineSide(tmbox: Pfixed_tArray; ld: Pline_t): integer;
var
  p1: integer;
  p2: integer;
begin
  case ld.slopetype of
    ST_HORIZONTAL:
    begin
      p1 := intval(tmbox[BOXTOP] > ld.v1.y);
      p2 := intval(tmbox[BOXBOTTOM] > ld.v1.y);
      if ld.dx < 0 then
      begin
        p1 := p1 xor 1;
        p2 := p2 xor 1;
      end;
    end;
    ST_VERTICAL:
    begin
      p1 := intval(tmbox[BOXRIGHT] < ld.v1.x);
      p2 := intval(tmbox[BOXLEFT] < ld.v1.x);
      if ld.dy < 0 then
      begin
        p1 := p1 xor 1;
        p2 := p2 xor 1;
      end;
    end;
    ST_POSITIVE:
    begin
      p1 := P_PointOnLineSide(tmbox[BOXLEFT], tmbox[BOXTOP], ld);
      p2 := P_PointOnLineSide(tmbox[BOXRIGHT], tmbox[BOXBOTTOM], ld);
    end;
    ST_NEGATIVE:
    begin
      p1 := P_PointOnLineSide(tmbox[BOXRIGHT], tmbox[BOXTOP], ld);
      p2 := P_PointOnLineSide(tmbox[BOXLEFT], tmbox[BOXBOTTOM], ld);
    end;
    else
    begin
      p1 := 0;
      p2 := 0;
      I_Error('P_BoxOnLineSide(): wierd slopetype %d', [Ord(ld.slopetype)]);
    end;
  end;
  if p1 = p2 then
    Result := p1
  else
    Result := -1;
end;

// P_PointOnDivlineSide
// Returns 0 or 1.
function P_PointOnDivlineSide(x: fixed_t; y: fixed_t; line: Pdivline_t): integer;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if line.dx = 0 then
  begin
    if x <= line.x then
      Result := intval(line.dy > 0)
    else
      Result := intval(line.dy < 0);
    Exit;
  end;

  if line.dy = 0 then
  begin
    if y <= line.y then
      Result := intval(line.dx < 0)
    else
      Result := intval(line.dx > 0);
    Exit;
  end;

  dx := x - line.x;
  dy := y - line.y;

  // try to quickly decide by looking at sign bits
  if (line.dy xor line.dx xor dx xor dy) and $80000000 <> 0 then
  begin //(left is negative)
    Result := (line.dy xor dx) and $80000000;
    if Result <> 0 then
      Result := 1;
    Exit;
  end;

  left := FixedMul(_SHR(line.dy, 8), _SHR(dx, 8));
  right := FixedMul(_SHR(dy, 8), _SHR(line.dx, 8));

  Result := intval(right >= left);
end;


// P_MakeDivline
procedure P_MakeDivline(li: Pline_t; dl: Pdivline_t);
begin
  dl.x := li.v1.x;
  dl.y := li.v1.y;
  dl.dx := li.dx;
  dl.dy := li.dy;
end;

// P_InterceptVector
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings
// and addlines traversers.
function P_InterceptVector(v2: Pdivline_t; v1: Pdivline_t): fixed_t;
var
  num: fixed_t;
  den: fixed_t;
begin
  den := FixedMul(_SHR(v1.dy, 8), v2.dx) - FixedMul(_SHR(v1.dx, 8), v2.dy);

  if den = 0 then
    Result := 0 // Parallel
  else
  begin
    num := FixedMul(_SHR((v1.x - v2.x), 8), v1.dy) +
      FixedMul(_SHR((v2.y - v1.y), 8), v1.dx);
    Result := FixedDiv(num, den);
  end;
end;

// P_LineOpening
// Sets opentop and openbottom to the window
// through a two sided line.
// OPTIMIZE: keep this precalculated
procedure P_LineOpening(linedef: Pline_t);
var
  front: Psector_t;
  back: Psector_t;
begin
  if linedef.sidenum[1] = -1 then
  begin
    // single sided line
    openrange := 0;
    Exit;
  end;

  front := linedef.frontsector;
  back := linedef.backsector;

  if front.ceilingheight < back.ceilingheight then
    opentop := front.ceilingheight
  else
    opentop := back.ceilingheight;

  if front.floorheight > back.floorheight then
  begin
    openbottom := front.floorheight;
    lowfloor := back.floorheight;
  end
  else
  begin
    openbottom := back.floorheight;
    lowfloor := front.floorheight;
  end;

  openrange := opentop - openbottom;
end;

// THING POSITION SETTING

// P_UnsetThingPosition
// Unlinks a thing from block map and sectors.
// On each position change, BLOCKMAP and other
// lookups maintaining lists ot things inside
// these structures need to be updated.
procedure P_UnsetThingPosition(thing: Pmobj_t);
var
  blockx: integer;
  blocky: integer;
begin
  if thing.flags and MF_NOSECTOR = 0 then
  begin
    // inert things don't need to be in blockmap?
    // unlink from subsector
    if thing.snext <> nil then
      thing.snext.sprev := thing.sprev;

    if thing.sprev <> nil then
      thing.sprev.snext := thing.snext
    else
      Psubsector_t(thing.subsector).sector.thinglist := thing.snext;
  end;

  if thing.flags and MF_NOBLOCKMAP = 0 then
  begin
    // inert things don't need to be in blockmap
    // unlink from block map
    if thing.bnext <> nil then
      thing.bnext.bprev := thing.bprev;

    if thing.bprev <> nil then
      thing.bprev.bnext := thing.bnext
    else
    begin
      blockx := _SHR((thing.x - bmaporgx), MAPBLOCKSHIFT);
      blocky := _SHR((thing.y - bmaporgy), MAPBLOCKSHIFT);

      if (blockx >= 0) and (blockx < bmapwidth) and (blocky >= 0) and
        (blocky < bmapheight) then
        blocklinks[blocky * bmapwidth + blockx] := thing.bnext;
    end;
  end;
end;

// P_SetThingPosition
// Links a thing into both a block and a subsector
// based on it's x y.
// Sets thing->subsector properly
procedure P_SetThingPosition(thing: Pmobj_t);
var
  ss: Psubsector_t;
  sec: Psector_t;
  blockx: integer;
  blocky: integer;
  link: ^Pmobj_t;
begin
  // link into subsector
  ss := R_PointInSubsector(thing.x, thing.y);
  thing.subsector := ss;

  if thing.flags and MF_NOSECTOR = 0 then
  begin
    // invisible things don't go into the sector links
    sec := ss.sector;

    thing.sprev := nil;
    thing.snext := sec.thinglist;

    if sec.thinglist <> nil then
      sec.thinglist.sprev := thing;

    sec.thinglist := thing;
  end;

  // link into blockmap
  if thing.flags and MF_NOBLOCKMAP = 0 then
  begin
    // inert things don't need to be in blockmap
    blockx := _SHR((thing.x - bmaporgx), MAPBLOCKSHIFT);
    blocky := _SHR((thing.y - bmaporgy), MAPBLOCKSHIFT);

    if (blockx >= 0) and (blockx < bmapwidth) and (blocky >= 0) and
      (blocky < bmapheight) then
    begin
      link := @blocklinks[blocky * bmapwidth + blockx];
      thing.bprev := nil;
      thing.bnext := link^;
      if link^ <> nil then
        (link^).bprev := thing;

      link^ := thing;
    end
    else
    begin
      // thing is off the map
      thing.bnext := nil;
      thing.bprev := nil;
    end;
  end;
end;

// BLOCK MAP ITERATORS
// For each line/thing in the given mapblock,
// call the passed PIT_* function.
// If the function returns False,
// Exit with False without checking anything else.

// P_BlockLinesIterator
// The validcount flags are used to avoid checking lines
// that are marked in multiple mapblocks,
// so increment validcount before the first call
// to P_BlockLinesIterator, then make one or more calls
// to it.
function P_BlockLinesIterator(x, y: integer; func: ltraverser_t): boolean;
var
  offset: PSmallInt;
  ld: Pline_t;
begin
  if (x < 0) or (y < 0) or (x >= bmapwidth) or (y >= bmapheight) then
  begin
    Result := True;
    Exit;
  end;

  offset := @blockmaplump[blockmap[y * bmapwidth + x]];

  while offset^ <> - 1 do
  begin
    ld := @lines[offset^];
    Inc(offset);
    if ld.validcount = validcount then
      Continue; // line has already been checked

    ld.validcount := validcount;

    if not func(ld) then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True; // everything was checked
end;

// P_BlockThingsIterator
function P_BlockThingsIterator(x, y: integer; func: ttraverser_t): boolean;
var
  mobj: Pmobj_t;
begin
  if (x < 0) or (y < 0) or (x >= bmapwidth) or (y >= bmapheight) then
  begin
    Result := True;
    Exit;
  end;

  mobj := blocklinks[y * bmapwidth + x];

  while mobj <> nil do
  begin
    if not func(mobj) then
    begin
      Result := False;
      Exit;
    end;
    mobj := mobj.bnext;
  end;

  Result := True;
end;

// INTERCEPT ROUTINES
var
  intercepts: array[0..MAXINTERCEPTS - 1] of intercept_t;
  intercept_p: integer;

  earlyout: boolean;

// PIT_AddLineIntercepts.
// Looks for lines in the given block
// that intercept the given trace
// to add to the intercepts list.

// A line is crossed if its endpoints
// are on opposite sides of the trace.
// Returns True if earlyout and a solid line hit.
function PIT_AddLineIntercepts(ld: Pline_t): boolean;
var
  s1: integer;
  s2: integer;
  frac: fixed_t;
  dl: divline_t;
begin
  // avoid precision problems with two routines
  if (trace.dx > FRACUNIT * 16) or (trace.dy > FRACUNIT * 16) or
    (trace.dx < -FRACUNIT * 16) or (trace.dy < -FRACUNIT * 16) then
  begin
    s1 := P_PointOnDivlineSide(ld.v1.x, ld.v1.y, @trace);
    s2 := P_PointOnDivlineSide(ld.v2.x, ld.v2.y, @trace);
  end
  else
  begin
    s1 := P_PointOnLineSide(trace.x, trace.y, ld);
    s2 := P_PointOnLineSide(trace.x + trace.dx, trace.y + trace.dy, ld);
  end;

  if s1 = s2 then
  begin
    Result := True; // line isn't crossed
    Exit;
  end;

  // hit the line
  P_MakeDivline(ld, @dl);
  frac := P_InterceptVector(@trace, @dl);

  if frac < 0 then
  begin
    Result := True; // behind source
    Exit;
  end;

  // try to early out the check
  if earlyout and (frac < FRACUNIT) and (ld.backsector = nil) then
  begin
    Result := False; // stop checking
    Exit;
  end;

  intercepts[intercept_p].frac := frac;
  intercepts[intercept_p].isaline := True;
  intercepts[intercept_p].d.line := ld;
  Inc(intercept_p);

  Result := True; // Continue
end;

// PIT_AddThingIntercepts
function PIT_AddThingIntercepts(thing: Pmobj_t): boolean;
var
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
  s1: integer;
  s2: integer;
  tracepositive: boolean;
  dl: divline_t;
  frac: fixed_t;
begin
  tracepositive := (trace.dx xor trace.dy) > 0;

  // check a corner to corner crossection for hit
  if tracepositive then
  begin
    x1 := thing.x - thing.radius;
    y1 := thing.y + thing.radius;
    x2 := thing.x + thing.radius;
    y2 := thing.y - thing.radius;
  end
  else
  begin
    x1 := thing.x - thing.radius;
    y1 := thing.y - thing.radius;
    x2 := thing.x + thing.radius;
    y2 := thing.y + thing.radius;
  end;

  s1 := P_PointOnDivlineSide(x1, y1, @trace);
  s2 := P_PointOnDivlineSide(x2, y2, @trace);

  if s1 = s2 then
  begin
    Result := True; // line isn't crossed
    Exit;
  end;

  dl.x := x1;
  dl.y := y1;
  dl.dx := x2 - x1;
  dl.dy := y2 - y1;

  frac := P_InterceptVector(@trace, @dl);

  if frac < 0 then
  begin
    Result := True; // behind source
    Exit;
  end;

  intercepts[intercept_p].frac := frac;
  intercepts[intercept_p].isaline := False;
  intercepts[intercept_p].d.thing := thing;
  Inc(intercept_p);

  Result := True; // keep going
end;

// P_TraverseIntercepts
// Returns True if the traverser function returns True
// for all lines.
function P_TraverseIntercepts(func: traverser_t; maxfrac: fixed_t): boolean;
var
  i: integer;
  dist: fixed_t;
  scan: integer;
  _in: Pintercept_t;
begin
  _in := nil; // shut up compiler warning

  for i := 0 to intercept_p - 1 do
  begin
    dist := MAXINT;

    for scan := 0 to intercept_p - 1 do
    begin
      if intercepts[scan].frac < dist then
      begin
        dist := intercepts[scan].frac;
        _in := @intercepts[scan];
      end;
    end;

    if dist > maxfrac then
    begin
      Result := True; // checked everything in range
      Exit;
    end;

    if not func(_in) then
    begin
      Result := False; // don't bother going farther
      Exit;
    end;
    _in.frac := MAXINT;
  end;

  Result := True;  // everything was traversed
end;

// P_PathTraverse
// Traces a line from x1,y1 to x2,y2,
// calling the traverser function for each.
// Returns True if the traverser function returns True
// for all lines.
function P_PathTraverse(x1, y1, x2, y2: fixed_t; flags: integer;
  trav: traverser_t): boolean;
var
  xt1: fixed_t;
  yt1: fixed_t;
  xt2: fixed_t;
  yt2: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  partial: fixed_t;
  xintercept: fixed_t;
  yintercept: fixed_t;
  mapx: integer;
  mapy: integer;
  mapxstep: integer;
  mapystep: integer;
  count: integer;
begin
  earlyout := flags and PT_EARLYOUT <> 0;

  Inc(validcount);
  intercept_p := 0;

  if (x1 - bmaporgx) and (MAPBLOCKSIZE - 1) = 0 then
    x1 := x1 + FRACUNIT; // don't side exactly on a line

  if (y1 - bmaporgy) and (MAPBLOCKSIZE - 1) = 0 then
    y1 := y1 + FRACUNIT; // don't side exactly on a line

  trace.x := x1;
  trace.y := y1;
  trace.dx := x2 - x1;
  trace.dy := y2 - y1;

  x1 := x1 - bmaporgx;
  y1 := y1 - bmaporgy;
  xt1 := _SHR(x1, MAPBLOCKSHIFT);
  yt1 := _SHR(y1, MAPBLOCKSHIFT);

  x2 := x2 - bmaporgx;
  y2 := y2 - bmaporgy;
  xt2 := _SHR(x2, MAPBLOCKSHIFT);
  yt2 := _SHR(y2, MAPBLOCKSHIFT);

  if xt2 > xt1 then
  begin
    mapxstep := 1;
    partial := FRACUNIT - (_SHR(x1, MAPBTOFRAC) and (FRACUNIT - 1));
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else if xt2 < xt1 then
  begin
    mapxstep := -1;
    partial := _SHR(x1, MAPBTOFRAC) and (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else
  begin
    mapxstep := 0;
    partial := FRACUNIT;
    ystep := 256 * FRACUNIT;
  end;

  yintercept := _SHR(y1, MAPBTOFRAC) + FixedMul(partial, ystep);

  if yt2 > yt1 then
  begin
    mapystep := 1;
    partial := FRACUNIT - (_SHR(y1, MAPBTOFRAC) and (FRACUNIT - 1));
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else if yt2 < yt1 then
  begin
    mapystep := -1;
    partial := _SHR(y1, MAPBTOFRAC) and (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else
  begin
    mapystep := 0;
    partial := FRACUNIT;
    xstep := 256 * FRACUNIT;
  end;

  xintercept := _SHR(x1, MAPBTOFRAC) + FixedMul(partial, xstep);

  // Step through map blocks.
  // count is present to prevent a round off error
  // from skipping the Break.
  mapx := xt1;
  mapy := yt1;

  for count := 0 to 63 do
  begin
    if flags and PT_ADDLINES <> 0 then
    begin
      if not P_BlockLinesIterator(mapx, mapy, PIT_AddLineIntercepts) then
      begin
        Result := False; // early out
        Exit;
      end;
    end;

    if flags and PT_ADDTHINGS <> 0 then
    begin
      if not P_BlockThingsIterator(mapx, mapy, PIT_AddThingIntercepts) then
      begin
        Result := False;// early out
        Exit;
      end;
    end;

    if (mapx = xt2) and (mapy = yt2) then
      Break;

    if _SHR(yintercept, FRACBITS) = mapy then
    begin
      yintercept := yintercept + ystep;
      mapx := mapx + mapxstep;
    end
    else if _SHR(xintercept, FRACBITS) = mapx then
    begin
      xintercept := xintercept + xstep;
      mapy := mapy + mapystep;
    end;
  end;

  // go through the sorted list
  Result := P_TraverseIntercepts(trav, FRACUNIT);
end;

end.


