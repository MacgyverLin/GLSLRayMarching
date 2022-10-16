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
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "DrawCall.h"
#include "LPVObjLoader.h"
#include "LPV.h"

class LPVSceneRenderer : public Video::Graphics3Component
{
public:
	struct Mesh
	{
		Matrix4 modelMatrix;
		DrawCall* drawCall;
		DrawCall* shadowMapDrawCall;
		DrawCall* rsmDrawCall;
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
	void SetupSpotLightsSponza(int _nSpotlights);
	VertexBuffer* CreateFullscreenVertexArray();
	VertexBuffer* CreateSphereVertexArray(float radius, int rings, int sectors);
	ShadowMapFrameBuffer* SetupDirectionalLightShadowMapFramebuffer(int size);
	RSMFramebuffer* SetupRSMFramebuffer(int size);
	void SetupSceneUniforms();
	VertexBuffer* CreateVertexArrayFromMeshInfo(const LPVObjLoader::ObjectInfo& info);
	DrawCall* SetupProbeDrawCall(VertexBuffer* vertexArray, ShaderProgram* shader);

	//////////////////////////////
	/// Rendering functions
	void Render();
	bool ShadowMapNeedsRendering();
	void RenderShadowMap();
	void RenderScene();
	void RenderLpvCells(const Matrix4& viewProjection);
	void RenderEnvironment(const Matrix4& inverseViewProjection);
	void RenderTextureToScreen(Texture* texture);
	
	//////////////////////////////
	/// Utilities functions
	void LoadObject(const std::string& directory, const std::string& objFilename, const std::string& mtlFilename, const Matrix4& modelMatrix);
	ShaderProgram* MakeShader(const std::string& name, std::map<std::string, LPVShaderLoader::ShaderResult>& shaderLoaderData);
	bool IsDataTexture(const std::string& imageName);
	Texture2DFile* LoadTexture(const char* imageName, bool haveOptions);
	Texture2D* MakeSingleColorTexture(const ColorRGBA& c);
	DrawCall* CreateDrawCall(ShaderProgram* shaderProgram_, VertexBuffer* vertexBuffer_, const VertexBuffer::Mode& mode_ = VertexBuffer::Mode::TRIANGLES);

	LPVCamera* camera;
	std::map<const char *, LPVLight*> lightSources;
	LPVLight* directionalLight;
	LPVLight* spotLight;
	LPVShaderLoader* shaderLoader;

	ShadowMapFrameBuffer* shadowMapFramebuffer;
	std::vector<RSMFramebuffer*> rsmFramebuffers;
	Buffer* sceneUniforms;

	VertexBuffer* fullscreenVertexArray;
	ShaderProgram* textureBlitShader;
	DrawCall* blitTextureDrawCall;

	ShaderProgram* lightInjectShader;
	ShaderProgram* geometryInjectShader;
	ShaderProgram* lightPropagationShader;

	ShaderProgram* environmentShader;
	DrawCall* environmentDrawCall;
	ShaderProgram* lpvDebugShader;
	VertexBuffer* probeVertexArray;
	ShaderProgram* defaultShader;
	ShaderProgram* rsmShader;
	ShaderProgram* simpleShadowMapShader;

	LPV* lpv;

	bool initLPV = false;
	bool sponza = true;

	float lpvGridSize;
	int propagationIterations;

	float offsetX;
	float offsetY;
	float offsetZ;

	int shadowMapSize = 4096;
	int shadowMapSmallSize = 512;

	ColorRGBA ambientColor = ColorRGBA(0.15f, 0.15f, 0.15f, 1.0f);
	ColorRGBA directionalLightcolor = ColorRGBA(1.0f, 1.0f, 1.0f, 1.0f);

	bool rotate_light = false;

	std::vector<LPVSceneRenderer::Mesh> meshes;
};

#endif