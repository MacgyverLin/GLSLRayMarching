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
, listenerComponent(gameObject)
, streamSourceComponent(gameObject)
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
	streamSourceComponent.Play();

	return true;
}

bool ShaderToyScene::OnUpdate()
{
	std::vector<char> data;
	// streamSourceComponent.GetSineWaveData(data, 1000, 1.0f);
	streamSourceComponent.GetEmptyData(data);
	streamSourceComponent.FillData(&data[0], data.size());
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