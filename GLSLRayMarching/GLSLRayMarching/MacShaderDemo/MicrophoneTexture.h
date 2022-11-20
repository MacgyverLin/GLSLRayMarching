#ifndef _MicrophoneTexture_h_
#define _MicrophoneTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"
#include "FFT.hpp"

class MicrophoneTexture : public DynamicTexture2D
{
public:
	MicrophoneTexture()
		: DynamicTexture2D()
		, maxBuffer(0)
		, microphone(nullptr)
	{
	}

	virtual ~MicrophoneTexture()
	{
	}

	bool Initiate()
	{
		microphone = Platform::CreateMicrophone(0);
		assert(microphone);

		if (!microphone->Initiate())
			return false;

		maxBuffer.resize(microphone->GetSampleCount() * microphone->GetChannelCount());
		if (!DynamicTexture2D::Initiate(microphone->GetSampleCount(), microphone->GetChannelCount(), 1, Texture::DynamicRange::HIGH, nullptr))
			return false;

		return true;
	}

	void Terminate()
	{
		DynamicTexture2D::Terminate();

		if (microphone)
		{
			microphone->Terminate();

			Platform::ReleaseMicrophone(microphone);
		}
	}

	virtual void Tick(float dt) override
	{
		if (microphone)
		{
			std::vector<float> buffer(microphone->GetSampleCount() * microphone->GetChannelCount());
			microphone->Update(buffer);

			UpdateMaxBuffer(buffer);

			DynamicTexture2D::Update(&maxBuffer[0]);
		}
	}
private:
	void UpdateMaxBuffer(const std::vector<float>& buffer)
	{
		const char* error_description;
		std::vector<complex_type> fftBuffer(buffer.size());
		simple_fft::FFT(buffer, fftBuffer, buffer.size(), error_description);

		for (int i = 0; i < buffer.size(); i++)
		{
			float d = Math::Sqrt(fftBuffer[i].real() * fftBuffer[i].real() + fftBuffer[i].imag() * fftBuffer[i].imag())*0.02;

			if (d > maxBuffer[i])
				maxBuffer[i] = d;
			else
				maxBuffer[i] *= 0.99;
		}
	}
private:
	Platform::Microphone* microphone;
	std::vector<float> maxBuffer;
};

#endif