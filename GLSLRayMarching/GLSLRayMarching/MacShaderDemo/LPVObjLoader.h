#ifndef _LPVObjLoader_h_ 
#define _LPVObjLoader_h_ 

#include "Component.h"
#include "Video.h"
#include "LPVCommon.h"
#include "assimp/importer.hpp"
#include "assimp/scene.h"
#include "assimp/postprocess.h"
#include <iostream>

class LPVObjLoader
{
public:
	struct ObjectInfo
	{
		std::vector<Vector3> tangents;
		std::vector<Vector3> bitangents;
		std::vector<Vector3> normals;
		std::vector<Vector3> positions;
		std::vector<Vector2> uvs;
		std::vector<Vector2> uv2s;
		std::vector<unsigned int> indices;
		std::string name;
		std::string material;
	};

	LPVObjLoader();

	virtual ~LPVObjLoader();

	void Load(const std::string& filename, std::function<void(std::vector<ObjectInfo>&)> onload);
private:
	void OnCompletion(std::function<void(std::vector<ObjectInfo>&)> onload);

	void processNode(std::vector<ObjectInfo>& container, aiNode* node, const aiScene* scene);

	ObjectInfo processMesh(aiMesh* mesh, const aiScene* scene);
public:
private:
};

#endif