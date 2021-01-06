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

unit p_mobj_h;

interface

uses
  m_fixed,
  info_h,
  doomdata,
  tables,
  d_think;

const
  // Call P_SpecialThing when touched.
  MF_SPECIAL = 1;
  // Blocks.
  MF_SOLID = 2;
  // Can be hit.
  MF_SHOOTABLE = 4;
  // Don't use the sector links (invisible but touchable).
  MF_NOSECTOR = 8;
  // Don't use the blocklinks (inert but displayable)
  MF_NOBLOCKMAP = 16;

  // Not to be activated by sound, deaf monster.
  MF_AMBUSH = 32;
  // Will try to attack right back.
  MF_JUSTHIT = 64;
  // Will take at least one step before attacking.
  MF_JUSTATTACKED = 128;
  // On level spawning (initial position),
  //  hang from ceiling instead of stand on floor.
  MF_SPAWNCEILING = 256;
  // Don't apply gravity (every tic),
  //  that is, object will float, keeping current height
  //  or changing it actively.
  MF_NOGRAVITY = 512;

  // Movement flags.
  // This allows jumps from high places.
  MF_DROPOFF = $400;
  // For players, will pick up items.
  MF_PICKUP = $800;
  // Player cheat. ???
  MF_NOCLIP = $1000;
  // Player: keep info about sliding along walls.
  MF_SLIDE = $2000;
  // Allow moves to any height, no gravity.
  // For active floaters, e.g. cacodemons, pain elementals.
  MF_FLOAT = $4000;
  // Don't cross lines
  //   ??? or look at heights on teleport.
  MF_TELEPORT = $8000;
  // Don't hit same species, explode on block.
  // Player missiles as well as fireballs of various kinds.
  MF_MISSILE = $10000;
  // Dropped by a demon, not level spawned.
  // E.g. ammo clips dropped by dying former humans.
  MF_DROPPED = $20000;
  // Use fuzzy draw (shadow demons or spectres),
  //  temporary player invisibility powerup.
  MF_SHADOW = $40000;
  // Flag: don't bleed when shot (use puff),
  //  barrels and shootable furniture shall not bleed.
  MF_NOBLOOD = $80000;
  // Don't stop moving halfway off a step,
  //  that is, have dead bodies slide down all the way.
  MF_CORPSE = $100000;
  // Floating to a height for a move, ???
  //  don't auto float to target's height.
  MF_INFLOAT = $200000;

  // On kill, count this enemy object
  //  towards intermission kill total.
  // Happy gathering.
  MF_COUNTKILL = $400000;

  // On picking up, count this item object
  //  towards intermission item total.
  MF_COUNTITEM = $800000;

  // Special handling: skull in flight.
  // Neither a cacodemon nor a missile.
  MF_SKULLFLY = $1000000;

  // Don't spawn this object
  //  in death match mode (e.g. key cards).
  MF_NOTDMATCH = $2000000;

  // Player sprites in multiplayer modes are modified
  //  using an internal color lookup table for re-indexing.
  // If 0x4 0x8 or 0xc,
  //  use a translation table for player colormaps
  MF_TRANSLATION = $c000000;
  // Hmm ???.
  MF_TRANSSHIFT = 26;

type
  // Map Object definition.
  Pmobj_t = ^mobj_t;

  mobj_t = record
    // List: thinker links.
    thinker: thinker_t;

    // Info for drawing: position.
    x: fixed_t;
    y: fixed_t;
    z: fixed_t;

    // More list: links in sector (if needed)
    snext: Pmobj_t;
    sprev: Pmobj_t;

    //More drawing info: to determine current sprite.
    angle: angle_t; // orientation
    sprite: spritenum_t; // used to find patch_t and flip value
    frame: integer; // might be ORed with FF_FULLBRIGHT

    // Interaction info, by BLOCKMAP.
    // Links in blocks (if needed).
    bnext: Pmobj_t;
    bprev: Pmobj_t;

    subsector: pointer; //Psubsector_t;

    // The closest interval over all contacted Sectors.
    floorz: fixed_t;
    ceilingz: fixed_t;

    // For movement checking.
    radius: fixed_t;
    Height: fixed_t;

    // Momentums, used to update position.
    momx: fixed_t;
    momy: fixed_t;
    momz: fixed_t;

    // If == validcount, already checked.
    validcount: integer;

    _type: mobjtype_t;
    info: Pmobjinfo_t; // &mobjinfo[mobj->type]

    tics: integer; // state tic counter
    state: Pstate_t;
    flags: integer;
    health: integer;

    // Movement direction, movement generation (zig-zagging).
    movedir: integer; // 0-7
    movecount: integer; // when 0, select a new dir

    // Thing being chased/attacked (or NULL),
    // also the originator for missiles.
    target: Pmobj_t;

    // Reaction time: if non 0, don't attack yet.
    // Used by player to freeze a bit after teleporting.
    reactiontime: integer;

    // If >0, the target will be chased
    // no matter what (even if shot)
    threshold: integer;

    // Additional info record for player avatars only.
    // Only valid if type == MT_PLAYER
    player: pointer; //Pplayer_t;

    // Player number last looked for.
    lastlook: integer;

    // For nightmare respawn.
    spawnpoint: mapthing_t;

    // Thing being chased/attacked for tracers.
    tracer: Pmobj_t;
  end;
  Tmobj_tPArray = array[0..$FFFF] of Pmobj_t;
  Pmobj_tPArray = ^Tmobj_tPArray;

implementation

end.
