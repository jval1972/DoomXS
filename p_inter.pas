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

unit p_inter;

interface

uses
  doomdef,
  dstrings,
  d_englsh,
  sounds,
  doomstat,
  m_rnd,
  i_system,
  am_map,
  p_local,
  p_mobj_h,
  s_sound,
  d_player;

function P_GivePower(player: Pplayer_t; power: (*powertype_t*)integer): boolean;

procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);

procedure P_DamageMobj(target, inflictor, Source: Pmobj_t; damage: integer);

const
  // a weapon is found with two clip loads,
  // a big item has five clip loads
  maxammo: array[0..Ord(NUMAMMO) - 1] of integer = (200, 50, 300, 50);
  clipammo: array[0..Ord(NUMAMMO) - 1] of integer = (10, 4, 20, 1);

implementation

uses
  d_delphi,
  info_h,
  info,
  m_fixed,
  d_items,
  g_game,
  p_mobj,
  p_pspr,
  r_defs,
  r_main,
  tables;

const
  BONUSADD = 6;


// GET STUFF

// P_GiveAmmo
// Num is the number of clip loads,
// not the individual count (0= 1/2 clip).
// Returns false if the ammo can't be picked up at all

function P_GiveAmmo(player: Pplayer_t; ammo: ammotype_t; num: integer): boolean;
var
  oldammo: integer;
begin
  if ammo = am_noammo then
  begin
    Result := False;
    exit;
  end;

  if (Ord(ammo) < 0) or (Ord(ammo) > Ord(NUMAMMO)) then
    I_Error('P_GiveAmmo(): bad type %d', [Ord(ammo)]);

  if player.ammo[Ord(ammo)] = player.maxammo[Ord(ammo)] then
  begin
    Result := False;
    exit;
  end;

  if boolval(num) then
    num := num * clipammo[Ord(ammo)]
  else
    num := clipammo[Ord(ammo)] div 2;

  if (gameskill = sk_baby) or (gameskill = sk_nightmare) then
  begin
    // give double ammo in trainer mode,
    // you'll need in nightmare
    num := _SHL(num, 1);
  end;


  oldammo := player.ammo[Ord(ammo)];
  player.ammo[Ord(ammo)] := player.ammo[Ord(ammo)] + num;

  if player.ammo[Ord(ammo)] > player.maxammo[Ord(ammo)] then
    player.ammo[Ord(ammo)] := player.maxammo[Ord(ammo)];

  // If non zero ammo,
  // don't change up weapons,
  // player was lower on purpose.
  if boolval(oldammo) then
  begin
    Result := True;
    exit;
  end;

  // We were down to zero,
  // so select a new weapon.
  // Preferences are not user selectable.
  case ammo of
    am_clip:
    begin
      if player.readyweapon = wp_fist then
      begin
        if player.weaponowned[Ord(wp_chaingun)] then
          player.pendingweapon := wp_chaingun
        else
          player.pendingweapon := wp_pistol;
      end;
    end;
    am_shell:
    begin
      if (player.readyweapon = wp_fist) or (player.readyweapon =
        wp_pistol) then
      begin
        if player.weaponowned[Ord(wp_shotgun)] then
          player.pendingweapon := wp_shotgun;
      end;
    end;
    am_cell:
    begin
      if (player.readyweapon = wp_fist) or (player.readyweapon =
        wp_pistol) then
      begin
        if player.weaponowned[Ord(wp_plasma)] then
          player.pendingweapon := wp_plasma;
      end;
    end;
    am_misl:
    begin
      if player.readyweapon = wp_fist then
      begin
        if player.weaponowned[Ord(wp_missile)] then
          player.pendingweapon := wp_missile;
      end;
    end;
  end;

  Result := True;
end;


// P_GiveWeapon
// The weapon name may have a MF_DROPPED flag ored in.

function P_GiveWeapon(player: Pplayer_t; weapon: weapontype_t;
  dropped: boolean): boolean;
var
  gaveammo: boolean;
  gaveweapon: boolean;
begin
  if netgame and (deathmatch <> 2) and (not dropped) then
  begin
    // leave placed weapons forever on net games
    if player.weaponowned[Ord(weapon)] then
    begin
      Result := False;
      exit;
    end;

    player.bonuscount := player.bonuscount + BONUSADD;
    player.weaponowned[Ord(weapon)] := True;

    if boolval(deathmatch) then
      P_GiveAmmo(player, weaponinfo[Ord(weapon)].ammo, 5)
    else
      P_GiveAmmo(player, weaponinfo[Ord(weapon)].ammo, 2);
    player.pendingweapon := weapon;

    if (player = @players[consoleplayer]) then
      S_StartSound(nil, Ord(sfx_wpnup));
    Result := False;
    exit;
  end;

  if weaponinfo[Ord(weapon)].ammo <> am_noammo then
  begin
    // give one clip with a dropped weapon,
    // two clips with a found weapon
    if dropped then
      gaveammo := P_GiveAmmo(player, weaponinfo[Ord(weapon)].ammo, 1)
    else
      gaveammo := P_GiveAmmo(player, weaponinfo[Ord(weapon)].ammo, 2);
  end
  else
    gaveammo := False;

  if player.weaponowned[Ord(weapon)] then
    gaveweapon := False
  else
  begin
    gaveweapon := True;
    player.weaponowned[Ord(weapon)] := True;
    player.pendingweapon := weapon;
  end;

  Result := gaveweapon or gaveammo;
end;


// P_GiveBody
// Returns false if the body isn't needed at all

function P_GiveBody(player: Pplayer_t; num: integer): boolean;
begin
  if player.health >= MAXHEALTH then
  begin
    Result := False;
    exit;
  end;

  player.health := player.health + num;
  if player.health > MAXHEALTH then
    player.health := MAXHEALTH;
  player.mo.health := player.health;

  Result := True;
end;


// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.

function P_GiveArmor(player: Pplayer_t; armortype: integer): boolean;
var
  hits: integer;
begin
  hits := armortype * 100;
  if player.armorpoints >= hits then
  begin
    Result := False;  // don't pick up
    exit;
  end;

  player.armortype := armortype;
  player.armorpoints := hits;

  Result := True;
end;


// P_GiveCard

procedure P_GiveCard(player: Pplayer_t; card: card_t);
begin
  if player.cards[Ord(card)] then
    exit;

  player.bonuscount := BONUSADD;
  player.cards[Ord(card)] := True;
end;


// P_GivePower

function P_GivePower(player: Pplayer_t; power: (*powertype_t*)integer): boolean;
begin
  if power = Ord(pw_invulnerability) then
  begin
    player.powers[power] := INVULNTICS;
    Result := True;
    exit;
  end;

  if power = Ord(pw_invisibility) then
  begin
    player.powers[power] := INVISTICS;
    player.mo.flags := player.mo.flags or MF_SHADOW;
    Result := True;
    exit;
  end;

  if power = Ord(pw_infrared) then
  begin
    player.powers[power] := INFRATICS;
    Result := True;
    exit;
  end;

  if power = Ord(pw_ironfeet) then
  begin
    player.powers[power] := IRONTICS;
    Result := True;
    exit;
  end;

  if power = Ord(pw_strength) then
  begin
    P_GiveBody(player, 100);
    player.powers[power] := 1;
    Result := True;
    exit;
  end;

  if boolval(player.powers[power]) then
    Result := False // already got it
  else
  begin
    player.powers[power] := 1;
    Result := True;
  end;
end;


// P_TouchSpecialThing

procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
var
  player: Pplayer_t;
  i: integer;
  delta: fixed_t;
  sound: integer;
begin
  delta := special.z - toucher.z;

  if (delta > toucher.Height) or (delta < -8 * FRACUNIT) then
    // out of reach
    exit;


  sound := Ord(sfx_itemup);
  player := toucher.player;

  // Dead thing touching.
  // Can happen with a sliding player corpse.
  if toucher.health <= 0 then
    exit;

  // Identify by sprite.
  case special.sprite of
    // armor
    SPR_ARM1:
    begin
      if not P_GiveArmor(player, 1) then
        exit;
      player._message := GOTARMOR;
    end;

    SPR_ARM2:
    begin
      if not P_GiveArmor(player, 2) then
        exit;
      player._message := GOTMEGA;
    end;

    // bonus items
    SPR_BON1:
    begin
      player.health := player.health + 1; // can go over 100%
      if player.health > 200 then
        player.health := 200;
      player.mo.health := player.health;
      player._message := GOTHTHBONUS;
    end;

    SPR_BON2:
    begin
      player.armorpoints := player.armorpoints + 1; // can go over 100%
      if player.armorpoints > 200 then
        player.armorpoints := 200;
      if not boolval(player.armortype) then
        player.armortype := 1;
      player._message := GOTARMBONUS;
    end;

    SPR_SOUL:
    begin
      player.health := player.health + 100;
      if player.health > 200 then
        player.health := 200;
      player.mo.health := player.health;
      player._message := GOTSUPER;
      sound := Ord(sfx_getpow);
    end;

    SPR_MEGA:
    begin
      if gamemode <> commercial then
        exit;
      player.health := 200;
      player.mo.health := player.health;
      P_GiveArmor(player, 2);
      player._message := GOTMSPHERE;
      sound := Ord(sfx_getpow);
    end;

    // cards
    // leave cards for everyone
    SPR_BKEY:
    begin
      if not player.cards[Ord(it_bluecard)] then
        player._message := GOTBLUECARD;
      P_GiveCard(player, it_bluecard);
      if netgame then
        exit;
    end;

    SPR_YKEY:
    begin
      if not player.cards[Ord(it_yellowcard)] then
        player._message := GOTYELWCARD;
      P_GiveCard(player, it_yellowcard);
      if netgame then
        exit;
    end;

    SPR_RKEY:
    begin
      if not player.cards[Ord(it_redcard)] then
        player._message := GOTREDCARD;
      P_GiveCard(player, it_redcard);
      if netgame then
        exit;
    end;

    SPR_BSKU:
    begin
      if not player.cards[Ord(it_blueskull)] then
        player._message := GOTBLUESKUL;
      P_GiveCard(player, it_blueskull);
      if netgame then
        exit;
    end;

    SPR_YSKU:
    begin
      if not player.cards[Ord(it_yellowskull)] then
        player._message := GOTYELWSKUL;
      P_GiveCard(player, it_yellowskull);
      if netgame then
        exit;
    end;

    SPR_RSKU:
    begin
      if not player.cards[Ord(it_redskull)] then
        player._message := GOTREDSKULL;
      P_GiveCard(player, it_redskull);
      if netgame then
        exit;
    end;

    // medikits, heals
    SPR_STIM:
    begin
      if not P_GiveBody(player, 10) then
        exit;
      player._message := GOTSTIM;
    end;

    SPR_MEDI:
    begin
      if not P_GiveBody(player, 25) then
        exit;

      if player.health < 25 then
        player._message := GOTMEDINEED
      else
        player._message := GOTMEDIKIT;
    end;

    // power ups
    SPR_PINV:
    begin
      if not P_GivePower(player, Ord(pw_invulnerability)) then
        exit;
      player._message := GOTINVUL;
      sound := Ord(sfx_getpow);
    end;

    SPR_PSTR:
    begin
      if not P_GivePower(player, Ord(pw_strength)) then
        exit;
      player._message := GOTBERSERK;
      if player.readyweapon <> wp_fist then
        player.pendingweapon := wp_fist;
      sound := Ord(sfx_getpow);
    end;

    SPR_PINS:
    begin
      if not P_GivePower(player, Ord(pw_invisibility)) then
        exit;
      player._message := GOTINVIS;
      sound := Ord(sfx_getpow);
    end;

    SPR_SUIT:
    begin
      if not P_GivePower(player, Ord(pw_ironfeet)) then
        exit;
      player._message := GOTSUIT;
      sound := Ord(sfx_getpow);
    end;

    SPR_PMAP:
    begin
      if not P_GivePower(player, Ord(pw_allmap)) then
        exit;
      player._message := GOTMAP;
      sound := Ord(sfx_getpow);
    end;

    SPR_PVIS:
    begin
      if not P_GivePower(player, Ord(pw_infrared)) then
        exit;
      player._message := GOTVISOR;
      sound := Ord(sfx_getpow);
    end;

    // ammo
    SPR_CLIP:
    begin
      if boolval(special.flags and MF_DROPPED) then
      begin
        if not P_GiveAmmo(player, am_clip, 0) then
          exit;
      end
      else
      begin
        if not P_GiveAmmo(player, am_clip, 1) then
          exit;
      end;
      player._message := GOTCLIP;
    end;

    SPR_AMMO:
    begin
      if not P_GiveAmmo(player, am_clip, 5) then
        exit;
      player._message := GOTCLIPBOX;
    end;

    SPR_ROCK:
    begin
      if not P_GiveAmmo(player, am_misl, 1) then
        exit;
      player._message := GOTROCKET;
    end;

    SPR_BROK:
    begin
      if not P_GiveAmmo(player, am_misl, 5) then
        exit;
      player._message := GOTROCKBOX;
    end;

    SPR_CELL:
    begin
      if not P_GiveAmmo(player, am_cell, 1) then
        exit;
      player._message := GOTCELL;
    end;

    SPR_CELP:
    begin
      if not P_GiveAmmo(player, am_cell, 5) then
        exit;
      player._message := GOTCELLBOX;
    end;

    SPR_SHEL:
    begin
      if not P_GiveAmmo(player, am_shell, 1) then
        exit;
      player._message := GOTSHELLS;
    end;

    SPR_SBOX:
    begin
      if not P_GiveAmmo(player, am_shell, 5) then
        exit;
      player._message := GOTSHELLBOX;
    end;

    SPR_BPAK:
    begin
      if not player.backpack then
      begin
        for i := 0 to Ord(NUMAMMO) - 1 do
          player.maxammo[i] := player.maxammo[i] * 2;
        player.backpack := True;
      end;
      for i := 0 to Ord(NUMAMMO) - 1 do
        P_GiveAmmo(player, ammotype_t(i), 1);
      player._message := GOTBACKPACK;
    end;

    // weapons
    SPR_BFUG:
    begin
      if not P_GiveWeapon(player, wp_bfg, False) then
        exit;
      player._message := GOTBFG9000;
      sound := Ord(sfx_wpnup);
    end;

    SPR_MGUN:
    begin
      if not P_GiveWeapon(player, wp_chaingun,
        boolval(special.flags and MF_DROPPED)) then
        exit;
      player._message := GOTCHAINGUN;
      sound := Ord(sfx_wpnup);
    end;

    SPR_CSAW:
    begin
      if not P_GiveWeapon(player, wp_chainsaw, False) then
        exit;
      player._message := GOTCHAINSAW;
      sound := Ord(sfx_wpnup);
    end;

    SPR_LAUN:
    begin
      if not P_GiveWeapon(player, wp_missile, False) then
        exit;
      player._message := GOTLAUNCHER;
      sound := Ord(sfx_wpnup);
    end;

    SPR_PLAS:
    begin
      if not P_GiveWeapon(player, wp_plasma, False) then
        exit;
      player._message := GOTPLASMA;
      sound := Ord(sfx_wpnup);
    end;

    SPR_SHOT:
    begin
      if not P_GiveWeapon(player, wp_shotgun,
        boolval(special.flags and MF_DROPPED)) then
        exit;
      player._message := GOTSHOTGUN;
      sound := Ord(sfx_wpnup);
    end;

    SPR_SGN2:
    begin
      if not P_GiveWeapon(player, wp_supershotgun,
        boolval(special.flags and MF_DROPPED)) then
        exit;
      player._message := GOTSHOTGUN2;
      sound := Ord(sfx_wpnup);
    end;

    else
      I_Error('P_TouchSpecialThing(): Unknown gettable thing');
  end;

  if boolval(special.flags and MF_COUNTITEM) then
    player.itemcount := player.itemcount + 1;
  P_RemoveMobj(special);
  player.bonuscount := player.bonuscount + BONUSADD;
  if player = @players[consoleplayer] then
    S_StartSound(nil, sound);
end;


// KillMobj

procedure P_KillMobj(Source: Pmobj_t; target: Pmobj_t);
var
  item: mobjtype_t;
  mo: Pmobj_t;
begin
  target.flags := target.flags and (not (MF_SHOOTABLE or MF_FLOAT or MF_SKULLFLY));

  if target._type <> MT_SKULL then
    target.flags := target.flags and (not MF_NOGRAVITY);

  target.flags := target.flags or (MF_CORPSE or MF_DROPOFF);
  target.Height := _SHR(target.Height, 2);

  if boolval(Source) and boolval(Source.player) then
  begin
    // count for intermission
    if boolval(target.flags and MF_COUNTKILL) then
      Pplayer_t(Source.player).killcount := Pplayer_t(Source.player).killcount + 1;

    if boolval(target.player) then
      Pplayer_t(Source.player).frags[pOperation(target.player, @players[0],
        '-', SizeOf(players[0]))] :=
        Pplayer_t(Source.player).frags[pOperation(target.player,
        @players[0], '-', SizeOf(players[0]))] + 1;
  end
  else if (not netgame) and boolval(target.flags and MF_COUNTKILL) then
  begin
    // count all monster deaths,
    // even those caused by other monsters
    players[0].killcount := players[0].killcount + 1;
  end;

  if target.player <> nil then
  begin
    // count environment kills against you
    if not boolval(Source) then
      Pplayer_t(target.player).frags[pOperation(target.player, @players[0],
        '-', SizeOf(players[0]))] :=
        Pplayer_t(target.player).frags[pOperation(target.player,
        @players[0], '-', SizeOf(players[0]))] + 1;

    target.flags := target.flags and not MF_SOLID;
    Pplayer_t(target.player).playerstate := PST_DEAD;
    P_DropWeapon(target.player);

    if (target.player = @players[consoleplayer]) and automapactive then
    begin
      // don't die in auto map,
      // switch view prior to dying
      AM_Stop;
    end;

  end;

  if (target.health < -target.info.spawnhealth) and boolval(target.info.xdeathstate) then
    P_SetMobjState(target, statenum_t(target.info.xdeathstate))
  else
    P_SetMobjState(target, statenum_t(target.info.deathstate));
  target.tics := target.tics - (P_Random and 3);

  if target.tics < 1 then
    target.tics := 1;

  //  I_StartSound (&actor->r, actor->info->deathsound);


  // Drop stuff.
  // This determines the kind of object spawned
  // during the death frame of a thing.
  case target._type of
    MT_WOLFSS,
    MT_POSSESSED:
      item := MT_CLIP;
    MT_SHOTGUY:
      item := MT_SHOTGUN;
    MT_CHAINGUY:
      item := MT_CHAINGUN;
    else
      exit;
  end;

  mo := P_SpawnMobj(target.x, target.y, ONFLOORZ, item);
  mo.flags := mo.flags or MF_DROPPED; // special versions of items
end;


// P_DamageMobj
// Damages both enemies and players
// "inflictor" is the thing that caused the damage
//  creature or missile, can be NULL (slime, etc)
// "source" is the thing to target after taking damage
//  creature or NULL
// Source and inflictor are the same for melee attacks.
// Source can be NULL for slime, barrel explosions
// and other environmental stuff.

procedure P_DamageMobj(target, inflictor, Source: Pmobj_t; damage: integer);
var
  ang: angle_t;
  saved: integer;
  player: Pplayer_t;
  thrust: fixed_t;
begin
  if not boolval(target.flags and MF_SHOOTABLE) then
    exit; // shouldn't happen...

  if target.health <= 0 then
    exit;

  if boolval(target.flags and MF_SKULLFLY) then
  begin
    target.momx := 0;
    target.momy := 0;
    target.momz := 0;
  end;

  player := target.player;
  if boolval(player) and (gameskill = sk_baby) then
    damage := _SHR(damage, 1); // take half damage in trainer mode


  // Some close combat weapons should not
  // inflict thrust and push the victim out of reach,
  // thus kick away unless using the chainsaw.
  if boolval(inflictor) and (not boolval(target.flags and MF_NOCLIP)) and
    (not boolval(Source) or (not boolval(Source.player)) or
    (Pplayer_t(Source.player).readyweapon <> wp_chainsaw)) then
  begin
    ang := R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y);

    thrust := (damage * (_SHR(FRACUNIT, 3)) * 100) div target.info.mass;

    // make fall forwards sometimes
    if (damage < 40) and (damage > target.health) and
      (target.z - inflictor.z > 64 * FRACUNIT) and boolval(P_Random and 1) then
    begin
      ang := ang + ANG180;
      thrust := thrust * 4;
    end;

    ang := _SHRW(ang, ANGLETOFINESHIFT);
    target.momx := target.momx + FixedMul(thrust, finecosine[ang]);
    target.momy := target.momy + FixedMul(thrust, finesine[ang]);
  end;

  // player specific
  if boolval(player) then
  begin
    // end of game hell hack
    if (Psubsector_t(target.subsector).sector.special = 11) and
      (damage >= target.health) then
      damage := target.health - 1;

    // Below certain threshold,
    // ignore damage in GOD mode, or with INVUL power.
    if (damage < 1000) and (boolval(player.cheats and CF_GODMODE) or
      boolval(player.powers[Ord(pw_invulnerability)])) then
      exit;

    if boolval(player.armortype) then
    begin
      if player.armortype = 1 then
        saved := damage div 3
      else
        saved := damage div 2;

      if player.armorpoints <= saved then
      begin
        // armor is used up
        saved := player.armorpoints;
        player.armortype := 0;
      end;
      player.armorpoints := player.armorpoints - saved;
      damage := damage - saved;
    end;
    player.health := player.health - damage;  // mirror mobj health here for Dave
    if player.health < 0 then
      player.health := 0;

    player.attacker := Source;
    player.damagecount := player.damagecount + damage;
    // add damage after armor / invuln

    if player.damagecount > 100 then
      player.damagecount := 100;  // teleport stomp does 10k points...

  end;

  // do the damage
  target.health := target.health - damage;
  if target.health <= 0 then
  begin
    P_KillMobj(Source, target);
    exit;
  end;

  if (P_Random < target.info.painchance) and
    (not boolval(target.flags and MF_SKULLFLY)) then
  begin
    target.flags := target.flags or MF_JUSTHIT; // fight back!
    P_SetMobjState(target, statenum_t(target.info.painstate));
  end;

  target.reactiontime := 0; // we're awake now...

  if ((not boolval(target.threshold)) or (target._type = MT_VILE)) and
    boolval(Source) and (Source <> target) and (Source._type <> MT_VILE) then
  begin
    // if not intent on another player,
    // chase after this one
    target.target := Source;
    target.threshold := BASETHRESHOLD;
    if (target.state = @states[target.info.spawnstate]) and
      (target.info.seestate <> Ord(S_NULL)) then
      P_SetMobjState(target, statenum_t(target.info.seestate));
  end;
end;

end.
