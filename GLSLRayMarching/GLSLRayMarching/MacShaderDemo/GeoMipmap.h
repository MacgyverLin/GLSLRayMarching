#ifndef _GeoMipmap_h_
#define _GeoMipmap_h_

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

// #define CAPTURE_GRAPHICS

class GeoMipmap
{
public:

#ifdef CAPTURE_GRAPHICS
#define MAX_LOD 5
#define PATCH_SIZE (32)
#else
#define MAX_LOD 6
#define PATCH_SIZE (64)
#endif

	class Patch
	{
	public:
		enum class Edge
		{
			Left = 8,
			Right = 4,
			Top = 2,
			Bottom = 1
		};

		Patch(std::vector<Vector2>& vertices, unsigned int size_, unsigned int stride_, unsigned int edge_)
		{
			size = size_;
			stride = stride_;

			baseVertexIndex = vertices.size();

			for (int y = 0; y < size; y += stride * 2)
			{
				for (int x = 0; x < size; x += stride * 2)
				{
					if ((x == size - stride * 2))
						x = x;
					if ((y == size - stride * 2))
						y = y;

					bool lodLeft = ((edge_ & (int)Edge::Left) && (x == 0));
					bool lodRight = ((edge_ & (int)Edge::Right) && (x == size - stride * 2));
					bool lodTop = ((edge_ & (int)Edge::Top) && (y == 0));
					bool lodBottom = ((edge_ & (int)Edge::Bottom) && (y == size - stride * 2));
					AddBigQuad(vertices, x, y, lodLeft, lodRight, lodTop, lodBottom);
				}
			}

			vertexCount = vertices.size() - baseVertexIndex;
		}

		~Patch()
		{
		}

		Patch(const Patch& other)
		{
			size = other.size;
			stride = other.stride;
			baseVertexIndex = other.baseVertexIndex;
			vertexCount = other.vertexCount;
		}

		Patch& operator = (const Patch& other)
		{
			size = other.size;
			stride = other.stride;
			baseVertexIndex = other.baseVertexIndex;
			vertexCount = other.vertexCount;

			return *this;
		}

		unsigned int GetSize() const
		{
			return size;
		}

		unsigned int GetBaseVertexIndex() const
		{
			return baseVertexIndex;
		}

		unsigned int GetVertexCount() const
		{
			return vertexCount;
		}
	private:
		void AddBigQuad(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_, bool L, bool R, bool T, bool B)
		{
#define X0 ((x_))
#define X1 ((x_) + stride)
#define X2 ((x_) + stride + stride)
#define Y0 ((y_))
#define Y1 ((y_) + stride)
#define Y2 ((y_) + stride + stride)
			// http://tma.main.jp/logic/index_en.html
			// TL
			// L R T B    NE NW SE SW
			// 0 x 0 x    0  1  1  0
			// 0 x 1 x    0  0  0  1
			// 1 x 0 x    1  0  0  0
			// 1 x 1 x    0  0  0  0
			// NE = L && !T
			// NW = !(L && T)
			// SE = !(L && T)
			// SW = !L && T

			// TR
			// L R T B    NE NW SE SW
			// x 0 0 x    1  0  0  1
			// x 0 1 x    0  0  1  0
			// x 1 0 x    0  1  0  0
			// x 1 1 x    0  0  0  0
			// NE = !(R && T)
			// NW = R && !T
			// SE = !R && T
			// SW = !(R && T)

			// BL
			// L R T B    NE NW SE SW
			// 0 x x 0    1  0  0  1
			// 0 x x 1    0  1  0  0
			// 1 x x 0    0  0  1  0
			// 1 x x 1    0  0  0  0
			// NE = !(L && B)
			// NW = !L && B
			// SE = L && !B
			// SW = !(L && B)

			// BR
			// L R T B    NE NW SE SW
			// x 0 x 0    0  1  1  0
			// x 0 x 1    1  0  0  0
			// x 1 x 0    0  0  0  1
			// x 1 x 1    0  0  0  0
			// NE = !R && B
			// NW = !(R && B)
			// SE = !(R && B)
			// SW = R && !B


			///////////////////////////////////////////////////////////////////////
			// NE = L && !T
			// NW = !(L && T)
			// SE = !(L && T)
			// SW = !L && T
			if (T)
			{
				if (L)
				{
				}
				else
				{
					AddTriangleSouthWest(vertices_, X0, Y0);
				}
			}
			else
			{
				if (L)
				{
					AddTriangleNorthEast(vertices_, X0, Y0);
				}
				else
				{
					AddTriangleNorthWest(vertices_, X0, Y0);
					AddTriangleSouthEast(vertices_, X0, Y0);
				}
			}

			///////////////////////////////////////////////////////////////////////
			// NE = !(R && T)
			// NW = R && !T
			// SE = !R && T
			// SW = !(R && T)
			if (T)
			{
				if (R)
				{
				}
				else
				{
					AddTriangleSouthEast(vertices_, X1, Y0);
				}
			}
			else
			{
				if (R)
				{
					AddTriangleNorthWest(vertices_, X1, Y0);
				}
				else
				{
					AddTriangleNorthEast(vertices_, X1, Y0);
					AddTriangleSouthWest(vertices_, X1, Y0);
				}
			}

			///////////////////////////////////////////////////////////////////////
			// NE = !(L && B)
			// NW = !L && B
			// SE = L && !B
			// SW = !(L && B)
			if (B)
			{
				if (L)
				{
				}
				else
				{
					AddTriangleNorthWest(vertices_, X0, Y1);
				}
			}
			else
			{
				if (L)
				{
					AddTriangleSouthEast(vertices_, X0, Y1);
				}
				else
				{
					AddTriangleNorthEast(vertices_, X0, Y1);
					AddTriangleSouthWest(vertices_, X0, Y1);
				}
			}

			///////////////////////////////////////////////////////////////////////
			// NE = !R && B
			// NW = !(R && B)
			// SE = !(R && B)
			// SW = R && !B
			if (B)
			{
				if (R)
				{
				}
				else
				{
					AddTriangleNorthEast(vertices_, X1, Y1);
				}
			}
			else
			{
				if (R)
				{
					AddTriangleSouthWest(vertices_, X1, Y1);
				}
				else
				{
					AddTriangleSouthEast(vertices_, X1, Y1);
					AddTriangleNorthWest(vertices_, X1, Y1);
				}
			}

			///////////////////////////////////////////////////////////////////////
			if (T)
			{
				AddTriangleTop(vertices_, X0, Y0);
			}

			if (B)
			{
				AddTriangleBottom(vertices_, X0, Y0);
			}

			if (L)
			{
				AddTriangleLeft(vertices_, X0, Y0);
			}

			if (R)
			{
				AddTriangleRight(vertices_, X0, Y0);
			}
		}

		void AddTriangleNorthWest(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X0, Y0);
			AddVertex(vertices_, X0, Y1);
			AddVertex(vertices_, X1, Y0);
		}

		void AddTriangleNorthEast(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X1, Y1);
			AddVertex(vertices_, X1, Y0);
			AddVertex(vertices_, X0, Y0);
		}

		void AddTriangleSouthEast(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X0, Y1);
			AddVertex(vertices_, X1, Y1);
			AddVertex(vertices_, X1, Y0);
		}

		void AddTriangleSouthWest(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X0, Y1);
			AddVertex(vertices_, X1, Y1);
			AddVertex(vertices_, X0, Y0);
		}

		void AddTriangleLeft(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X0, Y0);
			AddVertex(vertices_, X0, Y2);
			AddVertex(vertices_, X1, Y1);
		}

		void AddTriangleRight(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X2, Y0);
			AddVertex(vertices_, X1, Y1);
			AddVertex(vertices_, X2, Y2);
		}

		void AddTriangleTop(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X0, Y0);
			AddVertex(vertices_, X1, Y1);
			AddVertex(vertices_, X2, Y0);
		}

		void AddTriangleBottom(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			AddVertex(vertices_, X0, Y2);
			AddVertex(vertices_, X2, Y2);
			AddVertex(vertices_, X1, Y1);
		}

		void AddVertex(std::vector<Vector2>& vertices_, unsigned int x_, unsigned int y_)
		{
			vertices_.push_back(Vector2(x_, y_));
		}

		unsigned int size;
		unsigned int stride;
		unsigned int baseVertexIndex;
		unsigned int vertexCount;
	};

	class Level
	{
	public:
		Level(std::vector<Vector2>& vertices, unsigned int size_, unsigned int stride_)
		{
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, false, false, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, false, false, true));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, false, true, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, false, true, true));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, true, false, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, true, false, true));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, true, true, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(false, true, true, true));

			AddPatch(vertices, size_, stride_, GetPatchIndex(true, false, false, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, false, false, true));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, false, true, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, false, true, true));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, true, false, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, true, false, true));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, true, true, false));
			AddPatch(vertices, size_, stride_, GetPatchIndex(true, true, true, true));
		}

		~Level()
		{
		}

		Level(const Level& other)
		{
			patches = other.patches;
		}

		Level& operator = (const Level& other)
		{
			patches = other.patches;

			return *this;
		}

		unsigned int GetPatchCount() const
		{
			return patches.size();
		}

		static unsigned int GetPatchIndex(bool coarseLeft_, bool coarseRight_, bool coarseTop_, bool coarseBottom_)
		{
			unsigned int result = 0;
			if (coarseLeft_)
				result |= (int)Patch::Edge::Left;

			if (coarseRight_)
				result |= (int)Patch::Edge::Right;

			if (coarseTop_)
				result |= (int)Patch::Edge::Top;

			if (coarseBottom_)
				result |= (int)Patch::Edge::Bottom;

			return result;
		}

		const Patch& GetPatch(int i) const
		{
			return patches[i];
		}
	private:
		void AddPatch(std::vector<Vector2>& vertices, unsigned int size_, unsigned int stride_, unsigned int edge_)
		{
			patches.push_back(Patch(vertices, size_, stride_, edge_));
		}

		std::vector<Patch> patches;
	};
public:
	class TransformData
	{
	public:
		Matrix4 viewTransform;
		Matrix4 projTransform;
	};

	class RenderInfo
	{
	public:
		bool visible;
		Vector3 offset;
		unsigned int lodLevel;
		unsigned int patchID;
	};

	GeoMipmap()
	{
	}

	~GeoMipmap()
	{
	}

	bool Initiate(unsigned int size_)
	{
		unsigned int mipLevelCount = log(size_) / log(2);

		std::vector<Vector2> vertices;
		for (unsigned int mipLevel_ = 0; mipLevel_ < mipLevelCount; mipLevel_++)
		{
			AddLevel(vertices, size_, mipLevel_);
		}

		////////////////////////////////////////////////////////////
		bool success = vertexBuffer
			.Begin()
			.FillVertices(0, 2, VertexAttribute::DataType::FLOAT, false, 0, 0, 0, &vertices[0], vertices.size())
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
		heightMap.SetMinFilter(Texture::MinFilter::Nearest);
		heightMap.SetMagFilter(Texture::MagFilter::Nearest);
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
		if (!shaderProgram.Initiate("GeoMipMapVS.glsl", "GeoMipMapPS.glsl"))
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

	void CalculatePatches(std::vector<RenderInfo>& terrainRenderInfos_, Camera& camera)
	{
		Frustum f = camera.GetFrustum();
		terrainRenderInfos_.resize(heightMap.GetWidth() / PATCH_SIZE * heightMap.GetHeight() / PATCH_SIZE);

		for (int z = 0; z < heightMap.GetHeight() / PATCH_SIZE; z++)
		{
			for (int x = 0; x < heightMap.GetWidth() / PATCH_SIZE; x++)
			{
				int idx = z * (heightMap.GetWidth() / PATCH_SIZE) + x;
				RenderInfo& info = terrainRenderInfos_[idx];

				AABB3 aabb3(Vector3(x * PATCH_SIZE, 0, z * PATCH_SIZE), Vector3((x + 1) * PATCH_SIZE, 0, (z + 1) * PATCH_SIZE));
				info.visible = true;// IntersectAABBFrustum(f, aabb3);
				info.offset = Vector3(x * PATCH_SIZE, 0, z * PATCH_SIZE);
				info.lodLevel = EstimateLOD(camera, info.offset + Vector3(PATCH_SIZE / 2, 0, PATCH_SIZE / 2));
				info.patchID = 0;
			}
		}

		for (int z = 0; z < heightMap.GetHeight() / PATCH_SIZE; z++)
		{
			for (int x = 0; x < heightMap.GetWidth() / PATCH_SIZE; x++)
			{
				int idxC = (z + 0) * (heightMap.GetWidth() / PATCH_SIZE) + (x + 0);
				int idxL = (z + 0) * (heightMap.GetWidth() / PATCH_SIZE) + (x - 1);
				int idxR = (z + 0) * (heightMap.GetWidth() / PATCH_SIZE) + (x + 1);
				int idxT = (z - 1) * (heightMap.GetWidth() / PATCH_SIZE) + (x + 0);
				int idxB = (z + 1) * (heightMap.GetWidth() / PATCH_SIZE) + (x + 0);

				bool coarseL = ((x - 1) >= 0) ? (terrainRenderInfos_[idxC].lodLevel < terrainRenderInfos_[idxL].lodLevel) : false;
				bool coarseR = ((x + 1) <= (heightMap.GetWidth() / PATCH_SIZE) - 1) ? (terrainRenderInfos_[idxC].lodLevel < terrainRenderInfos_[idxR].lodLevel) : false;
				bool coarseT = ((z - 1) >= 0) ? (terrainRenderInfos_[idxC].lodLevel < terrainRenderInfos_[idxT].lodLevel) : false;
				bool coarseB = ((z + 1) <= (heightMap.GetHeight() / PATCH_SIZE) - 1) ? (terrainRenderInfos_[idxC].lodLevel < terrainRenderInfos_[idxB].lodLevel) : false;

				terrainRenderInfos_[idxC].patchID = GeoMipmap::Level::GetPatchIndex(coarseL, coarseR, coarseT, coarseB);
			}
		}
	}

	void DrawMipmap(Camera& camera, const Vector2& screenSize, bool solid, bool wire)
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
		vertexBuffer.Bind();

		// frustum culling
		// area = b * sqrt(b*b + h*h)
		std::vector<RenderInfo> terrainRenderInfos;
		CalculatePatches(terrainRenderInfos, camera);

		shaderProgram.Bind();
		shaderProgram.SetUniform1i("heightMap", 0);
		shaderProgram.SetUniform1i("texture0", 1);
		shaderProgram.SetUniform1i("texture1", 2);
		shaderProgram.SetUniform1i("texture2", 3);
		shaderProgram.SetUniform1i("texture3", 4);
		shaderProgram.SetUniform1i("splatMap", 5);
		shaderProgram.SetUniform1f("patchSize", PATCH_SIZE);

		shaderProgram.SetUniform2i("heightMapSize", heightMap.GetWidth(), heightMap.GetHeight());
		shaderProgram.SetUniform2i("splatMapSize", splatMap.GetWidth(), splatMap.GetHeight());

		shaderProgram.BindUniformBlock(uniformBlockBuffer, "TransformData", 0);
#define USE_UNIFORM_BLOCK
#ifdef USE_UNIFORM_BLOCK
		Matrix4 worldTransform;
		worldTransform.SetTranslateEulerAngleXYZScale(0, -30, 0, 0, 0, 0, 1.0);
		shaderProgram.SetUniformMatrix4x4fv("worldTransform", 1, worldTransform);

		TransformData transformData;
		transformData.viewTransform = camera.GetInverseGlobalTransform().Transpose();
		transformData.projTransform = camera.GetProjectionTransform().Transpose();
		uniformBlockBuffer.Update(0, &transformData, sizeof(TransformData));
#else
		Matrix4 worldTransform;
		worldTransform.SetTranslateRotXYZScale(0, -30, 0, 0, 0, 0, 1.0);
		shaderProgram.SetUniformMatrix4x4fv("worldTransform", 1, worldTransform);
		
		shaderProgram.SetUniformMatrix4x4fv("viewTransform", 1, camera.GetViewTransform());
		shaderProgram.SetUniformMatrix4x4fv("projTransform", 1, camera.GetProjectionTransform());
#endif

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
					const GeoMipmap::Patch& patch = GetLevel(info.lodLevel).GetPatch(info.patchID);
					float c = ((float)(MAX_LOD - info.lodLevel)) / MAX_LOD;
					shaderProgram.SetUniform1i("useTexture", true);
					shaderProgram.SetUniform2i("offset", info.offset.X(), info.offset.Z());

					vertexBuffer.DrawArray(VertexBuffer::Mode::TRIANGLES, patch.GetBaseVertexIndex(), patch.GetVertexCount());
				}
			}
		}

		if (wire)
		{
			renderStates.blendState.enabled = true;
			renderStates.polygonModeState.mode = PolygonModeState::Mode::LINE;
			renderStates.polygonOffsetState.factor = 2.0;
			renderStates.polygonOffsetState.offset = 10.0;
			renderStates.Apply();
			for (int i = 0; i < terrainRenderInfos.size(); i++)
			{
				RenderInfo& info = terrainRenderInfos[i];
				if (info.visible)
				{
					const GeoMipmap::Patch& patch = GetLevel(info.lodLevel).GetPatch(info.patchID);
					float c = ((float)(MAX_LOD - info.lodLevel)) / MAX_LOD;
					shaderProgram.SetUniform1i("useTexture", false);
					shaderProgram.SetUniform2i("offset", info.offset.X(), info.offset.Z());

					vertexBuffer.DrawArray(VertexBuffer::Mode::TRIANGLES, patch.GetBaseVertexIndex(), patch.GetVertexCount());
				}
			}
		}

		int a = 1;
	}

	void DrawMipmap2(Camera& camera, const Vector2& screenSize, bool solid, bool wire)
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
		vertexBuffer.Bind();

		// frustum culling
		// area = b * sqrt(b*b + h*h)
		std::vector<RenderInfo> terrainRenderInfos;
		CalculatePatches(terrainRenderInfos, camera);

		shaderProgram.Bind();
		shaderProgram.SetUniform1i("heightMap", 0);
		shaderProgram.SetUniform1i("texture0", 1);
		shaderProgram.SetUniform1i("texture1", 2);
		shaderProgram.SetUniform1i("texture2", 3);
		shaderProgram.SetUniform1i("texture3", 4);
		shaderProgram.SetUniform1i("splatMap", 5);
		shaderProgram.SetUniform1f("patchSize", PATCH_SIZE);

		shaderProgram.SetUniform2i("heightMapSize", heightMap.GetWidth(), heightMap.GetHeight());
		shaderProgram.SetUniform2i("splatMapSize", splatMap.GetWidth(), splatMap.GetHeight());

		shaderProgram.BindUniformBlock(uniformBlockBuffer, "TransformData", 0);
#define USE_UNIFORM_BLOCK
#ifdef USE_UNIFORM_BLOCK
		Matrix4 worldTransform;
		worldTransform.SetTranslateEulerAngleXYZScale(0, -30, 0, 0, 0, 0, 1.0);
		shaderProgram.SetUniformMatrix4x4fv("worldTransform", 1, worldTransform);

		TransformData transformData;
		transformData.viewTransform = camera.GetInverseGlobalTransform().Transpose();
		transformData.projTransform = camera.GetProjectionTransform().Transpose();
		uniformBlockBuffer.Update(0, &transformData, sizeof(TransformData));
#else
		Matrix4 worldTransform;
		worldTransform.SetTranslateRotXYZScale(0, -30, 0, 0, 0, 0, 1.0);
		shaderProgram.SetUniformMatrix4x4fv("worldTransform", 1, worldTransform);

		shaderProgram.SetUniformMatrix4x4fv("viewTransform", 1, camera.GetViewTransform());
		shaderProgram.SetUniformMatrix4x4fv("projTransform", 1, camera.GetProjectionTransform());
#endif

		renderStates.blendState.enabled = true;
		renderStates.polygonModeState.mode = PolygonModeState::Mode::LINE;
		renderStates.polygonOffsetState.factor = 2.0;
		renderStates.polygonOffsetState.offset = 10.0;
		renderStates.Apply();

		#define PATCH_SIZE1 (PATCH_SIZE * 1.2)
		Vector3 offsets[16] =
		{
			Vector3(PATCH_SIZE1 * 0, 0, PATCH_SIZE1 * 0), // 0
			Vector3(PATCH_SIZE1 * 0, 0, PATCH_SIZE1 * 1), // 1
			Vector3(PATCH_SIZE1 * 1, 0, PATCH_SIZE1 * 1), // 2
			Vector3(PATCH_SIZE1 * 0, 0, PATCH_SIZE1 * 2), // 3
			Vector3(PATCH_SIZE1 * 2, 0, PATCH_SIZE1 * 1), // 4
			Vector3(PATCH_SIZE1 * 1, 0, PATCH_SIZE1 * 2), // 5
			Vector3(PATCH_SIZE1 * 2, 0, PATCH_SIZE1 * 2), // 6
			Vector3(PATCH_SIZE1 * 1, 0, PATCH_SIZE1 * 3), // 7
			Vector3(PATCH_SIZE1 * 3, 0, PATCH_SIZE1 * 1), // 8			
			Vector3(PATCH_SIZE1 * 3, 0, PATCH_SIZE1 * 2), // 9
			Vector3(PATCH_SIZE1 * 4, 0, PATCH_SIZE1 * 2), // 10
			Vector3(PATCH_SIZE1 * 2, 0, PATCH_SIZE1 * 3), // 11
			Vector3(PATCH_SIZE1 * 5, 0, PATCH_SIZE1 * 2), // 12
			Vector3(PATCH_SIZE1 * 3, 0, PATCH_SIZE1 * 3), // 13
			Vector3(PATCH_SIZE1 * 0, 0, PATCH_SIZE1 * 3), // 14
			Vector3(PATCH_SIZE1 * 0, 0, PATCH_SIZE1 * 4)  // 15
		};
		for (int i = 0; i < 16; i++)
		{
			RenderInfo& info = terrainRenderInfos[i];

			info.visible = true;
			info.offset = offsets[i];
			info.lodLevel = 0;
			info.patchID = i;

			const GeoMipmap::Patch& patch = GetLevel(info.lodLevel).GetPatch(info.patchID);
			float c = ((float)(MAX_LOD - info.lodLevel)) / MAX_LOD;
			shaderProgram.SetUniform1i("useTexture", false);
			shaderProgram.SetUniform2i("offset", info.offset.X(), info.offset.Z());

			vertexBuffer.DrawArray(VertexBuffer::Mode::TRIANGLES, patch.GetBaseVertexIndex(), patch.GetVertexCount());
		}
	}

	void Render(Camera& camera, const Vector2& screenSize, bool solid, bool wire)
	{
#ifdef CAPTURE_GRAPHICS
		DrawMipmap2(camera, screenSize, solid, wire);
#else
		DrawMipmap(camera, screenSize, solid, wire);
#endif
	}

	void Terminate()
	{
		heightMap.Terminate();
		shaderStorageBlockBuffer.Terminate();

		uniformBlockBuffer.Terminate();
		shaderProgram.Terminate();
		renderStates.Terminate();

		vertexBuffer.Terminate();
	}

	unsigned int GetLevelsCount() const
	{
		return levels.size();
	}

	const Level& GetLevel(int i) const
	{
		return levels[i];
	}
private:
	void AddLevel(std::vector<Vector2>& vertices_, unsigned int size_, unsigned int mipLevel_)
	{
		unsigned int stride = pow(2, mipLevel_);
		levels.push_back(Level(vertices_, size_, stride));
	}

	Texture2DFile texture0;
	Texture2DFile texture1;
	Texture2DFile texture2;
	Texture2DFile texture3;
	Texture2DFile splatMap;

	Texture2DFile heightMap;
	Buffer shaderStorageBlockBuffer;

	std::vector<Level> levels;

	RenderStates renderStates;
	ShaderProgram shaderProgram;
	Buffer uniformBlockBuffer;
	VertexBuffer vertexBuffer;
};

#endif