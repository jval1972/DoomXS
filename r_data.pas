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

unit r_data;

interface

uses
  d_delphi,
  m_fixed,
  r_defs;

// Retrieve column data for span blitting.
function R_GetColumn(tex: integer; col: integer): PByteArray;

// I/O, setting up the stuff.
procedure R_InitData;
procedure R_PrecacheLevel;

// Retrieval.
// Floor/ceiling opaque texture tiles,
// lookup by name. For animation?
function R_FlatNumForName(const name: string): integer;

// Called by P_Ticker for switches and animations,
// returns the texture number for the texture name.
function R_TextureNumForName(const name: string): integer;
function R_CheckTextureNumForName(const name: string): integer;

var
// for global animation
  flattranslation: PIntegerArray;
  texturetranslation: PIntegerArray;

// needed for texture pegging
  textureheight: Pfixed_tArray;
  texturecompositesize: PIntegerArray;

  firstspritelump: integer;
  lastspritelump: integer;

// needed for pre rendering
  spritewidth: Pfixed_tArray;
  spriteoffset: Pfixed_tArray;
  spritetopoffset: Pfixed_tArray;

  colormaps: Plighttable_tArray;

var
  firstflat: integer;
  lastflat: integer;
  numflats: integer;
  maxvisplane: integer;

procedure R_SetupLevel;

implementation

uses
  doomdef,
  doomstat,
  d_think,
  g_game,
  i_system,
  p_local,
  p_setup,
  p_tick,
  p_mobj_h,
  p_mobj,
  r_sky,
  r_things,
  w_wad,
  z_memory;

//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
//

//
// Texture definition.
// Each texture is composed of one or more patches,
// with patches being lumps stored in the WAD.
// The lumps are referenced by number, and patched
// into the rectangular texture space using origin
// and possibly other attributes.
//
type
  mappatch_t = record
    originx: smallint;
    originy: smallint;
    patch: smallint;
    stepdir: smallint;
    colormap: smallint;
  end;
  Pmappatch_t = ^mappatch_t;

// Texture definition.
// A DOOM wall texture is a list of patches
// which are to be combined in a predefined order.
  maptexture_t = packed record
    name: char8_t;
    masked: integer;
    width: smallint;
    height: smallint;
    columndirectory: PPointer; // OBSOLETE
    patchcount: smallint;
    patches: array[0..0] of mappatch_t;
  end;
  Pmaptexture_t = ^maptexture_t;

// A single patch from a texture definition,
//  basically a rectangular area within
//  the texture rectangle.
  texpatch_t = packed record
    // Block origin (allways UL),
    // which has allready accounted
    // for the internal origin of the patch.
    originx: integer;
    originy: integer;
    patch: integer;
  end;
  Ptexpatch_t = ^texpatch_t;

// A maptexturedef_t describes a rectangular texture,
//  which is composed of one or more mappatch_t structures
//  that arrange graphic patches.
  texture_t = packed record
    // Keep name for switch changing, etc.
    name: char8_t;
    width: smallint;
    height: smallint;

    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    patchcount: smallint;
    patches: array[0..0] of texpatch_t;
  end;
  Ptexture_t = ^texture_t;
  texture_tPArray = array[0..$FFFF] of Ptexture_t;
  Ptexture_tPArray = ^texture_tPArray;

var
  numspritelumps: integer;
  numtextures: integer;
  textures: Ptexture_tPArray;
  texturewidthmask: PIntegerArray;
  texturecolumnlump: PSmallIntPArray;
  texturecolumnofs: PWordPArray;
  texturecomposite: PBytePArray;

//
// MAPTEXTURE_T CACHING
// When a texture is first needed,
//  it counts the number of composite columns
//  required in the texture and allocates space
//  for a column directory and any new columns.
// The directory will simply point inside other patches
//  if there is only one patch in a given column,
//  but any columns with multiple patches
//  will have new column_ts generated.
//

//
// R_DrawColumnInCache
// Clip and draw a column
//  from a patch into a cached post.
//
procedure R_DrawColumnInCache(patch: Pcolumn_t; cache: PByteArray;
  originy: integer; cacheheight: integer);
var
  count: integer;
  position: integer;
  source: PByteArray;
begin
  while patch.topdelta <> $ff do
  begin
    source := PByteArray(integer(patch) + 3);

    count := patch.len;
    position := originy + patch.topdelta;

    if position < 0 then
    begin
      count := count + position;
      position := 0;
    end;

    if position + count > cacheheight then
      count := cacheheight - position;

    if count > 0 then
      memcpy(@cache[position], source, count);

    patch := Pcolumn_t(integer(patch) + patch.len + 4);
  end;
end;

// R_GenerateComposite
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
procedure R_GenerateComposite(texnum: integer);
var
  block: PByteArray;
  texture: Ptexture_t;
  patch: Ptexpatch_t;
  realpatch: Ppatch_t;
  x: integer;
  x1: integer;
  x2: integer;
  i: integer;
  patchcol: Pcolumn_t;
  collump: PSmallIntArray;
  colofs: PWordArray;
begin
  texture := textures[texnum];

  block := Z_Malloc(texturecompositesize[texnum], PU_STATIC, @texturecomposite[texnum]);

  collump := texturecolumnlump[texnum];
  colofs := texturecolumnofs[texnum];

  // Composite the columns together.
  for i := 0 to texture.patchcount - 1 do
  begin
    patch := @texture.patches[i];

    realpatch := W_CacheLumpNum(patch.patch, PU_STATIC);
    x1 := patch.originx;
    x2 := x1 + realpatch.width;

    if x1 < 0 then
      x := 0
    else
      x := x1;

    if x2 > texture.width then
      x2 := texture.width;

    while x < x2 do
    begin
      // Column does not have multiple patches?
      if collump[x] < 0 then
      begin
        patchcol := Pcolumn_t(integer(realpatch) + realpatch.columnofs[x - x1]);
        R_DrawColumnInCache(
          patchcol, @block[colofs[x]], patch.originy, texture.height);
      end;
      inc(x);
    end;
    Z_ChangeTag(realpatch, PU_CACHE);
  end;

  // Now that the texture has been built in column cache,
  //  it is purgable from zone memory.
  Z_ChangeTag(block, PU_CACHE);
end;

// R_GenerateLookup
procedure R_GenerateLookup(texnum: integer);
var
  texture: Ptexture_t;
  patchcount: PByteArray; // patchcount[texture->width]
  patch: Ptexpatch_t;
  realpatch: Ppatch_t;
  x: integer;
  x1: integer;
  x2: integer;
  i: integer;
  collump: PSmallIntArray;
  colofs: PWordArray;
begin
  texture := textures[texnum];

  // Composited texture not created yet.
  texturecomposite[texnum] := nil;

  texturecompositesize[texnum] := 0;
  collump := texturecolumnlump[texnum];
  colofs := texturecolumnofs[texnum];

  // Now count the number of columns
  //  that are covered by more than one patch.
  // Fill in the lump / offset, so columns
  //  with only a single patch are all done.
  patchcount := malloc(texture.width);
  patch := @texture.patches[0];

  for i := 0 to texture.patchcount - 1 do
  begin
    realpatch := W_CacheLumpNum(patch.patch, PU_STATIC);
    x1 := patch.originx;
    x2 := x1 + realpatch.width;

    if x1 < 0 then
      x := 0
    else
      x := x1;

    if x2 > texture.width then
      x2 := texture.width;
    while x < x2 do
    begin
      patchcount[x] := patchcount[x] + 1;
      collump[x] := patch.patch;
      colofs[x] := realpatch.columnofs[x - x1] + 3;
      inc(x);
    end;
    inc(patch);
    Z_ChangeTag(realpatch, PU_CACHE);
  end;

  for x := 0 to texture.width - 1 do
  begin
    if patchcount[x] = 0 then
    begin
      printf('R_GenerateLookup(): column without a patch (%s)' + #13#10, [texture.name]);
      exit;
    end; // I_Error ("R_GenerateLookup: column without a patch");


    if patchcount[x] > 1 then
    begin
      // Use the cached block.
      collump[x] := -1;
      colofs[x] := texturecompositesize[texnum];

      if texturecompositesize[texnum] > $10000 - texture.height then
        I_Error('R_GenerateLookup(): texture %d is >64k', [texnum]);

      texturecompositesize[texnum] := texturecompositesize[texnum] + texture.height;
    end;
  end;

  FreeMem(patchcount);
end;

// R_GetColumn
function R_GetColumn(tex: integer; col: integer): PByteArray;
var
  lump: integer;
  ofs: integer;
begin
  col := col and texturewidthmask[tex];
  lump := texturecolumnlump[tex][col];
  ofs := texturecolumnofs[tex][col];

  if lump > 0 then
  begin
    result := PByteArray(integer(W_CacheLumpNum(lump, PU_CACHE)) + ofs);
    exit;
  end;

  if texturecomposite[tex] = nil then
    R_GenerateComposite(tex);

  result := PByteArray(integer(texturecomposite[tex]) + ofs);
end;

// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
procedure R_InitTextures;
var
  mtexture: Pmaptexture_t;
  texture: Ptexture_t;
  mpatch: Pmappatch_t;
  patch: Ptexpatch_t;
  i: integer;
  j: integer;
  maptex: PIntegerArray;
  maptex2: PIntegerArray;
  maptex1: PIntegerArray;
  name: char8_t;
  names: PByteArray;
  name_p: PByteArray;
  patchlookup: PIntegerArray;
  nummappatches: integer;
  offset: integer;
  maxoff: integer;
  maxoff2: integer;
  numtextures1: integer;
  numtextures2: integer;
  directory: PIntegerArray;
begin
  // Load the patch names from pnames.lmp.
  ZeroMemory(@name, SizeOf(name));
  names := W_CacheLumpName('PNAMES', PU_STATIC);
  nummappatches := PInteger(names)^;
  name_p := PByteArray(integer(names) + 4);

  GetMem(patchlookup, nummappatches * SizeOf(integer));

  for i := 0 to nummappatches - 1 do
  begin
    for j := 0 to 7 do
      name[j] := Chr(name_p[i * 8 + j]);
    patchlookup[i] := W_CheckNumForName(char8tostring(name));
  end;
  Z_Free(names);

  // Load the map texture definitions from textures.lmp.
  // The data is contained in one or two lumps,
  //  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
  maptex1 := W_CacheLumpName('TEXTURE1', PU_STATIC);
  maptex := maptex1;
  numtextures1 := maptex[0];
  maxoff := W_LumpLength(W_GetNumForName('TEXTURE1'));
  directory := PintegerArray(integer(maptex) + SizeOf(integer));

  if W_CheckNumForName('TEXTURE2') <> -1 then
  begin
    maptex2 := W_CacheLumpName('TEXTURE2', PU_STATIC);
    numtextures2 := maptex2[0];
    maxoff2 := W_LumpLength(W_GetNumForName('TEXTURE2'));
  end
  else
  begin
    maptex2 := nil;
    numtextures2 := 0;
    maxoff2 := 0;
  end;
  numtextures := numtextures1 + numtextures2;

  textures := Z_Malloc(numtextures * 4, PU_STATIC, nil);
  texturecolumnlump := Z_Malloc(numtextures * 4, PU_STATIC, nil);
  texturecolumnofs := Z_Malloc(numtextures * 4, PU_STATIC, nil);
  texturecomposite := Z_Malloc(numtextures * 4, PU_STATIC, nil);
  texturecompositesize := Z_Malloc(numtextures * 4, PU_STATIC, nil);
  texturewidthmask := Z_Malloc(numtextures * 4, PU_STATIC, nil);
  textureheight := Z_Malloc(numtextures * 4, PU_STATIC, nil);

  for i := 0 to numtextures - 1 do
  begin
    if i = numtextures1 then
    begin
      // Start looking in second texture file.
      maptex := maptex2;
      maxoff := maxoff2;
      directory := PIntegerArray(integer(maptex) + SizeOf(integer));
    end;

    offset := directory[0];

    if offset > maxoff then
      I_Error('R_InitTextures(): bad texture directory');

    mtexture := Pmaptexture_t(integer(maptex) + offset);

    textures[i] :=
      Z_Malloc(
        SizeOf(texture_t) + SizeOf(texpatch_t) * (mtexture.patchcount - 1),
          PU_STATIC, nil);
    texture := textures[i];

    texture.width := mtexture.width;
    texture.height := mtexture.height;
    texture.patchcount := mtexture.patchcount;

    memcpy(@texture.name, @mtexture.name, SizeOf(texture.name));
    mpatch := @mtexture.patches[0];
    patch := @texture.patches[0];

    for j := 0 to texture.patchcount - 1 do
    begin
      patch.originx := mpatch.originx;
      patch.originy := mpatch.originy;
      patch.patch := patchlookup[mpatch.patch];
      if patch.patch = -1 then
        I_Error('R_InitTextures(): Missing patch in texture %s', [texture.name]);
      inc(mpatch);
      inc(patch);
    end;
    texturecolumnlump[i] := Z_Malloc(texture.width * 2, PU_STATIC, nil);
    texturecolumnofs[i] := Z_Malloc(texture.width * 2, PU_STATIC, nil);

    j := 1;
    while j * 2 <= texture.width do
      j := j * 2;

    texturewidthmask[i] := j - 1;
    textureheight[i] := texture.height * FRACUNIT;

    incp(pointer(directory), SizeOf(integer));
  end;

  Z_Free(maptex1);
  if maptex2 <> nil then
    Z_Free(maptex2);

  // Precalculate whatever possible.
  for i := 0 to numtextures - 1 do
    R_GenerateLookup(i);

  // Create translation table for global animation.
  texturetranslation := Z_Malloc((numtextures + 1) * SizeOf(integer), PU_STATIC, nil);

  for i := 0 to numtextures - 1 do
    texturetranslation[i] := i;
end;

// R_InitFlats
procedure R_InitFlats;
var
  i: integer;
begin
  firstflat := W_GetNumForName('F_START') + 1;
  lastflat := W_GetNumForName('F_END') - 1;
  numflats := lastflat - firstflat + 1;

  // Create translation table for global animation.
  flattranslation := Z_Malloc((numflats + 1) * 4, PU_STATIC, nil);

  for i := 0 to numflats - 1 do
    flattranslation[i] := i;
end;

// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
procedure R_InitSpriteLumps;
var
  i: integer;
  patch: Ppatch_t;
begin
  firstspritelump := W_GetNumForName('S_START') + 1;
  lastspritelump := W_GetNumForName('S_END') - 1;

  numspritelumps := lastspritelump - firstspritelump + 1;
  spritewidth := Z_Malloc(numspritelumps * 4, PU_STATIC, nil);
  spriteoffset := Z_Malloc(numspritelumps * 4, PU_STATIC, nil);
  spritetopoffset := Z_Malloc(numspritelumps * 4, PU_STATIC, nil);

  for i := 0 to numspritelumps - 1 do
  begin

    patch := W_CacheLumpNum(firstspritelump + i, PU_CACHE);
    spritewidth[i] := patch.width * FRACUNIT;
    spriteoffset[i] := patch.leftoffset * FRACUNIT;
    spritetopoffset[i] := patch.topoffset * FRACUNIT;
  end;
end;

// R_InitColormaps
procedure R_InitColormaps;
var
  lump: integer;
  length: integer;
begin
  // Load in the light tables,
  //  256 byte align tables.
  lump := W_GetNumForName('COLORMAP');
  length := W_LumpLength(lump) + 255;
  colormaps := Z_Malloc(length, PU_STATIC, nil);
  colormaps := Plighttable_tArray((integer(colormaps) + 255)and (not $ff));
  W_ReadLump(lump, colormaps);
end;

// R_InitData
// Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
procedure R_InitData;
begin
  R_InitTextures;
  printf(#13#10 + 'InitTextures');
  R_InitFlats;
  printf(#13#10 + 'InitFlats');
  R_InitSpriteLumps;
  printf(#13#10 + 'InitSprites');
  R_InitColormaps;
  printf(#13#10 + 'InitColormaps');
end;

// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
function R_FlatNumForName(const name: string): integer;
var
  i: integer;
begin
  i := W_CheckNumForName(name);

  if i = -1 then
    I_Error('R_FlatNumForName(): %s not found', [name]);

  result := i - firstflat;
end;

// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
function R_CheckTextureNumForName(const name: string): integer;
var
  i: integer;
  check: string;
begin
  // "NoTexture" marker.
  if name[1] = '-' then
  begin
    result := 0;
    exit;
  end;

  check := strupper(name);
  for i := 0 to numtextures - 1 do
    if strupper(char8tostring(textures[i].name)) = check then
    begin
      result := i;
      exit;
    end;

  result := -1;
end;

// R_TextureNumForName
// Calls R_CheckTextureNumForName,
//  aborts with error message.
function R_TextureNumForName(const name: string): integer;
begin
  result := R_CheckTextureNumForName(name);

  if result = -1 then
    I_Error('R_TextureNumForName(): %s not found', [name]);
end;

// R_PrecacheLevel
// Preloads all relevant graphics for the level.
var
  flatmemory: integer;
  texturememory: integer;
  spritememory: integer;

procedure R_PrecacheLevel;
var
  flatpresent: PByteArray;
  texturepresent: PByteArray;
  spritepresent: PByteArray;
  i: integer;
  j: integer;
  k: integer;
  lump: integer;
  texture: Ptexture_t;
  th: Pthinker_t;
  sf: Pspriteframe_t;
begin
  if demoplayback then
    exit;

  // Precache flats.
  flatpresent := malloc(numflats);

  for i := 0 to numsectors - 1 do
  begin
    flatpresent[sectors[i].floorpic] := 1;
    flatpresent[sectors[i].ceilingpic] := 1;
  end;

  flatmemory := 0;

  for i := 0 to numflats - 1 do
  begin
    if flatpresent[i] <> 0 then
    begin
      lump := firstflat + i;
      flatmemory := flatmemory + lumpinfo[lump].size;
      W_CacheLumpNum(lump, PU_CACHE);
    end;
  end;
  FreeMem(flatpresent);

  // Precache textures.
  texturepresent := malloc(numtextures);

  for i := 0 to numsides - 1 do
  begin
    texturepresent[sides[i].toptexture] := 1;
    texturepresent[sides[i].midtexture] := 1;
    texturepresent[sides[i].bottomtexture] := 1;
  end;

  // Sky texture is always present.
  // Note that F_SKY1 is the name used to
  //  indicate a sky floor/ceiling as a flat,
  //  while the sky texture is stored like
  //  a wall texture, with an episode dependend
  //  name.
  texturepresent[skytexture] := 1;

  texturememory := 0;
  for i := 0 to numtextures - 1 do
  begin
    if texturepresent[i] = 0 then
      continue;

    texture := textures[i];

    for j := 0 to texture.patchcount - 1 do
    begin
      lump := texture.patches[j].patch;
      texturememory := texturememory + lumpinfo[lump].size;
      W_CacheLumpNum(lump, PU_CACHE);
    end;
  end;
  FreeMem(texturepresent);

  // Precache sprites.
  spritepresent := malloc(numsprites);
  th := thinkercap.next;
  while th <> @thinkercap do
  begin
    if @th._function.acp1 = @P_MobjThinker then
      spritepresent[Ord(Pmobj_t(th).sprite)] := 1;
    th := th.next;
  end;

  spritememory := 0;
  for i := 0 to numsprites - 1 do
  begin
    if spritepresent[i] = 0 then
      continue;

    for j := 0 to sprites[i].numframes - 1 do
    begin
      sf := @sprites[i].spriteframes[j];
      for k := 0 to 7 do
      begin
        lump := firstspritelump + sf.lump[k];
        spritememory := spritememory + lumpinfo[lump].size;
        W_CacheLumpNum(lump, PU_CACHE);
      end;
    end;
  end;

  FreeMem(spritepresent);
end;

procedure R_SetupLevel;
begin
  maxvisplane := -1;
end;

end.
