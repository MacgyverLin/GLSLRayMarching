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
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Path Tracing Cornell Box 2");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Path Tracing (+ELS)");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Path tracing cornellbox with MIS");
	//return shaderToyRenderer->Initiate("Demos/[NV15] Space Curvature");//streamSourceComponentU
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
	//return shaderToyRenderer->Initiate("Demos/Terrains/Elevated");
	//return shaderToyRenderer->Initiate("Demos/Terrains/Lake in highland");
	//return shaderToyRenderer->Initiate("Demos/Terrains/Mountains");
	//return shaderToyRenderer->Initiate("Demos/Terrains/Rainforest");
	//return shaderToyRenderer->Initiate("Demos/Terrains/Sirenian Dawn");
	//return shaderToyRenderer->Initiate("Demos/SimpleTexture");	


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
	////return shaderToyRenderer->Initiate("Demos/PathTracings/Course/1 Simple Random Sampling");	
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/9 Step By Step");
	//return shaderToyRenderer->Initiate("Demos/PathTracings/Course/10 Step By Step");
	
	
	//return shaderToyRenderer->Initiate("Demos/Diamonds/Diamonds1");
	//return shaderToyRenderer->Initiate("Demos/Hand-drawn Sketch");
	//return shaderToyRenderer->Initiate("Demos/Shader try of Star of Bethlehem"); 
	//return shaderToyRenderer->Initiate("Demos/Template/BufferA_Image"); 
	//return shaderToyRenderer->Initiate("Demos/Template/BufferA_Image_4Tex"); 
	//return shaderToyRenderer->Initiate("Demos/Template/Common_Image"); 
	//return shaderToyRenderer->Initiate("Demos/Where The Water Go"); 


	//return shaderToyRenderer->Initiate("Demos/Wednesday messing around");
	//return shaderToyRenderer->Initiate("Demos/Tunnel Experiment #2"); 
	//return shaderToyRenderer->Initiate("Demos/Controllable Machinery");
	//return shaderToyRenderer->Initiate("Demos/Coastal Landscape");
	//return shaderToyRenderer->Initiate("Demos/Pig Squad 9 Year Anniversary");
	//return shaderToyRenderer->Initiate("Demos/Cubic Dispersal");
	//return shaderToyRenderer->Initiate("Demos/Color processing");
	//return shaderToyRenderer->Initiate("Demos/Space ship");
	//return shaderToyRenderer->Initiate("Demos/Stars and galaxy");
	//return shaderToyRenderer->Initiate("Demos/Party Concert Visuals 2020");
	//return shaderToyRenderer->Initiate("Demos/OMZG Shader Royale - NuSan");
	//return shaderToyRenderer->Initiate("Demos/RME4 - Crater");
	//return shaderToyRenderer->Initiate("Demos/CLUB-CAVE-09");
	//return shaderToyRenderer->Initiate("Demos/Alexander horned sphere zoom");
	//return shaderToyRenderer->Initiate("Demos/Spiraled Layers");
	//return shaderToyRenderer->Initiate("Demos/Taste of Noise 7");
	//return shaderToyRenderer->Initiate("Demos/Cable nest");
	//return shaderToyRenderer->Initiate("Demos/Apollian with a twist");
	//return shaderToyRenderer->Initiate("Demos/Night Sneakings");
	//return shaderToyRenderer->Initiate("Demos/Energy plant");

	//return shaderToyRenderer->Initiate("Demos/CubemapTest");
	//return shaderToyRenderer->Initiate("Demos/WebCamTextureTest");
	//return shaderToyRenderer->Initiate("Demos/MicrophoneTextureTest");
	//return shaderToyRenderer->Initiate("Demos/VideoTextureTest");
	//return shaderToyRenderer->Initiate("Demos/Cubemaps/Geometric Cellular Surfaces");
	//return shaderToyRenderer->Initiate("Demos/Cubemaps/Cubemaps");
	//return shaderToyRenderer->Initiate("Demos/A cup of champagne");
	//return shaderToyRenderer->Initiate("Demos/Diamonds/Gem Bloom FX");
	//return shaderToyRenderer->Initiate("Demos/CubemapTest");
	//return shaderToyRenderer->Initiate("Demos/Diamonds/Diamonds1");
	//return shaderToyRenderer->Initiate("Demos/Rounded Voronoi Borders");
	//return shaderToyRenderer->Initiate("Demos/Controllable Hexapod 2");
	//return shaderToyRenderer->Initiate("Demos/Neon Dance");
	//return shaderToyRenderer->Initiate("Demos/Extruded Truchet Pattern");
	//return shaderToyRenderer->Initiate("Demos/Liberation of the True Self");
	//return shaderToyRenderer->Initiate("Demos/Dry ice 2");
	//return shaderToyRenderer->Initiate("Demos/PUMA CLYDE CONCEPT");
	//return shaderToyRenderer->Initiate("Demos/Neon Tunnel");
	//return shaderToyRenderer->Initiate("Demos/Not Day");
	//return shaderToyRenderer->Initiate("Demos/Warped Extruded Skewed Grid");
	//return shaderToyRenderer->Initiate("Demos/Underground Passageway");


	//return shaderToyRenderer->Initiate("Demos/Re-entry");
	//return shaderToyRenderer->Initiate("Demos/Shine On You Crazy Ball");
	//return shaderToyRenderer->Initiate("Demos/Abandoned Construction");
	//return shaderToyRenderer->Initiate("Demos/Tempting the Mariner");
	//return shaderToyRenderer->Initiate("Demos/Blurry Spheres");
	//return shaderToyRenderer->Initiate("Demos/Echeveria II"); 
	//return shaderToyRenderer->Initiate("Demos/Alien Core");
	//return shaderToyRenderer->Initiate("Demos/Boxy Pikachu");
	//return shaderToyRenderer->Initiate("Demos/Triangle Grid Contouring");
	//return shaderToyRenderer->Initiate("Demos/Abstract Terrain Objects");
	//return shaderToyRenderer->Initiate("Demos/The Amazing World of Gumball");
	//return shaderToyRenderer->Initiate("Demos/Backlit Lighthouse");
	//return shaderToyRenderer->Initiate("Demos/Patience 2");
	//return shaderToyRenderer->Initiate("Demos/Anthropo[s]cene is dead");
	//return shaderToyRenderer->Initiate("Demos/Geodesic tiling");
	//return shaderToyRenderer->Initiate("Demos/At The Mountains");
	//return shaderToyRenderer->Initiate("Demos/Protean clouds");
	//return shaderToyRenderer->Initiate("Demos/dez");
	//return shaderToyRenderer->Initiate("Demos/Digiverse - worms (a.ka pasta)");
	//return shaderToyRenderer->Initiate("Demos/Ocean Structure");
    //return shaderToyRenderer->Initiate("Demos/Rising Box");
	//return shaderToyRenderer->Initiate("Demos/[SH18]ForgottenLand");
	//return shaderToyRenderer->Initiate("Demos/Desert Bus");
	//return shaderToyRenderer->Initiate("Demos/Neon Lit Hexagons");
	//return shaderToyRenderer->Initiate("Demos/[SH18] Rabbit Character");
	//return shaderToyRenderer->Initiate("Demos/Shuto Highway 83");
	//return shaderToyRenderer->Initiate("Demos/glyphspinner");
	//return shaderToyRenderer->Initiate("Demos/Server Room");
	//return shaderToyRenderer->Initiate("Demos/Repelling");
	//return shaderToyRenderer->Initiate("Demos/sphere intersect pub");
	//return shaderToyRenderer->Initiate("Demos/The red hiker");
    //return shaderToyRenderer->Initiate("Demos/The Eye");
	//return shaderToyRenderer->Initiate("Demos/Desert Canyon");
	//return shaderToyRenderer->Initiate("Demos/Neon World");
	//return shaderToyRenderer->Initiate("Demos/Simple Greeble - Split4");
	//return shaderToyRenderer->Initiate("Demos/Alphaville");
	//return shaderToyRenderer->Initiate("Demos/Iceberg");
	//return shaderToyRenderer->Initiate("Demos/Moebius Ants");
	//return shaderToyRenderer->Initiate("Demos/The evolution of motion");
	//return shaderToyRenderer->Initiate("Demos/Flux Core");
	//return shaderToyRenderer->Initiate("Demos/Fruxis");


	//return shaderToyRenderer->Initiate("Demos/Cubemaps/Reprojection II");
	return shaderToyRenderer->Initiate("Demos/Cubemaps/Candlestick"); 
    //return shaderToyRenderer->Initiate("Demos/Cubemaps/Snowy Woods");
	//return shaderToyRenderer->Initiate("Demos/Cubemaps/Raytracing Textures and Cubemaps");
	//return shaderToyRenderer->Initiate("Demos/Cubemaps/Christmas Tree Star");
    //return shaderToyRenderer->Initiate("Demos/Webcam/Video on Tablet");
	//return shaderToyRenderer->Initiate("Demos/Webcam/ZX Spectrum attribute clash");
	//return shaderToyRenderer->Initiate("Demos/Webcam/Edge Detector");
	//return shaderToyRenderer->Initiate("Demos/Webcam/Webcam 'Giant in a lake'");
	//return shaderToyRenderer->Initiate("Demos/Webcam/Meta CRT - Single Pass");
    //return shaderToyRenderer->Initiate("Demos/Microphone/Fractal Audio 01");
    //return shaderToyRenderer->Initiate("Demos/Microphone/Tension Rings");
	//return shaderToyRenderer->Initiate("Demos/Microphone/Mellow Manypus jeanNshuti");
	//return shaderToyRenderer->Initiate("Demos/Microphone/Input - Microphone");
	//return shaderToyRenderer->Initiate("Demos/Microphone/Solines");
    //return shaderToyRenderer->Initiate("Demos/Video/VCR distortion");
    //return shaderToyRenderer->Initiate("Demos/Video/mpeg artifacts");
    //return shaderToyRenderer->Initiate("Demos/Wolfenstein 3D");
	//return shaderToyRenderer->Initiate("Demos/Rounded Voxels");
	//return shaderToyRenderer->Initiate("Demos/Unreal Intro");
	//return shaderToyRenderer->Initiate("Demos/Near miss!");


   



    //The following demos rendering results are different from the correct results, or cannot be run.
    ////return shaderToyRenderer->Initiate("Demos/Waterfall - Procedural GFX");
    /////return shaderToyRenderer->Initiate("Demos/Twizzly Circle Mess");
	/////return shaderToyRenderer->Initiate("Demos/simple refraction test");
	/////return shaderToyRenderer->Initiate("Demos/Desperate Distraction");
    ////return shaderToyRenderer->Initiate("Demos/Asymmetric Hexagon Landscape");
    ////return shaderToyRenderer->Initiate("Demos/Coronavirus-2020");
    ////return shaderToyRenderer->Initiate("Demos/Ball Room Dance");
	////return shaderToyRenderer->Initiate("Demos/Ethics Gradient");
	////return shaderToyRenderer->Initiate("Demos/Squishy balls");
    ////return shaderToyRenderer->Initiate("Demos/Androgynous bolts");
	////return shaderToyRenderer->Initiate("Demos/Webcam/Motion Detection");
    ////return shaderToyRenderer->Initiate("Demos/Webcam/Playing with a coke");
    



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