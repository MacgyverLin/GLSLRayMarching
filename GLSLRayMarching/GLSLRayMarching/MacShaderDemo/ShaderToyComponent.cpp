#include "ShaderToyComponent.h"
#include "FrameWork.h"

//////////////////////////////////////////////////////////////
ShaderToyComponent::ShaderToyComponent(GameObject& gameObject_)
	: Graphics3Component(gameObject_)
	, listenerComponent(gameObject_)
	, streamSourceComponent(gameObject_)
{
	shaderToyRenderer = new ShaderToyRenderer(streamSourceComponent);
}

ShaderToyComponent::~ShaderToyComponent()
{
	if (shaderToyRenderer)
	{
		delete shaderToyRenderer;
		shaderToyRenderer = nullptr;
	}
}

Vector4 ShaderToyComponent::GetMouse()
{
	static Vector4 r;

	if (Platform::GetKeyDown(Platform::KeyCode::Mouse0))
	{
		r.Z() = 1;
		r.W() = 1;

		r.X() = Platform::GetMouseX();
		r.Y() = Platform::GetMouseY();
	}
	else if (Platform::GetKeyUp(Platform::KeyCode::Mouse0))
	{
		r.Z() = -1;
		r.W() = 0;
	}
	else if (Platform::GetKeyHold(Platform::KeyCode::Mouse0))
	{
		r.Z() = 1;
		r.W() = 0;

		r.X() = Platform::GetMouseX();
		r.Y() = Platform::GetMouseY();
	}

	//Debug("%f %f %f %f\n", r.X(), r.Y(), r.Z(), r.W());

	return r;
}

void ShaderToyComponent::OnRender()
{
	shaderToyRenderer->Render
	(
		Platform::GetWidth(),
		Platform::GetHeight(),
		Platform::GetTime(),
		Platform::GetDeltaTime(),
		GetMouse(),
		Vector2(Platform::GetMouseDX(), Platform::GetMouseDY()),
		Platform::GetSceneFrameCounter() - 1
	);
}

bool ShaderToyComponent::OnInitiate()
{
	return true;
}

bool ShaderToyComponent::OnStart()
{
	//return shaderToyRenderer->Initiate("Demos/default");
	//return shaderToyRenderer->Initiate("Demos/Path Tracing Cornell Box 2");
	//return shaderToyRenderer->Initiate("Demos/Path Tracing (+ELS)");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Path tracing cornellbox with MIS");
	//return shaderToyRenderer->Initiate("Demos/[NV15] Space Curvature");
	//return shaderToyRenderer->Initiate("Demos/Buoy");
	//return shaderToyRenderer->Initiate("Demos/Music - Pirates");
	//return shaderToyRenderer->Initiate("Demos/Fork Heartfelt Nepse 180");
	//return shaderToyRenderer->Initiate("Demos/Rainier mood");
	//return shaderToyRenderer->Initiate("Demos/Noise/Perlin");//
	//return shaderToyRenderer->Initiate("Demos/Clouds/Cheap Cloud Flythrough");//
	//return shaderToyRenderer->Initiate("Demos/Clouds/Cloud");//
	//return shaderToyRenderer->Initiate("Demos/Clouds/CloudFight");//
	//return shaderToyRenderer->Initiate("Demos/Clouds/Cloud2");//
	//return shaderToyRenderer->Initiate("Demos/default");
	//return shaderToyRenderer->Initiate("Demos/Greek Temple");
	//return shaderToyRenderer->Initiate("Demos/JustForFuns/Hexagonal Grid Traversal - 3D");		
	//return shaderToyRenderer->Initiate("Demos/JustForFuns/MO");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Bidirectional path tracing");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Demofox Path Tracing 1");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Demofox Path Tracing 2");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Path Tracer MIS");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/PBR Material Gold");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Room DI");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Monte Carlo path tracer");
	//return shaderToyRenderer->Initiate("Demos/Post process - SSAO");
	//return shaderToyRenderer->Initiate("Demos/Biplanar mapping");
	//return shaderToyRenderer->Initiate("Demos/Scattering/Atmospheric scattering explained");
	//return shaderToyRenderer->Initiate("Demos/Scattering/Atmospheric Scattering Fog");
	//return shaderToyRenderer->Initiate("Demos/Scattering/Fast Atmospheric Scattering");
	//return shaderToyRenderer->Initiate("Demos/Scattering/RayleighMieDayNight");
	//return shaderToyRenderer->Initiate("Demos/Scattering/RealySimpleAtmosphericScatter");
	//return shaderToyRenderer->Initiate("Demos/Terrains/Cloudy Terrain");
	//return shaderToyRenderer->Initiate("Demos/Terrains/Desert Sand");
	return shaderToyRenderer->Initiate("Demos/Terrains/Elevated");
	////return shaderToyRenderer->Initiate("Demos/Terrains/Lake in highland");
	////return shaderToyRenderer->Initiate("Demos/Terrains/Mountains");
	////return shaderToyRenderer->Initiate("Demos/Terrains/Rainforest");
	// return shaderToyRenderer->Initiate("Demos/Fractal");
	// return shaderToyRenderer->Initiate("Demos/Terrains/Sirenian Dawn");
	////return shaderToyRenderer->Initiate("Demos/SimpleTexture");	
	
	//return shaderToyRenderer->Initiate("Demos/CubemapTest");
	 
	//return shaderToyRenderer->Initiate("Demos/Waters/RiverGo");
	//return shaderToyRenderer->Initiate("Demos/Waters/RiverGo");
	//return shaderToyRenderer->Initiate("Demos/Waters/Oceanic");
	//return shaderToyRenderer->Initiate("Demos/Waters/Ocean");
	//return shaderToyRenderer->Initiate("Demos/Waters/Very fast procedural ocean");
	//return shaderToyRenderer->Initiate("Demos/Waters/Water World");
	//return shaderToyRenderer->Initiate("Demos/Wave Propagation Effect");
	//return shaderToyRenderer->Initiate("Demos/Beneath the Sea God Ray");
	//return shaderToyRenderer->Initiate("Demos/Scattering/VolumetricIntegration");
	//return shaderToyRenderer->Initiate("Demos/Waters/Spout");

	//return shaderToyRenderer->Initiate("Demos/PathTracings/Path Tracer MIS");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Bidirectional path tracing");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Room DI");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Spatiotemporal Variance-Guided Filtering");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/StepByStepTutorial");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Cornell MIS");	
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/5 Caustics");

	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/8 SubSurface");	
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/7 Disney Principled BRDF");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/6 PBR");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/5 Caustics");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/4 Bidirectional path tracing");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/3 Path Tracer MIS");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/2 Light Sampling");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/1 Simple Random Sampling");	
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/9 Step By Step");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/10 Step By Step");
}

bool ShaderToyComponent::OnUpdate()
{
	return true;
}

bool ShaderToyComponent::OnPause()
{
	return true;
}

void ShaderToyComponent::OnResume()
{
}

void ShaderToyComponent::OnStop()
{
}

void ShaderToyComponent::OnTerminate()
{
}