/****************************************************************************************

   Copyright (C) 2015 Autodesk, Inc.
   All rights reserved.

   Use of this software is subject to the terms of the Autodesk license agreement
   provided at the time of installation or download, or which otherwise accompanies
   this software in either electronic or hard copy form.
 
****************************************************************************************/

#include "FBX.h"
#include "DisplayCamera.h"

void DisplayGlobalLightSettings(FbxGlobalSettings* pGlobalSettings)
{
    DisplayColor("Ambient Color: ", pGlobalSettings->GetAmbientColor());
    Debug("");
}


void DisplayGlobalCameraSettings(FbxGlobalSettings* pGlobalSettings)
{
    Debug("Default Camera: ", pGlobalSettings->GetDefaultCamera());
    Debug("");
}


void DisplayGlobalTimeSettings(FbxGlobalSettings* pGlobalSettings)
{
    char lTimeString[256];

    Debug("Time Mode : ", FbxGetTimeModeName(pGlobalSettings->GetTimeMode()));

    FbxTimeSpan lTs;
    FbxTime     lStart, lEnd;
    pGlobalSettings->GetTimelineDefaultTimeSpan(lTs);
    lStart = lTs.GetStart();
    lEnd   = lTs.GetStop();
    Debug("Timeline default timespan: ");
    Debug("     Start: ", lStart.GetTimeString(lTimeString, FbxUShort(256)));
    Debug("     Stop : ", lEnd.GetTimeString(lTimeString, FbxUShort(256)));

    Debug("");
}


