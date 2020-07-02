unit HotLabel;

interface

uses
  SysUtils, Classes, Controls, Graphics, StdCtrls, Windows, Messages, Forms;

type
  THotLabel = class(TLabel)
  private
    FMouseInside: Boolean;
    FFontRecall: TFontRecall;
    FHotUnderline: Boolean;
    FHotlightEnabled: Boolean;
    FHotlightColor: TColor;
    FHotBorderEnabled: Boolean;
    procedure SetHotUnderline(newstate: Boolean);
    procedure SetHotlightEnabled(newstate: Boolean);
    procedure SetHotlightColor(newcolor: TColor);
    procedure SetHotBorder(newstate: Boolean);

    { Message handlers }
    procedure MouseOver(var Msg: TMessage); message CM_MOUSEENTER;
    procedure MouseOut(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property HotBorder: Boolean read FHotBorderEnabled write SetHotBorder default False;
    property HotUnderline: Boolean read FHotUnderline write SetHotUnderline default True;
    property HotlightEnabled: Boolean read FHotlightEnabled write SetHotlightEnabled default True;
    property HotlightColor: TColor read FHotlightColor write SetHotlightColor;
    property Caption;
    property AutoSize;
    property Transparent;
  end;

implementation

const
  handcursor = crHandPoint;

constructor THotLabel.Create(AOwner: TComponent);
begin
  inherited;
  Screen.Cursors[handcursor] := LoadCursor(0, IDC_HAND);
  Cursor := handcursor;
  FHotBorderEnabled := False;
  FHotlightEnabled := True;
  FHotUnderline := True;
  FHotlightColor := clHotlight;
end;

destructor THotLabel.Destroy;
begin
  inherited;
end;

procedure THotLabel.Paint;
var
  oldPen: TPenRecall;
begin
  inherited Paint;
  oldPen := TPenRecall.Create(Canvas.Pen);

  if (csDesigning in ComponentState) then
    exit;

  if FHotBorderEnabled and FMouseInside then
  begin
    Canvas.Brush.Color := FHotlightColor;
    Canvas.FrameRect(ClientRect);
  end;
  oldPen.Destroy;
end;

procedure THotLabel.SetHotUnderline(newstate: Boolean);
begin
  if newstate <> FHotUnderline then
    FHotUnderline := newstate;
  invalidate;
end;

procedure THotLabel.SetHotlightEnabled(newstate: Boolean);
begin
  if newstate <> FHotlightEnabled then
    FHotlightEnabled := newstate;
  invalidate;
end;

procedure THotLabel.SetHotlightColor(newcolor: TColor);
begin
  if newcolor <> FHotlightColor then
    FHotlightColor := newcolor;
  invalidate;    
end;

procedure THotLabel.SetHotBorder(newstate: Boolean);
begin
  if newstate <> FHotBorderEnabled then
  begin
    FHotBorderEnabled := newstate;
    Invalidate;
  end;
end;

procedure THotLabel.MouseOver(var Msg: TMessage);
begin
  if (csDesigning in ComponentState) then
    exit;
  FMouseInside := True;
  FFontRecall := TFontRecall.Create(Font);
  if FHotlightEnabled then Font.Color := FHotlightColor;
  if FHotUnderline then Font.Style := [fsUnderline];
  Invalidate;
end;

procedure THotLabel.MouseOut(var Msg: TMessage);
begin
  if (csDesigning in ComponentState) then
    exit;
  FMouseInside := False;
  if Assigned(FFontRecall) then FFontRecall.Destroy;
  Invalidate;
end;

end.
