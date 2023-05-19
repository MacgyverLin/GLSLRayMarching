#ifndef _TriangleMesh_h_
#define _TriangleMesh_h_

#include "Primitive.h"
#include "Edge.h"

class TriangleMesh
{
public:
	std::vector<Primitive::Vertex> vertices;
	std::vector<int> indices;
public:
	TriangleMesh()
	{
	}

	~TriangleMesh()
	{
	}

	TriangleMesh(const TriangleMesh& mesh)
	{
		this->vertices = mesh.vertices;
		this->indices = mesh.indices;
	}

	TriangleMesh& operator = (const TriangleMesh& mesh)
	{
		this->vertices = mesh.vertices;
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
				int idx0 = indices[(i + j + 0) % 3];
				int idx1 = indices[(i + j + 1) % 3];

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
		this->vertices.clear();
		this->indices.clear();
	}
};

#endif