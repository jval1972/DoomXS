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

unit d_items;

interface

uses
  doomdef;

type
  { Weapon info: sprite frames, ammunition use. }
  weaponinfo_t = record
    ammo: ammotype_t;
    upstate: longint;
    downstate: longint;
    readystate: longint;
    atkstate: longint;
    flashstate: longint;
  end;

var
  weaponinfo: array[0..Ord(NUMWEAPONS)-1] of weaponinfo_t;

implementation

uses
  info_h;

initialization
//
// PSPRITE ACTIONS for waepons.
// This struct controls the weapon animations.
//
// Each entry is:
//   ammo/amunition type
//  upstate
//  downstate
// readystate
// atkstate, i.e. attack/fire/hit frame
// flashstate, muzzle flash
//

  // fist
  weaponinfo[0].ammo := am_noammo;
  weaponinfo[0].upstate := Ord(S_PUNCHUP);
  weaponinfo[0].downstate := Ord(S_PUNCHDOWN);
  weaponinfo[0].readystate := Ord(S_PUNCH);
  weaponinfo[0].atkstate := Ord(S_PUNCH1);
  weaponinfo[0].flashstate := Ord(S_NULL);

  // pistol
  weaponinfo[1].ammo := am_clip;
  weaponinfo[1].upstate := Ord(S_PISTOLUP);
  weaponinfo[1].downstate := Ord(S_PISTOLDOWN);
  weaponinfo[1].readystate := Ord(S_PISTOL);
  weaponinfo[1].atkstate := Ord(S_PISTOL1);
  weaponinfo[1].flashstate := Ord(S_PISTOLFLASH);

  // shotgun
  weaponinfo[2].ammo := am_shell;
  weaponinfo[2].upstate := Ord(S_SGUNUP);
  weaponinfo[2].downstate := Ord(S_SGUNDOWN);
  weaponinfo[2].readystate := Ord(S_SGUN);
  weaponinfo[2].atkstate := Ord(S_SGUN1);
  weaponinfo[2].flashstate := Ord(S_SGUNFLASH1);

  // chaingun
  weaponinfo[3].ammo := am_clip;
  weaponinfo[3].upstate := Ord(S_CHAINUP);
  weaponinfo[3].downstate := Ord(S_CHAINDOWN);
  weaponinfo[3].readystate := Ord(S_CHAIN);
  weaponinfo[3].atkstate := Ord(S_CHAIN1);
  weaponinfo[3].flashstate := Ord(S_CHAINFLASH1);

  // missile launcher
  weaponinfo[4].ammo := am_misl;
  weaponinfo[4].upstate := Ord(S_MISSILEUP);
  weaponinfo[4].downstate := Ord(S_MISSILEDOWN);
  weaponinfo[4].readystate := Ord(S_MISSILE);
  weaponinfo[4].atkstate := Ord(S_MISSILE1);
  weaponinfo[4].flashstate := Ord(S_MISSILEFLASH1);

  // plasma rifle
  weaponinfo[5].ammo := am_cell;
  weaponinfo[5].upstate := Ord(S_PLASMAUP);
  weaponinfo[5].downstate := Ord(S_PLASMADOWN);
  weaponinfo[5].readystate := Ord(S_PLASMA);
  weaponinfo[5].atkstate := Ord(S_PLASMA1);
  weaponinfo[5].flashstate := Ord(S_PLASMAFLASH1);

  // bfg 9000
  weaponinfo[6].ammo := am_cell;
  weaponinfo[6].upstate := Ord(S_BFGUP);
  weaponinfo[6].downstate := Ord(S_BFGDOWN);
  weaponinfo[6].readystate := Ord(S_BFG);
  weaponinfo[6].atkstate := Ord(S_BFG1);
  weaponinfo[6].flashstate := Ord(S_BFGFLASH1);

  // chainsaw
  weaponinfo[7].ammo := am_noammo;
  weaponinfo[7].upstate := Ord(S_SAWUP);
  weaponinfo[7].downstate := Ord(S_SAWDOWN);
  weaponinfo[7].readystate := Ord(S_SAW);
  weaponinfo[7].atkstate := Ord(S_SAW1);
  weaponinfo[7].flashstate := Ord(S_NULL);

  // super shotgun
  weaponinfo[8].ammo := am_shell;
  weaponinfo[8].upstate := Ord(S_DSGUNUP);
  weaponinfo[8].downstate := Ord(S_DSGUNDOWN);
  weaponinfo[8].readystate := Ord(S_DSGUN);
  weaponinfo[8].atkstate := Ord(S_DSGUN1);
  weaponinfo[8].flashstate := Ord(S_DSGUNFLASH1);

end.

