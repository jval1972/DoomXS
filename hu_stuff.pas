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

unit hu_stuff;

interface

uses
  doomdef,
  d_event,
  r_defs;

const
//
// Globally visible constants.
//
  HU_FONTSTART = '!'; // the first font characters
  HU_FONTEND = '_'; // the last font characters

// Calculate # of glyphs in font.
  HU_FONTSIZE = (Ord(HU_FONTEND) - Ord(HU_FONTSTART)) + 1;
  HU_BROADCAST = 5;

  HU_MSGREFRESH = KEY_ENTER;
  HU_MSGX = 0;
  HU_MSGY = 0;
  HU_MSGHEIGHT = 1; // in lines

  HU_MSGTIMEOUT = 4 * TICRATE;

//
// HEADS UP TEXT
//
procedure HU_Init;

procedure HU_Start;

function HU_Responder(ev: Pevent_t): boolean;

procedure HU_Ticker;

procedure HU_Drawer;

function HU_dequeueChatChar: char;

procedure HU_Erase;

var
  hu_font: array[0..HU_FONTSIZE - 1] of Ppatch_t;

  chat_on: boolean;

  message_on: boolean;
  message_dontfuckwithme: boolean;
  message_nottobefuckedwith: boolean;

var
// DOOM shareware/registered/retail (Ultimate) names.
  mapnames: array[0..35] of string;

// DOOM 2 map names.
  mapnames2: array[0..31] of string;

// Plutonia WAD map names.
  mapnamesp: array[0..31] of string;

// TNT WAD map names.
  mapnamest: array[0..31] of string;

  player_names: array[0..3] of string;

var
  chat_macros: array[0..9] of string;

implementation

uses
  d_delphi,
  z_memory,
  w_wad,
  doomstat,
  am_map,
  d_englsh,
  d_player,
  g_game,
  hu_lib,
  m_menu,
  s_sound,
  sounds,
  st_stuff;

function HU_TITLE: string;
begin
  Result := mapnames[(gameepisode - 1) * 9 + gamemap - 1];
end;

function HU_TITLE2: string;
begin
  Result := mapnames2[gamemap - 1];
end;

function HU_TITLEP: string;
begin
  Result := mapnamesp[gamemap - 1];
end;

function HU_TITLET: string;
begin
  Result := mapnamest[gamemap - 1];
end;

var
  plr: Pplayer_t;
  w_title: hu_textline_t;
  w_chat: hu_itext_t;
  always_off: boolean = False;
  chat_dest: array[0..MAXPLAYERS - 1] of char;
  w_inputbuffer: array[0..MAXPLAYERS - 1] of hu_itext_t;

  w_message: hu_stext_t;
  message_counter: integer;

  headsupactive: boolean = False;

const
  HU_TITLEHEIGHT = 1;
  HU_TITLEX = 0;

function HU_TITLEY: integer;
begin
  Result := (200 - ST_HEIGHT) * SCREENHEIGHT div 200 - 1 - hu_font[0].height;
end;

const
  HU_INPUTTOGGLE: char = 't';

function HU_INPUTX: integer;
begin
  Result := HU_MSGX;
end;

function HU_INPUTY: integer;
begin
  Result := HU_MSGY + HU_MSGHEIGHT * (hu_font[0].height + 1)
end;

const
  HU_INPUTWIDTH = 64;
  HU_INPUTHEIGHT = 1;

var
  shiftxform: array[0..127] of char;

const
  french_shiftxform: array[0..127] of char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '?', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    '0', // shift-0
    '1', // shift-1
    '2', // shift-2
    '3', // shift-3
    '4', // shift-4
    '5', // shift-5
    '6', // shift-6
    '7', // shift-7
    '8', // shift-8
    '9', // shift-9
    '/',
    '.', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  english_shiftxform: array[0..127] of char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '<', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    ')', // shift-0
    '!', // shift-1
    '@', // shift-2
    '#', // shift-3
    '$', // shift-4
    '%', // shift-5
    '^', // shift-6
    '&', // shift-7
    '*', // shift-8
    '(', // shift-9
    ':',
    ':', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  frenchKeyMap: array[0..127] of char = (
    #0,
    #1,#2,#3,#4,#5,#6,#7,#8,#9,#10,
    #11,#12,#13,#14,#15,#16,#17,#18,#19,#20,
    #21,#22,#23,#24,#25,#26,#27,#28,#29,#30,
    #31,
    ' ','!','"','#','$','%','&','%','(',')','*','+',';','-',':','!',
    '0','1','2','3','4','5','6','7','8','9',':','M','<','=','>','?',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^','_',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^',#127
  );

function ForeignTranslation(ch: char): char;
begin
  if ch < #128 then
    Result := frenchKeyMap[Ord(ch)]
  else
    Result := ch;
end;

procedure HU_Init;
var
  i: integer;
  j: integer;
  buffer: string;
begin
  if language = french then
  begin
    for i := 0 to 127 do
      shiftxform[i] := french_shiftxform[i];
  end
  else
  begin
    for i := 0 to 127 do
      shiftxform[i] := english_shiftxform[i];
  end;

  // load the heads-up font
  j := Ord(HU_FONTSTART);
  for i := 0 to HU_FONTSIZE - 1 do
  begin
    buffer := 'STCFN' + IntToStrZfill(3, j);
    inc(j);
    hu_font[i] := W_CacheLumpName(buffer, PU_STATIC);
  end;
end;

procedure HU_Stop;
begin
  headsupactive := False;
end;

procedure HU_Start;
var
  i: integer;
  s: string;
begin
  if headsupactive then
    HU_Stop;

  plr := @players[consoleplayer];
  message_on := False;
  message_dontfuckwithme := False;
  message_nottobefuckedwith := False;
  chat_on := False;

  // create the message widget
  HUlib_initSText(@w_message,
    HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
    @hu_font,
    Ord(HU_FONTSTART), @message_on);

  // create the map title widget
  HUlib_initTextLine(@w_title,
    HU_TITLEX, HU_TITLEY,
    @hu_font,
    Ord(HU_FONTSTART));

  if gamemode in [shareware, registered, retail] then
    s := HU_TITLE
  else
  begin
    case gamemission of
      pack_tnt: s := HU_TITLET;
      pack_plut: s := HU_TITLEP;
    else
      s := HU_TITLE2;
    end;
  end;

  for i := 1 to Length(s) do
    HUlib_addCharToTextLine(@w_title, s[i]);

  // create the chat widget
  HUlib_initIText(@w_chat,
    HU_INPUTX, HU_INPUTY,
    @hu_font,
    Ord(HU_FONTSTART), @chat_on);

  // create the inputbuffer widgets
  for i := 0 to MAXPLAYERS - 1 do
    HUlib_initIText(@w_inputbuffer[i], 0, 0, nil, 0, @always_off);

  headsupactive := True;
end;

procedure HU_Drawer;
begin
  HUlib_drawSText(@w_message);
  HUlib_drawIText(@w_chat);
  if automapactive then
    HUlib_drawTextLine(@w_title, False);
end;

procedure HU_Erase;
begin
  HUlib_eraseSText(@w_message);
  HUlib_eraseIText(@w_chat);
  HUlib_eraseTextLine(@w_title);
end;

procedure HU_Ticker;
var
  i, rc: integer;
  c: char;
begin
  // tick down message counter if message is up
  if message_counter <> 0 then
  begin
    dec(message_counter);
    if message_counter = 0 then
    begin
      message_on := False;
      message_nottobefuckedwith := False;
    end;
  end;

  if (showMessages <> 0) or message_dontfuckwithme then
  begin
    // display message if necessary
    if ((plr.msg <> '') and not message_nottobefuckedwith) or
       ((plr.msg <> '') and message_dontfuckwithme) then
    begin
      HUlib_addMessageToSText(@w_message, '', plr.msg);
      plr.msg := '';
      message_on := True;
      message_counter := HU_MSGTIMEOUT;
      message_nottobefuckedwith := message_dontfuckwithme;
      message_dontfuckwithme := False;
    end;
  end; // else message_on = False;

  // check for incoming chat characters
  if netgame then
  begin
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if not playeringame[i] then
        Continue;
      c := Chr(players[i].cmd.chatchar);
      if (i <> consoleplayer) and (c <> #0) then
      begin
        if c <= Chr(HU_BROADCAST) then
          chat_dest[i] := c
        else
        begin
          if (c >= 'a') and (c <= 'z') then
            c := shiftxform[ord(c)];
          rc := intval(HUlib_keyInIText(@w_inputbuffer[i], Ord(c)));
          if (rc <> 0) and (Ord(c) = KEY_ENTER) then
          begin
            if (w_inputbuffer[i].l.len <> 0) and
               ((Ord(chat_dest[i]) = consoleplayer + 1) or (Ord(chat_dest[i]) = HU_BROADCAST)) then
            begin
              HUlib_addMessageToSText(@w_message,
                player_names[i],
                w_inputbuffer[i].l.l);

              message_nottobefuckedwith := True;
              message_on := True;
              message_counter := HU_MSGTIMEOUT;
              if gamemode = commercial then
                S_StartSound(nil, Ord(sfx_radio))
              else
                S_StartSound(nil, Ord(sfx_tink));
            end;
            HUlib_resetIText(@w_inputbuffer[i]);
          end;
        end;
        players[i].cmd.chatchar := 0;
      end;
    end;
  end;
end;

const
  QUEUESIZE = 128;

var
  chatchars: array[0..QUEUESIZE - 1] of char;
  head: integer = 0;
  tail: integer = 0;

procedure HU_queueChatChar(c: char);
begin
  if ((head + 1) and (QUEUESIZE - 1)) = tail then
    plr.msg := HUSTR_MSGU
  else
  begin
    chatchars[head] := c;
    head := (head + 1) and (QUEUESIZE - 1);
  end;
end;

function HU_dequeueChatChar: char;
begin
  if head <> tail then
  begin
    Result := chatchars[tail];
    tail := (tail + 1) and (QUEUESIZE - 1);
  end
  else
    Result := #0;
end;

var
  lastmessage: string;
  shiftdown: boolean = False;
  altdown: boolean = False;
  destination_keys: array[0..MAXPLAYERS - 1] of char;
  num_nobrainers: integer = 0;

function HU_Responder(ev: Pevent_t): boolean;
var
  macromessage: string;
  c: char;
  i: integer;
  numplayers: integer;
begin
  Result := False;

  if ev.data1 = KEY_RSHIFT then
  begin
    shiftdown := ev.typ = ev_keydown;
    Exit;
  end
  else if ev.data1 = KEY_RALT then
  begin
    altdown := ev.typ = ev_keydown;
    Exit;
  end;

  if ev.typ <> ev_keydown then
    Exit;

  numplayers := 0;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      inc(numplayers);

  if not chat_on then
  begin
    if ev.data1 = HU_MSGREFRESH then
    begin
      message_on := True;
      message_counter := HU_MSGTIMEOUT;
      Result := True;
    end
    else if netgame and (ev.data1 = Ord(HU_INPUTTOGGLE)) then
    begin
      Result := True;
      chat_on := True;
      HUlib_resetIText(@w_chat);
      HU_queueChatChar(Chr(HU_BROADCAST));
    end
    else if netgame and (numplayers > 2) then
    begin
      for i := 0 to MAXPLAYERS - 1 do
      begin
        if ev.data1 = Ord(destination_keys[i]) then
        begin
          if playeringame[i] and (i <> consoleplayer) then
          begin
            Result := True;
            chat_on := True;
            HUlib_resetIText(@w_chat);
            HU_queueChatChar(Chr(i + 1));
            Break;
          end
          else if i = consoleplayer then
          begin
            inc(num_nobrainers);
            if num_nobrainers < 3 then
              plr.msg := HUSTR_TALKTOSELF1
            else if num_nobrainers < 6 then
              plr.msg := HUSTR_TALKTOSELF2
            else if num_nobrainers < 9 then
              plr.msg := HUSTR_TALKTOSELF3
            else if num_nobrainers < 32 then
              plr.msg := HUSTR_TALKTOSELF4
            else
              plr.msg := HUSTR_TALKTOSELF5;
          end
        end;
      end;
    end;
  end
  else
  begin
    c := Chr(ev.data1);
    // send a macro
    if altdown then
    begin
      c := Chr(Ord(c) - Ord('0'));
      if c > Chr(9) then
        Exit;
      macromessage := chat_macros[Ord(c)];

      // kill last message with a '\n'
      HU_queueChatChar(Chr(KEY_ENTER)); // DEBUG!!!

      // send the macro message
      for i := 1 to Length(macromessage) do
        HU_queueChatChar(macromessage[i]);
      HU_queueChatChar(Chr(KEY_ENTER));

      // leave chat mode and notify that it was sent
      chat_on := False;
      lastmessage := chat_macros[Ord(c)];
      plr.msg := lastmessage;
      Result := True;
    end
    else
    begin
      if language = french then
        c := ForeignTranslation(c);
      if shiftdown or ((c >= 'a') and (c <= 'z')) then
        c := shiftxform[Ord(c)];
      Result := HUlib_keyInIText(@w_chat, Ord(c));
      if Result then
        HU_queueChatChar(c);
      if Ord(c) = KEY_ENTER then
      begin
        chat_on := False;
        if w_chat.l.len <> 0 then
        begin
          lastmessage := w_chat.l.l;
          plr.msg := lastmessage;
        end
      end
      else if Ord(c) = KEY_ESCAPE then
        chat_on := False;
    end;
  end;
end;


initialization
  chat_macros[0] := HUSTR_CHATMACRO0;
  chat_macros[1] := HUSTR_CHATMACRO1;
  chat_macros[2] := HUSTR_CHATMACRO2;
  chat_macros[3] := HUSTR_CHATMACRO3;
  chat_macros[4] := HUSTR_CHATMACRO4;
  chat_macros[5] := HUSTR_CHATMACRO5;
  chat_macros[6] := HUSTR_CHATMACRO6;
  chat_macros[7] := HUSTR_CHATMACRO7;
  chat_macros[8] := HUSTR_CHATMACRO8;
  chat_macros[9] := HUSTR_CHATMACRO9;

  player_names[0] := HUSTR_PLRGREEN;
  player_names[1] := HUSTR_PLRINDIGO;
  player_names[2] := HUSTR_PLRBROWN;
  player_names[3] := HUSTR_PLRRED;

////////////////////////////////////////////////////////////////////////////////
//
// Builtin map names.
//
////////////////////////////////////////////////////////////////////////////////

// DOOM shareware/registered/retail (Ultimate) names.

  mapnames[0] := HUSTR_E1M1;
  mapnames[1] := HUSTR_E1M2;
  mapnames[2] := HUSTR_E1M3;
  mapnames[3] := HUSTR_E1M4;
  mapnames[4] := HUSTR_E1M5;
  mapnames[5] := HUSTR_E1M6;
  mapnames[6] := HUSTR_E1M7;
  mapnames[7] := HUSTR_E1M8;
  mapnames[8] := HUSTR_E1M9;

  mapnames[9] := HUSTR_E2M1;
  mapnames[10] := HUSTR_E2M2;
  mapnames[11] := HUSTR_E2M3;
  mapnames[12] := HUSTR_E2M4;
  mapnames[13] := HUSTR_E2M5;
  mapnames[14] := HUSTR_E2M6;
  mapnames[15] := HUSTR_E2M7;
  mapnames[16] := HUSTR_E2M8;
  mapnames[17] := HUSTR_E2M9;

  mapnames[18] := HUSTR_E3M1;
  mapnames[19] := HUSTR_E3M2;
  mapnames[20] := HUSTR_E3M3;
  mapnames[21] := HUSTR_E3M4;
  mapnames[22] := HUSTR_E3M5;
  mapnames[23] := HUSTR_E3M6;
  mapnames[24] := HUSTR_E3M7;
  mapnames[25] := HUSTR_E3M8;
  mapnames[26] := HUSTR_E3M9;

  mapnames[27] := HUSTR_E4M1;
  mapnames[28] := HUSTR_E4M2;
  mapnames[29] := HUSTR_E4M3;
  mapnames[30] := HUSTR_E4M4;
  mapnames[31] := HUSTR_E4M5;
  mapnames[32] := HUSTR_E4M6;
  mapnames[33] := HUSTR_E4M7;
  mapnames[34] := HUSTR_E4M8;
  mapnames[35] := HUSTR_E4M9;

////////////////////////////////////////////////////////////////////////////////

// DOOM 2 map names.

  mapnames2[0] := HUSTR_1;
  mapnames2[1] := HUSTR_2;
  mapnames2[2] := HUSTR_3;
  mapnames2[3] := HUSTR_4;
  mapnames2[4] := HUSTR_5;
  mapnames2[5] := HUSTR_6;
  mapnames2[6] := HUSTR_7;
  mapnames2[7] := HUSTR_8;
  mapnames2[8] := HUSTR_9;
  mapnames2[9] := HUSTR_10;
  mapnames2[10] := HUSTR_11;

  mapnames2[11] := HUSTR_12;
  mapnames2[12] := HUSTR_13;
  mapnames2[13] := HUSTR_14;
  mapnames2[14] := HUSTR_15;
  mapnames2[15] := HUSTR_16;
  mapnames2[16] := HUSTR_17;
  mapnames2[17] := HUSTR_18;
  mapnames2[18] := HUSTR_19;
  mapnames2[19] := HUSTR_20;

  mapnames2[20] := HUSTR_21;
  mapnames2[21] := HUSTR_22;
  mapnames2[22] := HUSTR_23;
  mapnames2[23] := HUSTR_24;
  mapnames2[24] := HUSTR_25;
  mapnames2[25] := HUSTR_26;
  mapnames2[26] := HUSTR_27;
  mapnames2[27] := HUSTR_28;
  mapnames2[28] := HUSTR_29;
  mapnames2[29] := HUSTR_30;
  mapnames2[30] := HUSTR_31;
  mapnames2[31] := HUSTR_32;

////////////////////////////////////////////////////////////////////////////////

// Plutonia WAD map names.

  mapnamesp[0] := PHUSTR_1;
  mapnamesp[1] := PHUSTR_2;
  mapnamesp[2] := PHUSTR_3;
  mapnamesp[3] := PHUSTR_4;
  mapnamesp[4] := PHUSTR_5;
  mapnamesp[5] := PHUSTR_6;
  mapnamesp[6] := PHUSTR_7;
  mapnamesp[7] := PHUSTR_8;
  mapnamesp[8] := PHUSTR_9;
  mapnamesp[9] := PHUSTR_10;
  mapnamesp[10] := PHUSTR_11;

  mapnamesp[11] := PHUSTR_12;
  mapnamesp[12] := PHUSTR_13;
  mapnamesp[13] := PHUSTR_14;
  mapnamesp[14] := PHUSTR_15;
  mapnamesp[15] := PHUSTR_16;
  mapnamesp[16] := PHUSTR_17;
  mapnamesp[17] := PHUSTR_18;
  mapnamesp[18] := PHUSTR_19;
  mapnamesp[19] := PHUSTR_20;

  mapnamesp[20] := PHUSTR_21;
  mapnamesp[21] := PHUSTR_22;
  mapnamesp[22] := PHUSTR_23;
  mapnamesp[23] := PHUSTR_24;
  mapnamesp[24] := PHUSTR_25;
  mapnamesp[25] := PHUSTR_26;
  mapnamesp[26] := PHUSTR_27;
  mapnamesp[27] := PHUSTR_28;
  mapnamesp[28] := PHUSTR_29;
  mapnamesp[29] := PHUSTR_30;
  mapnamesp[30] := PHUSTR_31;
  mapnamesp[31] := PHUSTR_32;

////////////////////////////////////////////////////////////////////////////////

// TNT WAD map names.

  mapnamest[0] := THUSTR_1;
  mapnamest[1] := THUSTR_2;
  mapnamest[2] := THUSTR_3;
  mapnamest[3] := THUSTR_4;
  mapnamest[4] := THUSTR_5;
  mapnamest[5] := THUSTR_6;
  mapnamest[6] := THUSTR_7;
  mapnamest[7] := THUSTR_8;
  mapnamest[8] := THUSTR_9;
  mapnamest[9] := THUSTR_10;
  mapnamest[10] := THUSTR_11;

  mapnamest[11] := THUSTR_12;
  mapnamest[12] := THUSTR_13;
  mapnamest[13] := THUSTR_14;
  mapnamest[14] := THUSTR_15;
  mapnamest[15] := THUSTR_16;
  mapnamest[16] := THUSTR_17;
  mapnamest[17] := THUSTR_18;
  mapnamest[18] := THUSTR_19;
  mapnamest[19] := THUSTR_20;

  mapnamest[20] := THUSTR_21;
  mapnamest[21] := THUSTR_22;
  mapnamest[22] := THUSTR_23;
  mapnamest[23] := THUSTR_24;
  mapnamest[24] := THUSTR_25;
  mapnamest[25] := THUSTR_26;
  mapnamest[26] := THUSTR_27;
  mapnamest[27] := THUSTR_28;
  mapnamest[28] := THUSTR_29;
  mapnamest[29] := THUSTR_30;
  mapnamest[30] := THUSTR_31;
  mapnamest[31] := THUSTR_32;

////////////////////////////////////////////////////////////////////////////////

  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;

end.


