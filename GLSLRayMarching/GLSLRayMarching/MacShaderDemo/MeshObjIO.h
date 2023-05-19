#ifndef _MeshObjIO_h_
#define _MeshObjIO_h_

#include "MeshIO.h"

class MeshObjIO : public MeshIO<Mesh>
{
private:
public:
	MeshObjIO()
		: MeshIO<Mesh>()
	{
	}

	~MeshObjIO()
	{
	}

	bool OnLoad(Mesh& mesh, const std::string& path) override
	{
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
		return true;
	}

	bool OnSave(const Mesh& mesh, const std::string& path) override
	{
		FILE* fptr = fopen(path.c_str(), "wt");
		if (!fptr)
			return false;

		fprintf(fptr, "# Blender v3.4.1 OBJ File: 'untitled.blend'\n");
		fprintf(fptr, "# www.blender.org\n");
		fprintf(fptr, "o %s\n", "test");

		for (auto& v : mesh.positions)
			fprintf(fptr, "v %f %f %f\n", v[0], v[1], v[2]);

		for (auto& uv : mesh.uvs[0])
			fprintf(fptr, "vt %f %f\n", uv[0], uv[1]);

		for (auto& n : mesh.normals[0])
			fprintf(fptr, "vn %f %f %f\n", n[0], n[1], n[2]);

		fprintf(fptr, "usemtl None\n");
		fprintf(fptr, "s off\n");

		bool hasuvIdx = !mesh.uvs[0].empty();
		bool hasnIdx = !mesh.normals[0].empty();
		for (int i = 0; i < mesh.indices.size(); i += 3)
		{
			Mesh::Index vertexIndex0 = mesh.indices[i + 0];
			Mesh::Index vertexIndex1 = mesh.indices[i + 1];
			Mesh::Index vertexIndex2 = mesh.indices[i + 2];

			int vidx0 = vertexIndex0.vIdx + 1;
			int vidx1 = vertexIndex1.vIdx + 1;
			int vidx2 = vertexIndex2.vIdx + 1;

			//Assert(vidx0 - 1 < mesh.positions.size());
			//Assert(vidx1 - 1 < mesh.positions.size());
			//Assert(vidx2 - 1 < mesh.positions.size());

			int uvIdx0 = vertexIndex0.uvIdx[0] + 1;
			int uvIdx1 = vertexIndex1.uvIdx[0] + 1;
			int uvIdx2 = vertexIndex2.uvIdx[0] + 1;

			int nIdx0 = vertexIndex0.nIdx[0] + 1;
			int nIdx1 = vertexIndex1.nIdx[0] + 1;
			int nIdx2 = vertexIndex2.nIdx[0] + 1;

			fprintf(fptr, "f");
			fprintf(fptr, " %d", vidx0);
			if (hasuvIdx) fprintf(fptr, "//%d", uvIdx0);
			if (hasnIdx) fprintf(fptr, "//%d", nIdx0);

			fprintf(fptr, " %d", vidx1);
			if (hasuvIdx) fprintf(fptr, "//%d", uvIdx1);
			if (hasnIdx) fprintf(fptr, "//%d", nIdx1);

			fprintf(fptr, " %d", vidx2);
			if (hasuvIdx) fprintf(fptr, "//%d", uvIdx2);
			if (hasnIdx) fprintf(fptr, "//%d", nIdx2);

			fprintf(fptr, "\n");
		}


		fclose(fptr);
		return true;
	}
private:
};

#endif