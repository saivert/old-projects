program APopupMenu;

uses
  Forms,
  Controls,
  SysUtils,
  Windows, Messages,
  frmPMAbout in 'frmPMAbout.pas' {AboutForm};

{$R *.res}
{$R xpmanifest_app.res}

begin
  Application.Initialize;
  Application.Title := 'PopupMenu';
  Application.CreateForm(TAboutForm, AboutForm);
  Application.ShowMainForm := False;  { This is essential... }
  if ParamCount <= 0 then
  begin
    Application.ShowMainForm := True;
  end else begin
  end;
  Application.Run;
end.
