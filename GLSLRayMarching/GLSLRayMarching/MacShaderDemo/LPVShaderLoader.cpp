#include "LPVShaderLoader.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVShaderLoader::LPVShaderLoader(const char *pathPrefix_)
{
	this->pathPrefix = pathPrefix_;
	this->includeRegEx = "#include\\s*<([a-zA-Z_][\\w|.]*)>";
	Debug("%s\n", this->includeRegEx.c_str());

	this->shaderFiles = std::vector<std::string>();
	this->shaders = std::map<std::string, std::string>();

	this->shaderPrograms = std::vector<ShaderProgramInfo>();
}

LPVShaderLoader::~LPVShaderLoader()
{
}

void LPVShaderLoader::AddShaderFile(const std::string& fileName) 
{
	// If the file is not already queued for loading and isn't already loaded, queue it
	if (!arrayIncludes(this->shaderFiles, fileName) && !mapHasOwnProperty(this->shaders, fileName))
	{
		this->shaderFiles.push_back(fileName);
	}
}

void LPVShaderLoader::Load(std::function<void(std::map<std::string, ShaderResult>&)> onload)
{
	// In case there is nothing to load but programs can be assembled from what is already loaded.
	// E.g.:
	//   loader.addShaderFile('fileA');
	//   loader.addShaderFile('fileB');
	//   loader.load(...)
	//   loader.addShaderProgram('program', 'fileA', 'fileB');
	// * loader.load(...)
	//
	// The last load call should still return the program!
	//
	for (int i = 0, len = this->shaderFiles.size(); i < len; ++i)
	{
		auto fileName = this->shaderFiles[i];
		auto path = this->PathForFileName(fileName);

		// load file from path
		FileInputStream fis(path);
		Assert(fis.IsOpened());

		int size = fis.GetSize();
		std::string source;
		source.resize(size+1);
		fis.ReadBuffer(&source[0], size);
		source[size] = 0;
		this->shaders[fileName] = source;
		//Debug("%s\n", source.c_str());
		Debug("%s\n", this->shaders[fileName].c_str());
	}

	OnCompletion(onload);
}

void LPVShaderLoader::OnCompletion(std::function<void(std::map<std::string, ShaderResult>&)> onload)
{
	std::map<std::string, ShaderResult> result;

	for (int i = 0, len = this->shaderPrograms.size(); i < len; ++i)
	{
		auto programInfo = this->shaderPrograms[i];
		auto name = programInfo.name;

		auto unresolvedVsSource = this->shaders[programInfo.vsFileName];
		auto unresolvedFsSource = this->shaders[programInfo.fsFileName];

		auto vsSource = this->ResolveSource(unresolvedVsSource);
		auto fsSource = this->ResolveSource(unresolvedFsSource);

		result[name] = { vsSource, fsSource };
	}

	// Empty array of shader programs and the list of shaders to load, but keep the already loaded shaders
	this->shaderPrograms.clear();
	this->shaderFiles.clear();

	onload(result);
}


const std::string LPVShaderLoader::PathForFileName(const std::string& fileName)
{
	return this->pathPrefix + fileName;
}

#include <iostream>

const std::string LPVShaderLoader::ResolveSource(const std::string& source)
{
	std::regex word_regex(this->includeRegEx.c_str());
	auto words_begin = std::sregex_iterator(source.begin(), source.end(), word_regex);
	auto words_end = std::sregex_iterator();

	if (words_begin!=words_end)
	{
		std::smatch matches = (*words_begin);
		auto includeFileName = matches[1];
		
		if (mapHasOwnProperty(this->shaders, includeFileName))
		{
			auto includedSource = this->ResolveSource(this->shaders[includeFileName]);

			std::string a = matches[0].str();
			std::string resolved = std::regex_replace(source, std::regex(matches[0].str()), includedSource.c_str());

			// Recursively resolve until there is nothing more to resolve
			return this->ResolveSource(resolved);
		}
	}
	else
	{
		return source;
	}
}

void LPVShaderLoader::AddShaderProgram(const std::string& name, const std::string& vsFileName, const std::string& fsFileName) 
{
	this->AddShaderFile(vsFileName);
	this->AddShaderFile(fsFileName);

	this->shaderPrograms.push_back({name, vsFileName, fsFileName});
}

bool LPVShaderLoader::OnInitiate()
{
	return true;
}

bool LPVShaderLoader::OnStart()
{
	return true;
}

bool LPVShaderLoader::OnUpdate()
{
	return true;
}

bool LPVShaderLoader::OnPause()
{
	return true;
}

void LPVShaderLoader::OnResume()
{
}

void LPVShaderLoader::OnStop()
{
}

void LPVShaderLoader::OnTerminate()
{
}

void LPVShaderLoader::OnRender()
{
}