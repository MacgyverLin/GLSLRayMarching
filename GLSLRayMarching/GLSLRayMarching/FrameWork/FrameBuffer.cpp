#include "Platform.h"
#include "FrameBuffer.h"
#include "Graphics.h"
#include "Texture.h"
#include <map>

static unsigned int frameBufferGLColorAttachments[] =
{
	GL_COLOR_ATTACHMENT0,
	GL_COLOR_ATTACHMENT1,
	GL_COLOR_ATTACHMENT2,
	GL_COLOR_ATTACHMENT3,
	GL_COLOR_ATTACHMENT4,
	GL_COLOR_ATTACHMENT5,
	GL_COLOR_ATTACHMENT6,
	GL_COLOR_ATTACHMENT7,
	GL_COLOR_ATTACHMENT8,
	GL_COLOR_ATTACHMENT9,
	GL_COLOR_ATTACHMENT10,
	GL_COLOR_ATTACHMENT11,
	GL_COLOR_ATTACHMENT12,
	GL_COLOR_ATTACHMENT13,
	GL_COLOR_ATTACHMENT14,
	GL_COLOR_ATTACHMENT15,
	GL_COLOR_ATTACHMENT16,
	GL_COLOR_ATTACHMENT17,
	GL_COLOR_ATTACHMENT18,
	GL_COLOR_ATTACHMENT19,
	GL_COLOR_ATTACHMENT20,
	GL_COLOR_ATTACHMENT21,
	GL_COLOR_ATTACHMENT22,
	GL_COLOR_ATTACHMENT23,
	GL_COLOR_ATTACHMENT24,
	GL_COLOR_ATTACHMENT25,
	GL_COLOR_ATTACHMENT26,
	GL_COLOR_ATTACHMENT27,
	GL_COLOR_ATTACHMENT28,
	GL_COLOR_ATTACHMENT29,
	GL_COLOR_ATTACHMENT30,
	GL_COLOR_ATTACHMENT31,
	//GL_DEPTH_ATTACHMENT,
	//GL_STENCIL_ATTACHMENT
};

class FrameBufferImpl
{
public:
	FrameBufferImpl()
		: fbo(0)
		, colorAttachments()
		, depthAttachment()
		, stencilAttachment()
	{
	}

	void Clear()
	{
		fbo = 0;
		colorAttachments.clear();
		depthAttachment = FrameBufferImpl::Attachment();
		stencilAttachment = FrameBufferImpl::Attachment();
	}

	class Attachment
	{
	public:
		Attachment()
			: texture(nullptr)
			, pixelStorage(FrameBuffer::PixelStorage::Store)
		{
		}

		Texture* texture;
		FrameBuffer::PixelStorage pixelStorage;
	};

	unsigned int fbo;

	std::map<FrameBuffer::ColorAttachment, Attachment> colorAttachments;
	Attachment depthAttachment;
	Attachment stencilAttachment;
};

FrameBuffer::FrameBuffer(FrameBuffer::Type type_)
: type(type_)
{
	impl = new FrameBufferImpl();
	Assert(impl);
}

FrameBuffer::~FrameBuffer()
{
	Assert(impl);

	Terminate();

	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

FrameBuffer::Type FrameBuffer::GetType() const
{
	return type;
}

bool FrameBuffer::Initiate()
{
	Assert(impl);

	glGenFramebuffers(1, &impl->fbo);
	//glBindFramebuffer(GL_FRAMEBUFFER, impl->fbo);

	return impl->fbo != 0;
}

void FrameBuffer::Terminate()
{
	Assert(impl);

	if (impl->fbo)
	{
		glDeleteFramebuffers(1, &impl->fbo);

		impl->Clear();
	}
}

bool FrameBuffer::Bind()
{
	Assert(impl);

	glBindFramebuffer(GL_FRAMEBUFFER, impl->fbo);

	return true;
}

void FrameBuffer::UnBind()
{
	Assert(impl);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void FrameBuffer::Invalidate(int x, int y, int w, int h) const
{
	Assert(impl);

	std::vector<unsigned int > attachmentEnums;
	///////////////////////////////////////////////////////////////
	for (auto& attachmentmentItr : impl->colorAttachments)
	{
		FrameBufferImpl::Attachment& attachment = attachmentmentItr.second;

		attachmentEnums.push_back((int)attachmentmentItr.first);
	}

	{
		FrameBufferImpl::Attachment& attachment = impl->depthAttachment;
		if (attachment.texture)
		{
			attachmentEnums.push_back(GL_DEPTH_ATTACHMENT);
		}
	}

	{
		FrameBufferImpl::Attachment& attachment = impl->stencilAttachment;
		if (attachment.texture)
		{
			attachmentEnums.push_back(GL_STENCIL_ATTACHMENT);
		}
	}
	
	if (x < 0 || y < 0 || w < 0 || h < 0)
		glInvalidateSubFramebuffer(GL_FRAMEBUFFER, attachmentEnums.size(), &attachmentEnums[0], x, y, w, h);
	else
		glInvalidateFramebuffer(GL_FRAMEBUFFER, attachmentEnums.size(), &attachmentEnums[0]);
}

void FrameBuffer::SetColorAttachment(FrameBuffer::ColorAttachment colorAttachment_, Texture* texture_, PixelStorage pixelStorage_)
{
	Assert(impl);

	impl->colorAttachments[colorAttachment_].texture = texture_;
	impl->colorAttachments[colorAttachment_].pixelStorage = pixelStorage_;
}

void FrameBuffer::SetDepthAttachment(Texture* texture_, PixelStorage pixelStorage_)
{
	Assert(impl);
	Assert(texture_);

	impl->depthAttachment.texture = texture_;
	impl->depthAttachment.pixelStorage = pixelStorage_;
}

void FrameBuffer::SetStencilAttachment(Texture* texture_, PixelStorage pixelStorage_)
{
	Assert(impl);
	Assert(texture_);

	impl->stencilAttachment.texture = texture_;
	impl->stencilAttachment.pixelStorage = pixelStorage_;
}

const Texture* FrameBuffer::GetColorAttachment(FrameBuffer::ColorAttachment colorAttachment_) const
{
	Assert(impl);

	std::map<FrameBuffer::ColorAttachment, FrameBufferImpl::Attachment>::const_iterator
		itr = impl->colorAttachments.find(colorAttachment_);

	if (itr != impl->colorAttachments.end())
		return itr->second.texture;
	else
		return nullptr;
}

const Texture* FrameBuffer::GetDepthAttachment() const
{
	Assert(impl);

	return impl->depthAttachment.texture;
}

const Texture* FrameBuffer::GetStencilAttachment() const
{
	Assert(impl);

	return impl->stencilAttachment.texture;
}

void FrameBuffer::ClearColorAttachment(FrameBuffer::ColorAttachment colorAttachment_, const ColorRGBA& color_)
{
	Assert(impl);

	int c[4] =
	{
		color_[0] * 255,
		color_[1] * 255,
		color_[2] * 255,
		color_[3] * 255,
	};

	bool attachmentIsFloat = false;
	if (attachmentIsFloat)
		glClearBufferfv(GL_COLOR, GL_DRAW_BUFFER0, color_);
	else
		glClearBufferiv(GL_COLOR, GL_DRAW_BUFFER0, c);
}

void FrameBuffer::ClearDepthAttachment(float clearDepth_)
{
	Assert(impl);

	glClearBufferfv(GL_DEPTH, 0, &clearDepth_);
}

void FrameBuffer::ClearStencilAttachment(int clearStencil_)
{
	Assert(impl);

	glClearBufferiv(GL_STENCIL, 0, &clearStencil_);
}

void FrameBuffer::EnableDrawBuffers()
{
	std::vector<GLenum> bufs;
	for (auto& colorAttachment : impl->colorAttachments)
	{
		bufs.push_back(frameBufferGLColorAttachments[(int)colorAttachment.first]);
	}

	glDrawBuffers(bufs.size(), &bufs[0]);
}

bool FrameBuffer::IsframeBufferComplete() const
{
	Assert(impl);

	return glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE;
}

////////////////////////////////////////////////////////////
FrameBuffer1D::FrameBuffer1D()
	: FrameBuffer(FrameBuffer::Type::Texture1D)
{
}

FrameBuffer1D::~FrameBuffer1D()
{
	Terminate();
}

bool FrameBuffer1D::Initiate(unsigned int width, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer::Initiate())
		return false;

	return true;
}

void FrameBuffer1D::Terminate()
{
	FrameBuffer::Terminate();
}

#define BIND_ATTACHEDMENT_1D(framebufferattachment, gl_attachmentEnum) \
{ \
	FrameBufferImpl::Attachment& attachment = framebufferattachment; \
	if (attachment.texture) \
	{ \
		glFramebufferTexture1D \
		( \
			GL_FRAMEBUFFER, \
			gl_attachmentEnum, \
			GL_TEXTURE_1D, \
			attachment.texture->GetHandle(), \
			0 \
		);\
	} \
}

#define BIND_ATTACHEDMENT_2D(framebufferattachment, gl_attachmentEnum) \
{ \
	FrameBufferImpl::Attachment& attachment = framebufferattachment; \
	if (attachment.texture) \
	{ \
		glFramebufferTexture2D \
		( \
			GL_FRAMEBUFFER, \
			gl_attachmentEnum, \
			GL_TEXTURE_2D, \
			attachment.texture->GetHandle(), \
			0 \
		);\
	} \
}

#define BIND_ATTACHEDMENT_CUBEMAP(face, framebufferattachment, gl_attachmentEnum) \
{ \
	FrameBufferImpl::Attachment& attachment = framebufferattachment; \
	if (attachment.texture) \
	{ \
		glFramebufferTexture2D \
		( \
			GL_FRAMEBUFFER, \
			gl_attachmentEnum, \
			GL_TEXTURE_CUBE_MAP_POSITIVE_X + face, \
			attachment.texture->GetHandle(), \
			0 \
		);\
	} \
}

#define BIND_ATTACHEDMENT_3D(framebufferattachment, gl_attachmentEnum) \
{ \
	FrameBufferImpl::Attachment& attachment = framebufferattachment; \
	if (attachment.texture) \
	{ \
		glFramebufferTexture3D \
		( \
			GL_FRAMEBUFFER, \
			gl_attachmentEnum, \
			GL_TEXTURE_3D, \
			attachment.texture->GetHandle(), \
			0, \
			0  \
		);\
	} \
}

bool FrameBuffer1D::Bind()
{
	if (!FrameBuffer::Bind())
		return false;

	for (auto& attachmentmentItr : impl->colorAttachments)
	{
		BIND_ATTACHEDMENT_1D(attachmentmentItr.second, frameBufferGLColorAttachments[(int)attachmentmentItr.first])
	}

	BIND_ATTACHEDMENT_1D(impl->depthAttachment, GL_DEPTH_ATTACHMENT);

	BIND_ATTACHEDMENT_1D(impl->stencilAttachment, GL_STENCIL_ATTACHMENT);

	return IsframeBufferComplete();
}

////////////////////////////////////////////////////////////
FrameBuffer2D::FrameBuffer2D()
	: FrameBuffer(FrameBuffer::Type::Texture2D)
{
}

FrameBuffer2D::~FrameBuffer2D()
{
	Terminate();
}

bool FrameBuffer2D::Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer::Initiate())
		return false;

	return true;
}

void FrameBuffer2D::Terminate()
{
	return FrameBuffer::Terminate();
}

bool FrameBuffer2D::Bind()
{
	if (!FrameBuffer::Bind())
		return false;

	for (auto& attachmentmentItr : impl->colorAttachments)
	{
		BIND_ATTACHEDMENT_2D(attachmentmentItr.second, frameBufferGLColorAttachments[(int)attachmentmentItr.first])
	}

	BIND_ATTACHEDMENT_2D(impl->depthAttachment, GL_DEPTH_ATTACHMENT);

	BIND_ATTACHEDMENT_2D(impl->stencilAttachment, GL_STENCIL_ATTACHMENT);

	return IsframeBufferComplete();
}

////////////////////////////////////////////////////////////
FrameBuffer3D::FrameBuffer3D()
	: FrameBuffer(FrameBuffer::Type::Texture3D)
{
}

FrameBuffer3D::~FrameBuffer3D()
{
	Terminate();
}

bool FrameBuffer3D::Initiate(unsigned int width, unsigned int height, unsigned int depth, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer::Initiate())
		return false;

	return true;
}

void FrameBuffer3D::Terminate()
{
	FrameBuffer::Terminate();
}

bool FrameBuffer3D::Bind()
{
	if (!FrameBuffer::Bind())
		return false;

	for (auto& attachmentmentItr : impl->colorAttachments)
	{
		BIND_ATTACHEDMENT_3D(attachmentmentItr.second, frameBufferGLColorAttachments[(int)attachmentmentItr.first])
	}

	BIND_ATTACHEDMENT_3D(impl->depthAttachment, GL_DEPTH_ATTACHMENT);

	BIND_ATTACHEDMENT_3D(impl->stencilAttachment, GL_STENCIL_ATTACHMENT);

	return IsframeBufferComplete();
}

////////////////////////////////////////////////////////////
FrameBufferCubemap::FrameBufferCubemap()
	: FrameBuffer(FrameBuffer::Type::TextureCubemap)
	, currentFace(0)
{
}

FrameBufferCubemap::~FrameBufferCubemap()
{
	Terminate();
}

void FrameBufferCubemap::Terminate()
{
	FrameBuffer::Terminate();
}

bool FrameBufferCubemap::Initiate(unsigned int size, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer::Initiate())
		return false;

	return true;
}

bool FrameBufferCubemap::Bind()
{
	if (!FrameBuffer::Bind())
		return false;

	for (auto& attachmentmentItr : impl->colorAttachments)
	{
		BIND_ATTACHEDMENT_CUBEMAP(currentFace, attachmentmentItr.second, frameBufferGLColorAttachments[(int)attachmentmentItr.first])
	}

	BIND_ATTACHEDMENT_2D(impl->depthAttachment, GL_DEPTH_ATTACHMENT);

	BIND_ATTACHEDMENT_2D(impl->stencilAttachment, GL_STENCIL_ATTACHMENT);

	return IsframeBufferComplete();
}

void FrameBufferCubemap::SetCurrentFace(int face)
{
	currentFace = face;
}

int FrameBufferCubemap::GetCurrentFace() const
{
	return currentFace;
}

////////////////////////////////////////////////////////////
TextureFrameBuffer1D::TextureFrameBuffer1D()
	: currentTexture(0)
{
}

TextureFrameBuffer1D::~TextureFrameBuffer1D()
{
	Terminate();
}

bool TextureFrameBuffer1D::Initiate(unsigned int width, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer1D::Initiate(width, nrComponents ,dynamicRange_))
		return false;

	if (!textures[0].Initiate(width, nrComponents, dynamicRange_, nullptr))
		return false;

	if (!textures[1].Initiate(width, nrComponents, dynamicRange_, nullptr))
		return false;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);

	return true;
}

void TextureFrameBuffer1D::Terminate()
{
	textures[0].Terminate();
	textures[1].Terminate();

	FrameBuffer1D::Terminate();
}

void TextureFrameBuffer1D::Flip()
{
	currentTexture = 1 - currentTexture;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);
}

Texture1D* TextureFrameBuffer1D::GetTexture()
{
	return &textures[currentTexture];
}

const Texture1D* TextureFrameBuffer1D::GetTexture() const
{
	return &textures[currentTexture];
}

////////////////////////////////////////////////////////////
TextureFrameBuffer2D::TextureFrameBuffer2D()
	: currentTexture(0)
{
}

TextureFrameBuffer2D::~TextureFrameBuffer2D()
{
	Terminate();
}

bool TextureFrameBuffer2D::Initiate(unsigned int width, unsigned int height, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer2D::Initiate(width, height, nrComponents, dynamicRange_))
		return false;

	if (!textures[0].Initiate(width, height, nrComponents, dynamicRange_, nullptr))
		return false;

	if (!textures[1].Initiate(width, height, nrComponents, dynamicRange_, nullptr))
		return false;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);

	return true;
}

void TextureFrameBuffer2D::Terminate()
{
	textures[0].Terminate();
	textures[1].Terminate();

	FrameBuffer2D::Terminate();
}

void TextureFrameBuffer2D::Flip()
{
	currentTexture = 1 - currentTexture;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);
}

Texture2D* TextureFrameBuffer2D::GetTexture()
{
	return &textures[currentTexture];
}

const Texture2D* TextureFrameBuffer2D::GetTexture() const
{
	return &textures[currentTexture];
}

////////////////////////////////////////////////////////////
TextureFrameBuffer3D::TextureFrameBuffer3D()
	: currentTexture(0)
{
}

TextureFrameBuffer3D::~TextureFrameBuffer3D()
{
	Terminate();
}

bool TextureFrameBuffer3D::Initiate(unsigned int width, unsigned int height, unsigned int depth, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBuffer3D::Initiate(width, height, depth, nrComponents, dynamicRange_))
		return false;

	if (!textures[0].Initiate(width, height, depth, nrComponents, dynamicRange_, nullptr))
		return false;

	if (!textures[1].Initiate(width, height, depth, nrComponents, dynamicRange_, nullptr))
		return false;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);

	return true;
}

void TextureFrameBuffer3D::Terminate()
{
	textures[0].Terminate();
	textures[1].Terminate();

	FrameBuffer3D::Terminate();
}

void TextureFrameBuffer3D::Flip()
{
	currentTexture = 1 - currentTexture;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);
}

Texture3D* TextureFrameBuffer3D::GetTexture()
{
	return &textures[currentTexture];
}

const Texture3D* TextureFrameBuffer3D::GetTexture() const
{
	return &textures[currentTexture];
}

////////////////////////////////////////////////////////////
TextureFrameBufferCubemap::TextureFrameBufferCubemap()
	: currentTexture(0)
{
}

TextureFrameBufferCubemap::~TextureFrameBufferCubemap()
{
	Terminate();
}

bool TextureFrameBufferCubemap::Initiate(unsigned int size, unsigned int nrComponents, Texture::DynamicRange dynamicRange_)
{
	if (!FrameBufferCubemap::Initiate(size, nrComponents, dynamicRange_))
		return false;

	if (!textures[0].Initiate(size, nrComponents, dynamicRange_, nullptr))
		return false;

	if (!textures[1].Initiate(size, nrComponents, dynamicRange_, nullptr))
		return false;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);

	return true;
}

void TextureFrameBufferCubemap::Terminate()
{
	textures[0].Terminate();
	textures[1].Terminate();

	FrameBufferCubemap::Terminate();
}

void TextureFrameBufferCubemap::Flip()
{
	currentTexture = 1 - currentTexture;

	SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, GetTexture(), FrameBuffer::PixelStorage::Store);
}

TextureCubemap* TextureFrameBufferCubemap::GetTexture()
{
	return &textures[currentTexture];
}

const TextureCubemap* TextureFrameBufferCubemap::GetTexture() const
{
	return &textures[currentTexture];
}