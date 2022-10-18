#ifndef _FlipFrameBuffer_h_
#define _FlipFrameBuffer_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class BackBuffer : public TextureFrameBuffer2D
{
public:
	BackBuffer()
		: TextureFrameBuffer2D()
	{
	}

	virtual ~BackBuffer()
	{
	}

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
	{
		if (!TextureFrameBuffer2D::Initiate(width, height, nrComponents, dynamicRange_))
			return false;

		return true;
	}

	virtual void Terminate()
	{
		TextureFrameBuffer2D::Terminate();
	}

	virtual Texture2D* GetTexture()
	{
		return nullptr;
	}

	virtual const Texture2D* GetTexture() const
	{
		return nullptr;
	}

private:
};

#endif