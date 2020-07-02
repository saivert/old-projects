object XPAboutForm: TXPAboutForm
  Left = 380
  Top = 118
  AutoSize = True
  BorderStyle = bsDialog
  Caption = 'About'
  ClientHeight = 316
  ClientWidth = 408
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ClientPanel: TPanel
    Left = 0
    Top = 75
    Width = 408
    Height = 241
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object LblProductName: TLabel
      Left = 56
      Top = 16
      Width = 257
      Height = 13
      AutoSize = False
    end
    object LblVersion: TLabel
      Left = 56
      Top = 32
      Width = 257
      Height = 13
      AutoSize = False
    end
    object LblCopyright: TLabel
      Left = 56
      Top = 48
      Width = 257
      Height = 13
      AutoSize = False
    end
    object HomepageLabel: TLabel
      Left = 56
      Top = 64
      Width = 3
      Height = 13
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      OnClick = HomepageLabelClick
      OnMouseEnter = HomepageLabelMouseEnter
      OnMouseLeave = HomepageLabelMouseLeave
    end
    object ImgAppIcon: TImage
      Left = 336
      Top = 8
      Width = 48
      Height = 48
      Center = True
      OnClick = ImgAppIconClick
    end
    object LblOSVerStr: TLabel
      Left = 56
      Top = 152
      Width = 345
      Height = 13
      AutoSize = False
    end
    object LblPhysMem: TLabel
      Left = 56
      Top = 168
      Width = 345
      Height = 13
      AutoSize = False
      Caption = 'Physical Memory: %.0n kB free of %.0n kB total'
    end
    object LblMemLoad: TLabel
      Left = 56
      Top = 184
      Width = 121
      Height = 13
      AutoSize = False
      Caption = 'Memory load: '
    end
    object B2: TBevel
      Left = 53
      Top = 145
      Width = 345
      Height = 3
      Shape = bsTopLine
    end
    object LblMoreInfo: TLabel
      Left = 56
      Top = 88
      Width = 337
      Height = 49
      AutoSize = False
    end
    object AboutOKBtn: TButton
      Left = 320
      Top = 208
      Width = 75
      Height = 25
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 0
    end
  end
  object HeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 408
    Height = 75
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object B1: TBevel
      Left = 0
      Top = 72
      Width = 408
      Height = 3
      Align = alBottom
      Shape = bsBottomLine
    end
    object AboutImage: TImage
      Left = 0
      Top = 0
      Width = 408
      Height = 72
      Align = alClient
    end
  end
  object FunTimer: TTimer
    Enabled = False
    Interval = 100
    OnTimer = FunTimerTimer
    Left = 8
    Top = 8
  end
end
