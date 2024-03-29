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

unit p_doors;

interface

uses
  z_memory,
  doomdef,
  p_mobj_h,
  p_spec,
  r_defs,
  s_sound,
  d_englsh,
  sounds;

procedure T_VerticalDoor(door: Pvldoor_t);

function EV_DoLockedDoor(line: Pline_t; typ: vldoor_e; thing: Pmobj_t): integer;

function EV_DoDoor(line: Pline_t; typ: vldoor_e): integer;

procedure EV_VerticalDoor(line: Pline_t; thing: Pmobj_t);

procedure P_SpawnDoorCloseIn30(sec: Psector_t);

procedure P_SpawnDoorRaiseIn5Mins(sec: Psector_t; secnum: integer);

implementation

uses
  m_fixed,
  d_player,
  p_tick,
  p_setup,
  p_floor;

// VERTICAL DOORS

// T_VerticalDoor
procedure T_VerticalDoor(door: Pvldoor_t);
var
  res: result_e;
begin
  case door.direction of
    0:
    begin
      // WAITING
      dec(door.topcountdown);
      if door.topcountdown = 0 then
      begin
        case door.typ of
          blazeRaise:
          begin
            door.direction := -1; // time to go back down
            S_StartSound(@door.sector.soundorg, Ord(sfx_bdcls));
          end;
          normal:
          begin
            door.direction := -1; // time to go back down
            S_StartSound(@door.sector.soundorg, Ord(sfx_dorcls));
          end;
          close30ThenOpen:
          begin
            door.direction := 1;
            S_StartSound(@door.sector.soundorg, Ord(sfx_doropn));
          end;
        end;
      end;
    end;
    2:
    begin
      //  INITIAL WAIT
      dec(door.topcountdown);
      if door.topcountdown = 0 then
      begin
        case door.typ of
          raiseIn5Mins:
          begin
            door.direction := 1;
            door.typ := normal;
            S_StartSound(@door.sector.soundorg, Ord(sfx_doropn));
          end;
        end;
      end;
    end;
    -1:
    begin
      // DOWN
      res := T_MovePlane(door.sector, door.speed, door.sector.floorheight,
        False, 1, door.direction);
      if res = pastdest then
      begin
        case door.typ of
          blazeRaise,
          blazeClose:
          begin
            door.sector.specialdata := nil;
            P_RemoveThinker(@door.thinker); // unlink and free
            S_StartSound(@door.sector.soundorg, Ord(sfx_bdcls));
          end;
          normal,
          close:
          begin
            door.sector.specialdata := nil;
            P_RemoveThinker(@door.thinker);  // unlink and free
          end;
          close30ThenOpen:
          begin
            door.direction := 0;
            door.topcountdown := TICRATE * 30;
          end;
        end;
      end
      else if res = crushed then
      begin
        case door.typ of
          blazeClose,
          close:    // DO NOT GO BACK UP!
          begin
          end;
          else
          begin
            door.direction := 1;
            S_StartSound(@door.sector.soundorg, Ord(sfx_doropn));
          end;
        end;
      end;
    end;
    1:
    begin
      // UP
      res := T_MovePlane(door.sector, door.speed, door.topheight,
        False, 1, door.direction);
      if res = pastdest then
      begin
        case door.typ of
          blazeRaise,
          normal:
          begin
            door.direction := 0; // wait at top
            door.topcountdown := door.topwait;
          end;
          close30ThenOpen,
          blazeOpen,
          open:
          begin
            door.sector.specialdata := nil;
            P_RemoveThinker(@door.thinker); // unlink and free
          end;
        end;
      end;
    end;
  end;
end;

// EV_DoLockedDoor
// Move a locked door up/down
function EV_DoLockedDoor(line: Pline_t; typ: vldoor_e; thing: Pmobj_t): integer;
var
  p: Pplayer_t;
begin
  p := thing.player;

  if p = nil then
  begin
    Result := 0;
    Exit;
  end;

  case line.special of
    99,  // Blue Lock
    133:
    begin
      if not p.cards[Ord(it_bluecard)] and not p.cards[Ord(it_blueskull)] then
      begin
        p.msg := PD_BLUEO;
        S_StartSound(nil, Ord(sfx_oof));
        Result := 0;
        Exit;
      end;
    end;

    134, // Red Lock
    135:
    begin
      if not p.cards[Ord(it_redcard)] and not p.cards[Ord(it_redskull)] then
      begin
        p.msg := PD_REDO;
        S_StartSound(nil, Ord(sfx_oof));
        Result := 0;
        Exit;
      end;
    end;

    136,  // Yellow Lock
    137:
    begin
      if not p.cards[Ord(it_yellowcard)] and not p.cards[Ord(it_yellowskull)] then
      begin
        p.msg := PD_YELLOWO;
        S_StartSound(nil, Ord(sfx_oof));
        Result := 0;
        Exit;
      end;
    end;
  end;

  Result := EV_DoDoor(line, typ);
end;

function EV_DoDoor(line: Pline_t; typ: vldoor_e): integer;
var
  initial: boolean;
  secnum: integer;
  sec: Psector_t;
  door: Pvldoor_t;
begin
  secnum := -1;
  Result := 0;

  initial := True;
  while (secnum >= 0) or initial do
  begin
    initial := False;
    secnum := P_FindSectorFromLineTag(line, secnum);
    if secnum < 0 then
      Break;

    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      Continue;

    // new door thinker
    Result := 1;
    door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
    P_AddThinker(@door.thinker);
    sec.specialdata := door;

    door.thinker.func.acp1 := @T_VerticalDoor;
    door.sector := sec;
    door.typ := typ;
    door.topwait := VDOORWAIT;
    door.speed := VDOORSPEED;

    case typ of
      blazeClose:
      begin
        door.topheight := P_FindLowestCeilingSurrounding(sec);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        door.speed := VDOORSPEED * 4;
        S_StartSound(@door.sector.soundorg, Ord(sfx_bdcls));
      end;

      Close:
      begin
        door.topheight := P_FindLowestCeilingSurrounding(sec);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        S_StartSound(@door.sector.soundorg, Ord(sfx_dorcls));
      end;

      close30ThenOpen:
      begin
        door.topheight := sec.ceilingheight;
        door.direction := -1;
        S_StartSound(@door.sector.soundorg, Ord(sfx_dorcls));
      end;

      blazeRaise,
      blazeOpen:
      begin
        door.direction := 1;
        door.topheight := P_FindLowestCeilingSurrounding(sec);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.speed := VDOORSPEED * 4;
        if door.topheight <> sec.ceilingheight then
          S_StartSound(@door.sector.soundorg, Ord(sfx_bdopn));
      end;

      normal,
      open:
      begin
        door.direction := 1;
        door.topheight := P_FindLowestCeilingSurrounding(sec);
        door.topheight := door.topheight - 4 * FRACUNIT;
        if door.topheight <> sec.ceilingheight then
          S_StartSound(@door.sector.soundorg, Ord(sfx_doropn));
      end;
    end;
  end;
end;

// EV_VerticalDoor : open a door manually, no tag value
procedure EV_VerticalDoor(line: Pline_t; thing: Pmobj_t);
var
  player: Pplayer_t;
  sec: Psector_t;
  door: Pvldoor_t;
  side: integer;
begin
  side := 0;  // only front sides can be used

  // Check for locks
  player := thing.player;

  case line.special of
    26, // Blue Lock
    32:
    begin
      if player = nil then
        Exit;

      if not player.cards[Ord(it_bluecard)] and not player.cards[Ord(it_blueskull)] then
      begin
        player.msg := PD_BLUEK;
        S_StartSound(nil, Ord(sfx_oof));
        Exit;
      end;
    end;
    27, // Yellow Lock
    34:
    begin
      if player = nil then
        Exit;

      if not player.cards[Ord(it_yellowcard)] and not player.cards[Ord(it_yellowskull)] then
      begin
        player.msg := PD_YELLOWK;
        S_StartSound(nil, Ord(sfx_oof));
        Exit;
      end;
    end;
    28, // Red Lock
    33:
    begin
      if player = nil then
        Exit;

      if not player.cards[Ord(it_redcard)] and not player.cards[Ord(it_redskull)] then
      begin
        player.msg := PD_REDK;
        S_StartSound(nil, Ord(sfx_oof));
        Exit;
      end;
    end;
  end;

  // if the sector has an active thinker, use it
  sec := sides[line.sidenum[side xor 1]].sector;

  if sec.specialdata <> nil then
  begin
    door := sec.specialdata;
    case line.special of
      1, // ONLY FOR "RAISE" DOORS, NOT "OPEN"s
      26,
      27,
      28,
      117:
      begin
        if door.direction = -1 then
          door.direction := 1 // go back up
        else
        begin
          if thing.player = nil then
            Exit; // JDC: bad guys never close doors

          door.direction := -1; // start going down immediately
        end;
        Exit;
      end;
    end;
  end;

  // for proper sound
  case line.special of
    117, // BLAZING DOOR RAISE
    118: // BLAZING DOOR OPEN
      S_StartSound(@sec.soundorg, Ord(sfx_bdopn));
    1, // NORMAL DOOR SOUND
    31:
      S_StartSound(@sec.soundorg, Ord(sfx_doropn));
    else // LOCKED DOOR SOUND
      S_StartSound(@sec.soundorg, Ord(sfx_doropn));
  end;

  // new door thinker
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
  P_AddThinker(@door.thinker);
  sec.specialdata := door;
  door.thinker.func.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.direction := 1;
  door.speed := VDOORSPEED;
  door.topwait := VDOORWAIT;

  case line.special of
    1,
    26,
    27,
    28:
      door.typ := normal;
    31,
    32,
    33,
    34:
    begin
      door.typ := open;
      line.special := 0;
    end;
    117: // blazing door raise
    begin
      door.typ := blazeRaise;
      door.speed := VDOORSPEED * 4;
    end;
    118: // blazing door open
    begin
      door.typ := blazeOpen;
      line.special := 0;
      door.speed := VDOORSPEED * 4;
    end;
  end;

  // find the top and bottom of the movement range
  door.topheight := P_FindLowestCeilingSurrounding(sec);
  door.topheight := door.topheight - 4 * FRACUNIT;
end;

// Spawn a door that closes after 30 seconds
procedure P_SpawnDoorCloseIn30(sec: Psector_t);
var
  door: Pvldoor_t;
begin
  door := Z_Malloc(SizeOf(door^), PU_LEVSPEC, nil);

  P_AddThinker(@door.thinker);

  sec.specialdata := door;
  sec.special := 0;

  door.thinker.func.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.direction := 0;
  door.typ := normal;
  door.speed := VDOORSPEED;
  door.topcountdown := 30 * TICRATE;
end;

// Spawn a door that opens after 5 minutes
procedure P_SpawnDoorRaiseIn5Mins(sec: Psector_t; secnum: integer);
var
  door: Pvldoor_t;
begin
  door := Z_Malloc(SizeOf(door^), PU_LEVSPEC, nil);

  P_AddThinker(@door.thinker);

  sec.specialdata := door;
  sec.special := 0;

  door.thinker.func.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.direction := 2;
  door.typ := raiseIn5Mins;
  door.speed := VDOORSPEED;
  door.topheight := P_FindLowestCeilingSurrounding(sec);
  door.topheight := door.topheight - 4 * FRACUNIT;
  door.topwait := VDOORWAIT;
  door.topcountdown := 5 * 60 * TICRATE;
end;

end.


