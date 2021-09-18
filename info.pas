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

unit info;

interface

uses
  d_think,
  info_h;

type
  statesArray_t = packed array[0..ord(NUMSTATES) - 1] of state_t;
  PstatesArray_t = ^statesArray_t;

  sprnamesArray_t = packed array[0..ord(NUMSPRITES) - 1] of string[4];
  PsprnamesArray_t = ^sprnamesArray_t;

  mobjinfoArray_t = packed array[0..ord(NUMMOBJTYPES) - 1] of mobjinfo_t;
  PmobjinfoArray_t = ^mobjinfoArray_t;

var
  states: PstatesArray_t;
  sprnames: PsprnamesArray_t;
  mobjinfo: PmobjinfoArray_t;

procedure I_InitInfo;

implementation

uses
  m_fixed,
  p_enemy,
  p_pspr,
  p_mobj_h,
  sounds;

var
  states1: array[0..ord(NUMSTATES) - 1] of state_t = (
   (
    sprite: SPR_TROO;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_NULL

   (
    sprite: SPR_SHTG;         // sprite
    frame: 4;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_LIGHTDONE

   (
    sprite: SPR_PUNG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCH

   (
    sprite: SPR_PUNG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCHDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCHDOWN

   (
    sprite: SPR_PUNG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCHUP;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCHUP

   (
    sprite: SPR_PUNG;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCH1

   (
    sprite: SPR_PUNG;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCH2

   (
    sprite: SPR_PUNG;         // sprite
    frame: 3;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCH3

   (
    sprite: SPR_PUNG;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH5;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCH4

   (
    sprite: SPR_PUNG;         // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUNCH5

   (
    sprite: SPR_PISG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0),                // S_PISTOL  // misc2

   (
    sprite: SPR_PISG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOLDOWN;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PISTOLDOWN

   (
    sprite: SPR_PISG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOLUP;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PISTOLUP

   (
    sprite: SPR_PISG;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PISTOL1

   (
    sprite: SPR_PISG;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0),                // S_PISTOL2  // misc2

   (
    sprite: SPR_PISG;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL4;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PISTOL3

   (
    sprite: SPR_PISG;         // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PISTOL4

   (
    sprite: SPR_PISF;         // sprite
    frame: 32768;             // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PISTOLFLASH

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUNDOWN;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUNDOWN

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUNUP;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUNUP

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN1

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN2

   (
    sprite: SPR_SHTG;         // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN3

   (
    sprite: SPR_SHTG;         // sprite
    frame: 2;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN4

   (
    sprite: SPR_SHTG;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN5

   (
    sprite: SPR_SHTG;         // sprite
    frame: 2;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN7;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN6

   (
    sprite: SPR_SHTG;         // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN8;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN7

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN9;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN8

   (
    sprite: SPR_SHTG;         // sprite
    frame: 0;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUN9

   (
    sprite: SPR_SHTF;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUNFLASH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUNFLASH1

   (
    sprite: SPR_SHTF;         // sprite
    frame: 32769;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SGUNFLASH2

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUNDOWN

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNUP;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUNUP

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN1

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN2

   (
    sprite: SPR_SHT2;         // sprite
    frame: 1;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN3

   (
    sprite: SPR_SHT2;         // sprite
    frame: 2;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN5;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN4

   (
    sprite: SPR_SHT2;         // sprite
    frame: 3;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN6;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN5

   (
    sprite: SPR_SHT2;         // sprite
    frame: 4;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN7;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN6

   (
    sprite: SPR_SHT2;         // sprite
    frame: 5;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN8;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN7

   (
    sprite: SPR_SHT2;         // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN9;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN8

   (
    sprite: SPR_SHT2;         // sprite
    frame: 7;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN10;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN9

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUN10

   (
    sprite: SPR_SHT2;         // sprite
    frame: 1;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSNR2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSNR1

   (
    sprite: SPR_SHT2;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSNR2

   (
    sprite: SPR_SHT2;         // sprite
    frame: 32776;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNFLASH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUNFLASH1

   (
    sprite: SPR_SHT2;         // sprite
    frame: 32777;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DSGUNFLASH2

   (
    sprite: SPR_CHGG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAIN

   (
    sprite: SPR_CHGG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAINDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAINDOWN

   (
    sprite: SPR_CHGG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAINUP;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAINUP

   (
    sprite: SPR_CHGG;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAIN1

   (
    sprite: SPR_CHGG;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAIN2

   (
    sprite: SPR_CHGG;         // sprite
    frame: 1;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAIN3

   (
    sprite: SPR_CHGF;         // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAINFLASH1

   (
    sprite: SPR_CHGF;         // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CHAINFLASH2

   (
    sprite: SPR_MISG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILE

   (
    sprite: SPR_MISG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEDOWN;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILEDOWN

   (
    sprite: SPR_MISG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEUP;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILEUP

   (
    sprite: SPR_MISG;         // sprite
    frame: 1;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILE1

   (
    sprite: SPR_MISG;         // sprite
    frame: 1;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILE2

   (
    sprite: SPR_MISG;         // sprite
    frame: 1;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILE3

   (
    sprite: SPR_MISF;         // sprite
    frame: 32768;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEFLASH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILEFLASH1

   (
    sprite: SPR_MISF;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEFLASH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILEFLASH2

   (
    sprite: SPR_MISF;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEFLASH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILEFLASH3

   (
    sprite: SPR_MISF;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MISSILEFLASH4

   (
    sprite: SPR_SAWG;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAWB;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAW

   (
    sprite: SPR_SAWG;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAWB

   (
    sprite: SPR_SAWG;         // sprite
    frame: 2;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAWDOWN;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAWDOWN

   (
    sprite: SPR_SAWG;         // sprite
    frame: 2;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAWUP;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAWUP

   (
    sprite: SPR_SAWG;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAW1

   (
    sprite: SPR_SAWG;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW3;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAW2

   (
    sprite: SPR_SAWG;         // sprite
    frame: 1;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SAW3

   (
    sprite: SPR_PLSG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMA;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMA

   (
    sprite: SPR_PLSG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMADOWN;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMADOWN

   (
    sprite: SPR_PLSG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMAUP;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMAUP

   (
    sprite: SPR_PLSG;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMA2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMA1

   (
    sprite: SPR_PLSG;         // sprite
    frame: 1;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMA;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMA2

   (
    sprite: SPR_PLSF;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMAFLASH1

   (
    sprite: SPR_PLSF;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASMAFLASH2

   (
    sprite: SPR_BFGG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFG

   (
    sprite: SPR_BFGG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGDOWN;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGDOWN

   (
    sprite: SPR_BFGG;         // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGUP;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGUP

   (
    sprite: SPR_BFGG;         // sprite
    frame: 0;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFG1

   (
    sprite: SPR_BFGG;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG3;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFG2

   (
    sprite: SPR_BFGG;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG4;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFG3

   (
    sprite: SPR_BFGG;         // sprite
    frame: 1;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFG4

   (
    sprite: SPR_BFGF;         // sprite
    frame: 32768;             // frame
    tics: 11;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGFLASH2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGFLASH1

   (
    sprite: SPR_BFGF;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGFLASH2

   (
    sprite: SPR_BLUD;         // sprite
    frame: 2;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOOD2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOOD1

   (
    sprite: SPR_BLUD;         // sprite
    frame: 1;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOOD3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOOD2

   (
    sprite: SPR_BLUD;         // sprite
    frame: 0;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOOD3

   (
    sprite: SPR_PUFF;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUFF2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUFF1

   (
    sprite: SPR_PUFF;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUFF3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUFF2

   (
    sprite: SPR_PUFF;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUFF4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUFF3

   (
    sprite: SPR_PUFF;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PUFF4

   (
    sprite: SPR_BAL1;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALL2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TBALL1

   (
    sprite: SPR_BAL1;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALL1;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TBALL2

   (
    sprite: SPR_BAL1;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALLX2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TBALLX1

   (
    sprite: SPR_BAL1;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALLX3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TBALLX2

   (
    sprite: SPR_BAL1;         // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TBALLX3

   (
    sprite: SPR_BAL2;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALL2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RBALL1

   (
    sprite: SPR_BAL2;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALL1;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RBALL2

   (
    sprite: SPR_BAL2;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALLX2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RBALLX1

   (
    sprite: SPR_BAL2;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALLX3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RBALLX2

   (
    sprite: SPR_BAL2;         // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RBALLX3

   (
    sprite: SPR_PLSS;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASBALL2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASBALL

   (
    sprite: SPR_PLSS;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASBALL;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASBALL2

   (
    sprite: SPR_PLSE;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASEXP

   (
    sprite: SPR_PLSE;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASEXP2

   (
    sprite: SPR_PLSE;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP4;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASEXP3

   (
    sprite: SPR_PLSE;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP5;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASEXP4

   (
    sprite: SPR_PLSE;         // sprite
    frame: 32772;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLASEXP5

   (
    sprite: SPR_MISL;         // sprite
    frame: 32768;             // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ROCKET;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ROCKET

   (
    sprite: SPR_BFS1;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGSHOT2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGSHOT

   (
    sprite: SPR_BFS1;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGSHOT;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGSHOT2

   (
    sprite: SPR_BFE1;         // sprite
    frame: 32768;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGLAND

   (
    sprite: SPR_BFE1;         // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGLAND2

   (
    sprite: SPR_BFE1;         // sprite
    frame: 32770;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND4;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGLAND3

   (
    sprite: SPR_BFE1;         // sprite
    frame: 32771;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND5;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGLAND4

   (
    sprite: SPR_BFE1;         // sprite
    frame: 32772;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND6;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGLAND5

   (
    sprite: SPR_BFE1;         // sprite
    frame: 32773;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGLAND6

   (
    sprite: SPR_BFE2;         // sprite
    frame: 32768;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGEXP2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGEXP

   (
    sprite: SPR_BFE2;         // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGEXP3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGEXP2

   (
    sprite: SPR_BFE2;         // sprite
    frame: 32770;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGEXP4;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGEXP3

   (
    sprite: SPR_BFE2;         // sprite
    frame: 32771;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFGEXP4

   (
    sprite: SPR_MISL;         // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EXPLODE2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EXPLODE1

   (
    sprite: SPR_MISL;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EXPLODE3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EXPLODE2

   (
    sprite: SPR_MISL;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EXPLODE3

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG01;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG02;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG01

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG02

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG2

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG3

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG4

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG5

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32773;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG7;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG6

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32774;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG8;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG7

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32775;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG9;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG8

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32776;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG10;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG9

   (
    sprite: SPR_TFOG;         // sprite
    frame: 32777;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TFOG10

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG01;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG02;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG01

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG02

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG2

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG3

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG4

   (
    sprite: SPR_IFOG;         // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_IFOG5

   (
    sprite: SPR_PLAY;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY

   (
    sprite: SPR_PLAY;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_RUN1

   (
    sprite: SPR_PLAY;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_RUN2

   (
    sprite: SPR_PLAY;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_RUN3

   (
    sprite: SPR_PLAY;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_RUN4

   (
    sprite: SPR_PLAY;         // sprite
    frame: 4;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_ATK1

   (
    sprite: SPR_PLAY;         // sprite
    frame: 32773;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_ATK1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_ATK2

   (
    sprite: SPR_PLAY;         // sprite
    frame: 6;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_PAIN

   (
    sprite: SPR_PLAY;         // sprite
    frame: 6;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_PAIN2

   (
    sprite: SPR_PLAY;         // sprite
    frame: 7;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE1

   (
    sprite: SPR_PLAY;         // sprite
    frame: 8;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE2

   (
    sprite: SPR_PLAY;         // sprite
    frame: 9;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE3

   (
    sprite: SPR_PLAY;         // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE4

   (
    sprite: SPR_PLAY;         // sprite
    frame: 11;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE5

   (
    sprite: SPR_PLAY;         // sprite
    frame: 12;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE6

   (
    sprite: SPR_PLAY;         // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_DIE7

   (
    sprite: SPR_PLAY;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE1

   (
    sprite: SPR_PLAY;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE2

   (
    sprite: SPR_PLAY;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE3

   (
    sprite: SPR_PLAY;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE4

   (
    sprite: SPR_PLAY;         // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE5

   (
    sprite: SPR_PLAY;         // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE6

   (
    sprite: SPR_PLAY;         // sprite
    frame: 20;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE7

   (
    sprite: SPR_PLAY;         // sprite
    frame: 21;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE8

   (
    sprite: SPR_PLAY;         // sprite
    frame: 22;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAY_XDIE9

   (
    sprite: SPR_POSS;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_STND

   (
    sprite: SPR_POSS;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_STND2

   (
    sprite: SPR_POSS;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN1

   (
    sprite: SPR_POSS;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN2

   (
    sprite: SPR_POSS;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN3

   (
    sprite: SPR_POSS;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN4

   (
    sprite: SPR_POSS;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN5

   (
    sprite: SPR_POSS;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN6

   (
    sprite: SPR_POSS;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN7

   (
    sprite: SPR_POSS;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RUN8

   (
    sprite: SPR_POSS;         // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_ATK1

   (
    sprite: SPR_POSS;         // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_ATK2

   (
    sprite: SPR_POSS;         // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_ATK3

   (
    sprite: SPR_POSS;         // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_PAIN

   (
    sprite: SPR_POSS;         // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_PAIN2

   (
    sprite: SPR_POSS;         // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_DIE1

   (
    sprite: SPR_POSS;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_DIE2

   (
    sprite: SPR_POSS;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_DIE3

   (
    sprite: SPR_POSS;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_DIE4

   (
    sprite: SPR_POSS;         // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_DIE5

   (
    sprite: SPR_POSS;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE1

   (
    sprite: SPR_POSS;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE2

   (
    sprite: SPR_POSS;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE3

   (
    sprite: SPR_POSS;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE4

   (
    sprite: SPR_POSS;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE5

   (
    sprite: SPR_POSS;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE6

   (
    sprite: SPR_POSS;         // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE7

   (
    sprite: SPR_POSS;         // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE8

   (
    sprite: SPR_POSS;         // sprite
    frame: 20;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_XDIE9

   (
    sprite: SPR_POSS;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RAISE1

   (
    sprite: SPR_POSS;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RAISE2

   (
    sprite: SPR_POSS;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RAISE3

   (
    sprite: SPR_POSS;         // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_POSS_RAISE4

   (
    sprite: SPR_SPOS;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_STND

   (
    sprite: SPR_SPOS;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_STND2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN1

   (
    sprite: SPR_SPOS;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN3

   (
    sprite: SPR_SPOS;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN4

   (
    sprite: SPR_SPOS;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN5

   (
    sprite: SPR_SPOS;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN6

   (
    sprite: SPR_SPOS;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN7

   (
    sprite: SPR_SPOS;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RUN8

   (
    sprite: SPR_SPOS;         // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_ATK1

   (
    sprite: SPR_SPOS;         // sprite
    frame: 32773;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_ATK2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_ATK3

   (
    sprite: SPR_SPOS;         // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_PAIN

   (
    sprite: SPR_SPOS;         // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_PAIN2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_DIE1

   (
    sprite: SPR_SPOS;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_DIE2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_DIE3

   (
    sprite: SPR_SPOS;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_DIE4

   (
    sprite: SPR_SPOS;         // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_DIE5

   (
    sprite: SPR_SPOS;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE1

   (
    sprite: SPR_SPOS;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE3

   (
    sprite: SPR_SPOS;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE4

   (
    sprite: SPR_SPOS;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE5

   (
    sprite: SPR_SPOS;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE6

   (
    sprite: SPR_SPOS;         // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE7

   (
    sprite: SPR_SPOS;         // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE8

   (
    sprite: SPR_SPOS;         // sprite
    frame: 20;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_XDIE9

   (
    sprite: SPR_SPOS;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RAISE1

   (
    sprite: SPR_SPOS;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RAISE2

   (
    sprite: SPR_SPOS;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RAISE3

   (
    sprite: SPR_SPOS;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RAISE4

   (
    sprite: SPR_SPOS;         // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPOS_RAISE5

   (
    sprite: SPR_VILE;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_STND

   (
    sprite: SPR_VILE;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_STND2

   (
    sprite: SPR_VILE;         // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN1

   (
    sprite: SPR_VILE;         // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN2

   (
    sprite: SPR_VILE;         // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN3

   (
    sprite: SPR_VILE;         // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN4

   (
    sprite: SPR_VILE;         // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN5

   (
    sprite: SPR_VILE;         // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN6

   (
    sprite: SPR_VILE;         // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN7

   (
    sprite: SPR_VILE;         // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN8

   (
    sprite: SPR_VILE;         // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN9

   (
    sprite: SPR_VILE;         // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN10

   (
    sprite: SPR_VILE;         // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN11

   (
    sprite: SPR_VILE;         // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_RUN12

   (
    sprite: SPR_VILE;         // sprite
    frame: 32774;             // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK1

   (
    sprite: SPR_VILE;         // sprite
    frame: 32774;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK2

   (
    sprite: SPR_VILE;         // sprite
    frame: 32775;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK3

   (
    sprite: SPR_VILE;         // sprite
    frame: 32776;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK4

   (
    sprite: SPR_VILE;         // sprite
    frame: 32777;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK5

   (
    sprite: SPR_VILE;         // sprite
    frame: 32778;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK6

   (
    sprite: SPR_VILE;         // sprite
    frame: 32779;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK7

   (
    sprite: SPR_VILE;         // sprite
    frame: 32780;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK8

   (
    sprite: SPR_VILE;         // sprite
    frame: 32781;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK9

   (
    sprite: SPR_VILE;         // sprite
    frame: 32782;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK10

   (
    sprite: SPR_VILE;         // sprite
    frame: 32783;             // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_ATK11

   (
    sprite: SPR_VILE;         // sprite
    frame: 32794;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_HEAL2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_HEAL1

   (
    sprite: SPR_VILE;         // sprite
    frame: 32795;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_HEAL3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_HEAL2

   (
    sprite: SPR_VILE;         // sprite
    frame: 32796;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_HEAL3

   (
    sprite: SPR_VILE;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_PAIN

   (
    sprite: SPR_VILE;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_PAIN2

   (
    sprite: SPR_VILE;         // sprite
    frame: 16;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE1

   (
    sprite: SPR_VILE;         // sprite
    frame: 17;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE2

   (
    sprite: SPR_VILE;         // sprite
    frame: 18;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE3

   (
    sprite: SPR_VILE;         // sprite
    frame: 19;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE4

   (
    sprite: SPR_VILE;         // sprite
    frame: 20;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE5

   (
    sprite: SPR_VILE;         // sprite
    frame: 21;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE6

   (
    sprite: SPR_VILE;         // sprite
    frame: 22;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE7

   (
    sprite: SPR_VILE;         // sprite
    frame: 23;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE8

   (
    sprite: SPR_VILE;         // sprite
    frame: 24;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE9

   (
    sprite: SPR_VILE;         // sprite
    frame: 25;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_VILE_DIE10

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32768;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE1

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE2

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32768;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE3

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE4

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE5

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE7;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE6

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE8;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE7

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE9;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE8

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE10;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE9

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE11;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE10

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE12;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE11

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE13;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE12

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE14;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE13

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE15;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE14

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE16;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE15

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE17;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE16

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE18;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE17

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE19;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE18

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE20;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE19

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32773;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE21;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE20

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE22;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE21

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32773;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE23;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE22

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE24;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE23

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32773;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE25;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE24

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32774;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE26;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE25

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32775;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE27;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE26

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32774;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE28;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE27

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32775;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE29;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE28

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32774;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE30;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE29

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32775;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FIRE30

   (
    sprite: SPR_PUFF;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SMOKE1

   (
    sprite: SPR_PUFF;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SMOKE2

   (
    sprite: SPR_PUFF;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SMOKE3

   (
    sprite: SPR_PUFF;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE5;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SMOKE4

   (
    sprite: SPR_PUFF;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SMOKE5

   (
    sprite: SPR_FATB;         // sprite
    frame: 32768;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACER2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TRACER

   (
    sprite: SPR_FATB;         // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACER;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TRACER2

   (
    sprite: SPR_FBXP;         // sprite
    frame: 32768;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACEEXP2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TRACEEXP1

   (
    sprite: SPR_FBXP;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACEEXP3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TRACEEXP2

   (
    sprite: SPR_FBXP;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TRACEEXP3

   (
    sprite: SPR_SKEL;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_STND

   (
    sprite: SPR_SKEL;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_STND2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN1

   (
    sprite: SPR_SKEL;         // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN3

   (
    sprite: SPR_SKEL;         // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN4

   (
    sprite: SPR_SKEL;         // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN5

   (
    sprite: SPR_SKEL;         // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN6

   (
    sprite: SPR_SKEL;         // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN7

   (
    sprite: SPR_SKEL;         // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN8

   (
    sprite: SPR_SKEL;         // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN9

   (
    sprite: SPR_SKEL;         // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN10

   (
    sprite: SPR_SKEL;         // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN11

   (
    sprite: SPR_SKEL;         // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RUN12

   (
    sprite: SPR_SKEL;         // sprite
    frame: 6;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_FIST2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_FIST1

   (
    sprite: SPR_SKEL;         // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_FIST3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_FIST2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 7;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_FIST4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_FIST3

   (
    sprite: SPR_SKEL;         // sprite
    frame: 8;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_FIST4

   (
    sprite: SPR_SKEL;         // sprite
    frame: 32777;             // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_MISS2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_MISS1

   (
    sprite: SPR_SKEL;         // sprite
    frame: 32777;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_MISS3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_MISS2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_MISS4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_MISS3

   (
    sprite: SPR_SKEL;         // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_MISS4

   (
    sprite: SPR_SKEL;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_PAIN

   (
    sprite: SPR_SKEL;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_PAIN2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 11;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_DIE1

   (
    sprite: SPR_SKEL;         // sprite
    frame: 12;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_DIE2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 13;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_DIE3

   (
    sprite: SPR_SKEL;         // sprite
    frame: 14;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_DIE4

   (
    sprite: SPR_SKEL;         // sprite
    frame: 15;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_DIE5

   (
    sprite: SPR_SKEL;         // sprite
    frame: 16;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_DIE6

   (
    sprite: SPR_SKEL;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RAISE1

   (
    sprite: SPR_SKEL;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RAISE2

   (
    sprite: SPR_SKEL;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RAISE3

   (
    sprite: SPR_SKEL;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RAISE4

   (
    sprite: SPR_SKEL;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RAISE5

   (
    sprite: SPR_SKEL;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKEL_RAISE6

   (
    sprite: SPR_MANF;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOT2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATSHOT1

   (
    sprite: SPR_MANF;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOT1;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATSHOT2

   (
    sprite: SPR_MISL;         // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOTX2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATSHOTX1

   (
    sprite: SPR_MISL;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOTX3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATSHOTX2

   (
    sprite: SPR_MISL;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATSHOTX3

   (
    sprite: SPR_FATT;         // sprite
    frame: 0;                 // frame
    tics: 15;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_STND

   (
    sprite: SPR_FATT;         // sprite
    frame: 1;                 // frame
    tics: 15;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_STND2

   (
    sprite: SPR_FATT;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN1

   (
    sprite: SPR_FATT;         // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN2

   (
    sprite: SPR_FATT;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN3

   (
    sprite: SPR_FATT;         // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN4

   (
    sprite: SPR_FATT;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN5

   (
    sprite: SPR_FATT;         // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN6

   (
    sprite: SPR_FATT;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN7

   (
    sprite: SPR_FATT;         // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN8

   (
    sprite: SPR_FATT;         // sprite
    frame: 4;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN9

   (
    sprite: SPR_FATT;         // sprite
    frame: 4;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN10

   (
    sprite: SPR_FATT;         // sprite
    frame: 5;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN11

   (
    sprite: SPR_FATT;         // sprite
    frame: 5;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RUN12

   (
    sprite: SPR_FATT;         // sprite
    frame: 6;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK1

   (
    sprite: SPR_FATT;         // sprite
    frame: 32775;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK2

   (
    sprite: SPR_FATT;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK3

   (
    sprite: SPR_FATT;         // sprite
    frame: 6;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK4

   (
    sprite: SPR_FATT;         // sprite
    frame: 32775;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK5

   (
    sprite: SPR_FATT;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK6

   (
    sprite: SPR_FATT;         // sprite
    frame: 6;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK7

   (
    sprite: SPR_FATT;         // sprite
    frame: 32775;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK8

   (
    sprite: SPR_FATT;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK9

   (
    sprite: SPR_FATT;         // sprite
    frame: 6;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_ATK10

   (
    sprite: SPR_FATT;         // sprite
    frame: 9;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_PAIN

   (
    sprite: SPR_FATT;         // sprite
    frame: 9;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_PAIN2

   (
    sprite: SPR_FATT;         // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE1

   (
    sprite: SPR_FATT;         // sprite
    frame: 11;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE2

   (
    sprite: SPR_FATT;         // sprite
    frame: 12;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE3

   (
    sprite: SPR_FATT;         // sprite
    frame: 13;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE4

   (
    sprite: SPR_FATT;         // sprite
    frame: 14;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE5

   (
    sprite: SPR_FATT;         // sprite
    frame: 15;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE6

   (
    sprite: SPR_FATT;         // sprite
    frame: 16;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE7

   (
    sprite: SPR_FATT;         // sprite
    frame: 17;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE8

   (
    sprite: SPR_FATT;         // sprite
    frame: 18;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE9

   (
    sprite: SPR_FATT;         // sprite
    frame: 19;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_DIE10

   (
    sprite: SPR_FATT;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE1

   (
    sprite: SPR_FATT;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE2

   (
    sprite: SPR_FATT;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE3

   (
    sprite: SPR_FATT;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE4

   (
    sprite: SPR_FATT;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE5

   (
    sprite: SPR_FATT;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE6

   (
    sprite: SPR_FATT;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE7

   (
    sprite: SPR_FATT;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FATT_RAISE8

   (
    sprite: SPR_CPOS;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_STND

   (
    sprite: SPR_CPOS;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_STND2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN1

   (
    sprite: SPR_CPOS;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN3

   (
    sprite: SPR_CPOS;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN4

   (
    sprite: SPR_CPOS;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN5

   (
    sprite: SPR_CPOS;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN6

   (
    sprite: SPR_CPOS;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN7

   (
    sprite: SPR_CPOS;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RUN8

   (
    sprite: SPR_CPOS;         // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_ATK1

   (
    sprite: SPR_CPOS;         // sprite
    frame: 32773;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_ATK2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 32772;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_ATK3

   (
    sprite: SPR_CPOS;         // sprite
    frame: 5;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_ATK4

   (
    sprite: SPR_CPOS;         // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_PAIN

   (
    sprite: SPR_CPOS;         // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_PAIN2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE1

   (
    sprite: SPR_CPOS;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE3

   (
    sprite: SPR_CPOS;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE4

   (
    sprite: SPR_CPOS;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE5

   (
    sprite: SPR_CPOS;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE6

   (
    sprite: SPR_CPOS;         // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_DIE7

   (
    sprite: SPR_CPOS;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_XDIE1

   (
    sprite: SPR_CPOS;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_XDIE2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_XDIE3

   (
    sprite: SPR_CPOS;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_XDIE4

   (
    sprite: SPR_CPOS;         // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_XDIE5

   (
    sprite: SPR_CPOS;         // sprite
    frame: 19;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_XDIE6

   (
    sprite: SPR_CPOS;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE1

   (
    sprite: SPR_CPOS;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE2

   (
    sprite: SPR_CPOS;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE3

   (
    sprite: SPR_CPOS;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE4

   (
    sprite: SPR_CPOS;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE5

   (
    sprite: SPR_CPOS;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE6

   (
    sprite: SPR_CPOS;         // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CPOS_RAISE7

   (
    sprite: SPR_TROO;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_STND

   (
    sprite: SPR_TROO;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_STND2

   (
    sprite: SPR_TROO;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN1

   (
    sprite: SPR_TROO;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN2

   (
    sprite: SPR_TROO;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN3

   (
    sprite: SPR_TROO;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN4

   (
    sprite: SPR_TROO;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN5

   (
    sprite: SPR_TROO;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN6

   (
    sprite: SPR_TROO;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN7

   (
    sprite: SPR_TROO;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RUN8

   (
    sprite: SPR_TROO;         // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_ATK1

   (
    sprite: SPR_TROO;         // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_ATK2

   (
    sprite: SPR_TROO;         // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_ATK3

   (
    sprite: SPR_TROO;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_PAIN

   (
    sprite: SPR_TROO;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_PAIN2

   (
    sprite: SPR_TROO;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_DIE1

   (
    sprite: SPR_TROO;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_DIE2

   (
    sprite: SPR_TROO;         // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_DIE3

   (
    sprite: SPR_TROO;         // sprite
    frame: 11;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_DIE4

   (
    sprite: SPR_TROO;         // sprite
    frame: 12;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_DIE5

   (
    sprite: SPR_TROO;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE1

   (
    sprite: SPR_TROO;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE2

   (
    sprite: SPR_TROO;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE3

   (
    sprite: SPR_TROO;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE4

   (
    sprite: SPR_TROO;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE5

   (
    sprite: SPR_TROO;         // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE6

   (
    sprite: SPR_TROO;         // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE7

   (
    sprite: SPR_TROO;         // sprite
    frame: 20;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_XDIE8

   (
    sprite: SPR_TROO;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RAISE1

   (
    sprite: SPR_TROO;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RAISE2

   (
    sprite: SPR_TROO;         // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RAISE3

   (
    sprite: SPR_TROO;         // sprite
    frame: 9;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RAISE4

   (
    sprite: SPR_TROO;         // sprite
    frame: 8;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TROO_RAISE5

   (
    sprite: SPR_SARG;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_STND

   (
    sprite: SPR_SARG;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_STND2

   (
    sprite: SPR_SARG;         // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN1

   (
    sprite: SPR_SARG;         // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN2

   (
    sprite: SPR_SARG;         // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN3

   (
    sprite: SPR_SARG;         // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN4

   (
    sprite: SPR_SARG;         // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN5

   (
    sprite: SPR_SARG;         // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN6

   (
    sprite: SPR_SARG;         // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN7

   (
    sprite: SPR_SARG;         // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RUN8

   (
    sprite: SPR_SARG;         // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_ATK1

   (
    sprite: SPR_SARG;         // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_ATK2

   (
    sprite: SPR_SARG;         // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_ATK3

   (
    sprite: SPR_SARG;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_PAIN

   (
    sprite: SPR_SARG;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_PAIN2

   (
    sprite: SPR_SARG;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_DIE1

   (
    sprite: SPR_SARG;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_DIE2

   (
    sprite: SPR_SARG;         // sprite
    frame: 10;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_DIE3

   (
    sprite: SPR_SARG;         // sprite
    frame: 11;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_DIE4

   (
    sprite: SPR_SARG;         // sprite
    frame: 12;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_DIE5

   (
    sprite: SPR_SARG;         // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_DIE6

   (
    sprite: SPR_SARG;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RAISE1

   (
    sprite: SPR_SARG;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RAISE2

   (
    sprite: SPR_SARG;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RAISE3

   (
    sprite: SPR_SARG;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RAISE4

   (
    sprite: SPR_SARG;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RAISE5

   (
    sprite: SPR_SARG;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SARG_RAISE6

   (
    sprite: SPR_HEAD;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_STND

   (
    sprite: SPR_HEAD;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RUN1

   (
    sprite: SPR_HEAD;         // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_ATK1

   (
    sprite: SPR_HEAD;         // sprite
    frame: 2;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_ATK2

   (
    sprite: SPR_HEAD;         // sprite
    frame: 32771;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_ATK3

   (
    sprite: SPR_HEAD;         // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_PAIN

   (
    sprite: SPR_HEAD;         // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_PAIN3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_PAIN2

   (
    sprite: SPR_HEAD;         // sprite
    frame: 5;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_PAIN3

   (
    sprite: SPR_HEAD;         // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_DIE1

   (
    sprite: SPR_HEAD;         // sprite
    frame: 7;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_DIE2

   (
    sprite: SPR_HEAD;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_DIE3

   (
    sprite: SPR_HEAD;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_DIE4

   (
    sprite: SPR_HEAD;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_DIE5

   (
    sprite: SPR_HEAD;         // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_DIE6

   (
    sprite: SPR_HEAD;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RAISE1

   (
    sprite: SPR_HEAD;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RAISE2

   (
    sprite: SPR_HEAD;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RAISE3

   (
    sprite: SPR_HEAD;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RAISE4

   (
    sprite: SPR_HEAD;         // sprite
    frame: 7;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RAISE5

   (
    sprite: SPR_HEAD;         // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEAD_RAISE6

   (
    sprite: SPR_BAL7;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRBALL1

   (
    sprite: SPR_BAL7;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALL1;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRBALL2

   (
    sprite: SPR_BAL7;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALLX2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRBALLX1

   (
    sprite: SPR_BAL7;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALLX3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRBALLX2

   (
    sprite: SPR_BAL7;         // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRBALLX3

   (
    sprite: SPR_BOSS;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_STND

   (
    sprite: SPR_BOSS;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_STND2

   (
    sprite: SPR_BOSS;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN1

   (
    sprite: SPR_BOSS;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN2

   (
    sprite: SPR_BOSS;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN3

   (
    sprite: SPR_BOSS;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN4

   (
    sprite: SPR_BOSS;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN5

   (
    sprite: SPR_BOSS;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN6

   (
    sprite: SPR_BOSS;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN7

   (
    sprite: SPR_BOSS;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RUN8

   (
    sprite: SPR_BOSS;         // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_ATK1

   (
    sprite: SPR_BOSS;         // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_ATK2

   (
    sprite: SPR_BOSS;         // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_ATK3

   (
    sprite: SPR_BOSS;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_PAIN

   (
    sprite: SPR_BOSS;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_PAIN2

   (
    sprite: SPR_BOSS;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE1

   (
    sprite: SPR_BOSS;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE2

   (
    sprite: SPR_BOSS;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE3

   (
    sprite: SPR_BOSS;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE4

   (
    sprite: SPR_BOSS;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE5

   (
    sprite: SPR_BOSS;         // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE6

   (
    sprite: SPR_BOSS;         // sprite
    frame: 14;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_DIE7

   (
    sprite: SPR_BOSS;         // sprite
    frame: 14;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE1

   (
    sprite: SPR_BOSS;         // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE2

   (
    sprite: SPR_BOSS;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE3

   (
    sprite: SPR_BOSS;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE4

   (
    sprite: SPR_BOSS;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE5

   (
    sprite: SPR_BOSS;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE6

   (
    sprite: SPR_BOSS;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOSS_RAISE7

   (
    sprite: SPR_BOS2;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_STND

   (
    sprite: SPR_BOS2;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_STND2

   (
    sprite: SPR_BOS2;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN1

   (
    sprite: SPR_BOS2;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN2

   (
    sprite: SPR_BOS2;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN3

   (
    sprite: SPR_BOS2;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN4

   (
    sprite: SPR_BOS2;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN5

   (
    sprite: SPR_BOS2;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN6

   (
    sprite: SPR_BOS2;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN7

   (
    sprite: SPR_BOS2;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RUN8

   (
    sprite: SPR_BOS2;         // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_ATK1

   (
    sprite: SPR_BOS2;         // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_ATK2

   (
    sprite: SPR_BOS2;         // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_ATK3

   (
    sprite: SPR_BOS2;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_PAIN

   (
    sprite: SPR_BOS2;         // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_PAIN2

   (
    sprite: SPR_BOS2;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE1

   (
    sprite: SPR_BOS2;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE2

   (
    sprite: SPR_BOS2;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE3

   (
    sprite: SPR_BOS2;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE4

   (
    sprite: SPR_BOS2;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE5

   (
    sprite: SPR_BOS2;         // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE6

   (
    sprite: SPR_BOS2;         // sprite
    frame: 14;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_DIE7

   (
    sprite: SPR_BOS2;         // sprite
    frame: 14;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE1

   (
    sprite: SPR_BOS2;         // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE2

   (
    sprite: SPR_BOS2;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE3

   (
    sprite: SPR_BOS2;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE4

   (
    sprite: SPR_BOS2;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE5

   (
    sprite: SPR_BOS2;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE6

   (
    sprite: SPR_BOS2;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BOS2_RAISE7

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32768;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_STND

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_STND;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_STND2

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_RUN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_RUN1

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_RUN2

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32770;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_ATK1

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_ATK2

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_ATK3

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_ATK4

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32772;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_PAIN

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32772;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_PAIN2

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32773;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_DIE1

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32774;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_DIE2

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32775;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_DIE3

   (
    sprite: SPR_SKUL;         // sprite
    frame: 32776;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_DIE4

   (
    sprite: SPR_SKUL;         // sprite
    frame: 9;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_DIE5

   (
    sprite: SPR_SKUL;         // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULL_DIE6

   (
    sprite: SPR_SPID;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_STND

   (
    sprite: SPR_SPID;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_STND2

   (
    sprite: SPR_SPID;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN1

   (
    sprite: SPR_SPID;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN2

   (
    sprite: SPR_SPID;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN3

   (
    sprite: SPR_SPID;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN4

   (
    sprite: SPR_SPID;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN5

   (
    sprite: SPR_SPID;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN6

   (
    sprite: SPR_SPID;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN7

   (
    sprite: SPR_SPID;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN8

   (
    sprite: SPR_SPID;         // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN9

   (
    sprite: SPR_SPID;         // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN10

   (
    sprite: SPR_SPID;         // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN11

   (
    sprite: SPR_SPID;         // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_RUN12

   (
    sprite: SPR_SPID;         // sprite
    frame: 32768;             // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_ATK1

   (
    sprite: SPR_SPID;         // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_ATK2

   (
    sprite: SPR_SPID;         // sprite
    frame: 32775;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_ATK3

   (
    sprite: SPR_SPID;         // sprite
    frame: 32775;             // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_ATK4

   (
    sprite: SPR_SPID;         // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_PAIN

   (
    sprite: SPR_SPID;         // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_PAIN2

   (
    sprite: SPR_SPID;         // sprite
    frame: 9;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE1

   (
    sprite: SPR_SPID;         // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE2

   (
    sprite: SPR_SPID;         // sprite
    frame: 11;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE3

   (
    sprite: SPR_SPID;         // sprite
    frame: 12;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE4

   (
    sprite: SPR_SPID;         // sprite
    frame: 13;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE5

   (
    sprite: SPR_SPID;         // sprite
    frame: 14;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE6

   (
    sprite: SPR_SPID;         // sprite
    frame: 15;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE7

   (
    sprite: SPR_SPID;         // sprite
    frame: 16;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE8

   (
    sprite: SPR_SPID;         // sprite
    frame: 17;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE9

   (
    sprite: SPR_SPID;         // sprite
    frame: 18;                // frame
    tics: 30;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE10

   (
    sprite: SPR_SPID;         // sprite
    frame: 18;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPID_DIE11

   (
    sprite: SPR_BSPI;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_STND

   (
    sprite: SPR_BSPI;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_STND2

   (
    sprite: SPR_BSPI;         // sprite
    frame: 0;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_SIGHT

   (
    sprite: SPR_BSPI;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN1

   (
    sprite: SPR_BSPI;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN2

   (
    sprite: SPR_BSPI;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN3

   (
    sprite: SPR_BSPI;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN4

   (
    sprite: SPR_BSPI;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN5

   (
    sprite: SPR_BSPI;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN6

   (
    sprite: SPR_BSPI;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN7

   (
    sprite: SPR_BSPI;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN8

   (
    sprite: SPR_BSPI;         // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN9

   (
    sprite: SPR_BSPI;         // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN10

   (
    sprite: SPR_BSPI;         // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN11

   (
    sprite: SPR_BSPI;         // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RUN12

   (
    sprite: SPR_BSPI;         // sprite
    frame: 32768;             // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_ATK1

   (
    sprite: SPR_BSPI;         // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_ATK2

   (
    sprite: SPR_BSPI;         // sprite
    frame: 32775;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_ATK3

   (
    sprite: SPR_BSPI;         // sprite
    frame: 32775;             // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_ATK4

   (
    sprite: SPR_BSPI;         // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_PAIN

   (
    sprite: SPR_BSPI;         // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_PAIN2

   (
    sprite: SPR_BSPI;         // sprite
    frame: 9;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE1

   (
    sprite: SPR_BSPI;         // sprite
    frame: 10;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE2

   (
    sprite: SPR_BSPI;         // sprite
    frame: 11;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE3

   (
    sprite: SPR_BSPI;         // sprite
    frame: 12;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE4

   (
    sprite: SPR_BSPI;         // sprite
    frame: 13;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE5

   (
    sprite: SPR_BSPI;         // sprite
    frame: 14;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE6

   (
    sprite: SPR_BSPI;         // sprite
    frame: 15;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_DIE7

   (
    sprite: SPR_BSPI;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE1

   (
    sprite: SPR_BSPI;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE2

   (
    sprite: SPR_BSPI;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE3

   (
    sprite: SPR_BSPI;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE4

   (
    sprite: SPR_BSPI;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE5

   (
    sprite: SPR_BSPI;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE6

   (
    sprite: SPR_BSPI;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSPI_RAISE7

   (
    sprite: SPR_APLS;         // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLAZ2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLAZ

   (
    sprite: SPR_APLS;         // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLAZ;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLAZ2

   (
    sprite: SPR_APBX;         // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLEX

   (
    sprite: SPR_APBX;         // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLEX2

   (
    sprite: SPR_APBX;         // sprite
    frame: 32770;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLEX3

   (
    sprite: SPR_APBX;         // sprite
    frame: 32771;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLEX4

   (
    sprite: SPR_APBX;         // sprite
    frame: 32772;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARACH_PLEX5

   (
    sprite: SPR_CYBR;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_STND

   (
    sprite: SPR_CYBR;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_STND;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_STND2

   (
    sprite: SPR_CYBR;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN1

   (
    sprite: SPR_CYBR;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN2

   (
    sprite: SPR_CYBR;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN3

   (
    sprite: SPR_CYBR;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN4

   (
    sprite: SPR_CYBR;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN5

   (
    sprite: SPR_CYBR;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN6

   (
    sprite: SPR_CYBR;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN7

   (
    sprite: SPR_CYBR;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_RUN8

   (
    sprite: SPR_CYBR;         // sprite
    frame: 4;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_ATK1

   (
    sprite: SPR_CYBR;         // sprite
    frame: 5;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_ATK2

   (
    sprite: SPR_CYBR;         // sprite
    frame: 4;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_ATK3

   (
    sprite: SPR_CYBR;         // sprite
    frame: 5;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_ATK4

   (
    sprite: SPR_CYBR;         // sprite
    frame: 4;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_ATK5

   (
    sprite: SPR_CYBR;         // sprite
    frame: 5;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_ATK6

   (
    sprite: SPR_CYBR;         // sprite
    frame: 6;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_PAIN

   (
    sprite: SPR_CYBR;         // sprite
    frame: 7;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE1

   (
    sprite: SPR_CYBR;         // sprite
    frame: 8;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE2

   (
    sprite: SPR_CYBR;         // sprite
    frame: 9;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE3

   (
    sprite: SPR_CYBR;         // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE4

   (
    sprite: SPR_CYBR;         // sprite
    frame: 11;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE5

   (
    sprite: SPR_CYBR;         // sprite
    frame: 12;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE6

   (
    sprite: SPR_CYBR;         // sprite
    frame: 13;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE7

   (
    sprite: SPR_CYBR;         // sprite
    frame: 14;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE8

   (
    sprite: SPR_CYBR;         // sprite
    frame: 15;                // frame
    tics: 30;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE9

   (
    sprite: SPR_CYBR;         // sprite
    frame: 15;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CYBER_DIE10

   (
    sprite: SPR_PAIN;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_STND

   (
    sprite: SPR_PAIN;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RUN1

   (
    sprite: SPR_PAIN;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RUN2

   (
    sprite: SPR_PAIN;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RUN3

   (
    sprite: SPR_PAIN;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RUN4

   (
    sprite: SPR_PAIN;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RUN5

   (
    sprite: SPR_PAIN;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RUN6

   (
    sprite: SPR_PAIN;         // sprite
    frame: 3;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_ATK1

   (
    sprite: SPR_PAIN;         // sprite
    frame: 4;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_ATK2

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32773;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_ATK3

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32773;             // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_ATK4

   (
    sprite: SPR_PAIN;         // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_PAIN

   (
    sprite: SPR_PAIN;         // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_PAIN2

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32775;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_DIE1

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32776;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_DIE2

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32777;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_DIE3

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32778;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_DIE4

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32779;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_DIE5

   (
    sprite: SPR_PAIN;         // sprite
    frame: 32780;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_DIE6

   (
    sprite: SPR_PAIN;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RAISE1

   (
    sprite: SPR_PAIN;         // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RAISE2

   (
    sprite: SPR_PAIN;         // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RAISE3

   (
    sprite: SPR_PAIN;         // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RAISE4

   (
    sprite: SPR_PAIN;         // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RAISE5

   (
    sprite: SPR_PAIN;         // sprite
    frame: 7;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PAIN_RAISE6

   (
    sprite: SPR_SSWV;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_STND

   (
    sprite: SPR_SSWV;         // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_STND2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN1

   (
    sprite: SPR_SSWV;         // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN3

   (
    sprite: SPR_SSWV;         // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN4

   (
    sprite: SPR_SSWV;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN5

   (
    sprite: SPR_SSWV;         // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN6

   (
    sprite: SPR_SSWV;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN7

   (
    sprite: SPR_SSWV;         // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RUN8

   (
    sprite: SPR_SSWV;         // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_ATK1

   (
    sprite: SPR_SSWV;         // sprite
    frame: 5;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_ATK2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_ATK3

   (
    sprite: SPR_SSWV;         // sprite
    frame: 5;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_ATK4

   (
    sprite: SPR_SSWV;         // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_ATK5

   (
    sprite: SPR_SSWV;         // sprite
    frame: 5;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_ATK6

   (
    sprite: SPR_SSWV;         // sprite
    frame: 7;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_PAIN

   (
    sprite: SPR_SSWV;         // sprite
    frame: 7;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_PAIN2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_DIE1

   (
    sprite: SPR_SSWV;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_DIE2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_DIE3

   (
    sprite: SPR_SSWV;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_DIE4

   (
    sprite: SPR_SSWV;         // sprite
    frame: 12;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_DIE5

   (
    sprite: SPR_SSWV;         // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE1

   (
    sprite: SPR_SSWV;         // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE3

   (
    sprite: SPR_SSWV;         // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE4

   (
    sprite: SPR_SSWV;         // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE5

   (
    sprite: SPR_SSWV;         // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE6

   (
    sprite: SPR_SSWV;         // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE7

   (
    sprite: SPR_SSWV;         // sprite
    frame: 20;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE8

   (
    sprite: SPR_SSWV;         // sprite
    frame: 21;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_XDIE9

   (
    sprite: SPR_SSWV;         // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RAISE1

   (
    sprite: SPR_SSWV;         // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RAISE2

   (
    sprite: SPR_SSWV;         // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RAISE3

   (
    sprite: SPR_SSWV;         // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RAISE4

   (
    sprite: SPR_SSWV;         // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SSWV_RAISE5

   (
    sprite: SPR_KEEN;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_KEENSTND;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_KEENSTND

   (
    sprite: SPR_KEEN;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN

   (
    sprite: SPR_KEEN;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN2

   (
    sprite: SPR_KEEN;         // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN3

   (
    sprite: SPR_KEEN;         // sprite
    frame: 3;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN4

   (
    sprite: SPR_KEEN;         // sprite
    frame: 4;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN5

   (
    sprite: SPR_KEEN;         // sprite
    frame: 5;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN6

   (
    sprite: SPR_KEEN;         // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN7

   (
    sprite: SPR_KEEN;         // sprite
    frame: 7;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN8

   (
    sprite: SPR_KEEN;         // sprite
    frame: 8;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN9

   (
    sprite: SPR_KEEN;         // sprite
    frame: 9;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN10

   (
    sprite: SPR_KEEN;         // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0),                // S_COMMKEEN11  // misc2

   (
    sprite: SPR_KEEN;         // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COMMKEEN12

   (
    sprite: SPR_KEEN;         // sprite
    frame: 12;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_KEENPAIN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_KEENPAIN

   (
    sprite: SPR_KEEN;         // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_KEENSTND;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_KEENPAIN2

   (
    sprite: SPR_BBRN;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAIN

   (
    sprite: SPR_BBRN;         // sprite
    frame: 1;                 // frame
    tics: 36;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAIN_PAIN

   (
    sprite: SPR_BBRN;         // sprite
    frame: 0;                 // frame
    tics: 100;                // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN_DIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAIN_DIE1

   (
    sprite: SPR_BBRN;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN_DIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAIN_DIE2

   (
    sprite: SPR_BBRN;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN_DIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAIN_DIE3

   (
    sprite: SPR_BBRN;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAIN_DIE4

   (
    sprite: SPR_SSWV;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEYE;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINEYE

   (
    sprite: SPR_SSWV;         // sprite
    frame: 0;                 // frame
    tics: 181;                // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEYE1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINEYESEE

   (
    sprite: SPR_SSWV;         // sprite
    frame: 0;                 // frame
    tics: 150;                // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEYE1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINEYE1

   (
    sprite: SPR_BOSF;         // sprite
    frame: 32768;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWN1

   (
    sprite: SPR_BOSF;         // sprite
    frame: 32769;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWN2

   (
    sprite: SPR_BOSF;         // sprite
    frame: 32770;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWN3

   (
    sprite: SPR_BOSF;         // sprite
    frame: 32771;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN1;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWN4

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE1

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE2

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE3

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE4

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32772;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE5

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32773;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE6

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE7

   (
    sprite: SPR_FIRE;         // sprite
    frame: 32775;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SPAWNFIRE8

   (
    sprite: SPR_MISL;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEXPLODE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINEXPLODE1

   (
    sprite: SPR_MISL;         // sprite
    frame: 32770;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEXPLODE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINEXPLODE2

   (
    sprite: SPR_MISL;         // sprite
    frame: 32771;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINEXPLODE3

   (
    sprite: SPR_ARM1;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM1A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARM1

   (
    sprite: SPR_ARM1;         // sprite
    frame: 32769;             // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM1;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARM1A

   (
    sprite: SPR_ARM2;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM2A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARM2

   (
    sprite: SPR_ARM2;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ARM2A

   (
    sprite: SPR_BAR1;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BAR2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BAR1

   (
    sprite: SPR_BAR1;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BAR1;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BAR2

   (
    sprite: SPR_BEXP;         // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BEXP

   (
    sprite: SPR_BEXP;         // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BEXP2

   (
    sprite: SPR_BEXP;         // sprite
    frame: 32770;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BEXP3

   (
    sprite: SPR_BEXP;         // sprite
    frame: 32771;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BEXP4

   (
    sprite: SPR_BEXP;         // sprite
    frame: 32772;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BEXP5

   (
    sprite: SPR_FCAN;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BBAR2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BBAR1

   (
    sprite: SPR_FCAN;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BBAR3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BBAR2

   (
    sprite: SPR_FCAN;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BBAR1;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BBAR3

   (
    sprite: SPR_BON1;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON1

   (
    sprite: SPR_BON1;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1B;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON1A

   (
    sprite: SPR_BON1;         // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1C;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON1B

   (
    sprite: SPR_BON1;         // sprite
    frame: 3;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1D;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON1C

   (
    sprite: SPR_BON1;         // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1E;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON1D

   (
    sprite: SPR_BON1;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON1E

   (
    sprite: SPR_BON2;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON2

   (
    sprite: SPR_BON2;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2B;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON2A

   (
    sprite: SPR_BON2;         // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2C;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON2B

   (
    sprite: SPR_BON2;         // sprite
    frame: 3;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2D;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON2C

   (
    sprite: SPR_BON2;         // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2E;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON2D

   (
    sprite: SPR_BON2;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BON2E

   (
    sprite: SPR_BKEY;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BKEY2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BKEY

   (
    sprite: SPR_BKEY;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BKEY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BKEY2

   (
    sprite: SPR_RKEY;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RKEY2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RKEY

   (
    sprite: SPR_RKEY;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RKEY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RKEY2

   (
    sprite: SPR_YKEY;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YKEY2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_YKEY

   (
    sprite: SPR_YKEY;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YKEY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_YKEY2

   (
    sprite: SPR_BSKU;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSKULL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSKULL

   (
    sprite: SPR_BSKU;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSKULL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BSKULL2

   (
    sprite: SPR_RSKU;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RSKULL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RSKULL

   (
    sprite: SPR_RSKU;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RSKULL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RSKULL2

   (
    sprite: SPR_YSKU;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YSKULL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_YSKULL

   (
    sprite: SPR_YSKU;         // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YSKULL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_YSKULL2

   (
    sprite: SPR_STIM;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_STIM

   (
    sprite: SPR_MEDI;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEDI

   (
    sprite: SPR_SOUL;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SOUL

   (
    sprite: SPR_SOUL;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SOUL2

   (
    sprite: SPR_SOUL;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SOUL3

   (
    sprite: SPR_SOUL;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SOUL4

   (
    sprite: SPR_SOUL;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SOUL5

   (
    sprite: SPR_SOUL;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SOUL6

   (
    sprite: SPR_PINV;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINV

   (
    sprite: SPR_PINV;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINV2

   (
    sprite: SPR_PINV;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINV3

   (
    sprite: SPR_PINV;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINV4

   (
    sprite: SPR_PSTR;         // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PSTR

   (
    sprite: SPR_PINS;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINS

   (
    sprite: SPR_PINS;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINS2

   (
    sprite: SPR_PINS;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINS3

   (
    sprite: SPR_PINS;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PINS4

   (
    sprite: SPR_MEGA;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEGA

   (
    sprite: SPR_MEGA;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEGA2

   (
    sprite: SPR_MEGA;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEGA3

   (
    sprite: SPR_MEGA;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEGA4

   (
    sprite: SPR_SUIT;         // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SUIT

   (
    sprite: SPR_PMAP;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PMAP

   (
    sprite: SPR_PMAP;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PMAP2

   (
    sprite: SPR_PMAP;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PMAP3

   (
    sprite: SPR_PMAP;         // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PMAP4

   (
    sprite: SPR_PMAP;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PMAP5

   (
    sprite: SPR_PMAP;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PMAP6

   (
    sprite: SPR_PVIS;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PVIS2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PVIS

   (
    sprite: SPR_PVIS;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PVIS;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PVIS2

   (
    sprite: SPR_CLIP;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CLIP

   (
    sprite: SPR_AMMO;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_AMMO

   (
    sprite: SPR_ROCK;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_ROCK

   (
    sprite: SPR_BROK;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BROK

   (
    sprite: SPR_CELL;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CELL

   (
    sprite: SPR_CELP;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CELP

   (
    sprite: SPR_SHEL;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SHEL

   (
    sprite: SPR_SBOX;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SBOX

   (
    sprite: SPR_BPAK;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BPAK

   (
    sprite: SPR_BFUG;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BFUG

   (
    sprite: SPR_MGUN;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MGUN

   (
    sprite: SPR_CSAW;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CSAW

   (
    sprite: SPR_LAUN;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_LAUN

   (
    sprite: SPR_PLAS;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_PLAS

   (
    sprite: SPR_SHOT;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SHOT

   (
    sprite: SPR_SGN2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SHOT2

   (
    sprite: SPR_COLU;         // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COLU

   (
    sprite: SPR_SMT2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_STALAG

   (
    sprite: SPR_GOR1;         // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOODYTWITCH

   (
    sprite: SPR_GOR1;         // sprite
    frame: 1;                 // frame
    tics: 15;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOODYTWITCH2

   (
    sprite: SPR_GOR1;         // sprite
    frame: 2;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOODYTWITCH3

   (
    sprite: SPR_GOR1;         // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLOODYTWITCH4

   (
    sprite: SPR_PLAY;         // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DEADTORSO

   (
    sprite: SPR_PLAY;         // sprite
    frame: 18;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DEADBOTTOM

   (
    sprite: SPR_POL2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEADSONSTICK

   (
    sprite: SPR_POL5;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GIBS

   (
    sprite: SPR_POL4;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEADONASTICK

   (
    sprite: SPR_POL3;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEADCANDLES2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEADCANDLES

   (
    sprite: SPR_POL3;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEADCANDLES;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEADCANDLES2

   (
    sprite: SPR_POL1;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_DEADSTICK

   (
    sprite: SPR_POL6;         // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIVESTICK2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_LIVESTICK

   (
    sprite: SPR_POL6;         // sprite
    frame: 1;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIVESTICK;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_LIVESTICK2

   (
    sprite: SPR_GOR2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEAT2

   (
    sprite: SPR_GOR3;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEAT3

   (
    sprite: SPR_GOR4;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEAT4

   (
    sprite: SPR_GOR5;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_MEAT5

   (
    sprite: SPR_SMIT;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_STALAGTITE

   (
    sprite: SPR_COL1;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TALLGRNCOL

   (
    sprite: SPR_COL2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SHRTGRNCOL

   (
    sprite: SPR_COL3;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TALLREDCOL

   (
    sprite: SPR_COL4;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SHRTREDCOL

   (
    sprite: SPR_CAND;         // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CANDLESTIK

   (
    sprite: SPR_CBRA;         // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_CANDELABRA

   (
    sprite: SPR_COL6;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SKULLCOL

   (
    sprite: SPR_TRE1;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TORCHTREE

   (
    sprite: SPR_TRE2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BIGTREE

   (
    sprite: SPR_ELEC;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECHPILLAR

   (
    sprite: SPR_CEYE;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EVILEYE

   (
    sprite: SPR_CEYE;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EVILEYE2

   (
    sprite: SPR_CEYE;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE4;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EVILEYE3

   (
    sprite: SPR_CEYE;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_EVILEYE4

   (
    sprite: SPR_FSKU;         // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FLOATSKULL2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FLOATSKULL

   (
    sprite: SPR_FSKU;         // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FLOATSKULL3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FLOATSKULL2

   (
    sprite: SPR_FSKU;         // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FLOATSKULL;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_FLOATSKULL3

   (
    sprite: SPR_COL5;         // sprite
    frame: 0;                 // frame
    tics: 14;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEARTCOL2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEARTCOL

   (
    sprite: SPR_COL5;         // sprite
    frame: 1;                 // frame
    tics: 14;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEARTCOL;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HEARTCOL2

   (
    sprite: SPR_TBLU;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLUETORCH

   (
    sprite: SPR_TBLU;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLUETORCH2

   (
    sprite: SPR_TBLU;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLUETORCH3

   (
    sprite: SPR_TBLU;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BLUETORCH4

   (
    sprite: SPR_TGRN;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GREENTORCH

   (
    sprite: SPR_TGRN;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GREENTORCH2

   (
    sprite: SPR_TGRN;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GREENTORCH3

   (
    sprite: SPR_TGRN;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GREENTORCH4

   (
    sprite: SPR_TRED;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_REDTORCH

   (
    sprite: SPR_TRED;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_REDTORCH2

   (
    sprite: SPR_TRED;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_REDTORCH3

   (
    sprite: SPR_TRED;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_REDTORCH4

   (
    sprite: SPR_SMBT;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BTORCHSHRT

   (
    sprite: SPR_SMBT;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BTORCHSHRT2

   (
    sprite: SPR_SMBT;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BTORCHSHRT3

   (
    sprite: SPR_SMBT;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BTORCHSHRT4

   (
    sprite: SPR_SMGT;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GTORCHSHRT

   (
    sprite: SPR_SMGT;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GTORCHSHRT2

   (
    sprite: SPR_SMGT;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GTORCHSHRT3

   (
    sprite: SPR_SMGT;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_GTORCHSHRT4

   (
    sprite: SPR_SMRT;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RTORCHSHRT

   (
    sprite: SPR_SMRT;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RTORCHSHRT2

   (
    sprite: SPR_SMRT;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RTORCHSHRT3

   (
    sprite: SPR_SMRT;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_RTORCHSHRT4

   (
    sprite: SPR_HDB1;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HANGNOGUTS

   (
    sprite: SPR_HDB2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HANGBNOBRAIN

   (
    sprite: SPR_HDB3;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HANGTLOOKDN

   (
    sprite: SPR_HDB4;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HANGTSKULL

   (
    sprite: SPR_HDB5;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HANGTLOOKUP

   (
    sprite: SPR_HDB6;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_HANGTNOBRAIN

   (
    sprite: SPR_POB1;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_COLONGIBS

   (
    sprite: SPR_POB2;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_SMALLPOOL

   (
    sprite: SPR_BRS1;         // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_BRAINSTEM

   (
    sprite: SPR_TLMP;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECHLAMP

   (
    sprite: SPR_TLMP;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECHLAMP2

   (
    sprite: SPR_TLMP;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECHLAMP3

   (
    sprite: SPR_TLMP;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECHLAMP4

   (
    sprite: SPR_TLP2;         // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECH2LAMP

   (
    sprite: SPR_TLP2;         // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECH2LAMP2

   (
    sprite: SPR_TLP2;         // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // misc2
   ),                         // S_TECH2LAMP3

   (
    sprite: SPR_TLP2;         // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0                  // S_TECH2LAMP4  // misc2
   )
  );

const
  sprnames1: array[0..ord(NUMSPRITES) - 1 + 1] of string[4] = (
    'TROO', 'SHTG', 'PUNG', 'PISG', 'PISF', 'SHTF', 'SHT2', 'CHGG', 'CHGF', 'MISG',
    'MISF', 'SAWG', 'PLSG', 'PLSF', 'BFGG', 'BFGF', 'BLUD', 'PUFF', 'BAL1', 'BAL2',
    'PLSS', 'PLSE', 'MISL', 'BFS1', 'BFE1', 'BFE2', 'TFOG', 'IFOG', 'PLAY', 'POSS',
    'SPOS', 'VILE', 'FIRE', 'FATB', 'FBXP', 'SKEL', 'MANF', 'FATT', 'CPOS', 'SARG',
    'HEAD', 'BAL7', 'BOSS', 'BOS2', 'SKUL', 'SPID', 'BSPI', 'APLS', 'APBX', 'CYBR',
    'PAIN', 'SSWV', 'KEEN', 'BBRN', 'BOSF', 'ARM1', 'ARM2', 'BAR1', 'BEXP', 'FCAN',
    'BON1', 'BON2', 'BKEY', 'RKEY', 'YKEY', 'BSKU', 'RSKU', 'YSKU', 'STIM', 'MEDI',
    'SOUL', 'PINV', 'PSTR', 'PINS', 'MEGA', 'SUIT', 'PMAP', 'PVIS', 'CLIP', 'AMMO',
    'ROCK', 'BROK', 'CELL', 'CELP', 'SHEL', 'SBOX', 'BPAK', 'BFUG', 'MGUN', 'CSAW',
    'LAUN', 'PLAS', 'SHOT', 'SGN2', 'COLU', 'SMT2', 'GOR1', 'POL2', 'POL5', 'POL4',
    'POL3', 'POL1', 'POL6', 'GOR2', 'GOR3', 'GOR4', 'GOR5', 'SMIT', 'COL1', 'COL2',
    'COL3', 'COL4', 'CAND', 'CBRA', 'COL6', 'TRE1', 'TRE2', 'ELEC', 'CEYE', 'FSKU',
    'COL5', 'TBLU', 'TGRN', 'TRED', 'SMBT', 'SMGT', 'SMRT', 'HDB1', 'HDB2', 'HDB3',
    'HDB4', 'HDB5', 'HDB6', 'POB1', 'POB2', 'BRS1', 'TLMP', 'TLP2', ''
  );

const
  mobjinfo1: array[0..ord(NUMMOBJTYPES) - 1] of mobjinfo_t = (
   (    // MT_PLAYER
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_PLAY);          // spawnstate
    spawnhealth: 100;                 // spawnhealth
    seestate: Ord(S_PLAY_RUN1);       // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 0;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_PLAY_PAIN);      // painstate
    painchance: 255;                  // painchance
    painsound: Ord(sfx_plpain);       // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_PLAY_ATK1);    // missilestate
    deathstate: Ord(S_PLAY_DIE1);     // deathstate
    xdeathstate: Ord(S_PLAY_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_pldeth);      // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_DROPOFF or MF_PICKUP or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_POSSESSED
    doomednum: 3004;                  // doomednum
    spawnstate: Ord(S_POSS_STND);     // spawnstate
    spawnhealth: 20;                  // spawnhealth
    seestate: Ord(S_POSS_RUN1);       // seestate
    seesound: Ord(sfx_posit1);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_pistol);     // attacksound
    painstate: Ord(S_POSS_PAIN);      // painstate
    painchance: 200;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_POSS_ATK1);    // missilestate
    deathstate: Ord(S_POSS_DIE1);     // deathstate
    xdeathstate: Ord(S_POSS_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_podth1);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_POSS_RAISE1)    // raisestate
   ),
   (    // MT_SHOTGUY
    doomednum: 9;                     // doomednum
    spawnstate: Ord(S_SPOS_STND);     // spawnstate
    spawnhealth: 30;                  // spawnhealth
    seestate: Ord(S_SPOS_RUN1);       // seestate
    seesound: Ord(sfx_posit2);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_SPOS_PAIN);      // painstate
    painchance: 170;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SPOS_ATK1);    // missilestate
    deathstate: Ord(S_SPOS_DIE1);     // deathstate
    xdeathstate: Ord(S_SPOS_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_podth2);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_SPOS_RAISE1)    // raisestate
   ),
   (    // MT_VILE
    doomednum: 64;                    // doomednum
    spawnstate: Ord(S_VILE_STND);     // spawnstate
    spawnhealth: 700;                 // spawnhealth
    seestate: Ord(S_VILE_RUN1);       // seestate
    seesound: Ord(sfx_vilsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_VILE_PAIN);      // painstate
    painchance: 10;                   // painchance
    painsound: Ord(sfx_vipain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_VILE_ATK1);    // missilestate
    deathstate: Ord(S_VILE_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_vildth);      // deathsound
    speed: 15;                        // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 500;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_vilact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_FIRE
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_FIRE1);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_UNDEAD
    doomednum: 66;                    // doomednum
    spawnstate: Ord(S_SKEL_STND);     // spawnstate
    spawnhealth: 300;                 // spawnhealth
    seestate: Ord(S_SKEL_RUN1);       // seestate
    seesound: Ord(sfx_skesit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_SKEL_PAIN);      // painstate
    painchance: 100;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(S_SKEL_FIST1);    // meleestate
    missilestate: Ord(S_SKEL_MISS1);    // missilestate
    deathstate: Ord(S_SKEL_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_skedth);      // deathsound
    speed: 10;                        // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 500;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_skeact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_SKEL_RAISE1)    // raisestate
   ),
   (    // MT_TRACER
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_TRACER);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_skeatk);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_TRACEEXP1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_barexp);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 11 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 10;                       // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_SMOKE
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_SMOKE1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_FATSO
    doomednum: 67;                    // doomednum
    spawnstate: Ord(S_FATT_STND);     // spawnstate
    spawnhealth: 600;                 // spawnhealth
    seestate: Ord(S_FATT_RUN1);       // seestate
    seesound: Ord(sfx_mansit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_FATT_PAIN);      // painstate
    painchance: 80;                   // painchance
    painsound: Ord(sfx_mnpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_FATT_ATK1);    // missilestate
    deathstate: Ord(S_FATT_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_mandth);      // deathsound
    speed: 8;                         // speed
    radius: 48 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_FATT_RAISE1)    // raisestate
   ),
   (    // MT_FATSHOT
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_FATSHOT1);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_FATSHOTX1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 20 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 8;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_CHAINGUY
    doomednum: 65;                    // doomednum
    spawnstate: Ord(S_CPOS_STND);     // spawnstate
    spawnhealth: 70;                  // spawnhealth
    seestate: Ord(S_CPOS_RUN1);       // seestate
    seesound: Ord(sfx_posit2);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_CPOS_PAIN);      // painstate
    painchance: 170;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_CPOS_ATK1);    // missilestate
    deathstate: Ord(S_CPOS_DIE1);     // deathstate
    xdeathstate: Ord(S_CPOS_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_podth2);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_CPOS_RAISE1)    // raisestate
   ),
   (    // MT_TROOP
    doomednum: 3001;                  // doomednum
    spawnstate: Ord(S_TROO_STND);     // spawnstate
    spawnhealth: 60;                  // spawnhealth
    seestate: Ord(S_TROO_RUN1);       // seestate
    seesound: Ord(sfx_bgsit1);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_TROO_PAIN);      // painstate
    painchance: 200;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(S_TROO_ATK1);     // meleestate
    missilestate: Ord(S_TROO_ATK1);    // missilestate
    deathstate: Ord(S_TROO_DIE1);     // deathstate
    xdeathstate: Ord(S_TROO_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_bgdth1);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_bgact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_TROO_RAISE1)    // raisestate
   ),
   (    // MT_SERGEANT
    doomednum: 3002;                  // doomednum
    spawnstate: Ord(S_SARG_STND);     // spawnstate
    spawnhealth: 150;                 // spawnhealth
    seestate: Ord(S_SARG_RUN1);       // seestate
    seesound: Ord(sfx_sgtsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_sgtatk);     // attacksound
    painstate: Ord(S_SARG_PAIN);      // painstate
    painchance: 180;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_SARG_ATK1);     // meleestate
    missilestate: Ord(0);             // missilestate
    deathstate: Ord(S_SARG_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_sgtdth);      // deathsound
    speed: 10;                        // speed
    radius: 30 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_SARG_RAISE1)    // raisestate
   ),
   (    // MT_SHADOWS
    doomednum: 58;                    // doomednum
    spawnstate: Ord(S_SARG_STND);     // spawnstate
    spawnhealth: 150;                 // spawnhealth
    seestate: Ord(S_SARG_RUN1);       // seestate
    seesound: Ord(sfx_sgtsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_sgtatk);     // attacksound
    painstate: Ord(S_SARG_PAIN);      // painstate
    painchance: 180;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_SARG_ATK1);     // meleestate
    missilestate: Ord(0);             // missilestate
    deathstate: Ord(S_SARG_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_sgtdth);      // deathsound
    speed: 10;                        // speed
    radius: 30 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_SHADOW or MF_COUNTKILL;    // flags
    raisestate: Ord(S_SARG_RAISE1)    // raisestate
   ),
   (    // MT_HEAD
    doomednum: 3005;                  // doomednum
    spawnstate: Ord(S_HEAD_STND);     // spawnstate
    spawnhealth: 400;                 // spawnhealth
    seestate: Ord(S_HEAD_RUN1);       // seestate
    seesound: Ord(sfx_cacsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_HEAD_PAIN);      // painstate
    painchance: 128;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_HEAD_ATK1);    // missilestate
    deathstate: Ord(S_HEAD_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_cacdth);      // deathsound
    speed: 8;                         // speed
    radius: 31 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_FLOAT or MF_NOGRAVITY or MF_COUNTKILL;    // flags
    raisestate: Ord(S_HEAD_RAISE1)    // raisestate
   ),
   (    // MT_BRUISER
    doomednum: 3003;                  // doomednum
    spawnstate: Ord(S_BOSS_STND);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_BOSS_RUN1);       // seestate
    seesound: Ord(sfx_brssit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_BOSS_PAIN);      // painstate
    painchance: 50;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_BOSS_ATK1);     // meleestate
    missilestate: Ord(S_BOSS_ATK1);    // missilestate
    deathstate: Ord(S_BOSS_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_brsdth);      // deathsound
    speed: 8;                         // speed
    radius: 24 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_BOSS_RAISE1)    // raisestate
   ),
   (    // MT_BRUISERSHOT
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BRBALL1);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BRBALLX1);      // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 15 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 8;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_KNIGHT
    doomednum: 69;                    // doomednum
    spawnstate: Ord(S_BOS2_STND);     // spawnstate
    spawnhealth: 500;                 // spawnhealth
    seestate: Ord(S_BOS2_RUN1);       // seestate
    seesound: Ord(sfx_kntsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_BOS2_PAIN);      // painstate
    painchance: 50;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_BOS2_ATK1);     // meleestate
    missilestate: Ord(S_BOS2_ATK1);    // missilestate
    deathstate: Ord(S_BOS2_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_kntdth);      // deathsound
    speed: 8;                         // speed
    radius: 24 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_BOS2_RAISE1)    // raisestate
   ),
   (    // MT_SKULL
    doomednum: 3006;                  // doomednum
    spawnstate: Ord(S_SKULL_STND);    // spawnstate
    spawnhealth: 100;                 // spawnhealth
    seestate: Ord(S_SKULL_RUN1);      // seestate
    seesound: Ord(0);                 // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_sklatk);     // attacksound
    painstate: Ord(S_SKULL_PAIN);     // painstate
    painchance: 256;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SKULL_ATK1);    // missilestate
    deathstate: Ord(S_SKULL_DIE1);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 8;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 50;                         // mass
    damage: 3;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_FLOAT or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_SPIDER
    doomednum: 7;                     // doomednum
    spawnstate: Ord(S_SPID_STND);     // spawnstate
    spawnhealth: 3000;                // spawnhealth
    seestate: Ord(S_SPID_RUN1);       // seestate
    seesound: Ord(sfx_spisit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_shotgn);     // attacksound
    painstate: Ord(S_SPID_PAIN);      // painstate
    painchance: 40;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SPID_ATK1);    // missilestate
    deathstate: Ord(S_SPID_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_spidth);      // deathsound
    speed: 12;                        // speed
    radius: 128 * FRACUNIT;           // radius
    height: 100 * FRACUNIT;           // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BABY
    doomednum: 68;                    // doomednum
    spawnstate: Ord(S_BSPI_STND);     // spawnstate
    spawnhealth: 500;                 // spawnhealth
    seestate: Ord(S_BSPI_SIGHT);      // seestate
    seesound: Ord(sfx_bspsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_BSPI_PAIN);      // painstate
    painchance: 128;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_BSPI_ATK1);    // missilestate
    deathstate: Ord(S_BSPI_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_bspdth);      // deathsound
    speed: 12;                        // speed
    radius: 64 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 600;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_bspact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_BSPI_RAISE1)    // raisestate
   ),
   (    // MT_CYBORG
    doomednum: 16;                    // doomednum
    spawnstate: Ord(S_CYBER_STND);    // spawnstate
    spawnhealth: 4000;                // spawnhealth
    seestate: Ord(S_CYBER_RUN1);      // seestate
    seesound: Ord(sfx_cybsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_CYBER_PAIN);     // painstate
    painchance: 20;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_CYBER_ATK1);    // missilestate
    deathstate: Ord(S_CYBER_DIE1);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_cybdth);      // deathsound
    speed: 16;                        // speed
    radius: 40 * FRACUNIT;            // radius
    height: 110 * FRACUNIT;           // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_PAIN
    doomednum: 71;                    // doomednum
    spawnstate: Ord(S_PAIN_STND);     // spawnstate
    spawnhealth: 400;                 // spawnhealth
    seestate: Ord(S_PAIN_RUN1);       // seestate
    seesound: Ord(sfx_pesit);         // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_PAIN_PAIN);      // painstate
    painchance: 128;                  // painchance
    painsound: Ord(sfx_pepain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_PAIN_ATK1);    // missilestate
    deathstate: Ord(S_PAIN_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_pedth);       // deathsound
    speed: 8;                         // speed
    radius: 31 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_FLOAT or MF_NOGRAVITY or MF_COUNTKILL;    // flags
    raisestate: Ord(S_PAIN_RAISE1)    // raisestate
   ),
   (    // MT_WOLFSS
    doomednum: 84;                    // doomednum
    spawnstate: Ord(S_SSWV_STND);     // spawnstate
    spawnhealth: 50;                  // spawnhealth
    seestate: Ord(S_SSWV_RUN1);       // seestate
    seesound: Ord(sfx_sssit);         // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_SSWV_PAIN);      // painstate
    painchance: 170;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SSWV_ATK1);    // missilestate
    deathstate: Ord(S_SSWV_DIE1);     // deathstate
    xdeathstate: Ord(S_SSWV_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_ssdth);       // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_SSWV_RAISE1)    // raisestate
   ),
   (    // MT_KEEN
    doomednum: 72;                    // doomednum
    spawnstate: Ord(S_KEENSTND);      // spawnstate
    spawnhealth: 100;                 // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_KEENPAIN);       // painstate
    painchance: 256;                  // painchance
    painsound: Ord(sfx_keenpn);       // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_COMMKEEN);      // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_keendt);      // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 72 * FRACUNIT;            // height
    mass: 10000000;                   // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BOSSBRAIN
    doomednum: 88;                    // doomednum
    spawnstate: Ord(S_BRAIN);         // spawnstate
    spawnhealth: 250;                 // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_BRAIN_PAIN);     // painstate
    painchance: 255;                  // painchance
    painsound: Ord(sfx_bospn);        // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BRAIN_DIE1);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_bosdth);      // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 10000000;                   // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SHOOTABLE;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BOSSSPIT
    doomednum: 89;                    // doomednum
    spawnstate: Ord(S_BRAINEYE);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_BRAINEYESEE);     // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 32 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOSECTOR;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BOSSTARGET
    doomednum: 87;                    // doomednum
    spawnstate: Ord(S_NULL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 32 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOSECTOR;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_SPAWNSHOT
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_SPAWN1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_bospit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 32 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 3;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY or MF_NOCLIP;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_SPAWNFIRE
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_SPAWNFIRE1);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BARREL
    doomednum: 2035;                  // doomednum
    spawnstate: Ord(S_BAR1);          // spawnstate
    spawnhealth: 20;                  // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BEXP);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_barexp);      // deathsound
    speed: 0;                         // speed
    radius: 10 * FRACUNIT;            // radius
    height: 42 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_NOBLOOD;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_TROOPSHOT
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_TBALL1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_TBALLX1);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 3;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_HEADSHOT
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_RBALL1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_RBALLX1);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 5;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_ROCKET
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_ROCKET);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_rlaunc);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_EXPLODE1);      // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_barexp);      // deathsound
    speed: 20 * FRACUNIT;             // speed
    radius: 11 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 20;                       // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_PLASMA
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_PLASBALL);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_plasma);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_PLASEXP);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 25 * FRACUNIT;             // speed
    radius: 13 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 5;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BFG
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BFGSHOT);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(0);                 // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BFGLAND);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_rxplod);      // deathsound
    speed: 25 * FRACUNIT;             // speed
    radius: 13 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 100;                      // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_ARACHPLAZ
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_ARACH_PLAZ);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_plasma);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_ARACH_PLEX);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 25 * FRACUNIT;             // speed
    radius: 13 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 5;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_PUFF
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_PUFF1);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_BLOOD
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BLOOD1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_TFOG
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_TFOG);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_IFOG
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_IFOG);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_TELEPORTMAN
    doomednum: 14;                    // doomednum
    spawnstate: Ord(S_NULL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOSECTOR;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_EXTRABFG
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BFGEXP);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC0
    doomednum: 2018;                  // doomednum
    spawnstate: Ord(S_ARM1);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC1
    doomednum: 2019;                  // doomednum
    spawnstate: Ord(S_ARM2);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC2
    doomednum: 2014;                  // doomednum
    spawnstate: Ord(S_BON1);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC3
    doomednum: 2015;                  // doomednum
    spawnstate: Ord(S_BON2);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC4
    doomednum: 5;                     // doomednum
    spawnstate: Ord(S_BKEY);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC5
    doomednum: 13;                    // doomednum
    spawnstate: Ord(S_RKEY);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC6
    doomednum: 6;                     // doomednum
    spawnstate: Ord(S_YKEY);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC7
    doomednum: 39;                    // doomednum
    spawnstate: Ord(S_YSKULL);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC8
    doomednum: 38;                    // doomednum
    spawnstate: Ord(S_RSKULL);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC9
    doomednum: 40;                    // doomednum
    spawnstate: Ord(S_BSKULL);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC10
    doomednum: 2011;                  // doomednum
    spawnstate: Ord(S_STIM);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC11
    doomednum: 2012;                  // doomednum
    spawnstate: Ord(S_MEDI);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC12
    doomednum: 2013;                  // doomednum
    spawnstate: Ord(S_SOUL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_INV
    doomednum: 2022;                  // doomednum
    spawnstate: Ord(S_PINV);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC13
    doomednum: 2023;                  // doomednum
    spawnstate: Ord(S_PSTR);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_INS
    doomednum: 2024;                  // doomednum
    spawnstate: Ord(S_PINS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC14
    doomednum: 2025;                  // doomednum
    spawnstate: Ord(S_SUIT);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC15
    doomednum: 2026;                  // doomednum
    spawnstate: Ord(S_PMAP);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC16
    doomednum: 2045;                  // doomednum
    spawnstate: Ord(S_PVIS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MEGA
    doomednum: 83;                    // doomednum
    spawnstate: Ord(S_MEGA);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_CLIP
    doomednum: 2007;                  // doomednum
    spawnstate: Ord(S_CLIP);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC17
    doomednum: 2048;                  // doomednum
    spawnstate: Ord(S_AMMO);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC18
    doomednum: 2010;                  // doomednum
    spawnstate: Ord(S_ROCK);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC19
    doomednum: 2046;                  // doomednum
    spawnstate: Ord(S_BROK);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC20
    doomednum: 2047;                  // doomednum
    spawnstate: Ord(S_CELL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC21
    doomednum: 17;                    // doomednum
    spawnstate: Ord(S_CELP);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC22
    doomednum: 2008;                  // doomednum
    spawnstate: Ord(S_SHEL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC23
    doomednum: 2049;                  // doomednum
    spawnstate: Ord(S_SBOX);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC24
    doomednum: 8;                     // doomednum
    spawnstate: Ord(S_BPAK);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC25
    doomednum: 2006;                  // doomednum
    spawnstate: Ord(S_BFUG);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_CHAINGUN
    doomednum: 2002;                  // doomednum
    spawnstate: Ord(S_MGUN);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC26
    doomednum: 2005;                  // doomednum
    spawnstate: Ord(S_CSAW);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC27
    doomednum: 2003;                  // doomednum
    spawnstate: Ord(S_LAUN);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC28
    doomednum: 2004;                  // doomednum
    spawnstate: Ord(S_PLAS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_SHOTGUN
    doomednum: 2001;                  // doomednum
    spawnstate: Ord(S_SHOT);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_SUPERSHOTGUN
    doomednum: 82;                    // doomednum
    spawnstate: Ord(S_SHOT2);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC29
    doomednum: 85;                    // doomednum
    spawnstate: Ord(S_TECHLAMP);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC30
    doomednum: 86;                    // doomednum
    spawnstate: Ord(S_TECH2LAMP);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC31
    doomednum: 2028;                  // doomednum
    spawnstate: Ord(S_COLU);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC32
    doomednum: 30;                    // doomednum
    spawnstate: Ord(S_TALLGRNCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC33
    doomednum: 31;                    // doomednum
    spawnstate: Ord(S_SHRTGRNCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC34
    doomednum: 32;                    // doomednum
    spawnstate: Ord(S_TALLREDCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC35
    doomednum: 33;                    // doomednum
    spawnstate: Ord(S_SHRTREDCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC36
    doomednum: 37;                    // doomednum
    spawnstate: Ord(S_SKULLCOL);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC37
    doomednum: 36;                    // doomednum
    spawnstate: Ord(S_HEARTCOL);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC38
    doomednum: 41;                    // doomednum
    spawnstate: Ord(S_EVILEYE);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC39
    doomednum: 42;                    // doomednum
    spawnstate: Ord(S_FLOATSKULL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC40
    doomednum: 43;                    // doomednum
    spawnstate: Ord(S_TORCHTREE);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC41
    doomednum: 44;                    // doomednum
    spawnstate: Ord(S_BLUETORCH);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC42
    doomednum: 45;                    // doomednum
    spawnstate: Ord(S_GREENTORCH);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC43
    doomednum: 46;                    // doomednum
    spawnstate: Ord(S_REDTORCH);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC44
    doomednum: 55;                    // doomednum
    spawnstate: Ord(S_BTORCHSHRT);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC45
    doomednum: 56;                    // doomednum
    spawnstate: Ord(S_GTORCHSHRT);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC46
    doomednum: 57;                    // doomednum
    spawnstate: Ord(S_RTORCHSHRT);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC47
    doomednum: 47;                    // doomednum
    spawnstate: Ord(S_STALAGTITE);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC48
    doomednum: 48;                    // doomednum
    spawnstate: Ord(S_TECHPILLAR);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC49
    doomednum: 34;                    // doomednum
    spawnstate: Ord(S_CANDLESTIK);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC50
    doomednum: 35;                    // doomednum
    spawnstate: Ord(S_CANDELABRA);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC51
    doomednum: 49;                    // doomednum
    spawnstate: Ord(S_BLOODYTWITCH);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC52
    doomednum: 50;                    // doomednum
    spawnstate: Ord(S_MEAT2);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 84 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC53
    doomednum: 51;                    // doomednum
    spawnstate: Ord(S_MEAT3);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 84 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC54
    doomednum: 52;                    // doomednum
    spawnstate: Ord(S_MEAT4);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC55
    doomednum: 53;                    // doomednum
    spawnstate: Ord(S_MEAT5);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 52 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC56
    doomednum: 59;                    // doomednum
    spawnstate: Ord(S_MEAT2);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 84 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC57
    doomednum: 60;                    // doomednum
    spawnstate: Ord(S_MEAT4);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC58
    doomednum: 61;                    // doomednum
    spawnstate: Ord(S_MEAT3);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 52 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC59
    doomednum: 62;                    // doomednum
    spawnstate: Ord(S_MEAT5);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 52 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC60
    doomednum: 63;                    // doomednum
    spawnstate: Ord(S_BLOODYTWITCH);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC61
    doomednum: 22;                    // doomednum
    spawnstate: Ord(S_HEAD_DIE6);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC62
    doomednum: 15;                    // doomednum
    spawnstate: Ord(S_PLAY_DIE7);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC63
    doomednum: 18;                    // doomednum
    spawnstate: Ord(S_POSS_DIE5);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC64
    doomednum: 21;                    // doomednum
    spawnstate: Ord(S_SARG_DIE6);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC65
    doomednum: 23;                    // doomednum
    spawnstate: Ord(S_SKULL_DIE6);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC66
    doomednum: 20;                    // doomednum
    spawnstate: Ord(S_TROO_DIE5);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC67
    doomednum: 19;                    // doomednum
    spawnstate: Ord(S_SPOS_DIE5);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC68
    doomednum: 10;                    // doomednum
    spawnstate: Ord(S_PLAY_XDIE9);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC69
    doomednum: 12;                    // doomednum
    spawnstate: Ord(S_PLAY_XDIE9);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC70
    doomednum: 28;                    // doomednum
    spawnstate: Ord(S_HEADSONSTICK);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC71
    doomednum: 24;                    // doomednum
    spawnstate: Ord(S_GIBS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC72
    doomednum: 27;                    // doomednum
    spawnstate: Ord(S_HEADONASTICK);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC73
    doomednum: 29;                    // doomednum
    spawnstate: Ord(S_HEADCANDLES);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC74
    doomednum: 25;                    // doomednum
    spawnstate: Ord(S_DEADSTICK);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC75
    doomednum: 26;                    // doomednum
    spawnstate: Ord(S_LIVESTICK);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC76
    doomednum: 54;                    // doomednum
    spawnstate: Ord(S_BIGTREE);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 32 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC77
    doomednum: 70;                    // doomednum
    spawnstate: Ord(S_BBAR1);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC78
    doomednum: 73;                    // doomednum
    spawnstate: Ord(S_HANGNOGUTS);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 88 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC79
    doomednum: 74;                    // doomednum
    spawnstate: Ord(S_HANGBNOBRAIN);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 88 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC80
    doomednum: 75;                    // doomednum
    spawnstate: Ord(S_HANGTLOOKDN);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC81
    doomednum: 76;                    // doomednum
    spawnstate: Ord(S_HANGTSKULL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC82
    doomednum: 77;                    // doomednum
    spawnstate: Ord(S_HANGTLOOKUP);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC83
    doomednum: 78;                    // doomednum
    spawnstate: Ord(S_HANGTNOBRAIN);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC84
    doomednum: 79;                    // doomednum
    spawnstate: Ord(S_COLONGIBS);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC85
    doomednum: 80;                    // doomednum
    spawnstate: Ord(S_SMALLPOOL);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    raisestate: Ord(S_NULL)           // raisestate
   ),
   (    // MT_MISC86
    doomednum: 81;                    // doomednum
    spawnstate: Ord(S_BRAINSTEM);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    raisestate: Ord(S_NULL)           // raisestate
   )
  );

procedure I_InitInfo;
begin
  states := @states1;
  sprnames := @sprnames1;
  mobjinfo := @mobjinfo1;

  states[1].action.acp1 := @A_Light0; // S_LIGHTDONE
  states[2].action.acp1 := @A_WeaponReady; // S_PUNCH
  states[3].action.acp1 := @A_Lower; // S_PUNCHDOWN
  states[4].action.acp1 := @A_Raise; // S_PUNCHUP
  states[6].action.acp1 := @A_Punch; // S_PUNCH2
  states[9].action.acp1 := @A_ReFire; // S_PUNCH5
  states[10].action.acp1 := @A_WeaponReady; // S_PISTOL
  states[11].action.acp1 := @A_Lower; // S_PISTOLDOWN
  states[12].action.acp1 := @A_Raise; // S_PISTOLUP
  states[14].action.acp1 := @A_FirePistol; // S_PISTOL2
  states[16].action.acp1 := @A_ReFire; // S_PISTOL4
  states[17].action.acp1 := @A_Light1; // S_PISTOLFLASH
  states[18].action.acp1 := @A_WeaponReady; // S_SGUN
  states[19].action.acp1 := @A_Lower; // S_SGUNDOWN
  states[20].action.acp1 := @A_Raise; // S_SGUNUP
  states[22].action.acp1 := @A_FireShotgun; // S_SGUN2
  states[29].action.acp1 := @A_ReFire; // S_SGUN9
  states[30].action.acp1 := @A_Light1; // S_SGUNFLASH1
  states[31].action.acp1 := @A_Light2; // S_SGUNFLASH2
  states[32].action.acp1 := @A_WeaponReady; // S_DSGUN
  states[33].action.acp1 := @A_Lower; // S_DSGUNDOWN
  states[34].action.acp1 := @A_Raise; // S_DSGUNUP
  states[36].action.acp1 := @A_FireShotgun2; // S_DSGUN2
  states[38].action.acp1 := @A_CheckReload; // S_DSGUN4
  states[39].action.acp1 := @A_OpenShotgun2; // S_DSGUN5
  states[41].action.acp1 := @A_LoadShotgun2; // S_DSGUN7
  states[43].action.acp1 := @A_CloseShotgun2; // S_DSGUN9
  states[44].action.acp1 := @A_ReFire; // S_DSGUN10
  states[47].action.acp1 := @A_Light1; // S_DSGUNFLASH1
  states[48].action.acp1 := @A_Light2; // S_DSGUNFLASH2
  states[49].action.acp1 := @A_WeaponReady; // S_CHAIN
  states[50].action.acp1 := @A_Lower; // S_CHAINDOWN
  states[51].action.acp1 := @A_Raise; // S_CHAINUP
  states[52].action.acp1 := @A_FireCGun; // S_CHAIN1
  states[53].action.acp1 := @A_FireCGun; // S_CHAIN2
  states[54].action.acp1 := @A_ReFire; // S_CHAIN3
  states[55].action.acp1 := @A_Light1; // S_CHAINFLASH1
  states[56].action.acp1 := @A_Light2; // S_CHAINFLASH2
  states[57].action.acp1 := @A_WeaponReady; // S_MISSILE
  states[58].action.acp1 := @A_Lower; // S_MISSILEDOWN
  states[59].action.acp1 := @A_Raise; // S_MISSILEUP
  states[60].action.acp1 := @A_GunFlash; // S_MISSILE1
  states[61].action.acp1 := @A_FireMissile; // S_MISSILE2
  states[62].action.acp1 := @A_ReFire; // S_MISSILE3
  states[63].action.acp1 := @A_Light1; // S_MISSILEFLASH1
  states[65].action.acp1 := @A_Light2; // S_MISSILEFLASH3
  states[66].action.acp1 := @A_Light2; // S_MISSILEFLASH4
  states[67].action.acp1 := @A_WeaponReady; // S_SAW
  states[68].action.acp1 := @A_WeaponReady; // S_SAWB
  states[69].action.acp1 := @A_Lower; // S_SAWDOWN
  states[70].action.acp1 := @A_Raise; // S_SAWUP
  states[71].action.acp1 := @A_Saw; // S_SAW1
  states[72].action.acp1 := @A_Saw; // S_SAW2
  states[73].action.acp1 := @A_ReFire; // S_SAW3
  states[74].action.acp1 := @A_WeaponReady; // S_PLASMA
  states[75].action.acp1 := @A_Lower; // S_PLASMADOWN
  states[76].action.acp1 := @A_Raise; // S_PLASMAUP
  states[77].action.acp1 := @A_FirePlasma; // S_PLASMA1
  states[78].action.acp1 := @A_ReFire; // S_PLASMA2
  states[79].action.acp1 := @A_Light1; // S_PLASMAFLASH1
  states[80].action.acp1 := @A_Light1; // S_PLASMAFLASH2
  states[81].action.acp1 := @A_WeaponReady; // S_BFG
  states[82].action.acp1 := @A_Lower; // S_BFGDOWN
  states[83].action.acp1 := @A_Raise; // S_BFGUP
  states[84].action.acp1 := @A_BFGsound; // S_BFG1
  states[85].action.acp1 := @A_GunFlash; // S_BFG2
  states[86].action.acp1 := @A_FireBFG; // S_BFG3
  states[87].action.acp1 := @A_ReFire; // S_BFG4
  states[88].action.acp1 := @A_Light1; // S_BFGFLASH1
  states[89].action.acp1 := @A_Light2; // S_BFGFLASH2
  states[119].action.acp1 := @A_BFGSpray; // S_BFGLAND3
  states[127].action.acp1 := @A_Explode; // S_EXPLODE1
  states[157].action.acp1 := @A_Pain; // S_PLAY_PAIN2
  states[159].action.acp1 := @A_PlayerScream; // S_PLAY_DIE2
  states[160].action.acp1 := @A_Fall; // S_PLAY_DIE3
  states[166].action.acp1 := @A_XScream; // S_PLAY_XDIE2
  states[167].action.acp1 := @A_Fall; // S_PLAY_XDIE3
  states[174].action.acp1 := @A_Look; // S_POSS_STND
  states[175].action.acp1 := @A_Look; // S_POSS_STND2
  states[176].action.acp1 := @A_Chase; // S_POSS_RUN1
  states[177].action.acp1 := @A_Chase; // S_POSS_RUN2
  states[178].action.acp1 := @A_Chase; // S_POSS_RUN3
  states[179].action.acp1 := @A_Chase; // S_POSS_RUN4
  states[180].action.acp1 := @A_Chase; // S_POSS_RUN5
  states[181].action.acp1 := @A_Chase; // S_POSS_RUN6
  states[182].action.acp1 := @A_Chase; // S_POSS_RUN7
  states[183].action.acp1 := @A_Chase; // S_POSS_RUN8
  states[184].action.acp1 := @A_FaceTarget; // S_POSS_ATK1
  states[185].action.acp1 := @A_PosAttack; // S_POSS_ATK2
  states[188].action.acp1 := @A_Pain; // S_POSS_PAIN2
  states[190].action.acp1 := @A_Scream; // S_POSS_DIE2
  states[191].action.acp1 := @A_Fall; // S_POSS_DIE3
  states[195].action.acp1 := @A_XScream; // S_POSS_XDIE2
  states[196].action.acp1 := @A_Fall; // S_POSS_XDIE3
  states[207].action.acp1 := @A_Look; // S_SPOS_STND
  states[208].action.acp1 := @A_Look; // S_SPOS_STND2
  states[209].action.acp1 := @A_Chase; // S_SPOS_RUN1
  states[210].action.acp1 := @A_Chase; // S_SPOS_RUN2
  states[211].action.acp1 := @A_Chase; // S_SPOS_RUN3
  states[212].action.acp1 := @A_Chase; // S_SPOS_RUN4
  states[213].action.acp1 := @A_Chase; // S_SPOS_RUN5
  states[214].action.acp1 := @A_Chase; // S_SPOS_RUN6
  states[215].action.acp1 := @A_Chase; // S_SPOS_RUN7
  states[216].action.acp1 := @A_Chase; // S_SPOS_RUN8
  states[217].action.acp1 := @A_FaceTarget; // S_SPOS_ATK1
  states[218].action.acp1 := @A_SPosAttack; // S_SPOS_ATK2
  states[221].action.acp1 := @A_Pain; // S_SPOS_PAIN2
  states[223].action.acp1 := @A_Scream; // S_SPOS_DIE2
  states[224].action.acp1 := @A_Fall; // S_SPOS_DIE3
  states[228].action.acp1 := @A_XScream; // S_SPOS_XDIE2
  states[229].action.acp1 := @A_Fall; // S_SPOS_XDIE3
  states[241].action.acp1 := @A_Look; // S_VILE_STND
  states[242].action.acp1 := @A_Look; // S_VILE_STND2
  states[243].action.acp1 := @A_VileChase; // S_VILE_RUN1
  states[244].action.acp1 := @A_VileChase; // S_VILE_RUN2
  states[245].action.acp1 := @A_VileChase; // S_VILE_RUN3
  states[246].action.acp1 := @A_VileChase; // S_VILE_RUN4
  states[247].action.acp1 := @A_VileChase; // S_VILE_RUN5
  states[248].action.acp1 := @A_VileChase; // S_VILE_RUN6
  states[249].action.acp1 := @A_VileChase; // S_VILE_RUN7
  states[250].action.acp1 := @A_VileChase; // S_VILE_RUN8
  states[251].action.acp1 := @A_VileChase; // S_VILE_RUN9
  states[252].action.acp1 := @A_VileChase; // S_VILE_RUN10
  states[253].action.acp1 := @A_VileChase; // S_VILE_RUN11
  states[254].action.acp1 := @A_VileChase; // S_VILE_RUN12
  states[255].action.acp1 := @A_VileStart; // S_VILE_ATK1
  states[256].action.acp1 := @A_FaceTarget; // S_VILE_ATK2
  states[257].action.acp1 := @A_VileTarget; // S_VILE_ATK3
  states[258].action.acp1 := @A_FaceTarget; // S_VILE_ATK4
  states[259].action.acp1 := @A_FaceTarget; // S_VILE_ATK5
  states[260].action.acp1 := @A_FaceTarget; // S_VILE_ATK6
  states[261].action.acp1 := @A_FaceTarget; // S_VILE_ATK7
  states[262].action.acp1 := @A_FaceTarget; // S_VILE_ATK8
  states[263].action.acp1 := @A_FaceTarget; // S_VILE_ATK9
  states[264].action.acp1 := @A_VileAttack; // S_VILE_ATK10
  states[270].action.acp1 := @A_Pain; // S_VILE_PAIN2
  states[272].action.acp1 := @A_Scream; // S_VILE_DIE2
  states[273].action.acp1 := @A_Fall; // S_VILE_DIE3
  states[281].action.acp1 := @A_StartFire; // S_FIRE1
  states[282].action.acp1 := @A_Fire; // S_FIRE2
  states[283].action.acp1 := @A_Fire; // S_FIRE3
  states[284].action.acp1 := @A_Fire; // S_FIRE4
  states[285].action.acp1 := @A_FireCrackle; // S_FIRE5
  states[286].action.acp1 := @A_Fire; // S_FIRE6
  states[287].action.acp1 := @A_Fire; // S_FIRE7
  states[288].action.acp1 := @A_Fire; // S_FIRE8
  states[289].action.acp1 := @A_Fire; // S_FIRE9
  states[290].action.acp1 := @A_Fire; // S_FIRE10
  states[291].action.acp1 := @A_Fire; // S_FIRE11
  states[292].action.acp1 := @A_Fire; // S_FIRE12
  states[293].action.acp1 := @A_Fire; // S_FIRE13
  states[294].action.acp1 := @A_Fire; // S_FIRE14
  states[295].action.acp1 := @A_Fire; // S_FIRE15
  states[296].action.acp1 := @A_Fire; // S_FIRE16
  states[297].action.acp1 := @A_Fire; // S_FIRE17
  states[298].action.acp1 := @A_Fire; // S_FIRE18
  states[299].action.acp1 := @A_FireCrackle; // S_FIRE19
  states[300].action.acp1 := @A_Fire; // S_FIRE20
  states[301].action.acp1 := @A_Fire; // S_FIRE21
  states[302].action.acp1 := @A_Fire; // S_FIRE22
  states[303].action.acp1 := @A_Fire; // S_FIRE23
  states[304].action.acp1 := @A_Fire; // S_FIRE24
  states[305].action.acp1 := @A_Fire; // S_FIRE25
  states[306].action.acp1 := @A_Fire; // S_FIRE26
  states[307].action.acp1 := @A_Fire; // S_FIRE27
  states[308].action.acp1 := @A_Fire; // S_FIRE28
  states[309].action.acp1 := @A_Fire; // S_FIRE29
  states[310].action.acp1 := @A_Fire; // S_FIRE30
  states[316].action.acp1 := @A_Tracer; // S_TRACER
  states[317].action.acp1 := @A_Tracer; // S_TRACER2
  states[321].action.acp1 := @A_Look; // S_SKEL_STND
  states[322].action.acp1 := @A_Look; // S_SKEL_STND2
  states[323].action.acp1 := @A_Chase; // S_SKEL_RUN1
  states[324].action.acp1 := @A_Chase; // S_SKEL_RUN2
  states[325].action.acp1 := @A_Chase; // S_SKEL_RUN3
  states[326].action.acp1 := @A_Chase; // S_SKEL_RUN4
  states[327].action.acp1 := @A_Chase; // S_SKEL_RUN5
  states[328].action.acp1 := @A_Chase; // S_SKEL_RUN6
  states[329].action.acp1 := @A_Chase; // S_SKEL_RUN7
  states[330].action.acp1 := @A_Chase; // S_SKEL_RUN8
  states[331].action.acp1 := @A_Chase; // S_SKEL_RUN9
  states[332].action.acp1 := @A_Chase; // S_SKEL_RUN10
  states[333].action.acp1 := @A_Chase; // S_SKEL_RUN11
  states[334].action.acp1 := @A_Chase; // S_SKEL_RUN12
  states[335].action.acp1 := @A_FaceTarget; // S_SKEL_FIST1
  states[336].action.acp1 := @A_SkelWhoosh; // S_SKEL_FIST2
  states[337].action.acp1 := @A_FaceTarget; // S_SKEL_FIST3
  states[338].action.acp1 := @A_SkelFist; // S_SKEL_FIST4
  states[339].action.acp1 := @A_FaceTarget; // S_SKEL_MISS1
  states[340].action.acp1 := @A_FaceTarget; // S_SKEL_MISS2
  states[341].action.acp1 := @A_SkelMissile; // S_SKEL_MISS3
  states[342].action.acp1 := @A_FaceTarget; // S_SKEL_MISS4
  states[344].action.acp1 := @A_Pain; // S_SKEL_PAIN2
  states[347].action.acp1 := @A_Scream; // S_SKEL_DIE3
  states[348].action.acp1 := @A_Fall; // S_SKEL_DIE4
  states[362].action.acp1 := @A_Look; // S_FATT_STND
  states[363].action.acp1 := @A_Look; // S_FATT_STND2
  states[364].action.acp1 := @A_Chase; // S_FATT_RUN1
  states[365].action.acp1 := @A_Chase; // S_FATT_RUN2
  states[366].action.acp1 := @A_Chase; // S_FATT_RUN3
  states[367].action.acp1 := @A_Chase; // S_FATT_RUN4
  states[368].action.acp1 := @A_Chase; // S_FATT_RUN5
  states[369].action.acp1 := @A_Chase; // S_FATT_RUN6
  states[370].action.acp1 := @A_Chase; // S_FATT_RUN7
  states[371].action.acp1 := @A_Chase; // S_FATT_RUN8
  states[372].action.acp1 := @A_Chase; // S_FATT_RUN9
  states[373].action.acp1 := @A_Chase; // S_FATT_RUN10
  states[374].action.acp1 := @A_Chase; // S_FATT_RUN11
  states[375].action.acp1 := @A_Chase; // S_FATT_RUN12
  states[376].action.acp1 := @A_FatRaise; // S_FATT_ATK1
  states[377].action.acp1 := @A_FatAttack1; // S_FATT_ATK2
  states[378].action.acp1 := @A_FaceTarget; // S_FATT_ATK3
  states[379].action.acp1 := @A_FaceTarget; // S_FATT_ATK4
  states[380].action.acp1 := @A_FatAttack2; // S_FATT_ATK5
  states[381].action.acp1 := @A_FaceTarget; // S_FATT_ATK6
  states[382].action.acp1 := @A_FaceTarget; // S_FATT_ATK7
  states[383].action.acp1 := @A_FatAttack3; // S_FATT_ATK8
  states[384].action.acp1 := @A_FaceTarget; // S_FATT_ATK9
  states[385].action.acp1 := @A_FaceTarget; // S_FATT_ATK10
  states[387].action.acp1 := @A_Pain; // S_FATT_PAIN2
  states[389].action.acp1 := @A_Scream; // S_FATT_DIE2
  states[390].action.acp1 := @A_Fall; // S_FATT_DIE3
  states[397].action.acp1 := @A_BossDeath; // S_FATT_DIE10
  states[406].action.acp1 := @A_Look; // S_CPOS_STND
  states[407].action.acp1 := @A_Look; // S_CPOS_STND2
  states[408].action.acp1 := @A_Chase; // S_CPOS_RUN1
  states[409].action.acp1 := @A_Chase; // S_CPOS_RUN2
  states[410].action.acp1 := @A_Chase; // S_CPOS_RUN3
  states[411].action.acp1 := @A_Chase; // S_CPOS_RUN4
  states[412].action.acp1 := @A_Chase; // S_CPOS_RUN5
  states[413].action.acp1 := @A_Chase; // S_CPOS_RUN6
  states[414].action.acp1 := @A_Chase; // S_CPOS_RUN7
  states[415].action.acp1 := @A_Chase; // S_CPOS_RUN8
  states[416].action.acp1 := @A_FaceTarget; // S_CPOS_ATK1
  states[417].action.acp1 := @A_CPosAttack; // S_CPOS_ATK2
  states[418].action.acp1 := @A_CPosAttack; // S_CPOS_ATK3
  states[419].action.acp1 := @A_CPosRefire; // S_CPOS_ATK4
  states[421].action.acp1 := @A_Pain; // S_CPOS_PAIN2
  states[423].action.acp1 := @A_Scream; // S_CPOS_DIE2
  states[424].action.acp1 := @A_Fall; // S_CPOS_DIE3
  states[430].action.acp1 := @A_XScream; // S_CPOS_XDIE2
  states[431].action.acp1 := @A_Fall; // S_CPOS_XDIE3
  states[442].action.acp1 := @A_Look; // S_TROO_STND
  states[443].action.acp1 := @A_Look; // S_TROO_STND2
  states[444].action.acp1 := @A_Chase; // S_TROO_RUN1
  states[445].action.acp1 := @A_Chase; // S_TROO_RUN2
  states[446].action.acp1 := @A_Chase; // S_TROO_RUN3
  states[447].action.acp1 := @A_Chase; // S_TROO_RUN4
  states[448].action.acp1 := @A_Chase; // S_TROO_RUN5
  states[449].action.acp1 := @A_Chase; // S_TROO_RUN6
  states[450].action.acp1 := @A_Chase; // S_TROO_RUN7
  states[451].action.acp1 := @A_Chase; // S_TROO_RUN8
  states[452].action.acp1 := @A_FaceTarget; // S_TROO_ATK1
  states[453].action.acp1 := @A_FaceTarget; // S_TROO_ATK2
  states[454].action.acp1 := @A_TroopAttack; // S_TROO_ATK3
  states[456].action.acp1 := @A_Pain; // S_TROO_PAIN2
  states[458].action.acp1 := @A_Scream; // S_TROO_DIE2
  states[460].action.acp1 := @A_Fall; // S_TROO_DIE4
  states[463].action.acp1 := @A_XScream; // S_TROO_XDIE2
  states[465].action.acp1 := @A_Fall; // S_TROO_XDIE4
  states[475].action.acp1 := @A_Look; // S_SARG_STND
  states[476].action.acp1 := @A_Look; // S_SARG_STND2
  states[477].action.acp1 := @A_Chase; // S_SARG_RUN1
  states[478].action.acp1 := @A_Chase; // S_SARG_RUN2
  states[479].action.acp1 := @A_Chase; // S_SARG_RUN3
  states[480].action.acp1 := @A_Chase; // S_SARG_RUN4
  states[481].action.acp1 := @A_Chase; // S_SARG_RUN5
  states[482].action.acp1 := @A_Chase; // S_SARG_RUN6
  states[483].action.acp1 := @A_Chase; // S_SARG_RUN7
  states[484].action.acp1 := @A_Chase; // S_SARG_RUN8
  states[485].action.acp1 := @A_FaceTarget; // S_SARG_ATK1
  states[486].action.acp1 := @A_FaceTarget; // S_SARG_ATK2
  states[487].action.acp1 := @A_SargAttack; // S_SARG_ATK3
  states[489].action.acp1 := @A_Pain; // S_SARG_PAIN2
  states[491].action.acp1 := @A_Scream; // S_SARG_DIE2
  states[493].action.acp1 := @A_Fall; // S_SARG_DIE4
  states[502].action.acp1 := @A_Look; // S_HEAD_STND
  states[503].action.acp1 := @A_Chase; // S_HEAD_RUN1
  states[504].action.acp1 := @A_FaceTarget; // S_HEAD_ATK1
  states[505].action.acp1 := @A_FaceTarget; // S_HEAD_ATK2
  states[506].action.acp1 := @A_HeadAttack; // S_HEAD_ATK3
  states[508].action.acp1 := @A_Pain; // S_HEAD_PAIN2
  states[511].action.acp1 := @A_Scream; // S_HEAD_DIE2
  states[514].action.acp1 := @A_Fall; // S_HEAD_DIE5
  states[527].action.acp1 := @A_Look; // S_BOSS_STND
  states[528].action.acp1 := @A_Look; // S_BOSS_STND2
  states[529].action.acp1 := @A_Chase; // S_BOSS_RUN1
  states[530].action.acp1 := @A_Chase; // S_BOSS_RUN2
  states[531].action.acp1 := @A_Chase; // S_BOSS_RUN3
  states[532].action.acp1 := @A_Chase; // S_BOSS_RUN4
  states[533].action.acp1 := @A_Chase; // S_BOSS_RUN5
  states[534].action.acp1 := @A_Chase; // S_BOSS_RUN6
  states[535].action.acp1 := @A_Chase; // S_BOSS_RUN7
  states[536].action.acp1 := @A_Chase; // S_BOSS_RUN8
  states[537].action.acp1 := @A_FaceTarget; // S_BOSS_ATK1
  states[538].action.acp1 := @A_FaceTarget; // S_BOSS_ATK2
  states[539].action.acp1 := @A_BruisAttack; // S_BOSS_ATK3
  states[541].action.acp1 := @A_Pain; // S_BOSS_PAIN2
  states[543].action.acp1 := @A_Scream; // S_BOSS_DIE2
  states[545].action.acp1 := @A_Fall; // S_BOSS_DIE4
  states[548].action.acp1 := @A_BossDeath; // S_BOSS_DIE7
  states[556].action.acp1 := @A_Look; // S_BOS2_STND
  states[557].action.acp1 := @A_Look; // S_BOS2_STND2
  states[558].action.acp1 := @A_Chase; // S_BOS2_RUN1
  states[559].action.acp1 := @A_Chase; // S_BOS2_RUN2
  states[560].action.acp1 := @A_Chase; // S_BOS2_RUN3
  states[561].action.acp1 := @A_Chase; // S_BOS2_RUN4
  states[562].action.acp1 := @A_Chase; // S_BOS2_RUN5
  states[563].action.acp1 := @A_Chase; // S_BOS2_RUN6
  states[564].action.acp1 := @A_Chase; // S_BOS2_RUN7
  states[565].action.acp1 := @A_Chase; // S_BOS2_RUN8
  states[566].action.acp1 := @A_FaceTarget; // S_BOS2_ATK1
  states[567].action.acp1 := @A_FaceTarget; // S_BOS2_ATK2
  states[568].action.acp1 := @A_BruisAttack; // S_BOS2_ATK3
  states[570].action.acp1 := @A_Pain; // S_BOS2_PAIN2
  states[572].action.acp1 := @A_Scream; // S_BOS2_DIE2
  states[574].action.acp1 := @A_Fall; // S_BOS2_DIE4
  states[585].action.acp1 := @A_Look; // S_SKULL_STND
  states[586].action.acp1 := @A_Look; // S_SKULL_STND2
  states[587].action.acp1 := @A_Chase; // S_SKULL_RUN1
  states[588].action.acp1 := @A_Chase; // S_SKULL_RUN2
  states[589].action.acp1 := @A_FaceTarget; // S_SKULL_ATK1
  states[590].action.acp1 := @A_SkullAttack; // S_SKULL_ATK2
  states[594].action.acp1 := @A_Pain; // S_SKULL_PAIN2
  states[596].action.acp1 := @A_Scream; // S_SKULL_DIE2
  states[598].action.acp1 := @A_Fall; // S_SKULL_DIE4
  states[601].action.acp1 := @A_Look; // S_SPID_STND
  states[602].action.acp1 := @A_Look; // S_SPID_STND2
  states[603].action.acp1 := @A_Metal; // S_SPID_RUN1
  states[604].action.acp1 := @A_Chase; // S_SPID_RUN2
  states[605].action.acp1 := @A_Chase; // S_SPID_RUN3
  states[606].action.acp1 := @A_Chase; // S_SPID_RUN4
  states[607].action.acp1 := @A_Metal; // S_SPID_RUN5
  states[608].action.acp1 := @A_Chase; // S_SPID_RUN6
  states[609].action.acp1 := @A_Chase; // S_SPID_RUN7
  states[610].action.acp1 := @A_Chase; // S_SPID_RUN8
  states[611].action.acp1 := @A_Metal; // S_SPID_RUN9
  states[612].action.acp1 := @A_Chase; // S_SPID_RUN10
  states[613].action.acp1 := @A_Chase; // S_SPID_RUN11
  states[614].action.acp1 := @A_Chase; // S_SPID_RUN12
  states[615].action.acp1 := @A_FaceTarget; // S_SPID_ATK1
  states[616].action.acp1 := @A_SPosAttack; // S_SPID_ATK2
  states[617].action.acp1 := @A_SPosAttack; // S_SPID_ATK3
  states[618].action.acp1 := @A_SpidRefire; // S_SPID_ATK4
  states[620].action.acp1 := @A_Pain; // S_SPID_PAIN2
  states[621].action.acp1 := @A_Scream; // S_SPID_DIE1
  states[622].action.acp1 := @A_Fall; // S_SPID_DIE2
  states[631].action.acp1 := @A_BossDeath; // S_SPID_DIE11
  states[632].action.acp1 := @A_Look; // S_BSPI_STND
  states[633].action.acp1 := @A_Look; // S_BSPI_STND2
  states[635].action.acp1 := @A_BabyMetal; // S_BSPI_RUN1
  states[636].action.acp1 := @A_Chase; // S_BSPI_RUN2
  states[637].action.acp1 := @A_Chase; // S_BSPI_RUN3
  states[638].action.acp1 := @A_Chase; // S_BSPI_RUN4
  states[639].action.acp1 := @A_Chase; // S_BSPI_RUN5
  states[640].action.acp1 := @A_Chase; // S_BSPI_RUN6
  states[641].action.acp1 := @A_BabyMetal; // S_BSPI_RUN7
  states[642].action.acp1 := @A_Chase; // S_BSPI_RUN8
  states[643].action.acp1 := @A_Chase; // S_BSPI_RUN9
  states[644].action.acp1 := @A_Chase; // S_BSPI_RUN10
  states[645].action.acp1 := @A_Chase; // S_BSPI_RUN11
  states[646].action.acp1 := @A_Chase; // S_BSPI_RUN12
  states[647].action.acp1 := @A_FaceTarget; // S_BSPI_ATK1
  states[648].action.acp1 := @A_BspiAttack; // S_BSPI_ATK2
  states[650].action.acp1 := @A_SpidRefire; // S_BSPI_ATK4
  states[652].action.acp1 := @A_Pain; // S_BSPI_PAIN2
  states[653].action.acp1 := @A_Scream; // S_BSPI_DIE1
  states[654].action.acp1 := @A_Fall; // S_BSPI_DIE2
  states[659].action.acp1 := @A_BossDeath; // S_BSPI_DIE7
  states[674].action.acp1 := @A_Look; // S_CYBER_STND
  states[675].action.acp1 := @A_Look; // S_CYBER_STND2
  states[676].action.acp1 := @A_Hoof; // S_CYBER_RUN1
  states[677].action.acp1 := @A_Chase; // S_CYBER_RUN2
  states[678].action.acp1 := @A_Chase; // S_CYBER_RUN3
  states[679].action.acp1 := @A_Chase; // S_CYBER_RUN4
  states[680].action.acp1 := @A_Chase; // S_CYBER_RUN5
  states[681].action.acp1 := @A_Chase; // S_CYBER_RUN6
  states[682].action.acp1 := @A_Metal; // S_CYBER_RUN7
  states[683].action.acp1 := @A_Chase; // S_CYBER_RUN8
  states[684].action.acp1 := @A_FaceTarget; // S_CYBER_ATK1
  states[685].action.acp1 := @A_CyberAttack; // S_CYBER_ATK2
  states[686].action.acp1 := @A_FaceTarget; // S_CYBER_ATK3
  states[687].action.acp1 := @A_CyberAttack; // S_CYBER_ATK4
  states[688].action.acp1 := @A_FaceTarget; // S_CYBER_ATK5
  states[689].action.acp1 := @A_CyberAttack; // S_CYBER_ATK6
  states[690].action.acp1 := @A_Pain; // S_CYBER_PAIN
  states[692].action.acp1 := @A_Scream; // S_CYBER_DIE2
  states[696].action.acp1 := @A_Fall; // S_CYBER_DIE6
  states[700].action.acp1 := @A_BossDeath; // S_CYBER_DIE10
  states[701].action.acp1 := @A_Look; // S_PAIN_STND
  states[702].action.acp1 := @A_Chase; // S_PAIN_RUN1
  states[703].action.acp1 := @A_Chase; // S_PAIN_RUN2
  states[704].action.acp1 := @A_Chase; // S_PAIN_RUN3
  states[705].action.acp1 := @A_Chase; // S_PAIN_RUN4
  states[706].action.acp1 := @A_Chase; // S_PAIN_RUN5
  states[707].action.acp1 := @A_Chase; // S_PAIN_RUN6
  states[708].action.acp1 := @A_FaceTarget; // S_PAIN_ATK1
  states[709].action.acp1 := @A_FaceTarget; // S_PAIN_ATK2
  states[710].action.acp1 := @A_FaceTarget; // S_PAIN_ATK3
  states[711].action.acp1 := @A_PainAttack; // S_PAIN_ATK4
  states[713].action.acp1 := @A_Pain; // S_PAIN_PAIN2
  states[715].action.acp1 := @A_Scream; // S_PAIN_DIE2
  states[718].action.acp1 := @A_PainDie; // S_PAIN_DIE5
  states[726].action.acp1 := @A_Look; // S_SSWV_STND
  states[727].action.acp1 := @A_Look; // S_SSWV_STND2
  states[728].action.acp1 := @A_Chase; // S_SSWV_RUN1
  states[729].action.acp1 := @A_Chase; // S_SSWV_RUN2
  states[730].action.acp1 := @A_Chase; // S_SSWV_RUN3
  states[731].action.acp1 := @A_Chase; // S_SSWV_RUN4
  states[732].action.acp1 := @A_Chase; // S_SSWV_RUN5
  states[733].action.acp1 := @A_Chase; // S_SSWV_RUN6
  states[734].action.acp1 := @A_Chase; // S_SSWV_RUN7
  states[735].action.acp1 := @A_Chase; // S_SSWV_RUN8
  states[736].action.acp1 := @A_FaceTarget; // S_SSWV_ATK1
  states[737].action.acp1 := @A_FaceTarget; // S_SSWV_ATK2
  states[738].action.acp1 := @A_CPosAttack; // S_SSWV_ATK3
  states[739].action.acp1 := @A_FaceTarget; // S_SSWV_ATK4
  states[740].action.acp1 := @A_CPosAttack; // S_SSWV_ATK5
  states[741].action.acp1 := @A_CPosRefire; // S_SSWV_ATK6
  states[743].action.acp1 := @A_Pain; // S_SSWV_PAIN2
  states[745].action.acp1 := @A_Scream; // S_SSWV_DIE2
  states[746].action.acp1 := @A_Fall; // S_SSWV_DIE3
  states[750].action.acp1 := @A_XScream; // S_SSWV_XDIE2
  states[751].action.acp1 := @A_Fall; // S_SSWV_XDIE3
  states[766].action.acp1 := @A_Scream; // S_COMMKEEN3
  states[774].action.acp1 := @A_KeenDie; // S_COMMKEEN11
  states[777].action.acp1 := @A_Pain; // S_KEENPAIN2
  states[779].action.acp1 := @A_BrainPain; // S_BRAIN_PAIN
  states[780].action.acp1 := @A_BrainScream; // S_BRAIN_DIE1
  states[783].action.acp1 := @A_BrainDie; // S_BRAIN_DIE4
  states[784].action.acp1 := @A_Look; // S_BRAINEYE
  states[785].action.acp1 := @A_BrainAwake; // S_BRAINEYESEE
  states[786].action.acp1 := @A_BrainSpit; // S_BRAINEYE1
  states[787].action.acp1 := @A_SpawnSound; // S_SPAWN1
  states[788].action.acp1 := @A_SpawnFly; // S_SPAWN2
  states[789].action.acp1 := @A_SpawnFly; // S_SPAWN3
  states[790].action.acp1 := @A_SpawnFly; // S_SPAWN4
  states[791].action.acp1 := @A_Fire; // S_SPAWNFIRE1
  states[792].action.acp1 := @A_Fire; // S_SPAWNFIRE2
  states[793].action.acp1 := @A_Fire; // S_SPAWNFIRE3
  states[794].action.acp1 := @A_Fire; // S_SPAWNFIRE4
  states[795].action.acp1 := @A_Fire; // S_SPAWNFIRE5
  states[796].action.acp1 := @A_Fire; // S_SPAWNFIRE6
  states[797].action.acp1 := @A_Fire; // S_SPAWNFIRE7
  states[798].action.acp1 := @A_Fire; // S_SPAWNFIRE8
  states[801].action.acp1 := @A_BrainExplode; // S_BRAINEXPLODE3
  states[809].action.acp1 := @A_Scream; // S_BEXP2
  states[811].action.acp1 := @A_Explode; // S_BEXP4

end;

end.
