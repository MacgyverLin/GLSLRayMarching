#include "LPVMtlLoader.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVMtlLoader::LPVMtlLoader()
{
}

LPVMtlLoader::~LPVMtlLoader()
{
}

void LPVMtlLoader::Load(const std::string& filename, std::function<void(std::map<std::string, MaterialInfo>&)> onload)
{
}

void LPVMtlLoader::OnCompletion(std::function<void(std::map<std::string, MaterialInfo>&)> onload)
{
}