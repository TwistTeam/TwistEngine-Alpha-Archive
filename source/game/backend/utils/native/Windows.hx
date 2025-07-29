package game.backend.utils.native;

import flixel.util.FlxColor;

#if CPP_WINDOWS
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows" />
	<lib name="shell32.lib" if="windows" />
	<lib name="gdi32.lib" if="windows" />
	<lib name="ole32.lib" if="windows" />
	<lib name="uxtheme.lib" if="windows" />
</target>
')

// majority is taken from microsofts doc
@:cppFileCode('
#include "combaseapi.h"
#include "mmdeviceapi.h"
#include <Shlobj.h>
#include <Windows.h>
#include <cstdio>
#include <dwmapi.h>
#include <iostream>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <strsafe.h>
#include <tchar.h>
#include <uxtheme.h>
#include <windows.h>
#include <wingdi.h>
#include <winuser.h>

// Link the required libraries
#pragma comment(lib, "Shell32.lib")

// Function prototype for SetCurrentProcessExplicitAppUserModelID
// extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);

NOTIFYICONDATA m_NID;

// Constants for notification
const int NOTIFICATION_ID = 1001;
const wchar_t* APP_ID = L"com.twistengine";

/*
// Set a custom AppUserModelID for the game process
void SetAppID() {
	HRESULT hr = SetCurrentProcessExplicitAppUserModelID(APP_ID);
	if (FAILED(hr)) {
		std::cerr << "Error: Failed to set AppUserModelID." << std::endl;
	}
}
*/

// Initialize NOTIFYICONDATA structure
void InitNotifyIconData(HWND hWnd) {
	memset(&m_NID, 0, sizeof(m_NID));
	m_NID.cbSize = sizeof(NOTIFYICONDATA);
	m_NID.hWnd = hWnd;
	m_NID.uID = NOTIFICATION_ID;
	m_NID.uFlags = NIF_MESSAGE | NIF_INFO | NIF_TIP;
	m_NID.uCallbackMessage = WM_USER + 1;
	m_NID.dwInfoFlags = NIIF_INFO;
	m_NID.uVersion = NOTIFYICON_VERSION_4;

	StringCchCopy(m_NID.szTip, sizeof(m_NID.szTip) / sizeof(TCHAR), "Twist Engine Notification");
}

// Show the notification
bool ShowNotification(const std::string& title, const std::string& desc) {
	// SetAppID(); // Ensure the custom AppUser ModelID is set

	HWND hWnd = GetForegroundWindow(); // Use the current game window
	InitNotifyIconData(hWnd);

	StringCchCopy(m_NID.szInfoTitle, sizeof(m_NID.szInfoTitle) / sizeof(TCHAR), title.c_str());
	StringCchCopy(m_NID.szInfo, sizeof(m_NID.szInfo) / sizeof(TCHAR), desc.c_str());

	if (!Shell_NotifyIcon(NIM_ADD, &m_NID)) {
		std::cerr << "Error: Failed to add notification icon." << std::endl;
		return false;
	}

	// Modify the notification
	if (!Shell_NotifyIcon(NIM_MODIFY, &m_NID)) {
		std::cerr << "Error: Failed to modify notification." << std::endl;
		return false;
	}

	// Clean up after showing the notification
	return Shell_NotifyIcon(NIM_DELETE, &m_NID);
}


#define SAFE_RELEASE(punk)  \\
			  if ((punk) != NULL)  \\
				{ (punk)->Release(); (punk) = NULL; }

static long lastDefId = 0;

class AudioFixClient : public IMMNotificationClient {
	LONG _cRef;
	IMMDeviceEnumerator *_pEnumerator;

	public:
	AudioFixClient() :
		_cRef(1),
		_pEnumerator(NULL)
	{
		HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator),
							  NULL, CLSCTX_INPROC_SERVER,
							  __uuidof(IMMDeviceEnumerator),
							  (void**)&_pEnumerator);
		if (result == S_OK) {
			_pEnumerator->RegisterEndpointNotificationCallback(this);
		}
	}

	~AudioFixClient()
	{
		SAFE_RELEASE(_pEnumerator);
	}

	ULONG STDMETHODCALLTYPE AddRef()
	{
		return InterlockedIncrement(&_cRef);
	}

	ULONG STDMETHODCALLTYPE Release()
	{
		ULONG ulRef = InterlockedDecrement(&_cRef);
		if (0 == ulRef)
		{
			delete this;
		}
		return ulRef;
	}

	HRESULT STDMETHODCALLTYPE QueryInterface(
								REFIID riid, VOID **ppvInterface)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceAdded(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	};

	HRESULT STDMETHODCALLTYPE OnDeviceRemoved(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(
								LPCWSTR pwstrDeviceId,
								DWORD dwNewState)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(
								LPCWSTR pwstrDeviceId,
								const PROPERTYKEY key)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(
		EDataFlow flow, ERole role,
		LPCWSTR pwstrDeviceId)
	{
		::game::Main_obj::audioDisconnected = true;
		return S_OK;
	};
};

AudioFixClient *curAudioFix;
')
#end
class Windows {
	public static var __audioChangeCallback:Void->Void = function() {
		trace("test");
	};
	#if CPP_WINDOWS
	@:functionCode(' if (!curAudioFix) curAudioFix = new AudioFixClient(); ')
	#end
	public static function registerAudio() {
		Main.audioDisconnected = false;
	}

	public static inline function setWindowTransparencyAlpha(alpha:Float = 1) return __setWindowTransparencyAlpha(Math.floor(alpha * 255));

	static var lastMaskColor:FlxColor = 0x0;
	public static inline function setWindowTransparencyColor(maskColor:Null<FlxColor> = 0x0, alpha:Float = 1){
		if (maskColor != null) lastMaskColor = maskColor;
		return __setWindowTransparencyColor(lastMaskColor.red, lastMaskColor.green, lastMaskColor.blue, Math.floor(alpha * 255));
	}

	#if CPP_WINDOWS
	@:functionCode('
		HWND window = FindWindowA(NULL, title.c_str());
		// Look for child windows if top level aint found
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
		// If still not found, try to get the active window
		if (window == NULL) window = GetActiveWindow();
		if (window == NULL) return;

		int darkMode = enable ? 1 : 0;

		if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
			DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
		}
		UpdateWindow(window);
	')
	#end
	public static function setDarkMode(enable:Bool, title:String){}

	#if CPP_WINDOWS
	@:functionCode('
		HWND window = FindWindowA(NULL, title.c_str());
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
		if (window == NULL) window = GetActiveWindow();
		if (window == NULL) return;

		COLORREF finalColor;
		if(color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
			finalColor = 0xFFFFFFFF; // Default border
		} else if(color[3] == 0) {
			finalColor = 0xFFFFFFFE; // No border (must have setBorder as true)
		} else {
			finalColor = RGB(color[0], color[1], color[2]); // Use your custom color
		}

		if(setHeader) DwmSetWindowAttribute(window, 35, &finalColor, sizeof(COLORREF));
		if(setBorder) DwmSetWindowAttribute(window, 34, &finalColor, sizeof(COLORREF));

		UpdateWindow(window);
	')
	#end
	public static function setWindowBorderColor(title:String, color:Array<Int>, setHeader:Bool = true, setBorder:Bool = true) {}

	#if CPP_WINDOWS
	@:functionCode('
		HWND window = FindWindowA(NULL, title.c_str());
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
		if (window == NULL) window = GetActiveWindow();
		if (window == NULL) return;

		COLORREF finalColor;
		if(color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
			finalColor = 0xFFFFFFFF; // Default border
		} else {
			finalColor = RGB(color[0], color[1], color[2]); // Use your custom color
		}

		DwmSetWindowAttribute(window, 36, &finalColor, sizeof(COLORREF));
		UpdateWindow(window);
	')
	#end
	public static function setWindowTitleColor(title:String, color:Array<Int>) {}

	#if CPP_WINDOWS
	@:functionCode('
		return ShowNotification(title.c_str(), desc.c_str());
	')
	#end
	public static function sendWindowsNotification(title:String = "", desc:String = ""):Bool {
		return true; // Actual logic is handled by C++ code
	}

	#if CPP_WINDOWS
	@:functionCode('
		HWND window = GetActiveWindow();
   		// Create and populate the Blur Behind structure
   		DWM_BLURBEHIND bb = {0};

   		// Enable Blur Behind and apply to the entire client area
   		bb.dwFlags = DWM_BB_ENABLE;
   		bb.fEnable = true;
   		bb.hRgnBlur = NULL;
   		bb.fTransitionOnMaximized = true;

   		// Apply Blur Behind
   		DwmEnableBlurBehindWindow(window, &bb);
	')
	#end
	public static function test() {}

	#if CPP_WINDOWS
	@:functionCode('std::system("pause");')
	#end
	public static function pause() {}

	#if CPP_WINDOWS
	@:functionCode('
		system("CLS");
		std::cout<< "" <<std::flush;
	')
	#end
	public static function clearScreen() {}

	#if CPP_WINDOWS
	@:functionCode("
		// simple but effective code
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return allocatedRAM / 1024;
	")
	#end
	public static function getTotalRam():ULong return 0;

	#if CPP_WINDOWS
	// kudos to bing chatgpt thing i hate C++
	@:functionCode('
		HWND hwnd = GetActiveWindow();
		HMENU hmenu = GetSystemMenu(hwnd, FALSE);
		if (enable) {
			EnableMenuItem(hmenu, SC_CLOSE, MF_BYCOMMAND | MF_ENABLED);
		} else {
			EnableMenuItem(hmenu, SC_CLOSE, MF_BYCOMMAND | MF_GRAYED);
		}
	')
	#end
	public static function setCloseButtonEnabled(enable:Bool) {
		return enable;
	}

	public static function alert(title:String, msg:String, ?yesCallback:Void->Void, ?noCallback:Void->Void):Void
	{
		#if CPP_WINDOWS
		final result:Int = untyped MessageBox(null, msg, title, untyped __cpp__("MB_ICONERROR | MB_OKCANCEL"));
		switch (result) {
			case 1 if (yesCallback != null): // IDOK
				yesCallback();
			case 2 if (noCallback != null): // IDCANCEL
				noCallback();
		}
		#end
	}


	#if CPP_WINDOWS
	@:functionCode('
		HWND window = GetActiveWindow();

		// make window layered
		int result = SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) | WS_EX_LAYERED);
		if (alpha > 255) alpha = 255;
		if (alpha < 0) alpha = 0;
		SetLayeredWindowAttributes(window, RGB(red, green, blue), alpha, LWA_COLORKEY);
	')
	#end
	public static function __setWindowTransparencyColor(red:Int, green:Int, blue:Int, alpha:Int = 0) return alpha;

	#if CPP_WINDOWS
	@:functionCode('
		HWND window = GetActiveWindow();

		// make window layered
		int result = SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) | WS_EX_LAYERED);
		if (targetAlpha > 255) targetAlpha = 255;
		if (targetAlpha < 0) targetAlpha = 0;
		SetLayeredWindowAttributes(window, RGB(0, 0, 0), targetAlpha, LWA_ALPHA);
	')
	#end
	public static function __setWindowTransparencyAlpha(targetAlpha:Int) return targetAlpha;
}