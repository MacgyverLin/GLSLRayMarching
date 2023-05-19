#ifndef _MeshGenerator_h_
#define _MeshGenerator_h_

#include "Platform.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix3.h"
#include "ColorRGBA.h"
#include "Ray3.h"
#include "BVHTree.h"
#include "Mesh.h"
#include "GeometryConverter.h"

class MeshProcessor
{
public:
	#define WORLD_COORD_TO_CELL_COORD(coord) \
		(coord.X() - aabb.Min().X() + 0.001f * voxelSize.X()) / voxelSize.X(), \
		(coord.Y() - aabb.Min().Y() + 0.001f * voxelSize.Y()) / voxelSize.Y(), \
		(coord.Z() - aabb.Min().Z() + 0.001f * voxelSize.Z()) / voxelSize.Z()

	class Voxel
	{
	public:
		int x;
		int y;
		int z;
		unsigned char code;
	};
private:
	AABB3 aabb;
	Vector3 voxelSize;
	int resolution;
	std::vector<bool> voxelOccupieds;

public:
	MeshProcessor()
	{
	}

	~MeshProcessor()
	{
	}

	const AABB3& GetAABB() const
	{
		return aabb;
	}

	const Vector3& GetVoxelSize() const
	{
		return voxelSize;
	}

	const int& GetResolution() const
	{
		return resolution;
	}

	unsigned int GetVoxelsCount() const
	{
		return (unsigned int)voxelOccupieds.size();
	}

	void SetVoxelOccupied(const Vector3& coord, bool occupied)
	{
		SetVoxelOccupied
		(
			WORLD_COORD_TO_CELL_COORD(coord),
			occupied
		);
	}

	void SetVoxelOccupied(int x, int y, int z, bool occupied)
	{
		voxelOccupieds[I(x, y, z)] = occupied;
	}

	bool GetVoxelOccupied(const Vector3& coord)
	{
		return GetVoxelOccupied
		(
			WORLD_COORD_TO_CELL_COORD(coord)
		);
	}

	bool GetVoxelOccupied(int x, int y, int z)
	{
		return voxelOccupieds[I(x, y, z)];
	}

	Voxel GetVoxel(const Vector3& coord)
	{
		return GetVoxel
		(
			WORLD_COORD_TO_CELL_COORD(coord)
		);
	}

	Voxel GetVoxel(int x, int y, int z)
	{
		Assert(x >= 0 && x < resolution);
		Assert(y >= 0 && y < resolution);
		Assert(z >= 0 && z < resolution);

		Voxel voxel;
		voxel.x = x;
		voxel.y = y;
		voxel.z = z;
		voxel.code = 0;

		if (GetVoxelOccupied(x + 0, y + 1, z + 1)) voxel.code |= 0x01;
		if (GetVoxelOccupied(x + 0, y + 1, z + 0)) voxel.code |= 0x02;
		if (GetVoxelOccupied(x + 0, y + 0, z + 0)) voxel.code |= 0x04;
		if (GetVoxelOccupied(x + 0, y + 0, z + 1)) voxel.code |= 0x08;
		if (GetVoxelOccupied(x + 1, y + 1, z + 1)) voxel.code |= 0x10;
		if (GetVoxelOccupied(x + 1, y + 1, z + 0)) voxel.code |= 0x20;
		if (GetVoxelOccupied(x + 1, y + 0, z + 0)) voxel.code |= 0x40;
		if (GetVoxelOccupied(x + 1, y + 0, z + 1)) voxel.code |= 0x80;

		return voxel;
	}

	void GetAllVoxels(std::vector<Voxel>& voxels_)
	{
		for (int z = 0; z < resolution; z++)
		{
			for (int y = 0; y < resolution; y++)
			{
				for (int x = 0; x < resolution; x++)
				{
					voxels_.push_back(GetVoxel(x, y, z));
				}
			}
		}
	}


	void Populate(const Mesh& mesh, int resolution_)
	{
		Reset(mesh.positions, resolution_);

		PopulateByMeshTriangles(mesh);
	}

	void Populate(const std::vector<Vector3>& positions, int resolution_)
	{
		Reset(positions, resolution_);

		for (int i = 0; i < positions.size(); i++)
		{
			SetVoxelOccupied(positions[i], true);
		}
	}
	
	void Generate(Mesh& resultMesh, const Mesh& mesh, int resolution_)
	{
		Populate(mesh, resolution_);

		std::vector<MeshProcessor::Voxel> voxels;
		GetAllVoxels(voxels);

		OnBuildMesh(resultMesh, voxels);
	}
protected:
	void Reset(const std::vector<Vector3>& positions, int resolution_)
	{
		////////////////////////
		// find Min Max of vertices
		GeometryConverter::Convert(aabb, positions);

		//////////////////////////////////////
		// adjust range to Maximum of 3 axis
		Vector3 range = (aabb.Max() - aabb.Min());
		float rangeMax = Math::Max(Math::Max(range.X(), range.Y()), range.Z());
		Vector3 aabbSize(rangeMax, rangeMax, rangeMax);
		aabb.Max() = aabb.Min() + aabbSize;

		voxelSize = (aabb.Max() - aabb.Min()) / Vector3((float)resolution_, (float)resolution_, (float)resolution_);
		resolution = resolution_;
		voxelOccupieds.resize((resolution + 1) * (resolution + 1) * (resolution + 1));
	}

	void PopulateByBVH(const Mesh& mesh)
	{
		BVHTree* tree = BVHTree::FromMesh(mesh);

		for (int z = 0; z<=resolution; z++)
		{
			for (int y = 0; y <= resolution; y++)
			{
				for (int x = 0; x <= resolution; x++)
				{
					Vector3 p = Vector3((float)x, (float)y, (float)z) * voxelSize + aabb.Min();
					if (tree->IsInside(p))
					{
						SetVoxelOccupied(p, true);
					}
				}
			}
		}
	}

	void PopulateByMeshTriangles(const Mesh& mesh)
	{
		std::vector<Triangle> triangles;
		for (int i = 0; i < mesh.indices.size(); i += 3)
		{
			int vIdx0 = mesh.indices[i + 0].vIdx;
			int vIdx1 = mesh.indices[i + 1].vIdx;
			int vIdx2 = mesh.indices[i + 2].vIdx;

			triangles.push_back(Triangle(mesh.positions[vIdx0], mesh.positions[vIdx1], mesh.positions[vIdx2]));
		}

		for (auto& triangle : triangles)
		{
			Vector3 count = (triangle.aabb.Max() - triangle.aabb.Min()) / voxelSize;

			for (int z = 0; z <= count.Z(); z++)
			{
				for (int y = 0; y <= count.Y(); y++)
				{
					for (int x = 0; x <= count.X(); x++)
					{
						Vector3 p = Vector3((float)x, (float)y, (float)z) * voxelSize + triangle.aabb.Min();
						AABB3 voxelAABB(p, p + voxelSize);
						
						if (Intersect::Test(voxelAABB, triangle))
						{
							SetVoxelOccupied(p, true);
						}
					}
				}
			}
		}
	}

	unsigned int I(int x, int y, int z)
	{
		Assert(x >= 0 && x < resolution + 1);
		Assert(y >= 0 && y < resolution + 1);
		Assert(z >= 0 && z < resolution + 1);

		return z * ((resolution + 1) * (resolution + 1)) + y * (resolution + 1) + x;
	}

protected:
	virtual void OnBuildMesh(Mesh& resultMesh, const std::vector<Voxel>& voxels) = 0;
};


#endif