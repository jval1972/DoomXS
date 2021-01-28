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

unit i_io;

interface

uses
  d_delphi;

var
  debugfile: TFile;
  stderr: TFile;

procedure I_InitializeIO;

procedure I_ShutdownIO;

procedure I_IOErrorMessageBox(const s: string);

procedure I_IOprintf(const s: string);

implementation

uses
  Windows,
  g_game,
  i_main,
  m_argv;

procedure I_IOErrorMessageBox(const s: string);
begin
  MessageBox(hMainWnd, PChar(s), AppTitle, MB_OK or MB_ICONERROR);
end;

procedure I_IOprintf(const s: string);
begin
end;

procedure I_InitializeIO;
var
  filename: string;
begin
  if M_CheckParm('-debugfile') <> 0 then
    sprintf(filename, 'debug%d.txt', [consoleplayer])
  else
    filename := 'debug.txt';

  if M_CheckParmCDROM then
  begin
    stderr := TFile.Create('c:\dooomdata\stderr.txt', fCreate);
    filename := 'c:\dooomdata\' + filename;
  end
  else
    stderr := TFile.Create('stderr.txt', fCreate);

  printf('debug output to: %s' + #13#10, [filename]);
  debugfile := TFile.Create(filename, fCreate);
end;


procedure I_ShutdownIO;
begin
  stderr.Free;
  debugfile.Free;
end;

end.
