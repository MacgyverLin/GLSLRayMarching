#include "LPVObjLoader.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVObjLoader::LPVObjLoader()
{
}

LPVObjLoader::~LPVObjLoader()
{
}

void LPVObjLoader::Load(const std::string& filename, std::function<void(std::vector<ObjectInfo>&)> onload)
{
}

void LPVObjLoader::OnCompletion(std::function<void(std::vector<ObjectInfo>&)> onload)
{
}