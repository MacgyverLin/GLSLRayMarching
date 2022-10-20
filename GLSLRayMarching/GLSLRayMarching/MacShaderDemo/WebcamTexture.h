#ifndef _WebcamTexture_h_
#define _WebcamTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class WebcamTexture : public Texture2D
{
public:
	WebcamTexture()
		: Texture2D()
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

	virtual void UpdateData()
	{
		// !!!!!!!!! TODO, ¡ıº“√» 
		// Webcam.GetData();

		Texture2D::Update(&buffer[0]);
	}
private:
private:
	std::vector<char> buffer;
};

#endif