#ifndef _Mesh_h_
#define _Mesh_h_

#include "Vector2.h"
#include "Vector3.h"
#include "ColorRGBA.h"
#include "Edge.h"

class Mesh
{
public:
#define MAX_COLOR_SET_COUNT 1
#define MAX_NORMAL_SET_COUNT 1
#define MAX_UV_SET_COUNT 8
#define MAX_TANGENT_SET_COUNT 1
#define MAX_BINORMAL_SET_COUNT 1

	class Index
	{
	public:
		int vIdx;
		int cIdx[MAX_COLOR_SET_COUNT];
		int nIdx[MAX_NORMAL_SET_COUNT];
		int uvIdx[MAX_UV_SET_COUNT];
		int tIdx[MAX_TANGENT_SET_COUNT];
		int bIdx[MAX_BINORMAL_SET_COUNT];

		Index()
		{
			vIdx = 0;

			for (int i = 0; i < MAX_COLOR_SET_COUNT; i++)
				cIdx[i] = 0;

			for (int i = 0; i < MAX_NORMAL_SET_COUNT; i++)
				nIdx[i] = 0;

			for (int i = 0; i < MAX_UV_SET_COUNT; i++)
				uvIdx[i] = 0;

			for (int i = 0; i < MAX_TANGENT_SET_COUNT; i++)
				tIdx[i] = 0;

			for (int i = 0; i < MAX_BINORMAL_SET_COUNT; i++)
				bIdx[i] = 0;
		}

		Index(const Index& other)
		{
			vIdx = other.vIdx;

			for (int i = 0; i < MAX_COLOR_SET_COUNT; i++)
				cIdx[i] = other.cIdx[i];

			for (int i = 0; i < MAX_NORMAL_SET_COUNT; i++)
				nIdx[i] = other.nIdx[i];

			for (int i = 0; i < MAX_UV_SET_COUNT; i++)
				uvIdx[i] = other.uvIdx[i];

			for (int i = 0; i < MAX_TANGENT_SET_COUNT; i++)
				tIdx[i] = other.tIdx[i];

			for (int i = 0; i < MAX_BINORMAL_SET_COUNT; i++)
				bIdx[i] = other.bIdx[i];
		}

		Index operator&(const Index& other)
		{
			vIdx = other.vIdx;

			for (int i = 0; i < MAX_COLOR_SET_COUNT; i++)
				cIdx[i] = other.cIdx[i];

			for (int i = 0; i < MAX_NORMAL_SET_COUNT; i++)
				nIdx[i] = other.nIdx[i];

			for (int i = 0; i < MAX_UV_SET_COUNT; i++)
				uvIdx[i] = other.uvIdx[i];

			for (int i = 0; i < MAX_TANGENT_SET_COUNT; i++)
				tIdx[i] = other.tIdx[i];

			for (int i = 0; i < MAX_BINORMAL_SET_COUNT; i++)
				bIdx[i] = other.bIdx[i];

			return *this;
		}
	};

	std::vector<Vector3> positions;
	std::vector<ColorRGBA> colors[MAX_COLOR_SET_COUNT];
	std::vector<Vector3> normals[MAX_NORMAL_SET_COUNT];
	std::vector<Vector2> uvs[MAX_UV_SET_COUNT];
	std::vector<Vector3> tangents[MAX_TANGENT_SET_COUNT];
	std::vector<Vector3> binormals[MAX_BINORMAL_SET_COUNT];

	std::vector<Index> indices;
public:
	Mesh()
	{
	}

	~Mesh()
	{
	}

	Mesh(const Mesh& mesh)
	{
		this->positions = mesh.positions;
		for (int i = 0; i < MAX_COLOR_SET_COUNT; i++)
			this->colors[i] = mesh.colors[i];
		for (int i = 0; i < MAX_NORMAL_SET_COUNT; i++)
			this->normals[i] = mesh.normals[i];
		for (int i = 0; i < MAX_UV_SET_COUNT; i++)
			this->uvs[i] = mesh.uvs[i];
		for (int i = 0; i < MAX_TANGENT_SET_COUNT; i++)
			this->tangents[i] = mesh.tangents[i];
		for (int i = 0; i < MAX_BINORMAL_SET_COUNT; i++)
			this->binormals[i] = mesh.binormals[i];

		this->indices = mesh.indices;
	}

	Mesh& operator = (const Mesh& mesh)
	{
		this->positions = mesh.positions;
		for (int i = 0; i < MAX_COLOR_SET_COUNT; i++)
			this->colors[i] = mesh.colors[i];
		for (int i = 0; i < MAX_NORMAL_SET_COUNT; i++)
			this->normals[i] = mesh.normals[i];
		for (int i = 0; i < MAX_UV_SET_COUNT; i++)
			this->uvs[i] = mesh.uvs[i];
		for (int i = 0; i < MAX_TANGENT_SET_COUNT; i++)
			this->tangents[i] = mesh.tangents[i];
		for (int i = 0; i < MAX_BINORMAL_SET_COUNT; i++)
			this->binormals[i] = mesh.binormals[i];

		this->indices = mesh.indices;

		return *this;
	}

	bool IsClosed(std::vector<Edge>& openEdges, bool collectOpenEdges = true) const
	{
		std::map<Edge, int> openEdgeCounter;

		for (int i = 0; i < indices.size(); i += 3)
		{
			for (int j = 0; j < 3; j++)
			{
				int idx0 = indices[(i + j + 0) % 3].vIdx;
				int idx1 = indices[(i + j + 1) % 3].vIdx;

				if (idx0 > idx1)
					openEdgeCounter[Edge(idx0, idx1)] += 1;
				else
					openEdgeCounter[Edge(idx1, idx0)] -= 1;
			}
		}

		for (auto& openEdgeCounterItr : openEdgeCounter)
		{
			if (openEdgeCounterItr.second != 0)
			{
				if (!collectOpenEdges)
					return false;
				openEdges.push_back(openEdgeCounterItr.first);
			}
		}

		return openEdges.size() == 0;
	}

	bool IsClosed() const
	{
		std::vector<Edge> openEdges;

		return IsClosed(openEdges, true);
	}

	void Clear()
	{
		this->positions.clear();
		for (int i = 0; i < MAX_COLOR_SET_COUNT; i++)
			this->colors[i].clear();
		for (int i = 0; i < MAX_NORMAL_SET_COUNT; i++)
			this->normals[i].clear();
		for (int i = 0; i < MAX_UV_SET_COUNT; i++)
			this->uvs[i].clear();
		for (int i = 0; i < MAX_TANGENT_SET_COUNT; i++)
			this->tangents[i].clear();
		for (int i = 0; i < MAX_BINORMAL_SET_COUNT; i++)
			this->binormals[i].clear();

		this->indices.clear();
	}
};

#endif