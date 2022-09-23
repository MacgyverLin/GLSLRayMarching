#ifndef _IKShapes_h_
#define _IKShapes_h_

#include "Texture.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "Buffer.h"
#include "VertexBuffer.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix4.h"
#include "GUI.h"
#include "AABB3.h"
#include "Shape.h"
#include "Camera.h"
#include "IK2DNJoint.h"
#include "IK2D2Joint.h"
#include "IK2DCCDJoint.h"
#include "IK2DFABRIKJoint.h"
#include "Video.h"
#include "GameObject.h"
#include "FrameWork.h"
#include "Scene.h"
#include "Input.h"

class IKCameraComponent : public Video::CameraComponent
{
public:
	IKCameraComponent(GameObject& object)
		: Video::CameraComponent(object)
		, pos(100, 600, 100)
		, phi(0.7343)
		, theta(-0.5733)
	{
	}

	virtual bool OnInitiate() override
	{
		return true;
	}

	virtual bool OnStart() override
	{
		return true;
	}

	virtual bool OnUpdate() override
	{
		Vector2 mousedelta = Vector2(Platform::GetMouseDX(), Platform::GetMouseDY());
		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::Mouse2))
		{
			phi += mousedelta.X() / (Platform::GetWidth() / 2) * 180 * Math::Degree2Radian;
			//if (phi > 180 * Math::Degree2Radian)
				//phi = 180 * Math::Degree2Radian;
			//if (phi < -180 * Math::Degree2Radian)
				//phi = -180 * Math::Degree2Radian;

			theta += mousedelta.Y() / (Platform::GetHeight() / 2) * 180 * Math::Degree2Radian;
			if (theta > 89.9 * Math::Degree2Radian)
				theta = 89.9 * Math::Degree2Radian;
			if (theta < -89.9 * Math::Degree2Radian)
				theta = -89.9 * Math::Degree2Radian;
		}

		Vector3 dir = Vector3(Math::Cos(theta) * Math::Cos(phi), Math::Sin(theta), Math::Cos(theta) * Math::Sin(phi)); dir.Normalize();
		Vector3 xAxis = dir.Cross(Vector3::UnitY); xAxis.Normalize();
		//		Debug("%f %f\n", theta, phi);

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::W))
		{
			pos += dir;
		}

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::S))
		{
			pos -= dir;
		}

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::A))
		{
			pos -= xAxis;
		}

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::D))
		{
			pos += xAxis;
		}

		Vector3 obj = pos + dir;
		Matrix4 cameraTransform;
		//cameraTransform.SetLookAt(pos, obj, Vector3::UnitY);
		//cameraTransform.SetLookAt(Vector3(10, 10, -10), Vector3::Zero, Vector3::UnitY);
		cameraTransform.SetLookAt(Vector3(0, 0, -10), Vector3::Zero, Vector3::UnitY);
		camera.SetLocalTransform(cameraTransform);
		camera.SetOrthogonal(20.0f, (20.0f * Platform::GetHeight()) / Platform::GetWidth(), 1.0f, 5000.0f);

		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
	}

	virtual void OnRender() override
	{
		ClearState clearState;
		clearState.clearColor = ColorRGBA(0.0f, 0.0f, 0.0f, 1.0f);
		clearState.clearDepth = 1.0f;
		clearState.clearStencil = 0;
		clearState.enableClearColor = true;
		clearState.enableClearDepth = true;
		clearState.enableClearStencil = true;
		clearState.Apply();
	}

	Camera camera;
	Vector3 pos;
	float phi;
	float theta;
};

//////////////////////////////////////////////////////////////////////
class IK2D2JointShape : public Video::Graphics3Component
{
public:
	class UniformData
	{
	public:
		Matrix4 worldTransform;
		Matrix4 viewTransform;
		Matrix4 projTransform;
		ColorRGBA color;
	};

	IK2D2JointShape(GameObject& gameObject, IKCameraComponent& ikCameraComponent_)
		: Video::Graphics3Component(gameObject)
		, ikCameraComponent(ikCameraComponent_)
	{
	}

	~IK2D2JointShape()
	{
	}

	virtual bool OnInitiate() override
	{
		ikChain2D.SetPositions(Vector2(0, 0), Vector2(3, 3), Vector2(6, -2));
		if (!ikChain2D.Initiate())
			return false;

		shapes.resize(ikChain2D.GetJointCount());
		for (int i = 0; i < shapes.size(); i++)
		{
			bool success =
				shapes[i].Begin().
				XYRect(Vector3(ikChain2D.GetLength(i), 0.1, 0), Vector3(-ikChain2D.GetLength(i) / 2, 0, 0)).
				End();

			if (!success)
				return false;

			ColorRGBA color = ColorRGBA(Math::UnitRandom(), Math::UnitRandom(), Math::UnitRandom());
			shapes[i].GetUniformBlockData().color = color;

			if (i - 1 >= 0)
				shapes[i - 1].AddChild(&shapes[i]);
		}

		return true;
	}

	virtual bool OnUpdate() override
	{
		Vector2 mouse = Vector2(Platform::GetMouseX(), Platform::GetMouseY());
		Vector2 targetPosition = Vector2
		(
			-(mouse.X() - Platform::GetWidth() / 2) / (Platform::GetWidth() / 2) * 10.0f,
			(mouse.Y() - Platform::GetHeight() / 2) / (Platform::GetHeight() / 2) * (10.0f * Platform::GetHeight()) / Platform::GetWidth()
		);

		ikChain2D.Update(targetPosition);

		for (int i = 0; i < shapes.size(); i++)
		{
			if (i == 0)
				shapes[i].SetTranslateEulerAngleZXYScale(ikChain2D.GetRoot().X(), ikChain2D.GetRoot().Y(), 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
			else
				shapes[i].SetTranslateEulerAngleZXYScale((i - 1 >= 0 ? ikChain2D.GetLength(i - 1) : 0), 0, 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
		}

		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Terminate();
	}

	virtual void OnRender() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));
	}

	IK2D2Joint ikChain2D;
	std::vector<Shape<UniformData>> shapes;
	IKCameraComponent& ikCameraComponent;
};

////////////////////////////////////////////////////////////////////
class IK2DNJointShape : public Video::Graphics3Component
{
public:
	class UniformData
	{
	public:
		Matrix4 worldTransform;
		Matrix4 viewTransform;
		Matrix4 projTransform;
		ColorRGBA color;
	};

	IK2DNJointShape(GameObject& gameObject, IKCameraComponent& ikCameraComponent_)
		: Video::Graphics3Component(gameObject)
		, ikCameraComponent(ikCameraComponent_)
	{
	}

	~IK2DNJointShape()
	{
	}

	virtual bool OnInitiate() override
	{
#define JOINT_COUNT 6

		Vector2 pos(1, 3);

		ikChain2D.Begin(1, 10);
		for (int i = 0; i < JOINT_COUNT; i++)
		{
			ikChain2D.AddJoint(pos, i == 0 ? -90 : -45, i == 0 ? 90 : 45);
			pos += Vector2(Math::IntervalRandom(-2, 2), Math::IntervalRandom(-2, 2));
		}
		ikChain2D.End(pos);
		if (!ikChain2D.Initiate())
			return false;

		shapes.resize(ikChain2D.GetJointCount());
		for (int i = 0; i < shapes.size(); i++)
		{
			bool success =
				shapes[i].Begin().
				XYRect(Vector3(ikChain2D.GetLength(i), 0.1, 0), Vector3(-ikChain2D.GetLength(i) / 2, 0, 0)).
				End();

			if (!success)
				return false;

			ColorRGBA color = ColorRGBA(Math::UnitRandom(), Math::UnitRandom(), Math::UnitRandom());
			shapes[i].GetUniformBlockData().color = color;

			if (i - 1 >= 0)
				shapes[i - 1].AddChild(&shapes[i]);
		}

		return true;
	}

	virtual bool OnUpdate() override
	{
		Vector2 mouse = Vector2(Platform::GetMouseX(), Platform::GetMouseY());
		Vector2 targetPosition = Vector2
		(
			-(mouse.X() - Platform::GetWidth() / 2) / (Platform::GetWidth() / 2) * 10.0f,
			(mouse.Y() - Platform::GetHeight() / 2) / (Platform::GetHeight() / 2) * (10.0f * Platform::GetHeight()) / Platform::GetWidth()
		);

		ikChain2D.Update(targetPosition);

		for (int i = 0; i < shapes.size(); i++)
		{
			if (i == 0)
				shapes[i].SetTranslateEulerAngleZXYScale(ikChain2D.GetRoot().X(), ikChain2D.GetRoot().Y(), 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
			else
				shapes[i].SetTranslateEulerAngleZXYScale((i - 1 >= 0 ? ikChain2D.GetLength(i - 1) : 0), 0, 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
		}

		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));

		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Terminate();
	}

	virtual void OnRender() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));
	}

	IK2DNJoint ikChain2D;
	std::vector<Shape<UniformData>> shapes;
	IKCameraComponent& ikCameraComponent;
};

//////////////////////////////////////////////////////////////////////
class IK2DCCDJointShape : public Video::Graphics3Component
{
public:
	class UniformData
	{
	public:
		Matrix4 worldTransform;
		Matrix4 viewTransform;
		Matrix4 projTransform;
		ColorRGBA color;
	};

	IK2DCCDJointShape(GameObject& gameObject, IKCameraComponent& ikCameraComponent_)
		: Video::Graphics3Component(gameObject)
		, ikCameraComponent(ikCameraComponent_)
	{
	}

	~IK2DCCDJointShape()
	{
	}

	virtual bool OnInitiate() override
	{
		Vector2 pos(1, 3);

		ikChain2D.Begin(10, true, true);
		for (int i = 0; i < JOINT_COUNT; i++)
		{
			ikChain2D.AddJoint(pos, i == 0 ? -90 : -45, i == 0 ? 90 : 45, 0.05);
			pos += Vector2(Math::IntervalRandom(-2, 2), Math::IntervalRandom(-2, 2));
		}
		ikChain2D.End(pos);
		if (!ikChain2D.Initiate())
			return false;

		shapes.resize(ikChain2D.GetJointCount());
		for (int i = 0; i < shapes.size(); i++)
		{
			bool success =
				shapes[i].Begin().
				XYRect(Vector3(ikChain2D.GetLength(i), 0.1, 0), Vector3(-ikChain2D.GetLength(i) / 2, 0, 0)).
				End();

			if (!success)
				return false;

			ColorRGBA color = ColorRGBA(Math::UnitRandom(), Math::UnitRandom(), Math::UnitRandom());
			shapes[i].GetUniformBlockData().color = color;

			if (i - 1 >= 0)
				shapes[i - 1].AddChild(&shapes[i]);
		}

		return true;
	}

	virtual bool OnUpdate() override
	{
		Vector2 mouse = Vector2(Platform::GetMouseX(), Platform::GetMouseY());
		Vector2 targetPosition = Vector2
		(
			-(mouse.X() - Platform::GetWidth() / 2) / (Platform::GetWidth() / 2) * 10.0f,
			(mouse.Y() - Platform::GetHeight() / 2) / (Platform::GetHeight() / 2) * (10.0f * Platform::GetHeight()) / Platform::GetWidth()
		);

		ikChain2D.Update(targetPosition);

		for (int i = 0; i < shapes.size(); i++)
		{
			if (i == 0)
				shapes[i].SetTranslateEulerAngleZXYScale(ikChain2D.GetRoot().X(), ikChain2D.GetRoot().Y(), 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
			else
				shapes[i].SetTranslateEulerAngleZXYScale((i - 1 >= 0 ? ikChain2D.GetLength(i - 1) : 0), 0, 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
		}

		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));

		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Terminate();
	}

	virtual void OnRender() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));
	}

	IK2DCCDJoint ikChain2D;
	std::vector<Shape<UniformData>> shapes;
	IKCameraComponent& ikCameraComponent;
};

class IK2DFABRIKJointShape : public Video::Graphics3Component
{
public:
	class UniformData
	{
	public:
		Matrix4 worldTransform;
		Matrix4 viewTransform;
		Matrix4 projTransform;
		ColorRGBA color;
	};

	IK2DFABRIKJointShape(GameObject& gameObject, IKCameraComponent& ikCameraComponent_)
		: Video::Graphics3Component(gameObject)
		, ikCameraComponent(ikCameraComponent_)
	{
	}

	~IK2DFABRIKJointShape()
	{
	}

	virtual bool OnInitiate() override
	{
		Vector2 pos(1, 3);

		ikChain2D.Begin(10, true);
		for (int i = 0; i < JOINT_COUNT; i++)
		{
			ikChain2D.AddJoint(pos, i == 0 ? -90 : -45, i == 0 ? 90 : 45);
			pos += Vector2(Math::IntervalRandom(-2, 2), Math::IntervalRandom(-2, 2));
		}
		ikChain2D.End(pos);
		if (!ikChain2D.Initiate())
			return false;

		shapes.resize(ikChain2D.GetJointCount());
		for (int i = 0; i < shapes.size(); i++)
		{
			bool success =
				shapes[i].Begin().
				XYRect(Vector3(ikChain2D.GetLength(i), 0.1, 0), Vector3(-ikChain2D.GetLength(i) / 2, 0, 0)).
				End();

			if (!success)
				return false;

			ColorRGBA color = ColorRGBA(Math::UnitRandom(), Math::UnitRandom(), Math::UnitRandom());
			shapes[i].GetUniformBlockData().color = color;

			if (i - 1 >= 0)
				shapes[i - 1].AddChild(&shapes[i]);
		}

		return true;
	}

	virtual bool OnUpdate() override
	{
		Vector2 mouse = Vector2(Platform::GetMouseX(), Platform::GetMouseY());
		Vector2 targetPosition = Vector2
		(
			-(mouse.X() - Platform::GetWidth() / 2) / (Platform::GetWidth() / 2) * 10.0f,
			(mouse.Y() - Platform::GetHeight() / 2) / (Platform::GetHeight() / 2) * (10.0f * Platform::GetHeight()) / Platform::GetWidth()
		);

		ikChain2D.Update(targetPosition);

		/*
		for (int i = 0; i < shapes.size(); i++)
		{
			if (i == 0)
				shapes[i].SetTranslateRotZXYScale(ikChain2D.GetRoot().X(), ikChain2D.GetRoot().Y(), 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
			else
				shapes[i].SetTranslateRotZXYScale((i - 1 >= 0 ? ikChain2D.GetLength(i - 1) : 0), 0, 0, ikChain2D.GetJointAngle(i), 0, 0, 1.0);
		}
		*/

		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));

		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Terminate();
	}

	virtual void OnRender() override
	{
		for (int i = 0; i < shapes.size(); i++)
			shapes[i].Render(ikCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()));
	}

	IK2DFABRIKJoint ikChain2D;
	std::vector<Shape<UniformData>> shapes;
	IKCameraComponent& ikCameraComponent;
};

#endif