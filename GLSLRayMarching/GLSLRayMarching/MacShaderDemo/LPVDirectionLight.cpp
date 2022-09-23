#include "LPVDirectionLight.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVDirectionLight::LPVDirectionLight(const Vector3& direction_, const ColorRGBA& color_)
: LPVLight(LPVLight::Type::DIRECTIONAL, direction_, color_)
, sponza(false)
, orthoProjectionSize(100.0)
{
	if (sponza)
		this->orthoProjectionSize = 100.0;
	else
		this->orthoProjectionSize = 30.0;
}

LPVDirectionLight::~LPVDirectionLight()
{
}

Vector3 LPVDirectionLight::ViewSpaceDirection(LPVCamera& camera)
{
	auto inverseRotation = camera.orientation.Conjugate();

	Vector3 result;
	vec3transformQuat(result, this->Direction(), inverseRotation);

	return result;
}


void LPVDirectionLight::ValidateLightViewMatrix(Matrix4& lightViewMatrix_)
{
	// Calculate as a look-at matrix from center to the direction (interpreted as a point)
	auto eyePosition = Vector3(0, 0, 0);
	auto up = Vector3(0, 1, 0);

	lightViewMatrix_.SetLookAt(eyePosition, this->Direction(), up);
}

void LPVDirectionLight::ValidateLightProjectionMatrix(Matrix4& lightProjectionMatrix_)
{
	auto size = this->orthoProjectionSize / 2.0;
	lightProjectionMatrix_.SetOrthogonalOffCenter(-size, size, -size, size, -size, size);
}

void LPVDirectionLight::ValidateLightViewProjectionMatrix(Matrix4& lightViewProjectionMatrix_)
{
	const Matrix4& lightViewMatrix = LightViewMatrix();
	const Matrix4& lightProjMatrix = LightProjectionMatrix();
	
	lightViewProjectionMatrix_ = lightProjMatrix * lightViewMatrix;
}

bool LPVDirectionLight::OnInitiate()
{
	return true;
}

bool LPVDirectionLight::OnStart()
{
	return true;
}

bool LPVDirectionLight::OnUpdate()
{
	return true;
}

bool LPVDirectionLight::OnPause()
{
	return true;
}

void LPVDirectionLight::OnResume()
{
}

void LPVDirectionLight::OnStop()
{
}

void LPVDirectionLight::OnTerminate()
{
}

void LPVDirectionLight::OnRender()
{
}