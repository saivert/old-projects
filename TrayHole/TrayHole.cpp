// TrayHole.cpp : Main and only module of the TrayHole application.
//
// Written by Saivert
// http://members.tripod.com/files_saivert/
//
// Note:
//  I'm using the term "tray icon" though it's actually called "notification icon",
//  because that is a term that has worked it's way in and it's also much shorter.
//

#include "stdafx.h" 
#include "cstdlib"
#include "commctrl.h"
#include "shellapi.h"
#include "NxSToolTip.h"
#include "resource.h"

#define WNDCLASS "Shell_TrayWnd"
#define NOTIFYICONDATAW_REAL_SIZE 0x000003B8


// Control id's
#define IDC_TOOLBAR       1201
#define IDC_STATUS        1202
//Toolbar button ID's 
#define TBB_ABOUT         100
#define TBB_CONFIG        101
#define TBB_EXIT          102
#define TBB_ALWAYSONTOP   103

// Tray icon metrics
#define TRAYICONS_XOFFSET 2
#define TRAYICONS_YOFFSET 2
#define TRAYICONS_CX 16
#define TRAYICONS_CY 16
#define TRAYICONS_CXLARGE 32
#define TRAYICONS_CYLARGE 32

// Object maintaining a list of pointers
class CItemList
{
  public:
    CItemList()
	{
		m_size=0;
		//m_list=0;
		m_list=(void**)::HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, 0);
	}
    ~CItemList()
	{
		//::free(m_list);
		HeapFree(GetProcessHeap(), 0, m_list);
	}

    void *Add(void *i);
    void *Get(int w);
    void Del(int idx);
    int GetSize(void) { return m_size; }
  protected:
    void **m_list;
    int m_size;
};


// Various typedefs required by this application

// Structure that is sent by the shell using WM_COPYDATA to our
// window procedure.
typedef struct _mynotifyicondata {
	DWORD dwSignature; //must be 0x34753423
	DWORD dwTrayMsg; // NIM_* ones
	NOTIFYICONDATAW nid;
} MYNOTIFYICONDATA, *PMYNOTIFYICONDATA;

// Private structure used to hold information about
// each tray icon added to a list.
typedef struct _trayiconstruct {
	UINT id;
	HWND owner;
	UINT callbackmsg;
	char tip[128];
	HICON icon;
	bool fShow;
} TRAYICONSTRUCT, *PTRAYICONSTRUCT;


// Local function prototypes
LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
INT_PTR CALLBACK AboutDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
int MyMsgBox(HWND hwndOwner, DWORD dwStyle, LPCTSTR lpszTitle, LPCTSTR lpszText, ...);
bool SaveConfig(void);
bool LoadConfig(void);
RECT GetTrayIconRect(UINT index);
TBBUTTON CreateToolBarButton(int iBitmap, int idCommand, BYTE fsState, BYTE fsStyle, DWORD dwData, int iString);
void AddTBTip(HWND hwTB, UINT id, UINT iString);
static void rgn_removeFromRgn(HRGN hrgn, int left, int top, int right, int bottom);
static void AddTrayIconTip(UINT index, LPTSTR lpszTip);
static void UpdateTipRects(void);
bool PtInTrayIconRect(POINT pt, UINT index);
void UpdateSize(HWND hWnd);
void MyCheckMenuItem(HMENU hmenu, UINT cmdid, bool fCheck);

// Global variable collection
HANDLE g_appmutex;
HINSTANCE g_hInst;
HWND g_hMainWnd;
CItemList g_traylist;
CNxSToolTip *g_tip=NULL;
CNxSToolTip *g_tbtip=NULL;
CNxSToolTip *g_balloon=NULL;
TCHAR g_szAppTitle[256];

// Global configuration items (and their default values)
bool g_fLargeIcons=false;
bool g_fShowToolbar=true;
bool g_fShowMenu=false;
bool g_fShowToolTips=true;
bool g_fAlwaysOnTop=true;


// Made this function just to check if I got the right stuff, or somethin'...
#ifdef NOTINUSE
int RealShell_NotifyIcon(DWORD dwMessage, NOTIFYICONDATAW *lpnid)
{
	MYNOTIFYICONDATA mynid;
	COPYDATASTRUCT cds;
	HWND hwndShell;

	// Shell_NotifyIcon puts the value of the dwMessage parameter in a special
	// structure together with the NOTIFYICONDATA structure and a signature in
	// front of the entire thing and sends it using WM_COPYDATA to the
	// Explorer Taskbar window.

	mynid.dwSignature = 0x34753423; // Also discovered this using MemDump
	mynid.dwTrayMsg = dwMessage;

	CopyMemory(&mynid.nid, lpnid, sizeof(NOTIFYICONDATAW));

	// I was running Windows XP when I tried this out so I'm using a fixed
	// size value (discovered using MemDump) instead of "sizeof(NOTIFYICONDATAW)"
	// because this works (don't ask me!).
	// The shell uses Wide character version structures internally, so even if an
	// application uses the ANSI version of NOTIFYICONDATA, SHELL32.DLL will
	// convert this to a NOTIFYICONDATAW structure and use this when sending the
	// WM_COPYDATA to the Explorer Taskbar.
	mynid.nid.cbSize = NOTIFYICONDATAW_REAL_SIZE;
	
	cds.dwData = 1;
	cds.lpData = &mynid;
	cds.cbData = sizeof(MYNOTIFYICONDATA);

	// I'm using FindWindow to locate the Taskbar window, because it appears that
	// Shell_NotifyIcon also does this.
	hwndShell = FindWindow("Shell_TrayWnd", NULL);
	if (!hwndShell) return -1;

	return SendMessage(hwndShell, WM_COPYDATA, 0, LPARAM(&cds));
}
#endif //NOTINUSE


int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	MSG msg;
	WNDCLASSEX wc;
	ATOM wndatom;
	INITCOMMONCONTROLSEX icc;

	g_hInst = hInstance;

	LoadString(g_hInst, IDS_APPTITLE, g_szAppTitle, sizeof(g_szAppTitle));

	// Only allow one instance
	g_appmutex = CreateMutex(NULL, TRUE, TEXT("TrayHole_Mutex"));
	if (GetLastError() == ERROR_ALREADY_EXISTS)
	{
		SetForegroundWindow(FindWindow(WNDCLASS, g_szAppTitle));
		return 0;
	}

	icc.dwSize = sizeof(INITCOMMONCONTROLSEX);
	icc.dwICC = ICC_WIN95_CLASSES;
	InitCommonControlsEx(&icc);

	ZeroMemory(&wc, sizeof(WNDCLASSEX));
	wc.cbSize = sizeof(WNDCLASSEX);
	wc.style = CS_DBLCLKS;
	wc.lpszClassName = WNDCLASS;
	wc.hIcon = LoadIcon(g_hInst, (LPCTSTR)IDI_MAINICON);
	wc.hIconSm = (HICON)LoadImage(g_hInst, (LPCTSTR)IDI_MAINICON, IMAGE_ICON, 16, 16, 0);
	wc.lpfnWndProc = WndProc;
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);

	wndatom = RegisterClassEx(&wc);

	g_hMainWnd = CreateWindowEx(
		WS_EX_APPWINDOW|WS_EX_TOOLWINDOW,				// style
		(LPCTSTR)wndatom,								// window class
		g_szAppTitle,									// caption
		WS_POPUP|WS_CAPTION|WS_THICKFRAME|WS_SYSMENU,	// style
		0,												// left
		GetSystemMetrics(SM_CYSCREEN)-75,				// top
		180,											// width
		75,												// height
		0,												// parent
		0,												// menu
		hInstance,										// instance handle
		NULL);											// lpParam

	ShowWindow(g_hMainWnd, nCmdShow);

	while (GetMessage(&msg, 0, 0, 0))
	{
		if (g_tip) g_tip->RelayEvent(&msg);
		if (g_balloon) g_balloon->RelayEvent(&msg);

		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	// Important to release the mutex so we don't dead-lock Windows and
	// have to restart the computer to be able to start TrayHole again.
	ReleaseMutex(g_appmutex);

	return msg.wParam;
}

TBBUTTON CreateToolBarButton(int iBitmap, int idCommand, BYTE fsState, BYTE fsStyle, DWORD dwData, int iString)
{
  TBBUTTON tbButton;
  tbButton.iBitmap = iBitmap;
  tbButton.idCommand = idCommand;
  tbButton.fsState = fsState;
  tbButton.fsStyle = fsStyle;
  tbButton.dwData = dwData;
  tbButton.iString = iString;

  return tbButton;
}

void AddTBTip(HWND hwTB, UINT id, UINT iString)
{
  RECT rect;
  UINT idx=(UINT)SendMessage(hwTB, TB_COMMANDTOINDEX, id, 0);
  SendMessage(hwTB, TB_GETITEMRECT, idx, (LPARAM) (LPRECT) &rect);
  g_tbtip->AddTool(0, id, &rect, iString);
}

static void rgn_removeFromRgn(HRGN hrgn, int left, int top, int right, int bottom)
{
  HRGN rgn2=CreateRectRgn(left,top,right,bottom);
  CombineRgn(hrgn,hrgn,rgn2,RGN_DIFF);
  DeleteObject(rgn2);
}

static void AddTrayIconTip(UINT index, LPTSTR lpszTip)
{
	RECT tr = GetTrayIconRect(index);
	g_tip->AddTool(0, index, &tr, lpszTip);
}

static void UpdateTipRects(void)
{
	int i=0, n=0;

	//Walk through the list, rebuilding the tooltip rects
	int c=g_traylist.GetSize();
	while (i < c)
	{
		PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i);
		if (ptmp->fShow)
		{
			RECT tr = GetTrayIconRect(n);

			g_tip->NewToolRect(i, &tr);
			g_tip->SetToolInfo(0, n, &tr, ptmp->tip); // Decided to update tip as well
			++n;
		} else {
			// There should never exist a tooltip for a hidden tray icon
			g_tip->DelTool(i);
		}
		++i;
	}
}

bool PtInTrayIconRect(POINT pt, UINT index)
{
	RECT tr = GetTrayIconRect(index);
	return (PtInRect(&tr, pt) > 0);
}

// Returns a proper rectangle depending on the index and if large icons is used.
RECT GetTrayIconRect(UINT index)
{
	RECT tr;
	if (g_fLargeIcons)
	{
		tr.left = TRAYICONS_XOFFSET+(index*TRAYICONS_CXLARGE);
		tr.top = TRAYICONS_YOFFSET;
		tr.right = tr.left+TRAYICONS_CXLARGE;
		tr.bottom = tr.top+TRAYICONS_CYLARGE;
	} else {
		tr.left = TRAYICONS_XOFFSET+(index*TRAYICONS_CX);
		tr.top = TRAYICONS_YOFFSET;
		tr.right = tr.left+TRAYICONS_CX;
		tr.bottom = tr.top+TRAYICONS_CY;
	}
	return tr;
}

void UpdateSize(HWND hWnd)
{
	RECT r;
	//Resize to fit new display
	GetWindowRect(hWnd, &r);
	r.bottom = r.top +
		GetSystemMetrics(SM_CYSMCAPTION) +
		(GetSystemMetrics(SM_CYFRAME)*2) +
		(g_fShowToolbar?30:0) +
		(g_fLargeIcons?TRAYICONS_CYLARGE:TRAYICONS_CY) +
		TRAYICONS_YOFFSET*2 +
		(GetMenu(hWnd)?GetSystemMetrics(SM_CYMENU):0);
	// If size change makes window fall off screen, move it back in
	if (r.bottom > GetSystemMetrics(SM_CYSCREEN))
		OffsetRect(&r, 0, -(r.bottom-GetSystemMetrics(SM_CYSCREEN)));
	if (r.right > GetSystemMetrics(SM_CXSCREEN))
		OffsetRect(&r, -(r.bottom-GetSystemMetrics(SM_CYSCREEN)), 0);
	if (r.top < 0)
		OffsetRect(&r, 0, -r.top);
	if (r.left < 0)
		OffsetRect(&r, -r.left, 0);
	SetWindowPos(hWnd, 0, r.left, r.top, r.right-r.left, r.bottom-r.top, SWP_NOZORDER);
}

void MyCheckMenuItem(HMENU hmenu, UINT cmdid, bool fCheck)
{
	CheckMenuItem(hmenu, cmdid, MF_BYCOMMAND|(fCheck?MF_CHECKED:MF_UNCHECKED));
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	RECT r;
	HWND hwTB;
	static HMENU hmConfigMenu;
	static HMENU hmConfigPopup;

	switch (uMsg)
	{
	case WM_CREATE:
		{
			//LPCREATESTRUCT cs = (LPCREATESTRUCT)lParam;
			TBBUTTON aBtns[5];
			HMENU sysmenu;

			//Load config popup menu
			hmConfigMenu = LoadMenu(g_hInst, TEXT("ConfigMenu"));
			hmConfigPopup = GetSubMenu(hmConfigMenu, 0);

			sysmenu = GetSystemMenu(hWnd, FALSE);
			AppendMenu(sysmenu, MF_POPUP|MF_STRING, (UINT)hmConfigPopup,
				TEXT("C&onfiguration"));
			AppendMenu(sysmenu, MF_STRING, ID_ABOUT, TEXT("&About"));

			// Disable inappropriate menu items in window menu
			EnableMenuItem(sysmenu, SC_RESTORE, MF_BYCOMMAND|MF_GRAYED);
			EnableMenuItem(sysmenu, SC_MINIMIZE, MF_BYCOMMAND|MF_GRAYED);
			EnableMenuItem(sysmenu, SC_MAXIMIZE, MF_BYCOMMAND|MF_GRAYED);
			
			
			LoadConfig();

			SetWindowPos(hWnd, g_fAlwaysOnTop?HWND_TOPMOST:HWND_NOTOPMOST,
				0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

			// Take notice of previous config
			if (g_fShowMenu)
			{
				SetMenu(hWnd, hmConfigMenu);
				MyCheckMenuItem(hmConfigPopup, ID_SHOW_MENU, true);
			}
			MyCheckMenuItem(hmConfigPopup, ID_SHOW_TOOLBAR, g_fShowToolbar);
			MyCheckMenuItem(hmConfigPopup, ID_LARGE_ICONS, g_fLargeIcons);
			MyCheckMenuItem(hmConfigPopup, ID_SHOW_TOOLTIPS, g_fShowToolTips);
			MyCheckMenuItem(hmConfigPopup, ID_ALWAYSONTOP, g_fAlwaysOnTop);

			//Create CNxSToolTip object for use with tray icons
			g_tip = new CNxSToolTip(hWnd, g_hInst);
			if (!g_tip)
			{
				MyMsgBox(hWnd, MB_OK|MB_ICONERROR, g_szAppTitle, (LPCTSTR)IDS_ERROR_TOOLTIP);
				PostMessage(hWnd, WM_CLOSE, 0, 0);
			}
			// This call is neccessary to keep the tip from growing off the screen, but
			// it also makes the tooltip control parse CR/LF sequences.
			g_tip->SetMaxTipWidth(400);

			//Create a CNxSToolTip object just to display balloon popups
			g_balloon = new CNxSToolTip(hWnd, g_hInst, true);
			if (!g_balloon)
			{
				MyMsgBox(hWnd, MB_OK|MB_ICONERROR, g_szAppTitle, (LPCTSTR)IDS_ERROR_BALLOON);
				PostMessage(hWnd, WM_CLOSE, 0, 0);
			}
			g_tip->SetMaxTipWidth(400);

			GetClientRect(hWnd, &r);

			aBtns[0] = CreateToolBarButton(0, TBB_ABOUT, TBSTATE_ENABLED, BTNS_BUTTON, 0, 0);
			aBtns[1] = CreateToolBarButton(2, TBB_EXIT, TBSTATE_ENABLED, BTNS_BUTTON, 0, 0);
			aBtns[2] = CreateToolBarButton(0, 0, TBSTATE_ENABLED, BTNS_SEP, 0, 0);
			aBtns[3] = CreateToolBarButton(1, TBB_CONFIG, TBSTATE_ENABLED,
						BTNS_DROPDOWN|BTNS_WHOLEDROPDOWN, 0, 0);
			aBtns[4] = CreateToolBarButton(3, TBB_ALWAYSONTOP,
						TBSTATE_ENABLED|(g_fAlwaysOnTop?TBSTATE_CHECKED:0), BTNS_CHECK, 0, 0);

			hwTB = CreateToolbarEx(
				hWnd,
				WS_CHILD | CCS_BOTTOM | (g_fShowToolbar?WS_VISIBLE:0),
				IDC_TOOLBAR,
				4,
				g_hInst,
				IDB_TOOLBAR,
				aBtns, 5,
				0, 0, 16, 16,
				sizeof(TBBUTTON)); 
			SendMessage(hwTB, TB_SETEXTENDEDSTYLE, 0, (LPARAM)
				(DWORD) TBSTYLE_EX_DRAWDDARROWS);

			//Create separate CNxSToolTip for toolbar
			g_tbtip = new CNxSToolTip(hwTB, g_hInst);
			if (g_tbtip)
			{
				g_tbtip->SetMaxTipWidth(400);
				g_tbtip->Activate(g_fShowToolTips);
				SendMessage(hwTB, TB_SETTOOLTIPS, (WPARAM) (HWND) g_tbtip->GetTooltipWnd(), 0);

				AddTBTip(hwTB, TBB_ABOUT, IDS_TIP_ABOUT);
				AddTBTip(hwTB, TBB_EXIT, IDS_TIP_EXIT);
				AddTBTip(hwTB, TBB_CONFIG, IDS_TIP_CONFIG);
				AddTBTip(hwTB, TBB_ALWAYSONTOP, IDS_TIP_AOT);
			} else {
				MyMsgBox(hWnd, MB_OK|MB_ICONERROR, g_szAppTitle, (LPCTSTR)IDS_ERROR_TBTIP);
				PostMessage(hWnd, WM_CLOSE, 0, 0);
			}

			UpdateSize(hWnd);

			//Tell applications to add tray icons
			SendMessage(HWND_BROADCAST, RegisterWindowMessage("TaskbarCreated"), 0, 0);
		}
		break;
	case WM_DESTROY:
		{
			//save configuration to registry
			SaveConfig();

			int i=0;
			while (i = g_traylist.GetSize())
			{
				PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i-1);
				if (ptmp)
				{
					// Free all resources bound to tray icon
					g_tip->DelTool(ptmp->id);
					GlobalFree((HGLOBAL)ptmp);
					g_traylist.Del(i-1);
				}
			}

			// Tooltip clean up
			if (g_tip) delete g_tip;
			if (g_tbtip) delete g_tbtip;
			if (g_balloon) delete g_balloon;

			// menu clean up
			DestroyMenu(hmConfigMenu);
			DestroyMenu(hmConfigPopup);

			hwTB = GetDlgItem(hWnd, IDC_TOOLBAR);
			DestroyWindow(hwTB);

			PostQuitMessage(0);
		}
		break;
	case WM_SIZE:
		{
			if (WS_VISIBLE) SendDlgItemMessage(hWnd, IDC_TOOLBAR, TB_AUTOSIZE, 0, 0);
		}
		break;
	case WM_GETMINMAXINFO:
		{
			LPMINMAXINFO lpmmi = (LPMINMAXINFO) lParam;
			lpmmi->ptMaxTrackSize.y = lpmmi->ptMinTrackSize.y = GetSystemMetrics(SM_CYSMCAPTION) +
				(GetSystemMetrics(SM_CYFRAME)*2) +
				(g_fShowToolbar?30:0) +
				(g_fLargeIcons?TRAYICONS_CYLARGE:TRAYICONS_CY) +
				TRAYICONS_YOFFSET*2 +
				(GetMenu(hWnd)?GetSystemMetrics(SM_CYMENU):0);
		}
		break;
	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case TBB_ABOUT:
		case ID_ABOUT:
			DialogBoxParam(g_hInst, "AboutDlg", hWnd, AboutDlgProc, NULL);
			break;
		case TBB_EXIT:
			PostMessage(hWnd, WM_CLOSE, 0, 0);
			break;
		case TBB_ALWAYSONTOP:
		case ID_ALWAYSONTOP:
			{
				g_fAlwaysOnTop = !g_fAlwaysOnTop; //toggle
				hwTB = GetDlgItem(hWnd, IDC_TOOLBAR);
				if (g_fAlwaysOnTop)
					SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
				else
					SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
				
				MyCheckMenuItem(hmConfigPopup, ID_ALWAYSONTOP, g_fAlwaysOnTop);

				// If call is from menu, then update toolbar button as well
				if (HIWORD(wParam)==0)
				{
					SendMessage(hwTB, TB_SETSTATE, TBB_ALWAYSONTOP,
						TBSTATE_ENABLED|(g_fAlwaysOnTop?TBSTATE_CHECKED:0));
				}
			}
			break;
		case ID_LARGE_ICONS:
			g_fLargeIcons = !g_fLargeIcons; //toggle
			MyCheckMenuItem(hmConfigPopup, ID_LARGE_ICONS, g_fLargeIcons);
			UpdateTipRects();
			UpdateSize(hWnd);
			InvalidateRect(hWnd, NULL, TRUE);
			break;
		case ID_SHOW_MENU:
			g_fShowMenu = !g_fShowMenu; //toggle
			if (g_fShowMenu)
				SetMenu(hWnd, hmConfigMenu);
			else
				SetMenu(hWnd, NULL);
			MyCheckMenuItem(hmConfigPopup, ID_SHOW_MENU, g_fShowMenu);
			UpdateSize(hWnd);
			break;
		case ID_SHOW_TOOLBAR:
			g_fShowToolbar = !g_fShowToolbar; //toggle
			hwTB = GetDlgItem(hWnd, IDC_TOOLBAR);
			ShowWindow(hwTB, g_fShowToolbar?SW_SHOWNA:SW_HIDE);
			MyCheckMenuItem(hmConfigPopup, ID_SHOW_TOOLBAR, g_fShowToolbar);
			UpdateSize(hWnd);
			break;
		case ID_SHOW_TOOLTIPS:
			g_fShowToolTips = !g_fShowToolTips; //toggle
			g_tbtip->Activate(g_fShowToolTips);
			MyCheckMenuItem(hmConfigPopup, ID_SHOW_TOOLTIPS, g_fShowToolTips);
			break;
		}
		break;
	case WM_SYSCOMMAND:
		{
			PostMessage(hWnd, WM_COMMAND, wParam, 0);
		}
		break;
	case WM_NOTIFY:
		{
			if ((*(LPNMHDR)lParam).code == TBN_DROPDOWN)
			{
				TBNOTIFY *ptbn = (TBNOTIFY *)lParam;
				if (ptbn->iItem == TBB_CONFIG)
				{
					RECT r;
					UINT idx=(UINT)SendDlgItemMessage(hWnd, IDC_TOOLBAR, TB_COMMANDTOINDEX, ptbn->iItem, 0);
					SendDlgItemMessage(hWnd, IDC_TOOLBAR, TB_GETITEMRECT, idx,
						(LPARAM) (LPRECT) &r);
					MapWindowPoints(GetDlgItem(hWnd, IDC_TOOLBAR), HWND_DESKTOP, (LPPOINT)&r, 2);

					
					TrackPopupMenu(hmConfigPopup, TPM_LEFTBUTTON, r.left, r.bottom, 0, hWnd, NULL);
				}
				return TBDDRET_DEFAULT;
			}
#ifdef NOTUSED
			if ((*(LPNMHDR)lParam).code == TTN_SHOW)
			{
				if ((*(LPNMHDR)lParam).hwndFrom == g_balloon->GetTooltipWnd())
				{
					POINT pt={0,0};
					MyMsgBox(hWnd, 0, "Got NM_CLICK!", NULL);
				}
			}
#endif
		}
		break;
	case WM_MOUSEMOVE:
	case WM_LBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_LBUTTONDBLCLK:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONUP:
	case WM_RBUTTONDBLCLK:
		{
			POINT pt;
			int i=0, n=0, c;
			GetCursorPos(&pt);
			ScreenToClient(hWnd, &pt);

			c = g_traylist.GetSize();
			while (i < c)
			{
				PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i);

				if (ptmp && ptmp->fShow)
				{
					if (PtInTrayIconRect(pt, n++))
					{
						//Found a match, pass on mouse messages
						ReleaseCapture();
						if (uMsg != WM_MOUSEMOVE) SetForegroundWindow(ptmp->owner);
						PostMessage(ptmp->owner, ptmp->callbackmsg, ptmp->id, uMsg);
						return 0;
					}
				}
				++i;
			}
		}
		break;
	case WM_ERASEBKGND:
		GetClientRect(hWnd, &r);
		FillRect((HDC)wParam, &r, (HBRUSH)GetStockObject(WHITE_BRUSH));
		return 1;
	case WM_PAINT:
		{
			PAINTSTRUCT ps;
			int i=0, n=0, c;
			HDC hdc;

			hdc=BeginPaint(hWnd, &ps);
			
			HRGN hrgn=NULL;
			if(ps.fErase)
			{
				RECT r=ps.rcPaint;
				hrgn=CreateRectRgnIndirect(&r);
			}

			c=g_traylist.GetSize();
			while (i < c)
			{
				PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i);
				if (ptmp && ptmp->fShow)
				{
					if (g_fLargeIcons)
					{
						DrawIconEx(hdc,
							TRAYICONS_XOFFSET+(n*TRAYICONS_CXLARGE), TRAYICONS_YOFFSET,
							ptmp->icon,
							TRAYICONS_CXLARGE, TRAYICONS_CYLARGE,
							0, (HBRUSH)GetStockObject(WHITE_BRUSH), 0);
						//clip out icon
						rgn_removeFromRgn(hrgn, TRAYICONS_XOFFSET+(n*TRAYICONS_CXLARGE), TRAYICONS_YOFFSET,
							TRAYICONS_XOFFSET+(n*TRAYICONS_CXLARGE)+TRAYICONS_CXLARGE, TRAYICONS_YOFFSET+TRAYICONS_CYLARGE);
					} else {
						DrawIconEx(hdc,
							TRAYICONS_XOFFSET+(n*TRAYICONS_CX), TRAYICONS_YOFFSET,
							ptmp->icon,
							TRAYICONS_CX, TRAYICONS_CY,
							0, (HBRUSH)GetStockObject(WHITE_BRUSH), 0);
						//clip out icon
						rgn_removeFromRgn(hrgn, TRAYICONS_XOFFSET+(n*TRAYICONS_CX), TRAYICONS_YOFFSET,
							TRAYICONS_XOFFSET+(n*TRAYICONS_CX)+TRAYICONS_CX, TRAYICONS_YOFFSET+TRAYICONS_CY);
					}
					++n;
				}
				++i;
			}

			if(hrgn)
			{
				//erase bkgnd while clipping out our own drawn stuff (for flickerless display)
				HBRUSH b=CreateSolidBrush(0x00808080);
				FillRgn(ps.hdc, hrgn, b);
				DeleteObject(b);
				DeleteObject(hrgn);
			}

			EndPaint(hWnd, &ps);
		}
		return 0;
	case WM_COPYDATA:
		{
			PCOPYDATASTRUCT lpcds = (PCOPYDATASTRUCT) lParam;
			PMYNOTIFYICONDATA pmynid = (PMYNOTIFYICONDATA)lpcds->lpData;

			if (pmynid->nid.cbSize != NOTIFYICONDATAW_REAL_SIZE) return 0;

			if (pmynid->dwTrayMsg == NIM_ADD)
			{
				PTRAYICONSTRUCT pti;

				int i;
				int c = g_traylist.GetSize();
				for (i=0; i<c; i++)
				{
					PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i);
					if (ptmp && ptmp->id == pmynid->nid.uID &&
						ptmp->owner == pmynid->nid.hWnd)
					{
						//Tray icon already exists. Fail the call!
						return 0;
					}
				}

				pti = (PTRAYICONSTRUCT)GlobalAlloc(GPTR, sizeof(TRAYICONSTRUCT));
				if (!pti) return 0;
				pti->id = pmynid->nid.uID;
				pti->owner = pmynid->nid.hWnd;
				pti->icon = 0;
				pti->tip[0] = 0;
				pti->callbackmsg = 0;
				pti->fShow = true;

				if (pmynid->nid.uFlags & NIF_MESSAGE)
				{
					pti->callbackmsg = pmynid->nid.uCallbackMessage;
				}
				if (pmynid->nid.uFlags & NIF_STATE)
				{
					if (pmynid->nid.dwStateMask & NIS_HIDDEN)
					{
						pti->fShow = !(pmynid->nid.dwState & NIS_HIDDEN);
					}
				}
				if (pmynid->nid.uFlags & NIF_TIP && pti->fShow)
				{
					WideCharToMultiByte(CP_ACP, 0, pmynid->nid.szTip, -1,
						pti->tip, sizeof(pti->tip), NULL, NULL);

					AddTrayIconTip(g_traylist.GetSize(), pti->tip);
				}
				if (pmynid->nid.uFlags & NIF_ICON)
				{
					pti->icon = CopyIcon(pmynid->nid.hIcon);
				}

				g_traylist.Add(pti);

				//Update display
				InvalidateRect(hWnd, NULL, TRUE);
			}
			else if (pmynid->dwTrayMsg == NIM_MODIFY)
			{
				int i=0;
				int c = g_traylist.GetSize();
				while (i < c)
				{
					PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i);
					if (ptmp && ptmp->id == pmynid->nid.uID &&
						ptmp->owner == pmynid->nid.hWnd)
					{
						// We found a match. Modify it.
						if (pmynid->nid.uFlags & NIF_MESSAGE)
						{
							ptmp->callbackmsg = pmynid->nid.uCallbackMessage;
						}
						if (pmynid->nid.uFlags & NIF_STATE)
						{
							if (pmynid->nid.dwStateMask & NIS_HIDDEN)
							{
								ptmp->fShow = !(pmynid->nid.dwState & NIS_HIDDEN);
								if (ptmp->fShow)
									//Add tool since tray icon is visible again
									AddTrayIconTip(i, ptmp->tip);
								else
									// Remove tool since tray icon is hidden
									g_tip->DelTool(i);

								//Update the tooltips for the other tray icons
								UpdateTipRects();

								//Full refresh
								InvalidateRect(hWnd, NULL, TRUE);
							}
							//if (pmynid->nid.dwStateMask & NIS_SHAREDICON)...
						}
						if (pmynid->nid.uFlags & NIF_TIP)
						{
							bool fToolExists = (ptmp->tip[0] > 0);
							WideCharToMultiByte(CP_ACP, 0, pmynid->nid.szTip, -1,
								ptmp->tip, sizeof(ptmp->tip), NULL, NULL);

							if (fToolExists)
							{
								g_tip->UpdateTipText(i, ptmp->tip);
							}
							else if (ptmp->fShow)
							{
								AddTrayIconTip(i, ptmp->tip);
								//Update the tooltips for the other tray icons
								UpdateTipRects();
							}
						}
						if (pmynid->nid.uFlags & NIF_ICON)
						{
							ptmp->icon = CopyIcon(pmynid->nid.hIcon);
						}
						if (pmynid->nid.uFlags & NIF_INFO)
						{
							TCHAR szText[256];
							TCHAR szTitle[128];
							DWORD dwFlags=NIIF_NONE;
							POINT pt;
							RECT tr = GetTrayIconRect(i);

							if (g_fLargeIcons)
							{
								pt.x = tr.left+(TRAYICONS_CXLARGE/2);
								pt.y = tr.top+(TRAYICONS_CYLARGE/2);
							}
							else
							{
								pt.x = tr.left+(TRAYICONS_CX/2);
								pt.y = tr.top+(TRAYICONS_CY/2);
							}
							ClientToScreen(hWnd, &pt);

							WideCharToMultiByte(CP_ACP, 0, pmynid->nid.szInfo, -1,
								szText, sizeof(ptmp->tip), NULL, NULL);

							WideCharToMultiByte(CP_ACP, 0, pmynid->nid.szInfoTitle, -1,
								szTitle, sizeof(ptmp->tip), NULL, NULL);

							if (pmynid->nid.dwInfoFlags & NIIF_INFO)
								dwFlags = TTI_INFO;
							else if (pmynid->nid.dwInfoFlags & NIIF_ERROR)
								dwFlags = TTI_ERROR;
							else if (pmynid->nid.dwInfoFlags & NIIF_WARNING)
								dwFlags = TTI_WARNING;

							g_balloon->ShowBalloon(szText, szTitle, dwFlags, pt);
						}
						

						//Update display
						{
							RECT r;// = GetTrayIconRect(i);
							GetClientRect(hWnd, &r);
							r.top = TRAYICONS_YOFFSET;
							r.left = TRAYICONS_XOFFSET;
							r.bottom = TRAYICONS_YOFFSET+(g_fLargeIcons?TRAYICONS_CYLARGE:TRAYICONS_CY);
							InvalidateRect(hWnd, &r, FALSE);
							UpdateWindow(hWnd);
						}
						break;
					}
					++i;
				}
			}
			else if (pmynid->dwTrayMsg == NIM_DELETE)
			{
				int i=0;
				int c = g_traylist.GetSize();
				while (i < c)
				{
					PTRAYICONSTRUCT ptmp = (PTRAYICONSTRUCT)g_traylist.Get(i);
					if (ptmp && ptmp->id == pmynid->nid.uID &&
						ptmp->owner == pmynid->nid.hWnd)
					{
						// We found a match. Remove it.
						g_tip->DelTool(i);
						GlobalFree((HGLOBAL)ptmp);
						g_traylist.Del(i);
						UpdateTipRects(); //Update the tooltips for the other tray icons
						InvalidateRect(hWnd, NULL, TRUE);
						break;
					}
					++i;
				}
			}
		}
		return 1;
	}
	return CallWindowProc(DefWindowProc, hWnd, uMsg, wParam, lParam);
}

INT_PTR CALLBACK AboutDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg)
	{
	case WM_INITDIALOG:
		{
			LOGFONT lf;
			ZeroMemory(&lf, sizeof(LOGFONT));
			// Fix the link "STATIC"
			lstrcpyn(lf.lfFaceName, "MS Shell Dlg", LF_FACESIZE);
			lf.lfHeight = -11;
			lf.lfUnderline++;
			SendDlgItemMessage(hDlg, IDC_LINK, WM_SETFONT, (WPARAM)
				(HFONT)CreateFontIndirect(&lf), MAKELPARAM(TRUE, 0));
		}
		return TRUE;
	case WM_COMMAND:
		if (HIWORD(wParam) == BN_CLICKED && LOWORD(wParam)==IDOK)
			EndDialog(hDlg, 0);

		if (LOWORD(wParam)==IDC_LINK && HIWORD(wParam) == STN_CLICKED)
		{
			fClick = 0;
			TCHAR szText[256];
			GetDlgItemText(hDlg, IDC_LINK, szText, sizeof(szText)/sizeof(szText[0]));
			ShellExecute(hDlg, "open", szText, NULL, NULL, SW_SHOWNORMAL);
		}

		break;
	case WM_CTLCOLORSTATIC:
		if (GetDlgItem(hDlg, IDC_LINK) == (HWND)lParam)
		{
			static HBRUSH hbr=CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
			SetTextColor((HDC)wParam, GetSysColor(COLOR_HOTLIGHT));
			SetBkMode((HDC)wParam, TRANSPARENT);
			return (BOOL)hbr;
		}
		break;
	case WM_SETCURSOR:
		if (GetDlgItem(hDlg, IDC_LINK) == (HWND)wParam)
		{
			SetCursor(LoadCursor(NULL, IDC_HAND));
			SetWindowLong(hDlg, DWL_MSGRESULT, 1);
			return TRUE;
		}
		break;
	case WM_RBUTTONUP:
		{
			DefWindowProc(hDlg, WM_SYSCOMMAND, SC_KEYMENU, 0);
		}
		break;
	// Since the About box got no caption we must provide a means for
	// the user to move the dialog around.
	case WM_NCHITTEST:
		if (DefWindowProc(hDlg, WM_NCHITTEST, wParam, lParam)==HTCLIENT)
		{
			POINT pt;
			pt.x = LOWORD(lParam);
			pt.y = HIWORD(lParam);
			ScreenToClient(hDlg, &pt);
			if (pt.y <= 15)
			{
				SetWindowLong(hDlg, DWL_MSGRESULT, HTCAPTION);
				return TRUE;
			}
		}
		break;
	}
	return FALSE;
}

// UTILITY FUNCTIONS

void *CItemList::Add(void *i)
{
	if (!m_list || !(m_size&31))
	{
		//m_list=(void**)::realloc(m_list, sizeof(void*) * (m_size+32));
		m_list=(void**)::HeapReAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, m_list, sizeof(void*) * (m_size+32));
	}
	m_list[m_size++]=i;
	return i;
}
void *CItemList::Get(int w)
{
	if (w >= 0 && w < m_size)
		return m_list[w];
	return NULL;
}

void CItemList::Del(int idx)
{
	if (m_list && idx >= 0 && idx < m_size)
	{
		m_size--;
		if (idx != m_size)
			//::memcpy(m_list+idx, m_list+idx+1, sizeof(void *) * (m_size-idx));
			CopyMemory(m_list+idx, m_list+idx+1, sizeof(void *) * (m_size-idx));

		if (!(m_size&31)&&m_size) // resize down
		{
			//m_list=(void**)::realloc(m_list, sizeof(void*) * m_size);
			m_list=(void**)::HeapReAlloc(GetProcessHeap(), 0, m_list, sizeof(void*) * m_size);
		}
	}
}

// My ultra-leet msgbox proc
// lpszText may specify a string list ID which will be loaded and displayed, or
// just plain text. Formats text using wvsprinf.
int MyMsgBox(HWND hwndOwner, DWORD dwStyle, LPCTSTR lpszTitle, LPCTSTR lpszText, ...)
{
	TCHAR szBuf[512];
	MSGBOXPARAMS mb;
	va_list va;
	va_start(va, lpszText);

	if (IS_INTRESOURCE(lpszText))
	{
		TCHAR szStr[256];
		LoadString(g_hInst, (UINT)lpszText, szStr, sizeof(szStr));
		wvsprintf(szBuf, szStr, va);
	} else {
		wvsprintf(szBuf, lpszText, va);
	}	
	va_end(va);
	
	mb.cbSize = sizeof(MSGBOXPARAMS);
	mb.hInstance = g_hInst;
	mb.dwStyle = (dwStyle & ~(MB_ICONINFORMATION|MB_ICONWARNING|MB_ICONERROR))|MB_USERICON;
	mb.lpszCaption = lpszTitle;
	mb.lpszText = szBuf;
	mb.hwndOwner = hwndOwner;
	mb.lpszIcon = (LPCTSTR)IDI_MAINICON;
	return MessageBoxIndirect(&mb);
}

bool RegSetDWORDValue(HKEY hkey, LPCTSTR lpValueName, DWORD value)
{
	DWORD dwValue;
	dwValue = value;
	return ERROR_SUCCESS==RegSetValueEx(hkey, lpValueName, NULL, REG_DWORD,
		(LPBYTE)(LPDWORD)&dwValue, sizeof(DWORD));
}

// Returns DefaultValue if value does not exists or another error.
DWORD RegGetDWORDValue(HKEY hkey, LPCTSTR lpValueName, DWORD DefaultValue)
{
	DWORD dwType=REG_DWORD;
	DWORD dwSize=sizeof(DWORD);
	DWORD dwValue = DefaultValue;
	if (ERROR_SUCCESS != RegQueryValueEx(hkey, lpValueName, NULL, &dwType,
		(LPBYTE)(LPDWORD)&dwValue, &dwSize))
		return DefaultValue;
	return dwValue > 0;
}

bool RegSetString(HKEY hkey, LPCTSTR lpValueName, LPCTSTR value, DWORD length)
{
	return RegSetValueEx(hkey, lpValueName, NULL, REG_SZ,
		(LPBYTE)value, length) == ERROR_SUCCESS;
}

// Returns true and GlobalAlloc()'ed data in retvalue if value exists
bool RegGetString(HKEY hkey, LPCTSTR lpValueName, LPTSTR *retvalue)
{
	DWORD dwType=0;
	DWORD dwSize=0;
	LPTSTR lpszRetBuf;

	if (RegQueryValueEx(hkey, lpValueName, NULL, &dwType, NULL, &dwSize) == ERROR_SUCCESS && dwType==REG_SZ)
	{
		lpszRetBuf = (LPTSTR)GlobalAlloc(GPTR, dwSize);

		if (RegQueryValueEx(hkey, lpValueName, NULL, &dwType, (LPBYTE)(LPTSTR)lpszRetBuf, &dwSize) == ERROR_SUCCESS)
		{
			*retvalue = lpszRetBuf;
			return true;
		}

		GlobalFree((HGLOBAL)lpszRetBuf);
	}
	return false;
}


bool SaveConfig(void)
{
	HKEY hkey;

	if (ERROR_SUCCESS != RegCreateKeyEx(HKEY_CURRENT_USER, TEXT("Software\\Saivert\\TrayHole"),
		0, NULL, 0, KEY_ALL_ACCESS,	NULL, &hkey, NULL))
		return false;

	RegSetDWORDValue(hkey, TEXT("LargeIcons"),    g_fLargeIcons);
	RegSetDWORDValue(hkey, TEXT("ShowMenu"),      g_fShowMenu);
	RegSetDWORDValue(hkey, TEXT("ShowToolbar"),   g_fShowToolbar);
	RegSetDWORDValue(hkey, TEXT("ShowToolTips"),  g_fShowToolTips);
	RegSetDWORDValue(hkey, TEXT("AlwaysOnTop"),   g_fAlwaysOnTop);	


	//Save version string
	RegSetString(hkey, TEXT(""), TEXT("TrayHole v1.0"), sizeof(TEXT("TrayHole v1.0")));

	RegCloseKey(hkey);

	return true; //success!
}

bool LoadConfig(void)
{
	HKEY hkey;
	TCHAR szBuf[256];
	LPTSTR ret;

	if (ERROR_SUCCESS != RegCreateKeyEx(HKEY_CURRENT_USER, TEXT("Software\\Saivert\\TrayHole"),
		0, NULL, 0, KEY_ALL_ACCESS,	NULL, &hkey, NULL))
		return false;

	//Check version and nuke registry settings if user upgraded TrayHole
	if (RegGetString(hkey, TEXT(""), &ret))
	{
		lstrcpyn(szBuf, ret, sizeof(szBuf));
		GlobalFree((HGLOBAL)ret);

		if (lstrcmpi(szBuf, TEXT("TrayHole v1.0"))) return false;
	} else {
		return false;
	}


	g_fLargeIcons    = !!RegGetDWORDValue(hkey, TEXT("LargeIcons"),   g_fLargeIcons);
	g_fShowMenu      = !!RegGetDWORDValue(hkey, TEXT("ShowMenu"),     g_fShowMenu);
	g_fShowToolbar   = !!RegGetDWORDValue(hkey, TEXT("ShowToolbar"),  g_fShowToolbar);
	g_fShowToolTips  = !!RegGetDWORDValue(hkey, TEXT("ShowToolTips"), g_fShowToolTips);
	g_fAlwaysOnTop   = !!RegGetDWORDValue(hkey, TEXT("AlwaysOnTop"),  g_fAlwaysOnTop);

	RegCloseKey(hkey);

	return true; //success!
}
