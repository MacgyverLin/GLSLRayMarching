#ifndef _FlipFrameBuffer_h_
#define _FlipFrameBuffer_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class FlipFrameBuffer : public FrameBuffer
{
public:
	FlipFrameBuffer()
		: FrameBuffer()
		, current(0)
	{
	}

	virtual ~FlipFrameBuffer()
	{
	}

	virtual void Flip()
	{
		current = 1 - current;
	}

	virtual Texture* GetCurrentTexture() = 0;
protected:
	int GetCurrent()
	{
		return current;
	}
private:
	int current;
};

class BackBuffer : public FlipFrameBuffer
{
public:
	BackBuffer()
		: FlipFrameBuffer()
	{
	}

	virtual ~BackBuffer()
	{
	}

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
	{
		return true;
	}

	Texture* GetCurrentTexture()
	{
		return nullptr;
	}

	virtual void Terminate()
	{
		return FlipFrameBuffer::Terminate();
	}

	virtual void Flip()
	{
		FlipFrameBuffer::Flip();
	}
private:
};

class FlipTexture2DFrameBuffer : public FlipFrameBuffer
{
public:
	FlipTexture2DFrameBuffer()
		: FlipFrameBuffer()
	{
	}

	virtual ~FlipTexture2DFrameBuffer()
	{
	}

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
	{
		if (!FlipFrameBuffer::Initiate())
			return false;

		if (!texture[0].Initiate(width, height, nrComponents, dynamicRange_, nullptr))
			return false;

		if (!texture[1].Initiate(width, height, nrComponents, dynamicRange_, nullptr))
			return false;

		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, &texture[0]);
		return true;
	}

	virtual void Terminate()
	{
		for (int i = 0; i < 2; i++)
			texture[i].Terminate();

		return FlipFrameBuffer::Terminate();
	}

	Texture* GetCurrentTexture()
	{
		return &texture[1 - GetCurrent()];
	}

	virtual void Flip()
	{
		FlipFrameBuffer::Flip();

		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, &texture[GetCurrent()]);
	}
private:
	Texture2D texture[2];
};

class FlipTextureCubeMapFrameBuffer : public FlipFrameBuffer
{
public:
	FlipTextureCubeMapFrameBuffer()
		: FlipFrameBuffer()
	{
	}

	virtual ~FlipTextureCubeMapFrameBuffer()
	{
	}

	virtual bool Initiate(unsigned int size, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
	{
		if (!FlipFrameBuffer::Initiate())
			return false;

		if (!texture[0].Initiate(size, nrComponents, dynamicRange_, nullptr))
			return false;

		if (!texture[1].Initiate(size, nrComponents, dynamicRange_, nullptr))
			return false;

		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, &texture[0]);
		return true;
	}

	virtual void Terminate()
	{
		for (int i = 0; i < 2; i++)
			texture[i].Terminate();

		return FlipFrameBuffer::Terminate();
	}

	Texture* GetCurrentTexture()
	{
		return &texture[1 - GetCurrent()];
	}

	virtual void Flip()
	{
		FlipFrameBuffer::Flip();

		//Invalidate();
		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, &texture[GetCurrent()]);
	}
private:
	TextureCubeMap texture[2];
};

#endif