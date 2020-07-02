unit HotRegister;

interface

uses SysUtils, Classes, Registry, Windows;

procedure Register;

implementation

uses HotLabel, XPAbout, NxSTray, NxSBrowseFolderDlg, 
  NxSFormResizeGrid, frmLicbox;

const
  SCfgKey = 'Software\Saivert\HotComponents';
  SLicenceShown = 'LicenceShown';

function ThisModuleFileName: string;
var
  Buf: array[0..MAX_PATH + 1] of Char;
begin
  GetModuleFileName(HInstance, Buf, SizeOf(Buf) - 1);
  Result := Buf;
end;

procedure Register;
var
  reg: TRegistry;
  licbox: TLicForm;
begin
  reg := TRegistry.Create;
  reg.OpenKey(SCfgKey, True);

  if not reg.ValueExists(SLicenceShown) then
  begin
    licbox := TLicForm.Create(nil);
    licbox.ShowModal;
    licbox.Destroy;
    reg.WriteBool(SLicenceShown, True);
  end;

  RegisterComponents('Hot Components', [
  THotLabel,
  TXPAbout,
  TNxSTray,
  TNxSBrowseFolderDlg,
  TNxSFormResizeGrid
  ]);

  reg.CloseKey;
  reg.Destroy;
end;

end.
