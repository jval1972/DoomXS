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

unit m_argv;

interface

const
  MAXARGS = 256;

var
  myargc: integer;
  myargv: array[0..MAXARGS] of string;

{ Returns the position of the given parameter }
{ in the arg list (0 if not found). }
function M_CheckParm(const check: string): integer;

function M_CheckParmCDROM: boolean;

procedure M_InitArgv;

implementation

uses
  d_delphi;

var
  cdchecked: integer = -1;

function M_CheckParm(const check: string): integer;
var
  i: integer;
begin
  for i := 1 to myargc - 1 do
    if strupper(check) = myargv[i] then
    begin
      Result := i;
      Exit;
    end;
  Result := 0;
end;

function M_CheckParmCDROM: boolean;
begin
  if cdchecked = -1 then
  begin
    cdchecked := M_CheckParm('-cdrom');
    {$I-}
    if cdchecked > 0 then
      MkDir('c:\doomdata');
    {$I+}
  end;
  Result := cdchecked > 0;
end;

procedure M_InitArgv;
var
  i: integer;
begin
  myargc := ParamCount + 1;
  for i := 0 to myargc - 1 do
    myargv[i] := strupper(ParamStr(i));
  for i := myargc to MAXARGS do
    myargv[i] := '';
end;

end.
