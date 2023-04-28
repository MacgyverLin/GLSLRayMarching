//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "GameObject.h"
#include "ID.h"

GameObject::Manager::Manager()
: gameObjects()
{
}

GameObject::Manager::~Manager()
{
}

GameObject::Manager& GameObject::Manager::GetInstance()
{
	static GameObject::Manager instance;

	return instance;
}

bool GameObject::Manager::Initiate()
{
	Debug("GameObject::Manager::Construct()\n");

	for (auto& gameObject : gameObjects)
	{
		if (!gameObject->Initiate())
			return false;
	}

	return true;
}

bool GameObject::Manager::Start()
{
	Debug("GameObject::Manager::Start()\n");

	for (auto& gameObject : gameObjects)
	{
		if (!gameObject->Start())
			return false;
	}

	return true;
}

bool GameObject::Manager::Update()
{
	//Debug("GameObject::Manager::Update()\n");

	for (auto& gameObject : gameObjects)
	{
		if (!gameObject->Update())
			return false;
	}

	return true;
}

bool GameObject::Manager::Pause()
{
	Debug("GameObject::Manager::Pause()\n");

	for (auto& gameObject : gameObjects)
	{
		if (!gameObject->Pause())
			return false;
	}

	return true;
}

void GameObject::Manager::Resume()
{
	Debug("GameObject::Manager::Resume()\n");

	for (auto& gameObject : gameObjects)
	{
		gameObject->Resume();
	}
}

void GameObject::Manager::Stop()
{
	for (auto& gameObject : gameObjects)
	{
		gameObject->Stop();
	}
}

void GameObject::Manager::Terminate()
{
	Debug("GameObject::Manager::Destruct()\n");

	for (auto& gameObject : gameObjects)
	{
		gameObject->Terminate();
	}
}

void GameObject::Manager::Add(GameObject* gameObject)
{
	gameObjects.push_back(gameObject);
}

void GameObject::Manager::Remove(GameObject* gameObject)
{
	auto itr = std::find(gameObjects.begin(), gameObjects.end(), gameObject);
	if (itr != gameObjects.end())
		gameObjects.erase(itr);
}

//////////////////////////////////////////////////////////////////////////////////
GameObject::GameObject()
: Frame3()
, id(ID::Get())
, name()
, components()
{
	GameObject::Manager::GetInstance().Add(this);
}

GameObject::GameObject(int test)
: Frame3()
, id(ID::Get())
, name()
, components()
{
	GameObject::Manager::GetInstance().Add(this);
}

GameObject::~GameObject()
{
	GameObject::Manager::GetInstance().Remove(this);
}

void GameObject::Add(Component* component_)
{
	components.push_back(component_);
}

void GameObject::Remove(Component* component_)
{
	auto itr = std::find(components.begin(), components.end(), component_);

	components.erase(itr);
}

Component* GameObject::Get(ID id_)
{
	for (auto& component : components)
	{
		if (component->id == id_)
		{
			return component;
		}
	}

	return nullptr;
}

Component* GameObject::Get(const std::string& name_)
{
	for (auto& component : components)
	{
		if (component->name == name_)
		{
			return component;
		}
	}

	return nullptr;
}

int GameObject::GetComponentCount() const
{
	return components.size();
}

ID GameObject::GetID() const
{
	return id;
}

const std::string& GameObject::GetName() const
{
	return name;
}

void GameObject::SetName(const std::string& name_)
{
	name = name_;
}

bool GameObject::Initiate()
{
	if (!OnInitiate())
		return false;

	for (auto& component : components)
	{
		if (!component->Initiate())
		{
			return false;
		}
	}

	return true;
}

bool GameObject::Start()
{
	if (!OnStart())
		return false;

	for (auto& component : components)
	{
		if (!component->Start())
		{
			return false;
		}
	}

	return true;
}

bool GameObject::Update()
{
	if (!OnUpdate())
		return false;

	for (auto& component : components)
	{
		if (!component->Update())
		{
			return false;
		}
	}

	return true;
}

bool GameObject::Pause()
{
	if (!OnPause())
		return false;

	for (auto& component : components)
	{
		if (!component->Pause())
		{
			return false;
		}
	}

	return true;
}

void GameObject::Resume()
{
	OnResume();

	for (auto& component : components)
	{
		component->Resume();
	}
}

void GameObject::Stop()
{
	OnStop();

	for (auto& component : components)
	{
		component->Stop();
	}
}

void GameObject::Terminate()
{
	OnTerminate();

	for (auto& component : components)
	{
		component->Terminate();
	}
}

bool GameObject::OnInitiate()
{
	return true;
}

bool GameObject::OnStart()
{
	return true;
}

bool GameObject::OnUpdate()
{
	return true;
}

bool GameObject::OnPause()
{
	return true;
}

void GameObject::OnResume()
{
}

void GameObject::OnStop()
{
}

void GameObject::OnTerminate()
{
}