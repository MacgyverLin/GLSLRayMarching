#ifndef _BVHTree_h_
#define _BVHTree_h_

#include "Triangle.h"
#include "AABB.h"
#include "HitRecord.h"
#include "Intersect.h"
#include "Mesh.h"

class BVHTree
{
public:
	int id;
	Triangle triangle;
	BVHTree* leftChild;
	BVHTree* rightChild;
	AABB aabb;
public:
	BVHTree(int id, const std::vector<Triangle>& triangles)
	{
		if (triangles.size() == 1) // leaf
		{
			this->id = id;
			this->triangle = triangles[0];
			this->leftChild = nullptr;
			this->rightChild = nullptr;
			this->aabb = this->triangle.aabb;
		}
		else
		{
			bool randomSplit = false;

			int bestSplitCost = Math::MaxInteger;
			int bestSplitAxis = -1;
			std::vector<int> bestLIndices;
			std::vector<int> bestRIndices;
			if (randomSplit)
			{
				int axis = (int)(Math::UnitRandom() * 3.0f);
				std::tuple< std::vector<int>, std::vector<int>, int> splitInfo = FindSplitCost(axis, triangles);
			}
			else
			{
				for (int axis = 0; axis < 3; axis++)
				{
					std::tuple< std::vector<int>, std::vector<int>, int> splitInfo = FindSplitCost(axis, triangles);
					int splitCost = std::get<2>(splitInfo);
					if (splitCost < bestSplitCost)
					{
						bestSplitCost = splitCost;
						bestSplitAxis = axis;
						bestLIndices = std::get<0>(splitInfo);
						bestRIndices = std::get<1>(splitInfo);
					}
				}
			}

			std::vector<Triangle> lTriangles;
			std::vector<Triangle> rTriangles;
			for (auto& i : bestLIndices)
				lTriangles.push_back(triangles[i]);
			for (auto& i : bestRIndices)
				rTriangles.push_back(triangles[i]);

			if (bestLIndices.size() == 0 || bestRIndices.size() == 0)
			{
			}

			this->id = id;
			this->triangle = Triangle();
			this->leftChild = new BVHTree(id * 2 + 1, lTriangles);
			this->rightChild = new BVHTree(id * 2 + 2, rTriangles);
			this->aabb = this->leftChild->aabb + this->rightChild->aabb;
		}
	}

	std::tuple< std::vector<int>, std::vector<int>, int> FindSplitCost(int axis, const std::vector<Triangle>& triangles)
	{
		std::vector<int> lIndices;
		std::vector<int> rIndices;

		float mean = 0;
		for (int i = 0; i < triangles.size(); i++)
		{
			mean += triangles[i].centroid[axis];
		}
		mean /= triangles.size();

		for (int i = 0; i < triangles.size(); i++)
		{
			if (triangles[i].centroid[axis] < mean)
				lIndices.push_back(i);
			else
				rIndices.push_back(i);
		}

		return std::tuple< std::vector<int>, std::vector<int>, int>(lIndices, rIndices, (int)abs((int)rIndices.size() - (int)lIndices.size()));
	}

	~BVHTree()
	{
		this->id = -1;

		if (this->leftChild)
		{
			delete this->leftChild;
			this->leftChild = nullptr;
		}

		if (this->rightChild)
		{
			delete this->rightChild;
			this->rightChild = nullptr;
		}
	}

	HitRecord RayCast(const Ray3& ray) const
	{
		HitRecord hitRecord = Intersect::RayCast(aabb, ray);
		if (!hitRecord.hit)
			return HitRecord();

		if (this->leftChild != nullptr && this->rightChild != nullptr)
		{
			HitRecord leftHitRecord = this->leftChild->RayCast(ray);
			HitRecord rightHitRecord = this->rightChild->RayCast(ray);

			if (leftHitRecord.hit) // left hit
			{
				if (rightHitRecord.hit) // both hit
				{
					if (leftHitRecord.t < rightHitRecord.t)
						return leftHitRecord;
					else
						return rightHitRecord;
				}
				else // only left hit
				{
					return leftHitRecord;
				}
			}
			else
			{
				if (rightHitRecord.hit) // only right hit
					return rightHitRecord;
				else
					return HitRecord(); // no hit
			}
		}
		else// # if(not(self.triangles == None)
		{
			HitRecord triangleHitRecord = Intersect::RayCast(triangle, ray);
			if (triangleHitRecord.hit)
				return triangleHitRecord;
			else
				return HitRecord();
		}
	}

	bool RayCast(std::vector<HitRecord>& hitRecords, const Ray3& ray) const
	{
		HitRecord hitRecord = Intersect::RayCast(aabb, ray);
		if (!hitRecord.hit)
			return false;

		Assert( !((leftChild != nullptr && rightChild == nullptr) || (leftChild == nullptr && rightChild != nullptr)) );
		
		if (leftChild && rightChild)
		{
			bool result = false;
			result |= leftChild->RayCast(hitRecords, ray);
			result |= rightChild->RayCast(hitRecords, ray);
			
			return result;
		}
		else// # if(not(self.triangles == None)
		{
			HitRecord triangleHitRecord = Intersect::RayCast(triangle, ray);
			if (triangleHitRecord.hit)
			{
				hitRecords.push_back(triangleHitRecord);
				return true;
			}
			else
				return false;
		}
	}

	bool IsInside(const Vector3& p, float minDist = 0.0) const
	{
		static std::vector<Vector3> dirs =
		{
			Vector3( 1.0f,  0.0f,  0.0f),
			Vector3(-1.0f,  0.0f,  0.0f),
			Vector3( 0.0f,  1.0f,  0.0f),
			Vector3( 0.0f, -1.0f,  0.0f),
			Vector3( 0.0f,  0.0f,  1.0f),
			Vector3( 0.0f,  0.0f, -1.0f)
		};

		int numIn = 0;
		for (int i = 0; i < 6; i++)
		{
			HitRecord hitRecord = RayCast(Ray3(p, dirs[i]));
			if (hitRecord.hit)
			{
				if ((hitRecord.normal.Dot(dirs[i]) > 0.0))
				{
					numIn = numIn + 1;
					if (numIn > 3)
						return true;
				}
				if (minDist > 0.0f && hitRecord.t < minDist)
					return false;
			}
		}

		return numIn > 3;
	}

	static BVHTree* FromMesh(const Mesh& mesh)
	{
		std::vector<Triangle> triangles;

		for (int i = 0; i < mesh.indices.size(); i += 3)
		{
			int vIdx0 = mesh.indices[i + 0].vIdx;
			int vIdx1 = mesh.indices[i + 1].vIdx;
			int vIdx2 = mesh.indices[i + 2].vIdx;

			triangles.push_back(Triangle(mesh.positions[vIdx0], mesh.positions[vIdx1], mesh.positions[vIdx2]));
		}

		return new BVHTree(0, triangles);
	}
};

#endif