 _____  __    ___                ___          ___
   |   |  \  |   |  \ /  |   |  |   |  |     |
   |   |--/  |---|   |   |---|  |   |  |     |---
   |   |  \  |   |   |   |   |  |___|  |___  |___
 ================================== ReadMe =======

  Introduction
--------------

  TrayHole is a Win32 application that gives you access to taskbar notification
  icons (erronously called tray icons) without actually using the
  Windows Explorer Taskbar.
	If you prefer running another shell than the one that comes with Windows 95,
  and you miss the notification icons, then TrayHole is the right deal for you.


  Technical information
-----------------------

  TrayHole is the result of the my personal curiousity in how the Taskbar
  does what it does when applications call the Shell_NotifyIcon Win32 API function.
	Through the use of a personally developed memory dumping program and
  Spy++ (a Window message spying program included with MS Visual C++) I discovered
  that Shell_NotifyIcon puts together a special structure consisting of

     1. A signature value (DWORD)
     2. The dwMessage parameter from the Shell_NotifyIcon call.
     3. The NOTIFYICONDATA structure itself.

  and sends this using the WM_COPYDATA message to the Taskbar window.


  Known bugs (but not fatal ones :-) )
--------------------------------------

  * Clicking a balloon popup does not hide the balloon nor send any message to
    application displaying it.
  * When you close the balloon popup manually by clicking the Close button,
    you may have to restart TrayHole to make the balloon popups work again.
    Don't know why this is the case yet...
  * If you move TrayHole while a balloon popup is being displayed then the balloon
    will stay behind and not move along with TrayHole.
  * After a notifiaction icon is added to TrayHole by an application anbd then
    removed the tooltip is still displayed for it when you move the mouse over
    the now empty spot.
  * If the application is constantly updating the tip text (via a timer for
    example), the tip will also move around if the you're also moving the mouse.
  * I tried using a wake-up timer application, that uses a notification icon with
    TrayHole and after a nights sleep I heard loud music (time to get up!) and
    checked my computer.
    The wake-up application displays a balloon popup when the timer has expired
    but when I looked at the popup the balloon spanned across the screen with
    no text in it. Weird bug!!



  Contact
---------

  If you make something out of this program and maybe even make your own version of it,
  please send me an E-Mail with the source (and the compiled app if it's not too much
  to ask). My contact information is:

  E-Mail -> saivert@email.com
  Homepage -> http://members.tripod.com/files_saivert/
