#ifndef _Shape_h_
#define _Shape_h_

#include "Texture.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "Buffer.h"
#include "VertexBuffer.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix4.h"
#include "AABB3.h"
#include "Frame3.h"
#include "Camera.h"

template<class UniformBlockData>
class Shape : public Frame3
{
public:
	Shape()
	{
	}

	virtual ~Shape()
	{
	}

	RenderStates& GetRenderStates()
	{
		return renderStates;
	}

	Texture2DFile& GetTexture()
	{
		return texture;
	}

	UniformBlockData& GetUniformBlockData()
	{
		return uniformBlockData;
	}

	ShaderProgram& GetShaderProgram()
	{
		return shaderProgram;
	}

	VertexBuffer& GetPrimitives()
	{
		return vertexBuffer;
	}

	#define USE_UNIFORM_BLOCK

	Shape& Begin()
	{
		vertices.clear();

		return *this;
	}

	Shape& XYRect(const Vector3& size_, const Vector3& pivot_ = Vector3::Zero)
	{
		Vector3 halfSize = size_ * 0.5f;
		vertices.push_back(Vector3(-halfSize.X() - pivot_.X(), -halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(-halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), -halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));

		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), -halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(-halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));

		return *this;
	}

	Shape& YZRect(const Vector3& size_, const Vector3& pivot_ = Vector3::Zero)
	{
		Vector3 halfSize = size_ * 0.5f;
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), -halfSize.Y() - pivot_.Y(), -halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), -halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), -halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));

		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), -halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), -halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));

		return *this;
	}

	Shape& ZXRect(const Vector3& size_, const Vector3& pivot_ = Vector3::Zero)
	{
		Vector3 halfSize = size_ * 0.5f;
		vertices.push_back(Vector3(-halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), -halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), -halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(-halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));

		vertices.push_back(Vector3(-halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), -halfSize.Z() - pivot_.Z()));
		vertices.push_back(Vector3(+halfSize.X() - pivot_.X(), +halfSize.Y() - pivot_.Y(), +halfSize.Z() - pivot_.Z()));

		return *this;
	}

	Shape& Box(const Vector3& size_)
	{
		return *this;
	}

	Shape& AddTriangle(const Vector3& v0_, const Vector3& v1_, const Vector3& v2_)
	{
		vertices.push_back(v0_);
		vertices.push_back(v1_);
		vertices.push_back(v2_);

		return *this;
	}

	bool End()
	{
		////////////////////////////////////////////////////////////
		bool success = vertexBuffer
			.Begin()
			.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false, 0, 0, &vertices[0], vertices.size())
			.End();
		if (!success)
		{
			return false;
		}
		vertices.clear();

		////////////////////////////////////////////////////////////
		renderStates.scissorTestState.enabled = true;
		renderStates.scissorTestState.pos = Vector2(0, 0);
		renderStates.viewportState.pos = Vector2(0, 0);

		renderStates.polygonModeState.face = PolygonModeState::Face::FRONT_AND_BACK;
		renderStates.polygonModeState.mode = PolygonModeState::Mode::LINE;

		renderStates.cullFaceState.enabled = true;
		renderStates.cullFaceState.mode = CullFaceState::Mode::BACK;

		renderStates.depthTestState.depthTestEnabled = true;
		renderStates.depthTestState.depthWriteEnabled = true;
		renderStates.depthTestState.func = DepthTestState::Func::LEQUAL;

		////////////////////////////////////////////////////////////
		if (!shaderProgram.Initiate("ShapeVS.glsl", "ShapePS.glsl"))
		{
			return false;
		}

		////////////////////////////////////////////////////////////
		if (!uniformBlockBuffer
			.Begin(Buffer::Type::UNIFORM_BUFFER, Buffer::Usage::STATIC_DRAW)
			.Fill(&uniformBlockData, sizeof(UniformBlockData))
			.End())
		{
			return false;
		}

		return true;
	}

	void Render(Camera& camera, const Vector2& screenSize)
	{
		//////////////////////////////////////////////////////
		// RS
		renderStates.scissorTestState.size = screenSize;
		renderStates.viewportState.size = screenSize;
		renderStates.Apply();

		///////////////////////////////////////////////////////
		// TexMap

		///////////////////////////////////////////////////////
		shaderProgram.Bind();
		shaderProgram.BindUniformBlock(uniformBlockBuffer, "UniformBlockData", 0);

#ifdef USE_UNIFORM_BLOCK
		uniformBlockData.worldTransform = GetGlobalTransform().Transpose();
		uniformBlockData.viewTransform = camera.GetInverseGlobalTransform().Transpose();
		uniformBlockData.projTransform = camera.GetProjectionTransform().Transpose();
		uniformBlockBuffer.Update(0, &uniformBlockData, sizeof(UniformBlockData));
#else
		shaderProgram.SetUniformMatrix4x4fv("worldTransform", 1, GetGlobalTransform());
		shaderProgram.SetUniformMatrix4x4fv("viewTransform", 1, camera.GetInverseGlobalTransform());
		shaderProgram.SetUniformMatrix4x4fv("projTransform", 1, camera.GetProjectionTransform());
		shaderProgram.SetUniform4fv("color", 1, &uniformBlockData.color[0]);
#endif
		vertexBuffer.Bind();
		vertexBuffer.DrawArray(VertexBuffer::Mode::TRIANGLES, 0, vertexBuffer.GetCount());
	}

	void Terminate()
	{
		renderStates.Terminate();
		texture.Terminate();
		uniformBlockBuffer.Terminate();
		shaderStorageBlockBuffer.Terminate();
		shaderProgram.Terminate();
		vertexBuffer.Terminate();
	}
private:
	RenderStates renderStates;
	Texture2DFile texture;
	UniformBlockData uniformBlockData;
	Buffer uniformBlockBuffer;
	Buffer shaderStorageBlockBuffer;
	ShaderProgram shaderProgram;
	VertexBuffer vertexBuffer;

	std::vector<Vector3> vertices;
};

#endif