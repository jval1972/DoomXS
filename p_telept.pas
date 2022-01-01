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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/doomxs/
//------------------------------------------------------------------------------

unit p_telept;

interface

uses
  p_mobj_h,
  r_defs;

// TELEPORTATION
function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t): integer;

implementation

uses
  doomdef,
  doomstat,
  d_think,
  d_player,
  info_h,
  m_fixed,
  p_setup,
  p_tick,
  p_mobj,
  p_map,
  s_sound,
  sounds,
  tables;

function EV_Teleport(line: Pline_t; side: integer; thing: Pmobj_t): integer;
var
  i: integer;
  tag: integer;
  m: Pmobj_t;
  fog: Pmobj_t;
  an: LongWord;
  thinker: Pthinker_t;
  sector: Psector_t;
  oldx: fixed_t;
  oldy: fixed_t;
  oldz: fixed_t;
  plyr: Pplayer_t;
begin
  // don't teleport missiles
  if thing.flags and MF_MISSILE <> 0 then
  begin
    Result := 0;
    Exit;
  end;

  // Don't teleport if hit back of line,
  //  so you can get out of teleporter.
  if side = 1 then
  begin
    Result := 0;
    Exit;
  end;

  tag := line.tag;
  for i := 0 to numsectors - 1 do
  begin
    if sectors[i].tag = tag then
    begin
      thinker := thinkercap.next;
      while thinker <> @thinkercap do
      begin
        // not a mobj
        if @thinker.func.acp1 <> @P_MobjThinker then
        begin
          thinker := thinker.next;
          Continue;
        end;

        m := Pmobj_t(thinker);

        // not a teleportman
        if m.typ <> MT_TELEPORTMAN then
        begin
          thinker := thinker.next;
          Continue;
        end;

        sector := Psubsector_t(m.subsector).sector;
        // wrong sector
        if sector <> @sectors[i] then
        begin
          thinker := thinker.next;
          Continue;
        end;

        oldx := thing.x;
        oldy := thing.y;
        oldz := thing.z;

        if not P_TeleportMove(thing, m.x, m.y) then
        begin
          Result := 0;
          Exit;
        end;

        if not (gamemission in [pack_tnt, pack_plut]) then
          thing.z := thing.floorz;  //fixme: not needed?
        plyr := thing.player;
        if plyr <> nil then
          plyr.viewz := thing.z + plyr.viewheight;

        // spawn teleport fog at source and destination
        fog := P_SpawnMobj(oldx, oldy, oldz, MT_TFOG);
        S_StartSound(fog, Ord(sfx_telept));
        an := m.angle shr ANGLETOFINESHIFT;
        fog := P_SpawnMobj(m.x + 20 * finecosine[an], m.y +
          20 * finesine[an], thing.z, MT_TFOG);

        // emit sound, where?
        S_StartSound(fog, Ord(sfx_telept));

        // don't move for a bit
        if plyr <> nil then
          thing.reactiontime := 18;

        thing.angle := m.angle;
        thing.momx := 0;
        thing.momy := 0;
        thing.momz := 0;
        Result := 1;
        Exit;
      end;
    end;
  end;
  Result := 0;
end;

end.

