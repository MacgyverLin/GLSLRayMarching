#ifndef _MicrophoneTexture_h_
#define _MicrophoneTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class MicrophoneTexture : public Texture2D
{
public:
	MicrophoneTexture()
		: Texture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~MicrophoneTexture()
	{
	}

	bool Initiate()
	{
		return Texture2D::Initiate(512, 2, 1, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Update()
	{
		Texture2D::Update(&buffer[0]);
	}

	virtual void Tick() override
	{
		// !!!!!!!!! TODO, ¡ıº“√» 
		// Platform::GetMicroPhone().GetData();
	}
private:
private:
	std::vector<char> buffer;
};

#endif