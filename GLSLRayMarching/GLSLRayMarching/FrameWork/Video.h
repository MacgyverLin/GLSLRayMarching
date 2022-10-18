//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Video_h_
#define _Video_h_

#include "Platform.h" 
#include "Component.h"

class Video
{
public:
	class Graphics3Component : public Component
	{
		friend class Video;
	public:
		Graphics3Component(GameObject& gameObject_);

		virtual ~Graphics3Component();
	private:
		void Render();

		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnRender() = 0;
	};

	class RendererComponent : public Component
	{
		friend class Video;
	public:
		RendererComponent(GameObject& gameObject_);

		virtual ~RendererComponent();
	
	private:
		void Render();

		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnRender() = 0;
	private:
	};

	class CameraComponent : public Component
	{
		friend class Video;
	public:
		CameraComponent(GameObject& gameObject_);

		virtual ~CameraComponent();
	private:
		void Render();

		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnRender() = 0;
	};

	class Manager
	{
		Manager();
		~Manager();
	public:
		static Video::Manager& GetInstance();

		bool Initialize();
		bool Update();
		bool Pause();
		void Resume();
		void Terminate();
	
		void Add(CameraComponent* camera);
		void Add(RendererComponent* renderer);
		void Add(Graphics3Component* graphics3);
		void Remove(CameraComponent* camera);
		void Remove(RendererComponent* renderer);
		void Remove(Graphics3Component* graphics3);
	private:
		std::vector<CameraComponent*> cameras;
		std::vector<RendererComponent*> renderers;
		std::vector<Graphics3Component*> graphics3s;
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