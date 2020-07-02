program ACMFiddler;

uses
  Forms,
  frmMain in 'frmMain.pas' {Form1};

{$R *.res}
{$R xpmanifest_app.res}

begin
  Application.Initialize;
  Application.Title := 'ACM Fiddler';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
