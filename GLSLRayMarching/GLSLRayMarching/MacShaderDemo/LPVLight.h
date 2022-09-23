#ifndef _LPVLight_h_ 
#define _LPVLight_h_ 

#include "ColorRGBA.h"
#include "Vector3.h"
#include "Matrix4.h"

class LPVLight
{
public:
	enum Type
	{
		POINT = 0,
		DIRECTIONAL,
		SPOT,
		COUNT
	};

	LPVLight(LPVLight::Type lightType_, const Vector3& direction_, const ColorRGBA& color_)
		: lightType(lightType_)
		, direction(direction_)
		, color(color_)
		, lightViewMatrix(Matrix4::Identity)
		, lightProjectionMatrix(Matrix4::Identity)
		, lightViewProjectionMatrix(Matrix4::Identity)
	{
		this->direction.Normalize();
	}

	virtual ~LPVLight()
	{
	}

	LPVLight::Type LightType()
	{
		return lightType;
	}

	Vector3& Direction()
	{
		return direction;
	}

	ColorRGBA& Color()
	{
		return color;
	}

	Matrix4& LightViewMatrix()
	{
		ValidateLightViewMatrix(lightViewMatrix);

		return lightViewMatrix;
	}

	Matrix4& LightProjectionMatrix()
	{
		ValidateLightProjectionMatrix(lightProjectionMatrix);

		return lightProjectionMatrix;
	}

	Matrix4& LightViewProjectionMatrix()
	{
		ValidateLightViewProjectionMatrix(lightViewProjectionMatrix);

		return lightViewProjectionMatrix;
	}
protected:
	virtual void ValidateLightViewMatrix(Matrix4& lightViewMatrix_) = 0;

	virtual void ValidateLightProjectionMatrix(Matrix4& lightProjectionMatrix_) = 0;

	virtual void ValidateLightViewProjectionMatrix(Matrix4& lightViewProjectionMatrix_) = 0;
private:
	Type lightType;
	Vector3 direction;
	ColorRGBA color;
	Matrix4 lightViewMatrix;
	Matrix4 lightProjectionMatrix;
	Matrix4 lightViewProjectionMatrix;
};

#endif