unit NxSFormResizeGrid;

{ Form resize granularity component
  Have you ever resized windows which sticks to
  every 10th pixel so you cant get a size inbetween.
  This component makes your form behave the same.
  Just drop it onto a form and select the Horizontal and
  vertical granularity (grid size).

  Written by Saivert
  Homepage -> http://members.tripod.com/files_saivert/
}

interface

uses
  SysUtils, Classes, Forms, Windows, Messages;

type
  TNxSFormResizeGrid = class(TComponent)
  private
    FOldWndMethod: TWndMethod;
    FHorzSize: Integer;
    FVertSize: Integer;
    FEnabled: Boolean;
    {new}
    FMoveGranularity: Boolean;
  protected
    procedure NewWndMethod(var msg: TMessage);
    function isClose(a: Integer; b: Integer): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property HorzSize: Integer read FHorzSize write FHorzSize default 20;
    property VertSize: Integer read FVertSize write FVertSize default 20;
    property MoveGranularity: Boolean read FMoveGranularity write FMoveGranularity default False;
  end;

implementation


constructor TNxSFormResizeGrid.Create(AOwner: TComponent);
begin
  inherited;
  FEnabled := True;
  FHorzSize := 20;
  FVertSize := 20;
  FMoveGranularity := False;
//  if not (csDesigning in ComponentState) then
// Works fine in design mode too, so why not?!...
  begin
    FOldWndMethod := TCustomForm(AOwner).WindowProc;
    TCustomForm(AOwner).WindowProc := NewWndMethod;
  end;
end;

destructor TNxSFormResizeGrid.Destroy;
begin
  inherited;
end;

var
  sSnapCX, sSnapCY: Integer;

function TNxSFormResizeGrid.isClose(a: Integer; b: Integer): Boolean;
begin
  result := Abs(a-b) <= FVertSize;
end;

procedure TNxSFormResizeGrid.NewWndMethod(var msg: TMessage);
var
  curpos: TPoint;
  _rect: TRect;
  rect_ptr: PRect;
begin
  if FEnabled and (msg.Msg = WM_SIZING) then
  with PRect(msg.LParam)^{lprc} do
  begin
    if (msg.WParam{fwSide} = WMSZ_TOP) or
       (msg.WParam = WMSZ_TOPLEFT) or
       (msg.WParam = WMSZ_TOPRIGHT) then
      if Top > Top - (Top mod FVertSize) then Top := Top - (Top mod FVertSize);

    if (msg.WParam = WMSZ_LEFT) or
       (msg.WParam = WMSZ_TOPLEFT) or
       (msg.WParam = WMSZ_BOTTOMLEFT) then
      if Left > Left - (Left mod FHorzSize) then Left := Left - (Left mod FHorzSize);

    if (msg.WParam = WMSZ_RIGHT) or
       (msg.WParam = WMSZ_BOTTOMRIGHT) or
       (msg.WParam = WMSZ_TOPRIGHT) then
      if Right > Right - (Right mod FHorzSize) then Right := Right - (Right mod FHorzSize);

    if (msg.WParam = WMSZ_BOTTOM) or
       (msg.WParam = WMSZ_BOTTOMRIGHT) or
       (msg.WParam = WMSZ_BOTTOMLEFT) then
      if Bottom > Bottom - (Bottom mod FVertSize) then Bottom := Bottom - (Bottom mod FVertSize);
  end;

  if FEnabled and FMoveGranularity and (msg.Msg = WM_ENTERSIZEMOVE) then
  begin
		GetWindowRect(TCustomForm(Owner).Handle, _rect);

		GetCursorPos(curPos);

		sSnapCX := curPos.x - _rect.Left;
		sSnapCY := curPos.y - _rect.Top;
		msg.Result := 1;
  end;

  if FEnabled and FMoveGranularity and (msg.Msg = WM_MOVING) then
  with PRect(msg.LParam)^{lprc} do
  begin
		rect_ptr := PRect(msg.LParam);

		GetCursorPos(curPos);
		OffsetRect(rect_ptr^, curPos.x - rect_ptr^.left - sSnapCX,
			curPos.y - rect_ptr^.top - sSnapCY);

		SystemParametersInfo(SPI_GETWORKAREA, 0, @_rect, 0);

		if(isClose(rect_ptr^.left, _rect.left)) then
		OffsetRect(rect_ptr^, _rect.left - rect_ptr^.left, 0)
		else if(isClose(_rect.right, rect_ptr^.right)) then
		OffsetRect(rect_ptr^, _rect.right - rect_ptr^.right, 0);

		if(isClose(rect_ptr^.top, _rect.top)) then
		OffsetRect(rect_ptr^, 0, _rect.top - rect_ptr^.top)
		else if(isClose(_rect.bottom, rect_ptr^.bottom)) then
		OffsetRect(rect_ptr^, 0, _rect.bottom - rect_ptr^.bottom);

    msg.Result := 1;
  end;

  if msg.Msg = WM_DESTROY then
  begin
//    if not (csDesigning in ComponentState) then
      TCustomForm(Owner).WindowProc := FOldWndMethod;
    exit;
  end;

  FOldWndMethod(msg); {call old (previous) window proc}
end;

end.
