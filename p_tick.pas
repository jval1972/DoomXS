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

unit p_tick;

interface

uses
  p_local,
  doomstat,
  d_think;


// THINKERS
// All thinkers should be allocated by Z_Malloc
// so they can be operated on uniformly.
// The actual structures will vary in size,
// but the first element must be thinker_t.


var
  // Both the head and tail of the thinker list.
  thinkercap: thinker_t;

procedure P_InitThinkers;

procedure P_AddThinker(thinker: Pthinker_t);

procedure P_RemoveThinker(thinker: Pthinker_t);

procedure P_Ticker;

var
  leveltime: integer;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  g_game,
  m_menu,
  p_user,
  p_spec,
  p_mobj,
  z_memory;

procedure P_InitThinkers;
begin
  thinkercap.prev := @thinkercap;
  thinkercap.next := @thinkercap;
end;

// P_AddThinker
// Adds a new thinker at the end of the list.
procedure P_AddThinker(thinker: Pthinker_t);
begin
  thinkercap.prev.next := thinker;
  thinker.next := @thinkercap;
  thinker.prev := thinkercap.prev;
  thinkercap.prev := thinker;
end;

// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
procedure P_RemoveThinker(thinker: Pthinker_t);
begin
  // FIXME: NOP.
  thinker._function.acv := nil;
end;

// P_AllocateThinker
// Allocates memory and adds a new thinker at the end of the list.
procedure P_AllocateThinker(thinker: Pthinker_t);
begin
end;

// P_RunThinkers
procedure P_RunThinkers;
var
  currentthinker: Pthinker_t;
  nextthinker: Pthinker_t;
begin
  currentthinker := thinkercap.next;
  while currentthinker <> @thinkercap do
  begin
    if not Assigned(currentthinker._function.acv) then
    begin
      // time to remove it
      currentthinker.next.prev := currentthinker.prev;
      currentthinker.prev.next := currentthinker.next;
      nextthinker := currentthinker.next; // JVAL: 20201228 - Keep next pointer in nextthinker
      Z_Free(currentthinker);
      currentthinker := nextthinker;      // JVAL: 20201228 - Set currentthinker to next pointer
    end
    else
    begin
      if Assigned(currentthinker._function.acp1) then
        currentthinker._function.acp1(currentthinker);
      currentthinker := currentthinker.next;
    end;
  end;
end;

// P_Ticker
procedure P_Ticker;
var
  i: integer;
begin
  // run the tic
  if paused then
    exit;

  // pause if in menu and at least one tic has been run
  if not netgame and menuactive and not demoplayback and
    (players[consoleplayer].viewz <> 1) then
    exit;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      P_PlayerThink(@players[i]);

  P_RunThinkers;
  P_UpdateSpecials;
  P_RespawnSpecials;

  // for par times
  Inc(leveltime);
end;

end.
