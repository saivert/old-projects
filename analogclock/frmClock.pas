unit frmClock;
{$R *.dfm}
interface

(*
This application started out as an excercise in drawing a analog clock,
but ended up as a study in equations and algebra in graphics programming.
I love values ranging from 0 to 1 (floating-point) which makes it possible
to draw curves and figures that can stretch with the width and height of
the canvas. Alongside with the almighty Cosinus and Sinus I make up those
coordinates in no-time. I don't have to fiddle with exact pixel-point
coordinates, just the plain math beneath it.
The most exciting and powerful example of this is the AVS plug-in that is
bindled with Winamp. It demostrates how powerful mathematics can be when
it comes to graphics programming. Worth noting is the SuperScope part of it.
By using math operators only (and some boolean operators too) you can render
anything your mind is set to. From simple curves to intricate 3D models.
*)

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    PaintBox1: TPaintBox;
    Button1: TButton;
    Button2: TButton;
    Timer1: TTimer;
    Memo1: TMemo;
    RomanCB: TCheckBox;
    Timer2: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

var
  Paused: Boolean;
  Dblbuf: TBitmap;
  csecs, cmins, chours: Extended;
  currStep: Extended;

const
  step = 0.03;
  HandY        = 5;
  HandX        = 5;
  face: array[0..11] of string =
  ('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII');
  facenum: array[0..11] of string =
  ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12');

procedure TForm1.Button1Click(Sender: TObject);
begin
  Close
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Paused := not Paused;
  if Paused then
    Button2.Caption := '&Resume'
  else
    Button2.Caption := '&Pause';
  Timer2.Enabled := not Paused;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
var
  r: TRect;
  center: TPoint;
  w, h: Integer;
  i: Integer;
  Split, Dsplit: Extended;
  datestr: string;
  hours, mins, secs, msecs: Word;
  timeSplit: Extended;
  ex, ey: Extended;
begin
  with Dblbuf.Canvas do
  begin
    {draw outline circle and center dot}
    Brush.Color := clBlack;
    FillRect(Cliprect);
    Pen.Width := 0;
    Pen.Color := clRed;
    r := Cliprect;
    InflateRect(r, -5, -5);
    Ellipse(r);
    InflateRect(r, -(ClipRect.Right div 2) , -(ClipRect.Bottom div 2));
    Ellipse(r);
    Brush.Color := clSilver;
    FloodFill(r.Left-3, r.Top-3, clRed, fsBorder);

    {draw clock}
    center.X := Cliprect.Right div 2;
    center.Y := Cliprect.Bottom div 2;
    w := Cliprect.Right-20;
    h := Cliprect.Bottom-20;

    DecodeTime(Now, hours, mins, secs, msecs);
    csecs := -1.57 + PI * secs/30;
    cmins := -1.57 + PI * mins/30;
    chours :=-1.575 + PI * hours/6+PI*mins/360;

    Pen.Width := 3;

    {draw second hand}
    Pen.Color := clRed;
    MoveTo(Trunc(w*HandX*cos(csecs)),
           Trunc(h*HandY*sin(csecs)));
    LineTo(center.X, center.Y);

    {draw minute hand}
    Pen.Color := clWhite;
    MoveTo(Round(w*HandX*cos(cmins)),
           Round(h*HandY*sin(cmins)));
    LineTo(center.X, center.Y);

    {draw hour hand}
    Pen.Color := clTeal;
    MoveTo(Round(w*HandX*cos(chours)),
           Round(h*HandY*sin(chours)));
    LineTo(center.X, center.Y);

    {draw numbers}
    Font.Color := clWhite;
    SetBkMode(Handle, TRANSPARENT);
    Split := 360/12;
    w := w div 2;
    h := h div 2;

    if RomanCB.Checked then
    begin
      for i := 0 to 11 do
      TextOut((TextWidth('X') div 2)+w+Round(w*cos(-1.0471 + i*Split*PI/180)),
              (TextHeight('X') div 2)+h+Round(h*sin(-1.0471 + i*Split*PI/180)),
              face[i]);
    end else
    begin
      for i := 0 to 11 do
      TextOut((TextWidth('X') div 2)+w+Round(w*cos(-1.0471 + i*Split*PI/180)),
              (TextHeight('X') div 2)+h+Round(h*sin(-1.0471 + i*Split*PI/180)),
              facenum[i]);
    end;
    {draw circular scrolling date ticker}
    Font.Color := $00FF66FF;
    datestr := FormatDateTime('dddd d mmmm yyyy', Now);
    Dsplit := 360/Length(datestr);
    for i := 1 to Length(datestr) do
    TextOut((TextWidth('X') div 2)+w+Round(0.8*w*cos(currStep+i*Dsplit*PI/180)),
            (TextHeight('X') div 2)+h+Round(0.8*h*sin(currStep+i*Dsplit*PI/180)),
            datestr[i]);
  end;
  PaintBox1.Canvas.Draw(0, 0, Dblbuf);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Dblbuf := TBitmap.Create;
  Dblbuf.Width := PaintBox1.Width;
  Dblbuf.Height := PaintBox1.Height;
  DblBuf.PixelFormat := pf32bit;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Dblbuf.Destroy
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  time: TDateTime;
  hours, mins, secs, msecs: Word;
begin
  time := Now;
  DecodeTime(time, hours, mins, secs, msecs);
  csecs := -1.57 + PI * secs/30;
  cmins := -1.57 + PI * mins/30;
  chours :=-1.575 + PI * hours/6+PI*mins/360;


  Memo1.Clear;
  Memo1.Lines.Add(FormatDateTime('"date = " dddd d. mmmm yyyy', Now));
  Memo1.Lines.Add(Format('hours = %d; mins = %d; secs = %d', [hours, mins, secs]));
  Memo1.Lines.Add(Format('chours = %g'#13#10'cmins = %g'#13#10'csecs = %g', [chours, cmins, csecs]));
  Memo1.Lines.Add(Format('step = %g; currStep = %g', [step, currStep]));
  Memo1.Lines.Add(Format('roman = %s', [BoolToStr(RomanCB.Checked,True)]));
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  currStep := currStep-step;
  PaintBox1Paint(PaintBox1);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  { Resize double buffer }
  DblBuf.Width := PaintBox1.Width;
  DblBuf.Height := PaintBox1.Height;
end;

end.
