//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Input_h_
#define _Input_h_

#include "Platform.h"
#include "Component.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Quaternion.h"

class Input
{
public:
	enum class Type
	{
		KeyOrMouseButton = 0,
		MouseMovement,
		JoystickAxis
	};

	enum class Axis
	{
		MouseX = 1,
		MouseY,
		Axis1 = 1,
		Axis2,
		Axis4,
		Axis5,
		Axis6,
		Axis7,
		Axis8,
		Axis9,
		Axis10,
		Axis11,
		Axis12,
		Axis13,
		Axis14,
		Axis15,
		Axis16,
		Axis17,
		Axis18,
		Axis19,
		Axis20,
		Axis21,
		Axis22,
		Axis23,
		Axis24,
		Axis25,
		Axis26,
		Axis27,
		Axis28
	};

	enum class JoyStick
	{
		JOYSTICK_ANY = 0,
		JOYSTICK_1,
		JOYSTICK_2,
		JOYSTICK_4,
		JOYSTICK_5,
		JOYSTICK_6,
		JOYSTICK_7,
		JOYSTICK_8,
		JOYSTICK_9,
		JOYSTICK_10,
		JOYSTICK_11,
		JOYSTICK_12,
		JOYSTICK_13,
		JOYSTICK_14,
		JOYSTICK_15,
		JOYSTICK_16
	};

	/*
	class Compass
	{
	public:
		bool enabled;			// Used to enable or disable compass.Note, that if you want Input.compass.trueHeading property to contain a valid value, you must also enable location updates by calling Input.location.Start().
		float headingAccuracy;	// Accuracy of heading reading in degrees.
		float magneticHeading;	// The heading in degrees relative to the magnetic North Pole. (Read Only)
		Vector3 rawVector;		// The raw geomagnetic data measured in microteslas. (Read Only)
		double timestamp;		// Timestamp(in seconds since 1970) when the heading was last time updated. (Read Only)
		float trueHeading;		// The heading in degrees relative to the geographic North Pole. (Read Only)
	};

	// enumerationLeave feedback
	// Description
	// Describes physical orientation of the device as determined by the OS.
	// 
	// If device is physically situated between discrete positions, as when(for example) rotated diagonally, system will report Unknown orientation.
	// 
	// Properties
	enum class DeviceOrientation
	{
		Unknown = 0,		// The orientation of the device cannot be determined.
		Portrait,			// The device is in portrait mode, with the device held uprightand the home button at the bottom.
		PortraitUpsideDown, // The device is in portrait mode but upside down, with the device held uprightand the home button at the top.
		LandscapeLeft,		// The device is in landscape mode, with the device held uprightand the home button on the right side.
		LandscapeRight,		// The device is in landscape mode, with the device held uprightand the home button on the left side.
		FaceUp,				// The device is held parallel to the ground with the screen facing upwards.
		FaceDown			// The device is held parallel to the ground with the screen facing downwards.
	};

	class Gyroscope
	{
	public:
		Quaternion attitude;			//	Returns the attitude(ie, orientation in space) of the device.
		bool enabled;					//	Sets or retrieves the enabled status of this gyroscope.
		Vector3 gravity;				//	Returns the gravity acceleration vector expressed in the device's reference frame.
		Vector3 rotationRate;			//	Returns rotation rate as measured by the device's gyroscope.
		Vector3 rotationRateUnbiased;	//	Returns unbiased rotation rate as measured by the device's gyroscope.
		float updateInterval;			//	Sets or retrieves gyroscope interval in seconds.
		Vector3 userAcceleration;		//	Returns the acceleration that the user is giving to the device.
	};

	enum class IMECompositionMode
	{
		Auto = 0,
		On,
		Off,
	};

	class LocationService
	{
	public:
		bool isEnabledByUser;		      //  Specifies whether location service is enabled in user settings.
		//LocationInfo lastData;		  //  Last measured device geographical location.
		//LocationServiceStatus status;   //  Returns location service status.
	};

	// static Vector3 acceleration;											// Last measured linear acceleration of a device in three - dimensional space. (Read Only)
	// static int accelerationEventCount;									// Number of acceleration measurements which occurred during last frame.
	// static std::vector<Vector3> accelerationEvents;						// Returns list of acceleration measurements which occurred during the last frame. (Read Only) (Allocates temporary variables).
	// static bool anyKey;													// Is any key or mouse button currently held down ? (Read Only)
	// static bool anyKeyDown;												// Returns true the first frame the user hits any key or mouse button. (Read Only)
	// static bool backButtonLeavesApp;										// Should Back button quit the application ? Only usable on Android, Windows Phone or Windows Tablets.
	// static Compass compass;												// Property for accessing compass(handheld devices only). (Read Only)
	// static bool compensateSensors;										// This property controls if input sensors should be compensated for screen orientation.
	// static Vector2 compositionCursorPos;									// The current text input position used by IMEs to open windows.
	// static std::string compositionString;								// The current IME composition string being typed by the user.
	// static DeviceOrientation deviceOrientation;							// Device physical orientation as reported by OS. (Read Only)
	// static Gyroscope gyro;												// Returns default gyroscope.
	// static IMECompositionMode imeCompositionMode;						// Controls enablingand disabling of IME input composition.
	// static bool imeIsSelected;											// Does the user have an IME keyboard input source selected ?
	// static std::string inputString;										// Returns the keyboard input entered this frame. (Read Only)
	// static LocationService	location;									// Property for accessing device location(handheld devices only). (Read Only)
	// static Vector3 mousePosition;										// The current mouse position in pixel coordinates. (Read Only).
	// static bool mousePresent;											// Indicates if a mouse device is detected.
	// static Vector2 mouseScrollDelta;										// The current mouse scroll delta. (Read Only)
	// static bool multiTouchEnabled;										// Property indicating whether the system handles multiple touches.
	// static bool simulateMouseWithTouches;								// Enables / Disables mouse simulation with touches.By default this option is enabled.
	// static bool stylusTouchSupported;									// Returns true when Stylus Touch is supported by a device or platform.
	// static int touchCount;												// Number of touches.Guaranteed not to change throughout the frame. (Read Only)
	// static std::vector<Touch> touches;									// Returns list of objects representing status of all touches during last frame. (Read Only) (Allocates temporary variables).
	// static bool touchPressureSupported;									// Bool value which let's users check if touch pressure is supported.
	// static bool touchSupported;											// Returns whether the device on which application is currently running supports touch input.
	*/

////////////////////////////////////////////////////////////////////////////////////////////////////////
	Input();
	Input(const std::string& name_,
		const std::string& descriptivePositiveName_,
		const std::string& descriptiveNegativeName_,
		Platform::KeyCode positiveButton_,
		Platform::KeyCode negativeButton_,
		Platform::KeyCode positiveAltButton_,
		Platform::KeyCode negativeAltButton_,
		float gravity_,
		float deadzone_,
		float sensitivity_,
		bool snap_,
		bool invert_,
		Type type_,
		Axis axis_,
		JoyStick joystick_);
	virtual ~Input();
	float GetAxis();
	float GetAxisRaw();
private:
	void Update();
	void UpdateKeyOrMouseButton();
	void UpdateMouseMovement();
	void UpdateJoystickAxis();	

	std::string name;
	std::string descriptivePositiveName;
	std::string descriptiveNegativeName;
	Platform::KeyCode positiveButton;
	Platform::KeyCode negativeButton;
	Platform::KeyCode positiveAltButton;
	Platform::KeyCode negativeAltButton;
	float gravity;
	float deadzone;
	float sensitivity;
	bool snap;
	bool invert;
	Type type;
	Axis axis;
	JoyStick joystick;

	float lastValue;
	float currentValue;
	float rawValue;

////////////////////////////////////////////////////////////////////////////////////////////////////////
public:
	class Service;

	class Event
	{
	public:
		float x;
		float y;
		int keyCode;
		int scanCode;
		int action;
		int mods;
	};

	class Manager
	{
		friend class Input;
		friend class Service;
		Manager();
		~Manager();
	public:
		static Input::Manager& GetInstance();

		Input& GetInput(const char* axisName);

		float GetAxis(const char* axisName);							// Returns the value of the virtual axis identified by axisName.
		float GetAxisRaw(const char* axisName);							// Returns the value of the virtual axis identified by axisName with no smoothing filtering applied.
		bool GetButtonDown(const char* axisName);						// Returns true during the frame the user pressed down the virtual button identified by axisName.
		bool GetButtonUp(const char* axisName);							// Returns true the first frame the user releases the virtual button identified by axisName.
		bool GetButtonHold(const char* axisName);						// Returns true while the virtual button identified by axisName is held down.
		bool GetButton(const char* axisName);							// Returns true while the virtual button identified by axisName is held down.

		bool GetKeyDown(Platform::KeyCode keyCode);						// Returns true during the frame the user starts pressing down the key identified by buttonName.
		bool GetKeyUp(Platform::KeyCode keyCode);						// Returns true during the frame the user releases the key identified by buttonName.
		bool GetKeyHold(Platform::KeyCode keyCode);						// Returns true while the user holds down the key identified by buttonName.
		bool GetKey(Platform::KeyCode keyCode);					// Returns true while the user holds down the key identified by buttonName.

		bool GetMouseButtonDown(int button);							// Returns true during the frame the user pressed the given mouse button.
		bool GetMouseButtonUp(int button); 								// Returns true during the frame the user releases the given mouse button.
		bool GetMouseButtonHold(int button); 								// Returns true during the frame the user releases the given mouse button.
		bool GetMouseButton(int button);								// Returns whether the given mouse button is held down.
		Vector2 GetMouseMovement();

		const std::vector<std::string>& GetJoystickNames();				// Retrieves a list of input device axisNames corresponding to the index of an Axis configured within Input Manager.

		typedef std::function<void(const Input::Event&)> EventCallBack;
		typedef std::list<EventCallBack *> EventCallBacks;

		void AddEventListener(const char *name, EventCallBack eventCallBack);
		void RemoveEventListener(EventCallBack eventCallBack);
	private:
		bool Initialize();
		bool Update();
		bool Pause();
		void Resume();
		void Terminate();
	private:
		std::map<const char*, Input> inputs;

		std::map<const char*, EventCallBacks> eventCallBacksMap;
	};

	///////////////////////////////////////////////////////////////////////
public:
	class Service
	{
	public:
		static bool Initialize();
		static bool Update();
		static bool Pause();
		static void Resume();
		static void Terminate();
	};
};

#endif