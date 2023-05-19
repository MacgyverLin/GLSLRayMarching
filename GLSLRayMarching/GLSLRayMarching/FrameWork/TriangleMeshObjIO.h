#ifndef _TriangleMeshObjIO_h_
#define _TriangleMeshObjIO_h_

#include "MeshIO.h"
#include "TriangleMesh.h"

class TriangleMeshObjIO : public MeshIO<TriangleMesh>
{
private:
public:
	TriangleMeshObjIO()
		: MeshIO<TriangleMesh>()
	{
	}

	~TriangleMeshObjIO()
	{
	}

	bool OnLoad(TriangleMesh& mesh, const std::string& path) override
	{
		/*
		FILE* fptr = fopen(path.c_str(), "rt");
		if (!fptr)
			return false;

		mesh.Clear();

		bool hasVertex = false;
		bool hasUV = false;
		bool hasNormal = false;

		while (!feof(fptr))
		{
			char buffer[4096];
			memset(buffer, 0, 4096);
			fgets(buffer, 4096, fptr);
			std::string line = buffer;


			if (_strnicmp(line.c_str(), "v ", 2) == 0)
			{
				hasVertex = true;

				size_t index1 = line.find(" ", 2);
				size_t index2 = line.find(" ", index1 + 1);

				std::string xStr = line.substr(2, index1 - 2);
				std::string yStr = line.substr(index1, index2 - index1);
				std::string zStr = line.substr(index2);

				float x = (float)atof(xStr.c_str());
				float y = (float)atof(yStr.c_str());
				float z = (float)atof(zStr.c_str());

				mesh.positions.push_back(Vector3(x, y, z));
			}
			else if (_strnicmp(line.c_str(), "vn ", 3) == 0)
			{
				hasNormal = true;

				size_t index1 = line.find(" ", 3);
				size_t index2 = line.find(" ", index1 + 1);

				std::string xStr = line.substr(3, index1 - 3);
				std::string yStr = line.substr(index1, index2 - index1);
				std::string zStr = line.substr(index2);

				float x = (float)atof(xStr.c_str());
				float y = (float)atof(yStr.c_str());
				float z = (float)atof(zStr.c_str());

				mesh.normals[0].push_back(Vector3(x, y, z));
			}
			else if (_strnicmp(line.c_str(), "vt ", 3) == 0)
			{
				hasUV = true;

				size_t index1 = line.find(" ", 3);

				std::string xStr = line.substr(3, index1 - 3);
				std::string yStr = line.substr(index1);

				float x = (float)atof(xStr.c_str());
				float y = (float)atof(yStr.c_str());
				 
				mesh.uvs[0].push_back(Vector2(x, y));
			}
			else if (_strnicmp(line.c_str(), "f ", 2) == 0)
			{
				std::vector<Mesh::Index> indices;

				size_t startIndex = 2;
				do
				{
					size_t endIndex = line.find(" ", startIndex);
					std::string indicesStr = line.substr(startIndex, endIndex - startIndex);

					{
						size_t index1 = indicesStr.find("/", 0);
						size_t index2 = indicesStr.find("/", index1 + 1);
						size_t index3 = indicesStr.find("/", index2 + 1);

						std::string vIdxStr = indicesStr.substr(0, index1 - 0);
						std::string tIdxStr = indicesStr.substr(index1 + 1, index2 - (index1+1));
						std::string nIdxStr = indicesStr.substr(index2 + 1);

						Mesh::Index vertexIndex;
						if(vIdxStr!="")
							vertexIndex.vIdx = atoi(vIdxStr.c_str()) - 1;
						if (tIdxStr != "")
							vertexIndex.uvIdx[0] = atoi(tIdxStr.c_str()) - 1;
						if (nIdxStr != "")
							vertexIndex.nIdx[0] = atoi(nIdxStr.c_str()) - 1;
						indices.push_back(vertexIndex);
					}

					startIndex = endIndex + 1;
				} while (startIndex > 0);

				for (int j = 0; j < indices.size() - 2; j++)
				{
					mesh.indices.push_back(indices[0]);
					mesh.indices.push_back(indices[j + 1]);
					mesh.indices.push_back(indices[j + 2]);
				}
			}
		}

		fclose(fptr);
		*/

		return true;
	}

	bool OnSave(const TriangleMesh& mesh, const std::string& path) override
	{
		FILE* fptr = fopen(path.c_str(), "wt");
		if (!fptr)
			return false;

		fprintf(fptr, "# Blender v3.4.1 OBJ File: 'untitled.blend'\n");
		fprintf(fptr, "# www.blender.org\n");
		fprintf(fptr, "o %s\n", "test");

		for (auto& v : mesh.vertices)
			fprintf(fptr, "v %f %f %f\n", v.p[0], v.p[1], v.p[2]);

		for (auto& v : mesh.vertices)
			fprintf(fptr, "vt %f %f\n", v.uv[0], v.uv[1]);

		for (auto& v : mesh.vertices)
			fprintf(fptr, "vn %f %f %f\n", v.c[0], v.c[1], v.c[2]);

		fprintf(fptr, "usemtl None\n");
		fprintf(fptr, "s off\n");

		bool hasuvIdx = true;
		bool hascIdx = true;
		for (int i = 0; i < mesh.indices.size(); i += 3)
		{
			int index0 = mesh.indices[i + 0];
			int index1 = mesh.indices[i + 1];
			int index2 = mesh.indices[i + 2];

			int vIdx0 = index0 + 1;
			int vIdx1 = index1 + 1;
			int vIdx2 = index2 + 1;

			int uvIdx0 = index0 + 1;
			int uvIdx1 = index1 + 1;
			int uvIdx2 = index2 + 1;

			int cIdx0 = index0 + 1;
			int cIdx1 = index1 + 1;
			int cIdx2 = index2 + 1;

			fprintf(fptr, "f");
			fprintf(fptr, " %d", vIdx0);
			if (hasuvIdx) fprintf(fptr, "//%d", uvIdx0);
			if (hascIdx) fprintf(fptr, "//%d", cIdx0);

			fprintf(fptr, " %d", vIdx1);
			if (hasuvIdx) fprintf(fptr, "//%d", uvIdx1);
			if (hascIdx) fprintf(fptr, "//%d", cIdx1);

			fprintf(fptr, " %d", vIdx2);
			if (hasuvIdx) fprintf(fptr, "//%d", uvIdx2);
			if (hascIdx) fprintf(fptr, "//%d", cIdx2);

			fprintf(fptr, "\n");
		}


		fclose(fptr);
		return true;
	}
private:
};

#endif