#ifndef _TetrahedronMesh_h_
#define _TetrahedronMesh_h_

#include "Vector3.h"

class TetrahedronMesh
{
public:
	static const std::vector<std::vector<int>> tetFaces;
	
	std::vector<Vector3> positions;
	std::vector<int> indices;
public:
	TetrahedronMesh()
	{
	}

	~TetrahedronMesh()
	{
	}

	TetrahedronMesh(const TetrahedronMesh& mesh)
	{
		this->positions = mesh.positions;
		this->indices = mesh.indices;
	}

	TetrahedronMesh& operator = (const TetrahedronMesh& mesh)
	{
		this->positions = mesh.positions;
		this->indices = mesh.indices;

		return *this;
	}

	void Clear()
	{
		this->positions.clear();
		this->indices.clear();
	}
};


#endif