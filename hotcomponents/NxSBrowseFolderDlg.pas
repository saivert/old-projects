unit NxSBrowseFolderDlg;

interface

uses SysUtils, Windows, ShellApi, ShlObj, ActiveX, Classes;

type
  TRootFolder = (rfDesktop, rfMyComputer, rfNetwork, rfRecycleBin, rfAppData,
    rfCommonDesktopDirectory, rfCommonPrograms, rfCommonStartMenu, rfCommonStartup,
    rfControlPanel, rfDesktopDirectory, rfFavorites, rfFonts, rfInternet, rfPersonal,
    rfPrinters, rfPrintHood, rfPrograms, rfRecent, rfSendTo, rfStartMenu, rfStartup,
    rfTemplates);

  TNxSBrowseFolderDlg = class(TComponent)
  private
    FUseStatusText: Boolean;
    FUseRecurseDirs: Boolean;
    FCaption: string;
    FDir: string;
    FRoot: string;
    FRecurseDirs: Boolean;
    ParentWnd: THandle;

    procedure SetRoot(newroot: string);
  protected
  public
    function Execute: Boolean;
  published
    property Caption: string read FCaption write FCaption;
    property Directory: string read FDir write FDir;
    property Root: string read FRoot write SetRoot;
    property UseStatusText: Boolean read FUseStatusText write FUseStatusText;
    property UseRecurseDirs: Boolean read FUseRecurseDirs write FUseRecurseDirs;
    property RecurseDirs: Boolean read FRecurseDirs write FRecurseDirs;
  end;

implementation

uses TypInfo, Messages;

const
  nFolder: array[TRootFolder] of Integer =
    (CSIDL_DESKTOP, CSIDL_DRIVES, CSIDL_NETWORK, CSIDL_BITBUCKET, CSIDL_APPDATA,
    CSIDL_COMMON_DESKTOPDIRECTORY, CSIDL_COMMON_PROGRAMS, CSIDL_COMMON_STARTMENU,
    CSIDL_COMMON_STARTUP, CSIDL_CONTROLS, CSIDL_DESKTOPDIRECTORY, CSIDL_FAVORITES,
    CSIDL_FONTS, CSIDL_INTERNET, CSIDL_PERSONAL, CSIDL_PRINTERS, CSIDL_PRINTHOOD,
    CSIDL_PROGRAMS, CSIDL_RECENT, CSIDL_SENDTO, CSIDL_STARTMENU, CSIDL_STARTUP,
    CSIDL_TEMPLATES);

function GetCSIDLType(const Value: string): TRootFolder;
begin
{$R+}
  Result := TRootFolder(GetEnumValue(TypeInfo(TRootFolder), Value))
{$R-}
end;

var
  OldBrowseSubClassProc: TFNWndProc;
  BFState: record
    usestatustext: Boolean;
    userecursedirs: Boolean;
    dir: PChar;
    recursedirs: Boolean;
    newlook: Boolean;
  end;

function BrowseSubClassProc(Wnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT stdcall;
begin
  if (uMsg = WM_COMMAND) and
     (HIWORD(wParam) = BN_CLICKED) and
     (LOWORD(wParam) = WM_USER+131) then
  begin
    BFState.recursedirs := not BFState.recursedirs;
    if BFState.recursedirs then
      SendMessage(lParam, BM_SETCHECK, BST_CHECKED, 0)
    else SendMessage(lParam, BM_SETCHECK, BST_UNCHECKED, 0);
  end;

  result := CallWindowProc(OldBrowseSubClassProc, Wnd, uMsg, wParam, lParam); 
end;

function SelectDirCB(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
var
  Buffer: PChar;
  ShellMalloc: IMalloc;
  btn: HWND;
  r: TRect;
begin

  if (uMsg = BFFM_INITIALIZED) and (BFState.userecursedirs) then
  begin
    SetWindowLong(GetDlgItem(Wnd, 14147), GWL_STYLE,
      SS_LEFT or SS_PATHELLIPSIS or WS_CHILD or WS_VISIBLE);

    if BFState.newlook then
    begin
      GetWindowRect(FindWindowEx(Wnd, 0,
        'SHBrowseForFolder ShellNameSpace Control', nil), r);
      Dec(r.Top, 18);
    end
    else
    begin
      GetWindowRect(FindWindowEx(Wnd, 0, 'STATIC', nil), r);
      Inc(r.Top, 14);
    end;

    MapWindowPoints(HWND_DESKTOP, Wnd, r, 2);
    btn := CreateWindow('Button', 'Recurse directories',
      WS_CHILD or WS_VISIBLE or BS_CHECKBOX,
      r.Left, r.Top, 130, 18,
      Wnd, WM_USER+131, HInstance, nil);
    SendMessage(btn, WM_SETFONT, SendMessage(Wnd, WM_GETFONT, 0, 0), 1);

    if BFState.recursedirs then
      SendMessage(btn, BM_SETCHECK, BST_CHECKED, 0)
    else SendMessage(btn, BM_SETCHECK, BST_UNCHECKED, 0);

    {Subclass window to detect clicks on the checkbox we added}
    OldBrowseSubClassProc := TFNWndProc(
      SetWindowLong(Wnd, GWL_WNDPROC, Integer(@BrowseSubClassProc)) );
  end;

  if (uMsg = BFFM_INITIALIZED) and (BFState.dir <> nil) then
    SendMessage(Wnd, BFFM_SETSELECTION, Integer(True), Integer(BFState.dir));

  if (uMsg = BFFM_SELCHANGED) and BFState.usestatustext then
    if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
    begin
      Buffer := ShellMalloc.Alloc(MAX_PATH);
      ShGetPathFromIDList(PItemIDList(lParam), Buffer);
      SendMessage(Wnd, BFFM_SETSTATUSTEXT, 0, Integer(Buffer));
      ShellMalloc.Free(Buffer);
    end;
  Result := 0;
end;

procedure TNxSBrowseFolderDlg.SetRoot(newroot: string);
begin
  if FRoot <> newroot then
    FRoot := newroot;
end;

function TNxSBrowseFolderDlg.Execute: Boolean;
var
  BrowseInfo: TBrowseInfo;
  Buffer: PChar;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
begin
  Result := False;
  ParentWnd := GetForegroundWindow;

  { Set up private state record }
  BFState.usestatustext := FUseStatusText;
  BFState.userecursedirs := FUseRecurseDirs;
  BFState.dir := PChar(FDir);
  BFState.recursedirs := FRecurseDirs;

  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer := ShellMalloc.Alloc(MAX_PATH);
    try
      SHGetDesktopFolder(IDesktopFolder);
      { Just hope no one needs a directory named "rfMyComputer",
        to be sure use absolute paths ("c:\somefolder\rfMyComputer") }
      if FRoot = '' then
        RootItemIDList := nil
      else
        SHGetSpecialFolderLocation(ParentWnd,
          nFolder[GetCSIDLType(FRoot)], RootItemIDList);
      with BrowseInfo do
      begin
        hwndOwner := ParentWnd;
        pidlRoot := RootItemIDList;
        pszDisplayName := Buffer;
        lpszTitle := PChar(Caption);
        ulFlags := BIF_RETURNONLYFSDIRS;
        if FUseStatusText then
          ulFlags := ulFlags or BIF_STATUSTEXT
        else ulFlags := ulFlags or BIF_USENEWUI;

        BFState.newlook := (ulFlags and BIF_USENEWUI) > 0;

        lpfn := SelectDirCB;
        lparam := 0;
      end;
      ItemIDList := SHBrowseForFolder(BrowseInfo);
      Result := ItemIDList <> nil;
      FRecurseDirs := BFState.recursedirs;
      if Result then
      begin
        ShGetPathFromIDList(ItemIDList, Buffer);
        ShellMalloc.Free(ItemIDList);
        Directory := Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;

end.

