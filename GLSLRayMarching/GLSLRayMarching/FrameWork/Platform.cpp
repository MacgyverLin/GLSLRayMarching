//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "ArgParse.h"
#include <iostream> 

extern "C"
{
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavutil/timestamp.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
};

//////////////////////////////////////////////////////////////////////////////////
std::string appName = "";
std::string initialScene = "";

void* handle = nullptr;
int width = 0;
int height = 0;
double currentTime = 0;
double deltaTime = 0;

int totalFrameCounter = 0;
int sceneFrameCounter = 0;

bool keystates[(int)Platform::KeyCode::Count] = { 0 };
bool oldkeystates[(int)Platform::KeyCode::Count] = { 0 };

Platform::Mouse mouse = { 0 };

Platform::JoyStick joySticks[JOYSTICK_COUNT] = { 0 };
bool joyStickConnected[JOYSTICK_COUNT] = { 0 };
std::vector<std::string> joyStickNames;

std::vector<std::string> dropPaths;

std::vector<std::string> arguments;

//////////////////////////////////////////////////////
Platform::SystemTime::SystemTime()
	: wYear(0)
	, wMonth(0)
	, wDayOfWeek(0)
	, wDay(0)
	, wHour(0)
	, wMinute(0)
	, wSecond(0)
	, wMilliseconds(0)
{
}

Platform::SystemTime::~SystemTime()
{
}

//////////////////////////////////////////////////////
#include "webcam3rdparty.h"

class Platform::WebCam::Impl
{
public:
	Platform::WebCam::Impl()
	{
		dev = 0;
	}

	bool Initiate()
	{
#if (PLATFORM == GLFW)
		//uncomment for silent setup
		//videoInput::setVerbose(false); 

		//uncomment for multithreaded setup
		//videoInput::setComMultiThreaded(true); 

		//optional static function to list devices
		//for silent listDevices use listDevices(true);
		int numDevices = videoInput::listDevices();

		//you can also now get the device list as a vector of strings 
		std::vector <std::string> list = videoInput::getDeviceList();
		for (size_t i = 0; i < list.size(); i++) {
			Info("[%i] device is %s\n", i, list[i].c_str());
		}

		//by default we use a callback method
		//this updates whenever a new frame
		//arrives if you are only ocassionally grabbing frames
		//you might want to set this to false as the callback caches the last
		//frame for performance reasons. 
		VI.setUseCallback(true);

		//try and setup device with id 0 and id 1
		//if only one device is found the second 
		//setupDevice should return false

		//if you want to capture at a different frame rate (default is 30) 
		//specify it here, you are not guaranteed to get this fps though.
		//m_imp->VI.setIdealFramerate(dev, 60);

		//we can specifiy the dimensions we want to capture at
		//if those sizes are not possible VI will look for the next nearest matching size
		//m_imp->VI.setRequestedMediaSubType((int)MEDIASUBTYPE_MJPG);
		VI.setupDevice(dev, 640, 480, VI_COMPOSITE);

		//once the device is setup you can try and
		//set the format - this is useful if your device
		//doesn't remember what format you set it to
		//m_imp->VI.setFormat(dev, VI_NTSC_M);					//optional set the format

		//we allocate our buffer based on the number
		//of pixels in each frame - this will be width * height * 3
		//frame_size = m_imp->VI.getSize(dev);
		//frame.resize(frame_size);

		if (VI.getSize(dev) < 1) return false;

		return true;

#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	bool Update(std::vector<unsigned char>& buffer, bool flip)
	{
#if (PLATFORM == GLFW)
		buffer.resize(VI.getWidth(dev)* VI.getHeight(dev) * 3);

		if (VI.isFrameNew(dev))
		{
			VI.getPixels(dev, &buffer[0], true, flip);
		}

		return true;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	bool Pause()
	{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	void Resume()
	{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	void Terminate()
	{
#if (PLATFORM == GLFW)
		VI.stopDevice(dev);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	int GetWidth()
	{
#if (PLATFORM == GLFW)
		return VI.getWidth(dev);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return 0;
	}

	int GetHeight()
	{
#if (PLATFORM == GLFW)
		return VI.getHeight(dev);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return 0;
	}
private:
	videoInput	VI;
	int			dev;
};


Platform::WebCam::WebCam()
	: impl(nullptr)
{
	impl = new Platform::WebCam::Impl();
}

Platform::WebCam::~WebCam()
{
	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

bool Platform::WebCam::Initiate()
{
	Assert(impl);

	return impl->Initiate();
}

bool Platform::WebCam::Update(std::vector<unsigned char>& buffer, bool flip)
{
	Assert(impl);

	return impl->Update(buffer, flip);
}

bool Platform::WebCam::Pause()
{
	Assert(impl);

	return impl->Pause();
}

void Platform::WebCam::Resume()
{
	Assert(impl);

	return impl->Resume();
}

void Platform::WebCam::Terminate()
{
	Assert(impl);

	return impl->Terminate();
}

int Platform::WebCam::GetWidth() const
{
	Assert(impl);

	return impl->GetWidth();
}

int Platform::WebCam::GetHeight() const
{
	Assert(impl);

	return impl->GetHeight();
}


//////////////////////////////////////////////////////
#include <windows.h>
#include <mmsystem.h>
#include <mmreg.h>
#include <process.h>

class Platform::Microphone::Impl
{
private:
	typedef void (*SoundFillFunc)(void* dest, void* src, int samples);

#ifdef USE_FLOAT_SND
	typedef float t_snd;
#else
	typedef short t_snd;
#endif

	enum {
		CombMax = 8,
		AllMax = 2,
	};

	struct DelayBuffer {
		enum {
			Max = 100000,
		};
		float Buf[Max];
		unsigned long Rate;
		unsigned int Index;
		void Init(unsigned long m) { Rate = m; }
		void Update(float a) { Buf[Index++ % Rate] = a; }
		float Sample(unsigned long n = 0) { return Buf[(Index + n) % Rate]; }
	};

	struct Reverb {
		enum {
			CombMax = 8,
			AllMax = 2,
		};
		DelayBuffer comb[CombMax], all[AllMax];

		float Sample(float a, int index = 0, int character = 0, int lpfnum = 4) {
			const int tau[][4][4] = {
									 {
										 {2063, 1847, 1523, 1277},
										 {3089, 2927, 2801, 2111},
										 {5479, 5077, 4987, 4057},
										 {9929, 7411, 4951, 1063},
									 },
									 {
										 {2053, 1867, 1531, 1259},
										 {3109, 2939, 2803, 2113},
										 {5477, 5059, 4993, 4051},
										 {9949, 7393, 4957, 1097},
									 } };

			const float gain[] = {
				-0.8733f,
				-0.8223f,
				-0.8513f,
				-0.8503f,
			};
			float D = a * 0.5f;
			float E = 0;

			// Comb
			for (int i = 0; i < CombMax; i++) {
				DelayBuffer* reb = &comb[i];
				reb->Init(tau[character % 2][index % 4][i]);
				float k = 0;
				float c = 0;
				int LerpMax = lpfnum + 1;
				for (int h = 0; h < LerpMax; h++) k += reb->Sample(h * 2);
				k /= float(LerpMax);
				c = a + k;
				reb->Update(c * gain[i] * 1.1);
				E += c;
			}
			D = (D + E) * 0.3;
			return D;
		}
	};

	DelayBuffer comb[CombMax], all[AllMax];

	Reverb rebL;
	Reverb rebR;
	DelayBuffer delayL;
	DelayBuffer delayR;

	inline float bound(float value) {
		if (value >= 1.0f)
			return 1.0f;
		if (value <= -1.0f)
			return -1.0f;
		return value;
	}

	inline t_snd float2snd(float value) {
#ifdef USE_FLOAT_SND
		return bound(value);
#else
		if (value >= 1.0f)
			return (SHORT)MAXSHORT;
		if (value <= -1.0f)
			return (SHORT)MINSHORT;
		return (t_snd)(value * 0x7FFF);
#endif
	}

	inline float snd2float(t_snd value) {
#ifdef USE_FLOAT_SND
		return bound(value);
#else
		if (value >= (SHORT)MAXSHORT)
			return 1.0f;
		if (value <= (SHORT)MINSHORT)
			return -1.0f;
		return float(value) / 0x7FFF;
#endif
	}

	enum {
		Bits = (sizeof(t_snd) * 8),
		Channel = (2),
		Freq = (44100),
		Align = ((Channel * Bits) / 8),
		BytePerSec = (Freq * Align),
		BufNum = 3,
		Samples = 1024,
	};

	enum STATE {
		STATE_NO_SOUND = 0,
		STATE_NORMAL,
		STATE_REVERB,
		STATE_DELAY,
		STATE_REVERB_AND_DELAY,
	};

	struct SoundCallback {
		SoundFillFunc inf;
		SoundFillFunc outf;
	};

	// fill callback
	void inFunc(void* dest, void* src, int samples)
	{
		t_snd* s = (t_snd*)src;
		t_snd* d = (t_snd*)dest;
		samples /= sizeof(t_snd);
		samples /= Channel;

		switch (s_state) {
		case STATE_NO_SOUND: // none
			for (int i = 0; i < samples; i++) {
				d[i * 2 + 0] = 0;
				d[i * 2 + 1] = 0;
			}
			break;
		case STATE_NORMAL: // normal
			for (int i = 0; i < samples; i++) {
				float v = bound(snd2float(s[i * 2 + 0]) * s_volume);
				d[i * 2 + 0] = float2snd(v);
				d[i * 2 + 1] = float2snd(v);
			}
			break;
		case STATE_REVERB: // reverb
			for (int i = 0; i < samples; i++) {
				float v = bound(snd2float(s[i * 2 + 0] * 0.5f) * s_volume);
				d[i * 2 + 0] = float2snd(0.5f * v + (rebL.Sample(v, 0, 0, 4)));
				d[i * 2 + 1] = float2snd(0.5f * v + (rebR.Sample(v, 0, 1, 4)));
			}
			break;
		case STATE_DELAY: // delay
			delayL.Init(15000);
			delayR.Init(15000);
			for (int i = 0; i < samples; i++) {
				float v = bound(snd2float(s[i * 2 + 0]) * s_volume);
				d[i * 2 + 0] = float2snd(delayL.Sample() + v);
				d[i * 2 + 1] = float2snd(delayR.Sample() + v);
				delayL.Update(snd2float(d[i * 2 + 0]) * 0.5f);
				delayR.Update(snd2float(d[i * 2 + 1]) * 0.5f);
			}
			break;
		case STATE_REVERB_AND_DELAY: // reverb and delay
			delayL.Init(60000);
			delayR.Init(60000);
			for (int i = 0; i < samples; i++) {
				float v0 = snd2float(s[i * 2 + 0] * 0.25f);
				float v1 = bound(snd2float(s[i * 2 + 0]) * s_volume);
				float L = 0.25f * v1 + (rebL.Sample(v0, 0, 0, 4));
				float R = 0.25f * v1 + (rebR.Sample(v0, 0, 0, 4));
				d[i * 2 + 0] = float2snd(delayL.Sample() + L);
				d[i * 2 + 1] = float2snd(delayR.Sample() + R);
				delayL.Update(bound(L * 0.5f));
				delayR.Update(bound(R * 0.5f));
			}
			break;
		}

		//printf("%3.4f %3.4f\r", abs(d[0]), abs(d[1]));
	}

	void outFunc(void* dest, void* src, int samples)
	{
	}

	HANDLE SoundInit()
	{
		return (HANDLE)_beginthread(SoundThreadProc, 0, this);
	}

	void SoundTerm(HANDLE hThread)
	{
		if (!hThread)
			return;

		PostThreadMessage(GetThreadId(hThread), WM_QUIT, 0, 0);
		WaitForSingleObject(hThread, 3000);
		CloseHandle(hThread);
	}

	void CopySound(void* dest, void* src, int samples)
	{
		//memcpy(&impl->buffer[0], whdrin[countin].lpData, whdrin[countin].dwBufferLength);

		t_snd* s = (t_snd*)src;
		float* d = (float*)dest;
		samples /= sizeof(t_snd);
		samples /= Channel;

		for (int i = 0; i < samples; i++)
		{
			float v = bound(snd2float(s[i * 2 + 0]) * s_volume);
			d[i * 2 + 0] = v;
			d[i * 2 + 1] = v;
		}
	}

	static VOID SoundThreadProc(void* ptr)
	{
		enum {
			SoundIn = 0,
			SoundOut,
			SoundMax,
		};

		HANDLE ahEvents[SoundMax] =
		{
			CreateEvent(NULL, FALSE, FALSE, NULL),
			CreateEvent(NULL, FALSE, FALSE, NULL),
		};

		WAVEFORMATEX wfx =
		{
	#ifdef USE_FLOAT_SND
			WAVE_FORMAT_IEEE_FLOAT,
	#else
			WAVE_FORMAT_PCM,
	#endif
			Channel,
			Freq,
			BytePerSec,
			Align,
			Bits,
			0
		};

		Platform::Microphone::Impl* impl = (Platform::Microphone::Impl*)ptr;

		HWAVEIN hwi = NULL;
		DWORD countin = 0;
		WAVEHDR whdrin[BufNum];

		impl->buffer.resize(Samples * 2);

		waveInOpen(&hwi, WAVE_MAPPER, &wfx, (DWORD_PTR)ahEvents[SoundIn], 0, CALLBACK_EVENT);
		std::vector<std::vector<char> > soundbuffer;
		soundbuffer.resize(BufNum);
		for (int i = 0; i < BufNum; i++)
		{
			soundbuffer[i].resize(Samples * wfx.nBlockAlign);
			WAVEHDR tempin =
			{
				&soundbuffer[i][0],
				(DWORD)(Samples * wfx.nBlockAlign),
				0,
				0,
				0,
				0,
				NULL,
				0
			};
			whdrin[i] = tempin;
			waveInPrepareHeader(hwi, &whdrin[i], sizeof(WAVEHDR));
			waveInAddBuffer(hwi, &whdrin[i], sizeof(WAVEHDR));
		}

		//#define WAVE_OUT
#ifdef WAVE_OUT
		waveOutOpen(&hwo, WAVE_MAPPER, &wfx, (DWORD_PTR)ahEvents[SoundOut], 0, CALLBACK_EVENT);
		std::vector<std::vector<char> > soundbufferout;
		soundbufferout.resize(BufNum);
		for (int i = 0; i < BufNum; i++)
		{
			soundbufferout[i].resize(Samples * wfx.nBlockAlign);
			WAVEHDR tempout =
			{
				&soundbufferout[i][0],
				(DWORD)(Samples * wfx.nBlockAlign),
				0,
				0,
				0,
				0,
				NULL,
				0
			};
			whdrout[i] = tempout;
		}
#endif

		// Record Start
		waveInStart(hwi);

		// Start MSG
		MSG msg;
		for (;;)
		{
			if (PeekMessage(&msg, 0, 0, 0, PM_REMOVE))
			{
				if (msg.message == WM_QUIT)
					break;
			}

			DWORD dwSignal = WaitForMultipleObjects(SoundMax, ahEvents, FALSE, 1000);

			// IN
			if (dwSignal == WAIT_OBJECT_0 + 0)
			{
				if (whdrin[countin].dwFlags & WHDR_DONE)
				{
#ifdef WAVE_OUT
					impl->inFunc(whdrout[countin].lpData, whdrin[countin].lpData, whdrin[countin].dwBufferLength);
					waveOutPrepareHeader(hwo, &whdrout[countout], sizeof(WAVEHDR));
					waveOutWrite(hwo, &whdrout[countout], sizeof(WAVEHDR));
					countout = (countout + 1) % BufNum;
#endif
					impl->CopySound(&impl->buffer[0], whdrin[countin].lpData, whdrin[countin].dwBufferLength);
					waveInPrepareHeader(hwi, &whdrin[countin], sizeof(WAVEHDR));
					waveInAddBuffer(hwi, &whdrin[countin], sizeof(WAVEHDR));
					countin = (countin + 1) % BufNum;
				}
			}

			// OUT
			if (dwSignal == WAIT_OBJECT_0 + 1)
			{
				;
			}
		}

		// in
		do
		{
			countin = 0;
			for (int i = 0; i < BufNum; i++)
			{
				countin += !(whdrin[i].dwFlags & WHDR_DONE);
			}
			if (countin)
				Sleep(50);
		} while (countin);

		// out
#ifdef WAVE_OUT
		do
		{
			countout = 0;
			for (int i = 0; i < BufNum; i++)
				countout += !(whdrout[i].dwFlags & WHDR_DONE);
			if (countout) Sleep(50);
		} while (countout);
#endif

		for (int i = 0; i < BufNum; i++)
		{
			waveInUnprepareHeader(hwi, &whdrin[i], sizeof(WAVEHDR));

#ifdef WAVE_OUT
			waveOutUnprepareHeader(hwo, &whdrout[i], sizeof(WAVEHDR));
#endif
		}


		waveInReset(hwi);
		waveInClose(hwi);

#ifdef WAVE_OUT
		waveOutReset(hwo);
		waveOutClose(hwo);
#endif

		for (int i = 0; i < SoundMax; i++)
		{
			if (ahEvents[i])
				CloseHandle(ahEvents[i]);
		}
	}

	HANDLE micStart(BOOL bMicOn)
	{
		s_bEcho = FALSE;
		if (s_bMic) {
			micOn();
		}
		else {
			micOff();
		}
		return SoundInit();
	}

	void micEnd(HANDLE handle)
	{
		SoundTerm(handle);
		s_bMic = FALSE;
	}

	void micOn(void)
	{
		s_bMic = TRUE;
		if (s_bEcho)
			s_state = STATE_REVERB_AND_DELAY;
		else
			s_state = STATE_REVERB;
	}

	void micOff(void)
	{
		s_bMic = FALSE;
		s_state = STATE_NO_SOUND;
	}

	void micEchoOn(void)
	{
		s_bEcho = TRUE;
		if (s_bMic)
			s_state = STATE_REVERB_AND_DELAY;
		else
			s_state = STATE_NO_SOUND;
	}

	void micEchoOff(void)
	{
		s_bEcho = FALSE;
		if (s_bMic)
			s_state = STATE_REVERB;
		else
			s_state = STATE_NO_SOUND;
	}

	void micVolume(float volume)
	{
		s_volume = volume;
	}

public:
	Impl()
	{
	}

	bool Initiate()
	{
#if (PLATFORM == GLFW)
		s_bMic = FALSE;
		s_bEcho = FALSE;

		h = micStart(TRUE);

		s_state = STATE_NORMAL;
		s_volume = 1.0f;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	bool Update(std::vector<float>& buffer)
	{
#if (PLATFORM == GLFW)
		// !!!!!!!!! TODO, ¡ıº“√»
		// update microphone, if necessary
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		buffer = this->buffer;
		return true;
	}

	bool Pause()
	{
#if (PLATFORM == GLFW)
		// !!!!!!!!! TODO, ¡ıº“√»
		// system pause, do something for microphone, if necessary
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	void Resume()
	{
#if (PLATFORM == GLFW)
		// !!!!!!!!! TODO, ¡ıº“√»
		// system pause, do something for microphone, if necessary
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	void Terminate()
	{
#if (PLATFORM == GLFW)
		micEnd(h);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	int GetSampleCount()
	{
		return Samples;
	}

	int GetChannelCount()
	{
		return Channel;
	}
private:
	HANDLE h;
	BOOL s_bMic;
	BOOL s_bEcho;
	STATE s_state;
	float s_volume;
	std::vector<float> buffer;
};

Platform::Microphone::Microphone()
	: impl(nullptr)
{
	impl = new Microphone::Impl();
}

Platform::Microphone::~Microphone()
{
	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

bool Platform::Microphone::Initiate()
{
	Assert(impl);

	return impl->Initiate();
}

bool Platform::Microphone::Update(std::vector<float>& buffer)
{
	Assert(impl);

	return impl->Update(buffer);
}

bool Platform::Microphone::Pause()
{
	Assert(impl);

	return impl->Pause();
}

void Platform::Microphone::Resume()
{
	Assert(impl);

	return impl->Resume();
}

void Platform::Microphone::Terminate()
{
	Assert(impl);

	return impl->Terminate();
}

int Platform::Microphone::GetSampleCount()
{
	Assert(impl);

	return impl->GetSampleCount();
}

int Platform::Microphone::GetChannelCount()
{
	Assert(impl);

	return impl->GetChannelCount();
}

//////////////////////////////////////////////////////
#include <math.h>

#define INBUF_SIZE 4096
#define AUDIO_INBUF_SIZE 20480
#define AUDIO_REFILL_THRESH 4096

bool Platform::InitiateFFMPEG()
{
	return true;
}

void Platform::TerminateFFMPEG()
{
}

class Platform::VideoDecoder::Impl
{
public:
	Platform::VideoDecoder::Impl()
	{
		src_filename = "";
		frame = NULL;
		pkt = NULL;

		fmt_ctx = NULL;
		video_dec_ctx = NULL;
		width = 0;
		height = 0;
		pix_fmt = AV_PIX_FMT_NONE;
		video_stream = NULL;
		video_stream_idx = 0;

		video_dst_data[4] = { NULL };
		video_dst_linesize[4] = { 0 };
		video_dst_bufsize = 0;

		sws_ctx = NULL;

		audio_dec_ctx = NULL;
		audio_stream = NULL;
		audio_stream_idx = 0;

		video_frame_count = 0;
		audio_frame_count = 0;
	}

	int output_video_frame(void* buffer, AVFrame* frame)
	{
		if (frame->width != width || frame->height != height || frame->format != pix_fmt)
		{
			/* To handle this change, one could call av_image_alloc again and
			 * decode the following frames into another rawvideo file. */
			Error("Error: Width, height and pixel format have to be "
				"constant in a rawvideo file, but the width, height or "
				"pixel format of the input video changed:\n"
				"old: width = %d, height = %d, format = %s\n"
				"new: width = %d, height = %d, format = %s\n",
				width, height, av_get_pix_fmt_name(pix_fmt),
				frame->width, frame->height,
				av_get_pix_fmt_name((AVPixelFormat)frame->format));
			return -1;
		}

		Info("video_frame n:%d coded_n:%d\n", video_frame_count++, frame->coded_picture_number);
		if (buffer)
		{
			//av_image_copy(video_src_data, video_src_linesize, (const uint8_t**)(frame->data), frame->linesize, pix_fmt, width, height);
			//int ret = sws_scale(sws_ctx, (const uint8_t* const*)video_src_data, video_src_linesize, 0, height, video_dst_data, video_dst_linesize);

			int ret = sws_scale(sws_ctx, frame->data, frame->linesize, 0, height, video_dst_data, video_dst_linesize);

			char buf[AV_ERROR_MAX_STRING_SIZE];
			if (ret < 0) {
				Error("Error submitting a packet for decoding (%s)\n", av_make_error_string(buf, AV_ERROR_MAX_STRING_SIZE, ret));
				return ret;
			}

			memcpy(buffer, video_dst_data[0], video_dst_bufsize);
		}
		return 0;
	}

	int output_audio_frame(void* buffer, AVFrame* frame)
	{
		char buf[AV_TS_MAX_STRING_SIZE];
		size_t unpadded_linesize = frame->nb_samples * av_get_bytes_per_sample((AVSampleFormat)frame->format);
		Info("audio_frame n:%d nb_samples:%d pts:%s\n", audio_frame_count++, frame->nb_samples, av_ts_make_time_string(buf, frame->pts, &audio_dec_ctx->time_base));

		if (buffer)
			memcpy(buffer, frame->extended_data[0], unpadded_linesize);

		return 0;
	}

	int decode_packet(void* buffer, AVCodecContext* dec, const AVPacket* pkt, int* hasNewFrame)
	{
		int ret = 0;
		char buf[AV_ERROR_MAX_STRING_SIZE];

		*hasNewFrame = 0;

		// submit the packet to the decoder
		ret = avcodec_send_packet(dec, pkt);
		if (ret < 0) {
			Error("Error submitting a packet for decoding (%s)\n", av_make_error_string(buf, AV_ERROR_MAX_STRING_SIZE, ret));
			return ret;
		}

		// get all the available frames from the decoder
		while (ret >= 0) {
			ret = avcodec_receive_frame(dec, frame);
			// those two return values are special and mean there is no output
			// frame available, but there were no errors during decoding
			if (ret == AVERROR_EOF || ret == AVERROR(EAGAIN))
				return 0;
			else if (ret < 0)
			{
				Error("Error during decoding (%s)\n", av_make_error_string(buf, AV_ERROR_MAX_STRING_SIZE, ret));
				return ret;
			}

			// write the frame data to output file
			if (dec->codec->type == AVMEDIA_TYPE_VIDEO)
			{
				*hasNewFrame = -1;
				ret = output_video_frame(buffer, frame);
				// av_frame_unref(frame);
				if (ret < 0)
					return ret;
				else
					return 0;
			}
			else
			{
				*hasNewFrame = -1;

				ret = output_audio_frame(buffer, frame);
				// av_frame_unref(frame);
				if (ret < 0)
					return ret;
				else
					return 0;
			}
		}

		return 0;
	}

	int open_codec_context(int* stream_idx,
		AVCodecContext** dec_ctx, AVFormatContext* fmt_ctx, enum AVMediaType type)
	{
		int ret, stream_index;
		AVStream* st;
		const AVCodec* dec = NULL;

		ret = av_find_best_stream(fmt_ctx, type, -1, -1, NULL, 0);
		if (ret < 0) {
			Error("Could not find %s stream in input file '%s'\n",
				av_get_media_type_string(type), src_filename);
			return ret;
		}
		else {
			stream_index = ret;
			st = fmt_ctx->streams[stream_index];

			/* find decoder for the stream */
			dec = avcodec_find_decoder(st->codecpar->codec_id);
			if (!dec) {
				Error("Failed to find %s codec\n",
					av_get_media_type_string(type));
				return AVERROR(EINVAL);
			}

			/* Allocate a codec context for the decoder */
			*dec_ctx = avcodec_alloc_context3(dec);
			if (!*dec_ctx) {
				Error("Failed to allocate the %s codec context\n",
					av_get_media_type_string(type));
				return AVERROR(ENOMEM);
			}

			/* Copy codec parameters from input stream to output codec context */
			if ((ret = avcodec_parameters_to_context(*dec_ctx, st->codecpar)) < 0) {
				Error("Failed to copy %s codec parameters to decoder context\n",
					av_get_media_type_string(type));
				return ret;
			}

			/* Init the decoders */
			if ((ret = avcodec_open2(*dec_ctx, dec, NULL)) < 0) {
				Error("Failed to open %s codec\n",
					av_get_media_type_string(type));
				return ret;
			}
			*stream_idx = stream_index;
		}

		return 0;
	}

	int get_format_from_sample_fmt(const char** fmt, enum AVSampleFormat sample_fmt)
	{
		int i;
		struct sample_fmt_entry {
			enum AVSampleFormat sample_fmt; const char* fmt_be, * fmt_le;
		} sample_fmt_entries[] = {
			{ AV_SAMPLE_FMT_U8,  "u8",    "u8"    },
			{ AV_SAMPLE_FMT_S16, "s16be", "s16le" },
			{ AV_SAMPLE_FMT_S32, "s32be", "s32le" },
			{ AV_SAMPLE_FMT_FLT, "f32be", "f32le" },
			{ AV_SAMPLE_FMT_DBL, "f64be", "f64le" },
		};
		*fmt = NULL;

		for (i = 0; i < FF_ARRAY_ELEMS(sample_fmt_entries); i++) {
			struct sample_fmt_entry* entry = &sample_fmt_entries[i];
			if (sample_fmt == entry->sample_fmt) {
				*fmt = AV_NE(entry->fmt_be, entry->fmt_le);
				return 0;
			}
		}

		Error("sample format %s is not supported as output format\n",
			av_get_sample_fmt_name(sample_fmt));
		return -1;
	}

	bool Initiate(const char* filename)
	{
#if (PLATFORM == GLFW)
		int ret = 0;
		src_filename = filename;

		/* open input file, and allocate format context */
		if (avformat_open_input(&fmt_ctx, src_filename.c_str(), NULL, NULL) < 0) {
			Error("Could not open source file %s\n", src_filename.c_str());
			exit(1);
		}

		/* retrieve stream information */
		if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
			Error("Could not find stream information\n");
			exit(1);
		}

		if (open_codec_context(&video_stream_idx, &video_dec_ctx, fmt_ctx, AVMEDIA_TYPE_VIDEO) >= 0) {
			video_stream = fmt_ctx->streams[video_stream_idx];

			// video_dst_file = fopen(video_dst_filename, "wb");
			// if (!video_dst_file) 
			// { 
				// Error("Could not open destination file %s\n", video_dst_filename);
			// 	ret = 1;
				// return false;
			// }

			/* allocate image where the decoded image will be put */
			width = video_dec_ctx->width;
			height = video_dec_ctx->height;
			pix_fmt = video_dec_ctx->pix_fmt;
			ret = av_image_alloc(video_dst_data, video_dst_linesize, width, height, AV_PIX_FMT_RGB24, 1);
			if (ret < 0)
			{
				Error("Could not allocate raw video buffer\n");
				return false;
			}
			video_dst_bufsize = ret;

			sws_ctx = sws_getContext(width, height, video_dec_ctx->pix_fmt, width, height, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
			if (!sws_ctx)
			{
				Error("Could not initialize the conversion context\n");
				ret = AVERROR(ENOMEM);
				return false;
			}
		}

		if (open_codec_context(&audio_stream_idx, &audio_dec_ctx, fmt_ctx, AVMEDIA_TYPE_AUDIO) >= 0) {
			audio_stream = fmt_ctx->streams[audio_stream_idx];
			// audio_dst_file = fopen(audio_dst_filename, "wb");
			// if (!audio_dst_file) {
				// Error("Could not open destination file %s\n", audio_dst_filename);
				// ret = 1;
				// return false;
			// }
		}

		/* dump input information to stderr */
		av_dump_format(fmt_ctx, 0, src_filename.c_str(), 0);

		if (!audio_stream && !video_stream) {
			Error("Could not find audio or video stream in the input, aborting\n");
			ret = 1;
			return false;
		}

		frame = av_frame_alloc();
		if (!frame) {
			Error("Could not allocate frame\n");
			ret = AVERROR(ENOMEM);
			return false;
		}

		pkt = av_packet_alloc();
		if (!pkt) {
			Error("Could not allocate packet\n");
			ret = AVERROR(ENOMEM);
			return false;
		}

		if (video_stream)
			Info("Demuxing video from file '%s'\n", src_filename);
		if (audio_stream)
			Info("Demuxing audio from file '%s'\n", src_filename);


#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	bool Update(void* buffer)
	{
#if (PLATFORM == GLFW)
		int ret;

		/* read frames from the file */
		while (av_read_frame(fmt_ctx, pkt) >= 0)
		{
			// check if the packet belongs to a stream we are interested in, otherwise
			// skip it
			int hasNewFrame = 0;

			if (pkt->stream_index == video_stream_idx)
				ret = decode_packet(buffer, video_dec_ctx, pkt, &hasNewFrame);
			else if (pkt->stream_index == audio_stream_idx)
				ret = decode_packet(buffer, audio_dec_ctx, pkt, &hasNewFrame);
			av_packet_unref(pkt);
			if (hasNewFrame)
				break;

			if (ret < 0)
				return false;
		}
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	bool Pause()
	{
#if (PLATFORM == GLFW)
		// !!!!!!!!! TODO, ¡ıº“√»
		// system pause, do something for microphone, if necessary
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
		return true;
	}

	void Resume()
	{
#if (PLATFORM == GLFW)
		// !!!!!!!!! TODO, ¡ıº“√»
		// system pause, do something for microphone, if necessary
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	void Terminate()
	{
#if (PLATFORM == GLFW)
		int ret;

		sws_freeContext(sws_ctx);

		int hasNewFrame = 0;
		/* flush the decoders */
		if (video_dec_ctx)
			decode_packet(NULL, video_dec_ctx, NULL, &hasNewFrame);
		if (audio_dec_ctx)
			decode_packet(NULL, audio_dec_ctx, NULL, &hasNewFrame);

		Info("Demuxing succeeded.\n");

		if (video_stream) {
			Info("Play the output video file with the command:\n"
				"ffplay -f rawvideo -pix_fmt %s -video_size %dx%d\n",
				av_get_pix_fmt_name(pix_fmt), width, height);
		}

		if (audio_stream) {
			enum AVSampleFormat sfmt = audio_dec_ctx->sample_fmt;
			// int n_channels = audio_dec_ctx->ch_layout.nb_channels;
			int n_channels = audio_dec_ctx->channels;
			const char* fmt;

			if (av_sample_fmt_is_planar(sfmt)) {
				const char* packed = av_get_sample_fmt_name(sfmt);
				Warning("Warning: the sample format the decoder produced is planar "
					"(%s). This example will output the first channel only.\n",
					packed ? packed : "?");
				sfmt = av_get_packed_sample_fmt(sfmt);
				n_channels = 1;
			}

			if ((ret = get_format_from_sample_fmt(&fmt, sfmt)) < 0)
				return;

			Info("Play the output audio file with the command:\n"
				"ffplay -f %s -ac %d -ar %d\n",
				fmt, n_channels, audio_dec_ctx->sample_rate);
		}

		avcodec_free_context(&video_dec_ctx);
		avcodec_free_context(&audio_dec_ctx);
		avformat_close_input(&fmt_ctx);
		// if (video_dst_file)
		// 	fclose(video_dst_file);
		// if (audio_dst_file)
		// 	fclose(audio_dst_file);
		av_packet_free(&pkt);
		av_frame_free(&frame);
		av_free(video_dst_data[0]);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	void* GetFrameData()
	{
#if (PLATFORM == GLFW)
		return nullptr;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	int GetWidth() const
	{
#if (PLATFORM == GLFW)
		return width;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	int GetHeight() const
	{
#if (PLATFORM == GLFW)
		return height;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
	}

	std::string src_filename;
	AVFrame* frame;
	AVPacket* pkt;

	AVFormatContext* fmt_ctx;
	AVCodecContext* video_dec_ctx;
	int width;
	int height;
	enum AVPixelFormat pix_fmt;
	AVStream* video_stream;
	int video_stream_idx;

	uint8_t* video_dst_data[4];
	int video_dst_linesize[4];
	int video_dst_bufsize;

	SwsContext* sws_ctx;

	AVCodecContext* audio_dec_ctx;
	AVStream* audio_stream;
	int audio_stream_idx;

	int video_frame_count;
	int audio_frame_count;
};

Platform::VideoDecoder::VideoDecoder()
	: impl(nullptr)
{
	impl = new VideoDecoder::Impl();
}

Platform::VideoDecoder::~VideoDecoder()
{
	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

bool Platform::VideoDecoder::Initiate(const char* filename)
{
	Assert(impl);

	return impl->Initiate(filename);
}

bool Platform::VideoDecoder::Update(void* buffer)
{
	Assert(impl);

	return impl->Update(buffer);
}

bool Platform::VideoDecoder::Pause()
{
	Assert(impl);

	return impl->Pause();
}

void Platform::VideoDecoder::Resume()
{
	Assert(impl);

	return impl->Resume();
}

void Platform::VideoDecoder::Terminate()
{
	Assert(impl);

	return impl->Terminate();
}

int Platform::VideoDecoder::GetWidth() const
{
	Assert(impl);

	return impl->GetWidth();
}

int Platform::VideoDecoder::GetHeight() const
{
	Assert(impl);

	return impl->GetHeight();
}

//////////////////////////////////////////////////////
#if (PLATFORM == GLFW)
#include <Windows.h>
#include <WinUser.h>
#include <glad\glad.h>
#include <GLFW\glfw3.h>
#include "imgui\imgui.h"
#include "imgui\imgui_impl_glfw.h"
#include "imgui\imgui_impl_opengl3.h"

void framebuffer_size_callback(void* win, int width_, int height_)
{
	GLFWwindow* window = (GLFWwindow*)win;
	width = width_;
	height = height_;
}

static void glfw_error_callback(int error_code, const char* description)
{
	Debug("GLFW Error: [%d] %s\n", error_code, description);
}

std::vector<int> glfwKeyCodes =
{
	GLFW_KEY_SPACE              ,
	GLFW_KEY_APOSTROPHE         ,
	GLFW_KEY_COMMA              ,
	GLFW_KEY_MINUS              ,
	GLFW_KEY_PERIOD             ,
	GLFW_KEY_SLASH              ,
	GLFW_KEY_0                  ,
	GLFW_KEY_1                  ,
	GLFW_KEY_2                  ,
	GLFW_KEY_3                  ,
	GLFW_KEY_4                  ,
	GLFW_KEY_5                  ,
	GLFW_KEY_6                  ,
	GLFW_KEY_7                  ,
	GLFW_KEY_8                  ,
	GLFW_KEY_9                  ,
	GLFW_KEY_SEMICOLON          ,
	GLFW_KEY_EQUAL              ,
	GLFW_KEY_A                  ,
	GLFW_KEY_B                  ,
	GLFW_KEY_C                  ,
	GLFW_KEY_D                  ,
	GLFW_KEY_E                  ,
	GLFW_KEY_F                  ,
	GLFW_KEY_G                  ,
	GLFW_KEY_H                  ,
	GLFW_KEY_I                  ,
	GLFW_KEY_J                  ,
	GLFW_KEY_K                  ,
	GLFW_KEY_L                  ,
	GLFW_KEY_M                  ,
	GLFW_KEY_N                  ,
	GLFW_KEY_O                  ,
	GLFW_KEY_P                  ,
	GLFW_KEY_Q                  ,
	GLFW_KEY_R                  ,
	GLFW_KEY_S                  ,
	GLFW_KEY_T                  ,
	GLFW_KEY_U                  ,
	GLFW_KEY_V                  ,
	GLFW_KEY_W                  ,
	GLFW_KEY_X                  ,
	GLFW_KEY_Y                  ,
	GLFW_KEY_Z                  ,
	GLFW_KEY_LEFT_BRACKET       ,
	GLFW_KEY_BACKSLASH          ,
	GLFW_KEY_RIGHT_BRACKET      ,
	GLFW_KEY_GRAVE_ACCENT       ,
	GLFW_KEY_WORLD_1            ,
	GLFW_KEY_WORLD_2            ,
	GLFW_KEY_ESCAPE             ,
	GLFW_KEY_ENTER              ,
	GLFW_KEY_TAB                ,
	GLFW_KEY_BACKSPACE          ,
	GLFW_KEY_INSERT             ,
	GLFW_KEY_DELETE             ,
	GLFW_KEY_RIGHT              ,
	GLFW_KEY_LEFT               ,
	GLFW_KEY_DOWN               ,
	GLFW_KEY_UP                 ,
	GLFW_KEY_PAGE_UP            ,
	GLFW_KEY_PAGE_DOWN          ,
	GLFW_KEY_HOME               ,
	GLFW_KEY_END                ,
	GLFW_KEY_CAPS_LOCK          ,
	GLFW_KEY_SCROLL_LOCK        ,
	GLFW_KEY_NUM_LOCK           ,
	GLFW_KEY_PRINT_SCREEN       ,
	GLFW_KEY_PAUSE              ,
	GLFW_KEY_F1                 ,
	GLFW_KEY_F2                 ,
	GLFW_KEY_F3                 ,
	GLFW_KEY_F4                 ,
	GLFW_KEY_F5                 ,
	GLFW_KEY_F6                 ,
	GLFW_KEY_F7                 ,
	GLFW_KEY_F8                 ,
	GLFW_KEY_F9                 ,
	GLFW_KEY_F10                ,
	GLFW_KEY_F11                ,
	GLFW_KEY_F12                ,
	GLFW_KEY_F13                ,
	GLFW_KEY_F14                ,
	GLFW_KEY_F15                ,
	GLFW_KEY_F16                ,
	GLFW_KEY_F17                ,
	GLFW_KEY_F18                ,
	GLFW_KEY_F19                ,
	GLFW_KEY_F20                ,
	GLFW_KEY_F21                ,
	GLFW_KEY_F22                ,
	GLFW_KEY_F23                ,
	GLFW_KEY_F24                ,
	GLFW_KEY_F25                ,
	GLFW_KEY_KP_0               ,
	GLFW_KEY_KP_1               ,
	GLFW_KEY_KP_2               ,
	GLFW_KEY_KP_3               ,
	GLFW_KEY_KP_4               ,
	GLFW_KEY_KP_5               ,
	GLFW_KEY_KP_6               ,
	GLFW_KEY_KP_7               ,
	GLFW_KEY_KP_8               ,
	GLFW_KEY_KP_9               ,
	GLFW_KEY_KP_DECIMAL         ,
	GLFW_KEY_KP_DIVIDE          ,
	GLFW_KEY_KP_MULTIPLY        ,
	GLFW_KEY_KP_SUBTRACT        ,
	GLFW_KEY_KP_ADD             ,
	GLFW_KEY_KP_ENTER           ,
	GLFW_KEY_KP_EQUAL           ,
	GLFW_KEY_LEFT_SHIFT         ,
	GLFW_KEY_LEFT_CONTROL       ,
	GLFW_KEY_LEFT_ALT           ,
	GLFW_KEY_LEFT_SUPER         ,
	GLFW_KEY_RIGHT_SHIFT        ,
	GLFW_KEY_RIGHT_CONTROL      ,
	GLFW_KEY_RIGHT_ALT          ,
	GLFW_KEY_RIGHT_SUPER        ,
	GLFW_KEY_MENU
};

std::map<int, Platform::KeyCode> glfwKeyCode2keyCodes =
{
	{	GLFW_KEY_SPACE              , Platform::KeyCode::Space			},
	{	GLFW_KEY_APOSTROPHE         , Platform::KeyCode::Quote			},
	{	GLFW_KEY_COMMA              , Platform::KeyCode::Comma			},
	{	GLFW_KEY_MINUS              , Platform::KeyCode::Minus			},
	{	GLFW_KEY_PERIOD             , Platform::KeyCode::Period			},
	{	GLFW_KEY_SLASH              , Platform::KeyCode::Slash			},
	{	GLFW_KEY_0                  , Platform::KeyCode::Alpha0			},
	{	GLFW_KEY_1                  , Platform::KeyCode::Alpha1			},
	{	GLFW_KEY_2                  , Platform::KeyCode::Alpha2			},
	{	GLFW_KEY_3                  , Platform::KeyCode::Alpha3			},
	{	GLFW_KEY_4                  , Platform::KeyCode::Alpha4			},
	{	GLFW_KEY_5                  , Platform::KeyCode::Alpha5			},
	{	GLFW_KEY_6                  , Platform::KeyCode::Alpha6			},
	{	GLFW_KEY_7                  , Platform::KeyCode::Alpha7			},
	{	GLFW_KEY_8                  , Platform::KeyCode::Alpha8			},
	{	GLFW_KEY_9                  , Platform::KeyCode::Alpha9			},
	{	GLFW_KEY_SEMICOLON          , Platform::KeyCode::Semicolon		},
	{	GLFW_KEY_EQUAL              , Platform::KeyCode::Equals			},
	{	GLFW_KEY_A                  , Platform::KeyCode::A				},
	{	GLFW_KEY_B                  , Platform::KeyCode::B				},
	{	GLFW_KEY_C                  , Platform::KeyCode::C				},
	{	GLFW_KEY_D                  , Platform::KeyCode::D				},
	{	GLFW_KEY_E                  , Platform::KeyCode::E				},
	{	GLFW_KEY_F                  , Platform::KeyCode::F				},
	{	GLFW_KEY_G                  , Platform::KeyCode::G				},
	{	GLFW_KEY_H                  , Platform::KeyCode::H				},
	{	GLFW_KEY_I                  , Platform::KeyCode::I				},
	{	GLFW_KEY_J                  , Platform::KeyCode::J				},
	{	GLFW_KEY_K                  , Platform::KeyCode::K				},
	{	GLFW_KEY_L                  , Platform::KeyCode::L				},
	{	GLFW_KEY_M                  , Platform::KeyCode::M				},
	{	GLFW_KEY_N                  , Platform::KeyCode::N				},
	{	GLFW_KEY_O                  , Platform::KeyCode::O				},
	{	GLFW_KEY_P                  , Platform::KeyCode::P				},
	{	GLFW_KEY_Q                  , Platform::KeyCode::Q				},
	{	GLFW_KEY_R                  , Platform::KeyCode::R				},
	{	GLFW_KEY_S                  , Platform::KeyCode::S				},
	{	GLFW_KEY_T                  , Platform::KeyCode::T				},
	{	GLFW_KEY_U                  , Platform::KeyCode::U				},
	{	GLFW_KEY_V                  , Platform::KeyCode::V				},
	{	GLFW_KEY_W                  , Platform::KeyCode::W				},
	{	GLFW_KEY_X                  , Platform::KeyCode::X				},
	{	GLFW_KEY_Y                  , Platform::KeyCode::Y				},
	{	GLFW_KEY_Z                  , Platform::KeyCode::Z				},
	{	GLFW_KEY_LEFT_BRACKET       , Platform::KeyCode::LeftBracket	},
	{	GLFW_KEY_BACKSLASH          , Platform::KeyCode::Backslash		},
	{	GLFW_KEY_RIGHT_BRACKET      , Platform::KeyCode::RightBracket	},
	{	GLFW_KEY_GRAVE_ACCENT       , Platform::KeyCode::BackQuote		},
	{	GLFW_KEY_WORLD_1            , Platform::KeyCode::None			},
	{	GLFW_KEY_WORLD_2            , Platform::KeyCode::None			},
	{	GLFW_KEY_ESCAPE             , Platform::KeyCode::Escape			},
	{	GLFW_KEY_ENTER              , Platform::KeyCode::KeypadEnter	},
	{	GLFW_KEY_TAB                , Platform::KeyCode::Tab			},
	{	GLFW_KEY_BACKSPACE          , Platform::KeyCode::Backspace		},
	{	GLFW_KEY_INSERT             , Platform::KeyCode::Insert			},
	{	GLFW_KEY_DELETE             , Platform::KeyCode::Delete			},
	{	GLFW_KEY_RIGHT              , Platform::KeyCode::RightArrow		},
	{	GLFW_KEY_LEFT               , Platform::KeyCode::LeftArrow		},
	{	GLFW_KEY_DOWN               , Platform::KeyCode::DownArrow		},
	{	GLFW_KEY_UP                 , Platform::KeyCode::UpArrow		},
	{	GLFW_KEY_PAGE_UP            , Platform::KeyCode::PageUp			},
	{	GLFW_KEY_PAGE_DOWN          , Platform::KeyCode::PageDown		},
	{	GLFW_KEY_HOME               , Platform::KeyCode::Home			},
	{	GLFW_KEY_END                , Platform::KeyCode::End			},
	{	GLFW_KEY_CAPS_LOCK          , Platform::KeyCode::CapsLock		},
	{	GLFW_KEY_SCROLL_LOCK        , Platform::KeyCode::ScrollLock		},
	{	GLFW_KEY_NUM_LOCK           , Platform::KeyCode::Numlock		},
	{	GLFW_KEY_PRINT_SCREEN       , Platform::KeyCode::Print			},
	{	GLFW_KEY_PAUSE              , Platform::KeyCode::Pause			},
	{	GLFW_KEY_F1                 , Platform::KeyCode::F1				},
	{	GLFW_KEY_F2                 , Platform::KeyCode::F2				},
	{	GLFW_KEY_F3                 , Platform::KeyCode::F3				},
	{	GLFW_KEY_F4                 , Platform::KeyCode::F4				},
	{	GLFW_KEY_F5                 , Platform::KeyCode::F5				},
	{	GLFW_KEY_F6                 , Platform::KeyCode::F6				},
	{	GLFW_KEY_F7                 , Platform::KeyCode::F7				},
	{	GLFW_KEY_F8                 , Platform::KeyCode::F8				},
	{	GLFW_KEY_F9                 , Platform::KeyCode::F9				},
	{	GLFW_KEY_F10                , Platform::KeyCode::F10			},
	{	GLFW_KEY_F11                , Platform::KeyCode::F11			},
	{	GLFW_KEY_F12                , Platform::KeyCode::F12			},
	{	GLFW_KEY_F13                , Platform::KeyCode::F13			},
	{	GLFW_KEY_F14                , Platform::KeyCode::F14			},
	{	GLFW_KEY_F15                , Platform::KeyCode::F15			},
	{	GLFW_KEY_F16                , Platform::KeyCode::F16			},
	{	GLFW_KEY_F17                , Platform::KeyCode::F17			},
	{	GLFW_KEY_F18                , Platform::KeyCode::F18			},
	{	GLFW_KEY_F19                , Platform::KeyCode::F19			},
	{	GLFW_KEY_F20                , Platform::KeyCode::F20			},
	{	GLFW_KEY_F21                , Platform::KeyCode::F21			},
	{	GLFW_KEY_F22                , Platform::KeyCode::F22			},
	{	GLFW_KEY_F23                , Platform::KeyCode::F23			},
	{	GLFW_KEY_F24                , Platform::KeyCode::F24			},
	{	GLFW_KEY_F25                , Platform::KeyCode::F25			},
	{	GLFW_KEY_KP_0               , Platform::KeyCode::Keypad0		},
	{	GLFW_KEY_KP_1               , Platform::KeyCode::Keypad1		},
	{	GLFW_KEY_KP_2               , Platform::KeyCode::Keypad2		},
	{	GLFW_KEY_KP_3               , Platform::KeyCode::Keypad3		},
	{	GLFW_KEY_KP_4               , Platform::KeyCode::Keypad4		},
	{	GLFW_KEY_KP_5               , Platform::KeyCode::Keypad5		},
	{	GLFW_KEY_KP_6               , Platform::KeyCode::Keypad6		},
	{	GLFW_KEY_KP_7               , Platform::KeyCode::Keypad7		},
	{	GLFW_KEY_KP_8               , Platform::KeyCode::Keypad8		},
	{	GLFW_KEY_KP_9               , Platform::KeyCode::Keypad9		},
	{	GLFW_KEY_KP_DECIMAL         , Platform::KeyCode::KeypadPeriod	},
	{	GLFW_KEY_KP_DIVIDE          , Platform::KeyCode::KeypadDivide	},
	{	GLFW_KEY_KP_MULTIPLY        , Platform::KeyCode::KeypadMultiply	},
	{	GLFW_KEY_KP_SUBTRACT        , Platform::KeyCode::KeypadMinus	},
	{	GLFW_KEY_KP_ADD             , Platform::KeyCode::KeypadPlus		},
	{	GLFW_KEY_KP_ENTER           , Platform::KeyCode::KeypadEnter	},
	{	GLFW_KEY_KP_EQUAL           , Platform::KeyCode::KeypadEquals	},
	{	GLFW_KEY_LEFT_SHIFT         , Platform::KeyCode::LeftShift		},
	{	GLFW_KEY_LEFT_CONTROL       , Platform::KeyCode::LeftControl	},
	{	GLFW_KEY_LEFT_ALT           , Platform::KeyCode::LeftAlt		},
	{	GLFW_KEY_LEFT_SUPER         , Platform::KeyCode::LeftWindows	},
	{	GLFW_KEY_RIGHT_SHIFT        , Platform::KeyCode::RightShift		},
	{	GLFW_KEY_RIGHT_CONTROL      , Platform::KeyCode::RightControl	},
	{	GLFW_KEY_RIGHT_ALT          , Platform::KeyCode::RightAlt		},
	{	GLFW_KEY_RIGHT_SUPER        , Platform::KeyCode::RightWindows	},
	{	GLFW_KEY_MENU               , Platform::KeyCode::Menu			}
};


std::vector<int> glfwMouseKeyCodes =
{
	GLFW_MOUSE_BUTTON_1,
	GLFW_MOUSE_BUTTON_2,
	GLFW_MOUSE_BUTTON_3,
	GLFW_MOUSE_BUTTON_4,
	GLFW_MOUSE_BUTTON_5,
	GLFW_MOUSE_BUTTON_6,
	GLFW_MOUSE_BUTTON_7,
	GLFW_MOUSE_BUTTON_8,
};

std::map<int, Platform::KeyCode> glfwMouseKeyCode2keyCodes =
{
	{	GLFW_MOUSE_BUTTON_1				, Platform::KeyCode::Mouse0		},
	{	GLFW_MOUSE_BUTTON_2				, Platform::KeyCode::Mouse1		},
	{	GLFW_MOUSE_BUTTON_3             , Platform::KeyCode::Mouse2		},
	{	GLFW_MOUSE_BUTTON_4             , Platform::KeyCode::Mouse3		},
	{	GLFW_MOUSE_BUTTON_5             , Platform::KeyCode::Mouse4		},
	{	GLFW_MOUSE_BUTTON_6             , Platform::KeyCode::Mouse5		},
	{	GLFW_MOUSE_BUTTON_7             , Platform::KeyCode::Mouse6		},
	{	GLFW_MOUSE_BUTTON_8             , Platform::KeyCode::Mouse7		},
};

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
	Platform::InputEvent e;

	if (action == 1)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 1;
		e.mods = mods;
	}
	if (action == 0)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 2;
		e.mods = mods;
	}

	/*
	auto itr = glfwKeyCode2keyCodes.find(key);
	if (itr != glfwKeyCode2keyCodes.end())
	{
		int idx = (int)itr->second;

		oldkeystates[idx] = keystates[idx];

		if (action == GLFW_PRESS)
			keystates[idx] = 0x01;
		else if (action == GLFW_RELEASE)
			keystates[idx] = 0x02;
		else //if(action == GLFW_REPEAT)
			keystates[idx] = 0x04;
	}
	*/
	// Debug("%d %d %d %d\n", key, scancode, action, mods);
}

std::vector<Platform::KeyCode> mouseButtonCodeMaps =
{
	Platform::KeyCode::Mouse0,
	Platform::KeyCode::Mouse1,
	Platform::KeyCode::Mouse2,
	Platform::KeyCode::Mouse3,
	Platform::KeyCode::Mouse4,
	Platform::KeyCode::Mouse5,
	Platform::KeyCode::Mouse6,
};

std::vector<Platform::InputEvent> inputEvents;

void mouse_button_callback(GLFWwindow* window, int key, int action, int mods)
{
	Platform::InputEvent e;

	if (action == 1)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 1;
		e.mods = mods;
	}
	if (action == 0)
	{
		e.x = 0;
		e.y = 0;
		e.keyCode = key;
		e.scanCode = key;
		e.action = 2;
		e.mods = mods;
	}
	/*
if (button < mouseButtonCodeMaps.size())
{
	int idx = (int)mouseButtonCodeMaps[button];

	oldkeystates[idx] = keystates[idx];

	if (action == GLFW_PRESS)
		keystates[idx] = 0x01;
	else// if (action == GLFW_RELEASE)
		keystates[idx] = 0x02;
}
*/
// Debug("%d %d %d", button, action, mods);
}

void joystick_callback(int jid, int event)
{
	if (event == GLFW_CONNECTED)
	{
		joyStickConnected[jid] = true;
	}
	else if (event == GLFW_DISCONNECTED)
	{
		joyStickConnected[jid] = false;
	}
}

void drop_callback(GLFWwindow* window, int count, const char** paths)
{
	dropPaths.resize(count);
	for (int i = 0; i < count; i++)
	{
		dropPaths[i] = paths[i];
	}
}

#endif


bool Platform::Instantiate(int width_, int height_, const char* appName_, const char* initialScene_)
{
#if (PLATFORM == GLFW)
	currentTime = glfwGetTime();
	deltaTime = 0;

	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
	appName = appName_;
	initialScene = initialScene_;
	width = width_;
	height = height_;
	handle = glfwCreateWindow(width, height, appName.c_str(), NULL, NULL);
	if (handle == nullptr)
	{
		Debug("Failed to create GLFW window\n");
		glfwTerminate();
		return false;
	}

	glfwMakeContextCurrent((GLFWwindow*)handle);
	glfwSetErrorCallback(glfw_error_callback);
	glfwSetFramebufferSizeCallback((GLFWwindow*)handle, (void (*)(GLFWwindow*, int, int))(framebuffer_size_callback));

	glfwSetKeyCallback((GLFWwindow*)handle, key_callback);
	glfwSetMouseButtonCallback((GLFWwindow*)handle, mouse_button_callback);

	glfwSetJoystickCallback(joystick_callback);
	glfwSetDropCallback((GLFWwindow*)handle, drop_callback);

	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
	{
		Debug("Failed to initialize GLAD\n");
		return false;
	}

	// Setup Dear ImGui context
	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io;
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

	// Setup Dear ImGui style
	ImGui::StyleColorsDark();
	//ImGui::StyleColorsClassic();

	// Setup Platform/Renderer bindings
	ImGui_ImplGlfw_InitForOpenGL((GLFWwindow*)handle, true);
	ImGui_ImplOpenGL3_Init();

	// Load Fonts
	// - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
	// - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
	// - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
	// - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
	// - Read 'docs/FONTS.md' for more instructions and details.
	// - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
	//io.Fonts->AddFontDefault();
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
	//io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
	//ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
	//IM_ASSERT(font != NULL);

	if (!InitiateFFMPEG())
		return false;

#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif


	return true;
}

bool Platform::PreUpdate()
{
#if (PLATFORM == GLFW)
	///////////////////////////////////////////////////
	// time
	double now = glfwGetTime();
	deltaTime = now - currentTime;
	currentTime = now;

	///////////////////////////////////////////////////
	glfwPollEvents();

	///////////////////////////////////////////////////
	// Button
	for (int i = 0; i < (int)Platform::KeyCode::Count; i++)
		oldkeystates[i] = keystates[i];

	for (int i = 0; i < glfwKeyCodes.size(); i++)
	{
		int glfwKey = glfwKeyCodes[i];
		Platform::KeyCode code = glfwKeyCode2keyCodes[glfwKey];

		int keyState = glfwGetKey((GLFWwindow*)handle, glfwKey);

		if (keyState == GLFW_PRESS)
		{
			keystates[int(code)] = true;

			if (glfwKey == GLFW_KEY_LEFT_SHIFT)
			{
				int a = 1;
			}
		}
		else if (keyState == GLFW_RELEASE)
		{
			keystates[int(code)] = false;
		}
	}

	for (int i = 0; i < glfwMouseKeyCodes.size(); i++)
	{
		int glfwKey = glfwMouseKeyCodes[i];
		Platform::KeyCode code = glfwMouseKeyCode2keyCodes[glfwKey];

		int keyState = glfwGetMouseButton((GLFWwindow*)handle, glfwKey);
		if (keyState == GLFW_PRESS)
			keystates[int(code)] = true;
		else if (keyState == GLFW_RELEASE)
			keystates[int(code)] = false;
	}

	///////////////////////////////////////////////////
	// Mouse Movement
	double newMouseX = 0;
	double newMouseY = 0;
	glfwGetCursorPos((GLFWwindow*)handle, &newMouseX, &newMouseY);
	newMouseY = GetHeight() - 1 - newMouseY;
	mouse.dx = (float)newMouseX - mouse.x;
	mouse.dy = (float)newMouseY - mouse.y;
	mouse.x = (float)newMouseX;
	mouse.y = (float)newMouseY;
	// Debug("%f %f %f %f\n", mouse.x, mouse.y, mouse.dx, mouse.dy);

	///////////////////////////////////////////////////
	// JoyStick
	for (int i = GLFW_JOYSTICK_1; i <= GLFW_JOYSTICK_16 && i < JOYSTICK_COUNT; i++)
	{
		if (joyStickConnected[i])
		{
			const char* name = glfwGetJoystickName(i);

			//std::cout << name << ":";

			int count;
			const float* axes = glfwGetJoystickAxes(i, &count);
			for (int j = 0; j < count && j < JOYSTICK_AXE_COUNT; j++)
			{
				joySticks[i].axis[j] = axes[j];
				//std::cout << ((fabs(axes[j]) < 0.0001) ? 0 :axes[j]) << " ,";
			}

			const unsigned char* buttons = glfwGetJoystickButtons(i, &count);
			for (int j = 0; j < count && j < JOYSTICK_BUTTON_COUNT; j++)
			{
				joySticks[i].button[j] = buttons[j];
				//std::cout << (buttons[j] ? '1' : '0');
			}

			//std::cout << "\n";
		}
	}

	///////////////////////////////////////////////////
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplGlfw_NewFrame();
	ImGui::NewFrame();
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

bool Platform::PostUpdate()
{
#if (PLATFORM == GLFW)
	// Rendering
	ImGui::Render();

	// glGetIntegerv(GL_CURRENT_PROGRAM, &last_program);
	// glUseProgram(0);
	ImDrawData* drawData = ImGui::GetDrawData();
	if (drawData)
		ImGui_ImplOpenGL3_RenderDrawData(drawData);
	//glUseProgram(last_program);

	glfwSwapInterval(0);
	glfwMakeContextCurrent((GLFWwindow*)handle);
	glfwSwapBuffers((GLFWwindow*)handle);

	totalFrameCounter++;
	sceneFrameCounter++;
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

bool Platform::Pause()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif

	return true;
}

void Platform::Resume()
{
#if (PLATFORM == GLFW)
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::Terminate()
{
#if (PLATFORM == GLFW)
	TerminateFFMPEG();

	glfwDestroyWindow((GLFWwindow*)handle);
	glfwTerminate();
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void* Platform::GetHandle()
{
	return handle;
}

const std::string& Platform::GetAppName()
{
	return appName;
}

const std::string& Platform::GetInitialScene()
{
	return initialScene;
}

int Platform::GetWidth()
{
	return width;
}

int Platform::GetHeight()
{
	return height;
}

double Platform::GetTime()
{
	return currentTime;
}

double Platform::GetDeltaTime()
{
	return deltaTime;
}

int Platform::GetTotalFrameCounter()
{
	return totalFrameCounter;
}

int Platform::GetSceneFrameCounter()
{
	return sceneFrameCounter;
}

void Platform::ResetSceneFrameCounter()
{
	sceneFrameCounter = -1;
}

int Platform::GetKeyCount()
{
	return (int)Platform::KeyCode::Count;
}

bool Platform::GetKeyDown(Platform::KeyCode code)
{
	return !oldkeystates[(int)code] && keystates[(int)code];
}

bool Platform::GetKeyUp(Platform::KeyCode code)
{
	return oldkeystates[(int)code] && !keystates[(int)code];
}

bool Platform::GetKeyHold(Platform::KeyCode code)
{
	return oldkeystates[(int)code] && keystates[(int)code];
}

bool Platform::GetKey(Platform::KeyCode code)
{
	return keystates[(int)code];
}

Platform::Mouse Platform::GetMouse()
{
	return mouse;
}

float Platform::GetMouseX()
{
	return mouse.x;
}

float Platform::GetMouseY()
{
	return mouse.y;
}

float Platform::GetMouseDX()
{
	return mouse.dx;
}

float Platform::GetMouseDY()
{
	return mouse.dy;
}

Platform::SystemTime Platform::GetSystemTime()
{
#if (PLATFORM == GLFW)
	Platform::SystemTime systemTime;

	SYSTEMTIME lt = { 0 };
	GetLocalTime(&lt);

	systemTime.wYear = lt.wYear;
	systemTime.wMonth = lt.wMonth;
	systemTime.wDayOfWeek = lt.wDayOfWeek;
	systemTime.wDay = lt.wDay;
	systemTime.wHour = lt.wHour;
	systemTime.wMinute = lt.wMinute;
	systemTime.wSecond = lt.wSecond;
	systemTime.wMilliseconds = lt.wMilliseconds;

	return systemTime;
#else
#endif
}

Platform::Microphone* Platform::CreateMicrophone(int id)
{
	return new Platform::Microphone();
}

void Platform::ReleaseMicrophone(Platform::Microphone* microphone)
{
	if (microphone)
	{
		delete microphone;
		microphone = nullptr;
	}
}

Platform::WebCam* Platform::CreateWebCam(int id)
{
	return new Platform::WebCam();
}

void Platform::ReleaseWebCam(Platform::WebCam* webCam)
{
	if (webCam)
	{
		delete webCam;
		webCam = nullptr;
	}
}

Platform::VideoDecoder* Platform::CreateVideoDecoder()
{
	return new Platform::VideoDecoder();
}

void Platform::ReleaseVideoDecoder(Platform::VideoDecoder* videoDecoder)
{
	if (videoDecoder)
	{
		delete videoDecoder;
		videoDecoder = nullptr;
	}
}

void Platform::EnableCursor()
{
#if (PLATFORM == GLFW)
	glfwSetInputMode((GLFWwindow*)handle, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

void Platform::DisableCursor()
{
#if (PLATFORM == GLFW)
	glfwSetInputMode((GLFWwindow*)handle, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

bool Platform::IsCursorEnabled()
{
#if (PLATFORM == GLFW)
	return glfwGetInputMode((GLFWwindow*)handle, GLFW_CURSOR);
#elif (PLATFORM == MACOSX)
#elif (PLATFORM == LINUX)
#elif (PLATFORM == ANDROID)
#elif (PLATFORM == IOS)
#elif (PLATFORM == PS4)
#elif (PLATFORM == XBOXONE)
#elif (PLATFORM == NSWITCH)
#elif (PLATFORM == PS5)
#elif (PLATFORM == XSX)
#else
#pragma error("unsupported PLATFORM type. Please make sure PLATFORM is defined")
#endif
}

bool Platform::IsJoyStickConnected(int i)
{
	return joyStickConnected[i];
}

Platform::JoyStick Platform::GetJoyStick(int i)
{
	return joySticks[i];
}

const std::vector<std::string>& Platform::GetJoystickNames()
{
	return joyStickNames;
}

void Platform::GetDropPaths(std::vector<std::string>& dropPaths_)
{
	dropPaths_ = dropPaths;
}

bool Platform::hasDropPath()
{
	return dropPaths.size() != 0;
}

const char* Platform::GetClipBoardString()
{
	return glfwGetClipboardString(nullptr);
}

void Platform::SetClipBoard(const char* s)
{
	glfwSetClipboardString(nullptr, s);
}

void Platform::SetArgument(std::vector<std::string>& args)
{
	arguments = args;
}

std::vector<std::string>& Platform::GetArgument()
{
	return arguments;
}

void Platform::QuitApp()
{
	glfwSetWindowShouldClose((GLFWwindow*)handle, true);
}

bool Platform::ShouldAppQuit()
{
	return glfwWindowShouldClose((GLFWwindow*)handle);
}

///////////////////////////////////////////
#define FORMAT_BUFFER_SIZE 32768

const char* Format(const char* format, ...)
{
	static char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	return (const char*)buffer;
}

void Verbose(const char* format, ...)
{
	return;
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Verbose: %s", buffer);
}

void Debug(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Debug: %s", buffer);
}

void Info(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Info: %s", buffer);
}

void Warning(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Warning: %s", buffer);
}

void Error(const char* format, ...)
{
	char buffer[FORMAT_BUFFER_SIZE];

	va_list aptr;
	int ret;

	va_start(aptr, format);
	ret = vsprintf(buffer, format, aptr);
	va_end(aptr);

	printf("Error: %s", buffer);
}

void MemSet(void* dst, int val, int size)
{
	::memset(dst, val, size);
}

void MemCpy(void* dst, const void* src, int size)
{
	::memcpy(dst, src, size);
}

int MemCmp(const void* s1, const void* s2, int size)
{
	return ::memcmp(s1, s2, size);
}