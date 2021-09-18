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

unit w_wad;

interface

uses
  d_delphi;

// TYPES
type
  char8_t = array[0..7] of char;

  wadinfo_t = packed record
    // Should be "IWAD" or "PWAD".
    identification: integer;
    numlumps: integer;
    infotableofs: integer;
  end;
  Pwadinfo_t = ^wadinfo_t;

  filelump_t = packed record
    filepos: integer;
    size: integer;
    name: char8_t;
  end;
  Pfilelump_t = ^filelump_t;
  Tfilelump_tArray = packed array[0..$FFFF] of filelump_t;
  Pfilelump_tArray = ^Tfilelump_tArray;

// WADFILE I/O related stuff.
  lumpinfo_t = record
    handle: TFile;
    position: integer;
    size: integer;
    case integer of
      0 : ( name: char8_t);
      1 : ( v1, v2: integer);
    end;

  Plumpinfo_t = ^lumpinfo_t;
  lumpinfo_tArray = array[0..$FFFF] of lumpinfo_t;
  Plumpinfo_tArray = ^lumpinfo_tArray;

function char8tostring(src: char8_t): string;

function stringtochar8(src: string): char8_t;

procedure W_InitMultipleFiles(filenames: PStringArray);

procedure W_Reload;

function W_CheckNumForName(const name: string): integer;

function W_GetNumForName(const name: string): integer;

function W_LumpLength(lump: integer): integer;
procedure W_ReadLump(lump: integer; dest: pointer);

function W_CacheLumpNum(lump: integer; tag: integer): pointer;
function W_CacheLumpName(const name: string; tag: integer): pointer;

var
  lumpinfo: Plumpinfo_tArray;

implementation

uses
  i_system,
  z_memory;

const
  IWAD = integer(Ord('I') or
                (Ord('W') shl 8) or
                (Ord('A') shl 16) or
                (Ord('D') shl 24));

  PWAD = integer(Ord('P') or
                (Ord('W') shl 8) or
                (Ord('A') shl 16) or
                (Ord('D') shl 24));

// GLOBALS

// Location of each lump on disk.
var
  numlumps: integer;
  lumpcache: PPointerArray;

function char8tostring(src: char8_t): string;
var
  i: integer;
begin
  Result := '';
  i := 0;
  while (i < 8) and (src[i] <> #0) do
  begin
    Result := Result + src[i];
    inc(i);
  end;
end;

function stringtochar8(src: string): char8_t;
var
  i: integer;
  len: integer;
begin
  len := length(src);
  if len > 8 then
    I_Error('stringtochar8(): length of %s is > 8', [src]);

  i := 1;
  while (i <= len) do
  begin
    Result[i - 1] := src[i];
    inc(i);
  end;

  for i := len to 7 do
    Result[i] := #0;
end;

function filelength(handle: TFile): integer;
begin
  try
    Result := handle.Size;
  except
    Result := 0;
    I_Error('filelength(): Error fstating');
  end;
end;

procedure ExtractFileBase(const path: string; var dest: string);
var
  i: integer;
  len: integer;
begin
  len := Length(path);
  i := len;
  while i > 0 do
  begin
    if path[i] in ['/', '\'] then
      break;
    dec(i);
  end;
  dest := '';
  while (i < len) do
  begin
    inc(i);
    if path[i] = '.' then
      break
    else
      dest := dest + toupper(path[i]);
  end;
  if Length(dest) > 8 then
    I_Error('ExtractFileBase(): Filename base of %s >8 chars', [path]);
end;

procedure ExtractFileBase8(const path: string; var dest: char8_t);
var
  dst: string;
begin
  dst := char8tostring(dest);
  ExtractFileBase(path, dst);
  dest := stringtochar8(dst);
end;

// LUMP BASED ROUTINES.

//
// W_AddFile
// All files are optional, but at least one file must be
//  found (PWAD, if all required lumps are present).
// Files with a .wad extension are wadlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//  for the lump name.
//
// If filename starts with a tilde, the file is handled
//  specially to allow map reloads.
// But: the reload feature is a fragile hack...
var
  reloadlump: integer;
  reloadname: string;

procedure W_AddFile(var filename: string);
var
  header: wadinfo_t;
  lump_p: Plumpinfo_t;
  i: integer;
  j: integer;
  handle: TFile;
  len: integer;
  startlump: integer;
  fileinfo: Pfilelump_tArray;
  singleinfo: filelump_t;
  storehandle: TFile;
  ext: string;
  c: char;
begin
  // open the file and add to directory
  // handle reload indicator.
  if filename[1] = '~' then
  begin
    reloadname := Copy(filename, 2, Length(filename) - 1);
    Delete(filename, 1, 1);
    reloadlump := numlumps;
  end
  else
    reloadname := '';

  if not fexists(filename) then
  begin
    printf('W_AddFile(): File %s does not exist' + #13#10, [filename]);
    Exit;
  end;

  try
    handle := TFile.Create(filename, fOpen);
  except
    printf('W_AddFile(): couldn''t open %s' + #13#10, [filename]);
    Exit;
  end;

  printf(' adding %s' + #13#10, [filename]);
  startlump := numlumps;

  ext := strupper(fext(filename));
  if ext <> '.WAD' then
  begin
    // single lump file
    fileinfo := @singleinfo;
    singleinfo.filepos := 0;
    singleinfo.size := filelength(handle);
    ExtractFileBase8(filename, singleinfo.name);
    inc(numlumps);
  end
  else
  begin
    // WAD file
    handle.Read(header, SizeOf(header));
    if header.identification <> IWAD then
      // Homebrew levels?
      if header.identification <> PWAD then
        I_Error('W_AddFile(): Wad file %s doesn''t have IWAD or PWAD id' + #13#10, [filename]);

    len := header.numlumps * SizeOf(filelump_t);
    GetMem(fileinfo, len);
    handle.Seek(header.infotableofs, sFromBeginning);
    handle.Read(fileinfo^, len);
    numlumps := numlumps + header.numlumps;
  end;

  // Fill in lumpinfo
  ReAllocMem(lumpinfo, numlumps * SizeOf(lumpinfo_t));

  if lumpinfo = nil then
    I_Error('W_AddFile(): Couldn''t realloc lumpinfo');

  if reloadname <> '' then
    storehandle := nil
  else
    storehandle := handle;

  for i := startlump to numlumps - 1 do
  begin
    lump_p := @lumpinfo[i];
    lump_p.handle := storehandle;
    lump_p.position := fileinfo[i - startlump].filepos;
    lump_p.size := fileinfo[i - startlump].size;
    c := #255;
    for j := 0 to 7 do
    begin
      // Prevent non null charactes after ending #0
      if c <> #0 then
        c := fileinfo[i - startlump].name[j];
      lump_p.name[j] := c;
    end;
  end;

  if reloadname <> '' then
    handle.Free;
end;

// W_Reload
// Flushes any of the reloadable lumps in memory
//  and reloads the directory.
procedure W_Reload;
var
  header: wadinfo_t;
  lumpcount: integer;
  lump_p: Plumpinfo_t;
  i: integer;
  handle: TFile;
  len: integer;
  fileinfo: Pfilelump_tArray;
begin
  if reloadname = '' then
    Exit;

  if not fexists(reloadname) then
    I_Error('W_Reload(): File %s does not exist' + #13#10, [reloadname]);

  try
    handle := TFile.Create(reloadname, fOpen);
  except
    handle := nil;
    I_Error('W_Reload(): couldn''t open %s', [reloadname]);
  end;

  handle.Read(header, SizeOf(header));
  lumpcount := header.numlumps;
  len := lumpcount * SizeOf(filelump_t);
  GetMem(fileinfo, len);
  handle.Seek(header.infotableofs, sFromBeginning);
  handle.Read(fileinfo^, len);

  // Fill in lumpinfo

  for i := reloadlump to reloadlump + lumpcount - 1 do
  begin
    lump_p := @lumpinfo[reloadlump];
    if lumpcache[i] <> nil then
      Z_Free(lumpcache[i]);

    lump_p.position := fileinfo[i - reloadlump].filepos;
    lump_p.size := fileinfo[i - reloadlump].size;
  end;

  handle.Free;
end;

// W_InitMultipleFiles
// Pass a null terminated list of files to use.
// All files are optional, but at least one file
//  must be found.
// Files with a .wad extension are idlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//  for the lump name.
// Lump names can appear multiple times.
// The name searcher looks backwards, so a later file
//  does override all earlier ones.
procedure W_InitMultipleFiles(filenames: PStringArray);
var
  size: integer;
  i: integer;
begin
  // open all the files, load headers, and count lumps
  numlumps := 0;

  // will be realloced as lumps are added
  GetMem(lumpinfo, 1);

  i := 0;
  while filenames[i] <> '' do
  begin
    W_AddFile(filenames[i]);
    inc(i);
  end;

  if numlumps = 0 then
    I_Error('W_InitMultipleFiles(): no files found');

  // set up caching
  size := numlumps * SizeOf(pointer);
  GetMem(lumpcache, size);

  if lumpcache = nil then
    I_Error('W_InitMultipleFiles(): Couldn''t allocate lumpcache');

  ZeroMemory(lumpcache, size);
end;

// W_InitFile
// Just initialize from a single file.
procedure W_InitFile(const filename: string);
var
  names: array[0..1] of string;
begin
  names[0] := filename;
  names[1] := '';
  W_InitMultipleFiles(@names);
end;

// W_NumLumps
function W_NumLumps: integer;
begin
  Result := numlumps;
end;

// W_CheckNumForName
// Returns -1 if name not found.
type
  name8_t = record
    case integer of
      0 : (s: char8_t);
      1 : (x: array[0..1] of integer);
    end;

function W_CheckNumForName(const name: string): integer;
var
  name8: name8_t;
  v1: integer;
  v2: integer;
  lump_p: Plumpinfo_t;
  len: integer;
  i: integer;
begin
  len := Length(name);
  if len > 8 then
    I_Error('W_CheckNumForName(): name string has more that 8 characters: %s', [name]);

  // make the name into two integers for easy compares
  for i := 1 to len do
    name8.s[i - 1] := toupper(name[i]); // case insensitive
  for i := len to 7 do
    name8.s[i] := #0;

  v1 := name8.x[0];
  v2 := name8.x[1];

  // scan backwards so patch lump files take precedence
  for i := numlumps - 1 downto 0 do
  begin
    lump_p := @lumpinfo[i];
    if (lump_p.v1 = v1) and (lump_p.v2 = v2) then
    begin
      Result := i;
      Exit;
    end;
  end;

  // TFB. Not found.
  Result := -1;
end;

// W_GetNumForName
// Calls W_CheckNumForName, but bombs out if not found.
function W_GetNumForName(const name: string): integer;
begin
  Result := W_CheckNumForName(name);
  if Result = -1 then
    I_Error('W_GetNumForName(): %s not found!', [name]);
end;

// W_LumpLength
// Returns the buffer size needed to load the given lump.
function W_LumpLength(lump: integer): integer;
begin
  if lump >= numlumps then
    I_Error('W_LumpLength(): %d >= numlumps', [lump]);

  Result := lumpinfo[lump].size;
end;

// W_ReadLump
// Loads the lump into the given buffer,
//  which must be >= W_LumpLength().
procedure W_ReadLump(lump: integer; dest: pointer);
var
  c: integer;
  l: Plumpinfo_t;
  handle: TFile;
begin
  if lump >= numlumps then
    I_Error('W_ReadLump(): %d >= numlumps', [lump]);

  l := @lumpinfo[lump];

  if l.handle = nil then
  begin
    // reloadable file, so use open / read / close
    if not fexists(reloadname) then
      I_Error('W_ReadLump(): couldn''t open %s', [reloadname]);

    try
      handle := TFile.Create(reloadname, fOpen);
    except
      handle := nil;
      I_Error('W_ReadLump(): couldn''t open %s', [reloadname]);
    end
  end
  else
    handle := l.handle;

  handle.Seek(l.position, sFromBeginning);
  c := handle.Read(dest^, l.size);

  if c < l.size then
    I_Error('W_ReadLump(): only read %d of %d on lump %d', [c, l.size, lump]);

  if l.handle = nil then
    handle.Free;
end;

// W_CacheLumpNum
function W_CacheLumpNum(lump: integer; tag: integer): pointer;
begin
  if lump >= numlumps then
    I_Error('W_CacheLumpNum(): lumn = %d, >= numlumps', [lump]);

  if lump < 0 then
    I_Error('W_CacheLumpNum(): lumn = %d, < 0', [lump]);

  if lumpcache[lump] = nil then
  begin
    // read the lump in
    Z_Malloc(W_LumpLength(lump), tag, @lumpcache[lump]);
    W_ReadLump(lump, lumpcache[lump]);
  end
  else
    Z_ChangeTag(lumpcache[lump], tag);

  Result := lumpcache[lump];
end;

// W_CacheLumpName
function W_CacheLumpName(const name: string; tag: integer): pointer;
begin
  Result := W_CacheLumpNum(W_GetNumForName(name), tag);
end;

end.
