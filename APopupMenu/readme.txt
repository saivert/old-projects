______________
  Introduction


APopupMenu is an application that uses an INI file to generate a
popup menu and displays that on screen.

____________________
  Usage instructions

APopupMenu {definitionfile} [position]

where definitionfile is a plain text file containing
these lines:

  [Menu]
  ItemCount={total count of items}

  [Item <zero-based item number>]
  Text=menu item title
  Action=<one of the actions listed below>
  ; one or more parameter keys
  anykey=anyvalue

Action can be one of these
  Execute - Execute a program or open a file.
            Operation={'open', 'edit', or some other operation}
            File={the actual file to open or execute}
            Params={Launch program in File with this text as parameters}
            WorkDir={current working directory}

  Link    - Pops up your favorite browser on the address in URL key.

  RunCPL  - Opens the Control Panel Applet in "CPlFile" key passing it
            the parameters in "Params" key.

  MsgBox  - Message box.
            MsgText is the text to show, MsgTitle will be the title of
            the dialog box.
            MsgAction is one of these predefined actions to take,
            if the user answers positive (Yes or Ok) to the message box.
            You will have to specify parameters for that action in the
            same manner as usual.

Here is an example:

Command line to start APopupMenu:
  APopupMenu c:\temp\apps.dat 346 18

Contents of apps.dat:
  [menu]
  ItemCount=4

  [Item 0]
  Text=Edit WIN.INI
  Action=Execute
  Operation=edit
  File=%windir%\win.ini

  [Item 1]
  Text=Visit Appz.net
  Action=Link
  URL=http://www.appz.net

  [Item 2]
  Text=System Control Panel
  Action=RunCPL
  Param1=%systemroot%\sysdm.cpl
  Param2= ,2

  [Item 3]
  Text=Delete temp folder
  Action=MsgBox
  MsgText=Do you wish to delete all files in temp folder?
  MsgTitle=Confirm delete
  MsgAction=Execute
  ; The following is parameter for Execute action wich is nested here.
  File=c:\utils\cleantemp.bat

__________
  Appendix

  The Flags parameter for MsgBox and AdvMsgBox can be one of these values:

  Icon flags:
  MB_ICONINFORMATION    - Information icon (the "I" in a circle)
  MB_ICONWARNING        - A Triangle with an exclamation point.
  MB_ICONERROR          - A cross ("X") inside a circle
  MB_ICONQUESTION       - A question mark inside a cartoon talking bubble.

  Button flags:
  MB_OK                 - OK button only
  MB_YESNO              - "Yes" and "No" buttons
  MB_YESNOCANCEL        - "Yes", "No" and "Cancel" buttons

#EOF