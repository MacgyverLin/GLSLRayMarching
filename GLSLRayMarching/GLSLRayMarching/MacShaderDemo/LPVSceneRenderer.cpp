#include "LPVSceneRenderer.h"
#include "LPVCommon.h"
#include "LPVObjLoader.h"
#include "LPVMtlLoader.h"

//////////////////////////////////////////////////////////////
LPVSceneRenderer::LPVSceneRenderer(GameObject& gameObject_)
	: Graphics3Component(gameObject_)
{
}

LPVSceneRenderer::~LPVSceneRenderer()
{
}

bool LPVSceneRenderer::OnInitiate()
{
	return Init();
}

bool LPVSceneRenderer::OnStart()
{
	return true;
}

bool LPVSceneRenderer::OnUpdate()
{
	return true;
}

bool LPVSceneRenderer::OnPause()
{
	return true;
}

void LPVSceneRenderer::OnResume()
{
}

void LPVSceneRenderer::OnStop()
{
}

void LPVSceneRenderer::OnTerminate()
{
}

void LPVSceneRenderer::OnRender()
{
	Render();
}

//////////////////////////////
/// Setup Functions

int target_fps = 60;
float environment_brightness = 1.5f;

bool rotate_light = true;

float indirect_light_attenuation = 1.0;
float ambient_light  =  0.0;
bool render_lpv_debug_view  =  false;
bool render_direct_light  =  true;
bool render_indirect_light  =  true;

ColorRGBA sceneSettings_ambientColor(0.15, 0.15, 0.15, 1.0);

bool LPVSceneRenderer::Init()
{
	if (sponza) {
		lpvGridSize = 32;
		propagationIterations = 64;
		offsetX = 0;
		offsetY = 1.5;
		offsetZ = 0;
	}
	else {
		lpvGridSize = 32;
		propagationIterations = 64;
		offsetX = 0;
		offsetY = -1;
		offsetZ = -4.5;
	}

	//if (!checkWebGL2Compability()) {
	//	return;
	//}

	//var canvas = document.getElementById('canvas');
	app = PicoGL::CreateApp
	(
		{
			{"antialias", PicoGL::Constant::TRUE}
		}
	);
	app->FloatRenderTargets();

	//stats = new Stats();
	//stats.showPanel(1); // (frame time)
	//document.body.appendChild(stats.dom);

	//gpuTimePanel = stats.addPanel(new Stats.Panel('MS (GPU)', '#ff8', '#221'));
	picoTimer = app->CreateTimer();

	//gui = new dat.GUI();
	//gui.add(settings, 'target_fps', 0, 120);
	//gui.add(settings, 'environment_brightness', 0.0, 2.0);
	//gui.add(settings, 'ambient_light').name('Ambient light');
	//gui.add(settings, 'rotate_light').name('Rotate light');
	//gui.add(settings, 'indirect_light_attenuation').name('Indirect light attenuation');
	//gui.add(settings, 'render_lpv_debug_view').name('Render LPV cells');
	//gui.add(settings, 'render_direct_light').name('Direct light');
	//gui.add(settings, 'render_indirect_light').name('Indirect light');

	//////////////////////////////////////
	// Basic GL state

	app->ClearColor(0, 0, 0, 0);
	app->CullBackfaces();
	app->NoBlend();

	Vector3 cameraPos;
	Quaternion cameraRot;
	if (sponza)
	{
		cameraPos = Vector3(-15 + offsetX, 3 + offsetY, 0 + offsetZ);
		cameraRot = quat_fromEuler(15, -90, 0);
	}
	else
	{
		cameraPos = Vector3(2.62158 + offsetX, 1.68613 + offsetY, 3.62357 + offsetZ);
		cameraRot = quat_fromEuler(90 - 101, 180 - 70.2, 180 + 180);
	}
	camera = new LPVCamera(cameraPos, cameraRot);

	if (sponza)
	{
		AddDirectionalLight(Vector3(-0.2, -1.0, 0.333), ColorRGBA(13.0, 13.0, 13.0, 1.0));
	}
	else
	{
		float dirLightAtt = 63;
		AddDirectionalLight(Vector3(-0.155185, -0.221726, 0.962681), ColorRGBA(dirLightAtt * 1.0, dirLightAtt * 0.803, dirLightAtt * 0.433, 1.0));
	}
	directionalLight = (LPVDirectionLight*)lightSources[0].source;
	//setupSpotLightsSponza(12);
	/*
		Vector3 spotPos(-5, 2.2, 8);
		Vector3 spotDir(0, 0, -1);
		AddSpotLight(spotPos, spotDir, 20, ColorRGBA(20, 0.6, 1.0, 1.0));
	*/

	shadowMapFramebuffer = SetupDirectionalLightShadowMapFramebuffer(shadowMapSize);
	for (int i = 0; i < lightSources.size(); i++)
	{
		rsmFramebuffers.push_back(SetupRSMFramebuffer(shadowMapSmallSize));
	}

	SetupSceneUniforms();

	lpv = new LPV(shadowMapSmallSize, lpvGridSize);

	shaderLoader = new LPVShaderLoader("LPVDemos/shaders/");
	shaderLoader->AddShaderFile("common.glsl");
	shaderLoader->AddShaderFile("scene_uniforms.glsl");
	shaderLoader->AddShaderFile("mesh_attributes.glsl");
	shaderLoader->AddShaderFile("lpv_common.glsl");
	shaderLoader->AddShaderProgram("unlit", "unlit.vert.glsl", "unlit.frag.glsl");
	shaderLoader->AddShaderProgram("default", "default.vert.glsl", "default.frag.glsl");
	shaderLoader->AddShaderProgram("environment", "environment.vert.glsl", "environment.frag.glsl");
	shaderLoader->AddShaderProgram("textureBlit", "screen_space.vert.glsl", "texture_blit.frag.glsl");
	shaderLoader->AddShaderProgram("shadowMapping", "shadow_mapping.vert.glsl", "shadow_mapping.frag.glsl");
	shaderLoader->AddShaderProgram("RSM", "lpv/reflective_shadow_map.vert.glsl", "lpv/reflective_shadow_map.frag.glsl");
	shaderLoader->AddShaderProgram("lightInjection", "lpv/light_injection.vert.glsl", "lpv/light_injection.frag.glsl");
	shaderLoader->AddShaderProgram("lightPropagation", "lpv/light_propagation.vert.glsl", "lpv/light_propagation.frag.glsl");
	shaderLoader->AddShaderProgram("geometryInjection", "lpv/geometry_injection.vert.glsl", "lpv/geometry_injection.frag.glsl");
	shaderLoader->AddShaderProgram("lpvDebug", "lpv/lpv_debug.vert.glsl", "lpv/lpv_debug.frag.glsl");
	shaderLoader->Load([&](std::map<std::string, LPVShaderLoader::ShaderResult>& data) {
		fullscreenVertexArray = CreateFullscreenVertexArray();

		textureBlitShader = MakeShader("textureBlit", data);
		blitTextureDrawCall = app->CreateDrawCall(textureBlitShader, fullscreenVertexArray);

		lightInjectShader = MakeShader("lightInjection", data);
		geometryInjectShader = MakeShader("geometryInjection", data);
		lightPropagationShader = MakeShader("lightPropagation", data);
		lpv->CreateInjectionDrawCall(lightInjectShader);
		lpv->CreateGeometryInjectDrawCall(geometryInjectShader);
		lpv->CreatePropagationDrawCall(lightPropagationShader);

		environmentShader = MakeShader("environment", data);
		environmentDrawCall = app->CreateDrawCall(environmentShader, fullscreenVertexArray)
			->Texture("u_environment_map", LoadTexture("environments/ocean.jpg", {}));

		lpvDebugShader = MakeShader("lpvDebug", data);
		probeVertexArray = CreateSphereVertexArray(0.08f, 8, 8);
		SetupProbeDrawCall(probeVertexArray, lpvDebugShader);

		defaultShader = MakeShader("default", data);
		rsmShader = MakeShader("RSM", data);
		simpleShadowMapShader = MakeShader("shadowMapping", data);
		//LoadObject("sponza/", "sponza.obj", "sponza.mtl");

		if (sponza) {
			Matrix4 m(Matrix4::Identity);
			Quaternion r = quat_fromEuler(0, 0, 0);
			Vector3 t(offsetX, offsetY, offsetZ);
			Vector3 s(1, 1, 1);
			m = mat4_fromRotationTranslationScale(r, t, s);
			LoadObject("sponza_with_teapot/", "sponza_with_teapot.obj", "sponza_with_teapot.mtl", m);
		}
		else {
			Matrix4 m(Matrix4::Identity);
			Quaternion r = quat_fromEuler(0, 0, 0);
			Vector3 t(offsetX, offsetY, offsetZ);
			Vector3 s(1, 1, 1);
			m = mat4_fromRotationTranslationScale(r, t, s);

			LoadObject("living_room/", "living_room.obj", "living_room.mtl", m);
		}
	});

	return true;
#if 0
	if (!checkWebGL2Compability()) {
		return;
	}

	var canvas = document.getElementById('canvas');
	app = PicoGL.createApp(canvas, { antialias: true });
	app.floatRenderTargets();

	stats = new Stats();
	stats.showPanel(1); // (frame time)
	document.body.appendChild(stats.dom);

	gpuTimePanel = stats.addPanel(new Stats.Panel('MS (GPU)', '#ff8', '#221'));
	picoTimer = app.createTimer();

	gui = new dat.GUI();
	gui.add(settings, 'target_fps', 0, 120);
	gui.add(settings, 'environment_brightness', 0.0, 2.0);
	gui.add(settings, 'ambient_light').name('Ambient light');
	gui.add(settings, 'rotate_light').name('Rotate light');
	gui.add(settings, 'indirect_light_attenuation').name('Indirect light attenuation');
	gui.add(settings, 'render_lpv_debug_view').name('Render LPV cells');
	gui.add(settings, 'render_direct_light').name('Direct light');
	gui.add(settings, 'render_indirect_light').name('Indirect light');

	//////////////////////////////////////
	// Basic GL state

	app.clearColor(0, 0, 0, 0);
	app.cullBackfaces();
	app.noBlend();

	//////////////////////////////////////
	// Camera stuff

	if (sponza) {
		var cameraPos = vec3.fromValues(-15 + offsetX, 3 + offsetY, 0 + offsetZ);
		var cameraRot = quat.fromEuler(quat.create(), 15, -90, 0);
	}
	else {
		var cameraPos = vec3.fromValues(2.62158 + offsetX, 1.68613 + offsetY, 3.62357 + offsetZ);
		var cameraRot = quat.fromEuler(quat.create(), 90 - 101, 180 - 70.2, 180 + 180);
	}
	camera = new Camera(cameraPos, cameraRot);

	//////////////////////////////////////
	// Scene setup

	if (sponza)
		addDirectionalLight(vec3.fromValues(-0.2, -1.0, 0.333), new Float32Array([13.0, 13.0, 13.0]));
	else {
		var dirLightAtt = 63;
		addDirectionalLight(vec3.fromValues(-0.155185, -0.221726, 0.962681), new Float32Array([dirLightAtt * 1.0, dirLightAtt * 0.803, dirLightAtt * 0.433]));
	}
	directionalLight = lightSources[0].source;
	//setupSpotLightsSponza(12);
	/*spotPos = vec3.fromValues(-5, 2.2, 8);
	spotDir = vec3.fromValues(0, 0, -1);
	addSpotLight(spotPos, spotDir, 20, vec3.fromValues(20, 0.6, 1.0));*/

	shadowMapFramebuffer = setupDirectionalLightShadowMapFramebuffer(shadowMapSize);
	for (var i = 0; i < lightSources.length; i++) {
		rsmFramebuffers.push(setupRSMFramebuffer(shadowMapSmallSize));
	}

	setupSceneUniforms();

	LPV = new LPV(shadowMapSmallSize, lpvGridSize);

	var shaderLoader = new ShaderLoader('src/shaders/');
	shaderLoader.addShaderFile('common.glsl');
	shaderLoader.addShaderFile('scene_uniforms.glsl');
	shaderLoader.addShaderFile('mesh_attributes.glsl');
	shaderLoader.addShaderFile('lpv_common.glsl');
	shaderLoader.addShaderProgram('unlit', 'unlit.vert.glsl', 'unlit.frag.glsl');
	shaderLoader.addShaderProgram('default', 'default.vert.glsl', 'default.frag.glsl');
	shaderLoader.addShaderProgram('environment', 'environment.vert.glsl', 'environment.frag.glsl');
	shaderLoader.addShaderProgram('textureBlit', 'screen_space.vert.glsl', 'texture_blit.frag.glsl');
	shaderLoader.addShaderProgram('shadowMapping', 'shadow_mapping.vert.glsl', 'shadow_mapping.frag.glsl');
	shaderLoader.addShaderProgram('RSM', 'lpv/reflective_shadow_map.vert.glsl', 'lpv/reflective_shadow_map.frag.glsl');
	shaderLoader.addShaderProgram('lightInjection', 'lpv/light_injection.vert.glsl', 'lpv/light_injection.frag.glsl');
	shaderLoader.addShaderProgram('lightPropagation', 'lpv/light_propagation.vert.glsl', 'lpv/light_propagation.frag.glsl');
	shaderLoader.addShaderProgram('geometryInjection', 'lpv/geometry_injection.vert.glsl', 'lpv/geometry_injection.frag.glsl');
	shaderLoader.addShaderProgram('lpvDebug', 'lpv/lpv_debug.vert.glsl', 'lpv/lpv_debug.frag.glsl');
	shaderLoader.load(function(data) {

		var fullscreenVertexArray = createFullscreenVertexArray();

		var textureBlitShader = makeShader('textureBlit', data);
		blitTextureDrawCall = app.createDrawCall(textureBlitShader, fullscreenVertexArray);

		var lightInjectShader = makeShader('lightInjection', data);
		var geometryInjectShader = makeShader('geometryInjection', data);
		var lightPropagationShader = makeShader('lightPropagation', data);
		LPV.createInjectionDrawCall(lightInjectShader);
		LPV.createGeometryInjectDrawCall(geometryInjectShader);
		LPV.createPropagationDrawCall(lightPropagationShader);

		var environmentShader = makeShader('environment', data);
		environmentDrawCall = app.createDrawCall(environmentShader, fullscreenVertexArray)
			.texture('u_environment_map', loadTexture('environments/ocean.jpg', {}));

		var lpvDebugShader = makeShader('lpvDebug', data);
		var probeVertexArray = createSphereVertexArray(0.08, 8, 8);
		setupProbeDrawCall(probeVertexArray, lpvDebugShader);

		defaultShader = makeShader('default', data);
		rsmShader = makeShader('RSM', data);
		simpleShadowMapShader = makeShader('shadowMapping', data);
		//loadObject('sponza/', 'sponza.obj', 'sponza.mtl');
		if (sponza) {
			let m = mat4.create();
			let r = quat.fromEuler(quat.create(), 0, 0, 0);
			let t = vec3.fromValues(offsetX, offsetY, offsetZ);
			let s = vec3.fromValues(1, 1, 1);
			mat4.fromRotationTranslationScale(m, r, t, s);
			loadObject('sponza_with_teapot/', 'sponza_with_teapot.obj', 'sponza_with_teapot.mtl', m);
		}
		else {
			let m = mat4.create();
			let r = quat.fromEuler(quat.create(), 0, 0, 0);
			let t = vec3.fromValues(offsetX, offsetY, offsetZ);
			let s = vec3.fromValues(1.0, 1.0, 1.0);
			mat4.fromRotationTranslationScale(m, r, t, s);
			loadObject('living_room/', 'living_room.obj', 'living_room.mtl', m);
		}

		//loadObject('sponza_crytek/', 'sponza.obj', 'sponza.mtl');
		/*
		{
			let m = mat4.create();
			let r = quat.fromEuler(quat.create(), 0, 0, 0);
			let t = vec3.fromValues(0, 0, 0);
			let s = vec3.fromValues(1, 1, 1);
			mat4.fromRotationTranslationScale(m, r, t, s);
			loadObject('test_room/', 'test_room.obj', 'test_room.mtl', m);
		}
*/
/*{
	let m = mat4.create();
	let r = quat.fromEuler(quat.create(), 0, 45, 0);
	let t = vec3.fromValues(-5, 1, 2.5);
	let s = vec3.fromValues(0.06, 0.06, 0.06);
	mat4.fromRotationTranslationScale(m, r, t, s);
	loadObject('teapot/', 'teapot.obj', 'default.mtl', m);
}*/

	});
#endif
}

void LPVSceneRenderer::AddDirectionalLight(const Vector3& direction_, const ColorRGBA& color_)
{
	lightSources.push_back(LightSource(new LPVDirectionLight(direction_, color_), "DIRECTIONAL_LIGHT"));
}

void LPVSceneRenderer::AddSpotLight(const Vector3& position_, const Vector3& direction_, float coneAngle_, const ColorRGBA& color_)
{
	lightSources.push_back(LightSource(new LPVSpotLight(position_, direction_, coneAngle_, color_), "SPOT_LIGHT"));
}

void LPVSceneRenderer::SetupSpotLightsSponza(int _nSpotlights)
{
	int nSpotLights = _nSpotlights;
	int spotLightsOnRow = 6;

	Vector3 spotPos(-23.0f, 6.0f, -8.0f);
	Vector3 spotDir(0.0f, -1.0f, 0.001f);
	for (int i = 0; i < nSpotLights; i++) {
		if (i == spotLightsOnRow)
			spotPos = Vector3(-23, 6, 8);
		if (i == 2 * spotLightsOnRow)
			spotPos = Vector3(-23, 20, 8);
		if (i == 3 * spotLightsOnRow)
			spotPos = Vector3(-23, 20, -8);
		float random0 = Math::UnitRandom() * 2;
		float random1 = Math::UnitRandom() * 2;
		float random2 = Math::UnitRandom() * 2;
		//console.log(random);
		Vector3 newSpotPos = Vector3::Zero;
		::Debug("%f %f %f\n", newSpotPos.X(), newSpotPos.Y(), newSpotPos.Z());
		newSpotPos = spotPos + Vector3(10 * (i % spotLightsOnRow) + random0, 0, random1);
		AddSpotLight(newSpotPos, spotDir, 20, ColorRGBA(20.0f * random0, 20.0f * random1, 20.0f * random2, 1.0f));
	}
#if 0
	function setupSpotLightsSponza(_nSpotlights) {
		var nSpotLights = _nSpotlights || 0;

		var spotLightsOnRow = 6;

		var spotPos = vec3.fromValues(-23, 6, -8);
		var spotDir = vec3.fromValues(0, -1, 0.001);
		for (var i = 0; i < nSpotLights; i++) {
			if (i == spotLightsOnRow)
				spotPos = vec3.fromValues(-23, 6, 8);
			if (i == 2 * spotLightsOnRow)
				spotPos = vec3.fromValues(-23, 20, 8);
			if (i == 3 * spotLightsOnRow)
				spotPos = vec3.fromValues(-23, 20, -8);
			let random0 = Math.random() * 2;
			let random1 = Math.random() * 2;
			let random2 = Math.random() * 2;
			//console.log(random);
			let newSpotPos = vec3.create();
			console.log(newSpotPos);
			vec3.add(newSpotPos, spotPos, vec3.fromValues(10 * (i % spotLightsOnRow) + random0, 0, random1));
			addSpotLight(newSpotPos, spotDir, 20, vec3.fromValues(20.0 * random0, 20.0 * random1, 20.0 * random2));
		}
	}
#endif
}

PicoGL::VertexArray* LPVSceneRenderer::CreateFullscreenVertexArray()
{
	std::vector<float> data =
	{
		-1, -1, 0,
		+3, -1, 0,
		-1, +3, 0
	};
	PicoGL::VertexBuffer* positions = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 3, &data[0], data.size() * sizeof(data[0]), PicoGL::Constant::STATIC_DRAW);

	PicoGL::VertexArray* vertexArray = app->CreateVertexArray()
		->VertexAttributeBuffer(0, positions);

	return vertexArray;
#if 0
	function createFullscreenVertexArray() {

		var positions = app.createVertexBuffer(PicoGL.FLOAT, 3, new Float32Array([
			-1, -1, 0,
				+3, -1, 0,
				-1, +3, 0
		]));

		var vertexArray = app.createVertexArray()
			.vertexAttributeBuffer(0, positions);

		return vertexArray;

	}

#endif
}

PicoGL::VertexArray* LPVSceneRenderer::CreateSphereVertexArray(float radius, int rings, int sectors)
{
	std::vector<float> positions;

	float R = 1.0f / (rings - 1);
	float S = 1.0f / (sectors - 1);

	float PI = Math::OnePi;
	float TWO_PI = 2.0 * PI;

	for (int r = 0; r < rings; ++r) {
		for (int s = 0; s < sectors; ++s) {

			float y = Math::Sin(-(PI / 2.0) + PI * r * R);
			float x = Math::Cos(TWO_PI * s * S) * Math::Sin(PI * r * R);
			float z = Math::Sin(TWO_PI * s * S) * Math::Sin(PI * r * R);

			positions.push_back(x * radius);
			positions.push_back(y * radius);
			positions.push_back(z * radius);
		}
	}

	std::vector<unsigned short> indices;
	for (int r = 0; r < rings - 1; ++r) {
		for (int s = 0; s < sectors - 1; ++s) {

			int i0 = r * sectors + s;
			int i1 = r * sectors + (s + 1);
			int i2 = (r + 1) * sectors + (s + 1);
			int i3 = (r + 1) * sectors + s;

			indices.push_back(i2);
			indices.push_back(i1);
			indices.push_back(i0);

			indices.push_back(i3);
			indices.push_back(i2);
			indices.push_back(i0);
		}

		PicoGL::VertexBuffer* positionBuffer = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 3, &positions[0], positions.size() * sizeof(positions[0]));
		PicoGL::VertexBuffer* indexBuffer = app->CreateIndexBuffer(PicoGL::Constant::UNSIGNED_SHORT, 3, &indices[0], indices.size() * sizeof(indices[0]));

		PicoGL::VertexArray* vertexArray = app->CreateVertexArray()
			->VertexAttributeBuffer(0, positionBuffer)
			->IndexBuffer(indexBuffer);

		return vertexArray;
	}
#if 0
	function createSphereVertexArray(radius, rings, sectors) {

		var positions = [];

		var R = 1.0 / (rings - 1);
		var S = 1.0 / (sectors - 1);

		var PI = Math.PI;
		var TWO_PI = 2.0 * PI;

		for (var r = 0; r < rings; ++r) {
			for (var s = 0; s < sectors; ++s) {

				var y = Math.sin(-(PI / 2.0) + PI * r * R);
				var x = Math.cos(TWO_PI * s * S) * Math.sin(PI * r * R);
				var z = Math.sin(TWO_PI * s * S) * Math.sin(PI * r * R);

				positions.push(x * radius);
				positions.push(y * radius);
				positions.push(z * radius);

			}
		}

		var indices = [];

		for (var r = 0; r < rings - 1; ++r) {
			for (var s = 0; s < sectors - 1; ++s) {

				var i0 = r * sectors + s;
				var i1 = r * sectors + (s + 1);
				var i2 = (r + 1) * sectors + (s + 1);
				var i3 = (r + 1) * sectors + s;

				indices.push(i2);
				indices.push(i1);
				indices.push(i0);

				indices.push(i3);
				indices.push(i2);
				indices.push(i0);

			}
		}

		var positionBuffer = app.createVertexBuffer(PicoGL.FLOAT, 3, new Float32Array(positions));
		var indexBuffer = app.createIndexBuffer(PicoGL.UNSIGNED_SHORT, 3, new Uint16Array(indices));

		var vertexArray = app.createVertexArray()
			.vertexAttributeBuffer(0, positionBuffer)
			.indexBuffer(indexBuffer);

		return vertexArray;

	}

#endif
	return nullptr;
}


PicoGL::Framebuffer* LPVSceneRenderer::SetupDirectionalLightShadowMapFramebuffer(int size)
{
	PicoGL::Texture* colorBuffer = app->CreateTexture2D
	(
		nullptr,
		size, size,
		{
			{ "format", PicoGL::Constant::RED },
			{ "internalFormat", PicoGL::Constant::R16F },
			{ "type", PicoGL::Constant::FLOAT },
			{ "minFilter", PicoGL::Constant::NEAREST },
			{ "magFilter", PicoGL::Constant::NEAREST }
		}
	);

	PicoGL::Texture* depthBuffer = app->CreateTexture2D
	(
		nullptr,
		size, size,
		{
			{ "format", PicoGL::Constant::DEPTH_COMPONENT },
			{ "internalFormat" , PicoGL::Constant::DEPTH_COMPONENT32F }
		}
	);

	PicoGL::Framebuffer* framebuffer = app->CreateFramebuffer()
		->ColorTarget(0, colorBuffer)
		->DepthTarget(depthBuffer);

	return framebuffer;
#if 0
	function setupDirectionalLightShadowMapFramebuffer(size) {

		var colorBuffer = app.createTexture2D(size, size, {
			format: PicoGL.RED,
			internalFormat : PicoGL.R16F,
			type : PicoGL.FLOAT,
			minFilter : PicoGL.NEAREST,
			magFilter : PicoGL.NEAREST
			});

		var depthBuffer = app.createTexture2D(size, size, {
			format: PicoGL.DEPTH_COMPONENT,
			internalFormat : PicoGL.DEPTH_COMPONENT32F
			});

		var framebuffer = app.createFramebuffer()
			.colorTarget(0, colorBuffer)
			.depthTarget(depthBuffer);

		return framebuffer;
	}
#endif
}

PicoGL::Framebuffer* LPVSceneRenderer::SetupRSMFramebuffer(int size)
{
	PicoGL::Texture* colorBuffer = app->CreateTexture2D
	(
		nullptr,
		size, size,
		{
			{ "type", PicoGL::Constant::FLOAT },
			{ "internalFormat", PicoGL::Constant::RGBA32F },
			{ "minFilter", PicoGL::Constant::NEAREST },
			{ "magFilter", PicoGL::Constant::NEAREST },
			{ "generateMipmaps", PicoGL::Constant::TRUE }
		}
	);
	PicoGL::Texture* positionBuffer = app->CreateTexture2D
	(
		nullptr,
		size, size,
		{
			{"type", PicoGL::Constant::FLOAT },
			{"internalFormat", PicoGL::Constant::RGBA32F},
			{"minFilter", PicoGL::Constant::NEAREST},
			{"magFilter", PicoGL::Constant::NEAREST},
			{"generateMipmaps", PicoGL::Constant::TRUE}
		}
	);
	PicoGL::Texture* normalBuffer = app->CreateTexture2D
	(
		nullptr,
		size, size,
		{
			{"type", PicoGL::Constant::FLOAT },
			{"internalFormat", PicoGL::Constant::RGBA32F},
			{"minFilter", PicoGL::Constant::NEAREST},
			{"magFilter", PicoGL::Constant::NEAREST},
			{"generateMipmaps", PicoGL::Constant::TRUE}
		}
	);
	PicoGL::Texture* depthBuffer = app->CreateTexture2D
	(
		nullptr,
		size, size,
		{
			{"type", PicoGL::Constant::FLOAT },
			{"internalFormat", PicoGL::Constant::RGBA32F},
			{"format", PicoGL::Constant::DEPTH_COMPONENT},

		}
	);

	PicoGL::Framebuffer* framebuffer = app->CreateFramebuffer()
		->ColorTarget(0, colorBuffer)
		->ColorTarget(1, positionBuffer)
		->ColorTarget(2, normalBuffer)
		->DepthTarget(depthBuffer);

	return framebuffer;
#if 0
	function
		setupRSMFramebuffer(size) {
		var colorBuffer = app.createTexture2D(size, size, {
			type: PicoGL.FLOAT,
			internalFormat : PicoGL.RBGA32F,
			minFilter : PicoGL.NEAREST,
			magFilter : PicoGL.NEAREST,
			generateMipmaps : true
			});
		var positionBuffer = app.createTexture2D(size, size, {
			type: PicoGL.FLOAT,
			internalFormat : PicoGL.RBGA32F,
			minFilter : PicoGL.NEAREST,
			magFilter : PicoGL.NEAREST,
			generateMipmaps : true
			});
		var normalBuffer = app.createTexture2D(size, size, {
			type: PicoGL.FLOAT,
			internalFormat : PicoGL.RBGA32F,
			minFilter : PicoGL.NEAREST,
			magFilter : PicoGL.NEAREST,
			generateMipmaps : true
			});
		var depthBuffer = app.createTexture2D(size, size, {
			type: PicoGL.FLOAT,
			internalFormat : PicoGL.RBGA32F,
			format : PicoGL.DEPTH_COMPONENT
			});
		var framebuffer = app.createFramebuffer()
			.colorTarget(0, colorBuffer)
			.colorTarget(1, positionBuffer)
			.colorTarget(2, normalBuffer)
			.depthTarget(depthBuffer);

		return framebuffer;
	}
#endif
}

void LPVSceneRenderer::SetupSceneUniforms()
{
	PicoGL::UniformBuffer* sceneUniforms = app->CreateUniformBuffer
	(
		{
			PicoGL::Constant::FLOAT_VEC4 /* 0 - ambient color */   //,
			//PicoGL.FLOAT_VEC4 /* 1 - directional light color */,
			//PicoGL.FLOAT_VEC4 /* 2 - directional light direction */,
			//PicoGL.FLOAT_MAT4 /* 3 - view from world matrix */,
			//PicoGL.FLOAT_MAT4 /* 4 - projection from view matrix */
		}
	)
	->Set(0, sceneSettings_ambientColor)
	//->Set(1, directionalLight.color)
	//->Set(2, directionalLight.direction)
	//->Set(3, camera.viewMatrix)
	//->Set(4, camera.projectionMatrix)
	->Update();

	/*
		camera.onViewMatrixChange = function(newValue) {
			sceneUniforms.set(3, newValue).update();
		};
	
		camera.onProjectionMatrixChange = function(newValue) {
			sceneUniforms.set(4, newValue).update();
		};
	*/
#if 0
	function setupSceneUniforms() {

		//
		// TODO: Fix all this! I got some weird results when I tried all this before but it should work...
		//

		sceneUniforms = app.createUniformBuffer([
			PicoGL.FLOAT_VEC4 /* 0 - ambient color */   //,
			//PicoGL.FLOAT_VEC4 /* 1 - directional light color */,
			//PicoGL.FLOAT_VEC4 /* 2 - directional light direction */,
			//PicoGL.FLOAT_MAT4 /* 3 - view from world matrix */,
			//PicoGL.FLOAT_MAT4 /* 4 - projection from view matrix */
		])
			.set(0, sceneSettings.ambientColor)
				//.set(1, directionalLight.color)
				//.set(2, directionalLight.direction)
				//.set(3, camera.viewMatrix)
				//.set(4, camera.projectionMatrix)
				.update();

			/*
				camera.onViewMatrixChange = function(newValue) {
					sceneUniforms.set(3, newValue).update();
				};

				camera.onProjectionMatrixChange = function(newValue) {
					sceneUniforms.set(4, newValue).update();
				};
			*/

	}
#endif
}

PicoGL::VertexArray* LPVSceneRenderer::CreateVertexArrayFromMeshInfo(const LPVObjLoader::ObjectInfo& meshInfo)
{
	PicoGL::VertexBuffer* positions = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 3, &meshInfo.positions[0], meshInfo.positions.size() * sizeof(meshInfo.positions[0]));
	PicoGL::VertexBuffer* normals   = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 3, &meshInfo.normals[0], meshInfo.normals.size() * sizeof(meshInfo.normals[0]));
	PicoGL::VertexBuffer* tangents  = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 4, &meshInfo.tangents[0], meshInfo.tangents.size() * sizeof(meshInfo.tangents[0]));
	PicoGL::VertexBuffer* texCoords = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 2, &meshInfo.uvs[0], meshInfo.uvs.size() * sizeof(meshInfo.uvs[0]));

	PicoGL::VertexArray* vertexArray = app->CreateVertexArray()
		->VertexAttributeBuffer(0, positions)
		->VertexAttributeBuffer(1, normals)
		->VertexAttributeBuffer(2, texCoords)
		->VertexAttributeBuffer(3, tangents);

	return vertexArray;
#if 0
	function createVertexArrayFromMeshInfo(meshInfo) {

		var positions = app.createVertexBuffer(PicoGL.FLOAT, 3, meshInfo.positions);
		var normals = app.createVertexBuffer(PicoGL.FLOAT, 3, meshInfo.normals);
		var tangents = app.createVertexBuffer(PicoGL.FLOAT, 4, meshInfo.tangents);
		var texCoords = app.createVertexBuffer(PicoGL.FLOAT, 2, meshInfo.uvs);

		var vertexArray = app.createVertexArray()
			.vertexAttributeBuffer(0, positions)
			.vertexAttributeBuffer(1, normals)
			.vertexAttributeBuffer(2, texCoords)
			.vertexAttributeBuffer(3, tangents);

		return vertexArray;

	}
#endif
	return nullptr;
}

void LPVSceneRenderer::SetupProbeDrawCall(PicoGL::VertexArray* vertexArray, PicoGL::Program* shader)
{
	//
		// Place probes
		//

	std::vector<float> probeLocations;
	std::vector<float> probeIndices;

	int gridSize = lpvGridSize;
	float cellSize;

	if (sponza) {
		cellSize = 2.25;
	}
	else {
		cellSize = 0.325;
	}

	Vector3 origin(0, 0, 0);
	Vector3 step(cellSize, cellSize, cellSize);

	Vector3 halfGridSize(gridSize / 2, gridSize / 2, gridSize / 2);
	Vector3 halfSize = step * halfGridSize;

	Vector3 bottomLeft = origin - halfSize;

	Vector3 diff = Vector3::Zero;

	for (int z = 0; z < gridSize; ++z) {
		for (int y = 0; y < gridSize; ++y) {
			for (int x = 0; x < gridSize; ++x) {

				diff = step * Vector3(x, y, z);

				Vector3 pos(0, 0, 0);
				pos = bottomLeft + diff;
				pos = pos + Vector3(0.5, 0.5, 0.5);

				probeLocations.push_back(pos[0]);
				probeLocations.push_back(pos[1]);
				probeLocations.push_back(pos[2]);

				probeIndices.push_back(x);
				probeIndices.push_back(y);
				probeIndices.push_back(z);
			}
		}
	}

	//
	// Pack into instance buffer
	//

	// We need at least one (x,y,z) pair to render any probes
	if (probeLocations.size() <= 3) {
		return;
	}

	if (probeLocations.size() % 3 != 0) {
		::Error("Probe locations invalid!Number of coordinates is not divisible by 3.");
		return;
	}

	// Set up for instanced drawing at the probe locations
	PicoGL::VertexBuffer* translations = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 3, &probeLocations[0], probeLocations.size() * sizeof(probeLocations[0]));
	PicoGL::VertexBuffer* indices = app->CreateVertexBuffer(PicoGL::Constant::FLOAT, 3, &probeIndices[0], probeIndices.size() * sizeof(probeIndices[0]));
	vertexArray->InstanceAttributeBuffer(10, translations);
	vertexArray->InstanceAttributeBuffer(11, indices);

	probeDrawCall = app->CreateDrawCall(shader, vertexArray);
#if 0
	function setupProbeDrawCall(vertexArray, shader) {

		//
		// Place probes
		//

		var probeLocations = [];
		var probeIndices = [];

		var gridSize = lpvGridSize;
		var cellSize;

		if (sponza) {
			cellSize = 2.25;
		}
		else {
			cellSize = 0.325;
		}

		var origin = vec3.fromValues(0, 0, 0);
		var step = vec3.fromValues(cellSize, cellSize, cellSize);

		var halfGridSize = vec3.fromValues(gridSize / 2, gridSize / 2, gridSize / 2);
		var halfSize = vec3.mul(vec3.create(), step, halfGridSize);

		var bottomLeft = vec3.sub(vec3.create(), origin, halfSize);

		var diff = vec3.create();

		for (var z = 0; z < gridSize; ++z) {
			for (var y = 0; y < gridSize; ++y) {
				for (var x = 0; x < gridSize; ++x) {

					vec3.mul(diff, step, vec3.fromValues(x, y, z));

					var pos = vec3.create();
					vec3.add(pos, bottomLeft, diff);
					vec3.add(pos, pos, vec3.fromValues(0.5, 0.5, 0.5));

					probeLocations.push(pos[0]);
					probeLocations.push(pos[1]);
					probeLocations.push(pos[2]);

					probeIndices.push(x);
					probeIndices.push(y);
					probeIndices.push(z);

				}
			}
		}

		//
		// Pack into instance buffer
		//

		// We need at least one (x,y,z) pair to render any probes
		if (probeLocations.length <= 3) {
			return;
		}

		if (probeLocations.length % 3 != = 0) {
			console.error('Probe locations invalid! Number of coordinates is not divisible by 3.');
			return;
		}

		// Set up for instanced drawing at the probe locations
		var translations = app.createVertexBuffer(PicoGL.FLOAT, 3, new Float32Array(probeLocations));
		var indices = app.createVertexBuffer(PicoGL.FLOAT, 3, new Float32Array(probeIndices));
		vertexArray.instanceAttributeBuffer(10, translations);
		vertexArray.instanceAttributeBuffer(11, indices);

		probeDrawCall = app.createDrawCall(shader, vertexArray);

}
#endif
}

//////////////////////////////
/// Rendering functions
void LPVSceneRenderer::Render()
{
	if (rotate_light) {
		// Rotate light

		vec3_rotateY(directionalLight->Direction(), directionalLight->Direction(), Vector3(0.0, 0.0, 0.0), 0.01);
	}

	camera->Update();

	RenderShadowMap();
	// Only refresh LPV when shadow map has been updated
	if (initLPV && render_indirect_light) {
		if (lpv->accumulatedBuffer && lpv->injectionFramebuffer) {
			lpv->ClearInjectionBuffer();
			lpv->ClearAccumulatedBuffer();
		}

		for (int i = 0; i < rsmFramebuffers.size(); i++) {
			lpv->LightInjection(rsmFramebuffers[i]);
		}

		lpv->GeometryInjection(rsmFramebuffers[0], (LPVDirectionLight*)directionalLight);
		lpv->LightPropagation(propagationIterations);
		initLPV = false;
	}

	if (lpv->accumulatedBuffer)
		RenderScene(lpv->accumulatedBuffer);

	Matrix4 viewProjection = camera->ProjectionMatrix() * camera->ViewMatrix();

	if (render_lpv_debug_view) {
		RenderLpvCells(viewProjection);
	}

	Matrix4 inverseViewProjection = viewProjection.Inverse();
	RenderEnvironment(inverseViewProjection);

	// Call this to get a debug render of the passed in texture
	//renderTextureToScreen(LPV.injectionFramebuffer.colorTextures[0]);
	//renderTextureToScreen(LPV.geometryInjectionFramebuffer.colorTextures[0]);
	//renderTextureToScreen(LPV.propagationFramebuffer.colorTextures[0]);
	//renderTextureToScreen(rsmFramebuffers[0].colorTextures[0]);
#if 0
	function render() {
		{
			if (settings["rotate_light"]) {
				// Rotate light
				vec3.rotateY(directionalLight.direction, directionalLight.direction, vec3.fromValues(0.0, 0.0, 0.0), 0.01);
			}

			camera.update();

			renderShadowMap();
			// Only refresh LPV when shadow map has been updated
			if (initLPV && settings.render_indirect_light) {
				if (LPV.accumulatedBuffer && LPV.injectionFramebuffer) {
					LPV.clearInjectionBuffer();
					LPV.clearAccumulatedBuffer();
				}

				for (var i = 0; i < rsmFramebuffers.length; i++) {
					LPV.lightInjection(rsmFramebuffers[i]);
				}

				LPV.geometryInjection(rsmFramebuffers[0], directionalLight);
				LPV.lightPropagation(propagationIterations);
				initLPV = false;
			}

			if (LPV.accumulatedBuffer)
				renderScene(LPV.accumulatedBuffer);

			var viewProjection = mat4.mul(mat4.create(), camera.projectionMatrix, camera.viewMatrix);

			if (settings.render_lpv_debug_view) {
				renderLpvCells(viewProjection);
			}

			var inverseViewProjection = mat4.invert(mat4.create(), viewProjection);
			renderEnvironment(inverseViewProjection);

			// Call this to get a debug render of the passed in texture
			//renderTextureToScreen(LPV.injectionFramebuffer.colorTextures[0]);
			//renderTextureToScreen(LPV.geometryInjectionFramebuffer.colorTextures[0]);
			//renderTextureToScreen(LPV.propagationFramebuffer.colorTextures[0]);
			//renderTextureToScreen(rsmFramebuffers[0].colorTextures[0]);

		}
	}
#endif
}

bool LPVSceneRenderer::ShadowMapNeedsRendering()
{
	static Vector3 lastDirection(0, 0, 0);
	static int lastMeshCount = 0;
	static int lastTexturesLoaded = 0;

	if (vec3_equals(lastDirection, directionalLight->Direction()) && lastMeshCount == meshes.size()
		&& lastTexturesLoaded == texturesLoaded) {

		return false;

	}
	else {

		lastDirection = directionalLight->Direction();
		lastMeshCount = meshes.size();
		lastTexturesLoaded = texturesLoaded;

		return true;
	}
#if 0
	function shadowMapNeedsRendering() {

		var lastDirection = shadowMapNeedsRendering.lastDirection || vec3.create();
		var lastMeshCount = shadowMapNeedsRendering.lastMeshCount || 0;
		var lastTexturesLoaded = shadowMapNeedsRendering.lastTexturesLoaded || 0;

		if (vec3.equals(lastDirection, directionalLight.direction) && lastMeshCount == = meshes.length
			&& lastTexturesLoaded == texturesLoaded) {

			return false;

		}
		else {

			shadowMapNeedsRendering.lastDirection = vec3.copy(lastDirection, directionalLight.direction);
			shadowMapNeedsRendering.lastMeshCount = meshes.length;
			shadowMapNeedsRendering.lastTexturesLoaded = texturesLoaded;

			return true;

		}
	}
#endif
	return true;
}

void LPVSceneRenderer::RenderShadowMap()
{
	//TODO: only render when needed to
	if (!ShadowMapNeedsRendering()) return;

	for (int i = 0; i < lightSources.size(); i++)
	{
		LightSource light = lightSources[i];

		Matrix4 lightViewProjection = light.source->LightViewProjectionMatrix();
		Vector3 lightDirection;
		if (light.type == "DIRECTIONAL_LIGHT") {
			LPVDirectionLight* dLight = (LPVDirectionLight*)light.source;
			lightDirection = dLight->ViewSpaceDirection(camera);
		}
		else if (light.type == "SPOT_LIGHT") {
			LPVSpotLight* sLight = (LPVSpotLight*)light.source;
			lightDirection = sLight->ViewSpaceDirection(camera);
		}

		Vector3 lightPosition(0, 0, 0);
		float lightCone = 0;
		if (light.type == "DIRECTIONAL_LIGHT") {
			LPVDirectionLight* dLight = (LPVDirectionLight*)light.source;
			lightPosition = Vector3(0, 0, 0);
			lightCone = 0;
		}
		else if (light.type == "SPOT_LIGHT") {
			LPVSpotLight* sLight = (LPVSpotLight*)light.source;
			lightPosition = sLight->Position();
			lightCone = sLight->ConeAngle();
		}

		ColorRGBA lightColor = light.source->Color();

		app->DrawFramebuffer(rsmFramebuffers[i])
			->Viewport(0, 0, shadowMapSmallSize, shadowMapSmallSize)
			->DepthTest()
			->DepthFunc(PicoGL::Constant::LEQUAL)
			->NoBlend()
			->Clear();

		for (int j = 0, len = meshes.size(); j < len; j++) {

			Mesh mesh = meshes[j];

			mesh.rsmDrawCall
				->Uniform("u_is_directional_light", light.type == "DIRECTIONAL_LIGHT")
				->Uniform("u_world_from_local", mesh.modelMatrix)
				->Uniform("u_light_projection_from_world", lightViewProjection)
				->Uniform("u_light_direction", lightDirection)
				->Uniform("u_spot_light_cone", lightCone)
				->Uniform("u_light_color", lightColor)
				->Uniform("u_spot_light_position", lightPosition)
				->Draw();
		}
	}

	Matrix4 lightViewProjection = directionalLight->LightViewProjectionMatrix();

	app->DrawFramebuffer(shadowMapFramebuffer)
		->Viewport(0, 0, shadowMapSize, shadowMapSize)
		->DepthTest()
		->DepthFunc(PicoGL::Constant::LEQUAL)
		->NoBlend()
		->Clear();

	for (int i = 0, len = meshes.size(); i < len; ++i) {

		Mesh mesh = meshes[i];

		mesh.shadowMapDrawCall
			->Uniform("u_world_from_local", mesh.modelMatrix)
			->Uniform("u_light_projection_from_world", lightViewProjection)
			->Draw();

	}
	initLPV = true;
#if 0

	function renderShadowMap() {
		//TODO: only render when needed to
		if (!shadowMapNeedsRendering()) return;

		for (var i = 0; i < lightSources.length; i++)
		{
			var light = lightSources[i];

			var lightViewProjection = light.source.getLightViewProjectionMatrix();
			var lightDirection;
			if (light.type == = 'DIRECTIONAL_LIGHT') {
				lightDirection = light.source.viewSpaceDirection(camera);
			}
			else if (light.type == = 'SPOT_LIGHT') {
				lightDirection = light.source.direction;
			}

			var lightColor = light.source.color;

			app.drawFramebuffer(rsmFramebuffers[i])
				.viewport(0, 0, shadowMapSmallSize, shadowMapSmallSize)
				.depthTest()
				.depthFunc(PicoGL.LEQUAL)
				.noBlend()
				.clear();

			for (var j = 0, len = meshes.length; j < len; j++) {

				var mesh = meshes[j];

				mesh.rsmDrawCall
					.uniform('u_is_directional_light', light.type == = 'DIRECTIONAL_LIGHT')
					.uniform('u_world_from_local', mesh.modelMatrix)
					.uniform('u_light_projection_from_world', lightViewProjection)
					.uniform('u_light_direction', lightDirection)
					.uniform('u_spot_light_cone', light.source.cone)
					.uniform('u_light_color', lightColor)
					.uniform('u_spot_light_position', light.source.position || vec3.fromValues(0, 0, 0))
					.draw();
			}
		}

		var lightViewProjection = directionalLight.getLightViewProjectionMatrix();

		app.drawFramebuffer(shadowMapFramebuffer)
			.viewport(0, 0, shadowMapSize, shadowMapSize)
			.depthTest()
			.depthFunc(PicoGL.LEQUAL)
			.noBlend()
			.clear();

		for (var i = 0, len = meshes.length; i < len; ++i) {

			var mesh = meshes[i];

			mesh.shadowMapDrawCall
				.uniform('u_world_from_local', mesh.modelMatrix)
				.uniform('u_light_projection_from_world', lightViewProjection)
				.draw();

		}
		initLPV = true;
	}
#endif
}

void LPVSceneRenderer::RenderScene(PicoGL::Framebuffer* framebuffer)
{
	Vector3 dirLightViewDirection = directionalLight->ViewSpaceDirection(camera);
	Matrix4 lightViewProjection = directionalLight->LightViewProjectionMatrix();
	PicoGL::Texture* shadowMap = shadowMapFramebuffer->DepthTexture();

	app->DefaultDrawFramebuffer()
		->DefaultViewport()
		->DepthTest()
		->DepthFunc(PicoGL::Constant::LEQUAL)
		->NoBlend()
		->Clear();

	for (int i = 0, len = meshes.size(); i < len; ++i) {
		Mesh mesh = meshes[i];

		for (int j = 1; j < lightSources.size(); j++) {
			Assert(lightSources[j].source->LightType() == LPVLight::Type::SPOT);
			LPVSpotLight* sLight = (LPVSpotLight*)lightSources[j].source;

			Vector3 spotLightViewPosition = sLight->ViewSpacePosition(camera);
			Vector3 spotLightViewDirection = sLight->ViewSpaceDirection(camera);
			float spotLightConeAngle = sLight->ConeAngle();
			ColorRGBA spotLightColor = sLight->Color();
	
			LPVSpotLight spotLight(spotLightViewPosition, spotLightViewDirection, spotLightConeAngle, spotLightColor);

			std::ostringstream stringStream;
			stringStream << "u_spot_light[" << (j - 1) << "].";
			stringStream.str();
			mesh.drawCall 
				->Uniform((stringStream.str() + "color").c_str(), spotLight.Color())
				->Uniform((stringStream.str() + "cone").c_str(), spotLight.ConeAngle())
				->Uniform((stringStream.str() + "view_position").c_str(), spotLightViewDirection)
				->Uniform((stringStream.str() + "view_direction").c_str(), spotLightViewPosition);
		}

		mesh.drawCall
			->Uniform("u_ambient_light_attenuation", ambient_light)
			->Uniform("u_world_from_local", mesh.modelMatrix)
			->Uniform("u_view_from_world", camera->ViewMatrix())
			->Uniform("u_projection_from_view", camera->ProjectionMatrix())
			->Uniform("u_dir_light_color", (Vector4)directionalLight->Color())
			->Uniform("u_dir_light_view_direction", dirLightViewDirection)
			->Uniform("u_light_projection_from_world", lightViewProjection)
			->Uniform("u_lpv_grid_size", lpv->framebufferSize)
			->Uniform("u_render_direct_light", render_direct_light)
			->Uniform("u_render_indirect_light", render_indirect_light)
			->Uniform("u_indirect_light_attenuation", indirect_light_attenuation)
			->Texture("u_shadow_map", shadowMap)
			->Texture("u_red_indirect_light", framebuffer->GetColorTextures()[0])
			->Texture("u_green_indirect_light", framebuffer->GetColorTextures()[1])
			->Texture("u_blue_indirect_light", framebuffer->GetColorTextures()[2])
			->Draw();


	}

#if 0
	function renderScene(framebuffer) {

		var dirLightViewDirection = directionalLight.viewSpaceDirection(camera);
		var lightViewProjection = directionalLight.getLightViewProjectionMatrix();
		var shadowMap = shadowMapFramebuffer.depthTexture;

		app.defaultDrawFramebuffer()
			.defaultViewport()
			.depthTest()
			.depthFunc(PicoGL.LEQUAL)
			.noBlend()
			.clear();

		for (var i = 0, len = meshes.length; i < len; ++i) {
			var mesh = meshes[i];

			for (var j = 1; j < lightSources.length; j++) {
				var spotLightViewPosition = lightSources[j].source.viewSpacePosition(camera);
				var spotLightViewDirection = lightSources[j].source.viewSpaceDirection(camera);
				var spotLight = { color: lightSources[j].source.color, cone : lightSources[j].source.cone, view_position : spotLightViewPosition, view_direction : spotLightViewDirection };

				mesh.drawCall
					.uniform('u_spot_light[' + (j - 1) + '].color', spotLight.color)
					.uniform('u_spot_light[' + (j - 1) + '].cone', spotLight.cone)
					.uniform('u_spot_light[' + (j - 1) + '].view_position', spotLight.view_position)
					.uniform('u_spot_light[' + (j - 1) + '].view_direction', spotLight.view_direction);
			}

			mesh.drawCall
				.uniform('u_ambient_light_attenuation', settings.ambient_light)
				.uniform('u_world_from_local', mesh.modelMatrix)
				.uniform('u_view_from_world', camera.viewMatrix)
				.uniform('u_projection_from_view', camera.projectionMatrix)
				.uniform('u_dir_light_color', directionalLight.color)
				.uniform('u_dir_light_view_direction', dirLightViewDirection)
				.uniform('u_light_projection_from_world', lightViewProjection)
				.uniform('u_lpv_grid_size', LPV.framebufferSize)
				.uniform('u_render_direct_light', settings.render_direct_light)
				.uniform('u_render_indirect_light', settings.render_indirect_light)
				.uniform('u_indirect_light_attenuation', settings.indirect_light_attenuation)
				.texture('u_shadow_map', shadowMap)
				.texture('u_red_indirect_light', framebuffer.colorTextures[0])
				.texture('u_green_indirect_light', framebuffer.colorTextures[1])
				.texture('u_blue_indirect_light', framebuffer.colorTextures[2])
				.draw();


		}

	}
#endif
}

void LPVSceneRenderer::RenderLpvCells(const Matrix4& viewProjection)
{
	if (probeDrawCall) {

		app->DefaultDrawFramebuffer()
			->DefaultViewport()
			->DepthTest()
			->DepthFunc(PicoGL::Constant::LEQUAL)
			->NoBlend();

		// Replace with the propagated for a view of it
		PicoGL::Framebuffer* lpvbuffers = lpv->accumulatedBuffer;

		probeDrawCall
			->Texture("u_lpv_red", lpvbuffers->GetColorTextures()[0])
			->Texture("u_lpv_green", lpvbuffers->GetColorTextures()[1])
			->Texture("u_lpv_blue", lpvbuffers->GetColorTextures()[2])
			->Uniform("u_lpv_size", lpvGridSize)
			->Uniform("u_projection_from_world", viewProjection)
			->Draw();
	}
#if 0
	function renderLpvCells(viewProjection) {

		if (probeDrawCall) {

			app.defaultDrawFramebuffer()
				.defaultViewport()
				.depthTest()
				.depthFunc(PicoGL.LEQUAL)
				.noBlend();

			// Replace with the propagated for a view of it
			var lpvbuffers = LPV.accumulatedBuffer;

			probeDrawCall
				.texture('u_lpv_red', lpvbuffers.colorTextures[0])
				.texture('u_lpv_green', lpvbuffers.colorTextures[1])
				.texture('u_lpv_blue', lpvbuffers.colorTextures[2])
				.uniform('u_lpv_size', lpvGridSize)
				.uniform('u_projection_from_world', viewProjection)
				.draw();

		}

	}
#endif
}

void LPVSceneRenderer::RenderEnvironment(const Matrix4& inverseViewProjection)
{
	if (environmentDrawCall) {

		app->DefaultDrawFramebuffer()
			->DefaultViewport()
			->DepthTest()
			->DepthFunc(PicoGL::Constant::EQUAL)
			->NoBlend();

		environmentDrawCall
			->Uniform("u_camera_position", camera->Position())
			->Uniform("u_world_from_projection", inverseViewProjection)
			->Uniform("u_environment_brightness", environment_brightness)
			->Draw();

}
#if 0
	function renderEnvironment(inverseViewProjection) {

		if (environmentDrawCall) {

			app.defaultDrawFramebuffer()
				.defaultViewport()
				.depthTest()
				.depthFunc(PicoGL.EQUAL)
				.noBlend();

			environmentDrawCall
				.uniform('u_camera_position', camera.position)
				.uniform('u_world_from_projection', inverseViewProjection)
				.uniform('u_environment_brightness', settings.environment_brightness)
				.draw();

		}

	}
#endif
}

void LPVSceneRenderer::RenderTextureToScreen(PicoGL::Texture* texture)
{

	//
	// NOTE:
	//
	//   This function can be really helpful for debugging!
	//   Just call this whenever and you get the texture on
	//   the screen (just make sure nothing is drawn on top)
	//

	if (!blitTextureDrawCall) {
		return;
	}

	app->DefaultDrawFramebuffer()
		->DefaultViewport()
		->NoDepthTest()
		->NoBlend();

	blitTextureDrawCall
		->Texture("u_texture", texture)
		->Draw();
#if 0
	function renderTextureToScreen(texture) {

		//
		// NOTE:
		//
		//   This function can be really helpful for debugging!
		//   Just call this whenever and you get the texture on
		//   the screen (just make sure nothing is drawn on top)
		//

		if (!blitTextureDrawCall) {
			return;
		}

		app.defaultDrawFramebuffer()
			.defaultViewport()
			.noDepthTest()
			.noBlend();

		blitTextureDrawCall
			.texture('u_texture', texture)
			.draw();

	}
#endif
}

//////////////////////////////
/// Utilities functions
void LPVSceneRenderer::LoadObject(const std::string& directory, const std::string& objFilename, const std::string& mtlFilename, const Matrix4& modelMatrix)
{
	LPVObjLoader objLoader;
	LPVMtlLoader mtlLoader;

	std::string path = std::string("LPVDemos/assets/") + directory;

	objLoader.Load(path + objFilename, [&](std::vector<LPVObjLoader::ObjectInfo>& objects) {
		mtlLoader.Load(path + mtlFilename, [&](std::map<std::string, LPVMtlLoader::MaterialInfo>& materials) {
			for (auto& object : objects)
			{
				LPVMtlLoader::MaterialInfo& material = materials[object.material];
				PicoGL::Texture* diffuseTexture;
				if (material.hasMapKd) {
					diffuseTexture = LoadTexture((directory + material.map_Kd).c_str());
				}
				else {
					diffuseTexture = MakeSingleColorTexture(material.Kd);
				}
				std::string specularMap = (material.hasMapKs) ? directory + material.map_Ks : "default_specular.jpg";
				std::string normalMap = (material.hasMapNorm) ? directory + material.map_norm : "default_normal.jpg";

				PicoGL::VertexArray* vertexArray = CreateVertexArrayFromMeshInfo(object);

				PicoGL::DrawCall* drawCall = app->CreateDrawCall(defaultShader, vertexArray)
					->UniformBlock("SceneUniforms", sceneUniforms)
					->Texture("u_diffuse_map", diffuseTexture)
					->Texture("u_specular_map", LoadTexture(specularMap.c_str()))
					->Texture("u_normal_map", LoadTexture(normalMap.c_str()));

				PicoGL::DrawCall* shadowMappingDrawCall = app->CreateDrawCall(simpleShadowMapShader, vertexArray);

				PicoGL::DrawCall* rsmDrawCall = app->CreateDrawCall(rsmShader, vertexArray)
					->Texture("u_diffuse_map", diffuseTexture);

				meshes.push_back
				(
					Mesh
					(
						modelMatrix,
						drawCall,
						shadowMappingDrawCall,
						rsmDrawCall
					)
				);
			}
		});

		RenderShadowMap();
	});
#if 0
	function loadObject(directory, objFilename, mtlFilename, modelMatrix) {

		var objLoader = new OBJLoader();
		var mtlLoader = new MTLLoader();

		var path = 'assets/' + directory;

		objLoader.load(path + objFilename, function(objects) {
			mtlLoader.load(path + mtlFilename, function(materials) {
				objects.forEach(function(object) {

					var material = materials[object.material];
					var diffuseTexture;
					if (material.properties.map_Kd) {
						diffuseTexture = loadTexture(directory + material.properties.map_Kd);
					}
					else {
						diffuseTexture = makeSingleColorTexture(material.properties.Kd);
					}
					var specularMap = (material.properties.map_Ks) ? directory + material.properties.map_Ks : 'default_specular.jpg';
					var normalMap = (material.properties.map_norm) ? directory + material.properties.map_norm : 'default_normal.jpg';

					var vertexArray = createVertexArrayFromMeshInfo(object);

					var drawCall = app.createDrawCall(defaultShader, vertexArray)
						.uniformBlock('SceneUniforms', sceneUniforms)
						.texture('u_diffuse_map', diffuseTexture)
						.texture('u_specular_map', loadTexture(specularMap))
						.texture('u_normal_map', loadTexture(normalMap));

					var shadowMappingDrawCall = app.createDrawCall(simpleShadowMapShader, vertexArray);

					var rsmDrawCall = app.createDrawCall(rsmShader, vertexArray)
						.texture('u_diffuse_map', diffuseTexture);

					meshes.push({
						modelMatrix: modelMatrix || mat4.create(),
						drawCall : drawCall,
						shadowMapDrawCall : shadowMappingDrawCall,
						rsmDrawCall : rsmDrawCall
						});

				});
			});
		});
		renderShadowMap();
	}
#endif
}

PicoGL::Program* LPVSceneRenderer::MakeShader(const std::string& name, std::map<std::string, LPVShaderLoader::ShaderResult>& shaderLoaderData)
{
	LPVShaderLoader::ShaderResult programData = shaderLoaderData[name];
	PicoGL::Program* program = app->CreateProgram
	(
		(const char* const*)programData.vertexSource.c_str(), programData.vertexSource.size(),
		(const char* const*)programData.fragmentSource.c_str(), programData.fragmentSource.size()
	);
	return program;
#if 0
	function makeShader(name, shaderLoaderData) {

		var programData = shaderLoaderData[name];
		var program = app.createProgram(programData.vertexSource, programData.fragmentSource);
		return program;

	}
#endif
	return nullptr;
}

bool LPVSceneRenderer::IsDataTexture(const std::string& imageName)
{
	return string_indexOf(imageName, "_ddn") != -1
		|| string_indexOf(imageName, "_spec") != -1
		|| string_indexOf(imageName, "_normal") != -1;
#if 0
	function isDataTexture(imageName) {
		return imageName.indexOf('_ddn') != -1
			|| imageName.indexOf('_spec') != -1
			|| imageName.indexOf('_normal') != -1;
	}
#endif
}

PicoGL::Texture* LPVSceneRenderer::LoadTexture(const char* imageName, const PicoGL::Options& options)
{
	PicoGL::Options textureOptions;
	if (textureOptions.size()==0)
	{
		textureOptions["minFilter"] = PicoGL::Constant::LINEAR_MIPMAP_NEAREST;
		textureOptions["magFilter"] = PicoGL::Constant::LINEAR;
		textureOptions["mipmaps"] = PicoGL::Constant::TRUE;

		if (IsDataTexture(imageName)) 
		{
			textureOptions["internalFormat"] = PicoGL::Constant::RGB8;
			textureOptions["format"] = PicoGL::Constant::RGB;
		}
		else 
		{
			textureOptions["internalFormat"] = PicoGL::Constant::SRGB8_ALPHA8;
			textureOptions["format"] = PicoGL::Constant::RGBA;
		}
	}
	PicoGL::Texture* texture = app->CreateTexture2D(nullptr, 1, 1, textureOptions);

	std::vector<unsigned char> data =
	{
		200, 200, 200, 255
	};
	texture->Data(&data[0], data.size());

	std::string path = std::string("LPVDemos/assets/") + imageName;
	// image.onload = function() {
	// 	texture.resize(image.width, image.height);
	// 	texture.data(image);
	// 	texturesLoaded++;
	// };

	return texture;

#if 0
	function loadTexture(imageName, options) {

		if (!options) {

			var options = {};
			options['minFilter'] = PicoGL.LINEAR_MIPMAP_NEAREST;
			options['magFilter'] = PicoGL.LINEAR;
			options['mipmaps'] = true;

			if (isDataTexture(imageName)) {
				options['internalFormat'] = PicoGL.RGB8;
				options['format'] = PicoGL.RGB;
			}
			else {
				options['internalFormat'] = PicoGL.SRGB8_ALPHA8;
				options['format'] = PicoGL.RGBA;
			}
		}

		var texture = app.createTexture2D(1, 1, options);
		texture.data(new Uint8Array([200, 200, 200, 256]));

		var image = document.createElement('img');
		image.onload = function() {

			texture.resize(image.width, image.height);
			texture.data(image);
			texturesLoaded++;
	};
		image.src = 'assets/' + imageName;
		return texture;

	}
#endif
}

PicoGL::Texture* LPVSceneRenderer::MakeSingleColorTexture(const ColorRGBA& color)
{
	PicoGL::Options options;
	options["minFilter"] = PicoGL::Constant::NEAREST;
	options["magFilter"] = PicoGL::Constant::NEAREST;
	options["mipmaps"] = PicoGL::Constant::TRUE;
	options["format"] = PicoGL::Constant::RGB;
	options["internalFormat"] = PicoGL::Constant::RGB32F;
	options["type"] = PicoGL::Constant::FLOAT;
	int side = 32;
	std::vector<ColorRGBA> arr;
	arr.resize(side * side);
	for (int i = 0; i < side * side; i++) {
		arr[i] = color;
	}
	return app->CreateTexture2D(&arr[0], side, side, options);
#if 0
	function makeSingleColorTexture(color) {
		var options = {};
		options['minFilter'] = PicoGL.NEAREST;
		options['magFilter'] = PicoGL.NEAREST;
		options['mipmaps'] = false;
		options['format'] = PicoGL.RGB;
		options['internalFormat'] = PicoGL.RGB32F;
		options['type'] = PicoGL.FLOAT;
		var side = 32;
		var arr = [];
		for (var i = 0; i < side * side; i++) {
			arr = arr.concat(color);
		}
		var image_data = new Float32Array(arr);
		return app.createTexture2D(image_data, side, side, options);
	}
#endif
	return nullptr;
}