#ifndef _TetrahedronizedMeshGenerator_h_
#define _TetrahedronizedMeshGenerator_h_

#include "TetrahedronMesh.h"
#include "Mesh.h"
#include "BVHTree.h"

class TetrahedronizedMeshGenerator
{
public:
	TetrahedronizedMeshGenerator()
	{
	}

	~TetrahedronizedMeshGenerator()
	{
	}

	void Generate(TetrahedronMesh& tetMesh, const Mesh& mesh, int resolution, float minQualityExp, float tetScale)
	{
		CreateTets(tetMesh, mesh, resolution, Math::Pow(10.0, minQualityExp), tetScale);
	}

	void CreateTets(TetrahedronMesh& tetMesh, const Mesh& mesh, int resolution, float minQualityExp, float tetScale)
	{
		static const std::vector< std::vector<int>> tetFaces =
		{
			{ 2, 1, 0 },
			{ 0, 1, 3 },
			{ 1, 2, 3 },
			{ 2, 0, 3 }
		};

		/*
		static const std::vector< std::vector<int>> tetEdges =
		{
			{1, 0},
			{0, 2},
			{2, 1},
			{1, 3},
			{3, 0},
			{2, 3}
		};
		*/

		BVHTree* tree = BVHTree::FromMesh(mesh);

		// create vertices

		// from input mesh

		std::vector<Vector3> tetVerts;

		for (auto& v : mesh.positions)
			tetVerts.push_back(v + Vector3::RandomEpsilon());

		Vector3 center = Vector3::Zero;
		Vector3 min = Vector3::MaxValue;
		Vector3 max = -Vector3::MaxValue;
		for (auto& p : tetVerts)
		{
			center += p;
			min = Vector3::Min(min, p);
			max = Vector3::Max(max, p);
		}
		center = center * (1.0f / tetVerts.size());

		float radius = 0.0f;
		for (auto& p : tetVerts)
		{
			float d = (p - center).Length();
			radius = Math::Max(radius, d);
		}

		// interior sampling

		if (resolution > 0)
		{
			Vector3 dims = max - min;
			float dim = Math::Max(dims[0], Math::Max(dims[1], dims[2]));
			float h = dim / resolution;

			for (int xi = 0; xi < int(dims[0] / h) + 1; xi++)
			{
				float x = min[0] + xi * h + Math::RandomEpsilon();
				for (int yi = 0; yi < int(dims[1] / h) + 1; yi++)
				{
					float y = min[1] + yi * h + Math::RandomEpsilon();
					for (int zi = 0; zi < int(dims[2] / h) + 1; zi++)
					{
						float z = min[2] + zi * h + Math::RandomEpsilon();
						Vector3 p(x, y, z);
						if (tree->IsInside(p, 0.5f * h))
						{
							tetVerts.push_back(p);
						}
					}
				}
			}
		}

		// big tet to start with
		//float s = 5.0f * radius;
		//tetVerts.push_back(Vector3(-s, 0.0f, -s) + center);
		//tetVerts.push_back(Vector3(s, 0.0f, -s) + center);
		//tetVerts.push_back(Vector3(0.0f, s, s) + center);
		//tetVerts.push_back(Vector3(0.0f, -s, s) + center);\

		float r = radius * 10.0f;
		float a = r / Math::Sin(30 * Math::Degree2Radian);
		float b = r / Math::Cos(30 * Math::Degree2Radian) * (a + r) / (a);
		tetVerts.push_back(Vector3(-b, -r, -r) + center);
		tetVerts.push_back(Vector3(b, -r, -r) + center);
		tetVerts.push_back(Vector3(0.0f, a, 0.0f) + center);
		tetVerts.push_back(Vector3(0.0f, -r, a) + center);

		std::vector<int> faces = CreateTetIds(tetVerts, tree, minQualityExp, tetFaces);
		int numTets = int(faces.size() / 4);

		//if (!debug)
		{
			int numSrcPoints = (int)mesh.positions.size();
			int numPoints = (int)tetVerts.size() - 4;

			// copy src points without distortion
			for (int i = 0; i < numSrcPoints; i++)
			{
				Vector3 co = mesh.positions[i];
				tetMesh.positions.push_back(co);
			}

			// copy added point with distortion
			for (int i = numSrcPoints; i < numPoints; i++)
			{
				Vector3 p = tetVerts[i];
				tetMesh.positions.push_back(p);
			}
		}
		/*
		else
		{
			for (int i = 0; i < numTets; i++)
			{
				center = (tetVerts[faces[4 * i]] + tetVerts[faces[4 * i + 1]] + tetVerts[faces[4 * i + 2]] + tetVerts[faces[4 * i + 3]]) * 0.25;

				for (int j = 0; j < 4; j++) // 4 faces per tetrahedron
				{
					for (int k = 0; k < 3; k++) // 3 vertices per faces
					{
						Vector3 p = tetVerts[faces[4 * i + tetFaces[j][k]]];
						p = center + (p - center) * tetScale;
						tetMesh.positions.push_back(p);
					}
				}
			}
		}
		*/

		int nr = 0;
		for (int i = 0; i < numTets; i++)
		{
			// if (!debug)
			{
				tetMesh.indices.push_back(faces[4 * i + 0]);
				tetMesh.indices.push_back(faces[4 * i + 1]);
				tetMesh.indices.push_back(faces[4 * i + 2]);
				tetMesh.indices.push_back(faces[4 * i + 3]);
			}
			/*
			else
			{
				for (int j = 0; j < 4; j++)
				{
					tetMesh.indices.push_back(nr + 0);
					tetMesh.indices.push_back(nr + 1);
					tetMesh.indices.push_back(nr + 2);

					nr = nr + 3;
				}
			}
			*/
		}

		if (tree)
		{
			delete tree;
			tree = nullptr;
		}
	}

	static bool compareEdges(const std::tuple<int, int, int, int>& e0, const std::tuple<int, int, int, int>& e1)
	{
		if (std::get<0>(e0) < std::get<0>(e1) || (std::get<0>(e0) == std::get<0>(e1) && std::get<1>(e0) < std::get<1>(e1)))
			return true;
		else
			return false;
	}

	static bool equalEdges(const std::tuple<int, int, int, int>& e0, const std::tuple<int, int, int, int>& e1)
	{
		return std::get<0>(e0) == std::get<0>(e1) && std::get<1>(e0) == std::get<1>(e1);
	}

	std::vector<int> CreateTetIds(const std::vector<Vector3>& verts, const BVHTree* tree, float minQuality, const std::vector< std::vector<int>>& tetFaces)
	{
		std::vector<int> tetIds;
		std::vector<int> neighbors;
		std::vector<int> tetMarks;
		int tetMark = 0;
		int firstFreeTet = -1;

		std::vector<Vector3> planesN;
		std::vector<float> planesD;

		int firstBig = (int)verts.size() - 4;
		tetIds.push_back(firstBig);
		tetIds.push_back(firstBig + 1);
		tetIds.push_back(firstBig + 2);
		tetIds.push_back(firstBig + 3);
		tetMarks.push_back(0);

		// for each faces of terahedra
		for (int i = 0; i < 4; i++)
		{
			neighbors.push_back(-1);
			const Vector3& p0 = verts[firstBig + tetFaces[i][0]];
			const Vector3& p1 = verts[firstBig + tetFaces[i][1]];
			const Vector3& p2 = verts[firstBig + tetFaces[i][2]];
			Vector3 n = (p1 - p0).Cross(p2 - p0);    n.Normalize();
			planesN.push_back(n);
			planesD.push_back(p0.Dot(n));
		}

		Vector3 center = Vector3::Zero;

		DisplayString(" ------------- tetrahedralization -------------------\n");
		for (int i = 0; i < firstBig; i++)
		{
			const Vector3& p = verts[i];

			if (i % 100 == 0)
			{
				char buffer[1024];
				snprintf(buffer, 1024, "inserting vert %d of %d\n", i + 1, firstBig);
				DisplayString(buffer);
			}

			// find non - deleted tet
			int tetNr = 0;
			while (tetIds[4 * tetNr] < 0)
				tetNr = tetNr + 1;

			// find containing tet
			tetMark = tetMark + 1;
			bool found = false;

			while (!found)
			{
				if (tetNr < 0 || tetMarks[tetNr] == tetMark)
					break;
				tetMarks[tetNr] = tetMark;

				int id0 = tetIds[4 * tetNr];
				int id1 = tetIds[4 * tetNr + 1];
				int id2 = tetIds[4 * tetNr + 2];
				int id3 = tetIds[4 * tetNr + 3];

				center = (verts[id0] + verts[id1] + verts[id2] + verts[id3]) * 0.25f;

				float minT = Math::MaxValue;
				int minFaceNr = -1;

				for (int j = 0; j < 4; j++)
				{
					Vector3 n = planesN[4 * tetNr + j];
					float d = planesD[4 * tetNr + j];

					float hp = n.Dot(p) - d;
					float hc = n.Dot(center) - d;

					float t = hp - hc;
					if (t == 0)
						continue;

					// time when c->p hits the face
					t = -hc / t;

					if (t >= 0.0f && t < minT)
					{
						minT = t;
						minFaceNr = j;
					}
				}

				if (minT >= 1.0)
					found = true;
				else
					tetNr = neighbors[4 * tetNr + minFaceNr];
			}

			if (!found)
			{
				DisplayString("*********** failed to insert vertex\n");
				continue;
			}

			// find violating tets

			tetMark = tetMark + 1;

			std::vector<int> violatingTets;
			std::vector<int> stack = { tetNr };

			while (stack.size() != 0)
			{
				tetNr = stack.back();  // stack.pop();
				stack.pop_back();

				if (tetMarks[tetNr] == tetMark)
					continue;
				tetMarks[tetNr] = tetMark;
				violatingTets.push_back(tetNr);

				for (int j = 0; j < 4; j++)
				{
					int n = neighbors[4 * tetNr + j];
					if (n < 0 || tetMarks[n] == tetMark)
						continue;

					// Delaunay condition test

					int id0 = tetIds[4 * n];
					int id1 = tetIds[4 * n + 1];
					int id2 = tetIds[4 * n + 2];
					int id3 = tetIds[4 * n + 3];

					Vector3 c = GetCircumCenter(verts[id0], verts[id1], verts[id2], verts[id3]);

					float r = (verts[id0] - c).Length();
					if ((p - c).Length() < r)
					{
						stack.push_back(n);
					}
				}
			}

			// remove old tets, create new ondes
			std::vector<std::tuple<int, int, int, int>> edges;
			for (int j = 0; j < violatingTets.size(); j++)
			{
				tetNr = violatingTets[j];

				// copy info before we delete it
				std::vector<int> ids = { 0, 0, 0, 0 };
				std::vector<int> ns = { 0, 0, 0, 0 };
				for (int k = 0; k < 4; k++)
				{
					ids[k] = tetIds[4 * tetNr + k];
					ns[k] = neighbors[4 * tetNr + k];
				}

				// delete the tet
				tetIds[4 * tetNr] = -1;
				tetIds[4 * tetNr + 1] = firstFreeTet;
				firstFreeTet = tetNr;

				// visit neighbors
				for (int k = 0; k < 4; k++)
				{
					int n = ns[k];
					if (n >= 0 && tetMarks[n] == tetMark)
						continue;

					// no neighbor or neighbor is not- violating->we are facing the border

					// create new tet

					int newTetNr = firstFreeTet;

					if (newTetNr >= 0)
						firstFreeTet = tetIds[4 * firstFreeTet + 1];
					else
					{
						newTetNr = int(tetIds.size() / 4);
						tetMarks.push_back(0);
						for (int l = 0; l < 4; l++)
						{
							tetIds.push_back(-1);
							neighbors.push_back(-1);
							planesN.push_back(Vector3::Zero);
							planesD.push_back(0.0);
						}
					}

					int id0 = ids[tetFaces[k][2]];
					int id1 = ids[tetFaces[k][1]];
					int id2 = ids[tetFaces[k][0]];

					tetIds[4 * newTetNr] = id0;
					tetIds[4 * newTetNr + 1] = id1;
					tetIds[4 * newTetNr + 2] = id2;
					tetIds[4 * newTetNr + 3] = i;

					neighbors[4 * newTetNr] = n;

					if (n >= 0)
					{
						for (int l = 0; l < 4; l++)
						{
							if (neighbors[4 * n + l] == tetNr)
								neighbors[4 * n + l] = newTetNr;
						}
					}

					// will set the neighbors among the new tets later

					neighbors[4 * newTetNr + 1] = -1;
					neighbors[4 * newTetNr + 2] = -1;
					neighbors[4 * newTetNr + 3] = -1;

					for (int l = 0; l < 4; l++)
					{
						const Vector3& p0 = verts[tetIds[4 * newTetNr + tetFaces[l][0]]];
						const Vector3& p1 = verts[tetIds[4 * newTetNr + tetFaces[l][1]]];
						const Vector3& p2 = verts[tetIds[4 * newTetNr + tetFaces[l][2]]];
						Vector3 newN = (p1 - p0).Cross(p2 - p0); newN.Normalize();
						planesN[4 * newTetNr + l] = newN;
						planesD[4 * newTetNr + l] = newN.Dot(p0);
					}


					if (id0 < id1)
						edges.push_back(std::tuple<int, int, int, int>(id0, id1, newTetNr, 1));
					else
						edges.push_back(std::tuple<int, int, int, int>(id1, id0, newTetNr, 1));

					if (id1 < id2)
						edges.push_back(std::tuple<int, int, int, int>(id1, id2, newTetNr, 2));
					else
						edges.push_back(std::tuple<int, int, int, int>(id2, id1, newTetNr, 2));

					if (id2 < id0)
						edges.push_back(std::tuple<int, int, int, int>(id2, id0, newTetNr, 3));
					else
						edges.push_back(std::tuple<int, int, int, int>(id0, id2, newTetNr, 3));


				}// next neighbor
			} // next violating tet

			// fix neighbors

			// sorted(edges, key = cmp_to_key(compareEdges));
			std::vector<std::tuple<int, int, int, int>> sortedEdges = edges;
			std::sort(sortedEdges.begin(), sortedEdges.end(), compareEdges);

			int nr = 0;
			int numEdges = (int)sortedEdges.size();

			while (nr < numEdges)
			{
				std::tuple<int, int, int, int> e0 = sortedEdges[nr];
				nr = nr + 1;

				if (nr < numEdges && equalEdges(sortedEdges[nr], e0))
				{
					std::tuple<int, int, int, int> e1 = sortedEdges[nr];

					// int id0 = tetIds[4 * std::get<2>(e0)];
					// int id1 = tetIds[4 * std::get<2>(e0) + 1];
					// int id2 = tetIds[4 * std::get<2>(e0) + 2];
					// int id3 = tetIds[4 * std::get<2>(e0) + 3];
					// 
					// int jd0 = tetIds[4 * std::get<2>(e1)];
					// int jd1 = tetIds[4 * std::get<2>(e1) + 1];
					// int jd2 = tetIds[4 * std::get<2>(e1) + 2];
					// int jd3 = tetIds[4 * std::get<2>(e1) + 3];

					neighbors[4 * std::get<2>(e0) + std::get<3>(e0)] = std::get<2>(e1);
					neighbors[4 * std::get<2>(e1) + std::get<3>(e1)] = std::get<2>(e0);
					nr = nr + 1;
				}
			}
		} // next point

		// remove outer, deleted and outside tets

		int numTets = int(tetIds.size() / 4);
		int num = 0;
		int numBad = 0;

		for (int i = 0; i < numTets; i++)
		{
			int id0 = tetIds[4 * i];
			int id1 = tetIds[4 * i + 1];
			int id2 = tetIds[4 * i + 2];
			int id3 = tetIds[4 * i + 3];

			if (id0 < 0 || id0 >= firstBig || id1 >= firstBig || id2 >= firstBig || id3 >= firstBig)
				continue;

			const Vector3& p0 = verts[id0];
			const Vector3& p1 = verts[id1];
			const Vector3& p2 = verts[id2];
			const Vector3& p3 = verts[id3];

			float quality = TetQuality(p0, p1, p2, p3);
			if (quality < minQuality)
			{
				numBad = numBad + 1;
				continue;
			}

			center = (p0 + p1 + p2 + p3) * 0.25f;
			if (!tree->IsInside(center))
				continue;

			tetIds[num] = id0;
			num = num + 1;
			tetIds[num] = id1;
			num = num + 1;
			tetIds[num] = id2;
			num = num + 1;
			tetIds[num] = id3;
			num = num + 1;
		}

		tetIds.resize(num);


		char buffer[1024];
		snprintf(buffer, 1024, "%d bad tets deleted\n", numBad);
		DisplayString(buffer);
		snprintf(buffer, 1024, "%d tets created\n", int(tetIds.size() / 4));
		DisplayString(buffer);

		return tetIds;
	}

	Vector3 GetCircumCenter(const Vector3& p0, const Vector3& p1, const Vector3& p2, const Vector3& p3)
	{
		int x = 0;
		int y = 1;
		int z = 2;

		Vector3 b = p1 - p0;
		Vector3 c = p2 - p0;
		Vector3 d = p3 - p0;

		float det = 2.0f * (b[x] * (c[y] * d[z] - c[z] * d[y]) - b[y] * (c[x] * d[z] - c[z] * d[x]) + b[z] * (c[x] * d[y] - c[y] * d[x]));
		if (det == 0.0f)
			return p0;
		else
		{
			Vector3 v = c.Cross(d) * b.Dot(b) + d.Cross(b) * c.Dot(c) + b.Cross(c) * d.Dot(d);
			v = v / det;
			return p0 + v;
		}
	}

	float TetQuality(const Vector3& p0, const Vector3& p1, const Vector3& p2, const Vector3& p3)
	{
		Vector3 d0 = p1 - p0;
		Vector3 d1 = p2 - p0;
		Vector3 d2 = p3 - p0;
		Vector3 d3 = p2 - p1;
		Vector3 d4 = p3 - p2;
		Vector3 d5 = p1 - p3;

		float s0 = d0.Length();
		float s1 = d1.Length();
		float s2 = d2.Length();
		float s3 = d3.Length();
		float s4 = d4.Length();
		float s5 = d5.Length();

		float ms = (s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3 + s4 * s4 + s5 * s5) / 6.0f;
		float rms = Math::Sqrt(ms);

		float s = 12.0f / Math::Sqrt(2.0f);

		float vol = d0.Dot(d1.Cross(d2)) / 6.0f;

		return s * vol / (rms * rms * rms); // 1.0 for regular tetrahedron
	}
};

#endif