//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Platform_h_
#define _Platform_h_

// include some basics Headers
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <assert.h>
#include <stdarg.h>
#include <time.h>

// include some std headers
#include <list>
#include <vector>
#include <map>
#include <set>
#include <functional>
#include <algorithm>
#include <functional>
#include <string>
#include <memory>

// Platform Encapsulation
#define PLATFORM GLFW
//#define PLATFORM WINDOWS_64
//#define PLATFORM MACOSX
//#define PLATFORM LINUX
//#define PLATFORM ANDROID
//#define PLATFORM IOS
//#define PLATFORM PS4
//#define PLATFORM XBOXONE
//#define PLATFORM NSWITCH
//#define PLATFORM PS5
//#define PLATFORM XSX

enum class Modifier
{
	SHIFT = 1,
	ALT = 2,
	CTRL = 4
};

class Platform
{
public:
	enum class KeyCode
	{
		None = 0,	//	Not assigned(never returned as the result of a keystroke).
		Backspace,	//	The backspace key.
		Delete,	//	The forward delete key.
		Tab,	//	The tab key.
		Clear,	//	The Clear key.
		Return,	//	Return key.
		Pause,	//	Pause on PC machines.
		Escape,	//	Escape key.
		Space,	//	Space key.
		Keypad0,	//	Numeric keypad 0.
		Keypad1,	//	Numeric keypad 1.
		Keypad2,	//	Numeric keypad 2.
		Keypad3,	//	Numeric keypad 3.
		Keypad4,	//	Numeric keypad 4.
		Keypad5,	//	Numeric keypad 5.
		Keypad6,	//	Numeric keypad 6.
		Keypad7,	//	Numeric keypad 7.
		Keypad8,	//	Numeric keypad 8.
		Keypad9,	//	Numeric keypad 9.
		KeypadPeriod,	//  Numeric keypad '.'.
		KeypadDivide,	//  Numeric keypad '/'.
		KeypadMultiply,	//  Numeric keypad '*'.
		KeypadMinus,	// Numeric keypad '-'.
		KeypadPlus,	// Numeric keypad '+'.
		KeypadEnter,	// Numeric keypad Enter.
		KeypadEquals,	// Numeric keypad '='.
		UpArrow,	// Up arrow key.
		DownArrow,	// Down arrow key.
		RightArrow,	// Right arrow key.
		LeftArrow,	// Left arrow key.
		Insert,	// Insert key key.
		Home,	// Home key.
		End,	// End key.
		PageUp,	// Page up.
		PageDown,	// Page down.
		F1,	// F1 function key.
		F2,	// F2 function key.
		F3,	// F3 function key.
		F4,	// F4 function key.
		F5,	// F5 function key.
		F6,	// F6 function key.
		F7,	// F7 function key.
		F8,	// F8 function key.
		F9,	// F9 function key.
		F10,	// F10 function key.
		F11,	// F11 function key.
		F12,	// F12 function key.
		F13,	// F13 function key.
		F14,	// F14 function key.
		F15,	// F15 function key.
		F16,	// F16 function key.
		F17,	// F17 function key.
		F18,	// F18 function key.
		F19,	// F19 function key.
		F20,	// F20 function key.
		F21,	// F21 function key.
		F22,	// F22 function key.
		F23,	// F23 function key.
		F24,	// F24 function key.
		F25,	// F25 function key.
		Alpha0,	// The '0' key on the top of the alphanumeric keyboard.
		Alpha1,	// The '1' key on the top of the alphanumeric keyboard.
		Alpha2,	// The '2' key on the top of the alphanumeric keyboard.
		Alpha3,	// The '3' key on the top of the alphanumeric keyboard.
		Alpha4,	// The '4' key on the top of the alphanumeric keyboard.
		Alpha5,	// The '5' key on the top of the alphanumeric keyboard.
		Alpha6,	// The '6' key on the top of the alphanumeric keyboard.
		Alpha7,	// The '7' key on the top of the alphanumeric keyboard.
		Alpha8,	// The '8' key on the top of the alphanumeric keyboard.
		Alpha9,	// The '9' key on the top of the alphanumeric keyboard.
		Exclaim,	// Exclamation mark key '!'.
		DoubleQuote,	// Double quote key '"'.
		Hash,	// Hash key '#'.
		Dollar,	// Dollar sign key '$'.
		Percent,	// Percent '%' key.
		Ampersand,	// Ampersand key '&'.
		Quote,	// Quote key '.
		LeftParen,	// Left Parenthesis key '('.
		RightParen,	// Right Parenthesis key ')'.
		Asterisk,	// Asterisk key '*'.
		Plus,	// Plus key '+'.
		Comma,	// Comma ',' key.
		Minus,	// Minus '-' key.
		Period,	// Period '.' key.
		Slash,	// Slash '/' key.
		Colon,	// Colon ':' key.
		Semicolon,	// Semicolon ';' key.
		Less,	// Less than '<' key.
		Equals,	// Equals '=' key.
		Greater,	// Greater than '>' key.
		Question,	// Question mark '?' key.
		At,	// At key '@'.
		LeftBracket,	// Left square bracket key '['.
		Backslash,	// Backslash key '\'.
		RightBracket,	// Right square bracket key ']'.
		Caret,	// Caret key '^'.
		Underscore,	// Underscore '_' key.
		BackQuote,	// Back quote key '`'.
		A,	// 'a' key.
		B,	// 'b' key.
		C,	// 'c' key.
		D,	// 'd' key.
		E,	// 'e' key.
		F,	// 'f' key.
		G,	// 'g' key.
		H,	// 'h' key.
		I,	// 'i' key.
		J,	// 'j' key.
		K,	// 'k' key.
		L,	// 'l' key.
		M,	// 'm' key.
		N,	// 'n' key.
		O,	// 'o' key.
		P,	// 'p' key.
		Q,	// 'q' key.
		R,	// 'r' key.
		S,	// 's' key.
		T,	// 't' key.
		U,	// 'u' key.
		V,	// 'v' key.
		W,	// 'w' key.
		X,	// 'x' key.
		Y,	// 'y' key.
		Z,	// 'z' key.
		LeftCurlyBracket,	// Left curly bracket key '{'.
		Pipe,	// Pipe '|' key.
		RightCurlyBracket,	// Right curly bracket key '}'.
		Tilde,	// Tilde '~' key.
		Numlock,	// Numlock key.
		CapsLock,	// Capslock key.
		ScrollLock,	// Scroll lock key.
		RightShift,	// Right shift key.
		LeftShift,	// Left shift key.
		RightControl,	// Right Control key.
		LeftControl,	// Left Control key.
		RightAlt,	// Right Alt key.
		LeftAlt,	// Left Alt key.
		LeftCommand,	// Left Command key.
		LeftApple,	// Left Command key.
		LeftWindows,	// Left Windows key.
		RightCommand,	// Right Command key.
		RightApple,	// Right Command key.
		RightWindows,	// Right Windows key.
		Help,	// Help key.
		Print,	// Print key.
		Break,	// Break key.
		Menu,	// Menu key.
		Mouse0,	// The Left(or primary) mouse button.
		Mouse1,	// Right mouse button(or secondary mouse button).
		Mouse2,	// Middle mouse button(or third button).
		Mouse3,	// Additional(fourth) mouse button.
		Mouse4,	// Additional(fifth) mouse button.
		Mouse5,	// Additional(or sixth) mouse button.
		Mouse6,	// Additional(or seventh) mouse button.
		Mouse7,	// Additional(or seventh) mouse button.
		JoystickButton0,	// Button 0 on any joystick.
		JoystickButton1,	// Button 1 on any joystick.
		JoystickButton2,	// Button 2 on any joystick.
		JoystickButton3,	// Button 3 on any joystick.
		JoystickButton4,	// Button 4 on any joystick.
		JoystickButton5,	// Button 5 on any joystick.
		JoystickButton6,	// Button 6 on any joystick.
		JoystickButton7,	// Button 7 on any joystick.
		JoystickButton8,	// Button 8 on any joystick.
		JoystickButton9,	// Button 9 on any joystick.
		JoystickButton10,	// Button 10 on any joystick.
		JoystickButton11,	// Button 11 on any joystick.
		JoystickButton12,	// Button 12 on any joystick.
		JoystickButton13,	// Button 13 on any joystick.
		JoystickButton14,	// Button 14 on any joystick.
		JoystickButton15,	// Button 15 on any joystick.
		JoystickButton16,	// Button 16 on any joystick.
		JoystickButton17,	// Button 17 on any joystick.
		JoystickButton18,	// Button 18 on any joystick.
		JoystickButton19,	// Button 19 on any joystick.
		Joystick1Button0,	// Button 0 on first joystick.
		Joystick1Button1,	// Button 1 on first joystick.
		Joystick1Button2,	// Button 2 on first joystick.
		Joystick1Button3,	// Button 3 on first joystick.
		Joystick1Button4,	// Button 4 on first joystick.
		Joystick1Button5,	// Button 5 on first joystick.
		Joystick1Button6,	// Button 6 on first joystick.
		Joystick1Button7,	// Button 7 on first joystick.
		Joystick1Button8,	// Button 8 on first joystick.
		Joystick1Button9,	// Button 9 on first joystick.
		Joystick1Button10,	// Button 10 on first joystick.
		Joystick1Button11,	// Button 11 on first joystick.
		Joystick1Button12,	// Button 12 on first joystick.
		Joystick1Button13,	// Button 13 on first joystick.
		Joystick1Button14,	// Button 14 on first joystick.
		Joystick1Button15,	// Button 15 on first joystick.
		Joystick1Button16,	// Button 16 on first joystick.
		Joystick1Button17,	// Button 17 on first joystick.
		Joystick1Button18,	// Button 18 on first joystick.
		Joystick1Button19,	// Button 19 on first joystick.
		Joystick2Button0,	// Button 0 on second joystick.
		Joystick2Button1,	// Button 1 on second joystick.
		Joystick2Button2,	// Button 2 on second joystick.
		Joystick2Button3,	// Button 3 on second joystick.
		Joystick2Button4,	// Button 4 on second joystick.
		Joystick2Button5,	// Button 5 on second joystick.
		Joystick2Button6,	// Button 6 on second joystick.
		Joystick2Button7,	// Button 7 on second joystick.
		Joystick2Button8,	// Button 8 on second joystick.
		Joystick2Button9,	// Button 9 on second joystick.
		Joystick2Button10,	// Button 10 on second joystick.
		Joystick2Button11,	// Button 11 on second joystick.
		Joystick2Button12,	// Button 12 on second joystick.
		Joystick2Button13,	// Button 13 on second joystick.
		Joystick2Button14,	// Button 14 on second joystick.
		Joystick2Button15,	// Button 15 on second joystick.
		Joystick2Button16,	// Button 16 on second joystick.
		Joystick2Button17,	// Button 17 on second joystick.
		Joystick2Button18,	// Button 18 on second joystick.
		Joystick2Button19,	// Button 19 on second joystick.
		Joystick3Button0,	// Button 0 on third joystick.
		Joystick3Button1,	// Button 1 on third joystick.
		Joystick3Button2,	// Button 2 on third joystick.
		Joystick3Button3,	// Button 3 on third joystick.
		Joystick3Button4,	// Button 4 on third joystick.
		Joystick3Button5,	// Button 5 on third joystick.
		Joystick3Button6,	// Button 6 on third joystick.
		Joystick3Button7,	// Button 7 on third joystick.
		Joystick3Button8,	// Button 8 on third joystick.
		Joystick3Button9,	// Button 9 on third joystick.
		Joystick3Button10,	// Button 10 on third joystick.
		Joystick3Button11,	// Button 11 on third joystick.
		Joystick3Button12,	// Button 12 on third joystick.
		Joystick3Button13,	// Button 13 on third joystick.
		Joystick3Button14,	// Button 14 on third joystick.
		Joystick3Button15,	// Button 15 on third joystick.
		Joystick3Button16,	// Button 16 on third joystick.
		Joystick3Button17,	// Button 17 on third joystick.
		Joystick3Button18,	// Button 18 on third joystick.
		Joystick3Button19,	// Button 19 on third joystick.
		Joystick4Button0,	// Button 0 on forth joystick.
		Joystick4Button1,	// Button 1 on forth joystick.
		Joystick4Button2,	// Button 2 on forth joystick.
		Joystick4Button3,	// Button 3 on forth joystick.
		Joystick4Button4,	// Button 4 on forth joystick.
		Joystick4Button5,	// Button 5 on forth joystick.
		Joystick4Button6,	// Button 6 on forth joystick.
		Joystick4Button7,	// Button 7 on forth joystick.
		Joystick4Button8,	// Button 8 on forth joystick.
		Joystick4Button9,	// Button 9 on forth joystick.
		Joystick4Button10,	// Button 10 on forth joystick.
		Joystick4Button11,	// Button 11 on forth joystick.
		Joystick4Button12,	// Button 12 on forth joystick.
		Joystick4Button13,	// Button 13 on forth joystick.
		Joystick4Button14,	// Button 14 on forth joystick.
		Joystick4Button15,	// Button 15 on forth joystick.
		Joystick4Button16,	// Button 16 on forth joystick.
		Joystick4Button17,	// Button 17 on forth joystick.
		Joystick4Button18,	// Button 18 on forth joystick.
		Joystick4Button19,	// Button 19 on forth joystick.
		Joystick5Button0,	// Button 0 on fifth joystick.
		Joystick5Button1,	// Button 1 on fifth joystick.
		Joystick5Button2,	// Button 2 on fifth joystick.
		Joystick5Button3,	// Button 3 on fifth joystick.
		Joystick5Button4,	// Button 4 on fifth joystick.
		Joystick5Button5,	// Button 5 on fifth joystick.
		Joystick5Button6,	// Button 6 on fifth joystick.
		Joystick5Button7,	// Button 7 on fifth joystick.
		Joystick5Button8,	// Button 8 on fifth joystick.
		Joystick5Button9,	// Button 9 on fifth joystick.
		Joystick5Button10,	// Button 10 on fifth joystick.
		Joystick5Button11,	// Button 11 on fifth joystick.
		Joystick5Button12,	// Button 12 on fifth joystick.
		Joystick5Button13,	// Button 13 on fifth joystick.
		Joystick5Button14,	// Button 14 on fifth joystick.
		Joystick5Button15,	// Button 15 on fifth joystick.
		Joystick5Button16,	// Button 16 on fifth joystick.
		Joystick5Button17,	// Button 17 on fifth joystick.
		Joystick5Button18,	// Button 18 on fifth joystick.
		Joystick5Button19,	// Button 19 on fifth joystick.
		Joystick6Button0,	// Button 0 on sixth joystick.
		Joystick6Button1,	// Button 1 on sixth joystick.
		Joystick6Button2,	// Button 2 on sixth joystick.
		Joystick6Button3,	// Button 3 on sixth joystick.
		Joystick6Button4,	// Button 4 on sixth joystick.
		Joystick6Button5,	// Button 5 on sixth joystick.
		Joystick6Button6,	// Button 6 on sixth joystick.
		Joystick6Button7,	// Button 7 on sixth joystick.
		Joystick6Button8,	// Button 8 on sixth joystick.
		Joystick6Button9,	// Button 9 on sixth joystick.
		Joystick6Button10,	// Button 10 on sixth joystick.
		Joystick6Button11,	// Button 11 on sixth joystick.
		Joystick6Button12,	// Button 12 on sixth joystick.
		Joystick6Button13,	// Button 13 on sixth joystick.
		Joystick6Button14,	// Button 14 on sixth joystick.
		Joystick6Button15,	// Button 15 on sixth joystick.
		Joystick6Button16,	// Button 16 on sixth joystick.
		Joystick6Button17,	// Button 17 on sixth joystick.
		Joystick6Button18,	// Button 18 on sixth joystick.
		Joystick6Button19,	// Button 19 on sixth joystick.
		Joystick7Button0,	// Button 0 on seventh joystick.
		Joystick7Button1,	// Button 1 on seventh joystick.
		Joystick7Button2,	// Button 2 on seventh joystick.
		Joystick7Button3,	// Button 3 on seventh joystick.
		Joystick7Button4,	// Button 4 on seventh joystick.
		Joystick7Button5,	// Button 5 on seventh joystick.
		Joystick7Button6,	// Button 6 on seventh joystick.
		Joystick7Button7,	// Button 7 on seventh joystick.
		Joystick7Button8,	// Button 8 on seventh joystick.
		Joystick7Button9,	// Button 9 on seventh joystick.
		Joystick7Button10,	// Button 10 on seventh joystick.
		Joystick7Button11,	// Button 11 on seventh joystick.
		Joystick7Button12,	// Button 12 on seventh joystick.
		Joystick7Button13,	// Button 13 on seventh joystick.
		Joystick7Button14,	// Button 14 on seventh joystick.
		Joystick7Button15,	// Button 15 on seventh joystick.
		Joystick7Button16,	// Button 16 on seventh joystick.
		Joystick7Button17,	// Button 17 on seventh joystick.
		Joystick7Button18,	// Button 18 on seventh joystick.
		Joystick7Button19,	// Button 19 on seventh joystick.
		Joystick8Button0,	// Button 0 on eighth joystick.
		Joystick8Button1,	// Button 1 on eighth joystick.
		Joystick8Button2,	// Button 2 on eighth joystick.
		Joystick8Button3,	// Button 3 on eighth joystick.
		Joystick8Button4,	// Button 4 on eighth joystick.
		Joystick8Button5,	// Button 5 on eighth joystick.
		Joystick8Button6,	// Button 6 on eighth joystick.
		Joystick8Button7,	// Button 7 on eighth joystick.
		Joystick8Button8,	// Button 8 on eighth joystick.
		Joystick8Button9,	// Button 9 on eighth joystick.
		Joystick8Button10,	// Button 10 on eighth joystick.
		Joystick8Button11,	// Button 11 on eighth joystick.
		Joystick8Button12,	// Button 12 on eighth joystick.
		Joystick8Button13,	// Button 13 on eighth joystick.
		Joystick8Button14,	// Button 14 on eighth joystick.
		Joystick8Button15,	// Button 15 on eighth joystick.
		Joystick8Button16,	// Button 16 on eighth joystick.
		Joystick8Button17,	// Button 17 on eighth joystick.
		Joystick8Button18,	// Button 18 on eighth joystick.
		Joystick8Button19,	// Button 19 on eighth joystick.
		Count
	};
#define JOYSTICK_COUNT 16
#define JOYSTICK_AXE_COUNT 4
#define JOYSTICK_BUTTON_COUNT 16
	class JoyStick
	{
	public:
		float axis[JOYSTICK_AXE_COUNT];
		bool button[JOYSTICK_BUTTON_COUNT];
	};

	class Mouse
	{
	public:
		float x;
		float y;
		int button;
		float dx;
		float dy;
	};

	class InputEvent
	{
	public:
		float x;
		float y;
		int keyCode;
		int scanCode;
		int action;
		int mods;
	};

	static bool Instantiate(int width_, int height_, const char* appName_, const char* InitalizeScene_);
	static bool PreUpdate();
	static bool PostUpdate();
	static bool Pause();
	static void Resume();
	static void Terminate();

	static void* GetHandle();
	static const std::string& GetAppName();
	static const std::string& GetInitialScene();
	static int GetWidth();
	static int GetHeight();

	static double GetTime();
	static double GetDeltaTime();
	static int GetTotalFrameCounter();
	static int GetSceneFrameCounter();
	static void ResetSceneFrameCounter();

	static int GetKeyCount();
	static bool GetKeyDown(Platform::KeyCode code);
	static bool GetKeyUp(Platform::KeyCode code);
	static bool GetKeyHold(Platform::KeyCode code);
	static bool GetKey(Platform::KeyCode code);

	static Mouse GetMouse();
	static float GetMouseX();
	static float GetMouseY();
	static float GetMouseDX();
	static float GetMouseDY();

	static void EnableCursor();
	static void DisableCursor();
	static bool IsCursorEnabled();

	static bool IsJoyStickConnected(int i);
	static JoyStick GetJoyStick(int i);
	static const std::vector<std::string>& GetJoystickNames();

	static void GetDropPaths(std::vector<std::string>& dropPaths_);
	static bool hasDropPath();

	static const char* GetClipBoardString();
	static void SetClipBoard(const char* s);

	static void SetArgument(std::vector<std::string>& std);
	static std::vector<std::string>& GetArgument();

	static void QuitApp();
	static bool ShouldAppQuit();
private:
};

void MemSet(void* dst, int val, int size);
void MemCpy(void* dst, const void* src, int size);
int MemCmp(const void* s1, const void* s2, int size);

const char* Format(const char* format, ...);
void Verbose(const char* s, ...);
void Debug(const char* s, ...);
void Info(const char* s, ...);
void Warning(const char* s, ...);
void Error(const char* s, ...);

#define Assert(cond)  assert((cond))

#endif