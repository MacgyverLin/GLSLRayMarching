//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Maths_h_
#define _Maths_h_

#include "Platform.h"
#include "InputStream.h"
#include "OutputStream.h"

class Math
{
public:
	static float Sgn(float value);

	static float Sin(float radian);
	static float Cos(float value);
	static float Tan(float radian);
	static float ACos(float value);
	static float ASin(float value);
	static float ATan(float value);
	static float ATan2(float y, float x);

	static float Ceil(float value);
	static float Floor(float value);

	static int Abs(int value);
	static float FAbs(float value);
	static float FMod(float x, float y);

	static float Exp(float value);
	static float Log(float value);
	static float Pow(float base, float exponent);

	static float Sqr(float value);
	static float Sqrt(float value);
	static float InvSqrt(float value);

	static float Min(float x, float y);
	static float Max(float x, float y);
	static float Clamp(float x, float min, float max);

	static int Sign(int value);
	static float Sign(float value);

	static float UnitRandom(unsigned int uiSeed = 0);
	static float SymmetricRandom(unsigned int uiSeed = 0);
	static float IntervalRandom(float min, float max, unsigned int uiSeed = 0);
	static float RandomEpsilon(unsigned int uiSeed = 0);	

	static unsigned int CeilPower2(unsigned int x);
	static bool isPowerOf2(unsigned int v);

	static float FastSin0(float radian);
	static float FastCos0(float radian);
	static float FastTan0(float radian);
	static float FastInvSin0(float value);
	static float FastInvCos0(float value);
	static float FastInvTan0(float value);
	static float FastSin1(float radian);
	static float FastCos1(float radian);
	static float FastTan1(float radian);
	static float FastInvSin1(float value);
	static float FastInvCos1(float value);
	static float FastInvTan1(float value);
	static float FastInvSqrt(float value);

	static float Radians(float deg)
	{
		return deg * Degree2Radian;
	}

	static float Degrees(float radian)
	{
		return radian * Radian2Degree;
	}

	static const float Epsilon;
	static const float ZeroTolerance;
	static const float MaxValue;
	static const float MinValue;
	static const int   MaxInteger;
	static const int   MinInteger;
	static const float OnePi;
	static const float TwoPi;
	static const float HalfPi;
	static const float InversePi;
	static const float InverseTwoPi;
	static const float Degree2Radian;
	static const float Radian2Degree;
};

#endif