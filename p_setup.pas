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

unit p_setup;

interface

uses d_delphi,
  doomdef, doomdata,
  m_fixed,
  p_mobj_h,
  r_defs;

{
    p_setup.h, p_setup.c
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
//   Setup a game, startup stuff.
//	Do all the WAD I/O, get map description,
//	set up initial state and misc. LUTs.
//
//-----------------------------------------------------------------------------

// NOT called by W_Ticker. Fixme.
procedure P_SetupLevel(episode, map, playermask: integer; skill: skill_t);

// Called by startup code.
procedure P_Init;

var
// origin of block map
  bmaporgx: fixed_t;
  bmaporgy: fixed_t;

  numvertexes: integer;
  vertexes: Pvertex_tArray;

  numsegs: integer;
  segs: Pseg_tArray;

  numsectors: integer;
  sectors: Psector_tArray;

  numsubsectors: integer;
  subsectors: Psubsector_tArray;

  numnodes: integer;
  nodes: Pnode_tArray;

  numlines: integer;
  lines: Pline_tArray;

  numsides: integer;
  sides: Pside_tArray;

//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
var

// BLOCKMAP
// Created from axis aligned bounding box
// of the map, a rectangular array of
// blocks of size ...
// Used to speed up collision detection
// by spatial subdivision in 2D.
//
// Blockmap size.
  bmapwidth: integer;
  bmapheight: integer; // size in mapblocks
  blockmap: PSmallIntArray; // int for larger maps
// offsets in blockmap are from here
  blockmaplump: PSmallIntArray;
// for thing chains
  blocklinks: Pmobj_tPArray;

// REJECT
// For fast sight rejection.
// Speeds up enemy AI by skipping detailed
//  LineOf Sight calculation.
// Without special effect, this could be
//  used as a PVS lookup as well.
//
  rejectmatrix: PByteArray;

const
// Maintain single and multi player starting spots.
  MAX_DEATHMATCH_STARTS = 10;

var
  deathmatchstarts: array[0..MAX_DEATHMATCH_STARTS - 1] of mapthing_t;
  deathmatch_p: integer; // VJ

  playerstarts: array[0..MAXPLAYERS - 1] of mapthing_t;

implementation

uses d_player,
  z_zone, m_bbox, g_game, i_system, w_wad,
  info,
  p_local, p_mobj, p_tick, p_spec, p_switch,
  r_data, r_things,
  s_sound, doomstat;


//
// P_LoadVertexes
//
procedure P_LoadVertexes(lump: integer);
var
  data: pointer;
  i: integer;
  ml: Pmapvertex_t;
  li: Pvertex_t;
begin
  // Determine number of lumps:
  //  total lump length / vertex record length.
  numvertexes := W_LumpLength(lump) div SizeOf(mapvertex_t);

  // Allocate zone memory for buffer.
  vertexes := Z_Malloc(numvertexes * SizeOf(vertex_t), PU_LEVEL, nil);

  // Load data into cache.
  data := W_CacheLumpNum(lump, PU_STATIC);

  ml := Pmapvertex_t(data);

  // Copy and convert vertex coordinates,
  // internal representation as fixed.
  for i := 0 to numvertexes - 1 do
  begin
    li := @vertexes[i];
    li.x := ml.x * FRACUNIT;
    li.y := ml.y * FRACUNIT;
    inc(ml);
  end;

  // Free buffer memory.
  Z_Free(data);
end;

//
// P_LoadSegs
//
procedure P_LoadSegs(lump: integer);
var
  data: pointer;
  i: integer;
  ml: Pmapseg_t;
  li: Pseg_t;
  ldef: Pline_t;
  linedef: integer;
  side: integer;
begin
  numsegs := W_LumpLength(lump) div SizeOf(mapseg_t);
  segs := Z_Malloc(numsegs * SizeOf(seg_t), PU_LEVEL, nil);
  memset(segs, 0, numsegs * SizeOf(seg_t));
  data := W_CacheLumpNum(lump, PU_STATIC);

  ml := Pmapseg_t(data);
  for i := 0 to numsegs - 1 do
  begin
    li := @segs[i];
    li.v1 := @vertexes[ml.v1];
    li.v2 := @vertexes[ml.v2];

    li.angle := _SHL(ml.angle, 16);
    li.offset := _SHL(ml.offset, 16);
    linedef := ml.linedef;
    ldef := @lines[linedef];
    li.linedef := ldef;
    side := ml.side;
    li.sidedef := @sides[ldef.sidenum[side]];
    li.frontsector := sides[ldef.sidenum[side]].sector;
    if boolval(ldef.flags and ML_TWOSIDED) then
      li.backsector := sides[ldef.sidenum[side xor 1]].sector
    else
      li.backsector := nil;
    inc(ml);
  end;

  Z_Free(data);
end;

//
// P_LoadSubsectors
//
procedure P_LoadSubsectors(lump: integer);
var
  data: pointer;
  i: integer;
  ms: Pmapsubsector_t;
  ss: Psubsector_t;
begin
  numsubsectors := W_LumpLength(lump) div SizeOf(mapsubsector_t);
  subsectors := Z_Malloc(numsubsectors * SizeOf(subsector_t), PU_LEVEL, nil);
  data := W_CacheLumpNum(lump, PU_STATIC);

  ms := Pmapsubsector_t(data);
  memset(subsectors, 0, numsubsectors * SizeOf(subsector_t));

  for i := 0 to numsubsectors - 1 do //; i++, ss++, ms++)
  begin
    ss := @subsectors[i];
    ss.numlines := ms.numsegs;
    ss.firstline := ms.firstseg;
    inc(ms);
  end;

  Z_Free(data);
end;

//
// P_LoadSectors
//
procedure P_LoadSectors(lump: integer);
var
  data: pointer;
  i: integer;
  ms: Pmapsector_t;
  ss: Psector_t;
begin
  numsectors := W_LumpLength(lump) div SizeOf(mapsector_t);
  sectors := Z_Malloc(numsectors * SizeOf(sector_t), PU_LEVEL, nil);
  memset(sectors, 0, numsectors * SizeOf(sector_t));
  data := W_CacheLumpNum(lump, PU_STATIC);

  ms := Pmapsector_t(data);
  for i := 0 to numsectors - 1 do //; i++, ss++, ms++)
  begin
    ss := @sectors[i];
    ss.floorheight := ms.floorheight * FRACUNIT;
    ss.ceilingheight := ms.ceilingheight * FRACUNIT;
    ss.floorpic := R_FlatNumForName(ms.floorpic);
    ss.ceilingpic := R_FlatNumForName(ms.ceilingpic);
    ss.lightlevel := ms.lightlevel;
    ss.special := ms.special;
    ss.tag := ms.tag;
    ss.thinglist := nil;
    inc(ms);
  end;

  Z_Free (data);
end;

//
// P_LoadNodes
//
procedure P_LoadNodes(lump: integer);
var
  data: pointer;
  i: integer;
  j: integer;
  k: integer;
  mn: Pmapnode_t;
  no: Pnode_t;
begin
  numnodes := W_LumpLength(lump) div SizeOf(mapnode_t);
  nodes := Z_Malloc(numnodes * SizeOf(node_t), PU_LEVEL, nil);
  data := W_CacheLumpNum(lump, PU_STATIC);

  mn := Pmapnode_t(data);

  for i := 0 to numnodes - 1 do //; i++, no++, mn++)
  begin
    no := @nodes[i];
    no.x := mn.x * FRACUNIT;
    no.y := mn.y * FRACUNIT;
    no.dx := mn.dx * FRACUNIT;
    no.dy := mn.dy * FRACUNIT;
    for j := 0 to 1 do
    begin
      no.children[j] := mn.children[j];
      for k := 0 to 3 do
        no.bbox[j, k] := SmallInt(mn.bbox[j, k]) * FRACUNIT;
    end;
    inc(mn);
  end;

  Z_Free (data);
end;

//
// P_LoadThings
//
procedure P_LoadThings(lump: integer);
var
  data: pointer;
  i: integer;
  mt: Pmapthing_t;
  numthings: integer;
  spawn: boolean;
begin
  data := W_CacheLumpNum(lump, PU_STATIC);
  numthings := W_LumpLength(lump) div SizeOf(mapthing_t);

  mt := Pmapthing_t(data);
  for i := 0 to numthings - 1 do
  begin
    spawn := true;
    // Do not spawn cool, new monsters if !commercial
    if gamemode <> commercial then
    begin
      case mt._type of
        68, // Arachnotron
        64, // Archvile
        88, // Boss Brain
        89, // Boss Shooter
        69, // Hell Knight
        67, // Mancubus
        71, // Pain Elemental
        65, // Former Human Commando
        66, // Revenant
        84: // Wolf SS
          spawn := false;
      end;
    end;

    if spawn then
    begin
      // Do spawn all other stuff.
      mt.x := SmallInt(mt.x);
      mt.y := SmallInt(mt.y);
      mt.angle := SmallInt(mt.angle);
      mt._type := SmallInt(mt._type);
      mt.options := SmallInt(mt.options);

      P_SpawnMapThing(mt);
    end;
    inc(mt);
  end;

  Z_Free(data);
end;

//
// P_LoadLineDefs
// Also counts secret lines for intermissions.
//
procedure P_LoadLineDefs(lump: integer);
var
  data: pointer;
  i: integer;
  mld: Pmaplinedef_t;
  ld: Pline_t;
  v1: Pvertex_t;
  v2: Pvertex_t;
begin
  numlines := W_LumpLength(lump) div SizeOf(maplinedef_t);
  lines := Z_Malloc(numlines * SizeOf(line_t), PU_LEVEL, nil);
  memset(lines, 0, numlines * SizeOf(line_t));
  data := W_CacheLumpNum(lump, PU_STATIC);

  mld := Pmaplinedef_t(data);
  for i := 0 to numlines - 1 do
  begin
    ld := @lines[i];
    ld.flags := SmallInt(mld.flags);
    ld.special := SmallInt(mld.special);
    ld.tag := SmallInt(mld.tag);
    ld.v1 := @vertexes[SmallInt(mld.v1)];
    v1 := ld.v1;
    ld.v2 := @vertexes[SmallInt(mld.v2)];
    v2 := ld.v2;
    ld.dx := v2.x - v1.x;
    ld.dy := v2.y - v1.y;

    if not boolval(ld.dx) then
      ld.slopetype := ST_VERTICAL
    else if not boolval(ld.dy) then
      ld.slopetype := ST_HORIZONTAL
    else
    begin
      if FixedDiv(ld.dy , ld.dx) > 0 then
        ld.slopetype := ST_POSITIVE
      else
        ld.slopetype := ST_NEGATIVE;
    end;

    if v1.x < v2.x then
    begin
      ld.bbox[BOXLEFT] := v1.x;
      ld.bbox[BOXRIGHT] := v2.x;
    end
    else
    begin
      ld.bbox[BOXLEFT] := v2.x;
      ld.bbox[BOXRIGHT] := v1.x;
    end;

    if v1.y < v2.y then
    begin
      ld.bbox[BOXBOTTOM] := v1.y;
      ld.bbox[BOXTOP] := v2.y;
    end
    else
    begin
      ld.bbox[BOXBOTTOM] := v2.y;
      ld.bbox[BOXTOP] := v1.y;
    end;

    ld.sidenum[0] := SmallInt(mld.sidenum[0]);
    ld.sidenum[1] := SmallInt(mld.sidenum[1]);

    if ld.sidenum[0] <> -1 then
      ld.frontsector := sides[ld.sidenum[0]].sector
    else
      ld.frontsector := nil;

    if ld.sidenum[1] <> -1 then
      ld.backsector := sides[ld.sidenum[1]].sector
    else
      ld.backsector := nil;

    inc(mld);
  end;

  Z_Free (data);
end;

//
// P_LoadSideDefs
//
procedure P_LoadSideDefs(lump: integer);
var
  data: pointer;
  i: integer;
  msd: Pmapsidedef_t;
  sd: Pside_t;
begin
  numsides := W_LumpLength(lump) div SizeOf(mapsidedef_t);
  sides := Z_Malloc(numsides * SizeOf(side_t), PU_LEVEL, nil);
  memset(sides, 0, numsides * SizeOf(side_t));
  data := W_CacheLumpNum(lump, PU_STATIC);

  msd := Pmapsidedef_t(data);
  for i := 0 to numsides - 1 do
  begin
    sd := @sides[i];
    sd.textureoffset := SmallInt(msd.textureoffset) * FRACUNIT;
    sd.rowoffset := SmallInt(msd.rowoffset) * FRACUNIT;
    sd.toptexture := R_TextureNumForName(msd.toptexture);
    sd.bottomtexture := R_TextureNumForName(msd.bottomtexture);
    sd.midtexture := R_TextureNumForName(msd.midtexture);
    sd.sector := @sectors[SmallInt(msd.sector)];
    inc(msd);
  end;

  Z_Free (data);
end;

//
// P_LoadBlockMap
//
procedure P_LoadBlockMap(lump: integer);
var
  count: integer;
begin
  blockmaplump := W_CacheLumpNum(lump, PU_LEVEL);
//  blockmap := PSmallIntArray(integer(blockmaplump) + 4);
  blockmap := @blockmaplump[4];

  bmaporgx := blockmaplump[0] * FRACUNIT;
  bmaporgy := blockmaplump[1] * FRACUNIT;
  bmapwidth := blockmaplump[2];
  bmapheight := blockmaplump[3];

  // clear out mobj chains
  count := SizeOf(Pmobj_t) * bmapwidth * bmapheight;
  blocklinks := Z_Malloc(count, PU_LEVEL, nil);
  memset(blocklinks, 0, count);
end;

//
// P_GroupLines
// Builds sector line lists and subsector sector numbers.
// Finds block bounding boxes for sectors.
//
procedure P_GroupLines;
var
  linebuffer: Pline_tPArray; // pointer to an array of pointers Pline_t
  i: integer;
  j: integer;
  total: integer;
  li: Pline_t;
  sector: Psector_t;
  seg: Pseg_t;
  bbox: array[0..3] of fixed_t;
  block: integer;
begin
  // look up sector number for each subsector
  for i := 0 to numsubsectors - 1 do
  begin
    seg := @segs[subsectors[i].firstline];
    subsectors[i].sector := seg.sidedef.sector;
  end;

  // count number of lines in each sector
  total := 0;
  for i := 0 to numlines - 1 do
  begin
    li := @lines[i];
    inc(total);
    li.frontsector.linecount := li.frontsector.linecount + 1;

    if boolval(li.backsector) and (li.backsector <> li.frontsector) then
    begin
      li.backsector.linecount := li.backsector.linecount + 1;
      inc(total);
    end;
  end;

  // build line tables for each sector
  linebuffer := Z_Malloc(total * 4, PU_LEVEL, nil);
  for i := 0 to numsectors - 1 do
  begin
    sector := @sectors[i];
    M_ClearBox(@bbox);
    sector.lines := linebuffer;
    for j := 0 to numlines - 1 do
    begin
      li := @lines[j];
	    if (li.frontsector = sector) or (li.backsector = sector) then
      begin
  		  linebuffer[0] := li;
        incp(pointer(linebuffer), SizeOf(Pointer));
        M_AddToBox(@bbox, li.v1.x, li.v1.y);
        M_AddToBox(@bbox, li.v2.x, li.v2.y);
      end;
    end;
    if pOperation(linebuffer, sector.lines, '-', SizeOf(pointer)) <> sector.linecount then
      I_Error('P_GroupLines(): miscounted'); // VJ ?????

    // set the degenmobj_t to the middle of the bounding box
    sector.soundorg.x := (bbox[BOXRIGHT] + bbox[BOXLEFT]) div 2;
    sector.soundorg.y := (bbox[BOXTOP] + bbox[BOXBOTTOM]) div 2;

    // adjust bounding box to map blocks
    block := _SHR(bbox[BOXTOP] - bmaporgy + MAXRADIUS, MAPBLOCKSHIFT);
    if block >= bmapheight then
      block  := bmapheight - 1;
    sector.blockbox[BOXTOP] := block;

    block := _SHR(bbox[BOXBOTTOM] - bmaporgy - MAXRADIUS, MAPBLOCKSHIFT);
    if block < 0 then
      block  := 0;
    sector.blockbox[BOXBOTTOM] := block;

    block := _SHR(bbox[BOXRIGHT] - bmaporgx + MAXRADIUS, MAPBLOCKSHIFT);
    if block >= bmapwidth then
      block := bmapwidth - 1;
    sector.blockbox[BOXRIGHT] := block;

    block := _SHR(bbox[BOXLEFT] - bmaporgx - MAXRADIUS, MAPBLOCKSHIFT);
    if block < 0 then
      block := 0;
    sector.blockbox[BOXLEFT] := block;
  end;
end;

//
// P_SetupLevel
//
procedure P_SetupLevel(episode, map, playermask: integer; skill: skill_t);
var
  i: integer;
  lumpname: string;
  lumpnum: integer;
begin
  totalkills := 0;
  totalitems := 0;
  totalsecret := 0;

  wminfo.maxfrags := 0;
  wminfo.partime := 180;
  for i := 0 to MAXPLAYERS - 1 do
  begin
	  players[i].killcount := 0;
    players[i].secretcount := 0;
    players[i].itemcount := 0;
  end;

  // Initial height of PointOfView
  // will be set by player think.
  players[consoleplayer].viewz := 1;

  // Make sure all sounds are stopped before Z_FreeTags.
  S_Start;

(*
#if 0 // UNUSED
    if (debugfile)
    {
	Z_FreeTags (PU_LEVEL, MAXINT);
	Z_FileDumpHeap (debugfile);
    }
    else
#endif
*)

  Z_FreeTags(PU_LEVEL, PU_PURGELEVEL - 1);

  R_SetupLevel;

  // UNUSED W_Profile ();
  P_InitThinkers;

  // if working with a devlopment map, reload it
  W_Reload;

  // find map name
  if gamemode = commercial then
  begin
    if map < 10 then
      sprintf(lumpname,'map0%d', [map])
    else
      sprintf(lumpname,'map%d', [map]);
  end
  else
    sprintf(lumpname, 'E%dM%d', [episode, map]);

  lumpnum := W_GetNumForName(lumpname);

  leveltime := 0;

  // note: most of this ordering is important
  P_LoadBlockMap(lumpnum + Ord(ML_BLOCKMAP));
  P_LoadVertexes(lumpnum + Ord(ML_VERTEXES));
  P_LoadSectors(lumpnum + Ord(ML_SECTORS));
  P_LoadSideDefs(lumpnum + Ord(ML_SIDEDEFS));

  P_LoadLineDefs(lumpnum + Ord(ML_LINEDEFS));
  P_LoadSubsectors(lumpnum + Ord(ML_SSECTORS));
  P_LoadNodes(lumpnum + Ord(ML_NODES));
  P_LoadSegs(lumpnum + Ord(ML_SEGS));

  rejectmatrix := W_CacheLumpNum(lumpnum + Ord(ML_REJECT), PU_LEVEL);
  P_GroupLines;

  bodyqueslot := 0;
  deathmatch_p := 0;
  P_LoadThings(lumpnum + Ord(ML_THINGS));

  // if deathmatch, randomly spawn the active players
  if boolval(deathmatch) then
  begin
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
      begin
        players[i].mo := nil;
        G_DeathMatchSpawnPlayer(i);
      end;
  end;

  // clear special respawning que
  iquehead := 0;
  iquetail := 0;

  // set up world state
  P_SpawnSpecials;

  // build subsector connect matrix
  // UNUSED P_ConnectSubsectors ();

  // preload graphics
  if precache then
    R_PrecacheLevel;

    //printf ("free memory: 0x%x\n", Z_FreeMemory());
end;

//
// P_Init
//
procedure P_Init;
begin
  P_InitSwitchList;
  P_InitPicAnims;
  R_InitSprites(sprnames);
end;

end.
