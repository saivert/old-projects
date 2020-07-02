unit NxSTray;
{
NxS Tray Icon component

  Notes:
--------
This component uses the new features of Windows 2000/XP.
If you use this component in an application that is running
on older Windows platforms such as Windows 95/98 the
component will do nothing when these methods/properties are used:
  SetVersion, ShowBalloon, SetFocus, and OnBalloonShow,
  OnBalloonHide, OnBalloonClose and OnBalloonClick.

This component creates a hidden window for each instance,
it keeps a record of each hidden window and makes sure the
right one (the one originally created for the instance) is
used. This is the same as the now deprecated function
"AllocateHWND". This hidded window is responsible for intercepting
window messages sent by the taskbar. This means that you can use
this component in a console application.

New: This component now uses the registered message "TaskbarCreated",
so if the taskbar is shutdown (either normally or abnormally) and is
restarted the tray icon will be re-inserted to the taskbar notification area.

  Credits:
----------
This component is based on the TTrayIcon component included
with Borland Delphi. I just added the new features of
Windows 2000/XP and cleaned up the code.

My contact information:

Web    http://members.tripod.com/files_saivert/
E-Mail saivert AT email DOT com

}

interface
uses
  SysUtils, Classes, Windows, Messages, ShellApi, Forms,
  Graphics, Controls, Menus, ExtCtrls;

type
  PNewNotifyIconData = ^TNewNotifyIconData;
  TNewNotifyIconData = record
    cbSize: DWORD;
    _hWnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array[0..127] of Char;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..255] of Char;
    case Integer of
      0: (uTimeout: UINT);
      1: (uVersion: UINT;
    szInfoTitle: array[0..63] of Char;
    dwInfoFlags: DWORD;
    guidItem: TGUID;)
  end;

{ NxS Tray component stuff }

type
  TTrayCompButtonClick = (arLeftClick, arLeftDblClick, arLeftClickUp,
                  arRightClick, arRightDblClick, arRightClickUp, arNone);

  TBalloonIconType = (bitNone, bitInfo, bitWarning, bitError);

  { Record for use with code that replaces the
    AllocateHWND deprecated function }
  TTrayWndObjRec = record
    WndHandle : HWND;
    pObject : TObject;
  end;

  TNxSTray = class(TComponent)
  private
    m_WndObj: TTrayWndObjRec;
    FNid: TNewNotifyIconData;
    FNewShell: Boolean;
    FCreated: Boolean;

    FTimer: TTimer;
    FIcon: TIcon;
    FIconList: TImageList;
    FPopupMenu: TPopupMenu;
    FHint: string;
    FIconIndex: Integer;
    FVisible: Boolean;
    FHideOnMinimize: Boolean;
    FAppRestore: TTrayCompButtonClick;
    FPopupMenuShow: TTrayCompButtonClick;

    FOnMinimize: TNotifyEvent;
    FOnRestore: TNotifyEvent;
    FOnLButtonDblClick: TNotifyEvent;
    FOnLButtonDown: TNotifyEvent;
    FOnLButtonUp: TNotifyEvent;
    FOnRButtonDblClick: TNotifyEvent;
    FOnRButtonDown: TNotifyEvent;
    FOnRButtonUp: TNotifyEvent;

    FBalloonShow: TNotifyEvent;
    FBalloonHide: TNotifyEvent;
    FBalloonClose: TNotifyEvent;
    FBalloonClick: TNotifyEvent;

  protected
    procedure SetVisible(Value: Boolean);
    procedure TrayCompMinimize(Sender: TObject);
    procedure TrayCompRestore(Sender: TObject);
    procedure SetHint(Hint: string);
    procedure SetHide(Value: Boolean);
    function GetInterval: Integer;
    procedure SetInterval(Value: Integer);
    function GetAnimate: Boolean;
    procedure SetAnimate(Value: Boolean);
    procedure SetIcon(NewIcon: TIcon);
    procedure TaskbarCreated;

    procedure LButtonDown;
    procedure LButtonUp;
    procedure LButtonDblClick;
    procedure RButtonDown;
    procedure RButtonUp;
    procedure RButtonDblClick;

    procedure BalloonShow;
    procedure BalloonHide;
    procedure BalloonClose;
    procedure BalloonClick;

    procedure EndSession;
    procedure Loaded; override;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;

    procedure Minimize;
    procedure Restore;
    procedure Update;
    procedure ShowMenu;
    procedure SetIconIndex(Value: Integer);
    procedure OnAnimation(Sender: TObject);
    procedure SetDefaultIcon;

    { Removes the icon from the taskbar and releases resources bound to it }
    procedure Remove;
    { Sets the focus to the tray icon }
    procedure SetFocus;
    { Sets the version we're operating under }
    function SetVersion(Version: Integer): Boolean;
    { Sets the GUID for the tray icon. Used to uniquely identify it }
    procedure SetGUID(newguid: PGUID);

    { Balloon Tool Tip stuff }
    procedure ShowBalloon(InfoText: string; InfoTitle: string = '';
      BalloonIcon: TBalloonIconType = bitInfo; PlaySound: Boolean = True;
      Timeout: Integer = 5000);
    procedure HideBalloon;
  published
   { Properties }
   property Visible: Boolean read FVisible write SetVisible default False;
   property Hint: String read FHint write SetHint;
   property PopupMenu: TPopupMenu read FPopupMenu write FPopupMenu;
   property HideOnMinimize: Boolean read FHideOnMinimize write SetHide default False;
   property RestoreOn: TTrayCompButtonClick read FAppRestore write FAppRestore default arLeftDblClick;
   property PopupMenuOn: TTrayCompButtonClick read FPopupMenuShow write FPopupMenuShow default arRightClickUp;
   property Icon: TIcon read FIcon write SetIcon;
   property Icons: TImageList read FIconList write FIconList;
   property IconIndex: Integer read FIconIndex write SetIconIndex default 0;
   property Interval: Integer read GetInterval write SetInterval default 1000;
   property Animate: Boolean read GetAnimate write SetAnimate default false;

   { Events }
   property OnMinimize: TNotifyEvent read FOnMinimize write FOnMinimize;
   property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
   property OnLButtonDblClick: TNotifyEvent read FOnLButtonDblClick write FOnLButtonDblClick;
   property OnLButtonDown: TNotifyEvent read FOnLButtonDown write FOnLButtonDown;
   property OnLButtonUp: TNotifyEvent read FOnLButtonUp write FOnLButtonUp;
   property OnRButtonDblClick: TNotifyEvent read FOnRButtonDblClick write FOnRButtonDblClick;
   property OnRButtonDown: TNotifyEvent read FOnRButtonDown write FOnRButtonDown;
   property OnRButtonUp: TNotifyEvent read FOnRButtonUp write FOnRButtonUp;

   { Balloon Tool Tip Events }
   property OnBalloonShow: TNotifyEvent read FBalloonShow write FBalloonShow;
   property OnBalloonHide: TNotifyEvent read FBalloonHide write FBalloonHide;
   property OnBalloonClose: TNotifyEvent read FBalloonClose write FBalloonClose;
   property OnBalloonClick: TNotifyEvent read FBalloonClick write FBalloonClick;
  end;

implementation

uses dllgetversion;

{ Version 5.0/6.0 Tray Notification stuff }
const
  NIM_SETFOCUS    = $00000003;
  NIM_SETVERSION  = $00000004;
  NOTIFYICON_VERSION = 3; { Used by NIM_SETVERSION }

  NIF_STATE       = $00000008;
  { State flags }
  NIS_HIDDEN      = $00000001;
  NIS_SHAREDICON  = $00000002;

  NIF_INFO        = $00000010;
  NIF_GUID        = $00000020;

  { Notify Icon Infotip flags }
  NIIF_NONE       = $00000000; { No icon }
  { icon flags are mutually exclusive
    and take only the lowest 2 bits }
  NIIF_INFO       = $00000001;
  NIIF_WARNING    = $00000002;
  NIIF_ERROR      = $00000003;
  NIIF_ICON_MASK  = $0000000F;

  NIIF_NOSOUND    = $00000010; { Do not play the "pop" sound }

  { Keyboard interface notifications }
  NIN_SELECT      = (WM_USER + 0);
  NINF_KEY        = 1;
  NIN_KEYSELECT   = (NIN_SELECT or NINF_KEY);

  { Balloon Tool Tip notifications }
  NIN_BALLOONSHOW      = (WM_USER + 2);
  NIN_BALLOONHIDE      = (WM_USER + 3);
  NIN_BALLOONTIMEOUT   = (WM_USER + 4);
  NIN_BALLOONUSERCLICK = (WM_USER + 5);

const
  WM_SYSTEM_TRAY_NOTIFY = (WM_USER + 100);
  TASKBAR_CREATED_REGMSG = 'TaskbarCreated';
  EmptyGUID: TGUID = '{00000000-0000-0000-0000-000000000000}';

{ START of stuff that replaces the use of AllocateHWND which is deprecated }

var
  l_lstObject: TList;

function GetObjectFromWnd(WndHandle : HWND) : TNxSTray;
var
  i : Integer;
  WndObj : TTrayWndObjRec;
begin
  Result := nil;

  for i := 0 to l_lstObject.Count - 1 do
  begin
    WndObj := TTrayWndObjRec(l_lstObject[i]^);
    if WndObj.WndHandle = WndHandle then
    begin
      Result := WndObj.pObject as TNxSTray;
      break;
    end;
  end;
end;

function CreateTrayWnd: HWND; forward;

{ END of stuff that replaces the use of AllocateHWND which is deprecated }

constructor TNxSTray.Create(Owner: TComponent);
var
  dvi: TDllVersionInfoRec;
begin
  inherited Create(Owner);

  { Initialize variables }
  FCreated := False;
  FIconIndex := 0;
  FIconList := nil;

  { Set up icon }
  FIcon := TIcon.Create;

  { Set up timer }
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.OnTimer := OnAnimation;
  FTimer.Interval := 1000;

  { Assign defaults }
  FIcon.Assign(Application.Icon);
  FAppRestore := arLeftDblClick;
  FPopupMenuShow := arRightClickUp;
  FVisible := False;
  FHideOnMinimize := False;

  if not (csDesigning in ComponentState) then
  begin

    { Create message handling window }
    m_WndObj.WndHandle := CreateTrayWnd;
    m_WndObj.pObject := Self;
    l_lstObject.Add(@m_WndObj);

    { Clear out everything just to be on the safe side }
    FillChar(FNid, sizeof(TNewNotifyIconData), 0);

    GetDllVersion('shell32.dll', dvi);
    FNewShell := (dvi.dwMajorVersion >= 5);

    if FNewShell then
      FNid.cbSize := sizeof(TNewNotifyIconData)
    else
      FNid.cbSize := sizeof(TNotifyIconData);

    FNid._hWnd := m_WndObj.WndHandle;
    FNid.uID := Integer(Self);
    FNid.hIcon := FIcon.Handle;
    FNid.uCallbackMessage := WM_SYSTEM_TRAY_NOTIFY;
    FNid.guidItem := EmptyGUID;

    if FNewShell then
    begin
      SetVersion(NOTIFYICON_VERSION);
    end;

    { Replace the application's OnMinimize and OnRestore handlers with
      special ones for the tray icon. The TrayComp component has its own
      OnMinimize and OnRestore events that the user can set. }
    Application.OnMinimize := TrayCompMinimize;
    Application.OnRestore := TrayCompRestore;
    Update;
  end;
end;

destructor TNxSTray.Destroy;
begin
   if not (csDesigning in ComponentState) then
   begin
      Shell_NotifyIcon(NIM_DELETE, @FNid);
      DestroyWindow(FNid._hWnd);      
   end;

   if Assigned(FIcon) then
      FIcon.Destroy;

   if Assigned(FTimer) then
      FTimer.Destroy;

   inherited Destroy;
end;

function TNxSTray.SetVersion(Version: Integer): Boolean;
begin
  FNid.uVersion := Version;
  result := Shell_NotifyIcon(NIM_SETVERSION, @FNid);
end;

procedure TNxSTray.SetGUID(newguid: PGUID);
begin
  if newguid = nil then
    FNid.guidItem := EmptyGUID
  else
    FNid.guidItem := newguid^;
  FNid.uFlags := NIF_GUID;
  Update;
end;


procedure TNxSTray.SetVisible(Value: Boolean);
begin
  { If already visible or hidden, don't bother... }
  if Value = FVisible then Exit;
  FVisible := Value;

  if (csDesigning in ComponentState) then Exit;

  if FVisible then
  begin
    if FNewShell and FCreated then begin
      FNid.uFlags := NIF_STATE;
      FNid.dwStateMask := NIS_HIDDEN;
      FNid.dwState := 0;
      Shell_NotifyIcon(NIM_MODIFY, @FNid)
    end else begin
      FCreated := True;

      FNid.uFlags := NIF_MESSAGE;
      if (FNid.szTip[0] > #0) then FNid.uFlags := FNid.uFlags or NIF_TIP;
      if (FNid.hIcon > 0) then FNid.uFlags := FNid.uFlags or NIF_ICON;
      if not IsEqualGUID(FNid.guidItem, EmptyGUID) then
        FNid.uFlags := FNid.uFlags or NIF_GUID;

      Shell_NotifyIcon(NIM_ADD, @FNid);
    end;
  end else
  begin
    if FNewShell then begin
      FNid.uFlags := NIF_STATE;
      FNid.dwStateMask := NIS_HIDDEN;
      FNid.dwState := NIS_HIDDEN;
      Shell_NotifyIcon(NIM_MODIFY, @FNid);
    end else begin
      FCreated := False;
      //Old style hiding by removing it
      Shell_NotifyIcon(NIM_DELETE, @FNid);
    end;
  end;
end;

procedure TNxSTray.Remove;
begin
	FVisible := False;
	FCreated := False;
	Shell_NotifyIcon(NIM_DELETE, @FNid);
end;

{ This function is called from the CommWndProc }
procedure TNxSTray.TaskbarCreated;
begin
  FVisible := False; { Set FVisible & FCreated to False, so we can... }
  FCreated := False;
  SetVisible(True);  { ...do this! }
end;

procedure TNxSTray.TrayCompMinimize(Sender: TObject);
begin
   Minimize;
end;

procedure TNxSTray.TrayCompRestore(Sender: TObject);
begin
   Restore;
end;

procedure TNxSTray.SetHint(Hint: string);
begin
  if FHint <> Hint then
  begin
    FHint := Hint;
    if FNewShell then
      StrPLCopy(FNid.szTip, Hint, sizeof(FNid.szTip) - 1)
    else
      StrPLCopy(FNid.szTip, Hint, 64 - 1);
    FNid.uFlags := NIF_TIP;
    Update;
  end;
end;

procedure TNxSTray.SetHide(Value: Boolean);
begin
  FHideOnMinimize := Value;
end;

function TNxSTray.GetInterval: Integer;
begin
  result := FTimer.Interval;
end;

procedure TNxSTray.SetInterval(Value: Integer);
begin
  FTimer.Interval := Value;
end;

function TNxSTray.GetAnimate: Boolean;
begin
  result := FTimer.Enabled;
end;

procedure TNxSTray.SetAnimate(Value: Boolean);
begin
  FTimer.Enabled := Value;
end;

procedure TNxSTray.SetIcon(NewIcon: TIcon);
begin
  FIcon.Assign(NewIcon);
  FNid.hIcon := FIcon.Handle;
  FNid.uFlags := NIF_ICON;
  Update;
end;

procedure TNxSTray.LButtonDown;
begin
  if (FAppRestore = arLeftClick) then
    Restore;
  if (FPopupMenuShow = arLeftClick) then
    ShowMenu;

  if Assigned(FOnLButtonDown) then
    FOnLButtonDown(Self);
end;

procedure TNxSTray.LButtonUp;
begin

  if (FAppRestore = arLeftClickUp) then
    Restore;
  if (FPopupMenuShow = arLeftClickUp) then
    ShowMenu;

  if Assigned(FOnLButtonUp) then
    FOnLButtonUp(Self);
end;

procedure TNxSTray.LButtonDblClick;
begin
  if (FAppRestore = arLeftDblClick) then
    Restore;
  if (FPopupMenuShow = arLeftDblClick) then
    ShowMenu;

  if Assigned(FOnLButtonDblClick) then
    FOnLButtonDblClick(Self);
end;

procedure TNxSTray.RButtonDown;
begin
  if (FAppRestore = arRightClick) then
    Restore;
  if (FPopupMenuShow = arRightClick) then
    ShowMenu;

  if Assigned(FOnRButtonDown) then
    FOnRButtonDown(Self);
end;

procedure TNxSTray.RButtonUp;
begin
  if (FAppRestore = arRightClickUp) then
    Restore;
  if (FPopupMenuShow = arRightClickUp) then
    ShowMenu;

  if Assigned(FOnRButtonUp) then
    FOnRButtonUp(Self);
end;

procedure TNxSTray.RButtonDblClick;
begin
  if (FAppRestore = arRightDblClick) then
    Restore;
  if (FPopupMenuShow = arRightDblClick) then
    ShowMenu;

  if Assigned(FOnRButtonDblClick) then
    FOnRButtonDblClick(Self);
end;

procedure TNxSTray.BalloonShow;
begin
  if Assigned(FBalloonShow) then
    FBalloonShow(Self);
end;

procedure TNxSTray.BalloonHide;
begin
  if Assigned(FBalloonHide) then
    FBalloonHide(Self);
end;

procedure TNxSTray.BalloonClose;
begin
  if Assigned(FBalloonClose) then
    FBalloonClose(Self);
end;

procedure TNxSTray.BalloonClick;
begin
  if Assigned(FBalloonClick) then
    FBalloonClick(Self);
end;


procedure TNxSTray.EndSession;
begin
  Shell_NotifyIcon(NIM_DELETE, @FNid);
end;

procedure TNxSTray.Loaded;
begin
  inherited;

  if Assigned(FIconList) then
    FIconList.GetIcon(FIconIndex, FIcon);

  FNid.hIcon := FIcon.Handle;
  FNid.uFlags := NIF_ICON;
  Update;
end;

procedure TNxSTray.Minimize;
begin
  Application.Minimize;

  if (FHideOnMinimize and FVisible) then
    ShowWindow(Application.Handle, SW_HIDE);

  if Assigned(FOnMinimize) then
    FOnMinimize(Self);
end;

procedure TNxSTray.Restore;
begin
  Application.Restore;

  if (FHideOnMinimize and FVisible) then
  begin
    ShowWindow(Application.Handle, SW_RESTORE);
    SetForegroundWindow(Application.Handle);
  end;

  if Assigned(FOnRestore) then
    FOnRestore(Self);
end;

procedure TNxSTray.Update;
begin
  if not (csDesigning in ComponentState) and FCreated then
  begin
    Shell_NotifyIcon(NIM_MODIFY, @FNid);
  end;
end;

procedure TNxSTray.ShowMenu;
var
  Point: TPoint;
begin
  if Assigned(FPopupMenu) then
  begin
    { Need to call SetForegroundWindow, or else the menu refuses to
      dismiss if clicking outside of menu. }
    SetForegroundWindow(m_WndObj.WndHandle);

    GetCursorPos(Point);
    FPopupMenu.Popup(Point.x, Point.y);
  end;
end;

procedure TNxSTray.SetIconIndex(Value: Integer);
begin
  FIconIndex := Value;

  if not (csDesigning in ComponentState) then
  begin
    if Assigned(FIconList) then
      FIconList.GetIcon(FIconIndex, FIcon);

    FNid.hIcon := FIcon.Handle;
    FNid.uFlags := NIF_ICON;
    Update;
  end;
end;

procedure TNxSTray.OnAnimation(Sender: TObject);
begin
  if (csDesigning in ComponentState) then Exit;
  if not Assigned(FIconList) then Exit;

  if (FIconIndex < FIconList.Count-1) then
    SetIconIndex(FIconIndex + 1)
  else
    SetIconIndex(0);
end;

procedure TNxSTray.SetDefaultIcon;
begin
  FIcon.Assign(Application.Icon);
  FNid.hIcon := FIcon.Handle;
  Update;
end;

procedure TNxSTray.SetFocus;
begin
  Shell_NotifyIcon(NIM_SETFOCUS, @FNid);
end;

{ Balloon Tool Tip functions }

procedure TNxSTray.ShowBalloon(InfoText: string; InfoTitle: string = '';
  BalloonIcon: TBalloonIconType = bitInfo; PlaySound: Boolean = True;
  Timeout: Integer = 5000);
const
  flags: array[TBalloonIconType] of Integer = (NIIF_NONE, NIIF_INFO, NIIF_WARNING, NIIF_ERROR);
  sound: array[Boolean] of Integer = (NIIF_NOSOUND, 0);
begin
  FNid.uFlags := NIF_INFO;
  StrPLCopy(FNid.szInfo, InfoText, sizeof(FNid.szInfo) - 1);
  StrPLCopy(FNid.szInfoTitle, InfoTitle, sizeof(FNid.szInfoTitle) - 1);
  FNid.uTimeout := Timeout;
  FNid.dwInfoFlags := flags[BalloonIcon] or sound[PlaySound];
  Shell_NotifyIcon(NIM_MODIFY, @FNid);
end;

procedure TNxSTray.HideBalloon;
begin
  FNid.uFlags := NIF_INFO;
  FNid.szInfo[0] := #0;
  Shell_NotifyIcon(NIM_MODIFY, @FNid);
end;

{ START of stuff that replaces the use of AllocateHWND which is deprecated }

function CommWndProc(hwnd : HWND; uMsg : Cardinal;
  wParam : WPARAM; lParam : LPARAM) : LResult; stdcall;
var
  Obj: TNxSTray;
begin
  Result := 0;
  Obj := GetObjectFromWnd(hwnd);

  with Obj do
  begin

    { Handle the "TaskbarCreated" registered window message }
    if uMsg = RegisterWindowMessage(TASKBAR_CREATED_REGMSG) then
      TaskbarCreated;

    case uMsg of
      WM_QUERYENDSESSION: Result := 1;
      WM_ENDSESSION: EndSession;
      WM_SYSTEM_TRAY_NOTIFY:
        case lParam of
          WM_LBUTTONDOWN: LButtonDown();
          WM_LBUTTONUP: LButtonUp();
          WM_LBUTTONDBLCLK: LButtonDblClick();
          WM_RBUTTONDOWN: RButtonDown();
          WM_RBUTTONUP: RButtonUp();
          WM_RBUTTONDBLCLK: RButtonDblClick();
          NIN_BALLOONSHOW: BalloonShow;
          NIN_BALLOONHIDE: BalloonHide;
          NIN_BALLOONTIMEOUT: BalloonClose;
          NIN_BALLOONUSERCLICK: BalloonClick;
        end;
      else Result := CallWindowProc(@DefWindowProc, hWnd, uMsg, wParam, lParam);
    end;
  end; {with Obj do...}
end;

function CreateTrayWnd: HWND;
var
  wndcls : WNDCLASS;
  hWnd : THandle;
  a: TAtom;
begin
  Result := 0;

  FillChar(wndcls, sizeof(WNDCLASS), 0);
  wndcls.lpfnWndProc   := @CommWndProc;
  wndcls.hInstance     := HInstance;
  wndcls.lpszClassName := 'NxSTray_Wnd';
  a := Windows.RegisterClass(wndcls);
  if a = 0 then
  begin
    if GetLastError() <> 1410 then
      Exit;
  end;

  hWnd := CreateWindow(
    PChar(a),
    'TNxSTray Window',
    WS_BORDER,
    Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT),
    0,
    0,
    hInstance,
    nil);

  Result := hWnd;
end;

initialization
  l_lstObject := TList.Create();
finalization
  l_lstObject.Free();

{ END of stuff that replaces the use of AllocateHWND which is deprecated }
end.
