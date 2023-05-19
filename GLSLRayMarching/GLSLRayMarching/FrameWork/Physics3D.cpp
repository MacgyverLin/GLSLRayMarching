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

//////////////////////////////////////////////////////////////////////////////////
Physics3D::BodyComponent::BodyComponent(GameObject& gameObject_)
	: Component(gameObject_)
{
	Physics3D::Manager::GetInstance().Add(this);
}

Physics3D::BodyComponent::~BodyComponent()
{
	Physics3D::Manager::GetInstance().Remove(this);
}

void Physics3D::BodyComponent::FixUpdate(float dt)
{
	OnFixUpdate(dt);
}

//////////////////////////////////////////////////////////////////////////////////
Physics3D::RigidbodyComponent::RigidbodyComponent(GameObject& gameObject_)
: Physics3D::BodyComponent(gameObject_)
{
}

Physics3D::RigidbodyComponent::~RigidbodyComponent()
{
}

bool Physics3D::RigidbodyComponent::OnInitiate()
{
	return true;
}

bool Physics3D::RigidbodyComponent::OnStart()
{
	return true;
}

bool Physics3D::RigidbodyComponent::OnUpdate()
{
	return true;
}

bool Physics3D::RigidbodyComponent::OnPause()
{
	return true;
}

void Physics3D::RigidbodyComponent::OnResume()
{
}

void Physics3D::RigidbodyComponent::OnStop()
{
}

void Physics3D::RigidbodyComponent::OnTerminate()
{
}

void Physics3D::RigidbodyComponent::OnFixUpdate(float dt)
{
}

//////////////////////////////////////////////////////////////////////////////////
Physics3D::SoftbodyComponent::SoftbodyComponent(GameObject& gameObject_)
	: Physics3D::BodyComponent(gameObject_)
{
}

Physics3D::SoftbodyComponent::~SoftbodyComponent()
{
}

bool Physics3D::SoftbodyComponent::OnInitiate()
{
	return true;
}

bool Physics3D::SoftbodyComponent::OnStart()
{
	return true;
}

bool Physics3D::SoftbodyComponent::OnUpdate()
{
	return true;
}

bool Physics3D::SoftbodyComponent::OnPause()
{
	return true;
}

void Physics3D::SoftbodyComponent::OnResume()
{
}

void Physics3D::SoftbodyComponent::OnStop()
{
}

void Physics3D::SoftbodyComponent::OnTerminate()
{
}

void Physics3D::SoftbodyComponent::OnFixUpdate(float dt)
{
}

/////////////////////////////////////////////////////////////////////
class Physics3D::Manager::Impl
{
public:
	Physics3D::Manager::Impl()
	{
	}
};

Physics3D::Manager::Manager()
{
	impl = new Physics3D::Manager::Impl();
}

Physics3D::Manager::~Manager()
{
	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

Physics3D::Manager& Physics3D::Manager::GetInstance()
{
	static Physics3D::Manager instance;

	return instance;
}

bool Physics3D::Manager::Initialize()
{
	Assert(impl);

	return true;
}

bool Physics3D::Manager::Update()
{
	Assert(impl);

	float dt = (float)Platform::GetDeltaTime();

	for (auto& bodyComponent : bodyComponents)
	{
		bodyComponent->FixUpdate(dt);
	}

	return true;
}

bool Physics3D::Manager::Pause()
{
	Assert(impl);

	return true;
}

void Physics3D::Manager::Resume()
{
	Assert(impl);
}

void Physics3D::Manager::Terminate()
{
	Assert(impl);

	bodyComponents.clear();

	if (impl)
	{
	}
}

void Physics3D::Manager::Add(BodyComponent* bodyComponent)
{
	Assert(impl);

	auto itr = std::find(bodyComponents.begin(), bodyComponents.end(), bodyComponent);
	if (itr != bodyComponents.end())
	{
		Error("duplicated BodyComponent is declared\n");
		return;
	}

	bodyComponents.push_back(bodyComponent);
}

void Physics3D::Manager::Remove(BodyComponent* bodyComponent)
{
	Assert(impl);

	auto itr = std::find(bodyComponents.begin(), bodyComponents.end(), bodyComponent);
	if (itr != bodyComponents.end())
		bodyComponents.erase(itr);
}

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