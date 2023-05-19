#ifndef _ProxyInfoGenerator_h_
#define _ProxyInfoGenerator_h_

#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix3.h"
#include "ColorRGBA.h"
#include "Ray3.h"
#include "Hash.h"
#include "MarchingCubeMeshGenerator.h"
#include "SkinningInfo.h"

class ProxyInfoGenerator
{
public:
	ProxyInfoGenerator()
	{
	}

	~ProxyInfoGenerator()
	{
	}

	void ComputeSkinningInfo(std::vector<SkinningInfo> &skinningInfos, const Mesh& visualMesh, const TetrahedronMesh& tetMesh)
	{
		///////////////////////////////////////////////////////////////////
		// setup hash
		// create a hash for all vertices of the visual mesh
		Hash hash;
		hash.Create(visualMesh.positions, 0.05f);

		// id, bary0, bary1, bary2, minDist
		skinningInfos.clear();
		skinningInfos.resize(visualMesh.positions.size());
		std::fill(skinningInfos.begin(), skinningInfos.end(), SkinningInfo());

		std::vector<float> dists;
		dists.resize(visualMesh.positions.size());
		std::fill(dists.begin(), dists.end(), Math::MaxValue);

		///////////////////////////////////////////////////////////////////
		// each tet searches for containing vertices
		int numTets = (int)tetMesh.indices.size() / 4;
		for (int i = 0; i < numTets; i++)
		{
			/*
			///////////////////////////////////////////////////////////////////
			// compute bounding sphere of tet
			Vector3 tetCenter = Vector3::Zero;
			for (int j = 0; j < 4; j++)
			{
				int id = tetMesh.vertexIndices[4 * i + j].vIdx;
				tetCenter += tetMesh.positions[id] * 0.25f;
			}

			float rMax = 0.0f;
			for (int j = 0; j < 4; j++)
			{
				int id = tetMesh.vertexIndices[4 * i + j].vIdx;
				float r2 = (tetCenter - tetMesh.positions[id]).SquaredLength();
				rMax = Math::Max(rMax, Math::Sqrt(r2));
			}
			//float border = 0.05f;
			//rMax += border;
			rMax *= 1.01f;

			///////////////////////////////////////////////////////////////////
			// query visual Mesh for point with in tetrahedron radius
			hash.Query(tetCenter, rMax);
			if (hash.querySize == 0)
				continue;
			*/
			
			AABB3 aabb;
			GeometryConverter::Convert
			(
				aabb,
				tetMesh.positions[tetMesh.indices[4 * i + 0]],
				tetMesh.positions[tetMesh.indices[4 * i + 1]],
				tetMesh.positions[tetMesh.indices[4 * i + 2]],
				tetMesh.positions[tetMesh.indices[4 * i + 3]]
			);
			hash.Query(aabb);
			if (hash.querySize == 0)
				continue;
			
			///////////////////////////////////////////////////////////////////
			// form a matrix by the edges of tetraherdon
			int id0 = tetMesh.indices[4 * i + 0];
			int id1 = tetMesh.indices[4 * i + 1];
			int id2 = tetMesh.indices[4 * i + 2];
			int id3 = tetMesh.indices[4 * i + 3];
			Vector3 c0 = tetMesh.positions[id0] - tetMesh.positions[id3];
			Vector3 c1 = tetMesh.positions[id1] - tetMesh.positions[id3];
			Vector3 c2 = tetMesh.positions[id2] - tetMesh.positions[id3];

			// Tetrahedron's Transform local->world
			Matrix3 tetMat;
			tetMat.SetColumn(0, c0);
			tetMat.SetColumn(1, c1);
			tetMat.SetColumn(2, c2);

			float d = tetMat.Determinant();
			if (Math::FAbs(d) < Math::Epsilon)
			{
				continue;
			}

			// Tetrahedron's Transform world->local
			Matrix3 tetMatInv = tetMat.Inverse();

			// Test Inverse
			// Matrix3 mat1 = tetMat.Inverse();
			// Matrix3 temp1 = tetMat * mat1;
			// Matrix3 temp2 = mat1 * tetMat;
			// Vector3 cc0 = tetMat * Vector3::UnitX;
			// Vector3 cc1 = tetMat * Vector3::UnitY;
			// Vector3 cc2 = tetMat * Vector3::UnitZ;
			// cc0 = mat1 * c0;
			// cc1 = mat1 * c1;
			// cc2 = mat1 * c2;


			for (int j = 0; j < hash.querySize; j++)
			{
				int id = hash.queryIds[j];

				SkinningInfo& skinningInfo = skinningInfos[id];

				///////////////////////////////////////////////////////////////////
				// we already have skinning info
				if (dists[id] <= 0.0f)
					continue;

				///////////////////////////////////////////////////////////////////
				// if outside circumsphere of tetrahedron
				//if ((visualMesh.positions[id] - tetCenter).SquaredLength() > rMax * rMax)
					//continue;

				///////////////////////////////////////////////////////////////////
				// compute barycentric coords for candidate
				Vector3 pWorld = (visualMesh.positions[id] + Vector3::RandomEpsilon()*1000.0f - tetMesh.positions[id3]);
				//Vector3 pLocal = Vector3::Zero;
				//pLocal += tetMatInv.GetColumn(0) * pWorld.X();
				//pLocal += tetMatInv.GetColumn(1) * pWorld.Y();
				//pLocal += tetMatInv.GetColumn(2) * pWorld.Z();
				Vector3 pLocal = tetMatInv * pWorld;

				Vector4 bary(pLocal[0], pLocal[1], pLocal[2], 1.0f - pLocal[0] - pLocal[1] - pLocal[2]);
				/*
				if (!(bary[0] > 0.0f && bary[0] < 1.0f &&
					bary[1] > 0.0f && bary[1] < 1.0f &&
					bary[2] > 0.0f && bary[2] < 1.0f))
				{
					continue;
				}
				*/

				///////////////////////////////////////////////////////////////////
				// find the min barycentric coordinate dist
				float dist = 0.0f;
				for (int k = 0; k < 4; k++)
					dist = Math::Max(dist, -bary[k]);

				if (dist < dists[id])
				{
					skinningInfo.tetid = i;
					skinningInfo.bary = bary;

					dists[id] = dist;
				}
			}
		}
	}

	void ComputeSkinMesh(Mesh& skinMesh, const Mesh& visualMesh, TetrahedronMesh& tetMesh, std::vector<SkinningInfo>& skinningInfos)
	{
		skinMesh.Clear();
		skinMesh.indices = visualMesh.indices;
		skinMesh.positions.resize(visualMesh.positions.size());

		for (int i = 0; i < skinningInfos.size(); i++)
		{
			const SkinningInfo& skinningInfo = skinningInfos[i];

			int tetid = skinningInfo.tetid;
			int id0 = tetMesh.indices[tetid * 4 + 0];
			int id1 = tetMesh.indices[tetid * 4 + 1];
			int id2 = tetMesh.indices[tetid * 4 + 2];
			int id3 = tetMesh.indices[tetid * 4 + 3];

			Vector3 c0 = tetMesh.positions[id0] - tetMesh.positions[id3];
			Vector3 c1 = tetMesh.positions[id1] - tetMesh.positions[id3];
			Vector3 c2 = tetMesh.positions[id2] - tetMesh.positions[id3];
			Vector3 p0 = tetMesh.positions[id3];

			Matrix3 P;
			P.SetColumn(0, c0);
			P.SetColumn(0, c1);
			P.SetColumn(0, c2);

			Vector3 x(skinningInfo.bary[0], skinningInfo.bary[1], skinningInfo.bary[2]);
			skinMesh.positions[i] = P * x + p0;
		}
	}
};

#endif