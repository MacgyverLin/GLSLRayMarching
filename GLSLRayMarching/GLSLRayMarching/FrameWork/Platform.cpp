//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "ArgParse.h"
#include <iostream>

//////////////////////////////////////////////////////////////////////////////////
std::string appName = "";
std::string initialScene = "";

void* handle = nullptr;
int width = 0;
int height = 0;
double currentTime = 0;
double deltaTime = 0;

int totalFrameCounter = 0;
int sceneFrameCounter = 0;

bool keystates[(int)Platform::KeyCode::Count] = { 0 };
bool oldkeystates[(int)Platform::KeyCode::Count] = { 0 };

Platform::Mouse mouse = { 0 };

Platform::JoyStick joySticks[JOYSTICK_COUNT] = { 0 };
bool joyStickConnected[JOYSTICK_COUNT] = { 0 };
std::vector<std::string> joyStickNames;

std::vector<std::string> dropPaths;

std::vector<std::string> arguments;

static Platform::WebCam webCam;
static Platform::Microphone microPhone;

//////////////////////////////////////////////////////
Platform::SystemTime::SystemTime()
: wYear(0)
, wMonth(0)
, wDayOfWeek(0)
, wDay(0)
, wHour(0)
, wMinute(0)
, wSecond(0)
, wMilliseconds(0)
{
}

Platform::SystemTime::~SystemTime()
{
}

//////////////////////////////////////////////////////
Platform::WebCam::WebCam()
: deviceHandle(nullptr)
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

Platform::WebCam::~WebCam()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

bool Platform::WebCam::Initiate()
{
#if (PLATFORM == GLFW)
	// deviceHandle = Create WebCam Device Here

	return true;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

bool Platform::WebCam::PreUpdate()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

bool Platform::WebCam::PostUpdate()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

bool Platform::WebCam::Pause()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

void Platform::WebCam::Resume()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::WebCam::Terminate()
{
#if (PLATFORM == GLFW)
	// deviceHandle = Destroy WebCam Device Here
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::WebCam::GetData()
{
	Assert(deviceHandle);

#if (PLATFORM == GLFW)
	// Get Webcam data from deviceHandle here
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

//////////////////////////////////////////////////////
Platform::Microphone::Microphone()
: deviceHandle(nullptr)
{
}

Platform::Microphone::~Microphone()
{
}

bool Platform::Microphone::Initiate()
{
#if (PLATFORM == GLFW)
	// deviceHandle = Create Microphone Device Here
	return true;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

bool Platform::Microphone::PreUpdate()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

bool Platform::Microphone::PostUpdate()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

bool Platform::Microphone::Pause()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	return true;
}

void Platform::Microphone::Resume()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::Microphone::Terminate()
{
#if (PLATFORM == GLFW)
	// deviceHandle = Destroy Microphone Device Here
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::Microphone::GetData()
{
#if (PLATFORM == GLFW)
	// Get Microphone data from deviceHandle here
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}


//////////////////////////////////////////////////////
#if (PLATFORM == GLFW)
#include <Windows.h>
#include <WinUser.h>
#include <glad\glad.h>
#include <GLFW\glfw3.h>
#include "imgui\imgui.h"
#include "imgui\imgui_impl_glfw.h"
#include "imgui\imgui_impl_opengl3.h"

void framebuffer_size_callback(void* win, int width_, int height_)
{
	GLFWwindow* window = (GLFWwindow*)win;
	width = width_;
	height = height_;
}

static void glfw_error_callback(int error_code, const char* description)
{
	Debug("GLFW Error: [%d] %s\n", error_code, description);
}

std::vector<int> glfwKeyCodes =
{
	GLFW_KEY_SPACE              ,
	GLFW_KEY_APOSTROPHE         ,
	GLFW_KEY_COMMA              ,
	GLFW_KEY_MINUS              ,
	GLFW_KEY_PERIOD             ,
	GLFW_KEY_SLASH              ,
	GLFW_KEY_0                  ,
	GLFW_KEY_1                  ,
	GLFW_KEY_2                  ,
	GLFW_KEY_3                  ,
	GLFW_KEY_4                  ,
	GLFW_KEY_5                  ,
	GLFW_KEY_6                  ,
	GLFW_KEY_7                  ,
	GLFW_KEY_8                  ,
	GLFW_KEY_9                  ,
	GLFW_KEY_SEMICOLON          ,
	GLFW_KEY_EQUAL              ,
	GLFW_KEY_A                  ,
	GLFW_KEY_B                  ,
	GLFW_KEY_C                  ,
	GLFW_KEY_D                  ,
	GLFW_KEY_E                  ,
	GLFW_KEY_F                  ,
	GLFW_KEY_G                  ,
	GLFW_KEY_H                  ,
	GLFW_KEY_I                  ,
	GLFW_KEY_J                  ,
	GLFW_KEY_K                  ,
	GLFW_KEY_L                  ,
	GLFW_KEY_M                  ,
	GLFW_KEY_N                  ,
	GLFW_KEY_O                  ,
	GLFW_KEY_P                  ,
	GLFW_KEY_Q                  ,
	GLFW_KEY_R                  ,
	GLFW_KEY_S                  ,
	GLFW_KEY_T                  ,
	GLFW_KEY_U                  ,
	GLFW_KEY_V                  ,
	GLFW_KEY_W                  ,
	GLFW_KEY_X                  ,
	GLFW_KEY_Y                  ,
	GLFW_KEY_Z                  ,
	GLFW_KEY_LEFT_BRACKET       ,
	GLFW_KEY_BACKSLASH          ,
	GLFW_KEY_RIGHT_BRACKET      ,
	GLFW_KEY_GRAVE_ACCENT       ,
	GLFW_KEY_WORLD_1            ,
	GLFW_KEY_WORLD_2            ,
	GLFW_KEY_ESCAPE             ,
	GLFW_KEY_ENTER              ,
	GLFW_KEY_TAB                ,
	GLFW_KEY_BACKSPACE          ,
	GLFW_KEY_INSERT             ,
	GLFW_KEY_DELETE             ,
	GLFW_KEY_RIGHT              ,
	GLFW_KEY_LEFT               ,
	GLFW_KEY_DOWN               ,
	GLFW_KEY_UP                 ,
	GLFW_KEY_PAGE_UP            ,
	GLFW_KEY_PAGE_DOWN          ,
	GLFW_KEY_HOME               ,
	GLFW_KEY_END                ,
	GLFW_KEY_CAPS_LOCK          ,
	GLFW_KEY_SCROLL_LOCK        ,
	GLFW_KEY_NUM_LOCK           ,
	GLFW_KEY_PRINT_SCREEN       ,
	GLFW_KEY_PAUSE              ,
	GLFW_KEY_F1                 ,
	GLFW_KEY_F2                 ,
	GLFW_KEY_F3                 ,
	GLFW_KEY_F4                 ,
	GLFW_KEY_F5                 ,
	GLFW_KEY_F6                 ,
	GLFW_KEY_F7                 ,
	GLFW_KEY_F8                 ,
	GLFW_KEY_F9                 ,
	GLFW_KEY_F10                ,
	GLFW_KEY_F11                ,
	GLFW_KEY_F12                ,
	GLFW_KEY_F13                ,
	GLFW_KEY_F14                ,
	GLFW_KEY_F15                ,
	GLFW_KEY_F16                ,
	GLFW_KEY_F17                ,
	GLFW_KEY_F18                ,
	GLFW_KEY_F19                ,
	GLFW_KEY_F20                ,
	GLFW_KEY_F21                ,
	GLFW_KEY_F22                ,
	GLFW_KEY_F23                ,
	GLFW_KEY_F24                ,
	GLFW_KEY_F25                ,
	GLFW_KEY_KP_0               ,
	GLFW_KEY_KP_1               ,
	GLFW_KEY_KP_2               ,
	GLFW_KEY_KP_3               ,
	GLFW_KEY_KP_4               ,
	GLFW_KEY_KP_5               ,
	GLFW_KEY_KP_6               ,
	GLFW_KEY_KP_7               ,
	GLFW_KEY_KP_8               ,
	GLFW_KEY_KP_9               ,
	GLFW_KEY_KP_DECIMAL         ,
	GLFW_KEY_KP_DIVIDE          ,
	GLFW_KEY_KP_MULTIPLY        ,
	GLFW_KEY_KP_SUBTRACT        ,
	GLFW_KEY_KP_ADD             ,
	GLFW_KEY_KP_ENTER           ,
	GLFW_KEY_KP_EQUAL           ,
	GLFW_KEY_LEFT_SHIFT         ,
	GLFW_KEY_LEFT_CONTROL       ,
	GLFW_KEY_LEFT_ALT           ,
	GLFW_KEY_LEFT_SUPER         ,
	GLFW_KEY_RIGHT_SHIFT        ,
	GLFW_KEY_RIGHT_CONTROL      ,
	GLFW_KEY_RIGHT_ALT          ,
	GLFW_KEY_RIGHT_SUPER        ,
	GLFW_KEY_MENU
};

std::map<int, Platform::KeyCode> glfwKeyCode2keyCodes =
{
	{	GLFW_KEY_SPACE              , Platform::KeyCode::Space			},
	{	GLFW_KEY_APOSTROPHE         , Platform::KeyCode::Quote			},
	{	GLFW_KEY_COMMA              , Platform::KeyCode::Comma			},
	{	GLFW_KEY_MINUS              , Platform::KeyCode::Minus			},
	{	GLFW_KEY_PERIOD             , Platform::KeyCode::Period			},
	{	GLFW_KEY_SLASH              , Platform::KeyCode::Slash			},
	{	GLFW_KEY_0                  , Platform::KeyCode::Alpha0			},
	{	GLFW_KEY_1                  , Platform::KeyCode::Alpha1			},
	{	GLFW_KEY_2                  , Platform::KeyCode::Alpha2			},
	{	GLFW_KEY_3                  , Platform::KeyCode::Alpha3			},
	{	GLFW_KEY_4                  , Platform::KeyCode::Alpha4			},
	{	GLFW_KEY_5                  , Platform::KeyCode::Alpha5			},
	{	GLFW_KEY_6                  , Platform::KeyCode::Alpha6			},
	{	GLFW_KEY_7                  , Platform::KeyCode::Alpha7			},
	{	GLFW_KEY_8                  , Platform::KeyCode::Alpha8			},
	{	GLFW_KEY_9                  , Platform::KeyCode::Alpha9			},
	{	GLFW_KEY_SEMICOLON          , Platform::KeyCode::Semicolon		},
	{	GLFW_KEY_EQUAL              , Platform::KeyCode::Equals			},
	{	GLFW_KEY_A                  , Platform::KeyCode::A				},
	{	GLFW_KEY_B                  , Platform::KeyCode::B				},
	{	GLFW_KEY_C                  , Platform::KeyCode::C				},
	{	GLFW_KEY_D                  , Platform::KeyCode::D				},
	{	GLFW_KEY_E                  , Platform::KeyCode::E				},
	{	GLFW_KEY_F                  , Platform::KeyCode::F				},
	{	GLFW_KEY_G                  , Platform::KeyCode::G				},
	{	GLFW_KEY_H                  , Platform::KeyCode::H				},
	{	GLFW_KEY_I                  , Platform::KeyCode::I				},
	{	GLFW_KEY_J                  , Platform::KeyCode::J				},
	{	GLFW_KEY_K                  , Platform::KeyCode::K				},
	{	GLFW_KEY_L                  , Platform::KeyCode::L				},
	{	GLFW_KEY_M                  , Platform::KeyCode::M				},
	{	GLFW_KEY_N                  , Platform::KeyCode::N				},
	{	GLFW_KEY_O                  , Platform::KeyCode::O				},
	{	GLFW_KEY_P                  , Platform::KeyCode::P				},
	{	GLFW_KEY_Q                  , Platform::KeyCode::Q				},
	{	GLFW_KEY_R                  , Platform::KeyCode::R				},
	{	GLFW_KEY_S                  , Platform::KeyCode::S				},
	{	GLFW_KEY_T                  , Platform::KeyCode::T				},
	{	GLFW_KEY_U                  , Platform::KeyCode::U				},
	{	GLFW_KEY_V                  , Platform::KeyCode::V				},
	{	GLFW_KEY_W                  , Platform::KeyCode::W				},
	{	GLFW_KEY_X                  , Platform::KeyCode::X				},
	{	GLFW_KEY_Y                  , Platform::KeyCode::Y				},
	{	GLFW_KEY_Z                  , Platform::KeyCode::Z				},
	{	GLFW_KEY_LEFT_BRACKET       , Platform::KeyCode::LeftBracket	},
	{	GLFW_KEY_BACKSLASH          , Platform::KeyCode::Backslash		},
	{	GLFW_KEY_RIGHT_BRACKET      , Platform::KeyCode::RightBracket	},
	{	GLFW_KEY_GRAVE_ACCENT       , Platform::KeyCode::BackQuote		},
	{	GLFW_KEY_WORLD_1            , Platform::KeyCode::None			},
	{	GLFW_KEY_WORLD_2            , Platform::KeyCode::None			},
	{	GLFW_KEY_ESCAPE             , Platform::KeyCode::Escape			},
	{	GLFW_KEY_ENTER              , Platform::KeyCode::KeypadEnter	},
	{	GLFW_KEY_TAB                , Platform::KeyCode::Tab			},
	{	GLFW_KEY_BACKSPACE          , Platform::KeyCode::Backspace		},
	{	GLFW_KEY_INSERT             , Platform::KeyCode::Insert			},
	{	GLFW_KEY_DELETE             , Platform::KeyCode::Delete			},
	{	GLFW_KEY_RIGHT              , Platform::KeyCode::RightArrow		},
	{	GLFW_KEY_LEFT               , Platform::KeyCode::LeftArrow		},
	{	GLFW_KEY_DOWN               , Platform::KeyCode::DownArrow		},
	{	GLFW_KEY_UP                 , Platform::KeyCode::UpArrow		},
	{	GLFW_KEY_PAGE_UP            , Platform::KeyCode::PageUp			},
	{	GLFW_KEY_PAGE_DOWN          , Platform::KeyCode::PageDown		},
	{	GLFW_KEY_HOME               , Platform::KeyCode::Home			},
	{	GLFW_KEY_END                , Platform::KeyCode::End			},
	{	GLFW_KEY_CAPS_LOCK          , Platform::KeyCode::CapsLock		},
	{	GLFW_KEY_SCROLL_LOCK        , Platform::KeyCode::ScrollLock		},
	{	GLFW_KEY_NUM_LOCK           , Platform::KeyCode::Numlock		},
	{	GLFW_KEY_PRINT_SCREEN       , Platform::KeyCode::Print			},
	{	GLFW_KEY_PAUSE              , Platform::KeyCode::Pause			},
	{	GLFW_KEY_F1                 , Platform::KeyCode::F1				},
	{	GLFW_KEY_F2                 , Platform::KeyCode::F2				},
	{	GLFW_KEY_F3                 , Platform::KeyCode::F3				},
	{	GLFW_KEY_F4                 , Platform::KeyCode::F4				},
	{	GLFW_KEY_F5                 , Platform::KeyCode::F5				},
	{	GLFW_KEY_F6                 , Platform::KeyCode::F6				},
	{	GLFW_KEY_F7                 , Platform::KeyCode::F7				},
	{	GLFW_KEY_F8                 , Platform::KeyCode::F8				},
	{	GLFW_KEY_F9                 , Platform::KeyCode::F9				},
	{	GLFW_KEY_F10                , Platform::KeyCode::F10			},
	{	GLFW_KEY_F11                , Platform::KeyCode::F11			},
	{	GLFW_KEY_F12                , Platform::KeyCode::F12			},
	{	GLFW_KEY_F13                , Platform::KeyCode::F13			},
	{	GLFW_KEY_F14                , Platform::KeyCode::F14			},
	{	GLFW_KEY_F15                , Platform::KeyCode::F15			},
	{	GLFW_KEY_F16                , Platform::KeyCode::F16			},
	{	GLFW_KEY_F17                , Platform::KeyCode::F17			},
	{	GLFW_KEY_F18                , Platform::KeyCode::F18			},
	{	GLFW_KEY_F19                , Platform::KeyCode::F19			},
	{	GLFW_KEY_F20                , Platform::KeyCode::F20			},
	{	GLFW_KEY_F21                , Platform::KeyCode::F21			},
	{	GLFW_KEY_F22                , Platform::KeyCode::F22			},
	{	GLFW_KEY_F23                , Platform::KeyCode::F23			},
	{	GLFW_KEY_F24                , Platform::KeyCode::F24			},
	{	GLFW_KEY_F25                , Platform::KeyCode::F25			},
	{	GLFW_KEY_KP_0               , Platform::KeyCode::Keypad0		},
	{	GLFW_KEY_KP_1               , Platform::KeyCode::Keypad1		},
	{	GLFW_KEY_KP_2               , Platform::KeyCode::Keypad2		},
	{	GLFW_KEY_KP_3               , Platform::KeyCode::Keypad3		},
	{	GLFW_KEY_KP_4               , Platform::KeyCode::Keypad4		},
	{	GLFW_KEY_KP_5               , Platform::KeyCode::Keypad5		},
	{	GLFW_KEY_KP_6               , Platform::KeyCode::Keypad6		},
	{	GLFW_KEY_KP_7               , Platform::KeyCode::Keypad7		},
	{	GLFW_KEY_KP_8               , Platform::KeyCode::Keypad8		},
	{	GLFW_KEY_KP_9               , Platform::KeyCode::Keypad9		},
	{	GLFW_KEY_KP_DECIMAL         , Platform::KeyCode::KeypadPeriod	},
	{	GLFW_KEY_KP_DIVIDE          , Platform::KeyCode::KeypadDivide	},
	{	GLFW_KEY_KP_MULTIPLY        , Platform::KeyCode::KeypadMultiply	},
	{	GLFW_KEY_KP_SUBTRACT        , Platform::KeyCode::KeypadMinus	},
	{	GLFW_KEY_KP_ADD             , Platform::KeyCode::KeypadPlus		},
	{	GLFW_KEY_KP_ENTER           , Platform::KeyCode::KeypadEnter	},
	{	GLFW_KEY_KP_EQUAL           , Platform::KeyCode::KeypadEquals	},
	{	GLFW_KEY_LEFT_SHIFT         , Platform::KeyCode::LeftShift		},
	{	GLFW_KEY_LEFT_CONTROL       , Platform::KeyCode::LeftControl	},
	{	GLFW_KEY_LEFT_ALT           , Platform::KeyCode::LeftAlt		},
	{	GLFW_KEY_LEFT_SUPER         , Platform::KeyCode::LeftWindows	},
	{	GLFW_KEY_RIGHT_SHIFT        , Platform::KeyCode::RightShift		},
	{	GLFW_KEY_RIGHT_CONTROL      , Platform::KeyCode::RightControl	},
	{	GLFW_KEY_RIGHT_ALT          , Platform::KeyCode::RightAlt		},
	{	GLFW_KEY_RIGHT_SUPER        , Platform::KeyCode::RightWindows	},
	{	GLFW_KEY_MENU               , Platform::KeyCode::Menu			}
};


std::vector<int> glfwMouseKeyCodes =
{
	GLFW_MOUSE_BUTTON_1,
	GLFW_MOUSE_BUTTON_2,
	GLFW_MOUSE_BUTTON_3,
	GLFW_MOUSE_BUTTON_4,
	GLFW_MOUSE_BUTTON_5,
	GLFW_MOUSE_BUTTON_6,
	GLFW_MOUSE_BUTTON_7,
	GLFW_MOUSE_BUTTON_8,
};

std::map<int, Platform::KeyCode> glfwMouseKeyCode2keyCodes =
{
	{	GLFW_MOUSE_BUTTON_1				, Platform::KeyCode::Mouse0		},
	{	GLFW_MOUSE_BUTTON_2				, Platform::KeyCode::Mouse1		},
	{	GLFW_MOUSE_BUTTON_3             , Platform::KeyCode::Mouse2		},
	{	GLFW_MOUSE_BUTTON_4             , Platform::KeyCode::Mouse3		},
	{	GLFW_MOUSE_BUTTON_5             , Platform::KeyCode::Mouse4		},
	{	GLFW_MOUSE_BUTTON_6             , Platform::KeyCode::Mouse5		},
	{	GLFW_MOUSE_BUTTON_7             , Platform::KeyCode::Mouse6		},
	{	GLFW_MOUSE_BUTTON_8             , Platform::KeyCode::Mouse7		},
};

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
	Platform::InputEvent e;

	if (action == 1)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 1;
		e.mods = mods;
	}
	if (action == 0)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 2;
		e.mods = mods;
	}

	/*
	auto itr = glfwKeyCode2keyCodes.find(key);
	if (itr != glfwKeyCode2keyCodes.end())
	{
		int idx = (int)itr->second;

		oldkeystates[idx] = keystates[idx];

		if (action == GLFW_PRESS)
			keystates[idx] = 0x01;
		else if (action == GLFW_RELEASE)
			keystates[idx] = 0x02;
		else //if(action == GLFW_REPEAT)
			keystates[idx] = 0x04;
	}
	*/
	// Debug("%d %d %d %d\n", key, scancode, action, mods);
}

std::vector<Platform::KeyCode> mouseButtonCodeMaps =
{
	Platform::KeyCode::Mouse0,
	Platform::KeyCode::Mouse1,
	Platform::KeyCode::Mouse2,
	Platform::KeyCode::Mouse3,
	Platform::KeyCode::Mouse4,
	Platform::KeyCode::Mouse5,
	Platform::KeyCode::Mouse6,
};

std::vector<Platform::InputEvent> inputEvents;

void mouse_button_callback(GLFWwindow* window, int key, int action, int mods)
{
	Platform::InputEvent e;

	if (action == 1)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 1;
		e.mods = mods;
	}
	if (action == 0)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 2;
		e.mods = mods;
	}
		/*
	if (button < mouseButtonCodeMaps.size())
	{
		int idx = (int)mouseButtonCodeMaps[button];

		oldkeystates[idx] = keystates[idx];

		if (action == GLFW_PRESS)
			keystates[idx] = 0x01;
		else// if (action == GLFW_RELEASE)
			keystates[idx] = 0x02;
	}
	*/
	// Debug("%d %d %d", button, action, mods);
}

void joystick_callback(int jid, int event)
{
	if (event == GLFW_CONNECTED)
	{
		joyStickConnected[jid] = true;
	}
	else if (event == GLFW_DISCONNECTED)
	{
		joyStickConnected[jid] = false;
	}
}

void drop_callback(GLFWwindow* window, int count, const char** paths)
{
	dropPaths.resize(count);
	for (int i = 0; i < count; i++)
	{
		dropPaths[i] = paths[i];
	}
}

#endif

bool Platform::Instantiate(int width_, int height_, const char* appName_, const char* initialScene_)
{
#if (PLATFORM == GLFW)
	currentTime = glfwGetTime();
	deltaTime = 0;

	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
	appName = appName_;
	initialScene = initialScene_;
	width = width_;
	height = height_;
	handle = glfwCreateWindow(width, height, appName.c_str(), NULL, NULL);
	if (handle == nullptr)
	{
		Debug("Failed to create GLFW window\n");
		glfwTerminate();
		return false;
	}

	glfwMakeContextCurrent((GLFWwindow*)handle);
	glfwSetErrorCallback(glfw_error_callback);
	glfwSetFramebufferSizeCallback((GLFWwindow*)handle, (void (*)(GLFWwindow*, int, int))(framebuffer_size_callback));
	
	glfwSetKeyCallback((GLFWwindow*)handle, key_callback);
	glfwSetMouseButtonCallback((GLFWwindow*)handle, mouse_button_callback);

	glfwSetJoystickCallback(joystick_callback);
	glfwSetDropCallback((GLFWwindow*)handle, drop_callback);

	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
	{
		Debug("Failed to initialize GLAD\n");
		return false;
	}

	// Setup Dear ImGui context
	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io;
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

	// Setup Dear ImGui style
	ImGui::StyleColorsDark();
	//ImGui::StyleColorsClassic();

	// Setup Platform/Renderer bindings
	ImGui_ImplGlfw_InitForOpenGL((GLFWwindow*)handle, true);
	ImGui_ImplOpenGL3_Init();

	// Load Fonts
	// - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
	// - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
	// - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
	// - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
	// - Read 'docs/FONTS.md' for more instructions and details.
	// - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
	//io.Fonts->AddFontDefault();
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
	//ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
	//IM_ASSERT(font != NULL);

	if (!webCam.Initiate())
		return false;

	if (!microPhone.Initiate())
		return false;

#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

bool Platform::PreUpdate()
{
#if (PLATFORM == GLFW)
	webCam.PreUpdate();

	microPhone.PreUpdate();

	///////////////////////////////////////////////////
	// time
	double now = glfwGetTime();
	deltaTime = now - currentTime;
	currentTime = now;

	///////////////////////////////////////////////////
	glfwPollEvents();

	///////////////////////////////////////////////////
	// Button
	for(int i=0; i<(int)Platform::KeyCode::Count; i++)
		oldkeystates[i] = keystates[i];

	for (int i = 0; i < glfwKeyCodes.size(); i++)
	{
		int glfwKey = glfwKeyCodes[i];
		Platform::KeyCode code = glfwKeyCode2keyCodes[glfwKey];
		
		int keyState = glfwGetKey((GLFWwindow*)handle, glfwKey);

		if (keyState == GLFW_PRESS)
		{
			keystates[int(code)] = true;

			if (glfwKey == GLFW_KEY_LEFT_SHIFT)
			{
				int a = 1;
			}
		}
		else if (keyState == GLFW_RELEASE)
		{
			keystates[int(code)] = false;
		}
	}

	for (int i = 0; i < glfwMouseKeyCodes.size(); i++)
	{
		int glfwKey = glfwMouseKeyCodes[i];
		Platform::KeyCode code = glfwMouseKeyCode2keyCodes[glfwKey];

		int keyState = glfwGetMouseButton((GLFWwindow*)handle, glfwKey);
		if (keyState == GLFW_PRESS)
			keystates[int(code)] = true;
		else if (keyState == GLFW_RELEASE)
			keystates[int(code)] = false;
	}

	///////////////////////////////////////////////////
	// Mouse Movement
	double newMouseX = 0;
	double newMouseY = 0;
	glfwGetCursorPos((GLFWwindow*)handle, &newMouseX, &newMouseY);
	newMouseY = GetHeight() - 1 - newMouseY;
	mouse.dx = (float)newMouseX - mouse.x;
	mouse.dy = (float)newMouseY - mouse.y;
	mouse.x = (float)newMouseX;
	mouse.y = (float)newMouseY;
	// Debug("%f %f %f %f\n", mouse.x, mouse.y, mouse.dx, mouse.dy);

	///////////////////////////////////////////////////
	// JoyStick
	for (int i = GLFW_JOYSTICK_1; i <= GLFW_JOYSTICK_16 && i < JOYSTICK_COUNT; i++)
	{
		if (joyStickConnected[i])
		{
			const char* name = glfwGetJoystickName(i);

			//std::cout << name << ":";

			int count;
			const float* axes = glfwGetJoystickAxes(i, &count);
			for (int j = 0; j < count && j < JOYSTICK_AXE_COUNT; j++)
			{
				joySticks[i].axis[j] = axes[j];
				//std::cout << ((fabs(axes[j]) < 0.0001) ? 0 :axes[j]) << " ,";
			}

			const unsigned char* buttons = glfwGetJoystickButtons(i, &count);
			for (int j = 0; j < count && j < JOYSTICK_BUTTON_COUNT; j++)
			{
				joySticks[i].button[j] = buttons[j];
				//std::cout << (buttons[j] ? '1' : '0');
			}

			//std::cout << "\n";
		}
	}

	///////////////////////////////////////////////////
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplGlfw_NewFrame();
	ImGui::NewFrame();
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

bool Platform::PostUpdate()
{
#if (PLATFORM == GLFW)
	webCam.PostUpdate();

	microPhone.PostUpdate();

	// Rendering
	ImGui::Render();

	// glGetIntegerv(GL_CURRENT_PROGRAM, &last_program);
	// glUseProgram(0);
	ImDrawData* drawData = ImGui::GetDrawData();
	if (drawData)
		ImGui_ImplOpenGL3_RenderDrawData(drawData);
	//glUseProgram(last_program);

	glfwSwapInterval(0);
	glfwMakeContextCurrent((GLFWwindow*)handle);
	glfwSwapBuffers((GLFWwindow*)handle);

	totalFrameCounter++;
	sceneFrameCounter++;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

bool Platform::Pause()
{
#if (PLATFORM == GLFW)
	webCam.Pause();

	microPhone.Pause();
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

void Platform::Resume()
{
#if (PLATFORM == GLFW)
	webCam.Resume();

	microPhone.Resume();
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::Terminate()
{
#if (PLATFORM == GLFW)
	webCam.Terminate();

	microPhone.Terminate();

	glfwDestroyWindow((GLFWwindow*)handle);
	glfwTerminate();
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void* Platform::GetHandle()
{
	return handle;
}

const std::string& Platform::GetAppName()
{
	return appName;
}

const std::string& Platform::GetInitialScene()
{
	return initialScene;
}

int Platform::GetWidth()
{
	return width;
}

int Platform::GetHeight()
{
	return height;
}

double Platform::GetTime()
{
	return currentTime;
}

double Platform::GetDeltaTime()
{
	return deltaTime;
}

int Platform::GetTotalFrameCounter()
{
	return totalFrameCounter;
}

int Platform::GetSceneFrameCounter()
{
	return sceneFrameCounter;
}

void Platform::ResetSceneFrameCounter()
{
	sceneFrameCounter = -1;
}

int Platform::GetKeyCount()
{
	return (int)Platform::KeyCode::Count;
}

bool Platform::GetKeyDown(Platform::KeyCode code)
{
	return !oldkeystates[(int)code] && keystates[(int)code];
}

bool Platform::GetKeyUp(Platform::KeyCode code)
{
	return oldkeystates[(int)code] && !keystates[(int)code];
}

bool Platform::GetKeyHold(Platform::KeyCode code)
{
	return oldkeystates[(int)code] && keystates[(int)code];
}

bool Platform::GetKey(Platform::KeyCode code)
{
	return keystates[(int)code];
}

Platform::Mouse Platform::GetMouse()
{
	return mouse;
}

float Platform::GetMouseX()
{
	return mouse.x;
}

float Platform::GetMouseY()
{
	return mouse.y;
}

float Platform::GetMouseDX()
{
	return mouse.dx;
}

float Platform::GetMouseDY()
{
	return mouse.dy;
}

Platform::SystemTime Platform::GetSystemTime()
{
#if (PLATFORM == GLFW)
	Platform::SystemTime systemTime;

	SYSTEMTIME lt = { 0 };
	GetLocalTime(&lt);

	systemTime.wYear = lt.wYear;
	systemTime.wMonth = lt.wMonth;
	systemTime.wDayOfWeek = lt.wDayOfWeek;
	systemTime.wDay = lt.wDay;
	systemTime.wHour = lt.wHour;
	systemTime.wMinute = lt.wMinute;
	systemTime.wSecond = lt.wSecond;
	systemTime.wMilliseconds = lt.wMilliseconds;

	return systemTime;
#else
#endif
}

Platform::Microphone Platform::GetMicrophone()
{
	return microPhone;
}

Platform::WebCam Platform::GetWebCam()
{
	return webCam;
}

void Platform::EnableCursor()
{
#if (PLATFORM == GLFW)
	glfwSetInputMode((GLFWwindow*)handle, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::DisableCursor()
{
#if (PLATFORM == GLFW)
	glfwSetInputMode((GLFWwindow*)handle, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

bool Platform::IsCursorEnabled()
{
#if (PLATFORM == GLFW)
	return glfwGetInputMode((GLFWwindow*)handle, GLFW_CURSOR);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

bool Platform::IsJoyStickConnected(int i)
{
	return joyStickConnected[i];
}

Platform::JoyStick Platform::GetJoyStick(int i)
{
	return joySticks[i];
}

const std::vector<std::string>& Platform::GetJoystickNames()
{
	return joyStickNames;
}

void Platform::GetDropPaths(std::vector<std::string>& dropPaths_)
{
	dropPaths_ = dropPaths;
}

bool Platform::hasDropPath()
{
	return dropPaths.size()!=0;
}

const char* Platform::GetClipBoardString()
{
	return glfwGetClipboardString(nullptr);
}

void Platform::SetClipBoard(const char* s)
{
	glfwSetClipboardString(nullptr, s);
}

void Platform::SetArgument(std::vector<std::string>& args)
{
	arguments = args;
}

std::vector<std::string>& Platform::GetArgument()
{
	return arguments;
}

void Platform::QuitApp()
{
	glfwSetWindowShouldClose((GLFWwindow*)handle, true);
}

bool Platform::ShouldAppQuit()
{
	return glfwWindowShouldClose((GLFWwindow*)handle);
}

///////////////////////////////////////////
#define FORMAT_BUFFER_SIZE 32768

const char* Format(const char* format, ...)
{
	static char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	return (const char*)buffer;
}

void Verbose(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Verbose: %s", buffer);
}

void Debug(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Debug: %s", buffer);
}

void Info(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Info: %s", buffer);
}

void Warning(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Warning: %s", buffer);
}

void Error(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Error: %s", buffer);
}

void MemSet(void* dst, int val, int size)
{
	::memset(dst, val, size);
}

void MemCpy(void* dst, const void* src, int size)
{
	::memcpy(dst, src, size);
}

int MemCmp(const void* s1, const void* s2, int size)
{
	return ::memcmp(s1, s2, size);
}