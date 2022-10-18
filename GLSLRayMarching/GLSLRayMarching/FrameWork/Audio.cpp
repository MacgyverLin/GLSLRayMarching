//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "Audio.h"
#include "GameObject.h"

#include <al.h>
#include <alc.h>

/////////////////////////////////////////////////////////////////////
class Audio::SourceComponent::Impl
{
public:
	Audio::SourceComponent::Impl()
	{
	}

	ALuint outSource;
	
	float gain;
	float minGain;
	float maxGain;

	Vector3 position;
	Vector3 velocity;
	Vector3 direction;
	bool headRelative;
	float referenceDistance;
	float maxDistance;
	float coneRollOffFactor;
	float coneInnerAngle;
	float coneOuterAngle;
	float coneOuterGain;
	float pitch;
	bool looping;
};

Audio::SourceComponent::SourceComponent(GameObject& gameObject_)
	: Component(gameObject_)
{
	impl = new Audio::SourceComponent::Impl();

	Audio::Manager::GetInstance().Add(this);
}

Audio::SourceComponent::~SourceComponent()
{
	Audio::Manager::GetInstance().Remove(this);

	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

void Audio::SourceComponent::SetGain(float gain, float minGain, float maxGain)
{
	Assert(impl);

	impl->gain = gain;
	impl->minGain = minGain;
	impl->maxGain = maxGain;
}

void Audio::SourceComponent::SetHeadRelativeMode(bool headRelative)
{
	Assert(impl);

	impl->headRelative = headRelative;
}

void Audio::SourceComponent::SetMaxDistance(float maxDistance, float referenceDistance)
{
	Assert(impl);

	impl->maxDistance = maxDistance;

	if(referenceDistance<0)
		impl->referenceDistance = maxDistance * 0.8f;
	else
		impl->referenceDistance = referenceDistance;
}

void Audio::SourceComponent::SetCone(float coneInnerAngle, float coneOuterAngle, float coneRollOffFactor, float coneOuterGain)
{
	Assert(impl);

	impl->coneInnerAngle = coneInnerAngle;
	impl->coneOuterAngle = coneOuterAngle;
	impl->coneRollOffFactor = coneRollOffFactor;
	impl->coneOuterGain = coneOuterGain;
}

void Audio::SourceComponent::SetPitch(float pitch)
{
	Assert(impl);

	impl->pitch = pitch;
}

void Audio::SourceComponent::SetLooping(bool looping)
{
	Assert(impl);

	impl->pitch = looping;
}

float Audio::SourceComponent::GetGain() const
{
	Assert(impl);

	return impl->gain;
}

float Audio::SourceComponent::GetMinGain() const
{
	Assert(impl);

	return impl->minGain;
}

float Audio::SourceComponent::GetMaxGain() const
{
	Assert(impl);

	return impl->maxGain;
}

bool Audio::SourceComponent::GetHeadRelativeMode() const
{
	Assert(impl);

	return impl->headRelative;
}

float Audio::SourceComponent::GetMaxDistance() const
{
	Assert(impl);

	return impl->maxDistance;
}

float Audio::SourceComponent::GetReferenceDistance() const
{
	Assert(impl);

	return impl->referenceDistance;
}

float Audio::SourceComponent::GetConeInnerAngle() const
{
	Assert(impl);

	return impl->coneInnerAngle;
}

float Audio::SourceComponent::GetConeOuterAngle() const
{
	Assert(impl);

	return impl->coneOuterAngle;
}

float Audio::SourceComponent::GetConeFalloff() const
{
	Assert(impl);

	return impl->coneRollOffFactor;
}

float Audio::SourceComponent::GetConeOuterGain() const
{
	Assert(impl);

	return impl->coneOuterGain;
}

float Audio::SourceComponent::GetPitch() const
{
	Assert(impl);

	return impl->pitch;
}

bool Audio::SourceComponent::GetLooping() const
{
	Assert(impl);

	return impl->looping;
}

void Audio::SourceComponent::Render()
{
	Assert(impl);

	OnRender();
}

bool Audio::SourceComponent::OnInitiate()
{
	Assert(impl);

	alGenSources(1, &impl->outSource);

	impl->gain = 1.0f;
	impl->minGain = 0.0f;
	impl->maxGain = 1.0f;

	impl->position = GetGameObject().GetGlobalPosition();
	impl->velocity = Vector3::Zero;
	impl->direction = -GetGameObject().GetGlobalZAxis();
	impl->headRelative = false;
	impl->referenceDistance = 1000.0f;
	impl->maxDistance = 1000.0f;
	impl->coneRollOffFactor = 1.0f;
	impl->coneInnerAngle = 100.0f;
	impl->coneOuterAngle = 120.0f;
	impl->coneOuterGain = 0.2f;
	impl->pitch = 1.0f;
	impl->looping = false;
	
	alSourcef(impl->outSource, AL_GAIN                 , impl->gain);
	alSourcef(impl->outSource, AL_MIN_GAIN             , impl->minGain);
	alSourcef(impl->outSource, AL_MAX_GAIN             , impl->maxGain);
	alSourcefv(impl->outSource, AL_POSITION            , impl->position);
	alSourcefv(impl->outSource, AL_VELOCITY            , impl->velocity);
	alSourcefv(impl->outSource, AL_DIRECTION           , impl->direction);
	alSourcei(impl->outSource, AL_SOURCE_RELATIVE      , impl->headRelative);
	alSourcef(impl->outSource, AL_REFERENCE_DISTANCE   , impl->referenceDistance);
	alSourcef(impl->outSource, AL_MAX_DISTANCE         , impl->maxDistance);
	alSourcef(impl->outSource, AL_CONE_INNER_ANGLE     , impl->coneInnerAngle);
	alSourcef(impl->outSource, AL_CONE_OUTER_ANGLE     , impl->coneOuterGain);
	alSourcef(impl->outSource, AL_ROLLOFF_FACTOR	   , impl->coneRollOffFactor);
	alSourcef(impl->outSource, AL_CONE_OUTER_GAIN      , impl->coneOuterGain);
	alSourcef(impl->outSource, AL_PITCH                , impl->pitch);
	alSourcei(impl->outSource, AL_LOOPING              , impl->looping);

	return true;
}

bool Audio::SourceComponent::OnStart()
{
	Assert(impl);

	return true;
}

bool Audio::SourceComponent::OnUpdate()
{
	Assert(impl);

	return true;
}

bool Audio::SourceComponent::OnPause()
{
	Assert(impl);

	return true;
}

void Audio::SourceComponent::OnResume()
{
	Assert(impl);
}

void Audio::SourceComponent::OnStop()
{
	Assert(impl);
}

void Audio::SourceComponent::OnTerminate()
{
	Assert(impl);

	if (impl)
	{
		alDeleteSources(1, &impl->outSource);

		impl->outSource = 0;
	}
}

void Audio::SourceComponent::OnRender()
{
	Assert(impl);
	float dt = Platform::GetDeltaTime();

	impl->velocity = (GetGameObject().GetGlobalPosition() - impl->position) / dt;
	impl->position = GetGameObject().GetGlobalPosition();
	impl->direction = -GetGameObject().GetGlobalZAxis();

	alSourcef(impl->outSource, AL_GAIN, impl->gain);
	alSourcef(impl->outSource, AL_MIN_GAIN, impl->minGain);
	alSourcef(impl->outSource, AL_MAX_GAIN, impl->maxGain);
	alSourcefv(impl->outSource, AL_POSITION, impl->position);
	alSourcefv(impl->outSource, AL_VELOCITY, impl->velocity);
	alSourcefv(impl->outSource, AL_DIRECTION, impl->direction);
	alSourcei(impl->outSource, AL_SOURCE_RELATIVE, impl->headRelative);
	alSourcef(impl->outSource, AL_REFERENCE_DISTANCE, impl->referenceDistance);
	alSourcef(impl->outSource, AL_MAX_DISTANCE, impl->maxDistance);
	alSourcef(impl->outSource, AL_CONE_INNER_ANGLE, impl->coneInnerAngle);
	alSourcef(impl->outSource, AL_CONE_OUTER_ANGLE, impl->coneOuterGain);
	alSourcef(impl->outSource, AL_ROLLOFF_FACTOR, impl->coneRollOffFactor);
	alSourcef(impl->outSource, AL_CONE_OUTER_GAIN, impl->coneOuterGain);
	alSourcef(impl->outSource, AL_PITCH, impl->pitch);
	alSourcei(impl->outSource, AL_LOOPING, impl->looping);
}

/////////////////////////////////////////////////////////////////////
Audio::StreamSourceComponent::StreamSourceComponent(GameObject& gameObject_)
	: Audio::SourceComponent(gameObject_)
{
}

Audio::StreamSourceComponent::~StreamSourceComponent()
{
}

bool Audio::StreamSourceComponent::OnInitiate()
{
	Assert(impl);

	return Audio::SourceComponent::OnInitiate();
}

bool Audio::StreamSourceComponent::OnStart()
{
	Assert(impl);

	return Audio::SourceComponent::OnStart();
}

bool Audio::StreamSourceComponent::OnUpdate()
{
	Assert(impl);

	return Audio::SourceComponent::OnUpdate();
}

bool Audio::StreamSourceComponent::OnPause()
{
	Assert(impl);

	return Audio::SourceComponent::OnPause();
}

void Audio::StreamSourceComponent::OnResume()
{
	Assert(impl);

	Audio::SourceComponent::OnResume();
}

void Audio::StreamSourceComponent::OnStop()
{
	Assert(impl);

	Audio::SourceComponent::OnStop();
}

void Audio::StreamSourceComponent::OnTerminate()
{
	Assert(impl);

	Audio::SourceComponent::OnTerminate();
}

void Audio::StreamSourceComponent::OnRender()
{
	Audio::SourceComponent::OnRender();
}

/////////////////////////////////////////////////////////////////////
class Audio::ListenerComponent::Impl
{
public:
	Audio::ListenerComponent::Impl()
	{
	}

	float gain;
	Vector3 position;
	Vector3 velocity;
	Vector3 right;
	Vector3 upward;
	Vector3 forward;
};

Audio::ListenerComponent::ListenerComponent(GameObject& gameObject_)
	: Component(gameObject_)
{
	impl = new Audio::ListenerComponent::Impl();

	Audio::Manager::GetInstance().Add(this);
}

Audio::ListenerComponent::~ListenerComponent()
{
	Audio::Manager::GetInstance().Remove(this);

	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

void Audio::ListenerComponent::SetGain(float gain)
{
	Assert(impl);

	impl->gain = gain;
}

float Audio::ListenerComponent::GetGain() const
{
	Assert(impl);

	return impl->gain;
}

void Audio::ListenerComponent::Render()
{
	OnRender();
}

bool Audio::ListenerComponent::OnInitiate()
{
	Assert(impl);

	impl->gain = 1.0f;
	impl->position = GetGameObject().GetGlobalPosition();
	impl->velocity = Vector3::Zero;
	impl->right = GetGameObject().GetGlobalXAxis();
	impl->upward = GetGameObject().GetGlobalYAxis();
	impl->forward = -GetGameObject().GetGlobalZAxis();

	float orientation[6] =
	{
		impl->forward[0],
		impl->forward[1],
		impl->forward[2],

		impl->upward[0],
		impl->upward[1],
		impl->upward[2]
	};
	alListenerf(AL_GAIN, impl->gain);
	alListenerfv(AL_POSITION, impl->position);
	alListenerfv(AL_ORIENTATION, orientation);

	return true;
}

bool Audio::ListenerComponent::OnStart()
{
	Assert(impl);

	return true;
}

bool Audio::ListenerComponent::OnUpdate()
{
	Assert(impl);

	return true;
}

bool Audio::ListenerComponent::OnPause()
{
	Assert(impl);

	return true;
}

void Audio::ListenerComponent::OnResume()
{
	Assert(impl);
}

void Audio::ListenerComponent::OnStop()
{
	Assert(impl);
}

void Audio::ListenerComponent::OnTerminate()
{
	Assert(impl);
}

void Audio::ListenerComponent::OnRender()
{
	float dt = Platform::GetDeltaTime();

	impl->velocity = (GetGameObject().GetGlobalPosition() - impl->position) / dt;
	impl->position = GetGameObject().GetGlobalPosition();
	impl->right = GetGameObject().GetGlobalXAxis();
	impl->upward = GetGameObject().GetGlobalYAxis();
	impl->forward = -GetGameObject().GetGlobalZAxis();

	float orientation[6] =
	{
		impl->forward[0],
		impl->forward[1],
		impl->forward[2],

		impl->upward[0],
		impl->upward[1],
		impl->upward[2]
	};

	alListenerf(AL_GAIN, impl->gain);
	alListenerfv(AL_POSITION, impl->position);
	alListenerfv(AL_ORIENTATION, orientation);
}

/////////////////////////////////////////////////////////////////////
class Audio::Manager::Impl
{
public:
	Audio::Manager::Impl()
	{
	}

	ALCcontext*			context;
	ALCdevice*			device;

	ALint				processedBuffer;
	ALint				queuedBuffer;

	std::vector<ALuint>	sndBuffers;

	int					channels;
	int					bitsPerSample;
	int					sampleRate;

	int					WP;

	// alDopplerFactor(1.0f);
	// alDopplerVelocity(343.3f);
	// alSpeedOfSound(343.3);
	// alDistanceModel(AL_EXPONENT_DISTANCE_CLAMPED);
};

Audio::Manager::Manager()
{
	impl = new Audio::Manager::Impl();
}

Audio::Manager::~Manager()
{
	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

Audio::Manager& Audio::Manager::GetInstance()
{
	static Audio::Manager instance;

	return instance;
}

#define CHANNELS 2
#define BITS_PER_SAMPLE 16
#define SAMPLE_RATE 44100
#define BUFFER_COUNT 32

bool Audio::Manager::Initialize()
{
	Assert(impl);

	ALuint error = 0;

	impl->context = 0;
	impl->device = 0;
	impl->processedBuffer = 0;
	impl->queuedBuffer = 0;
	impl->channels = CHANNELS;
	impl->bitsPerSample = BITS_PER_SAMPLE;
	impl->sampleRate = SAMPLE_RATE;

	impl->WP = 0;

	// device
	impl->device = alcOpenDevice(NULL);
	if (!impl->device)
		return false;

	// context
	impl->context = alcCreateContext(impl->device, NULL);
	alcMakeContextCurrent(impl->context);

	// create 32 buffers
	impl->sndBuffers.resize(BUFFER_COUNT);
	alGenBuffers(impl->sndBuffers.size(), &impl->sndBuffers[0]);
	error = alGetError();
	if (error != AL_NO_ERROR)
	{
		//printf("error alGenBuffers %x \n", error);
		return false;
	}

	alDopplerFactor(1.0f);
	alDopplerVelocity(343.3f);
	alSpeedOfSound(343.3);
	alDistanceModel(AL_EXPONENT_DISTANCE_CLAMPED);

	return true;
}

bool Audio::Manager::Update()
{
	Assert(impl);

	for (auto& listener : listeners)
	{
		listener->Render();

		for (auto& source : sources)
		{
			source->Render();
		}
	}

	return true;
}

bool Audio::Manager::Pause()
{
	Assert(impl);

	return true;
}

void Audio::Manager::Resume()
{
	Assert(impl);
}

void Audio::Manager::Terminate()
{
	Assert(impl);

	listeners.clear();
	sources.clear();

	if (impl->sndBuffers.size() != 0)
	{
		alDeleteBuffers(impl->sndBuffers.size(), &impl->sndBuffers[0]);
	}

	if (impl->device)
	{
		alcCloseDevice(impl->device);
		impl->device = NULL;
	}

	if (impl->context)
	{
		alcMakeContextCurrent(NULL);

		alcDestroyContext(impl->context);
		impl->context = NULL;
	}
}

void Audio::Manager::Add(ListenerComponent* listener)
{
	Assert(impl);

	auto itr = std::find(listeners.begin(), listeners.end(), listener);
	if (itr != listeners.end())
	{
		Error("duplicated ListenerComponent is declared\n");
		return;
	}

	listeners.push_back(listener);
}

void Audio::Manager::Add(SourceComponent* source)
{
	Assert(impl);

	auto itr = std::find(sources.begin(), sources.end(), source);
	if (itr != sources.end())
	{
		Error("duplicated RendererComponent is declared\n");
		return;
	}

	sources.push_back(source);
}

void Audio::Manager::Remove(ListenerComponent* listener)
{
	Assert(impl);

	auto itr = std::find(listeners.begin(), listeners.end(), listener);
	if (itr != listeners.end())
		listeners.erase(itr);
}

void Audio::Manager::Remove(SourceComponent* source)
{
	Assert(impl);

	auto itr = std::find(sources.begin(), sources.end(), source);
	if (itr != sources.end())
		sources.erase(itr);
}

/////////////////////////////////////////////////////////////////////
bool Audio::Service::Initialize()
{
	return Audio::Manager::GetInstance().Initialize();
}

bool Audio::Service::Update()
{
	return Audio::Manager::GetInstance().Update();
}

bool Audio::Service::Pause()
{
	return Audio::Manager::GetInstance().Pause();
}

void Audio::Service::Resume()
{
	Audio::Manager::GetInstance().Resume();
}

void Audio::Service::Terminate()
{
	Audio::Manager::GetInstance().Terminate();
}