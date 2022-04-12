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
unit d_delphi;

interface

const
  MAXSHORT = smallint($7fff);
  MINSHORT = smallint($8000);
  MAXINT = longint($7fffffff);
  MININT = longint($80000000);

type
  PPointer = ^Pointer;

  PString = ^string;

  PBoolean = ^boolean;

  PInteger = ^integer;

  PLongWord = ^LongWord;

  TWordArray = packed array[0..$FFFF] of word;
  PWordArray = ^TWordArray;

  TIntegerArray = packed array[0..$FFFF] of integer;
  PIntegerArray = ^TIntegerArray;

  TLongWordArray = packed array[0..$FFFF] of LongWord;
  PLongWordArray = ^TLongWordArray;

  TSmallintArray = packed array[0..$FFFF] of smallint;
  PSmallintArray = ^TSmallintArray;

  TByteArray = packed array[0..$FFFF] of byte;
  PByteArray = ^TByteArray;

  TBooleanArray = packed array[0..$FFFF] of boolean;
  PBooleanArray = ^TBooleanArray;

  PProcedure = procedure;

  TStringArray = array[0..$FFFF] of string;
  PStringArray = ^TStringArray;

  TPointerArray = packed array[0..$FFFF] of pointer;
  PPointerArray = ^TPointerArray;

  PSmallInt = ^smallint;
  TSmallIntPArray = packed array[0..$FFFF] of PSmallIntArray;
  PSmallIntPArray = ^TSmallIntPArray;

  PWord = ^word;
  TWordPArray = packed array[0..$FFFF] of PWordArray;
  PWordPArray = ^TWordPArray;

  PByte = ^byte;
  TBytePArray = packed array[0..$FFFF] of PByteArray;
  PBytePArray = ^TBytePArray;

  TOutProc = procedure(const s: string);

var
  outproc: TOutProc = nil;

procedure sprintf(var s: string; const Fmt: string; const Args: array of const);

procedure printf(const str: string); overload;

procedure printf(const Fmt: string; const Args: array of const); overload;

function itoa(i: integer): string;

function atoi(const s: string): integer;

function memcpy(dst: pointer; const src: pointer; len: integer): pointer;

function malloc(size: integer): Pointer;

function IntToStrZfill(const z: integer; const x: integer): string;

function intval(const b: boolean): integer;

function decide(const contition: boolean; const iftrue: integer;
  const iffalse: integer): integer;

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
    function Read(var Buffer; Count: longint): longint; virtual;
    function Write(const Buffer; Count: longint): longint; virtual;
    function Seek(Offset: longint; Origin: word): longint; virtual;
    function Size: longint;
  end;

type
  strlistitem_t = string[255];
  strlist_t = array[0..$FFF] of strlistitem_t;
  Pstrlist_t = ^strlist_t;

  TStrList = class
  private
    flist: Pstrlist_t;
    fcount: integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const s: string);
    procedure AppendText(const s: string);
    procedure LoadFromFile(const fname: string);
    procedure SaveToFile(const fname: string);
    function Strings(const i: integer): string;
    function Names(const i: integer): string;
    function Values(const i: integer): string;
    property Count: integer read fcount;
  end;

procedure fprintf(var f: file; const str: string); overload;

procedure fprintf(var f: file; const Fmt: string; const Args: array of const); overload;

procedure fprintf(var f: TFile; const str: string); overload;

procedure fprintf(var f: TFile; const Fmt: string; const Args: array of const); overload;

function ftan(const X: Extended): Extended;

function strupper(const S: string): string;

function toupper(ch: char): char;

function tolower(ch: char): char;

function _SHL(const x: integer; const bits: integer): integer;

function _SHLW(const x: LongWord; const bits: LongWord): LongWord;

function _SHR(const x: integer; const bits: integer): integer;

function StringVal(const Str: PChar): string;

procedure ZeroMemory(const P: Pointer; Count: integer);

implementation

uses
  Windows,
  SysUtils;

procedure sprintf(var s: string; const Fmt: string; const Args: array of const);
begin
  s := Format(Fmt, Args);
end;

procedure printf(const str: string);
begin
  if Assigned(outproc) then
    outproc(str)
  else if IsConsole then
    Write(str);
end;

procedure printf(const Fmt: string; const Args: array of const);
var
  s: string;
begin
  sprintf(s, Fmt, Args);
  printf(s);
end;

procedure fprintf(var f: file; const str: string);
begin
  BlockWrite(f, (@str[1])^, Length(str));
end;

procedure fprintf(var f: file; const Fmt: string; const Args: array of const);
var
  s: string;
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
  Result := IntToStr(i);
end;

function atoi(const s: string): integer;
begin
  Result := StrToIntDef(s, 0);
end;

function memcpy(dst: pointer; const src: pointer; len: integer): pointer;
begin
  move(src^, dst^, len);
  Result := dst;
end;

function malloc(size: integer): Pointer;
begin
  GetMem(Result, size);
  ZeroMemory(Result, size);
end;

function IntToStrZfill(const z: integer; const x: integer): string;
var
  i: integer;
  len: integer;
begin
  Result := IntToStr(x);
  len := Length(Result);
  for i := len + 1 to z do
    Result := '0' + Result;
end;

function intval(const b: boolean): integer;
begin
  if b then
    Result := 1
  else
    Result := 0;
end;

function decide(const contition: boolean; const iftrue: integer;
  const iffalse: integer): integer;
begin
  if contition then
    Result := iftrue
  else
    Result := iffalse;
end;

function incp(var p: pointer; const size: integer = 1): pointer;
begin
  Result := Pointer(integer(p) + size);
  p := Result;
end;

function pOperation(const p1, p2: pointer; const op: char; size: integer): integer;
begin
  case op of
    '+': Result := (integer(p1) + integer(p2)) div size;
    '-': Result := (integer(p1) - integer(p2)) div size;
    else
      Result := 0;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
constructor TFile.Create(const FileName: string; mode: word);
begin
  Assign(f, FileName);
  {$I-}
  if mode = fCreate then
    rewrite(f, 1)
  else
    reset(f, 1);
  {$I+}
end;

destructor TFile.Destroy;
begin
  Close(f);
  inherited;
end;

function TFile.Read(var Buffer; Count: longint): longint;
begin
  BlockRead(f, Buffer, Count, Result);
end;

function TFile.Write(const Buffer; Count: longint): longint;
begin
  BlockWrite(f, Buffer, Count, Result);
end;

function TFile.Seek(Offset: longint; Origin: word): longint;
begin
  case Origin of
    sFromBeginning:
      Result := Offset;
    sFromCurrent:
      Result := FilePos(f) + Offset;
    sFromEnd:
      Result := FileSize(f) - Offset;
    else
      Result := 0;
  end;
  system.Seek(f, Result);
end;

function TFile.Size: longint;
begin
  Result := FileSize(f);
end;

constructor TStrList.Create;
begin
  flist := nil;
  fcount := 0;
end;

destructor TStrList.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TStrList.Clear;
begin
  if flist <> nil then
    FreeMem(flist);
  fcount := 0;
end;

procedure TStrList.Add(const s: string);
begin
  ReAllocMem(flist, (fcount + 1) * SizeOf(strlistitem_t));
  flist[fcount] := s;
  inc(fcount);
end;

procedure TStrList.AppendText(const s: string);
var
  s1: string;
  i: integer;
begin
  s1 := '';
  for i := 1 to Length(s) do
  begin
    if s[i] = #10 then
    begin
      Add(s1);
      s1 := '';
    end
    else if s[i] <> #13 then
      s1 := s1 + s[i];
  end;
  if s1 <> '' then
    Add(s1);
end;

procedure TStrList.LoadFromFile(const fname: string);
var
  t: textfile;
  s: string;
begin
  assignfile(t, fname);
  reset(t);
  while not EOF(t) do
  begin
    readln(t, s);
    Add(s);
  end;
  closefile(t);
end;

procedure TStrList.SaveToFile(const fname: string);
var
  t: textfile;
  i: integer;
begin
  assignfile(t, fname);
  rewrite(t);
  for i := 0 to fcount - 1 do
    writeln(t, flist[i]);
  closefile(t);
end;

function TStrList.Strings(const i: integer): string;
begin
  if i >= 0 then
    if i < fcount then
    begin
      Result := flist[i];
      Exit;
    end;
  Result := '';
end;

function TStrList.Names(const i: integer): string;
var
  p: integer;
begin
  if i >= 0 then
    if i < fcount then
    begin
      Result := flist[i];
      p := Pos('=', Result);
      if p > 0 then
        SetLength(Result, p - 1);
      Exit;
    end;
  Result := '';
end;

function TStrList.Values(const i: integer): string;
var
  s: string;
  p: integer;
begin
  Result := '';
  if i >= 0 then
    if i < fcount then
    begin
      s := flist[i];
      p := Pos('=', s);
      if p > 0 then
      begin
        inc(p);
        while p <= Length(s) do
        begin
          Result := Result + s[p];
          inc(p);
        end;
      end;
    end;
end;

{$IFDEF FPC}
function GetEnvironmentVariable(lpName: PChar; lpBuffer: PChar; nSize: DWORD): DWORD; stdcall; external 'kernel32.dll' name 'GetEnvironmentVariableA';
{$ENDIF}

function getenv(const env: string): string;
var
  buf: array[0..2047] of char;
begin
  ZeroMemory(@buf, SizeOf(buf));
  GetEnvironmentVariable(PChar(env), buf, 2047);
  Result := Trim(StringVal(buf));
end;

function fexists(const filename: string): boolean;
begin
  Result := FileExists(filename);
end;

procedure fdelete(const filename: string);
begin
  if fexists(filename) then
    DeleteFile(filename);
end;

function fext(const filename: string): string;
begin
  Result := ExtractFileExt(filename);
end;

function ftan(const X: Extended): Extended;
asm
  FLD    X
  FPTAN
  FSTP   ST(0)
  FWAIT
end;

function strupper(const S: string): string;
var
  Ch: char;
  L: integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then
      Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function toupper(ch: char): char;
asm
  CMP     AL,'a'
  JB      @@Exit
  CMP     AL,'z'
  JA      @@Exit
  SUB     AL,'a' - 'A'
@@Exit:
end;

function tolower(ch: char): char;
asm
  CMP     AL,'A'
  JB      @@Exit
  CMP     AL,'Z'
  JA      @@Exit
  SUB     AL,'A' - 'a'
@@Exit:
end;

function _SHL(const x: integer; const bits: integer): integer; assembler;
asm
  mov ecx, edx
  sal eax, cl
end;

function _SHLW(const x: LongWord; const bits: LongWord): LongWord;
begin
  Result := x shl bits;
end;

function _SHR(const x: integer; const bits: integer): integer; assembler;
asm
  mov ecx, edx
  sar eax, cl
end;

function StringVal(const Str: PChar): string;
begin
  Result := Str;
end;

procedure ZeroMemory(const P: Pointer; Count: integer);
begin
  FillChar(P^, Count, Chr(0));
end;

end.
