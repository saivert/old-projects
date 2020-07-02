unit dllgetversion;
(* DllGetVersion implementation in pascal *)
interface
uses Windows;

type
  PDllVersionInfoRec = ^TDllVersionInfoRec;
  TDllVersionInfoRec = record
    cbSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformID: DWORD;
  end;

function GetDllVersion(dllfile: string; var pdvi: TDllVersionInfoRec): Boolean;

implementation

{ = GetDllVersion =
  Pass a TDllVersionInfoRec record and it
  returns the Dll version info there.
  Do not care for the cbSize member which is
  filled in by this function. }
function GetDllVersion(dllfile: string; var pdvi: TDllVersionInfoRec): Boolean;
var
  hDll: THandle;
  pDllGetVer: function(var pdvi: TDllVersionInfoRec): Integer; stdcall;
begin
  result := False;
  pDllGetVer := nil;
  SetErrorMode(SEM_FAILCRITICALERRORS);
  hDll := LoadLibrary(PChar(dllfile));
  if hDll <> 0 then pDllGetVer := GetProcAddress(hDll, 'DllGetVersion');
  if Assigned(pDllGetVer) then
  begin
    pdvi.cbSize := sizeof(TDllVersionInfoRec);
    pDllGetVer(pdvi);
    result := True;
  end;
  FreeLibrary(hDll);
  SetErrorMode(0);
end;

end.
 
