program multimonwallpaper;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}
{$R xpmanifest_app.res}

begin
  Application.Initialize;
  Application.Title := 'MultiMonWallpaperMaker';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
