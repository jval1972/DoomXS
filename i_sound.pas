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

unit i_sound;

interface

uses
  sounds;

// Init at program start...
procedure I_InitSound;

// ... update sound buffer and audio device at runtime...
procedure I_UpdateSound;
procedure I_SubmitSound;

// ... shut down and relase at program termination.
procedure I_ShutdownSound;


//  SFX I/O


// Initialize channels?
procedure I_SetChannels;

// Get raw data lump index for sound descriptor.
function I_GetSfxLumpNum(sfxinfo: Psfxinfo_t): integer;


// Starts a sound in a particular sound channel.
function I_StartSound(id: integer; vol: integer; sep: integer;
  pitch: integer; priority: integer): integer;


// Stops a sound channel.
procedure I_StopSound(handle: integer);

// Called by S_*() functions
//  to see if a channel is still playing.
// Returns 0 if no longer playing, 1 if playing.
function I_SoundIsPlaying(handle: integer): boolean;

// Updates the volume, separation,
//  and pitch of a sound channel.
procedure I_UpdateSoundParams(handle: integer; vol: integer; sep: integer;
  pitch: integer);


implementation

uses
  d_delphi,
  DirectX,
  mmsystem,
  z_zone,
  m_argv,
  m_misc,
  i_system,
  i_main,
  s_sound,
  w_wad,
  doomdef,
  doomstat;

// The number of internal mixing channels,
//  the samples calculated for each mixing step,
//  the size of the 16bit, 2 hardware channel (stereo)
//  mixing buffer, and the samplerate of the raw data.

// Needed for calling the actual sound output.
const
  NUM_CHANNELS = 16;

type
  LPDIRECTSOUND = IDirectSound;
  LPDIRECTSOUNDBUFFER = IDirectSoundBuffer;

var
  pDS: LPDIRECTSOUND;
  pDSBPrimary: LPDIRECTSOUNDBUFFER;
  HandleCount: integer;

  SampleFormat: TWAVEFORMATEX;

  // The actual lengths of all sound effects.
  SoundLengths: array[0..Ord(NUMSFX) - 1] of integer;
  HighSound: boolean = False;

  // The sound in channel handles,
  //  determined on registration,
  //  might be used to unregister/stop/modify,
  //  currently unused.
  channelhandles: array[0..NUM_CHANNELS - 1] of integer;

  // SFX id of the playing sound effect.
  // Used to catch duplicates (like chainsaw).
  channelids: array[0..NUM_CHANNELS - 1] of integer;

  //actual data buffers
  ChannelBuffers: array[0..NUM_CHANNELS - 1] of LPDIRECTSOUNDBUFFER;
  ChannelActive: packed array[0..NUM_CHANNELS - 1] of boolean;


// Retrieve the raw data lump index
//  for a given SFX name.

function I_GetSfxLumpNum(sfxinfo: Psfxinfo_t): integer;
var
  namebuf: string;
begin
  sprintf(namebuf, 'ds%s', [sfxinfo.Name]);
  Result := W_GetNumForName(namebuf);
end;

// This function loads the sound data from the WAD lump,
//  for single sound.

procedure CacheSFX(sfxid: integer);
var
  Name: string;
  sfx: Psfxinfo_t;
begin
  sfx := @S_sfx[sfxid];
  if sfx.Data <> nil then
    exit;
  // Get the sound data from the WAD, allocate lump
  //  in zone memory.
  sprintf(Name, 'ds%s', [sfx.Name]);

  // Now, there is a severe problem with the
  //  sound handling, in it is not (yet/anymore)
  //  gamemode aware. That means, sounds from
  //  DOOM II will be requested even with DOOM
  //  shareware.
  // The sound list is wired into sounds.c,
  //  which sets the external variable.
  // I do not do runtime patches to that
  //  variable. Instead, we will use a
  //  default sound for replacement.
  if W_CheckNumForName(Name) = -1 then
    sfx.lumpnum := W_GetNumForName('dspistol')
  else
    sfx.lumpnum := W_GetNumForName(Name);

  SoundLengths[sfxid] := W_LumpLength(sfx.lumpnum);

  sfx.Data := W_CacheLumpNum(sfx.lumpnum, PU_STATIC);
end;


// SFX API
// Note: this was called by S_Init.
// However, whatever they did in the
// old DPMS based DOS version, this
// were simply dummies in the Linux
// version.
// See soundserver initdata().

procedure I_SetChannels;
begin
end;

procedure I_SetSfxVolume(volume: integer);
begin
  // Identical to DOS.
  // Basically, this should propagate
  //  the menu/config file setting
  //  to the state variable used in
  //  the mixing.
  snd_SfxVolume := volume;
end;

function I_ChannelPlaying(channel: integer): boolean;
var
  status: longword;
begin
  if not boolval(pointer(pDS)) then
  begin
    Result := False;
    exit;
  end;

  if not boolval(pointer(ChannelBuffers[channel])) then
  begin
    Result := False;
    exit;
  end;

  if not ChannelActive[channel] then
  begin
    Result := False;
    exit;
  end;

  ChannelBuffers[channel].GetStatus(status);
  if boolval(status and DSBSTATUS_PLAYING) then
    Result := True
  else
  begin
    ChannelActive[channel] := False;
    Result := False;
  end;
end;

procedure I_KillChannel(channel: integer);
begin
  if not boolval(pointer(pDS)) then
    exit;

  if ChannelBuffers[channel] <> nil then
  begin
    ChannelBuffers[channel].Stop;
    ChannelBuffers[channel]._Release;
  end;
end;

function I_RestartChannel(channel: integer; volume: integer): integer;
var
  dsb: LPDIRECTSOUNDBUFFER;
begin
  if not boolval(pointer(pDS)) then
  begin
    Result := HandleCount;
    Inc(HandleCount);
    exit;
  end;

  ChannelActive[channel] := True;
  dsb := ChannelBuffers[channel];
  if not boolval(pointer(dsb)) then
    I_Error('I_RestartChannel(): Restarting dead sound at channel %d', [channel]);

  dsb.Stop;
  dsb.SetCurrentPosition(0);
  dsb.SetVolume(DSBVOLUME_MIN + _SHR((DSBVOLUME_MAX - DSBVOLUME_MIN) * (volume + 1), 4));
  dsb.Play(0, 0, 0);
  channelhandles[channel] := HandleCount;
  Result := HandleCount;
  Inc(HandleCount);
end;


// Starting a sound means adding it
//  to the current list of active sounds
//  in the internal channels.
// As the SFX info struct contains
//  e.g. a pointer to the raw data,
//  it is ignored.
// As our sound handling does not handle
//  priority, it is ignored.
// Pitching (that is, increased speed of playback)
//  is set, but currently not used by mixing.

function I_StartSound(id: integer; vol: integer; sep: integer;
  pitch: integer; priority: integer): integer;
var
  channel: integer;
  dsb: LPDIRECTSOUNDBUFFER;
  hres: HRESULT;
  dsbd: DSBUFFERDESC;
  oldchannel: integer;
  oldhandle: integer;
  freechannel: integer;
  p: pointer;
  p2: pointer;
  s: longword;
  s2: longword;

  procedure I_ErrorStartSound(const procname: string);
  begin
    I_Error('I_StartSound(): %s failed, result = %d', [procname, hres]);
  end;

begin
  if not boolval(pointer(pDS)) then
  begin
    Result := HandleCount;
    Inc(HandleCount);
    exit;
  end;

  oldhandle := 0;
  oldchannel := 0;
  freechannel := NUM_CHANNELS;
  for channel := 0 to NUM_CHANNELS - 1 do
  begin
    if boolval(pointer(ChannelBuffers[channel])) then
    begin
      if (channelids[channel] = id) and
        (not boolval(pointer(I_ChannelPlaying(channel)))) then
      begin
        Result := I_RestartChannel(channel, vol);
        exit;
      end;
      if HandleCount - channelhandles[channel] > oldhandle then
      begin
        oldhandle := HandleCount - channelhandles[channel];
        oldchannel := channel;
      end;
    end
    else
      freechannel := channel;
  end;

  if boolval(freechannel) then
    channel := freechannel
  else
    channel := oldchannel;
  CacheSFX(id);
  ZeroMemory(dsbd, SizeOf(DSBUFFERDESC));
  dsbd.dwSize := Sizeof(DSBUFFERDESC);
  //dsbd.dwFlags=DSBCAPS_CTRLDEFAULT|DSBCAPS_GETCURRENTPOSITION2|DSBCAPS_STATIC;
  dsbd.dwFlags := DSBCAPS_CTRLVOLUME or DSBCAPS_CTRLFREQUENCY or
    DSBCAPS_CTRLPAN or DSBCAPS_GETCURRENTPOSITION2 or DSBCAPS_STATIC;
  dsbd.dwBufferBytes := SoundLengths[id];
  dsbd.lpwfxFormat := @SampleFormat;

  hres := pDS.CreateSoundBuffer(dsbd, dsb, nil);
  if hres <> DS_OK then
    I_ErrorStartSound('CreateSoundBuffer()');

  hres := dsb.Lock(0, SoundLengths[id] - 8, p, s, p2, s2, 0);
  if hres <> DS_OK then
    I_ErrorStartSound('SoundBuffer.Lock()');

  memcpy(p, pointer(integer(S_sfx[id].Data) + 8), s);
  hres := dsb.Unlock(p, s, p2, s2); // VJ -> dsb.Unlock(p, s, p2, 0); ???
  if hres <> DS_OK then
    I_ErrorStartSound('SoundBuffer.Unlock()');

  ChannelBuffers[channel] := dsb;
  channelids[channel] := id;
  Result := I_RestartChannel(channel, vol);
end;

procedure I_StopSound(handle: integer);
var
  channel: integer;
begin
  if not boolval(pointer(pDS)) then
    exit;

  for channel := 0 to NUM_CHANNELS - 1 do
  begin
    if I_ChannelPlaying(channel) and (channelhandles[channel] = handle) then
    begin
      ChannelBuffers[channel].Stop;
      ChannelActive[channel] := False;
    end;
  end;
end;

function I_SoundIsPlaying(handle: integer): boolean;
var
  channel: integer;
begin
  if not boolval(pointer(pDS)) then
  begin
    Result := False;
    exit;
  end;

  for channel := 0 to NUM_CHANNELS - 1 do
  begin
    if (channelhandles[channel] = handle) and I_ChannelPlaying(channel) then
    begin
      Result := True;
      exit;
    end;
  end;
  Result := False;
end;


// to mix the sounds into buffers, called every frame

procedure I_ProcessSound;
begin
end;

procedure I_UpdateSoundParams(handle: integer; vol: integer; sep: integer;
  pitch: integer);
begin
  // I fail too see that this is used.
  // Would be using the handle to identify
  //  on which channel the sound might be active,
  //  and resetting the channel parameters.
end;

procedure I_ShutdownSound;
var
  i: integer;
begin
  if pDS <> nil then
  begin
    for i := 0 to NUM_CHANNELS - 1 do
      I_KillChannel(i);
  end;

  if pDSBPrimary <> nil then
    pDSBPrimary._Release;

  if pDS <> nil then
    pDS._Release;
end;

procedure I_InitSound;
var
  hres: HRESULT;
  dsbd: DSBUFFERDESC;
  i: integer;
begin
  if boolval(M_CheckParm('-nosound')) then
    exit;

  hres := DirectSoundCreate(nil, pDS, nil);
  if hres <> DS_OK then
  begin
    pDS := nil;
    printf('I_InitSound(): DirectSoundCreate Failed, result = %d', [hres]);
    exit;
  end;

  hres := pDS.SetCooperativeLevel(hMainWnd, DSSCL_PRIORITY);
  if hres <> DS_OK then
    I_Error('I_InitSound(): DirectSound.SetCooperativeLevel Failed, result = %d',
      [hres]);

  SampleFormat.wFormatTag := WAVE_FORMAT_PCM;
  SampleFormat.nChannels := 1;
  SampleFormat.nSamplesPerSec := 11025;
  SampleFormat.cbSize := 0;
  if HighSound then
  begin
    SampleFormat.nBlockAlign := 2;
    SampleFormat.nAvgBytesPerSec := 22050;
    SampleFormat.wBitsPerSample := 16;
  end
  else
  begin
    SampleFormat.nBlockAlign := 1;
    SampleFormat.nAvgBytesPerSec := 11025;
    SampleFormat.wBitsPerSample := 8;
  end;

  ZeroMemory(dsbd, SizeOf(DSBUFFERDESC));
  dsbd.dwSize := SizeOf(DSBUFFERDESC);
  dsbd.dwFlags := DSBCAPS_PRIMARYBUFFER;
  dsbd.dwBufferBytes := 0;
  dsbd.lpwfxFormat := nil;

  hres := pDS.CreateSoundBuffer(dsbd, pDSBPrimary, nil);
  if hres <> DS_OK then
  begin
    printf('I_InitSound(): Unable to access primary sound buffer, result = %d', [hres]);
    pDSBPrimary := nil;
  end
  else
  begin
    hres := pDSBPrimary.SetFormat(SampleFormat);
    if hres <> DS_OK then
      printf('I_InitSound(): Unable to set primary sound buffer format, result = %d',
        [hres]);
    pDSBPrimary.Play(0, 0, DSBPLAY_LOOPING);
  end;

  for i := 0 to NUM_CHANNELS - 1 do
    ChannelBuffers[i] := nil;

  for i := 0 to Ord(NUMSFX) - 1 do
    S_sfx[i].Data := nil;

  SampleFormat.wFormatTag := WAVE_FORMAT_PCM;
  SampleFormat.nChannels := 1;
  SampleFormat.nSamplesPerSec := 11025;
  SampleFormat.nBlockAlign := 1;
  SampleFormat.nAvgBytesPerSec := 11025;
  SampleFormat.wBitsPerSample := 8;
  SampleFormat.cbSize := 0;
end;

// ... update sound buffer and audio device at runtime...
procedure I_UpdateSound;
begin
end;

procedure I_SubmitSound;
begin
end;

initialization
  pDS := nil;
  pDSBPrimary := nil;
  HandleCount := 1;

end.
