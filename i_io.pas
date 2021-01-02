unit i_io;

interface

uses 
  d_delphi;

var
  debugfile: TFile;
  stderr: TFile;

procedure I_InitializeIO;

procedure I_ShutdownIO;

procedure I_IOMessageBox(const s: string);

procedure I_IOErrorMessageBox(const s: string);

procedure I_IOprintf(const s: string);

implementation

uses Windows,
  g_game,
  i_main,
  m_argv;

procedure I_IOMessageBox(const s: string);
begin
  MessageBox(hMainWnd, PChar(s), AppTitle, MB_OK);
end;

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
