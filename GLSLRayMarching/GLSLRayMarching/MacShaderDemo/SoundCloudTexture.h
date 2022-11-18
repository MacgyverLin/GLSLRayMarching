#ifndef _SoundCloudTexture_h_
#define _SoundCloudTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

// Sound from Web
class SoundCloudTexture : public DynamicTexture2D
{
public:
	SoundCloudTexture()
		: DynamicTexture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~SoundCloudTexture()
	{
	}

	bool Initiate(const std::string& url, bool vflip_)
	{
		return Texture2D::Initiate(512, 1, 1, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Tick(float dt) override
	{
		DynamicTexture2D::Update(&buffer[0]);
	}
private:
private:
	std::vector<char> buffer;
};

#endif