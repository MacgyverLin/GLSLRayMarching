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
			, webcam()
			, microphone()
			, soundcloud()
			, texture2d()
			, texturecubemap()
			, texturevideo()
			, buffer()

			, filter()
			, wrap()
			, vflip(false)
		{
		}

		bool IsKeyboard() const
		{
			return keyboard != "";
		}

		bool IsWebcam() const
		{
			return webcam != "";
		}

		bool IsMicrophone() const
		{
			return microphone != "";
		}

		bool IsSoundcloud() const
		{
			return soundcloud != "";
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

		bool IsBuffer() const
		{
			return buffer != "";
		}

		std::string keyboard;
		std::string webcam;
		std::string microphone;
		std::string soundcloud;
		std::string texture2d;
		std::string texturecubemap;
		std::string texturevideo;
		std::string buffer;

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

			if (!CreateCommon(shaderToyDoc))
				return false;

			if (!CreatePasses(shaderToyDoc, folder_, common.GetShaderPath()))
				return false;

			if (!CreatePostprocessPass(
					{ "image" , "keyboard", "buffera", "scaledimage"	},					// input texture
					{ "linear", "nearest" , "nearest", "linear"			},					// input filter
					{ "clamp" , "clamp"   , "clamp"  , "clamp"			},					// input wrap
					"Demos/AMD_FSR/scaledimage.glsl",
					"scaledimage",
					common.GetShaderPath()))
				return false;

			if (!CreatePostprocessPass(
				{ "scaledimage", "buffera", "buffera", "scaledimage" },															// input texture
				{ "linear", "linear" , "linear", "linear" },					// input filter
				{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
				"Demos/AMD_FSR/easu.glsl",
				"easu",
				common.GetShaderPath()))
				return false;

			if (!CreatePostprocessPass(
				{ "easu", "buffera", "buffera", "scaledimage" },																// input texture
				{ "linear", "linear" , "linear", "linear" },					// input filter
				{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
				"Demos/AMD_FSR/rcas.glsl",
				"rcas",
				common.GetShaderPath()))
				return false;

			if (!CreatePostprocessPass(
				{ "image", "easu", "rcas", "scaledimage" },
				{ "linear", "linear" , "linear", "linear" },					// input filter
				{ "clamp" , "clamp"   , "clamp"  , "clamp" },					// input wrap
				"Demos/AMD_FSR/copy.glsl",
				"default",
				common.GetShaderPath()))
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
	bool CreateCommon(rapidjson::Document& shaderToyDoc)
	{
		if (shaderToyDoc.HasMember("common"))
		{
			Value& commonsJson = shaderToyDoc["common"];

			if (commonsJson.HasMember("shader"))
			{
				common.shader = commonsJson["shader"].GetString();
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

	bool CreatePasses(rapidjson::Document& shaderToyDoc, const char* folder_, const char* commonShaderURL)
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
					if (!CreatePass(i, passesJson, folder, commonShaderURL))
						return false;
				}
			}
		}

		return true;
	}

	bool CreatePass(int i, rapidjson::Value& passesJson, std::string& folder, const char* commonShaderURL)
	{
		Value& passJson = passesJson[i];
		if (passJson.IsObject())
		{
			Value& channelsJson = passJson["channels"];

			passes[i].channels.resize(channelsJson.Size());
			for (int j = 0; j < channelsJson.Size(); j++)
			{
				Value& channelJson = channelsJson[j];
				if (channelJson.IsObject())
				{
					if (channelJson.HasMember("filter"))
					{
						passes[i].channels[j].filter = channelJson["filter"].GetString();
					}
					if (channelJson.HasMember("wrap"))
					{
						passes[i].channels[j].wrap = channelJson["wrap"].GetString();
					}
					if (channelJson.HasMember("vflip"))
					{
						passes[i].channels[j].vflip = channelJson["vflip"].GetBool();
					}

					if (channelJson.HasMember("keyboard"))
					{
						passes[i].channels[j].keyboard = "keyboard0";
					}
					else if (channelJson.HasMember("webcam"))
					{
						passes[i].channels[j].webcam = "webcam0";
					}
					else if (channelJson.HasMember("microphone"))
					{
						passes[i].channels[j].microphone = "microphone0";
					}
					else if (channelJson.HasMember("soundcloud"))
					{
						passes[i].channels[j].soundcloud = channelJson["soundcloud"].GetString();
					}
					else if (channelJson.HasMember("texture2d"))
					{
						std::string url(folder);
						url += "/";
						url += channelJson["texture2d"].GetString();

						passes[i].channels[j].texture2d = url;
					}
					else if (channelJson.HasMember("texturecubemap"))
					{
						std::string url = folder;
						url += "/";
						url += channelJson["texturecubemap"].GetString();

						passes[i].channels[j].texturecubemap = url;
					}
					else if (channelJson.HasMember("texturevideo"))
					{
						std::string url = folder;
						url += "/";
						url += channelJson["texturevideo"].GetString();

						passes[i].channels[j].texturevideo = url;
					}
					else if (channelJson.HasMember("buffer"))
					{
						passes[i].channels[j].buffer = channelJson["buffer"].GetString();
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

				passes[i].shader = url;
			}
			else
			{
				Debug("channel%d: must have shader specified\n", i);
			}

			if (passJson.HasMember("rendertarget"))
			{
				passes[i].renderTarget = passJson["rendertarget"].GetString();
			}
			else
			{
				Debug("Pass must have Render Target\n");
				return false;
			}
		}

		return true;
	}

	bool CreatePostprocessPass(	
		const std::vector<const char *> channelBufferNames,	
		const std::vector<const char *> channelFilters,
		const std::vector<const char *> channelWraps,
		const char* shaderFileName, 
		const char* renderTarget,
		const char* commonShaderURL)
	{
		passes.push_back(Pass());

		Pass& pass = passes.back();

		pass.channels.resize(channelBufferNames.size());
		for (int i = 0; i < channelBufferNames.size(); i++)
		{
			pass.channels[i].filter = channelFilters[i];
			pass.channels[i].wrap = channelWraps[i];
			pass.channels[i].vflip = false;

			if (channelBufferNames[i] == "keyboard")
			{
				pass.channels[i].keyboard = "keyboard";
			}
			else if (channelBufferNames[i] == "webcam")
			{
				pass.channels[i].webcam = "webcam";
			}
			else if (channelBufferNames[i] == "microphone")
			{
				pass.channels[i].microphone = "microphone";
			}
			else if (channelBufferNames[i] == "soundcloud")
			{
				pass.channels[i].soundcloud = "soundcloud";
			}
			else if (channelBufferNames[i] == "texture2d")
			{
				pass.channels[i].texture2d = channelBufferNames[i];
			}
			else if (channelBufferNames[i] == "texturecubemap")
			{
				pass.channels[i].texturecubemap = channelBufferNames[i];
			}
			else if (channelBufferNames[i] == "texturevideo")
			{
				pass.channels[i].texturevideo = channelBufferNames[i];
			}
			else
			{
				pass.channels[i].buffer = channelBufferNames[i];
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