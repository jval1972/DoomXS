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

unit m_fixed;

interface

const
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;

type
  fixed_t = integer;
  Pfixed_t = ^fixed_t;
  fixed_tArray = packed array[0..$FFFF] of fixed_t;
  Pfixed_tArray = ^fixed_tArray;

function FixedMul(a: fixed_t; b: fixed_t): fixed_t;

function FixedDiv(a: fixed_t; b: fixed_t): fixed_t;

function FixedDiv2(a: fixed_t; b: fixed_t): fixed_t;

implementation

uses
  i_system,
  d_delphi,
  doomtype;

function FixedMul(a: fixed_t; b: fixed_t): fixed_t;
var
  c: extended;
begin
  //  result := (a * b) div FRACUNIT;
  c := a / FRACUNIT;
  Result := trunc(c * b);
end;

function FixedDiv(a: fixed_t; b: fixed_t): fixed_t;
begin
  if _SHR(abs(a), 14) >= abs(b) then
  begin
    if a xor b < 0 then
      Result := MININT
    else
      Result := MAXINT;
  end
  else
    Result := FixedDiv2(a, b);
end;

function FixedDiv2(a: fixed_t; b: fixed_t): fixed_t;
var
  c: extended;
begin
  c := (a / b) * FRACUNIT;

  if (c >= 2147483648.0) or (c < -2147483648.0) then
    I_Error('FixedDiv(): divide by zero' + #13#10);

  Result := trunc(c);
end;

end.
