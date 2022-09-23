#ifndef _LPVCommon_h_ 
#define _LPVCommon_h_ 

#include "Component.h"
#include "Video.h"
#include "Vector3.h"
#include "Quaternion.h"
#include "Matrix4.h"
#include "Input.h"
#include <map>
#include <string>
#include <vector>

static void vec3transformQuat(Vector3& out, const Vector3& v, const Quaternion& q)
{
	// Matrix4 rot;
	// q.GetRotationMatrix(rot);

	// out = rot * v;
}

static void vec3transformMat4(Vector3& out, const Vector3& v, const Matrix4& m)
{
	// out = m * v;
}

static void quatmultiply(Quaternion& out, const Matrix4& m1, const Quaternion& q)
{
	// Matrix4 m2;
	// q.GetRotationMatrix(m2);

	// out.SetRotationMatrix(m1 * m2);
}

static bool mapHasOwnProperty(const std::map<std::string, std::string>& map, const std::string& includeFileName)
{
	return map.find(includeFileName) != map.end();
}

static bool arrayIncludes(const std::vector<std::string>& arr, const std::string& fileName)
{
	for (auto& a : arr)
	{
		if (a == fileName)
			return true;
	}

	return false;
}


////////////////////////////////////////////////////////////////////////////////
#include "FrameBuffer.h"
#include "Texture.h"
#include "Buffer.h"

class ShadowMapFrameBuffer : public FrameBuffer
{
public:
	ShadowMapFrameBuffer()
		: FrameBuffer()
	{
	}

	virtual ~ShadowMapFrameBuffer()
	{
	}

	virtual bool Initiate(unsigned int width, unsigned int height)
	{
		if (!FrameBuffer::Initiate())
			return false;

		if (!colorBuffer.Initiate(width, height, Texture::Format::R16F, nullptr))
			return false;
		colorBuffer.SetMinFilter(Texture::MinFilter::Nearest);
		colorBuffer.SetMagFilter(Texture::MagFilter::Nearest);
		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, &colorBuffer);


		if (!depthBuffer.Initiate(width, height, Texture::Format::DEPTH_COMPONENT32F, nullptr))
			return false;
		depthBuffer.SetMinFilter(Texture::MinFilter::Nearest);
		depthBuffer.SetMagFilter(Texture::MagFilter::Nearest);
		SetDepthAttachment(&depthBuffer);

		return true;
	}

	virtual void Terminate()
	{
		colorBuffer.Terminate();
		depthBuffer.Terminate();

		return FrameBuffer::Terminate();
	}
private:
	Texture2D colorBuffer;
	Texture2D depthBuffer;
};

class RSMFramebuffer : public FrameBuffer
{
public:
	RSMFramebuffer()
		: FrameBuffer()
	{
	}

	virtual ~RSMFramebuffer()
	{
	}

	virtual bool Initiate(unsigned int width, unsigned int height)
	{
		if (!FrameBuffer::Initiate())
			return false;

		if (!colorBuffer.Initiate(width, height, Texture::Format::RGBA32F, nullptr))
			return false;
		colorBuffer.SetMinFilter(Texture::MinFilter::Nearest);
		colorBuffer.SetMagFilter(Texture::MagFilter::Nearest);
		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0, &colorBuffer);

		if (!positionBuffer.Initiate(width, height, Texture::Format::RGBA32F, nullptr))
			return false;
		positionBuffer.SetMinFilter(Texture::MinFilter::Nearest);
		positionBuffer.SetMagFilter(Texture::MagFilter::Nearest);
		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT1, &positionBuffer);

		if (!normalBuffer.Initiate(width, height, Texture::Format::RGBA32F, nullptr))
			return false;
		normalBuffer.SetMinFilter(Texture::MinFilter::Nearest);
		normalBuffer.SetMagFilter(Texture::MagFilter::Nearest);
		SetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT2, &normalBuffer);

		if (!depthBuffer.Initiate(width, height, Texture::Format::DEPTH_COMPONENT32F, nullptr))
			return false;
		depthBuffer.SetMinFilter(Texture::MinFilter::Nearest);
		depthBuffer.SetMagFilter(Texture::MagFilter::Nearest);
		SetDepthAttachment(&depthBuffer);

		return true;
	}

	virtual void Terminate()
	{
		colorBuffer.Terminate();
		depthBuffer.Terminate();

		return FrameBuffer::Terminate();
	}
private:
	Texture2D colorBuffer;
	Texture2D positionBuffer;
	Texture2D normalBuffer;
	Texture2D depthBuffer;
};

#endif