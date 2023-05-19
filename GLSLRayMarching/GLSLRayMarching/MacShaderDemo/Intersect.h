#ifndef _Intersection_h_
#define _Intersection_h_

#include "Sphere3.h"
#include "Vector3.h"
#include "AABB3.h"
#include "Triangle.h"
#include "HitRecord.h"
#include "Ray3.h"

class Intersect
{
public:
	static bool Test(const Sphere3& sphere0, const Sphere3& sphere1)
	{
		float distance = (sphere0.center - sphere1.center).Length();

		return distance <= (sphere0.radius + sphere1.radius);
	}

	static bool Test(const Sphere3& sphere, const AABB3& aabb)
	{
		auto check = [&](
			const float pn,
			const float bmin,
			const float bmax) -> float
		{
			float out = 0;
			float v = pn;

			if (v < bmin)
			{
				float val = (bmin - v);
				out += val * val;
			}

			if (v > bmax)
			{
				float val = (v - bmax);
				out += val * val;
			}

			return out;
		};

		// Squared distance
		float sq = 0.0f;

		sq += check(sphere.center[0], aabb.Min()[0], aabb.Max()[0]);
		sq += check(sphere.center[1], aabb.Min()[1], aabb.Max()[1]);
		sq += check(sphere.center[2], aabb.Min()[2], aabb.Max()[2]);

		double squaredDistance = sq;

		return squaredDistance <= (sphere.radius * sphere.radius);
	}

	static bool Test(const Vector3& p, const AABB3& aabb)
	{
		return  aabb.Min().X() <= p.X() && p.X() < aabb.Max().X() &&
				aabb.Min().Y() <= p.Y() && p.Y() < aabb.Max().Y() &&
				aabb.Min().Z() <= p.Z() && p.Z() < aabb.Max().Z();
	}

	static bool Test(const AABB3& aabb0, const AABB3& aabb1)
	{
		Vector3 halfExtent0 = aabb0.Max() - aabb0.Min();
		Vector3 halfExtent1 = aabb1.Max() - aabb1.Min();

		if (Math::FAbs(aabb0.Min()[0] - aabb1.Min()[0]) > (halfExtent0[0] + halfExtent1[0])) return false;
		if (Math::FAbs(aabb0.Min()[1] - aabb1.Min()[1]) > (halfExtent0[1] + halfExtent1[1])) return false;
		if (Math::FAbs(aabb0.Min()[2] - aabb1.Min()[2]) > (halfExtent0[2] + halfExtent1[2])) return false;

		// We have an overlap
		return true;
	}

	static bool Test(const AABB3& aabb, const Triangle& triangle)
	{
		if (!Test(aabb, triangle.aabb))
			return false;

		float triangleMin, triangleMax;
		float boxMin, boxMax;

		// Test the box normals (x-, y- and z-axes)
		const Vector3 boxNormals[3] =
		{
			Vector3(1, 0, 0),
			Vector3(0, 1, 0),
			Vector3(0, 0, 1)
		};

		const Vector3 boxVertices[8] =
		{
			Vector3(aabb.Min().X(), aabb.Min().Y(), aabb.Min().Z()),
			Vector3(aabb.Min().X(), aabb.Min().Y(), aabb.Max().Z()),
			Vector3(aabb.Min().X(), aabb.Max().Y(), aabb.Min().Z()),
			Vector3(aabb.Min().X(), aabb.Max().Y(), aabb.Max().Z()),

			Vector3(aabb.Max().X(), aabb.Min().Y(), aabb.Min().Z()),
			Vector3(aabb.Max().X(), aabb.Min().Y(), aabb.Max().Z()),
			Vector3(aabb.Max().X(), aabb.Max().Y(), aabb.Min().Z()),
			Vector3(aabb.Max().X(), aabb.Max().Y(), aabb.Max().Z())
		};

		for (int i = 0; i < 3; i++)
		{
			Project(triangle.vertex, 3, boxNormals[i], triangleMin, triangleMax);
			if (triangleMax < aabb.Min()[i] || triangleMin > aabb.Max()[i])
			{
				return false; // No intersection possible.
			}
		}

		// Test the triangle normal
		Vector3 triangleNormal = triangle.GetNormal();
		float triangleValue = triangleNormal.Dot(triangle.vertex[0]);
		Project(boxVertices, 8, triangleNormal, boxMin, boxMax);
		if (boxMax < triangleValue || boxMin > triangleValue)
		{
			return false; // No intersection possible.
		}

		// Test the nine edge cross-products
		Vector3 triangleEdges[3] =
		{
			triangle.vertex[0] - triangle.vertex[1],
			triangle.vertex[1] - triangle.vertex[2],
			triangle.vertex[2] - triangle.vertex[0]
		};

		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				// The box normals are the same as it's edge tangents
				Vector3 axis = triangleEdges[i].Cross(boxNormals[j]);
				axis.Normalize();

				Project(boxVertices, 8, axis, boxMin, boxMax);
				Project(triangle.vertex, 3, axis, triangleMin, triangleMax);
				if (boxMax <= triangleMin || boxMin >= triangleMax)
					return false; // No intersection possible
			}
		}

		// No separating axis found.
		return true;
	}


	static void Project(const Vector3* points, int count, Vector3 axis, float& min, float& max)
	{
		min = Math::MaxValue;
		max = -Math::MaxValue;

		for (int i = 0; i < count; i++)
		{
			float val = axis.Dot(points[i]);
			if (val < min)
				min = val;
			if (val > max)
				max = val;
		}
	}

	static HitRecord RayCast(const AABB3& aabb, const Ray3& ray)
	{
		HitRecord result;

		Vector3 dir = ray.direction;// +Vector3::RandomEpsilon();

		Vector3 tMin = (aabb.Min() - ray.origin) / dir;
		Vector3 tMax = (aabb.Max() - ray.origin) / dir;

		Vector3 t1 = Vector3::Min(tMin, tMax);
		Vector3 t2 = Vector3::Max(tMin, tMax);

		float tNear = Math::Max(Math::Max(t1[0], t1[1]), t1[2]);
		float tFar = Math::Min(Math::Min(t2[0], t2[1]), t2[2]);

		if (tFar < 0 || tNear > tFar)
		{
			result.hit = false;
			result.t = Math::MaxValue;
			result.normal = Vector3::Zero;
			result.u = 0;
			result.v = 0;
		}
		else
		{
			result.hit = true;
			result.t = tNear;
			result.normal = Vector3::Zero;
			result.u = 0;
			result.v = 0;
		}

		return result;
	}

	static HitRecord RayCast(const Triangle& triangle, Ray3 ray)
	{
		HitRecord result;

		// compute the plane's normal
		Vector3 v0v1 = triangle.vertex[1] - triangle.vertex[0];
		Vector3 v0v2 = triangle.vertex[2] - triangle.vertex[0];

		// no need to normalize
		Vector3 N = v0v1.Cross(v0v2);
		float area2 = N.Length();

		// # Step 1: finding P
		// # check if the ray and plane are parallel.
		float NdotRayDirection = N.Dot(ray.direction);
		if (abs(NdotRayDirection) < 0.000001) //# almost 0
			return result; //# they are parallel, so they don't intersect! 

		// #compute d parameter using equation 2
		float d = -N.Dot(triangle.vertex[0]);

		// # compute t(equation 3)
		float t = -(N.Dot(ray.origin) + d) * (1.0f / NdotRayDirection);

		// check if the triangle is behind the ray
		if (t < 0.0)
			return result; // # the triangle is behind

		// # compute the intersection point using equation 1
		Vector3 P = ray.origin + t * ray.direction;


		// #Step 2: inside - outside test
		// # edge 0
		Vector3 edge0 = triangle.vertex[1] - triangle.vertex[0];
		Vector3 vp0 = P - triangle.vertex[0];
		Vector3 C0 = edge0.Cross(vp0);
		if (N.Dot(C0) < 0)
			return result;// # P is on the right side

		// # edge 1
		Vector3 edge1 = triangle.vertex[2] - triangle.vertex[1];
		Vector3 vp1 = P - triangle.vertex[1];
		Vector3 C1 = edge1.Cross(vp1);
		if (N.Dot(C1) < 0)
			return result;// # P is on the right side

		// # edge 2
		Vector3 edge2 = triangle.vertex[0] - triangle.vertex[2];
		Vector3 vp2 = P - triangle.vertex[2];
		Vector3 C2 = edge2.Cross(vp2);
		if (N.Dot(C2) < 0)
			return result; // # P is on the right side

		result.hit = true;
		result.t = t;
		//result.normal = (triangle.vertex[1] - triangle.vertex[0]).Cross(triangle.vertex[2] - triangle.vertex[0]);
		//result.normal.Normalize();
		//result.normal = triangle.GetNormal();
		result.normal = (edge0).Cross(-edge2);
		result.normal.Normalize();

		result.u = C1.Length() / area2;
		result.v = C2.Length() / area2;

		return result;
	}
};

#endif