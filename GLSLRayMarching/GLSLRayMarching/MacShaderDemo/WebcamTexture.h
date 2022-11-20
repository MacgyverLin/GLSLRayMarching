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
		, buffer(0)
		, webcam(nullptr)
	{
	}

	virtual ~WebcamTexture()
	{
	}

	bool Initiate()
	{
		webcam = Platform::CreateWebCam(0);
		assert(webcam);

		if (!webcam->Initiate())
			return false;

		if (!DynamicTexture2D::Initiate(webcam->GetWidth(), webcam->GetHeight(), 3, Texture::DynamicRange::LOW, nullptr))
			return false;

		return true;
	}

	void Terminate()
	{
		DynamicTexture2D::Terminate();

		if (webcam)
		{
			webcam->Terminate();

			Platform::ReleaseWebCam(webcam);
		}
	}

	virtual void Tick(float dt) override
	{
		if (webcam)
		{
			webcam->Update(buffer);

			DynamicTexture2D::Update(&buffer[0]);
		}
	}
private:
private:
	Platform::WebCam* webcam;
	std::vector<unsigned char> buffer;
};

#endif