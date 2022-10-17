#ifndef _LPVMtlLoader_h_ 
#define _LPVMtlLoader_h_ 

#include "Component.h"
#include "Video.h"
#include "LPVCommon.h"
#include "ColorRGBA.h"

class LPVMtlLoader
{
public:
	struct MaterialInfo
	{
		bool hasMapKd;
		ColorRGBA Kd;
		std::string map_Kd;

		bool hasMapKs;
		ColorRGBA Ks;
		std::string map_Ks;
		
		bool hasMapNorm;
		std::string map_norm;
	};
	LPVMtlLoader();

	virtual ~LPVMtlLoader();

	void Load(const std::string& filename, std::function<void(std::map<std::string, MaterialInfo>&)> onload);
private:
	void OnCompletion(std::function<void(std::map<std::string, MaterialInfo>&)> onload);
public:
private:
};

#endif