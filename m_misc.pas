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

unit m_misc;

interface

function M_WriteFile(const name: string; source: pointer; length: integer): boolean;

function M_ReadFile(const name: string; var buffer: Pointer): integer;

procedure M_ScreenShot;

procedure M_LoadDefaults;

procedure M_SaveDefaults;

implementation

uses
  d_delphi,
  doomdef,
  d_englsh,
  d_main,
  d_player,
  g_game,
  hu_stuff,
  m_menu,
  m_argv,
  i_system,
  i_video,
  s_sound,
  v_video,
  w_wad,
  z_memory,
  doomstat;

function M_WriteFile(const name: string; source: pointer; length: integer): boolean;
var
  handle: file;
  count: integer;
begin
  assign(handle, name);
  {$I-}
  rewrite(handle, 1);
  {$I+}
  if IOResult <> 0 then
  begin
    result := false;
    exit;
  end;

  BlockWrite(handle, source^, length, count);
  close(handle);

  result := count > 0;
end;

function M_ReadFile(const name: string; var buffer: Pointer): integer;
var
  handle: file;
  count: integer;
begin
  assign(handle, name);
  {$I-}
  reset(handle, 1);
  {$I+}
  if IOResult <> 0 then
    I_Error('M_ReadFile(): Could not read file %s', [name]);

  result := FileSize(handle);
  buffer := Z_Malloc(result, PU_STATIC, nil);
  BlockRead(handle, buffer^, result, count);
  close(handle);

  if count < result then
    I_Error('M_ReadFile(): Could not read file %s', [name]);
end;

type
  ttype_t = (tString, tInteger);

  default_t = record
    name: string;
    location: pointer;
    defaultsvalue: string;
    defaultivalue: integer;
    _type: ttype_t;
  end;

const
  NUMDEFAULTS = 37;

  defaults: array[0..NUMDEFAULTS - 1] of default_t = (
    (name: 'mouse_sensitivity';
     location: @mouseSensitivity;
     defaultivalue: 5;
     _type: tInteger),

    (name: 'sfx_volume';
     location: @snd_SfxVolume;
     defaultivalue: 8;
     _type: tInteger),
    (name: 'music_volume';
     location: @snd_MusicVolume;
     defaultivalue: 8;
     _type: tInteger),

    (name: 'show_messages';
     location: @showMessages;
     defaultivalue: 1;
     _type: tInteger),

    (name: 'key_right';
     location: @key_right;
     defaultivalue: KEY_RIGHTARROW;
     _type: tInteger),
    (name: 'key_left';
     location: @key_left;
     defaultivalue: KEY_LEFTARROW;
     _type: tInteger),
    (name: 'key_up';
     location: @key_up;
     defaultivalue: KEY_UPARROW;
     _type: tInteger),
    (name: 'key_down';
     location: @key_down;
     defaultivalue: KEY_DOWNARROW;
     _type: tInteger),
    (name: 'key_strafeleft';
     location: @key_strafeleft;
     defaultivalue: Ord(',');
     _type: tInteger),
    (name: 'key_straferight';
     location: @key_straferight;
     defaultivalue: Ord('.');
     _type: tInteger),
    (name: 'key_fire';
     location: @key_fire;
     defaultivalue: KEY_RCTRL;
     _type: tInteger),
    (name: 'key_use';
     location: @key_use;
     defaultivalue: Ord(' ');
     _type: tInteger),
    (name: 'key_strafe';
     location: @key_strafe;
     defaultivalue: KEY_RALT;
     _type: tInteger),
    (name: 'key_speed';
     location: @key_speed;
     defaultivalue: KEY_RSHIFT;
     _type: tInteger),

    (name: 'use_mouse';
     location: @usemouse;
     defaultivalue: 1;
     _type: tInteger),
    (name: 'mouseb_fire';
     location: @mousebfire;
     defaultivalue: 0;
     _type: tInteger),
    (name: 'mouseb_strafe';
     location: @mousebstrafe;
     defaultivalue: 1;
     _type: tInteger),
    (name: 'mouseb_forward';
     location: @mousebforward;
     defaultivalue: 2;
     _type: tInteger),

    (name: 'use_joystick';
     location: @usejoystick;
     defaultivalue: 0;
     _type: tInteger),
    (name: 'joyb_fire';
     location: @joybfire;
     defaultivalue: 0;
     _type: tInteger),
    (name: 'joyb_strafe';
     location: @joybstrafe;
     defaultivalue: 1;
     _type: tInteger),
    (name: 'joyb_use';
     location: @joybuse;
     defaultivalue: 3;
     _type: tInteger),
    (name: 'joyb_speed';
     location: @joybspeed;
     defaultivalue: 2;
     _type: tInteger),

    (name: 'screenblocks';
     location: @screenblocks;
     defaultivalue: 9;
     _type: tInteger),
    (name: 'detaillevel';
     location: @detailLevel;
     defaultivalue: 0;
     _type: tInteger),

    (name: 'snd_channels';
     location: @numChannels;
     defaultivalue: 8;
     _type: tInteger),

    (name: 'usegamma';
     location: @usegamma;
     defaultivalue: 0;
     _type: tInteger),

    (name: 'chatmacro0';
     location: @chat_macros[0];
     defaultsvalue: HUSTR_CHATMACRO0;
     _type: tString),
    (name: 'chatmacro1';
     location: @chat_macros[1];
     defaultsvalue: HUSTR_CHATMACRO1;
     _type: tString),
    (name: 'chatmacro2';
     location: @chat_macros[2];
     defaultsvalue: HUSTR_CHATMACRO2;
     _type: tString),
    (name: 'chatmacro3';
     location: @chat_macros[3];
     defaultsvalue: HUSTR_CHATMACRO3;
     _type: tString),
    (name: 'chatmacro4';
     location: @chat_macros[4];
     defaultsvalue: HUSTR_CHATMACRO4;
     _type: tString),
    (name: 'chatmacro5';
     location: @chat_macros[5];
     defaultsvalue: HUSTR_CHATMACRO5;
     _type: tString),
    (name: 'chatmacro6';
     location: @chat_macros[6];
     defaultsvalue: HUSTR_CHATMACRO6;
     _type: tString),
    (name: 'chatmacro7';
     location: @chat_macros[7];
     defaultsvalue: HUSTR_CHATMACRO7;
     _type: tString),
    (name: 'chatmacro8';
     location: @chat_macros[8];
     defaultsvalue: HUSTR_CHATMACRO8;
     _type: tString),
    (name: 'chatmacro9';
     location: @chat_macros[9];
     defaultsvalue: HUSTR_CHATMACRO9;
     _type: tString)
  );

var
  defaultfile: string;

procedure M_SaveDefaults;
var
  i: integer;
  s: TStrList;
begin
  s := TStrList.Create;
  try
    for i := 0 to NUMDEFAULTS - 1 do
      if defaults[i]._type = tInteger then
        s.Add(defaults[i].name + '=' + itoa(PInteger(defaults[i].location)^))
      else if defaults[i]._type = tString then
        s.Add(defaults[i].name + '=' + PString(defaults[i].location)^);

    s.SaveToFile(defaultfile);

  finally
    s.Free;
  end;
end;

procedure M_LoadDefaults;
var
  i: integer;
  j: integer;
  idx: integer;
  s: TStrList;
  n, v: string;
begin
  // set everything to base values
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tInteger then
      PInteger(defaults[i].location)^ := defaults[i].defaultivalue
    else if defaults[i]._type = tString then
      PString(defaults[i].location)^ := defaults[i].defaultsvalue;

  // check for a custom default file
  i := M_CheckParm ('-config');
  if (i > 0) and (i < myargc - 1) then
  begin
    defaultfile := myargv[i + 1];
    printf(' default file: %s' + #13#10, [defaultfile]);
  end
  else
    defaultfile := basedefault;

  s := TStrList.Create;
  try
    // read the file in, overriding any set defaults
    if fexists(defaultfile) then
      s.LoadFromFile(defaultfile);

    for i := 0 to s.Count - 1 do
    begin
      idx := -1;
      n := s.Names(i);
      for j := 0 to NUMDEFAULTS - 1 do
        if defaults[j].name = n then
        begin
          idx := j;
          break;
        end;

      if idx > -1 then
      begin
        v := s.Values(i);
        if defaults[idx]._type = tInteger then
        begin
          if v <> '' then
            PInteger(defaults[idx].location)^ := atoi(v)
        end
        else if defaults[idx]._type = tString then
          PString(defaults[idx].location)^ := v;
      end;
    end;

  finally
    s.Free;
  end;
end;

type
  pcx_t = record
    manufacturer: byte;
    version: byte;
    encoding: byte;
    bits_per_pixel: byte;

    xmin: word;
    ymin: word;
    xmax: word;
    ymax: word;

    hres: word;
    vres: word;

    palette: array[0..47] of byte;

    reserved: byte;
    color_planes: byte;
    bytes_per_line: word;
    palette_type: word;

    filler: array[0..57] of byte;
  end;
  Ppcx_t = ^pcx_t;

//
// WritePCXfile
//
procedure WritePCXfile(const filename: string; data: PByteArray;
  width, height: integer; palette: PByteArray);
var
  i: integer;
  pcx: Ppcx_t;
  pack: PByteArray;
  i_d,
  i_p: integer;
begin
  pcx := Z_Malloc(width * height * 2 + 1000, PU_STATIC, nil);

  pcx.manufacturer := $0a;  // PCX id
  pcx.version := 5;         // 256 color
  pcx.encoding := 1;        // uncompressed
  pcx.bits_per_pixel := 8;  // 256 color
  pcx.xmin := 0;
  pcx.ymin := 0;
  pcx.xmax := WORD(width - 1);
  pcx.ymax := WORD(height - 1);
  pcx.hres := 1;
  pcx.vres := 1;
  memset(@pcx.palette, 0, SizeOf(pcx.palette));
  pcx.color_planes := 1;    // chunky image
  pcx.bytes_per_line := WORD(width);
  pcx.palette_type := 2;    // not a grey scale
  memset(@pcx.filler, 0, SizeOf(pcx.filler));


  // pack the image
  pack := PByteArray(pcx);

  i_d := 0;
  i_p := SizeOf(pcx_t);
  for i := 0 to width * height - 1 do
  begin
    if data[i_d] and $c0 <> $c0 then
    begin
      pack[i_p] := data[i_d];
      inc(i_p);
      inc(i_d);
    end
    else
    begin
      pack[i_p] := $c1;
      inc(i_p);
      pack[i_p] := data[i_d];
      inc(i_p);
      inc(i_d);
    end;
  end;

  // write the palette
  pack[i_p] := $0c; // palette ID byte
  inc(i_p);
  i_d := 0;
  for i := 1 to 768 do
  begin
    pack[i_p] := palette[i_d];
    inc(i_p);
    inc(i_d);
  end;

  // write output file
  M_WriteFile(filename, pcx, i_p);

  Z_Free(pcx);
end;

//
// M_ScreenShot
//
procedure M_ScreenShot;
var
  i: integer;
  linear: PByteArray;
  lbmname: string;
begin
  // munge planar buffer to linear
  linear := screens[2];
  I_ReadScreen(linear);

  // find a file name to save it to
  lbmname := 'DOOM00.pcx';

  i := 0;
  while i < 100 do
  begin
    lbmname[5] := Chr((i div 10) + Ord('0'));
    lbmname[6] := Chr((i mod 10) + Ord('0'));
    if not fexists(lbmname) then
      break;  // file doesn't exist
    inc(i);
  end;

  if i = 100 then
    I_Error('M_ScreenShot(): Couldn''t create a PCX');

  // save the pcx file
  WritePCXfile(lbmname, linear, SCREENWIDTH, SCREENHEIGHT,
    W_CacheLumpName('PLAYPAL', PU_CACHE));

  players[consoleplayer].msg := 'screen shot';
end;

end.
