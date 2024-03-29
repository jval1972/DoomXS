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

unit hu_lib;

interface

uses
  doomdef,
  r_defs,
  d_delphi;

const
// background and foreground screen numbers
// different from other modules.
  BG = 1;
  FG = 0;

// font stuff
  HU_CHARERASE = KEY_BACKSPACE;

  HU_MAXLINES = 4;
  HU_MAXLINELENGTH = 80;

//
// Typedefs of widgets
//

// Text Line widget
//  (parent of Scrolling Text and Input Text widgets)
type
  hu_textline_t = record
    // left-justified position of scrolling text window
    x: integer;
    y: integer;
    f: Ppatch_tPArray; // font
    sc: integer; // start character
    l: array[0..(HU_MAXLINELENGTH + 1) - 1] of char; // line of text
    len: integer; // current line length
    needsupdate: integer; // whether this line needs to be udpated
  end;
  Phu_textline_t = ^hu_textline_t;

// Scrolling Text window widget
//  (child of Text Line widget)
  hu_stext_t = record
    l: array[0..HU_MAXLINES - 1] of hu_textline_t; // text lines to draw
    h: integer;       // height in lines
    cl: integer;      // current line number
    _on: Pboolean;    // pointer to boolean stating whether to update window
    laston: boolean;  // last value of *._on.
  end;
  Phu_stext_t = ^hu_stext_t;

// Input Text Line widget
//  (child of Text Line widget)
  hu_itext_t = record
    l: hu_textline_t; // text line to input on
    lm: integer;      // left margin past which I am not to delete characters
    _on: Pboolean;    // pointer to boolean stating whether to update window
    laston: boolean;  // last value of *->on;
  end;
  Phu_itext_t = ^hu_itext_t;

//
// Widget creation, access, and update routines
//

//
// textline code
//

// clear a line of text
procedure HUlib_clearTextLine(t: Phu_textline_t);

procedure HUlib_initTextLine(t: Phu_textline_t; x: integer; y: integer; f: Ppatch_tPArray; sc: integer);

// returns success
function HUlib_addCharToTextLine(t: Phu_textline_t; ch: char): boolean;

// returns success
function HUlib_delCharFromTextLine(t: Phu_textline_t): boolean;

// draws tline
procedure HUlib_drawTextLine(l: Phu_textline_t; drawcursor: boolean);

// erases text line
procedure HUlib_eraseTextLine(l: Phu_textline_t);

//
// Scrolling Text window widget routines
//

// ?
procedure HUlib_initSText(s: Phu_stext_t; x: integer; y: integer; h: integer;
  font: Ppatch_tPArray; startchar: integer; _on: Pboolean);

// add a new line
procedure HUlib_addLineToSText(s: Phu_stext_t);

// ?
procedure HUlib_addMessageToSText(s: Phu_stext_t; prefix: string; msg: string);

// draws stext
procedure HUlib_drawSText(s: Phu_stext_t);

// erases all stext lines
procedure HUlib_eraseSText(s: Phu_stext_t);

// Input Text Line widget routines
procedure HUlib_initIText(it: Phu_itext_t; x: integer; y: integer; font: Ppatch_tPArray;
  startchar: integer; _on: Pboolean);

// enforces left margin
procedure HUlib_delCharFromIText(it: Phu_itext_t);

// resets line and left margin
procedure HUlib_resetIText(it: Phu_itext_t);

// whether eaten
function HUlib_keyInIText(it: Phu_itext_t; ch: byte): boolean;

procedure HUlib_drawIText(it: Phu_itext_t);

// erases all itext lines
procedure HUlib_eraseIText(it: Phu_itext_t);

implementation

uses
  v_video,
  r_draw,
  am_map;

procedure HUlib_clearTextLine(t: Phu_textline_t);
begin
  t.len := 0;
  t.l[0] := Chr(0);
  t.needsupdate := 1; //True;
end;

procedure HUlib_initTextLine(t: Phu_textline_t; x: integer; y: integer; f: Ppatch_tPArray; sc: integer);
begin
  t.x := x;
  t.y := y;
  t.f := f;
  t.sc := sc;
  HUlib_clearTextLine(t);
end;

function HUlib_addCharToTextLine(t: Phu_textline_t; ch: char): boolean;
begin
  if t.len = HU_MAXLINELENGTH then
    Result := False
  else
  begin
    t.l[t.len] := ch;
    inc(t.len);
    t.l[t.len] := Chr(0);
    t.needsupdate := 4;
    Result := True;
  end;
end;

function HUlib_delCharFromTextLine(t: Phu_textline_t): boolean;
begin
  if t.len = 0 then
    Result := False
  else
  begin
    dec(t.len);
    t.l[t.len] := Chr(0);
    t.needsupdate := 4;
    Result := True;
  end;
end;

procedure HUlib_drawTextLine(l: Phu_textline_t; drawcursor: boolean);
var
  i: integer;
  w: integer;
  x: integer;
  c: char;
begin
  // draw the new stuff
  x := l.x;
  for i := 0 to l.len - 1 do
  begin
    c := toupper(l.l[i]);
    if (c <> ' ') and (Ord(c) >= l.sc) and (c <= '_') then
    begin
      w := l.f[Ord(c) - l.sc].width;
      if x + w > SCREENWIDTH then
        Break;
      V_DrawPatch(x, l.y, FG, l.f[Ord(c) - l.sc], False);
      x := x + w;
    end
    else
    begin
      x := x + 4;
      if x >= SCREENWIDTH then
        Break;
    end;
  end;

  // draw the cursor if requested
  if drawcursor and (x + l.f[Ord('_') - l.sc].width <= SCREENWIDTH) then
    V_DrawPatch(x, l.y, FG, l.f[Ord('_') - l.sc], False);
end;

// sorta called by HU_Erase and just better darn get things straight
procedure HUlib_eraseTextLine(l: Phu_textline_t);
var
  lh: integer;
  y: integer;
  yoffset: integer;
begin
  // Only erases when NOT in automap and the screen is reduced,
  // and the text must either need updating or refreshing
  // (because of a recent change back from the automap)
  if not automapactive and (viewwindowx <> 0) and (l.needsupdate <> 0) then
  begin
    lh := l.f[0].height + 1;
    y := l.y;
    yoffset := y * SCREENWIDTH;
    while y < l.y + lh do
    begin
      if (y < viewwindowy) or (y >= viewwindowy + viewheight) then
        R_VideoErase(yoffset, SCREENWIDTH) // erase entire line
      else
      begin
        // erase left border
        R_VideoErase(yoffset, viewwindowx);
        // erase right border
        R_VideoErase(yoffset + viewwindowx + viewwidth, viewwindowx);
      end;
      inc(y);
      yoffset := yoffset + SCREENWIDTH;
    end;
  end;

  if l.needsupdate > 0 then
    l.needsupdate := l.needsupdate - 1;
end;

procedure HUlib_initSText(s: Phu_stext_t; x: integer; y: integer; h: integer;
  font: Ppatch_tPArray; startchar: integer; _on: Pboolean);
var
  i: integer;
begin
  s.h := h;
  s._on := _on;
  s.laston := True;
  s.cl := 0;
  for i := 0 to h - 1 do
    HUlib_initTextLine(@s.l[i], x, y - i * (font[0].height + 1),
      font, startchar);
end;

procedure HUlib_addLineToSText(s: Phu_stext_t);
var
  i: integer;
begin
  // add a clear line
  inc(s.cl);
  if s.cl = s.h then
    s.cl := 0;
  HUlib_clearTextLine(@s.l[s.cl]);

  // everything needs updating
  for i := 0 to s.h - 1 do
    s.l[i].needsupdate := 4;
end;

procedure HUlib_addMessageToSText(s: Phu_stext_t; prefix: string; msg: string);
var
  i: integer;
begin
  HUlib_addLineToSText(s);

  for i := 1 to Length(prefix) do
    HUlib_addCharToTextLine(@s.l[s.cl], prefix[i]);

  for i := 1 to Length(msg) do
    HUlib_addCharToTextLine(@s.l[s.cl], msg[i]);
end;

procedure HUlib_drawSText(s: Phu_stext_t);
var
  i, idx: integer;
  l: Phu_textline_t;
begin
  if not s._on^ then
    Exit; // if not on, don't draw

  // draw everything
  for i := 0 to s.h - 1 do
  begin
    idx := s.cl - i;
    if idx < 0 then
      idx := idx + s.h; // handle queue of lines

    l := @s.l[idx];

    // need a decision made here on whether to skip the draw
    HUlib_drawTextLine(l, False); // no cursor, please
  end;
end;

procedure HUlib_eraseSText(s: Phu_stext_t);
var
  i: integer;
begin
  for i := 0 to s.h - 1 do
  begin
    if s.laston and not s._on^ then
      s.l[i].needsupdate := 4;
    HUlib_eraseTextLine(@s.l[i]);
  end;
  s.laston := s._on^;
end;

procedure HUlib_initIText(it: Phu_itext_t; x: integer; y: integer; font: Ppatch_tPArray;
  startchar: integer; _on: Pboolean);
begin
  it.lm := 0; // default left margin is start of text
  it._on := _on;
  it.laston := True;
  HUlib_initTextLine(@it.l, x, y, font, startchar);
end;

// The following deletion routines adhere to the left margin restriction
procedure HUlib_delCharFromIText(it: Phu_itext_t);
begin
  if it.l.len <> it.lm then
    HUlib_delCharFromTextLine(@it.l);
end;

// Resets left margin as well
procedure HUlib_resetIText(it: Phu_itext_t);
begin
  it.lm := 0;
  HUlib_clearTextLine(@it.l);
end;

// wrapper function for handling general keyed input.
// returns True if it ate the key
function HUlib_keyInIText(it: Phu_itext_t; ch: byte): boolean;
begin
  if (ch >= Ord(' ')) and (ch <= Ord('_')) then
    HUlib_addCharToTextLine(@it.l, Chr(ch))
  else
  if ch = KEY_BACKSPACE then
    HUlib_delCharFromIText(it)
  else if ch <> KEY_ENTER then
  begin
    Result := False; // did not eat key
    Exit;
  end;

  Result := True; // ate the key
end;

procedure HUlib_drawIText(it: Phu_itext_t);
begin
  if it._on^ then
    HUlib_drawTextLine(@it.l, True); // draw the line w/ cursor
end;

procedure HUlib_eraseIText(it: Phu_itext_t);
begin
  if it.laston and not it._on^ then
    it.l.needsupdate := 4;
  HUlib_eraseTextLine(@it.l);
  it.laston := it._on^;
end;

end.

