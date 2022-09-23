#ifndef _LPVObjLoader_h_ 
#define _LPVObjLoader_h_ 

#include "Component.h"
#include "Video.h"
#include "LPVCommon.h"

class LPVObjLoader
{
public:
	struct ObjectInfo
	{
		std::vector<Vector3> tangents;
		std::vector<Vector3> normals;
		std::vector<Vector3> positions;
		std::vector<Vector2> uvs;
		std::vector<Vector2> uv2s;
		std::string name;
		std::string material;
	};

	LPVObjLoader();

	virtual ~LPVObjLoader();

	void Load(const std::string& filename, std::function<void(std::vector<ObjectInfo>&)> onload);
private:
	void OnCompletion(std::function<void(std::vector<ObjectInfo>&)> onload);
public:
private:
};

#endif