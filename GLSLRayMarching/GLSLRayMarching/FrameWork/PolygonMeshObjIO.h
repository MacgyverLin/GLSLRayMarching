#ifndef _PolyMeshObjIO_h_
#define _PolyMeshObjIO_h_

#include "MeshIO.h"
#include "PolygonMesh.h"

class PolygonMeshObjIO : public MeshIO<PolygonMesh>
{
public:
	PolygonMeshObjIO()
	{
	}

	~PolygonMeshObjIO()
	{
	}

	bool OnLoad(PolygonMesh& polygonMesh, const std::string& path) override
	{
		return true;
	}

	bool OnSave(const PolygonMesh& polygonMesh, const std::string& path) override
	{
		FILE* fptr = fopen(path.c_str(), "wt");
		if (!fptr)
			return false;

		fprintf(fptr, "# Blender v3.4.1 OBJ File: 'untitled.blend'\n");
		fprintf(fptr, "# www.blender.org\n");
		fprintf(fptr, "o %s\n", "test");

		for (auto& v : polygonMesh.vertices)
			fprintf(fptr, "v %f %f %f\n", v.p[0], v.p[1], v.p[2]);

		for (auto& v : polygonMesh.vertices)
			fprintf(fptr, "vt %f %f\n", v.uv[0], v.uv[1]);

		for (auto& v : polygonMesh.vertices)
			fprintf(fptr, "vn %f %f %f\n", v.n[0], v.n[1], v.n[2]);

		fprintf(fptr, "usemtl None\n");
		fprintf(fptr, "s off\n");

		bool hasuvIdx = true;
		bool hasnIdx = true;
		for (int i = 0; i < polygonMesh.polygons.size(); i++)
		{
			const Polygon& polygon = polygonMesh.polygons[i];
			for (int j = 0; j < polygon.indices.size(); j++)
			{
				int idx = polygonMesh.polygons[i].indices[j] + 1;

				fprintf(fptr, "f");
				
				fprintf(fptr, " %d", idx);
				if (hasuvIdx) fprintf(fptr, "//%d", idx);
				if (hasnIdx) fprintf(fptr, "//%d", idx);
			}

			fprintf(fptr, "\n");
		}


		fclose(fptr);
		return true;
	}

	/*
	bool OnLoad(Mesh& mesh, const std::string& path) override
	{
		return true;
	}

	bool OnSave(const Mesh& mesh, const std::string& path) override
	{
		FILE* fptr = fopen(path.c_str(), "wt");
		if (!fptr)
			return false;

		
		fprintf(fptr, "# Part 1 - node list\n");
		fprintf(fptr, "# node count, 3 dim, no attribute, no boundary marker\n");
		fprintf(fptr, "%d %d %d %d\n", (int)mesh.positions.size(), 3, 0, 0);
		fprintf(fptr, "# Node index, node coordinates\n");
		for (int i = 0; i < mesh.positions.size(); i++)
		{
			const Vector3& v = mesh.positions[i];
			fprintf(fptr, "%d %3.4f %3.4f %3.4f\n", i, v.X(), v.Y(), v.Z());
		}
		fprintf(fptr, "\n");

		fprintf(fptr, "# Part 2 - facet list\n");
		fprintf(fptr, "# facet count, no boundary marker\n");
		fprintf(fptr, "%d %d\n", (int)mesh.vertexIndices.size() / 3, 0);
		fprintf(fptr, "# facets\n");
		for (int i = 0; i < mesh.vertexIndices.size(); i+=3)
		{
			Mesh::VertexIndex vertexIndex0 = mesh.vertexIndices[i + 0];
			Mesh::VertexIndex vertexIndex1 = mesh.vertexIndices[i + 1];
			Mesh::VertexIndex vertexIndex2 = mesh.vertexIndices[i + 2];
			fprintf(fptr, "%d\n", 1);
			fprintf(fptr, "%d %d %d %d\n", 3, vertexIndex0.vIdx, vertexIndex1.vIdx, vertexIndex2.vIdx);
		}

		fprintf(fptr, "# Part 3 - hole list\n");
		fprintf(fptr, "%d\n", 0);

		fprintf(fptr, "# Part 3 - region list\n");
		fprintf(fptr, "%d\n", 0);

		fclose(fptr);
		return true;
	}
	*/
private:
};

#endif