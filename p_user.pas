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

unit p_user;

interface

uses
  d_player;

procedure P_PlayerThink(player: Pplayer_t);

implementation

uses
  d_delphi,
  m_fixed,
  tables,
  d_ticcmd,
  d_event,
  info_h,
  info,
  p_mobj_h,
  p_mobj,
  p_tick,
  p_pspr,
  p_local,
  p_spec,
  p_map,
  r_main,
  r_defs,
  doomdef,
  doomstat;

const
  // Index of the special effects (INVUL inverse) map.
  INVERSECOLORMAP = 32;


// Movement.

const
  // 16 pixels of bob
  MAXBOB = $100000;

var
  onground: boolean;


// P_Thrust
// Moves the given origin along a given angle.

procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);
begin
  angle := angle shr ANGLETOFINESHIFT;

  player.mo.momx := player.mo.momx + FixedMul(move, finecosine[angle]);
  player.mo.momy := player.mo.momy + FixedMul(move, finesine[angle]);
end;


// P_CalcHeight
// Calculate the walking / running height adjustment

procedure P_CalcHeight(player: Pplayer_t);
var
  angle: integer;
  bob: fixed_t;
begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.

  player.bob := FixedMul(player.mo.momx, player.mo.momx) +
    FixedMul(player.mo.momy, player.mo.momy);
  player.bob := _SHR(player.bob, 2);

  if player.bob > MAXBOB then
    player.bob := MAXBOB;

  if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then
  begin
    player.viewz := player.mo.z + PVIEWHEIGHT;

    if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
      player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

    exit;
  end;

  angle := (FINEANGLES div 20 * leveltime) and FINEMASK;
  bob := FixedMul(player.bob div 2, finesine[angle]);

  // move viewheight
  if player.playerstate = PST_LIVE then
  begin
    player.viewheight := player.viewheight + player.deltaviewheight;

    if player.viewheight > PVIEWHEIGHT then
    begin
      player.viewheight := PVIEWHEIGHT;
      player.deltaviewheight := 0;
    end;

    if player.viewheight < PVIEWHEIGHT div 2 then
    begin
      player.viewheight := PVIEWHEIGHT div 2;
      if player.deltaviewheight <= 0 then
        player.deltaviewheight := 1;
    end;

    if player.deltaviewheight <> 0 then
    begin
      player.deltaviewheight := player.deltaviewheight + FRACUNIT div 4;
      if player.deltaviewheight = 0 then
        player.deltaviewheight := 1;
    end;
  end;
  player.viewz := player.mo.z + player.viewheight + bob;

  if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
    player.viewz := player.mo.ceilingz - 4 * FRACUNIT;
end;

// P_MovePlayer
procedure P_MovePlayer(player: Pplayer_t);
var
  cmd: Pticcmd_t;
begin
  cmd := @player.cmd;

  player.mo.angle := player.mo.angle + _SHLW(cmd.angleturn, 16);

  // Do not let the player control movement
  //  if not onground.
  onground := player.mo.z <= player.mo.floorz;

  if (cmd.forwardmove <> 0) and onground then
    P_Thrust(player, player.mo.angle, cmd.forwardmove * 2048);

  if (cmd.sidemove <> 0) and onground then
    P_Thrust(player, player.mo.angle - ANG90, cmd.sidemove * 2048);

  if ((cmd.forwardmove <> 0) or (cmd.sidemove <> 0)) and
    (player.mo.state = @states[Ord(S_PLAY)]) then
    P_SetMobjState(player.mo, S_PLAY_RUN1);
end;

// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
const
  ANG5 = ANG90 div 18;
  ANG355 = ANG270 + ANG5 * 17; // add by VJ

procedure P_DeathThink(player: Pplayer_t);
var
  angle: angle_t;
  delta: angle_t;
begin
  P_MovePsprites(player);

  // fall to the ground
  if player.viewheight > 6 * FRACUNIT then
    player.viewheight := player.viewheight - FRACUNIT;

  if player.viewheight < 6 * FRACUNIT then
    player.viewheight := 6 * FRACUNIT;

  player.deltaviewheight := 0;
  onground := player.mo.z <= player.mo.floorz;
  P_CalcHeight(player);

  if (player.attacker <> nil) and (player.attacker <> player.mo) then
  begin
    angle := R_PointToAngle2(player.mo.x, player.mo.y,
      player.attacker.x, player.attacker.y);

    delta := angle - player.mo.angle;

    if (delta < ANG5) or (delta > ANG355) then
    begin
      // Looking at killer,
      //  so fade damage flash down.
      player.mo.angle := angle;

      if player.damagecount > 0 then
        player.damagecount := player.damagecount - 1;
    end
    else if delta < ANG180 then
      player.mo.angle := player.mo.angle + ANG5
    else
      player.mo.angle := player.mo.angle - ANG5;
  end
  else if player.damagecount > 0 then
    player.damagecount := player.damagecount - 1;


  if player.cmd.buttons and BT_USE <> 0 then
    player.playerstate := PST_REBORN;
end;


// P_PlayerThink

procedure P_PlayerThink(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  newweapon: weapontype_t;
begin
  // fixme: do this in the cheat code
  if player.cheats and CF_NOCLIP <> 0 then
    player.mo.flags := player.mo.flags or MF_NOCLIP
  else
    player.mo.flags := player.mo.flags and not MF_NOCLIP;

  // chain saw run forward
  cmd := @player.cmd;
  if player.mo.flags and MF_JUSTATTACKED <> 0 then
  begin
    cmd.angleturn := 0;
    cmd.forwardmove := $c800 div 512;
    cmd.sidemove := 0;
    player.mo.flags := player.mo.flags and not MF_JUSTATTACKED;
  end;


  if player.playerstate = PST_DEAD then
  begin
    P_DeathThink(player);
    exit;
  end;

  // Move around.
  // Reactiontime is used to prevent movement
  //  for a bit after a teleport.
  if player.mo.reactiontime <> 0 then
    player.mo.reactiontime := player.mo.reactiontime - 1
  else
    P_MovePlayer(player);

  P_CalcHeight(player);

  if Psubsector_t(player.mo.subsector).sector.special <> 0 then
    P_PlayerInSpecialSector(player);

  // Check for weapon change.

  // A special event has no other buttons.
  if cmd.buttons and BT_SPECIAL <> 0 then
    cmd.buttons := 0;

  if cmd.buttons and BT_CHANGE <> 0 then
  begin
    // The actual changing of the weapon is done
    //  when the weapon psprite can do it
    //  (read: not in the middle of an attack).
    newweapon := weapontype_t(_SHR(cmd.buttons and BT_WEAPONMASK, BT_WEAPONSHIFT));

    if (newweapon = wp_fist) and player.weaponowned[Ord(wp_chainsaw)] and
      (not ((player.readyweapon = wp_chainsaw) and
      (player.powers[Ord(pw_strength)] <> 0))) then
      newweapon := wp_chainsaw;

    if (gamemode = commercial) and (newweapon = wp_shotgun) and
      player.weaponowned[Ord(wp_supershotgun)] and
      (player.readyweapon <> wp_supershotgun) then
      newweapon := wp_supershotgun;

    if player.weaponowned[Ord(newweapon)] and
      (newweapon <> player.readyweapon) then
      // Do not go to plasma or BFG in shareware,
      //  even if cheated.
      if ((newweapon <> wp_plasma) and (newweapon <> wp_bfg)) or
        (gamemode <> shareware) then
        player.pendingweapon := newweapon;

  end;

  // check for use
  if cmd.buttons and BT_USE <> 0 then
  begin
    if not player.usedown then
    begin
      P_UseLines(player);
      player.usedown := True;
    end;
  end
  else
    player.usedown := False;

  // cycle psprites
  P_MovePsprites(player);

  // Counters, time dependend power ups.

  // Strength counts up to diminish fade.
  if player.powers[Ord(pw_strength)] <> 0 then
    player.powers[Ord(pw_strength)] := player.powers[Ord(pw_strength)] + 1;

  if player.powers[Ord(pw_invulnerability)] > 0 then
    player.powers[Ord(pw_invulnerability)] := player.powers[Ord(pw_invulnerability)] - 1;

  if player.powers[Ord(pw_invisibility)] > 0 then
  begin
    player.powers[Ord(pw_invisibility)] := player.powers[Ord(pw_invisibility)] - 1;
    if player.powers[Ord(pw_invisibility)] = 0 then
      player.mo.flags := player.mo.flags and not MF_SHADOW;
  end;

  if player.powers[Ord(pw_infrared)] > 0 then
    player.powers[Ord(pw_infrared)] := player.powers[Ord(pw_infrared)] - 1;

  if player.powers[Ord(pw_ironfeet)] > 0 then
    player.powers[Ord(pw_infrared)] := player.powers[Ord(pw_infrared)] - 1;

  if player.damagecount > 0 then
    player.damagecount := player.damagecount - 1;

  if player.bonuscount > 0 then
    player.bonuscount := player.bonuscount - 1;


  // Handling colormaps.
  if player.powers[Ord(pw_invulnerability)] > 0 then
  begin
    if (player.powers[Ord(pw_invulnerability)] > 4 * 32) or
      (player.powers[Ord(pw_invulnerability)] and 8 <> 0) then
      player.fixedcolormap := INVERSECOLORMAP
    else
      player.fixedcolormap := 0;
  end
  else if player.powers[Ord(pw_infrared)] > 0 then
  begin
    if (player.powers[Ord(pw_infrared)] > 4 * 32) or
      (player.powers[Ord(pw_infrared)] and 8 <> 0) then

      // almost full bright
      player.fixedcolormap := 1
    else
      player.fixedcolormap := 0;
  end
  else
    player.fixedcolormap := 0;
end;

end.
