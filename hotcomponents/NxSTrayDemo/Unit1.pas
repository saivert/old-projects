unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, NxSTray, StdCtrls, Menus, ImgList;

type
  TForm1 = class(TForm)
    NxSTray1: TNxSTray;
    GroupBox1: TGroupBox;
    VisibleCB: TCheckBox;
    GroupBox2: TGroupBox;
    Button1: TButton;
    Label1: TLabel;
    BalloonTitleEdit: TEdit;
    BalloonMsgMemo: TMemo;
    Label2: TLabel;
    RemoveBtn: TButton;
    PopupMenu1: TPopupMenu;
    Exit1: TMenuItem;
    Show1: TMenuItem;
    HideOnMinimizeCB: TCheckBox;
    Button3: TButton;
    AnimateCB: TCheckBox;
    SetFocusBtn: TButton;
    ImageList1: TImageList;
    Button5: TButton;
    Hide1: TMenuItem;
    Animate1: TMenuItem;
    N1: TMenuItem;
    procedure VisibleCBClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);
    procedure Show1Click(Sender: TObject);
    procedure HideOnMinimizeCBClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure AnimateCBClick(Sender: TObject);
    procedure SetFocusBtnClick(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Hide1Click(Sender: TObject);
    procedure NxSTray1Minimize(Sender: TObject);
    procedure NxSTray1Restore(Sender: TObject);
    procedure NxSTray1BalloonClick(Sender: TObject);
    procedure NxSTray1BalloonShow(Sender: TObject);
    procedure NxSTray1BalloonHide(Sender: TObject);
    procedure NxSTray1BalloonClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Animate1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
{$R xpmanifest_app.res}

uses ShellApi;

resourcestring
  SCaption = 'NxSTray demo';
const
  MyTrayGUID: TGUID = '{96FEB63E-6D70-4AFD-8407-9251D066D24A}';

procedure TForm1.VisibleCBClick(Sender: TObject);
begin
  NxSTray1.Visible := VisibleCB.Checked;
  if VisibleCB.Checked then
    RemoveBtn.Enabled := True;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  NxSTray1.ShowBalloon(BalloonMsgMemo.Text, BalloonTitleEdit.Text, bitWarning);
end;

procedure TForm1.RemoveBtnClick(Sender: TObject);
begin
  NxSTray1.Remove;
  VisibleCB.Checked := False;
  RemoveBtn.Enabled := False;
end;

procedure TForm1.HideOnMinimizeCBClick(Sender: TObject);
begin
  NxSTray1.HideOnMinimize := HideOnMinimizeCB.Checked;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.AnimateCBClick(Sender: TObject);
begin
  NxSTray1.Animate := AnimateCB.Checked;
  Animate1.Checked := AnimateCB.Checked;
end;

procedure TForm1.SetFocusBtnClick(Sender: TObject);
begin
  NxSTray1.SetFocus;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  NxSTray1.HideBalloon;
end;

procedure TForm1.Show1Click(Sender: TObject);
begin
  NxSTray1.Restore;
end;

procedure TForm1.Hide1Click(Sender: TObject);
begin
  NxSTray1.Minimize;
end;

procedure TForm1.NxSTray1Minimize(Sender: TObject);
begin
  Show1.Visible := True;
  Hide1.Visible := False;
end;

procedure TForm1.NxSTray1Restore(Sender: TObject);
begin
  Show1.Visible := False;
  Hide1.Visible := True;
end;

procedure TForm1.NxSTray1BalloonClick(Sender: TObject);
begin
  Caption := SCaption + ' - Balloon was clicked';
end;

procedure TForm1.NxSTray1BalloonShow(Sender: TObject);
begin
  Caption := SCaption + ' - Balloon showing';
end;

procedure TForm1.NxSTray1BalloonHide(Sender: TObject);
begin
  Caption := SCaption + ' - Balloon hiding';

end;

procedure TForm1.NxSTray1BalloonClose(Sender: TObject);
begin
  Caption := SCaption + ' - Balloon closing';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  NxSTray1.SetGUID(@MyTrayGUID);
end;

procedure TForm1.Animate1Click(Sender: TObject);
begin
  AnimateCB.Checked := not AnimateCB.Checked;
  Animate1.Checked := AnimateCB.Checked;
end;

end.
