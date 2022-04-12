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
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
unit r_things;

interface

uses
  d_delphi,
  doomdef,
  info,
  m_fixed,
  r_defs;

const
  MAXVISSPRITES = 256; // JVAL was = 128

procedure R_DrawMaskedColumn(column: Pcolumn_t);

procedure R_SortVisSprites;

procedure R_AddSprites(sec: Psector_t);
procedure R_InitSprites(namelist: PsprnamesArray_t);
procedure R_ClearSprites;
procedure R_DrawMasked;

var
  pspritescale: fixed_t;
  pspriteyscale: fixed_t;
  pspriteiscale: fixed_t;

var
  mfloorclip: PSmallIntArray;
  mceilingclip: PSmallIntArray;
  spryscale: fixed_t;
  sprtopscreen: fixed_t;

// constant arrays
//  used for psprite clipping and initializing clipping
  negonearray: packed array[0..SCREENWIDTH - 1] of smallint;
  screenheightarray: packed array[0..SCREENWIDTH - 1] of smallint;

// variables used to look up
//  and range check thing_t sprites patches
  sprites: Pspritedef_tArray;
  numsprites: integer;

implementation

uses
  tables,
  i_system,
  p_mobj_h,
  p_pspr,
  p_pspr_h,
  r_data,
  r_draw,
  r_main,
  r_bsp,
  r_segs,
  z_memory,
  w_wad,
  doomstat;

const
  MINZ = FRACUNIT * 4;
  BASEYCENTER = 100;

// Sprite rotation 0 is facing the viewer,
//  rotation 1 is one angle turn CLOCKWISE around the axis.
// This is not the same as the angle,
//  which increases counter clockwise (protractor).
// There was a lot of stuff grabbed wrong, so I changed it...
var
  spritelights: Plighttable_tPArray;

// INITIALIZATION FUNCTIONS
const
  MAXFRAMES = 29; // Maximun number of frames in sprite

var
  sprtemp: array[0..MAXFRAMES - 1] of spriteframe_t;
  maxframe: integer;
  spritename: string;

// R_InstallSpriteLump
// Local function for R_InitSprites.
procedure R_InstallSpriteLump(lump: integer;
  frame: LongWord; rotation: LongWord; flipped: boolean);
var
  r: integer;
begin
  if (frame >= MAXFRAMES) or (rotation > 8) then
    I_Error('R_InstallSpriteLump(): Bad frame characters in lump %d', [lump]);

  if integer(frame) > maxframe then
    maxframe := frame;

  if rotation = 0 then
  begin
    // the lump should be used for all rotations
    if sprtemp[frame].rotate = 0 then
      I_Error('R_InitSprites(): Sprite %s frame %s has multip rot=0 lump',
        [spritename, Chr(Ord('A') + frame)]);

    if sprtemp[frame].rotate = 1 then
      I_Error('R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump',
        [spritename, Chr(Ord('A') + frame)]);

    sprtemp[frame].rotate := 0;
    for r := 0 to 7 do
    begin
      sprtemp[frame].lump[r] := lump - firstspritelump;
      sprtemp[frame].flip[r] := flipped;
    end;
    Exit;
  end;

  // the lump is only used for one rotation
  if sprtemp[frame].rotate = 0 then
    I_Error('R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump',
      [spritename, Chr(Ord('A') + frame)]);

  sprtemp[frame].rotate := 1;

  // make 0 based
  dec(rotation);
  if sprtemp[frame].lump[rotation] <> -1 then
    I_Error('R_InitSprites(): Sprite %s : %s : %s has two lumps mapped to it',
      [spritename, Chr(Ord('A') + frame), Chr(Ord('1') + rotation)]);

  sprtemp[frame].lump[rotation] := lump - firstspritelump;
  sprtemp[frame].flip[rotation] := flipped;
end;

// R_InitSpriteDefs
// Pass a null terminated list of sprite names
//  (4 chars exactly) to be used.
// Builds the sprite rotation matrixes to account
//  for horizontally flipped sprites.
// Will report an error if the lumps are inconsistant.
// Only called at startup.

// Sprite lump names are 4 characters for the actor,
//  a letter for the frame, and a number for the rotation.
// A sprite that is flippable will have an additional
//  letter/number appended.
// The rotation character can be 0 to signify no rotations.
procedure R_InitSpriteDefs(namelist: PsprnamesArray_t);

  procedure sprtempreset;
  var
    i: integer;
    j: integer;
  begin
    for i := 0 to MAXFRAMES - 1 do
    begin
      sprtemp[i].rotate := -1;
      for j := 0 to 7 do
      begin
        sprtemp[i].lump[j] := -1;
        sprtemp[i].flip[j] := False;
      end;
    end;
  end;

var
  i: integer;
  l: integer;
  intname: integer;
  frame: integer;
  rotation: integer;
  start: integer;
  finish: integer;
  patched: integer;
begin
  // count the number of sprite names
  numsprites := 0;
  while namelist[numsprites] <> '' do
    inc(numsprites);

  if numsprites = 0 then
    Exit;

  sprites := Z_Malloc(numsprites * SizeOf(spritedef_t), PU_STATIC, nil);

  start := firstspritelump - 1;
  finish := lastspritelump + 1;

  // scan all the lump names for each of the names,
  //  noting the highest frame letter.
  // Just compare 4 characters as ints
  for i := 0 to numsprites - 1 do
  begin
    spritename := namelist[i];

    sprtempreset;

    maxframe := -1;
    intname := PInteger(@spritename[1])^;

    // scan the lumps,
    //  filling in the frames for whatever is found
    for l := start + 1 to finish - 1 do
    begin
      if lumpinfo[l].v1 = intname then
      begin
        frame := Ord(lumpinfo[l].name[4]) - Ord('A');
        rotation := Ord(lumpinfo[l].name[5]) - Ord('0');

        if modifiedgame then
          patched := W_GetNumForName(lumpinfo[l].name)
        else
          patched := l;

        R_InstallSpriteLump(patched, frame, rotation, False);

        if lumpinfo[l].name[6] <> #0 then
        begin
          frame := Ord(lumpinfo[l].name[6]) - Ord('A');
          rotation := Ord(lumpinfo[l].name[7]) - Ord('0');
          R_InstallSpriteLump(l, frame, rotation, True);
        end;
      end;
    end;

    // check the frames that were found for completeness
    if maxframe = -1 then
    begin
      sprites[i].numframes := 0;
      Continue;
    end;

    inc(maxframe);

    for frame := 0 to maxframe - 1 do
    begin
      case sprtemp[frame].rotate of
        -1:
          begin
            // no rotations were found for that frame at all
            I_Error('R_InitSprites(): No patches found for %s frame %s',
              [namelist[i], Chr(frame + Ord('A'))]);
          end;
         0:
          begin
            // only the first rotation is needed
          end;
         1:
          begin
            // must have all 8 frames
            for rotation := 0 to 7 do
              if sprtemp[frame].lump[rotation] = -1 then
                I_Error('R_InitSprites(): Sprite %s frame %s is missing rotations',
                  [namelist[i], Chr(frame + Ord('A'))]);
          end;
      end;
    end;

    // allocate space for the frames present and copy sprtemp to it
    sprites[i].numframes := maxframe;
    sprites[i].spriteframes :=
      Z_Malloc(maxframe * SizeOf(spriteframe_t), PU_STATIC, nil);
    memcpy(sprites[i].spriteframes, @sprtemp, maxframe * SizeOf(spriteframe_t));
  end;
end;

// GAME FUNCTIONS
var
  vissprites: array[0..MAXVISSPRITES - 1] of vissprite_t;
  vissprite_p: integer;

// R_InitSprites
// Called at program start.
procedure R_InitSprites(namelist: PsprnamesArray_t);
var
  i: integer;
begin
  for i := 0 to SCREENWIDTH - 1 do
    negonearray[i] := -1;

  R_InitSpriteDefs(namelist);
end;

// R_ClearSprites
// Called at frame start.
procedure R_ClearSprites;
begin
  vissprite_p := 0;
end;

// R_NewVisSprite
var
  overflowsprite: vissprite_t;

function R_NewVisSprite: Pvissprite_t;
begin
  if vissprite_p = MAXVISSPRITES then
    Result := @overflowsprite
  else
  begin
    Result := @vissprites[vissprite_p];
    inc(vissprite_p);
  end;
end;

// R_DrawMaskedColumn
// Used for sprites and masked mid textures.
// Masked means: partly transparent, i.e. stored
//  in posts/runs of opaque pixels.
procedure R_DrawMaskedColumn(column: Pcolumn_t);
var
  topscreen: integer;
  bottomscreen: integer;
  basetexturemid: fixed_t;
begin
  basetexturemid := dc_texturemid;

  while column.topdelta <> $ff do
  begin
    // calculate unclipped screen coordinates
    // for post
    topscreen := sprtopscreen + spryscale * column.topdelta;
    bottomscreen := topscreen + spryscale * column.len;

    dc_yl := (topscreen + FRACUNIT - 1) div FRACUNIT;
    dc_yh := (bottomscreen - 1) div FRACUNIT;

    if dc_yh >= mfloorclip[dc_x] then
      dc_yh := mfloorclip[dc_x] - 1;
    if dc_yl <= mceilingclip[dc_x] then
      dc_yl := mceilingclip[dc_x] + 1;

    if dc_yl <= dc_yh then
    begin
      dc_source := PByteArray(PCAST(column) + 3);
      dc_texturemid := basetexturemid - (column.topdelta * FRACUNIT);

      // Drawn by either R_DrawColumn
      //  or (SHADOW) R_DrawFuzzColumn.
      colfunc;
    end;
    incp(pointer(column), column.len + 4);
  end;

  dc_texturemid := basetexturemid;
end;

// R_DrawVisSprite
//  mfloorclip and mceilingclip should also be set.
procedure R_DrawVisSprite(vis: Pvissprite_t; x1: integer; x2: integer);
var
  column: Pcolumn_t;
  texturecolumn: integer;
  frac: fixed_t;
  patch: Ppatch_t;
  i: integer;
begin
  patch := W_CacheLumpNum(vis.patch + firstspritelump, PU_STATIC);

  dc_colormap := vis.colormap;

  if dc_colormap = nil then
    colfunc := fuzzcolfunc // NULL colormap = shadow draw
  else if vis.mobjflags and MF_TRANSLATION <> 0 then
  begin
    colfunc := R_DrawTranslatedColumn;
    dc_translation := PByteArray(PCAST(translationtables) - 256 +
      ( _SHR((vis.mobjflags and MF_TRANSLATION), (MF_TRANSSHIFT - 8)) ));
  end;

  dc_iscale := abs(FixedDiv(FRACUNIT, vis.scale));
  dc_texturemid := vis.texturemid;
  frac := vis.startfrac;
  spryscale := vis.scale;
  sprtopscreen := centeryfrac - FixedMul(dc_texturemid, spryscale);

  for i := vis.x1 to vis.x2 do
  begin
    dc_x := i;
    texturecolumn := frac div FRACUNIT;
    column := Pcolumn_t(PCAST(patch) + patch.columnofs[texturecolumn]);
    R_DrawMaskedColumn(column);
    frac := frac + vis.xiscale;
  end;

  colfunc := basecolfunc;

  Z_ChangeTag(patch, PU_CACHE);
end;

procedure R_DrawPVisSprite(vis: Pvissprite_t);
var
  column: Pcolumn_t;
  texturecolumn: integer;
  frac: fixed_t;
  fracstep: fixed_t;
  patch: Ppatch_t;
  i: integer;
begin
  patch := W_CacheLumpNum(vis.patch + firstspritelump, PU_CACHE);

  dc_colormap := vis.colormap;

  if dc_colormap = nil then
    colfunc := fuzzcolfunc  // NULL colormap = shadow draw
  else if vis.mobjflags and MF_TRANSLATION <> 0 then
  begin
    colfunc := R_DrawTranslatedColumn;
    dc_translation := PByteArray(PCAST(translationtables) - 256 +
      ( _SHR((vis.mobjflags and MF_TRANSLATION), (MF_TRANSSHIFT - 8)) ));
  end;

  dc_iscale := FixedDiv(FRACUNIT, vis.scale); //vis.xiscale;
  dc_texturemid := vis.texturemid;
  frac := vis.startfrac;
  fracstep := vis.xiscale;
  spryscale := vis.scale;
  sprtopscreen := centeryfrac - FixedMul(dc_texturemid, spryscale);
  for i := vis.x1 to vis.x2 do
  begin
    dc_x := i;
    texturecolumn := frac div FRACUNIT;
    column := Pcolumn_t(PCAST(patch) + patch.columnofs[texturecolumn]);
    R_DrawMaskedColumn(column);
    frac := frac + fracstep;
  end;

  colfunc := basecolfunc;
end;

// R_ProjectSprite
// Generates a vissprite for a thing
//  if it might be visible.
procedure R_ProjectSprite(thing: Pmobj_t);
var
  tr_x: fixed_t;
  tr_y: fixed_t;
  gxt: fixed_t;
  gyt: fixed_t;
  tx: fixed_t;
  tz: fixed_t;
  xscale: fixed_t;
  x1: integer;
  x2: integer;
  sprdef: Pspritedef_t;
  sprframe: Pspriteframe_t;
  lump: integer;
  rot: LongWord;
  flip: boolean;
  index: integer;
  vis: Pvissprite_t;
  ang: angle_t;
  iscale: fixed_t;
begin
  // transform the origin point
  tr_x := thing.x - viewx;
  tr_y := thing.y - viewy;

  gxt := FixedMul(tr_x, viewcos);
  gyt := -FixedMul(tr_y, viewsin);

  tz := gxt - gyt;

  // thing is behind view plane?
  if tz < MINZ then
    Exit;

  xscale := FixedDiv(projection, tz);

  gxt := -FixedMul(tr_x, viewsin);
  gyt := FixedMul(tr_y, viewcos);
  tx := -(gyt + gxt);

  // too far off the side?
  if abs(tx) > 4 * tz then
    Exit;

  // decide which patch to use for sprite relative to player
  sprdef := @sprites[Ord(thing.sprite)];
  sprframe := @sprdef.spriteframes[thing.frame and FF_FRAMEMASK];

  if sprframe.rotate <> 0 then
  begin
    // choose a different rotation based on player view
    ang := R_PointToAngle(thing.x, thing.y);
    rot := (ang - thing.angle + LongWord(ANG45 div 2) * 9) shr 29;
    lump := sprframe.lump[rot];
    flip := sprframe.flip[rot];
  end
  else
  begin
    // use single rotation for all views
    lump := sprframe.lump[0];
    flip := sprframe.flip[0];
  end;

  // calculate edges of the shape
  tx := tx - spriteoffset[lump];
  x1 := (centerxfrac + FixedMul(tx, xscale)) div FRACUNIT;

  // off the right side?
  if x1 > viewwidth then
    Exit;

  tx := tx + spritewidth[lump];
  x2 := ((centerxfrac + FixedMul(tx, xscale)) div FRACUNIT) - 1;

  // off the left side
  if x2 < 0 then
    Exit;

  // store information in a vissprite
  vis := R_NewVisSprite;
  vis.mobjflags := thing.flags;
  vis.scale := FixedDiv(projectiony, tz);
  vis.gx := thing.x;
  vis.gy := thing.y;
  vis.gz := thing.z;
  vis.gzt := thing.z + spritetopoffset[lump];
  vis.texturemid := vis.gzt - viewz;
  vis.x1 := decide(x1 < 0, 0, x1);
  vis.x2 := decide(x2 >= viewwidth, viewwidth - 1, x2);
  iscale := FixedDiv(FRACUNIT, xscale);

  if flip then
  begin
    vis.startfrac := spritewidth[lump] - 1;
    vis.xiscale := -iscale;
  end
  else
  begin
    vis.startfrac := 0;
    vis.xiscale := iscale;
  end;

  if vis.x1 > x1 then
    vis.startfrac := vis.startfrac + vis.xiscale * (vis.x1 - x1);
  vis.patch := lump;

  // get light level
  if thing.flags and MF_SHADOW <> 0 then
    vis.colormap := nil // shadow draw
  else if fixedcolormap <> nil then
    vis.colormap := fixedcolormap // fixed map
  else if thing.frame and FF_FULLBRIGHT <> 0 then
    vis.colormap := colormaps // full bright
  else
  begin
    // diminished light
    index := _SHR(xscale, LIGHTSCALESHIFT);
    if index >= MAXLIGHTSCALE then
      index := MAXLIGHTSCALE - 1;
    vis.colormap := spritelights[index];
  end;
end;

// R_AddSprites
// During BSP traversal, this adds sprites by sector.
procedure R_AddSprites(sec: Psector_t);
var
  thing: Pmobj_t;
  lightnum: integer;
begin
  // BSP is traversed by subsector.
  // A sector might have been split into several
  // subsectors during BSP building.
  // Thus we check whether its already added.
  if sec.validcount = validcount then
    Exit;

  // Well, now it will be done.
  sec.validcount := validcount;

  lightnum := _SHR(sec.lightlevel, LIGHTSEGSHIFT) + extralight;

  if lightnum < 0 then
    spritelights := @scalelight[0, 0]
  else if lightnum >= LIGHTLEVELS then
    spritelights := @scalelight[LIGHTLEVELS - 1, 0]
  else
    spritelights := @scalelight[lightnum, 0];

  // Handle all things in sector.
  thing := sec.thinglist;
  while thing <> nil do
  begin
    R_ProjectSprite(thing);
    thing := thing.snext;
  end;
end;

// R_DrawPSprite
procedure R_DrawPSprite(psp: Ppspdef_t);
var
  tx: fixed_t;
  x1: integer;
  x2: integer;
  sprdef: Pspritedef_t;
  sprframe: Pspriteframe_t;
  lump: integer;
  flip: boolean;
  vis: Pvissprite_t;
  avis: vissprite_t;
begin
  // decide which patch to use
  sprdef := @sprites[Ord(psp.state.sprite)];
  sprframe := @sprdef.spriteframes[psp.state.frame and FF_FRAMEMASK];

  lump := sprframe.lump[0];
  flip := sprframe.flip[0];

  // calculate edges of the shape
  tx := psp.sx - 160 * FRACUNIT;

  tx := tx - spriteoffset[lump];
  x1 := (centerxfrac + FixedMul(tx, pspritescale)) div FRACUNIT;

  // off the right side
  if x1 > viewwidth then
    Exit;

  tx := tx + spritewidth[lump];
  x2 := ((centerxfrac + FixedMul(tx, pspritescale)) div FRACUNIT) - 1;

  // off the left side
  if x2 < 0 then
    Exit;

  // store information in a vissprite
  vis := @avis;
  vis.mobjflags := 0;
  vis.texturemid := (BASEYCENTER * FRACUNIT) + FRACUNIT div 2 - (psp.sy - spritetopoffset[lump]);
  vis.x1 := decide(x1 < 0, 0, x1);
  vis.x2 := decide(x2 >= viewwidth, viewwidth - 1, x2);
  vis.scale := pspriteyscale;

  if flip then
  begin
    vis.xiscale := -pspriteiscale;
    vis.startfrac := spritewidth[lump] - 1;
  end
  else
  begin
    vis.xiscale := pspriteiscale;
    vis.startfrac := 0;
  end;

  if vis.x1 > x1 then
    vis.startfrac := vis.startfrac + vis.xiscale * (vis.x1 - x1);

  vis.patch := lump;

  if (viewplayer.powers[Ord(pw_invisibility)] > 4 * 32) or
     (viewplayer.powers[Ord(pw_invisibility)] and 8 <> 0) then
    vis.colormap := nil // shadow draw
  else if fixedcolormap <> nil then
    vis.colormap := fixedcolormap // fixed color
  else if psp.state.frame and FF_FULLBRIGHT <> 0 then
    vis.colormap := colormaps // full bright
  else
    vis.colormap := spritelights[MAXLIGHTSCALE - 1];  // local light

  R_DrawPVisSprite(vis);
end;

// R_DrawPlayerSprites
procedure R_DrawPlayerSprites;
var
  i: integer;
  lightnum: integer;
begin
  // get light level
  lightnum :=
    _SHR(Psubsector_t(viewplayer.mo.subsector).sector.lightlevel, LIGHTSEGSHIFT) +
      extralight;

  if lightnum < 0 then
    spritelights := @scalelight[0, 0]
  else if lightnum >= LIGHTLEVELS then
    spritelights := @scalelight[LIGHTLEVELS - 1, 0]
  else
    spritelights := @scalelight[lightnum, 0];

  // clip to screen bounds
  mfloorclip := @screenheightarray;
  mceilingclip := @negonearray;

  // add all active psprites
  for i := 0 to Ord(NUMPSPRITES) - 1 do
    if viewplayer.psprites[i].state <> nil then
      R_DrawPSprite(@viewplayer.psprites[i]);
end;

// R_SortVisSprites
var
  vsprsortedhead: vissprite_t;

procedure R_SortVisSprites;
var
  i: integer;
  count: integer;
  ds: Pvissprite_t;
  best: Pvissprite_t;
  unsorted: vissprite_t;
  bestscale: fixed_t;
begin
  count := vissprite_p;

  if count = 0 then
    Exit;

  unsorted.next := @unsorted;
  unsorted.prev := @unsorted;

  vissprites[0].next := @vissprites[1];
  vissprites[0].prev := @unsorted;

  for i := 1 to count - 1 do
  begin
    vissprites[i].next := @vissprites[i + 1];
    vissprites[i].prev := @vissprites[i - 1];
  end;

  unsorted.prev := @vissprites[vissprite_p - 1];
  unsorted.next := @vissprites[0];
  vissprites[vissprite_p - 1].next := @unsorted;

  // pull the vissprites out by scale
  vsprsortedhead.next := @vsprsortedhead;
  vsprsortedhead.prev := @vsprsortedhead;
  for i := 0 to count - 1 do
  begin
    bestscale := MAXINT;
    ds := unsorted.next;
    best := nil; // JVAL - > avoid compiler warning
    while ds <> @unsorted do
    begin
      if ds.scale < bestscale then
      begin
        bestscale := ds.scale;
        best := ds;
      end;
      ds := ds.next;
    end;

    if best <> nil then // JVAL - > avoid compiler warning
    begin
      best.next.prev := best.prev;
      best.prev.next := best.next;
      best.next := @vsprsortedhead;
      best.prev := vsprsortedhead.prev;
      vsprsortedhead.prev.next := best;
      vsprsortedhead.prev := best;
    end;
  end;
end;

// R_DrawSprite
var
  clipbot: packed array[0..SCREENWIDTH - 1] of smallint;
  cliptop: packed array[0..SCREENWIDTH - 1] of smallint;

procedure R_DrawSprite(spr: Pvissprite_t);
var
  ds: Pdrawseg_t;
  x: integer;
  r1: integer;
  r2: integer;
  scale: fixed_t;
  lowscale: fixed_t;
  silhouette: integer;
  i: integer;
begin
  for x := spr.x1 to spr.x2 do
  begin
    clipbot[x] := -2;
    cliptop[x] := -2;
  end;

  // Scan drawsegs from end to start for obscuring segs.
  // The first drawseg that has a greater scale
  //  is the clip seg.
  for i := ds_p - 1 downto 0 do
  begin
    ds := @drawsegs[i];
    // determine if the drawseg obscures the sprite
    if (ds.x1 > spr.x2) or
       (ds.x2 < spr.x1) or
       ((ds.silhouette = 0) and (ds.maskedtexturecol = nil)) then
      Continue; // does not cover sprite

    r1 := decide(ds.x1 < spr.x1, spr.x1, ds.x1);
    r2 := decide(ds.x2 > spr.x2, spr.x2, ds.x2);

    if ds.scale1 > ds.scale2 then
    begin
      lowscale := ds.scale2;
      scale := ds.scale1;
    end
    else
    begin
      lowscale := ds.scale1;
      scale := ds.scale2;
    end;

    if (scale < spr.scale) or
       ((lowscale < spr.scale) and not R_PointOnSegSide(spr.gx, spr.gy, ds.curline)) then
    begin
      // masked mid texture?
      if ds.maskedtexturecol <> nil then
        R_RenderMaskedSegRange(ds, r1, r2);
      // seg is behind sprite
      Continue;
    end;

    // clip this piece of the sprite
    silhouette := ds.silhouette;

    if spr.gz >= ds.bsilheight then
      silhouette := silhouette and not SIL_BOTTOM;

    if spr.gzt <= ds.tsilheight then
      silhouette := silhouette and not SIL_TOP;

    if silhouette = 1 then
    begin
      // bottom sil
      for x := r1 to r2 do
        if clipbot[x] = -2 then
          clipbot[x] := ds.sprbottomclip[x];
    end
    else if silhouette = 2 then
    begin
      // top sil
      for x := r1 to r2 do
        if cliptop[x] = -2 then
          cliptop[x] := ds.sprtopclip[x];
    end
    else if silhouette = 3 then
    begin
      // both
      for x := r1 to r2 do
      begin
        if clipbot[x] = -2 then
          clipbot[x] := ds.sprbottomclip[x];
        if cliptop[x] = -2 then
          cliptop[x] := ds.sprtopclip[x];
      end;
    end;
  end;

  // all clipping has been performed, so draw the sprite

  // check for unclipped columns
  for x := spr.x1 to spr.x2 do
  begin
    if clipbot[x] = -2 then
      clipbot[x] := viewheight;
    if cliptop[x] = -2 then
      cliptop[x] := -1;
  end;

  mfloorclip := @clipbot;
  mceilingclip := @cliptop;
  R_DrawVisSprite(spr, spr.x1, spr.x2);
end;

// R_DrawMasked
procedure R_DrawMasked;
var
  spr: Pvissprite_t;
  ds: Pdrawseg_t;
  i: integer;
begin
  R_SortVisSprites;

  if vissprite_p > 0 then
  begin
    // draw all vissprites back to front
    spr := vsprsortedhead.next;
    while spr <> @vsprsortedhead do
    begin
      R_DrawSprite(spr);
      spr := spr.next;
    end;
  end;

  // render any remaining masked mid textures
  for i := ds_p - 1 downto 0 do
  begin
    ds := @drawsegs[i];
    if ds.maskedtexturecol <> nil then
      R_RenderMaskedSegRange(ds, ds.x1, ds.x2);
  end;

  // draw the psprites on top of everything
  //  but does not draw on side views
  if viewangleoffset = 0 then
    R_DrawPlayerSprites;
end;

end.

