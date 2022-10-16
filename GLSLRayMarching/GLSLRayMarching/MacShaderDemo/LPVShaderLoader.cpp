#include "LPVShaderLoader.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVShaderLoader::LPVShaderLoader(const char *pathPrefix_)
{
#if 0
	function ShaderLoader(pathPrefix) {

		this.pathPrefix = pathPrefix;
		this.includeRegEx = / #include\s * <([a-zA-Z_][\w|.]*)> / g;

		this.loadCounter = 0;

		this.shaderFiles = [];
		this.shaders = {};

		this.shaderPrograms = [];

	}

#endif
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

const std::string LPVShaderLoader::PathForFileName(const std::string& fileName)
{
#if 0
	pathForFileName: function(fileName) {

		return this.pathPrefix + fileName;

	},
#endif
	return this->pathPrefix + fileName;
}

#include <iostream>

const std::string LPVShaderLoader::ResolveSource(const std::string& source)
{
#if 0
	resolveSource: function(source) {

		var matches = this.includeRegEx.exec(source);
		if (matches != null) {

			var includeFileName = matches[1];
			if (this.shaders.hasOwnProperty(includeFileName)) {

				var includedSource = this.resolveSource(this.shaders[includeFileName]);
				var resolved = source.replace(matches[0], includedSource);

				// Recursively resolve until there is nothing more to resolve
				return this.resolveSource(resolved);

			}
			else {

				console.error('ShaderLoader: shader file trying to include other file ("' + includeFileName + '") not added!');

			}

		}
		else {

			return source;

		}

	},
#endif
	std::regex word_regex(this->includeRegEx.c_str());
	auto words_begin = std::sregex_iterator(source.begin(), source.end(), word_regex);
	auto words_end = std::sregex_iterator();

	if (words_begin != words_end)
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

void LPVShaderLoader::OnCompletion(std::function<void(std::map<std::string, ShaderResult>&)> onload)
{
#if 0
	onCompletion: function(onload) {

		var result = {};

		for (var i = 0, len = this.shaderPrograms.length; i < len; ++i) {

			var programInfo = this.shaderPrograms[i];
			var name = programInfo.name;

			var unresolvedVsSource = this.shaders[programInfo.vsFileName];
			var unresolvedFsSource = this.shaders[programInfo.fsFileName];

			var vsSource = this.resolveSource(unresolvedVsSource);
			var fsSource = this.resolveSource(unresolvedFsSource);

			result[name] = {
				vertexSource: vsSource,
				fragmentSource : fsSource
			};

		}

		// Empty array of shader programs and the list of shaders to load, but keep the already loaded shaders
		this.shaderPrograms = [];
		this.shaderFiles = [];

		onload(result);

	},
#endif
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


void LPVShaderLoader::AddShaderFile(const std::string& fileName) 
{
#if 0
	addShaderFile: function(fileName) {

		// If the file is not already queued for loading and isn't already loaded, queue it
		if (!this.shaderFiles.includes(fileName) && !this.shaders.hasOwnProperty(fileName)) {

			this.shaderFiles.push(fileName);
			this.loadCounter += 1;

		}

	},
#endif
	// If the file is not already queued for loading and isn't already loaded, queue it
	if (!arrayIncludes(this->shaderFiles, fileName) && !mapHasOwnProperty(this->shaders, fileName))
	{
		this->shaderFiles.push_back(fileName);
	}
}

void LPVShaderLoader::AddShaderProgram(const std::string& name, const std::string& vsFileName, const std::string& fsFileName)
{
#if 0
	addShaderProgram: function(name, vsFileName, fsFileName) {

		this.addShaderFile(vsFileName);
		this.addShaderFile(fsFileName);

		this.shaderPrograms.push({
			name: name,
			vsFileName : vsFileName,
			fsFileName : fsFileName
			});

	},
#endif
	this->AddShaderFile(vsFileName);
	this->AddShaderFile(fsFileName);

	this->shaderPrograms.push_back({ name, vsFileName, fsFileName });
}

void LPVShaderLoader::Load(std::function<void(std::map<std::string, ShaderResult>&)> onload)
{
#if 0
	load: function(onload) {

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
		if (this.loadCounter == = 0) {
			this.onCompletion(onload);
			return;
		}

		var scope = this;

		for (var i = 0, len = this.shaderFiles.length; i < len; ++i) {

			var fileName = this.shaderFiles[i];
			var path = this.pathForFileName(fileName);

			makeTextDataRequest(path, fileName, function(file, source) {

				scope.shaders[file] = source;
				scope.loadCounter -= 1;

				if (scope.loadCounter == = 0) {
					scope.onCompletion(onload);
				}

			});

		}

	}
#endif
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