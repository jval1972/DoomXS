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

unit r_main;

interface

uses
  d_delphi,
  doomdef,
  d_player,
  m_fixed,
  tables,
  r_data,
  r_defs;

const
//
// Lighting LUT.
// Used for z-depth cuing per column/row,
//  and other lighting effects (sector ambient, flash).
//

// Lighting constants.
// Now why not 32 levels here?
  LIGHTLEVELS = 16;
  LIGHTSEGSHIFT = 4;

  MAXLIGHTSCALE = 48;
  LIGHTSCALESHIFT = 12;
  MAXLIGHTZ = 128;
  LIGHTZSHIFT = 20;

// Number of diminishing brightness levels.
// There a 0-31, i.e. 32 LUT in the COLORMAP lump.
  NUMCOLORMAPS = 32;

//
// Utility functions.
function R_PointOnSide(x: fixed_t; y: fixed_t; node: Pnode_t): integer;

function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;

function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;

function R_PointToAngle2(x1: fixed_t; y1: fixed_t; x2: fixed_t; y2: fixed_t): angle_t;

function R_PointToDist(x: fixed_t; y: fixed_t): fixed_t;

function R_ScaleFromGlobalAngle(visangle: angle_t): fixed_t;

function R_PointInSubsector(x: fixed_t; y: fixed_t): Psubsector_t;

procedure R_AddPointToBox(const x: integer; const y: integer; box: Pfixed_tArray);


//
// REFRESH - the actual rendering functions.
//

// Called by G_Drawer.
procedure R_RenderPlayerView(player: Pplayer_t);

// Called by startup code.
procedure R_Init;

// Called by M_Responder.
procedure R_SetViewSize(blocks: integer; detail: integer);

procedure R_ExecuteSetViewSize;

var
  colfunc: PProcedure;
  skycolfunc: PProcedure;
  basecolfunc: PProcedure;
  fuzzcolfunc: PProcedure;
  spanfunc: PProcedure;

// 0 = high, 1 = low
  detailshift: integer;

  centerxfrac: fixed_t;
  centeryfrac: fixed_t;

  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

  viewangle: angle_t;

  viewcos: fixed_t;
  viewsin: fixed_t;

  projection: fixed_t;

  centerx: integer;
  centery: integer;

  fixedcolormap: Plighttable_tArray;

// increment every time a check is made
  validcount: integer = 1;

// bumped light from gun blasts
  extralight: integer;

  scalelight: array[0..LIGHTLEVELS - 1, 0..MAXLIGHTSCALE - 1] of Plighttable_tArray;
  scalelightfixed: array[0..MAXLIGHTSCALE - 1] of Plighttable_tArray;
  zlight: array[0..LIGHTLEVELS - 1, 0..MAXLIGHTZ - 1] of Plighttable_tArray;

  viewplayer: Pplayer_t;

// The viewangletox[viewangle + FINEANGLES/4] lookup
// maps the visible view angles to screen X coordinates,
// flattening the arc to a flat projection plane.
// There will be many angles mapped to the same X.
  viewangletox: array[0..FINEANGLES div 2 - 1] of integer;

// The xtoviewangleangle[] table maps a screen pixel
// to the lowest viewangle that maps back to x ranges
// from clipangle to -clipangle.
  xtoviewangle: array[0..SCREENWIDTH] of angle_t;

//
// precalculated math tables
//
  clipangle: angle_t;

// UNUSED.
// The finetangentgent[angle+FINEANGLES/4] table
// holds the fixed_t tangent values for view angles,
// ranging from MININT to 0 to MAXINT.
// fixed_t    finetangent[FINEANGLES/2];

// fixed_t    finesine[5*FINEANGLES/4];
// fixed_t*    finecosine = &finesine[FINEANGLES/4]; // VJ -> moved to tables.pas


  sscount: integer;
  linecount: integer;
  loopcount: integer;

  viewangleoffset: angle_t = 0; // never a value assigned to this variable!

  setsizeneeded: boolean;

implementation

uses
  doomdata,
  d_net,
  m_bbox,
  m_menu,
  p_setup,
  r_draw,
  r_bsp,
  r_things,
  r_plane,
  r_sky,
  r_segs,
  v_video,
  st_stuff;

const
// Fineangles in the SCREENWIDTH wide window.
  FIELDOFVIEW = 2048;

var

// just for profiling purposes
  framecount: integer;

//
// R_AddPointToBox
// Expand a given bbox
// so that it encloses a given point.
//
procedure R_AddPointToBox(const x: integer; const y: integer; box: Pfixed_tArray);
begin
  if x < box[BOXLEFT] then
    box[BOXLEFT] := x;
  if x > box[BOXRIGHT] then
    box[BOXRIGHT] := x;
  if y < box[BOXBOTTOM] then
    box[BOXBOTTOM] := y;
  if y > box[BOXTOP] then
    box[BOXTOP] := y;
end;

//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//
function R_PointOnSide(x: fixed_t; y: fixed_t; node: Pnode_t): integer;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if not boolval(node.dx) then
  begin
    if x <= node.x then
      result := intval(node.dy > 0)
    else
      result := intval(node.dy < 0);
    exit;
  end;

  if not boolval(node.dy) then
  begin
    if y <= node.y then
      result := intval(node.dx < 0)
    else
      result := intval(node.dx > 0);
    exit;
  end;

  dx := (x - node.x);
  dy := (y - node.y);

    // Try to quickly decide by looking at sign bits.
  if boolval((node.dy xor node.dx xor dx xor dy) and $80000000) then
  begin
    if boolval((node.dy xor dx) and $80000000) then
      // (left is negative)
      result := 1
    else
      result := 0;
    exit;
  end;

  left := FixedMul(node.dy div FRACUNIT, dx);
  right := FixedMul(dy, node.dx div FRACUNIT);

  if right < left then
    result := 0  // front side
  else
    result := 1; // back side
end;

function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if not boolval(ldx) then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if not boolval(ldy) then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx := x - lx;
  dy := y - ly;

  // Try to quickly decide by looking at sign bits.
  if boolval((ldy xor ldx xor dx xor dy) and $80000000) then
  begin
    if  boolval((ldy xor dx) and $80000000) then
      // (left is negative)
      result := true
    else
      result := false;
    exit;
  end;

  left := FixedMul(ldy div FRACUNIT, dx);
  right := FixedMul(dy, ldx div FRACUNIT);

  if right < left then
    result := false // front side
  else
    result := true; // back side
end;

//
// R_PointToAngle
// To get a global angle from cartesian coordinates,
//  the coordinates are flipped until they are in
//  the first octant of the coordinate system, then
//  the y (<=x) is scaled and divided by x to get a
//  tangent (slope) value which is looked up in the
//  tantoangle[] table.

//
function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;
begin
  x := x - viewx;
  y := y - viewy;

  if (not boolval(x)) and (not boolval(y)) then
  begin
    result := 0;
    exit;
  end;

  if x >= 0 then
  begin
    // x >=0
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 0
        result := tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 1
        result := ANG90 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 8
        result := -tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 7
        result := ANG270 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end
  else
  begin
    // x<0
    x := -x;
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 3
        result := ANG180 - 1 - tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 2
        result := ANG90 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 4
        result := ANG180 + tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 5
        result := ANG270 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end;

  result := 0;
end;

function R_PointToAngle2(x1: fixed_t; y1: fixed_t; x2: fixed_t; y2: fixed_t): angle_t;
begin
  viewx := x1;
  viewy := y1;

  result := R_PointToAngle(x2, y2);
end;

function R_PointToDist(x: fixed_t; y: fixed_t): fixed_t;
var
  angle: integer;
  dx: fixed_t;
  dy: fixed_t;
  temp: fixed_t;
begin
  dx := abs(x - viewx);
  dy := abs(y - viewy);

  if dy > dx then
  begin
    temp := dx;
    dx := dy;
    dy := temp;
  end;

  angle := _SHRW(tantoangle[_SHRW(FixedDiv(dy, dx), DBITS)] + ANG90, ANGLETOFINESHIFT); // VJ, does it work ???

  // use as cosine
  result := FixedDiv(dx, finesine[angle]);
end;

//
// R_InitPointToAngle
//
procedure R_InitPointToAngle; 
// UNUSED - now getting from tables.c
var
  i: integer;
  t: integer;
  f: single;
begin
//
// slope (tangent) to angle lookup
//
  for i := 0 to SLOPERANGE do
  begin
    f := arctan(i / SLOPERANGE) / (3.141592657 * 2); // VJ was atan() function
    t := round($ffffffff * f);
    tantoangle[i] := t;
  end;
end;

//
// R_ScaleFromGlobalAngle
// Returns the texture mapping scale
//  for the current line (horizontal span)
//  at the given angle.
// rw_distance must be calculated first.
//
function R_ScaleFromGlobalAngle(visangle: angle_t): fixed_t;
var
  anglea: angle_t;
  angleb: angle_t;
  sinea: integer;
  sineb: integer;
  num: fixed_t;
  den: integer;
begin
(*
    // UNUSED
#if 0
{
    fixed_t    dist;
    fixed_t    z;
    fixed_t    sinv;
    fixed_t    cosv;

    sinv = finesine[(visangle-rw_normalangle)>>ANGLETOFINESHIFT];
    dist = FixedDiv (rw_distance, sinv);
    cosv = finecosine[(viewangle-visangle)>>ANGLETOFINESHIFT];
    z = abs(FixedMul (dist, cosv));
    result = FixedDiv(projection, z);
    return result;
}
#endif
*)
  anglea := ANG90 + (visangle - viewangle);
  angleb := ANG90 + (visangle - rw_normalangle);

  // both sines are allways positive
  sinea := finesine[_SHRW(anglea, ANGLETOFINESHIFT)];
  sineb := finesine[_SHRW(angleb, ANGLETOFINESHIFT)];
  num := FixedMul(projection, sineb);
  den := FixedMul(rw_distance, sinea);

  if den > _SHR(num, 16) then
  begin
    result := FixedDiv(num, den);

    if result > 64 * FRACUNIT then
      result := 64 * FRACUNIT
    else if result < 256 then
      result := 256
  end
  else
    result := 64 * FRACUNIT;
end;

//
// R_InitTables
//
procedure R_InitTables;
// UNUSED: now getting from tables.c
// VJ: tables constants are now calculated here
var
  i: integer;
  a: extended; // VJ was single
  fv: single;
  t: integer;
begin
// viewangle tangent table
  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    a := (i - FINEANGLES / 4 + 0.5) * PI * 2 / FINEANGLES;
    fv := FRACUNIT * tan(a);
    t := round(fv);
    finetangent[i] := t;
  end;

  // finesine table
  for i := 0 to 5 * FINEANGLES div 4 - 1 do
  begin
    // OPTIMIZE: mirror...
    a := (i + 0.5) * PI * 2 / FINEANGLES;
    t := round(FRACUNIT * sin(a));
    finesine[i] := t;
  end;
  
  finecosine := Pfixed_tArray(@finesine[FINEANGLES div 4]);
end;

//
// R_InitTextureMapping
//
procedure R_InitTextureMapping;
var
  i: integer;
  x: integer;
  t: integer;
  focallength: fixed_t;
  an: angle_t;
begin
  // Use tangent table to generate viewangletox:
  //  viewangletox will give the next greatest x
  //  after the view angle.
  //
  // Calc focallength
  //  so FIELDOFVIEW angles covers SCREENWIDTH.
  focallength := FixedDiv(centerxfrac, finetangent[FINEANGLES div 4 + FIELDOFVIEW div 2]);

  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    if finetangent[i] > FRACUNIT * 2 then
      t := -1
    else if finetangent[i] < -FRACUNIT * 2 then
      t := viewwidth + 1
    else
    begin
      t := FixedMul(finetangent[i], focallength);
      t := (centerxfrac - t + FRACUNIT - 1) div FRACUNIT;

      if t < -1 then
        t := -1
      else if t > viewwidth + 1 then
        t := viewwidth + 1;
    end;
    viewangletox[i] := t;
  end;

  // Scan viewangletox[] to generate xtoviewangle[]:
  //  xtoviewangle will give the smallest view angle
  //  that maps to x.
  for x := 0 to viewwidth do
  begin
    an := 0;
    while viewangletox[an] > x do
      inc(an);
    xtoviewangle[x] := _SHLW(an, ANGLETOFINESHIFT) - ANG90;
  end;

  // Take out the fencepost cases from viewangletox.
  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    if viewangletox[i] = -1 then
      viewangletox[i] := 0
    else if viewangletox[i] = viewwidth + 1 then
      viewangletox[i] := viewwidth;
  end;
  clipangle := xtoviewangle[0];
end;

//
// R_InitLightTables
// Only inits the zlight table,
//  because the scalelight table changes with view size.
//
const
  DISTMAP = 2;

procedure R_InitLightTables;
var
  i: integer;
  j: integer;
  level: integer;
  startmap: integer;
  scale: integer;
begin
  // Calculate the light levels to use
  //  for each level / distance combination.
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmap := ((LIGHTLEVELS - 1 - i) * 2) * NUMCOLORMAPS div LIGHTLEVELS;
    for j := 0 to MAXLIGHTZ - 1 do
    begin
//      scale := FixedDiv((SCREENWIDTH div 2 * FRACUNIT), _SHL(j + 1, LIGHTZSHIFT)); // VJ maybe 320 ????
      scale := FixedDiv(160 * FRACUNIT, _SHL(j + 1, LIGHTZSHIFT));
      scale := _SHR(scale, LIGHTSCALESHIFT);
      level := startmap - scale div DISTMAP;

      if level < 0 then
        level := 0
      else if level >= NUMCOLORMAPS then
        level := NUMCOLORMAPS - 1;

      zlight[i][j] := Plighttable_tArray(integer(colormaps) + level * 256);
    end;
  end;
end;

//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//
var
  setblocks: integer;
  setdetail: integer;

procedure R_SetViewSize(blocks: integer; detail: integer);
begin
  setsizeneeded := true;
  setblocks := blocks;
  setdetail := detail;
end;

//
// R_ExecuteSetViewSize
//
procedure R_ExecuteSetViewSize;
var
  cosadj: fixed_t;
  dy: fixed_t;
  i: integer;
  j: integer;
  level: integer;
  startmap: integer;
begin
  setsizeneeded := false;

  if setblocks = 11 then
  begin
    scaledviewwidth := SCREENWIDTH;
    viewheight := SCREENHEIGHT;
  end
  else
  begin
    scaledviewwidth := setblocks * (SCREENWIDTH div 10);
    if setblocks = 10 then
      viewheight := V_PreserveY(200 - ST_HEIGHT)
    else
      viewheight := (setblocks * V_PreserveY(200 - ST_HEIGHT) div 10) and (not 7); //and (not 7);
  end;

  detailshift := setdetail;
  viewwidth := scaledviewwidth;

  centery := viewheight div 2;
  centerx := viewwidth div 2;
  centerxfrac := centerx * FRACUNIT;
  centeryfrac := centery * FRACUNIT;
  projection := centerxfrac;

  if not boolval(detailshift) then
  begin
    colfunc := R_DrawColumn;

    if SCREENHEIGHT = 200 then
      skycolfunc := R_DrawColumn
    else
      skycolfunc := R_DrawSkyColumn;

    basecolfunc := R_DrawColumn;

    fuzzcolfunc := R_DrawFuzzColumn;

    spanfunc := R_DrawSpan;
  end
  else
  begin
    colfunc := R_DrawColumnLow;

    if SCREENHEIGHT = 200 then
      skycolfunc := R_DrawColumn
    else
      skycolfunc := R_DrawSkyColumn;

    basecolfunc := R_DrawColumn;

    fuzzcolfunc := R_DrawFuzzColumn;

    spanfunc := R_DrawSpanLow;
  end;

  R_InitBuffer(scaledviewwidth, viewheight);

  R_InitTextureMapping;

  // psprite scales
  pspritescale := FRACUNIT * viewwidth div 320;
  pspriteiscale := FRACUNIT * 320 div viewwidth;

  // thing clipping
  for i := 0 to viewwidth - 1 do
    screenheightarray[i] := viewheight;

  // planes
  for i := 0 to viewheight - 1 do
  begin
    dy := ((i - viewheight div 2) * FRACUNIT) + FRACUNIT div 2;
    dy := abs(dy);
    yslope[i] := FixedDiv(viewwidth * FRACUNIT div 2, dy);
  end;

  for i := 0 to viewwidth - 1 do
  begin
    cosadj := abs(finecosine[_SHRW(xtoviewangle[i], ANGLETOFINESHIFT)]);
    distscale[i] := FixedDiv(FRACUNIT, cosadj);
  end;

  // Calculate the light levels to use
  //  for each level / scale combination.
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmap := ((LIGHTLEVELS - 1 - i) * 2) * NUMCOLORMAPS div LIGHTLEVELS;
    for j := 0 to MAXLIGHTSCALE - 1 do
    begin
      level := startmap - j * SCREENWIDTH div viewwidth div DISTMAP;

      if level < 0 then
        level := 0;

      if level >= NUMCOLORMAPS then
        level := NUMCOLORMAPS - 1;

      scalelight[i][j] := Plighttable_tArray(integer(colormaps) + level * 256);
    end;
  end;
end;

//
// R_Init
//
procedure R_Init;
begin
  R_InitData;
  printf(#13#10 + 'R_InitData');
  R_InitPointToAngle;
  printf(#13#10 + 'R_InitPointToAngle');
  R_InitTables;
  // viewwidth / viewheight / detailLevel are set by the defaults
  printf(#13#10 + 'R_InitTables');

  R_SetViewSize(screenblocks, detailLevel);
  R_InitLightTables;
  printf(#13#10 + 'R_InitLightTables');
  R_InitSkyMap;
  printf(#13#10 + 'R_InitSkyMap');
  R_InitTranslationTables;
  printf(#13#10 + 'R_InitTranslationsTables');

  framecount := 0;
end;

//
// R_PointInSubsector
//
function R_PointInSubsector(x: fixed_t; y: fixed_t): Psubsector_t;
var
  node: Pnode_t;
  side: integer;
  nodenum: integer;
begin
  // single subsector is a special case
  if numnodes = 0 then
  begin
    result := @subsectors[0];
    exit;
  end;

  nodenum := numnodes - 1;

  while (nodenum and NF_SUBSECTOR) = 0 do
  begin
    node := @nodes[nodenum];
    side := R_PointOnSide(x, y, node);
    nodenum := node.children[side];
  end;

  result := @subsectors[nodenum and not NF_SUBSECTOR];
end;

//
// R_SetupFrame
//
procedure R_SetupFrame(player: Pplayer_t);
var
  i: integer;
  cy: integer;
begin
  viewplayer := player;
  viewx := player.mo.x;
  viewy := player.mo.y;
  viewangle := player.mo.angle + viewangleoffset;
  extralight := player.extralight;

  viewz := player.viewz;

//{***********************
// Enable this for z axis shift (still buggy)
  cy := viewheight div 2 + player.lookdir * screenblocks div 10;
  if centery <> cy then
  begin
    centery := cy;
    centeryfrac := centery * FRACUNIT;
    for i := 0 to viewwidth - 1 do
      yslope[i] := FixedDiv(viewwidth div 2 * FRACUNIT,
        abs(((i - centery) * FRACUNIT) + FRACUNIT div 2));
  end;
//******************************}

  viewsin := finesine[_SHRW(viewangle, ANGLETOFINESHIFT)];
  viewcos := finecosine[_SHRW(viewangle, ANGLETOFINESHIFT)];

  sscount := 0;

  if player.fixedcolormap <> 0 then
  begin
    fixedcolormap := Plighttable_tArray(
      integer(colormaps) + player.fixedcolormap * 256 * SizeOf(lighttable_t));

    walllights := @scalelightfixed;

    for i := 0 to MAXLIGHTSCALE - 1 do
      scalelightfixed[i] := fixedcolormap;
  end
  else
    fixedcolormap := nil;

  inc(framecount);
  inc(validcount);
end;

//
// R_RenderView
//
procedure R_RenderPlayerView(player: Pplayer_t);
begin
  R_SetupFrame(player);

  // Clear buffers.
  R_ClearClipSegs;
  R_ClearDrawSegs;
  R_ClearPlanes;
  R_ClearSprites;

  // check for new console commands.
  NetUpdate;

  // The head node is the last node output.
  R_RenderBSPNode(numnodes - 1);

  // Check for new console commands.
  NetUpdate;

  R_DrawPlanes;

  // Check for new console commands.
  NetUpdate;

  R_DrawMasked;

  // Check for new console commands.
  NetUpdate;
end;

end.
