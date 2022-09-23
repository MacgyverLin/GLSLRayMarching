#ifndef _LPVSpotLight_h_ 
#define _LPVSpotLight_h_ 

#include "LPVCommon.h"
#include "LPVLight.h"
#include "LPVCamera.h"

class LPVSpotLight : public LPVLight
{
public:
	LPVSpotLight(const Vector3& position_ = Vector3(0, 2, 0), const Vector3& direction_ = Vector3(0.3, -0.3, 0.3), float coneAngle = 20.0f, const ColorRGBA& color_ = ColorRGBA(1.5f, 1.5f, 1.5f));

	virtual ~LPVSpotLight();

	virtual void OnRender();

	virtual bool OnInitiate();

	virtual bool OnStart();

	virtual bool OnUpdate();

	virtual bool OnPause();

	virtual void OnResume();

	virtual void OnStop();

	virtual void OnTerminate();

	Vector3 ViewSpaceDirection(LPVCamera& camera);

	Vector3 ViewSpacePosition(LPVCamera& camera);

	Vector3& Position()
	{
		return position;
	}
	
	float& ConeAngle()
	{
		return coneAngle;
	}
private:
	virtual void ValidateLightViewMatrix(Matrix4& lightViewMatrix_) override;

	virtual void ValidateLightProjectionMatrix(Matrix4& lightProjectionMatrix_) override;

	virtual void ValidateLightViewProjectionMatrix(Matrix4& lightViewProjectionMatrix_) override;
private:
	Vector3 position;
	float coneAngle;
};

#endif