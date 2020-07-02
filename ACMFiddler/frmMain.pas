unit frmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    DriverLB: TListBox;
    DriverListLbl: TLabel;
    EnumDriversBtn: TButton;
    InfoMemo: TMemo;
    FormatLB: TListBox;
    FormatsLbl: TLabel;
    DriverInfoLbl: TLabel;
    SplitterPanel: TPanel;
    FormatTagLB: TListBox;
    FormatTagsLbl: TLabel;
    FormatHC: THeaderControl;
    FormatTagHC: THeaderControl;
    procedure EnumDriversBtnClick(Sender: TObject);
    procedure DriverLBClick(Sender: TObject);
    procedure SplitterPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SplitterPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SplitterPanelMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure FormatTagLBClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DriverLBDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormatTagLBDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormatTagHCSectionResize(HeaderControl: THeaderControl;
      Section: THeaderSection);
    procedure FormatHCSectionResize(HeaderControl: THeaderControl;
      Section: THeaderSection);
  private
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses MMSystem;

{ BEGIN OF MSACM.H DEFINITIONS }
type
  HACMDRIVERID = THandle;
  HACMDRIVER   = THandle;

const
  ACMDRIVERDETAILS_SHORTNAME_CHARS    = 32;
  ACMDRIVERDETAILS_LONGNAME_CHARS     = 128;
  ACMDRIVERDETAILS_COPYRIGHT_CHARS    = 80;
  ACMDRIVERDETAILS_LICENSING_CHARS    = 128;
  ACMDRIVERDETAILS_FEATURES_CHARS     = 512;

type
  _ACMDRIVERDETAILS = record
    cbStruct: DWORD;
    fccType: FOURCC;
    fccComp: FOURCC;
    wMid: WORD;
    wPid: WORD;
    vdwACM: DWORD;
    vdwDriver: DWORD;
    fdwSupport: DWORD;
    cFormatTags: DWORD;
    cFilterTags: DWORD;
    hicon: HICON;
    szShortName: array[0..ACMDRIVERDETAILS_SHORTNAME_CHARS-1] of Char;
    szLongName: array[0..ACMDRIVERDETAILS_LONGNAME_CHARS-1] of Char;
    szCopyright: array[0..ACMDRIVERDETAILS_COPYRIGHT_CHARS-1] of Char;
    szLicensing: array[0..ACMDRIVERDETAILS_LICENSING_CHARS-1] of Char;
    szFeatures: array[0..ACMDRIVERDETAILS_FEATURES_CHARS-1] of Char;
  end;
  TACMDriverDetails = _ACMDRIVERDETAILS;
  PACMDriverDetails = ^TACMDriverDetails;

const
  ACMFORMATTAGDETAILS_FORMATTAG_CHARS = 48;

  ACM_FORMATTAGDETAILSF_INDEX         = $00000000;
  ACM_FORMATTAGDETAILSF_FORMATTAG     = $00000001;
  ACM_FORMATTAGDETAILSF_LARGESTSIZE   = $00000002;
  ACM_FORMATTAGDETAILSF_QUERYMASK     = $0000000F;

  ACMFORMATDETAILS_FORMAT_CHARS       = 128;

  ACM_FORMATDETAILSF_INDEX            = $00000000;
  ACM_FORMATDETAILSF_FORMAT           = $00000001;
  ACM_FORMATDETAILSF_QUERYMASK        = $0000000F;

type
  PACMFormatTagDetails = ^TACMFormatTagDetails;
  TACMFormatTagDetails = record
    cbStruct: DWORD;
    dwFormatTagIndex: DWORD;
    dwFormatTag: DWORD;
    cbFormatSize: DWORD;
    fdwSupport: DWORD;
    cStandardFormats: DWORD;
    szFormatTag: array[0..ACMFORMATTAGDETAILS_FORMATTAG_CHARS-1] of Char;
  end;

type
  PACMFormatDetails = ^TACMFormatDetails;
  TACMFormatDetails = record
    cbStruct: DWORD;
    dwFormatIndex: DWORD;
    dwFormatTag: DWORD;
    fdwSupport: DWORD;
    pwfx: PWAVEFORMATEX;
    cbwfx: DWORD;
    szFormat: array[0..ACMFORMATDETAILS_FORMAT_CHARS-1] of Char;
  end;

const
  ACM_FORMATENUMF_WFORMATTAG       = $00010000;
  ACM_FORMATENUMF_NCHANNELS        = $00020000;
  ACM_FORMATENUMF_NSAMPLESPERSEC   = $00040000;
  ACM_FORMATENUMF_WBITSPERSAMPLE   = $00080000;
  ACM_FORMATENUMF_CONVERT          = $00100000;
  ACM_FORMATENUMF_SUGGEST          = $00200000;
  ACM_FORMATENUMF_HARDWARE         = $00400000;
  ACM_FORMATENUMF_INPUT            = $00800000;
  ACM_FORMATENUMF_OUTPUT           = $01000000;

type
  ACMDRIVERENUMCB = function(hadid: HACMDRIVERID; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
  ACMFORMATTAGENUMCB = function(hadid: HACMDRIVERID; var paftd: TACMFormatTagDetails; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
  ACMFORMATENUMCB = function(hadid: HACMDRIVERID; var pafd: TACMFormatDetails; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;



{ ACM functions }
function acmGetVersion: DWORD; stdcall; external 'msacm32.dll';
{ ACM Driver functions }
function acmDriverOpen(var phad: HACMDRIVER; hadid: HACMDRIVERID; fdwOpen: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmDriverOpen';
function acmDriverClose(had: HACMDRIVER; fdwClose: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmDriverClose';
function acmDriverEnum(fnCallback: ACMDRIVERENUMCB; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmDriverEnum';
function acmDriverDetails(hadid: HACMDRIVERID; var padd: TACMDriverDetails; fdwDetails: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmDriverDetailsA';
{ Format tag functions }
function acmFormatTagEnum(had: HACMDRIVER; var paftd: TACMFormatTagDetails; fnCallback: ACMFORMATTAGENUMCB; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmFormatTagEnumA';
function acmFormatTagDetails(had: HACMDRIVER; var paftd: TACMFormatTagDetails; fdwDetails: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmFormatTagDetailsA';
{ Format functions }
function acmFormatEnum(had: HACMDRIVER; var pafd: TACMFormatDetails; fnCallback: ACMFORMATENUMCB; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmFormatEnumA';
function acmFormatDetails(had: HACMDRIVER; var pafd: TACMFormatDetails; fdwDetails: DWORD): MMRESULT; stdcall; external 'msacm32.dll' name 'acmFormatDetailsA';

{ Format choose dialog }
const
  ACMFORMATCHOOSE_STYLEF_SHOWHELP              = $00000004;
  ACMFORMATCHOOSE_STYLEF_ENABLEHOOK            = $00000008;
  ACMFORMATCHOOSE_STYLEF_ENABLETEMPLATE        = $00000010;
  ACMFORMATCHOOSE_STYLEF_ENABLETEMPLATEHANDLE  = $00000020;
  ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT       = $00000040;
  ACMFORMATCHOOSE_STYLEF_CONTEXTHELP           = $00000080;


type
  ACMFORMATCHOOSEHOOKPROC = function(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
  PACMFormatChoose = ^TACMFormatChoose;
  TACMFormatChoose = record
    cbStruct: DWORD;           // sizeof(ACMFILTERCHOOSE)
    fdwStyle: DWORD;           // chooser style flags

    hwndOwner: HWND;           // caller's window handle

    pwfx: PWaveFormatEx;       // ptr to wfltr buf to receive choice
    cbwfx: DWORD;              // size of mem buf for pwfltr

    pszTitle: LPCSTR;

    szFormatTag: array[0..ACMFORMATTAGDETAILS_FORMATTAG_CHARS-1] of Char;
    szFilter: array[0..ACMFORMATDETAILS_FORMAT_CHARS-1] of Char;
    pszName: LPSTR;            // custom name selection
    cchName: DWORD;            // size in chars of mem buf for pszName

    fdwEnum: DWORD;            // filter enumeration restrictions
    pwfxEnum: PWaveFormatEx;   // filter describing restrictions

    hInstance: HINST;          // app instance containing dlg template
    pszTemplateName: LPCSTR;   // custom template name
    lCustData: LPARAM;         // data passed to hook fn.
    pfnHook: ACMFORMATCHOOSEHOOKPROC; // ptr to hook function
    end;

function acmFormatChoose(var pafltrc: TACMFormatChoose): MMRESULT; stdcall; external 'msacm32.dll' name 'acmFormatChooseA';


{ ACM filter definitions }
const
  ACMFILTERTAGDETAILS_FILTERTAG_CHARS = 48;
  ACMFILTERDETAILS_FILTER_CHARS       = 128;

type
  PWaveFilter = ^TWaveFilter;
  TWaveFilter = record
    cbStruct: DWORD;
    dwFilterTag: DWORD;
    fdwFilter: DWORD;
    dwReserved: array[0..5-1] of DWORD;
  end;


{ END OF MSACM.H DEFINITIONS }

function MyEnumProc(hadid: HACMDRIVERID; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
var
  s: string;
  d: PACMDriverDetails;
begin
  New(d);
  d^.cbStruct := sizeof(TACMDriverDetails);
  acmDriverDetails(hadid, d^, 0);

  s := Format('%s (%s)', [d^.szLongName, d^.szShortName]);

  Form1.DriverLB.AddItem(s, TObject(hadid));
  result := TRUE;
end;


function MyFormatTagCallback(hadid: HACMDRIVERID; var paftd: TACMFormatTagDetails; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
var
  tmp: PACMFormatTagDetails;
begin
  result := TRUE;
  GetMem(tmp, paftd.cbStruct);
  Move(paftd, tmp^, paftd.cbStruct);
  Form1.FormatTagLB.AddItem(
    Format('%s '#9'(ID=%d; Index=%d; Size=%d)', [paftd.szFormatTag, paftd.dwFormatTag, paftd.dwFormatTagIndex, paftd.cbFormatSize]),
    TObject(tmp)
  );
end;

function MyFormatCallback(hadid: HACMDRIVERID; var pafd: TACMFormatDetails; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
begin
  result := TRUE;

  Form1.FormatLB.Items.Append(
    Format('%s'#9'(ID=%d; Index=%d)', [pafd.szFormat, pafd.dwFormatTag, pafd.dwFormatIndex])
  );
end;

procedure TForm1.EnumDriversBtnClick(Sender: TObject);
begin
  DriverLB.Clear;
  FormatTagLB.Clear;
  FormatLB.Clear;
  acmDriverEnum(MyEnumProc, 0, 0);
end;

procedure TForm1.DriverLBClick(Sender: TObject);
var
  d: TACMDriverDetails;
  aftd: TACMFormatTagDetails;
  had: HACMDRIVER;
  hadid: HACMDRIVERID;
begin
  FillChar(d, sizeof(TACMDriverDetails), 0);
  d.cbStruct := sizeof(TACMDriverDetails);
  acmDriverDetails(HACMDRIVERID(DriverLB.Items.Objects[DriverLB.ItemIndex]), d, 0);
  InfoMemo.Clear;
  InfoMemo.Lines.Append(d.szFeatures);
  InfoMemo.Lines.Append(d.szCopyright);
  InfoMemo.Lines.Append(d.szLicensing);


  FormatTagLB.Clear;
  hadid := HACMDRIVERID(DriverLB.Items.Objects[DriverLB.ItemIndex]);

  FillChar(aftd, sizeof(TACMFormatTagDetails), 0);
  aftd.cbStruct := sizeof(TACMFormatTagDetails);

  acmDriverOpen(had, hadid, 0);
  acmFormatTagEnum(had, aftd, MyFormatTagCallback, 0, 0);
  acmDriverClose(had, 0);

end;

procedure TForm1.SplitterPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SplitterPanel.BevelOuter := bvRaised;
  SplitterPanel.BringToFront;
  SetCapture(SplitterPanel.Handle);
end;

procedure TForm1.SplitterPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  pos: Integer;
begin
  ReleaseCapture;

  pos := SplitterPanel.Left;

  { Resize and move controls }
  DriverLB.Width := pos-DriverLB.Left;
  EnumDriversBtn.Left := pos-EnumDriversBtn.Width;
  DriverListLbl.Width := DriverLB.Width-EnumDriversBtn.Width;
  InfoMemo.Width := pos-InfoMemo.Left;
  DriverInfoLbl.Width := InfoMemo.Width;
  { Format tags section }
  FormatTagLB.Left := pos + SplitterPanel.Width;
  FormatTagLB.Width := ClientWidth-FormatTagLB.Left-8;
  FormatTagsLbl.Left := FormatTagLB.Left;
  FormatTagsLbl.Width := FormatTagLB.Width;
  FormatTagHC.Left := FormatTagLB.Left;
  FormatTagHC.Width := FormatTagLB.Width;
  { Formats section }
  FormatLB.Left := pos + SplitterPanel.Width;
  FormatLB.Width := ClientWidth-FormatLB.Left-8;
  FormatsLbl.Left := FormatLB.Left;
  FormatsLbl.Width := FormatLB.Width;
  FormatHC.Left := FormatLB.Left;
  FormatHC.Width := FormatLB.Width;


  SplitterPanel.BevelOuter := bvNone;

end;

procedure TForm1.SplitterPanelMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  pos: Integer;
begin
  if GetCapture = SplitterPanel.Handle then
  begin
    pos := ScreenToClient(Mouse.CursorPos).X - 3;
    if pos > ClientWidth-50 then pos := ClientWidth-SplitterPanel.Width;
    if pos < 50 then pos := 0;
    SplitterPanel.Left := pos;
  end;
end;

procedure TForm1.FormatTagLBClick(Sender: TObject);
var
  afd: TACMFormatDetails;
  had: HACMDRIVER;
  hadid: HACMDRIVERID;
  wfx: TWaveFormatEx;
  paftd: PACMFormatTagDetails;
begin
  { Dont bother if no selection }
  if FormatTagLB.ItemIndex < 0 then Exit;

  FormatLB.Clear;
  hadid := HACMDRIVERID(DriverLB.Items.Objects[DriverLB.ItemIndex]);
  paftd := PACMFormatTagDetails(FormatTagLB.Items.Objects[FormatTagLB.ItemIndex]);

  { Initialize a TWaveFormatEx record }
  FillChar(wfx, sizeof(TWaveFormatEx), 0);
  wfx.wFormatTag := paftd^.dwFormatTag;

  { Initialize a TACMFormatDetails record }
  FillChar(afd, sizeof(TACMFormatDetails), 0);
  afd.cbStruct := sizeof(TACMFormatDetails);
  afd.dwFormatTag := paftd^.dwFormatTag;
  afd.pwfx := @wfx;
  afd.cbwfx := paftd^.cbFormatSize;

  acmDriverOpen(had, hadid, 0);
  acmFormatEnum(had, afd, MyFormatCallback, 0, 0);
  acmDriverClose(had, 0);

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  EnumDriversBtn.Click;
end;

procedure TForm1.DriverLBDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  d: TACMDriverDetails;
begin
  FillChar(d, sizeof(TACMDriverDetails), 0);
  d.cbStruct := sizeof(TACMDriverDetails);
  acmDriverDetails(HACMDRIVERID(DriverLB.Items.Objects[Index]), d, 0);
  with Control as TListBox do
  begin
    Canvas.FillRect(Rect);
    if d.hicon > 0 then
    begin
      DrawIconEx(Canvas.Handle, Rect.Left+2, Rect.Top+2, d.hicon, 16, 16,
        0, Canvas.Brush.Handle, 0);
    end;
    Rect.Left := 20;
    DrawText(Canvas.Handle, PChar(Items[Index]), -1, Rect,
      DT_SINGLELINE or DT_VCENTER);
  end;
end;

procedure TForm1.FormatTagLBDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  first, last: string;
  i: Integer;
  r: TRect;
begin
  with Control as TListBox do
  begin
    i := Pos(#9, Items[Index]);
    first := Copy(Items[Index], 1, i-1);
    last := Copy(Items[Index], i+1, Length(Items[Index])-i);

    Canvas.FillRect(Rect);
    r := Rect;
    if Control = FormatTagLB then
      r.Right := Rect.Left + FormatTagHC.Sections[0].Width
    else if Control = FormatLB then
      r.Right := Rect.Left + FormatHC.Sections[0].Width;
    DrawText(Canvas.Handle, PChar(first), -1, r, DT_LEFT or DT_SINGLELINE or DT_END_ELLIPSIS);

    { Draw last part depending on header section position }
    r := Rect;
    if Control = FormatTagLB then
    begin
      r.Left := Rect.Left+FormatTagHC.Sections[0].Width;
      r.Right := r.Left + FormatTagHC.Sections[1].Width;
      DrawText(Canvas.Handle, PChar(last), -1, r, DT_LEFT or DT_SINGLELINE or DT_END_ELLIPSIS);
    end
    else if Control = FormatLB then
    begin
      r.Left := Rect.Left+FormatHC.Sections[0].Width;
      r.Right := r.Left + FormatHC.Sections[1].Width;
      DrawText(Canvas.Handle, PChar(last), -1, r, DT_LEFT or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;
  end;
end;

procedure TForm1.FormatTagHCSectionResize(HeaderControl: THeaderControl;
  Section: THeaderSection);
begin
  FormatTagLB.Repaint;
end;

procedure TForm1.FormatHCSectionResize(HeaderControl: THeaderControl;
  Section: THeaderSection);
begin
  FormatLB.Repaint;
end;

end.
