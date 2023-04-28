//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "Physics3D.h"


/////////////////////////////////////////////////////////////////////
bool Physics3D::Service::Initialize()
{
	return Physics3D::Manager::GetInstance().Initialize();
}

bool Physics3D::Service::Update()
{
	return Physics3D::Manager::GetInstance().Update();
}

bool Physics3D::Service::Pause()
{
	return Physics3D::Manager::GetInstance().Pause();
}

void Physics3D::Service::Resume()
{
	Physics3D::Manager::GetInstance().Resume();
}

void Physics3D::Service::Terminate()
{
	Physics3D::Manager::GetInstance().Terminate();
}