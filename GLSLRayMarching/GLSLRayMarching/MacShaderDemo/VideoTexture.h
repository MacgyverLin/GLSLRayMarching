#ifndef _VideoTexture_h_
#define _VideoTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class VideoTexture : public Texture2D
{
public:
	VideoTexture()
		: Texture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~VideoTexture()
	{
	}

	bool Initiate(const std::string& url, bool vflip_)
	{
		return Texture2D::Initiate(1280, 720, 4, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Update()
	{
		Texture2D::Update(&buffer[0]);
	}

	virtual void Tick() override
	{
		// !!!!!!!!! TODO, ¡ıº“√» 
	}
private:
private:
	std::vector<char> buffer;
};


#endif