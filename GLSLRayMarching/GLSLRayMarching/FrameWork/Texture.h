#ifndef _Texture_h_
#define _Texture_h_

#include "Platform.h"
#include "Vector3.h"

class TextureImpl;

class Texture
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

	enum class Wrap
	{
		Repeat = 0,
		Clamp
	};

	enum class MinFilter
	{
		Nearest = 0,
		Linear,
		NearestMipmapNearest,
		LinearMipmapNearest,
		NearestMipmapLinear,
		LinearMipmapLinear
	};

	enum class MagFilter
	{
		Nearest = 0,
		Linear,
	};

	enum class Format
	{
		R8 = 0,
		R8_SNORM,
		R16F,
		R32F,
		R8UI,
		R8I,
		R16UI,
		R16I,
		R32UI,
		R32I,
		RG8,
		RG8_SNORM,
		RG16F,
		RG32F,
		RG8UI,
		RG8I,
		RG16UI,
		RG16I,
		RG32UI,
		RG32I,
		RGB8,
		SRGB8,
		RGB565,
		RGB8_SNORM,
		R11F_G11F_B10F,
		RGB9_E5,
		RGB16F,
		RGB32F,
		RGB8UI,
		RGB8I,
		RGB16UI,
		RGB16I,
		RGB32UI,
		RGB32I,
		RGBA8,
		SRGB8_ALPHA8,
		RGBA8_SNORM,
		RGB5_A1,
		RGBA4,
		RGB10_A2,
		RGBA16F,
		RGBA32F,
		RGBA8UI,
		RGBA8I,
		RGB10_A2UI,
		RGBA16UI,
		RGBA16I,
		RGBA32I,
		RGBA32UI,
		DEPTH_COMPONENT16,
		DEPTH_COMPONENT24,
		DEPTH_COMPONENT32F,
		DEPTH24_STENCIL8,
		DEPTH32F_STENCIL8,
		STENCIL_INDEX8,

		COMPRESSED_R11_EAC,
		COMPRESSED_SIGNED_R11_EAC,
		COMPRESSED_RG11_EAC,
		COMPRESSED_SIGNED_RG11_EAC,
		COMPRESSED_RGB8_ETC2,
		COMPRESSED_SRGB8_ETC2,
		COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2,
		COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2,
		COMPRESSED_RGBA8_ETC2_EAC,
		COMPRESSED_SRGB8_ALPHA8_ETC2_EAC,
		COMPRESSED_RGBA_ASTC_4x4,
		COMPRESSED_RGBA_ASTC_5x4,
		COMPRESSED_RGBA_ASTC_5x5,
		COMPRESSED_RGBA_ASTC_6x5,
		COMPRESSED_RGBA_ASTC_6x6,
		COMPRESSED_RGBA_ASTC_8x5,
		COMPRESSED_RGBA_ASTC_8x6,
		COMPRESSED_RGBA_ASTC_8x8,
		COMPRESSED_RGBA_ASTC_10x5,
		COMPRESSED_RGBA_ASTC_10x6,
		COMPRESSED_RGBA_ASTC_10x8,
		COMPRESSED_RGBA_ASTC_10x10,
		COMPRESSED_RGBA_ASTC_12x10,
		COMPRESSED_RGBA_ASTC_12x12,
		COMPRESSED_SRGB8_ALPHA8_ASTC_4x4,
		COMPRESSED_SRGB8_ALPHA8_ASTC_5x4,
		COMPRESSED_SRGB8_ALPHA8_ASTC_5x5,
		COMPRESSED_SRGB8_ALPHA8_ASTC_6x5,
		COMPRESSED_SRGB8_ALPHA8_ASTC_6x6,
		COMPRESSED_SRGB8_ALPHA8_ASTC_8x5,
		COMPRESSED_SRGB8_ALPHA8_ASTC_8x6,
		COMPRESSED_SRGB8_ALPHA8_ASTC_8x8,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x5,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x6,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x8,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x10,
		COMPRESSED_SRGB8_ALPHA8_ASTC_12x10,
		COMPRESSED_SRGB8_ALPHA8_ASTC_12x12,
	};

	enum class DynamicRange
	{
		LOW = 0,
		MID,
		HIGH
	};

	Texture(Texture::Type type_);
	virtual ~Texture();

	virtual bool Initiate();
	virtual void Terminate();

	void Bind(unsigned int texStage_);
	void Unbind();

	Texture::Type GetType() const;
	Texture::Format GetFormat()  const;
	unsigned int GetHandle() const;

	void SetWarpS(Texture::Wrap warpS_);
	void SetWarpT(Texture::Wrap warpT_);
	void SetWarpR(Texture::Wrap warpR_);
	void SetMinFilter(Texture::MinFilter minFilter_);
	void SetMagFilter(Texture::MagFilter magFilter_);
	Texture::Wrap GetWarpS() const;
	Texture::Wrap GetWarpT() const;
	Texture::Wrap GetWarpR() const;
	Texture::MinFilter GetMinFilter() const;
	Texture::MagFilter GetMagFilter() const;

	virtual void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const = 0;
public:
protected:
	Texture::Format GetFormat(unsigned int nrComponents_, Texture::DynamicRange dynamicRange_) const;
private:
public:
protected:
	TextureImpl* impl;
private:
};

///////////////////////////////////////////////////////////////////
class Texture1D : public Texture
{
public:
	Texture1D();
	virtual ~Texture1D();

	bool Initiate(unsigned int width_, Texture::Format format_, void* data_);
	bool Initiate(unsigned int width_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* data_);
	void Terminate();

	void Update(unsigned int x_, unsigned int w_, void* src_, int mipLevel_ = -1);
	void Update(void* src_, int mipLevel_ = -1);

	virtual void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetWidth() const;
protected:
private:

public:
protected:
	unsigned int width;
private:
};

class DynamicTexture1D : public Texture1D
{
public:
	DynamicTexture1D()
	{
	}

	virtual ~DynamicTexture1D()
	{
	}

	virtual void Tick(float dt) = 0;
protected:
private:

public:
protected:
private:
};

class Texture2D : public Texture
{
public:
	Texture2D();
	virtual ~Texture2D();

	bool Initiate(unsigned int width_, unsigned int height_, Texture::Format format_, void* src_);
	bool Initiate(unsigned int width_, unsigned int height_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_);
	void Terminate();

	void Update(unsigned int x_, unsigned int y_, unsigned int w_, unsigned int h_, void* src_, int mipLevel_ = -1);
	void Update(void* src_, int mipLevel_ = -1);

	virtual void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetWidth() const;
	unsigned int GetHeight() const;
protected:
private:

public:
protected:
	unsigned int width;
	unsigned int height;
private:
};

class DynamicTexture2D : public Texture2D
{
public:
	DynamicTexture2D()
	{
	}

	virtual ~DynamicTexture2D()
	{
	}

	virtual void Tick(float dt) = 0;
protected:
private:

public:
protected:
private:
};


class Texture3D : public Texture
{
public:
	Texture3D();
	virtual ~Texture3D();

	bool Initiate(unsigned int width_, unsigned int height_, unsigned int depth_, Texture::Format format_, void* src_);
	bool Initiate(unsigned int width_, unsigned int height_, unsigned int depth_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_);
	void Terminate();

	void Update(unsigned int x_, unsigned int y_, unsigned int z_, unsigned int w_, unsigned int h_, unsigned int d_, void* src_, int mipLevel_ = -1);
	void Update(void* src_, int mipLevel_ = -1);

	virtual void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetWidth() const;
	unsigned int GetHeight() const;
	unsigned int GetDepth() const;
protected:
private:

public:
protected:
	unsigned int width;
	unsigned int height;
	unsigned int depth;
private:
};

class DynamicTexture3D : public Texture3D
{
public:
	DynamicTexture3D()
	{
	}

	virtual ~DynamicTexture3D()
	{
	}

	virtual void Tick(float dt) = 0;
protected:
private:

public:
protected:
private:
};


// !!!!!!!!! NEED CHECK all TextureCubemap method, ¡ıº“√» 
class TextureCubemap : public Texture
{
public:
	enum class Side
	{
		POSITIVE_X = 0,
		NEGATIVE_X,
		POSITIVE_Y,
		NEGATIVE_Y,
		POSITIVE_Z,
		NEGATIVE_Z
	};

	TextureCubemap();
	virtual ~TextureCubemap();

	bool Initiate(unsigned int size_, Texture::Format format_, void* src_);
	bool Initiate(unsigned int size_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_);
	void Terminate();

	void Update(Side side_, unsigned int x_, unsigned int y_, unsigned int w_, unsigned int h_, void* src_, int mipLevel_ = -1);
	void Update(Side side_, void* src_, int mipLevel_ = -1);
	void Update(void* src_, int mipLevel_ = -1);

	void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetSize() const;
private:

public:
protected:
private:
	unsigned int size;
	unsigned int faceDataSize;
};

class DynamicTextureCubemap : public TextureCubemap
{
public:
	DynamicTextureCubemap()
	{
	}

	virtual ~DynamicTextureCubemap()
	{
	}

	virtual void Tick(float dt) = 0;
protected:
private:

public:
protected:
private:
};


/////////////////////////////////////////////////////////
class Texture1DArray : public Texture
{
public:
	Texture1DArray();
	virtual ~Texture1DArray();

	bool Initiate(unsigned int layerCount_, unsigned int width_, Texture::Format format_, void* data_);
	bool Initiate(unsigned int layerCount_, unsigned int width_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* data_);
	void Terminate();

	void Update(unsigned int layer_, unsigned int x_, unsigned int w_, void* src_, int mipLevel_ = -1);
	void Update(unsigned int layer_, void* src_, int mipLevel_ = -1);

	virtual void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetWidth() const;
	unsigned int GetLayerCount() const;
protected:
private:

public:
protected:
	unsigned int width;
	unsigned int layerCount;
private:
};

class Texture2DArray : public Texture
{
public:
	Texture2DArray();
	virtual ~Texture2DArray();

	bool Initiate(unsigned int layerCount_, unsigned int width_, unsigned int height_, Texture::Format format_, void* src_);
	bool Initiate(unsigned int layerCount_, unsigned int width_, unsigned int height_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_);
	void Terminate();

	void Update(unsigned int layer_, unsigned int x_, unsigned int y_, unsigned int w_, unsigned int h_, void* src_, int mipLevel_ = -1);
	void Update(unsigned int layer_, void* src_, int mipLevel_ = -1);

	virtual void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetWidth() const;
	unsigned int GetHeight() const;
	unsigned int GetLayerCount() const;
protected:
private:

public:
protected:
	unsigned int width;
	unsigned int height;
	unsigned int layerCount;
private:
};

class TextureCubeMapArray : public Texture
{
public:
	enum class Side
	{
		POSITIVE_X = 0,
		NEGATIVE_X,
		POSITIVE_Y,
		NEGATIVE_Y,
		POSITIVE_Z,
		NEGATIVE_Z
	};

	TextureCubeMapArray();
	virtual ~TextureCubeMapArray();

	bool Initiate(unsigned int layerCount_, unsigned int size_, Texture::Format format_, void* src_);
	bool Initiate(unsigned int layerCount_, unsigned int size_, unsigned int nrComponents_, Texture::DynamicRange dynamicRange_, void* src_);
	void Terminate();

	void Update(unsigned int layer_, Side side_, unsigned int x_, unsigned int y_, unsigned int w_, unsigned int h_, void* src_, int mipLevel_ = -1);
	void Update(unsigned int layer_, Side side_, void* src_, int mipLevel_ = -1);
	void Update(unsigned int layer_, void* src_, int mipLevel_ = -1);

	void GetResolution(unsigned int* w_ = nullptr, unsigned int* h_ = nullptr, unsigned int* d_ = nullptr) const;
	unsigned int GetSize() const;
	unsigned int GetLayerCount() const;
private:

public:
protected:
private:
	unsigned int size;
	unsigned int faceDataSize;
	unsigned int layerCount;
};

///////////////////////////////////////////////////////////////////
class Texture1DFile : public Texture1D
{
public:
	Texture1DFile();
	virtual ~Texture1DFile();

	bool Initiate(const std::string& path_);
	void Terminate();
protected:
private:

public:
protected:
private:

};
class Texture2DFile : public Texture2D
{
public:
	Texture2DFile();
	virtual ~Texture2DFile();

	bool Initiate(const std::string& path_, bool vflip_);
	void Terminate();
protected:
private:

public:
protected:
private:
};

class Texture3DFile : public Texture3D
{
public:
	Texture3DFile();
	virtual ~Texture3DFile();

	bool Initiate(const std::string& path_, bool vflip_);
	void Terminate();
protected:
private:

public:
protected:
private:
};

class TextureCubeMapFile : public TextureCubemap
{
public:
	TextureCubeMapFile();
	virtual ~TextureCubeMapFile();

	bool Initiate(const std::string& path_, bool vflip_);
	void Terminate();
protected:
private:


public:
protected:
private:
};

#endif