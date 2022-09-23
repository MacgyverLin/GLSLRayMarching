#ifndef _LPVShaderLoader_h_ 
#define _LPVShaderLoader_h_ 

#include "Component.h"
#include "Video.h"
#include "LPVCommon.h"
#include <regex>

class LPVShaderLoader
{
public:
	class ShaderProgramInfo
	{
	public:
		std::string name;
		std::string vsFileName;
		std::string fsFileName;
	};

	class ShaderResult
	{
	public:
		std::string vertexSource;
		std::string fragmentSource;
	};
	LPVShaderLoader(const char* pathPrefix_);

	virtual ~LPVShaderLoader();

	void AddShaderFile(const std::string& fileName);
	void AddShaderProgram(const std::string& name, const std::string& vsFileName, const std::string& fsFileName);
	void Load(std::function<void(std::map<std::string, ShaderResult>&)> onload);
private:
	void OnCompletion(std::function<void(std::map<std::string, ShaderResult>&)> onload);
	const std::string PathForFileName(const std::string& fileName);
	const std::string ResolveSource(const std::string& source);
public:
	virtual void OnRender();

	virtual bool OnInitiate();

	virtual bool OnStart();

	virtual bool OnUpdate();

	virtual bool OnPause();

	virtual void OnResume();

	virtual void OnStop();

	virtual void OnTerminate();
private:
	std::string pathPrefix;
	std::string includeRegEx;
	std::vector<std::string> shaderFiles;
	std::map<std::string, std::string> shaders;
	std::vector<ShaderProgramInfo> shaderPrograms;
};

#endif