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

unit d_delphi;
// Delphi specific routines

interface

type
  PPointer = ^Pointer;
  
  PString = ^string;

  PBoolean = ^Boolean;

  PInteger = ^Integer;
  
  PLongWord = ^LongWord;
  
  TWordArray = packed array[0..$FFFF] of word;
  PWordArray = ^TWordArray;

  TIntegerArray = packed array[0..$FFFF] of integer;
  PIntegerArray = ^TIntegerArray;

  TLongWordArray = packed array[0..$FFFF] of LongWord;
  PLongWordArray = ^TLongWordArray;

  TSmallintArray = packed array[0..$FFFF] of Smallint;
  PSmallintArray = ^TSmallintArray;

  TByteArray = packed array[0..$FFFF] of Byte;
  PByteArray = ^TByteArray;

  TBooleanArray = packed array[0..$FFFF] of boolean;
  PBooleanArray = ^TBooleanArray;

  PProcedure = procedure;

  TStringArray = array[0..$FFFF] of string;
  PStringArray = ^TStringArray;

  TPointerArray = packed array[0..$FFFF] of pointer;
  PPointerArray = ^TPointerArray;

  PSmallInt = ^SmallInt;
  TSmallIntPArray = packed array[0..$FFFF] of PSmallIntArray;
  PSmallIntPArray = ^TSmallIntPArray;

  PWord = ^Word;
  TWordPArray = packed array[0..$FFFF] of PWordArray;
  PWordPArray = ^TWordPArray;

  PByte = ^Byte;
  TBytePArray = packed array[0..$FFFF] of PByteArray;
  PBytePArray = ^TBytePArray;

  TOutProc = procedure (const s: string);

var
  outproc: TOutProc = nil;

procedure sprintf(var s: string; const Fmt: string; const Args: array of const);

procedure printf(const str: string); overload;

procedure printf(const Fmt: string; const Args: array of const); overload;

function itoa(i: integer): string;

function atoi(const s: string): integer;

function atof(const s: string): single;

function memcpy(dst: pointer; const src: pointer; len: integer): pointer; overload;

function memcpy(dst: pointer; const src: string; len: integer): pointer; overload;

function memmove(dst: pointer; const src: pointer; len: integer): pointer;

function memset(buf: pointer; c: integer; len: integer): pointer;

function malloc(size: integer): Pointer;

function IntToStrZfill(const z: integer; const x: integer): string;

function boolval(const x: integer): boolean; overload;

function boolval(const c: char): boolean; overload;

function boolval(const p: pointer): boolean; overload;

function intval(const b: boolean): integer;

function decide(const contition: boolean;
  const iftrue: integer; const iffalse: integer): integer; overload;

function decide(const contition: boolean;
  const iftrue: boolean; const iffalse: boolean): boolean; overload;

function decide(const contition: boolean;
  const iftrue: string; const iffalse: string): string; overload;

function decide(const contition: boolean;
  const iftrue: pointer; const iffalse: pointer): pointer; overload;

function decide(const contition: integer;
  const iftrue: integer; const iffalse: integer): integer; overload;

function decide(const contition: integer;
  const iftrue: boolean; const iffalse: boolean): boolean; overload;

function decide(const contition: integer;
  const iftrue: string; const iffalse: string): string; overload;

function decide(const contition: integer;
  const iftrue: pointer; const iffalse: pointer): pointer; overload;

function incp(var p: pointer; const size: integer = 1): pointer;

function pOperation(const p1, p2: pointer; const op: char; size: integer): integer;

function getenv(const env: string): string;

function fexists(const filename: string): boolean;

procedure fdelete(const filename: string);

function fext(const filename: string): string;

const
  fOpen = 0;
  fCreate = 1;

  sFromBeginning = 0;
  sFromCurrent = 1;
  sFromEnd = 2;

type
  TFile = class
  public
    f: file;
    constructor Create(const FileName: string; mode: word);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; virtual;
    function Write(const Buffer; Count: Longint): Longint; virtual;
    function Seek(Offset: Longint; Origin: Word): Longint; virtual;
    function Size: Longint;
  end;

  TCachedFile = class(TFile)
  private
    fBufSize: integer;
    fBuffer: pointer;
    fPosition: integer;
    fBufferStart: integer;
    fBufferEnd: integer;
    fSize: integer;
    fInitialized: boolean;
  protected
    procedure SetSize(NewSize: Longint); //override;
    procedure ResetBuffer; virtual;
  public
    constructor Create(const FileName: string; mode: word; ABufSize: integer = $FFFF); virtual;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
  end;

procedure fprintf(var f: file; const str: string); overload;

procedure fprintf(var f: file; const Fmt: string; const Args: array of const); overload;

procedure fprintf(var f: TFile; const str: string); overload;

procedure fprintf(var f: TFile; const Fmt: string; const Args: array of const); overload;

function tan(const x: single): single;

function strupper(const S: string): string;

function toupper(ch: Char): Char;

function tolower(ch: Char): Char;

function _SHL(const x: integer; const bits: integer): integer;

function _SHLW(const x: LongWord; const bits: LongWord): LongWord;

function _SHR(const x: integer; const bits: integer): integer;

function _SHRW(const x: LongWord; const bits: LongWord): LongWord;

function StringVal(const Str: PChar): string;

procedure ZeroMemory(var X; Count: Integer);

implementation

uses Windows, SysUtils;

procedure sprintf(var s: string; const Fmt: string; const Args: array of const);
begin
  s := Format(Fmt, Args);
end;

procedure printf(const str: string);
begin
  if Assigned(outproc) then
    outproc(str)
  else if IsConsole then
    write(str);
end;

procedure printf(const Fmt: string; const Args: array of const);
var s: string;
begin
  sprintf(s, Fmt, Args);
  printf(s);
end;

procedure fprintf(var f: file; const str: string);
begin
  BlockWrite(f, (@str[1])^, Length(str));
end;

procedure fprintf(var f: file; const Fmt: string; const Args: array of const);
var s: string;
begin
  sprintf(s, Fmt, Args);
  fprintf(f, s);
end;

procedure fprintf(var f: TFile; const str: string);
begin
  fprintf(f.f, str);
end;

procedure fprintf(var f: TFile; const Fmt: string; const Args: array of const);
begin
  fprintf(f.f, Fmt, Args);
end;

function itoa(i: integer): string;
begin
  result := IntToStr(i);
end;

function atoi(const s: string): integer;
begin
  result := StrToIntDef(s, 0);
end;

function StrToFloatDef(const s: string; def: single): single;
var
  code: integer;
begin
  val(s, result, code);
  if code <> 0 then
    result := def;
end;

function atof(const s: string): single;
var
  s2: string;
  i: Integer;
begin
  s2 := s;
  for i := 1 to length(s2) do
  begin
    if s2[i] in ['.', ','] then
      s2[i] := SysUtils.DecimalSeparator;
  end;
  result := StrToFloatDef(s2, 0.0);
end;

function memcpy(dst: pointer; const src: pointer; len: integer): pointer;
begin
  move(src^, dst^, len);
  result := dst;
end;

function memcpy(dst: pointer; const src: string; len: integer): pointer;
var i: integer;
begin
  if len >= Length(src) then
  begin
    for i := 1 to Length(src) do
      PByteArray(dst)[i] := ord(src[i]);
    for i := Length(src) + 1 to len do
      PByteArray(dst)[i] := 0;
  end
  else
    for i := 1 to len do
      PByteArray(dst)[i] := ord(src[i]);
  result := dst;
end;

function memmove(dst: pointer; const src: pointer; len: integer): pointer;
begin
  move(src^, dst^, len);
  result := dst;
end;

function memset(buf: pointer; c: integer; len: integer): pointer;
begin
  FillChar(buf^, len, c);
  Result := buf;
end;

function malloc(size: integer): Pointer;
begin
  GetMem(Result, size);
  ZeroMemory(Result^, size);
end;

function IntToStrZfill(const z: integer; const x: integer): string;
var
  i: integer;
  len: integer;
begin
  result := IntToStr(x);
  len := Length(result);
  for i := len + 1 to z do
    result := '0' + result;
end;

function boolval(const x: integer): boolean;
begin
  result := x <> 0;
end;

function boolval(const c: char): boolean;
begin
  result := c <> #0;
end;

function boolval(const p: pointer): boolean;
begin
  result := p <> nil;
end;

function intval(const b: boolean): integer;
begin
  if b then
    result := 1
  else
    result := 0;
end;

function decide(const contition: boolean;
  const iftrue: integer; const iffalse: integer): integer;
begin
  if contition then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: boolean;
  const iftrue: boolean; const iffalse: boolean): boolean;
begin
  if contition then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: boolean;
  const iftrue: string; const iffalse: string): string;
begin
  if contition then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: boolean;
  const iftrue: pointer; const iffalse: pointer): pointer;
begin
  if contition then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: integer;
  const iftrue: integer; const iffalse: integer): integer;
begin
  if contition <> 0 then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: integer;
  const iftrue: boolean; const iffalse: boolean): boolean;
begin
  if contition <> 0 then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: integer;
  const iftrue: string; const iffalse: string): string;
begin
  if contition <> 0 then
    result := iftrue
  else
    result := iffalse;
end;

function decide(const contition: integer;
  const iftrue: pointer; const iffalse: pointer): pointer;
begin
  if contition <> 0 then
    result := iftrue
  else
    result := iffalse;
end;

function incp(var p: pointer; const size: integer = 1): pointer;
begin
  result := Pointer(integer(p) + size);
  p := result;
end;

function pOperation(const p1, p2: pointer; const op: char; size: integer): integer;
begin
  case op of
    '+': result := (Integer(p1) + Integer(p2)) div size;
    '-': result := (Integer(p1) - Integer(p2)) div size;
  else
    result := 0;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
constructor TFile.Create(const FileName: string; mode: word);
begin
  assign(f, FileName);
  {$I-}
  if mode = fCreate then
    rewrite(f, 1)
  else
    reset(f, 1);
  {$I+}
end;

destructor TFile.Destroy;
begin
  close(f);
  Inherited;
end;

function TFile.Read(var Buffer; Count: Longint): Longint;
begin
  BlockRead(f, Buffer, Count, result);
end;

function TFile.Write(const Buffer; Count: Longint): Longint;
begin
  BlockWrite(f, Buffer, Count, result);
end;

function TFile.Seek(Offset: Longint; Origin: Word): Longint;
begin
  case Origin of
    sFromBeginning:
      result := Offset;
    sFromCurrent:
      result := FilePos(f) + Offset;
    sFromEnd:
      result := FileSize(f) - Offset;
  else
    result := 0;
  end;
  system.Seek(f, result);
end;

function TFile.Size: Longint;
begin
  result := FileSize(f);
end;

constructor TCachedFile.Create(const FileName: string; mode: word; ABufSize: integer = $FFFF);
begin
  fInitialized := false;
  Inherited Create(FileName, mode);
  fBufSize := ABufSize;
  GetMem(fBuffer, fBufSize);
  fPosition := 0;
  ResetBuffer;
  fSize := Inherited Size;
  fInitialized := true;
end;

procedure TCachedFile.ResetBuffer;
begin
  fBufferStart := -1;
  fBufferEnd := -1;
end;

destructor TCachedFile.Destroy;
begin
  FreeMem(fBuffer, fBufSize);
  Inherited;
end;

function TCachedFile.Read(var Buffer; Count: Longint): Longint;
var x: Longint;
begin
// Buffer hit
  if (fPosition >= fBufferStart) and (fPosition + Count <= fBufferEnd) then
  begin
    x := LongInt(fBuffer) + fPosition - fBufferStart;
    Move(Pointer(x)^, Buffer, Count);
    fPosition := fPosition + Count;
    result := Count;
  end
// Non Buffer hit, cache buffer
  else if Count <= fBufSize then
  begin
    fPosition := Inherited Seek(fPosition, sFromBeginning);
    x := Inherited Read(fBuffer^, fBufSize);
    if x < Count then
      result := x
    else
      result := Count;
    Move(fBuffer^, Buffer, Count);
    fBufferStart := fPosition;
    fBufferEnd := fPosition + x;
    fPosition := fPosition + result;
  end
// Keep old buffer
  else
  begin
    fPosition := Inherited Seek(fPosition, sFromBeginning);
    result := Inherited Read(Buffer, Count);
    fPosition := fPosition + result;
  end;
end;

function TCachedFile.Write(const Buffer; Count: Longint): Longint;
begin
  fPosition := Inherited Seek(fPosition, sFromBeginning);
  result := Inherited Write(Buffer, Count);
  fPosition := fPosition + result;
  if fSize < fPosition then
    fSize := fPosition;
end;

function TCachedFile.Seek(Offset: Longint; Origin: Word): Longint;
begin
  if fInitialized then
  begin
    case Origin of
      sFromBeginning: fPosition := Offset;
      sFromCurrent: Inc(fPosition, Offset);
      sFromEnd: fPosition := fSize + Offset;
    end;
    result := fPosition;
  end
  else
    result := Inherited Seek(Offset, Origin);
end;

procedure TCachedFile.SetSize(NewSize: Longint);
begin
  Inherited;
  fSize := NewSize;
end;

function getenv(const env: string): string;
var
  buf: array[0..255] of char;
begin
  ZeroMemory(buf, SizeOf(buf));
  GetEnvironmentVariable(PChar(env), buf, 255);
  result := Trim(StringVal(buf));
end;

function fexists(const filename: string): boolean;
begin
  result := FileExists(filename);
end;

procedure fdelete(const filename: string);
begin
  if fexists(filename) then
    DeleteFile(filename);
end;

function fext(const filename: string): string;
begin
  result := ExtractFileExt(filename);
end;

function tan(const x: single): single;
var
  a: single;
  b: single;
begin
  b := cos(x);
  if b <> 0 then
  begin
    a := sin(x);
    result := a / b;
  end
  else
    result := 0.0;
end;


function strupper(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;


function toupper(ch: Char): Char;
asm
{ ->    AL      Character       }
{ <-    AL      Result          }

        CMP     AL,'a'
        JB      @@exit
        CMP     AL,'z'
        JA      @@exit
        SUB     AL,'a' - 'A'
@@exit:
end;

function tolower(ch: Char): Char;
asm
{ ->    AL      Character       }
{ <-    AL      Result          }

        CMP     AL,'A'
        JB      @@exit
        CMP     AL,'Z'
        JA      @@exit
        SUB     AL,'A' - 'a'
@@exit:
end;

function _SHL(const x: integer; const bits: integer): integer;
begin
  result := x * (1 shl bits);
end;

function _SHLW(const x: LongWord; const bits: LongWord): LongWord;
begin
//  result := x * (1 shl bits);
  result := x shl bits;
end;

function _SHR(const x: integer; const bits: integer): integer;
begin
  result := x div (1 shl bits);
end;

function _SHRW(const x: LongWord; const bits: LongWord): LongWord;
begin
//  result := x div (1 shl bits);
  result := x shr bits;
end;

function StringVal(const Str: PChar): string;
begin
  Result := Str;
end;

procedure ZeroMemory(var X; Count: Integer);
begin
  FillChar(X, Count, Chr(0));
end;

end.
