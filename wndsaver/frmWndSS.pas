unit frmWndSS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  ExtCtrls, StdCtrls, Buttons, XPAbout, Menus, NxSTray, AppEvnts, Dialogs,
  ShellApi, ImgList;

const
  StrRegKey = 'Software\Saivert\wndsaver';
  OTHERINSTANCE = 1044;
  
type
  TWndSSForm = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    BitBtnBrowse: TBitBtn;
    BtnLoadUnload: TButton;
    BtnSSConfigure: TButton;
    Shape1: TShape;
    BtnAbout: TButton;
    XPAbout1: TXPAbout;
    BtnExit: TButton;
    OpenDialog1: TOpenDialog;
    CBUseDesktop: TCheckBox;
    CheckBox1: TCheckBox;
    TrayMenu: TPopupMenu;
    ShowHideMI: TMenuItem;
    About1: TMenuItem;
    Exit1: TMenuItem;
    FramePanel: TPanel;
    SSPanel: TPanel;
    Displayproperties1: TMenuItem;
    NxSTray1: TNxSTray;
    TrayAnimIL: TImageList;
    procedure BtnAboutClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure BitBtnBrowseClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure UnloadClick(Sender: TObject);
    procedure BtnSSConfigureClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShowHideMIClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Displayproperties1Click(Sender: TObject);
    procedure NxSTray1Minimize(Sender: TObject);
    procedure DrawProc(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      State: TOwnerDrawState);
    procedure MeasureProc(Sender: TObject; ACanvas: TCanvas; var Width,
      Height: Integer);
  private
    FScrFilename: string;
    FOwnDeskWnd: THandle;
    function CreateDeskWnd: THandle;
    procedure OnWMCopyData(var msg: TWMCopyData); message WM_COPYDATA;
  public
    FLoaded: Boolean;
    procedure Load(scrfn: string);
    procedure Unload;
  end;

var
  WndSSForm: TWndSSForm;

function OwnWndProc(wnd: HWND; msg: Integer; wParam: WPARAM; lParam: LPARAM): Integer; stdcall;

{ This will cause run-time errors when linked and run on a Pre-Windows 2000
  machine. }
function GetShellWindow: Integer; stdcall; external 'user32.dll' name 'GetShellWindow';

implementation

uses Registry;

{$R *.dfm}

const
  StrLoad = '&Load';
  StrUnload = '&Unload';
  StrNoSS = 'No screensaver loaded!';
  StrDeskWndClassName = 'NxS_SaverHost';
  StrShow = '&Show';
  StrHide = '&Hide';

var
  deskwnd: HWND;

function TWndSSForm.CreateDeskWnd: THandle;
var
  wc: TWndClass;
  wr: TRect;
begin
  if Win32MajorVersion >= 5 then
    deskwnd := GetShellWindow { In Windows 2000 and above.}
  else deskwnd := FindWindow(nil, 'Program Manager');

  Windows.GetClientRect(deskwnd, wr);
  FillChar(wc, sizeof(TWndClass), 0);
  wc.lpfnWndProc := @OwnWndProc;
  wc.hInstance := HInstance;
  wc.lpszClassName := StrDeskWndClassName;
  Windows.RegisterClass(wc);
  result := CreateWindowEx(0, StrDeskWndClassName, 'NxS Screensaver Host Window',
    WS_CHILD or WS_VISIBLE, 0, 0, wr.Right-wr.Left, wr.Bottom-wr.Top, deskwnd, 0,
    wc.hInstance, nil);
end;

function OwnWndProc(wnd: HWND; msg: Integer; wParam: WPARAM; lParam: LPARAM): Integer; stdcall;
var
  ps: TPaintStruct;
  dc: HDC;
  r: TRect;
  pn: HPEN;
  bn: HBRUSH;
begin
  Result := 0;
  case Msg of
  WM_DESTROY: Windows.UnregisterClass(StrDeskWndClassName, HInstance);
  WM_CONTEXTMENU: begin
    WndSSForm.Displayproperties1.Visible := True;
    WndSSForm.TrayMenu.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
    WndSSForm.Displayproperties1.Visible := False;
  end;
  WM_ERASEBKGND: begin
    dc := BeginPaint(wnd, ps);
    GetClientRect(wnd, r);
    pn := CreatePen(0, 1, clWhite);
    bn := CreateSolidBrush(clBlack);
    SelectObject(dc, pn);
    SelectObject(dc, bn);
    Rectangle(dc, 0, 0, r.Right-r.Left, r.Bottom-r.Top);
    EndPaint(wnd, ps);
  end;
  else Result := DefWindowProc(wnd, Msg, wParam, lParam);
  end;
end;

procedure TWndSSForm.Load(scrfn: string);
var
  val: Integer;
begin
  FLoaded := False;
  if FileExists(scrfn) then
  begin
    FScrFilename := scrfn;
    if not CBUseDesktop.Checked then
    begin
      WinExec(PChar(Format('%s /p %d', [scrfn, SSPanel.Handle])), SW_SHOWNORMAL);
      FLoaded := IsWindow(GetWindow(SSPanel.Handle, GW_CHILD));
    end
    else begin
      FOwnDeskWnd := CreateDeskWnd;
      if Checkbox1.Checked then
        val := HWND_TOP
      else val := HWND_BOTTOM;
      SetWindowPos(FOwnDeskWnd, val, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

      WinExec(PChar(Format('%s /p %d', [scrfn, FOwnDeskWnd])), SW_SHOWNORMAL);
      FLoaded := IsWindow(GetWindow(FOwnDeskWnd, GW_CHILD));
      if FLoaded then
        EnableWindow(GetWindow(FOwnDeskWnd, GW_CHILD), False)
      else DestroyWindow(FOwnDeskWnd);
    end;
  end;
end;

procedure TWndSSForm.Unload;
var
  tmph: THandle;
begin
  if not CBUseDesktop.Checked then
  begin
    tmph := GetWindow(SSPanel.Handle, GW_CHILD);
    if tmph > 0 then
    begin
      SendMessage(tmph, WM_CLOSE, 0, 0);
      FLoaded := False;
    end;
  end else
  begin
    tmph := GetWindow(FOwnDeskWnd, GW_CHILD);
    if tmph > 0 then
    begin
      SendMessage(tmph, WM_CLOSE, 0, 0);
    end;
    DestroyWindow(FOwnDeskWnd);
    FLoaded := False;    
  end;
end;

procedure TWndSSForm.BtnAboutClick(Sender: TObject);
begin
  XPAbout1.Execute
end;

procedure TWndSSForm.BtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TWndSSForm.BitBtnBrowseClick(Sender: TObject);
var
  tmppath: array[0..MAX_PATH-1] of Char;
begin
  GetSystemDirectory(tmppath, MAX_PATH-1);
  OpenDialog1.InitialDir := tmppath;
  OpenDialog1.FileName := Edit1.Text;
  if OpenDialog1.Execute then
    Edit1.Text := OpenDialog1.FileName;
end;

procedure TWndSSForm.LoadClick(Sender: TObject);
begin
  Load(Edit1.Text);
  if FLoaded then
  begin
    CBUseDesktop.Enabled := False;
    BtnLoadUnload.OnClick := UnloadClick;
    BtnLoadUnload.Caption := StrUnload;
    SSPanel.Align := alNone;
    if CBUseDesktop.Checked then
      SSPanel.Caption := 'Screensaver is on desktop!'
    else SSPanel.Caption := EmptyStr;

    { Update TrayIcon, make it animate! }
    NxSTray1.Icons := TrayAnimIL;
    NxSTray1.Animate := True;
  end;
end;

procedure TWndSSForm.UnloadClick(Sender: TObject);
begin
  Unload;
  if not FLoaded then
  begin
    CBUseDesktop.Enabled := True;
    BtnLoadUnload.OnClick := LoadClick;
    BtnLoadUnload.Caption := StrLoad;
    SSPanel.Caption := StrNoSS;
    BtnLoadUnload.Enabled := FileExists(Edit1.Text);
    SSPanel.Align := alClient;

    { Update TrayIcon, stop animation! }
    NxSTray1.Animate := False;
    NxSTray1.SetDefaultIcon;

  end;
end;

procedure TWndSSForm.BtnSSConfigureClick(Sender: TObject);
begin
  WinExec(PChar(Format('%s /c:%d', [Edit1.Text, Handle])), SW_SHOWNORMAL)
end;

procedure TWndSSForm.Edit1Change(Sender: TObject);
var
  en: Boolean;
begin
  en := FileExists(Edit1.Text);
  if not FLoaded then
    BtnLoadUnload.Enabled := en;
  BtnSSConfigure.Enabled := en;
end;

procedure TWndSSForm.CheckBox1Click(Sender: TObject);
var
  val: Integer;
begin
  if Checkbox1.Checked then
    val := HWND_TOP
  else val := HWND_BOTTOM;
  SetWindowPos(FOwnDeskWnd, val, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TWndSSForm.FormCreate(Sender: TObject);
var
  abd: TAppBarData;
begin
  with TRegistry.Create do
  begin
    OpenKey(StrRegKey, False);
    if ValueExists('File') then
      Edit1.Text := ReadString('File');
    if ValueExists('Hide desktop icons') then
      Checkbox1.Checked := ReadBool('Hide desktop icons');
    if ValueExists('Show on desktop') then
      CBUseDesktop.Checked := ReadBool('Show on desktop');
    CloseKey;
    Destroy;
  end;

  { Get the taskbar position }
  abd.cbSize := sizeof(TAppBarData);
  abd.hWnd := Handle;
  SHAppBarMessage(ABM_GETTASKBARPOS, abd);

  { Position the window near the taskbar }
  case abd.uEdge of
    ABE_BOTTOM: begin
      Top := abd.rc.Top - Height - 16;
      Left := abd.rc.Right - Width - 16;
    end;
    ABE_TOP: begin
      Top := abd.rc.Bottom + 16;
      Left := abd.rc.Right - Width - 16;
    end;
    ABE_LEFT: begin
      Top := abd.rc.Bottom - Height - 16;
      Left := abd.rc.Right + 16;
    end;
    ABE_RIGHT: begin
      Top := abd.rc.Bottom - Height - 16;
      Left := abd.rc.Left - Width - 16;
    end;
  end;

  if ParamCount >= 1 then
  begin
   Edit1.Text := ParamStr(1);
   if FLoaded then BtnLoadUnload.Click;
   BtnLoadUnload.Click;
  end;
end;

procedure TWndSSForm.About1Click(Sender: TObject);
begin
  SetForegroundWindow(Handle);
  XPAbout1.Execute;
end;

procedure TWndSSForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  with TRegistry.Create do
  begin
    OpenKey(StrRegKey, True);
    WriteString('', Application.Title);
    WriteString('File', Edit1.Text);
    WriteBool('Hide desktop icons', Checkbox1.Checked);
    WriteBool('Show on desktop', CBUseDesktop.Checked);    
    CloseKey;
    Destroy;
  end;
  if FLoaded then BtnLoadUnload.Click;
end;

procedure TWndSSForm.ShowHideMIClick(Sender: TObject);
begin
  if NxSTray1.Tag = 0 then
  begin
    NxSTray1.Tag := 1;
    ShowHideMI.Caption := StrShow;
    NxSTray1.Minimize;
  end else
  begin
    NxSTray1.Tag := 0;
    NxSTray1.Restore;
    ShowHideMI.Caption := StrHide;
  end;
end;

procedure TWndSSForm.Exit1Click(Sender: TObject);
begin
  BtnExit.Click  
end;

procedure TWndSSForm.Displayproperties1Click(Sender: TObject);
begin
  WinExec('rundll32.exe shell32.dll,Control_RunDLL desk.cpl', SW_SHOWNORMAL);
end;

procedure TWndSSForm.OnWMCopyData(var msg: TWMCopyData);
var
  cl: PChar;
begin
  if msg.CopyDataStruct^.dwData = OTHERINSTANCE then
  begin
    GetMem(cl, 4096);
    StrLCopy(cl, msg.CopyDataStruct^.lpData, msg.CopyDataStruct^.cbData);
    StrCopy(CmdLine, cl); { Assign the new command line to CmdLine }
    { Now we can use the well known ParamCount and ParamStr functions on
      the new command line. }
    if ParamCount >= 1 then
    begin
      Edit1.Text := ParamStr(1);
      if FLoaded then BtnLoadUnload.Click;
      BtnLoadUnload.Click;
    end else
    begin
      ShowHideMI.Caption := StrHide;
      WndSSForm.Show;
      SetForegroundWindow(Handle);
    end;
    FreeMem(cl);
  end;
end;

procedure TWndSSForm.NxSTray1Minimize(Sender: TObject);
begin
  NxSTray1.Tag := 1;
  ShowHideMI.Caption := StrShow;
end;

procedure TWndSSForm.DrawProc(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  State: TOwnerDrawState);
var
  mi: TMenuItem;
  r: TRect;
  bm: TBitmap;
begin
  mi := Sender as TMenuItem;

  with ACanvas do
  begin
    Brush.Color := clWindow;
    FillRect(ARect);

    Brush.Color := clBtnFace;
    Windows.CopyRect(r, ARect);
    r.Right := 22;
    FillRect(r);
    if odSelected in State then
    begin
      Pen.Color := RGB(49,105,198);
      Brush.Color := RGB(198,211,239);
      Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    end;

    if mi.IsLine then
    begin
      PenPos := Point(ARect.Left+25, ARect.Top+(ARect.Bottom-ARect.Top) div 2);
      LineTo(ARect.Right, PenPos.Y);
      Exit;
    end;


    r.Left := ARect.Left+3;
    r.Top := ARect.Top+2;
    if odSelected in State then
      InflateRect(r, +1, +1);


    if not mi.Checked and Assigned(mi.Bitmap) then
    begin
      Draw(r.Left, r.Top, mi.Bitmap);
    end;

    {You must fix this when using this code in other places.}
    if not mi.Checked and (mi.ImageIndex >= 0) and
      (mi.GetImageList <> nil) then
    begin
      mi.GetImageList.Draw(ACanvas, r.Left, r.Top, mi.ImageIndex);
    end;

    if mi.Checked then
    begin
      bm := TBitmap.Create;
      bm.Handle := LoadBitmap(0, PChar(OBM_CHECK));
      Draw(r.Left, r.Top, bm);
      bm.Destroy;
    end;

    { Draw menu item text }
    Windows.CopyRect(r, ARect);
    r.Left := 25;
    InflateRect(r, -2, -2);

    Brush.Color := clMenu;
    SetBkMode(Handle, TRANSPARENT);
    if odSelected in State then
      SetBkColor(Handle, RGB(198,211,239))
    else
      SetBkColor(Handle, GetSysColor(COLOR_WINDOW));
    if mi.Enabled then
      Font.Color := clMenuText
    else
      Font.Color := clGrayText;
    if mi.Default then
      Font.Style := Font.Style + [fsBold];

    if odNoAccel in State then
      DrawText(Handle, PChar(StripHotkey(mi.Caption)), -1, r,
        DT_SINGLELINE or DT_VCENTER)
    else
      DrawText(Handle, PChar(mi.Caption), -1, r, DT_SINGLELINE or DT_VCENTER);

    if mi.ShortCut <> 0 then
    begin
      r.Left := ARect.Right-TextWidth(ShortcutToText(mi.ShortCut))-5;
      DrawText(Handle, PChar(ShortcutToText(mi.ShortCut)), -1, r,
        DT_SINGLELINE or DT_VCENTER);
    end;

  end;
end;


procedure TWndSSForm.MeasureProc(Sender: TObject; ACanvas: TCanvas; var Width,
  Height: Integer);
var
  mi: TMenuItem;
begin
  mi := Sender As TMenuItem;
  if mi.IsLine then
    Height := 3
  else
  begin
    Width := ACanvas.TextWidth(mi.Caption)+25;
    Height := ACanvas.TextHeight(mi.Caption)+8;

    {Support menu items with shortcuts}
    if mi.ShortCut <> 0 then
      Width := Width + ACanvas.TextWidth( ShortcutToText(mi.ShortCut) ) + 25;

  end;
end;


end.
