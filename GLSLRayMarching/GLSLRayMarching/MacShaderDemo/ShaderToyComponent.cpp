#include "ShaderToyComponent.h"
#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "Primitives.h"
#include "GUI.h"
#include "FrameWork.h"

#include <iostream>
#include <fstream>
#include <sstream>

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
using namespace rapidjson;

#include <Windows.h>
#include <WinUser.h>
#include <time.h>

class KeyboardTexture : public Texture2D
{
public:
	KeyboardTexture()
		: Texture2D()
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

	void UpdateKey(Platform::KeyCode keycode)
	{
		unsigned char* keydown = &buffer[256 * 0];
		unsigned char* keyclick = &buffer[256 * 1];
		unsigned char* keytoggle = &buffer[256 * 2];

		keydown[int(keycode)] = Platform::GetKey(keycode) ? 0 : 255;
		keyclick[int(keycode)] = Platform::GetKeyDown(keycode) ? 0 : 255;
		keytoggle[int(keycode)] = Platform::GetKeyHold(keycode) ? 0 : 255;
	}

	virtual void Tick()
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

		Debug("%d\n", buffer[256 * 0 + 98]);

		Texture2D::Update(&buffer[0]);
	}
private:
private:
	std::vector<unsigned char> buffer;
};

class WebcamTexture : public Texture2D
{
public:
	WebcamTexture()
		: Texture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~WebcamTexture()
	{
	}

	bool Initiate(bool vflip_)
	{
		return Texture2D::Initiate(1280, 720, 4, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Update()
	{
		Texture2D::Update(&buffer[0]);
	}

	virtual void Tick() override
	{
	}
private:
private:
	std::vector<char> buffer;
};

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
	}
private:
private:
	std::vector<char> buffer;
};

class SoundCloudTexture : public Texture2D
{
public:
	SoundCloudTexture()
		: Texture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~SoundCloudTexture()
	{
	}

	bool Initiate(const std::string& url, bool vflip_)
	{
		return Texture2D::Initiate(512, 2, 1, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Update()
	{
		Texture2D::Update(&buffer[0]);
	}

	virtual void Tick() override
	{
	}
private:
private:
	std::vector<char> buffer;
};

class VideoTexture : public Texture2D
{
public:
	VideoTexture()
		: Texture2D()
		, buffer(1280 * 720 * 4)
	{
	}

	virtual ~VideoTexture()
	{
	}

	bool Initiate(const std::string& url, bool vflip_)
	{
		return Texture2D::Initiate(1280, 720, 4, Texture::DynamicRange::LOW, &buffer[0]);
	}

	virtual void Update()
	{
		Texture2D::Update(&buffer[0]);
	}

	virtual void Tick() override
	{
	}
private:
private:
	std::vector<char> buffer;
};

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


#define SOUND 0
#define BUFFER_A 1
#define BUFFER_B 2
#define BUFFER_C 3
#define BUFFER_D 4
#define CUBEMAP_A 5
#define IMAGE 6

#define CHANNEL_COUNT 4

class Pass
{
public:
	enum Filter
	{
		Nearest,
		Linear,
		Mipmap
	};

	enum Wrap
	{
		Clamp,
		Repeat,
	};

	class Channel
	{
	public:
		Channel()
			: texture(nullptr)
			, frameBuffer(nullptr)
			, filter(Mipmap)
			, wrap(Repeat)
			, vFlip(true)
		{
		}

		void Terminate()
		{
			texture = nullptr;
			frameBuffer = nullptr;
			filter = Mipmap;
			wrap = Repeat;
			vFlip = true;
		}

		Texture* texture;
		FlipFrameBuffer* frameBuffer;
		Filter filter;
		Wrap wrap;
		bool vFlip;
	};

	Pass()
		: enabled(true)
		, primitives()
		, shaderProgram()
		, iChannels(CHANNEL_COUNT)
		, frameBuffer(nullptr)
	{
	}

	virtual ~Pass()
	{
		Terminate();
	}

	bool Initiate()
	{
		float vertices[] =
		{
			1.0f, -1.0f, 0.0f,  // bottom right
			1.0f,  1.0f, 0.0f,  // top right
			-1.0f, -1.0f, 0.0f,  // bottom left

			-1.0f, -1.0f, 0.0f,  // bottom left
			1.0f,  1.0f, 0.0f,  // top right
			-1.0f,  1.0f, 0.0f   // top left 
		};

		bool success =
			primitives
			.Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, vertices, sizeof(vertices) / sizeof(vertices[0]) / 3)
			.End();
		if (!success)
		{
			return false;
		}

		return true;
	}

	bool Update(unsigned int width, unsigned height, double time, double deltaTime, Vector4 mouse, Vector2 mouseDelta, int frameCounter)
	{
		//int facecount = 1;
		Vector3 resolution;
		if (frameBuffer)
		{
			//if (frameBuffer->GetColorAttachment(GL_COLOR_ATTACHMENT0)->GetType() == GL_TEXTURE_CUBE_MAP)
				//facecount = 6;
			frameBuffer->Bind();

			unsigned int w;
			unsigned int h;
			unsigned int d;
			frameBuffer->GetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0)->GetResolution(&w, &h, &d);
			resolution = Vector3(w, h, d);

			renderStates.viewportState.pos = Vector2(0, 0);
			renderStates.viewportState.size = Vector2(resolution[0], resolution[1]);

			renderStates.scissorTestState.enabled = true;
			renderStates.scissorTestState.pos = Vector2(0, 0);
			renderStates.scissorTestState.size = Vector2(resolution[0], resolution[1]);
		}
		else
		{
			resolution = Vector3(Platform::GetWidth(), Platform::GetHeight(), 1.0);

			renderStates.viewportState.pos = Vector2(0, 0);
			renderStates.viewportState.size = Vector2(width, height);

			renderStates.scissorTestState.enabled = true;
			renderStates.scissorTestState.pos = Vector2(0, 0);
			renderStates.scissorTestState.size = Vector2(width, height);
		}

		renderStates.Apply();

		shaderProgram.Bind();
		shaderProgram.SetUniform3f("iResolution", resolution[0], resolution[1], resolution[2]);
		shaderProgram.SetUniform1f("iTime", (float)time);
		shaderProgram.SetUniform1f("iTimeDelta", (float)deltaTime);
		shaderProgram.SetUniform1f("iFrameRate", 60.0f);
		shaderProgram.SetUniform1i("iFrame", frameCounter);
		shaderProgram.SetUniform4f("iMouse", mouse.X(), mouse.Y(), mouse.Z(), mouse.W());

		//Debug("%f %f %f %f\n", mouse.X(), mouse.Y(), mouse.Z(), mouse.W());
		SYSTEMTIME lt = { 0 };
		GetLocalTime(&lt);
		shaderProgram.SetUniform4f("iDate", (float)lt.wYear - 1, (float)lt.wMonth - 1, (float)lt.wDay, lt.wHour * 60.0f * 60.0f + lt.wMinute * 60.0f + lt.wSecond);
		shaderProgram.SetUniform1f("iSampleRate", 48000.0);

		std::vector<Vector3> channelResolutions(CHANNEL_COUNT);
		std::vector<float> channelTimes(CHANNEL_COUNT);
		for (int i = 0; i < iChannels.size(); i++)
		{
			Texture* texture = nullptr;
			if (iChannels[i].texture)
				texture = iChannels[i].texture;
			else if (iChannels[i].frameBuffer)
				texture = iChannels[i].frameBuffer->GetCurrentTexture();

			if (texture)
			{
				unsigned int w, h, d;
				texture->GetResolution(&w, &h, &d);
				channelResolutions[i].X() = w;
				channelResolutions[i].Y() = h;
				channelResolutions[i].Z() = d;

				channelTimes[i] = 0.0;

				if (iChannels[i].wrap == Pass::Wrap::Repeat)
				{
					texture->SetWarpS(Texture::Wrap::Repeat);
					texture->SetWarpR(Texture::Wrap::Repeat);
					texture->SetWarpT(Texture::Wrap::Repeat);
				}
				else if (iChannels[i].wrap == Pass::Wrap::Clamp)
				{
					texture->SetWarpS(Texture::Wrap::Clamp);
					texture->SetWarpR(Texture::Wrap::Clamp);
					texture->SetWarpT(Texture::Wrap::Clamp);
				}

				if (iChannels[i].filter == Pass::Filter::Nearest)
				{
					texture->SetMinFilter(Texture::MinFilter::Nearest);
					texture->SetMagFilter(Texture::MagFilter::Nearest);
				}
				else if (iChannels[i].filter == Pass::Filter::Linear)
				{
					texture->SetMinFilter(Texture::MinFilter::Linear);
					texture->SetMagFilter(Texture::MagFilter::Linear);
				}
				else if (iChannels[i].filter == Pass::Filter::Mipmap)
				{
					texture->SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
					texture->SetMagFilter(Texture::MagFilter::Linear);
				}

				texture->Bind(i);

				texture->Tick();
			}
			else
			{
				channelResolutions[i] = Vector3(0.0, 0.0, 0.0);
				channelTimes[i] = 0.0;
			}
		}

		shaderProgram.SetUniform3fv("iChannelResolution", CHANNEL_COUNT, &channelResolutions[0][0]);
		shaderProgram.SetUniform1fv("iChannelTime", CHANNEL_COUNT, &channelTimes[0]);


		for (int i = 0; i < CHANNEL_COUNT; i++)
		{
			std::string name = "iChannel";
			name += ('0' + i);

			shaderProgram.SetUniform1i(name.c_str(), i);
		}

		primitives.Bind();
		primitives.DrawArray(Primitives::Mode::TRIANGLES, 0, primitives.GetCount());

		if (frameBuffer)
		{
			frameBuffer->UnBind();
		}

		return true;
	}

	void Flip()
	{
		if (frameBuffer)
		{
			frameBuffer->Flip();
		}
	}

	void Terminate()
	{
		enabled = false;

		renderStates.Terminate();
		shaderProgram.Terminate();

		for (auto& channel : iChannels)
		{
			channel.Terminate();
		}

		frameBuffer = nullptr;
		primitives.Terminate();
	}

	void SetEnabled(bool enabled_)
	{
		this->enabled = enabled_;
	}

	bool GetEnabled() const
	{
		return enabled;
	}

	void SetFilter(int i, Filter filter_)
	{
		this->iChannels[i].filter = filter_;
	}

	void SetWrap(int i, Wrap wrap_)
	{
		this->iChannels[i].wrap = wrap_;
	}

	void SetVFlip(int i, bool vFlip_)
	{
		this->iChannels[i].vFlip = vFlip_;
	}

	void SetChannelTexture(int i, Texture* texture_)
	{
		this->iChannels[i].texture = texture_;
		this->iChannels[i].frameBuffer = nullptr;
	}

	void SetChannelFrameBuffer(int i, FlipFrameBuffer* frameBuffer_)
	{
		this->iChannels[i].texture = nullptr;
		this->iChannels[i].frameBuffer = frameBuffer_;
	}

	const Pass::Channel& GetChannel(int i) const
	{
		return this->iChannels[i];
	}

	void SetFrameBuffer(FlipFrameBuffer* frameBuffer_)
	{
		frameBuffer = frameBuffer_;
	}

	FlipFrameBuffer* GetFrameBuffer() const
	{
		return frameBuffer;
	}

	bool LoadShader(const char* path_, std::string& fShaderCode)
	{
		// 1. retrieve the vertex/fragment source code from filePath
		std::ifstream fShaderFile;
		// ensure ifstream objects can throw exceptions:
		fShaderFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
		try
		{
			// open files
			fShaderFile.open(path_);
			std::stringstream fShaderStream;

			// read file's buffer contents into streams
			fShaderStream << fShaderFile.rdbuf();

			// close file handlers
			fShaderFile.close();

			// convert stream into string
			fShaderCode = fShaderStream.str();
		}
		catch (std::ifstream::failure&)
		{
			return false;
		}

		return true;
	}

	bool SetShader(const char* folder_, const char* fShaderURL_, const char* commonShaderURL_)
	{
		std::string vShaderCode =
			"#version 430 core\n"
			"#extension GL_ARB_shading_language_include : require\n"
			"layout(location = 0) in vec3 aPos;\n"
			"out vec2 fragCoord;\n"
			"uniform vec3 iResolution;\n"
			"uniform float iTime;\n"
			"uniform float iTimeDelta;\n"
			"uniform int iFrame;\n"
			"uniform float iChannelTime[4];\n"
			"uniform vec4 iMouse;\n"
			"uniform vec4 iDate;\n"
			"uniform float iSampleRate;\n"
			"uniform vec3 iChannelResolution[4];\n"
			"void main()\n"
			"{\n"
			"gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
			"fragCoord = (vec2(aPos.x, aPos.y) + 1.0) / 2.0 * iResolution.xy;\n"
			"}\n";

		std::string fShaderHeader =
			"#version 430 core\n"
			"#extension GL_ARB_shading_language_include : require\n"
			"precision highp float;\n"
			"precision highp int;\n"
			"in vec2 fragCoord;\n"
			"out vec4 FragColor;\n"
			"uniform vec3 iResolution;\n"
			"uniform float iTime;\n"
			"uniform float iTimeDelta;\n"
			"uniform int iFrame;\n"
			"uniform float iChannelTime[4];\n"
			"uniform vec4 iMouse;\n"
			"uniform vec4 iDate;\n"
			"uniform float iSampleRate;\n"
			"uniform vec3 iChannelResolution[4];\n"
			;

		std::string fShaderChannels = "";
		for (int i = 0; i < iChannels.size(); i++)
		{
			std::string idx = "0";
			idx[0] += i;

			if (iChannels[i].texture)
			{
				if (iChannels[i].texture->GetType() == Texture::Type::Texture2D)
					fShaderChannels += "uniform sampler2D iChannel" + idx + ";\n";
				else if (iChannels[i].texture->GetType() == Texture::Type::TextureCubeMap)
					fShaderChannels += "uniform samplerCube iChannel" + idx + ";\n";
			}
			else if (iChannels[i].frameBuffer)
			{
				if (iChannels[i].frameBuffer->GetCurrentTexture()->GetType() == Texture::Type::Texture2D)
					fShaderChannels += "uniform sampler2D iChannel" + idx + ";\n";
				else if (iChannels[i].frameBuffer->GetCurrentTexture()->GetType() == Texture::Type::TextureCubeMap)
					fShaderChannels += "uniform samplerCube iChannel" + idx + ";\n";
			}
		}

		std::string fShaderMain =
			"void main()\n"
			"{\n"
			"vec4 fragColor; \n"
			"mainImage(fragColor, fragCoord);\n"
			"FragColor = fragColor;\n"
			"}\n";

		std::string fShaderCode;
		if (fShaderURL_)
		{
			std::string url;
			url = folder_;
			url += "/";
			url += fShaderURL_;
			if (!LoadShader(url.c_str(), fShaderCode))
			{
				Debug("failed to load shader\n", url.c_str());
				return false;
			}
		}

		std::string commonShaderCode;
		if (commonShaderURL_)
		{
			std::string url;
			url = folder_;
			url += "/";
			url += commonShaderURL_;
			if (!LoadShader(url.c_str(), commonShaderCode))
			{
				Debug("failed to load shader\n", url.c_str());
				return false;
			}
		}

		std::string fShader = fShaderHeader + "\n" +
			fShaderChannels + "\n" +
			commonShaderCode + "\n" +
			fShaderCode + "\n" +
			fShaderMain;
		{
			FILE* fptr = fopen("test.log", "wt");
			if (fptr)
			{
				fprintf(fptr, "%s\n", fShader.c_str());
				fclose(fptr);
			}
		}

		return shaderProgram.CreateFromSource(vShaderCode.c_str(), fShader.c_str());
	}
protected:
private:

public:
protected:
private:
	bool enabled;

	RenderStates renderStates;
	ShaderProgram shaderProgram;
	std::vector<Channel> iChannels;
	FlipFrameBuffer* frameBuffer;
	Primitives primitives;
};

class MacShaderDemo
{
public:
	MacShaderDemo()
		: textures()
		, black()
		, soundFrameBuffer()
		, bufferAFrameBuffer()
		, bufferBFrameBuffer()
		, bufferCFrameBuffer()
		, bufferDFrameBuffer()
		, cubeMapAFrameBuffer()
		, cubeMapBFrameBuffer()
		, cubeMapCFrameBuffer()
		, cubeMapDFrameBuffer()

		, imageFrameBuffer()
		, scaledImageFrameBuffer()
		, easuFrameBuffer()
		, rcasFrameBuffer()

		, passes()
	{
	}

	virtual ~MacShaderDemo()
	{
	}

	std::string ToLower(const char* str)
	{
		std::string result = str;

		for (int i = 0; i < result.size(); i++)
		{
			result[i] = tolower(result[i]);
		}

		return result;
	}

	Pass::Filter GetFilter(const char* str)
	{
		std::string s = ToLower(str);

		if (s == "nearest")
		{
			return Pass::Filter::Nearest;
		}
		else if (s == "linear")
		{
			return Pass::Filter::Linear;
		}
		else// if (s == "mipmap")
		{
			return Pass::Filter::Mipmap;
		}
	}

	Pass::Wrap GetWrap(const char* str)
	{
		std::string s = ToLower(str);

		if (s == "clamp")
		{
			return Pass::Wrap::Clamp;
		}
		else// if (s == "repeat")
		{
			return Pass::Wrap::Repeat;
		}
	}

	FlipFrameBuffer* GetFrameBuffer(const char* str)
	{
		std::string s = ToLower(str);

		if (s == "sound")
		{
			return &soundFrameBuffer;
		}
		else if (s == "buffera")
		{
			return &bufferAFrameBuffer;
		}
		else if (s == "bufferb")
		{
			return &bufferBFrameBuffer;
		}
		else if (s == "bufferc")
		{
			return &bufferCFrameBuffer;
		}
		else if (s == "bufferd")
		{
			return &bufferDFrameBuffer;
		}
		else if (s == "cubemapa")
		{
			return &cubeMapAFrameBuffer;
		}
		else if (s == "cubemapb")
		{
			return &cubeMapBFrameBuffer;
		}
		else if (s == "cubemapc")
		{
			return &cubeMapCFrameBuffer;
		}
		else if (s == "cubemapd")
		{
			return &cubeMapDFrameBuffer;
		}
		else if (s == "image")
		{
			return &imageFrameBuffer;
		}
		else if (s == "scaledimage")
		{
			return &scaledImageFrameBuffer;
		}
		else if (s == "easu")
		{
			return &easuFrameBuffer;
		}
		else if (s == "rcas")
		{
			return &rcasFrameBuffer;
		}		
		else if (s == "default")
		{
			return nullptr;
		}
		else
			return nullptr;
	}

	Texture* AddKeyboardTexture()
	{
		KeyboardTexture* texture = new KeyboardTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate())
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	Texture* AddWebcamTexture(bool vflip_)
	{
		WebcamTexture* texture = new WebcamTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(vflip_))
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	Texture* AddMicrophoneTexture()
	{
		MicrophoneTexture* texture = new MicrophoneTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate())
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	Texture* AddSoundCloudTexture(const char* url_, bool vflip_)
	{
		SoundCloudTexture* texture = new SoundCloudTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(url_, vflip_))
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	Texture* AddTexture2D(const char* path, bool vflip_)
	{
		Texture2DFile* texture = new Texture2DFile();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(path, vflip_))
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	Texture* AddTextureCubemap(const char* path, bool vflip_)
	{
		TextureCubeMapFile* texture = new TextureCubeMapFile();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(path, vflip_))
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	Texture* AddVideoTexture(const char* path, bool vflip_)
	{
		VideoTexture* texture = new VideoTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(path, vflip_))
		{
			delete texture;
			return nullptr;
		}

		textures.push_back(texture);
		return texture;
	}

	void DebugLog(const char* msg)
	{
		Debug("Error: %s\n", msg);
	}

	bool Initiate(const char* folder_)
	{
		if (!InitiateScene(folder_, "scene.json"))
			return false;

		return true;
	}

	bool InitiateScene(const char* folder_, const char* scenefile_)
	{
		std::string folder = folder_;

		// 1. retrieve the vertex/fragment source code from filePath
		std::string url;
		std::string shaderToyCode;
		std::ifstream shaderToyFile;
		// ensure ifstream objects can throw exceptions:
		shaderToyFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
		try
		{
			url = folder;
			url += "/";
			url += scenefile_;

			// open files
			shaderToyFile.open(url.c_str());
			std::stringstream shaderToyStream;

			// read file's buffer contents into streams
			shaderToyStream << shaderToyFile.rdbuf();

			// close file handlers
			shaderToyFile.close();

			// convert stream into string
			shaderToyCode = shaderToyStream.str();
		}
		catch (std::ifstream::failure&)
		{
			Debug("Failed to Open %s\n", url.c_str());
			return false;
		}

		///////////////////////////////////
		// glsl include file
		ShaderProgram::AddShaderHeaderFile("ffx_a.h");
		ShaderProgram::AddShaderHeaderFile("ffx_fsr1.h");
		ShaderProgram::AddShaderHeaderFile("savestate.h");

		///////////////////////////////////
		// shadertoy config
		Document shaderToyDoc;
		shaderToyDoc.Parse(shaderToyCode.c_str());
		const char* commonShaderURL = CreateCommon(shaderToyDoc);

		std::vector<char> colors(32 * 32 * 4);
		memset(&colors[0], 0, (32 * 32 * 4));
		if (!black.Initiate(32, 32, 4, Texture::DynamicRange::LOW, &colors[0]))
			return false;
		if (!soundFrameBuffer.Initiate(512, 2, 1, Texture::DynamicRange::LOW))
			return false;
		if (!bufferAFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!bufferBFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!bufferCFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!bufferDFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!cubeMapAFrameBuffer.Initiate(1024, 4, Texture::DynamicRange::HIGH))
			return false;
		if (!cubeMapBFrameBuffer.Initiate(1024, 4, Texture::DynamicRange::HIGH))
			return false;
		if (!cubeMapCFrameBuffer.Initiate(1024, 4, Texture::DynamicRange::HIGH))
			return false;
		if (!cubeMapDFrameBuffer.Initiate(1024, 4, Texture::DynamicRange::HIGH))
			return false;

		if (!imageFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!scaledImageFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!easuFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		if (!rcasFrameBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;
		
		if (!CreatePasses(shaderToyDoc, folder, commonShaderURL))
			return false;

		return true;
	}

	const char* CreateCommon(rapidjson::Document& shaderToyDoc)
	{
		if (shaderToyDoc.HasMember("common"))
		{
			Value& commonsJson = shaderToyDoc["common"];

			if (commonsJson.HasMember("shader"))
			{
				return commonsJson["shader"].GetString();
			}
		}

		return nullptr;
	}

	bool CreatePasses(rapidjson::Document& shaderToyDoc, std::string& folder, const char* commonShaderURL)
	{
		if (shaderToyDoc.HasMember("passes"))
		{
			Value& passesJson = shaderToyDoc["passes"];
			if (passesJson.IsArray())
			{
				passes.resize(passesJson.Size() + 4);

				for (int i = 0; i < passesJson.Size(); i++)
				{
					if (!CreatePass(i, passesJson, folder, commonShaderURL))
						return false;
				}

				if (!CreatePostprocessPass
				(
					passes[passesJson.Size() + 0],
					{ "image", "keyboard", "default", "scaledimage" },																// input texture
					{ Pass::Filter::Linear, Pass::Filter::Nearest, Pass::Filter::Nearest, Pass::Filter::Linear },					// input filter
					{ Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp },						// input wrap
					"scaledimage.glsl",
					"scaledimage",
					commonShaderURL))
					return false;

				if (!CreatePostprocessPass
				(
					passes[passesJson.Size() + 1],
					{ "scaledimage", "default", "default", "scaledimage" },															// input texture
					{ Pass::Filter::Linear /* Linear? */, Pass::Filter::Linear, Pass::Filter::Linear, Pass::Filter::Linear },		// input filter
					{ Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp },						// input wrap
					"easu.glsl",
					"easu",
					commonShaderURL))
					return false;

				if (!CreatePostprocessPass
				(
					passes[passesJson.Size() + 2],
					{ "easu", "default", "default", "scaledimage" },																// input texture
					{ Pass::Filter::Linear, Pass::Filter::Linear, Pass::Filter::Linear, Pass::Filter::Linear },						// input filter
					{ Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp },						// input wrap
					"rcas.glsl",
					"rcas",
					commonShaderURL))
					return false;

				if (!CreatePostprocessPass
				(
					passes[passesJson.Size() + 3],
					{ "image", "easu", "rcas", "scaledimage"},
					{ Pass::Filter::Linear, Pass::Filter::Linear, Pass::Filter::Linear, Pass::Filter::Linear },
					{ Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp   , Pass::Wrap::Clamp },
					"copy.glsl",
					"default",
					commonShaderURL)
					)
					return false;
			}
		}

		return true;
	}

	bool CreatePostprocessPass(Pass& pass, 
								const std::vector<const char*> channelBufferNames,
								const std::vector<Pass::Filter> channelFilters,
								const std::vector<Pass::Wrap> channelWraps,
								const char* shaderFileName, const char* renderTargetName, const char* commonShaderURL)
	{
		if (!pass.Initiate())
		{
			Debug("Failed to CreatePostprocessPass %d\n");
			return false;
		}

		pass.SetEnabled(true);

		for (int i = 0; i < CHANNEL_COUNT; i++)
		{
			pass.SetFilter(i, channelFilters[i]);
			pass.SetWrap(i, channelWraps[i]); 
			pass.SetVFlip(i, false);		
			if (channelBufferNames[i]=="keyboard")
			{
				Texture* texture = AddKeyboardTexture();
				if (!texture)
					return false;

				pass.SetChannelTexture(i, texture);
			}
			else if (channelBufferNames[i] == "webcam")
			{
				Texture* texture = AddWebcamTexture(pass.GetChannel(i).vFlip);
				if (!texture)
					return false;

				pass.SetChannelTexture(i, texture);
			}
			else if (channelBufferNames[i] == "microphone")
			{
				Texture* texture = AddMicrophoneTexture();
				if (!texture)
					return false;

				pass.SetChannelTexture(i, texture);
			}
			else if (channelBufferNames[i] == "soundcloud")
			{
				/*
				std::string url = channelJson["soundcloud"].GetString();

				Texture* texture = AddSoundCloudTexture(url.c_str(), pass.GetChannel(j).vFlip);
				if (!texture)
				{
					Debug("channel %d: failed to load soundcloud %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(i, texture);
				*/
			}
			else if (channelBufferNames[i] == "texture2d")
			{
				/*
				Texture* texture = LoadTexture2D(folder, channelJson, i, j);
				if (!texture)
				{
					Debug("channel %d: failed to load texture2d %s\n", i, url.c_str());
					return false;
				}

				pass.SetChannelTexture(i, texture);
				return true;
				*/
				return false;
			}
			else if (channelBufferNames[i] == "texturecubemap")
			{
				/*
				std::string url = folder;
				url += "/";
				url += channelJson["texturecubemap"].GetString();

				Texture* texture = AddTextureCubemap(url.c_str(), pass.GetChannel(i).vFlip);
				if (!texture)
				{
					Debug("channel %d: failed to load texturecubemap %s\n", i, url.c_str());
					return false;
				}

				pass.SetChannelTexture(i, texture);
				*/
			}
			else if (channelBufferNames[i] == "texturevideo")
			{
				/*
				std::string url = folder;
				url += "/";
				url += channelJson["texturevideo"].GetString();

				Texture* texture = AddVideoTexture(url.c_str(), pass.GetChannel(i).vFlip);
				if (!texture)
				{
					Debug("channel %d: failed to load texture video %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(i, texture);
				*/
			}
			else
			{
				pass.SetChannelFrameBuffer(i, GetFrameBuffer(channelBufferNames[i]));
			}
		}
		if (!pass.SetShader("Demos/AMD_FSR", shaderFileName, commonShaderURL))
			return false;

		pass.SetFrameBuffer(GetFrameBuffer(renderTargetName));

		return true;
	}

	bool CreatePass(int i, rapidjson::Value& passesJson, std::string& folder, const char* commonShaderURL)
	{
		Value& passJson = passesJson[i];
		if (passJson.IsObject())
		{
			if (!passes[i].Initiate())
			{
				Debug("Failed to Create Pass %d\n", i);
				return false;
			}

			passes[i].SetEnabled(true);

			for (int j = 0; j < CHANNEL_COUNT; j++)
			{
				passes[i].SetChannelTexture(j, &black);

				std::string name = "ichannel";
				name += ('0' + j);

				if (passJson.HasMember(name.c_str()))
				{
					Value& channelJson = passJson[name.c_str()];
					if (channelJson.IsObject())
					{
						if (channelJson.HasMember("filter"))
						{
							Pass::Filter channelFilter = GetFilter(channelJson["filter"].GetString());
							passes[i].SetFilter(j, channelFilter);
						}
						if (channelJson.HasMember("wrap"))
						{
							Pass::Wrap channelWrap = GetWrap(channelJson["wrap"].GetString());
							passes[i].SetWrap(j, channelWrap);
						}
						if (channelJson.HasMember("vflip"))
						{
							bool vFlip = channelJson["vflip"].GetBool();
							passes[i].SetVFlip(j, vFlip);
						}

						if (channelJson.HasMember("keyboard"))
						{
							Texture* texture = AddKeyboardTexture();
							if (!texture)
								return false;

							passes[i].SetChannelTexture(j, texture);
						}
						else if (channelJson.HasMember("webcam"))
						{
							Texture* texture = AddWebcamTexture(passes[i].GetChannel(j).vFlip);
							if (!texture)
								return false;

							passes[i].SetChannelTexture(j, texture);
						}
						else if (channelJson.HasMember("microphone"))
						{
							Texture* texture = AddMicrophoneTexture();
							if (!texture)
								return false;

							passes[i].SetChannelTexture(j, texture);
						}
						else if (channelJson.HasMember("soundcloud"))
						{
							std::string url = channelJson["soundcloud"].GetString();

							Texture* texture = AddSoundCloudTexture(url.c_str(), passes[i].GetChannel(j).vFlip);
							if (!texture)
							{
								Debug("channel %d: failed to load soundcloud %s\n", j, url.c_str());
								return false;
							}

							passes[i].SetChannelTexture(j, texture);
						}
						else if (channelJson.HasMember("texture2d"))
						{
							if (!LoadTexture2D(folder, channelJson, i, j))
								return false;
						}
						else if (channelJson.HasMember("texturecubemap"))
						{
							std::string url = folder;
							url += "/";
							url += channelJson["texturecubemap"].GetString();

							Texture* texture = AddTextureCubemap(url.c_str(), passes[i].GetChannel(j).vFlip);
							if (!texture)
							{
								Debug("channel %d: failed to load texturecubemap %s\n", j, url.c_str());
								return false;
							}

							passes[i].SetChannelTexture(j, texture);
						}
						else if (channelJson.HasMember("texturevideo"))
						{
							std::string url = folder;
							url += "/";
							url += channelJson["texturevideo"].GetString();

							Texture* texture = AddVideoTexture(url.c_str(), passes[i].GetChannel(j).vFlip);
							if (!texture)
							{
								Debug("channel %d: failed to load texture video %s\n", j, url.c_str());
								return false;
							}

							passes[i].SetChannelTexture(j, texture);
						}
						else if (channelJson.HasMember("buffer"))
						{
							std::string buffername = channelJson["buffer"].GetString();

							FlipFrameBuffer* fb = GetFrameBuffer(buffername.c_str());
							if (!fb)
							{
								Debug("channel %d: buffer=%s is not supported\n", j, buffername.c_str());
								return false;
							}

							passes[i].SetChannelFrameBuffer(j, fb);
						}
						else
						{
							Debug("channel%d: must have texture or frame buffer specified or texture type is not supported\n", j);
							return false;
						}
					}
				}
			}

			if (passJson.HasMember("shader"))
			{
				const char* shaderURL = passJson["shader"].GetString();
				if (!passes[i].SetShader(folder.c_str(), shaderURL, commonShaderURL))
				{
					return false;
				}
			}
			else
			{
				Debug("channel%d: must have shader specified\n", i);
			}

			if (passJson.HasMember("rendertarget"))
			{
				std::string rendertargetname = passJson["rendertarget"].GetString();

				if (rendertargetname != "default")
				{
					FlipFrameBuffer* rendertarget = this->GetFrameBuffer(rendertargetname.c_str());
					if (!rendertarget)
					{
						Debug("rendertarget=%s not supported\n", rendertargetname.c_str());
						return false;
					}

					passes[i].SetFrameBuffer(rendertarget);
				}
				else
				{
					passes[i].SetFrameBuffer(nullptr);
				}
			}
			else
			{
				Debug("Pass must have Render Target\n");
				return false;
			}
		}

		return true;
	}

	bool LoadTexture2D(std::string& folder, rapidjson::Value& channelJson, int i, int j)
	{
		std::string url = folder;
		url += "/";
		url += channelJson["texture2d"].GetString();

		Texture* texture = AddTexture2D(url.c_str(), passes[i].GetChannel(j).vFlip);
		if (!texture)
		{
			Debug("channel %d: failed to load texture2d %s\n", j, url.c_str());
			return false;
		}

		passes[i].SetChannelTexture(j, texture);
		return true;
	}

	bool Update(unsigned int width, unsigned int height, double time, double deltaTime, Vector4 mouse, Vector2 mouseDelta, int frameCounter)
	{
		for (auto& pass : passes)
		{
			if (!pass.GetEnabled())
				continue;

			if (!pass.Update(width, height, time, deltaTime, mouse, mouseDelta, frameCounter))
				return false;

			pass.Flip();
		}

		return true;
	}

	void Terminate()
	{
		for (auto texture : textures)
		{
			if (texture)
			{
				texture->Terminate();

				delete texture;
				texture = nullptr;
			}
		}
		textures.clear();

		black.Terminate();

		soundFrameBuffer.Terminate();
		bufferAFrameBuffer.Terminate();
		bufferBFrameBuffer.Terminate();
		bufferCFrameBuffer.Terminate();
		bufferDFrameBuffer.Terminate();
		cubeMapAFrameBuffer.Terminate();
		cubeMapBFrameBuffer.Terminate();
		cubeMapCFrameBuffer.Terminate();
		cubeMapDFrameBuffer.Terminate();

		imageFrameBuffer.Terminate();
		scaledImageFrameBuffer.Terminate();
		easuFrameBuffer.Terminate();
		rcasFrameBuffer.Terminate();
	}
protected:
private:
	std::vector<Texture*> textures;
	Texture2D black;

	FlipTexture2DFrameBuffer soundFrameBuffer;
	FlipTexture2DFrameBuffer bufferAFrameBuffer;
	FlipTexture2DFrameBuffer bufferBFrameBuffer;
	FlipTexture2DFrameBuffer bufferCFrameBuffer;
	FlipTexture2DFrameBuffer bufferDFrameBuffer;
	FlipTextureCubeMapFrameBuffer cubeMapAFrameBuffer;
	FlipTextureCubeMapFrameBuffer cubeMapBFrameBuffer;
	FlipTextureCubeMapFrameBuffer cubeMapCFrameBuffer;
	FlipTextureCubeMapFrameBuffer cubeMapDFrameBuffer;

	FlipTexture2DFrameBuffer imageFrameBuffer;
	FlipTexture2DFrameBuffer scaledImageFrameBuffer;
	FlipTexture2DFrameBuffer easuFrameBuffer;
	FlipTexture2DFrameBuffer rcasFrameBuffer;

	std::vector<Pass> passes;
};

//////////////////////////////////////////////////////////////
ShaderToyComponent::ShaderToyComponent(GameObject& gameObject_)
	: Graphics3Component(gameObject_)
{
	macShaderDemo = new MacShaderDemo();
}

ShaderToyComponent::~ShaderToyComponent()
{
	if (macShaderDemo)
	{
		delete macShaderDemo;
		macShaderDemo = nullptr;
	}
}

Vector4 ShaderToyComponent::GetMouse()
{
	static Vector4 r;

	if (Platform::GetKeyDown(Platform::KeyCode::Mouse0))
	{
		r.Z() = 1;
		r.W() = 1;

		r.X() = Platform::GetMouseX();
		r.Y() = Platform::GetMouseY();
	}
	else if (Platform::GetKeyUp(Platform::KeyCode::Mouse0))
	{
		r.Z() = -1;
		r.W() = 0;
	}
	else if (Platform::GetKeyHold(Platform::KeyCode::Mouse0))
	{
		r.Z() = 1;
		r.W() = 0;

		r.X() = Platform::GetMouseX();
		r.Y() = Platform::GetMouseY();
	}

	//Debug("%f %f %f %f\n", r.X(), r.Y(), r.Z(), r.W());

	return r;
}

void ShaderToyComponent::OnRender()
{
	macShaderDemo->Update
	(
		Platform::GetWidth(),
		Platform::GetHeight(),
		Platform::GetTime(),
		Platform::GetDeltaTime(),
		GetMouse(),
		Vector2(Platform::GetMouseDX(), Platform::GetMouseDY()),
		Platform::GetSceneFrameCounter() - 1
	);
}

bool ShaderToyComponent::OnInitiate()
{
	return true;
}

bool ShaderToyComponent::OnStart()
{
	//return macShaderDemo->Initiate("Demos/default");
	//return macShaderDemo->Initiate("Demos/Path Tracing Cornell Box 2");
	//return macShaderDemo->Initiate("Demos/Path Tracing (+ELS)");
	//return macShaderDemo->Initiate("Demos/PathTracings/Path tracing cornellbox with MIS");
	//return macShaderDemo->Initiate("Demos/[NV15] Space Curvature");
	//return macShaderDemo->Initiate("Demos/Buoy");
	//return macShaderDemo->Initiate("Demos/Music - Pirates");
	//return macShaderDemo->Initiate("Demos/Fork Heartfelt Nepse 180");
	//return macShaderDemo->Initiate("Demos/Rainier mood");
	//return macShaderDemo->Initiate("Demos/Noise/Perlin");//
	//return macShaderDemo->Initiate("Demos/Clouds/Cheap Cloud Flythrough");//
	//return macShaderDemo->Initiate("Demos/Clouds/Cloud");//
	//return macShaderDemo->Initiate("Demos/Clouds/CloudFight");//
	//return macShaderDemo->Initiate("Demos/Clouds/Cloud2");//
	//return macShaderDemo->Initiate("Demos/default");
	//return macShaderDemo->Initiate("Demos/Greek Temple");
	//return macShaderDemo->Initiate("Demos/JustForFuns/Hexagonal Grid Traversal - 3D");		
	//return macShaderDemo->Initiate("Demos/JustForFuns/MO");
	//return macShaderDemo->Initiate("Demos/PathTracings/Bidirectional path tracing");
	//return macShaderDemo->Initiate("Demos/PathTracings/Demofox Path Tracing 1");
	//return macShaderDemo->Initiate("Demos/PathTracings/Demofox Path Tracing 2");
	//return macShaderDemo->Initiate("Demos/PathTracings/Path Tracer MIS");
	//return macShaderDemo->Initiate("Demos/PathTracings/PBR Material Gold");
	//return macShaderDemo->Initiate("Demos/PathTracings/Room DI");
	//return macShaderDemo->Initiate("Demos/PathTracings/Monte Carlo path tracer");
	//return macShaderDemo->Initiate("Demos/Post process - SSAO");
	//return macShaderDemo->Initiate("Demos/Biplanar mapping");
	//return macShaderDemo->Initiate("Demos/Scattering/Atmospheric scattering explained");
	//return macShaderDemo->Initiate("Demos/Scattering/Atmospheric Scattering Fog");
	//return macShaderDemo->Initiate("Demos/Scattering/Fast Atmospheric Scattering");
	//return macShaderDemo->Initiate("Demos/Scattering/RayleighMieDayNight");
	//return macShaderDemo->Initiate("Demos/Scattering/RealySimpleAtmosphericScatter");
	//return macShaderDemo->Initiate("Demos/Terrains/Cloudy Terrain");
	//return macShaderDemo->Initiate("Demos/Terrains/Desert Sand");
	//return macShaderDemo->Initiate("Demos/Terrains/Elevated");
	//return macShaderDemo->Initiate("Demos/Terrains/Lake in highland");
	//return macShaderDemo->Initiate("Demos/Terrains/Mountains");
	//return macShaderDemo->Initiate("Demos/Terrains/Rainforest");
	//return macShaderDemo->Initiate("Demos/Terrains/Sirenian Dawn");
	return macShaderDemo->Initiate("Demos/SimpleTexture");	

	//return macShaderDemo->Initiate("Demos/Waters/RiverGo");
	//return macShaderDemo->Initiate("Demos/Waters/RiverGo");
	//return macShaderDemo->Initiate("Demos/Waters/Oceanic");
	//return macShaderDemo->Initiate("Demos/Waters/Ocean");
	//return macShaderDemo->Initiate("Demos/Waters/Very fast procedural ocean");
	//return macShaderDemo->Initiate("Demos/Waters/Water World");
	//return macShaderDemo->Initiate("Demos/Wave Propagation Effect");
	//return macShaderDemo->Initiate("Demos/Beneath the Sea God Ray");
	//return macShaderDemo->Initiate("Demos/Scattering/VolumetricIntegration");
	//return macShaderDemo->Initiate("Demos/Waters/Spout");

	//return macShaderDemo->Initiate("Demos/PathTracings/Path Tracer MIS");
	//return macShaderDemo->Initiate("Demos/PathTracings/Bidirectional path tracing");
	//return macShaderDemo->Initiate("Demos/PathTracings/Room DI");
	//return macShaderDemo->Initiate("Demos/PathTracings/Spatiotemporal Variance-Guided Filtering");
	//return macShaderDemo->Initiate("Demos/PathTracings/StepByStepTutorial");
	//return macShaderDemo->Initiate("Demos/PathTracings/Cornell MIS");	
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/5 Caustics");

	//return macShaderDemo->Initiate("Demos/PathTracings/Course/8 SubSurface");	
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/7 Disney Principled BRDF");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/6 PBR");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/5 Caustics");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/4 Bidirectional path tracing");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/3 Path Tracer MIS");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/2 Light Sampling");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/1 Simple Random Sampling");	
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/9 Step By Step");
	//return macShaderDemo->Initiate("Demos/PathTracings/Course/10 Step By Step");
}

bool ShaderToyComponent::OnUpdate()
{
	return true;
}

bool ShaderToyComponent::OnPause()
{
	return true;
}

void ShaderToyComponent::OnResume()
{
}

void ShaderToyComponent::OnStop()
{
}

void ShaderToyComponent::OnTerminate()
{
}