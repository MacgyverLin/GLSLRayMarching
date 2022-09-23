#ifndef _TerrainCameraComponent_h_
#define _TerrainCameraComponent_h_

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
#include "GeoMipmap.h"
#include "GeoMorph.h"
#include "Camera.h"
#include "FrameWork.h"
#include "Scene.h"
#include "GameObject.h"
#include "IKShapes.h"

//////////////////////////////////////////////////////////////////////
class TerrainCameraComponent : public Video::CameraComponent
{
public:
	TerrainCameraComponent(GameObject& object)
		: Video::CameraComponent(object)
#ifdef CAPTURE_GRAPHICS
		, pos(0, 1, 0)
#else
		, pos(100, 600, 100)
#endif
		, phi(0.7343)
		, theta(-0.5733)
	{
	}

	virtual ~TerrainCameraComponent()
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
		//Debug("%f %f\n", mousedelta.X(), mousedelta.Y());

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::Mouse1))
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


#ifdef CAPTURE_GRAPHICS
		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::W))
		{
			pos += Vector3(1.2, 0, 0);
		}

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::S))
		{
			pos -= Vector3(1.2, 0, 0);
		}

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::A))
		{
			pos += Vector3(0, 0, 1.2);
		}

		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::D))
		{
			pos -= Vector3(0, 0, 1.2);
		}
		*/
			Vector3 obj = pos + Vector3(0, -1, 0);

		Matrix4 cameraTransform;
		cameraTransform.SetLookAt(pos, obj, Vector3::UnitX);
		camera.SetLocalTransform(cameraTransform);
		camera.SetPerspectiveFov(90.0f, float(Platform::GetWidth()) / Platform::GetHeight(), 1.0f, 5000.0f);
#else
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
		cameraTransform.SetLookAt(pos, obj, Vector3::UnitY);
		camera.SetLocalTransform(cameraTransform);
		camera.SetPerspectiveFov(90.0f, float(Platform::GetWidth()) / Platform::GetHeight(), 1.0f, 5000.0f);
#endif

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

#endif