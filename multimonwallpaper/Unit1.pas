unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, ExtDlgs, Menus, jpeg;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    FileLV: TListView;
    AddBtn: TButton;
    MakeBtn: TButton;
    RemoveBtn: TButton;
    OpPictureDlg: TOpenPictureDialog;
    PopupMenu1: TPopupMenu;
    DetailedInfoMI: TMenuItem;
    FocusPanel: TPanel;
    SavePicDlg: TSavePictureDialog;
    MoveUpBtn: TButton;
    MoveDownBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);
    procedure FileLVDeletion(Sender: TObject; Item: TListItem);
    procedure FileLVInsert(Sender: TObject; Item: TListItem);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure DetailedInfoMIClick(Sender: TObject);
    procedure MIAdvancedDrawItem(Sender: TObject;
      ACanvas: TCanvas; ARect: TRect; State: TOwnerDrawState);
    procedure MIMeasureItem(Sender: TObject; ACanvas: TCanvas;
      var Width, Height: Integer);
    procedure FormContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure FocusPanelEnter(Sender: TObject);
    procedure FocusPanelExit(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure MakeBtnClick(Sender: TObject);
    procedure FileLVSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    FSelectedMonitor: Integer;
    FMonitorIconsFocused: Boolean;
  public
    procedure DrawMonitors;
    function SelectMonitor(X, Y: Integer): Integer;
    function GetMonitorIconRect(Index: Integer; var ARect: TRect): Boolean;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses ActiveX, ShellApi, ShlObj, ComObj, Registry;

var
  SCALENUMBER: Integer = 10;
resourcestring
  SDetailInfo = 'Workarea:'#13#10'Left: %d; Top: %d; Right: %d; Bottom: %d';

procedure TForm1.DrawMonitors;
var
  i: Integer;
  r, r2: TRect;
  s: string;
begin
  with Image1.Canvas do
  begin
    Font.Color := clWhite;
    Font.Size := 10;
    Font.Style := [fsBold];

    Brush.Color := clBtnFace;
    Pen.Color := clHighlight;
    Rectangle(ClipRect);
    if FMonitorIconsFocused and (FSelectedMonitor < 0) then
    begin
      r := ClipRect;
      InflateRect(r, -2, -2);
      DrawFocusRect(r);
    end;

    Brush.Color := clBlack;
    Pen.Color := clWhite;
  end;

  for i := 0 to Screen.MonitorCount-1 do
  begin
    GetMonitorIconRect(i, r);

    { Draw rectangle to screen }
    if FSelectedMonitor = Screen.Monitors[i].MonitorNum then
    begin
      Image1.Canvas.Pen.Color := clHighlight;
      Image1.Canvas.Pen.Width := 3;
      InflateRect(r, -1, -1); { Compensate for pen width }
    end
    else
      Image1.Canvas.Pen.Width := 0;

    Image1.Canvas.Rectangle(r);
    { Draw text - adjust rect for display }
    InflateRect(r, -2, -2);

    Image1.Canvas.Pen.Width := 0;

    if Screen.Monitors[i].Primary then
      Image1.Canvas.Font.Style := [fsBold]
    else
      Image1.Canvas.Font.Style := [];

    s := Format('Monitor %d'#13#10'%d x %d', [
      1+Screen.Monitors[i].MonitorNum,
      Screen.Monitors[i].Width,
      Screen.Monitors[i].Height]);

    r2 := r;
    DrawText(Image1.Canvas.Handle, PChar(s), -1, r2,
      DT_CENTER or DT_VCENTER or DT_CALCRECT);

    { Center r2 in r }
    r.Top := r.Top + ((r.Bottom-r.Top) - (r2.Bottom-r2.Top)) div 2;
    r.Bottom := r.Top + (r2.Bottom-r2.Top);

    DrawText(Image1.Canvas.Handle, PChar(s), -1, r,
      DT_CENTER or DT_VCENTER);

    { Indicate focused list by framing the text with a focus rect }
    if FMonitorIconsFocused and (FSelectedMonitor = i) then
      Image1.Canvas.DrawFocusRect(r);

  end;
end;

function TForm1.SelectMonitor(X, Y: Integer): Integer;
var
  i: Integer;
  r: TRect;
begin
  result := -1;
  for i := 0 to Screen.MonitorCount-1 do
  begin
    GetMonitorIconRect(i, r);
    if PtInRect(r, Point(X, Y)) then
    begin
      result := Screen.Monitors[i].MonitorNum;
    end;
  end;
end;

{ Retrieves the bounding rectangle of the icons used to represent the
  monitor with a given index. Rectangle is relative to Image1's canvas.
  Returns True if index is valid, False otherwise. }
function TForm1.GetMonitorIconRect(Index: Integer; var ARect: TRect): Boolean;
begin
  result := False;
  if (Index >= 0) and (Index < Screen.MonitorCount) then
  begin
    result := True;
    ARect := Screen.Monitors[Index].BoundsRect;
    { Scale rectangle }
    ARect.Left := ARect.Left div SCALENUMBER;
    ARect.Top := ARect.Top div SCALENUMBER;
    ARect.Right := ARect.Right div SCALENUMBER;
    ARect.Bottom := ARect.Bottom div SCALENUMBER;
    { Shift rectangle down and to the right }
    OffsetRect(ARect, +5, +5);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  shfi: SHFILEINFO;
  pidlDesk: PItemIDList;
  pMalloc: IMalloc;
begin
  { Move FocusPanel offscreen since it's only purpose is to manage the
    keyboard focus for Image1 which can't receive focus and we hide it
    since this will discriminate it as a focus target. }
  FocusPanel.Left := -FocusPanel.Width;
  FocusPanel.Top := -FocusPanel.Height;

  FSelectedMonitor := Monitor.MonitorNum;
  FMonitorIconsFocused := False;

  DrawMonitors;

  { Set image list for FileLV to the System Image List }
  SHGetMalloc(pMalloc);
  SHGetSpecialFolderLocation(Handle, CSIDL_DESKTOP, pidlDesk);
  FileLV.SmallImages := TImageList.Create(nil);
  FileLV.SmallImages.Handle := SHGetFileInfo(PChar(pidlDesk), 0,
    shfi, sizeof(SHFILEINFO),
    SHGFI_PIDL or SHGFI_ICON or SHGFI_SMALLICON or SHGFI_SYSICONINDEX);
  pMalloc.Free(pidlDesk);
end;

procedure TForm1.AddBtnClick(Sender: TObject);
var
  i: Integer;
  item: TListItem;
  shfi: SHFILEINFO;
begin
  if OpPictureDlg.Execute then
  begin
    for i := 0 to OpPictureDlg.Files.Count-1 do
    begin
      item := FileLV.Items.Add;
      item.Caption := OpPictureDlg.Files[i];
      SHGetFileInfo(PChar(OpPictureDlg.Files[i]), 0,
        shfi, sizeof(SHFILEINFO),
        SHGFI_ICON or SHGFI_SMALLICON or SHGFI_SYSICONINDEX);
      item.ImageIndex := shfi.iIcon;
    end;
  end;
end;

procedure TForm1.RemoveBtnClick(Sender: TObject);
begin
  FileLV.DeleteSelected;
end;

procedure TForm1.FileLVDeletion(Sender: TObject; Item: TListItem);
var
  e: Boolean;
begin
  e := (FileLV.Items.Count-1) > 0;
  MakeBtn.Enabled := e;
  RemoveBtn.Enabled := e;
  MoveUpBtn.Enabled := e;
  MoveDownBtn.Enabled := e;
end;

procedure TForm1.FileLVInsert(Sender: TObject; Item: TListItem);
var
  e: Boolean;
begin
  e := FileLV.Items.Count > 0;
  MakeBtn.Enabled := e;
  RemoveBtn.Enabled := e;
  MoveUpBtn.Enabled := e;
  MoveDownBtn.Enabled := e;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if mbLeft = Button then
  begin
    FSelectedMonitor := SelectMonitor(X, Y);
    DrawMonitors; { Update display }
  end;
end;

{ This OnContextPopup event handler manages mouse access to the
  context menu for monitor icons. }
procedure TForm1.Image1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  index: Integer;
begin
  Handled := True;
  index := SelectMonitor(MousePos.X, MousePos.Y);
  if index >= 0 then
  begin
    Handled := False;
    FSelectedMonitor := index;
    DrawMonitors;
  end;
end;

{ This OnContextPopup event handler manages keyboard access to the
  context menu for monitor icons. }
procedure TForm1.FormContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  r: TRect;
begin
  if (MousePos.X < 0) and (MousePos.Y < 0) then
  begin
    if GetMonitorIconRect(FSelectedMonitor, r) then
    begin
      Handled := True;
      r.TopLeft := Image1.ClientToScreen(r.TopLeft);
      { Call Popup manually since Form1.PopupMenu is nil, and
        it is more cumbersome to set PopupMenu to PopupMenu1 as
        this will require more code in this handler procedure to
        prevent the popup from appearing when user right-clicks
        anywhere on the form. }
      PopupMenu1.Popup(r.Left, r.Top);
    end;
  end;
end;

procedure TForm1.DetailedInfoMIClick(Sender: TObject);
begin
  with Screen.Monitors[FSelectedMonitor] do
  ShowMessageFmt(SDetailInfo, [WorkareaRect.Left, WorkareaRect.Top, WorkareaRect.Right, WorkareaRect.Bottom]);
end;

{ Since Image1 (TImage) is a non-windowed control and thus' cannot receive
  keyboard focus, we must simulate this by using a Panel that will act
  as a step-in for this purpose. }
procedure TForm1.FocusPanelEnter(Sender: TObject);
begin
  { Using the FMonitorIconsFocused boolean variable we manage the
    foucus state. }
  FMonitorIconsFocused := True;
  DrawMonitors;
end;

procedure TForm1.FocusPanelExit(Sender: TObject);
begin
  FMonitorIconsFocused := False;
  DrawMonitors;
end;

procedure TForm1.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  Handled := False;
  if FMonitorIconsFocused then
  begin
    Handled := True;
    case Msg.CharCode of
      VK_LEFT, VK_UP:
        if (FSelectedMonitor) > 0 then
          Dec(FSelectedMonitor);
      VK_RIGHT, VK_DOWN:
        if (FSelectedMonitor+1) < Screen.MonitorCount then
          Inc(FSelectedMonitor);
    else Handled := False;
    end;
    if Handled then DrawMonitors;
  end;
end;

procedure TForm1.Image1DblClick(Sender: TObject);
begin
   if (FSelectedMonitor >= 0) and (FSelectedMonitor < Screen.MonitorCount) then
   begin
     ReleaseCapture(); { Need to call this to prevent lost selection }
     DetailedInfoMI.Click;
   end;
end;

procedure TForm1.FileLVSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  e: Boolean;
begin
  e := FileLV.SelCount > 0;
  MoveDownBtn.Enabled := e;
  MoveUpBtn.Enabled := e;
  RemoveBtn.Enabled := e;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FocusPanel.SetFocus;
end;

procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta < WHEEL_DELTA then
    Inc(SCALENUMBER)
  else if WheelDelta >= WHEEL_DELTA then
    Dec(SCALENUMBER);
  DrawMonitors;
end;

procedure TForm1.MakeBtnClick(Sender: TObject);
var
  bm: TBitmap;
  tmp: TBitmap;
  fbm: TJPEGImage;
  i: Integer;
  reg: TRegistry;
begin
  if not SavePicDlg.Execute then Exit;

  bm := TBitmap.Create;
  bm.Width := Screen.DesktopWidth;
  bm.Height := Screen.DesktopHeight;
  bm.PixelFormat := pf32bit;

  { Load image }
  fbm := TJPEGImage.Create;
  for i := 0 to Screen.MonitorCount-1 do
  begin
    tmp := TBitmap.Create;

    fbm.LoadFromFile(FileLV.Items[i].Caption);
    tmp.Assign(fbm);

    bm.Canvas.CopyRect(Screen.Monitors[i].BoundsRect, tmp.Canvas,
      tmp.Canvas.ClipRect);

    tmp.Destroy;
  end;
  fbm.Destroy;

  bm.SaveToFile(SavePicDlg.FileName);

  bm.Destroy;

  { First we need to set the right style. }
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  reg.OpenKey('Control Panel\Desktop', True);
  reg.WriteString('WallpaperStyle', '0');
  reg.WriteString('TileWallpaper', '1');
  reg.CloseKey;
  reg.Destroy;

  { Now do the SPI_SETDESKWALLPAPER call. }
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(SavePicDlg.FileName),
    SPIF_UPDATEINIFILE or SPIF_SENDCHANGE);
end;

{ Owner-draw stuff }

procedure TForm1.MIAdvancedDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; State: TOwnerDrawState);
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
    if (odSelected in State) and (mi.Enabled) then
    begin
      Pen.Color := RGB(49,105,198);
      Brush.Color := RGB(198,211,239);
      Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    end;

    if mi.IsLine then
    begin
      MoveTo(ARect.Left+25, ARect.Top+(ARect.Bottom-ARect.Top) div 2);
      LineTo(ARect.Right, PenPos.Y);
      Exit; {return;}
    end;

    { Adjust rect for the glyph, and move it a bit if selected }
    r.Left := ARect.Left+4;
    r.Top := ARect.Top+3;
    if mi.Enabled and ((odSelected in State) or mi.Checked) then
      InflateRect(r, +1, +1);


    { Draw glyph from associated ImageList/Bitmap }
    if ((mi.ImageIndex >= 0) and (mi.GetImageList <> nil))
       or (not mi.Bitmap.Empty) then
    begin
      if mi.Checked then
      begin
        Pen.Color := RGB(49,105,198);
        Brush.Color := RGB(198,211,239);
        Rectangle(ARect.Left+1, ARect.Top+1, ARect.Left-1+22, ARect.Bottom-1);
      end;
      { Draw glyph stored in Bitmap property... }
      if not mi.Bitmap.Empty then
        Draw(r.Left, r.Top, mi.Bitmap)
      else
        mi.GetImageList.Draw(ACanvas, r.Left, r.Top, mi.ImageIndex, mi.Enabled);
    end;

    if mi.Checked and (mi.ImageIndex < 0) then
    begin
      bm := TBitmap.Create;
      bm.Handle := LoadBitmap(0, PChar(OBM_CHECK));
      Pen.Color := RGB(49,105,198);
      Brush.Color := RGB(198,211,239);
      Rectangle(ARect.Left+1, ARect.Top+1, ARect.Left-1+22, ARect.Bottom-1);
      Draw(ARect.Left+5, ARect.Top+3, bm);
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

procedure TForm1.MIMeasureItem(Sender: TObject;
  ACanvas: TCanvas; var Width, Height: Integer);
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
