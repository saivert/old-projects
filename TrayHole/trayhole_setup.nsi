; Generated by makesimplensi @ 21.07.2004 15:15:01
; from directory "C:\vcproj\page 2\TrayHole"
; Fine-tuned by Saivert

!include "infopage.nsh"
!include "addremoveprograms.nsh"
!include "Sections.nsh"
!include "infopage.nsh"

OutFile "trayhole_setup.exe"
ChangeUI IDD_INST "${NSISDIR}\contrib\uis\classic_buttonstoright.exe"
XPStyle on
AddBrandingImage top 60
Name "TrayHole"
InstallDir "$PROGRAMFILES\TrayHole"

!insertmacro PAGE_INFO "ReadMe..." "ReadMe.txt"
Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "TrayHole" Sec_Main
  SectionIn RO
  SectionIn 1 2

  SetOutPath "$INSTDIR"
    File "Release\TrayHole.exe"
    File "ReadMe.txt"
SectionEnd

Section "Source" Sec_Source
  SectionIn 2

  SetOutPath $INSTDIR\Source
    File "icon1.ico"
    File "NxSToolTip.cpp"
    File "NxSToolTip.h"
    File "ReadMe.txt"
    File "resource.h"
    File "StdAfx.cpp"
    File "StdAfx.h"
    File "toolbar.bmp"
    File "TrayHole.cpp"
    File "TrayHole.dsp"
    File "TrayHole.dsw"
    File "TrayHole.rc"
    File "xp.manifest"

SectionEnd

Section "Create shortcuts" Sec_Shortcuts
  SectionIn 1 2
  CreateDirectory "$SMPROGRAMS\TrayHole"
  CreateShortcut "$SMPROGRAMS\TrayHole\TrayHole.lnk" "$INSTDIR\trayhole.exe"
  CreateShortcut "$SMPROGRAMS\TrayHole\Uninstall TrayHole.lnk" "$INSTDIR\uninstall.exe"

  !insertmacro SectionFlagIsSet ${Sec_Source} ${SF_SELECTED} +1 nosource
    CreateShortcut "$SMPROGRAMS\TrayHole\TrayHole workspace.lnk" "$INSTDIR\source\trayhole.dsw"
  nosource:

SectionEnd

Section -post
  !insertmacro ADDTOADDREMOVELIST "TrayHole" "$(^Name)" "$INSTDIR\uninstall.exe" 1 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
  ; Remove main application files
  Delete "$INSTDIR\TrayHole.exe"
  Delete "$INSTDIR\ReadMe.txt"

  ; Remove source file
  RMDIR /r "$INSTDIR\source"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\TrayHole\TrayHole.lnk"
  Delete "$SMPROGRAMS\TrayHole\Uninstall TrayHole.lnk"
  Delete "$SMPROGRAMS\TrayHole\TrayHole workspace.lnk"
  RMDir "$SMPROGRAMS\TrayHole"

  ; Remove uninstaller and program folder
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR\"

  ; Remove entry in Add/Remove programs list
  !insertmacro REMOVEFROMADDREMOVELIST "TrayHole"

SectionEnd

!define NUMSECTIONS 3
Function .onMouseOverSection
  StrCpy $1 0
  repshit:
    !insertmacro ClearSectionFlag $1 ${SF_BOLD}
    IntOp $1 $1 + 1
  IntCmp $1 ${NUMSECTIONS} 0 repshit 0
  !insertmacro SetSectionFlag $0 ${SF_BOLD}


  StrCpy $3 "$(^ComponentsSubText2_NoInstTypes)$\r$\n$\r$\n"
  StrCmp $0 "${Sec_Main}" +1 +2
    StrCpy $3 "$3Main files"
  StrCmp $0 "${Sec_Source}" +1 +2
    StrCpy $3 "$3Install Microsoft Visual C++ 6.0 project for TrayHole."
  StrCmp $0 "${Sec_Shortcuts}" +1 +2
    StrCpy $3 "$3Create shortcuts in Start-Menu\Programs."

  FindWindow $4 "#32770" "" $HWNDPARENT 0
  GetDlgItem $4 $4 1022
  SendMessage $4 0x0C 0 "STR:$3"
FunctionEnd

!macro GUIINIT_MACRO ISUN
Function ${ISUN}.onGUIInit
  InitPluginsDir
  File /oname=$PLUGINSDIR\banner.bmp banner.bmp
  SetBrandingImage /RESIZETOFIT $PLUGINSDIR\banner.bmp
FunctionEnd
!macroend

!insertmacro GUIINIT_MACRO ""
!insertmacro GUIINIT_MACRO un


; Number of File lines: 26
; Number of SetOutPath lines: 2
; Total size of all files: 4 MB (4616071 bytes)