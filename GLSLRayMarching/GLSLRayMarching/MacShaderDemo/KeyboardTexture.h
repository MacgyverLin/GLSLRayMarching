#ifndef _KeyboardTexture_h_
#define _KeyboardTexture_h_

#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

class KeyboardTexture : public DynamicTexture2D
{
public:
	KeyboardTexture()
		: DynamicTexture2D()
		, buffer(256 * 3)
	{
		MemSet(&buffer[0], 0, buffer.size());
	}

	virtual ~KeyboardTexture()
	{
	}

	bool Initiate()
	{
		if (!Texture2D::Initiate(256, 3, 1, Texture::DynamicRange::LOW, &buffer[0]))
			return false;

		SetMinFilter(Texture::MinFilter::Nearest);
		SetMagFilter(Texture::MagFilter::Nearest);
		SetWarpS(Texture::Wrap::Clamp);
		SetWarpR(Texture::Wrap::Clamp);
		SetWarpT(Texture::Wrap::Clamp);

		return true;
	}

	// ...............................................
	// ...............................................
	// ...............................................
	void UpdateKey(Platform::KeyCode keycode)
	{
		unsigned char* keydown = &buffer[256 * 0];
		unsigned char* keyclick = &buffer[256 * 1];
		unsigned char* keytoggle = &buffer[256 * 2];

		keydown[int(keycode)] = Platform::GetKey(keycode) ? 0 : 255;
		keyclick[int(keycode)] = Platform::GetKeyDown(keycode) ? 0 : 255;
		keytoggle[int(keycode)] = Platform::GetKeyHold(keycode) ? 0 : 255;
	}

	virtual void Tick(float dt) override
	{
		for (int keycode = (int)Platform::KeyCode::A; keycode <= (int)Platform::KeyCode::Z; keycode += 1)
		{
			UpdateKey((Platform::KeyCode)keycode);
		}

		UpdateKey(Platform::KeyCode::LeftArrow);
		UpdateKey(Platform::KeyCode::RightArrow);
		UpdateKey(Platform::KeyCode::UpArrow);
		UpdateKey(Platform::KeyCode::DownArrow);
		UpdateKey(Platform::KeyCode::End);
		UpdateKey(Platform::KeyCode::Home);
		UpdateKey(Platform::KeyCode::LeftShift);
		UpdateKey(Platform::KeyCode::RightShift);
		UpdateKey(Platform::KeyCode::LeftControl);
		UpdateKey(Platform::KeyCode::RightControl);
		UpdateKey(Platform::KeyCode::LeftAlt);
		UpdateKey(Platform::KeyCode::RightAlt);

		DynamicTexture2D::Update(&buffer[0]);
	}
private:
private:
	std::vector<unsigned char> buffer;
};


#endif