unit frmPMAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ShellApi, ExtCtrls, Menus, Inifiles;

type
  TAboutForm = class(TForm)
    BitBtn1: TBitBtn;
    URLLabel: TLabel;
    Image1: TImage;
    Label5: TLabel;
    ThePM: TPopupMenu;
    GB1: TGroupBox;
    GB2: TGroupBox;
    procedure URLLabelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure AboutPopupMenuMIDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure AboutPopupMenuMIMeasureItem(Sender: TObject;
      ACanvas: TCanvas; var Width, Height: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure AboutPopupMenuMIClick(Sender: TObject);
    procedure TheItemsClickHandler(Sender: TObject);
    procedure LnkLblEnter(Sender: TObject);
    procedure LnkLblLeave(Sender: TObject);
  private
    MIarray: array of TMenuItem;
    datafile: string;

    procedure DrawProc(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      State: TOwnerDrawState);
    procedure MeasureProc(Sender: TObject; ACanvas: TCanvas; var Width,
      Height: Integer);

  public
    procedure LoadItemData(datafile: String);
    procedure FreeItemData;
    procedure HandleItem(item: Integer; otheraction: string = '');
  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.dfm}

uses urlmon;

const
  StrNA = 'N/A';

resourcestring
  RstInvaldAction = 'Invalid action specified for Item %d.';
  RstInvalidNumItems = 'ItemCount is lareger than actual number of Item sections.';

procedure TAboutForm.URLLabelClick(Sender: TObject);
var
  s: array[0..256] of WideChar;
begin
  MultiByteToWideChar(CP_ACP, 0, PChar(URLLabel.Caption), -1, s, sizeof(s));
  HlinkNavigateString(nil, s);
end;

procedure TAboutForm.FormCreate(Sender: TObject);
begin

  if ParamCount >= 1 then
  begin
    LoadItemData(ParamStr(1));
    BringToFront;
    if ParamCount >= 2 then
      ThePM.Popup(StrToInt(ParamStr(2)), StrToInt(ParamStr(3)))
    else
      ThePM.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);

    Application.Terminate;
  end;

  { Borland's default crHandPoint cursor is a custom one
    stored in the VCL's binaries. Here I load the official
    IDC_HAND cursor from Windows effectively overriding the
    old one. Maybe Borland updates their code in the future?? }
  Screen.Cursors[crHandPoint] := LoadCursor(0, IDC_HAND);
  Image1.Picture.Icon.Assign(Application.Icon);


  { Setting Position property to poScreenCenter centers it on the primary
    monitor only if it's the main form of an application so we need to
    adjust it here. Thus poDesigned must be set or this will be ignored.
    The code simply determines the current foreground window (usually the app,
    that starts this app) and uses the monitor that window is on.}
  with Screen.MonitorFromWindow(GetForegroundWindow) do
  begin
    AboutForm.Left := Left + (Width - AboutForm.Width) div 2;
    AboutForm.Top := Top + (Height - AboutForm.Height) div 2;
  end;

end;

procedure TAboutForm.Label5Click(Sender: TObject);
begin
  ShellExecute(Handle, 'edit', PChar(ExtractFilePath(ParamStr(0)) + '\usage.txt'), nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutForm.LoadItemData(datafile: String);
var
  ti: TIniFile;
  ic, i: Integer;
begin
  if not FileExists(datafile) then exit;
  Self.datafile := datafile;
  FreeItemData;
  ti := TIniFile.Create(datafile);

  ic := ti.ReadInteger('Menu', 'ItemCount', 0);
  SetLength(MIarray, ic);
  for i := 0 to ic-1 do
  begin
    MIarray[i] := TMenuItem.Create(ThePM);
    MIarray[i].Caption := ti.ReadString(Format('Item %d', [i]), 'Text', StrNA);
    MIarray[i].OnClick := TheItemsClickHandler;
    MIarray[i].OnAdvancedDrawItem := DrawProc;
    MIarray[i].OnMeasureItem := MeasureProc;
  end;
  ThePM.Items.Add(MIarray);
  ti.Destroy;
end;

function GetMsgBoxFlags(str: string): Integer;
begin
  result := 0;
  if Pos('MB_ICONINFORMATION', str) > 0 then result := MB_ICONINFORMATION;
  if Pos('MB_ICONWARNING',     str) > 0 then result := result or MB_ICONWARNING;
  if Pos('MB_ICONERROR',       str) > 0 then result := result or MB_ICONERROR;
  if Pos('MB_ICONQUESTION',    str) > 0 then result := result or MB_ICONQUESTION;
  if Pos('MB_OK',              str) > 0 then result := result or MB_OK;
  if Pos('MB_YESNO',           str) > 0 then result := result or MB_YESNO;
  if Pos('MB_YESNOCANCEL',     str) > 0 then result := result or MB_YESNOCANCEL;
end;

procedure TAboutForm.HandleItem(item: Integer; otheraction: string = '');
var
  ti: TIniFile;
  midx: Integer;
  msgboxflags: Integer;
  action: string;
  params: array of string;
  szFile: array[0..MAX_PATH+1] of Char;
  szParams: array[0..MAX_PATH+1] of Char;
begin
  ti := TIniFile.Create(datafile);
  midx := item;
  if Length(otheraction) = 0 then
  action := ti.ReadString(Format('Item %d', [midx]), 'Action', StrNA)
  else action := otheraction;
  if action = StrNA then
    ShowMessageFmt(RstInvaldAction, [midx]);
  if (CompareText(action, 'Execute') = 0) then
  begin
    SetLength(params, 4);
    params[0] := ti.ReadString(Format('Item %d', [midx]), 'Operation', EmptyStr);
    params[1] := ti.ReadString(Format('Item %d', [midx]), 'File', StrNA);
    params[2] := ti.ReadString(Format('Item %d', [midx]), 'Params', EmptyStr);
    params[3] := ti.ReadString(Format('Item %d', [midx]), 'WorkDir', EmptyStr);
    ExpandEnvironmentStrings(PChar(params[1]), szFile, 1024);
    ExpandEnvironmentStrings(PChar(params[2]), szParams, 1024);

    if not FileExists(szFile) then
    //I'm typecasting to string to get a copy of it (like strdup in C).
      StrFmt(szFile, '%s%s', [ExtractFilePath(ParamStr(1)), string(szFile)]);

    ShellExecute(Handle, PChar(params[0]), szFile, szParams, PChar(params[3]), SW_SHOWNORMAL);
  end else if (CompareText(action, 'Link') = 0) then
  begin
    SetLength(params, 1);
    params[0] := ti.ReadString(Format('Item %d', [midx]), 'URL', EmptyStr);
    StrPCopy(szFile, params[0]);
    ShellExecute(Handle, 'open', szFile, nil, nil, SW_SHOWNORMAL);
  end else if (CompareText(action, 'RunCPL') = 0) then
  begin
    SetLength(params, 2);
    params[0] := ti.ReadString(Format('Item %d', [midx]), 'CPlFile', EmptyStr);
    params[1] := ti.ReadString(Format('Item %d', [midx]), 'Params', StrNA);
    ExpandEnvironmentStrings(PChar(params[0]), szFile, 1024);

    if not FileExists(szFile) then
      StrFmt(szFile, '%s%s', [ExtractFilePath(ParamStr(1)), string(szFile)]);

    StrPCopy(szParams, 'shell32.dll,Control_RunDLL "'+szFile+'" '+params[1]);
    ShellExecute(Handle, 'open', 'rundll32.exe', szParams, nil, SW_SHOWNORMAL);
  end else if (CompareText(action, 'MsgBox') = 0) then
  begin
    SetLength(params, 4);
    params[0] := ti.ReadString(Format('Item %d', [midx]), 'MsgText', '{No message text was defined!}');
    params[1] := ti.ReadString(Format('Item %d', [midx]), 'MsgTitle', '{No message title was defined!}');
    params[2] := ti.ReadString(Format('Item %d', [midx]), 'MsgAction', StrNA);
    params[3] := UpperCase( ti.ReadString(Format('Item %d', [midx]), 'Flags', 'MB_OK|MB_ICONINFORMATION') );
    msgboxflags := GetMsgBoxFlags(params[3]);

    if MessageBox(GetForegroundWindow, PChar(params[0]), PChar(params[1]), msgboxflags) in [IDOK, IDYES] then
      { Call own function to handle other action. }
      HandleItem(midx, params[2]);
  end;

  SetLength(params, 0);
  ti.Destroy;
end;

procedure TAboutForm.TheItemsClickHandler(Sender: TObject);
var
  mi: TMenuItem;
  midx: Integer;
begin
  if not (Sender is TMenuItem) then exit;
  mi := (Sender as TMenuItem);
  midx := mi.MenuIndex;
  HandleItem(midx);
  Close;
end;

procedure TAboutForm.FreeItemData;
begin
  if Length(MIarray) = 0 then exit;
  SetLength(MIarray, 0);
end;

procedure TAboutForm.AboutPopupMenuMIDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
  with ACanvas do
  begin
    Font.Color := clHotlight;
    DrawText(Handle, PChar( (Sender As TMenuItem).Caption ),
      Length( (Sender As TMenuItem).Caption ), ARect,
      DT_SINGLELINE or DT_TOP or DT_CENTER);
    Pen.Color := clRed;
    Pen.Mode := pmNot;
    MoveTo(0, ARect.Bottom - 3);
    LineTo(ARect.Right, ARect.Bottom - 3);
  end;
end;

procedure TAboutForm.AboutPopupMenuMIMeasureItem(Sender: TObject;
  ACanvas: TCanvas; var Width, Height: Integer);
begin
  Width := ACanvas.TextWidth((Sender As TMenuItem).Caption) + 10;
  Height := ACanvas.TextHeight((Sender As TMenuItem).Caption) + 5;
end;

procedure TAboutForm.FormDestroy(Sender: TObject);
begin
  FreeItemData;
end;

procedure TAboutForm.AboutPopupMenuMIClick(Sender: TObject);
begin
  Show;
end;

procedure TAboutForm.LnkLblEnter(Sender: TObject);
begin
  if Sender is TLabel then
    TLabel(Sender).Font.Style := TLabel(Sender).Font.Style + [fsUnderline];
end;

procedure TAboutForm.LnkLblLeave(Sender: TObject);
begin
  if Sender is TLabel then
    TLabel(Sender).Font.Style := TLabel(Sender).Font.Style - [fsUnderline];
end;

{ Owner-draw procedures }
{ Copy and paste into your code editor, after having set up the event handlers. }

procedure TAboutForm.MeasureProc(Sender: TObject; ACanvas: TCanvas; var Width,
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

procedure TAboutForm.DrawProc(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  State: TOwnerDrawState);
var
  mi: TMenuItem;
  r: TRect;
  bm: TBitmap;

  function RemoveMnemonics(input: string): string;
  var
    i: Integer;
  begin
    i := 1;
    while i <= Length(input) do
    begin
      if (input[i] <> '&') then
        result := result + input[i];
      Inc(i);
    end;
  end;
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
      Exit; {return;}
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
      Assigned(ThePM.Images) then
    begin
      ThePM.Images.Draw(ACanvas, r.Left, r.Top, mi.ImageIndex);
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
    Font.Color := clMenuText;
    if odNoAccel in State then
      DrawText(Handle, PChar(RemoveMnemonics(mi.Caption)), -1, r,
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


end.
