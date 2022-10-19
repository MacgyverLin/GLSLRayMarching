//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Audio_h_
#define _Audio_h_

#include "Platform.h" 
#include "Component.h"

class Audio
{
public:
	class SourceComponent : public Component
	{
		friend class Audio;
	private:
		class Impl;
	public:
		SourceComponent(GameObject& gameObject_);
		virtual ~SourceComponent();

		bool Play();
		bool Stop();
		bool Pause();
		bool Rewind();

		void SetGain(float gain, float minGain = 0.0f, float maxGain = 1.0f);
		void SetHeadRelativeMode(bool mode);
		void SetMaxDistance(float maxDistance, float referenceDistance = -1.0f);

		void SetCone(float coneInnerAngle, float coneOuterAngle, float coneFalloff, float coneOuterGain);

		void SetPitch(float pitch);
		void SetLooping(bool loop);

		bool IsPlaying() const;
		bool IsStopped() const;
		bool IsPaused() const;

		float GetGain() const;
		float GetMinGain() const;
		float GetMaxGain() const;
		bool GetHeadRelativeMode() const;
		float GetMaxDistance() const;
		float GetReferenceDistance() const;

		float GetConeInnerAngle() const;
		float GetConeOuterAngle() const;
		float GetConeFalloff() const;
		float GetConeOuterGain() const;

		float GetPitch() const;
		bool GetLooping() const;
	private:	
		void Render();

		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnRender();

		virtual bool OnSourcePlay() = 0;

		virtual bool OnSourceStop() = 0;
		
		virtual bool OnSourcePause() = 0;
		
		virtual bool OnSourceRewind() = 0;
	protected:
		Impl* impl;
	};

	class StreamSourceComponent : public SourceComponent
	{
		friend class Audio;
	public:
		StreamSourceComponent(GameObject& gameObject_);

		virtual ~StreamSourceComponent();
	private:
		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnRender() override;

		virtual bool OnSourcePlay() override;

		virtual bool OnSourceStop() override;

		virtual bool OnSourcePause() override;

		virtual bool OnSourceRewind() override;
	protected:
		std::vector<unsigned int> buffers;
	};

	class ListenerComponent : public Component
	{
		friend class Audio;
	private:
		class Impl;
	public:
		ListenerComponent(GameObject& gameObject_);

		virtual ~ListenerComponent();

		void SetGain(float gain);

		float GetGain() const;
	private:
		void Render();

		virtual bool OnInitiate() override;

		virtual bool OnStart() override;

		virtual bool OnUpdate() override;

		virtual bool OnPause() override;

		virtual void OnResume() override;

		virtual void OnStop() override;

		virtual void OnTerminate() override;

		virtual void OnRender();
	private:
		Impl* impl;
	};

	class Manager
	{
	private:
		class Impl;
	private:
		Manager();
		~Manager();
	public:
		static Audio::Manager& GetInstance();

		int GetSourceBufferCount() const;
		int GetChannelCount() const;
		int GetSamplingRate() const;
		int GetBitsPerSample() const;
		int GetFormat() const;
		int GetSamplesPerBuffer() const;
		int GetBytesPerBuffer() const;

		bool Initialize();
		bool Update();
		bool Pause();
		void Resume();
		void Terminate();

		void Add(ListenerComponent* audioListener);
		void Add(SourceComponent* soundSource);
		void Remove(ListenerComponent* audioListener);
		void Remove(SourceComponent* soundSource);
	private:
		std::vector<ListenerComponent*> listeners;
		std::vector<SourceComponent*> sources;
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