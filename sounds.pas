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

unit sounds;

interface

//
// SoundFX struct.
//
type
  Psfxinfo_t = ^sfxinfo_t;
  sfxinfo_t = packed record
    // up to 6-character name
    name: string;
    // Sfx singularity (only one at a time)
    singularity: boolean;
    // Sfx priority
    priority: integer;
    // referenced sound if a link
    link: Psfxinfo_t;
    // pitch if a link
    pitch: integer;
    // volume if a link
    volume: integer;
    // sound data
    data: pointer;
    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    usefulness: integer;
    // lump number of sfx
    lumpnum: integer;
  end;

//
// MusicInfo struct.
//
  musicinfo_t = record
    // up to 6-character name
    name: string;
    // lump number of music
    lumpnum: integer;
    // music data
    data: pointer;
    // music handle once registered
    handle: integer;
  end;
  Pmusicinfo_t = ^musicinfo_t;

//
// Identifiers for all music in game.
//
  musicenum_t = (
    mus_None,
    mus_e1m1,
    mus_e1m2,
    mus_e1m3,
    mus_e1m4,
    mus_e1m5,
    mus_e1m6,
    mus_e1m7,
    mus_e1m8,
    mus_e1m9,
    mus_e2m1,
    mus_e2m2,
    mus_e2m3,
    mus_e2m4,
    mus_e2m5,
    mus_e2m6,
    mus_e2m7,
    mus_e2m8,
    mus_e2m9,
    mus_e3m1,
    mus_e3m2,
    mus_e3m3,
    mus_e3m4,
    mus_e3m5,
    mus_e3m6,
    mus_e3m7,
    mus_e3m8,
    mus_e3m9,
    mus_inter,
    mus_intro,
    mus_bunny,
    mus_victor,
    mus_introa,
    mus_runnin,
    mus_stalks,
    mus_countd,
    mus_betwee,
    mus_doom,
    mus_the_da,
    mus_shawn,
    mus_ddtblu,
    mus_in_cit,
    mus_dead,
    mus_stlks2,
    mus_theda2,
    mus_doom2,
    mus_ddtbl2,
    mus_runni2,
    mus_dead2,
    mus_stlks3,
    mus_romero,
    mus_shawn2,
    mus_messag,
    mus_count2,
    mus_ddtbl3,
    mus_ampie,
    mus_theda3,
    mus_adrian,
    mus_messg2,
    mus_romer2,
    mus_tense,
    mus_shawn3,
    mus_openin,
    mus_evil,
    mus_ultima,
    mus_read_m,
    mus_dm2ttl,
    mus_dm2int,
    NUMMUSIC
  );

//
// Identifiers for all sfx in game.
//
  sfxenum_t = (
    sfx_None,
    sfx_pistol,
    sfx_shotgn,
    sfx_sgcock,
    sfx_dshtgn,
    sfx_dbopn,
    sfx_dbcls,
    sfx_dbload,
    sfx_plasma,
    sfx_bfg,
    sfx_sawup,
    sfx_sawidl,
    sfx_sawful,
    sfx_sawhit,
    sfx_rlaunc,
    sfx_rxplod,
    sfx_firsht,
    sfx_firxpl,
    sfx_pstart,
    sfx_pstop,
    sfx_doropn,
    sfx_dorcls,
    sfx_stnmov,
    sfx_swtchn,
    sfx_swtchx,
    sfx_plpain,
    sfx_dmpain,
    sfx_popain,
    sfx_vipain,
    sfx_mnpain,
    sfx_pepain,
    sfx_slop,
    sfx_itemup,
    sfx_wpnup,
    sfx_oof,
    sfx_telept,
    sfx_posit1,
    sfx_posit2,
    sfx_posit3,
    sfx_bgsit1,
    sfx_bgsit2,
    sfx_sgtsit,
    sfx_cacsit,
    sfx_brssit,
    sfx_cybsit,
    sfx_spisit,
    sfx_bspsit,
    sfx_kntsit,
    sfx_vilsit,
    sfx_mansit,
    sfx_pesit,
    sfx_sklatk,
    sfx_sgtatk,
    sfx_skepch,
    sfx_vilatk,
    sfx_claw,
    sfx_skeswg,
    sfx_pldeth,
    sfx_pdiehi,
    sfx_podth1,
    sfx_podth2,
    sfx_podth3,
    sfx_bgdth1,
    sfx_bgdth2,
    sfx_sgtdth,
    sfx_cacdth,
    sfx_skldth,
    sfx_brsdth,
    sfx_cybdth,
    sfx_spidth,
    sfx_bspdth,
    sfx_vildth,
    sfx_kntdth,
    sfx_pedth,
    sfx_skedth,
    sfx_posact,
    sfx_bgact,
    sfx_dmact,
    sfx_bspact,
    sfx_bspwlk,
    sfx_vilact,
    sfx_noway,
    sfx_barexp,
    sfx_punch,
    sfx_hoof,
    sfx_metal,
    sfx_chgun,
    sfx_tink,
    sfx_bdopn,
    sfx_bdcls,
    sfx_itmbk,
    sfx_flame,
    sfx_flamst,
    sfx_getpow,
    sfx_bospit,
    sfx_boscub,
    sfx_bossit,
    sfx_bospn,
    sfx_bosdth,
    sfx_manatk,
    sfx_mandth,
    sfx_sssit,
    sfx_ssdth,
    sfx_keenpn,
    sfx_keendt,
    sfx_skeact,
    sfx_skesit,
    sfx_skeatk,
    sfx_radio,
    NUMSFX
  );

var
  S_music: array[0..67] of musicinfo_t = (
    (name: '';       lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m1';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m2';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m3';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m4';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m5';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m6';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m7';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m8';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e1m9';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m1';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m2';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m3';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m4';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m5';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m6';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m7';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m8';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e2m9';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m1';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m2';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m3';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m4';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m5';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m6';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m7';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m8';   lumpnum: 0; data: nil; handle: 0),
    (name: 'e3m9';   lumpnum: 0; data: nil; handle: 0),
    (name: 'inter';  lumpnum: 0; data: nil; handle: 0),
    (name: 'intro';  lumpnum: 0; data: nil; handle: 0),
    (name: 'bunny';  lumpnum: 0; data: nil; handle: 0),
    (name: 'victor'; lumpnum: 0; data: nil; handle: 0),
    (name: 'introa'; lumpnum: 0; data: nil; handle: 0),
    (name: 'runnin'; lumpnum: 0; data: nil; handle: 0),
    (name: 'stalks'; lumpnum: 0; data: nil; handle: 0),
    (name: 'countd'; lumpnum: 0; data: nil; handle: 0),
    (name: 'betwee'; lumpnum: 0; data: nil; handle: 0),
    (name: 'doom';   lumpnum: 0; data: nil; handle: 0),
    (name: 'the_da'; lumpnum: 0; data: nil; handle: 0),
    (name: 'shawn';  lumpnum: 0; data: nil; handle: 0),
    (name: 'ddtblu'; lumpnum: 0; data: nil; handle: 0),
    (name: 'in_cit'; lumpnum: 0; data: nil; handle: 0),
    (name: 'dead';   lumpnum: 0; data: nil; handle: 0),
    (name: 'stlks2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'theda2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'doom2';  lumpnum: 0; data: nil; handle: 0),
    (name: 'ddtbl2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'runni2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'dead2';  lumpnum: 0; data: nil; handle: 0),
    (name: 'stlks3'; lumpnum: 0; data: nil; handle: 0),
    (name: 'romero'; lumpnum: 0; data: nil; handle: 0),
    (name: 'shawn2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'messag'; lumpnum: 0; data: nil; handle: 0),
    (name: 'count2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'ddtbl3'; lumpnum: 0; data: nil; handle: 0),
    (name: 'ampie';  lumpnum: 0; data: nil; handle: 0),
    (name: 'theda3'; lumpnum: 0; data: nil; handle: 0),
    (name: 'adrian'; lumpnum: 0; data: nil; handle: 0),
    (name: 'messg2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'romer2'; lumpnum: 0; data: nil; handle: 0),
    (name: 'tense';  lumpnum: 0; data: nil; handle: 0),
    (name: 'shawn3'; lumpnum: 0; data: nil; handle: 0),
    (name: 'openin'; lumpnum: 0; data: nil; handle: 0),
    (name: 'evil';   lumpnum: 0; data: nil; handle: 0),
    (name: 'ultima'; lumpnum: 0; data: nil; handle: 0),
    (name: 'read_m'; lumpnum: 0; data: nil; handle: 0),
    (name: 'dm2ttl'; lumpnum: 0; data: nil; handle: 0),
    (name: 'dm2int'; lumpnum: 0; data: nil; handle: 0)
  );

  S_sfx: array[0..108] of sfxinfo_t = (
  // S_sfx[0] needs to be a dummy for odd reasons.
    (name: 'none';   singularity: False; priority:   0; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pistol'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'shotgn'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sgcock'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dshtgn'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dbopn';  singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dbcls';  singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dbload'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'plasma'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bfg';    singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sawup';  singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sawidl'; singularity: False; priority: 118; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sawful'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sawhit'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'rlaunc'; singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'rxplod'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'firsht'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'firxpl'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pstart'; singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pstop';  singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'doropn'; singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dorcls'; singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'stnmov'; singularity: False; priority: 119; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'swtchn'; singularity: False; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'swtchx'; singularity: False; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'plpain'; singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dmpain'; singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'popain'; singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'vipain'; singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'mnpain'; singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pepain'; singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'slop';   singularity: False; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'itemup'; singularity: True;  priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'wpnup';  singularity: True;  priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'oof';    singularity: False; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'telept'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'posit1'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'posit2'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'posit3'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bgsit1'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bgsit2'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sgtsit'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'cacsit'; singularity: True;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'brssit'; singularity: True;  priority:  94; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'cybsit'; singularity: True;  priority:  92; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'spisit'; singularity: True;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bspsit'; singularity: True;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'kntsit'; singularity: True;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'vilsit'; singularity: True;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'mansit'; singularity: True;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pesit';  singularity: True;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sklatk'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sgtatk'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skepch'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'vilatk'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'claw';   singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skeswg'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pldeth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pdiehi'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'podth1'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'podth2'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'podth3'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bgdth1'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bgdth2'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sgtdth'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'cacdth'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skldth'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'brsdth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'cybdth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'spidth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bspdth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'vildth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'kntdth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'pedth';  singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skedth'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'posact'; singularity: True;  priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bgact';  singularity: True;  priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'dmact';  singularity: True;  priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bspact'; singularity: True;  priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bspwlk'; singularity: True;  priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'vilact'; singularity: True;  priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'noway';  singularity: False; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'barexp'; singularity: False; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'punch';  singularity: False; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'hoof';   singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'metal';  singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'chgun';  singularity: False; priority:  64; link: @S_sfx[Ord(sfx_pistol)]; pitch: 150; volume: 0; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'tink';   singularity: False; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bdopn';  singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bdcls';  singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'itmbk';  singularity: False; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'flame';  singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'flamst'; singularity: False; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'getpow'; singularity: False; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bospit'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'boscub'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bossit'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bospn';  singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'bosdth'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'manatk'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'mandth'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'sssit';  singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'ssdth';  singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'keenpn'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'keendt'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skeact'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skesit'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'skeatk'; singularity: False; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0),
    (name: 'radio';  singularity: False; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0)
  );

implementation

end.
