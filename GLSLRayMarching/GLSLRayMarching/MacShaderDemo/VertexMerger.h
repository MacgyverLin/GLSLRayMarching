#ifndef _VertexMerger_h_
#define _VertexMerger_h_

#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix3.h"
#include "ColorRGBA.h"
#include "Ray3.h"

template<class VertexType>
class VertexMerger
{
private:
	std::map<VertexType, int> indicesMap;
	std::vector<VertexType>& vertices;

public:
	VertexMerger(std::vector<VertexType>& vertices_)
		: vertices(vertices_)
	{
	}

	~VertexMerger()
	{
	}

	std::vector<VertexType>& GetVertices()
	{
		return vertices;
	}

	int Get(const VertexType& v)
	{
		typename std::map<VertexType, int>::iterator itr = indicesMap.find(v);

		int idx = -1;
		if (itr == indicesMap.end())
		{
			return -1;
		}
		else
		{
			return idx = itr->second;
		}
	}

	int Insert(const VertexType& v)
	{
		typename std::map<VertexType, int>::iterator itr = indicesMap.find(v);

		int idx = -1;
		if (itr == indicesMap.end())
		{
			// v is not in vertices buffer, append v, index of buffer tail
			idx = (int)vertices.size();
			indicesMap[v] = idx;

			vertices.push_back(v);
		}
		else
		{
			// v is already in vertices buffer, no need append v, resuse vIdx

			idx = itr->second;
		}

		return idx;
	}
};
#endif