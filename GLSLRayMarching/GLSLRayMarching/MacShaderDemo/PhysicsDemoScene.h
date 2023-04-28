#ifndef _PhysicsDemoScene_h_
#define _PhysicsDemoScene_h_

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
#include "PhysicsDemoCameraComponent.h"
#include "PhysicsDemoGraphicComponent.h"

class PhysicsDemoScene : public Scene
{
public:
	PhysicsDemoScene()
		: Scene()
		, physicsDemoCameraComponent(physicsDemoCameraGameObject)
		, physicsDemoGraphicComponent(physicsDemoGraphicGameObject)
	{
	}

	virtual ~PhysicsDemoScene()
	{
	}
protected:
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
		physicsDemoGraphicComponent.SetWorldTransform
		(
			physicsDemoCameraComponent.GetWorldTransform(),
			physicsDemoCameraComponent.GetViewTransform(),
			physicsDemoCameraComponent.GetProjectionTransform()
		);

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
private:
	GameObject physicsDemoCameraGameObject;
	PhysicsDemoCameraComponent physicsDemoCameraComponent;

	GameObject physicsDemoGraphicGameObject;
	PhysicsDemoGraphicComponent physicsDemoGraphicComponent;
};

#endif