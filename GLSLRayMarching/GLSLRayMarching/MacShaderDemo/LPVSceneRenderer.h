#ifndef _LPVSceneRenderer_h_ 
#define _LPVSceneRenderer_h_ 

#include "Component.h"
#include "Video.h"
#include "ColorRGBA.h"
#include "Matrix4.h"
#include "LPVCommon.h"
#include "LPVCamera.h"
#include "LPVDirectionLight.h"
#include "LPVSpotLight.h"
#include "LPVShaderLoader.h"
#include "LPVObjLoader.h"
#include "LPV.h"
#include "PicoGL.h"

class LPVSceneRenderer : public Video::Graphics3Component
{
public:
	class Mesh
	{
	public:
		Mesh(Matrix4 modelMatrix, PicoGL::DrawCall* drawCall, PicoGL::DrawCall* shadowMapDrawCall, PicoGL::DrawCall* rsmDrawCall)
		{
			this->modelMatrix = modelMatrix;
			this->drawCall = drawCall;
			this->shadowMapDrawCall = shadowMapDrawCall;
			this->rsmDrawCall = rsmDrawCall;
		}
		Matrix4 modelMatrix;
		PicoGL::DrawCall* drawCall;
		PicoGL::DrawCall* shadowMapDrawCall;
		PicoGL::DrawCall* rsmDrawCall;
	};
	LPVSceneRenderer(GameObject& gameObject_);

	virtual ~LPVSceneRenderer();

	virtual void OnRender() override;

	virtual bool OnInitiate() override;

	virtual bool OnStart() override;

	virtual bool OnUpdate() override;

	virtual bool OnPause() override;

	virtual void OnResume() override;

	virtual void OnStop() override;

	virtual void OnTerminate() override;
private:
	//////////////////////////////
	/// Setup Functions
	bool Init();
	void AddDirectionalLight(const Vector3& direction_, const ColorRGBA& color_);
	void AddSpotLight(const Vector3& position_, const Vector3& direction_, float coneAngle_, const ColorRGBA& color_);
	void SetupSpotLightsSponza(int _nSpotlights = 0);
	PicoGL::VertexArray* CreateFullscreenVertexArray();
	PicoGL::VertexArray* CreateSphereVertexArray(float radius, int rings, int sectors);
	PicoGL::Framebuffer* SetupDirectionalLightShadowMapFramebuffer(int size);
	PicoGL::Framebuffer* SetupRSMFramebuffer(int size);
	void SetupSceneUniforms();
	PicoGL::VertexArray* CreateVertexArrayFromMeshInfo(const LPVObjLoader::ObjectInfo& info);
	void SetupProbeDrawCall(PicoGL::VertexArray* vertexArray, PicoGL::Program* shader);

	//////////////////////////////
	/// Rendering functions
	void Render();
	bool ShadowMapNeedsRendering();
	void RenderShadowMap();
	void RenderScene(PicoGL::Framebuffer* framebuffer);
	void RenderLpvCells(const Matrix4& viewProjection);
	void RenderEnvironment(const Matrix4& inverseViewProjection);
	void RenderTextureToScreen(PicoGL::Texture* texture);
	
	//////////////////////////////
	/// Utilities functions
	void LoadObject(const std::string& directory, const std::string& objFilename, const std::string& mtlFilename, const Matrix4& modelMatrix);
	PicoGL::Program* MakeShader(const std::string& name, std::map<std::string, LPVShaderLoader::ShaderResult>& shaderLoaderData);
	bool IsDataTexture(const std::string& imageName);
	PicoGL::Texture* LoadTexture(const char* imageName, const PicoGL::Options& options = PicoGL::DUMMY_OBJECT);
	PicoGL::Texture* MakeSingleColorTexture(const ColorRGBA& c);
	
	////////////////////////////////////////////////////////////////////////////////
	int target_fps = 60;
	float environment_brightness = 1.5;

	bool rotate_light = true;

	float indirect_light_attenuation = 1.0;
	float ambient_light = 0.0;
	bool render_lpv_debug_view = false;
	bool render_direct_light = true;
	bool render_indirect_light = true;

	ColorRGBA ambientColor = ColorRGBA(0.15f, 0.15f, 0.15f, 1.0f);


	PicoGL::App* app;

	// GUI gpuTimePanel;
	PicoGL::Timer* picoTimer;

	PicoGL::Program* defaultShader;
	PicoGL::Program* rsmShader;
	PicoGL::Program* simpleShadowMapShader;

	LPV* lpv;

	PicoGL::DrawCall* blitTextureDrawCall;
	PicoGL::DrawCall* environmentDrawCall;

	PicoGL::UniformBuffer* sceneUniforms;

	int shadowMapSize = 4096;
	PicoGL::Framebuffer* shadowMapFramebuffer;

	int shadowMapSmallSize;
	std::vector<PicoGL::Framebuffer*> rsmFramebuffers;

	bool sponza = true;

	bool initLPV = false;

	int lpvGridSize;
	int propagationIterations;

	float offsetX;
	float offsetY;
	float offsetZ;

	LPVCamera* camera;

	LPVDirectionLight* directionalLight;
	LPVSpotLight* spotLight;

	class LightSource
	{
	public:
		LightSource(LPVLight* source, std::string type)
		{
			this->source = source;
			this->type = type;
		}

		LPVLight* source;
		std::string type;
	};
	std::vector<LightSource> lightSources;

	std::vector<LPVSceneRenderer::Mesh> meshes;

	int texturesLoaded = 0;

	PicoGL::DrawCall* probeDrawCall;

	/////////////////////////////////
	LPVShaderLoader* shaderLoader;
	PicoGL::VertexArray* fullscreenVertexArray;
	PicoGL::Program* textureBlitShader;

	PicoGL::Program* lightInjectShader;
	PicoGL::Program* geometryInjectShader;
	PicoGL::Program* lightPropagationShader;

	PicoGL::Program* environmentShader;
	PicoGL::Program* lpvDebugShader;
	PicoGL::VertexArray* probeVertexArray;
};

#endif