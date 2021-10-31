unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    SoundGroupBox: TGroupBox;
    InputGroupBox: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    KeyboardRadioGroup: TRadioGroup;
    DetailCheckBox: TCheckBox;
    SmoothDisplayCheckBox: TCheckBox;
    AutorunModeCheckBox: TCheckBox;
    ScreenblocksTrackBar: TTrackBar;
    SFXTrackBar: TTrackBar;
    MusicTrackBar: TTrackBar;
    ChannelsTrackBar: TTrackBar;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ScreenblocksTrackBarChange(Sender: TObject);
    procedure DetailCheckBoxClick(Sender: TObject);
    procedure SmoothDisplayCheckBoxClick(Sender: TObject);
    procedure SFXTrackBarChange(Sender: TObject);
    procedure MusicTrackBarChange(Sender: TObject);
    procedure ChannelsTrackBarChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure AutorunModeCheckBoxClick(Sender: TObject);
  private
    { Private declarations }
    defaults: TStringList;
    in_startup: boolean;
    procedure SetDefault(const defname: string; const defvalue: integer);
    function GetDefault(const defname: string): integer;
    procedure ToControls;
    procedure FromControls;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  DoubleBuffered := True;
  for i := 0 to ComponentCount - 1 do
    if Components[i].InheritsFrom(TWinControl) then
      (Components[i] as TWinControl).DoubleBuffered := True;
  defaults := TStringList.Create;
  if FileExists('default.cfg') then
    defaults.LoadFromFile('default.cfg')
  else
    defaults.Text :=
      'mouse_sensitivity=5'#13#10 +
      'sfx_volume=15'#13#10 +
      'music_volume=15'#13#10 +
      'show_messages=1'#13#10 +
      'key_right=174'#13#10 +
      'key_left=172'#13#10 +
      'key_up=173'#13#10 +
      'key_down=175'#13#10 +
      'key_strafeleft=44'#13#10 +
      'key_straferight=46'#13#10 +
      'key_fire=157'#13#10 +
      'key_use=32'#13#10 +
      'key_strafe=184'#13#10 +
      'key_speed=182'#13#10 +
      'autorun_mode=0'#13#10 +
      'use_mouse=1'#13#10 +
      'mouseb_fire=0'#13#10 +
      'mouseb_strafe=1'#13#10 +
      'mouseb_forward=2'#13#10 +
      'use_joystick=0'#13#10 +
      'joyb_fire=0'#13#10 +
      'joyb_strafe=1'#13#10 +
      'joyb_use=3'#13#10 +
      'joyb_speed=2'#13#10 +
      'screenblocks=10'#13#10 +
      'detaillevel=0'#13#10 +
      'smoothdisplay=1'#13#10 +
      'snd_channels=8'#13#10 +
      'usegamma=0'#13#10 +
      'chatmacro0=No'#13#10 +
      'chatmacro1=I''m ready to kick butt!'#13#10 +
      'chatmacro2=I''m OK.'#13#10 +
      'chatmacro3=I''m not looking too good!'#13#10 +
      'chatmacro4=Help!'#13#10 +
      'chatmacro5=You suck!'#13#10 +
      'chatmacro6=Next time, scumbag...'#13#10 +
      'chatmacro7=Come here!'#13#10 +
      'chatmacro8=I''ll take care of it.'#13#10 +
      'chatmacro9=Yes';

  in_startup := True;
  ToControls;
  in_startup := False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  defaults.Free;
end;

procedure TForm1.SetDefault(const defname: string; const defvalue: integer);
begin
  if defaults.IndexOfName(defname) < 0 then
    defaults.Add(defname + '=' + IntToStr(defvalue))
  else
    defaults.Values[defname] := IntToStr(defvalue);
end;

function TForm1.GetDefault(const defname: string): integer;
begin
  Result := StrToIntDef(defaults.Values[defname], 0);
end;

procedure TForm1.ToControls;
begin
  if (GetDefault('key_up') = 173) and
     (GetDefault('key_down') = 175) and
     (GetDefault('key_strafeleft') = 44) and
     (GetDefault('key_straferight') = 46) then
    KeyboardRadioGroup.ItemIndex := 0
  else if (GetDefault('key_up') = 119) and
     (GetDefault('key_down') = 115) and
     (GetDefault('key_strafeleft') = 97) and
     (GetDefault('key_straferight') = 100) then
    KeyboardRadioGroup.ItemIndex := 1
  else
    KeyboardRadioGroup.ItemIndex := 2;
  DetailCheckBox.Checked := GetDefault('detaillevel') = 1;
  SmoothDisplayCheckBox.Checked := GetDefault('smoothdisplay') = 1;
  ScreenblocksTrackBar.Position := GetDefault('screenblocks');
  SFXTrackBar.Position := GetDefault('sfx_volume');
  MusicTrackBar.Position := GetDefault('music_volume');
  ChannelsTrackBar.Position := GetDefault('snd_channels');
  AutorunModeCheckBox.Checked := GetDefault('autorun_mode') = 1;
end;

procedure TForm1.FromControls;
begin
  if in_startup then
    Exit;
  if KeyboardRadioGroup.ItemIndex = 0 then
  begin
    SetDefault('key_up', 173);
    SetDefault('key_down', 175);
    SetDefault('key_strafeleft', 44);
    SetDefault('key_straferight', 46);
  end
  else if KeyboardRadioGroup.ItemIndex = 1 then
  begin
    SetDefault('key_up', 119);
    SetDefault('key_down', 115);
    SetDefault('key_strafeleft', 97);
    SetDefault('key_straferight', 100);
  end;

  if DetailCheckBox.Checked then
    SetDefault('detaillevel', 1)
  else
    SetDefault('detaillevel', 0);

  if SmoothDisplayCheckBox.Checked then
    SetDefault('smoothdisplay', 1)
  else
    SetDefault('smoothdisplay', 0);

  SetDefault('screenblocks', ScreenblocksTrackBar.Position);
  SetDefault('sfx_volume', SFXTrackBar.Position);
  SetDefault('music_volume', MusicTrackBar.Position);
  SetDefault('snd_channels', ChannelsTrackBar.Position);

  if AutorunModeCheckBox.Checked then
    SetDefault('autorun_mode', 1)
  else
    SetDefault('autorun_mode', 0);
end;

procedure TForm1.ScreenblocksTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.DetailCheckBoxClick(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.SmoothDisplayCheckBoxClick(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.SFXTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.MusicTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.ChannelsTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  weret: integer;
  errmsg: string;
begin
  FromControls;
  defaults.SaveToFile('default.cfg');
  weret := WinExec(PChar('DoomXS.exe'), SW_SHOWNORMAL);
  if weret > 31 then
    Close
  else
  begin
    if weret = 0 then
      errmsg := 'The system is out of memory or resources.'
    else if weret = ERROR_BAD_FORMAT then
      errmsg := 'The "DoomXS.exe" file is invalid (non-Win32 .EXE or error in .EXE image).'
    else if weret = ERROR_FILE_NOT_FOUND then
      errmsg := 'The "DoomXS.exe" file was not found.'
    else if weret = ERROR_PATH_NOT_FOUND then
      errmsg := 'Path not found.'
    else
      errmsg := 'Can not run  "DoomXS.exe".';

    ShowMessage(errmsg);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  FromControls;
  defaults.SaveToFile('default.cfg');
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.AutorunModeCheckBoxClick(Sender: TObject);
begin
  FromControls;
end;

end.
