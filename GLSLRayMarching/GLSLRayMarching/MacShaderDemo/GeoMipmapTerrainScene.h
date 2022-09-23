#ifndef _GeoMipmapTerrainScene_h_
#define _GeoMipmapTerrainScene_h_

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
#include "TerrainCameraComponent.h"

class GeoMipmapTerrain : public Video::Graphics3Component
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

	GeoMipmapTerrain(GameObject& gameObject, TerrainCameraComponent& terrainCameraComponent_)
		: Video::Graphics3Component(gameObject)
		, terrainCameraComponent(terrainCameraComponent_)
	{
	}

	~GeoMipmapTerrain()
	{
	}

	virtual bool OnInitiate() override
	{
		if (!geoMipmap.Initiate(PATCH_SIZE))
			return false;

		return true;
	}

	virtual bool OnUpdate() override
	{
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
		geoMipmap.Terminate();
	}

	virtual void OnRender() override
	{
		Vector2 mouse = Vector2(Platform::GetMouseX(), Platform::GetMouseY());
		static int delay = 0;
		static bool wire = true;
		static bool solid = false;
		static float alpha = 0.0f;
		delay++;

		if (Input::Manager::GetInstance().GetKeyDown(Platform::KeyCode::Alpha1))
		{
			wire = !wire;
		}
		if (Input::Manager::GetInstance().GetKeyDown(Platform::KeyCode::Alpha2))
		{
			solid = !solid;
		}
		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::Alpha3))
		{
			alpha += 0.01f;
			alpha = (alpha > 1) ? 1 : alpha;
		}
		if (Input::Manager::GetInstance().GetKey(Platform::KeyCode::Alpha4))
		{
			alpha -= 0.01f;
			alpha = (alpha < 0) ? 0 : alpha;
		}

		geoMipmap.Render(terrainCameraComponent.camera, Vector2(Platform::GetWidth(), Platform::GetHeight()), solid, wire);
	}

	TerrainCameraComponent& terrainCameraComponent;

	GeoMipmap geoMipmap;
};

class GeoMipmapTerrainScene : public Scene
{
public:
	GeoMipmapTerrainScene()
		: Scene()
		, terrainCameraComponent(gameObject)
		, terrain(gameObject, terrainCameraComponent)
	{
	}

	virtual ~GeoMipmapTerrainScene()
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
	GameObject gameObject;
	TerrainCameraComponent terrainCameraComponent;
	GeoMipmapTerrain terrain;
};

#endif