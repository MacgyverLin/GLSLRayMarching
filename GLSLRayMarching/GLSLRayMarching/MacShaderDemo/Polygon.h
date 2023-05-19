#ifndef _Polygon_h_
#define _Polygon_h_

#include "Platform.h"

class Polygon
{
public:
	std::vector<int> indices;
public:
	Polygon()
	{
	}

	~Polygon()
	{
	}

	int GetNumVertices() const
	{
		return (int)indices.size();
	}

	bool IsEmpty() const
	{
		return GetNumVertices() == 0;
	}

	bool IsTriangle() const
	{
		return GetNumVertices() == 3;
	}

	bool IsPolygon() const
	{
		return GetNumVertices() >= 3;
	}
};

#endif