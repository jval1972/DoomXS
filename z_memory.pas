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

unit z_memory;

interface

//
// PU - purge tags.
// Tags < 100 are not overwritten until freed.

const
  PU_LOTAG = 1;
  PU_STATIC = 1;    // static entire execution time
  PU_SOUND = 2;     // static while playing
  PU_MUSIC = 3;     // static while playing
  PU_DAVE = 4;      // anything else Dave wants static
  PU_LEVEL = 50;    // static until level exited
  PU_LEVSPEC = 51;  // a special thinker in a level
  // Tags >= 100 are purgable whenever needed.
  PU_PURGELEVEL = 100;
  PU_CACHE = 101;

procedure Z_Init;
procedure Z_ShutDown;

function Z_Malloc(size: integer; tag: integer; user: pointer): pointer;
function Z_Realloc(ptr: pointer; size: integer; tag: integer; user: pointer): pointer;

procedure Z_Free(ptr: pointer);

procedure Z_FreeTags(lowtag: integer; hightag: integer);

procedure Z_ChangeTag(ptr: pointer; tag: integer);

implementation

uses
  d_delphi;

type
  memmanageritem_t = record
    size: integer;
    user: PPointer;
    tag: integer;
    index: integer;
  end;
  Pmemmanageritem_t = ^memmanageritem_t;

  memmanageritems_t = array[0..$FFF] of Pmemmanageritem_t;
  Pmemmanageritems_t = ^memmanageritems_t;

type
  TMemManager = class
  private
    fitems: Pmemmanageritems_t;
    fnumitems: integer;
    realsize: integer;
    function item2ptr(const id: integer): Pointer;
    function ptr2item(const ptr: Pointer): integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure M_Free(ptr: Pointer);
    procedure M_FreeTags(lowtag, hightag: integer);
    procedure M_ChangeTag(ptr: Pointer; tag: integer);
    function M_Malloc(size: integer; tag: integer; user: Pointer): pointer;
    function M_Realloc(ptr: Pointer; size: integer; tag: integer; user: Pointer): pointer;
    property items: Pmemmanageritems_t read fitems write fitems;
    property numitems: integer read fnumitems write fnumitems;
  end;

constructor TMemManager.Create;
begin
  fitems := nil;
  fnumitems := 0;
  realsize := 0;
end;

destructor TMemManager.Destroy;
var
  i: integer;
begin
  for i := fnumitems - 1 downto 0 do
    FreeMem(fitems[i], fitems[i].size + SizeOf(memmanageritem_t));
  FreeMem(fitems, realsize * SizeOf(Pmemmanageritem_t));
  inherited;
end;

function TMemManager.item2ptr(const id: integer): Pointer;
begin
  Result := fitems[id];
  incp(Result, SizeOf(memmanageritem_t));
end;

function TMemManager.ptr2item(const ptr: Pointer): integer;
var
  p: pointer;
begin
  p := ptr;
  Result := Pmemmanageritem_t(incp(p, -SizeOf(memmanageritem_t))).index;
end;

procedure TMemManager.M_Free(ptr: Pointer);
var
  i: integer;
begin
  i := ptr2item(ptr);
  if fitems[i].user <> nil then
    fitems[i].user^ := nil;
  if fitems[i] <> nil then
  begin
    FreeMem(fitems[i], fitems[i].size + SizeOf(memmanageritem_t));
    fitems[i] := nil;
  end;
  if i < fnumitems - 1 then
  begin
    fitems[i] := fitems[fnumitems - 1];
    fitems[fnumitems - 1] := nil;
    fitems[i].index := i;
  end
  else
    fitems[i] := nil;
  dec(fnumitems);
end;

procedure TMemManager.M_FreeTags(lowtag, hightag: integer);
var
  i: integer;
begin
  for i := fnumitems - 1 downto 0 do
    if (fitems[i].tag >= lowtag) and (fitems[i].tag <= hightag) then
      M_Free(item2ptr(i));
end;

procedure TMemManager.M_ChangeTag(ptr: Pointer; tag: integer);
begin
  fitems[ptr2item(ptr)].tag := tag;
end;

function TMemManager.M_Malloc(size: integer; tag: integer; user: Pointer): pointer;
var
  i: integer;
begin
  if realsize <= fnumitems then
  begin
    realsize := (realsize * 4 div 3 + 64) and not 7;
    ReAllocMem(fitems, realsize * SizeOf(Pmemmanageritem_t));
    for i := fnumitems + 1 to realsize - 1 do
      fitems[i] := nil;
  end;

  fitems[fnumitems] := malloc(size + SizeOf(memmanageritem_t));
  fitems[fnumitems].size := size;
  fitems[fnumitems].tag := tag;
  fitems[fnumitems].index := fnumitems;
  fitems[fnumitems].user := user;
  Result := item2ptr(fnumitems);
  inc(fnumitems);
  if user <> nil then
    PPointer(user)^ := Result;
end;

function TMemManager.M_Realloc(ptr: Pointer; size: integer; tag: integer; user: Pointer): pointer;
var
  tmp: pointer;
  copysize: integer;
  i: integer;
begin
  if size = 0 then
  begin
    M_Free(ptr);
    Result := nil;
    Exit;
  end;

  if ptr = nil then
  begin
    Result := M_Malloc(size, tag, user);
    Exit;
  end;

  i := ptr2item(ptr);
  if fitems[i].size = size then
  begin
    Result := ptr;
    Exit;
  end;

  if size > fitems[i].size then
    copysize := fitems[i].size
  else
    copysize := size;

  tmp := malloc(copysize);
  memcpy(tmp, ptr, copysize);
  M_Free(ptr);
  Result := M_Malloc(size, tag, user);
  memcpy(Result, tmp, copysize);
  FreeMem(tmp, copysize);
end;

var
  memmanager: TMemManager;

// Z_Init
procedure Z_Init;
begin
  memmanager := TMemManager.Create;
end;

procedure Z_ShutDown;
begin
  memmanager.Free;
end;

// Z_Free
procedure Z_Free(ptr: pointer);
begin
  memmanager.M_Free(ptr);
end;

// Z_Malloc
// You can pass a NULL user if the tag is < PU_PURGELEVEL.
function Z_Malloc(size: integer; tag: integer; user: pointer): pointer;
begin
  Result := memmanager.M_Malloc(size, tag, user);
end;

function Z_Realloc(ptr: pointer; size: integer; tag: integer; user: pointer): pointer;
begin
  Result := memmanager.M_Realloc(ptr, size, tag, user);
end;

// Z_FreeTags
procedure Z_FreeTags(lowtag: integer; hightag: integer);
begin
  memmanager.M_FreeTags(lowtag, hightag);
end;

// Z_ChangeTag
procedure Z_ChangeTag(ptr: pointer; tag: integer);
begin
  memmanager.M_ChangeTag(ptr, tag);
end;

end.
