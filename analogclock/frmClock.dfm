object Form1: TForm1
  Left = 296
  Top = 116
  Width = 449
  Height = 273
  Caption = 'Analog Clock'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  DesignSize = (
    441
    239)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 16
    Width = 189
    Height = 185
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Clock display'
    TabOrder = 0
    DesignSize = (
      189
      185)
    object PaintBox1: TPaintBox
      Left = 8
      Top = 16
      Width = 170
      Height = 160
      Anchors = [akLeft, akTop, akRight, akBottom]
      OnPaint = PaintBox1Paint
    end
  end
  object GroupBox2: TGroupBox
    Left = 203
    Top = 16
    Width = 233
    Height = 185
    Anchors = [akTop, akRight]
    Caption = 'Status and settings'
    TabOrder = 1
    object Memo1: TMemo
      Left = 8
      Top = 16
      Width = 217
      Height = 121
      Lines.Strings = (
        'Please wait...')
      ReadOnly = True
      TabOrder = 0
    end
    object RomanCB: TCheckBox
      Left = 8
      Top = 144
      Width = 97
      Height = 17
      Caption = 'Roman numbers'
      TabOrder = 1
    end
  end
  object Button1: TButton
    Left = 352
    Top = 208
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'E&xit'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 264
    Top = 208
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '&Pause'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Timer1: TTimer
    Interval = 250
    OnTimer = Timer1Timer
    Left = 8
    Top = 208
  end
  object Timer2: TTimer
    Interval = 20
    OnTimer = Timer2Timer
    Left = 56
    Top = 208
  end
end
