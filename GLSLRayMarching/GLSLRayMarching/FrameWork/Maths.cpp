//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Maths.h"
#include "Platform.h"

const float Math::Epsilon = 1e-6f;
const float Math::ZeroTolerance = 1e-4f;
const float Math::MaxValue = FLT_MAX;
const float Math::MinValue = FLT_MIN;
const int   Math::MaxInteger = INT_MAX;
const int   Math::MinInteger = INT_MIN;
const float Math::OnePi = 3.14159265359f;
const float Math::TwoPi = 2.0f * Math::OnePi;
const float Math::HalfPi = 0.5f * Math::OnePi;
const float Math::InversePi = 1.0f / Math::OnePi;
const float Math::InverseTwoPi = 1.0f / Math::TwoPi;
const float Math::Degree2Radian = Math::OnePi / 180.0f;
const float Math::Radian2Degree = 180.0f / Math::OnePi;

float Math::Sgn(float value)
{
	return value >= 0 ? 1.0f : -1.0f;
}

float Math::Sin(float value)
{
	return sinf(value);
}

float Math::Tan(float value)
{
	return tanf(value);
}

float Math::Cos(float value)
{
	return cosf(value);
}

float Math::ASin(float value)
{
	if (-1.0 < value)
	{
		if (value < 1.0)
			return asinf(value);
		else
			return HalfPi;
	}
	else
	{
		return -HalfPi;
	}
}

float Math::ACos(float value)
{
	if (-1.0f < value)
	{
		if (value < 1.0f)
			return acosf(value);
		else
			return 0.0;
	}
	else
	{
		return OnePi;
	}
}

float Math::ATan(float value)
{
	return atanf(value);
}

float Math::ATan2(float y, float x)
{
	return atan2f(y, x);
}

float Math::FAbs(float value)
{
	return (float)fabs(value);
}

float Math::Ceil(float value)
{
	return (float)ceil(value);
}

float Math::Floor(float value)
{
	return(float)floor(value);
}

float Math::FMod(float x, float y)
{
	return (float)fmod(x, y);
}

float Math::Exp(float value)
{
	return (float)exp(value);
}

float Math::Log(float value)
{
	return (float)log(value);
}

float Math::Pow(float base, float exponent)
{
	return (float)pow(base, exponent);
}

float Math::Sqr(float value)
{
	return value * value;
}

float Math::Sqrt(float value)
{
	return (float)sqrt(value);
}

float Math::InvSqrt(float value)
{
	return (1.0f / (float)sqrt(value));
}

float Math::Min(float x, float y)
{
	return (x < y) ? x : y;
}

float Math::Max(float x, float y)
{
	return (x > y) ? x : y;
}

float Math::Clamp(float x, float min, float max)
{
	return Min(Max(x, min), max);
}

int Math::Sign(int value)
{
	if (value > 0)
		return 1;

	if (value < 0)
		return -1;

	return 0;
}

float Math::Sign(float value)
{
	if (value > 0.0f)
		return 1.0f;

	if (value < 0.0f)
		return -1.0f;

	return 0.0f;
}

float Math::UnitRandom(unsigned int seed)
{
	if (seed > 0.0f)
		srand(seed);

	float dRatio = float(rand()) / ((RAND_MAX));
	return dRatio;
}

float Math::SymmetricRandom(unsigned int seed)
{
	if (seed > 0.0f)
		srand(seed);

	float dRatio = float(rand()) / ((RAND_MAX));
	return (2.0f * dRatio - 1.0f);
}

float Math::IntervalRandom(float min, float max, unsigned int seed)
{
	if (seed > 0)
		srand(seed);

	float dRatio = float(rand()) / ((RAND_MAX));
	return min + (max - min) * (dRatio);
}

unsigned int Math::CeilPower2(unsigned int x)
{
	x = x - 1;
	x = x | (x >> 1);
	x = x | (x >> 2);
	x = x | (x >> 4);
	x = x | (x >> 8);
	x = x | (x >> 16);

	return x + 1;
}

bool Math::isPowerOf2(unsigned int v)
{
	return (v & (v - 1)) == 0;
}

float Math::FastSin0(float fAngle)
{
	float fASqr = fAngle * fAngle;
	float fResult = 7.61e-03f;
	fResult *= fASqr;
	fResult -= 1.6605e-01f;
	fResult *= fASqr;
	fResult += 1.0f;
	fResult *= fAngle;
	return fResult;
}

float Math::FastSin1(float fAngle)
{
	float fASqr = fAngle * fAngle;
	float fResult = -2.39e-08f;
	fResult *= fASqr;
	fResult += 2.7526e-06f;
	fResult *= fASqr;
	fResult -= 1.98409e-04f;
	fResult *= fASqr;
	fResult += 8.3333315e-03f;
	fResult *= fASqr;
	fResult -= 1.666666664e-01f;
	fResult *= fASqr;
	fResult += 1.0f;
	fResult *= fAngle;
	return fResult;
}

float Math::FastCos0(float fAngle)
{
	float fASqr = fAngle * fAngle;
	float fResult = 3.705e-02f;
	fResult *= fASqr;
	fResult -= 4.967e-01f;
	fResult *= fASqr;
	fResult += 1.0f;
	return fResult;
}

float Math::FastCos1(float fAngle)
{
	float fASqr = fAngle * fAngle;
	float fResult = -2.605e-07f;
	fResult *= fASqr;
	fResult += 2.47609e-05f;
	fResult *= fASqr;
	fResult -= 1.3888397e-03f;
	fResult *= fASqr;
	fResult += 4.16666418e-02f;
	fResult *= fASqr;
	fResult -= 4.999999963e-01f;
	fResult *= fASqr;
	fResult += 1.0f;
	return fResult;
}

float Math::FastTan0(float fAngle)
{
	float fASqr = fAngle * fAngle;
	float fResult = 2.033e-01f;
	fResult *= fASqr;
	fResult += 3.1755e-01f;
	fResult *= fASqr;
	fResult += 1.0f;
	fResult *= fAngle;
	return fResult;
}

float Math::FastTan1(float fAngle)
{
	float fASqr = fAngle * fAngle;
	float fResult = 9.5168091e-03f;
	fResult *= fASqr;
	fResult += 2.900525e-03f;
	fResult *= fASqr;
	fResult += 2.45650893e-02f;
	fResult *= fASqr;
	fResult += 5.33740603e-02f;
	fResult *= fASqr;
	fResult += 1.333923995e-01f;
	fResult *= fASqr;
	fResult += 3.333314036e-01f;
	fResult *= fASqr;
	fResult += 1.0;
	fResult *= fAngle;
	return fResult;
}

float Math::FastInvSin0(float value)
{
	float fRoot = Math::Sqrt((1.0f) - value);
	float fResult = -0.0187293f;
	fResult *= value;
	fResult += 0.0742610f;
	fResult *= value;
	fResult -= 0.2121144f;
	fResult *= value;
	fResult += 1.5707288f;
	fResult = HalfPi - fRoot * fResult;
	return fResult;
}

float Math::FastInvSin1(float value)
{
	float fRoot = Math::Sqrt(FAbs((1.0f) - value));
	float fResult = -0.0012624911f;
	fResult *= value;
	fResult += 0.0066700901f;
	fResult *= value;
	fResult -= 0.0170881256f;
	fResult *= value;
	fResult += 0.0308918810f;
	fResult *= value;
	fResult -= 0.0501743046f;
	fResult *= value;
	fResult += 0.0889789874f;
	fResult *= value;
	fResult -= 0.2145988016f;
	fResult *= value;
	fResult += 1.5707963050f;
	fResult = HalfPi - fRoot * fResult;
	return fResult;
}

float Math::FastInvCos0(float value)
{
	float fRoot = Math::Sqrt((1.0f) - value);
	float fResult = -0.0187293f;
	fResult *= value;
	fResult += 0.0742610f;
	fResult *= value;
	fResult -= 0.2121144f;
	fResult *= value;
	fResult += 1.5707288f;
	fResult *= fRoot;
	return fResult;
}

float Math::FastInvCos1(float value)
{
	float fRoot = Math::Sqrt(FAbs((1.0f) - value));
	float fResult = -0.0012624911f;
	fResult *= value;
	fResult += 0.0066700901f;
	fResult *= value;
	fResult -= 0.0170881256f;
	fResult *= value;
	fResult += 0.0308918810f;
	fResult *= value;
	fResult -= 0.0501743046f;
	fResult *= value;
	fResult += 0.0889789874f;
	fResult *= value;
	fResult -= 0.2145988016f;
	fResult *= value;
	fResult += 1.5707963050f;
	fResult *= fRoot;
	return fResult;
}

float Math::FastInvTan0(float value)
{
	float fVSqr = value * value;
	float fResult = 0.0208351f;
	fResult *= fVSqr;
	fResult -= 0.085133f;
	fResult *= fVSqr;
	fResult += 0.180141f;
	fResult *= fVSqr;
	fResult -= 0.3302995f;
	fResult *= fVSqr;
	fResult += 0.999866f;
	fResult *= value;
	return fResult;
}

float Math::FastInvTan1(float value)
{
	float fVSqr = value * value;
	float fResult = 0.0028662257f;
	fResult *= fVSqr;
	fResult -= 0.0161657367f;
	fResult *= fVSqr;
	fResult += 0.0429096138f;
	fResult *= fVSqr;
	fResult -= 0.0752896400f;
	fResult *= fVSqr;
	fResult += 0.1065626393f;
	fResult *= fVSqr;
	fResult -= 0.1420889944f;
	fResult *= fVSqr;
	fResult += 0.1999355085f;
	fResult *= fVSqr;
	fResult -= 0.3333314528f;
	fResult *= fVSqr;
	fResult += 1.0f;
	fResult *= value;
	return fResult;
}

float Math::FastInvSqrt(float value)
{
	float half = 0.5f * value;

	int i = *(int*)(&value);

	i = 0x5f3759df - (i >> 1);
	value = *(float*)&i;

	value = value * (1.5f - half * value * value);

	return value;
}