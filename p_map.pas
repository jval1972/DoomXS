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

unit p_map;

interface

uses
  m_bbox,
  m_rnd,
  i_system,
  p_local,
  p_mobj_h,
  s_sound,
  m_fixed,
  tables,
  d_player,
  r_defs,
  sounds;

function P_TeleportMove(thing: Pmobj_t; x, y: fixed_t): boolean;

function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;

function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;

function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t): fixed_t;

procedure P_LineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t;
  slope: fixed_t; damage: integer);

procedure P_UseLines(player: Pplayer_t);

procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: integer);

function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;

procedure P_SlideMove(mo: Pmobj_t);

var
  linetarget: Pmobj_t;  // who got hit (or NULL)

  // If "floatok" True, move would be ok
  // if within "tmfloorz - tmceilingz".
  floatok: boolean;

  tmfloorz: fixed_t;
  tmceilingz: fixed_t;
  tmdropoffz: fixed_t;

const
  // keep track of special lines as they are hit,
  // but don't process them until the move is proven valid
  MAXSPECIALCROSS = 64;

var
  spechit: array[0..MAXSPECIALCROSS - 1] of Pline_t;
  numspechit: integer;

  // keep track of the line that lowers the ceiling,
  // so missiles don't explode against sky hack walls
  ceilingline: Pline_t;

  attackrange: fixed_t;

implementation

uses
  d_delphi,
  doomdata,
  g_game,
  info_h,
  p_setup,
  p_maputl,
  p_inter,
  p_mobj,
  p_spec,
  p_sight,
  p_switch,
  p_tick,
  r_main,
  r_sky;

var
  tmbbox: array[0..3] of fixed_t;
  tmthing: Pmobj_t;
  tmflags: integer;
  tmx: fixed_t;
  tmy: fixed_t;

// TELEPORT MOVE

// PIT_StompThing
function PIT_StompThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    Result := True;
    Exit;
  end;

  blockdist := thing.radius + tmthing.radius;

  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin
    // didn't hit it
    Result := True;
    Exit;
  end;

  // don't clip against self
  if thing = tmthing then
  begin
    Result := True;
    Exit;
  end;

  // monsters don't stomp things except on boss level
  if (tmthing.player = nil) and (gamemap <> 30) then
  begin
    Result := False;
    Exit;
  end;

  P_DamageMobj(thing, tmthing, tmthing, 10000);

  Result := True;
end;


// P_TeleportMove

function P_TeleportMove(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  newsubsec: Psubsector_t;
begin
  // kill anything occupying the position
  tmthing := thing;
  tmflags := thing.flags;

  tmx := x;
  tmy := y;

  tmbbox[BOXTOP] := y + tmthing.radius;
  tmbbox[BOXBOTTOM] := y - tmthing.radius;
  tmbbox[BOXRIGHT] := x + tmthing.radius;
  tmbbox[BOXLEFT] := x - tmthing.radius;

  newsubsec := R_PointInSubsector(x, y);
  ceilingline := nil;

  // The base floor/ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  tmdropoffz := newsubsec.sector.floorheight;
  tmfloorz := tmdropoffz;

  tmceilingz := newsubsec.sector.ceilingheight;

  Inc(validcount);
  numspechit := 0;

  // stomp on any things contacted
  xl := _SHR((tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS), MAPBLOCKSHIFT);
  xh := _SHR((tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS), MAPBLOCKSHIFT);
  yl := _SHR((tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS), MAPBLOCKSHIFT);
  yh := _SHR((tmbbox[BOXTOP] - bmaporgy + MAXRADIUS), MAPBLOCKSHIFT);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_StompThing) then
      begin
        Result := False;
        Exit;
      end;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;
  thing.x := x;
  thing.y := y;

  P_SetThingPosition(thing);

  Result := True;
end;

// MOVEMENT ITERATOR FUNCTIONS

// PIT_CheckLine
// Adjusts tmfloorz and tmceilingz as lines are contacted
function PIT_CheckLine(ld: Pline_t): boolean;
begin
  if (tmbbox[BOXRIGHT] <= ld.bbox[BOXLEFT]) or (tmbbox[BOXLEFT] >=
    ld.bbox[BOXRIGHT]) or (tmbbox[BOXTOP] <= ld.bbox[BOXBOTTOM]) or
    (tmbbox[BOXBOTTOM] >= ld.bbox[BOXTOP]) then
  begin
    Result := True;
    Exit;
  end;

  if P_BoxOnLineSide(@tmbbox, ld) <> -1 then
  begin
    Result := True;
    Exit;
  end;

  // A line has been hit

  // The moving thing's destination position will cross
  // the given line.
  // If this should not be allowed, return False.
  // If the line is special, keep track of it
  // to process later if the move is proven ok.
  // NOTE: specials are NOT sorted by order,
  // so two special lines that are only 8 pixels apart
  // could be crossed in either order.

  if ld.backsector = nil then
  begin
    Result := False;  // one sided line
    Exit;
  end;

  if tmthing.flags and MF_MISSILE = 0 then
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      Result := False;  // explicitly blocking everything
      Exit;
    end;

    if (tmthing.player = nil) and ((ld.flags and ML_BLOCKMONSTERS) <> 0) then
    begin
      Result := False;  // block monsters only
      Exit;
    end;
  end;

  // set openrange, opentop, openbottom
  P_LineOpening(ld);

  // adjust floor / ceiling heights
  if opentop < tmceilingz then
  begin
    tmceilingz := opentop;
    ceilingline := ld;
  end;

  if openbottom > tmfloorz then
    tmfloorz := openbottom;

  if lowfloor < tmdropoffz then
    tmdropoffz := lowfloor;

  // if contacted a special line, add it to the list
  if ld.special <> 0 then
  begin
    spechit[numspechit] := ld;

    Inc(numspechit);
  end;

  Result := True;
end;

// PIT_CheckThing
function PIT_CheckThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
  solid: boolean;
  damage: integer;
begin
  if thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE) = 0 then
  begin
    Result := True;
    Exit;
  end;

  // don't clip against self
  if thing = tmthing then
  begin
    Result := True;
    Exit;
  end;

  blockdist := thing.radius + tmthing.radius;

  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin
    // didn't hit it
    Result := True;
    Exit;
  end;

  // check for skulls slamming into things
  if tmthing.flags and MF_SKULLFLY <> 0 then
  begin
    damage := ((P_Random mod 8) + 1) * tmthing.info.damage;
    P_DamageMobj(thing, tmthing, tmthing, damage);

    tmthing.flags := tmthing.flags and not MF_SKULLFLY;
    tmthing.momx := 0;
    tmthing.momy := 0;
    tmthing.momz := 0;

    P_SetMobjState(tmthing, statenum_t(tmthing.info.spawnstate));

    Result := False;  // stop moving
    Exit;
  end;

  // missiles can hit other things
  if tmthing.flags and MF_MISSILE <> 0 then
  begin
    // see if it went over / under
    if tmthing.z > thing.z + thing.height then
    begin
      Result := True; // overhead
      Exit;
    end;
    if tmthing.z + tmthing.height < thing.z then
    begin
      Result := True; // underneath
      Exit;
    end;

    if (tmthing.target <> nil) and ((tmthing.target.typ = thing.typ) or
      ((tmthing.target.typ = MT_KNIGHT) and (thing.typ = MT_BRUISER)) or
      ((tmthing.target.typ = MT_BRUISER) and (thing.typ = MT_KNIGHT))) then
    begin
      // Don't hit same species as originator.
      if thing = tmthing.target then
      begin
        Result := True;
        Exit;
      end;

      if thing.typ <> MT_PLAYER then
      begin
        // Explode, but do no damage.
        // Let players missile other players.
        Result := False;
        Exit;
      end;
    end;

    if thing.flags and MF_SHOOTABLE = 0 then
    begin
      // didn't do any damage
      Result := thing.flags and MF_SOLID = 0;
      Exit;
    end;

    // damage / explode
    damage := ((P_Random mod 8) + 1) * tmthing.info.damage;
    P_DamageMobj(thing, tmthing, tmthing.target, damage);

    // don't traverse any more
    Result := False;
    Exit;
  end;

  // check for special pickup
  if thing.flags and MF_SPECIAL <> 0 then
  begin
    solid := thing.flags and MF_SOLID <> 0;
    if tmflags and MF_PICKUP <> 0 then
    begin
      // can remove thing
      P_TouchSpecialThing(thing, tmthing);
    end;
    Result := not solid;
  end
  else
    Result := thing.flags and MF_SOLID = 0;
end;

// MOVEMENT CLIPPING

// P_CheckPosition
// This is purely informative, nothing is modified
// (except things picked up).

// in:
//  a mobj_t (can be valid or invalid)
//  a position to be checked
//   (doesn't need to be related to the mobj_t->x,y)
//
// during:
//  special things are touched if MF_PICKUP
//  early out on solid lines?
//
// out:
//  newsubsec
//  floorz
//  ceilingz
//  tmdropoffz
//   the lowest point contacted
//   (monsters won't move to a dropoff)
//  speciallines[]
//  numspeciallines
function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  newsubsec: Psubsector_t;
begin
  tmthing := thing;
  tmflags := thing.flags;

  tmx := x;
  tmy := y;

  tmbbox[BOXTOP] := y + tmthing.radius;
  tmbbox[BOXBOTTOM] := y - tmthing.radius;
  tmbbox[BOXRIGHT] := x + tmthing.radius;
  tmbbox[BOXLEFT] := x - tmthing.radius;

  newsubsec := R_PointInSubsector(x, y);
  ceilingline := nil;

  // The base floor / ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  tmdropoffz := newsubsec.sector.floorheight;
  tmfloorz := tmdropoffz;
  tmceilingz := newsubsec.sector.ceilingheight;

  Inc(validcount);
  numspechit := 0;

  if tmflags and MF_NOCLIP <> 0 then
  begin
    Result := True;
    Exit;
  end;

  // Check things first, possibly picking things up.
  // The bounding box is extended by MAXRADIUS
  // because mobj_ts are grouped into mapblocks
  // based on their origin point, and can overlap
  // into adjacent blocks by up to MAXRADIUS units.
  xl := _SHR((tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS), MAPBLOCKSHIFT);
  xh := _SHR((tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS), MAPBLOCKSHIFT);
  yl := _SHR((tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS), MAPBLOCKSHIFT);
  yh := _SHR((tmbbox[BOXTOP] - bmaporgy + MAXRADIUS), MAPBLOCKSHIFT);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_CheckThing) then
      begin
        Result := False;
        Exit;
      end;

  // check lines
  xl := _SHR((tmbbox[BOXLEFT] - bmaporgx), MAPBLOCKSHIFT);
  xh := _SHR((tmbbox[BOXRIGHT] - bmaporgx), MAPBLOCKSHIFT);
  yl := _SHR((tmbbox[BOXBOTTOM] - bmaporgy), MAPBLOCKSHIFT);
  yh := _SHR((tmbbox[BOXTOP] - bmaporgy), MAPBLOCKSHIFT);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockLinesIterator(bx, by, PIT_CheckLine) then
      begin
        Result := False;
        Exit;
      end;

  Result := True;
end;

// P_TryMove
// Attempt to move to a new position,
// crossing special lines unless MF_TELEPORT is set.
function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  oldx: fixed_t;
  oldy: fixed_t;
  side: integer;
  oldside: integer;
  ld: Pline_t;
begin
  floatok := False;
  if not P_CheckPosition(thing, x, y) then
  begin
    Result := False;  // solid wall or thing
    Exit;
  end;

  if thing.flags and MF_NOCLIP = 0 then
  begin
    if tmceilingz - tmfloorz < thing.height then
    begin
      Result := False;  // doesn't fit
      Exit;
    end;

    floatok := True;

    if (thing.flags and MF_TELEPORT = 0) and
      (tmceilingz - thing.z < thing.height) then
    begin
      Result := False;  // mobj must lower itself to fit
      Exit;
    end;

    if (thing.flags and MF_TELEPORT = 0) and
      (tmfloorz - thing.z > 24 * FRACUNIT) then
    begin
      Result := False;  // too big a step up
      Exit;
    end;

    if ((thing.flags and (MF_DROPOFF or MF_FLOAT)) = 0) and
      (tmfloorz - tmdropoffz > 24 * FRACUNIT) then
    begin
      Result := False;  // don't stand over a dropoff
      Exit;
    end;
  end;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  oldx := thing.x;
  oldy := thing.y;
  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;
  thing.x := x;
  thing.y := y;

  P_SetThingPosition(thing);

  // if any special lines were hit, do the effect
  if thing.flags and (MF_TELEPORT or MF_NOCLIP) = 0 then
  begin
    while numspechit > 0 do
    begin
      // see if the line was crossed
      Dec(numspechit);
      ld := spechit[numspechit];
      side := P_PointOnLineSide(thing.x, thing.y, ld);
      oldside := P_PointOnLineSide(oldx, oldy, ld);
      if side <> oldside then
      begin
        if ld.special <> 0 then
          P_CrossSpecialLine(pOperation(ld, @lines[0], '-', SizeOf(ld^)),
            oldside, thing);
      end;
    end;
  end;

  Result := True;
end;

// P_ThingHeightClip
// Takes a valid thing and adjusts the thing->floorz,
// thing->ceilingz, and possibly thing->z.
// This is called for all nearby monsters
// whenever a sector changes height.
// If the thing doesn't fit,
// the z will be set to the lowest value
// and False will be returned.
function P_ThingHeightClip(thing: Pmobj_t): boolean;
var
  onfloor: boolean;
begin
  onfloor := thing.z = thing.floorz;

  P_CheckPosition(thing, thing.x, thing.y);
  // what about stranding a monster partially off an edge?

  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;

  if onfloor then
  begin
    // walking monsters rise and fall with the floor
    thing.z := thing.floorz;
  end
  else
  begin
    // don't adjust a floating monster unless forced to
    if thing.z + thing.height > thing.ceilingz then
      thing.z := thing.ceilingz - thing.height;
  end;

  Result := thing.ceilingz - thing.floorz >= thing.height;
end;

// SLIDE MOVE
// Allows the player to slide along any angled walls.
var
  bestslidefrac: fixed_t;

  bestslideline: Pline_t;

  slidemo: Pmobj_t;

  tmxmove: fixed_t;
  tmymove: fixed_t;

// P_HitSlideLine
// Adjusts the xmove / ymove
// so that the next move will slide along the wall.
procedure P_HitSlideLine(ld: Pline_t);
var
  side: integer;
  lineangle: angle_t;
  moveangle: angle_t;
  deltaangle: angle_t;
  movelen: fixed_t;
  newlen: fixed_t;
begin
  if ld.slopetype = ST_HORIZONTAL then
  begin
    tmymove := 0;
    Exit;
  end;

  if ld.slopetype = ST_VERTICAL then
  begin
    tmxmove := 0;
    Exit;
  end;

  side := P_PointOnLineSide(slidemo.x, slidemo.y, ld);

  lineangle := R_PointToAngle2(0, 0, ld.dx, ld.dy);

  if side = 1 then
    lineangle := lineangle + ANG180;

  moveangle := R_PointToAngle2(0, 0, tmxmove, tmymove);
  deltaangle := moveangle - lineangle;

  if deltaangle > ANG180 then
    deltaangle := deltaangle + ANG180;

  lineangle := lineangle shr ANGLETOFINESHIFT;
  deltaangle := deltaangle shr ANGLETOFINESHIFT;

  movelen := P_AproxDistance(tmxmove, tmymove);
  newlen := FixedMul(movelen, finecosine[deltaangle]);

  tmxmove := FixedMul(newlen, finecosine[lineangle]);
  tmymove := FixedMul(newlen, finesine[lineangle]);
end;

// PTR_SlideTraverse
function PTR_SlideTraverse(intr: Pintercept_t): boolean;
var
  li: Pline_t;

  procedure isblocking;
  begin
    // the line does block movement,
    // see if it is closer than best so far
    if intr.frac < bestslidefrac then
    begin
      bestslidefrac := intr.frac;
      bestslideline := li;
    end;
  end;

begin
  if not intr.isaline then
    I_Error('PTR_SlideTraverse(): not a line?');

  li := intr.d.line;

  if li.flags and ML_TWOSIDED = 0 then
  begin
    if P_PointOnLineSide(slidemo.x, slidemo.y, li) <> 0 then
    begin
      // don't hit the back side
      Result := True;
      Exit;
    end;
    isblocking;
    Result := False; // stop
    Exit;
  end;

  // set openrange, opentop, openbottom
  P_LineOpening(li);

  if openrange < slidemo.height then
  begin
    isblocking; // doesn't fit
    Result := False; // stop
    Exit;
  end;

  if opentop - slidemo.z < slidemo.height then
  begin
    isblocking; // mobj is too high
    Result := False; // stop
    Exit;
  end;

  if openbottom - slidemo.z > 24 * FRACUNIT then
  begin
    isblocking; // too big a step up
    Result := False; // stop
    Exit;
  end;

  // this line doesn't block movement
  Result := True;
end;

// P_SlideMove
// The momx / momy move is bad, so try to slide
// along a wall.
// Find the first line hit, move flush to it,
// and slide along it

// This is a kludgy mess.
procedure P_SlideMove(mo: Pmobj_t);
var
  leadx: fixed_t;
  leady: fixed_t;
  trailx: fixed_t;
  traily: fixed_t;
  newx: fixed_t;
  newy: fixed_t;
  hitcount: integer;

  procedure stairstep;
  begin
    if not P_TryMove(mo, mo.x, mo.y + mo.momy) then
      P_TryMove(mo, mo.x + mo.momx, mo.y);
  end;

begin
  slidemo := mo;
  hitcount := 0;

  repeat
    Inc(hitcount);
    if hitcount = 3 then
    begin
      stairstep;
      Exit;  // don't loop forever
    end;

    // trace along the three leading corners
    if mo.momx > 0 then
    begin
      leadx := mo.x + mo.radius;
      trailx := mo.x - mo.radius;
    end
    else
    begin
      leadx := mo.x - mo.radius;
      trailx := mo.x + mo.radius;
    end;

    if mo.momy > 0 then
    begin
      leady := mo.y + mo.radius;
      traily := mo.y - mo.radius;
    end
    else
    begin
      leady := mo.y - mo.radius;
      traily := mo.y + mo.radius;
    end;

    bestslidefrac := FRACUNIT + 1;

    P_PathTraverse(leadx, leady, leadx + mo.momx, leady + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);
    P_PathTraverse(trailx, leady, trailx + mo.momx, leady + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);
    P_PathTraverse(leadx, traily, leadx + mo.momx, traily + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);

    // move up to the wall
    if bestslidefrac = FRACUNIT + 1 then
    begin
      // the move most have hit the middle, so stairstep
      stairstep;
      Exit;
    end;

    // fudge a bit to make sure it doesn't hit
    bestslidefrac := bestslidefrac - $800;
    if bestslidefrac > 0 then
    begin
      newx := FixedMul(mo.momx, bestslidefrac);
      newy := FixedMul(mo.momy, bestslidefrac);

      if not P_TryMove(mo, mo.x + newx, mo.y + newy) then
      begin
        stairstep;
        Exit;
      end;
    end;

    // Now Continue along the wall.
    // First calculate remainder.
    bestslidefrac := FRACUNIT - (bestslidefrac + $800);

    if bestslidefrac > FRACUNIT then
      bestslidefrac := FRACUNIT;

    if bestslidefrac <= 0 then
      Exit;

    tmxmove := FixedMul(mo.momx, bestslidefrac);
    tmymove := FixedMul(mo.momy, bestslidefrac);

    P_HitSlideLine(bestslideline);  // clip the moves

    mo.momx := tmxmove;
    mo.momy := tmymove;

  until P_TryMove(mo, mo.x + tmxmove, mo.y + tmymove);
end;

// P_LineAttack
var
  shootthing: Pmobj_t;

// Height if not aiming up or down
// ???: use slope for monsters?
  shootz: fixed_t;

  la_damage: integer;

  aimslope: fixed_t;

// PTR_AimTraverse
// Sets linetaget and aimslope when a target is aimed at.
function PTR_AimTraverse(intr: Pintercept_t): boolean;
var
  li: Pline_t;
  th: Pmobj_t;
  slope: fixed_t;
  thingtopslope: fixed_t;
  thingbottomslope: fixed_t;
  dist: fixed_t;
begin
  if intr.isaline then
  begin
    li := intr.d.line;

    if li.flags and ML_TWOSIDED = 0 then
    begin
      Result := False; // stop
      Exit;
    end;

    // Crosses a two sided line.
    // A two sided line will restrict
    // the possible target ranges.
    P_LineOpening(li);

    if openbottom >= opentop then
    begin
      Result := False; // stop
      Exit;
    end;

    dist := FixedMul(attackrange, intr.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - shootz, dist);
      if slope > bottomslope then
        bottomslope := slope;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - shootz, dist);
      if slope < topslope then
        topslope := slope;
    end;

    if topslope <= bottomslope then
    begin
      Result := False; // stop
      Exit;
    end;

    Result := True;  // shot continues
    Exit;
  end;

  // shoot a thing
  th := intr.d.thing;
  if th = shootthing then
  begin
    Result := True;  // can't shoot self
    Exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    Result := True; // corpse or something
    Exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, intr.frac);
  thingtopslope := FixedDiv(th.z + th.height - shootz, dist);

  if thingtopslope < bottomslope then
  begin
    Result := True; // shot over the thing
    Exit;
  end;

  thingbottomslope := FixedDiv(th.z - shootz, dist);

  if thingbottomslope > topslope then
  begin
    Result := True; // shot under the thing
    Exit;
  end;

  // this thing can be hit!
  if thingtopslope > topslope then
    thingtopslope := topslope;

  if thingbottomslope < bottomslope then
    thingbottomslope := bottomslope;

  aimslope := (thingtopslope + thingbottomslope) div 2;
  linetarget := th;

  Result := False; // don't go any farther
end;

// PTR_ShootTraverse
function PTR_ShootTraverse(intr: Pintercept_t): boolean;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  frac: fixed_t;
  li: Pline_t;
  th: Pmobj_t;
  slope: fixed_t;
  dist: fixed_t;
  thingtopslope: fixed_t;
  thingbottomslope: fixed_t;

  function hitline: boolean;
  begin
    // hit line
    // position a bit closer
    frac := intr.frac - FixedDiv(4 * FRACUNIT, attackrange);
    x := trace.x + FixedMul(trace.dx, frac);
    y := trace.y + FixedMul(trace.dy, frac);
    z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

    if li.frontsector.ceilingpic = skyflatnum then
    begin
      // don't shoot the sky!
      if z > li.frontsector.ceilingheight then
      begin
        Result := False;
        Exit;
      end;

      // it's a sky hack wall
      if (li.backsector <> nil) and (li.backsector.ceilingpic = skyflatnum) then
      begin
        Result := False;
        Exit;
      end;
    end;
    // Spawn bullet puffs.
    P_SpawnPuff(x, y, z);

    // don't go any farther
    Result := False;
  end;

begin
  if intr.isaline then
  begin
    li := intr.d.line;

    if li.special <> 0 then
      P_ShootSpecialLine(shootthing, li);

    if li.flags and ML_TWOSIDED = 0 then
    begin
      Result := hitline;
      Exit;
    end;

    // crosses a two sided line
    P_LineOpening(li);

    dist := FixedMul(attackrange, intr.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - shootz, dist);
      if slope > aimslope then
      begin
        Result := hitline;
        Exit;
      end;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - shootz, dist);
      if slope < aimslope then
      begin
        Result := hitline;
        Exit;
      end;
    end;

    // shot continues
    Result := True;
    Exit;
  end;

  // shoot a thing
  th := intr.d.thing;
  if th = shootthing then
  begin
    Result := True; // can't shoot self
    Exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    Result := True; // corpse or something
    Exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, intr.frac);
  thingtopslope := FixedDiv(th.z + th.height - shootz, dist);

  if thingtopslope < aimslope then
  begin
    Result := True; // shot over the thing
    Exit;
  end;

  thingbottomslope := FixedDiv(th.z - shootz, dist);

  if thingbottomslope > aimslope then
  begin
    Result := True; // shot under the thing
    Exit;
  end;


  // hit thing
  // position a bit closer
  frac := intr.frac - FixedDiv(10 * FRACUNIT, attackrange);

  x := trace.x + FixedMul(trace.dx, frac);
  y := trace.y + FixedMul(trace.dy, frac);
  z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

  // Spawn bullet puffs or blood spots,
  // depending on target type.
  if intr.d.thing.flags and MF_NOBLOOD <> 0 then
    P_SpawnPuff(x, y, z)
  else
    P_SpawnBlood(x, y, z, la_damage);

  if la_damage <> 0 then
    P_DamageMobj(th, shootthing, shootthing, la_damage);

  // don't go any farther
  Result := False;
end;

// P_AimLineAttack
function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t): fixed_t;
var
  x2: fixed_t;
  y2: fixed_t;
begin
  angle := angle shr ANGLETOFINESHIFT;
  shootthing := t1;

  x2 := t1.x + _SHR(distance, FRACBITS) * finecosine[angle];
  y2 := t1.y + _SHR(distance, FRACBITS) * finesine[angle];
  shootz := t1.z + _SHR(t1.height, 1) + 8 * FRACUNIT;

  // can't shoot outside view angles
  topslope := (100 * FRACUNIT) div 160;
  bottomslope := -topslope;

  attackrange := distance;
  linetarget := nil;

  P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_AimTraverse);

  if linetarget <> nil then
    Result := aimslope
  else
    Result := 0;
end;

// P_LineAttack
// If damage == 0, it is just a test trace
// that will leave linetarget set.
procedure P_LineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t;
  slope: fixed_t; damage: integer);
var
  x2: fixed_t;
  y2: fixed_t;
begin
  angle := angle shr ANGLETOFINESHIFT;
  shootthing := t1;
  la_damage := damage;
  x2 := t1.x + _SHR(distance, FRACBITS) * finecosine[angle];
  y2 := t1.y + _SHR(distance, FRACBITS) * finesine[angle];
  shootz := t1.z + (_SHR(t1.height, 1)) + 8 * FRACUNIT;
  attackrange := distance;
  aimslope := slope;

  P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_ShootTraverse);
end;

// USE LINES
var
  usething: Pmobj_t;

function PTR_UseTraverse(_in: Pintercept_t): boolean;
var
  side: integer;
begin
  if _in.d.line.special = 0 then
  begin
    P_LineOpening(_in.d.line);
    if openrange <= 0 then
    begin
      S_StartSound(usething, Ord(sfx_noway));
      // can't use through a wall
      Result := False;
      Exit;
    end;
    // not a special line, but keep checking
    Result := True;
    Exit;
  end;

  side := 0;
  if P_PointOnLineSide(usething.x, usething.y, _in.d.line) = 1 then
    side := 1;

  //  return False;    // don't use back side

  P_UseSpecialLine(usething, _in.d.line, side);

  // can't use for than one special line in a row
  Result := False;
end;

// P_UseLines
// Looks for special lines in front of the player to activate.
procedure P_UseLines(player: Pplayer_t);
var
  angle: angle_t;
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
begin
  usething := player.mo;

  angle := player.mo.angle shr ANGLETOFINESHIFT;

  x1 := player.mo.x;
  y1 := player.mo.y;
  x2 := x1 + USERANGEINT * finecosine[angle];
  y2 := y1 + USERANGEINT * finesine[angle];

  P_PathTraverse(x1, y1, x2, y2, PT_ADDLINES, PTR_UseTraverse);
end;

// RADIUS ATTACK
var
  bombsource: Pmobj_t;
  bombspot: Pmobj_t;
  bombdamage: integer;


// PIT_RadiusAttack
// "bombsource" is the creature
// that caused the explosion at "bombspot".
function PIT_RadiusAttack(thing: Pmobj_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  dist: fixed_t;
begin
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    Result := True;
    Exit;
  end;

  // Boss spider and cyborg
  // take no damage from concussion.
  if (thing.typ = MT_CYBORG) or (thing.typ = MT_SPIDER) then
  begin
    Result := True;
    Exit;
  end;

  dx := abs(thing.x - bombspot.x);
  dy := abs(thing.y - bombspot.y);

  if dx > dy then
    dist := dx
  else
    dist := dy;
  dist := _SHR(dist - thing.radius, FRACBITS);

  if dist < 0 then
    dist := 0;

  if dist >= bombdamage then
  begin
    Result := True; // out of range
    Exit;
  end;

  if P_CheckSight(thing, bombspot) then
  begin
    // must be in direct path
    P_DamageMobj(thing, bombspot, bombsource, bombdamage - dist);
  end;

  Result := True;
end;

// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: integer);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := (damage + MAXRADIUS) * FRACUNIT;
  yh := _SHR((spot.y + dist - bmaporgy), MAPBLOCKSHIFT);
  yl := _SHR((spot.y - dist - bmaporgy), MAPBLOCKSHIFT);
  xh := _SHR((spot.x + dist - bmaporgx), MAPBLOCKSHIFT);
  xl := _SHR((spot.x - dist - bmaporgx), MAPBLOCKSHIFT);
  bombspot := spot;
  bombsource := source;
  bombdamage := damage;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_RadiusAttack);
end;


// SECTOR HEIGHT CHANGING
// After modifying a sectors floor or ceiling height,
// call this routine to adjust the positions
// of all things that touch the sector.

// If anything doesn't fit anymore, True will be returned.
// If crunch is True, they will take damage
//  as they are being crushed.
// If Crunch is False, you should set the sector height back
//  the way it was and call P_ChangeSector again
//  to undo the changes.
var
  crushchange: boolean;
  nofit: boolean;

// PIT_ChangeSector
function PIT_ChangeSector(thing: Pmobj_t): boolean;
var
  mo: Pmobj_t;
begin
  if P_ThingHeightClip(thing) then
  begin
    // keep checking
    Result := True;
    Exit;
  end;

  // crunch bodies to giblets
  if thing.health <= 0 then
  begin
    P_SetMobjState(thing, S_GIBS);

    thing.flags := thing.flags and not MF_SOLID;
    thing.height := 0;
    thing.radius := 0;

    // keep checking
    Result := True;
    Exit;
  end;

  // crunch dropped items
  if thing.flags and MF_DROPPED <> 0 then
  begin
    P_RemoveMobj(thing);

    // keep checking
    Result := True;
    Exit;
  end;

  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    // assume it is bloody gibs or something
    Result := True;
    Exit;
  end;

  nofit := True;

  if crushchange and ((leveltime and 3) = 0) then
  begin
    P_DamageMobj(thing, nil, nil, 10);

    // spray blood in a random direction
    mo := P_SpawnMobj(thing.x, thing.y, thing.z + thing.height div 2, MT_BLOOD);

    mo.momx := _SHL(P_Random - P_Random, 12);
    mo.momy := _SHL(P_Random - P_Random, 12);
  end;

  // keep checking (crush other things)
  Result := True;
end;

// P_ChangeSector
function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
var
  x: integer;
  y: integer;
begin
  nofit := False;
  crushchange := crunch;

  // re-check heights for all things near the moving sector
  for x := sector.blockbox[BOXLEFT] to sector.blockbox[BOXRIGHT] do
    for y := sector.blockbox[BOXBOTTOM] to sector.blockbox[BOXTOP] do
      P_BlockThingsIterator(x, y, PIT_ChangeSector);

  Result := nofit;
end;

end.

