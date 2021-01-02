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

unit s_sound;

interface

{
    s_sound.h, s_sound.c
}

// Emacs style mode select   -*- C++ -*- 
//-----------------------------------------------------------------------------
//
// $Id:$
//
// Copyright (C) 1993-1996 by id Software, Inc.
//
// This source is available for distribution and/or modification
// only under the terms of the DOOM Source Code License as
// published by id Software. All rights reserved.
//
// The source is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License
// for more details.
//
// DESCRIPTION:
//	The not so system specific sound interface.
//
//-----------------------------------------------------------------------------

//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
procedure S_Init(sfxVolume: integer; musicVolume: integer);


//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
procedure S_Start;


//
// Start sound for thing at <origin>
//  using <sound_id> from sounds.h
//
procedure S_StartSound(origin: pointer; sfx_id: integer);


// Will start a sound at a given volume.
procedure S_StartSoundAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);


// Stop sound for thing at <origin>
procedure S_StopSound(origin: pointer);


// Start music using <music_id> from sounds.h
procedure S_StartMusic(music_id: integer);

// Start music using <music_id> from sounds.h,
//  and set whether looping
procedure S_ChangeMusic(musicnum: integer; looping: boolean);

// Stops the music fer sure.
procedure S_StopMusic;

// Stop and resume music, during game PAUSE.
procedure S_PauseSound;
procedure S_ResumeSound;


//
// Updates music & sounds
//
procedure S_UpdateSounds(listener_p: pointer);

procedure S_SetMusicVolume(volume: integer);
procedure S_SetSfxVolume(volume: integer);

var
// These are not used, but should be (menu).
// Maximum volume of a sound effect.
// Internal default is max out of 0-15.
  snd_SfxVolume: integer;

// Maximum volume of music. Useless so far.
  snd_MusicVolume: integer;

// following is set
//  by the defaults code in M_misc:
// number of channels available
  numChannels: integer;
  
implementation

uses d_delphi,
  d_player,
  g_game,
  i_system, i_sound, i_music,
  m_fixed, m_rnd,
  p_mobj_h, p_local,
  sounds,
  z_zone, w_wad,
  doomdef,
  r_main,
  tables,
  doomstat;

// Purpose?
const
  snd_prefixen: array[0..11] of char =
    ('P', 'P', 'A', 'S', 'S', 'S', 'M', 'M', 'M', 'S', 'S', 'S' );

  S_MAX_VOLUME = 127;

// when to clip out sounds
// Does not fit the large outdoor areas.
  S_CLIPPING_DIST = 1200 * $10000;

// Distance tp origin when sounds should be maxed out.
// This should relate to movement clipping resolution
// (see BLOCKMAP handling).
// Originally: (200*0x10000).
  S_CLOSE_DIST = 160 * $10000;

  S_ATTENUATOR = (S_CLIPPING_DIST - S_CLOSE_DIST) div FRACUNIT;

// Adjustable by menu.
  NORM_PITCH = 128;
  NORM_PRIORITY = 64;
  NORM_SEP = 128;

  S_PITCH_PERTURB = 1;
  S_STEREO_SWING = 96 * $10000;

// percent attenuation from front to back
  S_IFRACVOL = 30;

  NA = 0;
  S_NUMCHANNELS = 2;

type
  channel_t = record
    // sound information (if null, channel avail.)
    sfxinfo: Psfxinfo_t;

    // origin of sound
    origin: pointer;

    // handle of the sound being played
    handle: integer;
  end;
  Pchannel_t = ^channel_t;
  channel_tArray = packed array[0..$FFFF] of channel_t;
  Pchannel_tArray = ^channel_tArray;

// the set of channels available
var
  channels: Pchannel_tArray;

var
// whether songs are mus_paused
  mus_paused: boolean;

// music currently being played
  mus_playing: Pmusicinfo_t;

  nextcleanup: integer;

//
// Internals.
//
function S_getChannel(origin: pointer; sfxinfo: Psfxinfo_t): integer; forward;

function S_AdjustSoundParams(listener: Pmobj_t; source:Pmobj_t;
  vol: Pinteger; sep: Pinteger; pitch:Pinteger): boolean; forward;

procedure S_StopChannel(cnum: integer); forward;

//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
procedure S_Init(sfxVolume: integer; musicVolume: integer);
var
  i: integer;
begin
  printf('S_Init: default sfx volume %d' + #13#10, [sfxVolume]);

  // Whatever these did with DMX, these are rather dummies now.
  I_SetChannels;

  S_SetSfxVolume(sfxVolume);
  // No music with Linux - another dummy.
  S_SetMusicVolume(musicVolume);

  // Allocating the internal channels for mixing
  // (the maximum numer of sounds rendered
  // simultaneously) within zone memory.
  channels := Pchannel_tArray(Z_Malloc(numChannels * SizeOf(channel_t), PU_STATIC, nil));

  // Free all channels for use
  for i := 0 to numChannels - 1 do
    channels[i].sfxinfo := nil;

  // no sounds are playing, and they are not mus_paused
  mus_paused := boolval(0);

  // Note that sounds have not been cached (yet).
  for i := 1 to Ord(NUMSFX) - 1 do
  begin
    S_sfx[i].lumpnum := -1;
    S_sfx[i].usefulness := -1;
  end;
end;

//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
procedure S_Start;
var
  cnum: integer;
  mnum: integer;
begin
  // kill all playing sounds at start of level
  //  (trust me - a good idea)
  for cnum := 0 to numChannels - 1 do
    if boolval(channels[cnum].sfxinfo) then
      S_StopChannel(cnum);

  // start new music for the level
  mus_paused := boolval(0);

  if gamemode = commercial then
    mnum := Ord(mus_runnin) + gamemap - 1
  else
  begin
    if gameepisode < 4 then
      mnum := Ord(mus_e1m1) + (gameepisode - 1) * 9 + gamemap - 1
    else
    begin
      case gamemap of
        1: mnum := Ord(mus_e3m4);  // American	e4m1
        2: mnum := Ord(mus_e3m2);  // Romero	e4m2
        3: mnum := Ord(mus_e3m3);  // Shawn	e4m3
        4: mnum := Ord(mus_e1m5);  // American	e4m4
        5: mnum := Ord(mus_e2m7);  // Tim 	e4m5
        6: mnum := Ord(mus_e2m4);  // Romero	e4m6
        7: mnum := Ord(mus_e2m6);  // J.Anderson	e4m7 CHIRON.WAD
        8: mnum := Ord(mus_e2m5);  // Shawn	e4m8
        9: mnum := Ord(mus_e1m9);  // Tim		e4m9
      else
        mnum := Ord(mus_e1m1); // VJ ?????
      end;
    end;
  end;

  // HACK FOR COMMERCIAL
  //  if (commercial && mnum > mus_e3m9)
  //      mnum -= mus_e3m9;

  S_ChangeMusic(mnum, true);

  nextcleanup := 15;
end;

procedure S_StartSoundAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
var
  rc: boolean;
  sep: integer;
  pitch: integer;
  priority: integer;
  sfx: Psfxinfo_t;
  cnum: integer;
  origin: Pmobj_t;
begin
  origin := Pmobj_t(origin_p);


  // Debug.
  (*fprintf( stderr,
  	   "S_StartSoundAtVolume: playing sound %d (%s)\n",
  	   sfx_id, S_sfx[sfx_id].name );*)

  // check for bogus sound #
  if (sfx_id < 1) or (sfx_id > Ord(NUMSFX)) then
    I_Error('Bad sfx #: %d', [sfx_id]);

  sfx := @S_sfx[sfx_id];

  // Initialize sound parameters
  if boolval(sfx.link) then
  begin
    pitch := sfx.pitch;
    priority := sfx.priority;
    volume := volume + sfx.volume;

    if volume < 1 then
      exit;

    if volume > snd_SfxVolume then
      volume := snd_SfxVolume;
  end
  else
  begin
    pitch := NORM_PITCH;
    priority := NORM_PRIORITY;
  end;

  // Check to see if it is audible,
  //  and if not, modify the params
  if boolval(origin) and (origin <> players[consoleplayer].mo) then
  begin
    rc := S_AdjustSoundParams(players[consoleplayer].mo, origin,
			     @volume,
			     @sep,
			     @pitch);

    if (origin.x = players[consoleplayer].mo.x) and
       (origin.y = players[consoleplayer].mo.y) then
      sep := NORM_SEP;

    if not rc then
      exit;
  end
  else
    sep := NORM_SEP;

  // hacks to vary the sfx pitches
  if (sfx_id >= Ord(sfx_sawup)) and
     (sfx_id <= Ord(sfx_sawhit)) then
  begin
    pitch := pitch + 8 - (M_Random and 15);

    if pitch < 0 then
      pitch := 0
    else if pitch > 255 then
      pitch := 255
  end
  else if (sfx_id <> Ord(sfx_itemup)) and
          (sfx_id <> Ord(sfx_tink)) then
  begin
    pitch := pitch + 16 - (M_Random and 31);

    if pitch < 0 then
      pitch := 0
    else if pitch > 255 then
      pitch := 255;
  end;

  // kill old sound
  S_StopSound(origin);

  // try to find a channel
  cnum := S_getChannel(origin, sfx);

  if cnum < 0 then
    exit;

  //
  // This is supposed to handle the loading/caching.
  // For some odd reason, the caching is done nearly
  //  each time the sound is needed?
  //

  // get lumpnum if necessary
  if sfx.lumpnum < 0 then
    sfx.lumpnum := I_GetSfxLumpNum(sfx);

//#ifndef SNDSRV
//  // cache data if necessary
//  if (!sfx->data)
//  {
//    fprintf( stderr,
//	     "S_StartSoundAtVolume: 16bit and not pre-cached - wtf?\n");
//
//    // DOS remains, 8bit handling
//    //sfx->data = (void *) W_CacheLumpNum(sfx->lumpnum, PU_MUSIC);
//    // fprintf( stderr,
//    //	     "S_StartSoundAtVolume: loading %d (lump %d) : 0x%x\n",
//    //       sfx_id, sfx->lumpnum, (int)sfx->data );
//
//  }
//#endif

  // increase the usefulness
  if sfx.usefulness < 0 then
    sfx.usefulness := 0; // VJ ??? original was := 1
  sfx.usefulness := sfx.usefulness + 1;

  // Assigns the handle to one of the channels in the
  //  mix/output buffer.
  channels[cnum].handle := I_StartSound(sfx_id, volume, sep, pitch, priority);
end;

procedure S_StartSound(origin: pointer; sfx_id: integer);
begin
//#ifdef SAWDEBUG
//    // if (sfx_id == sfx_sawful)
//    // sfx_id = sfx_itemup;
//#endif

  S_StartSoundAtVolume(origin, sfx_id, snd_SfxVolume);


    // UNUSED. We had problems, had we not?
//#ifdef SAWDEBUG
//{
//    int i;
//    int n;
//
//    static mobj_t*      last_saw_origins[10] = {1,1,1,1,1,1,1,1,1,1};
//    static int		first_saw=0;
//    static int		next_saw=0;
//
//    if (sfx_id == sfx_sawidl
//	|| sfx_id == sfx_sawful
//	|| sfx_id == sfx_sawhit)
//    {
//	for (i=first_saw;i!=next_saw;i=(i+1)%10)
//	    if (last_saw_origins[i] != origin)
//		fprintf(stderr, "old origin 0x%lx != "
//			"origin 0x%lx for sfx %d\n",
//			last_saw_origins[i],
//			origin,
//			sfx_id);
//
//	last_saw_origins[next_saw] = origin;
//	next_saw = (next_saw + 1) % 10;
//	if (next_saw == first_saw)
//	    first_saw = (first_saw + 1) % 10;
//
//	for (n=i=0; i<numChannels ; i++)
//	{
//	    if (channels[i].sfxinfo == &S_sfx[sfx_sawidl]
//		|| channels[i].sfxinfo == &S_sfx[sfx_sawful]
//		|| channels[i].sfxinfo == &S_sfx[sfx_sawhit]) n++;
//	}
//
//	if (n>1)
//	{
//	    for (i=0; i<numChannels ; i++)
//	    {
//		if (channels[i].sfxinfo == &S_sfx[sfx_sawidl]
//		    || channels[i].sfxinfo == &S_sfx[sfx_sawful]
//		    || channels[i].sfxinfo == &S_sfx[sfx_sawhit])
//		{
//		    fprintf(stderr,
//			    "chn: sfxinfo=0x%lx, origin=0x%lx, "
//			    "handle=%d\n",
//			    channels[i].sfxinfo,
//			    channels[i].origin,
//			    channels[i].handle);
//		}
//	    }
//	    fprintf(stderr, "\n");
//	}
//    }
//}
//#endif
end;

procedure S_StopSound(origin: pointer);
var
  cnum: integer;
begin
  for cnum := 0 to numChannels - 1 do
  begin
    if boolval(channels[cnum].sfxinfo) and (channels[cnum].origin = origin) then
    begin
      S_StopChannel(cnum);
      break;
    end;
  end;
end;

//
// Stop and resume music, during game PAUSE.
//
procedure S_PauseSound;
begin
  if boolval(mus_playing) and (not mus_paused) then
  begin
    I_PauseSong(mus_playing.handle);
    mus_paused := true;
  end;
end;

procedure S_ResumeSound;
begin
  if boolval(mus_playing) and mus_paused then
  begin
    I_ResumeSong(mus_playing.handle);
    mus_paused := false;
  end;
end;

//
// Updates music & sounds
//
procedure S_UpdateSounds(listener_p: pointer);
var
  audible: boolean;
  cnum: integer;
  volume: integer;
  sep: integer;
  pitch: integer;
  sfx: Psfxinfo_t;
  c: Pchannel_t;
  listener: Pmobj_t;
begin
  listener := Pmobj_t(listener_p);
  // Clean up unused data.
  // This is currently not done for 16bit (sounds cached static).
  // DOS 8bit remains.
    (*if (gametic > nextcleanup)
    {
	for (i=1 ; i<NUMSFX ; i++)
	{
	    if (S_sfx[i].usefulness < 1
		&& S_sfx[i].usefulness > -1)
	    {
		if (--S_sfx[i].usefulness == -1)
		{
		    Z_ChangeTag(S_sfx[i].data, PU_CACHE);
		    S_sfx[i].data = 0;
		}
	    }
	}
	nextcleanup = gametic + 15;
    }*)

  for cnum := 0 to numChannels - 1 do
  begin
    c := @channels[cnum];
    sfx := c.sfxinfo;

    if boolval(c.sfxinfo) then
    begin
      if I_SoundIsPlaying(c.handle) then
      begin
        // initialize parameters
        volume := snd_SfxVolume;
        pitch := NORM_PITCH;
        sep := NORM_SEP;

        if boolval(sfx.link) then
        begin
          pitch := sfx.pitch;
          volume := volume + sfx.volume;
          if volume < 1 then
          begin
            S_StopChannel(cnum);
            continue;
          end
          else if volume > snd_SfxVolume then
          begin
            volume := snd_SfxVolume;
          end;
        end;

        // check non-local sounds for distance clipping
        //  or modify their params
        if boolval(c.origin) and (integer(listener_p) <> integer(c.origin)) then
        begin
          audible := S_AdjustSoundParams(listener, c.origin, @volume, @sep, @pitch);

          if not audible then
          begin
            S_StopChannel(cnum);
          end
          else
            I_UpdateSoundParams(c.handle, volume, sep, pitch);
        end
      end
      else
      begin
        // if channel is allocated but sound has stopped,
        //  free it
        S_StopChannel(cnum);
      end;
    end;
  end;
  // kill music if it is a single-play && finished
  // if (	mus_playing
  //      && !I_QrySongPlaying(mus_playing->handle)
  //      && !mus_paused )
  // S_StopMusic();
end;

procedure S_SetMusicVolume(volume: integer);
begin
  if (volume < 0) or (volume > 15) then
    I_Error('S_SetMusicVolume(): Attempt to set music volume at %d', [volume]);

//  I_SetMusicVolume(15); // VJ ????
  I_SetMusicVolume(volume);
  snd_MusicVolume := volume;
end;

procedure S_SetSfxVolume(volume: integer);
begin
  if (volume < 0) or (volume > 127) then
    I_Error('S_SetSfxVolume(): Attempt to set sfx volume at %d', [volume]);

  snd_SfxVolume := volume;
end;

//
// Starts some music with the music id found in sounds.h.
//
procedure S_StartMusic(music_id: integer);
begin
  S_ChangeMusic(music_id, false);
end;

procedure S_ChangeMusic(musicnum: integer; looping: boolean);
var
  music: Pmusicinfo_t;
  namebuf: char8_t;
begin
  if (musicnum <= Ord(mus_None)) or
     (musicnum >= Ord(NUMMUSIC)) then
    I_Error('S_ChangeMusic(): Bad music number %d', [musicnum]);

  music := @S_music[musicnum];

  if mus_playing = music then
    exit;

  // shutdown old music
  S_StopMusic;

  // get lumpnum if neccessary
  if not boolval(music.lumpnum) then
  begin
    namebuf := stringtochar8('d_' + music.name);
    music.lumpnum := W_GetNumForName(namebuf);
  end;

  // load & register it
  music.data := W_CacheLumpNum(music.lumpnum, PU_MUSIC);
  music.handle := I_RegisterSong(music.data, W_LumpLength(music.lumpnum));

  // play it
  I_PlaySong(music.handle, looping);

  mus_playing := music;
end;

procedure S_StopMusic;
begin
  if boolval(mus_playing) then
  begin
    if mus_paused then
      I_ResumeSong(mus_playing.handle);

    I_UnRegisterSong(mus_playing.handle);
    Z_ChangeTag(mus_playing.data, PU_CACHE);

    mus_playing.data := nil;
    mus_playing := nil;
  end;
end;

procedure S_StopChannel(cnum: integer);
var
  i: integer;
  c: Pchannel_t;
begin
  c := @channels[cnum];

  if boolval(c.sfxinfo) then
  begin
    // stop the sound playing
    if I_SoundIsPlaying(c.handle) then
    begin
//#ifdef SAWDEBUG
//	    if (c->sfxinfo == &S_sfx[sfx_sawful])
//		fprintf(stderr, "stopped\n");
//#endif
      I_StopSound(c.handle);
    end;

    // check to see
    //  if other channels are playing the sound
    for i := 0 to numChannels - 1 do
    begin
	    if (cnum <> i) and
         (c.sfxinfo = channels[i].sfxinfo) then
        break;
    end;

    // degrade usefulness of sound data
    c.sfxinfo.usefulness := c.sfxinfo.usefulness - 1;

    c.sfxinfo := nil;
  end;
end;

//
// Changes volume, stereo-separation, and pitch variables
//  from the norm of a sound effect to be played.
// If the sound is not audible, returns a 0.
// Otherwise, modifies parameters and returns 1.
//
function S_AdjustSoundParams(listener: Pmobj_t; source:Pmobj_t;
  vol: Pinteger; sep: Pinteger; pitch:Pinteger): boolean;
var
  approx_dist: fixed_t;
  adx: fixed_t;
  ady: fixed_t;
  angle: angle_t;
begin
  // calculate the distance to sound origin
  //  and clip it if necessary
  adx := abs(listener.x - source.x);
  ady := abs(listener.y - source.y);

  // From _GG1_ p.428. Appox. eucledian distance fast.
  approx_dist := adx + ady - _SHR(decide(adx < ady, adx, ady), 1);

  if (gamemap <> 8) and
     (approx_dist > S_CLIPPING_DIST) then
  begin
    result := false;
    exit;
  end;

  // angle of source to listener
  angle := R_PointToAngle2(listener.x, listener.y, source.x, source.y);

  if angle > listener.angle then
    angle := angle - listener.angle
  else
    angle := angle + ($ffffffff - listener.angle);

  angle := _SHRW(angle, ANGLETOFINESHIFT);

  // stereo separation
  sep^ := 128 - (FixedMul(S_STEREO_SWING, finesine[angle]) div FRACUNIT);

  // volume calculation
  if approx_dist < S_CLOSE_DIST then
  begin
    vol^ := snd_SfxVolume;
  end
  else if gamemap = 8 then
  begin
    if approx_dist > S_CLIPPING_DIST then
      approx_dist := S_CLIPPING_DIST;

    vol^ := 15 + ((snd_SfxVolume - 15) *
      ((S_CLIPPING_DIST - approx_dist) div FRACUNIT)) div S_ATTENUATOR;
  end
  else
  begin
    // distance effect
    vol^ := (snd_SfxVolume * ((S_CLIPPING_DIST - approx_dist) div FRACUNIT)) div
              S_ATTENUATOR;
  end;

  result := vol^ > 0;
end;

//
// S_getChannel :
//   If none available, return -1.  Otherwise channel #.
//
function S_getChannel(origin: pointer; sfxinfo: Psfxinfo_t): integer;
var
  // channel number to use
  cnum: integer;
  c: Pchannel_t;
begin
  // Find an open channel
  cnum := 0;
  while cnum < numChannels do
  begin
    if not boolval(channels[cnum].sfxinfo) then
      break
    else if boolval(origin) and (channels[cnum].origin = origin) then
    begin
      S_StopChannel(cnum);
      break;
    end;
    inc(cnum);
  end;

  // None available
  if cnum = numChannels then
  begin
    // Look for lower priority
    cnum := 0;
    while cnum < numChannels do
    begin
	    if channels[cnum].sfxinfo.priority >= sfxinfo.priority then
        break;
      inc(cnum);
    end;

    if cnum = numChannels then
    begin
      // FUCK!  No lower priority.  Sorry, Charlie.
      result := -1;
      exit;
    end
    else
    begin
      // Otherwise, kick out lower priority.
      S_StopChannel(cnum);
    end;
  end;

  c := @channels[cnum];

  // channel is decided to be cnum.
  c.sfxinfo := sfxinfo;
  c.origin := origin;

  result := cnum;
end;





initialization
  snd_SfxVolume := 15;
  snd_MusicVolume := 15;

  mus_playing := nil;


end.