!include "addremoveprograms.nsh"
!include "WinMessages.nsh"

OutFile "alerttimersetup.exe"
SetCompressor lzma
Name "Alert Timer"
XPStyle on
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\AlertTimer"

ChangeUI IDD_INST "${NSISDIR}\Contrib\UIs\classic_buttonstoright.exe"
AddBrandingImage top 73 ; Needs to be after ChangeUI

CheckBitmap "${NSISDIR}\Contrib\Graphics\Checks\modern.bmp"

LoadLanguageFile "${NSISDIR}\Contrib\Language files\norwegian.nlf"

InstallDir "$PROGRAMFILES\Alert Timer"
InstallDirRegKey HKEY_LOCAL_MACHINE ${UNINSTKEY} "UninstallString"

Page components
Page directory
Page instfiles


LangString UNCOMPONENTSTEXT 1033 "Please select the components to remove."
LangString UNCOMPONENTSTEXT 1044 "Vennligst velg komponentene du vil fjerne."

UninstPage uninstConfirm
PageEx un.components
  ComponentText $(UNCOMPONENTSTEXT)
PageExEnd

UninstPage instfiles

Section "Alert Timer"
  SectionIn RO

  DetailPrint "Checking for running instances of Alert Timer..."
  check:
    FindWindow $R0 "NxSAlertTimerApplication"
    StrCmp $R0 0 noinstances
    DetailPrint "Closing instance (HWND=$R0)..."
    SendMessage $R0 ${WM_SYSCOMMAND} ${SC_CLOSE} 0 /TIMEOUT=5000
  Goto check

    ;MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
    ;  "You have running instance of Alert Timer! Please close down all \
    ;  instances of Alert Timer before continuing." IDRETRY check
    ;Quit

  noinstances:

  SetOutPath $INSTDIR
  ;Main program files
  File alerttimer.exe
  File menusidebar.bmp

  ; Language files
  File norwegian.lng
  File example.lng

  ; Language file creation helper utility
  File MakeLangID.exe
  
SectionEnd

Section "Source files (Delphi)"
  SetOutPath $INSTDIR\Source
  ; Source files
  File frmAlert.pas
  File frmAlert.dfm
  File alerttimer.dpr
  File alerttimer.ico
  File alerttimer.res
  File alerttimer.cfg
  File aboutlogo.bmp
SectionEnd

Section "Start Menu Shortcuts"
  AddSize 2 ;Two shortcuts = Approx. 2 kb
  CreateDirectory "$SMPROGRAMS\Alert Timer"
  CreateShortcut "$SMPROGRAMS\Alert Timer\Alert Timer.lnk" "$INSTDIR\alerttimer.exe"
  CreateShortcut "$SMPROGRAMS\Alert Timer\Uninstall Alert Timer.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

Section /o "Launch at Windows Startup"
  CreateShortcut "$SMSTARTUP\Alert Timer.lnk" "$INSTDIR\alerttimer.exe" "/h"
SectionEnd

Section -post
  !insertmacro ADDTOADDREMOVELIST AlertTimer $(^Name) $INSTDIR\uninstall.exe 1 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "un.Remove Alert Timer"
  SectionIn RO
  ;Main program files
  
  Delete "$INSTDIR\alerttimer.exe"
  Delete "$INSTDIR\menusidebar.bmp"
  Delete "$INSTDIR\timeralert.exe.manifest"

  ; Language files
  Delete "$INSTDIR\norwegian.lng"
  Delete "$INSTDIR\example.lng"

  ; Language file creation helper utility
  Delete "$INSTDIR\MakeLangID.exe"

  ; Source files
  Delete "$INSTDIR\Source\frmAlert.pas"
  Delete "$INSTDIR\Source\frmAlert.dfm"
  Delete "$INSTDIR\Source\alerttimer.dpr"
  Delete "$INSTDIR\Source\alerttimer.ico"
  Delete "$INSTDIR\Source\alerttimer.res"
  Delete "$INSTDIR\Source\alerttimer.cfg"
  Delete "$INSTDIR\Source\aboutlogo.bmp"
  RMDir /r "$INSTDIR\Source"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\Alert Timer\Alert Timer.lnk"
  Delete "$SMPROGRAMS\Alert Timer\Uninstall Alert Timer.lnk"
  RMDir "$SMPROGRAMS\Alert Timer"
  ; Remove from Startup folder
  Delete "$SMSTARTUP\Alert Timer.lnk"

  !insertmacro REMOVEFROMADDREMOVELIST AlertTimer

  Delete "$INSTDIR\uninstall.exe"
SectionEnd

Section "un.Remove configuration file"
  Delete "$INSTDIR\alerttimer.ini"
  RMDir /r "$INSTDIR"
SectionEnd

!macro INIT
  InitPluginsDir
  File /oname=$PLUGINSDIR\branding.bmp "aboutlogo.bmp"
  SetBrandingImage "$PLUGINSDIR\branding.bmp"
!macroend

Function .OnGUIInit
  !insertmacro INIT
FunctionEnd

Function un.OnGUIInit
  !insertmacro INIT
FunctionEnd
