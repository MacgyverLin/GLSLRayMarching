#include "LPVSceneRenderer.h"
#include "LPVCommon.h"
#include "VertexBuffer.h"
#include "DrawCall.h"
#include "LPVObjLoader.h"
#include "LPVMtlLoader.h"

//////////////////////////////////////////////////////////////
LPVSceneRenderer::LPVSceneRenderer(GameObject& gameObject_)
	: Graphics3Component(gameObject_)
	, camera()
{
}

LPVSceneRenderer::~LPVSceneRenderer()
{
}

bool initLPV = false;



bool sponza = true;

float lpvGridSize;
int propagationIterations;

float offsetX;
float offsetY;
float offsetZ;

int shadowMapSize = 4096;
int shadowMapSmallSize = 512;

ColorRGBA ambientColor(0.15, 0.15, 0.15, 1.0);
ColorRGBA directionalLightcolor(1.0f, 1.0f, 1.0f, 1.0f);

bool rotate_light = false;

bool LPVSceneRenderer::OnInitiate()
{
	if (sponza)
	{
		lpvGridSize = 32;
		propagationIterations = 64;
		offsetX = 0;
		offsetY = 1.5;
		offsetZ = 0;
	}
	else
	{
		lpvGridSize = 32;
		propagationIterations = 64;
		offsetX = 0;
		offsetY = -1;
		offsetZ = -4.5;
	}

	//app.clearColor(0, 0, 0, 0);
	//app.cullBackfaces();
	//app.noBlend();

	Vector3 cameraPos;
	Matrix4 cameraRot;
	if (sponza)
	{
		cameraPos = Vector3(-15 + offsetX, 3 + offsetY, 0 + offsetZ);
		cameraRot.SetEulerAngleXYZ(15, -90, 0);
	}
	else
	{
		cameraPos = Vector3(2.62158 + offsetX, 1.68613 + offsetY, 3.62357 + offsetZ);
		cameraRot.SetEulerAngleXYZ(90 - 101, 180 - 70.2, 180 + 180);
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
	directionalLight = lightSources[0];

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

	sceneUniforms = SetupSceneUniforms();

	shaderLoader = new LPVShaderLoader("lpvShaders/");
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
		blitTextureDrawCall = CreateDrawCall(fullscreenVertexArray, textureBlitShader);

		lightInjectShader = MakeShader("lightInjection", data);
		geometryInjectShader = MakeShader("geometryInjection", data);
		lightPropagationShader = MakeShader("lightPropagation", data);
		//LPV.createInjectionDrawCall(lightInjectShader);
		//LPV.createGeometryInjectDrawCall(geometryInjectShader);
		//LPV.createPropagationDrawCall(lightPropagationShader);

		environmentShader = MakeShader("environment", data);
		environmentDrawCall = CreateDrawCall(fullscreenVertexArray, environmentShader,
			"u_environment_map", LoadTexture("environments/ocean.jpg", true));

		lpvDebugShader = MakeShader("lpvDebug", data);
		probeVertexArray = CreateSphereVertexArray(0.08, 8, 8);
		SetupProbeDrawCall(probeVertexArray, lpvDebugShader);

		defaultShader = MakeShader("default", data);
		rsmShader = MakeShader("RSM", data);
		simpleShadowMapShader = MakeShader("shadowMapping", data);
		if (sponza)
		{
			Matrix4 m(Matrix4::Identity);
			Quaternion r; r.SetEulerAngleZXY(0.0f, 0.0f, 0.0f);
			Vector3 t(offsetX, offsetY, offsetZ);
			Vector3 s(1, 1, 1);
			m.SetTranslateEulerAngleXYZScale(offsetX, offsetY, offsetZ, 0, 0, 0, 1);
			LoadObject("sponza_with_teapot/", "sponza_with_teapot.obj", "sponza_with_teapot.mtl", m);
		}
		else
		{
			Matrix4 m(Matrix4::Identity);
			Quaternion r; r.SetEulerAngleZXY(0.0f, 0.0f, 0.0f);
			Vector3 t(offsetX, offsetY, offsetZ);
			Vector3 s(1, 1, 1);
			m.SetTranslateEulerAngleXYZScale(offsetX, offsetY, offsetZ, 0, 0, 0, 1);
			LoadObject("living_room/", "living_room.obj", "living_room.mtl", m);
		}

		//LoadObject('sponza_crytek/', 'sponza.obj', 'sponza.mtl');
		/*
		{
			let m = mat4.create();
			let r = quat.fromEuler(quat.create(), 0, 0, 0);
			let t = vec3.fromValues(0, 0, 0);
			let s = vec3.fromValues(1, 1, 1);
			mat4.fromRotationTranslationScale(m, r, t, s);
			LoadObject('test_room/', 'test_room.obj', 'test_room.mtl', m);
		}
		*/
		/*{
			let m = mat4.create();
			let r = quat.fromEuler(quat.create(), 0, 45, 0);
			let t = vec3.fromValues(-5, 1, 2.5);
			let s = vec3.fromValues(0.06, 0.06, 0.06);
			mat4.fromRotationTranslationScale(m, r, t, s);
			LoadObject('teapot/', 'teapot.obj', 'default.mtl', m);
		}*/
	});

	return true;
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
	double startStamp = Platform::GetTime();

	if (rotate_light)
	{
		// Rotate light
		Matrix4 rotateMat;
		rotateMat.SetAxisAngle(Vector3(1, 1, 1), 0.01);

		//directionalLight-> = rotateMat * directionalLight->direction;
	}

	camera->Update();

	RenderShadowMap();

	bool render_indirect_light = false;
	bool render_lpv_debug_view = false;

	// Only refresh LPV when shadow map has been updated
	if (initLPV && render_indirect_light) {
		//if (LPV.accumulatedBuffer && LPV.injectionFramebuffer) {
			//LPV.clearInjectionBuffer();
			//LPV.clearAccumulatedBuffer();
		//}

		for (int i = 0; i < rsmFramebuffers.size(); i++) {
			// LPV.lightInjection(rsmFramebuffers[i]);
		}

		//LPV.geometryInjection(rsmFramebuffers[0], directionalLight);
		//LPV.lightPropagation(propagationIterations);
		initLPV = false;
	}

	//if (LPV.accumulatedBuffer)
		//RenderScene(LPV.accumulatedBuffer);

	Matrix4 viewProjection = camera->projectionMatrix * camera->viewMatrix;

	if (render_lpv_debug_view) {
		RenderLpvCells(viewProjection);
	}

	Matrix4 inverseViewProjection = viewProjection.Inverse();
	RenderEnvironment(inverseViewProjection);

	// Call this to get a debug render of the passed in texture
	//RenderTextureToScreen(LPV.injectionFramebuffer.colorTextures[0]);
	//RenderTextureToScreen(LPV.geometryInjectionFramebuffer.colorTextures[0]);
	//RenderTextureToScreen(LPV.propagationFramebuffer.colorTextures[0]);
	//RenderTextureToScreen(rsmFramebuffers[0].colorTextures[0]);

	double renderDelta = Platform::GetTime() - startStamp;
#if 0
	var startStamp = new Date().getTime();

	stats.begin();
	picoTimer.start();
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
		//RenderTextureToScreen(LPV.injectionFramebuffer.colorTextures[0]);
		//RenderTextureToScreen(LPV.geometryInjectionFramebuffer.colorTextures[0]);
		//RenderTextureToScreen(LPV.propagationFramebuffer.colorTextures[0]);
		//RenderTextureToScreen(rsmFramebuffers[0].colorTextures[0]);

	}
	picoTimer.end();
	stats.end();

	if (picoTimer.ready()) {
		gpuTimePanel.update(picoTimer.gpuTime, 35);
	}

	//requestAnimationFrame(render);

	var renderDelta = new Date().getTime() - startStamp;
	setTimeout(function() {
		requestAnimationFrame(render);
	}, 1000 / settings.target_fps - renderDelta - 1000 / 120);
#endif
}

void LPVSceneRenderer::RenderShadowMap()
{
	for (int i = 0; i < lightSources.size(); i++)
	{
		LPVLight* light = lightSources[i];

		const Matrix4& lightViewProjection = light->LightViewProjectionMatrix();
		Vector3 lightDirection;
		Vector3 lightPosition;
		float coneAngle = 0.0f;
		if (light->LightType()==LPVLight::Type::DIRECTIONAL) 
		{
			LPVDirectionLight* dirLight = (LPVDirectionLight*)light;
			lightDirection = dirLight->ViewSpaceDirection(*camera);
			lightPosition = Vector3::Zero;
			coneAngle = 0.0f;
		}
		else /*if (light->LightType() == LPVLight::Type::SPOT) */
		{
			LPVSpotLight* spotLight = (LPVSpotLight*)light;
			lightDirection = spotLight->Direction();
			lightPosition = spotLight->Position();
			coneAngle = spotLight->ConeAngle();
		}

		ColorRGBA lightColor = light->Color();

		/*
		app.drawFramebuffer(rsmFramebuffers[i])
			.viewport(0, 0, shadowMapSmallSize, shadowMapSmallSize)
			.depthTest()
			.depthFunc(PicoGL.LEQUAL)
			.noBlend()
			.clear();
		*/

		for (int j = 0, len = meshes.size(); j < len; j++) 
		{
			const Mesh& mesh = meshes[j];

			ShaderProgram* shaderProgram = mesh.rsmDrawCall->GetShaderProgram();
			shaderProgram->SetUniform1i("u_is_directional_light", (light->LightType() == LPVLight::Type::DIRECTIONAL));
			shaderProgram->SetUniformMatrix4x4fv("u_world_from_local", 1, mesh.modelMatrix);
			shaderProgram->SetUniformMatrix4x4fv("u_light_projection_from_world", 1, lightViewProjection);
			shaderProgram->SetUniform3fv("u_light_direction", 1, &lightDirection[0]);
			shaderProgram->SetUniform1f("u_spot_light_cone", coneAngle);
			shaderProgram->SetUniform4fv("u_light_color", 1, &lightColor[0]);
			shaderProgram->SetUniform3fv("u_spot_light_position", 1, &lightPosition[0]);
			
			mesh.rsmDrawCall->Bind();
			//mesh.rsmDrawCall->DrawArray();
		}
	}

	Matrix4& lightViewProjection = directionalLight->LightViewProjectionMatrix();

	//app.drawFramebuffer(shadowMapFramebuffer)
		//.viewport(0, 0, shadowMapSize, shadowMapSize)
		//.depthTest()
		//.depthFunc(PicoGL.LEQUAL)
		//.noBlend()
		//.clear();

	for (int i = 0, len = meshes.size(); i < len; ++i) 
	{
		Mesh& mesh = meshes[i];

		ShaderProgram* shaderProgram = mesh.shadowMapDrawCall->GetShaderProgram();
		shaderProgram->SetUniformMatrix4x4fv("u_world_from_local", 1, mesh.modelMatrix);
		shaderProgram->SetUniformMatrix4x4fv("u_light_projection_from_world", 1, lightViewProjection);

		mesh.shadowMapDrawCall->Bind();
		//mesh.shadowMapDrawCall->DrawArray();
	}
	
	initLPV = true;
}

void LPVSceneRenderer::RenderScene()
{
#if 0

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
#endif
}

void LPVSceneRenderer::RenderLpvCells(const Matrix4& viewProjection)
{
#if 0

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
#endif
}

void LPVSceneRenderer::RenderEnvironment(const Matrix4& inverseViewProjection)
{
#if 0
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
#endif
}

void LPVSceneRenderer::RenderTextureToScreen(Texture* texture)
{
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
#endif
}

	///////////////////////////////////////////////////////////////
	ShadowMapFrameBuffer* LPVSceneRenderer::SetupDirectionalLightShadowMapFramebuffer(int size)
	{
		ShadowMapFrameBuffer* frameBuffer = new ShadowMapFrameBuffer();
		if (!frameBuffer)
			return nullptr;

		if (!frameBuffer->Initiate(size, size))
			return nullptr;

		return frameBuffer;
	}

	RSMFramebuffer* LPVSceneRenderer::SetupRSMFramebuffer(int size)
	{
		RSMFramebuffer* frameBuffer = new RSMFramebuffer();
		if (!frameBuffer)
			return nullptr;

		if (!frameBuffer->Initiate(size, size))
			return nullptr;

		return frameBuffer;
	}

	Buffer* LPVSceneRenderer::SetupSceneUniforms()
	{
		Buffer* buffer = new Buffer();

		buffer->Begin(Buffer::Type::UNIFORM_BUFFER, Buffer::Usage::DYNAMIC_COPY);
		buffer->Fill(&ambientColor, sizeof(ambientColor)); // buffer->Update(int offset_, const void* src_, int size_);
		buffer->Fill(&directionalLightcolor, sizeof(directionalLightcolor));
		buffer->Fill(&camera->viewMatrix, sizeof(camera->viewMatrix));
		buffer->Fill(&camera->projectionMatrix, sizeof(camera->projectionMatrix));
		buffer->End();

		return buffer;
	}


	void LPVSceneRenderer::AddDirectionalLight(const Vector3 & direction_, const ColorRGBA & color_)
	{
		lightSources.push_back(new LPVDirectionLight(direction_, color_));
	}

	void LPVSceneRenderer::AddSpotLight(const Vector3 & position_, const Vector3 & direction_, float coneAngle_, const ColorRGBA & color_)
	{
		lightSources.push_back(new LPVSpotLight(position_, direction_, coneAngle_, color_));
	}

	void LPVSceneRenderer::SetupSpotLightsSponza(int _nSpotlights)
	{
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


	VertexBuffer* LPVSceneRenderer::CreateFullscreenVertexArray()
	{
		////////////////////////////////////////////////////////////
		float vertices[] =
		{
			-1, -1, 0,
			+3, -1, 0,
			-1, +3, 0
		};

		VertexBuffer* vertexBuffer = new VertexBuffer();
		VertexBuffer& p = *vertexBuffer;
		bool success = p
			.Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, &vertices[0], sizeof(vertices) / sizeof(vertices[0]) / 3)
			.End();
		if (!success)
		{
			return nullptr;
		}

		return vertexBuffer;
	}

	VertexBuffer* LPVSceneRenderer::CreateSphereVertexArray(float radius, int rings, int sectors)
	{
		std::vector<Vector3> positions;

		float R = 1.0f / (rings - 1);
		float S = 1.0f / (sectors - 1);

		float PI = Math::OnePi;
		float TWO_PI = 2.0 * PI;

		for (int r = 0; r < rings; ++r) {
			for (int s = 0; s < sectors; ++s) {

				float y = Math::Sin(-(PI / 2.0f) + PI * r * R);
				float x = Math::Cos(TWO_PI * s * S) * Math::Sin(PI * r * R);
				float z = Math::Sin(TWO_PI * s * S) * Math::Sin(PI * r * R);

				positions.push_back(Vector3(x * radius, y * radius, z * radius));
			}
		}

		std::vector<int> indices;

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
		}

		VertexBuffer* vertexBuffer = new VertexBuffer();
		VertexBuffer& p = *vertexBuffer;
		bool success = p
			.Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, &positions[0], sizeof(positions) / sizeof(positions[0]) / 3)
			.End();
		if (!success)
		{
			return nullptr;
		}

		// TODO:
		// indexBuffer = app.createIndexBuffer(PicoGL.UNSIGNED_SHORT, 3, new Uint16Array(indices));
		// var vertexArray = app.createVertexArray()
			// .vertexAttributeBuffer(0, positionBuffer)
			// .indexBuffer(indexBuffer);

		return vertexBuffer;
	}

	VertexBuffer* LPVSceneRenderer::CreateVertexArrayFromMeshInfo(const LPVObjLoader::ObjectInfo & info)
	{
		VertexBuffer* vertexBuffer = new VertexBuffer();
		VertexBuffer& p = *vertexBuffer;
		bool success = p
			.Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, info.positions[0], sizeof(info.positions) / sizeof(info.positions[0]) / 3)
			.FillVertices(1, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, info.normals[0], sizeof(info.normals) / sizeof(info.normals[0]) / 3)
			.FillVertices(2, 2, VertexAttribute::DataType::FLOAT, false, 0, 0, info.tangents[0], sizeof(info.tangents) / sizeof(info.tangents[0]) / 2)
			.FillVertices(3, 2, VertexAttribute::DataType::FLOAT, false, 0, 0, info.uvs[0], sizeof(info.uvs) / sizeof(info.uvs[0]) / 2)
			.End();
		if (!success)
		{
			return nullptr;
		}

		return vertexBuffer;
	}

	DrawCall* LPVSceneRenderer::SetupProbeDrawCall(VertexBuffer * vertexArray, ShaderProgram * shader)
	{
		std::vector<Vector3> probeLocations;
		std::vector<IVector3> probeIndices;

		float gridSize = lpvGridSize;
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

		Vector3 diff(0, 0, 0);

		for (float z = 0; z < gridSize; ++z) {
			for (float y = 0; y < gridSize; ++y) {
				for (float x = 0; x < gridSize; ++x) {

					diff = step * Vector3(x, y, z);

					Vector3 pos(0, 0, 0);
					pos = bottomLeft + diff;
					pos = pos + Vector3(0.5, 0.5, 0.5);

					probeLocations.push_back(pos);

					probeIndices.push_back(IVector3(x, y, z));
				}
			}
		}

		//
		// Pack into instance buffer
		//

		// We need at least one (x,y,z) pair to render any probes
		if (probeLocations.size() <= 1) {
			return nullptr;
		}

		// Set up for instanced drawing at the probe locations
		VertexBuffer* translations = new VertexBuffer();
		bool success = translations->
			Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, &probeLocations[0], sizeof(probeLocations) / sizeof(probeLocations[0]) / 3)
			.End();
		if (!success)
		{
			return nullptr;
		}

		VertexBuffer* indices = new VertexBuffer();
		success = translations->
			Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, &probeIndices[0], sizeof(probeIndices) / sizeof(probeIndices[0]) / 3)
			.End();
		if (!success)
		{
			return nullptr;
		}

		// TODO
		// vertexArray.instanceAttributeBuffer(10, translations);
		// vertexArray.instanceAttributeBuffer(11, indices);

		DrawCall* probeDrawCall = CreateDrawCall(vertexArray, shader);

		return probeDrawCall;
	}

	DrawCall* LPVSceneRenderer::CreateDrawCall(VertexBuffer * vertexBuffer_, ShaderProgram * shaderProgram_, const char* textureName_, Texture * texture_)
	{
		DrawCall* drawCall = new DrawCall();
		drawCall->SetVertexBuffer(vertexBuffer_);
		drawCall->SetShaderProgram(shaderProgram_);
		drawCall->SetTexture(textureName_, texture_);

		return drawCall;
	}

	void LPVSceneRenderer::LoadObject(const std::string & directory, const std::string & objFilename, const std::string & mtlFilename, const Matrix4 & modelMatrix)
	{
		LPVObjLoader objLoader;
		LPVMtlLoader mtlLoader;

		std::string path = std::string("assets/") + directory;

		objLoader.Load(path + objFilename, [&](std::vector<LPVObjLoader::ObjectInfo>& objects) {
			mtlLoader.Load(path + mtlFilename, [&](std::map<std::string, LPVMtlLoader::MaterialInfo>& materials) {
				for (auto& object : objects)
				{
					LPVMtlLoader::MaterialInfo material = materials[object.material];

					Texture2D* diffuseTexture;
					if (material.hasMapKd) {
						Texture2DFile* texture2DFile = new Texture2DFile();
						texture2DFile->Initiate(directory + material.map_Kd, false);
						diffuseTexture = texture2DFile;
					}
					else
					{
						diffuseTexture = MakeSingleColorTexture(material.Kd);
					}

					std::string specularMap = (material.hasMapKs) ? directory + material.map_Ks : "default_specular.jpg";
					std::string normalMap = (material.hasMapNorm) ? directory + material.map_norm : "default_normal.jpg";

					VertexBuffer* vertexArray = CreateVertexArrayFromMeshInfo(object);

					DrawCall* drawCall = CreateDrawCall(vertexArray, defaultShader);
					drawCall->SetTexture("u_diffuse_map", diffuseTexture);
					drawCall->SetTexture("u_specular_map", LoadTexture(specularMap.c_str(), false));
					drawCall->SetTexture("u_normal_map", LoadTexture(normalMap.c_str(), false));
					drawCall->SetBuffer("SceneUniforms", sceneUniforms);

					DrawCall* shadowMappingDrawCall = CreateDrawCall(vertexArray, simpleShadowMapShader);

					DrawCall* rsmDrawCall = CreateDrawCall(vertexArray, rsmShader, "u_diffuse_map", diffuseTexture);

					meshes.push_back({ modelMatrix, drawCall, shadowMappingDrawCall, rsmDrawCall });
				}
			});
		});
	}

	ShaderProgram* LPVSceneRenderer::MakeShader(const std::string & name, std::map<std::string, LPVShaderLoader::ShaderResult>&shaderLoaderData)
	{
		LPVShaderLoader::ShaderResult programData = shaderLoaderData[name];
		ShaderProgram* program = new ShaderProgram();
		program->CreateFromSource(programData.vertexSource.c_str(), programData.fragmentSource.c_str(), nullptr);

		return program;
	}

	bool IsDataTexture(const std::string & imageName)
	{
		return imageName.find("_ddn") != std::string::npos ||
			imageName.find("_spec") != std::string::npos ||
			imageName.find("_normal") != std::string::npos;
	}

	Texture2DFile* LPVSceneRenderer::LoadTexture(const char* imageName, bool haveOptions)
	{
		Texture2DFile* textureFile2D = new Texture2DFile();
		if (!textureFile2D)
			return nullptr;

		if (!haveOptions)
		{
			textureFile2D->SetMinFilter(Texture::MinFilter::LinearMipmapNearest);
			textureFile2D->SetMagFilter(Texture::MagFilter::Linear);

			if (IsDataTexture(imageName))
			{
				// options['internalFormat'] = PicoGL.RGB8;
				// options['format'] = PicoGL.RGB;
			}
			else
			{
				// options['internalFormat'] = PicoGL.SRGB8_ALPHA8;
				// options['format'] = PicoGL.RGBA;
			}
		}

		std::string path = std::string("assets/") + imageName;
		if (!textureFile2D->Initiate(path, false))
			return nullptr;
		else
			return textureFile2D;
	}

	Texture2D* LPVSceneRenderer::MakeSingleColorTexture(const ColorRGBA & c)
	{
		float side = 32;
		std::vector<ColorRGBA> arr;
		for (int i = 0; i < side * side; i++) {
			arr.push_back(c);
		}

		Texture2D* texture = new Texture2D();
		texture->Initiate(side, side, 4, Texture::DynamicRange::HIGH, &arr[0]);
		texture->SetMagFilter(Texture::MagFilter::Nearest);
		texture->SetMinFilter(Texture::MinFilter::Nearest);

		return texture;
	}