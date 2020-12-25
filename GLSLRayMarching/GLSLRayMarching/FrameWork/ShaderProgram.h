#ifndef _ShaderProgram_h_
#define _ShaderProgram_h_

#include <glad\glad.h>
#include <GLFW\glfw3.h>
#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class ShaderProgram
{
public:
	ShaderProgram()
		: handle(0)
	{
	}

	~ShaderProgram()
	{
		Destroy();
	}

	bool CreateFromBuffer(const char* vShaderCode, const char* fShaderCode, const char* gShaderCode = nullptr)
	{
		// 2. compile shaders
		unsigned int vertex, fragment, geometry;
		// vertex shader
		vertex = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vertex, 1, &vShaderCode, NULL);
		glCompileShader(vertex);
		if (!CheckCompileErrors(vertex, "VERTEX"))
		{
			printf("failed to compile vertex shader\n");
			return false;
		}

		// fragment Shader
		fragment = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fragment, 1, &fShaderCode, NULL);
		glCompileShader(fragment);
		if (!CheckCompileErrors(fragment, "FRAGMENT"))
		{
			printf("failed to compile fragment shader\n");
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
				return false;
			}
		}

		// shader Program
		handle = glCreateProgram();
		glAttachShader(handle, vertex);
		glAttachShader(handle, fragment);
		if (gShaderCode)
		{
			glAttachShader(handle, geometry);
		}

		glLinkProgram(handle);
		if (!CheckCompileErrors(handle, "PROGRAM"))
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

	bool Create(const char* vertexPath, const char* fragmentPath, const char* geometryPath = nullptr)
	{
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
			if(geometryPath)
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

		return CreateFromBuffer(vShaderCode, fShaderCode, gShaderCode);
	}

	void Destroy()
	{
		if (handle)
		{
			glDeleteProgram(handle);

			handle = 0;
		}
	}

	void Bind()
	{
		if (handle)
			glUseProgram(handle);
	}

	void Unbind()
	{
		glUseProgram(0);
	}

	void SetUniform1i(const char* name_, int v0_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform1i(idx, v0_);
	}

	void SetUniform2i(const char* name_, int v0_, int v1_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform2i(idx, v0_, v1_);
	}

	void SetUniform3i(const char* name_, int v0_, int v1_, int v2_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform3i(idx, v0_, v1_, v2_);
	}

	void SetUniform4i(const char* name_, int v0_, int v1_, int v2_, int v3_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform4i(idx, v0_, v1_, v2_, v3_);
	}

	void SetUniform1f(const char* name_, float v0_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform1f(idx, v0_);
	}

	void SetUniform2f(const char* name_, float v0_, float v1_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform2f(idx, v0_, v1_);
	}

	void SetUniform3f(const char* name_, float v0_, float v1_, float v2_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform3f(idx, v0_, v1_, v2_);
	}

	void SetUniform4f(const char* name_, float v0_, float v1_, float v2_, float v3_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform4f(idx, v0_, v1_, v2_, v3_);
	}

	void SetUniform1iv(const char* name_, int count_, const int* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform1iv(idx, count_, v_);
	}

	void SetUniform2iv(const char* name_, int count_, const int* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform2iv(idx, count_, v_);
	}

	void SetUniform3iv(const char* name_, int count_, const int* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform3iv(idx, count_, v_);
	}

	void SetUniform4iv(const char* name_, int count_, const int* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform4iv(idx, count_, v_);
	}

	void SetUniform1fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform1fv(idx, count_, v_);
	}

	void SetUniform2fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform2fv(idx, count_, v_);
	}

	void SetUniform3fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform3fv(idx, count_, v_);
	}

	void SetUniform4fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniform4fv(idx, count_, v_);
	}

	void SetUniformMatrix2fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniformMatrix2fv(idx, count_, true, v_);
	}

	void SetUniformMatrix3fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniformMatrix3fv(idx, count_, true, v_);
	}

	void SetUniformMatrix4fv(const char* name_, int count_, const float* v_)
	{
		int idx = glGetUniformLocation(handle, name_);

		glUniformMatrix4fv(idx, count_, true, v_);
	}
private:
	bool CheckCompileErrors(GLuint shader, std::string type)
	{
		GLint success = 0;
		GLchar infoLog[1024];
		if (type != "PROGRAM")
		{
			glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
			if (!success)
			{
				glGetShaderInfoLog(shader, 1024, NULL, infoLog);
				std::cout << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;

				return false;
			}
		}
		else
		{
			glGetProgramiv(shader, GL_LINK_STATUS, &success);
			if (!success)
			{
				glGetProgramInfoLog(shader, 1024, NULL, infoLog);
				std::cout << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;

				return false;
			}
		}

		return true;
	}
private:
	unsigned int handle;
};

#endif