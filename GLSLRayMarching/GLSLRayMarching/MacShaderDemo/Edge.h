#ifndef _Edge_h_
#define _Edge_h_

#include "Vector2.h"

class Edge
{
public:
	int idx0;
	int idx1;
public:
	Edge(int idx0_, int idx1_)
	{
		idx0 = idx0_;
		idx1 = idx1_;
	}

	bool operator < (const Edge& other) const
	{
		return (this->idx0 < other.idx0) || ((this->idx0 == other.idx0) && (this->idx1 < other.idx1));
	}

	bool operator == (const Edge& other) const
	{
		return this->idx0 < other.idx0 && this->idx1 < other.idx1;
	}
};

#endif