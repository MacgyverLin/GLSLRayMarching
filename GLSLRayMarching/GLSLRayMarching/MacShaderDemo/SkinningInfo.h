#ifndef _SkinningInfo_h_
#define _SkinningInfo_h_

#include "Vector4.h"

class SkinningInfo
{
public:
	SkinningInfo()
	{
		tetid = -1;
		bary = Vector4(-1, -1, -1, -1);
	}
	int tetid;
	Vector4 bary;
};

#endif