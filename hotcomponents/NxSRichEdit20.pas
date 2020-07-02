unit NxSRichEdit20;

interface

uses
  Windows, SysUtils, Classes, Controls, StdCtrls, ComCtrls;

type
  TNxSRichEdit20 = class(TRichEdit)
  private
    { Private declarations }
  protected
    procedure CreateWindowHandle(const Params: TCreateParams);  override;

  public
    { Public declarations }
  published
    { Published declarations }
  end;

implementation

procedure TNxSRichEdit20.CreateWindowHandle(const Params: TCreateParams);
var
  myParams: TCreateParams;
begin
  Move(Params, myParams, sizeof(TCreateParams));
  GetClassInfo(HInstance, 'RichEdit20W', myParams.WindowClass);

  myParams.WindowClass.cbClsExtra := 256;
  myParams.WindowClass.cbWndExtra := 256;

  StrPCopy(myParams.WinClassName, 'RichEdit20W');
  inherited CreateWindowHandle(myParams);
end;

initialization
  LoadLibrary('riched20.dll');
end.
