#include "Platform.h"
#include "Graphics.h"
#include "ShaderProgram.h"
#include "Buffer.h"

#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class ShaderProgramImpl
{
public:
	ShaderProgramImpl()
		: handle(0)
	{
	}

	unsigned int handle;
};

/////////////////////////////////////////////////////////////////////////
ShaderProgram::ShaderProgram()
	: impl(nullptr)
{
	impl = new ShaderProgramImpl();
}

ShaderProgram::~ShaderProgram()
{
	Assert(impl);

	Terminate();

	if (impl)
	{
		delete impl;
		impl = nullptr;
	}
}

void ShaderProgram::AddShaderHeaderFile(const std::string& fileName)
{
	if (fileName.empty())
		return;

	std::string shaderPath = "Demos/AMD_FSR/" + fileName;

	/// 读common shader文件
	std::string code;
	std::ifstream shaderFile;
	shaderFile.exceptions(std::ifstream::badbit);
	try
	{
		/// 打开文件
		shaderFile.open(shaderPath);
		std::stringstream shaderStream;
		/// 读取文件的缓冲内容到流中；
		shaderStream << shaderFile.rdbuf();
		/// 关闭文件
		shaderFile.close();
		/// 转换流至GLchar数组
		code = shaderStream.str();
	}
	catch (std::ifstream::failure e) 
	{
		std::cout << "init shader error: failed to read shader file";
	}

	std::string fullFileName = "/" + fileName;
	glNamedStringARB(GL_SHADER_INCLUDE_ARB, fullFileName.size(), fullFileName.c_str(), code.size(), code.c_str());
}

bool ShaderProgram::Initiate(const char* vertexPath, const char* fragmentPath, const char* geometryPath)
{
	Assert(impl);

	// 1. retrieve the vertex/fragment source code from filePath
	std::string vertexCode;
	std::string fragmentCode;
	std::string geometryCode;
	std::ifstream vShaderFile;
	std::ifstream fShaderFile;
	std::ifstream gShaderFile;
	// ensure ifstream objects can throw exceptions:
	vShaderFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
	fShaderFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
	gShaderFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
	try
	{
		// open files
		vShaderFile.open(vertexPath);
		fShaderFile.open(fragmentPath);
		if (geometryPath)
			gShaderFile.open(geometryPath);
		std::stringstream vShaderStream, fShaderStream, gShaderStream;

		// read file's buffer contents into streams
		vShaderStream << vShaderFile.rdbuf();
		fShaderStream << fShaderFile.rdbuf();
		if (geometryPath)
			gShaderStream << gShaderFile.rdbuf();

		// close file handlers
		vShaderFile.close();
		fShaderFile.close();
		if (geometryPath)
			gShaderFile.close();

		// convert stream into string
		vertexCode = vShaderStream.str();
		fragmentCode = fShaderStream.str();
		if (geometryPath)
			geometryCode = gShaderStream.str();
	}
	catch (std::ifstream::failure&)
	{
		return false;
	}

	const char* vShaderCode = vertexCode.c_str();
	const char* fShaderCode = fragmentCode.c_str();
	const char* gShaderCode = geometryCode.c_str();
	if (!geometryPath)
		gShaderCode = nullptr;

	return CreateFromSource(vShaderCode, fShaderCode, gShaderCode);
}

void ShaderProgram::Terminate()
{
	Assert(impl);

	if (impl->handle)
	{
		glDeleteProgram(impl->handle);
		impl->handle = 0;

		MemSet(impl, 0, sizeof(*impl));
	}
}

bool ShaderProgram::CreateFromSource(const char* vShaderCode, const char* fShaderCode, const char* gShaderCode)
{
	Assert(impl);

	Terminate();

	// 2. compile shaders
	unsigned int vertex, fragment, geometry;
	// vertex shader

	static const char* const searchPath = "/";
	vertex = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertex, 1, &vShaderCode, NULL);
	glCompileShaderIncludeARB(vertex, 1, &searchPath, nullptr);
	glCompileShader(vertex);
	if (!CheckCompileErrors(vertex, "VERTEX"))
	{
		printf("failed to compile vertex shader\n");
		printf("%s\n", vShaderCode);
		
		return false;
	}

	// fragment Shader
	fragment = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragment, 1, &fShaderCode, NULL);
	glCompileShader(fragment);
	if (!CheckCompileErrors(fragment, "FRAGMENT"))
	{
		printf("failed to compile fragment shader\n");
		printf("%s\n", fShaderCode);
		return false;
	}

	if (gShaderCode)
	{
		// fragment Shader
		geometry = glCreateShader(GL_GEOMETRY_SHADER);
		glShaderSource(geometry, 1, &gShaderCode, NULL);
		glCompileShader(geometry);
		if (!CheckCompileErrors(geometry, "GEOMETRY"))
		{
			printf("failed to compile geometry shader\n");
			printf("%s\n", gShaderCode);
			return false;
		}
	}

	// shader Program
	impl->handle = glCreateProgram();
	if (impl->handle == 0)
		return false;

	glAttachShader(impl->handle, vertex);
	glAttachShader(impl->handle, fragment);
	if (gShaderCode)
	{
		glAttachShader(impl->handle, geometry);
	}

	glLinkProgram(impl->handle);
	if (!CheckCompileErrors(impl->handle, "PROGRAM"))
	{
		printf("failed to link shader programs\n");
		return false;
	}
	glDeleteShader(vertex);
	glDeleteShader(fragment);
	if (gShaderCode)
	{
		glDeleteShader(geometry);
	}

	return true;
}

void ShaderProgram::GetProgramBinary(ShaderProgramBinary& shaderProgramBinary)
{
	Assert(impl);
	Assert(impl->handle);

	int inBufLength = 0;
	int outBufLength = 0;
	glGetProgramiv(impl->handle, GL_PROGRAM_BINARY_LENGTH, &inBufLength);

	shaderProgramBinary.buffer.resize(inBufLength);
	glGetProgramBinary(impl->handle, inBufLength, &outBufLength, &shaderProgramBinary.format, &shaderProgramBinary.buffer[0]);
}

bool ShaderProgram::CreateFromBinary(const ShaderProgramBinary& shaderProgramBinary)
{
	Assert(impl);

	Terminate();

	// shader Program
	impl->handle = glCreateProgram();
	if(impl->handle==0)
		return false;

	glProgramBinary(impl->handle, shaderProgramBinary.format, &shaderProgramBinary.buffer[0], shaderProgramBinary.buffer.size());
	if (!CheckCompileErrors(impl->handle, "PROGRAM"))
	{
		printf("failed to load binary program\n");
		return false;
	}

	return true;
}

unsigned int ShaderProgram::GetHandle() const
{
	Assert(impl);

	return impl->handle;
}

void ShaderProgram::Bind() const
{
	Assert(impl);
	Assert(impl->handle);

	glUseProgram(impl->handle);
}

void ShaderProgram::Unbind() const
{
	Assert(impl);

	glUseProgram(0);
}

int ShaderProgram::GetActiveUniformCount() const
{
	Assert(impl);

	int activeuniform = 0;
	glGetProgramiv(impl->handle, GL_ACTIVE_UNIFORMS, &activeuniform);

	return activeuniform;
}

std::map<int, UniformType> uniformTypeGLValues =
{
	{ GL_FLOAT,								  UniformType::FLOAT },
	{ GL_FLOAT_VEC2,						  UniformType::FLOAT_VEC2 },
	{ GL_FLOAT_VEC3,						  UniformType::FLOAT_VEC3 },
	{ GL_FLOAT_VEC4,						  UniformType::FLOAT_VEC4 },
	{ GL_INT,								  UniformType::INT },
	{ GL_INT_VEC2,							  UniformType::INT_VEC2 },
	{ GL_INT_VEC3,							  UniformType::INT_VEC3 },
	{ GL_INT_VEC4,							  UniformType::INT_VEC4 },
	{ GL_UNSIGNED_INT,						  UniformType::UNSIGNED_INT },
	{ GL_UNSIGNED_INT_VEC2,					  UniformType::UNSIGNED_INT_VEC2 },
	{ GL_UNSIGNED_INT_VEC3,					  UniformType::UNSIGNED_INT_VEC3 },
	{ GL_UNSIGNED_INT_VEC4,					  UniformType::UNSIGNED_INT_VEC4 },
	{ GL_BOOL,								  UniformType::BOOL },
	{ GL_BOOL_VEC2,							  UniformType::BOOL_VEC2 },
	{ GL_BOOL_VEC3,							  UniformType::BOOL_VEC3 },
	{ GL_BOOL_VEC4,							  UniformType::BOOL_VEC4 },
	{ GL_FLOAT_MAT2, 						  UniformType::FLOAT_MAT2 },
	{ GL_FLOAT_MAT3, 						  UniformType::FLOAT_MAT3 },
	{ GL_FLOAT_MAT4, 						  UniformType::FLOAT_MAT4 },
	{ GL_FLOAT_MAT2x3,						  UniformType::FLOAT_MAT2x3 },
	{ GL_FLOAT_MAT2x4,						  UniformType::FLOAT_MAT2x4 },
	{ GL_FLOAT_MAT3x2,						  UniformType::FLOAT_MAT3x2 },
	{ GL_FLOAT_MAT3x4,						  UniformType::FLOAT_MAT3x4 },
	{ GL_FLOAT_MAT4x2,						  UniformType::FLOAT_MAT4x2 },
	{ GL_FLOAT_MAT4x3,						  UniformType::FLOAT_MAT4x3 },
	{ GL_SAMPLER_2D,						  UniformType::SAMPLER_2D },
	{ GL_SAMPLER_3D,						  UniformType::SAMPLER_3D },
	{ GL_SAMPLER_CUBE,						  UniformType::SAMPLER_CUBE },
	{ GL_SAMPLER_2D_SHADOW,					  UniformType::SAMPLER_2D_SHADOW },
	{ GL_SAMPLER_2D_ARRAY,					  UniformType::SAMPLER_2D_ARRAY },
	{ GL_SAMPLER_2D_ARRAY_SHADOW,			  UniformType::SAMPLER_2D_ARRAY_SHADOW },
	{ GL_SAMPLER_CUBE_SHADOW,				  UniformType::SAMPLER_CUBE_SHADOW },
	{ GL_INT_SAMPLER_2D,					  UniformType::INT_SAMPLER_2D },
	{ GL_INT_SAMPLER_3D,					  UniformType::INT_SAMPLER_3D },
	{ GL_INT_SAMPLER_CUBE,					  UniformType::INT_SAMPLER_CUBE },
	{ GL_INT_SAMPLER_2D_ARRAY,				  UniformType::INT_SAMPLER_2D_ARRAY },
	{ GL_UNSIGNED_INT_SAMPLER_2D,			  UniformType::UNSIGNED_INT_SAMPLER_2D },
	{ GL_UNSIGNED_INT_SAMPLER_3D,			  UniformType::UNSIGNED_INT_SAMPLER_3D },
	{ GL_UNSIGNED_INT_SAMPLER_CUBE,			  UniformType::UNSIGNED_INT_SAMPLER_CUBE },
	{ GL_UNSIGNED_INT_SAMPLER_2D_ARRAY,		  UniformType::UNSIGNED_INT_SAMPLER_2D_ARRAY },
};

void ShaderProgram::GetActiveUniformInfo(int index_, std::string& name_, UniformType& uniformType_, int& size_) const
{
	Assert(impl);

	unsigned int bufSize = 1024;
	int length = 0;
	name_.resize(bufSize + 1);
	GLenum type;
	glGetActiveUniform(impl->handle, index_, bufSize, &length, &size_, &type, &name_[0]);

	if(uniformTypeGLValues.find(type) == uniformTypeGLValues.end())
		uniformType_ = UniformType::UNSUPPORTED;
	else
		uniformType_ = uniformTypeGLValues[type];
}

unsigned int ShaderProgram::GetUniformLocation(const char* uniform_) const
{
	Assert(impl);

	return glGetUniformLocation(impl->handle, uniform_);
}

void ShaderProgram::SetUniform1i(const char* uniform_, int v0_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform1i(location, v0_);
}

void ShaderProgram::SetUniform2i(const char* uniform_, int v0_, int v1_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform2i(location, v0_, v1_);
}

void ShaderProgram::SetUniform3i(const char* uniform_, int v0_, int v1_, int v2_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform3i(location, v0_, v1_, v2_);
}

void ShaderProgram::SetUniform4i(const char* uniform_, int v0_, int v1_, int v2_, int v3_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform4i(location, v0_, v1_, v2_, v3_);
}

void ShaderProgram::SetUniform1iv(const char* uniform_, int count_, const int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform1iv(location, count_, v_);
}

void ShaderProgram::SetUniform2iv(const char* uniform_, int count_, const int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform2iv(location, count_, v_);
}

void ShaderProgram::SetUniform3iv(const char* uniform_, int count_, const int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform3iv(location, count_, v_);
}

void ShaderProgram::SetUniform4iv(const char* uniform_, int count_, const int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform4iv(location, count_, v_);
}

void ShaderProgram::SetUniform1ui(const char* uniform_, unsigned int v0_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform1ui(location, v0_);
}

void ShaderProgram::SetUniform2ui(const char* uniform_, unsigned int v0_, unsigned int v1_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform2ui(location, v0_, v1_);
}

void ShaderProgram::SetUniform3ui(const char* uniform_, unsigned int v0_, unsigned int v1_, unsigned int v2_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform3ui(location, v0_, v1_, v2_);
}

void ShaderProgram::SetUniform4ui(const char* uniform_, unsigned int v0_, unsigned int v1_, unsigned int v2_, unsigned int v3_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform4ui(location, v0_, v1_, v2_, v3_);
}

void ShaderProgram::SetUniform1uiv(const char* uniform_, int count_, const unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform1uiv(location, count_, v_);
}

void ShaderProgram::SetUniform2uiv(const char* uniform_, int count_, const unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform2uiv(location, count_, v_);
}

void ShaderProgram::SetUniform3uiv(const char* uniform_, int count_, const unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform3uiv(location, count_, v_);
}

void ShaderProgram::SetUniform4uiv(const char* uniform_, int count_, const unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform4uiv(location, count_, v_);
}

void ShaderProgram::SetUniform1f(const char* uniform_, float v0_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform1f(location, v0_);
}

void ShaderProgram::SetUniform2f(const char* uniform_, float v0_, float v1_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform2f(location, v0_, v1_);
}

void ShaderProgram::SetUniform3f(const char* uniform_, float v0_, float v1_, float v2_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform3f(location, v0_, v1_, v2_);
}

void ShaderProgram::SetUniform4f(const char* uniform_, float v0_, float v1_, float v2_, float v3_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform4f(location, v0_, v1_, v2_, v3_);
}

void ShaderProgram::SetUniform1fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform1fv(location, count_, v_);
}

void ShaderProgram::SetUniform2fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform2fv(location, count_, v_);
}

void ShaderProgram::SetUniform3fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform3fv(location, count_, v_);
}

void ShaderProgram::SetUniform4fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniform4fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix2x2fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix2x2fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix2x3fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix2x3fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix2x4fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix2x4fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix3x2fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix3x2fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix3x3fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix3x3fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix3x4fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix3x4fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix4x2fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix4x2fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix4x3fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix4x3fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix4x4fv(const char* uniform_, int count_, const float* v_)
{
	int location = GetUniformLocation(uniform_);

	SetUniformMatrix4x4fv(location, count_, v_);
}

#define USE_PROGRAM_UNIFORM
void ShaderProgram::SetUniform1i(unsigned int uniformLocation_, int v0_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1i(impl->handle, uniformLocation_, v0_);
#else
	glUniform1i(uniformLocation_, v0_);
#endif
}

void ShaderProgram::SetUniform2i(unsigned int uniformLocation_, int v0_, int v1_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2i(impl->handle, uniformLocation_, v0_, v1_);
#else
	glUniform2i(uniformLocation_, v0_, v1_);
#endif
}

void ShaderProgram::SetUniform3i(unsigned int uniformLocation_, int v0_, int v1_, int v2_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3i(impl->handle, uniformLocation_, v0_, v1_, v2_);
#else
	glUniform3i(uniformLocation_, v0_, v1_, v2_);
#endif
}

void ShaderProgram::SetUniform4i(unsigned int uniformLocation_, int v0_, int v1_, int v2_, int v3_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4i(impl->handle, uniformLocation_, v0_, v1_, v2_, v3_);
#else
	glUniform4i(uniformLocation_, v0_, v1_, v2_, v3_);
#endif
}

void ShaderProgram::SetUniform1iv(unsigned int uniformLocation_, int count_, const int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform1iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform2iv(unsigned int uniformLocation_, int count_, const int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform2iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform3iv(unsigned int uniformLocation_, int count_, const int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform3iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform4iv(unsigned int uniformLocation_, int count_, const int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform4iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform1ui(unsigned int uniformLocation_, unsigned int v0_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1ui(impl->handle, uniformLocation_, v0_);
#else
	glUniform1ui(uniformLocation_, v0_);
#endif
}

void ShaderProgram::SetUniform2ui(unsigned int uniformLocation_, unsigned int v0_, unsigned int v1_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2ui(impl->handle, uniformLocation_, v0_, v1_);
#else
	glUniform2ui(uniformLocation_, v0_, v1_);
#endif
}

void ShaderProgram::SetUniform3ui(unsigned int uniformLocation_, unsigned int v0_, unsigned int v1_, unsigned int v2_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3ui(impl->handle, uniformLocation_, v0_, v1_, v2_);
#else
	glUniform3ui(uniformLocation_, v0_, v1_, v2_);
#endif
}

void ShaderProgram::SetUniform4ui(unsigned int uniformLocation_, unsigned int v0_, unsigned int v1_, unsigned int v2_, unsigned int v3_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4ui(impl->handle, uniformLocation_, v0_, v1_, v2_, v3_);
#else
	glUniform4ui(uniformLocation_, v0_, v1_, v2_, v3_);
#endif
}

void ShaderProgram::SetUniform1uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1uiv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform1uiv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform2uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2uiv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform2uiv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform3uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3uiv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform3uiv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform4uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4uiv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform4uiv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform1f(unsigned int uniformLocation_, float v0_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1f(impl->handle, uniformLocation_, v0_);
#else
	glUniform1f(uniformLocation_, v0_);
#endif
}

void ShaderProgram::SetUniform2f(unsigned int uniformLocation_, float v0_, float v1_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2f(impl->handle, uniformLocation_, v0_, v1_);
#else
	glUniform2f(uniformLocation_, v0_, v1_);
#endif
}

void ShaderProgram::SetUniform3f(unsigned int uniformLocation_, float v0_, float v1_, float v2_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3f(impl->handle, uniformLocation_, v0_, v1_, v2_);
#else
	glUniform3f(uniformLocation_, v0_, v1_, v2_);
#endif
}

void ShaderProgram::SetUniform4f(unsigned int uniformLocation_, float v0_, float v1_, float v2_, float v3_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4f(impl->handle, uniformLocation_, v0_, v1_, v2_, v3_);
#else
	glUniform4f(uniformLocation_, v0_, v1_, v2_, v3_);
#endif
}

void ShaderProgram::SetUniform1fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1fv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform1fv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform2fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2fv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform2fv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform3fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3fv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform3fv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniform4fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4fv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform4fv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::SetUniformMatrix2x2fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix2fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix2fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix2x3fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix2x3fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix2x3fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix2x4fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix2x4fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix2x4fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix3x2fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix3x2fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix3x2fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix3x3fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix3fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix3fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix3x4fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix3x4fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix3x4fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix4x2fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix4x2fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix4x2fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix4x3fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix4x3fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix4x3fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::SetUniformMatrix4x4fv(unsigned int uniformLocation_, int count_, const float* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniformMatrix4fv(impl->handle, uniformLocation_, count_, true, v_);
#else
	glUniformMatrix4fv(uniformLocation_, count_, true, v_);
#endif
}

void ShaderProgram::GetUniform1i(const char* uniform_, int& v0_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform1i(location, v0_);
}

void ShaderProgram::GetUniform2i(const char* uniform_, int& v0_, int& v1_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform2i(location, v0_, v1_);
}

void ShaderProgram::GetUniform3i(const char* uniform_, int& v0_, int& v1_, int& v2_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform3i(location, v0_, v1_, v2_);
}

void ShaderProgram::GetUniform4i(const char* uniform_, int& v0_, int& v1_, int& v2_, int& v3_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform4i(location, v0_, v1_, v2_, v3_);
}

void ShaderProgram::GetUniform1iv(const char* uniform_, int count_, int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform1iv(location, count_, v_);
}

void ShaderProgram::GetUniform2iv(const char* uniform_, int count_, int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform2iv(location, count_, v_);
}

void ShaderProgram::GetUniform3iv(const char* uniform_, int count_, int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform3iv(location, count_, v_);
}

void ShaderProgram::GetUniform4iv(const char* uniform_, int count_, int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform4iv(location, count_, v_);
}

void ShaderProgram::GetUniform1ui(const char* uniform_, unsigned int& v0_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform1ui(location, v0_);
}

void ShaderProgram::GetUniform2ui(const char* uniform_, unsigned int& v0_, unsigned int& v1_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform2ui(location, v0_, v1_);
}

void ShaderProgram::GetUniform3ui(const char* uniform_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform3ui(location, v0_, v1_, v2_);
}

void ShaderProgram::GetUniform4ui(const char* uniform_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_, unsigned int& v3_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform4ui(location, v0_, v1_, v2_, v3_);
}

void ShaderProgram::GetUniform1uiv(const char* uniform_, int count_, unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform1uiv(location, count_, v_);
}

void ShaderProgram::GetUniform2uiv(const char* uniform_, int count_, unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform2uiv(location, count_, v_);
}

void ShaderProgram::GetUniform3uiv(const char* uniform_, int count_, unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform3uiv(location, count_, v_);
}

void ShaderProgram::GetUniform4uiv(const char* uniform_, int count_, unsigned int* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform4uiv(location, count_, v_);
}

void ShaderProgram::GetUniform1f(const char* uniform_, float& v0_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform1f(location, v0_);
}

void ShaderProgram::GetUniform2f(const char* uniform_, float& v0_, float& v1_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform2f(location, v0_, v1_);
}

void ShaderProgram::GetUniform3f(const char* uniform_, float& v0_, float& v1_, float& v2_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform3f(location, v0_, v1_, v2_);
}

void ShaderProgram::GetUniform4f(const char* uniform_, float& v0_, float& v1_, float& v2_, float& v3_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform4f(location, v0_, v1_, v2_, v3_);
}

void ShaderProgram::GetUniform1fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform1fv(location, count_, v_);
}

void ShaderProgram::GetUniform2fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform2fv(location, count_, v_);
}

void ShaderProgram::GetUniform3fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform3fv(location, count_, v_);
}

void ShaderProgram::GetUniform4fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniform4fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix2x2fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix2x2fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix2x3fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix2x3fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix2x4fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix2x4fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix3x2fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix3x2fv(location, count_, v_);
}

void ShaderProgram::SetUniformMatrix3x3fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix3x3fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix3x4fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix3x4fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix4x2fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix4x2fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix4x3fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix4x3fv(location, count_, v_);
}

void ShaderProgram::GetUniformMatrix4x4fv(const char* uniform_, int count_, float* v_)
{
	int location = GetUniformLocation(uniform_);

	GetUniformMatrix4x4fv(location, count_, v_);
}

#define USE_PROGRAM_UNIFORM
void ShaderProgram::GetUniform1i(unsigned int uniformLocation_, int& v0_)
{
	Assert(impl);

	int values[4];
	glGetUniformiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
}

void ShaderProgram::GetUniform2i(unsigned int uniformLocation_, int& v0_, int& v1_)
{
	Assert(impl);

	int values[4];
	glGetUniformiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
}

void ShaderProgram::GetUniform3i(unsigned int uniformLocation_, int& v0_, int& v1_, int& v2_)
{
	Assert(impl);

	int values[4];
	glGetUniformiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
	v2_ = values[2];
}

void ShaderProgram::GetUniform4i(unsigned int uniformLocation_, int& v0_, int& v1_, int& v2_, int& v3_)
{
	Assert(impl);

	int values[4];
	glGetUniformiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
	v2_ = values[2];
	v3_ = values[3];
}

void ShaderProgram::GetUniform1iv(unsigned int uniformLocation_, int count_, int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform1iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform1iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::GetUniform2iv(unsigned int uniformLocation_, int count_, int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform2iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform2iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::GetUniform3iv(unsigned int uniformLocation_, int count_, int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform3iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform3iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::GetUniform4iv(unsigned int uniformLocation_, int count_, int* v_)
{
#ifdef USE_PROGRAM_UNIFORM
	Assert(impl);

	glProgramUniform4iv(impl->handle, uniformLocation_, count_, v_);
#else
	glUniform4iv(uniformLocation_, count_, v_);
#endif
}

void ShaderProgram::GetUniform1ui(unsigned int uniformLocation_, unsigned int& v0_)
{
	Assert(impl);

	unsigned int values[4];
	glGetUniformuiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
}

void ShaderProgram::GetUniform2ui(unsigned int uniformLocation_, unsigned int& v0_, unsigned int& v1_)
{
	Assert(impl);

	unsigned int values[4];
	glGetUniformuiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
}

void ShaderProgram::GetUniform3ui(unsigned int uniformLocation_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_)
{
	Assert(impl);

	unsigned int values[4];
	glGetUniformuiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
	v2_ = values[2];
}

void ShaderProgram::GetUniform4ui(unsigned int uniformLocation_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_, unsigned int& v3_)
{
	Assert(impl);

	unsigned int values[4];
	glGetUniformuiv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
	v2_ = values[2];
	v3_ = values[3];
}

void ShaderProgram::GetUniform1uiv(unsigned int uniformLocation_, int count_, unsigned int* v_)
{
	Assert(impl);

	glGetUniformuiv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform2uiv(unsigned int uniformLocation_, int count_, unsigned int* v_)
{
	Assert(impl);

	glGetUniformuiv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform3uiv(unsigned int uniformLocation_, int count_, unsigned int* v_)
{
	Assert(impl);

	glGetUniformuiv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform4uiv(unsigned int uniformLocation_, int count_, unsigned int* v_)
{
	Assert(impl);

	glGetUniformuiv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform1f(unsigned int uniformLocation_, float& v0_)
{
	Assert(impl);

	float values[4];
	glGetUniformfv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
}

void ShaderProgram::GetUniform2f(unsigned int uniformLocation_, float& v0_, float& v1_)
{
	Assert(impl);

	float values[4];
	glGetUniformfv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
}

void ShaderProgram::GetUniform3f(unsigned int uniformLocation_, float& v0_, float& v1_, float& v2_)
{
	Assert(impl);

	float values[4];
	glGetUniformfv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
	v2_ = values[2];
}

void ShaderProgram::GetUniform4f(unsigned int uniformLocation_, float& v0_, float& v1_, float& v2_, float& v3_)
{
	Assert(impl);

	float values[4];
	glGetUniformfv(impl->handle, uniformLocation_, values);

	v0_ = values[0];
	v1_ = values[1];
	v2_ = values[2];
	v3_ = values[3];
}

void ShaderProgram::GetUniform1fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform2fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform3fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniform4fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix2x2fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix2x3fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix2x4fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix3x2fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix3x3fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix3x4fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix4x2fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix4x3fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::GetUniformMatrix4x4fv(unsigned int uniformLocation_, int count_, float* v_)
{
	Assert(impl);

	glGetUniformfv(impl->handle, uniformLocation_, v_);
}

void ShaderProgram::BindShaderStorageBuffer(Buffer& buffer_, const char* name_, unsigned int bindingPoint_)
{
	Assert(impl);

	buffer_.BindShaderStorage(*this, name_, bindingPoint_);
}

void ShaderProgram::BindShaderStorageBuffer(Buffer& buffer_, unsigned int bindingPoint_)
{
	Assert(impl);

	buffer_.BindShaderStorage(*this, bindingPoint_);
}

void ShaderProgram::BindUniformBlock(Buffer& buffer_, const char* name_, unsigned int bindingPoint_)
{
	Assert(impl);

	buffer_.BindUniformBlock(*this, name_, bindingPoint_);
}

void ShaderProgram::BindUniformBlock(Buffer& buffer_, unsigned int bindingPoint_)
{
	Assert(impl);

	buffer_.BindUniformBlock(*this, bindingPoint_);
}

bool ShaderProgram::CheckCompileErrors(unsigned int shader, std::string type) const
{
	Assert(impl);

	GLint success = 0;
	GLchar infoLog[1024];
	if (type != "PROGRAM")
	{
		glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
		if (!success)
		{
			glGetShaderInfoLog(shader, 1024, NULL, infoLog);
			Debug("ERROR::SHADER_COMPILATION_ERROR of type: %s%s%s%s\n", type.c_str(), "\n", infoLog, "\n");

			return false;
		}
	}
	else
	{
		glGetProgramiv(shader, GL_LINK_STATUS, &success);
		if (!success)
		{
			glGetProgramInfoLog(shader, 1024, NULL, infoLog);
			Debug("ERROR::PROGRAM_LINKING_ERROR of type: %s%s%s%s\n", type.c_str(), "\n", infoLog, "\n");

			return false;
		}
	}

	return true;
}

void ShaderProgram::ReleaseShaderCompiler()
{
	glReleaseShaderCompiler();
}