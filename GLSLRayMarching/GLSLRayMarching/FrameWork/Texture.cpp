#include "Texture.h"
#include "Graphics.h"

#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>

static unsigned int textureGLTypes[] =
{
	GL_TEXTURE_1D,
	GL_TEXTURE_2D,
	GL_TEXTURE_3D,
	GL_TEXTURE_CUBE_MAP,
	GL_TEXTURE_1D_ARRAY,
	GL_TEXTURE_2D_ARRAY,
	GL_TEXTURE_CUBE_MAP_ARRAY
};

static unsigned int textureGLWraps[] =
{
	GL_REPEAT,
	GL_CLAMP_TO_EDGE
};

static unsigned int textureGLMinFilters[] =
{
	GL_NEAREST,
	GL_LINEAR,
	GL_NEAREST_MIPMAP_NEAREST,
	GL_LINEAR_MIPMAP_NEAREST,
	GL_NEAREST_MIPMAP_LINEAR,
	GL_LINEAR_MIPMAP_LINEAR
};

static unsigned int textureGLMagFilters[] =
{
	GL_NEAREST,
	GL_LINEAR
};

typedef struct 
{
	unsigned int internal;
	unsigned int format;
	unsigned int type;
	float bytePerPixels;
}Formats;

static Formats textureGLFormats[] =
{
	{ GL_R8						, GL_RED					, GL_UNSIGNED_BYTE					 , 1.0f },
	{ GL_R8_SNORM				, GL_RED					, GL_BYTE							 , 1.0f },
	{ GL_R16F					, GL_RED					, GL_HALF_FLOAT						 , 2.0f },
	{ GL_R32F					, GL_RED					, GL_FLOAT							 , 4.0f },
	{ GL_R8UI					, GL_RED_INTEGER			, GL_UNSIGNED_BYTE					 , 1.0f },
	{ GL_R8I					, GL_RED_INTEGER			, GL_BYTE							 , 1.0f },
	{ GL_R16UI					, GL_RED_INTEGER			, GL_UNSIGNED_SHORT					 , 2.0f },
	{ GL_R16I					, GL_RED_INTEGER			, GL_SHORT							 , 2.0f },
	{ GL_R32UI					, GL_RED_INTEGER			, GL_UNSIGNED_INT					 , 4.0f },
	{ GL_R32I					, GL_RED_INTEGER			, GL_INT							 , 4.0f },

	{ GL_RG8					, GL_RG						, GL_UNSIGNED_BYTE					 , 2.0f },
	{ GL_RG8_SNORM				, GL_RG						, GL_BYTE							 , 2.0f },
	{ GL_RG16F					, GL_RG						, GL_HALF_FLOAT						 , 4.0f },
	{ GL_RG32F					, GL_RG						, GL_FLOAT							 , 8.0f },
	{ GL_RG8UI					, GL_RG_INTEGER				, GL_UNSIGNED_BYTE					 , 2.0f },
	{ GL_RG8I					, GL_RG_INTEGER				, GL_BYTE							 , 2.0f },
	{ GL_RG16UI					, GL_RG_INTEGER				, GL_UNSIGNED_SHORT					 , 4.0f },
	{ GL_RG16I					, GL_RG_INTEGER				, GL_SHORT							 , 4.0f },
	{ GL_RG32UI					, GL_RG_INTEGER				, GL_UNSIGNED_INT					 , 8.0f },
	{ GL_RG32I					, GL_RG_INTEGER				, GL_INT							 , 8.0f },

	{ GL_RGB8					, GL_RGB					, GL_UNSIGNED_BYTE					 , 3.0f },
	{ GL_SRGB8					, GL_RGB					, GL_UNSIGNED_BYTE					 , 3.0f },
	{ GL_RGB565					, GL_RGB					, GL_UNSIGNED_SHORT_5_6_5			 , 2.0f },
	{ GL_RGB8_SNORM				, GL_RGB					, GL_BYTE							 , 3.0f },
	{ GL_R11F_G11F_B10F			, GL_RGB					, GL_HALF_FLOAT						 , 4.0f },
	{ GL_RGB9_E5				, GL_RGB					, GL_HALF_FLOAT						 , 4.0f },
	{ GL_RGB16F					, GL_RGB					, GL_HALF_FLOAT						 , 6.0f },
	{ GL_RGB32F					, GL_RGB					, GL_FLOAT							 , 12.0f },
	{ GL_RGB8UI					, GL_RGB_INTEGER			, GL_UNSIGNED_BYTE					 , 3.0f },
	{ GL_RGB8I					, GL_RGB_INTEGER			, GL_BYTE							 , 3.0f },
	{ GL_RGB16UI				, GL_RGB_INTEGER			, GL_UNSIGNED_SHORT					 , 6.0f },
	{ GL_RGB16I					, GL_RGB_INTEGER			, GL_SHORT							 , 6.0f },
	{ GL_RGB32UI				, GL_RGB_INTEGER			, GL_UNSIGNED_INT					 , 12.0f },
	{ GL_RGB32I					, GL_RGB_INTEGER			, GL_INT							 , 12.0f },

	{ GL_RGBA8					, GL_RGBA					, GL_UNSIGNED_BYTE					 , 4.0f },
	{ GL_SRGB8_ALPHA8			, GL_RGBA					, GL_UNSIGNED_BYTE					 , 4.0f },
	{ GL_RGBA8_SNORM			, GL_RGBA					, GL_BYTE							 , 4.0f },
	{ GL_RGB5_A1				, GL_RGBA					, GL_UNSIGNED_BYTE					 , 2.0f },
	{ GL_RGBA4					, GL_RGBA					, GL_UNSIGNED_BYTE					 , 2.0f },
	{ GL_RGB10_A2				, GL_RGBA					, GL_UNSIGNED_INT_2_10_10_10_REV	 , 4.0f },
	{ GL_RGBA16F				, GL_RGBA					, GL_HALF_FLOAT						 , 8.0f },
	{ GL_RGBA32F				, GL_RGBA					, GL_FLOAT							 , 16.0f },
	{ GL_RGBA8UI				, GL_RGBA_INTEGER			, GL_UNSIGNED_BYTE					 , 4.0f },
	{ GL_RGBA8I					, GL_RGBA_INTEGER			, GL_BYTE							 , 4.0f },
	{ GL_RGB10_A2UI				, GL_RGBA_INTEGER			, GL_UNSIGNED_INT_2_10_10_10_REV	 , 4.0f },
	{ GL_RGBA16UI				, GL_RGBA_INTEGER			, GL_UNSIGNED_SHORT					 , 8.0f },
	{ GL_RGBA16I				, GL_RGBA_INTEGER			, GL_SHORT							 , 8.0f },
	{ GL_RGBA32I				, GL_RGBA_INTEGER			, GL_INT							 , 16.0f },
	{ GL_RGBA32UI				, GL_RGBA_INTEGER			, GL_UNSIGNED_INT					 , 16.0f },

	{ GL_DEPTH_COMPONENT16		, GL_DEPTH_COMPONENT		, GL_UNSIGNED_SHORT					, 2.0f },
	{ GL_DEPTH_COMPONENT24		, GL_DEPTH_COMPONENT		, GL_UNSIGNED_INT					, 3.0f },
	{ GL_DEPTH_COMPONENT32F		, GL_DEPTH_COMPONENT		, GL_FLOAT							, 4.0f },
	{ GL_DEPTH24_STENCIL8		, GL_DEPTH_STENCIL			, GL_UNSIGNED_INT_24_8				, 4.0f },
	{ GL_DEPTH32F_STENCIL8		, GL_DEPTH_STENCIL			, GL_FLOAT_32_UNSIGNED_INT_24_8_REV	, 5.0f },
	{ GL_STENCIL_INDEX8			, GL_STENCIL_INDEX			, GL_UNSIGNED_BYTE					, 1.0f },

	{ GL_COMPRESSED_R11_EAC								, GL_RED		, 0						, 8.0f / 4 / 4 },
	{ GL_COMPRESSED_SIGNED_R11_EAC						, GL_RED		, 0						, 8.0f / 4 / 4 },
	{ GL_COMPRESSED_RG11_EAC							, GL_RG			, 0						, 16.0f / 4 / 4 },
	{ GL_COMPRESSED_SIGNED_RG11_EAC						, GL_RG			, 0						, 16.0f / 4 / 4 },
	{ GL_COMPRESSED_RGB8_ETC2							, GL_RGB		, 0						, 8.0f / 4 / 4 },
	{ GL_COMPRESSED_SRGB8_ETC2							, GL_RGB		, 0						, 8.0f / 4 / 4 },
	{ GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2		, GL_RGBA		, 0						, 8.0f / 4 / 4 },
	{ GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2		, GL_RGBA		, 0						, 8.0f / 4 / 4 },
	{ GL_COMPRESSED_RGBA8_ETC2_EAC						, GL_RGBA		, 0						, 16.0f / 4 / 4 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC				, GL_RGBA		, 0						, 16.0f / 4 / 4 },
	{ GL_COMPRESSED_RGBA_ASTC_4x4_KHR					, GL_RGBA		, 0						, 16.0f / 4 / 4 },
	{ GL_COMPRESSED_RGBA_ASTC_5x4_KHR					, GL_RGBA		, 0						, 16.0f / 5 / 4 },
	{ GL_COMPRESSED_RGBA_ASTC_5x5_KHR					, GL_RGBA		, 0						, 16.0f / 5 / 5 },
	{ GL_COMPRESSED_RGBA_ASTC_6x5_KHR					, GL_RGBA		, 0						, 16.0f / 6 / 5 },
	{ GL_COMPRESSED_RGBA_ASTC_6x6_KHR					, GL_RGBA		, 0						, 16.0f / 6 / 6 },
	{ GL_COMPRESSED_RGBA_ASTC_8x5_KHR					, GL_RGBA		, 0						, 16.0f / 8 / 5 },
	{ GL_COMPRESSED_RGBA_ASTC_8x6_KHR					, GL_RGBA		, 0						, 16.0f / 8 / 6 },
	{ GL_COMPRESSED_RGBA_ASTC_8x8_KHR					, GL_RGBA		, 0						, 16.0f / 8 / 8 },
	{ GL_COMPRESSED_RGBA_ASTC_10x5_KHR					, GL_RGBA		, 0						, 16.0f / 10 / 5 },
	{ GL_COMPRESSED_RGBA_ASTC_10x6_KHR					, GL_RGBA		, 0						, 16.0f / 10 / 6 },
	{ GL_COMPRESSED_RGBA_ASTC_10x8_KHR					, GL_RGBA		, 0						, 16.0f / 10 / 8 },
	{ GL_COMPRESSED_RGBA_ASTC_10x10_KHR					, GL_RGBA		, 0						, 16.0f / 10 / 10 },
	{ GL_COMPRESSED_RGBA_ASTC_12x10_KHR					, GL_RGBA		, 0						, 16.0f / 12 / 10 },
	{ GL_COMPRESSED_RGBA_ASTC_12x12_KHR					, GL_RGBA		, 0						, 16.0f / 10 / 12 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR			, GL_RGBA		, 0						, 16.0f / 4 / 4 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR			, GL_RGBA		, 0						, 16.0f / 5 / 4 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR			, GL_RGBA		, 0						, 16.0f / 5 / 5 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR			, GL_RGBA		, 0						, 16.0f / 6 / 5 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR			, GL_RGBA		, 0						, 16.0f / 6 / 6 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR			, GL_RGBA		, 0						, 16.0f / 8 / 5 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR			, GL_RGBA		, 0						, 16.0f / 8 / 6 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR			, GL_RGBA		, 0						, 16.0f / 8 / 8 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR			, GL_RGBA		, 0						, 16.0f / 10 / 5 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR			, GL_RGBA		, 0						, 16.0f / 10 / 6 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR			, GL_RGBA		, 0						, 16.0f / 10 / 8 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR			, GL_RGBA		, 0						, 16.0f / 10 / 10 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR			, GL_RGBA		, 0						, 16.0f / 12 / 10 },
	{ GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR			, GL_RGBA		, 0						, 16.0f / 12 / 12 }
};

static unsigned int textureCubeMapGLSide[] =
{
	GL_TEXTURE_CUBE_MAP_POSITIVE_X,
	GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
	GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
	GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
	GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
	GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
};

////////////////////////////////////////////////////////////////////////////
class TextureImpl
{
public:
	TextureImpl(Texture::Type type_)
		: type(type_)
		, format(Texture::Format::RGBA32UI)
		, handle(0)

		, warpS(Texture::Wrap::Repeat)
		, warpT(Texture::Wrap::Repeat)
		, warpR(Texture::Wrap::Repeat)
		, minFilter(Texture::MinFilter::Nearest)
		, magFilter(Texture::MagFilter::Nearest)
	{
	}

	Texture::Type type;
	Texture::Format format;
	unsigned int handle;

	Texture::Wrap warpS;
	Texture::Wrap warpR;
	Texture::Wrap warpT;
	Texture::MinFilter minFilter;
	Texture::MagFilter magFilter;
};

////////////////////////////////////////////////////////////////////////
Texture::Texture(Texture::Type type_)
: impl(nullptr)
{
	impl = new TextureImpl(type_);
}

Texture::~Texture()
{
	Terminate();

	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

bool Texture::Initiate()
{
	Assert(impl);

	return true;
}

void Texture::Terminate()
{
	Assert(impl);

	if (impl->handle)
	{
		glDeleteTextures(1, &impl->handle);
		impl->handle = 0;

		MemSet(impl, 0, sizeof(*impl));
	}
}

void Texture::Bind(unsigned int texStage_)
{
	Assert(impl);

	if (impl->handle)
	{
		glActiveTexture(GL_TEXTURE0 + texStage_);

		unsigned int textureType = textureGLTypes[(int)impl->type];
		glBindTexture(textureType, impl->handle);

		glTexParameteri(textureType, GL_TEXTURE_WRAP_S, textureGLWraps[(int)impl->warpS]);
		glTexParameteri(textureType, GL_TEXTURE_WRAP_T, textureGLWraps[(int)impl->warpT]);
		glTexParameteri(textureType, GL_TEXTURE_WRAP_R, textureGLWraps[(int)impl->warpR]);
		glTexParameteri(textureType, GL_TEXTURE_MIN_FILTER, textureGLMinFilters[(int)impl->minFilter]);
		glTexParameteri(textureType, GL_TEXTURE_MAG_FILTER, textureGLMagFilters[(int)impl->magFilter]);
	}
}

void Texture::Unbind()
{
	Assert(impl);

	glBindTexture(textureGLTypes[(int)impl->type], 0);
}

Texture::Type Texture::GetType()  const
{
	Assert(impl);

	return impl->type;
}

Texture::Format Texture::GetFormat()  const
{
	Assert(impl);

	return impl->format;
}

unsigned int Texture::GetHandle() const
{
	Assert(impl);

	return impl->handle;
}

void Texture::SetWarpS(Texture::Wrap warpS_)
{
	Assert(impl);

	impl->warpS = warpS_;
}

void Texture::SetWarpT(Texture::Wrap warpT_)
{
	Assert(impl);

	impl->warpT = warpT_;
}

void Texture::SetWarpR(Texture::Wrap warpR_)
{
	Assert(impl);

	impl->warpR = warpR_;
}

void Texture::SetMinFilter(Texture::MinFilter minFilter_)
{
	Assert(impl);

	impl->minFilter = minFilter_;
}

void Texture::SetMagFilter(Texture::MagFilter magFilter_)
{
	Assert(impl);

	impl->magFilter = magFilter_;
}

Texture::Wrap Texture::GetWarpS() const
{
	Assert(impl);

	return impl->warpS;
}

Texture::Wrap Texture::GetWarpT() const
{
	Assert(impl);

	return impl->warpT;
}

Texture::Wrap Texture::GetWarpR() const
{
	Assert(impl);

	return impl->warpR;
}

Texture::MinFilter Texture::GetMinFilter() const
{
	Assert(impl);

	return impl->minFilter;
}

Texture::MagFilter Texture::GetMagFilter() const
{
	Assert(impl);

	return impl->magFilter;
}

Texture::Format Texture::GetFormat(unsigned int nrComponents_, Texture::DynamicRange precision) const
{
	Assert(impl);

	if (nrComponents_ == 1)
	{
		if (precision == Texture::DynamicRange::HIGH)
		{
			return Texture::Format::R32F;
		}
		else if (precision == Texture::DynamicRange::MID)
		{
			return Texture::Format::R16F;
		}
		else// if (precision == Texture::DynamicRange::LOW)
		{
			return Texture::Format::R8;
		}
	}
	else if (nrComponents_ == 2)
	{
		if (precision == Texture::DynamicRange::HIGH)
		{
			return Texture::Format::RG32F;
		}
		else if (precision == Texture::DynamicRange::MID)
		{
			return Texture::Format::RG16F;
		}
		else// if (precision == Texture::DynamicRange::LOW)
		{
			return Texture::Format::RG8;
		}
	}
	else if (nrComponents_ == 3)
	{
		if (precision == Texture::DynamicRange::HIGH)
		{
			return Texture::Format::RGB32F;
		}
		else if (precision == Texture::DynamicRange::MID)
		{
			return Texture::Format::RGB16F;
		}
		else// if (precision == Texture::DynamicRange::LOW)
		{
			return Texture::Format::RGB8;
		}
	}
	else// if (nrComponents_ == 4)
	{
		if (precision == Texture::DynamicRange::HIGH)
		{
			return Texture::Format::RGBA32F;
		}
		else if (precision == Texture::DynamicRange::MID)
		{
			return Texture::Format::RGBA16F;
		}
		else// if (precision == Texture::DynamicRange::LOW)
		{
			return Texture::Format::RGBA8;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////
Texture1D::Texture1D()
: Texture(Texture::Type::Texture1D)
, width(0)
{
	Assert(impl);
}

Texture1D::~Texture1D()
{
	Assert(impl);

	Terminate();
}

bool Texture1D::Initiate(unsigned int width_, Texture::Format format_, void* src_)
{
	Assert(impl);

	width = width_;
	impl->format = format_;

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexImage1D(textureType, 0, f.internal, width_, 0, (GLsizei)(f.bytePerPixels * width_), src_);
	else
		glTexImage1D(textureType, 0, f.internal, width_, 0, f.format, f.type, src_);

	glGenerateMipmap(textureType);

	return Texture::Initiate();
}

bool Texture1D::Initiate(unsigned int width_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_)
{
	Assert(impl);

	return Initiate(width_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void Texture1D::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

void Texture1D::Update(unsigned int x_, unsigned int width_, void* src_, int level_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage1D(textureType, level_ == -1 ? 0 : level_, x_, width_, f.format, (GLsizei)(f.bytePerPixels * width_), src_);
	else
		glTexSubImage1D(textureType, level_ == -1 ? 0 : level_, 0, width_, f.format, f.type, src_);

	if (level_ == -1)
		glGenerateMipmap(textureType);
}

void Texture1D::Update(void* src_, int level_)
{
	Update(0, width, src_, level_);
}

void Texture1D::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = width;
	*h_ = 1;
	*d_ = 1;
}

unsigned int Texture1D::GetWidth() const
{
	Assert(impl);

	return width;
}

////////////////////////////////////////////////////////////////////////////////////
Texture2D::Texture2D()
	: Texture(Texture::Type::Texture2D)
	, width(0)
	, height(0)
{
	Assert(impl);
}

Texture2D::~Texture2D()
{
	Assert(impl);

	Terminate();
}

bool Texture2D::Initiate(unsigned int width_, unsigned int height_, Texture::Format format_, void* src_)
{
	Assert(impl);

	width = width_;
	height = height_;
	impl->format = format_;

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexImage2D(textureType, 0, f.internal, width_, height_, 0, (GLsizei)(f.bytePerPixels * width_ * height_), src_);
	else
		glTexImage2D(textureType, 0, f.internal, width_, height_, 0, f.format, f.type, src_);

	glGenerateMipmap(textureType);

	return Texture::Initiate();
}

bool Texture2D::Initiate(unsigned int width_, unsigned int height_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_)
{
	Assert(impl);

	return Initiate(width_, height_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void Texture2D::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

void Texture2D::Update(unsigned int x_, unsigned int y_, unsigned int width_, unsigned int height_, void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage2D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, width_, height_, f.format, (GLsizei)(f.bytePerPixels * width_ * height_), src_);
	else
		glTexSubImage2D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, width_, height_, f.format, f.type, src_);

	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void Texture2D::Update(void* src_, int mipLevel_)
{
	Assert(impl);

	Update(0, 0, width, height, src_, mipLevel_);
}

void Texture2D::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = width;
	*h_ = height;
	*d_ = 1;

}
unsigned int Texture2D::GetWidth() const
{
	Assert(impl);

	return width;
}

unsigned int Texture2D::GetHeight() const
{
	Assert(impl);

	return height;
}

////////////////////////////////////////////////////////////////////////////////////
Texture3D::Texture3D()
: Texture(Texture::Type::Texture3D)
, width(0)
, height(0)
, depth(0)
{
	Assert(impl);
}

Texture3D::~Texture3D()
{
	Assert(impl);

	Terminate();
}

bool Texture3D::Initiate(unsigned int width_, unsigned int height_, unsigned int depth_, Texture::Format format_, void* src_)
{
	Assert(impl);

	width = width_;
	height = height_;
	depth = depth_;
	impl->format = format_;

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexImage3D(textureType, 0, f.internal, width_, height_, depth_, 0, (GLsizei)(f.bytePerPixels * width_ * height_ * depth_), src_);
	else
		glTexImage3D(textureType, 0, f.internal, width_, height_, depth_, 0, f.format, f.type, src_);
	
	glGenerateMipmap(textureType);

	return Texture::Initiate();
}

bool Texture3D::Initiate(unsigned int width_, unsigned int height_, unsigned int depth_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_)
{
	Assert(impl);

	return Initiate(width_, height_, depth_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void Texture3D::Update(unsigned int x_, unsigned int y_, unsigned int z_, unsigned int width_, unsigned int height_, unsigned int depth_, void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage3D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, z_, width_, height_, depth_, f.format, (GLsizei)(f.bytePerPixels * width_ * height_ * depth_), src_);
	else
		glTexSubImage3D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, z_, width_, height_, depth_, f.format, f.type, src_);
	
	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void Texture3D::Update(void* src_, int mipLevel_)
{
	Assert(impl);

	Update(0, 0, 0, width, height, depth, src_, mipLevel_);
}

void Texture3D::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = width;
	*h_ = height;
	*d_ = depth;
}

void Texture3D::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

unsigned int Texture3D::GetWidth() const
{
	Assert(impl);

	return width;
}

unsigned int Texture3D::GetHeight() const
{
	Assert(impl);

	return height;
}

unsigned int Texture3D::GetDepth() const
{
	Assert(impl);

	return depth;
}

////////////////////////////////////////////////////////////////////////////////////
TextureCubemap::TextureCubemap()
: Texture(Texture::Type::TextureCubemap)
, size(0)
, faceDataSize(0)
{
}

TextureCubemap::~TextureCubemap()
{
	Assert(impl);

	Terminate();
}

bool TextureCubemap::Initiate(unsigned int size_, Texture::Format format_, void* src_[6])
{
	Assert(impl);

	size = size_;
	impl->format = format_;

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	faceDataSize = (unsigned int)(size_ * size_ * f.bytePerPixels);

	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);
	glTexParameterf(textureType, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(textureType, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(textureType, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(textureType, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameterf(textureType, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
	{
		for (int i = 0; i < 6; i++)
		{
			void* ptr = src_ ? (src_[i] ? src_[i] : NULL) : NULL;
			glCompressedTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, f.internal, size, size, 0, (GLsizei)(f.bytePerPixels * size * size), ptr);
		}
	}
	else
	{
		for (int i = 0; i < 6; i++)
		{
			void* ptr = src_ ? (src_[i] ? src_[i] : NULL) : NULL;
			glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, f.internal, size, size, 0, f.format, f.type, ptr);
		}
	}

	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	return Texture::Initiate();
}

bool TextureCubemap::Initiate(unsigned int size_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_[6])
{
	return Initiate(size_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void TextureCubemap::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

void TextureCubemap::Update(Side side_, unsigned int x_, unsigned int y_, unsigned int width_, unsigned int height_, void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
	{
		glCompressedTexSubImage2D(textureCubeMapGLSide[(int)side_], mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, width_, height_, f.format, (GLsizei)(f.bytePerPixels * width_ * height_), src_);
	}
	else
	{
		glTexSubImage2D(textureCubeMapGLSide[(int)side_], mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, width_, height_, f.format, f.type, src_);
	}

	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void TextureCubemap::Update(Side side_, void* src_, int mipLevel_)
{
	Update(side_, 0, 0, size, size, src_, mipLevel_);
}

void TextureCubemap::Update(void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];
	unsigned char* dataPtr = (unsigned char*)src_;

	glBindTexture(textureType, impl->handle);
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
	{
		glCompressedTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
		glCompressedTexSubImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
		glCompressedTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
		glCompressedTexSubImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
		glCompressedTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
		glCompressedTexSubImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
	}
	else
	{
		glTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, f.type, dataPtr); dataPtr += faceDataSize;
		glTexSubImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, f.type, dataPtr); dataPtr += faceDataSize;
		glTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, f.type, dataPtr); dataPtr += faceDataSize;
		glTexSubImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, f.type, dataPtr); dataPtr += faceDataSize;
		glTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, f.type, dataPtr); dataPtr += faceDataSize;
		glTexSubImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, size, size, f.format, f.type, dataPtr); dataPtr += faceDataSize;
	}

	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void TextureCubemap::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = size;
	*h_ = size;
	*d_ = 1;
}

unsigned int TextureCubemap::GetSize() const
{
	Assert(impl);

	return size;
}

////////////////////////////////////////////////////////////////////////////////////
Texture1DArray::Texture1DArray()
: Texture(Texture::Type::Texture1DArray)
, width(0)
, layerCount(0)
{
	Assert(impl);
}

Texture1DArray::~Texture1DArray()
{
	Assert(impl);

	Terminate();
}

bool Texture1DArray::Initiate(unsigned int layerCount_, unsigned int width_, Texture::Format format_, void* src_)
{
	Assert(impl);

	layerCount = layerCount_;
	width = width_;
	impl->format = format_;
	int miplevels = log2(width);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];
	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);
	glTexStorage2D(textureType, miplevels, f.internal, width, layerCount);

	/*
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexImage1D(textureType, 0, f.internal, width_, 0, (GLsizei)(f.bytePerPixels * width_), src_);
	else
		glTexImage1D(textureType, 0, f.internal, width_, 0, f.format, f.type, src_);
	*/
	for (int i = 0; i < layerCount_; i++)
	{
		if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
			glCompressedTexImage2D(textureType, 0, f.internal, width_, layerCount_, 0, (GLsizei)(f.bytePerPixels * width_), src_);
		else
			glTexImage2D(textureType, 0, f.internal, width_, layerCount_, 0, f.format, f.type, src_);
	}
	
	glGenerateMipmap(textureType);

	return Texture::Initiate();
}

bool Texture1DArray::Initiate(unsigned int layerCount_, unsigned int width_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_)
{
	Assert(impl);

	return Initiate(layerCount_, width_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void Texture1DArray::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

void Texture1DArray::Update(unsigned int layer_, unsigned int x_, unsigned int width_, void* src_, int level_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage2D(textureType, level_ == -1 ? 0 : level_, x_, layer_, width_, 1, f.format, (GLsizei)(f.bytePerPixels * width_), src_);
	else
		glTexSubImage2D(textureType, level_ == -1 ? 0 : level_, x_, layer_, width_, 1, f.format, f.type, src_);
	/*
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage1D(textureType, level_ == -1 ? 0 : level_, x_, width_, f.format, (GLsizei)(f.bytePerPixels * width_), src_);
	else
		glTexSubImage1D(textureType, level_ == -1 ? 0 : level_, 0, width_, f.format, f.type, src_);
	*/

	if (level_ == -1)
		glGenerateMipmap(textureType);
}

void Texture1DArray::Update(unsigned int layer_, void* src_, int level_)
{
	Update(layer_, 0, width, src_, level_);
}

void Texture1DArray::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = width;
	*h_ = 1;
	*d_ = 1;
}

unsigned int Texture1DArray::GetWidth() const
{
	Assert(impl);

	return width;
}

unsigned int Texture1DArray::GetLayerCount() const
{
	Assert(impl);

	return layerCount;
}

////////////////////////////////////////////////////////////////////////////////////
Texture2DArray::Texture2DArray()
: Texture(Texture::Type::Texture2DArray)
, width(0)
, height(0)
, layerCount(0)
{
	Assert(impl);
}

Texture2DArray::~Texture2DArray()
{
	Assert(impl);

	Terminate();
}

bool Texture2DArray::Initiate(unsigned int layerCount_, unsigned int width_, unsigned int height_, Texture::Format format_, void* src_)
{
	Assert(impl);

	layerCount = layerCount_;
	width = width_;
	height = height_;
	impl->format = format_;
	int miplevels = log2(Math::Min(width, height));

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);
	glTexStorage3D(textureType, miplevels, f.internal, width, height, layerCount);

	for (int i = 0; i < layerCount_; i++)
	{
		if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
			glCompressedTexImage3D(textureType, 0, f.internal, width_, height_, layerCount_, 0, (GLsizei)(f.bytePerPixels * width_), src_);
		else
			glTexImage3D(textureType, 0, f.internal, width_, height_, layerCount_, 0, f.format, f.type, src_);
	}

	glGenerateMipmap(textureType);

	return Texture::Initiate();
}

bool Texture2DArray::Initiate(unsigned int layerCount_, unsigned int width_, unsigned int height_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_)
{
	Assert(impl);

	return Initiate(layerCount_, width_, height_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void Texture2DArray::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

void Texture2DArray::Update(unsigned int layer_, unsigned int x_, unsigned int y_, unsigned int width_, unsigned int height_, void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);

	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage3D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, layer_, width_, height_, 1, f.format, (GLsizei)(f.bytePerPixels * width_ * height_), src_);
	else
		glTexSubImage3D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, layer_, width_, height_, 1, f.format, f.type, src_);
	/*
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		glCompressedTexSubImage2D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, width_, height_, f.format, (GLsizei)(f.bytePerPixels * width_ * height_), src_);
	else
		glTexSubImage2D(textureType, mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, width_, height_, f.format, f.type, src_);
	*/

	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void Texture2DArray::Update(unsigned int layer_, void* src_, int mipLevel_)
{
	Assert(impl);

	Update(layer_, 0, 0, width, height, src_, mipLevel_);
}

void Texture2DArray::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = width;
	*h_ = height;
	*d_ = 1;
}

unsigned int Texture2DArray::GetWidth() const
{
	Assert(impl);

	return width;
}

unsigned int Texture2DArray::GetHeight() const
{
	Assert(impl);

	return height;
}

unsigned int Texture2DArray::GetLayerCount() const
{
	Assert(impl);

	return layerCount;
}

////////////////////////////////////////////////////////////////////////////////////
TextureCubeMapArray::TextureCubeMapArray()
: Texture(Texture::Type::TextureCubeMapArray)
, size(0)
, faceDataSize(0)
, layerCount(0)
{
}

TextureCubeMapArray::~TextureCubeMapArray()
{
	Assert(impl);

	Terminate();
}

bool TextureCubeMapArray::Initiate(unsigned int layerCount_, unsigned int size_, Texture::Format format_, void* src_)
{
	Assert(impl);

	layerCount = layerCount_;
	size = size_;
	impl->format = format_;

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];
	int miplevels = log2(size);

	faceDataSize = size_ * size_ * f.bytePerPixels;
	unsigned char* dataPtr = (unsigned char*)src_;

	glGenTextures(1, &impl->handle);
	glBindTexture(textureType, impl->handle);
	glTexStorage3D(textureType, miplevels, f.internal, size, size, layerCount);

	for (int i = 0; i < layerCount_; i++)
	{
		if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
		{
			glCompressedTexImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, f.internal, size, size, layerCount, 0, (GLsizei)(f.bytePerPixels * size * size), src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glCompressedTexImage3D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, f.internal, size, size, layerCount, 0, (GLsizei)(f.bytePerPixels * size * size), src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glCompressedTexImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, f.internal, size, size, layerCount, 0, (GLsizei)(f.bytePerPixels * size * size), src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glCompressedTexImage3D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, f.internal, size, size, layerCount, 0, (GLsizei)(f.bytePerPixels * size * size), src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glCompressedTexImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, f.internal, size, size, layerCount, 0, (GLsizei)(f.bytePerPixels * size * size), src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glCompressedTexImage3D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, f.internal, size, size, layerCount, 0, (GLsizei)(f.bytePerPixels * size * size), src_ ? dataPtr : NULL); dataPtr += faceDataSize;
		}
		else
		{
			glTexImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, f.internal, size, size, 0, f.format, f.type, 0, src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glTexImage3D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, f.internal, size, size, 0, f.format, f.type, 0, src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glTexImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, f.internal, size, size, 0, f.format, f.type, 0, src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glTexImage3D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, f.internal, size, size, 0, f.format, f.type, 0, src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glTexImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, f.internal, size, size, 0, f.format, f.type, 0, src_ ? dataPtr : NULL); dataPtr += faceDataSize;
			glTexImage3D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, f.internal, size, size, 0, f.format, f.type, 0, src_ ? dataPtr : NULL); dataPtr += faceDataSize;
		}
	}

	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	return Texture::Initiate();
}

bool TextureCubeMapArray::Initiate(unsigned int layerCount_, unsigned int size_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_)
{
	return Initiate(layerCount_, size_, GetFormat(nrComponents_, dynamicRange_), src_);
}

void TextureCubeMapArray::Terminate()
{
	Assert(impl);

	return Texture::Terminate();
}

void TextureCubeMapArray::Update(unsigned int layer_, Side side_, unsigned int x_, unsigned int y_, unsigned int width_, unsigned int height_, void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];

	glBindTexture(textureType, impl->handle);
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
	{
		glCompressedTexSubImage3D(textureCubeMapGLSide[(int)side_], mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, layer_, width_, height_, 1, f.format, (GLsizei)(f.bytePerPixels * width_ * height_), src_);
	}
	else
	{
		glTexSubImage3D(textureCubeMapGLSide[(int)side_], mipLevel_ == -1 ? 0 : mipLevel_, x_, y_, layer_, width_, height_, 1, f.format, f.type, src_);
	}

	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void TextureCubeMapArray::Update(unsigned int layer_, Side side_, void* src_, int mipLevel_)
{
	Update(layer_, side_, 0, 0, size, size, src_, mipLevel_);
}

void TextureCubeMapArray::Update(unsigned int layer_, void* src_, int mipLevel_)
{
	Assert(impl);

	unsigned int textureType = textureGLTypes[(int)impl->type];
	Formats f = textureGLFormats[(int)impl->format];
	unsigned char* dataPtr = (unsigned char*)src_;

	glBindTexture(textureType, impl->handle);
	if (impl->format >= Texture::Format::COMPRESSED_R11_EAC)
	{
		glCompressedTexSubImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, layer_, size, size, 1, f.format, (GLsizei)(f.bytePerPixels * size * size), dataPtr); dataPtr += faceDataSize;
	}
	else
	{
		glTexSubImage3D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, mipLevel_ == -1 ? 0 : mipLevel_, 0, 0, layer_, size, size, 1, f.format, f.type, dataPtr); dataPtr += faceDataSize;
	}

	if (mipLevel_ == -1)
		glGenerateMipmap(textureType);
}

void TextureCubeMapArray::GetResolution(unsigned int* w_, unsigned int* h_, unsigned int* d_) const
{
	Assert(impl);

	*w_ = size;
	*h_ = size;
	*d_ = 1;
}

unsigned int TextureCubeMapArray::GetSize() const
{
	Assert(impl);

	return size;
}

unsigned int TextureCubeMapArray::GetLayerCount() const
{
	Assert(impl);

	return layerCount;
}

////////////////////////////////////////////////////////////////////////////////////
Texture2DFile::Texture2DFile()
: Texture2D()
{
}

Texture2DFile::~Texture2DFile()
{
	Assert(impl);

	Terminate();
}

bool Texture2DFile::Initiate(const std::string& path_, bool vflip_)
{
	Assert(impl);

	bool isHDR = stbi_is_hdr(path_.c_str());

	int width, height, nrComponents;

	void* data = nullptr;
	if (isHDR)
	{
		data = stbi_loadf(path_.c_str(), &width, &height, &nrComponents, 0);
		if (vflip_)
			stbi__vertical_flip(data, width, height, nrComponents * 4);
	}
	else
	{
		data = stbi_load(path_.c_str(), &width, &height, &nrComponents, 0);
		if (vflip_)
			stbi__vertical_flip(data, width, height, nrComponents * 1);
	}

	if (data)
	{
		Texture::DynamicRange precision = isHDR ? Texture::DynamicRange::HIGH : Texture::DynamicRange::LOW;
		bool result = Texture2D::Initiate(width, height, nrComponents, precision, data);

		stbi_image_free(data);

		return result;
	}
	else
	{
		return false;
	}
}

void Texture2DFile::Terminate()
{
	Assert(impl);

	return Texture2D::Terminate();
}

////////////////////////////////////////////////////////////////////////////////////
Texture3DFile::Texture3DFile()
	: Texture3D()
{
}

Texture3DFile::~Texture3DFile()
{
	Assert(impl);

	Terminate();
}

bool Texture3DFile::Initiate(const std::string& path_, bool vflip_)
{
	Assert(impl);

	bool isHDR = stbi_is_hdr(path_.c_str());

	int width, height, depth, nrComponents;

	void* data = nullptr;
	if (isHDR)
	{
		data = stbi_loadf(path_.c_str(), &width, &height, &nrComponents, 0);
		if (vflip_)
			stbi__vertical_flip(data, width, height, nrComponents * 4);
	}
	else
	{
		data = stbi_load(path_.c_str(), &width, &height, &nrComponents, 0);
		if (vflip_)
			stbi__vertical_flip(data, width, height, nrComponents * 1);
	}
	depth = 1;

	if (data)
	{
		Texture::DynamicRange precision = isHDR ? Texture::DynamicRange::HIGH : Texture::DynamicRange::LOW;
		bool result = Texture3D::Initiate(width, height, depth, nrComponents, precision, data);

		stbi_image_free(data);

		return result;
	}
	else
	{
		return false;
	}
}

void Texture3DFile::Terminate()
{
	Assert(impl);

	return Texture3D::Terminate();
}

///////////////////////////////////////////////////////////////////////////////////////
TextureCubeMapFile::TextureCubeMapFile()
	: TextureCubemap()
{
}

TextureCubeMapFile::~TextureCubeMapFile()
{
	Assert(impl);

	Terminate();
}

bool TextureCubeMapFile::Initiate(const std::string& path_, bool vflip_)
{
	Assert(impl);

	bool isHDR = stbi_is_hdr(path_.c_str());

	int width, height, nrComponents;
	void* data[6] = { nullptr , nullptr , nullptr , nullptr , nullptr , nullptr };


	bool failed = false;
	for (int i = 0; i < 6; i++)
	{
		std::string pathnoext = path_.substr(0, path_.find_last_of("."));
		std::string ext = path_.substr(path_.find_last_of(".") + 1);
		std::string number = "0";
		number[0] += i;

		std::string cubemapFacePath;
		if (i != 0)
			cubemapFacePath = pathnoext + "_" + number + "." + ext;
		else
			cubemapFacePath = path_;

		if (isHDR)
		{
			data[i] = stbi_loadf(cubemapFacePath.c_str(), &width, &height, &nrComponents, 0);
			if (data[i])
			{
				if (vflip_)
					stbi__vertical_flip(data[i], width, height, nrComponents * 4);
			}
			else
			{
				failed = true;
			}
		}
		else
		{
			data[i] = stbi_load(cubemapFacePath.c_str(), &width, &height, &nrComponents, 0);
			if (data[i])
			{
				if (vflip_)
					stbi__vertical_flip(data[i], width, height, nrComponents * 1);
			}
			else
			{
				failed = true;
			}
		}
	}

	if (!failed)
	{
		Texture::DynamicRange precision = isHDR ? Texture::DynamicRange::HIGH : Texture::DynamicRange::LOW;
		bool result = TextureCubemap::Initiate(width, nrComponents, precision, data);

		for (int i = 0; i < 6; i++)
		{
			if(data[i])
				stbi_image_free(data[i]);
		}
		return true;
	}
	else
	{
		return false;
	}
}

void TextureCubeMapFile::Terminate()
{
	Assert(impl);

	return TextureCubemap::Terminate();
}