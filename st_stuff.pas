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

unit st_stuff;

interface

uses doomtype, doomdef, d_event;

// Size of statusbar.
// Now sensitive for scaling.
const
  ST_HEIGHT = 32;
  ST_WIDTH = 320; //SCREENWIDTH;
  ST_Y = 200 - ST_HEIGHT; //SCREENHEIGHT - ST_HEIGHT;


//
// STATUS BAR
//

// Called by main loop.
function ST_Responder(ev: Pevent_t): boolean;

// Called by main loop.
procedure ST_Ticker;

// Called by main loop.
procedure ST_Drawer(fullscreen: boolean; refresh: boolean);

// Called when the console player is spawned on each level.
procedure ST_Start;

// Called by startup code.
procedure ST_Init;



// States for status bar code.
type
  st_stateenum_t = (
    AutomapState,
    FirstPersonState
  );

// States for the chat code.
  st_chatstateenum_t = (
    StartChatState,
    WaitDestState,
    GetChatState
  );


implementation

uses
  d_delphi,
  tables,
  d_items,
  i_system,
  i_video,
  z_memory,
  w_wad,
  g_game,
  st_lib,
  p_local,
  p_inter,
  d_player,
  r_defs,
  r_main,
  am_map,
  m_cheat,
  m_rnd,
  m_fixed,
  s_sound,
// Needs access to LFB.
  v_video,
// State.
  doomstat,
// Data.
  d_englsh,
  sounds,
// for mapnames
  hu_stuff;

//
// STATUS BAR DATA
//

const
// Palette indices.
// For damage/bonus red-/gold-shifts
  STARTREDPALS = 1;
  STARTBONUSPALS = 9;
  NUMREDPALS = 8;
  NUMBONUSPALS = 4;
// Radiation suit, green shift.
  RADIATIONPAL = 13;

// N/256*100% probability
//  that the normal face state will change
  ST_FACEPROBABILITY = 96;

// For Responder
  ST_TOGGLECHAT = KEY_ENTER;

// Location of status bar
  ST_X = 0;
  ST_X2 = 104;

  ST_FX = 143;
  ST_FY = ST_Y + 1; // VJ was 169;

// Number of status faces.
  ST_NUMPAINFACES = 5;
  ST_NUMSTRAIGHTFACES = 3;
  ST_NUMTURNFACES = 2;
  ST_NUMSPECIALFACES = 3;

  ST_FACESTRIDE = ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES;

  ST_NUMEXTRAFACES = 2;

  ST_NUMFACES = ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES;

  ST_TURNOFFSET = ST_NUMSTRAIGHTFACES;
  ST_OUCHOFFSET = ST_TURNOFFSET + ST_NUMTURNFACES;
  ST_EVILGRINOFFSET = ST_OUCHOFFSET + 1;
  ST_RAMPAGEOFFSET = ST_EVILGRINOFFSET + 1;
  ST_GODFACE = ST_NUMPAINFACES * ST_FACESTRIDE;
  ST_DEADFACE = ST_GODFACE + 1;

  ST_FACESX = 143;
  ST_FACESY = ST_Y; // VJ was 168;

  ST_EVILGRINCOUNT = 2 * TICRATE;
  ST_STRAIGHTFACECOUNT = TICRATE div 2;
  ST_TURNCOUNT = 1 * TICRATE;
  ST_OUCHCOUNT = 1 * TICRATE;
  ST_RAMPAGEDELAY = 2 * TICRATE;

  ST_MUCHPAIN = 20;


// Location and size of statistics,
//  justified according to widget type.
// Problem is, within which space? STbar? Screen?
// Note: this could be read in by a lump.
//       Problem is, is the stuff rendered
//       into a buffer,
//       or into the frame buffer?

// AMMO number pos.
  ST_AMMOWIDTH = 3;
  ST_AMMOX = 44;
  ST_AMMOY = ST_Y + 3; // VJ was 171;

// HEALTH number pos.
  ST_HEALTHWIDTH = 3;
  ST_HEALTHX = 90;
  ST_HEALTHY = ST_Y + 3; // VJ was 171;

// Weapon pos.
  ST_ARMSX = 111;
  ST_ARMSY = ST_Y + 4; // VJ was 172;
  ST_ARMSBGX = 104;
  ST_ARMSBGY = ST_Y; // VJ was 168;
  ST_ARMSXSPACE = 12;
  ST_ARMSYSPACE = 10;

// Frags pos.
  ST_FRAGSX = 138;
  ST_FRAGSY = ST_Y + 3; // VJ was 171;
  ST_FRAGSWIDTH = 2;

// ARMOR number pos.
  ST_ARMORWIDTH = 3;
  ST_ARMORX = 221;
  ST_ARMORY = ST_Y + 3; // VJ was 171;

// Key icon positions.
  ST_KEY0WIDTH = 8;
  ST_KEY0HEIGHT = 5;
  ST_KEY0X = 239;
  ST_KEY0Y = ST_Y + 3; // VJ was 171;
  ST_KEY1WIDTH = ST_KEY0WIDTH;
  ST_KEY1X = 239;
  ST_KEY1Y = ST_Y + 13; // VJ was 181;
  ST_KEY2WIDTH = ST_KEY0WIDTH;
  ST_KEY2X = 239;
  ST_KEY2Y = ST_Y + 23; // VJ was 191;

// Ammunition counter.
  ST_AMMO0WIDTH = 3;
  ST_AMMO0HEIGHT = 6;
  ST_AMMO0X = 288;
  ST_AMMO0Y = ST_Y + 5; // VJ was 173;
  ST_AMMO1WIDTH = ST_AMMO0WIDTH;
  ST_AMMO1X = 288;
  ST_AMMO1Y = ST_Y + 11; // VJ was 179;
  ST_AMMO2WIDTH = ST_AMMO0WIDTH;
  ST_AMMO2X = 288;
  ST_AMMO2Y = ST_Y + 23; // VJ was 191;
  ST_AMMO3WIDTH = ST_AMMO0WIDTH;
  ST_AMMO3X = 288;
  ST_AMMO3Y = ST_Y + 17; // VJ was 185;

// Indicate maximum ammunition.
// Only needed because backpack exists.
  ST_MAXAMMO0WIDTH = 3;
  ST_MAXAMMO0HEIGHT = 5;
  ST_MAXAMMO0X = 314;
  ST_MAXAMMO0Y = ST_Y + 5; // VJ was 173;
  ST_MAXAMMO1WIDTH = ST_MAXAMMO0WIDTH;
  ST_MAXAMMO1X = 314;
  ST_MAXAMMO1Y = ST_Y + 11; // VJ was 179;
  ST_MAXAMMO2WIDTH = ST_MAXAMMO0WIDTH;
  ST_MAXAMMO2X = 314;
  ST_MAXAMMO2Y = ST_Y + 23; // VJ was 191;
  ST_MAXAMMO3WIDTH = ST_MAXAMMO0WIDTH;
  ST_MAXAMMO3X = 314;
  ST_MAXAMMO3Y = ST_Y + 17; // VJ was 185;

// pistol
  ST_WEAPON0X = 110;
  ST_WEAPON0Y = ST_Y + 4; // VJ was 172;

// shotgun
  ST_WEAPON1X = 122;
  ST_WEAPON1Y = ST_Y + 4; // VJ was 172;

// chain gun
  ST_WEAPON2X = 134;
  ST_WEAPON2Y = ST_Y + 4; // VJ was 172;

// missile launcher
  ST_WEAPON3X = 110;
  ST_WEAPON3Y = ST_Y + 13; // VJ was 181;

// plasma gun
  ST_WEAPON4X = 122;
  ST_WEAPON4Y = ST_Y + 13; // VJ was 181;

 // bfg
  ST_WEAPON5X = 134;
  ST_WEAPON5Y = ST_Y + 13; // VJ was 181;

// WPNS title
  ST_WPNSX = 109;
  ST_WPNSY = ST_Y + 23; // VJ was 191;

 // DETH title
  ST_DETHX = 109;
  ST_DETHY = ST_Y + 23; // VJ was 191;

//Incoming messages window location
  ST_MSGTEXTX = 0;
  ST_MSGTEXTY = 0;
// Dimensions given in characters.
  ST_MSGWIDTH = 52;
// Or shall I say, in lines?
  ST_MSGHEIGHT = 1;

  ST_OUTTEXTX = 0;
  ST_OUTTEXTY = 6;

// Width, in characters again.
  ST_OUTWIDTH = 52;
 // Height, in lines.
  ST_OUTHEIGHT = 1;


  ST_MAPTITLEY = 0;
  ST_MAPHEIGHT = 1;

var

// main player in game
  plyr: Pplayer_t;

// ST_Start() has just been called
  st_firsttime: boolean;

// used to execute ST_Init() only once
  veryfirsttime: integer;

// lump number for PLAYPAL
  lu_palette: integer;

// used for timing
  st_clock: LongWord;

// used for making messages go away
  st_msgcounter: integer;

// used when in chat
  st_chatstate: st_chatstateenum_t;

// whether in automap or first-person
  st_gamestate: st_stateenum_t;

// whether left-side main status bar is active
  st_statusbaron: boolean;

// whether status bar chat is active
  st_chat: boolean;

// value of st_chat before message popped up
  st_oldchat: boolean;

// whether chat window has the cursor on
  st_cursoron: boolean;

// !deathmatch
  st_notdeathmatch: boolean;

// !deathmatch && st_statusbaron
  st_armson: boolean;

// !deathmatch
  st_fragson: boolean;

// main bar left
  sbar: Ppatch_t;

// 0-9, tall numbers
  tallnum: array[0..9] of Ppatch_t;

// tall % sign
  tallpercent: Ppatch_t;

// 0-9, short, yellow (,different!) numbers
  shortnum: array[0..9] of Ppatch_t;

// 3 key-cards, 3 skulls
  keys: array[0..Ord(NUMCARDS) - 1] of Ppatch_t;

// face status patches
  faces: array[0..ST_NUMFACES - 1] of Ppatch_t;

// face background
  faceback: Ppatch_t;

 // main bar right
  armsbg: Ppatch_t;

// weapon ownership patches
  arms: array[0..5, 0..1] of Ppatch_t;

// ready-weapon widget
  w_ready: st_number_t;

 // in deathmatch only, summary of frags stats
  w_frags: st_number_t;

// health widget
  w_health: st_percent_t;

// arms background
  w_armsbg: st_binicon_t;


// weapon ownership widgets
  w_arms: array[0..5] of st_multicon_t;

// face status widget
  w_faces: st_multicon_t;

// keycard widgets
  w_keyboxes: array[0..2] of st_multicon_t;

// armor widget
  w_armor: st_percent_t;

// ammo widgets
  w_ammo: array[0..3] of st_number_t;

// max ammo widgets
  w_maxammo: array[0..3] of st_number_t;



// number of frags so far in deathmatch
  st_fragscount: integer;

// used to use appopriately pained face
  st_oldhealth: integer;

// used for evil grin
  oldweaponsowned: array[0..Ord(NUMWEAPONS) - 1] of boolean;

 // count until face changes
  st_facecount: integer;

// current face index, used by w_faces
  st_faceindex: integer;

// holds key-type for each key box on bar
  keyboxes: array[0..2] of integer;

// a random number per tick
  st_randomnumber: integer;  


const
// Massive bunches of cheat shit
//  to keep it from being easy to figure them out.
// Yeah, right...
  cheat_mus_seq: array[0..8] of char = (
    Chr($b2), Chr($26), Chr($b6), Chr($ae), Chr($ea),
    Chr($1),  Chr($0),  Chr($0),  Chr($ff)
  );

  cheat_choppers_seq: array[0..10] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($32), Chr($f6),
    Chr($2a), Chr($2a), Chr($a6), Chr($6a), Chr($ea),
    Chr($ff) // id...
  );

  cheat_god_seq: array[0..5] of char = (
    Chr($b2), Chr($26), Chr($26), Chr($aa), Chr($26),
    Chr($ff)  // iddqd
  );

  cheat_ammo_seq: array[0..5] of char = (
    Chr($b2), Chr($26), Chr($f2), Chr($66), Chr($a2),
    Chr($ff)  // idkfa
  );

  cheat_ammonokey_seq: array[0..4] of char = (
    Chr($b2), Chr($26), Chr($66), Chr($a2), Chr($ff) // idfa
  );

// Smashing Pumpkins Into Samml Piles Of Putried Debris.
  cheat_noclip_seq: array[0..10] of char = (
    Chr($b2), Chr($26), Chr($ea), Chr($2a), Chr($b2), // idspispopd
    Chr($ea), Chr($2a), Chr($f6), Chr($2a), Chr($26),
    Chr($ff)
  );

//
  cheat_commercial_noclip_seq: array[0..6] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($36), Chr($b2),
    Chr($2a), Chr($ff)  // idclip
  );



  cheat_powerup_seq0: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($6e), Chr($ff)  // beholdv
  );

  cheat_powerup_seq1: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($ea), Chr($ff)  // beholds
  );

  cheat_powerup_seq2: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($b2), Chr($ff)  // beholdi
  );

  cheat_powerup_seq3: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($6a), Chr($ff)  // beholdr
  );

  cheat_powerup_seq4: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($a2), Chr($ff)  // beholda
  );

  cheat_powerup_seq5: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($36), Chr($ff)  // beholdl
  );

  cheat_powerup_seq6: array[0..8] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($ff)  // behold
  );


  cheat_clev_seq: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($36), Chr($a6),
    Chr($6e), Chr($1),  Chr($0),  Chr($0),  Chr($ff)  // idclev
  );

// my position cheat
  cheat_mypos_seq: array[0..7] of char = (
    Chr($b2), Chr($26), Chr($b6), Chr($ba), Chr($2a),
    Chr($f6), Chr($ea), Chr($ff) // idmypos
  );

var
// Now what?
  cheat_mus: cheatseq_t;
  cheat_god: cheatseq_t;
  cheat_ammo: cheatseq_t;
  cheat_ammonokey: cheatseq_t;
  cheat_noclip: cheatseq_t;
  cheat_commercial_noclip: cheatseq_t;

  cheat_powerup: array[0..6] of cheatseq_t;

  cheat_choppers: cheatseq_t;
  cheat_clev: cheatseq_t;
  cheat_mypos: cheatseq_t;


// Should be set to patch width
//  for tall numbers later on
function ST_TALLNUMWIDTH: integer;
begin
  result := tallnum[0].width;
end;

function ST_MAPWIDTH: integer;
begin
  result := Length(mapnames[(gameepisode - 1) * 9 + (gamemap - 1)]);
end;

//
// STATUS BAR CODE
//
procedure ST_RefreshBackground;
begin
  if st_statusbaron then
  begin
    V_DrawPatch(ST_X, 0, SCN_ST, sbar, false);

    if netgame then
      V_DrawPatch(ST_FX, 0, SCN_ST, faceback, false);
  end;
end;

procedure ST_FinishRefresh;
begin
  V_CopyRect(ST_X,
             0,
             SCN_ST,
             ST_WIDTH,
             ST_HEIGHT,
             ST_X,
             ST_Y,
             SCN_FG,
             true);
end;

// Respond to keyboard input events,
//  intercept cheats.
function ST_Responder(ev: Pevent_t): boolean;
var
  i: integer;
  buf: string;
  musnum: integer;
  epsd: integer;
  map: integer;
begin
  result := false;
  // Filter automap on/off.
  if (ev._type = ev_keyup) and
     ((ev.data1 and $ffff0000) = AM_MSGHEADER) then
  begin
    case ev.data1 of
      AM_MSGENTERED:
        begin
          st_gamestate := AutomapState;
          st_firsttime := true;
        end;

      AM_MSGEXITED:
        begin
          //  fprintf(stderr, "AM exited\n");
          st_gamestate := FirstPersonState;
        end;
    end;
  end
  // if a user keypress...
  else if ev._type = ev_keydown then
  begin
    if not netgame then
    begin
      // b. - enabled for more debug fun.
      // if (gameskill != sk_nightmare) {

      // 'dqd' cheat for toggleable god mode
      if cht_CheckCheat(@cheat_god, Chr(ev.data1)) then
      begin
        plyr.cheats := plyr.cheats xor CF_GODMODE;
        if plyr.cheats and CF_GODMODE <> 0 then
        begin
          if plyr.mo <> nil then
            plyr.mo.health := 100;

          plyr.health := 100;
          plyr._message := STSTR_DQDON;
        end
        else
          plyr._message := STSTR_DQDOFF;
      end
      // 'fa' cheat for killer fucking arsenal
      else if cht_CheckCheat(@cheat_ammonokey, Chr(ev.data1)) then
      begin
        plyr.armorpoints := 200;
        plyr.armortype := 2;

        for i := 0 to Ord(NUMWEAPONS) - 1 do
          plyr.weaponowned[i] := True;

        for i := 0 to Ord(NUMAMMO) - 1 do
          plyr.ammo[i] := plyr.maxammo[i];

        plyr._message := STSTR_FAADDED;
      end
      // 'kfa' cheat for key full ammo
      else if cht_CheckCheat(@cheat_ammo, Chr(ev.data1)) then
      begin
        plyr.armorpoints := 200;
        plyr.armortype := 2;

        for i := 0 to Ord(NUMWEAPONS) - 1 do
          plyr.weaponowned[i] := True;

        for i := 0 to Ord(NUMAMMO) - 1 do
          plyr.ammo[i] := plyr.maxammo[i];

        for i := 0 to Ord(NUMCARDS) - 1 do
          plyr.cards[i] := true;

        plyr._message := STSTR_KFAADDED;
      end
      // 'mus' cheat for changing music
      else if cht_CheckCheat(@cheat_mus, Chr(ev.data1)) then
      begin
        plyr._message := STSTR_MUS;
        cht_GetParam(@cheat_mus, buf);

        if gamemode = commercial then
        begin
          musnum := Ord(mus_runnin) + (Ord(buf[1]) - Ord('0')) * 10 + Ord(buf[2]) - Ord('0') - 1;

          if (Ord(buf[1]) - Ord('0')) * 10 + Ord(buf[2]) - Ord('0') > 35 then
            plyr._message := STSTR_NOMUS
          else
            S_ChangeMusic(musnum, true);
        end
        else
        begin
          musnum := Ord(mus_e1m1) + (Ord(buf[1]) - Ord('1')) * 9 + Ord(buf[2]) - Ord('1');

          if (Ord(buf[1]) - Ord('1')) * 9 + Ord(buf[2]) - Ord('1') > 31 then
            plyr._message := STSTR_NOMUS
          else
            S_ChangeMusic(musnum, true);
        end;
      end
      // Simplified, accepting both "noclip" and "idspispopd".
      // no clipping mode cheat
      else if cht_CheckCheat(@cheat_noclip, Chr(ev.data1)) or
              cht_CheckCheat(@cheat_commercial_noclip, Chr(ev.data1)) then
      begin
        plyr.cheats := plyr.cheats xor CF_NOCLIP;

        if plyr.cheats and CF_NOCLIP <> 0 then
          plyr._message := STSTR_NCON
        else
          plyr._message := STSTR_NCOFF;
      end;
      // 'behold?' power-up cheats
      for i := 0 to 5 do
      begin
        if cht_CheckCheat(@cheat_powerup[i], Chr(ev.data1)) then
        begin
          if plyr.powers[i] = 0 then
            P_GivePower(plyr, i)
          else if i <> Ord(pw_strength) then
            plyr.powers[i] := 1
          else
            plyr.powers[i] := 0;

          plyr._message := STSTR_BEHOLDX;
        end;
      end;

      // 'behold' power-up menu
      if cht_CheckCheat(@cheat_powerup[6], Chr(ev.data1)) then
      begin
        plyr._message := STSTR_BEHOLD;
      end
      // 'choppers' invulnerability & chainsaw
      else if cht_CheckCheat(@cheat_choppers, Chr(ev.data1)) then
      begin
        plyr.weaponowned[Ord(wp_chainsaw)] := True;
        plyr.powers[Ord(pw_invulnerability)] := 1;
        plyr._message := STSTR_CHOPPERS;
      end
      // 'mypos' for player position
      else if cht_CheckCheat(@cheat_mypos, Chr(ev.data1)) then
      begin
        sprintf(buf, 'ang = %d, (x, y) = (%d, %d)', [
          plyr.mo.angle div $B60B60,
          plyr.mo.x div FRACUNIT,
          plyr.mo.y div FRACUNIT]);
        plyr._message := buf;
      end;
    end;

    // 'clev' change-level cheat
    if cht_CheckCheat(@cheat_clev, Chr(ev.data1)) then
    begin
      cht_GetParam(@cheat_clev, buf);

      if gamemode = commercial then
      begin
        epsd := 0;
        map := (Ord(buf[1]) - Ord('0')) * 10 + Ord(buf[2]) - Ord('0');
      end
      else
      begin
        epsd := Ord(buf[1]) - Ord('0');
        map := Ord(buf[2]) - Ord('0');
        // Catch invalid maps.
        if epsd < 1 then
          exit;
      end;

      if map < 1 then
        exit;

      // Ohmygod - this is not going to work.
      if (gamemode = retail) and
         ((epsd > 4) or (map > 9)) then
        exit;

      if (gamemode = registered) and
         ((epsd > 3) or (map > 9)) then
        exit;

      if (gamemode = shareware) and
         ((epsd > 1) or (map > 9)) then
        exit;

      if (gamemode = commercial) and
         ((epsd > 1) or (map > 34)) then
        exit;

      // So be it.
      plyr._message := STSTR_CLEV;
      G_DeferedInitNew(gameskill, epsd, map);
      result := true;
    end;
  end;
end;

var
  lastcalc: integer;
  oldhealth: integer;

function ST_calcPainOffset: integer;
var
  health: integer;
begin
  health := decide(plyr.health > 100, 100, plyr.health);

  if health <> oldhealth then
  begin
    lastcalc := ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) div 101);
    oldhealth := health;
  end;
  result := lastcalc;
end;

//
// This is a not-very-pretty routine which handles
//  the face states and their timing.
// the precedence of expressions is:
//  dead > evil grin > turned head > straight ahead
//
var
  lastattackdown: integer;
  priority: integer;

procedure ST_updateFaceWidget;
var
  i: integer;
  badguyangle: angle_t;
  diffang: angle_t;
  doevilgrin: boolean;
begin
  if priority < 10 then
  begin
    // dead
    if plyr.health = 0 then
    begin
      priority := 9;
      st_faceindex := ST_DEADFACE;
      st_facecount := 1;
    end;
  end;

  if priority < 9 then
  begin
    if plyr.bonuscount <> 0 then
    begin
      // picking up bonus
      doevilgrin := false;

      for i := 0 to Ord(NUMWEAPONS) - 1 do
      begin
        if oldweaponsowned[i] <> plyr.weaponowned[i] then
        begin
          doevilgrin := true;
          oldweaponsowned[i] := plyr.weaponowned[i];
        end;
      end;
      if doevilgrin then
      begin
        // evil grin if just picked up weapon
        priority := 8;
        st_facecount := ST_EVILGRINCOUNT;
        st_faceindex := ST_calcPainOffset + ST_EVILGRINOFFSET;
      end;
    end;
  end;

  if priority < 8 then
  begin
    if (plyr.damagecount <> 0) and
       (plyr.attacker <> nil) and
       (plyr.attacker <> plyr.mo) then
    begin
      // being attacked
      priority := 7;

      if plyr.health - st_oldhealth > ST_MUCHPAIN then
      begin
        st_facecount := ST_TURNCOUNT;
        st_faceindex := ST_calcPainOffset + ST_OUCHOFFSET;
      end
      else
      begin
        badguyangle :=
          R_PointToAngle2(plyr.mo.x, plyr.mo.y, plyr.attacker.x, plyr.attacker.y);

        if badguyangle > plyr.mo.angle then
        begin
          // whether right or left
          diffang := badguyangle - plyr.mo.angle;
          i := intval(diffang > ANG180);
        end
        else
        begin
          // whether left or right
          diffang := plyr.mo.angle - badguyangle;
          i := intval(diffang <= ANG180);
        end; // confusing, aint it?


        st_facecount := ST_TURNCOUNT;
        st_faceindex := ST_calcPainOffset;

        if diffang < ANG45 then
        begin
          // head-on
          st_faceindex := st_faceindex + ST_RAMPAGEOFFSET;
        end
        else if i <> 0 then
        begin
          // turn face right
          st_faceindex := st_faceindex + ST_TURNOFFSET;
        end
        else
        begin
          // turn face left
          st_faceindex := st_faceindex + ST_TURNOFFSET + 1;
        end;
      end;
    end;
  end;

  if priority < 7 then
  begin
    // getting hurt because of your own damn stupidity
    if plyr.damagecount <> 0 then
    begin
      if plyr.health - st_oldhealth > ST_MUCHPAIN then
      begin
        priority := 7;
        st_facecount := ST_TURNCOUNT;
        st_faceindex := ST_calcPainOffset + ST_OUCHOFFSET;
      end
      else
      begin
        priority := 6;
        st_facecount := ST_TURNCOUNT;
        st_faceindex := ST_calcPainOffset + ST_RAMPAGEOFFSET;
      end;
    end;
  end;
    
  if priority < 6 then
  begin
    // rapid firing
    if plyr.attackdown then
    begin
      if lastattackdown = -1 then
        lastattackdown := ST_RAMPAGEDELAY
      else
      begin
        dec(lastattackdown);
        if lastattackdown = 0 then
        begin
          priority := 5;
          st_faceindex := ST_calcPainOffset + ST_RAMPAGEOFFSET;
          st_facecount := 1;
          lastattackdown := 1;
        end;
      end;
    end
    else
      lastattackdown := -1;
  end;

  if priority < 5 then
  begin
    // invulnerability
    if (plyr.cheats and CF_GODMODE <> 0) or
       (plyr.powers[Ord(pw_invulnerability)] <> 0) then
    begin
      priority := 4;

      st_faceindex := ST_GODFACE;
      st_facecount := 1;
    end;
  end;

  // look left or look right if the facecount has timed out
  if st_facecount = 0 then
  begin
    st_faceindex := ST_calcPainOffset + (st_randomnumber mod 3);
    st_facecount := ST_STRAIGHTFACECOUNT;
    priority := 0;
  end;

  dec(st_facecount);
end;

var
  largeammo: integer; // means "n/a"

procedure ST_updateWidgets;
var
  i: integer;
begin
  // must redirect the pointer if the ready weapon has changed.
  //  if (w_ready.data != plyr->readyweapon)
  //  {
  if weaponinfo[Ord(plyr.readyweapon)].ammo = am_noammo then
    w_ready.num := @largeammo
  else
    w_ready.num := @plyr.ammo[Ord(weaponinfo[Ord(plyr.readyweapon)].ammo)];

  w_ready.data := Ord(plyr.readyweapon);

  // update keycard multiple widgets
  for i := 0 to 2 do
  begin
    keyboxes[i] := decide(plyr.cards[i], i, -1);

    if plyr.cards[i + 3] then
      keyboxes[i] := i + 3;
  end;

  // refresh everything if this is him coming back to life
  ST_updateFaceWidget;

  // used by the w_armsbg widget
  st_notdeathmatch := deathmatch = 0;

  // used by w_arms[] widgets
  st_armson := st_statusbaron and st_notdeathmatch;

  // used by w_frags widget
  st_fragson := (deathmatch <> 0) and st_statusbaron;
  st_fragscount := 0;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if i <> consoleplayer then
      st_fragscount := st_fragscount + plyr.frags[i]
    else
      st_fragscount := st_fragscount - plyr.frags[i];
  end;

  // get rid of chat window if up because of message
  dec(st_msgcounter);
  if st_msgcounter = 0 then
    st_chat := st_oldchat;
end;

procedure ST_Ticker;
begin
  inc(st_clock);
  st_randomnumber := M_Random;
  ST_updateWidgets;
  st_oldhealth := plyr.health;
end;

var
  st_palette: integer;

procedure ST_doPaletteStuff;
var
  palette: integer;
  pal: PByteArray;
  cnt: integer;
  bzc: integer;
begin
  cnt := plyr.damagecount;

  if plyr.powers[Ord(pw_strength)] <> 0 then
  begin
    // slowly fade the berzerk out
    bzc := 12 - _SHR(plyr.powers[Ord(pw_strength)], 6);

    if bzc > cnt then
      cnt := bzc;
  end;

  if cnt <> 0 then
  begin
    palette := _SHR(cnt + 7, 3);

    if palette >= NUMREDPALS then
      palette := NUMREDPALS - 1;

    palette := palette + STARTREDPALS;
  end
  else if plyr.bonuscount <> 0 then
  begin
    palette := _SHR(plyr.bonuscount + 7, 3);

    if palette >= NUMBONUSPALS then
      palette := NUMBONUSPALS - 1;

    palette := palette + STARTBONUSPALS;
  end
  else if (plyr.powers[Ord(pw_ironfeet)] > 4 * 32) or
          (plyr.powers[Ord(pw_ironfeet)] and 8 <> 0) then
    palette := RADIATIONPAL
  else
    palette := 0;

  if palette <> st_palette then
  begin
    st_palette := palette;
    pal := PByteArray(integer(W_CacheLumpNum(lu_palette, PU_CACHE)) + palette * 768);
    I_SetPalette(pal);
  end;
end;

procedure ST_DrawWidgets(refresh: boolean);
var
  i: integer;
begin
  // used by w_arms[] widgets
  st_armson := st_statusbaron and (deathmatch = 0);

  // used by w_frags widget
  st_fragson := (deathmatch <> 0) and st_statusbaron;

  STlib_updateNum(@w_ready, refresh);

  for i := 0 to 3 do
  begin
    STlib_updateNum(@w_ammo[i], refresh);
    STlib_updateNum(@w_maxammo[i], refresh);
  end;

  STlib_updatePercent(@w_health, refresh);
  STlib_updatePercent(@w_armor, refresh);

  STlib_updateBinIcon(@w_armsbg, refresh);

  for i := 0 to 5 do
    STlib_updateMultIcon(@w_arms[i], refresh);

  STlib_updateMultIcon(@w_faces, refresh);

  for i := 0 to 2 do
    STlib_updateMultIcon(@w_keyboxes[i], refresh);

  STlib_updateNum(@w_frags, refresh);
end;

procedure ST_Refresh(refresh: boolean);
begin
  // draw status bar background to off-screen buff}
  ST_RefreshBackground;
  // and refresh all widgets
  ST_DrawWidgets(refresh);
  ST_FinishRefresh;
end;

procedure ST_Drawer(fullscreen: boolean; refresh: boolean);
begin
  st_statusbaron := not fullscreen or automapactive;
  st_firsttime := st_firsttime or refresh;

  // Do red-/gold-shifts from damage/items
  ST_doPaletteStuff;

  ST_Refresh(st_firsttime);
end;

procedure ST_loadGraphics;
var
  i: integer;
  j: integer;
  facenum: integer;
  namebuf: string;
begin
  // Load the numbers, tall and short
  for i := 0 to 9 do
  begin
    sprintf(namebuf, 'STTNUM%d', [i]);
    tallnum[i] := Ppatch_t(W_CacheLumpName(namebuf, PU_STATIC));

    sprintf(namebuf, 'STYSNUM%d', [i]);
    shortnum[i] := Ppatch_t(W_CacheLumpName(namebuf, PU_STATIC));
  end;

  // Load percent key.
  //Note: why not load STMINUS here, too?
  tallpercent := Ppatch_t(W_CacheLumpName('STTPRCNT', PU_STATIC));

  // key cards
  for i := 0 to Ord(NUMCARDS) - 1 do
  begin
    sprintf(namebuf, 'STKEYS%d', [i]);
    keys[i] := Ppatch_t(W_CacheLumpName(namebuf, PU_STATIC));
  end;

  // arms background
  armsbg := Ppatch_t(W_CacheLumpName('STARMS', PU_STATIC));

  // arms ownership widgets
  for i := 0 to 5 do
  begin
    sprintf(namebuf, 'STGNUM%d', [i + 2]);

    // gray #
    arms[i][0] := Ppatch_t(W_CacheLumpName(namebuf, PU_STATIC));

    // yellow #
    arms[i][1] := shortnum[i + 2];
  end;

  // face backgrounds for different color players
  sprintf(namebuf, 'STFB%d', [consoleplayer]);
  faceback := Ppatch_t(W_CacheLumpName(namebuf, PU_STATIC));

  // status bar background bits
  sbar := Ppatch_t(W_CacheLumpName('STBAR', PU_STATIC));

  // face states
  facenum := 0;
  for i := 0 to ST_NUMPAINFACES - 1 do
  begin
    for j := 0 to ST_NUMSTRAIGHTFACES - 1 do
    begin
      sprintf(namebuf, 'STFST%d%d', [i, j]);
      faces[facenum] := W_CacheLumpName(namebuf, PU_STATIC);
      inc(facenum);
    end;
    sprintf(namebuf, 'STFTR%d0', [i]); // turn right
    faces[facenum] := W_CacheLumpName(namebuf, PU_STATIC);
    inc(facenum);
    sprintf(namebuf, 'STFTL%d0', [i]); // turn left
    faces[facenum] := W_CacheLumpName(namebuf, PU_STATIC);
    inc(facenum);
    sprintf(namebuf, 'STFOUCH%d', [i]); // ouch!
    faces[facenum] := W_CacheLumpName(namebuf, PU_STATIC);
    inc(facenum);
    sprintf(namebuf, 'STFEVL%d', [i]); // evil grin ;)
    faces[facenum] := W_CacheLumpName(namebuf, PU_STATIC);
    inc(facenum);
    sprintf(namebuf, 'STFKILL%d', [i]); // pissed off
    faces[facenum] := W_CacheLumpName(namebuf, PU_STATIC);
    inc(facenum);
  end;
  faces[facenum] := W_CacheLumpName('STFGOD0', PU_STATIC);
  inc(facenum);
  faces[facenum] := W_CacheLumpName('STFDEAD0', PU_STATIC);
end;

procedure ST_loadData;
begin
  lu_palette := W_GetNumForName('PLAYPAL');
  ST_loadGraphics;
end;

procedure ST_initData;
var
  i: integer;
begin
  st_firsttime := true;
  plyr := @players[consoleplayer];

  st_clock := 0;
  st_chatstate := StartChatState;
  st_gamestate := FirstPersonState;

  st_statusbaron := true;
  st_oldchat := false;
  st_chat := false;
  st_cursoron := false;

  st_faceindex := 0;
  st_palette := -1;

  st_oldhealth := -1;

  for i := 0 to Ord(NUMWEAPONS) - 1 do
    oldweaponsowned[i] := plyr.weaponowned[i];

  for i := 0 to 2 do
    keyboxes[i] := -1;

  STlib_init;
end;

procedure ST_createWidgets;
var
  i: integer;
begin
  // ready weapon ammo
  STlib_initNum(
    @w_ready,
    ST_AMMOX,
    ST_AMMOY,
    @tallnum,
    @plyr.ammo[Ord(weaponinfo[Ord(plyr.readyweapon)].ammo)],
    @st_statusbaron,
    ST_AMMOWIDTH);

  // the last weapon type
  w_ready.data := Ord(plyr.readyweapon);

  // health percentage
  STlib_initPercent(
    @w_health,
    ST_HEALTHX,
    ST_HEALTHY,
    @tallnum,
    @plyr.health,
    @st_statusbaron,
    tallpercent);

  // arms background
  STlib_initBinIcon(
    @w_armsbg,
    ST_ARMSBGX,
    ST_ARMSBGY,
    armsbg,
    @st_notdeathmatch,
    @st_statusbaron);

  // weapons owned
  for i := 0 to 5 do
  begin
    STlib_initMultIcon(
      @w_arms[i],
      ST_ARMSX + (i mod 3) * ST_ARMSXSPACE,
      ST_ARMSY + (i div 3) * ST_ARMSYSPACE,
      @arms[i],
      @plyr.weaponowned[i + 1],
      @st_armson);
  end;

  // frags sum
  STlib_initNum(
    @w_frags,
    ST_FRAGSX,
    ST_FRAGSY,
    @tallnum,
    @st_fragscount,
    @st_fragson,
    ST_FRAGSWIDTH);

  // faces
  STlib_initMultIcon(
    @w_faces,
    ST_FACESX,
    ST_FACESY,
    @faces,
    @st_faceindex,
    @st_statusbaron);

  // armor percentage - should be colored later
  STlib_initPercent(
    @w_armor,
    ST_ARMORX,
    ST_ARMORY,
    @tallnum,
    @plyr.armorpoints,
    @st_statusbaron,
    tallpercent);

  // keyboxes 0-2
  STlib_initMultIcon(
    @w_keyboxes[0],
    ST_KEY0X,
    ST_KEY0Y,
    @keys,
    @keyboxes[0],
    @st_statusbaron);

  STlib_initMultIcon(
    @w_keyboxes[1],
    ST_KEY1X,
    ST_KEY1Y,
    @keys,
    @keyboxes[1],
    @st_statusbaron);

  STlib_initMultIcon(
    @w_keyboxes[2],
    ST_KEY2X,
    ST_KEY2Y,
    @keys,
    @keyboxes[2],
    @st_statusbaron);

  // ammo count (all four kinds)
  STlib_initNum(
    @w_ammo[0],
    ST_AMMO0X,
    ST_AMMO0Y,
    @shortnum,
    @plyr.ammo[0],
    @st_statusbaron,
    ST_AMMO0WIDTH);

  STlib_initNum(
    @w_ammo[1],
    ST_AMMO1X,
    ST_AMMO1Y,
    @shortnum,
    @plyr.ammo[1],
    @st_statusbaron,
    ST_AMMO1WIDTH);

  STlib_initNum(
    @w_ammo[2],
    ST_AMMO2X,
    ST_AMMO2Y,
    @shortnum,
    @plyr.ammo[2],
    @st_statusbaron,
    ST_AMMO2WIDTH);

  STlib_initNum(
    @w_ammo[3],
    ST_AMMO3X,
    ST_AMMO3Y,
    @shortnum,
    @plyr.ammo[3],
    @st_statusbaron,
    ST_AMMO3WIDTH);

  // max ammo count (all four kinds)
  STlib_initNum(
    @w_maxammo[0],
    ST_MAXAMMO0X,
    ST_MAXAMMO0Y,
    @shortnum,
    @plyr.maxammo[0],
    @st_statusbaron,
    ST_MAXAMMO0WIDTH);

  STlib_initNum(
    @w_maxammo[1],
    ST_MAXAMMO1X,
    ST_MAXAMMO1Y,
    @shortnum,
    @plyr.maxammo[1],
    @st_statusbaron,
    ST_MAXAMMO1WIDTH);

  STlib_initNum(
    @w_maxammo[2],
    ST_MAXAMMO2X,
    ST_MAXAMMO2Y,
    @shortnum,
    @plyr.maxammo[2],
    @st_statusbaron,
    ST_MAXAMMO2WIDTH);

  STlib_initNum(
    @w_maxammo[3],
    ST_MAXAMMO3X,
    ST_MAXAMMO3Y,
    @shortnum,
    @plyr.maxammo[3],
    @st_statusbaron,
    ST_MAXAMMO3WIDTH);
end;

var
  st_stopped: boolean;

procedure ST_Stop;
begin
  if st_stopped then
    exit;

  I_SetPalette(W_CacheLumpNum (lu_palette, PU_CACHE));

  st_stopped := true;
end;

procedure ST_Start;
begin
  if not st_stopped then
    ST_Stop;

  ST_initData;
  ST_createWidgets;
  st_stopped := false;
end;

procedure ST_Init;
begin
  veryfirsttime := 0;
  ST_loadData;
  screens[SCN_ST] := Z_Malloc(ST_WIDTH * ST_HEIGHT, PU_STATIC, nil);
end;


initialization
////////////////////////////////////////////////////////////////////////////////
  veryfirsttime := 1;
  st_msgcounter := 0;
  st_oldhealth := -1;
  st_facecount := 0;
  st_faceindex := 0;

////////////////////////////////////////////////////////////////////////////////
// Now what?
  cheat_mus.sequence := get_cheatseq_string(cheat_mus_seq);
  cheat_mus.p := get_cheatseq_string(0);
  cheat_god.sequence := get_cheatseq_string(cheat_god_seq);
  cheat_god.p := get_cheatseq_string(0);
  cheat_ammo.sequence := get_cheatseq_string(cheat_ammo_seq);
  cheat_ammo.p := get_cheatseq_string(0);
  cheat_ammonokey.sequence := get_cheatseq_string(cheat_ammonokey_seq);
  cheat_ammonokey.p := get_cheatseq_string(0);
  cheat_noclip.sequence := get_cheatseq_string(cheat_noclip_seq);
  cheat_noclip.p := get_cheatseq_string(0);
  cheat_commercial_noclip.sequence := get_cheatseq_string(cheat_commercial_noclip_seq);
  cheat_commercial_noclip.p := get_cheatseq_string(0);

  cheat_powerup[0].sequence := get_cheatseq_string(cheat_powerup_seq0);
  cheat_powerup[0].p := get_cheatseq_string(0);
  cheat_powerup[1].sequence := get_cheatseq_string(cheat_powerup_seq1);
  cheat_powerup[1].p := get_cheatseq_string(0);
  cheat_powerup[2].sequence := get_cheatseq_string(cheat_powerup_seq2);
  cheat_powerup[2].p := get_cheatseq_string(0);
  cheat_powerup[3].sequence := get_cheatseq_string(cheat_powerup_seq3);
  cheat_powerup[3].p := get_cheatseq_string(0);
  cheat_powerup[4].sequence := get_cheatseq_string(cheat_powerup_seq4);
  cheat_powerup[4].p := get_cheatseq_string(0);
  cheat_powerup[5].sequence := get_cheatseq_string(cheat_powerup_seq5);
  cheat_powerup[5].p := get_cheatseq_string(0);
  cheat_powerup[6].sequence := get_cheatseq_string(cheat_powerup_seq6);
  cheat_powerup[6].p := get_cheatseq_string(0);

  cheat_choppers.sequence := get_cheatseq_string(cheat_choppers_seq);
  cheat_choppers.p := get_cheatseq_string(0);
  cheat_clev.sequence := get_cheatseq_string(cheat_clev_seq);
  cheat_clev.p := get_cheatseq_string(0);
  cheat_mypos.sequence := get_cheatseq_string(cheat_mypos_seq);
  cheat_mypos.p := get_cheatseq_string(0);

////////////////////////////////////////////////////////////////////////////////
  lastcalc := 0;
  oldhealth := -1;

////////////////////////////////////////////////////////////////////////////////
  lastattackdown := -1;
  priority := 0;

////////////////////////////////////////////////////////////////////////////////
  largeammo := 1994; // means "n/a"

////////////////////////////////////////////////////////////////////////////////
  st_palette := 0;

////////////////////////////////////////////////////////////////////////////////
  st_stopped := true;

end.
