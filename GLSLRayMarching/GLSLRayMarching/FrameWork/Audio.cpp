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

enum Contants
{
	AUDIO_BUFFER_FORMAT = AL_FORMAT_STEREO16,

	AUDIO_CHANNEL_COUNT = 2,
	AUDIO_SAMPLING_RATE = 44100,
	AUDIO_BITS_PER_SAMPLE = 16,
	AUDIO_BUFFER_COUNT = 32,
	AUDIO_SAMPLES_PER_BUFFER = ((AUDIO_SAMPLING_RATE / AUDIO_BUFFER_COUNT))
};

/////////////////////////////////////////////////////////////////////
class Audio::SourceComponent::Impl
{
public:
	Audio::SourceComponent::Impl()
	{
	}

	ALuint source;

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

	int state;
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

	if (referenceDistance < 0)
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

bool Audio::SourceComponent::IsPlaying() const
{
	Assert(impl);

	return impl->state == AL_PLAYING;
}

bool Audio::SourceComponent::IsStopped() const
{
	Assert(impl);

	return impl->state == AL_STOPPED;
}

bool Audio::SourceComponent::IsPaused() const
{
	Assert(impl);

	return impl->state == AL_PAUSED;
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

	alGenSources(1, &impl->source);

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

	impl->state = AL_INITIAL;

	alSourcef(impl->source, AL_GAIN, impl->gain);
	// alSourcef(impl->source, AL_MIN_GAIN, impl->minGain);
	// alSourcef(impl->source, AL_MAX_GAIN, impl->maxGain);
	// alSourcefv(impl->source, AL_POSITION, impl->position);
	// alSourcefv(impl->source, AL_VELOCITY, impl->velocity);
	// alSourcefv(impl->source, AL_DIRECTION, impl->direction);
	// alSourcei(impl->source, AL_SOURCE_RELATIVE, impl->headRelative);
	// alSourcef(impl->source, AL_REFERENCE_DISTANCE, impl->referenceDistance);
	// alSourcef(impl->source, AL_MAX_DISTANCE, impl->maxDistance);
	// alSourcef(impl->source, AL_CONE_INNER_ANGLE, impl->coneInnerAngle);
	// alSourcef(impl->source, AL_CONE_OUTER_ANGLE, impl->coneOuterGain);
	// alSourcef(impl->source, AL_ROLLOFF_FACTOR, impl->coneRollOffFactor);
	// alSourcef(impl->source, AL_CONE_OUTER_GAIN, impl->coneOuterGain);
	alSourcef(impl->source, AL_PITCH, impl->pitch);
	alSourcei(impl->source, AL_LOOPING, impl->looping);

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

bool Audio::SourceComponent::Play()
{
	Assert(impl);

	OnSourcePlay();

	alSourcePlay(impl->source);
	if (alGetError() != AL_NO_ERROR)
		return false;

	alGetSourcei(impl->source, AL_SOURCE_STATE, &impl->state);
	if (impl->state != AL_PLAYING)
		return false;

	return true;
}

bool Audio::SourceComponent::Stop()
{
	Assert(impl);

	if (!OnSourceStop())
		return false;

	alSourceStop(impl->source);
	if (alGetError() != AL_NO_ERROR)
		return false;

	alGetSourcei(impl->source, AL_SOURCE_STATE, &impl->state);
	if (impl->state != AL_STOPPED)
		return false;

	return true;
}

bool Audio::SourceComponent::Pause()
{
	Assert(impl);

	if (!OnSourcePause())
		return false;

	alSourcePause(impl->source);
	if (alGetError() != AL_NO_ERROR)
		return false;

	alGetSourcei(impl->source, AL_SOURCE_STATE, &impl->state);
	if (impl->state != AL_PAUSED)
		return false;

	return true;
}

bool Audio::SourceComponent::Rewind()
{
	Assert(impl);

	alSourceRewind(impl->source);
	if (alGetError() != AL_NO_ERROR)
		return false;

	alGetSourcei(impl->source, AL_SOURCE_STATE, &impl->state);
	if (impl->state != AL_PLAYING)
		return false;

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
		alDeleteSources(1, &impl->source);

		impl->source = 0;
	}
}

void Audio::SourceComponent::OnRender()
{
	Assert(impl);
	float dt = Platform::GetDeltaTime();

	impl->velocity = (GetGameObject().GetGlobalPosition() - impl->position) / dt;
	impl->position = GetGameObject().GetGlobalPosition();
	impl->direction = -GetGameObject().GetGlobalZAxis();

	alSourcef(impl->source, AL_GAIN, impl->gain);
	// alSourcef(impl->source, AL_MIN_GAIN, impl->minGain);
	// alSourcef(impl->source, AL_MAX_GAIN, impl->maxGain);
	// alSourcefv(impl->source, AL_POSITION, impl->position);
	// alSourcefv(impl->source, AL_VELOCITY, impl->velocity);
	// alSourcefv(impl->source, AL_DIRECTION, impl->direction);
	// alSourcei(impl->source, AL_SOURCE_RELATIVE, impl->headRelative);
	// alSourcef(impl->source, AL_REFERENCE_DISTANCE, impl->referenceDistance);
	// alSourcef(impl->source, AL_MAX_DISTANCE, impl->maxDistance);
	// alSourcef(impl->source, AL_CONE_INNER_ANGLE, impl->coneInnerAngle);
	// alSourcef(impl->source, AL_CONE_OUTER_ANGLE, impl->coneOuterGain);
	// alSourcef(impl->source, AL_ROLLOFF_FACTOR, impl->coneRollOffFactor);
	// alSourcef(impl->source, AL_CONE_OUTER_GAIN, impl->coneOuterGain);
	alSourcef(impl->source, AL_PITCH, impl->pitch);
	alSourcei(impl->source, AL_LOOPING, impl->looping);
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

	buffers.resize(AUDIO_BUFFER_COUNT);
	alGenBuffers(AUDIO_BUFFER_COUNT, &buffers[0]);
	if (alGetError() != AL_NO_ERROR)
		return false;

	// clear buffer
	// for 16 bit stereo
	int dataLength = AUDIO_SAMPLES_PER_BUFFER * AUDIO_CHANNEL_COUNT * (AUDIO_BITS_PER_SAMPLE / 16);
	std::vector<char> data(dataLength);
	for (int i = 0; i < buffers.size(); i++)
	{
		alBufferData(buffers[i], AUDIO_BUFFER_FORMAT, &data[0], data.size(), AUDIO_SAMPLING_RATE);
		if (alGetError() != AL_NO_ERROR)
			return false;
	}

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

	alDeleteBuffers(AUDIO_BUFFER_COUNT, &buffers[0]);
	Assert(alGetError() != AL_NO_ERROR);

	Audio::SourceComponent::OnTerminate();
}

void Audio::StreamSourceComponent::OnRender()
{
	if (!IsPlaying())
		return;

	// force no looping;
	SetLooping(false);

	float dt = Platform::GetDeltaTime();
	bool haveNewBuffer = true;

	ALint error;

	// Get status
	ALint processed = 0;
	ALint queued = 0;

	if ((error = alGetError()) != AL_NO_ERROR)
	{
		::Error("alSourceUnqueueBuffers 1 : %d", error);
	}

	alGetSourceiv(impl->source, AL_BUFFERS_PROCESSED, &processed);
	if ((error = alGetError()) != AL_NO_ERROR)
	{
		::Error("alSourceUnqueueBuffers 1 : %d", error);
	}

	alGetSourceiv(impl->source, AL_BUFFERS_QUEUED, &queued);
	if ((error = alGetError()) != AL_NO_ERROR)
	{
		::Error("alSourceUnqueueBuffers 1 : %d", error);
	}
	::Debug("Queued %d, Processed %d\n", queued, processed);

	// If some buffers have been played, unqueue them
	// then load new audio into them, then add them to the queue
	if (processed > 0)
	{
		// Pseudo code for Streaming with Open AL
		// while (processed)
		//		Unqueue a buffer
		//		Load audio data into buffer (returned by UnQueueBuffers)
		//		if successful
		//			Queue buffer
		//			processed--
		//		else
		//			buffersinqueue--
		//			if buffersinqueue == 0
		//				finished playing !
		while (processed !=0)
		{
			ALuint bufferID;
			alSourceUnqueueBuffers(impl->source, 1, &bufferID);
			if ((error = alGetError()) != AL_NO_ERROR)
			{
				::Error("alSourceUnqueueBuffers 1 : %d", error);
			}
			
			ALint queued = 0;
			alGetSourceiv(impl->source, AL_BUFFERS_QUEUED, &queued);
			::Debug("Queued %d\n", queued);

			if (haveNewBuffer)
			{
				// Load data to buffer
				/*
				DataToRead = (DataSize > BSIZE) ? BSIZE : DataSize;
				if (DataToRead == DataSize) bFinished = AL_TRUE;
					fread(data, 1, DataToRead, fp);
				DataSize -= DataToRead;
				if (bFinished == AL_TRUE)
				{
					memset(data + DataToRead, 0, BSIZE - DataToRead);
				}
				*/

				int dataLength = AUDIO_SAMPLES_PER_BUFFER * AUDIO_CHANNEL_COUNT * (AUDIO_BITS_PER_SAMPLE / 16);
				std::vector<char> data(dataLength);

				// for 16 bit channel, stereo
				short* l = (short*)(&data[0]);
				short* r = (short*)(&data[1]);
				for (int i = 0; i < AUDIO_SAMPLES_PER_BUFFER; i++)
				{
					float frequency = 1000.0f;
					float phase = frequency * (((float)i) / AUDIO_SAMPLES_PER_BUFFER / AUDIO_BUFFER_COUNT) * Math::TwoPi;
					*l = 32767 * Math::Cos(phase); l += 2;
					*r = 32767 * Math::Cos(phase); r += 2;
				}

				alBufferData(bufferID, AUDIO_BUFFER_FORMAT, &data[0], data.size(), AUDIO_SAMPLING_RATE);
				if ((error = alGetError()) != AL_NO_ERROR)
					::Error("alBufferData :  %d", error);
				
				// Queue buffer
				alSourceQueueBuffers(impl->source, 1, &bufferID);
				if ((error = alGetError()) != AL_NO_ERROR)
					::Error("alSourceQueueBuffers 1 :  %d", error);
				
				processed--;
			}
			else
			{
				// fill empty buffer
				processed--;
			}
		}
	}
	
	Audio::SourceComponent::OnRender();
}

bool Audio::StreamSourceComponent::OnSourcePlay()
{
	ALint error;

	alSourcei(impl->source, AL_LOOPING, AL_FALSE);

	// attach first set of buffers using queuing mechanism
	alSourceQueueBuffers(impl->source, AUDIO_BUFFER_COUNT, &buffers[0]);
	if ((error = alGetError()) != AL_NO_ERROR)
		::Debug("alSourceQueueBuffers : %d", error);


	return true;
}

bool Audio::StreamSourceComponent::OnSourceStop()
{
	return true;
}

bool Audio::StreamSourceComponent::OnSourcePause()
{
	return true;
}

bool Audio::StreamSourceComponent::OnSourceRewind()
{
	return true;
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

	ALCcontext* context;
	ALCdevice* device;

	int					channels;
	int					bitsPerSample;
	int					sampleRate;

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

bool Audio::Manager::Initialize()
{
	Assert(impl);

	ALuint error = 0;

	impl->context = 0;
	impl->device = 0;
	impl->channels = AUDIO_CHANNEL_COUNT;
	impl->bitsPerSample = AUDIO_BITS_PER_SAMPLE;
	impl->sampleRate = AUDIO_SAMPLING_RATE;

	// device
	impl->device = alcOpenDevice(NULL);
	if (!impl->device)
		return false;

	// context
	impl->context = alcCreateContext(impl->device, NULL);
	alcMakeContextCurrent(impl->context);

	alSpeedOfSound(1.0);
	alDopplerVelocity(1.0);
	alDopplerFactor(1.0);
	//alDopplerFactor(1.0f);
	//alDopplerVelocity(1.0f);
	//alSpeedOfSound(1.0f);
	//alDistanceModel(AL_EXPONENT_DISTANCE_CLAMPED);

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

	if (impl->context)
	{
		alcMakeContextCurrent(NULL);

		alcDestroyContext(impl->context);
		impl->context = NULL;
	}

	if (impl->device)
	{
		alcCloseDevice(impl->device);
		impl->device = NULL;
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