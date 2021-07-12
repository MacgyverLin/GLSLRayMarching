#include "FrameWork.h"
#include "Video.h"

/////////////////////////////////////////////////////////////////////
#include "Service.h"
#include "ResourceAccess.h"
#include "ResourceImport.h"
#include "Scene.h"
#include "Input.h"
#include "Physics3D.h"
#include "Physics2D.h"
#include "Video.h"
#include "Audio.h"
Service<Video> VideoService("Video");
Service<ResourceAccess> ResourceAccessService("ResourceAccess");
Service<ResourceImport> ResourceImportService("ResourceImport");
Service<Scene> SceneService("Scene");
Service<Input> InputService("Input");
Service<Physics3D> Physics3DService("Physics3D");
Service<Physics2D> Physics2DService("Physics2D");
Service<Audio> AudioService("Audio");

/////////////////////////////////////////////////////////////////////
#include "GameObject.h"

/////////////////////////////////////////////////////////////////////
#include "DefaultScene.h"
#include "ShaderToyScene.h"
#include "PathTraceScene.h"
#include "IKDemoScene.h"
#include "GeometryTextureScene.h"
#include "GeoMipmapTerrainScene.h"
#include "GeoMorphTerrainScene.h"
#include "LightFieldRendererScene.h"

Scene::Creator<DefaultScene> DefaultSceneCreator("Default");
Scene::Creator<ShaderToyScene> MacScene1Creator("ShaderToy");
Scene::Creator<PathTraceScene> MacScene2Creator("PathTrace");
Scene::Creator<IKDemoScene> IKDemoSceneCreator("IKDemo");
Scene::Creator<GeometryTextureScene> GeometryTextureSceneCreator("GeometryTexture");
Scene::Creator<GeoMipmapTerrainScene> GeoMipmapTerrainSceneCreator("GeoMorphTerrain");
Scene::Creator<GeoMorphTerrainScene> GeoMorphTerrainSceneCreator("GeoMorphTerrain");
Scene::Creator<LightFieldRendererScene> LightFieldRendererSceneCreator("LightFieldRenderer");

class MacShaderDemoApp : public FrameWork
{
public:
	MacShaderDemoApp(int argc, char** argv)
	: FrameWork(argc, argv)
	{
	}

	virtual ~MacShaderDemoApp()
	{
	}

	virtual bool OnInstantiate() override
	{
		return true;
	}

	virtual bool OnUpdate() override
	{
		return true;
	}

	void OnTerminate() override
	{
	}
private:
};

int main(int argc, char** argv)
{
	MacShaderDemoApp macShaderDemoApp(argc, argv);
#define SCALE 2
	if (!macShaderDemoApp.Instantiate(800* SCALE, 400 * SCALE, "MacShaderDemo", "ShaderToy"))
		return -1;

	macShaderDemoApp.Start();

	macShaderDemoApp.Terminate();

	return 0;
}