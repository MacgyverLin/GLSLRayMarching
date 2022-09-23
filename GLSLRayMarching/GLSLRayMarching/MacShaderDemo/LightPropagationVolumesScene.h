//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _LightPropagationVolumesScene_h_
#define _LightPropagationVolumesScene_h_

#include "Platform.h"
#include "Scene.h"
#include "GameObject.h"
#include "LightFieldCamera.h"
#include "LightFieldComponent.h"
#include "LPVSceneRenderer.h"

class LightPropagationVolumesScene : public Scene
{
public:
	LightPropagationVolumesScene();

	virtual ~LightPropagationVolumesScene();
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
	LPVSceneRenderer lpvSceneRenderer;
};

#endif