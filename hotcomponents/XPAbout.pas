unit XPAbout;

(* XPAbout component; written by Saivert; http://saivert.webhop.net *)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, jpeg, Buttons, Registry, ExtCtrls;

function ShellExec(ownerwnd: THandle; action, target, param, workdir: PChar; showcmd: Integer): HINST; stdcall; external 'shell32.dll' name 'ShellExecuteA';

type
  TXPAboutForm = class(TForm)
    ClientPanel: TPanel;
    LblProductName: TLabel;
    LblVersion: TLabel;
    LblCopyright: TLabel;
    HomepageLabel: TLabel;
    ImgAppIcon: TImage;
    LblOSVerStr: TLabel;
    LblPhysMem: TLabel;
    LblMemLoad: TLabel;
    B2: TBevel;
    LblMoreInfo: TLabel;
    AboutOKBtn: TButton;
    HeaderPanel: TPanel;
    B1: TBevel;
    AboutImage: TImage;
    FunTimer: TTimer;
    procedure HomepageLabelMouseEnter(Sender: TObject);
    procedure HomepageLabelMouseLeave(Sender: TObject);
    procedure HomepageLabelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FunTimerTimer(Sender: TObject);
    procedure ImgAppIconClick(Sender: TObject);
  private
  public
    { Public declarations }
  end;

  TXPAbout = class(TComponent)
  private
    FTitle,
    FVersion,
    FProductName,
    FHomepageURL,
    FCopyright: string;
    FShowHeader,
    FAutoVersion: Boolean;
    FPicture: TPicture;
    FMoreInformation: TStrings;
    FShowEvent,
    FHideEvent: TNotifyEvent;
    procedure SetPicture(const Value: TPicture);
    procedure SetMoreInformation(const Value: TStrings);
    procedure SetShowHeader(newstate: Boolean);
    procedure SetAutoVersion(newstate: Boolean);
  protected
  public
    Dialog: TXPAboutForm;

    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;

    function Execute: TModalResult;
    procedure Dismiss;
  published
    property Title: string read FTitle write FTitle;
{ If AutoVersion is set to True, Version is ignored. }
    property AutoVersion: Boolean read FAutoVersion write SetAutoVersion;
    property Version: string read FVersion write FVersion;
    property Copyright: string read FCopyright write FCopyright;
    property ProductName: string read FProductName write FProductName;
    property MoreInformation: TStrings read FMoreInformation write SetMoreInformation;
    property HomepageURL: string read FHomepageURL write FHomepageURL;
    property HeaderLogo: TPicture read FPicture write SetPicture;
    property ShowHeader: Boolean read FShowHeader write SetShowHeader;
    property OnShow: TNotifyEvent read FShowEvent write FShowEvent;
    property OnHide: TNotifyEvent read FHideEvent write FHideEvent;
  end;

implementation

{$R *.dfm}

function GetFileVerStr(var verstr: String): Boolean;
var
  vfs: Cardinal;
  vip, vp: Pointer;
  vl: Cardinal;
begin
  result := False;
  vfs := GetFileVersionInfoSize(PChar(ParamStr(0)), vl);
  if vfs > 0 then
  begin
    GetMem(vip, vfs+1);
    if GetFileVersionInfo(PChar(ParamStr(0)), 0, vfs, vip) then
      if VerQueryValue(vip, '\', vp, vl) then
      begin
        with PVSFixedFileInfo(vp)^ do
          verstr := Format('Version: %d.%d.%d.%d',
          [Byte(dwFileVersionMS shr 16), Byte(dwFileVersionMS shr 32),
          Byte(dwFileVersionLS shr 16), Byte(dwFileVersionLS shr 32)]);
        result := True;
      end;
    FreeMem(vip, vfs+1);
  end;
end;

function GetOSString: string;
var
  OSPlatform: string;
  BuildNumber: Integer;
begin
  Result := 'Unknown Windows Version';
  OSPlatform := 'Microsoft Windows ';
  BuildNumber := Win32BuildNumber;

  case Win32Platform of
    VER_PLATFORM_WIN32_WINDOWS:
      begin
        BuildNumber := Win32BuildNumber and $0000FFFF;
        case Win32MinorVersion of
          0..9:
            begin
              if Trim(Win32CSDVersion) = 'B' then
                OSPlatform := OSPlatform + '95 OSR2'
              else
                OSPlatform := OSPlatform + '95';
            end;
          10..89:
            begin
              if Trim(Win32CSDVersion) = 'A' then
                OSPlatform := OSPlatform + '98'
              else
                OSPlatform := OSPlatform + '98 SE';
            end;
          90:
            OSPlatform := OSPlatform + 'Me';
        end;
      end;
    VER_PLATFORM_WIN32_NT:
      begin
        if Win32MajorVersion in [3, 4] then
          OSPlatform := OSPlatform + 'NT'
        else if Win32MajorVersion = 5 then
        begin
          case Win32MinorVersion of
            0: OSPlatform := OSPlatform + '2000';
            1: OSPlatform := OSPlatform + 'XP';
          end;
        end;
      end;
  end;
  if (Win32Platform = VER_PLATFORM_WIN32_WINDOWS) or
    (Win32Platform = VER_PLATFORM_WIN32_NT) then
  begin
    if Trim(Win32CSDVersion) = '' then
      Result := Format('%s %d.%d (Build %d)', [OSPlatform, Win32MajorVersion,
        Win32MinorVersion, BuildNumber])
    else
      Result := Format('%s %d.%d (Build %d: %s)', [OSPlatform, Win32MajorVersion,
        Win32MinorVersion, BuildNumber, Win32CSDVersion]);
  end
  else if Win32Platform = VER_PLATFORM_WIN32s then
    Result := Format('%s %d.%d (w/Win32s)', [OSPlatform, Win32MajorVersion, Win32MinorVersion])
  else
    Result := Format('%s %d.%d', [OSPlatform, Win32MajorVersion, Win32MinorVersion])
end;

(*** TXPAboutForm ***)

procedure TXPAboutForm.HomepageLabelMouseEnter(Sender: TObject);
begin
  (Sender As TLabel).Font.Style := (Sender As TLabel).Font.Style + [fsUnderline];
end;

procedure TXPAboutForm.HomepageLabelMouseLeave(Sender: TObject);
begin
  (Sender As TLabel).Font.Style := (Sender As TLabel).Font.Style - [fsUnderline];
end;

procedure TXPAboutForm.HomepageLabelClick(Sender: TObject);
begin
  ShellExec(Application.Handle, 'open', PChar(HomepageLabel.Caption), nil, nil, SW_SHOWNORMAL);
end;

procedure TXPAboutForm.FormCreate(Sender: TObject);
var
  memInfo : TMemoryStatus;
begin
  Screen.Cursors[154] := LoadCursor(0, IDC_HAND);
  HomepageLabel.Cursor := 154;

  LblProductName.Caption := Application.Title;

  if Assigned (Application.Icon) then
    ImgAppIcon.Picture.Icon := Application.Icon;

  LblOSVerStr.Caption := LblOSVerStr.Caption + GetOSString;
  memInfo.dwLength := sizeof(TMemoryStatus);
  GlobalMemoryStatus (memInfo);
  LblPhysMem.Caption := Format(LblPhysMem.Caption,
  [memInfo.dwAvailPhys / 1024, memInfo.dwTotalPhys / 1024]);
  LblMemLoad.Caption := LblMemLoad.Caption +
    Format ('%3d %%', [memInfo.dwMemoryLoad]);
end;

(*** TXPAbout component ***)

constructor TXPAbout.Create(Owner: TComponent);
begin
  inherited;
  FTitle := 'About';
  FAutoVersion := True;
  FPicture := TPicture.Create;
  FMoreInformation := TStringList.Create;
end;

destructor TXPAbout.Destroy;
begin
//  Dialog.Destroy;
  FMoreInformation.Destroy;
  FPicture.Destroy;
  inherited;
end;

function TXPAbout.Execute: TModalResult;
var
  tmps: string;
begin
  Dialog := TXPAboutForm.Create(Self);
  try
    if Assigned(OnShow) then OnShow(Self);

    with Dialog do
    begin
      if Title <> '' then Caption := Title;
      if ProductName <> '' then LblProductName.Caption := ProductName;
      if Copyright <> '' then LblCopyright.Caption := Copyright;
      if Assigned(MoreInformation) then LblMoreInfo.Caption := MoreInformation.Text;
      if Version <> '' then LblVersion.Caption := Version
      else begin
        if GetFileVerStr(tmps) and AutoVersion then
          LblVersion.Caption := tmps;
      end;
      HeaderPanel.Visible := ShowHeader;
      if HomepageURL <> '' then HomepageLabel.Caption := HomepageURL;
      if Assigned(HeaderLogo) then AboutImage.Picture.Assign(HeaderLogo);
    end;

    result := Dialog.ShowModal;
    if Assigned(OnHide) then OnHide(Self);
  finally
    Dialog.Free
  end
end;

procedure TXPAbout.Dismiss;
begin
  if Assigned(Dialog) then Dialog.Close;
end;

procedure TXPAbout.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
  FShowHeader := Assigned(Value);
end;

procedure TXPAbout.SetMoreInformation(const Value: TStrings);
begin
  FMoreInformation.Assign(Value);
end;

procedure TXPAbout.SetShowHeader(newstate: Boolean);
begin
  if newstate <> FShowHeader then
    FShowHeader := newstate;
end;

procedure TXPAbout.SetAutoVersion(newstate: Boolean);
begin
  if newstate <> FAutoVersion then
    FAutoVersion := newstate;
end;

procedure TXPAboutForm.FunTimerTimer(Sender: TObject);
begin
  if FunTimer.Tag = 0 then
  begin
    ImgAppIcon.Top := ImgAppIcon.Top + (4+Random(4));
    if ImgAppIcon.Top >= 40 then
      FunTimer.Tag := 1;

  end else begin
    ImgAppIcon.Top := ImgAppIcon.Top - (4+Random(4));
    if ImgAppIcon.Top <= 8 then
      FunTimer.Tag := 0;
  end;

  if ImgAppIcon.Tag = 0 then
  begin
    ImgAppIcon.Left := ImgAppIcon.Left + (4+Random(8));
    if ImgAppIcon.Left >= 360 then
      ImgAppIcon.Tag := 1;

  end else begin
    ImgAppIcon.Left := ImgAppIcon.Left - (4+Random(8));
    if ImgAppIcon.Left <= 232 then
      ImgAppIcon.Tag := 0;
  end;
end;

procedure TXPAboutForm.ImgAppIconClick(Sender: TObject);
begin
  FunTimer.Enabled := True;
end;

end.
