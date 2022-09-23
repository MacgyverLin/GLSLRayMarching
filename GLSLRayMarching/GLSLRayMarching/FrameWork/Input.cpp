//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "Input.h"

Input::Input()
{
}

Input::Input(
	const std::string& name_,
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
	JoyStick joystick_)
: name(name_)
, descriptivePositiveName(descriptivePositiveName_)
, descriptiveNegativeName(descriptiveNegativeName_)
, positiveButton(positiveButton_)
, negativeButton(negativeButton_)
, positiveAltButton(positiveAltButton_)
, negativeAltButton(negativeAltButton_)
, gravity(gravity_)
, deadzone(deadzone_)
, sensitivity(sensitivity_)
, snap(snap_)
, invert(invert_)
, type(type_)
, axis(axis_)
, joystick(joystick_)
, lastValue(0)
, currentValue(0)
, rawValue(0)
{
}

Input::~Input()
{
}

float Input::GetAxis()
{
	return currentValue;
}

float Input::GetAxisRaw()
{
	return rawValue;
}

void Input::UpdateKeyOrMouseButton()
{
	/*
	int posVK1 = keyCode2VKs[positiveButton];
	int negVK1 = keyCode2VKs[negativeButton];
	int posVK2 = keyCode2VKs[positiveAltButton];
	int negVK2 = keyCode2VKs[negativeAltButton];

	lastValue = currentValue;

	if (Input::Manager::GetInstance().currentValues[posVK1]>deadzone || Input::Manager::GetInstance().currentValues[posVK2] > deadzone)
	{
		if (!invert)
			rawValue = 1.0;
		else
			rawValue = -1.0;

		currentValue += rawValue * sensitivity * Platform::GetDeltaTime();
	}
	else if (Input::Manager::GetInstance().currentValues[negVK1] > deadzone || Input::Manager::GetInstance().currentValues[negVK2] > deadzone)
	{
		if (!invert)
			rawValue = -1.0;
		else
			rawValue = 1.0;

		currentValue += rawValue * sensitivity * Platform::GetDeltaTime();
	}

	if (gravity != 0)
	{
		currentValue -= Math::Sgn(currentValue) * gravity * Platform::GetDeltaTime();
	}

	if (currentValue > 1.0)
		currentValue = 1.0;

	if (currentValue < -1.0)
		currentValue = -1.0;
	*/
}

void Input::UpdateMouseMovement()
{
}

void Input::UpdateJoystickAxis()
{
}

void Input::Update()
{
	if (type == Type::KeyOrMouseButton)
	{
		UpdateKeyOrMouseButton();
	}
	else if (type == Type::MouseMovement)
	{
		UpdateMouseMovement();
	}
	else// if (type == Type::JoystickAxis)
	{
		UpdateJoystickAxis();
	}
}

/////////////////////////////////////////////////////////////////////
Input::Manager::Manager()
{
}

Input::Manager::~Manager()
{
}

Input::Manager& Input::Manager::GetInstance()
{
	static Input::Manager instance;

	return instance;
}

Input& Input::Manager::GetInput(const char* axisName)
{
	return inputs[axisName];
}

float Input::Manager::GetAxis(const char* axisName)
{
	return GetInput(axisName).GetAxis();
}

float Input::Manager::GetAxisRaw(const char* axisName)
{
	return GetInput(axisName).GetAxisRaw();
}

bool Input::Manager::GetButtonDown(const char* axisName)
{
	const Input& input = GetInput(axisName);

	return GetKeyDown(input.positiveButton);// || GetKeyDown(input.positiveAltButton);
}

bool Input::Manager::GetButtonUp(const char* axisName)
{
	const Input& input = GetInput(axisName);

	return GetKeyUp(input.positiveButton);// || GetKeyUp(input.positiveAltButton);
}

bool Input::Manager::GetButtonHold(const char* axisName)
{
	const Input& input = GetInput(axisName);

	return GetKeyHold(input.positiveButton);// || GetKeyUp(input.positiveAltButton);
}

bool Input::Manager::GetButton(const char* axisName)
{
	const Input& input = GetInput(axisName);

	return GetKey(input.positiveButton);// || GetKeyUp(input.positiveAltButton);
}

bool Input::Manager::GetKeyDown(Platform::KeyCode keyCode)
{
	return Platform::GetKeyDown(keyCode);
}

bool Input::Manager::GetKeyUp(Platform::KeyCode keyCode)
{
	return Platform::GetKeyUp(keyCode);
}

bool Input::Manager::GetKeyHold(Platform::KeyCode keyCode)
{
	return Platform::GetKeyHold(keyCode);
}

bool Input::Manager::GetKey(Platform::KeyCode keyCode)
{
	return Platform::GetKey(keyCode);
}

const std::vector<std::string>& Input::Manager::GetJoystickNames()
{
	return Platform::GetJoystickNames();
}

bool Input::Manager::GetMouseButtonDown(int button)
{
	if (button == 0)
		return GetKeyDown(Platform::KeyCode::Mouse0);
	else if (button == 1)
		return GetKeyDown(Platform::KeyCode::Mouse1);
	else// if (button == 2)
		return GetKeyDown(Platform::KeyCode::Mouse2);
}

bool Input::Manager::GetMouseButtonUp(int button)
{
	if (button == 0)
		return GetKeyUp(Platform::KeyCode::Mouse0);
	else if (button == 1)
		return GetKeyUp(Platform::KeyCode::Mouse1);
	else// if (button == 2)
		return GetKeyUp(Platform::KeyCode::Mouse2);
}

bool Input::Manager::GetMouseButtonHold(int button)
{
	if (button == 0)
		return GetKeyHold(Platform::KeyCode::Mouse0);
	else if (button == 1)
		return GetKeyHold(Platform::KeyCode::Mouse1);
	else// if (button == 2)
		return GetKeyHold(Platform::KeyCode::Mouse2);
}

bool Input::Manager::GetMouseButton(int button)
{
	if (button == 0)
		return GetKey(Platform::KeyCode::Mouse0);
	else if (button == 1)
		return GetKey(Platform::KeyCode::Mouse1);
	else// if (button == 2)
		return GetKey(Platform::KeyCode::Mouse2);
}

Vector2 Input::Manager::GetMouseMovement()
{
	return Vector2(Platform::GetMouseDX(), Platform::GetMouseDY());
}

void Input::Manager::AddEventListener(const char* name, EventCallBack eventCallBack)
{
	eventCallBacksMap[name].push_back(&eventCallBack);
}

void Input::Manager::RemoveEventListener(EventCallBack eventCallBack)
{
	for (auto& eventCallBacks : eventCallBacksMap)
	{
		eventCallBacks.second.remove(&eventCallBack);
	}
}

bool Input::Manager::Initialize()
{
	return true;
}

bool Input::Manager::Update()
{
	for (auto& eventCallBacks : eventCallBacksMap)
	{
		for (auto& eventCallBack : eventCallBacks.second)
		{
			Input::Event e;
			(*eventCallBack)(e);
		}
	}

	return true;
}

bool Input::Manager::Pause()
{
	return true;
}

void Input::Manager::Resume()
{
}

void Input::Manager::Terminate()
{
}

/////////////////////////////////////////////////////////////////////
bool Input::Service::Initialize()
{
	return Input::Manager::GetInstance().Initialize();
}

bool Input::Service::Update()
{
	return Input::Manager::GetInstance().Update();
}

bool Input::Service::Pause()
{
	return Input::Manager::GetInstance().Pause();
}

void Input::Service::Resume()
{
	Input::Manager::GetInstance().Resume();
}

void Input::Service::Terminate()
{
	Input::Manager::GetInstance().Terminate();
}