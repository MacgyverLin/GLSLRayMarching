//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _ShaderToyScene_h_
#define _ShaderToyScene_h_

#include "Platform.h"
#include "Scene.h"
#include "GameObject.h"
#include "ShaderToyCamera.h"
#include "ShaderToyComponent.h"

class ShaderToyScene : public Scene
{
public:
	ShaderToyScene();

	virtual ~ShaderToyScene();
protected:
	virtual bool OnInitiate() override;

	virtual bool OnStart() override;

	virtual bool OnUpdate() override;

	virtual bool OnPause() override;

	virtual void OnResume() override;

	virtual void OnStop() override;

	virtual void OnTerminate() override;

private:
	GameObject gameObject;
	ShaderToyCamera shaderToyCamera;
	ShaderToyComponent shaderToyComponent;
};

#endif