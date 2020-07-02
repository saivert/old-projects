/*
** Written by Saivert
**
** Read license in .H file.
*/

//Uncomment next line if building under MS Visual C++
#include "StdAfx.h"

#include <windows.h>
#include "NxSToolTip.h"

// - ctor & dtor -
CNxSToolTip::CNxSToolTip(HWND hwndOwner, bool IsBalloonPopup)
{
	CNxSToolTip(hwndOwner, GetModuleHandle(NULL), IsBalloonPopup);
}

CNxSToolTip::CNxSToolTip(HWND hwndOwner, HINSTANCE hinst, bool IsBalloonPopup)
{
	m_hwndOwner = hwndOwner;
	m_hinst = hinst;
	m_IsBalloonPopup = IsBalloonPopup;

	//Variables used to backup the g_* ones.
	m_old_g_hwndTT = NULL;
	m_old_g_hwndDlg = NULL;
	m_old_g_hhk = NULL;

	m_hwnd = CreateWindowEx(
		WS_EX_TOOLWINDOW|WS_EX_TOPMOST,// extended window style
		TOOLTIPS_CLASS,	// window class
		(LPSTR) NULL,	// caption
		WS_POPUP| TTS_ALWAYSTIP | (m_IsBalloonPopup?TTS_BALLOON|TTS_CLOSE|TTS_NOPREFIX:0),
		CW_USEDEFAULT,	// left
		CW_USEDEFAULT,	// top
		CW_USEDEFAULT,	// width
		CW_USEDEFAULT,	// height
		hwndOwner,		// parent (*)
		(HMENU) NULL,	// menu
		hinst,			// hInstance
		NULL);			// lpParam

// *) Not needed, but I do this so the tooltip will stay above it's window even if
//	  the owner window has the WS_EX_TOPMOST style. It's not a child window anyway...

	if (m_IsBalloonPopup)
	{
		AddTool(TTF_TRACK, 1, NULL, (LPTSTR)"");
	}
}

CNxSToolTip::~CNxSToolTip()
{
	if (m_IsBalloonPopup)
	{
		DelTool(1);
	}

	DestroyWindow(m_hwnd);
}

//- methods -

//- AddTool -
BOOL CNxSToolTip::_AddTool(UINT uFlags, UINT uId, LPRECT prect, LPTSTR lpszText, HINSTANCE hinst)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.uFlags = uFlags;
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	if (prect) ti.rect = *prect;
	ti.hinst = hinst;
	ti.lpszText = lpszText;
	return (BOOL)SendMessage(m_hwnd, TTM_ADDTOOL, 0, (LPARAM)&ti);
}

BOOL CNxSToolTip::AddTool(UINT uFlags, UINT uId, LPRECT prect, LPTSTR lpszText)
{
	return _AddTool(uFlags, uId, prect, lpszText, NULL);
}

BOOL CNxSToolTip::AddTool(UINT uFlags, UINT uId, LPRECT prect, UINT strId)
{
	return _AddTool(uFlags, uId, prect, MAKEINTRESOURCE(strId), m_hinst);
}

//- SetToolInfo -
BOOL CNxSToolTip::_SetToolInfo(UINT uFlags, UINT uId, LPRECT prect, LPTSTR lpszText, HINSTANCE hinst)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.uFlags = uFlags;
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	if (prect) ti.rect = *prect;
	ti.hinst = hinst;
	ti.lpszText = lpszText;
	return (BOOL)SendMessage(m_hwnd, TTM_SETTOOLINFO, 0, (LPARAM)&ti);
}

BOOL CNxSToolTip::SetToolInfo(UINT uFlags, UINT uId, LPRECT prect, LPTSTR lpszText)
{
	return _SetToolInfo(uFlags, uId, prect, lpszText, NULL);
}

BOOL CNxSToolTip::SetToolInfo(UINT uFlags, UINT uId, LPRECT prect, UINT strId)
{
	return _SetToolInfo(uFlags, uId, prect, MAKEINTRESOURCE(strId), m_hinst);
}

void CNxSToolTip::DelTool(UINT uId)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	SendMessage(m_hwnd, TTM_DELTOOL, 0, (LPARAM)&ti);
}

char* CNxSToolTip::GetText(UINT uId)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	SendMessage(m_hwnd, TTM_GETTEXT, 0, (LPARAM)&ti);
	return ti.lpszText;
}

BOOL CNxSToolTip::GetInfo(UINT uId, LPRECT prect, char **lpszText)
{
	TOOLINFO ti;
	LRESULT res;
	ti.cbSize = sizeof(TOOLINFO);
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	res = SendMessage(m_hwnd, TTM_GETTOOLINFO, 0, (LPARAM)&ti);
	if (res)
	{
		if (lpszText) *lpszText = ti.lpszText;
		if (prect) CopyRect(prect, &ti.rect);
	}
	return (BOOL)res;
}

BOOL CNxSToolTip::HitTest(POINT point, LPRECT prect, char **lpszText)
{
	TTHITTESTINFO tthti;
	LRESULT res;
	tthti.hwnd = m_hwndOwner;
	tthti.pt = point;
	tthti.ti.cbSize = sizeof(TOOLINFO);
	res = SendMessage(m_hwnd, TTM_HITTEST, 0, (LPARAM)&tthti);
	if (res)
	{
		if (lpszText) *lpszText = tthti.ti.lpszText;
		if (prect) CopyRect(prect, &tthti.ti.rect);
	}
	return (BOOL)res;
}

void CNxSToolTip::SetDelayTime(UINT uAutoPop, UINT uInitial, UINT uReshow)
{
	SendMessage(m_hwnd, TTM_SETDELAYTIME, TTDT_AUTOPOP, uAutoPop);
	SendMessage(m_hwnd, TTM_SETDELAYTIME, TTDT_INITIAL, uInitial);
	SendMessage(m_hwnd, TTM_SETDELAYTIME, TTDT_RESHOW, uReshow);
}
void CNxSToolTip::SetDelayTime(UINT uAutomatic)
{
	SendMessage(m_hwnd, TTM_SETDELAYTIME, TTDT_AUTOMATIC, uAutomatic);
}

void CNxSToolTip::_UpdateTipText(UINT uId, char* lpszText, HINSTANCE hinst)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	ti.hinst = hinst;
	ti.lpszText = lpszText;

	SendMessage(m_hwnd, TTM_UPDATETIPTEXT, 0, (LPARAM)&ti);
}

void CNxSToolTip::UpdateTipText(UINT uId, char* lpszText)
{
	_UpdateTipText(uId, lpszText, NULL);
}

void CNxSToolTip::UpdateTipText(UINT uId, UINT strId)
{
	_UpdateTipText(uId, MAKEINTRESOURCE(strId), m_hinst);
}

void CNxSToolTip::NewToolRect(UINT uId, LPRECT newrect)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;
	if (newrect) ti.rect = *newrect;

	SendMessage(m_hwnd, TTM_NEWTOOLRECT, 0, (LPARAM)&ti);
}

void CNxSToolTip::TrackActivate(UINT uId, bool fActive)
{
	TOOLINFO ti;
	ti.cbSize = sizeof(TOOLINFO);
	ti.hwnd = m_hwndOwner;
	ti.uId = uId;

	SendMessage(m_hwnd, TTM_TRACKACTIVATE, (WPARAM)fActive?1:0, (LPARAM)(LPTOOLINFO)&ti);
}

void CNxSToolTip::TrackPosition(POINT pt)
{
	SendMessage(m_hwnd, TTM_TRACKPOSITION, 0, MAKELPARAM(pt.x, pt.y));
}

void CNxSToolTip::ShowBalloon(LPCTSTR lpszText, LPCTSTR lpszTitle, DWORD dwFlags, POINT pt)
{
	// Reject the call if this isn't a Balloon Tooltip instance
	if (!m_IsBalloonPopup) return;
	
	if (!lpszText || !lpszText[0])
	{
		TrackActivate(1, false);
	}
	else
	{
		RECT r;

		if (lpszTitle && lpszTitle[0])
			SendMessage(m_hwnd, TTM_SETTITLE, dwFlags, (LPARAM)(LPCTSTR)lpszTitle);
		else
			SendMessage(m_hwnd, TTM_SETTITLE, 0, 0);
		
		(*(LPPOINT)&r) = pt;
		r.right = r.left + 1;
		r.bottom = r.top + 1;


		UpdateTipText(1, (LPTSTR)lpszText);

		TrackActivate(1, true);
		TrackPosition(pt);
	}
}

void CNxSToolTip::RelayEvent(LPMSG pmsg)
{
	switch (pmsg->message)
	{
	case WM_MOUSEMOVE:
	case WM_LBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONUP:
		SendMessage(m_hwnd, TTM_RELAYEVENT, 0, (LPARAM)pmsg);
		break;
	}
}

BOOL WINAPI CNxSToolTip::AddToolInfo_EnumChild(HWND hwndCtrl, LPARAM lParam)
{ 
	DWORD dwFlags;
	char szBuf[NXSTOOLTIP_MAXLOADSTRING];

	if (((CNxSToolTip*)lParam)->m_fSubClass)
		dwFlags = TTF_IDISHWND|TTF_SUBCLASS;
	else
		dwFlags = TTF_IDISHWND;

	//Only handles 256 byte long strings:
	//((CNxSToolTip*)lParam)->AddTool(dwFlags, (UINT)hwndCtrl, NULL, GetDlgCtrlID(hwndCtrl));

	//Here we load the string ourself to handle NXSTOOLTIP_MAXLOADSTRING bytes in strings.
	if ( LoadString(((CNxSToolTip*)lParam)->m_hinst, GetDlgCtrlID(hwndCtrl), szBuf, sizeof(szBuf)) )
		((CNxSToolTip*)lParam)->AddTool(dwFlags, (UINT)hwndCtrl, NULL, szBuf);
	return TRUE;
}

void CNxSToolTip::AddDialogControls(bool fSubClass)
{
	m_fSubClass = fSubClass;
	EnumChildWindows(m_hwndOwner, AddToolInfo_EnumChild, (LPARAM)this);
}

// These variables need to be guarded by private
// member variables in CNxSToolTip.
HWND g_hwndDlg=0;
HHOOK g_hhk=0;
HWND g_hwndTT=0;

void CNxSToolTip::InstallHook(void)
{
	//Backup current value, if any
	if (g_hwndTT) m_old_g_hwndTT = g_hwndTT;
	if (g_hwndDlg) m_old_g_hwndDlg = g_hwndDlg;
	if (g_hhk) m_old_g_hhk = g_hhk;

	g_hwndTT = m_hwnd;
	g_hwndDlg = m_hwndOwner;
    g_hhk = SetWindowsHookEx(WH_GETMESSAGE, GetMsgProc,
        (HINSTANCE) NULL, GetCurrentThreadId());
}

void CNxSToolTip::UninstallHook(void)
{
	UnhookWindowsHookEx(g_hhk);

	//Restore previous value, if any
	if (m_old_g_hwndTT) g_hwndTT = m_old_g_hwndTT;
	if (m_old_g_hwndDlg) g_hwndDlg = m_old_g_hwndDlg;
	if (m_old_g_hhk) g_hhk = m_old_g_hhk;

}


//This static function is used by InstallHook
LRESULT CALLBACK CNxSToolTip::GetMsgProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    MSG *lpmsg;
	
    lpmsg = (MSG *) lParam;
    if (nCode < 0 || !(IsChild(g_hwndDlg, lpmsg->hwnd)))
        return (CallNextHookEx(g_hhk, nCode, wParam, lParam));
	
    switch (lpmsg->message)
	{
	case WM_MOUSEMOVE:
	case WM_LBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONUP:
		if (g_hwndTT != NULL)
			SendMessage(g_hwndTT, TTM_RELAYEVENT, 0,
			(LPARAM) (LPMSG) lpmsg);
		break;
	default:
		break;
    }
    return (CallNextHookEx(g_hhk, nCode, wParam, lParam));
}

//- properties -

LONG CNxSToolTip::SetStyle(LONG style)
{
	return SetWindowLong(m_hwnd, GWL_STYLE, style);
}

LONG CNxSToolTip::GetStyle(void)
{
	return GetWindowLong(m_hwnd, GWL_STYLE);
}

HWND CNxSToolTip::SetOwnerWnd(HWND hwndNewOwner)
{
	HWND hwndTemp;

	hwndTemp = m_hwndOwner;
	if (IsWindow(hwndNewOwner))
		m_hwndOwner = hwndNewOwner;
	return hwndTemp;
}
