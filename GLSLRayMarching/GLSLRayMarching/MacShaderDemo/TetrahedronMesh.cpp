#include "TetrahedronMesh.h"

const std::vector<std::vector<int>> TetrahedronMesh::tetFaces =
{
	{ 2, 1, 0 },
	{ 0, 1, 3 },
	{ 1, 2, 3 },
	{ 2, 0, 3 }
};