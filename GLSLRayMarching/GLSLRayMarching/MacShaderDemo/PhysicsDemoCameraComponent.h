#ifndef _PhysicsDemoCameraComponent_h_
#define _PhysicsDemoCameraComponent_h_

#include "Scene.h"
#include "GameObject.h"
#include "Texture.h"
#include "Scene.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "Buffer.h"
#include "VertexBuffer.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix4.h"
#include "GUI.h"
#include "Camera.h"
#include "GameObject.h"
#include "Video.h"

////////////////////////////////////////////////////////////////////////////
#define GEOMETRY_TEXTURE_SIZE 1024
#define NORMAL_TEXTURE_SIZE 512
      
class PhysicsDemoCameraComponent : public Video::CameraComponent
{
private:
	Matrix4 worldTransform;
	Camera camera;

public:
	PhysicsDemoCameraComponent(GameObject& object)
		: Video::CameraComponent(object)
	{
	}

	virtual ~PhysicsDemoCameraComponent()
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
		float dt = Platform::GetDeltaTime();
		static float angle = 0.0f;
		angle += 60 * dt;

		//worldTransform.SetTranslate(test1, 0, 0);
		worldTransform.SetTranslateEulerAngleXYZScale(0, 0, 0, 0, angle, 0, 6.0);
		camera.SetLocalTransform(worldTransform);

		Matrix4 cameraTransform;
		cameraTransform.SetLookAt(Vector3(5, 5, 5), Vector3(0, 0, 0), Vector3(0, 1, 0));
		camera.SetLocalTransform(cameraTransform);

		camera.SetPerspectiveFov(90.0f, float(Platform::GetWidth()) / Platform::GetHeight(), 1.0f, 1000.0f);

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

	const Matrix4& GetWorldTransform()
	{
		return worldTransform;
	}

	const Matrix4& GetViewTransform()
	{
		return camera.GetInverseGlobalTransform();
	}

	const Matrix4& GetProjectionTransform()
	{
		return camera.GetProjectionTransform();
	}
};

#endif