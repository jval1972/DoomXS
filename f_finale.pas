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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/doomxs/
//------------------------------------------------------------------------------

unit f_finale;

interface

uses
  d_event;

function F_Responder(ev: Pevent_t): boolean;

// Called by main loop.
procedure F_Ticker;

// Called by main loop.
procedure F_Drawer;

procedure F_StartFinale;

implementation

uses
  d_delphi,
  am_map,
  d_player,
  d_main,
  g_game,
  info_h,
  info,
  p_pspr,
  r_data,
  r_defs,
  r_things,
// Functions.
  z_memory,
  v_video,
  w_wad,
  s_sound,
  d_englsh,
  sounds,
  doomdef,
  doomstat,
  hu_stuff;

var
// Stage of animation:
//  0 = text, 1 = art screen, 2 = character cast
  finalestage: integer;

  finalecount: integer;

const
  TEXTSPEED = 3;
  TEXTWAIT = 250;

var
  finaletext: string;
  finaleflat: string;

procedure F_StartCast; forward;

procedure F_CastTicker; forward;

function F_CastResponder(ev: Pevent_t): boolean; forward;

procedure F_CastDrawer; forward;

procedure F_StartFinale;
begin
  gameaction := ga_nothing;
  gamestate := GS_FINALE;
  viewactive := False;
  automapactive := False;

  // Okay - IWAD dependend stuff.
  // This has been changed severly, and
  //  some stuff might have changed in the process.
  case gamemode of
    // DOOM 1 - E1, E3 or E4, but each nine missions
    shareware,
    registered,
    retail:
      begin
        S_ChangeMusic(Ord(mus_victor), True);
        case gameepisode of
          1:
            begin
              finaleflat := 'FLOOR4_8';
              finaletext := E1TEXT;
            end;
          2:
            begin
              finaleflat := 'SFLR6_1';
              finaletext := E2TEXT;
            end;
          3:
            begin
              finaleflat := 'MFLR8_4';
              finaletext := E3TEXT;
            end;
          4:
            begin
              finaleflat := 'MFLR8_3';
              finaletext := E4TEXT;
            end;
        else
          // Ouch.
        end;
      end;
    // DOOM II and missions packs with E1, M34
    commercial:
      begin
        S_ChangeMusic(Ord(mus_read_m), True);
        case gamemap of
          6:
            begin
              finaleflat := 'SLIME16';
              case gamemission of
                pack_tnt: finaletext := T1TEXT;
                pack_plut: finaletext := P1TEXT;
              else
                finaletext := C1TEXT;
              end;
            end;
         11:
            begin
              finaleflat := 'RROCK14';
              case gamemission of
                pack_tnt: finaletext := T2TEXT;
                pack_plut: finaletext := P2TEXT;
              else
                finaletext := C2TEXT;
              end;
            end;
         20:
            begin
              finaleflat := 'RROCK07';
              case gamemission of
                pack_tnt: finaletext := T3TEXT;
                pack_plut: finaletext := P3TEXT;
              else
                finaletext := C3TEXT;
              end;
            end;
         30:
            begin
              finaleflat := 'RROCK17';
              case gamemission of
                pack_tnt: finaletext := T4TEXT;
                pack_plut: finaletext := P4TEXT;
              else
                finaletext := C4TEXT;
              end;
            end;
         15:
            begin
              finaleflat := 'RROCK13';
              case gamemission of
                pack_tnt: finaletext := T5TEXT;
                pack_plut: finaletext := P5TEXT;
              else
                finaletext := C5TEXT;
              end;
            end;
         31:
            begin
              finaleflat := 'RROCK19';
              case gamemission of
                pack_tnt: finaletext := T6TEXT;
                pack_plut: finaletext := P6TEXT;
              else
                finaletext := C6TEXT;
              end;
            end;
        else
        // Ouch.
        end;
      end;
  else
    begin
      S_ChangeMusic(Ord(mus_read_m), True);
      finaleflat := 'F_SKY1'; // Not used anywhere else.
      finaletext := C1TEXT;   // FIXME - other text, music?
    end;
  end;
  finalestage := 0;
  finalecount := 0;
end;

function F_Responder(ev: Pevent_t): boolean;
begin
  Result := False;
  if finalestage = 2 then
    Result := F_CastResponder(ev);
end;

// F_Ticker
procedure F_Ticker;
var
  i: integer;
begin
  // check for skipping
  if (gamemode = commercial) and (finalecount > 50) then
  begin
    // go on to the next level
    i := 0;
    while i < MAXPLAYERS do
    begin
      if players[i].cmd.buttons <> 0 then
        Break;
      inc(i);
    end;
    if i < MAXPLAYERS then
    begin
      if gamemap = 30 then
        F_StartCast
      else
        gameaction := ga_worlddone;
    end;
  end;

  // advance animation
  inc(finalecount);

  if finalestage = 2 then
  begin
    F_CastTicker;
    Exit;
  end;

  if gamemode = commercial then
    Exit;

  if (finalestage = 0) and (finalecount > Length(finaletext) * TEXTSPEED + TEXTWAIT) then
  begin
    finalecount := 0;
    finalestage := 1;
    wipegamestate := -1;    // force a wipe
    if gameepisode = 3 then
      S_StartMusic(Ord(mus_bunny));
  end;
end;

procedure F_TextWrite;
var
  src: PByteArray;
  dest: integer;
  x, y, w: integer;
  count: integer;
  ch: string;
  c: char;
  c1: integer;
  i: integer;
  len: integer;
  cx: integer;
  cy: integer;
begin
  // erase the entire screen to a tiled background
  src := W_CacheLumpName(finaleflat, PU_CACHE);
  dest := 0;

  for y := 0 to 200 - 1 do
    for x := 0 to (320 div 64) - 1 do
    begin
      memcpy(@screens[SCN_SCRF, dest], @src[_SHL(y and 63, 6)], 64);
      dest := dest + 64;
    end;

  // draw some of the text onto the screen
  cx := 10;
  cy := 10;
  ch := finaletext;
  len := Length(ch);

  count := (finalecount - 10) div TEXTSPEED;
  if count < 0 then
    count := 0;

  i := 1;
  while count > 0 do
  begin

    if i > len then
      Break;

    c := ch[i];
    inc(i);
    if c = #13 then
    begin
      cy := cy + 11;
      Continue;
    end;
    if c = #10 then
    begin
      cx := 10;
      Continue;
    end;

    c1 := Ord(toupper(c)) - Ord(HU_FONTSTART);
    if (c1 < 0) or (c1 > HU_FONTSIZE) then
    begin
      cx := cx + 4;
      Continue;
    end;

    w := hu_font[c1].width;
    if cx + w > 320 then
      Break;
    V_DrawPatch(cx, cy, SCN_SCRF, hu_font[c1], False);
    cx := cx + w;
    dec(count);
  end;
  V_CopyRect(0, 0, SCN_SCRF, 320, 200, 0, 0, SCN_FG, True);
end;

// Final DOOM 2 animation
// Casting by id Software.
//   in order of appearance
type
  castinfo_t = record
    name: string;
    casttype: mobjtype_t;
  end;
  Pcastinfo_t = ^castinfo_t;

const
  NUM_CASTS = 18;

var
  castorder: array[0..NUM_CASTS - 1] of castinfo_t;

  castnum: integer;
  casttics: integer;
  caststate: Pstate_t;
  castdeath: boolean;
  castframes: integer;
  castonmelee: integer;
  castattacking: boolean;

// F_StartCast
procedure F_StartCast;
begin
  if finalestage = 2 then
    Exit;
  wipegamestate := -1;    // force a screen wipe
  castnum := 0;
  caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].seestate];
  casttics := caststate.tics;
  castdeath := False;
  finalestage := 2;
  castframes := 0;
  castonmelee := 0;
  castattacking := False;
  S_ChangeMusic(Ord(mus_evil), True);
end;

// F_CastTicker
procedure F_CastTicker;
var
  st: integer;
  sfx: integer;
begin
  dec(casttics);
  if casttics > 0 then
    Exit; // not time to change state yet

  if (caststate.tics = -1) or (caststate.nextstate = S_NULL) then
  begin
    // switch from deathstate to next monster
    inc(castnum);
    castdeath := False;
    if castorder[castnum].name = '' then
      castnum := 0;
    if mobjinfo[Ord(castorder[castnum].casttype)].seesound <> 0 then
      S_StartSound(nil, mobjinfo[Ord(castorder[castnum].casttype)].seesound);
    caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].seestate];
    castframes := 0;
  end
  else
  begin
  // just advance to next state in animation
    if caststate = @states[Ord(S_PLAY_ATK1)] then
    begin
      castattacking := False;
      castframes := 0;
      caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].seestate];
      casttics := caststate.tics;
      if casttics = -1 then
        casttics := 15;
      Exit;
    end;
    st := Ord(caststate.nextstate);
    caststate := @states[st];
    inc(castframes);

    // sound hacks....
    case statenum_t(st) of
      S_PLAY_ATK1: sfx := Ord(sfx_dshtgn);
      S_POSS_ATK2: sfx := Ord(sfx_pistol);
      S_SPOS_ATK2: sfx := Ord(sfx_shotgn);
      S_VILE_ATK2: sfx := Ord(sfx_vilatk);
      S_SKEL_FIST2: sfx := Ord(sfx_skeswg);
      S_SKEL_FIST4: sfx := Ord(sfx_skepch);
      S_SKEL_MISS2: sfx := Ord(sfx_skeatk);
      S_FATT_ATK8,
      S_FATT_ATK5,
      S_FATT_ATK2: sfx := Ord(sfx_firsht);
      S_CPOS_ATK2,
      S_CPOS_ATK3,
      S_CPOS_ATK4: sfx := Ord(sfx_shotgn);
      S_TROO_ATK3: sfx := Ord(sfx_claw);
      S_SARG_ATK2: sfx := Ord(sfx_sgtatk);
      S_BOSS_ATK2,
      S_BOS2_ATK2,
      S_HEAD_ATK2: sfx := Ord(sfx_firsht);
      S_SKULL_ATK2: sfx := Ord(sfx_sklatk);
      S_SPID_ATK2,
      S_SPID_ATK3: sfx := Ord(sfx_shotgn);
      S_BSPI_ATK2: sfx := Ord(sfx_plasma);
      S_CYBER_ATK2,
      S_CYBER_ATK4,
      S_CYBER_ATK6: sfx := Ord(sfx_rlaunc);
      S_PAIN_ATK3: sfx := Ord(sfx_sklatk);
    else
      sfx := 0;
    end;
    if sfx <> 0 then
      S_StartSound(nil, sfx);
  end;

  if castframes = 12 then
  begin
    // go into attack frame
    castattacking := True;
    if castonmelee <> 0 then
      caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].meleestate]
    else
      caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].missilestate];
    castonmelee := castonmelee xor 1;
    if caststate = @states[Ord(S_NULL)] then
    begin
      if castonmelee <> 0 then
        caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].meleestate]
      else
        caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].missilestate];
    end;
  end;

  if castattacking then
  begin
    if (castframes = 24) or
       (caststate = @states[mobjinfo[Ord(castorder[castnum].casttype)].seestate]) then
    begin
      castattacking := False;
      castframes := 0;
      caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].seestate];
    end;
  end;

  casttics := caststate.tics;
  if casttics = -1 then
    casttics := 15;
end;

// F_CastResponder
function F_CastResponder(ev: Pevent_t): boolean;
begin
  if ev.typ <> ev_keydown then
  begin
    Result := False;
    Exit;
  end;

  if castdeath then
  begin
    Result := True; // already in dying frames
    Exit;
  end;

  // go into death frame
  castdeath := True;
  caststate := @states[mobjinfo[Ord(castorder[castnum].casttype)].deathstate];
  casttics := caststate.tics;
  castframes := 0;
  castattacking := False;
  if mobjinfo[Ord(castorder[castnum].casttype)].deathsound <> 0 then
    S_StartSound(nil, mobjinfo[Ord(castorder[castnum].casttype)].deathsound);

  Result := True;
end;

procedure F_CastPrint(text: string);
var
  ch: string;
  i: integer;
  c: char;
  c1: integer;
  len: integer;
  cx: integer;
  w: integer;
  width: integer;
begin
  // find width
  ch := text;
  width := 0;

  len := Length(ch);
  for i := 1 to len do
  begin
    c := ch[i];
    if c = #0 then
      Break;
    c1 := Ord(toupper(c)) - Ord(HU_FONTSTART);
    if (c1 < 0) or (c1 > HU_FONTSIZE) then
      width := width + 4
    else
    begin
      w := hu_font[c1].width;
      width := width + w;
    end;
  end;

  // draw it
  cx := (320 - width) div 2;
  for i := 1 to len do
  begin
    c := ch[i];
    if c = #0 then
      Break;
    c1 := Ord(toupper(c)) - Ord(HU_FONTSTART);
    if (c1 < 0) or (c1 > HU_FONTSIZE) then
      cx := cx + 4
    else
    begin
      w := hu_font[c1].width;
      V_DrawPatch(cx, 180, SCN_SCRF, hu_font[c1], False);
      cx := cx + w;
    end;
  end;
end;

// F_CastDrawer
procedure F_CastDrawer;
var
  sprdef: Pspritedef_t;
  sprframe: Pspriteframe_t;
  lump: integer;
  flip: boolean;
  patch: Ppatch_t;
begin
  // erase the entire screen to a background
  V_DrawPatch(0, 0, SCN_SCRF, W_CacheLumpName('BOSSBACK', PU_CACHE), False);

  F_CastPrint(castorder[castnum].name);

  // draw the current frame in the middle of the screen
  sprdef := @sprites[Ord(caststate.sprite)];
  sprframe := @sprdef.spriteframes[caststate.frame and FF_FRAMEMASK];
  lump := sprframe.lump[0];
  flip := sprframe.flip[0];

  patch := W_CacheLumpNum(lump + firstspritelump, PU_CACHE);
  if flip then
    V_DrawPatchFlipped(160, 170, SCN_SCRF, patch, False)
  else
    V_DrawPatch(160, 170, SCN_SCRF, patch, False);
  V_CopyRect(0, 0, SCN_SCRF, 320, 200, 0, 0, SCN_FG, True);
end;

// F_DrawPatchCol
procedure F_DrawPatchCol(scr: integer; x: integer; patch: Ppatch_t; col: integer);
var
  column: Pcolumn_t;
  source: PByte;
  dest: PByte;
  desttop: PByte;
  count: integer;
begin
  column := Pcolumn_t(integer(patch) + patch.columnofs[col]);
  desttop := PByte(integer(screens[scr]) + x);

  // step through the posts in a column
  while column.topdelta <> $ff do
  begin
    source := PByte(integer(column) + 3);
    dest := PByte(integer(desttop) + column.topdelta * 320);
    count := column.len;

    while count > 0 do
    begin
      dest^ := source^;
      inc(source);
      inc(dest, 320);
      dec(count);
    end;
    column := Pcolumn_t(integer(column) + column.len + 4);
  end;
end;

// F_BunnyScroll
var
  laststage: integer = 0;

procedure F_BunnyScroll;
var
  scrolled: integer;
  x: integer;
  p1: Ppatch_t;
  p2: Ppatch_t;
  name: string;
  stage: integer;
begin
  p1 := W_CacheLumpName('PFUB2', PU_LEVEL);
  p2 := W_CacheLumpName('PFUB1', PU_LEVEL);

  scrolled := 320 - (finalecount - 230) div 2;
  if scrolled > 320 then
    scrolled := 320
  else if scrolled < 0 then
    scrolled := 0;

  for x := 0 to 320 - 1 do
  begin
    if x + scrolled < 320 then
      F_DrawPatchCol(SCN_SCRF, x, p1, x + scrolled)
    else
      F_DrawPatchCol(SCN_SCRF, x, p2, x + scrolled - 320);
  end;

  if finalecount >= 1130 then
  begin
    if finalecount < 1180 then
    begin
      V_DrawPatch((320 - 13 * 8) div 2,
                  (200 - 8 * 8) div 2,
                   SCN_SCRF, W_CacheLumpName('END0', PU_CACHE), False);
      laststage := 0;
    end
    else
    begin
      stage := (finalecount - 1180) div 5;
      if stage > 6 then
        stage := 6;
      if stage > laststage then
      begin
        S_StartSound(nil, Ord(sfx_pistol));
        laststage := stage;
      end;

      sprintf(name,'END%d', [stage]);
      V_DrawPatch((320 - 13 * 8) div 2,
                  (200 - 8 * 8) div 2,
                   SCN_SCRF, W_CacheLumpName(name, PU_CACHE), False);
    end;
  end;

  V_CopyRect(0, 0, SCN_SCRF, 320, 200, 0, 0, SCN_FG, True);
end;

// F_Drawer
procedure F_Drawer;
begin
  if finalestage = 2 then
  begin
    F_CastDrawer;
    Exit;
  end;

  if finalestage = 0 then
    F_TextWrite
  else
  begin
    case gameepisode of
      1:
        begin
          if gamemode = retail then
            V_DrawPatch(0, 0, 0,
              W_CacheLumpName('CREDIT', PU_CACHE), True)
          else
            V_DrawPatch(0, 0, 0,
              W_CacheLumpName('HELP2', PU_CACHE), True);
        end;
      2:
        begin
          V_DrawPatch(0, 0, 0,
            W_CacheLumpName('VICTORY2', PU_CACHE), True);
        end;
      3:
        begin
          F_BunnyScroll;
        end;
      4:
        begin
          V_DrawPatch(0, 0, 0,
            W_CacheLumpName('ENDPIC', PU_CACHE), True);
        end;
    end;
  end;
end;

initialization
  castorder[0].name := CC_ZOMBIE;
  castorder[0].casttype := MT_POSSESSED;

  castorder[1].name := CC_SHOTGUN;
  castorder[1].casttype := MT_SHOTGUY;

  castorder[2].name := CC_HEAVY;
  castorder[2].casttype := MT_CHAINGUY;

  castorder[3].name := CC_IMP;
  castorder[3].casttype := MT_TROOP;

  castorder[4].name := CC_DEMON;
  castorder[4].casttype := MT_SERGEANT;

  castorder[5].name := CC_LOST;
  castorder[5].casttype := MT_SKULL;

  castorder[6].name := CC_CACO;
  castorder[6].casttype := MT_HEAD;

  castorder[7].name := CC_HELL;
  castorder[7].casttype := MT_KNIGHT;

  castorder[8].name := CC_BARON;
  castorder[8].casttype := MT_BRUISER;

  castorder[9].name := CC_ARACH;
  castorder[9].casttype := MT_BABY;

  castorder[10].name := CC_PAIN;
  castorder[10].casttype := MT_PAIN;

  castorder[11].name := CC_REVEN;
  castorder[11].casttype := MT_UNDEAD;

  castorder[12].name := CC_MANCU;
  castorder[12].casttype := MT_FATSO;

  castorder[13].name := CC_ARCH;
  castorder[13].casttype := MT_VILE;

  castorder[14].name := CC_SPIDER;
  castorder[14].casttype := MT_SPIDER;

  castorder[15].name := CC_CYBER;
  castorder[15].casttype := MT_CYBORG;

  castorder[16].name := CC_HERO;
  castorder[16].casttype := MT_PLAYER;

  castorder[17].name := '';
  castorder[17].casttype := mobjtype_t(0);

end.


