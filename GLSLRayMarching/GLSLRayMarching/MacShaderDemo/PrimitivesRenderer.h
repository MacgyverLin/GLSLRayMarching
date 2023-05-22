#ifndef _PrimitivesRenderer_h_
#define _PrimitivesRenderer_h_
		 
#include "Scene.h"
#include "GameObject.h"
#include "Texture.h"
#include "Scene.h"
#include "RenderStates.h"
#include "ShaderProgram.h"
#include "Buffer.h"
#include "VertexBuffer.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix4.h"
#include "GUI.h"
#include "Camera.h"
#include "GameObject.h"
#include "Video.h"
#include "Primitive.h"

////////////////////////////////////////////////////////////////////////////
#define GEOMETRY_TEXTURE_SIZE 1024
#define NORMAL_TEXTURE_SIZE 512

////////////////////////////////////////////////////////////////////////////
class PrimitivesRenderer : public Video::RendererComponent
{
private:
	std::vector<Primitive> primitives;

	ShaderProgram shader;
	RenderStates renderStates;
	VertexBuffer vertexBuffer;

	Matrix4 worldTransform;
	Matrix4 viewTransform;
	Matrix4 projTransform;
public:
	PrimitivesRenderer(GameObject& gameObject)
		: Video::RendererComponent(gameObject)
	{
	}

	~PrimitivesRenderer()
	{
	}

	void SetWorldTransform(Matrix4 worldTransform, Matrix4 viewTransform, Matrix4 projTransform)
	{
		this->worldTransform = worldTransform;
		this->viewTransform = viewTransform;
		this->projTransform = projTransform;
	}

	void UpdateShader(bool& wireframe, int& lod, float& ratio)
	{
		GUI::Test3(lod, ratio, wireframe);

		shader.Bind();
		shader.SetUniform1i("geometryTexture", 0);
		shader.SetUniform1i("normalTexture", 1);

		shader.SetUniformMatrix4x4fv("worldTransform", 1, worldTransform);

		shader.SetUniformMatrix4x4fv("viewTransform", 1, viewTransform);
		shader.SetUniformMatrix4x4fv("projTransform", 1, projTransform);
		shader.SetUniform1i("lod", lod);
		shader.SetUniform1f("ratio", ratio / 100.0f);
		
		//shaderStorageBlockBuffer.Update(0, vertexData, sizeof(VertexData) * 4);
	}

	virtual bool OnInitiate() override
	{
		// vertex buffer
		// texture


		// shader
		if (!shader.Initiate("primitivesVS.glsl", "primitivesPS.glsl"))
		{
			return false;
		}

		// uniform

		return true;
	}

	virtual bool OnUpdate() override
	{
		unsigned int count = shader.GetActiveUniformCount();
		std::string name;
		UniformType uniformType;
		int size;
		for (int i = 0; i < count; i++)
		{
			shader.GetActiveUniformInfo(i, name, uniformType, size);
		}


		// shader
		static int lod = 0;
		static bool wireframe = true;
		static float ratio = 0.0;
		UpdateShader(wireframe, lod, ratio);


		// render sate
		renderStates.scissorTestState.enabled = true;
		renderStates.scissorTestState.pos = Vector2(0, 0);
		renderStates.scissorTestState.size = Vector2(Platform::GetWidth(), Platform::GetHeight());
		renderStates.viewportState.pos = Vector2(0, 0);
		renderStates.viewportState.size = Vector2(Platform::GetWidth(), Platform::GetHeight());

		renderStates.polygonModeState.face = PolygonModeState::Face::FRONT_AND_BACK;
		if (wireframe)
			renderStates.polygonModeState.mode = PolygonModeState::Mode::LINE;
		else
			renderStates.polygonModeState.mode = PolygonModeState::Mode::FILL;

		renderStates.depthTestState.depthTestEnabled = true;
		renderStates.depthTestState.depthWriteEnabled = true;
		renderStates.depthTestState.func = DepthTestState::Func::LEQUAL;
		renderStates.Apply();

		// texture

		// primitives
		for (auto& primitive : primitives)
		{
			vertexBuffer.Bind();

			//layout(location = 0) in vec3 vPos;
			//layout(location = 1) in vec3 vNormal;
			//layout(location = 2) in vec4 vCol;
			//layout(location = 3) in vec2 vUV;
			bool success = vertexBuffer
				.Begin()
				.FillVertices(0, 3, VertexAttribute::DataType::FLOAT, false,   0, 12, 0, &primitive.vertices[0], primitive.vertices.size())
				.FillVertices(1, 3, VertexAttribute::DataType::FLOAT, false,   3, 12, 0, &primitive.vertices[0], primitive.vertices.size())
				.FillVertices(2, 4, VertexAttribute::DataType::FLOAT, false, 3+3, 12, 0, &primitive.vertices[0], primitive.vertices.size())
				.FillVertices(3, 2, VertexAttribute::DataType::FLOAT, false, 3+4, 12, 0, &primitive.vertices[0], primitive.vertices.size())
				.End();

			if (!success)
			{
				return false;
			}
			/*
			bool success = vertexBuffer
				.Begin()
				.FillVertices(0, 2, VertexAttribute::DataType::FLOAT, false, 0, 0, &vertices[0], sizeof(vertices) / sizeof(vertices[0]) / 2)
				.End();
			if (!success)
			{
				return false;
			}
			*/

			vertexBuffer.DrawArray(VertexBuffer::Mode::TRIANGLES, 0, vertexBuffer.GetCount());
		}

		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
		shader.Terminate();
		renderStates.Terminate();
		vertexBuffer.Terminate();
	}

	virtual void OnRender() override
	{
	}


	void Clear()
	{
		primitives.clear();
	}

	void DrawPoint(const Vector3& p, const ColorRGBA& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawPoint(p, c);
	}

	void DrawLine(const Vector3& p0, const Vector3& p1, const ColorRGBA& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawLine(p0, p1, c);
	}

	void DrawLine(const Vector3& p0, const ColorRGBA& c0, const Vector3& p1, const ColorRGBA& c1)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawLine(p0, c0, p1, c1);
	}

	void DrawLines(const std::vector<Vector3>& p, const std::vector<ColorRGBA>& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawLines(p, c);
	}

	void DrawTriangle(const Vector3& p0, const Vector3& p1, const Vector3& p2, const ColorRGBA& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawTriangle(p0, p1, p2, c);
	}

	void DrawTriangle(const Vector3& p0, const ColorRGBA& c0, const Vector3& p1, const ColorRGBA& c1, const Vector3& p2, const ColorRGBA& c2)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawTriangle(p0, c0, p1, c1, p2, c2);
	}

	void DrawTriangles(const std::vector<Vector3>& p, const std::vector<ColorRGBA>& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawTriangles(p, c);
	}

	void DrawQuad(const Vector3& p0, const Vector3& p1, const Vector3& p2, const Vector3& p3, const ColorRGBA& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawQuad(p0, p1, p2, p3, c);
	}

	void DrawQuad(const Vector3& p0, const ColorRGBA& c0, const Vector3& p1, const ColorRGBA& c1, const Vector3& p2, const ColorRGBA& c2, const Vector3& p3, const ColorRGBA& c3)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawQuad(p0, c0, p1, c1, p2, c2, p3, c3);
	}

	void DrawQuad(const std::vector<Vector3>& p, const std::vector<ColorRGBA>& c)
	{
		primitives.push_back(Primitive());

		primitives.back().DrawQuads(p, c);
	}

	void DrawGrid(float min, float max, float gridSize, const ColorRGBA& c)
	{
		std::vector<Vector3> ps;
		std::vector<ColorRGBA> cs;

		for (float x = min; x <= max; x += gridSize)
		{
			ps.push_back(Vector3(x, 0, min)); cs.push_back(c);
			ps.push_back(Vector3(x, 0, max)); cs.push_back(c);
		}

		for (float z = min; z <= max; z += gridSize)
		{
			ps.push_back(Vector3(min, 0, z)); cs.push_back(c);
			ps.push_back(Vector3(max, 0, z)); cs.push_back(c);
		}

		primitives.push_back(Primitive());

		primitives.back().DrawLines(ps, cs);
	}

};

#endif