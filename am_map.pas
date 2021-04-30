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

//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/doomxs/
//------------------------------------------------------------------------------

unit am_map;

interface

uses
  d_delphi,
  z_memory,
  doomdef,
  doomdata,
  d_player,
  r_defs,
  d_event,
  st_stuff,
  p_local,
  w_wad,
  m_cheat,
  i_system,
  v_video,
  m_fixed;

const
  AM_MSGHEADER = (Ord('a') shl 24) + (Ord('m') shl 16);
  AM_MSGENTERED = AM_MSGHEADER or (Ord('e') shl 8);
  AM_MSGEXITED = AM_MSGHEADER or (Ord('x') shl 8);

{ Called by main loop. }
const
  REDS = 256 - (5 * 16);
  REDRANGE = 16;
  BLUES = (256 - (4 * 16)) + 8;
  BLUERANGE = 8;
  GREENS = 7 * 16;
  GREENRANGE = 16;
  GRAYS = 6 * 16;
  GRAYSRANGE = 16;
  BROWNS = 4 * 16;
  BROWNRANGE = 16;
  YELLOWS = (256 - 32) + 7;
  YELLOWRANGE = 1;
  BLACK = 0;
  WHITE = 256 - 47;

  { Automap colors }
  BACKGROUND = BLACK;
  YOURCOLORS = WHITE;
  YOURRANGE = 0;
  WALLCOLORS = REDS;
  WALLRANGE = REDRANGE;
  TSWALLCOLORS = GRAYS;
  TSWALLRANGE = GRAYSRANGE;
  FDWALLCOLORS = BROWNS;
  FDWALLRANGE = BROWNRANGE;
  CDWALLCOLORS = YELLOWS;
  CDWALLRANGE = YELLOWRANGE;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  SECRETWALLCOLORS = WALLCOLORS;
  SECRETWALLRANGE = WALLRANGE;
  GRIDCOLORS = GRAYS + (GRAYSRANGE div 2);
  GRIDRANGE = 0;
  XHAIRCOLORS = GRAYS;

  AM_PANDOWNKEY = KEY_DOWNARROW;
  AM_PANUPKEY = KEY_UPARROW;
  AM_PANRIGHTKEY = KEY_RIGHTARROW;
  AM_PANLEFTKEY = KEY_LEFTARROW;
  AM_ZOOMINKEY = '=';
  AM_ZOOMOUTKEY = '-';
  AM_STARTKEY = KEY_TAB;
  AM_ENDKEY = KEY_TAB;
  AM_GOBIGKEY = '0';
  AM_FOLLOWKEY = 'f';
  AM_GRIDKEY = 'g';
  AM_MARKKEY = 'm';
  AM_CLEARMARKKEY = 'c';

  AM_NUMMARKPOINTS = 10;

// scale on entry
  INITSCALEMTOF = FRACUNIT div 5;

// how much the automap moves window per tic in frame-buffer coordinates }
// moves 140 pixels in 1 second }
  F_PANINC = 4;

{ how much zoom-in per tic }
function M_ZOOMIN: integer;

{ how much zoom-out per tic }
function M_ZOOMOUT: integer;

{ translates between frame-buffer and map distances }
function FTOM(x: integer): integer;
function MTOF(x: integer): integer;

{ translates between frame-buffer and map coordinates }
function CXMTOF(x: integer): integer;
function CYMTOF(y: integer): integer;

{ the following is crap }

const
  LINE_NEVERSEE = ML_DONTDRAW;

type
  fpoint_t = record
    x: integer;
    y: integer;
  end;
  Pfpoint_t = ^fpoint_t;

  fline_t = record
    a: fpoint_t;
    b: fpoint_t;
  end;
  Pfline_t = ^fline_t;

  mpoint_t = record
    x: fixed_t;
    y: fixed_t;
  end;
  Pmpoint_t = ^mpoint_t;

  mline_t = record
    a: mpoint_t;
    b: mpoint_t;
  end;
  Pmline_t = ^mline_t;
  mline_tArray = packed array[0..$FFFF] of mline_t;
  Pmline_tArray = ^mline_tArray;

  islope_t = record
    slp: fixed_t;
    islp: fixed_t;
  end;
  Pislope_t = ^islope_t;

// The vector graphics for the automap.
//  A line drawing of the player pointing right,
//   starting from the middle.
const
  NUMPLYRLINES = 7;

var
  player_arrow: array[0..NUMPLYRLINES - 1] of mline_t;

const
  NUMCHEATPLYRLINES = 16;

var
  cheat_player_arrow: array[0..NUMCHEATPLYRLINES - 1] of mline_t;

const
  NUMTRIANGLEGUYLINES = 3;

var
  triangle_guy: array[0..NUMTRIANGLEGUYLINES - 1] of mline_t;

const
  NUMTHINTRIANGLEGUYLINES = 3;

var
  thintriangle_guy: array[0..NUMTHINTRIANGLEGUYLINES - 1] of mline_t;

var
  cheating: integer = 0;
  grid: boolean = False;

  leveljuststarted: integer = 1;   // kluge until AM_LevelInit() is called

  automapactive: boolean = False;

  finit_width: integer = SCREENWIDTH;
  finit_height: integer = (200 - 32) * SCREENHEIGHT div 200;

  // location of window on screen
  f_x: integer;
  f_y: integer;

  // size of window on screen
  f_w: integer;
  f_h: integer;

  fb: PByteArray;       // pseudo-frame buffer
  amclock: integer;

  m_paninc: mpoint_t;    // how far the window pans each tic (map coords)
  mtof_zoommul: fixed_t; // how far the window zooms in each tic (map coords)
  ftom_zoommul: fixed_t; // how far the window zooms in each tic (fb coords)

  m_x, m_y: fixed_t;    // LL x,y where the window is on the map (map coords)
  m_x2, m_y2: fixed_t;  // UR x,y where the window is on the map (map coords)

  // width/height of window on map (map coords)
  m_w: fixed_t;
  m_h: fixed_t;

  // based on level size
  min_x: fixed_t;
  min_y: fixed_t;
  max_x: fixed_t;
  max_y: fixed_t;

  max_w: fixed_t; // max_x-min_x,
  max_h: fixed_t; // max_y-min_y

  // based on player size
  min_w: fixed_t;
  min_h: fixed_t;


  min_scale_mtof: fixed_t; // used to tell when to stop zooming out
  max_scale_mtof: fixed_t; // used to tell when to stop zooming in

  // old stuff for recovery later
  old_m_w, old_m_h: fixed_t;
  old_m_x, old_m_y: fixed_t;

  // old location used by the Follower routine
  f_oldloc: mpoint_t;

  // used by MTOF to scale from map-to-frame-buffer coords
  scale_mtof: fixed_t = INITSCALEMTOF;
  // used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)
  scale_ftom: fixed_t;

  plr: Pplayer_t; // the player represented by an arrow

var
  marknums: packed array[0..9] of Ppatch_t; // numbers used for marking by the automap

  markpoints: array[0..AM_NUMMARKPOINTS - 1] of mpoint_t; // where the points are

  markpointnum: integer = 0; // next point to be assigned

  followplayer: boolean = True; // specifies whether to follow the player around

const
  cheat_amap_seq: string = Chr($b2) + Chr($26) + Chr($26) + Chr($2e) + Chr($ff);

var
  cheat_amap: cheatseq_t;

  stopped: boolean = True;

function AM_Responder(ev: Pevent_t): boolean;

// Called by main loop.
procedure AM_Ticker;

// Called by main loop,
// called instead of view drawer if automap active.
procedure AM_Drawer;

{ Called to force the automap to quit }
{ if the level is completed while it is up. }
procedure AM_Stop;

procedure AM_Init;

implementation

uses
  tables,
  d_englsh,
  g_game,
  p_mobj_h,
  p_setup;

{ how much zoom-in per tic }
function M_ZOOMIN: integer;
begin
  Result := trunc(1.02 * FRACUNIT);
end;

{ how much zoom-out per tic }
function M_ZOOMOUT: integer;
begin
  Result := trunc(FRACUNIT / 1.02);
end;

function FTOM(x: integer): integer;
begin
  Result := FixedMul(_SHL(x, 16), scale_ftom);
end;

function MTOF(x: integer): integer;
begin
  Result := _SHR(FixedMul(x, scale_mtof), 16);
end;

function CXMTOF(x: integer): integer;
begin
  Result := f_x + MTOF(x - m_x);
end;

function CYMTOF(y: integer): integer;
begin
  Result := f_y + (f_h - MTOF(y - m_y));
end;

procedure AM_getIslope(ml: Pmline_t; _is: Pislope_t);
var
  dx, dy: integer;
begin
  dx := ml.b.x - ml.a.x;
  dy := ml.a.y - ml.b.y;

  if dy = 0 then
  begin
    if dx < 0 then
      _is.islp := -MAXINT
    else
      _is.islp := MAXINT;
  end
  else
    _is.islp := FixedDiv(dx, dy);

  if dx = 0 then
  begin
    if dy < 0 then
      _is.slp := -MAXINT
    else
      _is.slp := MAXINT;
  end
  else
    _is.slp := FixedDiv(dy, dx);
end;

procedure AM_activateNewScale;
begin
  m_x := m_x + m_w div 2;
  m_y := m_y + m_h div 2;
  m_w := FTOM(f_w);
  m_h := FTOM(f_h);
  m_x := m_x - m_w div 2;
  m_y := m_y - m_h div 2;
  m_x2 := m_x + m_w;
  m_y2 := m_y + m_h;
end;

procedure AM_saveScaleAndLoc;
begin
  old_m_x := m_x;
  old_m_y := m_y;
  old_m_w := m_w;
  old_m_h := m_h;
end;

procedure AM_restoreScaleAndLoc;
begin
  m_w := old_m_w;
  m_h := old_m_h;
  if not followplayer then
  begin
    m_x := old_m_x;
    m_y := old_m_y;
  end
  else
  begin
    m_x := plr.mo.x - m_w div 2;
    m_y := plr.mo.y - m_h div 2;
  end;

  m_x2 := m_x + m_w;
  m_y2 := m_y + m_h;

  // Change the scaling multipliers
  scale_mtof := FixedDiv(f_w * FRACUNIT, m_w);
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);
end;

// adds a marker at the current location
procedure AM_addMark;
begin
  markpoints[markpointnum].x := m_x + m_w div 2;
  markpoints[markpointnum].y := m_y + m_h div 2;
  markpointnum := (markpointnum + 1) mod AM_NUMMARKPOINTS;
end;

// Determines bounding box of all vertices,
// sets global variables controlling zoom range.
procedure AM_findMinMaxBoundaries;
var
  i: integer;
  a, b: fixed_t;
begin
  min_x := MAXINT;
  min_y := MAXINT;
  max_x := -MAXINT;
  max_y := -MAXINT;

  for i := 0 to numvertexes - 1 do
  begin
    if vertexes[i].x < min_x then
      min_x := vertexes[i].x
    else if vertexes[i].x > max_x then
      max_x := vertexes[i].x;

    if vertexes[i].y < min_y then
      min_y := vertexes[i].y
    else if vertexes[i].y > max_y then
      max_y := vertexes[i].y;
  end;

  max_w := max_x - min_x;
  max_h := max_y - min_y;

  min_w := 2 * PLAYERRADIUS; // const? never changed?
  min_h := 2 * PLAYERRADIUS;

  a := FixedDiv(f_w * FRACUNIT, max_w);
  b := FixedDiv(f_h * FRACUNIT, max_h);

  if a < b then
    min_scale_mtof := a
  else
    min_scale_mtof := b;

  max_scale_mtof := FixedDiv(f_h * FRACUNIT, 2 * PLAYERRADIUS);
end;

procedure AM_changeWindowLoc;
begin
  if (m_paninc.x <> 0) or (m_paninc.y <> 0) then
  begin
    followplayer := False;
    f_oldloc.x := MAXINT;
  end;

  m_x := m_x + m_paninc.x;
  m_y := m_y + m_paninc.y;

  if m_x + m_w div 2 > max_x then
    m_x := max_x - m_w div 2
  else if m_x + m_w div 2 < min_x then
    m_x := min_x - m_w div 2;

  if m_y + m_h div 2 > max_y then
    m_y := max_y - m_h div 2
  else if m_y + m_h div 2 < min_y then
    m_y := min_y - m_h div 2;

  m_x2 := m_x + m_w;
  m_y2 := m_y + m_h;
end;

var
  st_notify_AM_initVariables: event_t;

procedure AM_initVariables;
var
  pnum: integer;
  i: integer;
begin
  automapactive := True;
  fb := screens[SCN_FG];

  f_oldloc.x := MAXINT;
  amclock := 0;

  m_paninc.x := 0;
  m_paninc.y := 0;

  ftom_zoommul := FRACUNIT;
  mtof_zoommul := FRACUNIT;

  m_w := FTOM(f_w);
  m_h := FTOM(f_h);

  // find player to center on initially
  pnum := consoleplayer;
  if not playeringame[pnum] then
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
      begin
        pnum := i;
        break;
      end;

  plr := @players[pnum];
  m_x := plr.mo.x - m_w div 2;
  m_y := plr.mo.y - m_h div 2;
  AM_changeWindowLoc;

  // for saving & restoring
  //AM_saveScaleAndLoc;
  old_m_x := m_x;
  old_m_y := m_y;
  old_m_w := m_w;
  old_m_h := m_h;

  // inform the status bar of the change
  ST_Responder(@st_notify_AM_initVariables);
end;

procedure AM_loadPics;
var
  i: integer;
  namebuf: string;
begin
  for i := 0 to AM_NUMMARKPOINTS - 1 do
  begin
    sprintf(namebuf, 'AMMNUM%d', [i]);
    marknums[i] := W_CacheLumpName(namebuf, PU_STATIC);
  end;
end;

procedure AM_unloadPics;
var
  i: integer;
begin
  for i := 0 to AM_NUMMARKPOINTS - 1 do
    Z_ChangeTag(marknums[i], PU_CACHE);
end;

procedure AM_clearMarks;
var
  i: integer;
begin
  for i := 0 to AM_NUMMARKPOINTS - 1 do
    markpoints[i].x := -1; // means empty
  markpointnum := 0;
end;

// should be called at the start of every level
// right now, i figure it out myself
procedure AM_LevelInit;
begin
  leveljuststarted := 0;

  f_x := 0;
  f_y := 0;
  f_w := finit_width;
  f_h := finit_height;

  AM_clearMarks;

  AM_findMinMaxBoundaries;
  scale_mtof := FixedDiv(min_scale_mtof, trunc(0.7 * FRACUNIT));
  if scale_mtof > max_scale_mtof then
    scale_mtof := min_scale_mtof;
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);
end;

var
  st_notify_AM_Stop: event_t;

procedure AM_Stop;
begin
  AM_unloadPics;
  automapactive := False;
  ST_Responder(@st_notify_AM_Stop);
  stopped := True;
end;

var
  lastlevel: integer = -1;
  lastepisode: integer = -1;

procedure AM_Start;
begin
  if not stopped then
    AM_Stop;
  stopped := False;

  if (lastlevel <> gamemap) or (lastepisode <> gameepisode) then
  begin
    AM_LevelInit;
    lastlevel := gamemap;
    lastepisode := gameepisode;
  end;
  AM_initVariables;
  AM_loadPics;
end;

// set the window scale to the maximum size
procedure AM_minOutWindowScale;
begin
  scale_mtof := min_scale_mtof;
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);
  AM_activateNewScale;
end;

// set the window scale to the minimum size
procedure AM_maxOutWindowScale;
begin
  scale_mtof := max_scale_mtof;
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);
  AM_activateNewScale;
end;

// Handle events (user inputs) in automap mode
var
  cheatstate: integer = 0;
  bigstate: boolean = False;

function AM_Responder(ev: Pevent_t): boolean;
var
  msg: string;
begin
  Result := False;

  if not automapactive then
  begin
    if (ev._type = ev_keydown) and (ev.data1 = AM_STARTKEY) then
    begin
      AM_Start;
      viewactive := False;
      Result := True;
    end;
  end
  else if ev._type = ev_keydown then
  begin
    Result := True;
    case ev.data1 of
      AM_PANRIGHTKEY: // pan right
      begin
        if not followplayer then
          m_paninc.x := FTOM(F_PANINC)
        else
          Result := False;
      end;
      AM_PANLEFTKEY: // pan left
      begin
        if not followplayer then
          m_paninc.x := -FTOM(F_PANINC)
        else
          Result := False;
      end;
      AM_PANUPKEY: // pan up
      begin
        if not followplayer then
          m_paninc.y := FTOM(F_PANINC)
        else
          Result := False;
      end;
      AM_PANDOWNKEY: // pan down
      begin
        if not followplayer then
          m_paninc.y := -FTOM(F_PANINC)
        else
          Result := False;
      end;
      Ord(AM_ZOOMOUTKEY): // zoom out
      begin
        mtof_zoommul := M_ZOOMOUT;
        ftom_zoommul := M_ZOOMIN;
      end;
      Ord(AM_ZOOMINKEY): // zoom in
      begin
        mtof_zoommul := M_ZOOMIN;
        ftom_zoommul := M_ZOOMOUT;
      end;
      AM_ENDKEY:
      begin
        bigstate := False;
        viewactive := True;
        AM_Stop;
      end;
      Ord(AM_GOBIGKEY):
      begin
        bigstate := not bigstate;
        if bigstate then
        begin
          AM_saveScaleAndLoc;
          AM_minOutWindowScale;
        end
        else
          AM_restoreScaleAndLoc;
      end;
      Ord(AM_FOLLOWKEY):
      begin
        followplayer := not followplayer;
        f_oldloc.x := MAXINT;
        if followplayer then
          plr.msg := AMSTR_FOLLOWON
        else
          plr.msg := AMSTR_FOLLOWOFF;
      end;
      Ord(AM_GRIDKEY):
      begin
        grid := not grid;
        if grid then
          plr.msg := AMSTR_GRIDON
        else
          plr.msg := AMSTR_GRIDOFF;
      end;
      Ord(AM_MARKKEY):
      begin
        sprintf(msg, '%s %d', [AMSTR_MARKEDSPOT, markpointnum]);
        plr.msg := msg;
        AM_addMark;
      end;
      Ord(AM_CLEARMARKKEY):
      begin
        AM_clearMarks;
        plr.msg := AMSTR_MARKSCLEARED;
      end
      else
      begin
        cheatstate := 0;
        Result := False;
      end
    end;
    if (deathmatch = 0) and cht_CheckCheat(@cheat_amap, Chr(ev.data1)) then
    begin
      Result := False;
      cheating := (cheating + 1) mod 3;
    end;
  end
  else if ev._type = ev_keyup then
  begin
    Result := False;
    case ev.data1 of
      AM_PANRIGHTKEY:
      begin
        if not followplayer then
          m_paninc.x := 0;
      end;
      AM_PANLEFTKEY:
      begin
        if not followplayer then
          m_paninc.x := 0;
      end;
      AM_PANUPKEY:
      begin
        if not followplayer then
          m_paninc.y := 0;
      end;
      AM_PANDOWNKEY:
      begin
        if not followplayer then
          m_paninc.y := 0;
      end;
      Ord(AM_ZOOMOUTKEY),
      Ord(AM_ZOOMINKEY):
      begin
        mtof_zoommul := FRACUNIT;
        ftom_zoommul := FRACUNIT;
      end;
    end;
  end;

end;


// Zooming

procedure AM_changeWindowScale;
begin
  // Change the scaling multipliers
  scale_mtof := FixedMul(scale_mtof, mtof_zoommul);
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);

  if scale_mtof < min_scale_mtof then
    AM_minOutWindowScale
  else if scale_mtof > max_scale_mtof then
    AM_maxOutWindowScale
  else
    AM_activateNewScale;
end;

procedure AM_doFollowPlayer;
begin
  if (f_oldloc.x <> plr.mo.x) or (f_oldloc.y <> plr.mo.y) then
  begin
    m_x := FTOM(MTOF(plr.mo.x)) - m_w div 2;
    m_y := FTOM(MTOF(plr.mo.y)) - m_h div 2;
    m_x2 := m_x + m_w;
    m_y2 := m_y + m_h;
    f_oldloc.x := plr.mo.x;
    f_oldloc.y := plr.mo.y;
  end;
end;

procedure AM_Ticker;
begin
  if not automapactive then
    exit;

  Inc(amclock);

  if followplayer then
    AM_doFollowPlayer;

  // Change the zoom if necessary
  if ftom_zoommul <> FRACUNIT then
    AM_changeWindowScale;

  // Change x,y location
  if (m_paninc.x <> 0) or (m_paninc.y <> 0) then
    AM_changeWindowLoc;

end;

// Clear automap frame buffer.
procedure AM_clearFB(color: integer);
begin
  FillChar(fb^, f_w * f_h, color);
end;

// Automap clipping of lines.
// Based on Cohen-Sutherland clipping algorithm but with a slightly
// faster reject and precalculated slopes.  If the speed is needed,
// use a hash algorithm to handle  the common cases.
function AM_clipMline(ml: Pmline_t; fl: Pfline_t): boolean;
const
  LEFT = 1;
  RIGHT = 2;
  BOTTOM = 4;
  TOP = 8;
var
  outcode1, outcode2, outside: integer;
  tmp: fpoint_t;
  dx, dy: integer;

  procedure DOOUTCODE(var oc: integer; mx, my: integer);
  begin
    oc := 0;
    if my < 0 then
      oc := oc or TOP
    else if my >= f_h then
      oc := oc or BOTTOM;
    if mx < 0 then
      oc := oc or LEFT
    else if mx >= f_w then
      oc := oc or RIGHT;
  end;

begin
  // do trivial rejects and outcodes
  if ml.a.y > m_y2 then
    outcode1 := TOP
  else if ml.a.y < m_y then
    outcode1 := BOTTOM
  else
    outcode1 := 0;

  if ml.b.y > m_y2 then
    outcode2 := TOP
  else if ml.b.y < m_y then
    outcode2 := BOTTOM
  else
    outcode2 := 0;

  if outcode1 and outcode2 <> 0 then
  begin
    Result := False; // trivially outside
    exit;
  end;

  if ml.a.x < m_x then
    outcode1 := outcode1 or LEFT
  else if ml.a.x > m_x2 then
    outcode1 := outcode1 or RIGHT;

  if ml.b.x < m_x then
    outcode2 := outcode2 or LEFT
  else if ml.b.x > m_x2 then
    outcode2 := outcode2 or RIGHT;

  if outcode1 and outcode2 <> 0 then
  begin
    Result := False; // trivially outside
    exit;
  end;

  // transform to frame-buffer coordinates.
  fl.a.x := CXMTOF(ml.a.x);
  fl.a.y := CYMTOF(ml.a.y);
  fl.b.x := CXMTOF(ml.b.x);
  fl.b.y := CYMTOF(ml.b.y);

  DOOUTCODE(outcode1, fl.a.x, fl.a.y);
  DOOUTCODE(outcode2, fl.b.x, fl.b.y);

  if outcode1 and outcode2 <> 0 then
  begin
    Result := False; // trivially outside
    exit;
  end;

  while outcode1 or outcode2 <> 0 do
  begin
    // may be partially inside box
    // find an outside point
    if outcode1 <> 0 then
      outside := outcode1
    else
      outside := outcode2;

    // clip to each side
    if outside and TOP <> 0 then
    begin
      dy := fl.a.y - fl.b.y;
      dx := fl.b.x - fl.a.x;
      tmp.x := fl.a.x + (dx * (fl.a.y)) div dy;
      tmp.y := 0;
    end
    else if outside and BOTTOM <> 0 then
    begin
      dy := fl.a.y - fl.b.y;
      dx := fl.b.x - fl.a.x;
      tmp.x := fl.a.x + (dx * (fl.a.y - f_h)) div dy;
      tmp.y := f_h - 1;
    end
    else if outside and RIGHT <> 0 then
    begin
      dy := fl.b.y - fl.a.y;
      dx := fl.b.x - fl.a.x;
      tmp.y := fl.a.y + (dy * (f_w - 1 - fl.a.x)) div dx;
      tmp.x := f_w - 1;
    end
    else if outside and LEFT <> 0 then
    begin
      dy := fl.b.y - fl.a.y;
      dx := fl.b.x - fl.a.x;
      tmp.y := fl.a.y + (dy * (-fl.a.x)) div dx;
      tmp.x := 0;
    end;

    if outside = outcode1 then
    begin
      fl.a := tmp;
      DOOUTCODE(outcode1, fl.a.x, fl.a.y);
    end
    else
    begin
      fl.b := tmp;
      DOOUTCODE(outcode2, fl.b.x, fl.b.y);
    end;

    if outcode1 and outcode2 <> 0 then
    begin
      Result := False; // trivially outside
      exit;
    end;
  end;

  Result := True;
end;

// Classic Bresenham w/ whatever optimizations needed for speed
procedure AM_drawFline(fl: Pfline_t; color: integer);
var
  x, y, dx, dy, sx, sy, ax, ay, d: integer;

  procedure PUTDOT(xx, yy, cc: integer);
  begin
    fb[yy * f_w + xx] := cc;
  end;

begin
  // For debugging only
  if (fl.a.x < 0) or (fl.a.x >= f_w) or (fl.a.y < 0) or (fl.a.y >= f_h) or
    (fl.b.x < 0) or (fl.b.x >= f_w) or (fl.b.y < 0) or (fl.b.y >= f_h) then
  begin
    I_Error('AM_drawFline(): fuck!');
    exit;
  end;

  dx := fl.b.x - fl.a.x;
  ax := 2 * abs(dx);
  if dx < 0 then
    sx := -1
  else
    sx := 1;

  dy := fl.b.y - fl.a.y;
  ay := 2 * abs(dy);
  if dy < 0 then
    sy := -1
  else
    sy := 1;

  x := fl.a.x;
  y := fl.a.y;

  if ax > ay then
  begin
    d := ay - ax div 2;
    while True do
    begin
      PUTDOT(x, y, color);
      if x = fl.b.x then
        exit;
      if d >= 0 then
      begin
        y := y + sy;
        d := d - ax;
      end;
      x := x + sx;
      d := d + ay;
    end;
  end
  else
  begin
    d := ax - ay div 2;
    while True do
    begin
      PUTDOT(x, y, color);
      if y = fl.b.y then
        exit;
      if d >= 0 then
      begin
        x := x + sx;
        d := d - ay;
      end;
      y := y + sy;
      d := d + ax;
    end;
  end;
end;

// Clip lines, draw visible part sof lines.
var
  fl: fline_t;

procedure AM_drawMline(ml: Pmline_t; color: integer);
begin
  if AM_clipMline(ml, @fl) then
    AM_drawFline(@fl, color); // draws it on frame buffer using fb coords
end;


// Draws flat (floor/ceiling tile) aligned grid lines.
procedure AM_drawGrid(color: integer);
var
  x, y: fixed_t;
  start, finish: fixed_t;
  ml: mline_t;
begin
  // Figure out start of vertical gridlines
  start := m_x;
  if (start - bmaporgx) mod (MAPBLOCKUNITS * FRACUNIT) <> 0 then
    start := start + (MAPBLOCKUNITS * FRACUNIT) -
      ((start - bmaporgx) mod (MAPBLOCKUNITS * FRACUNIT));
  finish := m_x + m_w;

  // draw vertical gridlines
  ml.a.y := m_y;
  ml.b.y := m_y + m_h;
  x := start;
  while x < finish do
  begin
    ml.a.x := x;
    ml.b.x := x;
    AM_drawMline(@ml, color);
    x := x + (MAPBLOCKUNITS * FRACUNIT);
  end;

  // Figure out start of horizontal gridlines
  start := m_y;
  if (start - bmaporgy) mod (MAPBLOCKUNITS * FRACUNIT) <> 0 then
    start := start + (MAPBLOCKUNITS * FRACUNIT) -
      ((start - bmaporgy) mod (MAPBLOCKUNITS * FRACUNIT));
  finish := m_y + m_h;

  // draw horizontal gridlines
  ml.a.x := m_x;
  ml.b.x := m_x + m_w;
  y := start;
  while y < finish do
  begin
    ml.a.y := y;
    ml.b.y := y;
    AM_drawMline(@ml, color);
    y := y + (MAPBLOCKUNITS * FRACUNIT);
  end;
end;


// Determines visible lines, draws them.
// This is LineDef based, not LineSeg based.
procedure AM_drawWalls;
var
  i: integer;
  l: mline_t;
  line: Pline_t;
begin
  line := @lines[0];
  for i := 0 to numlines - 1 do
  begin
    l.a.x := line.v1.x;
    l.a.y := line.v1.y;
    l.b.x := line.v2.x;
    l.b.y := line.v2.y;
    if (cheating <> 0) or (line.flags and ML_MAPPED <> 0) then
    begin
      if (line.flags and LINE_NEVERSEE <> 0) and (cheating = 0) then
        continue;
      if line.backsector = nil then
      begin
        AM_drawMline(@l, WALLCOLORS);
      end
      else
      begin
        if line.special = 39 then
        begin // teleporters
          AM_drawMline(@l, WALLCOLORS + WALLRANGE div 2);
        end
        else if line.flags and ML_SECRET <> 0 then // secret door
        begin
          if cheating <> 0 then
            AM_drawMline(@l, SECRETWALLCOLORS)
          else
            AM_drawMline(@l, WALLCOLORS);
        end
        else if line.backsector.floorheight <> line.frontsector.floorheight then
        begin
          AM_drawMline(@l, FDWALLCOLORS); // floor level change
        end
        else if line.backsector.ceilingheight <> line.frontsector.ceilingheight then
        begin
          AM_drawMline(@l, CDWALLCOLORS); // ceiling level change
        end
        else if cheating <> 0 then
        begin
          AM_drawMline(@l, TSWALLCOLORS);
        end;
      end;
    end
    else if plr.powers[Ord(pw_allmap)] <> 0 then
    begin
      if lines[i].flags and LINE_NEVERSEE = 0 then
        AM_drawMline(@l, GRAYS + 3);
    end;
    inc(line);
  end;
end;



// Rotation in 2D.
// Used to rotate player arrow line character.

procedure AM_rotate(x: Pfixed_t; y: Pfixed_t; a: angle_t);
var
  tmpx: fixed_t;
begin
  tmpx := FixedMul(x^, finecosine[a shr ANGLETOFINESHIFT]) -
    FixedMul(y^, finesine[a shr ANGLETOFINESHIFT]);

  y^ := FixedMul(x^, finesine[a shr ANGLETOFINESHIFT]) +
    FixedMul(y^, finecosine[a shr ANGLETOFINESHIFT]);

  x^ := tmpx;
end;

procedure AM_drawLineCharacter(lineguy: Pmline_tArray; lineguylines: integer;
  scale: fixed_t; angle: angle_t; color: integer; x: fixed_t; y: fixed_t);
var
  i: integer;
  l: mline_t;
begin
  for i := 0 to lineguylines - 1 do
  begin
    l.a.x := lineguy[i].a.x;
    l.a.y := lineguy[i].a.y;

    if scale <> 0 then
    begin
      l.a.x := FixedMul(scale, l.a.x);
      l.a.y := FixedMul(scale, l.a.y);
    end;

    if angle <> 0 then
      AM_rotate(@l.a.x, @l.a.y, angle);

    l.a.x := l.a.x + x;
    l.a.y := l.a.y + y;

    l.b.x := lineguy[i].b.x;
    l.b.y := lineguy[i].b.y;

    if scale <> 0 then
    begin
      l.b.x := FixedMul(scale, l.b.x);
      l.b.y := FixedMul(scale, l.b.y);
    end;

    if angle <> 0 then
      AM_rotate(@l.b.x, @l.b.y, angle);

    l.b.x := l.b.x + x;
    l.b.y := l.b.y + y;

    AM_drawMline(@l, color);
  end;
end;

procedure AM_drawPlayers;
const
  their_colors: array[0..MAXPLAYERS - 1] of integer = (GREENS, GRAYS, BROWNS, REDS);
var
  i: integer;
  p: Pplayer_t;
  their_color, color: integer;
begin
  if not netgame then
  begin
    if cheating <> 0 then
      AM_drawLineCharacter
      (@cheat_player_arrow, NUMCHEATPLYRLINES, 0,
        plr.mo.angle, WHITE, plr.mo.x, plr.mo.y)
    else
      AM_drawLineCharacter
      (@player_arrow, NUMPLYRLINES, 0, plr.mo.angle,
        WHITE, plr.mo.x, plr.mo.y);
    exit;
  end;

  their_color := -1;
  for i := 0 to MAXPLAYERS - 1 do
  begin
    Inc(their_color);
    p := @players[i];

    if (deathmatch <> 0) and not singledemo and (p <> plr) then
      continue;

    if not playeringame[i] then
      continue;

    if p.powers[Ord(pw_invisibility)] <> 0 then
      color := 246 // *close* to black
    else
      color := their_colors[their_color];

    AM_drawLineCharacter
    (@player_arrow, NUMPLYRLINES, 0, p.mo.angle,
      color, p.mo.x, p.mo.y);
  end;
end;

procedure AM_drawThings(colors: integer; colorrange: integer);
var
  i: integer;
  t: Pmobj_t;
begin
  for i := 0 to numsectors - 1 do
  begin
    t := sectors[i].thinglist;
    while t <> nil do
    begin
      AM_drawLineCharacter
      (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
        16 * FRACUNIT, t.angle, colors, t.x, t.y);
      t := t.snext;
    end;
  end;
end;

procedure AM_drawMarks;
var
  i, fx, fy, w, h: integer;
begin
  for i := 0 to AM_NUMMARKPOINTS - 1 do
  begin
    if markpoints[i].x <> -1 then
    begin
      w := 5; // because something's wrong with the wad, i guess
      h := 6; // because something's wrong with the wad, i guess
      fx := CXMTOF(markpoints[i].x);
      fy := CYMTOF(markpoints[i].y);
      if (fx >= f_x) and (fx <= f_w - w) and (fy >= f_y) and (fy <= f_h - h) then
        V_DrawPatch(fx, fy, SCN_FG, marknums[i], False);
    end;
  end;
end;

procedure AM_drawCrosshair(color: integer);
begin
  fb[(f_w * (f_h + 1)) div 2] := color; // single point for now
end;

procedure AM_Drawer;
begin
  if not automapactive then
    exit;

  AM_clearFB(BACKGROUND);
  if grid then
    AM_drawGrid(GRIDCOLORS);
  AM_drawWalls;
  AM_drawPlayers;
  if cheating = 2 then
    AM_drawThings(THINGCOLORS, THINGRANGE);
  AM_drawCrosshair(XHAIRCOLORS);

  AM_drawMarks;
end;

procedure AM_Init;
var
  pl: Pmline_t;
begin
  pl := @player_arrow[0];
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

////////////////////////////////////////////////////////////////////////////////

  pl := @cheat_player_arrow[0];
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 10;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

////////////////////////////////////////////////////////////////////////////////

  pl := @triangle_guy[0];
  pl.a.x := Round(-0.867 * FRACUNIT);
  pl.a.y := Round(-0.5 * FRACUNIT);
  pl.b.x := Round(0.867 * FRACUNIT);
  pl.b.y := Round(-0.5 * FRACUNIT);

  inc(pl);
  pl.a.x := Round(0.867 * FRACUNIT);
  pl.a.y := Round(-0.5 * FRACUNIT);
  pl.b.x := 0;
  pl.b.y := FRACUNIT;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := FRACUNIT;
  pl.b.x := Round(-0.867 * FRACUNIT);
  pl.b.y := Round(-0.5 * FRACUNIT);

////////////////////////////////////////////////////////////////////////////////

  pl := @thintriangle_guy[0];
  pl.a.x := Round(-0.5 * FRACUNIT);
  pl.a.y := Round(-0.7 * FRACUNIT);
  pl.b.x := FRACUNIT;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := FRACUNIT;
  pl.a.y := 0;
  pl.b.x := Round(-0.5 * FRACUNIT);
  pl.b.y := Round(0.7 * FRACUNIT);

  inc(pl);
  pl.a.x := Round(-0.5 * FRACUNIT);
  pl.a.y := Round(0.7 * FRACUNIT);
  pl.b.x := Round(-0.5 * FRACUNIT);
  pl.b.y := Round(-0.7 * FRACUNIT);

  ////////////////////////////////////////////////////////////////////////////////
  cheat_amap.sequence := get_cheatseq_string(cheat_amap_seq);
  cheat_amap.p := '';

  ////////////////////////////////////////////////////////////////////////////////
  ZeroMemory(@st_notify_AM_initVariables, SizeOf(st_notify_AM_initVariables));
  st_notify_AM_initVariables._type := ev_keyup;
  st_notify_AM_initVariables.data1 := AM_MSGENTERED;

  ////////////////////////////////////////////////////////////////////////////////
  ZeroMemory(@st_notify_AM_Stop, SizeOf(st_notify_AM_Stop));
  st_notify_AM_Stop._type := ev_keyup;
  st_notify_AM_Stop.data1 := AM_MSGEXITED;
end;

end.
