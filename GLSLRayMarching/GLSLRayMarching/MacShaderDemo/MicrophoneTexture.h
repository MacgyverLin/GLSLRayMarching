#ifndef _MicrophoneTexture_h_
#define _MicrophoneTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class MicrophoneTexture : public DynamicTexture2D
{
public:
	MicrophoneTexture()
		: DynamicTexture2D()
		, buffer(0)
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

		buffer.resize(1024 * 2);
		if (!Texture2D::Initiate(1024, 2, 1, Texture::DynamicRange::HIGH, &buffer[0]))
			return false;

		return true;
	}

	void Terminate()
	{
		Texture2D::Terminate();

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
			microphone->Update(buffer);

			DynamicTexture2D::Update(&buffer[0]);
		}
	}
private:
private:
	Platform::Microphone* microphone;
	std::vector<float> buffer;
};

#endif