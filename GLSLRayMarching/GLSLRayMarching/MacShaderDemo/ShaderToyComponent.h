#ifndef _ShaderToyComponent_h_ 
#define _ShaderToyComponent_h_ 

#include "Component.h"
#include "Video.h"
#include "ShaderToyRenderer.h"

class ShaderToyComponent : public Video::Graphics3Component
{
public:
	ShaderToyComponent(GameObject& gameObject_);

	virtual ~ShaderToyComponent();

	Vector4 GetMouse();

	virtual void OnRender() override;

	virtual bool OnInitiate() override;

	virtual bool OnStart() override;

	virtual bool OnUpdate() override;

	virtual bool OnPause() override;

	virtual void OnResume() override;

	virtual void OnStop() override;

	virtual void OnTerminate() override;
private:
	ShaderToyRenderer* shaderToyRenderer;
};

#endif