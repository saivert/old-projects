unit frmLicbox;

(* A dull License Agr... (long boring word) dialog box *)

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TLicForm = class(TForm)
    Memo1: TMemo;
    BtnAccept: TButton;
    BtnDecline: TButton;
    Label1: TLabel;
    Label2: TLabel;
    procedure BtnDeclineMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure BtnAcceptClick(Sender: TObject);
    procedure BtnDeclineClick(Sender: TObject);
    procedure BtnDeclineEnter(Sender: TObject);
  private
    procedure SwapButtons;
  public
  end;

var
  LicForm: TLicForm;

implementation

{$R *.dfm}

procedure TLicForm.BtnDeclineMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  SwapButtons;
end;

procedure TLicForm.SwapButtons;
var
  r: TRect;
begin
  r := BtnDecline.BoundsRect;
  BtnDecline.Left := BtnAccept.Left;
  BtnAccept.Left := r.Left;
end;

procedure TLicForm.BtnAcceptClick(Sender: TObject);
begin
  Close;
end;

procedure TLicForm.BtnDeclineClick(Sender: TObject);
begin
  ShowMessage('That is not nice!');
end;

procedure TLicForm.BtnDeclineEnter(Sender: TObject);
begin
 SwapButtons;
 BtnAccept.SetFocus;
end;

end.
