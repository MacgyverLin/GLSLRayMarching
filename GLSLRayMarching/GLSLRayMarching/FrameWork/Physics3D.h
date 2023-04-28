//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Physics3D_h_
#define _Physics3D_h_

#include "Platform.h" 
#include "Component.h"

#include "String.h"

class Physics3D
{
public:
	class SoftBodyComponent : public Component
	{
		friend class Physics3D;
	public:
		SoftBodyComponent(GameObject& gameObject_)
			: Component(gameObject_)
		{
		}

		virtual ~SoftBodyComponent()
		{
		}

	private:
		void FixUpdate(float dt)
		{
		}

		virtual bool OnInitiate() override
		{
		}

		virtual bool OnStart() override
		{
		}

		virtual bool OnUpdate() override
		{
		}

		virtual bool OnPause() override
		{
		}

		virtual void OnResume() override
		{
		}

		virtual void OnStop() override
		{
		}

		virtual void OnTerminate() override
		{
		}

		virtual void OnFixUpdate(float dt) = 0;
	private:
	};

	class WorldComponent : public Component
	{
		friend class Physics3D;
	public:
		std::list<SoftBodyComponent*> softBodyComponents;


	public:
		WorldComponent(GameObject& gameObject_)
			: Component(gameObject_)
		{
			Physics3D::Manager::GetInstance().Add(this);
		}

		virtual ~WorldComponent()
		{
			Physics3D::Manager::GetInstance().Remove(this);
		}

		void Add(SoftBodyComponent* softBodyComponent)
		{
			softBodyComponents.push_back(softBodyComponent);
		}

		void Remove(SoftBodyComponent* softBodyComponent)
		{
			auto itr = std::find(softBodyComponents.begin(), softBodyComponents.end(), softBodyComponent);
			if (itr != softBodyComponents.end())
				softBodyComponents.erase(itr);
		}
	private:
		void FixUpdate(float dt)
		{
			OnFixUpdate(dt);
		}

		virtual bool OnInitiate() override
		{
			return true;
		}

		virtual bool OnStart() override
		{
			return true;
		}

		virtual bool OnUpdate() override
		{
			return true;
		}

		virtual bool OnPause() override
		{
			return true;
		}

		virtual void OnResume() override
		{
		}

		virtual void OnStop() override
		{
		}

		virtual void OnTerminate() override
		{
		}

		virtual void OnFixUpdate(float dt) = 0
		{
		}
	};



	class Manager
	{
	private:
		std::vector<WorldComponent*> worldComponents;
	public:
		Manager()
		{
		}

		~Manager()
		{
		}
	public:
		static Physics3D::Manager& GetInstance()
		{
			Physics3D::Manager instance;

			return instance;
		}

		bool Initialize()
		{
			return true;
		}

		bool Update()
		{
			float dt = Platform::GetDeltaTime();
			for (auto worldComponent : worldComponents)
			{
				worldComponent->FixUpdate(dt);
			}
			return true;
		}

		bool Pause()
		{
			return true;
		}

		void Resume()
		{
		}

		void Terminate()
		{
		}

		void Add(WorldComponent* worldComponent)
		{
			worldComponents.push_back(worldComponent);
		}

		void Remove(WorldComponent* worldComponent)
		{
			auto itr = std::find(worldComponents.begin(), worldComponents.end(), worldComponent);
			if (itr != worldComponents.end())
				worldComponents.erase(itr);
		}
	};

	///////////////////////////////////////////////////////////////////////
public:
	class Service
	{
	public:
		static bool Initialize();
		static bool Update();
		static bool Pause();
		static void Resume();
		static void Terminate();
	};
};

#endif