#ifndef _LPVDirectionLight_h_ 
#define _LPVDirectionLight_h_ 

#include "LPVCommon.h"
#include "LPVLight.h"
#include "LPVCamera.h"

class LPVDirectionLight : public LPVLight
{
public:
	LPVDirectionLight(const Vector3& direction_ = Vector3(0.3, -1.0, 0.3), const ColorRGBA& color_ = ColorRGBA::White);

	virtual ~LPVDirectionLight();

	Vector3 ViewSpaceDirection(LPVCamera& camera);

	virtual void OnRender();

	virtual bool OnInitiate();

	virtual bool OnStart();

	virtual bool OnUpdate();

	virtual bool OnPause();

	virtual void OnResume();

	virtual void OnStop();

	virtual void OnTerminate();

	float& OrthoProjectionSize()
	{
		return orthoProjectionSize;
	}
private:
	virtual void ValidateLightViewMatrix(Matrix4& lightViewMatrix_) override;

	virtual void ValidateLightProjectionMatrix(Matrix4& lightProjectionMatrix_) override;

	virtual void ValidateLightViewProjectionMatrix(Matrix4& lightViewProjectionMatrix_) override;
private:
	bool sponza;
	float orthoProjectionSize;
};

#endif