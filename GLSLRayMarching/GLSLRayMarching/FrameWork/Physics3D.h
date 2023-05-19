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
	class BodyComponent : public Component
	{
		friend class Physics3D;
		friend class WorldComponent;

	public:
		BodyComponent(GameObject& gameObject_);

		virtual ~BodyComponent();

		void FixUpdate(float dt);
	private:
		virtual bool OnInitiate() = 0;

		virtual bool OnStart() = 0;

		virtual bool OnUpdate() = 0;

		virtual bool OnPause() = 0;

		virtual void OnResume() = 0;

		virtual void OnStop() = 0;

		virtual void OnTerminate() = 0;

		virtual void OnFixUpdate(float dt) = 0;
	};

	class RigidbodyComponent : public BodyComponent
	{
		friend class Physics3D;
	public:
		RigidbodyComponent(GameObject& gameObject_);

		virtual ~RigidbodyComponent();
	private:
		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;
	
		virtual void OnFixUpdate(float dt) override;
	};

	class SoftbodyComponent : public BodyComponent
	{
		friend class Physics3D;
	public:
		SoftbodyComponent(GameObject& gameObject_);

		virtual ~SoftbodyComponent();
	private:
		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnFixUpdate(float dt) override;
	};

	
	class Manager
	{
	private:
		class Impl;
	public:
		Manager();

		~Manager();
	public:
		static Physics3D::Manager& GetInstance();

		bool Initialize();
		bool Update();
		bool Pause();

		void Resume();
		void Terminate();
		void Add(BodyComponent* bodyComponent);
		void Remove(BodyComponent* bodyComponent);
	private:
		std::vector<BodyComponent*> bodyComponents;
		Impl* impl;
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