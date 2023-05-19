#ifndef _PolygonMeshGenerator_h_
#define _PolygonMeshGenerator_h_

#include "Plane3.h"

class PolygonMeshGenerator
{
public:
	float epsilon;

	PolygonMeshGenerator()
	{
		epsilon = Math::Epsilon;
	}

	~PolygonMeshGenerator()
	{
	}

	void Split(const PolygonMesh& inMesh, const Plane3& splitPlane, PolygonMesh& frontMesh, PolygonMesh& backMesh)
	{
		std::vector<int> frontClipPlanesIndices;
		std::vector<int> backClipPlaneIndices;
		
		for (int i = 0; i < inMesh.polygons.size(); i++)
		{
			const Polygon& polygon = inMesh.polygons[i];

			SplitPolygon(polygon, splitPlane, inMesh.vertices, 
						frontMesh.polygons, backMesh.polygons, 
					    frontMesh.polygons, backMesh.polygons, 
						frontClipPlanesIndices, backClipPlaneIndices);
		}

		
		Assert((frontClipPlanesIndices.size() % 2) == 0);

		Vertex centroid;
		for (int i = 0; i < frontClipPlanesIndices.size(); i++)
		{
			int idx0 = frontClipPlanesIndices[i];
			centroid = centroid + inMesh.vertices[idx0];
		}
		centroid = centroid / frontClipPlanesIndices.size();
		inMesh.vertices.push_back(centroid);

		for (int i = 0; i < frontClipPlanesIndices.size(); i += 2)
		{
			int centroidIdx = inMesh.vertices.size() - 1;

			Polygon frontPolygon;
			frontPolygon.indices.push_back(centroidIdx);
			frontPolygon.indices.push_back(frontClipPlanesIndices[i + 0]);
			frontPolygon.indices.push_back(frontClipPlanesIndices[i + 1]);
			
			frontMesh.polygons.push_back(frontPolygon);
		}
	}

	enum PolygonClassification
	{
		Coplanar = 0,
		Front = 1,
		Back = 2,
		Spanning = 3
	};

	void SplitPolygon
	(
		const Polygon& polygon, const Plane3& splitPlane, std::vector<Vertex>& vertices, 
		std::vector<Polygon>& coplanarFront,
		std::vector<Polygon>& coplanarBack,
		std::vector<Polygon>& front,
		std::vector<Polygon>& back,
		std::vector<int>& frontClipPlanesIndices,
		std::vector<int>& backClipPlanesIndices)
	{
		int polygonType = 0;
		std::vector<PolygonClassification> vertexTypes;
		for (int i = 0; i < polygon.indices.size(); i++)
		{
			float t = splitPlane.DistanceTo(vertices[polygon.indices[i]].p);

			int vertexType = (t < -epsilon) ? Back : (t > epsilon) ? Front : Coplanar;
			vertexTypes.push_back((PolygonClassification)vertexType);

			polygonType |= vertexType;
		}

		switch (polygonType)
		{
		case Coplanar:
		{
			Vector3 p0 = vertices[polygon.indices[0]].p;
			Vector3 p1 = vertices[polygon.indices[1]].p;
			Vector3 p2 = vertices[polygon.indices[2]].p;

			Vector3 polygonNormal = (p2 - p0).Cross(p1 - p0);
			(splitPlane.Normal().Dot(polygonNormal) > 0 ? coplanarFront : coplanarBack).push_back(polygon);
		}
		break;

		case Front:
		{
			front.push_back(polygon);
		}
		break;

		case Back:
		{
			back.push_back(polygon);
		}
		break;

		case Spanning:
		{
			front.push_back(Polygon());
			back.push_back(Polygon());
			for (int i = 0; i < polygon.indices.size(); i++)
			{
				int j = (i + 1) % polygon.indices.size();
				PolygonClassification ti = vertexTypes[i];
				PolygonClassification tj = vertexTypes[j];

				int indexI = polygon.indices[i];
				int indexJ = polygon.indices[j];
				if (ti == Front || ti == Coplanar)
				{
					front.back().indices.push_back(indexI);
				}
				if (ti == Back || ti == Coplanar)
				{
					back.back().indices.push_back(indexI);
				}

				if ((ti | tj) == Spanning)
				{
					Vertex vfront = GenerateClipVertex(vertices[indexI], vertices[indexJ], splitPlane, true);
					
					int idxfront = vertices.size();
					vertices.push_back(vfront);
					front.back().indices.push_back(idxfront);

					frontClipPlanesIndices.push_back(idxfront);


					Vertex vback = GenerateClipVertex(vertices[indexI], vertices[indexJ], splitPlane, false);

					int idxback = vertices.size();
					vertices.push_back(vback);
					back.back().indices.push_back(idxback);

					backClipPlanesIndices.push_back(idxback);
				}
			}
			break;
		}
		};
	}

	Vertex GenerateClipVertex(const Vertex& v0, const Vertex& v1, const Plane3& splitPlane, bool front)
	{
		float t = (splitPlane.Constant() - splitPlane.Normal().Dot(v0.p)) / splitPlane.Normal().Dot(v1.p - v0.p);

		Vertex clipVertex = v0 + (v1 - v0) * t;

		if (front)
		{
			clipVertex.n = -splitPlane.Normal();
		}
		else
		{
			clipVertex.n = splitPlane.Normal();
		}

		return clipVertex;
	}


#if 0
	enum class VertexClassification
	{
		Behind = 0,
		InFront = 1,
		OnPlane = 2
	};

	enum class PolygonClassification
	{
		Behind = 0,
		InFront = 1,
		OnPlaneFront = 2,
		OnPlaneBehind = 3,
		Across = 4
	};

	void Split2(const PolygonMesh& inMesh, const Plane3& splitPlane, PolygonMesh& frontMesh, PolygonMesh& behindMesh)
	{
		for (int i = 0; i < inMesh.polygons.size(); i++)
		{
			if (i == 487)
			{
				int a = 1;
			}

			const Polygon& polygon = inMesh.polygons[i];

			PolygonClassification c = ClassifyPolygon(inMesh.vertices, polygon, splitPlane);
			switch (c)
			{
			case PolygonClassification::OnPlaneBehind:
			case PolygonClassification::Behind:
				behindMesh.polygons.push_back(polygon);
				break;

			case PolygonClassification::OnPlaneFront:
			case PolygonClassification::InFront:
				frontMesh.polygons.push_back(polygon);
				break;

			case PolygonClassification::Across:
			{
				Polygon behindPolygon;
				Polygon frontPolygon;
				SplitPolygon(polygon, splitPlane, inMesh.vertices, frontPolygon, behindPolygon);

				behindMesh.polygons.push_back(behindPolygon);
				frontMesh.polygons.push_back(frontPolygon);
				break;
			}
			};
		}
	}

	void SplitPolygon(const Polygon& polygon, const Plane3& splitPlane, std::vector<Vertex>& vertices, Polygon& infrontPolygon, Polygon& behindPolygon)
	{
		for (int j = 0; j < polygon.GetNumVertices(); j++)
		{
			int numVerts = polygon.GetNumVertices();
			int idx0 = polygon.indices[(j + 0) % numVerts];
			int idx1 = polygon.indices[(j + 1) % numVerts];

			const Vertex& v0 = vertices[idx0];
			const Vertex& v1 = vertices[idx1];

			VertexClassification c0 = ClassifyVertex(v0, splitPlane);
			VertexClassification c1 = ClassifyVertex(v1, splitPlane);

			// front poly
			if (c0 == VertexClassification::InFront)
			{
				if (c1 == VertexClassification::InFront)
				{
					infrontPolygon.indices.push_back(idx0);					// treat as front -> front
				}
				else if (c1 == VertexClassification::Behind)
				{
					infrontPolygon.indices.push_back(idx0);					// treat as front -> behind

					infrontPolygon.indices.push_back(vertices.size());
					vertices.push_back(ClipVertex(v0, v1, splitPlane));
				}
				else// if (c1 == VertexClassification::OnPlane)
				{
					infrontPolygon.indices.push_back(idx0);					// treat as front -> front
				}
			}
			else if (c0 == VertexClassification::Behind)
			{
				if (c1 == VertexClassification::InFront)
				{
					infrontPolygon.indices.push_back(vertices.size());		// treat as behind -> front
					vertices.push_back(ClipVertex(v0, v1, splitPlane));
				}
				else if (c1 == VertexClassification::Behind)
				{
					// nothing												// treat as behind -> behind
				}
				else// if (c1 == VertexClassification::OnPlane)
				{
					// nothing												// treat as behind -> behind
				}
			}
			else// if (c0 == VertexClassification::OnPlane)
			{
				if (c1 == VertexClassification::InFront)
				{
					infrontPolygon.indices.push_back(idx0);					// treat as front -> front
				}
				else if (c1 == VertexClassification::Behind)
				{
					// nothing												// treat as behind -> behind
				}
				else// if (c1 == VertexClassification::OnPlane)
				{
					// nothing												// treat as behind -> behind
					Assert(false); // something must went wrong, imposible case for across
				}
			}
		}
	}

	PolygonClassification ClassifyPolygon(const std::vector<Vertex>& vertices, const Polygon& polygon, const Plane3& splitPlane)
	{
		//std::vector<VertexClassification> vertexClassifications;
		int front = 0;
		int behind = 0;
		int on = 0;

		int vertexCount = 0;
		for (int j = 0; j < polygon.GetNumVertices(); j++)
		{
			int idx0 = polygon.indices[j + 0];
			const Vertex& v0 = vertices[idx0];

			VertexClassification c = ClassifyVertex(v0, splitPlane);
			// vertexClassifications.push_back(c);
			switch (c)
			{
			case VertexClassification::InFront:
				front++;
				break;
			case VertexClassification::Behind:
				behind++;
				break;
			case VertexClassification::OnPlane:
				on++;
				front++;
				behind++;
				break;
			}
		}

		if (on == vertexCount)
		{
			int idx0 = polygon.indices[0];
			int idx1 = polygon.indices[1];
			int idx2 = polygon.indices[2];
			const Vertex& v0 = vertices[idx0];
			const Vertex& v1 = vertices[idx1];
			const Vertex& v2 = vertices[idx2];
			Vector3 pNormal = (v2.p - v0.p).Cross(v1.p - v0.p);

			float dot = splitPlane.Normal().Dot(pNormal);
			if (dot > 0)
				return PolygonClassification::OnPlaneFront;
			else
				return PolygonClassification::OnPlaneBehind;
		}
		else if (front == vertexCount)
			return PolygonClassification::InFront;
		else if (behind == vertexCount)
			return PolygonClassification::Behind;
		else
			return PolygonClassification::Across;
	}

	VertexClassification ClassifyVertex(const Vertex& v, const Plane3& splitPlane)
	{
		float dist = splitPlane.DistanceTo(v.p);
		if (dist < -epsilon)
			return VertexClassification::Behind;
		else if (dist > epsilon)
			return VertexClassification::InFront;
		else
			return VertexClassification::OnPlane;
	}
#endif
};

#endif