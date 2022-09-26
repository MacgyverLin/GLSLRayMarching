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
	ShadowMapFrameBuffer* SetupDirectionalLightShadowMapFramebuffer(int size);
	RSMFramebuffer* SetupRSMFramebuffer(int size);
	Buffer* SetupSceneUniforms();

	void AddDirectionalLight(const Vector3& direction_ = Vector3(0.3, -1.0, 0.3), const ColorRGBA& color_ = ColorRGBA::White);
	void AddSpotLight(const Vector3& position_ = Vector3(0, 2, 0), const Vector3& direction_ = Vector3(0.3, -0.3, 0.3), float coneAngle_ = 20.0f, const ColorRGBA& color_ = ColorRGBA(1.5f, 1.5f, 1.5f));
	void SetupSpotLightsSponza(int _nSpotlights = 0);
	
	VertexBuffer* CreateFullscreenVertexArray();
	VertexBuffer* CreateSphereVertexArray(float radius, int rings, int sectors);
	VertexBuffer* CreateVertexArrayFromMeshInfo(const LPVObjLoader::ObjectInfo& info);
	DrawCall* SetupProbeDrawCall(VertexBuffer* vertexArray, ShaderProgram* shader);

	DrawCall* CreateDrawCall(VertexBuffer* primitives_ = nullptr, ShaderProgram* shaderProgram_ = nullptr, const char* textureName_ = nullptr, Texture* texture_ = nullptr);
	void LoadObject(const std::string& directory, const std::string& objFilename, const std::string& mtlFilename, const Matrix4& modelMatrix);

	ShaderProgram* MakeShader(const std::string& name, std::map<std::string, LPVShaderLoader::ShaderResult>& shaderLoaderData);
	Texture2DFile* LoadTexture(const char* imageName, bool useDefaultOptions);
	Texture2D* MakeSingleColorTexture(const ColorRGBA& c);

	void RenderShadowMap();
	void RenderScene();
	void RenderLpvCells(const Matrix4& viewProjection);
	void RenderEnvironment(const Matrix4& inverseViewProjection);
	void RenderTextureToScreen(Texture* texture);

	LPVCamera* camera;
	std::vector<LPVLight*> lightSources;
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

	std::vector<Mesh> meshes;
};

#endif