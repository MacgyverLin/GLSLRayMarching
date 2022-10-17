#ifndef _Pass_h_
#define _Pass_h_

#include "ShaderToyComponent.h"
#include "Texture.h"
#include "FrameBuffer.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "GUI.h"
#include "FrameWork.h"
#include "FlipFrameBuffer.h"

#include <iostream>
#include <fstream>
#include <sstream>

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
using namespace rapidjson;

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
			, buffer(nullptr)
			, filter(Mipmap)
			, wrap(Repeat)
			, vFlip(true)
		{
		}

		void Terminate()
		{
			texture = nullptr;
			buffer = nullptr;
			filter = Mipmap;
			wrap = Repeat;
			vFlip = true;
		}

		Texture* texture;
		FrameBuffer* buffer;
		Filter filter;
		Wrap wrap;
		bool vFlip;
	};

	Pass()
		: enabled(true)
		, vertexBuffer()
		, shaderProgram()
		, iChannels(CHANNEL_COUNT)
		, renderTarget(nullptr)
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
			vertexBuffer
			.Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, vertices, sizeof(vertices) / sizeof(vertices[0]) / 3)
			.End();
		if (!success)
		{
			return false;
		}

		return true;
	}

	bool Render(unsigned int width, unsigned height, double time, double deltaTime, Vector4 mouse, Vector2 mouseDelta, int frameCounter)
	{
		int facecount = 1;

		Vector3 resolution;
		if (renderTarget)
		{
			renderTarget->Bind();

			unsigned int w;
			unsigned int h;
			unsigned int d;
			renderTarget->GetColorAttachment(FrameBuffer::ColorAttachment::COLOR_ATTACHMENT0)->GetResolution(&w, &h, &d);
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

		////////////
		// renderState
		renderStates.Apply();

		////////////
		// Bind Shader Uniform
		shaderProgram.Bind();
		shaderProgram.SetUniform3f("iResolution", resolution[0], resolution[1], resolution[2]);
		shaderProgram.SetUniform1f("iTime", (float)time);
		shaderProgram.SetUniform1f("iTimeDelta", (float)deltaTime);
		shaderProgram.SetUniform1f("iFrameRate", 60.0f);
		shaderProgram.SetUniform1i("iFrame", frameCounter);
		shaderProgram.SetUniform4f("iMouse", mouse.X(), mouse.Y(), mouse.Z(), mouse.W());
		//Debug("%f %f %f %f\n", mouse.X(), mouse.Y(), mouse.Z(), mouse.W());
		
		Platform::SystemTime lt = Platform::GetSystemTime();
		shaderProgram.SetUniform4f("iDate", (float)lt.wYear - 1, (float)lt.wMonth - 1, (float)lt.wDay, lt.wHour * 60.0f * 60.0f + lt.wMinute * 60.0f + lt.wSecond);
		shaderProgram.SetUniform1f("iSampleRate", 48000.0);

		////////////////////////////////////////////////
		// Bind Channels
		std::vector<Vector3> channelResolutions(CHANNEL_COUNT);
		std::vector<float> channelTimes(CHANNEL_COUNT);
		for (int i = 0; i < iChannels.size(); i++)
		{
			Texture* texture = nullptr;
			if (iChannels[i].texture)
			{
				texture = iChannels[i].texture;
			}
			else if (iChannels[i].buffer)
			{
				if (iChannels[i].buffer->GetType() == FrameBuffer::Type::Texture2D)
					texture = ((TextureFrameBuffer2D*)iChannels[i].buffer)->GetTexture();
				else if (iChannels[i].buffer->GetType() == FrameBuffer::Type::TextureCubemap)
					texture = ((TextureFrameBufferCubemap*)iChannels[i].buffer)->GetTexture();
				else
				{
					::Debug("Channel%d: channel texture must be either 2D cubemap");
					return false;
				}
			}

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

		//////////////////////////////////////////////////
		// Draw
		vertexBuffer.Bind();
		vertexBuffer.DrawArray(VertexBuffer::Mode::TRIANGLES, 0, vertexBuffer.GetCount());

		//////////////////////////////////////////////////
		// Flip buffer
		if (renderTarget)
		{
			if (renderTarget->GetType() == FrameBuffer::Type::Texture2D)
				((TextureFrameBuffer2D*)renderTarget)->Flip();
			else if (renderTarget->GetType() == FrameBuffer::Type::TextureCubemap)
				((TextureFrameBufferCubemap*)renderTarget)->Flip();
			else
			{
				::Debug("Channel%d: channel texture must be either 2D cubemap");
			}
		}

		//////////////////////////////////////////////////
		// Clean Up
		if (renderTarget)
		{
			renderTarget->UnBind();
		}

		return true;
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

		renderTarget = nullptr;
		vertexBuffer.Terminate();
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
		this->iChannels[i].buffer = nullptr;
	}

	void SetChannelBuffer(int i, FrameBuffer* renderTarget_)
	{
		this->iChannels[i].texture = nullptr;
		this->iChannels[i].buffer = renderTarget_;
	}

	const Pass::Channel& GetChannel(int i) const
	{
		return this->iChannels[i];
	}

	void SetRenderTarget(FrameBuffer* renderTarget_)
	{
		renderTarget = renderTarget_;
	}

	FrameBuffer* GetRenderTarget() const
	{
		return renderTarget;
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

	bool SetShader(const char* path_, const char* commonShaderURL_)
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
				else if (iChannels[i].texture->GetType() == Texture::Type::TextureCubemap)
					fShaderChannels += "uniform samplerCube iChannel" + idx + ";\n";
			}
			else if (iChannels[i].buffer)
			{
				if (iChannels[i].buffer->GetType() == FrameBuffer::Type::Texture2D)
					fShaderChannels += "uniform sampler2D iChannel" + idx + ";\n";
				else if (iChannels[i].buffer->GetType() == FrameBuffer::Type::TextureCubemap)
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
		if (path_)
		{
			std::string url = path_;
			if (!LoadShader(url.c_str(), fShaderCode))
			{
				Debug("failed to load shader\n", url.c_str());
				return false;
			}
		}

		std::string commonShaderCode;
		if (commonShaderURL_)
		{
			std::string url = commonShaderURL_;
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
		
		
		FILE* fptr = fopen("test.log", "wt");
		if (fptr)
		{
			fprintf(fptr, "%s\n", fShader.c_str());
			fclose(fptr);
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
	FrameBuffer* renderTarget;
	VertexBuffer vertexBuffer;
};

#endif