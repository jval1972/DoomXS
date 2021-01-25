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

function FixedMul(const a, b: fixed_t): fixed_t;

function FixedDiv(const a, b: fixed_t): fixed_t;

function FixedDiv2(const a, b: fixed_t): fixed_t;

implementation

uses
  d_delphi,
  doomtype;

function FixedMul(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
end;

function FixedDiv(const a, b: fixed_t): fixed_t;
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

function FixedDiv2(const a, b: fixed_t): fixed_t; assembler;
asm
  mov ebx, b
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
end;

end.
