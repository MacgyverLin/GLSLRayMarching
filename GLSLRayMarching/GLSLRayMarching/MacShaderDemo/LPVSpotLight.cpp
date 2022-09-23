#include "LPVSpotLight.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVSpotLight::LPVSpotLight(const Vector3& position_, const Vector3& direction_, float coneAngle_, const ColorRGBA& color_)
: LPVLight(LPVLight::Type::SPOT, direction_, color_)
, position(position_)
, coneAngle(coneAngle_)
{
}

LPVSpotLight::~LPVSpotLight()
{
}

Vector3 LPVSpotLight::ViewSpaceDirection(LPVCamera& camera)
{
	auto inverseRotation = camera.orientation.Conjugate();

	Vector3 result;
	vec3transformQuat(result, this->Direction(), inverseRotation);

	return result;
}

Vector3 LPVSpotLight::ViewSpacePosition(LPVCamera& camera)
{
	Vector3 result;
	vec3transformMat4(result, this->position, camera.viewMatrix);
	
	return result;
}

void LPVSpotLight::ValidateLightViewMatrix(Matrix4& lightViewMatrix_)
{
	// Calculate as a look-at matrix from center to the direction (interpreted as a point)
	auto lookatpPoint = this->Position() + this->Direction();
	auto up = Vector3(0, 1, 0);

	lightViewMatrix_.SetLookAt(this->Position(), lookatpPoint, up);
}

void LPVSpotLight::ValidateLightProjectionMatrix(Matrix4& lightProjectionMatrix_)
{
	auto fov = this->coneAngle / 2.0;
	auto near = 0.01f;
	auto far = 1000.0f;

	lightProjectionMatrix_.SetPerspectiveFov(fov, 1.0, near, far);
}

void LPVSpotLight::ValidateLightViewProjectionMatrix(Matrix4& lightViewProjectionMatrix_)
{
	const Matrix4& lightViewMatrix = LightViewMatrix();
	const Matrix4& lightProjMatrix = LightProjectionMatrix();
	lightViewProjectionMatrix_ = lightProjMatrix * lightViewMatrix;
}

bool LPVSpotLight::OnInitiate()
{
	return true;
}

bool LPVSpotLight::OnStart()
{
	return true;
}

bool LPVSpotLight::OnUpdate()
{
	return true;
}

bool LPVSpotLight::OnPause()
{
	return true;
}

void LPVSpotLight::OnResume()
{
}

void LPVSpotLight::OnStop()
{
}

void LPVSpotLight::OnTerminate()
{
}

void LPVSpotLight::OnRender()
{
}