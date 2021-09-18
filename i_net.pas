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

unit i_net;

interface

procedure I_InitNetwork;

procedure I_NetCmd;

implementation

uses
  WinSock,
  d_delphi,
  d_net,
  i_system,
  g_game,
  m_argv;

var
  netget: PProcedure;
  netsend: PProcedure;

const
  IPPORT_USERRESERVED = 5000;

var
  DOOMPORT: integer = (IPPORT_USERRESERVED + $1d);
  sendsocket: TSocket;
  insocket: TSocket;
  sendaddress: array[0..MAXNETNODES - 1] of TSockAddrIn;

// UDPsocket
function UDPsocket: TSocket;
begin
  // allocate a socket
  Result := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if Result = INVALID_SOCKET then
    I_Error('UDPsocket(): Can''t create socket: Result = %d'#13#10 , [Result]);
end;

// BindToLocalPort
procedure BindToLocalPort(s: integer; port: integer);
var
  v: integer;
  address: TSockAddrIn;
begin
  ZeroMemory(@address, SizeOf(address));
  address.sin_family := AF_INET;
  address.sin_addr.s_addr := INADDR_ANY;
  address.sin_port := port;

  v := bind(s, address, SizeOf(address));
  if v = -1 then
    I_Error('BindToLocalPort(): Failed.');
end;

// PacketSend
procedure PacketSend;
var
  c: integer;
begin
  c := sendto(sendsocket, netbuffer^, doomcom.datalength, 0,
        sendaddress[doomcom.remotenode], SizeOf(sendaddress[doomcom.remotenode]));

  if c = SOCKET_ERROR then
    I_Error('PacketSend(): sendto() failed.');
end;

// PacketGet
procedure PacketGet;
var
  i: integer;
  c: integer;
  fromaddress: TSockAddrIn;
  fromlen: integer;
begin
  fromlen := SizeOf(fromaddress);
  c := recvfrom(insocket, netbuffer^, SizeOf(doomdata_t), 0, fromaddress, fromlen);
  if c = SOCKET_ERROR then
  begin
    c := WSAGetLastError;
    if c <> WSAEWOULDBLOCK then
      I_Error('PacketGet(): Network error.');
    doomcom.remotenode := -1;        // no packet
    Exit;
  end;

  // find remote node number
  i := 0;
  while i < doomcom.numnodes do
  begin
    if fromaddress.sin_addr.s_addr = sendaddress[i].sin_addr.s_addr then
      break;
    inc(i);
  end;

  if i = doomcom.numnodes then
  begin
    // packet is not from one of the players (new game broadcast)
    doomcom.remotenode := -1;        // no packet
    Exit;
  end;

  doomcom.remotenode := i;  // good packet from a game player
  doomcom.datalength := c;
end;

// I_InitNetwork
procedure I_InitNetwork;
var
  trueval: integer;
  i, err: integer;
  p: integer;
  hostentry: PHostEnt;    // host information entry
  wsadata: TWSAData;
begin
  trueval := 1;
  ZeroMemory(@doomcom, SizeOf(doomcom_t));

  // set up for network
  i := M_CheckParm('-dup');
  if (i > 0) and (i < myargc - 1) then
  begin
    doomcom.ticdup := Ord(myargv[i + 1][1]) - Ord('0');
    if doomcom.ticdup < 1 then
      doomcom.ticdup := 1
    else if doomcom.ticdup > 9 then
      doomcom.ticdup := 9;
  end
  else
    doomcom.ticdup := 1;

  if M_CheckParm('-extratic') > 0 then
    doomcom.extratics := 1
  else
    doomcom.extratics := 0;

  p := M_CheckParm('-port');
  if (p > 0) and (p < myargc - 1) then
  begin
    DOOMPORT := atoi(myargv[p + 1]);
    printf('Using Port %d'#13#10, [DOOMPORT]);
  end;

  // parse network game options,
  //  -net <consoleplayer> <host> <host> ...
  i := M_CheckParm('-net');
  if i = 0 then
  begin
    // single player game
    netgame := False;
    doomcom.id := DOOMCOM_ID;
    doomcom.numplayers := 1;
    doomcom.numnodes := 1;
    doomcom.deathmatch := 0;
    doomcom.consoleplayer := 0;
    Exit;
  end;

  err := WSAStartup($0101, wsadata);
  if err <> 0 then
    I_Error('I_InitNetwork(): Could not initialize Windows Sockets, WSAStartup Result = %d', [err]);

  netsend := PacketSend;
  netget := PacketGet;
  netgame := True;

  // parse player number and host list
  doomcom.consoleplayer := Ord(myargv[i + 1][1]) - Ord('1');
  printf('console player number: %d'#13#10, [doomcom.consoleplayer]);

  doomcom.numnodes := 1;    // this node for sure

  inc(i);
  inc(i);
  while (i < myargc) and (myargv[i][1] <> '-') do
  begin
    sendaddress[doomcom.numnodes].sin_family := AF_INET;
    if myargv[i][1] = '.' then
    begin
      printf('Node number %d address %s'#13#10, [doomcom.numnodes, Copy(myargv[i], 2, Length(myargv[i]) - 1)]);
      sendaddress[doomcom.numnodes].sin_addr.s_addr := inet_addr(PChar(Copy(myargv[i], 2, Length(myargv[i]) - 1)));
    end
    else
    begin
      printf('Node number %d hostname %s'#13#10, [doomcom.numnodes, myargv[i]]);
      hostentry := gethostbyname(PChar(myargv[i]));
      if hostentry = nil then
        I_Error('gethostbyname(): couldn''t find %s', [myargv[i]]);
      sendaddress[doomcom.numnodes].sin_addr.s_addr := PInteger(hostentry.h_addr_list^)^;
    end;
    inc(i);
    if (i < myargc) and (myargv[i][1] = ':') then
    begin
      printf('Node number %d port %s'#13#10, [doomcom.numnodes, Copy(myargv[i], 2, Length(myargv[i]) - 1)]);
      sendaddress[doomcom.numnodes].sin_port := htons(atoi(Copy(myargv[i], 2, Length(myargv[i]) - 1)));
      inc(i);
    end
    else
      sendaddress[doomcom.numnodes].sin_port := htons(DOOMPORT);
    inc(doomcom.numnodes);
  end;

  printf('Total number of players : %d'#13#10, [doomcom.numnodes]);
  doomcom.id := DOOMCOM_ID;
  doomcom.numplayers := doomcom.numnodes;

// build message to receive
  insocket := UDPsocket;
  BindToLocalPort(insocket,htons(DOOMPORT));
  ioctlsocket(insocket, FIONBIO, trueval);

  sendsocket := UDPsocket;
end;

procedure I_NetCmd;
begin
  if doomcom.command = CMD_SEND then
    netsend
  else if doomcom.command = CMD_GET then
    netget
  else
    I_Error('I_NetCmd(): Bad net cmd: %d', [doomcom.command]);
end;

end.
