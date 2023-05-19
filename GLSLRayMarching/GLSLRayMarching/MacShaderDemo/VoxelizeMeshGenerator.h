#ifndef _VoxelizeMeshGenerator_h_
#define _VoxelizeMeshGenerator_h_

#include "Platform.h"
#include "MeshProcessor.h"
#include "VertexMerger.h"

class VoxelizeMeshGenerator : public MeshProcessor
{
public:
	VoxelizeMeshGenerator()
		: MeshProcessor()
	{
	}

	~VoxelizeMeshGenerator()
	{
	}

protected:
	virtual void OnBuildMesh(Mesh& resultMesh, const std::vector<Voxel>& voxels) override
	{
		BuildVoxelMesh(resultMesh);
	}

	void BuildVoxelMesh(Mesh& resultMesh)
	{
		resultMesh.Clear();

		VertexMerger indexMerger(resultMesh.positions);
		for (int z = 0; z <= GetResolution(); z++)
		{
			for (int y = 0; y <= GetResolution(); y++)
			{
				for (int x = 0; x <= GetResolution(); x++)
				{
					std::vector<Vector3> edgeVertices;
					GetTrianglesVertices(edgeVertices, x, y, z);

					for_each
					(
						edgeVertices.begin(), edgeVertices.end(),
						[&](const Vector3& v)
						{
							Mesh::Index vertexIdx;
							vertexIdx.vIdx = indexMerger.Insert(v);

							resultMesh.indices.push_back(vertexIdx);
						}
					);
				}
			}
		}
	}

	void GetTrianglesIndices(std::vector<int>& triangleIndices, int x, int y, int z)
	{
		std::vector<std::vector<int>> indices =
		{
			{ 2, 3, 6, 6, 3, 7 },
			{ 0, 4, 1, 1, 4, 5 },
			{ 0, 1, 2, 2, 1, 3 },
			{ 4, 6, 5, 5, 6, 7 },
			{ 1, 5, 3, 3, 5, 7 },
			{ 0, 2, 4, 4, 2, 6 }
		};

		bool C = GetVoxelOccupied(x, y, z);

		bool U = (y != GetResolution()) && GetVoxelOccupied(x + 0, y + 1, z + 0);
		bool D = (y != 0) && GetVoxelOccupied(x + 0, y - 1, z + 0);
		bool R = (x != GetResolution()) && GetVoxelOccupied(x + 1, y + 0, z + 0);
		bool L = (x != 0) && GetVoxelOccupied(x - 1, y + 0, z + 0);
		bool F = (z != GetResolution()) && GetVoxelOccupied(x + 0, y + 0, z + 1);
		bool B = (z != 0) && GetVoxelOccupied(x + 0, y + 0, z - 1);

		int faceDirection;
		if (C && !U)
		{
			// up face
			faceDirection = 0;

			triangleIndices.push_back(indices[faceDirection][0]);
			triangleIndices.push_back(indices[faceDirection][1]);
			triangleIndices.push_back(indices[faceDirection][2]);

			triangleIndices.push_back(indices[faceDirection][3]);
			triangleIndices.push_back(indices[faceDirection][4]);
			triangleIndices.push_back(indices[faceDirection][5]);
		}

		if (C && !D)
		{
			// down face
			faceDirection = 1;

			triangleIndices.push_back(indices[faceDirection][0]);
			triangleIndices.push_back(indices[faceDirection][1]);
			triangleIndices.push_back(indices[faceDirection][2]);

			triangleIndices.push_back(indices[faceDirection][3]);
			triangleIndices.push_back(indices[faceDirection][4]);
			triangleIndices.push_back(indices[faceDirection][5]);
		}

		if (C && !L)
		{
			// left face
			faceDirection = 2;

			triangleIndices.push_back(indices[faceDirection][0]);
			triangleIndices.push_back(indices[faceDirection][1]);
			triangleIndices.push_back(indices[faceDirection][2]);

			triangleIndices.push_back(indices[faceDirection][3]);
			triangleIndices.push_back(indices[faceDirection][4]);
			triangleIndices.push_back(indices[faceDirection][5]);
		}

		if (C && !R)
		{
			// right face
			faceDirection = 3;

			triangleIndices.push_back(indices[faceDirection][0]);
			triangleIndices.push_back(indices[faceDirection][1]);
			triangleIndices.push_back(indices[faceDirection][2]);

			triangleIndices.push_back(indices[faceDirection][3]);
			triangleIndices.push_back(indices[faceDirection][4]);
			triangleIndices.push_back(indices[faceDirection][5]);
		}

		if (C && !F)
		{
			// front face
			faceDirection = 4;

			triangleIndices.push_back(indices[faceDirection][0]);
			triangleIndices.push_back(indices[faceDirection][1]);
			triangleIndices.push_back(indices[faceDirection][2]);

			triangleIndices.push_back(indices[faceDirection][3]);
			triangleIndices.push_back(indices[faceDirection][4]);
			triangleIndices.push_back(indices[faceDirection][5]);
		}

		if (C && !B)
		{
			// back face
			faceDirection = 5;

			triangleIndices.push_back(indices[faceDirection][0]);
			triangleIndices.push_back(indices[faceDirection][1]);
			triangleIndices.push_back(indices[faceDirection][2]);

			triangleIndices.push_back(indices[faceDirection][3]);
			triangleIndices.push_back(indices[faceDirection][4]);
			triangleIndices.push_back(indices[faceDirection][5]);
		}
	}

	void GetTrianglesVertices(std::vector<Vector3>& edgeVertices, int x, int y, int z)
	{
		static std::vector<Vector3> vertices =
		{
			Vector3(0, 0, 0), // 0
			Vector3(0, 0, 1), // 1
			Vector3(0, 1, 0), // 2
			Vector3(0, 1, 1), // 3

			Vector3(1, 0, 0), // 4
			Vector3(1, 0, 1), // 5
			Vector3(1, 1, 0), // 6
			Vector3(1, 1, 1)  // 7
		};

		Vector3 scale = GetVoxelSize();
		Vector3 offset((float)x, (float)y, (float)z);
		
		std::vector<int> triangleIndices;
		GetTrianglesIndices(triangleIndices, x, y, z);

		for(auto& i : triangleIndices)
			edgeVertices.push_back((vertices[i] + offset) * scale);
	}
};


#endif