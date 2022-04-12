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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/doomxs/
//------------------------------------------------------------------------------
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
unit p_lights;

interface

uses
  m_rnd,
  p_spec,
  r_defs,
  z_memory;

procedure T_FireFlicker(flick: Pfireflicker_t);

procedure P_SpawnFireFlicker(sector: Psector_t);

procedure P_SpawnLightFlash(sector: Psector_t);

procedure T_StrobeFlash(flash: Pstrobe_t);

procedure P_SpawnStrobeFlash(sector: Psector_t; fastOrSlow, inSync: integer);

procedure EV_StartLightStrobing(line: Pline_t);

procedure EV_TurnTagLightsOff(line: Pline_t);

procedure EV_LightTurnOn(line: Pline_t; bright: integer);

procedure T_Glow(g: Pglow_t);

procedure P_SpawnGlowingLight(sector: Psector_t);

procedure T_LightFlash(flash: Plightflash_t);

implementation

uses
  p_tick,
  p_setup;

// FIRELIGHT FLICKER

// T_FireFlicker
procedure T_FireFlicker(flick: Pfireflicker_t);
var
  amount: integer;
begin
  flick.count := flick.count - 1;
  if flick.count > 0 then
    Exit;

  amount := (P_Random and 3) * 16;

  if flick.sector.lightlevel - amount < flick.minlight then
    flick.sector.lightlevel := flick.minlight
  else
    flick.sector.lightlevel := flick.maxlight - amount;

  flick.count := 4;
end;

// P_SpawnFireFlicker
procedure P_SpawnFireFlicker(sector: Psector_t);
var
  flick: Pfireflicker_t;
begin
  // Note that we are resetting sector attributes.
  // Nothing special about it during gameplay.
  sector.special := 0;

  flick := Z_Malloc(SizeOf(fireflicker_t), PU_LEVSPEC, nil);

  P_AddThinker(@flick.thinker);

  flick.thinker.func.acp1 := @T_FireFlicker;
  flick.sector := sector;
  flick.maxlight := sector.lightlevel;
  flick.minlight := P_FindMinSurroundingLight(sector, sector.lightlevel) + 16;
  flick.count := 4;
end;

// BROKEN LIGHT FLASHING

// T_LightFlash
// Do flashing lights.
procedure T_LightFlash(flash: Plightflash_t);
begin
  flash.count := flash.count - 1;
  if flash.count > 0 then
    Exit;

  if flash.sector.lightlevel = flash.maxlight then
  begin
    flash.sector.lightlevel := flash.minlight;
    flash.count := (P_Random and flash.mintime) + 1;
  end
  else
  begin
    flash.sector.lightlevel := flash.maxlight;
    flash.count := (P_Random and flash.maxtime) + 1;
  end;
end;

// P_SpawnLightFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
procedure P_SpawnLightFlash(sector: Psector_t);
var
  flash: Plightflash_t;
begin
  // nothing special about it during gameplay
  sector.special := 0;

  flash := Z_Malloc(SizeOf(lightflash_t), PU_LEVSPEC, nil);

  P_AddThinker(@flash.thinker);

  flash.thinker.func.acp1 := @T_LightFlash;
  flash.sector := sector;
  flash.maxlight := sector.lightlevel;

  flash.minlight := P_FindMinSurroundingLight(sector, sector.lightlevel);
  flash.maxtime := 64;
  flash.mintime := 7;
  flash.count := (P_Random and flash.maxtime) + 1;
end;

// STROBE LIGHT FLASHING

// T_StrobeFlash
procedure T_StrobeFlash(flash: Pstrobe_t);
begin
  flash.count := flash.count - 1;
  if flash.count > 0 then
    Exit;

  if flash.sector.lightlevel = flash.minlight then
  begin
    flash.sector.lightlevel := flash.maxlight;
    flash.count := flash.brighttime;
  end
  else
  begin
    flash.sector.lightlevel := flash.minlight;
    flash.count := flash.darktime;
  end;
end;

// P_SpawnStrobeFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
procedure P_SpawnStrobeFlash(sector: Psector_t; fastOrSlow, inSync: integer);
var
  flash: Pstrobe_t;
begin
  flash := Z_Malloc(SizeOf(strobe_t), PU_LEVSPEC, nil);

  P_AddThinker(@flash.thinker);

  flash.sector := sector;
  flash.darktime := fastOrSlow;
  flash.brighttime := STROBEBRIGHT;
  flash.thinker.func.acp1 := @T_StrobeFlash;
  flash.maxlight := sector.lightlevel;
  flash.minlight := P_FindMinSurroundingLight(sector, sector.lightlevel);

  if flash.minlight = flash.maxlight then
    flash.minlight := 0;

  // nothing special about it during gameplay
  sector.special := 0;

  if inSync = 0 then
    flash.count := (P_Random and 7) + 1
  else
    flash.count := 1;
end;

// Start strobing lights (usually from a trigger)
procedure EV_StartLightStrobing(line: Pline_t);
var
  secnum: integer;
  sec: Psector_t;
begin
  secnum := -1;
  repeat
    secnum := P_FindSectorFromLineTag(line, secnum);

    if secnum >= 0 then
    begin
      sec := @sectors[secnum];
      if sec.specialdata = nil then
        P_SpawnStrobeFlash(sec, SLOWDARK, 0);
    end;
  until secnum < 0;
end;

// TURN LINE'S TAG LIGHTS OFF
procedure EV_TurnTagLightsOff(line: Pline_t);
var
  i: integer;
  j: integer;
  min: integer;
  sector: Psector_t;
  tsec: Psector_t;
  templine: Pline_t;
begin
  for i := 0 to numsectors - 1 do
  begin
    sector := @sectors[i];
    if sector.tag = line.tag then
    begin
      min := sector.lightlevel;
      for j := 0 to sector.linecount - 1 do
      begin
        templine := sector.lines[j];
        tsec := getNextSector(templine, sector);
        if tsec <> nil then
        begin
          if tsec.lightlevel < min then
            min := tsec.lightlevel;
        end;
      end;
      sector.lightlevel := min;
    end;
  end;
end;

// TURN LINE'S TAG LIGHTS ON
procedure EV_LightTurnOn(line: Pline_t; bright: integer);
var
  i: integer;
  j: integer;
  sector: Psector_t;
  temp: Psector_t;
  templine: Pline_t;
begin
  for i := 0 to numsectors - 1 do
  begin
    sector := @sectors[i];
    if sector.tag = line.tag then
    begin
      // bright = 0 means to search
      // for highest light level
      // surrounding sector
      if bright = 0 then
      begin
        for j := 0 to sector.linecount - 1 do
        begin
          templine := sector.lines[j];
          temp := getNextSector(templine, sector);
          if temp <> nil then
          begin
            if temp.lightlevel > bright then
              bright := temp.lightlevel;
          end;
        end;
      end;
      sector.lightlevel := bright;
    end;
  end;
end;

// Spawn glowing light
procedure T_Glow(g: Pglow_t);
begin
  case g.direction of
    -1:
    begin
      // DOWN
      g.sector.lightlevel := g.sector.lightlevel - GLOWSPEED;
      if g.sector.lightlevel <= g.minlight then
      begin
        g.sector.lightlevel := g.sector.lightlevel + GLOWSPEED;
        g.direction := 1;
      end;
    end;
    1:
    begin
      // UP
      g.sector.lightlevel := g.sector.lightlevel + GLOWSPEED;
      if g.sector.lightlevel >= g.maxlight then
      begin
        g.sector.lightlevel := g.sector.lightlevel - GLOWSPEED;
        g.direction := -1;
      end;
    end;
  end;
end;

procedure P_SpawnGlowingLight(sector: Psector_t);
var
  g: Pglow_t;
begin
  g := Z_Malloc(SizeOf(glow_t), PU_LEVSPEC, nil);

  P_AddThinker(@g.thinker);

  g.sector := sector;
  g.minlight := P_FindMinSurroundingLight(sector, sector.lightlevel);
  g.maxlight := sector.lightlevel;
  g.thinker.func.acp1 := @T_Glow;
  g.direction := -1;

  sector.special := 0;
end;

end.
