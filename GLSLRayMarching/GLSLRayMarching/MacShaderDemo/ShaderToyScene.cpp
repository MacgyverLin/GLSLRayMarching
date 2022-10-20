//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "ShaderToyScene.h"
#include "Input.h"

ShaderToyScene::ShaderToyScene()
: shaderToyCamera(gameObject)
, shaderToyComponent(gameObject)
{
}

ShaderToyScene::~ShaderToyScene()
{
}

bool ShaderToyScene::OnInitiate()
{
	return true;
}

bool ShaderToyScene::OnStart()
{
	return true;
}

bool ShaderToyScene::OnUpdate()
{
	return true;
}

bool ShaderToyScene::OnPause()
{
	return true;
}

void ShaderToyScene::OnResume()
{
}

void ShaderToyScene::OnStop()
{
}

void ShaderToyScene::OnTerminate()
{
}