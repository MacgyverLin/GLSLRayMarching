#ifndef _Hash_h_
#define _Hash_h_

#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix3.h"
#include "ColorRGBA.h"
#include "Ray3.h"

class Hash
{
public:
	float spacing;
	int tableSize;
	std::vector<int> cellStart;
	std::vector<int> cellEntries;
	std::vector<int> queryIds;
	int querySize;
public:
	Hash()
	{
	}

	int HashCoords(int xi, int yi, int zi)
	{
		int h = (xi * 92837111) ^ (yi * 689287499) ^ (zi * 283923481);	// fantasy function

		return Math::Abs(h) % tableSize;
	}

	int IntCoord(float coord)
	{
		return (int)Math::Floor(coord / this->spacing);
	}

	int HashPos(const Vector3& pos)
	{
		return HashCoords
		(
			IntCoord(pos.X()),
			IntCoord(pos.Y()),
			IntCoord(pos.Z())
		);
	}

	void Create(const std::vector<Vector3>& pos, float spacing_)
	{
#define SPARSE_TABLE_SIZE 5
		spacing = spacing_;
		tableSize = SPARSE_TABLE_SIZE * (int)pos.size(); //  larger table size, fewer collision

		cellStart.resize(tableSize + 1);
		cellEntries.resize((int)pos.size());

		queryIds.resize((int)pos.size());
		querySize = 0;


		// create a Dense Hash table, so that particle at the same grid are consecutive
		int numObjects = (int)pos.size();

		// determine cell sizes
		std::fill(queryIds.begin(), queryIds.end(), -1);
		std::fill(cellStart.begin(), cellStart.end(), 0);
		std::fill(cellEntries.begin(), cellEntries.end(), 0);

		// fill particle count for eash hash entry
		for (int i = 0; i < numObjects; i++)
		{
			int h = HashPos(pos[i]);
			cellStart[h]++;
		}

		// partial sum
		int start = 0;
		for (int i = 0; i < tableSize; i++)
		{
			start += cellStart[i];
			cellStart[i] = start;
		}
		cellStart[tableSize] = start;	// guard

		// fill in objects ids
		for (int i = 0; i < numObjects; i++)
		{
			int h = HashPos(pos[i]);
			cellStart[h]--;
			cellEntries[cellStart[h]] = i;
		}
	}

	void Query(const AABB3& aabb)
	{
		int x0 = IntCoord(aabb.Min().X());
		int y0 = IntCoord(aabb.Min().Y());
		int z0 = IntCoord(aabb.Min().Z());

		int x1 = IntCoord(aabb.Max().X());
		int y1 = IntCoord(aabb.Max().Y());
		int z1 = IntCoord(aabb.Max().Z());

		Query(x0, y0, z0, x1, y1, z1);
	}

	void Query(const Vector3& pos, float maxDist)
	{
		int x0 = IntCoord(pos.X() - maxDist);
		int y0 = IntCoord(pos.Y() - maxDist);
		int z0 = IntCoord(pos.Z() - maxDist);

		int x1 = IntCoord(pos.X() + maxDist);
		int y1 = IntCoord(pos.Y() + maxDist);
		int z1 = IntCoord(pos.Z() + maxDist);

		Query(x0, y0, z0, x1, y1, z1);
	}

	void Query(int x0, int y0, int z0, int x1, int y1, int z1)
	{
		std::set<int> usedHashes;

		querySize = 0;
		for (int xi = x0; xi <= x1; xi++)
		{
			for (int yi = y0; yi <= y1; yi++)
			{
				for (int zi = z0; zi <= z1; zi++)   // for 27 neighbours
				{
					int h = HashCoords(xi, yi, zi);
					if(usedHashes.contains(h))
						continue;
					
					usedHashes.insert(h);

					int start = cellStart[h];		  // for all particle in this cell
					int end = cellStart[h + 1];

					for (int i = start; i < end; i++)
					{
						queryIds[querySize] = cellEntries[i];
						querySize++;
					}
				}
			}
		}
	}
};

#endif