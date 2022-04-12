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
unit r_intrpl;

// JVAL
// Frame interpolation to exceed the 35fps limit
//

interface

procedure R_ResetInterpolationBuffer;

procedure R_StoreInterpolationData;

procedure R_RestoreInterpolationData;

function R_Interpolate: boolean;

var
  interpolationstarttime: int64;

implementation

uses
  d_delphi,
  d_player,
  d_think,
  g_game,
  i_system,
  m_fixed,
  p_setup,
  p_tick,
  p_mobj,
  p_mobj_h,
  p_pspr_h,
  r_defs,
  z_memory;

type
  // Interpolation item
  //  Holds information about the previous and next values
  iitem_t = record
    lastaddress: PInteger;
    address: PInteger;
    iprev, inext: integer;
  end;
  Piitem_t = ^iitem_t;
  iitem_tArray = array[0..$FFFF] of iitem_t;
  Piitem_tArray = ^iitem_tArray;

  // Interpolation structure
  //  Holds the global interpolation items list
  istruct_t = record
    numitems: integer;
    realsize: integer;
    items: Piitem_tArray;
  end;

const
  IGROWSTEP = 256;

var
  istruct: istruct_t;
  ffrac: single;

procedure R_ResetInterpolationBuffer;
begin
  if istruct.items <> nil then
    Z_Free(istruct.items);
  istruct.items := nil;
  istruct.numitems := 0;
  istruct.realsize := 0;
end;

const
  DIFF_THRESHOLD = 32 * FRACUNIT;

procedure R_InterpolationCalcI(const pi: Piitem_t; const thres: integer = DIFF_THRESHOLD);
var
  diff: integer;
begin
  diff := pi.inext - pi.iprev;
  if Abs(diff) > thres then
    exit;
  if diff <> 0 then
    pi.address^ := pi.iprev + Round(diff * ffrac);
end;

procedure R_AddInterpolationItem(const addr: PInteger);
var
  newrealsize: integer;
  pi: Piitem_t;
begin
  if istruct.realsize <= istruct.numitems then
  begin
    newrealsize := istruct.realsize + IGROWSTEP;
    istruct.items := Z_Realloc(istruct.items, newrealsize * SizeOf(iitem_t), PU_STATIC, nil);
    ZeroMemory(@istruct.items[istruct.realsize], IGROWSTEP * SizeOf(iitem_t));
    istruct.realsize := newrealsize;
  end;
  pi := @istruct.items[istruct.numitems];
  pi.lastaddress := pi.address;
  pi.address := addr;
  pi.iprev := pi.inext;
  pi.inext := addr^;
  inc(istruct.numitems);
end;

procedure R_StoreInterpolationData;
var
  sec: Psector_t;
  li: Pline_t;
  si: PSide_t;
  i, j: integer;
  player: Pplayer_t;
  pmo: Pmobj_t;
  th: Pthinker_t;
begin
  istruct.numitems := 0;

  // Interpolate player
  player := @players[displayplayer];
  pmo := player.mo;
  R_AddInterpolationItem(@pmo.angle);
  R_AddInterpolationItem(@pmo.x);
  R_AddInterpolationItem(@pmo.y);
  R_AddInterpolationItem(@pmo.z);
  R_AddInterpolationItem(@player.viewz);
  for i := 0 to Ord(NUMPSPRITES) - 1 do
  begin
    R_AddInterpolationItem(@player.psprites[i].sx);
    R_AddInterpolationItem(@player.psprites[i].sy);
  end;

  // Interpolate Sectors
  sec := @sectors[0];
  for i := 0 to numsectors - 1 do
  begin
    R_AddInterpolationItem(@sec.floorheight);
    R_AddInterpolationItem(@sec.ceilingheight);
    inc(sec);
  end;

  // Interpolate Lines
  li := @lines[0];
  for i := 0 to numlines - 1 do
  begin
    for j := 0 to 1 do
    begin
      if li.sidenum[j] > -1 then
      begin
        si := @sides[li.sidenum[j]];
        R_AddInterpolationItem(@si.textureoffset);
        R_AddInterpolationItem(@si.rowoffset);
      end;
    end;
    inc(li);
  end;

  // Map Objects
  th := thinkercap.next;
  while (th <> nil) and (th <> @thinkercap) do
  begin
    if @th.func.acp1 = @P_MobjThinker then
      if Pmobj_t(th) <> pmo then
      begin
        R_AddInterpolationItem(@Pmobj_t(th).x);
        R_AddInterpolationItem(@Pmobj_t(th).y);
        R_AddInterpolationItem(@Pmobj_t(th).z);
      end;
    th := th.next;
  end;
end;

procedure R_RestoreInterpolationData;
var
  i: integer;
  pi: Piitem_t;
begin
  pi := @istruct.items[0];
  for i := 0 to istruct.numitems - 1 do
  begin
    pi.address^ := pi.inext;
    inc(pi);
  end;
  istruct.numitems := 0;
end;

function R_Interpolate: boolean;
var
  i: integer;
  pi: Piitem_t;
begin
  ffrac := (I_GetTime64 - interpolationstarttime) / FRACUNIT;
  if ffrac >= 1.0 then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  // Prevent player teleport interpolation
  if (istruct.items[1].lastaddress = istruct.items[1].address) and
    (istruct.items[2].lastaddress = istruct.items[2].address) and
    (istruct.items[3].lastaddress = istruct.items[3].address) then
  begin
    if (Abs(istruct.items[1].iprev - istruct.items[1].inext) < DIFF_THRESHOLD) and
      (Abs(istruct.items[2].iprev - istruct.items[2].inext) < DIFF_THRESHOLD) and
      (Abs(istruct.items[3].iprev - istruct.items[3].inext) < DIFF_THRESHOLD) then
    begin
      R_InterpolationCalcI(@istruct.items[0], MAXINT);
      R_InterpolationCalcI(@istruct.items[1]);
      R_InterpolationCalcI(@istruct.items[2]);
      R_InterpolationCalcI(@istruct.items[3]);
      R_InterpolationCalcI(@istruct.items[4]);
    end;
  end;
  pi := @istruct.items[5];
  for i := 5 to istruct.numitems - 1 do
  begin
    if pi.address = pi.lastaddress then
      R_InterpolationCalcI(pi);
    inc(pi);
  end;
end;

end.

