object AboutForm: TAboutForm
  Left = 309
  Top = 113
  BorderStyle = bsDialog
  Caption = 'About PopupMenu'
  ClientHeight = 170
  ClientWidth = 295
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 24
    Top = 16
    Width = 32
    Height = 32
  end
  object BitBtn1: TBitBtn
    Left = 104
    Top = 136
    Width = 75
    Height = 25
    TabOrder = 0
    Kind = bkClose
  end
  object GB1: TGroupBox
    Left = 80
    Top = 8
    Width = 201
    Height = 57
    Caption = 'Version information'
    TabOrder = 1
    object TLabel
      Left = 8
      Top = 16
      Width = 56
      Height = 13
      Caption = 'Version: 1.2'
    end
    object TLabel
      Left = 8
      Top = 32
      Width = 38
      Height = 13
      Caption = 'Click for'
    end
    object Label5: TLabel
      Left = 50
      Top = 32
      Width = 88
      Height = 13
      Cursor = crHandPoint
      Caption = 'usage instructions.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHotLight
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      OnClick = Label5Click
      OnMouseEnter = LnkLblEnter
      OnMouseLeave = LnkLblLeave
    end
  end
  object GB2: TGroupBox
    Left = 8
    Top = 72
    Width = 273
    Height = 57
    Caption = 'Contact information'
    TabOrder = 2
    object TLabel
      Left = 16
      Top = 16
      Width = 84
      Height = 13
      Caption = 'Written by Saivert'
    end
    object TLabel
      Left = 16
      Top = 32
      Width = 55
      Height = 13
      Caption = 'Homepage:'
    end
    object URLLabel: TLabel
      Left = 80
      Top = 32
      Width = 126
      Height = 13
      Cursor = crHandPoint
      Caption = 'http://saivert.webhop.net/'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHotLight
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      OnClick = URLLabelClick
      OnMouseEnter = LnkLblEnter
      OnMouseLeave = LnkLblLeave
    end
  end
  object ThePM: TPopupMenu
    OwnerDraw = True
    Left = 8
    Top = 136
  end
end
