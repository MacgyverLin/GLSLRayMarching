#ifndef _LPVMtlLoader_h_ 
#define _LPVMtlLoader_h_ 

#include "Component.h"
#include "Video.h"
#include "LPVCommon.h"
#include "ColorRGBA.h"
#include <fstream>

class LPVMtlLoader
{
public:
	struct MaterialInfo
	{
		ColorRGBA Ka;
		ColorRGBA Kd;
		ColorRGBA Ks;
		ColorRGBA Ke;
		ColorRGBA Tf;

		float Ns;
		float Ni;
		float d;
		float Tr;

		int illum;

		bool hasMapKa;
		std::string map_Ka;

		bool hasMapKd;
		std::string map_Kd;

		bool hasMapKs;
		std::string map_Ks;

		bool hasMapd;
		std::string map_d;

		bool hasMapNorm;
		std::string map_norm;

		bool hasMapbump;
		std::string map_bump;

		bool hasbump;
		std::string bump;
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