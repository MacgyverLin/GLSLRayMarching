#ifndef _Triangle_h_
#define _Triangle_h_

#include "Vector3.h"
#include "AABB3.h"
#include "GeometryConverter.h"

class Triangle
{
public:
	Vector3 vertex[3];

	Vector3 centroid;
	AABB3 aabb;
public:
	Triangle()
	{
		this->vertex[0] = Vector3::Zero;
		this->vertex[1] = Vector3::Zero;
		this->vertex[2] = Vector3::Zero;

		this->centroid = Vector3::Zero;
		this->aabb = AABB3(Vector3::Zero, Vector3::Zero);
	}

	~Triangle()
	{
	}

	Triangle(const Vector3& vertex0, const Vector3& vertex1, const Vector3& vertex2)
	{
		this->vertex[0] = vertex0;
		this->vertex[1] = vertex1;
		this->vertex[2] = vertex2;

		this->centroid = (vertex0 + vertex1 + vertex2) * 0.33333f;
		GeometryConverter::Convert(aabb, vertex0, vertex1, vertex2);
	}

	Triangle(const Triangle& other)
	{
		this->vertex[0] = other.vertex[0];
		this->vertex[1] = other.vertex[1];
		this->vertex[2] = other.vertex[2];

		this->centroid = other.centroid;
		this->aabb = other.aabb;
	}

	Triangle& operator = (const Triangle& other)
	{
		this->vertex[0] = other.vertex[0];
		this->vertex[1] = other.vertex[1];
		this->vertex[2] = other.vertex[2];

		this->centroid = other.centroid;
		this->aabb = other.aabb;

		return *this;
	}

	Vector3 GetNormal() const
	{
		Vector3 normal = (vertex[1] - vertex[0]).Cross((vertex[2] - vertex[0]));
		normal.Normalize();

		return normal;
	}
};

#endif