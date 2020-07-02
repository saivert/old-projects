unit NxSXPMainMenu;

interface

uses
  SysUtils, Windows, Classes, Menus, Graphics;

type
  TNxSXPMenuItem = class;

  TNxSXPMainMenu = class(TMainMenu)
  private
    FItems: TNxSXPMenuItem;
  protected
  public
    constructor Create(AOwner: TComponent); override; 
  published
    property Items: TNxSXPMenuItem read FItems;
  end;

  TNxSXPMenuItem = class(TMenuItem)
  private
  protected
    procedure MeasureProc(Sender: TObject; ACanvas: TCanvas; var Width,
      Height: Integer);
    procedure AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      State: TOwnerDrawState; TopLevel: Boolean); reintroduce;
  public
  published
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Hot Components', [TNxSXPMainMenu]);
end;

constructor TNxSXPMainMenu.Create(AOwner: TComponent);
begin
  inherited;
  FItems := TNxSXPMenuItem.Create(Self);
end;

procedure TNxSXPMenuItem.AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      State: TOwnerDrawState; TopLevel: Boolean);
var
  mi: TMenuItem;
  r: TRect;
  bm: TBitmap;
begin
  mi := Sender as TMenuItem;

  if TopLevel then
  begin
    with ACanvas do
    begin
      Brush.Color := clMenuBar;
      Windows.CopyRect(r, ARect);
      FillRect(r);
      if (odSelected in State) or (odHotLight in State) then
      begin
        Pen.Color := RGB(49,105,198);
        Brush.Color := RGB(198,211,239);
        Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
      end;

      { Draw menu item text }

      r.Left := ARect.Left + 5;

      Brush.Color := clMenu;
      SetBkMode(Handle, TRANSPARENT);
      if odSelected in State then
        SetBkColor(Handle, RGB(198,211,239))
      else
        SetBkColor(Handle, GetSysColor(COLOR_WINDOW));
      Font.Color := clMenuText;
      if odNoAccel in State then
      DrawText(Handle, PChar(StripHotkey(mi.Caption)), -1, r, DT_SINGLELINE or DT_VCENTER)
      else
      DrawText(Handle, PChar(mi.Caption), -1, r, DT_SINGLELINE or DT_VCENTER);

    end;

  end
  else begin

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
        PenPos := Point(ARect.Left+25, ARect.Top+(ARect.Bottom-ARect.Top) div 2);
        LineTo(ARect.Right, PenPos.Y);
        Exit; {return;}
      end;

      { Adjust rect for the glyph, and move it a bit if selected }
      r.Left := ARect.Left+3;
      r.Top := ARect.Top+2;
      if (odSelected in State) and (mi.Enabled) then
        InflateRect(r, +1, +1);


      { Draw glyph stored in Bitmap property... }
      if not mi.Checked and Assigned(mi.Bitmap) then
      begin
        Draw(r.Left, r.Top, mi.Bitmap);
      end;

      { ...or draw glyph from associated ImageList }
      { Note: You must fix this when using this code in other places. }
      if not mi.Checked and (mi.ImageIndex >= 0) and
        (GetImageList <> nil) then
      begin
        GetImageList.Draw(ACanvas, r.Left, r.Top, mi.ImageIndex, mi.Enabled);
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
end;

procedure TNxSXPMenuItem.MeasureProc(Sender: TObject; ACanvas: TCanvas; var Width,
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
