object LicForm: TLicForm
  Left = 192
  Top = 130
  BorderStyle = bsDialog
  Caption = 'License'
  ClientHeight = 328
  ClientWidth = 356
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 264
    Width = 315
    Height = 13
    Caption = 
      'Click one of the buttons. NOW! (I think you know which to press.' +
      '..)'
  end
  object Label2: TLabel
    Left = 16
    Top = 8
    Width = 278
    Height = 26
    Caption = 
      'Please read and accept this licence agreement before you install' +
      ' Saivert'#39's HotComponents.'
    WordWrap = True
  end
  object Memo1: TMemo
    Left = 16
    Top = 48
    Width = 321
    Height = 209
    Lines.Strings = (
      'HotComponents'
      'Release 1'
      '20'#169'03 Saivert.'
      'http://saivert.webhop.net'
      ''
      'License:'
      ''
      'Feel free to modify this source code and release components '
      'derived from these components.'
      'Parts of this source code is based on the GExperts code.'
      'I feel free, so should you. Okey!'
      'Also: I hate writing lame license agreements who'#39's taking away '
      'all '
      'your rights.'
      'Mother F***ing shit!'
      ''
      ''
      'This is here just so you can scroll down a bit. We all love to '
      'scroll, huh!?')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object BtnAccept: TButton
    Left = 264
    Top = 288
    Width = 75
    Height = 25
    Caption = 'I Accept'
    Default = True
    TabOrder = 1
    OnClick = BtnAcceptClick
  end
  object BtnDecline: TButton
    Left = 176
    Top = 288
    Width = 75
    Height = 25
    Caption = 'I Decline'
    TabOrder = 2
    OnClick = BtnDeclineClick
    OnEnter = BtnDeclineEnter
    OnMouseMove = BtnDeclineMouseMove
  end
end
