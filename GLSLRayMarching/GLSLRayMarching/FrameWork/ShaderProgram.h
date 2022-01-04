#ifndef _ShaderProgram_h_
#define _ShaderProgram_h_

#include "Platform.h"
#include <vector>

class ShaderProgramImpl;
class Buffer;

class ShaderProgramBinary
{
public:
	ShaderProgramBinary()
	{
	}

	unsigned int format;
	std::vector<unsigned char> buffer;
};

enum class UniformType
{
	FLOAT = 0							, //float
	FLOAT_VEC2							, //vec2
	FLOAT_VEC3							, //vec3
	FLOAT_VEC4							, //vec4
	INT									, //int
	INT_VEC2							, //ivec2
	INT_VEC3							, //ivec3
	INT_VEC4							, //ivec4
	UNSIGNED_INT						, //unsigned int
	UNSIGNED_INT_VEC2					, //uvec2
	UNSIGNED_INT_VEC3					, //uvec3
	UNSIGNED_INT_VEC4					, //uvec4
	BOOL								, //bool
	BOOL_VEC2							, //bvec2
	BOOL_VEC3							, //bvec3
	BOOL_VEC4							, //bvec4
	FLOAT_MAT2							, //mat2
	FLOAT_MAT3							, //mat3
	FLOAT_MAT4							, //mat4
	FLOAT_MAT2x3						, //mat2x3
	FLOAT_MAT2x4						, //mat2x4
	FLOAT_MAT3x2						, //mat3x2
	FLOAT_MAT3x4						, //mat3x4
	FLOAT_MAT4x2						, //mat4x2
	FLOAT_MAT4x3						, //mat4x3
	SAMPLER_2D							, //sampler2D
	SAMPLER_3D							, //sampler3D
	SAMPLER_CUBE						, //samplerCube
	SAMPLER_2D_SHADOW					, //sampler2DShadow
	SAMPLER_2D_ARRAY					, //sampler2DArray
	SAMPLER_2D_ARRAY_SHADOW				, //sampler2DArrayShadow
	SAMPLER_CUBE_SHADOW					, //samplerCubeShadow
	INT_SAMPLER_2D						, //isampler2D
	INT_SAMPLER_3D						, //isampler3D
	INT_SAMPLER_CUBE					, //isamplerCube
	INT_SAMPLER_2D_ARRAY				, //isampler2DArray
	UNSIGNED_INT_SAMPLER_2D				, //usampler2D
	UNSIGNED_INT_SAMPLER_3D				, //usampler3D
	UNSIGNED_INT_SAMPLER_CUBE			, //usamplerCube
	UNSIGNED_INT_SAMPLER_2D_ARRAY		, //usampler2DArray
	UNSUPPORTED
};

class ShaderProgram
{
public:
	ShaderProgram();
	virtual ~ShaderProgram();

	static void AddShaderHeaderFile(const std::string& fileName);

	bool Initiate(const char* vertexPath, const char* fragmentPath, const char* geometryPath = nullptr);
	void Terminate();
	bool CreateFromSource(const char* vShaderCode, const char* fShaderCode, const char* gShaderCode = nullptr);
	void GetProgramBinary(ShaderProgramBinary& binary);
	bool CreateFromBinary(const ShaderProgramBinary& binary);
	unsigned int GetHandle() const;

	void Bind() const;
	void Unbind() const;

	int GetActiveUniformCount() const;
	void GetActiveUniformInfo(int index_, std::string& name_, UniformType& uniformType_, int& size_) const;
	
	unsigned int GetUniformLocation(const char* uniform_) const;
	
	void GetUniform1i(const char* uniform_, int& v0_);
	void GetUniform2i(const char* uniform_, int& v0_, int& v1_);
	void GetUniform3i(const char* uniform_, int& v0_, int& v1_, int& v2_);
	void GetUniform4i(const char* uniform_, int& v0_, int& v1_, int& v2_, int& v3_);

	void GetUniform1iv(const char* uniform_, int count_, int* v_);
	void GetUniform2iv(const char* uniform_, int count_, int* v_);
	void GetUniform3iv(const char* uniform_, int count_, int* v_);
	void GetUniform4iv(const char* uniform_, int count_, int* v_);

	void GetUniform1ui(const char* uniform_, unsigned int& v0_);
	void GetUniform2ui(const char* uniform_, unsigned int& v0_, unsigned int& v1_);
	void GetUniform3ui(const char* uniform_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_);
	void GetUniform4ui(const char* uniform_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_, unsigned int& v3_);

	void GetUniform1uiv(const char* uniform_, int count_, unsigned int* v_);
	void GetUniform2uiv(const char* uniform_, int count_, unsigned int* v_);
	void GetUniform3uiv(const char* uniform_, int count_, unsigned int* v_);
	void GetUniform4uiv(const char* uniform_, int count_, unsigned int* v_);

	void GetUniform1f(const char* uniform_, float& v0_);
	void GetUniform2f(const char* uniform_, float& v0_, float& v1_);
	void GetUniform3f(const char* uniform_, float& v0_, float& v1_, float& v2_);
	void GetUniform4f(const char* uniform_, float& v0_, float& v1_, float& v2_, float& v3_);

	void GetUniform1fv(const char* uniform_, int count_, float* v_);
	void GetUniform2fv(const char* uniform_, int count_, float* v_);
	void GetUniform3fv(const char* uniform_, int count_, float* v_);
	void GetUniform4fv(const char* uniform_, int count_, float* v_);

	void GetUniformMatrix2x2fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix2x3fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix2x4fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix3x2fv(const char* uniform_, int count_, float* v_);
	void SetUniformMatrix3x3fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix3x4fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix4x2fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix4x3fv(const char* uniform_, int count_, float* v_);
	void GetUniformMatrix4x4fv(const char* uniform_, int count_, float* v_);

	void GetUniform1i(unsigned int uniformLocation_, int& v0_);
	void GetUniform2i(unsigned int uniformLocation_, int& v0_, int& v1_);
	void GetUniform3i(unsigned int uniformLocation_, int& v0_, int& v1_, int& v2_);
	void GetUniform4i(unsigned int uniformLocation_, int& v0_, int& v1_, int& v2_, int& v3_);

	void GetUniform1iv(unsigned int uniformLocation_, int count_, int* v_);
	void GetUniform2iv(unsigned int uniformLocation_, int count_, int* v_);
	void GetUniform3iv(unsigned int uniformLocation_, int count_, int* v_);
	void GetUniform4iv(unsigned int uniformLocation_, int count_, int* v_);

	void GetUniform1ui(unsigned int uniformLocation_, unsigned int& v0_);
	void GetUniform2ui(unsigned int uniformLocation_, unsigned int& v0_, unsigned int& v1_);
	void GetUniform3ui(unsigned int uniformLocation_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_);
	void GetUniform4ui(unsigned int uniformLocation_, unsigned int& v0_, unsigned int& v1_, unsigned int& v2_, unsigned int& v3_);

	void GetUniform1uiv(unsigned int uniformLocation_, int count_, unsigned int* v_);
	void GetUniform2uiv(unsigned int uniformLocation_, int count_, unsigned int* v_);
	void GetUniform3uiv(unsigned int uniformLocation_, int count_, unsigned int* v_);
	void GetUniform4uiv(unsigned int uniformLocation_, int count_, unsigned int* v_);

	void GetUniform1f(unsigned int uniformLocation_, float& v0_);
	void GetUniform2f(unsigned int uniformLocation_, float& v0_, float& v1_);
	void GetUniform3f(unsigned int uniformLocation_, float& v0_, float& v1_, float& v2_);
	void GetUniform4f(unsigned int uniformLocation_, float& v0_, float& v1_, float& v2_, float& v3_);

	void GetUniform1fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniform2fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniform3fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniform4fv(unsigned int uniformLocation_, int count_, float* v_);

	void GetUniformMatrix2x2fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix2x3fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix2x4fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix3x2fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix3x3fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix3x4fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix4x2fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix4x3fv(unsigned int uniformLocation_, int count_, float* v_);
	void GetUniformMatrix4x4fv(unsigned int uniformLocation_, int count_, float* v_);

	void SetUniform1i(const char* uniform_, int v0_);
	void SetUniform2i(const char* uniform_, int v0_, int v1_);
	void SetUniform3i(const char* uniform_, int v0_, int v1_, int v2_);
	void SetUniform4i(const char* uniform_, int v0_, int v1_, int v2_, int v3_);
	void SetUniform1iv(const char* uniform_, int count_, const int* v_);
	void SetUniform2iv(const char* uniform_, int count_, const int* v_);
	void SetUniform3iv(const char* uniform_, int count_, const int* v_);
	void SetUniform4iv(const char* uniform_, int count_, const int* v_);

	void SetUniform1ui(const char* uniform_, unsigned int v0_);
	void SetUniform2ui(const char* uniform_, unsigned int v0_, unsigned int v1_);
	void SetUniform3ui(const char* uniform_, unsigned int v0_, unsigned int v1_, unsigned int v2_);
	void SetUniform4ui(const char* uniform_, unsigned int v0_, unsigned int v1_, unsigned int v2_, unsigned int v3_);
	void SetUniform1uiv(const char* uniform_, int count_, const unsigned int* v_);
	void SetUniform2uiv(const char* uniform_, int count_, const unsigned int* v_);
	void SetUniform3uiv(const char* uniform_, int count_, const unsigned int* v_);
	void SetUniform4uiv(const char* uniform_, int count_, const unsigned int* v_);

	void SetUniform1f(const char* uniform_, float v0_);
	void SetUniform2f(const char* uniform_, float v0_, float v1_);
	void SetUniform3f(const char* uniform_, float v0_, float v1_, float v2_);
	void SetUniform4f(const char* uniform_, float v0_, float v1_, float v2_, float v3_);
	void SetUniform1fv(const char* uniform_, int count_, const float* v_);
	void SetUniform2fv(const char* uniform_, int count_, const float* v_);
	void SetUniform3fv(const char* uniform_, int count_, const float* v_);
	void SetUniform4fv(const char* uniform_, int count_, const float* v_);

	void SetUniformMatrix2x2fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix2x3fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix2x4fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix3x2fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix3x3fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix3x4fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix4x2fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix4x3fv(const char* uniform_, int count_, const float* v_);
	void SetUniformMatrix4x4fv(const char* uniform_, int count_, const float* v_);

	void SetUniform1i(unsigned int uniformLocation_, int v0_);
	void SetUniform2i(unsigned int uniformLocation_, int v0_, int v1_);
	void SetUniform3i(unsigned int uniformLocation_, int v0_, int v1_, int v2_);
	void SetUniform4i(unsigned int uniformLocation_, int v0_, int v1_, int v2_, int v3_);
	void SetUniform1iv(unsigned int uniformLocation_, int count_, const int* v_);
	void SetUniform2iv(unsigned int uniformLocation_, int count_, const int* v_);
	void SetUniform3iv(unsigned int uniformLocation_, int count_, const int* v_);
	void SetUniform4iv(unsigned int uniformLocation_, int count_, const int* v_);

	void SetUniform1ui(unsigned int uniformLocation_, unsigned int v0_);
	void SetUniform2ui(unsigned int uniformLocation_, unsigned int v0_, unsigned int v1_);
	void SetUniform3ui(unsigned int uniformLocation_, unsigned int v0_, unsigned int v1_, unsigned int v2_);
	void SetUniform4ui(unsigned int uniformLocation_, unsigned int v0_, unsigned int v1_, unsigned int v2_, unsigned int v3_);
	void SetUniform1uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_);
	void SetUniform2uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_);
	void SetUniform3uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_);
	void SetUniform4uiv(unsigned int uniformLocation_, int count_, const unsigned int* v_);

	void SetUniform1f(unsigned int uniformLocation_, float v0_);
	void SetUniform2f(unsigned int uniformLocation_, float v0_, float v1_);
	void SetUniform3f(unsigned int uniformLocation_, float v0_, float v1_, float v2_);
	void SetUniform4f(unsigned int uniformLocation_, float v0_, float v1_, float v2_, float v3_);
	void SetUniform1fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniform2fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniform3fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniform4fv(unsigned int uniformLocation_, int count_, const float* v_);

	void SetUniformMatrix2x2fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix2x3fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix2x4fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix3x2fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix3x3fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix3x4fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix4x2fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix4x3fv(unsigned int uniformLocation_, int count_, const float* v_);
	void SetUniformMatrix4x4fv(unsigned int uniformLocation_, int count_, const float* v_);

	void BindShaderStorageBuffer(Buffer& buffer_, const char* name_, unsigned int bindingPoint_);
	void BindUniformBlock(Buffer& buffer_, const char* name_, unsigned int bindingPoint_);
	void BindShaderStorageBuffer(Buffer& buffer_, unsigned int bindingPoint_);
	void BindUniformBlock(Buffer& buffer_, unsigned int bindingPoint_);

	static void ReleaseShaderCompiler();
private:
	bool CheckCompileErrors(unsigned int shader, std::string type) const;

	ShaderProgramImpl* impl;
};

#endif