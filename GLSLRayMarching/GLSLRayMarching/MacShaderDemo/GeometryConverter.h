#ifndef _GeometryConverter_h_
#define _GeometryConverter_h_

#include "AABB.h"
#include "Vector3.h"
#include "Vertex.h"

#include "Mesh.h"
#include "PolygonMesh.h"
#include "TriangleMesh.h"
#include "VertexMerger.h"

class GeometryConverter
{
public:
	static void Convert(PolygonMesh& polygonMesh, const Mesh& mesh)
	{
		VertexMerger<Vertex> vertexMerger(polygonMesh.vertices);

		for (int i = 0; i < mesh.indices.size(); i += 3)
		{
			Polygon polygon;

			for (int j = 0; j < 3; j += 1)
			{
				Vertex v = GetVertex(mesh, mesh.indices[i + j]);

				int idx = vertexMerger.Insert(v);
				polygon.indices.push_back(idx);
			}

			polygonMesh.polygons.push_back(polygon);
		}
	}

	static void Convert(TriangleMesh& triangleMesh, const Mesh& mesh)
	{
		VertexMerger<Primitive::Vertex> vertexMerger(triangleMesh.vertices);

		for (int i = 0; i < mesh.indices.size(); i += 3)
		{
			for (int j = 0; j < 3; j += 1)
			{
				const Mesh::Index& index = mesh.indices[i + j];


				// prepare Vertex
				Primitive::Vertex v;
				v.p = mesh.positions[index.vIdx];
				if (mesh.colors[0].size() != 0)
					v.c = mesh.colors[0][index.cIdx[0]];
				if (mesh.uvs[0].size() != 0)
					v.uv = mesh.uvs[0][index.uvIdx[0]];

				int idx = vertexMerger.Insert(v);


				triangleMesh.indices.push_back(idx);
			}
		}
	}

	static void Convert(AABB& aabb, const Vector3& v0, const Vector3& v1, const Vector3& v2)
	{
		aabb = AABB(Vector3::Min(Vector3::Min(v0, v1), v2), Vector3::Max(Vector3::Max(v0, v1), v2));
	}

	static void Convert(AABB& aabb, const Vector3& v0, const Vector3& v1, const Vector3& v2, const Vector3& v3)
	{
		aabb = AABB(Vector3::Min(Vector3::Min(Vector3::Min(v0, v1), v2), v3), Vector3::Max(Vector3::Max(Vector3::Max(v0, v1), v2), v3));
	}

	static void Convert(AABB& aabb, const std::vector<Vector3>& p)
	{
		aabb.min = Vector3(Math::MaxValue, Math::MaxValue, Math::MaxValue);
		aabb.max = -aabb.min;
		for (int i = 0; i < p.size(); i++)
		{
			aabb.min = Vector3::Min(aabb.min, p[i]);
			aabb.max = Vector3::Max(aabb.max, p[i]);
		}
	}

	static const Vertex GetVertex(const Mesh& mesh, const Mesh::Index& index)
	{
		// prepare Vertex
		Vertex v;

		v.p = mesh.positions[index.vIdx];
		if (mesh.colors[0].size() != 0)
			v.c = mesh.colors[0][index.cIdx[0]];
		if (mesh.normals[0].size() != 0)
			v.n = mesh.normals[0][index.nIdx[0]];
		if (mesh.uvs[0].size() != 0)
			v.uv = mesh.uvs[0][index.uvIdx[0]];
		if (mesh.tangents[0].size() != 0)
			v.t = mesh.tangents[0][index.tIdx[0]];
		if (mesh.binormals[0].size() != 0)
			v.b = mesh.binormals[0][index.bIdx[0]];

		return v;
	}
};

#endif