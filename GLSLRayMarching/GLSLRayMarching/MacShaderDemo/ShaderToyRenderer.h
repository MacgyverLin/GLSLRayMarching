#ifndef _ShaderToyRenderer_h_ 
#define _ShaderToyRenderer_h_

#include "Component.h"
#include "Video.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "VertexBuffer.h"
#include "Texture.h"
#include "FrameBuffer.h"
#include "GUI.h"
#include "FrameWork.h"

#include "FlipFrameBuffer.h"
#include "KeyboardTexture.h"
#include "MicrophoneTexture.h"
#include "SoundCloudTexture.h"
#include "VideoTexture.h"
#include "WebcamTexture.h"
#include "Pass.h"
#include "ShaderToyConfig.h"

#include "Audio.h"

class ShaderToyRenderer
{
public:
	ShaderToyRenderer(Audio::StreamSourceComponent& streamSourceComponent_)
		: staticTextures()
		, dynamicTextures()
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
		
		, backBuffer()

		, passes()

		, streamSourceComponent(streamSourceComponent_)
	{
	}

	virtual ~ShaderToyRenderer()
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

	FrameBuffer* GetRenderTarget(const std::string& s)
	{
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
		else if (s == "cubemapbuffera")
		{
			return &cubeMapAFrameBuffer;
		}
		else if (s == "cubemapbufferb")
		{
			return &cubeMapBFrameBuffer;
		}
		else if (s == "cubemapbufferc")
		{
			return &cubeMapCFrameBuffer;
		}
		else if (s == "cubemapbufferd")
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
		else if (s == "backbuffer")
		{
			return &backBuffer;
		}
		else
			return nullptr;
	}

	Texture* AddKeyboardTexture(const char* url_)
	{
		KeyboardTexture* texture = new KeyboardTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate())
		{
			delete texture;
			return nullptr;
		}

		dynamicTextures.push_back(texture);
		return texture;
	}

	Texture* AddWebcamTexture(const char* url_, bool vflip_)
	{
		WebcamTexture* texture = new WebcamTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(vflip_))
		{
			delete texture;
			return nullptr;
		}

		dynamicTextures.push_back(texture);
		return texture;
	}

	Texture* AddMicrophoneTexture(const char* url_)
	{
		MicrophoneTexture* texture = new MicrophoneTexture();
		if (!texture)
			return nullptr;
		if (!texture->Initiate())
		{
			delete texture;
			return nullptr;
		}

		dynamicTextures.push_back(texture);
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

		dynamicTextures.push_back(texture);
		return texture;
	}

	Texture2D* AddTexture2D(const char* path, bool vflip_)
	{
		Texture2DFile* texture = new Texture2DFile();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(path, vflip_))
		{
			delete texture;
			return nullptr;
		}

		staticTextures.push_back(texture);
		return texture;
	}

	TextureCubemap* AddTextureCubemap(const char* path, bool vflip_)
	{
		TextureCubeMapFile* texture = new TextureCubeMapFile();
		if (!texture)
			return nullptr;
		if (!texture->Initiate(path, vflip_))
		{
			delete texture;
			return nullptr;
		}

		staticTextures.push_back(texture);
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

		dynamicTextures.push_back(texture);
		return texture;
	}

	bool Initiate(const char* folder_)
	{
		if (!InitiateScene(folder_, "scene.json"))
			return false;

		streamSourceComponent.Play();

		return streamSourceComponent.IsPlaying();
	}

	bool InitiateScene(const char* folder_, const char* scenefile_)
	{
		ShaderToyConfig shaderToyConfig;
		if (!shaderToyConfig.Parse(folder_, scenefile_))
			return false;

		///////////////////////////////////
		// glsl include file
		ShaderProgram::AddShaderHeaderFile("ffx_a.h");
		ShaderProgram::AddShaderHeaderFile("ffx_fsr1.h");
		ShaderProgram::AddShaderHeaderFile("savestate.h");

		///////////////////////////////////
		// shadertoy config
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

		if (!backBuffer.Initiate(Platform::GetWidth(), Platform::GetHeight(), 4, Texture::DynamicRange::HIGH))
			return false;

		if (!CreatePasses(shaderToyConfig))
			return false;

		return true;
	}

	bool CreatePasses(const ShaderToyConfig& shaderToyConfig)
	{
		passes.resize(shaderToyConfig.GetPassCount());

		for (int i = 0; i < shaderToyConfig.GetPassCount(); i++)
		{
			if (!CreatePass(passes[i], shaderToyConfig.GetPass(i), shaderToyConfig.GetCommon()))
				return false;
		}

		return true;
	}

	bool CreatePass(Pass& pass, const ShaderToyConfig::Pass& passConfig, const ShaderToyConfig::Common& common)
	{
		////////////////////////////////////////////////////////////////
		// Initiate pass
		if (!pass.Initiate())
		{
			Debug("Failed to Create Pass %d\n");
			return false;
		}

		pass.SetEnabled(true);

		//////////////////////////////////////////////////////
		// Setup pass's channels
		for (int j = 0; j < passConfig.channels.size(); j++)
		{
			//////////////////////////////////////////////////////
			// default black texture
			pass.SetChannelTexture(j, &black);

			const ShaderToyConfig::Channel& channel = passConfig.channels[j];

			//////////////////////////////////////////////////////
			// Setup channels's texture filter
			Pass::Filter channelFilter = GetFilter(channel.filter.c_str());
			pass.SetFilter(j, channelFilter);

			//////////////////////////////////////////////////////
			// Setup channels's texture wrap
			Pass::Wrap channelWrap = GetWrap(channel.wrap.c_str());
			pass.SetWrap(j, channelWrap);

			//////////////////////////////////////////////////////
			// Setup channels's texture vflip
			bool channelVFlip = channel.vflip;
			pass.SetVFlip(j, channelVFlip);

			//////////////////////////////////////////////////////
			// Setup channels's texture
			if (channel.IsKeyboard())
			{
				std::string url = channel.keyboard;  	// !!!!!!!!! TODO, Áõ¼ÒÃÈ

				Texture* texture = AddKeyboardTexture(url.c_str());
				if (!texture)
				{
					Debug("channel %d: failed to load soundcloud %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsMicrophone()) 
			{
				std::string url = channel.microphone;  	// !!!!!!!!! TODO, Áõ¼ÒÃÈ

				Texture* texture = AddMicrophoneTexture(url.c_str());
				if (!texture)
				{
					Debug("channel %d: failed to load soundcloud %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsSoundcloud())
			{
				std::string url = channel.soundcloud;  	// !!!!!!!!! TODO, Áõ¼ÒÃÈ

				Texture* texture = AddSoundCloudTexture(url.c_str(), pass.GetChannel(j).vFlip);
				if (!texture)
				{
					Debug("channel %d: failed to load soundcloud %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsSound())	
			{
				FrameBuffer* fb = GetRenderTarget(channel.sound); 			// !!!!!!!!! TODO, Áõ¼ÒÃÈ 
				if (!fb)
				{
					Debug("channel %d: buffer=%s is not supported\n", j, channel.sound.c_str());
					return false;
				}

				pass.SetChannelBuffer(j, fb);
			}
			else if (channel.IsTexture2d())
			{
				std::string url = channel.texture2d;
				Texture2D* texture = LoadTexture2D(url, pass, j);
				if (!texture)
					return false;

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsTextureCubemap())	// !!!!!!!!! TODO, Áõ¼ÒÃÈ
			{
				std::string url = channel.texturecubemap;
				TextureCubemap* texture = LoadTextureCube(url, pass, j);
				if (!texture)
					return false;

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsTextureVideo())		// !!!!!!!!! TODO, Áõ¼ÒÃÈ
			{
				std::string url = channel.texturevideo.c_str();

				Texture* texture = AddVideoTexture(url.c_str(), pass.GetChannel(j).vFlip);
				if (!texture)
				{
					Debug("channel %d: failed to load texture video %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsWebcam())			// !!!!!!!!! TODO, Áõ¼ÒÃÈ
			{
				std::string url = channel.microphone;  	// !!!!!!!!! TODO, Áõ¼ÒÃÈ

				Texture* texture = AddWebcamTexture(url.c_str(), pass.GetChannel(j).vFlip);
				if (!texture)
				{
					Debug("channel %d: failed to load soundcloud %s\n", j, url.c_str());
					return false;
				}

				pass.SetChannelTexture(j, texture);
			}
			else if (channel.IsBuffer())
			{
				FrameBuffer* fb = GetRenderTarget(channel.buffer);
				if (!fb)
				{
					Debug("channel %d: buffer=%s is not supported\n", j, channel.buffer.c_str());
					return false;
				}

				pass.SetChannelBuffer(j, fb);
			}
			else if (channel.IsCubemapBuffer())	// !!!!!!!!! TODO, Áõ¼ÒÃÈ
			{
				FrameBuffer* fb = GetRenderTarget(channel.cubemapbuffer);
				if (!fb)
				{
					Debug("channel %d: buffer=%s is not supported\n", j, channel.buffer.c_str());
					return false;
				}

				pass.SetChannelBuffer(j, fb);
			}
			else
			{
				Debug("channel%d: must have texture or frame buffer specified or texture type is not supported\n", j);
				return false;
			}
		}

		std::string rendertargetname = passConfig.renderTarget;
		if (rendertargetname == "backbuffer")
		{
			pass.SetRenderTarget(nullptr);
		}
		else
		{
			FrameBuffer* rendertarget = this->GetRenderTarget(rendertargetname);
			if (!rendertarget)
			{
				Debug("rendertarget=%s not supported\n", rendertargetname.c_str());
				return false;
			}
			pass.SetRenderTarget(rendertarget);
		}

		if (!pass.CreateShader(passConfig.shader.c_str(), common.GetShaderPath()))
		{
			return false;
		}

		return true;
	}

	Texture2D* LoadTexture2D(const std::string& url, Pass& pass, int j)
	{
		Texture2D* texture = AddTexture2D(url.c_str(), pass.GetChannel(j).vFlip);
		if (!texture)
		{
			Debug("channel %d: failed to load texture2d %s\n", j, url.c_str());
			return nullptr;
		}

		return texture;
	}

	TextureCubemap* LoadTextureCube(const std::string& url, Pass& pass, int j)
	{
		TextureCubemap* texture = AddTextureCubemap(url.c_str(), pass.GetChannel(j).vFlip);
		if (!texture)
		{
			Debug("channel %d: failed to load texturecubemap %s\n", j, url.c_str());
			return nullptr;
		}

		return texture;
	}

	bool Render(unsigned int width, unsigned int height, double time, double deltaTime, Vector4 mouse, Vector2 mouseDelta, int frameCounter)
	{
		for (auto& pass : passes)
		{
			if (!pass.GetEnabled())
				continue;

			if (!pass.Render(width, height, time, deltaTime, mouse, mouseDelta, frameCounter))
				return false;
		}

		for(int i=0 ;i< dynamicTextures.size(); i++)
			dynamicTextures[i]->Tick(deltaTime);

		/*
		std::vector<char> data;
		streamSourceComponent.GetSineWaveData(data, 1000, 1.0f);
		//streamSourceComponent.GetEmptyData(data);
		streamSourceComponent.FillData(&data[0], data.size());
		*/

		return true;
	}

	void Terminate()
	{
		for (auto& texture : staticTextures)
		{
			if (texture)
			{
				texture->Terminate();

				delete texture;
				texture = nullptr;
			}
		}
		staticTextures.clear();

		for (auto& texture : dynamicTextures)
		{
			if (texture)
			{
				texture->Terminate();

				delete texture;
				texture = nullptr;
			}
		}
		dynamicTextures.clear();

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

		backBuffer.Terminate();
	}
protected:
private:
	std::vector<Texture*> staticTextures;
	std::vector<DynamicTexture2D*> dynamicTextures;
	Texture2D black;

	//KeyboardTexture keyboardTexture;
	//WebcamTexture webcamTexture;
	//MicrophoneTexture microphoneTexture;

	TextureFrameBuffer2D soundFrameBuffer;
	TextureFrameBuffer2D bufferAFrameBuffer;
	TextureFrameBuffer2D bufferBFrameBuffer;
	TextureFrameBuffer2D bufferCFrameBuffer;
	TextureFrameBuffer2D bufferDFrameBuffer;
	TextureFrameBufferCubemap cubeMapAFrameBuffer;
	TextureFrameBufferCubemap cubeMapBFrameBuffer;
	TextureFrameBufferCubemap cubeMapCFrameBuffer;
	TextureFrameBufferCubemap cubeMapDFrameBuffer;

	TextureFrameBuffer2D imageFrameBuffer;
	TextureFrameBuffer2D scaledImageFrameBuffer;
	TextureFrameBuffer2D easuFrameBuffer;
	TextureFrameBuffer2D rcasFrameBuffer;

	BackBuffer backBuffer;

	std::vector<Pass> passes;

	Audio::StreamSourceComponent& streamSourceComponent;
};

#endif