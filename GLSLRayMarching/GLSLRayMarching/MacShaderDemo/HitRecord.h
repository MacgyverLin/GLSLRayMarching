#ifndef _HitRecord_h_
#define _HitRecord_h_

#include "Vector3.h"

class HitRecord
{
public:
	bool hit;
	float t;
	Vector3 normal;
	float u;
	float v;
public:
	HitRecord()
	{
		this->hit = false;
		this->t = Math::MaxValue;
		this->normal = Vector3::Zero;
		this->u = 0.0f;
		this->v = 0.0f;
	}

	HitRecord(const HitRecord& other)
	{
		this->hit = other.hit;
		this->t = other.t;
		this->normal = other.normal;
		this->u = other.u;
		this->v = other.v;
	}

	HitRecord& operator = (const HitRecord& other)
	{
		this->hit = other.hit;
		this->t = other.t;
		this->normal = other.normal;
		this->u = other.u;
		this->v = other.v;

		return *this;
	}

	bool operator < (const HitRecord& other)
	{
		return this->t < other.t;
	}

	~HitRecord()
	{
	}
};

#endif