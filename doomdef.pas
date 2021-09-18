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

unit doomdef;

interface

//
// Global parameters/defines.
//
// DOOM version
const
  VERSION = 109;

type
// Game mode handling - identify IWAD version
//  to handle IWAD dependend animations etc.
  GameMode_t = (
    shareware,   // DOOM 1 shareware, E1, M9
    registered,  // DOOM 1 registered, E3, M27
    commercial,  // DOOM 2 retail, E1 M34
    ///////////  // DOOM 2 german edition not handled
    retail,      // DOOM 1 retail, E4, M36
    indetermined // Well, no IWAD found.
  );

// Mission packs - might be useful for TC stuff?
  GameMission_t = (
    doom,       // DOOM 1
    doom2,      // DOOM 2
    pack_tnt,   // TNT mission pack
    pack_plut,  // Plutonia pack
    none
  );

// Identify language to use, software localization.
  Language_t = (
    english,
    french,
    german,
    unknown
  );

const
  SCREENWIDTH = 640;
  SCREENHEIGHT = 400;

const
// The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4;

// State updates, number of tics / second.
  TICRATE = 35;

// The current state of the game: whether we are
// playing, gazing at the intermission screen,
// the game final animation, or a demo.
type
  gamestate_t = (
    GS_LEVEL,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN
  );

const
// Difficulty/skill settings/filters.

// Skill flags.
  MTF_EASY = 1;
  MTF_NORMAL = 2;
  MTF_HARD = 4;

// Deaf monsters/do not react to sound.
  MTF_AMBUSH = 8;

type
  skill_t = (
    sk_baby,
    sk_easy,
    sk_medium,
    sk_hard,
    sk_nightmare
  );

// Key cards.
  card_t = (
    it_bluecard,
    it_yellowcard,
    it_redcard,
    it_blueskull,
    it_yellowskull,
    it_redskull,
    NUMCARDS
  );

// The defined weapons,
//  including a marker indicating
//  user has not changed weapon.
  weapontype_t = (
    wp_fist,
    wp_pistol,
    wp_shotgun,
    wp_chaingun,
    wp_missile,
    wp_plasma,
    wp_bfg,
    wp_chainsaw,
    wp_supershotgun,
    NUMWEAPONS,
    // No pending weapon change.
    wp_nochange
  );

// Ammunition types defined.
  ammotype_t = (
    am_clip,  // Pistol / chaingun ammo.
    am_shell, // Shotgun / double barreled shotgun.
    am_cell,  // Plasma rifle, BFG.
    am_misl,  // Missile launcher.
    NUMAMMO,
    am_noammo // Unlimited for chainsaw / fist.
  );

// Power up artifacts.
  powertype_t = (
    pw_invulnerability,
    pw_strength,
    pw_invisibility,
    pw_ironfeet,
    pw_allmap,
    pw_infrared,
    NUMPOWERS
  );
  Ppowertype_t = ^powertype_t;

//
// Power up durations,
//  how many seconds till expiration,
//  assuming TICRATE is 35 ticks/second.
//
const
  INVULNTICS = 30 * TICRATE;
  INVISTICS = 60 * TICRATE;
  INFRATICS = 120 * TICRATE;
  IRONTICS = 60 * TICRATE;

// DOOM keyboard definition.
// This is the stuff configured by Setup.Exe.
// Most key data are simple ascii (uppercased).
const
  KEY_RIGHTARROW = $ae;
  KEY_LEFTARROW = $ac;
  KEY_UPARROW = $ad;
  KEY_DOWNARROW = $af;
  KEY_ESCAPE = 27;
  KEY_ENTER = 13;
  KEY_TAB = 9;

  KEY_F1 = $80 + $3b;
  KEY_F2 = $80 + $3c;
  KEY_F3 = $80 + $3d;
  KEY_F4 = $80 + $3e;
  KEY_F5 = $80 + $3f;
  KEY_F6 = $80 + $40;
  KEY_F7 = $80 + $41;
  KEY_F8 = $80 + $42;
  KEY_F9 = $80 + $43;
  KEY_F10 = $80 + $44;
  KEY_F11 = $80 + $57;
  KEY_F12 = $80 + $58;

  KEY_BACKSPACE = 127;
  KEY_PAUSE = $ff;

  KEY_EQUALS = $3d;
  KEY_MINUS = $2d;

  KEY_RSHIFT = $80 + $36;
  KEY_RCTRL = $80 + $1d;
  KEY_RALT = $80 + $38;

  KEY_PAGEDOWN = $80 + $45;
  KEY_PAGEUP = $80 + $46;
  KEY_INS = $80 + $47;

implementation

end.
