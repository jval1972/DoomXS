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

unit tables;

interface

{
    tables.h, tables.c
}

  { Emacs style mode select   -*- C++ -*-  }
  {----------------------------------------------------------------------------- }
  { }
  { $Id:$ }
  { }
  { Copyright (C) 1993-1996 by id Software, Inc. }
  { }
  { This source is available for distribution and/or modification }
  { only under the terms of the DOOM Source Code License as }
  { published by id Software. All rights reserved. }
  { }
  { The source is distributed in the hope that it will be useful, }
  { but WITHOUT ANY WARRANTY; without even the implied warranty of }
  { FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License }
  { for more details. }
  { }
  { DESCRIPTION: }
  {	Lookup tables. }
  {	Do not try to look them up :-). }
  {	In the order of appearance:  }
  { }
  {	int finetangent[4096]	- Tangens LUT. }
  {	 Should work with BAM fairly well (12 of 16bit, }
  {      effectively, by shifting). }
  { }
  {	int finesine[10240]		- Sine lookup. }
  {	 Guess what, serves as cosine, too. }
  {	 Remarkable thing is, how to use BAMs with this?  }
  { }
  {	int tantoangle[2049]	- ArcTan LUT, }
  {	  maps tan(angle) to angle fast. Gotta search.	 }
  {     }
  {----------------------------------------------------------------------------- }

uses m_fixed;

const PI = 3.141592657;


const
  FINEANGLES = 8192;
  FINEMASK = FINEANGLES - 1;

// 0x100000000 to 0x2000
  ANGLETOFINESHIFT = 19;
  { Effective size is 10240. }

// Binary Angle Measument, BAM.

type
  angle_t = LongWord;

const
  ANG45 = $20000000;
  ANG90 = $40000000;
  ANG180 = $80000000;
  ANG270 = $c0000000;
  SLOPERANGE = 2048;
  SLOPEBITS = 11;
  DBITS = FRACBITS - SLOPEBITS;

var
// Effective size is 10240.
  finesine: array[0..((5 * FINEANGLES) div 4) - 1] of fixed_t;

// Re-use data, is just PI/2 pahse shift.
  finecosine: Pfixed_tArray;

// Effective size is 4096.
  finetangent : array[0..(FINEANGLES div 2) - 1] of fixed_t;

// Effective size is 2049;
// The +1 size is to handle the case when x==y
//  without additional checking.
  tantoangle: array[0..(SLOPERANGE + 1) - 1] of angle_t;

// Utility function,
// called by R_PointToAngle.

function SlopeDiv(const num: integer; const den: integer): integer;
// VJ was function SlopeDiv(num: LongWord; den: LongWord): integer;

implementation

uses d_delphi;

function SlopeDiv(const num: integer; const den: integer): integer;
// VJ was function SlopeDiv(num: LongWord; den: LongWord): integer;
var ans: LongWord;
begin
  if den < 512 then
    result := SLOPERANGE
  else
  begin
    ans := _SHL(num, 3) div _SHR(den, 8);
    if ans < SLOPERANGE then
      result := ans
    else
      result := SLOPERANGE;
  end;
end;

initialization
  finecosine := Pfixed_tArray(@finesine[FINEANGLES div 4]);

end.


