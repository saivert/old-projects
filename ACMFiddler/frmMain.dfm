object Form1: TForm1
  Left = 294
  Top = 114
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'ACM Fiddler'
  ClientHeight = 338
  ClientWidth = 753
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DriverListLbl: TLabel
    Left = 8
    Top = 16
    Width = 163
    Height = 13
    Caption = 'List of installed ACM drivers:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object FormatsLbl: TLabel
    Left = 400
    Top = 168
    Width = 239
    Height = 13
    Caption = 'List of formats for selected driver and tag:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object DriverInfoLbl: TLabel
    Left = 8
    Top = 248
    Width = 192
    Height = 13
    Caption = 'Information about selected driver:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object FormatTagsLbl: TLabel
    Left = 400
    Top = 8
    Width = 214
    Height = 13
    Caption = 'List of format tags for selected driver:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object DriverLB: TListBox
    Left = 8
    Top = 40
    Width = 385
    Height = 201
    Style = lbOwnerDrawFixed
    ItemHeight = 20
    TabOrder = 1
    OnClick = DriverLBClick
    OnDrawItem = DriverLBDrawItem
  end
  object EnumDriversBtn: TButton
    Left = 312
    Top = 8
    Width = 81
    Height = 25
    Caption = 'Refresh'
    TabOrder = 2
    OnClick = EnumDriversBtnClick
  end
  object InfoMemo: TMemo
    Left = 8
    Top = 264
    Width = 385
    Height = 65
    Lines.Strings = (
      
        '<Info will appear here as soon as you select an item from the li' +
        'st.>')
    ReadOnly = True
    TabOrder = 3
  end
  object FormatLB: TListBox
    Left = 400
    Top = 208
    Width = 345
    Height = 121
    Style = lbOwnerDrawFixed
    ItemHeight = 13
    TabOrder = 4
    OnDrawItem = FormatTagLBDrawItem
  end
  object SplitterPanel: TPanel
    Left = 393
    Top = -3
    Width = 6
    Height = 353
    Cursor = crHSplit
    BevelOuter = bvNone
    BevelWidth = 2
    TabOrder = 0
    OnMouseDown = SplitterPanelMouseDown
    OnMouseMove = SplitterPanelMouseMove
    OnMouseUp = SplitterPanelMouseUp
  end
  object FormatTagLB: TListBox
    Left = 400
    Top = 48
    Width = 345
    Height = 113
    Style = lbOwnerDrawFixed
    ItemHeight = 13
    TabOrder = 5
    OnClick = FormatTagLBClick
    OnDrawItem = FormatTagLBDrawItem
  end
  object FormatHC: THeaderControl
    Left = 400
    Top = 187
    Width = 345
    Height = 21
    Align = alNone
    Sections = <
      item
        AllowClick = False
        ImageIndex = -1
        MaxWidth = 512
        Text = 'Format'
        Width = 220
      end
      item
        AllowClick = False
        ImageIndex = -1
        MaxWidth = 512
        Text = 'Tech info.'
        Width = 120
      end>
    OnSectionResize = FormatHCSectionResize
  end
  object FormatTagHC: THeaderControl
    Left = 400
    Top = 27
    Width = 345
    Height = 21
    Align = alNone
    Sections = <
      item
        AllowClick = False
        ImageIndex = -1
        MaxWidth = 512
        Text = 'Format tag'
        Width = 190
      end
      item
        AllowClick = False
        ImageIndex = -1
        MaxWidth = 512
        Text = 'Tech info.'
        Width = 150
      end>
    OnSectionResize = FormatTagHCSectionResize
  end
end
