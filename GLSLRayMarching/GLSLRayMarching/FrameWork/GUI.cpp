//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "GUI.h"

#include "imgui\imgui.h"
#include "imgui\imgui_impl_glfw.h"
#include "imgui\imgui_impl_opengl3.h"

void GUI::Test(std::map<const char*, bool>& bValues,
	std::map<const char*, IValue>& iValues,
	std::map<const char*, FValue>& fValues,
	std::map<const char*, Vec4Value>& vec4Values)
{
	if (ImGui::Begin("SuperGameObject"))
	{
		for (auto& v : bValues)
		{
			ImGui::Checkbox(v.first, &v.second);
		}

		for (auto& v : iValues)
		{
			ImGui::SliderInt(v.first, &v.second.value, v.second.min, v.second.max);
		}

		for (auto& v : fValues)
		{
			ImGui::SliderFloat(v.first, &v.second.value, v.second.min, v.second.max);
		}

		for (auto& v : vec4Values)
		{
			float vvv[4] = { v.second.value[0], v.second.value[1], v.second.value[2], v.second.value[3] };

			ImGui::SliderFloat4(v.first, vvv, v.second.min, v.second.max);
		}
	}

	ImGui::End();
}

void GUI::Test2(int& lod, float& ratio, bool& wireframe, float& v)
{
	if (ImGui::Begin("SuperGameObject"))
	{
		if (ImGui::CollapsingHeader("Lod"))
		{
			ImGui::SliderInt("Lod", &lod, 0, 7, "%d");
		}
		if (ImGui::CollapsingHeader("Ratio"))
		{
			ImGui::SliderFloat("Ratio", &ratio, 0.0, 100.0, "%f");
		}
		if (ImGui::CollapsingHeader("WireFrame?"))
		{
			ImGui::Checkbox("WireFrame", &wireframe);
		}
		if (ImGui::CollapsingHeader("Shape and CSG"))
		{
			/*
			ImGui::Indent(10.0f);
			ImGui::Checkbox("Render Shape1", &enabled1);
			ImGui::ColorEdit4("Shape1 Color", &c[0], ImGuiColorEditFlags_AlphaBar | ImGuiColorEditFlags_NoInputs);
			ImGui::Checkbox("Shape1 Wire", &enabled2);
			ImGui::Checkbox("Shape1 Solid", &enabled3);
			ImGui::Unindent(10.0f);
			*/
		}

		if (ImGui::CollapsingHeader("vertexData[0].px[0]"))
		{
			ImGui::SliderFloat4("vertexData[0].px[0]", &v, -1, 1, "%f");
		}
	}

	ImGui::End();
}

void GUI::Test3(int& lod, float& ratio, bool& wireframe)
{
	if (ImGui::Begin("Physics"))
	{
		if (ImGui::CollapsingHeader("Lod"))
		{
			ImGui::SliderInt("Lod", &lod, 0, 7, "%d");
		}
		if (ImGui::CollapsingHeader("Ratio"))
		{
			ImGui::SliderFloat("Ratio", &ratio, 0.0, 100.0, "%f");
		}
		if (ImGui::CollapsingHeader("WireFrame?"))
		{
			ImGui::Checkbox("WireFrame", &wireframe);
		}
	}

	ImGui::End();
}

void GUI::UpdateShader(ShaderProgram& shaderProgram)
{
	if (ImGui::Begin("ShaderProgram"))
	{
		unsigned int count = shaderProgram.GetActiveUniformCount();

		std::string name;
		UniformType uniformType;
		int size;
		for (int i = 0; i < count; i++)
		{
			unsigned int uiValues[4];
			int iValues[4];
			float fValues[4];
			bool bValues[4];
			
			shaderProgram.GetActiveUniformInfo(i, name, uniformType, size);
			switch (uniformType)
			{
				case UniformType::FLOAT: //float
					shaderProgram.GetUniform1f(name.c_str(), fValues[0]);
					ImGui::SliderFloat(name.c_str(), fValues, -1000, 1000);
					shaderProgram.SetUniform1f(name.c_str(), fValues[0]);
				break;
				case UniformType::FLOAT_VEC2: //vec2
					shaderProgram.GetUniform2f(name.c_str(), fValues[0], fValues[1]);
					ImGui::SliderFloat2(name.c_str(), fValues, -1000, 1000);
					shaderProgram.SetUniform2f(name.c_str(), fValues[0], fValues[1]);
					break;
				case UniformType::FLOAT_VEC3: //vec3
					shaderProgram.GetUniform3f(name.c_str(), fValues[0], fValues[1], fValues[2]);
					ImGui::SliderFloat3(name.c_str(), fValues, -1000, 1000);
					shaderProgram.SetUniform3f(name.c_str(), fValues[0], fValues[1], fValues[2]);
					break;
				case UniformType::FLOAT_VEC4: //vec4
					shaderProgram.GetUniform4f(name.c_str(), fValues[0], fValues[1], fValues[2], fValues[3]);
					ImGui::SliderFloat4(name.c_str(), fValues, -1000, 1000);
					shaderProgram.SetUniform4f(name.c_str(), fValues[0], fValues[1], fValues[2], fValues[3]);
					break;
				case UniformType::INT: //int
					shaderProgram.GetUniform1i(name.c_str(), iValues[0]);
					ImGui::SliderInt(name.c_str(), iValues, -1000, 1000);
					shaderProgram.SetUniform1i(name.c_str(), iValues[0]);
					break;
				case UniformType::INT_VEC2: //ivec2
					shaderProgram.GetUniform2i(name.c_str(), iValues[0], iValues[1]);
					ImGui::SliderInt2(name.c_str(), iValues, -1000, 1000);
					shaderProgram.SetUniform2i(name.c_str(), iValues[0], iValues[1]);
					break;
				case UniformType::INT_VEC3: //ivec3
					shaderProgram.GetUniform3i(name.c_str(), iValues[0], iValues[1], iValues[2]);
					ImGui::SliderInt3(name.c_str(), iValues, -1000, 1000);
					shaderProgram.SetUniform3i(name.c_str(), iValues[0], iValues[1], iValues[2]);
					break;
				case UniformType::INT_VEC4: //ivec4
					shaderProgram.GetUniform4i(name.c_str(), iValues[0], iValues[1], iValues[2], iValues[3]);
					ImGui::SliderInt4(name.c_str(), iValues, -1000, 1000);
					shaderProgram.SetUniform4i(name.c_str(), iValues[0], iValues[1], iValues[2], iValues[3]);
					break;
				case UniformType::UNSIGNED_INT: //unsigned int
					shaderProgram.GetUniform1ui(name.c_str(), uiValues[0]);
					ImGui::SliderInt(name.c_str(), iValues, 0, 1000);
					shaderProgram.SetUniform1ui(name.c_str(), uiValues[0]);
					break;
				case UniformType::UNSIGNED_INT_VEC2: //uvec2
					shaderProgram.GetUniform2ui(name.c_str(), uiValues[0], uiValues[1]);
					ImGui::SliderInt2(name.c_str(), iValues, 0, 1000);
					shaderProgram.SetUniform2ui(name.c_str(), uiValues[0], uiValues[1]);
					break;
				case UniformType::UNSIGNED_INT_VEC3: //uvec3
					shaderProgram.GetUniform3ui(name.c_str(), uiValues[0], uiValues[1], uiValues[2]);
					ImGui::SliderInt3(name.c_str(), iValues, 0, 1000);
					shaderProgram.SetUniform3ui(name.c_str(), uiValues[0], uiValues[1], uiValues[2]);
					break;
				case UniformType::UNSIGNED_INT_VEC4: //uvec4
					shaderProgram.GetUniform4ui(name.c_str(), uiValues[0], uiValues[1], uiValues[2], uiValues[3]);
					ImGui::SliderInt4(name.c_str(), iValues, 0, 1000);
					shaderProgram.SetUniform4ui(name.c_str(), uiValues[0], uiValues[1], uiValues[2], uiValues[3]);
					break;
				case UniformType::BOOL: //bool
					ImGui::Checkbox(name.c_str(), bValues); ImGui::SameLine();
					break;
				case UniformType::BOOL_VEC2: //bvec2
					ImGui::Checkbox((name + "[0]").c_str(), bValues); ImGui::SameLine();
					ImGui::Checkbox((name + "[1]").c_str(), bValues); ImGui::SameLine();
					break;
				case UniformType::BOOL_VEC3: //bvec3
					ImGui::Checkbox((name + "[0]").c_str(), bValues); ImGui::SameLine();
					ImGui::Checkbox((name + "[1]").c_str(), bValues); ImGui::SameLine();
					ImGui::Checkbox((name + "[2]").c_str(), bValues); ImGui::SameLine();
					break;
				case UniformType::BOOL_VEC4: //bvec4
					ImGui::Checkbox((name + "[0]").c_str(), bValues); ImGui::SameLine();
					ImGui::Checkbox((name + "[1]").c_str(), bValues); ImGui::SameLine();
					ImGui::Checkbox((name + "[2]").c_str(), bValues); ImGui::SameLine();
					ImGui::Checkbox((name + "[3]").c_str(), bValues); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT2: //mat2
					ImGui::SliderFloat2((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat2((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT2x3: //mat2x3
					ImGui::SliderFloat2((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat2((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat2((name + "[2]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT2x4: //mat2x4
					ImGui::SliderFloat2((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat2((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat2((name + "[2]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat2((name + "[3]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT3x2: //mat3x2
					ImGui::SliderFloat3((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat3((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT3: //mat3
					ImGui::SliderFloat3((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat3((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat3((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT3x4: //mat3x4
					ImGui::SliderFloat3((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat3((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat3((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT4x2: //mat4x2
					ImGui::SliderFloat4((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat4((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT4x3: //mat4x3
					ImGui::SliderFloat4((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat4((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat4((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				case UniformType::FLOAT_MAT4: //mat4
					ImGui::SliderFloat4((name + "[0]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat4((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat4((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					ImGui::SliderFloat4((name + "[1]").c_str(), fValues, -1000, 1000); ImGui::SameLine();
					break;
				//case UniformType::SAMPLER_2D: //sampler2D
				//case UniformType::SAMPLER_2D_SHADOW: //sampler2DShadow
				//case UniformType::SAMPLER_CUBE: //samplerCube
				//case UniformType::SAMPLER_CUBE_SHADOW: //samplerCubeShadow
				//case UniformType::SAMPLER_3D: //sampler3D
				//case UniformType::SAMPLER_2D_ARRAY: //sampler2DArray
				//case UniformType::SAMPLER_2D_ARRAY_SHADOW: //sampler2DArrayShadow
				//case UniformType::INT_SAMPLER_2D: //isampler2D
				//case UniformType::INT_SAMPLER_3D: //isampler3D
				//case UniformType::INT_SAMPLER_CUBE: //isamplerCube
				//case UniformType::INT_SAMPLER_2D_ARRAY: //isampler2DArray
				//case UniformType::UNSIGNED_INT_SAMPLER_2D: //usampler2D
				//case UniformType::UNSIGNED_INT_SAMPLER_3D: //usampler3D
				//case UniformType::UNSIGNED_INT_SAMPLER_CUBE: //usamplerCube
				//case UniformType::UNSIGNED_INT_SAMPLER_2D_ARRAY: //usampler2DArray
				//case UniformType::UNSUPPORTED
					break;
			};

			ImGui::Separator();
		}
	}

	ImGui::End();
}