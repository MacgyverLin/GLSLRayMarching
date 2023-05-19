#ifndef _TetGenObjIO_h_
#define _TetGenObjIO_h_

#include "MeshIO.h"

class TetGenObjIO : public MeshIO<Mesh>
{
public:
	TetGenObjIO()
	{
	}

	~TetGenObjIO()
	{
	}

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
private:
};

#endif