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

#define A_CPU 1
#define FSR_EASU_F 1
#include "G:/Play/GLSLRayMarching/GLSLRayMarching/GLSLRayMarching/MacShaderDemo/Demos/AMD_FSR/ffx_a.h"
#include "G:/Play/GLSLRayMarching/GLSLRayMarching/GLSLRayMarching/MacShaderDemo/Demos/AMD_FSR/ffx_fsr1.h"
#define WIDTH 1600
#define HEIGHT 800

void test()
{
	float easuScale = 1.8f;
	AU1 con0[4] = { 0, 0, 0, 0 };
	AU1 con1[4] = { 0, 0, 0, 0 };
	AU1 con2[4] = { 0, 0, 0, 0 };
	AU1 con3[4] = { 0, 0, 0, 0 };

	AF1 inputViewportInPixelsX = WIDTH / easuScale;
	AF1 inputSizeInPixelsX = WIDTH;
	AF1 outputSizeInPixelsX = WIDTH;
	AF1 inputViewportInPixelsY = HEIGHT / easuScale;
	AF1 inputSizeInPixelsY = HEIGHT;
	AF1 outputSizeInPixelsY = HEIGHT;

	FsrEasuCon(con0, con1, con2, con3,
		inputViewportInPixelsX, inputViewportInPixelsY,  // Viewport size (top left aligned) in the input image which is to be scaled.
		inputSizeInPixelsX, inputSizeInPixelsY,      // The size of the input image.
		outputSizeInPixelsX, outputSizeInPixelsY);     // The output resolution.
}

int main(int argc, char** argv)
{
	MacShaderDemoApp macShaderDemoApp(argc, argv);
	if (!macShaderDemoApp.Instantiate(WIDTH, HEIGHT, "MacShaderDemo", "ShaderToy"))
		return -1;

	macShaderDemoApp.Start();

	macShaderDemoApp.Terminate();

	return 0;
}