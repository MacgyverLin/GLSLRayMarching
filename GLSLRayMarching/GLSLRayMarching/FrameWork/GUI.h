//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _GUI_h_
#define _GUI_h_

#include "Platform.h"
#include "Vector4.h"
#include "ShaderProgram.h"

struct IValue
{
	int value;
	int min;
	int max;
};

struct FValue
{
	float value;
	float min;
	float max;
};

struct Vec4Value
{
	Vector4 value;
	float min;
	float max;
};

class GUI
{
public:
	static void Test(std::map<const char*, bool>& bValues,
	std::map<const char*, IValue>& iValues,
	std::map<const char*, FValue>& fValues,
	std::map<const char*, Vec4Value>& vec4Values);

	static void Test2(int& lod, float& ratio, bool& wireframe, float& v);
	static void UpdateShader(ShaderProgram& shaderProgram);


	static void Test3(int& lod, float& ratio, bool& wireframe);
};

#endif