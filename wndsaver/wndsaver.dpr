program wndsaver;

uses
  Forms, SysUtils,
  Windows, Messages,
  frmWndSS in 'frmWndSS.pas' {WndSSForm};

{$R *.res}

var
  hm: THandle;
  cds: TCOPYDATASTRUCT;
begin
  hm := CreateMutex(nil, True, 'wndsaver_mutex');
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    FillChar(cds, sizeof(TCOPYDATASTRUCT), 0);
    cds.dwData := OTHERINSTANCE;
    cds.cbData := StrLen(GetCommandLine);
    cds.lpData := GetCommandLine;
    SendMessage(FindWindow('TWndSSForm', 'Windowed Screensaver'), WM_COPYDATA, Application.Handle, Integer(@cds));
    Halt;
  end;

  Application.Initialize;
  Application.Title := 'Windowed Screensaver';
  Application.CreateForm(TWndSSForm, WndSSForm);
  Application.Run;

  ReleaseMutex(hm);
end.
