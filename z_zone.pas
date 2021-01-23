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

unit z_zone;

interface

uses
  d_delphi;

//
// ZONE MEMORY
// PU - purge tags.
// Tags < 100 are not overwritten until freed.

const
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

function Z_Malloc(size: integer; tag: integer; user: pointer): pointer;

procedure Z_Free(ptr: pointer);

procedure Z_FreeTags(lowtag: integer; hightag: integer);

procedure Z_DumpHeap(lowtag: integer; hightag: integer);

procedure Z_FileDumpHeap(var f: file); overload;

procedure Z_FileDumpHeap(const filename: string); overload;

procedure Z_CheckHeap;

procedure Z_ChangeTag(ptr: pointer; tag: integer);

procedure Z_ChangeTag2(ptr: pointer; tag: integer);

function Z_FreeMemory: integer;

  { including the header and possibly tiny fragments }
  { NULL if a free block }
  { purgelevel }
  { should be ZONEID }

type
  Pmemblock_t = ^memblock_t;

  memblock_t = record
    size: integer;  // including the header and possibly tiny fragments
    user: PPointer; // NULL if a free block
    tag: integer;   // purgelevel
    id: integer;    // should be ZONEID
    next: Pmemblock_t;
    prev: Pmemblock_t;
  end;

implementation

uses
  i_system;

//
// ZONE MEMORY ALLOCATION
//
// There is never any space between memblocks,
//  and there will never be two contiguous free memblocks.
// The rover can be left pointing at a non-empty block.
//
// It is of no value to free a cachable block,
//  because it will get overwritten automatically if needed.
//

const
  ZONEID = $1d4a11;

type
  memzone_t = record
    // total bytes malloced, including header
    size: integer;
    // start / end cap for linked list
    blocklist: memblock_t;
    rover: Pmemblock_t;
  end;
  Pmemzone_t = ^memzone_t;

var
  mainzone: Pmemzone_t;

//
// Z_ClearZone
//
procedure Z_ClearZone(zone: Pmemzone_t);
var
  block: Pmemblock_t;
begin
  // set the entire zone to one free block
  block := Pmemblock_t(integer(zone) + SizeOf(memzone_t));
  zone.blocklist.next := block;
  zone.blocklist.prev := block;

  zone.blocklist.user := PPointer(zone);
  zone.blocklist.tag := PU_STATIC;
  zone.rover := block;

  block.prev := @zone.blocklist;
  block.next := block.prev;

  // NULL indicates a free block.
  block.user := nil;

  block.size := zone.size - SizeOf(memzone_t);
end;

//
// Z_Init
//
procedure Z_Init;
var
  block: Pmemblock_t;
  size: integer;
begin
  mainzone := Pmemzone_t(I_ZoneBase(size));
  mainzone.size := size;

  // set the entire zone to one free block
  block := Pmemblock_t(integer(mainzone) + SizeOf(memzone_t));
  mainzone.blocklist.next := block;
  mainzone.blocklist.prev := block;

  mainzone.blocklist.user := PPointer(mainzone);
  mainzone.blocklist.tag := PU_STATIC;
  mainzone.rover := block;

  block.prev := @mainzone.blocklist;
  block.next := block.prev;

  // NULL indicates a free block.
  block.user := nil;

  block.size := mainzone.size - SizeOf(memzone_t);
end;

//
// Z_Free
//
procedure Z_Free(ptr: pointer);
var
  block: Pmemblock_t;
  other: Pmemblock_t;
begin
  block := Pmemblock_t(integer(ptr) - SizeOf(memblock_t));

  if block.id <> ZONEID then
    I_Error('Z_Free(): freed a pointer without ZONEID');

  if integer(block.user) > $100 then
  begin
    // smaller values are not pointers
    // Note: OS-dependend?

    // clear the user's mark
    block.user^ := nil;
  end;

  // mark as free
  block.user := nil;
  block.tag := 0;
  block.id := 0;

  other := block.prev;

  if not boolval(other.user) then
  begin
    // merge with previous free block
    other.size := other.size + block.size;
    other.next := block.next;
    other.next.prev := other;

    if block = mainzone.rover then
      mainzone.rover := other;

    block := other;
  end;

  other := block.next;
  if not boolval(other.user) then
  begin
    // merge the next free block onto the end
    block.size := block.size + other.size;
    block.next := other.next;
    block.next.prev := block;

    if other = mainzone.rover then
      mainzone.rover := block;
  end;
end;

//
// Z_Malloc
// You can pass a NULL user if the tag is < PU_PURGELEVEL.
//
const
  MINFRAGMENT = 64;

function Z_Malloc(size: integer; tag: integer; user: pointer): pointer;
var
  extra: integer;
  start: Pmemblock_t;
  rover: Pmemblock_t;
  newblock: Pmemblock_t;
  base: Pmemblock_t;
begin
  size := (size + 3) and (not 3);

  // scan through the block list,
  // looking for the first free block
  // of sufficient size,
  // throwing out any purgable blocks along the way.

  // account for size of block header
  size := size + SizeOf(memblock_t);

  // if there is a free block behind the rover,
  //  back up over them
  base := mainzone.rover;

  if not boolval(base.prev.user) then
    base := base.prev;

  rover := base;
  start := base.prev;

  repeat
    if rover = start then
    begin
      // scanned all the way around the list
      I_Error('Z_Malloc(): failed on allocation of %d bytes', [size]);
    end;

    if boolval(rover.user) then
    begin
      if rover.tag < PU_PURGELEVEL then
      begin
        // hit a block that can't be purged,
        //  so move base past it
        rover := rover.next;
        base := rover;
      end
      else
      begin
        // free the rover block (adding the size to base)
        // the rover can be the base block
        base := base.prev;
        Z_Free(pointer(integer(rover) + SizeOf(memblock_t)));
        base := base.next;
        rover := base.next;
      end;
    end
    else
      rover := rover.next;
  until not (boolval(base.user) or (base.size < size));


  // found a block big enough
  extra := base.size - size;

  if extra > MINFRAGMENT then
  begin
    // there will be a free fragment after the allocated block
    newblock := Pmemblock_t(integer(base) + size);
    newblock.size := extra;

    // NULL indicates free block.
    newblock.user := nil;
    newblock.tag := 0;
    newblock.prev := base;
    newblock.next := base.next;
    newblock.next.prev := newblock;

    base.next := newblock;
    base.size := size;
  end;

  if boolval(user) then
  begin
    // mark as an in use block
    base.user := user;
    PPointer(user)^ := Pointer(integer(base) + SizeOf(memblock_t));
//  *(void **)user = (void *) ((byte *)base + sizeof(memblock_t));
  end
  else
  begin
    if tag >= PU_PURGELEVEL then
      I_Error('Z_Malloc(): an owner is required for purgable blocks');

    // mark as in use, but unowned
    base.user := Pointer(2);
  end;

  base.tag := tag;

  // next allocation will start looking here
  mainzone.rover := base.next;

  base.id := ZONEID;

  result := Pointer(integer(base) + SizeOf(memblock_t));
end;

//
// Z_FreeTags
//
procedure Z_FreeTags(lowtag: integer; hightag: integer);
var
  block: Pmemblock_t;
  next: Pmemblock_t;
begin
  block := mainzone.blocklist.next;
  while block <> @mainzone.blocklist do
  begin
    // get link before freeing
    next := block.next;

    // not free block?
    if boolval(block.user) then
      if (block.tag >= lowtag) and (block.tag <= hightag) then
        Z_Free(Pointer(integer(block) + SizeOf(memblock_t)));
    block := next;
  end;
end;

//
// Z_DumpHeap
// Note: TFileDumpHeap( stdout ) ?
//
procedure Z_DumpHeap(lowtag: integer; hightag: integer);
var
  block: Pmemblock_t;
begin
  printf('zone size: %d  location: %s' + #13#10,
    [mainzone.size, IntToStrZfill(8, integer(mainzone))]);

  printf('tag range: %s to %s' + #13#10,
    [IntToStrZfill(3, lowtag), IntToStrZfill(3, hightag)]);

  block := mainzone.blocklist.next;
  while true do
  begin
    if (block.tag >= lowtag) and (block.tag <= hightag) then
      printf('block:%s    size:%s    user:%s    tag:%s' + #13#10,
        [IntToStrZfill(8, integer(block)), IntToStrZfill(7, block.size),
         IntToStrZfill(8, integer(block.user)), IntToStrZfill(3, block.tag)]);
    if block.next = @mainzone.blocklist then
    begin
      // all blocks have been hit
      break;
    end;

    if integer(block) + block.size <> integer(block.next) then
      printf('ERROR: block size does not touch the next block' + #13#10);

    if block.next.prev <> block then
      printf('ERROR: next block doesn''t have proper back link' + #13#10);

    if (not boolval(block.user)) and (not boolval(block.next.user)) then
      printf('ERROR: two consecutive free blocks' + #13#10);

    block := block.next;
  end;
end;

procedure Z_FileDumpHeap(var f: file);
var
  block: Pmemblock_t;
begin
  fprintf(f, 'zone size: %d  location: %s' + #13#10,
    [mainzone.size, IntToStrZfill(8, integer(mainzone))]);

  block := mainzone.blocklist.next;
  while true do
  begin
    fprintf(f, 'block:%s    size:%s    user:%s    tag:%s' + #13#10,
      [IntToStrZfill(8, integer(block)), IntToStrZfill(7, block.size),
       IntToStrZfill(8, integer(block.user)), IntToStrZfill(3, block.tag)]);
    if block.next = @mainzone.blocklist then
    begin
      // all blocks have been hit
      break;
    end;

    if integer(block) + block.size <> integer(block.next) then
      fprintf(f, 'ERROR: block size does not touch the next block' + #13#10);

    if block.next.prev <> block then
      fprintf(f, 'ERROR: next block doesn''t have proper back link' + #13#10);

    if (not boolval(block.user)) and (not boolval(block.next.user)) then
      fprintf(f, 'ERROR: two consecutive free blocks' + #13#10);

    block := block.next;
  end;
end;

procedure Z_FileDumpHeap(const filename: string);
var f: file;
begin
  assign(f, filename);
  {$I-}
  rewrite(f, 1);
  {$I+}
  if IOResult = 0 then
  begin
    Z_FileDumpHeap(f);
    close(f);
  end
  else
    I_Error('Z_FileDumpHeap(): Can not create output file: %s', [filename]);
end;

//
// Z_CheckHeap
//
procedure Z_CheckHeap;
var
  block: Pmemblock_t;
begin
  block := mainzone.blocklist.next;
  while true do
  begin
    if block.next = @mainzone.blocklist then
    begin
      // all blocks have been hit
      break;
    end;

    if integer(block) + block.size <> integer(block.next) then
      I_Error('Z_CheckHeap(): block size does not touch the next block');

    if block.next.prev <> block then
      I_Error('Z_CheckHeap(): next block doesn''t have proper back link');

    if (not boolval(block.user)) and (not boolval(block.next.user)) then
      I_Error('Z_CheckHeap(): two consecutive free blocks');

    block := block.next
  end;
end;

//
// Z_ChangeTag
//
procedure Z_ChangeTag(ptr: pointer; tag: integer);
begin
  Z_ChangeTag2(ptr, tag);
end;

procedure Z_ChangeTag2(ptr: pointer; tag: integer);
var
  block: Pmemblock_t;
begin
  block := Pmemblock_t(integer(ptr) - SizeOf(memblock_t));

  if block.id <> ZONEID then
    I_Error('Z_ChangeTag(): freed a pointer without ZONEID');

  if (tag >= PU_PURGELEVEL) and (LongWord(block.user) < $100) then
    I_Error('Z_ChangeTag(): an owner is required for purgable blocks');

  block.tag := tag;
end;

//
// Z_FreeMemory
//
function Z_FreeMemory: integer;
var
  block: Pmemblock_t;
begin
  result := 0;

  block := mainzone.blocklist.next;
  while block <> @mainzone.blocklist do
  begin
    if (not boolval(block.user)) or (block.tag >= PU_PURGELEVEL) then
      result := result + block.size;
    block := block.next;
  end;
end;

end.

