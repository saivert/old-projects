unit frmAlert;
(* Timer Alert *)

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  XPAbout, StdCtrls, ComCtrls, ExtCtrls, Menus, NxSTray, jpeg,
  ShellApi, commdlg, Graphics, ImgList;

const
  WM_APPBARMSG = WM_USER + 4;

type
  TForm1 = class(TForm)
    AlertTimeGroupBox: TGroupBox;
    TimePicker: TDateTimePicker;
    NowBtn: TButton;
    AlertMsgGroupBox: TGroupBox;
    StartBtn: TButton;
    AboutBtn: TButton;
    XPA: TXPAbout;
    CheckTimer: TTimer;
    QuickSelections: TComboBox;
    TrayMenu: TPopupMenu;
    ShowHideMI: TMenuItem;
    ExitMI: TMenuItem;
    AboutMI: TMenuItem;
    N1: TMenuItem;
    NxSTray1: TNxSTray;
    RunAppGroupBox: TGroupBox;
    AppEdit: TEdit;
    BrowseAppButton: TButton;
    StartMI: TMenuItem;
    MessageTypesCB: TComboBox;
    DispMsgLabel: TLabel;
    MsgRE: TMemo;
    ParamsEdit: TEdit;
    ParamsLabel: TLabel;
    ImageList1: TImageList;
    procedure AboutBtnClick(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure NowBtnClick(Sender: TObject);
    procedure CheckTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure QuickSelectionsChange(Sender: TObject);
    procedure ExitMIClick(Sender: TObject);
    procedure ShowHideMIClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure NxSTray1LButtonDblClick(Sender: TObject);
    procedure BrowseAppButtonClick(Sender: TObject);
    procedure DrawSidebarProc(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      State: TOwnerDrawState);
    procedure MeasureSidebarProc(Sender: TObject; ACanvas: TCanvas;
      var Width, Height: Integer);
    procedure FormShow(Sender: TObject);


  private
    sidebarimage: TBitmap;

    procedure QuickSelectMIClick(Sender: TObject);
    procedure OnAppMsg(var Msg: TMsg; var Handled: Boolean);
    procedure OnWMSysCommand(var msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure OnAppBarMsg(var msg: TMessage); message WM_APPBARMSG;

    function GetMenuHeight(ACanvas: TCanvas): Integer;

  protected
    procedure CreateParams(var Params: TCreateParams); override;

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses DateUtils, IniFiles;

resourcestring
  _SAppTitleFmt = '%s - Alert timer';
  _SAppTitle = 'Alert timer';
  _STimerTriggered = 'Timer has elapsed';
  _SStart = '&Start';
  _SStop = 'Sto&p';
  _SShow = '&Show';
  _SHide = '&Hide';

var
  SAppTitleFmt: string = _SAppTitleFmt;
  SAppTitle: string = _SAppTitle;
  STimerTriggered: string = _STimerTriggered;
  SStart: string = _SStart;
  SStop: string = _SStop;
  SShow: string = _SShow;
  SHide: string = _SHide;

const
  { Do not localize }
  SIniSection = 'Alert timer';
  SIniSectionMsg = 'Alert message';
  CountIdent = 'Count';

var
  AlertTime: TDateTime;
  qsmistart: Integer;

procedure FindAndLoadLanguageFile;
var
  cur_lcid, sys_lcid: Integer;
  ini: TIniFile;
  basepath, tmps: string;
  sr: TSearchRec;
  i: Integer;
begin
  sys_lcid := GetSystemDefaultLCID();
  basepath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  { Find and load a language file }
  if FindFirst(basepath + '*.lng', 0, sr) = 0 then
  repeat
    ini := TIniFile.Create(basepath + sr.Name);
    cur_lcid := ini.ReadInteger('LanguageFile', 'LangCode', 0);
    if (cur_lcid > 0) and (cur_lcid = sys_lcid) then
    begin
      { An appropriate language file was found.
        Let's get the localized strings. }

      with Form1 do
      begin
        NowBtn.Caption := ini.ReadString('MainForm', NowBtn.Name, NowBtn.Caption);
        AlertTimeGroupBox.Caption := ini.ReadString('MainForm', AlertTimeGroupBox.Name, AlertTimeGroupBox.Caption);
        DispMsgLabel.Caption := ini.ReadString('MainForm', DispMsgLabel.Name, DispMsgLabel.Caption);
        RunAppGroupBox.Caption := ini.ReadString('MainForm', RunAppGroupBox.Name, RunAppGroupBox.Caption);
        AlertMsgGroupBox.Caption := ini.ReadString('MainForm', AlertMsgGroupBox.Name, AlertMsgGroupBox.Caption);
        AboutBtn.Caption := ini.ReadString('MainForm', AboutBtn.Name, AboutBtn.Caption);

        StartBtn.Caption := ini.ReadString('Strings', 'SStart', _SStart);

        ParamsLabel.Caption := ini.ReadString('MainForm', ParamsLabel.Name, ParamsLabel.Caption);

        { Read menu items in system tray popup menu }
        AboutMI.Caption := AboutBtn.Caption; //it's the same
        ExitMI.Caption := ini.ReadString('Strings', 'SExit', '&Exit');
        StartMI.Caption := ini.ReadString('Strings', 'SStart', _SStart);

      end;

      { Read combo box items }
      { Fill QuickSelections with items }
      if ini.SectionExists('QuickSelections') then
      begin
        Form1.QuickSelections.Clear;
        i := 0;
        repeat
          tmps := Format('Item%d', [i]);
          if ini.ValueExists('QuickSelections', tmps) then
            Form1.QuickSelections.Items.Add(ini.ReadString('QuickSelections', tmps, ''));
          Inc(i);
        until not ini.ValueExists('QuickSelections', tmps);
      end;

      { Fill MessageTypeCB with items }
      if ini.SectionExists('MessageTypes') then
      begin
        Form1.MessageTypesCB.Clear;
        i := 0;
        repeat
          tmps := Format('Item%d', [i]);
          if ini.ValueExists('MessageTypes', tmps) then
            Form1.MessageTypesCB.Items.Add(ini.ReadString('MessageTypes', tmps, ''));
          Inc(i);
        until not ini.ValueExists('MessageTypes', tmps);
      end;

      { Now get the generic strings }
      SAppTitleFmt := ini.ReadString('Strings', 'SAppTitleFmt', _SAppTitleFmt);
      SAppTitle := ini.ReadString('Strings', 'SAppTitle', _SAppTitle);
      STimerTriggered := ini.ReadString('Strings', 'STimerTriggered', _STimerTriggered);
      SStart := ini.ReadString('Strings', 'SStart', _SStart);
      SStop := ini.ReadString('Strings', 'SStop', _SStop);
      SShow := ini.ReadString('Strings', 'SShow', _SShow);
      SHide := ini.ReadString('Strings', 'SHide', _SHide);

      { Get credits for the translator }
      Form1.XPA.MoreInformation.Add('Translated by '+
      ini.ReadString('LanguageFile', 'Author', 'John Doe')+' to '+
      ini.ReadString('LanguageFile', 'LangName', 'N/A')+#13#10+
      'E-Mail: '+ini.ReadString('LanguageFile', 'EMail', 'N/A')+#13#10+
      'Homepage: '+ini.ReadString('LanguageFile', 'Homepage', 'N/A'));

    end;
    ini.Destroy;
  until FindNext(sr) <> 0;
  FindClose(sr);
end;

procedure ShowAlertMsg(msg: string);
begin
  Application.MessageBox(PChar(msg), PChar(SAppTitle), 64 or MB_SYSTEMMODAL)
end;

{ Need to override CreateParams to specify custom class name for Window }
procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  { Need to change WinClassName to a somewhat unique name, so we can
    use FindWindow on it in the installer. }
  StrPLCopy(Params.WinClassName, 'NxSAlertTimerApplication', 63);
end;

{ Need to handle the same message in two places }
{ Here... }
procedure TForm1.OnAppMsg(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_SYSCOMMAND then
    if Msg.wParam = ($FFF0 and SC_MINIMIZE) then
    begin
      ShowHideMI.Click;
      Handled := True;
    end;
end;
{ ...and here }
procedure TForm1.OnWMSysCommand(var msg: TWMSysCommand);
begin
  if msg.CmdType = ($FFF0 and SC_MINIMIZE) then
    ShowHideMI.Click
  else inherited;
end;
{ That's what I call redundant programming. Too cumbersome! }

procedure TForm1.AboutBtnClick(Sender: TObject);
begin
  XPA.Execute;
end;

procedure TForm1.StartClick(Sender: TObject);
begin
  StartBtn.OnClick := StopClick;
  StartBtn.Caption := SStop;
  StartMI.Caption := SStop;
  StartMI.OnClick := StopClick;
  case QuickSelections.ItemIndex of
    0: AlertTime := IncMinute(Now, 5);
    1: AlertTime := IncMinute(Now, 10);
    2: AlertTime := IncMinute(Now, 15);
    3: AlertTime := IncSecond(Now, 10);
    4: AlertTime := IncHour(Now);
    5: AlertTime := IncDay(Now);
    6: begin
      if TimePicker.DateTime <= Now then
        AlertTime := IncDay(TimePicker.DateTime)
      else
        AlertTime := TimePicker.DateTime;
    end;
  end;
  if QuickSelections.ItemIndex <> 6 then
    TimePicker.DateTime := AlertTime;
  CheckTimer.Enabled := True;

  { Hide the app }
  Form1.Hide;
  ShowHideMI.Caption := SShow;
  NxSTray1.Animate := True;
end;

procedure TForm1.StopClick(Sender: TObject);
begin
  StartBtn.OnClick := StartClick;
  StartBtn.Caption := SStart;
  StartMI.Caption := SStart;
  StartMI.OnClick := StartClick;

  CheckTimer.Enabled := False;
  Caption := SAppTitle;
  Application.Title := Caption;
  NxSTray1.Hint := Caption;
  NxSTray1.Animate := False;
  NxSTray1.IconIndex := 0;
end;

procedure TForm1.NowBtnClick(Sender: TObject);
begin
  TimePicker.DateTime := Now;
end;

procedure TForm1.CheckTimerTimer(Sender: TObject);
var
  s: string;
begin
  Application.Title := Format(SAppTitleFmt, [TimeToStr(AlertTime - Now)]);
  Caption := Application.Title;
  NxSTray1.Hint := Application.Title;
  if CompareDateTime(AlertTime, Now) = -1 then
  begin

    if Length(MsgRE.Text) > 0 then
      s := MsgRE.Text          { user message }
    else s := STimerTriggered; { or default }
    StartBtn.Click;

    { Launch application }
    if Length(AppEdit.Text) > 0 then
    begin
      ShellExecute(Handle, 'open', PChar(AppEdit.Text), PChar(ParamsEdit.Text),
        nil, SW_SHOWNORMAL);
    end;

    { Alert the user }
    case MessageTypesCB.ItemIndex of
    0: ShowAlertMsg(s);
    1: NxSTray1.ShowBalloon(s, SAppTitle);
    else ShowAlertMsg(s);
    end;

  end;
end;

procedure TForm1.QuickSelectMIClick(Sender: TObject);
begin
  QuickSelections.ItemIndex := (Sender as TMenuItem).MenuIndex - qsmistart;
  StartBtn.Click;
  StartBtn.Enabled := True;
end;

procedure TForm1.OnAppBarMsg(var msg: TMessage);
var
  abd: TAppBarData;
begin
  if msg.WParam = ABN_POSCHANGED then
  begin
    { Get the taskbar position }
    abd.cbSize := sizeof(TAppBarData);
    abd.hWnd := Handle;
    SHAppBarMessage(ABM_GETTASKBARPOS, abd);
    { Position the window near the taskbar }
    case abd.uEdge of
      ABE_BOTTOM: begin
        Top := abd.rc.Top - Height - 10;
        Left := abd.rc.Right - Width - 10;
      end;
      ABE_TOP: begin
        Top := abd.rc.Bottom + 10;
        Left := abd.rc.Right - Width - 10;
      end;
      ABE_LEFT: begin
        Top := abd.rc.Bottom - Height - 10;
        Left := abd.rc.Right + 10;
      end;
      ABE_RIGHT: begin
        Top := abd.rc.Bottom - Height - 10;
        Left := abd.rc.Left - Width - 10;
      end;
    end;
  end;
  inherited;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, y: Integer;
  item: TMenuItem;
  AKey: string;
  abd: TAppBarData;

  imgfn: string;
begin
  Application.OnMessage := OnAppMsg;
  FindAndLoadLanguageFile;
  { Create and load the sidebar image for the menu }
  imgfn := ExtractFilePath(ParamStr(0)) + 'menusidebar.bmp';
  if FileExists(imgfn) then
  begin
    sidebarimage := TBitmap.Create;
    sidebarimage.LoadFromFile(imgfn);
  end else
    MessageBox(0, 'Sidebar image not found!', 'Error', MB_ICONERROR);

  if SameText(ParamStr(1), '/h') then
    ShowHideMI.Caption := SShow
  else
    ShowHideMI.Caption := SHide;
    
  TimePicker.DateTime := Now;

  for i := 0 to QuickSelections.Items.Count-2 do
  begin
    item := TMenuItem.Create(TrayMenu);
    item.Caption := QuickSelections.Items[i];
    item.OnClick := QuickSelectMIClick;
    item.OnAdvancedDrawItem := DrawSidebarProc;
    item.OnMeasureItem := MeasureSidebarProc;
    TrayMenu.Items.Insert(ShowHideMI.MenuIndex+1+i, item);
  end;
  qsmistart := TrayMenu.Items.InsertNewLineAfter(ShowHideMI);
  TrayMenu.Items[qsmistart-1].OnMeasureItem := MeasureSidebarProc;
  TrayMenu.Items[qsmistart-1].OnAdvancedDrawItem := DrawSidebarProc;

  with TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
  begin
    y := 0;
    MsgRE.Clear;
    repeat
      AKey := Format('Line%d', [y]);
      if ValueExists(SIniSectionMsg, AKey) then
        MsgRE.Lines.Add(ReadString(SIniSectionMsg, AKey, ''));
      Inc(y);
    until not ValueExists(SIniSectionMsg, AKey);

    QuickSelections.ItemIndex := ReadInteger(SIniSection, 'QSItemIndex', -1);
    TimePicker.Enabled := QuickSelections.ItemIndex = 6;
    NowBtn.Enabled := QuickSelections.ItemIndex = 6;
    StartBtn.Enabled := (QuickSelections.ItemIndex <> -1);

    MessageTypesCB.ItemIndex := ReadInteger(SIniSection, 'MessageType', 0);

    Width := ReadInteger(SIniSection, 'Width', 342);
    Height := ReadInteger(SIniSection, 'Height', 271);
    AppEdit.Text := ReadString(SIniSection, 'App', '');
    ParamsEdit.Text := ReadString(SIniSection, 'AppParams', '');
  end;

  { Get the taskbar position }
  abd.cbSize := sizeof(TAppBarData);
  abd.hWnd := Handle;
  abd.uCallbackMessage := WM_APPBARMSG;

  { Register with the appbar services to get notifications }
  SHAppBarMessage(ABM_NEW, abd);

  SHAppBarMessage(ABM_GETTASKBARPOS, abd);
  { Position the window near the taskbar }
  case abd.uEdge of
    ABE_BOTTOM: begin
      Top := abd.rc.Top - Height - 10;
      Left := abd.rc.Right - Width - 10;
    end;
    ABE_TOP: begin
      Top := abd.rc.Bottom + 10;
      Left := abd.rc.Right - Width - 10;
    end;
    ABE_LEFT: begin
      Top := abd.rc.Bottom - Height - 10;
      Left := abd.rc.Right + 10;
    end;
    ABE_RIGHT: begin
      Top := abd.rc.Bottom - Height - 10;
      Left := abd.rc.Left - Width - 10;
    end;
  end;

end;

procedure TForm1.QuickSelectionsChange(Sender: TObject);
begin
  NowBtn.Click;
  NowBtn.Enabled := False;
  StartBtn.Enabled := True;
  with TimePicker do
  begin
    Enabled := False;
    case QuickSelections.ItemIndex of
      0: DateTime := IncMinute(DateTime, 5);
      1: DateTime := IncMinute(DateTime, 10);
      2: DateTime := IncMinute(DateTime, 15);
      3: DateTime := IncSecond(DateTime, 10);
      4: DateTime := IncHour(DateTime);
      5: DateTime := IncDay(DateTime);
      6: begin
        Enabled := True;
        SetFocus;
        NowBtn.Enabled := True;
      end
    end;
  end;
end;

procedure TForm1.ExitMIClick(Sender: TObject);
begin
  Close
end;

procedure TForm1.ShowHideMIClick(Sender: TObject);
begin
  if not Form1.Visible then
  begin
    ShowHideMI.Caption := SHide;
    Show; Application.BringToFront;
  end
  else begin
    ShowHideMI.Caption := SShow;
    Hide;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;
  abd: TAppBarData;
begin
  with TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
  begin
    EraseSection(SIniSectionMsg);
    for i := 0 to MsgRE.Lines.Count - 1 do
    begin
      WriteString(SIniSectionMsg, Format('Line%d', [i]), MsgRE.Lines[i]);
    end;

    WriteInteger(SIniSection, 'QSItemIndex', QuickSelections.ItemIndex);
    WriteInteger(SIniSection, 'MessageType', MessageTypesCB.ItemIndex);

    WriteInteger(SIniSection, 'Width', Width);
    WriteInteger(SIniSection, 'Height', Height);
    WriteString(SIniSection, 'App', AppEdit.Text);
    WriteString(SIniSection, 'AppParams', ParamsEdit.Text);
  end;

  { Unregister with the appbar services }
  abd.cbSize := sizeof(TAppBarData);
  abd.hWnd := Handle;
  SHAppBarMessage(ABM_REMOVE, abd);

end;

procedure TForm1.NxSTray1LButtonDblClick(Sender: TObject);
begin
  ShowHideMI.Click
end;

procedure TForm1.BrowseAppButtonClick(Sender: TObject);
var
  opf: OPENFILENAME;
  s: PChar;
begin
  s := StrAlloc(MAX_PATH);

  if FileExists(AppEdit.Text) then
    StrPLCopy(s, AppEdit.Text, MAX_PATH)
  else s[0] := #0;

  FillChar(opf, sizeof(OPENFILENAME), 0);
  opf.lStructSize := sizeof(OPENFILENAME);
  opf.lpstrFilter :=
    'Programs (*.exe)'#0'*.exe'#0+
    'Batch files (*.bat,*.cmd)'#0'*.bat;*.cmd'#0+
    'WSH Script files (*.vbs,*.js)'#0'*.vbs;*.js'#0+
    'All files'#0'*.*'#0;
  opf.nFilterIndex := 1;
  opf.lpstrFile := s;
  opf.lpstrTitle := 'Open application';
  opf.nMaxFile := MAX_PATH;
  opf.lpstrDefExt := 'exe';
  opf.hWndOwner := Handle;
  opf.hInstance := HInstance;
  opf.Flags := OFN_EXPLORER or OFN_FILEMUSTEXIST;

  if GetOpenFileName(opf) then
    AppEdit.Text := s;

  StrDispose(s);
end;

function TForm1.GetMenuHeight(ACanvas: TCanvas): Integer;
var
  i, w, h: Integer;
begin
  result := 0;
  for i := 0 to TrayMenu.Items.Count-1 do
  begin
    MeasureSidebarProc(TrayMenu.Items[i], ACanvas, w, h);
    result := result + h;
  end;
end;

{ Draw menu with sidebar image. }
procedure TForm1.DrawSidebarProc(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  State: TOwnerDrawState);
var
  mi: TMenuItem;
  r: TRect;
  bm: TBitmap;
  menuheight: Integer;
begin
  mi := Sender as TMenuItem;

  with ACanvas do
  begin
    Brush.Color := clWindow;
    FillRect(ARect);

    Brush.Color := clBtnFace;
    Windows.CopyRect(r, ARect);
    r.Right := 22+22;
    FillRect(r);
    if (odSelected in State) and (mi.Enabled) then
    begin
      Pen.Color := RGB(49,105,198);
      Brush.Color := RGB(198,211,239);
      Rectangle(ARect.Left+22, ARect.Top, ARect.Right, ARect.Bottom);
    end;

    { Draw sidebar image }
    menuheight := GetMenuHeight(ACanvas);
    { Draw background (surface not covered by sidebar image) }
    r.Top := 0;
    r.Left := 0;
    r.Right := 22;
    r.Bottom := menuheight-sidebarimage.Height;
    Brush.Color := sidebarimage.TransparentColor;
    FillRect(r);
    { Draw sidebar image at the bottom left of menu }
    r.Top := menuheight-sidebarimage.Height;
    r.Bottom := menuheight;
    CopyRect(r, sidebarimage.Canvas, sidebarimage.Canvas.ClipRect);

    
    if mi.IsLine then
    begin
      PenPos := Point(ARect.Left+25+25, ARect.Top+(ARect.Bottom-ARect.Top) div 2);
      LineTo(ARect.Right, PenPos.Y);
      Exit; {return;}
    end;

    { Adjust rect for the glyph, and move it a bit if selected }
    r.Left := 22+ARect.Left+3;
    r.Top := ARect.Top+2;
    if (odSelected in State) and (mi.Enabled) then
      InflateRect(r, +1, +1);

    Brush.Color := RGB(198,211,239); {Set the brush for subsequent operations}

    { Draw glyph stored in Bitmap property... }
    if not mi.Checked and Assigned(mi.Bitmap) then
    begin
      Draw(r.Left, r.Top, mi.Bitmap);
    end;

    { ...or draw glyph from associated ImageList }
    { Note: You must fix this when using this code in other places. }
    if not mi.Checked and (mi.ImageIndex >= 0) and
      (mi.GetImageList <> nil) then
    begin

      mi.GetImageList.Draw(ACanvas, r.Left, r.Top, mi.ImageIndex, mi.Enabled);
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
    r.Left := 22+25;
    InflateRect(r, -2, -2);

    if (odSelected in State) and mi.Enabled then
      SetBkColor(Handle, RGB(198,211,239))
    else
      SetBkColor(Handle, GetSysColor(COLOR_WINDOW));
    if mi.Enabled then
      Font.Color := clMenuText
    else
      Font.Color := clGrayText;
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

procedure TForm1.MeasureSidebarProc(Sender: TObject; ACanvas: TCanvas;
  var Width, Height: Integer);
var
  mi: TMenuItem;
begin
  mi := Sender As TMenuItem;
  if mi.IsLine then
    Height := 3
  else
  begin
    Width := ACanvas.TextWidth(mi.Caption)+25+25;
    Height := ACanvas.TextHeight(mi.Caption)+8;

    {Support menu items with shortcuts}
    if mi.ShortCut <> 0 then
      Width := Width + ACanvas.TextWidth( ShortcutToText(mi.ShortCut) ) + 25;

  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if QuickSelections.ItemIndex = 6 then
    TimePicker.SetFocus;
end;

end.
