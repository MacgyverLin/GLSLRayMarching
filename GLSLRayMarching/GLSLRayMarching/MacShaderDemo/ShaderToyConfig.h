#ifndef _ShaderToyConfig_h_
#define _ShaderToyConfig_h_

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
using namespace rapidjson;

class ShaderToyConfig
{
public:
	class Common
	{
	public:
		Common()
			: valid(false)
			, shader()
		{
		}

		const char* GetShaderPath() const
		{
			if (valid)
			{
				return shader.c_str();
			}
			else
			{
				return nullptr;
			}
		}

		bool IsValid() const
		{
			return valid;
		}

		std::string shader;
		bool valid;
	};

	class Channel
	{
	public:
		Channel()
			: keyboard()

			, microphone()
			, soundcloud()
			, sound()

			, texture2d()
			, texturecubemap()
			, texturevideo()
			, webcam()

			, buffer()
			, cubemapbuffer()

			, filter()
			, wrap()
			, vflip(false)
		{
		}

		bool IsKeyboard() const
		{
			return keyboard != "";
		}

		bool IsMicrophone() const
		{
			return microphone != "";
		}

		bool IsSoundcloud() const
		{
			return soundcloud != "";
		}

		bool IsSound() const
		{
			return sound != "";
		}

		bool IsTexture2d() const
		{
			return texture2d != "";
		}

		bool IsTextureCubemap() const
		{
			return texturecubemap != "";
		}

		bool IsTextureVideo() const
		{
			return texturevideo != "";
		}

		bool IsWebcam() const
		{
			return webcam != "";
		}

		bool IsBuffer() const
		{
			return buffer != "";
		}

		bool IsCubemapBuffer() const
		{
			return cubemapbuffer != "";
		}

		std::string keyboard;
		std::string microphone;
		std::string sound;
		std::string soundcloud;
		std::string texture2d;
		std::string texturecubemap;
		std::string texturevideo;
		std::string webcam;
		std::string buffer;
		std::string cubemapbuffer;

		std::string filter;
		std::string wrap;
		bool vflip;
	};

	class Pass
	{
	public:
		std::string shader;
		std::vector<Channel> channels;
		std::string renderTarget;
	};

	ShaderToyConfig()
	{
	}

	~ShaderToyConfig()
	{
	}

	bool Parse(const char* folder_, const char* scenefile_)
	{
		std::string folder = folder_;

		// 1. retrieve the vertex/fragment source code from filePath
		// ensure ifstream objects can throw exceptions:
		std::string url;
		std::ifstream shaderToyFile;
		std::string shaderToyCode;

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

			Document shaderToyDoc;
			shaderToyDoc.Parse(shaderToyCode.c_str());

			if (!CreateCommon(shaderToyDoc, folder_))
				return false;

			if (!CreatePasses(shaderToyDoc, folder_))
				return false;

			if (!CreatePostprocessPasses())
				return false;
		}
		catch (std::ifstream::failure&)
		{
			Debug("Failed to Open %s\n", url.c_str());
			return false;
		}

		return true;
	}

	const Common& GetCommon() const
	{
		return common;
	}

	int GetPassCount() const
	{
		return passes.size();
	}

	const Pass& GetPass(int i) const
	{
		return passes[i];
	}
private:
	bool CreateCommon(rapidjson::Document& shaderToyDoc, const char *folder)
	{
		if (shaderToyDoc.HasMember("common"))
		{
			Value& commonsJson = shaderToyDoc["common"];

			if (commonsJson.HasMember("shader"))
			{
				std::string url = folder;
				url += "/";
				url += commonsJson["shader"].GetString();

				common.shader = url;
				common.valid = true;
			}
			else
			{
				common.shader = "";
				common.valid = false;
			}
		}
		else
		{
			common.shader = "";
			common.valid = false;
		}

		return true;
	}

	bool CreatePasses(rapidjson::Document& shaderToyDoc, const char* folder_)
	{
		std::string folder = folder_;

		if (shaderToyDoc.HasMember("passes"))
		{
			Value& passesJson = shaderToyDoc["passes"];
			if (passesJson.IsArray())
			{
				passes.resize(passesJson.Size());
				for (int i = 0; i < passesJson.Size(); i++)
				{
					if (!CreatePass(passes[i], passesJson[i], folder))
						return false;
				}
			}
		}

		return true;
	}

	static bool IsValidChannelTextureName(const std::string& texturename_)
	{
		return texturename_ == "keyboard" ||
			texturename_ == "microphone" || texturename_ == "soundcloud" ||
			texturename_ == "texture2d" || texturename_ == "texturecubemap" || texturename_ == "texturevideo" || texturename_ == "webcam" ||
			texturename_ == "buffera" || texturename_ == "bufferb" || texturename_ == "bufferc" || texturename_ == "bufferd" ||
			texturename_ == "cubemapbuffera" || texturename_ == "cubemapbufferb" || texturename_ == "cubemapbufferc" || texturename_ == "cubemapbufferd" ||
			IsValidRenderTargetName(texturename_);
	}

	static bool IsValidRenderTargetName(const std::string& rendertargetname_)
	{
		return 
			rendertargetname_ == "backbuffer" ||
			rendertargetname_ == "sound" ||
			rendertargetname_ == "image" || rendertargetname_ == "scaledimage" || rendertargetname_ == "easu" || rendertargetname_ == "rcas" ||
			rendertargetname_ == "buffera" || rendertargetname_ == "bufferb" || rendertargetname_ == "bufferc" || rendertargetname_ == "bufferd" ||
			rendertargetname_ == "cubemapbuffera" || rendertargetname_ == "cubemapbufferb" || rendertargetname_ == "cubemapbufferc" || rendertargetname_ == "cubemapbufferd";
	}

	const std::string& GetJSONStringLowerCase(const rapidjson::Value& value)
	{
		static std::string data;

		data = value.GetString();

		std::transform(data.begin(), data.end(), data.begin(),
			[](unsigned char c)
		{
			return std::tolower(c);
		}
		);

		return data;
	}

	bool CreatePass(Pass& pass, const rapidjson::Value& passJson, std::string& folder)
	{
		if (passJson.IsObject())
		{
			const Value& channelsJson = passJson["channels"];

			pass.channels.resize(channelsJson.Size());
			for (int j = 0; j < channelsJson.Size(); j++)
			{
				const Value& channelJson = channelsJson[j];
				if (channelJson.IsObject())
				{
					if (channelJson.HasMember("filter"))
					{
						pass.channels[j].filter = GetJSONStringLowerCase(channelJson["filter"]);
					}
					if (channelJson.HasMember("wrap"))
					{
						pass.channels[j].wrap = GetJSONStringLowerCase(channelJson["wrap"]);
					}
					if (channelJson.HasMember("vflip"))
					{
						pass.channels[j].vflip = channelJson["vflip"].GetBool();
					}

					if (channelJson.HasMember("keyboard"))
					{
						pass.channels[j].keyboard = "keyboard";
					}
					else if (channelJson.HasMember("microphone"))
					{
						pass.channels[j].microphone = "microphone";
					}
					else if (channelJson.HasMember("soundcloud"))
					{
						std::string url(folder);
						url += "/";
						url += channelJson["soundcloud"].GetString();

						pass.channels[j].soundcloud = url;
					}
					else if (channelJson.HasMember("sound"))
					{
						pass.channels[j].sound = "sound";
					}
					else if (channelJson.HasMember("texture2d"))
					{
						std::string url(folder);
						url += "/";
						url += channelJson["texture2d"].GetString();

						pass.channels[j].texture2d = url;
					}
					else if (channelJson.HasMember("texturecubemap"))
					{
						std::string url = folder;
						url += "/";
						url += channelJson["texturecubemap"].GetString();

						pass.channels[j].texturecubemap = url;
					}
					else if (channelJson.HasMember("texturevideo"))
					{
						std::string url = folder;
						url += "/";
						url += channelJson["texturevideo"].GetString();

						pass.channels[j].texturevideo = url;
					}
					else if (channelJson.HasMember("webcam"))
					{
						pass.channels[j].webcam = "webcam";
					}
					else if (channelJson.HasMember("buffer"))
					{
						pass.channels[j].buffer = GetJSONStringLowerCase(channelJson["buffer"]);
						if (!IsValidChannelTextureName(pass.channels[j].buffer))
						{
							Debug("IsValidChannelTextureName: %s\n", pass.channels[j].buffer);
							return false;
						}
					}
					else if (channelJson.HasMember("cubemapbuffer"))
					{
						pass.channels[j].cubemapbuffer = GetJSONStringLowerCase(channelJson["cubemapbuffer"]);
						if (!IsValidChannelTextureName(pass.channels[j].cubemapbuffer))
						{
							Debug("IsValidRenderTargetName: %s\n", pass.channels[j].cubemapbuffer);
							return false;
						}
					}
					else
					{
						Debug("channel%d: must have texture or frame buffer specified or texture type is not supported\n", j);
						return false;
					}
				}
			}

			if (passJson.HasMember("shader"))
			{
				std::string url = folder;
				url += "/";
				url += passJson["shader"].GetString();

				pass.shader = url;
			}
			else
			{
				Debug("channel: must have shader specified\n");
			}

			if (passJson.HasMember("rendertarget"))
			{
				pass.renderTarget = GetJSONStringLowerCase(passJson["rendertarget"]);
				if (!IsValidRenderTargetName(pass.renderTarget))
				{
					Debug("IsValidRenderTargetName: %s\n", pass.renderTarget);
					return false;
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

	bool CreatePostprocessPasses()
	{
		/*
		if (!CreatePostprocessPass(
			{ "image" , "keyboard", "buffera", "scaledimage" },					// input texture
			{ "linear", "nearest" , "nearest", "linear" },					// input filter
			{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
			"Demos/AMD_FSR/scaledimage.glsl",
			"scaledimage",
			commonShaderPath))
			return false;

		if (!CreatePostprocessPass(
			{ "scaledimage", "buffera", "buffera", "scaledimage" },															// input texture
			{ "linear", "linear" , "linear", "linear" },					// input filter
			{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
			"Demos/AMD_FSR/easu.glsl",
			"easu",
			commonShaderPath))
			return false;

		if (!CreatePostprocessPass(
			{ "easu", "buffera", "buffera", "scaledimage" },																// input texture
			{ "linear", "linear" , "linear", "linear" },					// input filter
			{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
			"Demos/AMD_FSR/rcas.glsl",
			"rcas",
			commonShaderPath))
			return false;
		*/
		if (!CreatePostprocessPass(
			{ "image", "buffera", "buffera", "buffera" },
			{ "linear", "linear" , "linear", "linear" },					// input filter
			{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
			"Demos/Copy/copy.glsl",
			"backbuffer"))
			return false;

		return true;
	}

	bool CreatePostprocessPass(
		const std::vector<const char*> channelTextureNames,
		const std::vector<const char*> channelFilters,
		const std::vector<const char*> channelWraps,
		const char* shaderFileName,
		const char* renderTarget)
	{
		for (int i = 0; i < channelTextureNames.size(); i++)
		{
			if (!IsValidChannelTextureName(channelTextureNames[i]))
			{
				Debug("IsValidChannelTextureName: %s\n", channelTextureNames[i]);
				return false;
			}
		}

		if (!IsValidRenderTargetName(renderTarget))
		{
			Debug("IsValidRenderTargetName: %s\n", renderTarget);
			return false;
		}

		passes.push_back(Pass());

		Pass& pass = passes.back();

		pass.channels.resize(channelTextureNames.size());
		for (int i = 0; i < channelTextureNames.size(); i++)
		{
			pass.channels[i].filter = channelFilters[i];
			pass.channels[i].wrap = channelWraps[i];
			pass.channels[i].vflip = false;

			if (channelTextureNames[i] == "keyboard")
			{
				pass.channels[i].keyboard = "keyboard";
			}
			else if (channelTextureNames[i] == "microphone")
			{
				pass.channels[i].microphone = "microphone";
			}
			else if (channelTextureNames[i] == "soundcloud")
			{
				pass.channels[i].soundcloud = "soundcloud";
			}
			else if (channelTextureNames[i] == "sound")
			{
				pass.channels[i].sound = "sound";
			}
			else if (channelTextureNames[i] == "texture2d")
			{
				pass.channels[i].texture2d = channelTextureNames[i];
			}
			else if (channelTextureNames[i] == "texturecubemap")
			{
				pass.channels[i].texturecubemap = channelTextureNames[i];
			}
			else if (channelTextureNames[i] == "texturevideo")
			{
				pass.channels[i].texturevideo = channelTextureNames[i];
			}
			else if (channelTextureNames[i] == "webcam")
			{
				pass.channels[i].webcam = "webcam";
			}
			else if (channelTextureNames[i] == "buffera" ||
				channelTextureNames[i] == "bufferb" ||
				channelTextureNames[i] == "bufferc" ||
				channelTextureNames[i] == "bufferd" ||
				channelTextureNames[i] == "image" ||
				channelTextureNames[i] == "scaledimage" ||
				channelTextureNames[i] == "easu" ||
				channelTextureNames[i] == "rcas")
			{
				pass.channels[i].buffer = channelTextureNames[i];
			}
			else if (channelTextureNames[i] == "cubemapbuffera" ||
				channelTextureNames[i] == "cubemapbufferb" ||
				channelTextureNames[i] == "cubemapbufferc" ||
				channelTextureNames[i] == "cubemapbufferd")
			{
				pass.channels[i].cubemapbuffer = channelTextureNames[i];
			}
			else
			{
				Debug("channel%d: must have texture or frame buffer specified. or Texture type is not supported\n", i);
				return false;
			}
		}

		pass.shader = shaderFileName;

		pass.renderTarget = renderTarget;

		return true;
	}
private:
	Common common;
	std::vector<Pass> passes;
};

#endif