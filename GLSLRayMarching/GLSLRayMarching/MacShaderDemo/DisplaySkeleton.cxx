/****************************************************************************************

   Copyright (C) 2015 Autodesk, Inc.
   All rights reserved.

   Use of this software is subject to the terms of the Autodesk license agreement
   provided at the time of installation or download, or which otherwise accompanies
   this software in either electronic or hard copy form.
 
****************************************************************************************/
#include "FBX.h"

void DisplaySkeleton(FbxNode* pNode)
{ 
    FbxSkeleton* lSkeleton = (FbxSkeleton*) pNode->GetNodeAttribute();

    Debug("Skeleton Name: ", (char *) pNode->GetName());
    DisplayMetaDataConnections(lSkeleton);

    const char* lSkeletonTypes[] = { "Root", "Limb", "Limb Node", "Effector" };

    Debug("    Type: ", lSkeletonTypes[lSkeleton->GetSkeletonType()]);

    if (lSkeleton->GetSkeletonType() == FbxSkeleton::eLimb)
    {
        DisplayDouble("    Limb Length: ", lSkeleton->LimbLength.Get());
    }
    else if (lSkeleton->GetSkeletonType() == FbxSkeleton::eLimbNode)
    {
        DisplayDouble("    Limb Node Size: ", lSkeleton->Size.Get());
    }
    else if (lSkeleton->GetSkeletonType() == FbxSkeleton::eRoot)
    {
        DisplayDouble("    Limb Root Size: ", lSkeleton->Size.Get());
    }

    DisplayColor("    Color: ", lSkeleton->GetLimbNodeColor());
}
