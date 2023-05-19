#ifndef _PolygonMesh_h_
#define _PolygonMesh_h_

#include "Vertex.h"
#include "Polygon.h"

class PolygonMesh
{
	friend class ObjMesh;
	friend class PolygonMeshGenerator;
public:
	std::vector<Vertex>& vertices;
	std::vector<Polygon> polygons;
public:
	PolygonMesh(std::vector<Vertex>& vertices_)
		: vertices(vertices_)
	{
	}

	~PolygonMesh()
	{
	}

	PolygonMesh(const PolygonMesh& mesh)
		: vertices(mesh.vertices)
	{
		this->polygons = mesh.polygons;
	}

	PolygonMesh& operator = (const PolygonMesh& mesh)
	{
		this->vertices = mesh.vertices;
		this->polygons = mesh.polygons;

		return *this;
	}

	bool IsClosed(std::vector<Edge>& openEdges, bool collectOpenEdges = true) const
	{
		std::map<Edge, int> edges;

		for (int i = 0; i < polygons.size(); i++)
		{
			for (int j = 0; j <= polygons[i].GetNumVertices(); j++)
			{
				int idx0 = polygons[i].indices[(j + 0) % polygons[i].GetNumVertices()];
				int idx1 = polygons[i].indices[(j + 1) % polygons[i].GetNumVertices()];

				if (idx0 > idx1)
					edges[Edge(idx0, idx1)] += 1;
				else
					edges[Edge(idx1, idx0)] -= 1;
			}
		}

		for (auto& edgesItr : edges)
		{
			if (edgesItr.second != 0)
			{
				if (!collectOpenEdges)
					return false;
				openEdges.push_back(edgesItr.first);
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
		this->polygons.clear();
	}
};

#endif