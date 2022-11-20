#ifndef _VideoTexture_h_
#define _VideoTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class VideoTexture : public DynamicTexture2D
{
public:
	VideoTexture()
		: DynamicTexture2D()
		, buffer(0)
		, decoder(nullptr)
	{
	}

	virtual ~VideoTexture()
	{
	}

	bool Initiate(const std::string& url, bool vflip_)
	{
		decoder = Platform::CreateVideoDecoder();
		assert(decoder);
		
		if (!decoder->Initiate(url.c_str()))
			return false;

		buffer.resize(decoder->GetWidth() * decoder->GetHeight() * 3);
		if (!DynamicTexture2D::Initiate(decoder->GetWidth(), decoder->GetHeight(), 3, Texture::DynamicRange::LOW, &buffer[0]))
			return false;

		return true;
	}

	void Terminate()
	{
		DynamicTexture2D::Terminate();

		if (decoder)
		{
			decoder->Terminate();

			Platform::ReleaseVideoDecoder(decoder);
		}
	}

	virtual void Tick(float dt) override
	{
		if (decoder)
		{
			decoder->Update(&buffer[0]);

			DynamicTexture2D::Update(&buffer[0]);
		}
	}
private:
private:
	Platform::VideoDecoder* decoder;
	std::vector<char> buffer;
};

#endif