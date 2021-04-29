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

unit p_mobj;

interface

uses
  p_mobj_h,
  doomdata,
  info_h,
  m_fixed;

function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;

procedure P_MobjThinker(mobj: Pmobj_t);

function P_SpawnMobj(x, y, z: fixed_t; _type: mobjtype_t): Pmobj_t;

procedure P_RemoveMobj(mobj: Pmobj_t);

procedure P_SpawnPlayer(mthing: Pmapthing_t);

procedure P_SpawnMapThing(mthing: Pmapthing_t);

procedure P_SpawnPuff(x, y, z: fixed_t);

function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: mobjtype_t): Pmobj_t;

procedure P_SpawnPlayerMissile(source: Pmobj_t; _type: mobjtype_t);

procedure P_RespawnSpecials;

procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer);

var
  iquehead: integer; // Initialized at p_setup
  iquetail: integer; // Initialized at p_setup

implementation

uses
  d_delphi,
  d_player,
  d_think,
  d_main,
  tables,
  g_game,
  i_system,
  z_memory,
  m_rnd,
  doomdef,
  p_local,
  p_map,
  p_maputl,
  p_tick,
  p_pspr,
  p_setup,
  r_defs,
  r_sky,
  r_main,
  sounds,
  st_stuff,
  hu_stuff,
  s_sound,
  info,
  doomstat;


// P_SetMobjState
// Returns true if the mobj is still present.
function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;
var
  st: Pstate_t;
begin
  repeat
    if state = S_NULL then
    begin
      mobj.state := @states[Ord(S_NULL)];
      P_RemoveMobj(mobj);
      Result := False;
      exit;
    end;

    st := @states[Ord(state)];
    mobj.state := st;
    mobj.tics := st.tics;
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;

    // Modified handling.
    // Call action functions when the state is set
    if Assigned(st.action.acp1) then
      st.action.acp1(mobj);

    state := st.nextstate;
  until mobj.tics <> 0;

  Result := True;
end;

// P_ExplodeMissile
procedure P_ExplodeMissile(mo: Pmobj_t);
begin
  mo.momx := 0;
  mo.momy := 0;
  mo.momz := 0;

  P_SetMobjState(mo, statenum_t(mobjinfo[Ord(mo._type)].deathstate));

  mo.tics := mo.tics - (P_Random and 3);

  if mo.tics < 1 then
    mo.tics := 1;

  mo.flags := mo.flags and not MF_MISSILE;

  if mo.info.deathsound <> 0 then
    S_StartSound(mo, mo.info.deathsound);
end;

// P_XYMovement
const
  STOPSPEED = $1000;
  FRICTION = $e800;

procedure P_XYMovement(mo: Pmobj_t);
var
  ptryx: fixed_t;
  ptryy: fixed_t;
  player: Pplayer_t;
  xmove: fixed_t;
  ymove: fixed_t;
begin
  if mo.momx or mo.momy = 0 then
  begin
    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.flags := mo.flags and not MF_SKULLFLY;
      mo.momx := 0;
      mo.momy := 0;
      mo.momz := 0;

      P_SetMobjState(mo, statenum_t(mo.info.spawnstate));
    end;
    exit;
  end;

  player := mo.player;

  if mo.momx > MAXMOVE then
    mo.momx := MAXMOVE
  else if mo.momx < -MAXMOVE then
    mo.momx := -MAXMOVE;

  if mo.momy > MAXMOVE then
    mo.momy := MAXMOVE
  else if mo.momy < -MAXMOVE then
    mo.momy := -MAXMOVE;

  xmove := mo.momx;
  ymove := mo.momy;

  repeat
    if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) then
    begin
      ptryx := mo.x + xmove div 2;
      ptryy := mo.y + ymove div 2;
      xmove := _SHR(xmove, 1);
      ymove := _SHR(ymove, 1);
    end
    else
    begin
      ptryx := mo.x + xmove;
      ptryy := mo.y + ymove;
      xmove := 0;
      ymove := 0;
    end;

    if not P_TryMove(mo, ptryx, ptryy) then
    begin
      // blocked move
      if mo.player <> nil then
      begin // try to slide along it
        P_SlideMove(mo);
      end
      else if (mo.flags and MF_MISSILE) <> 0 then
      begin
        // explode a missile
        if (ceilingline <> nil) and (ceilingline.backsector <> nil) and
          (ceilingline.backsector.ceilingpic = skyflatnum) then
        begin
          // Hack to prevent missiles exploding
          // against the sky.
          // Does not handle sky floors.
          P_RemoveMobj(mo);
          exit;
        end;
        P_ExplodeMissile(mo);
      end
      else
      begin
        mo.momx := 0;
        mo.momy := 0;
      end;
    end;
  until (xmove = 0) and (ymove = 0);

  // slow down
  if (player <> nil) and ((player.cheats and CF_NOMOMENTUM) <> 0) then
  begin
    // debug option for no sliding at all
    mo.momx := 0;
    mo.momy := 0;
    exit;
  end;

  if (mo.flags and (MF_MISSILE or MF_SKULLFLY)) <> 0 then
    exit; // no friction for missiles ever

  if mo.z > mo.floorz then
    exit; // no friction when airborne

  if mo.flags and MF_CORPSE <> 0 then
  begin
    // do not stop sliding
    //  if halfway off a step with some momentum
    if (mo.momx > FRACUNIT div 4) or (mo.momx < -FRACUNIT div 4) or
      (mo.momy > FRACUNIT div 4) or (mo.momy < -FRACUNIT div 4) then
    begin
      if mo.floorz <> Psubsector_t(mo.subsector).sector.floorheight then
        exit;
    end;
  end;

  if (mo.momx > -STOPSPEED) and (mo.momx < STOPSPEED) and
    (mo.momy > -STOPSPEED) and (mo.momy < STOPSPEED) and
    ((player = nil) or ((player.cmd.forwardmove = 0) and
    (player.cmd.sidemove = 0))) then
  begin
    // if in a walking frame, stop moving
    if (player <> nil) and (LongWord(
      (pOperation(player.mo.state, @states[0], '-', SizeOf(states[0]))) -
      Ord(S_PLAY_RUN1)) < 4) then
      P_SetMobjState(player.mo, S_PLAY);

    mo.momx := 0;
    mo.momy := 0;
  end
  else
  begin
    mo.momx := FixedMul(mo.momx, FRICTION);
    mo.momy := FixedMul(mo.momy, FRICTION);
  end;
end;

// P_ZMovement
procedure P_ZMovement(mo: Pmobj_t);
var
  dist: fixed_t;
  delta: fixed_t;
  plyr: Pplayer_t;
begin
  // check for smooth step up
  plyr := mo.player;
  if (plyr <> nil) and (mo.z < mo.floorz) then
  begin
    plyr.viewheight := plyr.viewheight - (mo.floorz - mo.z);
    plyr.deltaviewheight := _SHR((PVIEWHEIGHT - plyr.viewheight), 3);
  end;

  // adjust height
  mo.z := mo.z + mo.momz;

  if (mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin
    // float down towards target if too close
    if (mo.flags and MF_SKULLFLY = 0) and
      (mo.flags and MF_INFLOAT = 0) then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);

      delta := (mo.target.z + _SHR(mo.height, 1)) - mo.z;

      if (delta < 0) and (dist < -(delta * 3)) then
        mo.z := mo.z - FLOATSPEED
      else if (delta > 0) and (dist < (delta * 3)) then
        mo.z := mo.z + FLOATSPEED;
    end;
  end;

  // clip movement
  if mo.z <= mo.floorz then
  begin
    // hit the floor

    // Note (id):
    //  somebody left this after the setting momz to 0,
    //  kinda useless there.
    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.momz := -mo.momz;
    end;

    if mo.momz < 0 then
    begin
      if (plyr <> nil) and (mo.momz < -GRAVITY * 8) then
      begin
        // Squat down.
        // Decrease viewheight for a moment
        // after hitting the ground (hard),
        // and utter appropriate sound.
        plyr.deltaviewheight := _SHR(mo.momz, 3);
        S_StartSound(mo, Ord(sfx_oof));
      end;
      mo.momz := 0;
    end;
    mo.z := mo.floorz;

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and MF_NOCLIP = 0) then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;
  end
  else if mo.flags and MF_NOGRAVITY = 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -GRAVITY * 2
    else
      mo.momz := mo.momz - GRAVITY;
  end;

  if mo.z + mo.height > mo.ceilingz then
  begin
    // hit the ceiling
    if mo.momz > 0 then
      mo.momz := 0;

    mo.z := mo.ceilingz - mo.height;

    if mo.flags and MF_SKULLFLY <> 0 then
      mo.momz := -mo.momz; // the skull slammed into something

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and MF_NOCLIP = 0) then
      P_ExplodeMissile(mo);
  end;
end;

// P_NightmareRespawn
procedure P_NightmareRespawn(mobj: Pmobj_t);
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psubsector_t;
  mo: Pmobj_t;
  mthing: Pmapthing_t;
begin
  x := mobj.spawnpoint.x * FRACUNIT;
  y := mobj.spawnpoint.y * FRACUNIT;

  // somthing is occupying it's position?
  if not P_CheckPosition(mobj, x, y) then
    exit; // no respwan

  // spawn a teleport fog at old spot
  // because of removal of the body?
  mo := P_SpawnMobj(mobj.x, mobj.y, Psubsector_t(mobj.subsector).sector.floorheight,
    MT_TFOG);
  // initiate teleport sound
  S_StartSound(mo, Ord(sfx_telept));

  // spawn a teleport fog at the new spot
  ss := R_PointInSubsector(x, y);

  mo := P_SpawnMobj(x, y, ss.sector.floorheight, MT_TFOG);

  S_StartSound(mo, Ord(sfx_telept));

  // spawn the new monster
  mthing := @mobj.spawnpoint;

  // spawn it
  if mobj.info.flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else
    z := ONFLOORZ;

  // inherit attributes from deceased one
  mo := P_SpawnMobj(x, y, z, mobj._type);
  mo.spawnpoint := mobj.spawnpoint;
  mo.angle := ANG45 * (mthing.angle div 45);

  if mthing.options and MTF_AMBUSH <> 0 then
    mo.flags := mo.flags or MF_AMBUSH;

  mo.reactiontime := 18;

  // remove the old monster,
  P_RemoveMobj(mobj);
end;

// P_MobjThinker
procedure P_MobjThinker(mobj: Pmobj_t);
begin
  // momentum movement
  if (mobj.momx <> 0) or (mobj.momy <> 0) or
    (mobj.flags and MF_SKULLFLY <> 0) then
  begin
    P_XYMovement(mobj);

    if not Assigned(mobj.thinker._function.acv) then
      exit; // mobj was removed
  end;

  if (mobj.z <> mobj.floorz) or (mobj.momz <> 0) then
  begin
    P_ZMovement(mobj);

    if not Assigned(mobj.thinker._function.acv) then
      exit; // mobj was removed
  end;


  // cycle through states,
  // calling action functions at transitions
  if mobj.tics <> -1 then
  begin
    mobj.tics := mobj.tics - 1;

    // you can cycle through multiple states in a tic
    if mobj.tics = 0 then
      if not P_SetMobjState(mobj, mobj.state.nextstate) then
        exit; // freed itself
  end
  else
  begin
    // check for nightmare respawn
    if mobj.flags and MF_COUNTKILL = 0 then
      exit;

    if not respawnmonsters then
      exit;

    mobj.movecount := mobj.movecount + 1;

    if mobj.movecount < 12 * TICRATE then
      exit;

    if leveltime and 31 <> 0 then
      exit;

    if P_Random > 4 then
      exit;

    P_NightmareRespawn(mobj);
  end;
end;

// P_SpawnMobj
function P_SpawnMobj(x, y, z: fixed_t; _type: mobjtype_t): Pmobj_t;
var
  mobj: Pmobj_t;
  st: Pstate_t;
  info: Pmobjinfo_t;
begin
  mobj := Z_Malloc(SizeOf(mobj^), PU_LEVEL, nil);
  memset(mobj, 0, SizeOf(mobj^));
  info := @mobjinfo[Ord(_type)];

  mobj._type := _type;
  mobj.info := info;
  mobj.x := x;
  mobj.y := y;
  mobj.radius := info.radius;
  mobj.height := info.height;
  mobj.flags := info.flags;
  mobj.health := info.spawnhealth;

  if gameskill <> sk_nightmare then
    mobj.reactiontime := info.reactiontime;

  mobj.lastlook := P_Random mod MAXPLAYERS;
  // do not set the state with P_SetMobjState,
  // because action routines can not be called yet
  st := @states[info.spawnstate];

  mobj.state := st;
  mobj.tics := st.tics;
  mobj.sprite := st.sprite;
  mobj.frame := st.frame;

  // set subsector and/or block links
  P_SetThingPosition(mobj);

  mobj.floorz := Psubsector_t(mobj.subsector).sector.floorheight;
  mobj.ceilingz := Psubsector_t(mobj.subsector).sector.ceilingheight;

  if z = ONFLOORZ then
    mobj.z := mobj.floorz
  else if z = ONCEILINGZ then
    mobj.z := mobj.ceilingz - mobj.info.height
  else
    mobj.z := z;
  @mobj.thinker._function.acp1 := @P_MobjThinker;

  P_AddThinker(@mobj.thinker);

  Result := mobj;
end;

// P_RemoveMobj
var
  itemrespawnque: array[0..ITEMQUESIZE - 1] of mapthing_t;
  itemrespawntime: array[0..ITEMQUESIZE - 1] of integer;

procedure P_RemoveMobj(mobj: Pmobj_t);
begin
  if (mobj.flags and MF_SPECIAL <> 0) and
    (mobj.flags and MF_DROPPED = 0) and (mobj._type <> MT_INV) and
    (mobj._type <> MT_INS) then
  begin
    itemrespawnque[iquehead] := mobj.spawnpoint;
    itemrespawntime[iquehead] := leveltime;
    iquehead := (iquehead + 1) and (ITEMQUESIZE - 1);

    // lose one off the end?
    if iquehead = iquetail then
      iquetail := (iquetail + 1) and (ITEMQUESIZE - 1);
  end;

  // unlink from sector and block lists
  P_UnsetThingPosition(mobj);

  // stop any playing sound
  S_StopSound(mobj);

  // free block
  P_RemoveThinker(Pthinker_t(mobj));
end;

// P_RespawnSpecials
procedure P_RespawnSpecials;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psubsector_t;
  mo: Pmobj_t;
  mthing: Pmapthing_t;
  i: integer;
begin
  // only respawn items in deathmatch
  if deathmatch <> 2 then
    exit;

  // nothing left to respawn?
  if iquehead = iquetail then
    exit;

  // wait at least 30 seconds
  if leveltime - itemrespawntime[iquetail] < 30 * TICRATE then
    exit;

  mthing := @itemrespawnque[iquetail];

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  // spawn a teleport fog at the new spot
  ss := R_PointInSubsector(x, y);
  mo := P_SpawnMobj(x, y, ss.sector.floorheight, MT_IFOG);
  S_StartSound(mo, Ord(sfx_itmbk));

  // find which type to spawn
  i := 0;
  while i < Ord(NUMMOBJTYPES) do
  begin
    if mthing._type = mobjinfo[i].doomednum then
      break;
    Inc(i);
  end;

  // spawn it
  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else
    z := ONFLOORZ;

  mo := P_SpawnMobj(x, y, z, mobjtype_t(i));
  mo.spawnpoint := mthing^;
  mo.angle := ANG45 * (mthing.angle div 45);

  // pull it from the que
  iquetail := (iquetail + 1) and (ITEMQUESIZE - 1);
end;


// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.

procedure P_SpawnPlayer(mthing: Pmapthing_t);
var
  p: Pplayer_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  mobj: Pmobj_t;
  i: integer;
begin
  // not playing?
  if not playeringame[mthing._type - 1] then
    exit;

  p := @players[mthing._type - 1];

  if p.playerstate = PST_REBORN then
    G_PlayerReborn(mthing._type - 1);

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;
  z := ONFLOORZ;
  mobj := P_SpawnMobj(x, y, z, MT_PLAYER);

  // set color translations for player sprites
  if mthing._type > 1 then
    mobj.flags := mobj.flags or _SHL(mthing._type - 1, MF_TRANSSHIFT);

  mobj.angle := ANG45 * (mthing.angle div 45);
  mobj.player := p;
  mobj.health := p.health;

  p.mo := mobj;
  p.playerstate := PST_LIVE;
  p.refire := 0;
  p.msg := '';
  p.damagecount := 0;
  p.bonuscount := 0;
  p.extralight := 0;
  p.fixedcolormap := 0;
  p.viewheight := PVIEWHEIGHT;

  // setup gun psprite
  P_SetupPsprites(p);

  // give all cards in death match mode
  if deathmatch <> 0 then
    for i := 0 to Ord(NUMCARDS) - 1 do
      p.cards[i] := True;

  if mthing._type - 1 = consoleplayer then
  begin
    // wake up the status bar
    ST_Start;
    // wake up the heads up text
    HU_Start;
  end;
end;


// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.

procedure P_SpawnMapThing(mthing: Pmapthing_t);
var
  i: integer;
  bit: integer;
  mobj: Pmobj_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
begin
  // count deathmatch start positions
  if mthing._type = 11 then
  begin
    if deathmatch_p < MAX_DEATHMATCH_STARTS then
    begin
      memcpy(@deathmatchstarts[deathmatch_p], mthing, SizeOf(mthing^));
      Inc(deathmatch_p);
    end;
    exit;
  end;

  // check for players specially
  if mthing._type <= 4 then
  begin
    // save spots for respawning in network games
    playerstarts[mthing._type - 1] := mthing^;
    if deathmatch = 0 then
      P_SpawnPlayer(mthing);
    exit;
  end;

  // check for apropriate skill level
  if not netgame and (mthing.options and 16 <> 0) then
    exit;

  if gameskill = sk_baby then
    bit := 1
  else if gameskill = sk_nightmare then
    bit := 4
  else
    bit := _SHL(1, Ord(gameskill) - 1);

  if mthing.options and bit = 0 then
    exit;

  // find which type to spawn
  i := 0;
  while i < Ord(NUMMOBJTYPES) do
  begin
    if mthing._type = mobjinfo[i].doomednum then
      break;
    Inc(i);
  end;

  if i = Ord(NUMMOBJTYPES) then
    I_Error('P_SpawnMapThing(): Unknown type %d at (%d, %d)',
      [mthing._type, mthing.x, mthing.y]);

  // don't spawn keycards and players in deathmatch
  if (deathmatch <> 0) and (mobjinfo[i].flags and MF_NOTDMATCH <> 0) then
    exit;

  // don't spawn any monsters if -nomonsters
  if nomonsters and ((i = Ord(MT_SKULL)) or
    (mobjinfo[i].flags and MF_COUNTKILL <> 0)) then
    exit;

  // spawn it
  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else
    z := ONFLOORZ;

  mobj := P_SpawnMobj(x, y, z, mobjtype_t(i));
  mobj.spawnpoint := mthing^;

  if mobj.tics > 0 then
    mobj.tics := 1 + (P_Random mod mobj.tics);
  if mobj.flags and MF_COUNTKILL <> 0 then
    Inc(totalkills);
  if mobj.flags and MF_COUNTITEM <> 0 then
    Inc(totalitems);

  mobj.angle := ANG45 * (mthing.angle div 45);
  if mthing.options and MTF_AMBUSH <> 0 then
    mobj.flags := mobj.flags or MF_AMBUSH;
end;

// GAME SPAWN FUNCTIONS

// P_SpawnPuff
procedure P_SpawnPuff(x, y, z: fixed_t);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);

  th := P_SpawnMobj(x, y, z, MT_PUFF);
  th.momz := FRACUNIT;
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  // don't make punches spark on the wall
  if attackrange = MELEERANGE then
    P_SetMobjState(th, S_PUFF3);
end;


// P_SpawnBlood
procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);
  th := P_SpawnMobj(x, y, z, MT_BLOOD);
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if (damage <= 12) and (damage >= 9) then
    P_SetMobjState(th, S_BLOOD2)
  else if damage < 9 then
    P_SetMobjState(th, S_BLOOD3);
end;


// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
procedure P_CheckMissileSpawn(th: Pmobj_t);
begin
  th.tics := th.tics - (P_Random and 3);
  if th.tics < 1 then
    th.tics := 1;

  // move a little forward so an angle can
  // be computed if it immediately explodes
  th.x := th.x + _SHR(th.momx, 1);
  th.y := th.y + _SHR(th.momy, 1);
  th.z := th.z + _SHR(th.momz, 1);

  if not P_TryMove(th, th.x, th.y) then
    P_ExplodeMissile(th);
end;


// P_SpawnMissile
function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: mobjtype_t): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  th := P_SpawnMobj(source.x, source.y, source.z + 4 * 8 * FRACUNIT, _type);

  if th.info.seesound <> 0 then
    S_StartSound(th, th.info.seesound);

  th.target := source;  // where it came from
  an := R_PointToAngle2(source.x, source.y, dest.x, dest.y);

  // fuzzy player
  if dest.flags and MF_SHADOW <> 0 then
    an := an + _SHLW(P_Random - P_Random, 20);

  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  th.momx := FixedMul(th.info.speed, finecosine[an]);
  th.momy := FixedMul(th.info.speed, finesine[an]);

  dist := P_AproxDistance(dest.x - source.x, dest.y - source.y);
  dist := dist div th.info.speed;

  if dist < 1 then
    dist := 1;

  th.momz := (dest.z - source.z) div dist;
  P_CheckMissileSpawn(th);

  Result := th;
end;


// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
procedure P_SpawnPlayerMissile(source: Pmobj_t; _type: mobjtype_t);
var
  th: Pmobj_t;
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);
    end;

    if linetarget = nil then
    begin
      an := source.angle;
      slope := 0;
    end;
  end;

  x := source.x;
  y := source.y;
  z := source.z + 4 * 8 * FRACUNIT;

  th := P_SpawnMobj(x, y, z, _type);

  if th.info.seesound <> 0 then
    S_StartSound(th, th.info.seesound);

  th.target := source;

  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  th.momx := FixedMul(th.info.speed, finecosine[an]);
  th.momy := FixedMul(th.info.speed, finesine[an]);
  th.momz := FixedMul(th.info.speed, slope);

  P_CheckMissileSpawn(th);
end;

end.
