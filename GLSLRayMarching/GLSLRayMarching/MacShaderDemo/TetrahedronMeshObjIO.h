#ifndef _TetrahedronMeshObjIO_h_
#define _TetrahedronMeshObjIO_h_

#include "MeshIO.h"
#include "TetrahedronMesh.h"

class TetrahedronMeshObjIO : public MeshIO<TetrahedronMesh>
{
	float scale;
public:
	TetrahedronMeshObjIO(float scale_ = 0.8f)
		: scale(scale_)
	{
	}

	~TetrahedronMeshObjIO()
	{
	}

	bool OnLoad(TetrahedronMesh& tetrahedronMesh, const std::string& path) override
	{
		return true;
	}

	bool OnSave(const TetrahedronMesh& tetrahedronMesh, const std::string& path) override
	{
		FILE* fptr = fopen(path.c_str(), "wt");
		if (!fptr)
			return false;

		fprintf(fptr, "# Blender v3.4.1 OBJ File: 'untitled.blend'\n");
		fprintf(fptr, "# www.blender.org\n");
		fprintf(fptr, "o %s\n", "test");

		const std::vector<Vector3>& positions = tetrahedronMesh.positions;
		const std::vector<int>& indices = tetrahedronMesh.indices;

		for (int i = 0; i < indices.size(); i += 4)
		{
			Vector3 center = Vector3::Zero;

			int id0 = indices[i + 0];
			int id1 = indices[i + 1];
			int id2 = indices[i + 2];
			int id3 = indices[i + 3];
			center += positions[id0] * 0.25f;
			center += positions[id1] * 0.25f;
			center += positions[id2] * 0.25f;
			center += positions[id3] * 0.25f;

			for (int j = 0; j < 4; j++) // 4 faces per tetrahedron
			{
				for (int k = 0; k < 3; k++) // 3 vertices per face
				{
					int id = indices[i + TetrahedronMesh::tetFaces[j][k]];

					Vector3 p = positions[id];
					p = center + (p - center) * 0.8f;

					fprintf(fptr, "v %f %f %f\n", p[0], p[1], p[2]);
				}
			}
		}

		fprintf(fptr, "usemtl None\n");
		fprintf(fptr, "s off\n");

		int idx = 1;
		for (int i = 0; i < tetrahedronMesh.indices.size(); i += 4)
		{
			for (int j = 0; j < 4; j++) // 4 faces per tetrahedron
			{
				fprintf(fptr, "f");
				for (int k = 0; k < 3; k++) // 3 vertices per face
				{
					fprintf(fptr, " %d", idx++);
				}

				fprintf(fptr, "\n");
			}
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