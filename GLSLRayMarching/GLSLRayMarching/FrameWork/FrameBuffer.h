#ifndef _FrameBuffer_h_
#define _FrameBuffer_h_

#include "Platform.h"

#include "Texture.h"
#include "Rect2.h"
#include "ColorRGBA.h"

class FrameBufferImpl;

class FrameBuffer
{
public:
	enum class Type
	{
		Texture1D = 0,
		Texture2D,
		Texture3D,
		TextureCubemap,
		Texture1DArray,
		Texture2DArray,
		TextureCubeMapArray,
	};

	enum class ColorAttachment
	{
		COLOR_ATTACHMENT0 = 0,
		COLOR_ATTACHMENT1,
		COLOR_ATTACHMENT2,
		COLOR_ATTACHMENT3,
		COLOR_ATTACHMENT4,
		COLOR_ATTACHMENT5,
		COLOR_ATTACHMENT6,
		COLOR_ATTACHMENT7,
		COLOR_ATTACHMENT8,
		COLOR_ATTACHMENT9,
		COLOR_ATTACHMENT10,
		COLOR_ATTACHMENT11,
		COLOR_ATTACHMENT12,
		COLOR_ATTACHMENT13,
		COLOR_ATTACHMENT14,
		COLOR_ATTACHMENT15,
		COLOR_ATTACHMENT16,
		COLOR_ATTACHMENT17,
		COLOR_ATTACHMENT18,
		COLOR_ATTACHMENT19,
		COLOR_ATTACHMENT20,
		COLOR_ATTACHMENT21,
		COLOR_ATTACHMENT22,
		COLOR_ATTACHMENT23,
		COLOR_ATTACHMENT24,
		COLOR_ATTACHMENT25,
		COLOR_ATTACHMENT26,
		COLOR_ATTACHMENT27,
		COLOR_ATTACHMENT28,
		COLOR_ATTACHMENT29,
		COLOR_ATTACHMENT30,
		COLOR_ATTACHMENT31,
		//		DEPTH_ATTACHMENT,
		//		STENCIL_ATTACHMENT
	};

	enum PixelStorage
	{
		Store = 0,
		DontCare
	};

	enum BlitMask
	{
		COLOR_BUFFER_BIT = 0x01,
		DEPTH_BUFFER_BIT = 0x02,
		STENCIL_BUFFER_BIT = 0x04
	};

	FrameBuffer(FrameBuffer::Type type_);
	virtual ~FrameBuffer();

	FrameBuffer::Type GetType() const;

	virtual bool Initiate();
	virtual void Terminate();

	virtual bool Bind();
	void UnBind();

	void SetColorAttachment(FrameBuffer::ColorAttachment colorAttachment_, Texture* texture_, PixelStorage pixelStorage_ = FrameBuffer::PixelStorage::Store);
	void SetDepthAttachment(Texture* texture_, PixelStorage pixelStorage_ = FrameBuffer::PixelStorage::Store);
	void SetStencilAttachment(Texture* texture_, PixelStorage pixelStorage_ = FrameBuffer::PixelStorage::Store);
	const Texture* GetColorAttachment(FrameBuffer::ColorAttachment colorAttachment_) const;
	const Texture* GetDepthAttachment() const;
	const Texture* GetStencilAttachment() const;
	void ClearColorAttachment(FrameBuffer::ColorAttachment colorAttachment_, const ColorRGBA& color_);
	void ClearDepthAttachment(float clearDepth_);
	void ClearStencilAttachment(int clearStencil_);

	void Invalidate(int x = -1, int y = -1, int w = -1, int h = -1) const;
protected:
	void EnableDrawBuffers();
	bool IsframeBufferComplete() const;
private:
protected:
	Type type;
	FrameBufferImpl* impl;
};

class FrameBuffer1D : public FrameBuffer
{
public:
	FrameBuffer1D();
	virtual ~FrameBuffer1D();

	virtual bool Initiate(unsigned int width, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	virtual bool Bind() override;

	virtual Texture1D* GetFrameBufferTexture() = 0;
	virtual const Texture1D* GetFrameBufferTexture() const = 0;

	virtual Texture1D* GetTexture() = 0;
	virtual const Texture1D* GetTexture() const = 0;
private:
};

class FrameBuffer2D : public FrameBuffer
{
public:
	FrameBuffer2D();
	virtual ~FrameBuffer2D();

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	virtual bool Bind() override;

	virtual Texture2D* GetFrameBufferTexture() = 0;
	virtual const Texture2D* GetFrameBufferTexture() const = 0;

	virtual Texture2D* GetTexture() = 0;
	virtual const Texture2D* GetTexture() const = 0;
private:
};

class FrameBuffer3D : public FrameBuffer
{
public:
	FrameBuffer3D();
	virtual ~FrameBuffer3D();

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int depth, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	virtual bool Bind() override;

	virtual Texture3D* GetFrameBufferTexture() = 0;
	virtual const Texture3D* GetFrameBufferTexture() const = 0;

	virtual Texture3D* GetTexture() = 0;
	virtual const Texture3D* GetTexture() const = 0;
private:
};

class FrameBufferCubemap : public FrameBuffer
{
public:
	FrameBufferCubemap();
	virtual ~FrameBufferCubemap();

	virtual bool Initiate(unsigned int size, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	virtual bool Bind() override;

	void SetCurrentFace(int face);
	int GetCurrentFace() const;

	virtual TextureCubemap* GetFrameBufferTexture() = 0;
	virtual const TextureCubemap* GetFrameBufferTexture() const = 0;

	virtual TextureCubemap* GetTexture() = 0;
	virtual const TextureCubemap* GetTexture() const = 0;
private:
	int currentFace;
};

/////////////////////////////////////
class TextureFrameBuffer1D : public FrameBuffer1D
{
public:
	TextureFrameBuffer1D();
	virtual ~TextureFrameBuffer1D();

	virtual bool Initiate(unsigned int width, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	void Flip();

	virtual Texture1D* GetFrameBufferTexture() override;
	virtual const Texture1D* GetFrameBufferTexture() const override;

	virtual Texture1D* GetTexture() override;
	virtual const Texture1D* GetTexture() const override;
private:
	int currentTexture;
	Texture1D textures[2];
};

class TextureFrameBuffer2D : public FrameBuffer2D
{
public:
	TextureFrameBuffer2D();
	virtual ~TextureFrameBuffer2D();

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	void Flip();

	virtual Texture2D* GetFrameBufferTexture() override;
	virtual const Texture2D* GetFrameBufferTexture() const override;

	virtual Texture2D* GetTexture() override;
	virtual const Texture2D* GetTexture() const override;
private:
	int currentTexture;
	Texture2D textures[2];
};

class TextureFrameBuffer3D : public FrameBuffer3D
{
public:
	TextureFrameBuffer3D();
	virtual ~TextureFrameBuffer3D();

	virtual bool Initiate(unsigned int width, unsigned int height, unsigned int depth, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	void Flip();

	virtual Texture3D* GetFrameBufferTexture() override;
	virtual const Texture3D* GetFrameBufferTexture() const override;

	virtual Texture3D* GetTexture() override;
	virtual const Texture3D* GetTexture() const override;
private:
	int currentTexture;
	Texture3D textures[2];
};

class TextureFrameBufferCubemap : public FrameBufferCubemap
{
public:
	TextureFrameBufferCubemap();
	virtual ~TextureFrameBufferCubemap();

	virtual bool Initiate(unsigned int size, unsigned int nrComponents, Texture::DynamicRange dynamicRange_);
	virtual void Terminate();

	void Flip();

	virtual TextureCubemap* GetFrameBufferTexture() override;
	virtual const TextureCubemap* GetFrameBufferTexture() const override;

	virtual TextureCubemap* GetTexture() override;
	virtual const TextureCubemap* GetTexture() const override;
private:
	int currentTexture;
	TextureCubemap textures[2];
};


#endif