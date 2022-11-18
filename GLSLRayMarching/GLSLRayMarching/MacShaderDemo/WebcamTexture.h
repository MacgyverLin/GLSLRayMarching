#ifndef _WebcamTexture_h_
#define _WebcamTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class WebcamTexture : public DynamicTexture2D
{
public:
	WebcamTexture()
		: DynamicTexture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~WebcamTexture()
	{
	}

	bool Initiate(bool flip_)
	{
		return Texture2D::Initiate(512, 2, 1, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Tick(float dt) override
	{
		// !!!!!!!!! TODO, ¡ıº“√» 
		// Webcam.GetData();

		DynamicTexture2D::Update(&buffer[0]);
	}
private:
private:
	std::vector<char> buffer;
};

#endif