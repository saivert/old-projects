object Form1: TForm1
  Left = 314
  Top = 117
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'MultiMonWallpaperMaker'
  ClientHeight = 412
  ClientWidth = 437
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnContextPopup = FormContextPopup
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  OnShortCut = FormShortCut
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 8
    Top = 24
    Width = 417
    Height = 209
    PopupMenu = PopupMenu1
    OnContextPopup = Image1ContextPopup
    OnDblClick = Image1DblClick
    OnMouseDown = Image1MouseDown
    OnMouseUp = Image1MouseUp
  end
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 192
    Height = 13
    Caption = 'Monitors on your system (primary in bold):'
  end
  object Label2: TLabel
    Left = 8
    Top = 240
    Width = 193
    Height = 13
    Caption = 'Select image files to build wallpaper from:'
  end
  object FileLV: TListView
    Left = 8
    Top = 256
    Width = 297
    Height = 145
    Columns = <
      item
        Caption = 'Filename'
        Width = 275
      end>
    MultiSelect = True
    ReadOnly = True
    TabOrder = 4
    ViewStyle = vsReport
    OnDeletion = FileLVDeletion
    OnInsert = FileLVInsert
    OnSelectItem = FileLVSelectItem
  end
  object AddBtn: TButton
    Left = 320
    Top = 256
    Width = 107
    Height = 25
    Caption = '&Add'
    TabOrder = 1
    OnClick = AddBtnClick
  end
  object MakeBtn: TButton
    Left = 320
    Top = 376
    Width = 107
    Height = 25
    Caption = 'Make wallpaper'
    Enabled = False
    TabOrder = 3
    OnClick = MakeBtnClick
  end
  object RemoveBtn: TButton
    Left = 320
    Top = 280
    Width = 107
    Height = 25
    Caption = '&Remove'
    Enabled = False
    TabOrder = 2
    OnClick = RemoveBtnClick
  end
  object FocusPanel: TPanel
    Left = 17
    Top = 64
    Width = 400
    Height = 25
    Caption = 'Focus Panel - only used to "fake" keyboard focus for Image1'
    TabOrder = 0
    TabStop = True
    OnEnter = FocusPanelEnter
    OnExit = FocusPanelExit
  end
  object MoveUpBtn: TButton
    Left = 320
    Top = 312
    Width = 107
    Height = 25
    Caption = 'Move up'
    Enabled = False
    TabOrder = 5
  end
  object MoveDownBtn: TButton
    Left = 320
    Top = 336
    Width = 107
    Height = 25
    Caption = 'Move down'
    Enabled = False
    TabOrder = 6
  end
  object OpPictureDlg: TOpenPictureDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Title = 'Add images'
    Left = 16
    Top = 32
  end
  object PopupMenu1: TPopupMenu
    OwnerDraw = True
    Left = 48
    Top = 32
    object DetailedInfoMI: TMenuItem
      Caption = 'Detailed info'
      Default = True
      OnClick = DetailedInfoMIClick
      OnAdvancedDrawItem = MIAdvancedDrawItem
      OnMeasureItem = MIMeasureItem
    end
  end
  object SavePicDlg: TSavePictureDialog
    DefaultExt = 'bmp'
    Filter = 'Bitmaps (*.bmp)|*.bmp'
    Left = 88
    Top = 32
  end
end
