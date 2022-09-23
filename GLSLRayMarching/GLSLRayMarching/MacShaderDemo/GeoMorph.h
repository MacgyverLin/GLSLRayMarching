#ifndef _GeoMorph_h_
#define _GeoMorph_h_

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
#include "Camera.h"
#include "Vector4.h"
class GeoMorph
{
public:
#define GEOMORPH_PATCH_SIZE
	class Patch
	{
	public:
		Patch(std::vector<Vector4>& vertices_, std::vector<unsigned int>& indices_)
		{
			vertices_.resize(25);
			vertices_[0]  = Vector4(0, 0,  0,  0);
			vertices_[1]  = Vector4(0, 1,  0,  1);
			vertices_[2]  = Vector4(0, 2,  0,  0);
			vertices_[3]  = Vector4(0, 3,  0, -1);
			vertices_[4]  = Vector4(0, 4,  0,  0);
			vertices_[5]  = Vector4(1, 4,  1,  0);
			vertices_[6]  = Vector4(2, 4,  0,  0);
			vertices_[7]  = Vector4(3, 4, -1,  0);
			vertices_[8]  = Vector4(4, 4,  0,  0);
			vertices_[9]  = Vector4(4, 3,  0, -1);
			vertices_[10] = Vector4(4, 2,  0,  0);
			vertices_[11] = Vector4(4, 1,  0,  1);
			vertices_[12] = Vector4(4, 0,  0,  0);
			vertices_[13] = Vector4(3, 0, -1,  0);
			vertices_[14] = Vector4(2, 0,  0,  0);
			vertices_[15] = Vector4(1, 0,  1,  0);
			vertices_[16] = Vector4(1, 1,  1,  1);
			vertices_[17] = Vector4(1, 2,  1,  0);
			vertices_[18] = Vector4(1, 3,  1, -1);
			vertices_[19] = Vector4(2, 3,  0, -1);
			vertices_[20] = Vector4(3, 3, -1, -1);
			vertices_[21] = Vector4(3, 2, -1,  0);
			vertices_[22] = Vector4(3, 1, -1,  1);
			vertices_[23] = Vector4(2, 1,  0,  1);
			vertices_[24] = Vector4(2, 2,  0,  0);

			indices_.resize(96);
			indices_[0] = 1;
			indices_[1] = 16;
			indices_[2] = 0;

			indices_[3] = 0;
			indices_[4] = 16;
			indices_[5] = 15;

			indices_[6] = 15;
			indices_[7] = 16;
			indices_[8] = 14;

			indices_[9] = 14;
			indices_[10] = 16;
			indices_[11] = 23;

			indices_[12] = 23;
			indices_[13] = 22;
			indices_[14] = 14;

			indices_[15] = 14;
			indices_[16] = 22;
			indices_[17] = 13;

			indices_[18] = 13;
			indices_[19] = 22;
			indices_[20] = 12;

			indices_[21] = 12;
			indices_[22] = 22;
			indices_[23] = 11;

			indices_[24] = 1;
			indices_[25] = 2;
			indices_[26] = 16;

			indices_[27] = 16;
			indices_[28] = 2;
			indices_[29] = 17;

			indices_[30] = 17;
			indices_[31] = 24;
			indices_[32] = 16;

			indices_[33] = 16;
			indices_[34] = 24;
			indices_[35] = 23;

			indices_[36] = 23;
			indices_[37] = 24;
			indices_[38] = 22;

			indices_[39] = 22;
			indices_[40] = 24;
			indices_[41] = 21;

			indices_[42] = 21;
			indices_[43] = 10;
			indices_[44] = 22;

			indices_[45] = 22;
			indices_[46] = 10;
			indices_[47] = 11;

			indices_[48] = 3;
			indices_[49] = 18;
			indices_[50] = 2;

			indices_[51] = 2;
			indices_[52] = 18;
			indices_[53] = 17;

			indices_[54] = 17;
			indices_[55] = 18;
			indices_[56] = 24;

			indices_[57] = 24;
			indices_[58] = 18;
			indices_[59] = 19;

			indices_[60] = 19;
			indices_[61] = 20;
			indices_[62] = 24;

			indices_[63] = 24;
			indices_[64] = 20;
			indices_[65] = 21;

			indices_[66] = 21;
			indices_[67] = 20;
			indices_[68] = 10;

			indices_[69] = 10;
			indices_[70] = 20;
			indices_[71] = 9;

			indices_[72] = 3;
			indices_[73] = 4;
			indices_[74] = 18;

			indices_[75] = 18;
			indices_[76] = 4;
			indices_[77] = 5;

			indices_[78] = 5;
			indices_[79] = 6;
			indices_[80] = 18;

			indices_[81] = 18;
			indices_[82] = 6;
			indices_[83] = 19;

			indices_[84] = 19;
			indices_[85] = 6;
			indices_[86] = 20;

			indices_[87] = 20;
			indices_[88] = 6;
			indices_[89] = 7;

			indices_[90] = 7;
			indices_[91] = 8;
			indices_[92] = 20;

			indices_[93] = 20;
			indices_[94] = 8;
			indices_[95] = 9;
		}

		~Patch()
		{
		}

		Patch(const Patch& other)
		{
		}

		Patch& operator = (const Patch& other)
		{
			return *this;
		}
	private:
	};
public:
	class TransformData
	{
	public:
		Matrix4 viewTransform;
		Matrix4 projTransform;
	};

	GeoMorph()
	{
	}

	~GeoMorph()
	{
	}

	bool Initiate()
	{
		std::vector<Vector4> vertices;
		std::vector<unsigned int> indices;
		Patch patch(vertices, indices);

		////////////////////////////////////////////////////////////
		bool success = primitives
			.Begin()
			.FillVertices(0, 4, VertexAttribute::DataType::FLOAT, false, 0, 0, &vertices[0], vertices.size())
			.FillIndices(&indices[0], indices.size())
			.End();
		if (!success)
		{
			return false;
		}

		////////////////////////////////////////////////////////////
		if (!heightMap.Initiate("heightMap1.hdr", false))
		{
			return false;
		}
		heightMap.SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
		heightMap.SetMagFilter(Texture::MagFilter::Linear);
		heightMap.SetWarpS(Texture::Wrap::Clamp);
		heightMap.SetWarpR(Texture::Wrap::Clamp);
		heightMap.SetWarpT(Texture::Wrap::Clamp);


		if (!texture0.Initiate("texture0.jpg", false))
		{
			return false;
		}
		texture0.SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
		texture0.SetMagFilter(Texture::MagFilter::Linear);
		texture0.SetWarpS(Texture::Wrap::Repeat);
		texture0.SetWarpR(Texture::Wrap::Repeat);
		texture0.SetWarpT(Texture::Wrap::Repeat);

		if (!texture1.Initiate("texture1.jpg", false))
		{
			return false;
		}
		texture1.SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
		texture1.SetMagFilter(Texture::MagFilter::Linear);
		texture1.SetWarpS(Texture::Wrap::Repeat);
		texture1.SetWarpR(Texture::Wrap::Repeat);
		texture1.SetWarpT(Texture::Wrap::Repeat);

		if (!texture2.Initiate("texture2.jpg", false))
		{
			return false;
		}
		texture2.SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
		texture2.SetMagFilter(Texture::MagFilter::Linear);
		texture2.SetWarpS(Texture::Wrap::Repeat);
		texture2.SetWarpR(Texture::Wrap::Repeat);
		texture2.SetWarpT(Texture::Wrap::Repeat);

		if (!texture3.Initiate("texture3.jpg", false))
		{
			return false;
		}
		texture3.SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
		texture3.SetMagFilter(Texture::MagFilter::Linear);
		texture3.SetWarpS(Texture::Wrap::Repeat);
		texture3.SetWarpR(Texture::Wrap::Repeat);
		texture3.SetWarpT(Texture::Wrap::Repeat);

		if (!splatMap.Initiate("splatmap.jpg", false))
		{
			return false;
		}
		splatMap.SetMinFilter(Texture::MinFilter::LinearMipmapLinear);
		splatMap.SetMagFilter(Texture::MagFilter::Linear);
		splatMap.SetWarpS(Texture::Wrap::Repeat);
		splatMap.SetWarpR(Texture::Wrap::Repeat);
		splatMap.SetWarpT(Texture::Wrap::Repeat);

		////////////////////////////////////////////////////////////
		if (!shaderProgram.Initiate("GeoMorphVS.glsl", "GeoMorphPS.glsl"))
		{
			return false;
		}

		////////////////////////////////////////////////////////////
		TransformData transformData;
		if (!uniformBlockBuffer
			.Begin(Buffer::Type::UNIFORM_BUFFER, Buffer::Usage::STATIC_DRAW)
			.Fill(&transformData, sizeof(TransformData))
			.End()
			)
		{
			return false;
		}

		return true;
	}

	unsigned int EstimateLOD(Camera& camera, Vector3 worldpos)
	{
		Vector3 viewpos = camera.GetInverseGlobalTransform() * Vector3(worldpos.X(), worldpos.Y(), worldpos.Z());
		viewpos.Y() = 0;
		float dist = viewpos.Length();

#define SCALE 10
		float maxdist = 10;
		for (int i = 0; i < MAX_LOD; i++)
		{
			if (dist < maxdist * SCALE)
			{
				return i;
			}
			maxdist *= 2;
		}

		return MAX_LOD - 1;
	}

	bool IntersectAABBFrustum(Frustum& f, AABB3& aabb)
	{
		float m, n;
		int i;
		int result = true;

		Vector3 bm = aabb.Center();
		Vector3 bd = aabb.Extent();

		for (i = 0; i < f.GetPlaneCount(); i++)
		{
			const Plane3& p = f.GetPlane(i);

			m = (bm.X() * p.Normal().X()) + (bm.Y() * p.Normal().Y()) + (bm.Z() * p.Normal().Z()) + p.Constant();
			n = (bd.X() * Math::FAbs(p.Normal().X())) + (bd.Y() * Math::FAbs(p.Normal().Y())) + (bm.Z() * Math::FAbs(p.Normal().Z()));

			if (m + n < 0)
				return false;
			if (m - n < 0)
				result = true;
		}

		return result;
	}

	class RenderInfo
	{
	public:
		float offsetX;
		float offsetZ;
		float sizeX;
		float sizeZ;
	};

	void CalculatePatches(std::vector<RenderInfo>& terrainRenderInfos_, 
							Camera& camera, float x, float z, float sizeX, float sizeZ)
	{
		Vector3 halfSize = Vector3(sizeX * 0.5f, 0, sizeZ * 0.5f);

		Vector3 p(x + halfSize.X(), 0, z + halfSize.Z());
		float d = (camera.GetGlobalPosition() - p).Length();
		if (d > 100.0)
		{
			RenderInfo info;
			info.offsetX = x;
			info.offsetZ = z;
			info.sizeX = sizeX;
			info.sizeZ = sizeZ;
			terrainRenderInfos_.push_back(info);
		}
		else
		{
			CalculatePatches(terrainRenderInfos_, camera, x + 0, z + 0, halfSize.X(), halfSize.Z());
			CalculatePatches(terrainRenderInfos_, camera, x + halfSize.X(), z + 0, halfSize.X(), halfSize.Z());
			CalculatePatches(terrainRenderInfos_, camera, x + 0, z + halfSize.Z(), halfSize.X(), halfSize.Z());
			CalculatePatches(terrainRenderInfos_, camera, x + halfSize.X(), z + halfSize.Z(), halfSize.X(), halfSize.Z());
		}
	}

	void DrawMipmap(Camera& camera, const Vector2& screenSize, bool solid, bool wire, float alpha)
	{
		//////////////////////////////////////////////////////
		// RS
		renderStates.scissorTestState.enabled = true;
		renderStates.scissorTestState.pos = Vector2(0, 0);
		renderStates.scissorTestState.size = screenSize;
		renderStates.viewportState.pos = Vector2(0, 0);
		renderStates.viewportState.size = screenSize;

		renderStates.blendState.colorSrcFactor = BlendState::Func::SRC_ALPHA;
		renderStates.blendState.colorDstFactor = BlendState::Func::ONE_MINUS_SRC_ALPHA;
		renderStates.blendState.alphaSrcFactor = BlendState::Func::ONE;
		renderStates.blendState.alphaDstFactor = BlendState::Func::ZERO;

		renderStates.polygonModeState.face = PolygonModeState::Face::FRONT_AND_BACK;
		renderStates.polygonModeState.mode = PolygonModeState::Mode::LINE;

		renderStates.cullFaceState.enabled = true;
		renderStates.cullFaceState.mode = CullFaceState::Mode::BACK;

		renderStates.depthTestState.depthTestEnabled = true;
		renderStates.depthTestState.depthWriteEnabled = true;
		renderStates.depthTestState.func = DepthTestState::Func::LEQUAL;
		renderStates.Apply();

		///////////////////////////////////////////////////////
		// TexMap
		heightMap.Bind(0);
		texture0.Bind(1);
		texture1.Bind(2);
		texture2.Bind(3);
		texture3.Bind(4);
		splatMap.Bind(5);

		///////////////////////////////////////////////////////
		primitives.Bind();

		// frustum culling
		// area = b * sqrt(b*b + h*h)
		std::vector<RenderInfo> terrainRenderInfos;
		CalculatePatches(terrainRenderInfos, camera, 0, 0, heightMap.GetWidth()/10, heightMap.GetHeight() / 10);

		shaderProgram.Bind();
		shaderProgram.SetUniform1i("heightMap", 0);
		shaderProgram.SetUniform1i("texture0", 1);
		shaderProgram.SetUniform1i("texture1", 2);
		shaderProgram.SetUniform1i("texture2", 3);
		shaderProgram.SetUniform1i("texture3", 4);
		shaderProgram.SetUniform1i("splatMap", 5);
		shaderProgram.SetUniform2i("heightMapSize", heightMap.GetWidth(), heightMap.GetHeight());
		shaderProgram.SetUniform2i("splatMapSize", splatMap.GetWidth(), splatMap.GetHeight());

		Matrix4 worldTransform;
		worldTransform.SetTranslateRotXYZScale(0, -30, 0, 0, 0, 0, 1.0);
		shaderProgram.SetUniformMatrix4x4fv("worldTransform", 1, worldTransform);

#define USE_UNIFORM_BLOCK
#ifdef USE_UNIFORM_BLOCK
		shaderProgram.BindUniformBlock(uniformBlockBuffer, "TransformData", 0);

		TransformData transformData;
		transformData.viewTransform = camera.GetInverseGlobalTransform().Transpose();
		transformData.projTransform = camera.GetProjectionTransform().Transpose();
		uniformBlockBuffer.Update(0, &transformData, sizeof(TransformData));
#else
		shaderProgram.SetUniformMatrix4x4fv("viewTransform", 1, camera.GetViewTransform());
		shaderProgram.SetUniformMatrix4x4fv("projTransform", 1, camera.GetProjectionTransform());
#endif

#if 0
		if (solid)
		{
			renderStates.blendState.enabled = false;
			renderStates.polygonModeState.mode = PolygonModeState::Mode::FILL;
			renderStates.polygonOffsetState.factor = 1.0;
			renderStates.polygonOffsetState.offset = 0.0;
			renderStates.Apply();
			for (int i = 0; i < terrainRenderInfos.size(); i++)
			{
				RenderInfo& info = terrainRenderInfos[i];
				if (info.visible)
				{
					const GeoMipmap<Vector2>::Patch& patch = GetLevel(info.lodLevel).GetPatch(info.patchID);
					float c = ((float)(MAX_LOD - info.lodLevel)) / MAX_LOD;
					shaderProgram.SetUniform1i("useTexture", true);
					shaderProgram.SetUniform2i("offset", info.offset.X(), info.offset.Z());

					primitives.DrawArray(Primitives::Mode::TRIANGLES, patch.GetBaseVertexIndex(), patch.GetVertexCount());
				}
			}
		}
#endif
		if (wire)
		{
			//renderStates.cullFaceState.enabled = false;
			//renderStates.blendState.enabled = true;
			//renderStates.polygonModeState.mode = PolygonModeState::Mode::FILL;
			//renderStates.polygonOffsetState.factor = 2.0;
			//renderStates.polygonOffsetState.offset = 10.0;
			renderStates.Apply();
			for (int i = 0; i < terrainRenderInfos.size(); i++)
			{
				shaderProgram.SetUniform2i("offset", terrainRenderInfos[i].offsetX, terrainRenderInfos[i].offsetZ);
				shaderProgram.SetUniform2i("size", terrainRenderInfos[i].sizeX, terrainRenderInfos[i].sizeZ);
				shaderProgram.SetUniform1f("alpha", alpha);

				RenderInfo& info = terrainRenderInfos[i];
				primitives.DrawIndices(VertexBuffer::Mode::TRIANGLES, 0, 96);
			}
		}
	}

	void DrawCamera(Camera& camera)
	{
	}

	void Render(Camera& camera, const Vector2& screenSize, bool solid, bool wire, float alpha)
	{
		DrawMipmap(camera, screenSize, solid, wire, alpha);

		DrawCamera(camera);
	}

	void Terminate()
	{
		heightMap.Terminate();
		shaderStorageBlockBuffer.Terminate();

		uniformBlockBuffer.Terminate();
		shaderProgram.Terminate();
		renderStates.Terminate();

		primitives.Terminate();
	}
private:
	Texture2DFile texture0;
	Texture2DFile texture1;
	Texture2DFile texture2;
	Texture2DFile texture3;
	Texture2DFile splatMap;

	Texture2DFile heightMap;
	Buffer shaderStorageBlockBuffer;

	RenderStates renderStates;
	ShaderProgram shaderProgram;
	Buffer uniformBlockBuffer;
	VertexBuffer primitives;
};

#endif