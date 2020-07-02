program alerttimer;

uses
  Forms,
  Windows,
  frmAlert in 'frmAlert.pas' {Form1};

{$R *.res}
{$R xpmanifest_app.res}

begin
  Application.Initialize;
  Application.Title := 'Alert Timer';
  Application.CreateForm(TForm1, Form1);
  if (ParamStr(1) = '/h') or (ParamStr(1) = '/H') then
    Application.ShowMainForm := False;
  Application.Run;
end.
