#ifndef _LPVCamera_h_ 
#define _LPVCamera_h_ 

#include "Component.h"
#include "Video.h"
#include "Vector3.h"
#include "Quaternion.h"
#include "Matrix4.h"
#include "Input.h"
#include <map>

class LPVCamera
{
	class Keys
	{
	public:
		Keys()
		{
		}

		int& operator [] (int key)
		{
			return map[key];
		}

		std::map<int, int> map;
	};
public:
	LPVCamera(const Vector3& position_ = Vector3::Zero, const Quaternion& orientation_ = Quaternion::Identity);

	virtual ~LPVCamera();

	virtual bool Initiate();

	virtual bool Start();

	virtual bool Update();

	virtual bool Pause();

	virtual void Resume();

	virtual void Stop();

	virtual void Terminate();

	virtual void Render();
private:
	void KeyDownListener(const Input::Event& e);
	void KeyUpListener(const Input::Event& e);
	void MouseKeyDownListener(const Input::Event& e);
	void MouseKeyUpListener(const Input::Event& e);
	void MouseMoveListener(const Input::Event& e);
public:
private:
	void SetKeyState(Keys& map, int keyCode, int val);

	void Resize();
	void UpdateProjectionMatrix(float aspectRatio);
	void UpdateViewMatrix();

public:
	Vector3 Position()
	{
		return position;
	}

	Quaternion Orientation()
	{
		return orientation;
	}

	Matrix4 ViewMatrix()
	{
		return viewMatrix;
	}

	Matrix4 ProjectionMatrix()
	{
		return projectionMatrix;
	}
private:
	Vector3 position;
	Quaternion orientation;

	float near;
	float far;
	float fovDegrees;

	Matrix4 viewMatrix;
	Matrix4 projectionMatrix;

	std::function<void(const Matrix4&)> OnViewMatrixChange;
	std::function<void(const Matrix4&)> OnProjectionMatrixChange;

	float moveSpeed;
	float rotationSpeed;

	bool controlsEnabled;

	Vector2 currentMousePos;
	Vector2 lastMousePos;

	Keys keys;
};

#endif