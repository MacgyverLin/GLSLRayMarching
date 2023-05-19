/****************************************************************************************

   Copyright (C) 2015 Autodesk, Inc.
   All rights reserved.

   Use of this software is subject to the terms of the Autodesk license agreement
   provided at the time of installation or download, or which otherwise accompanies
   this software in either electronic or hard copy form.
 
****************************************************************************************/

#include "FBX.h"

void DisplayPivotsAndLimits(FbxNode* pNode)
{
    FbxVector4 lTmpVector;

    //
    // Pivots
    //
    Debug("    Pivot Information\n");

    FbxNode::EPivotState lPivotState;
    pNode->GetPivotState(FbxNode::eSourcePivot, lPivotState);
    Debug("        Pivot State: %s\n", lPivotState == FbxNode::ePivotActive ? "Active" : "Reference");

    lTmpVector = pNode->GetPreRotation(FbxNode::eSourcePivot);
    Display3DVector("        Pre-Rotation: %f %f %f\n", lTmpVector);

    lTmpVector = pNode->GetPostRotation(FbxNode::eSourcePivot);
    Display3DVector("        Post-Rotation: %f %f %f\n", lTmpVector);

    lTmpVector = pNode->GetRotationPivot(FbxNode::eSourcePivot);
    Display3DVector("        Rotation Pivot: %f %f %f\n", lTmpVector);

    lTmpVector = pNode->GetRotationOffset(FbxNode::eSourcePivot);
    Display3DVector("        Rotation Offset: %f %f %f\n", lTmpVector);

    lTmpVector = pNode->GetScalingPivot(FbxNode::eSourcePivot);
    Display3DVector("        Scaling Pivot: %f %f %f\n", lTmpVector);

    lTmpVector = pNode->GetScalingOffset(FbxNode::eSourcePivot);
    Display3DVector("        Scaling Offset: %f %f %f\n", lTmpVector);

    //
    // Limits
    //
    bool		lIsActive, lMinXActive, lMinYActive, lMinZActive;
    bool		lMaxXActive, lMaxYActive, lMaxZActive;
    FbxDouble3	lMinValues, lMaxValues;

    Debug("    Limits Information\n");

	lIsActive = pNode->TranslationActive;
	lMinXActive = pNode->TranslationMinX;
	lMinYActive = pNode->TranslationMinY;
	lMinZActive = pNode->TranslationMinZ;
	lMaxXActive = pNode->TranslationMaxX;
	lMaxYActive = pNode->TranslationMaxY;
	lMaxZActive = pNode->TranslationMaxZ;
	lMinValues = pNode->TranslationMin;
	lMaxValues = pNode->TranslationMax;

    Debug("        Translation limits: %s\n", lIsActive ? "Active" : "Inactive");
    Debug("            X\n");
    Debug("                Min Limit: %s\n", lMinXActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[0]);
    Debug("                Max Limit: %s\n", lMaxXActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[0]);
    Debug("            Y\n");
    Debug("                Min Limit: %s\n", lMinYActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[1]);
    Debug("                Max Limit: %s\n", lMaxYActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[1]);
    Debug("            Z\n");
    Debug("                Min Limit: %s\n", lMinZActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[2]);
    Debug("                Max Limit: %s\n", lMaxZActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[2]);

	lIsActive = pNode->RotationActive;
	lMinXActive = pNode->RotationMinX;
	lMinYActive = pNode->RotationMinY;
	lMinZActive = pNode->RotationMinZ;
	lMaxXActive = pNode->RotationMaxX;
	lMaxYActive = pNode->RotationMaxY;
	lMaxZActive = pNode->RotationMaxZ;
	lMinValues = pNode->RotationMin;
	lMaxValues = pNode->RotationMax;

    Debug("        Rotation limits: %s\n", lIsActive ? "Active" : "Inactive");
    Debug("            X\n");
    Debug("                Min Limit: %s\n", lMinXActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[0]);
    Debug("                Max Limit: %s\n", lMaxXActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[0]);
    Debug("            Y\n");
    Debug("                Min Limit: %s\n", lMinYActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[1]);
    Debug("                Max Limit: %s\n", lMaxYActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[1]);
    Debug("            Z\n");
    Debug("                Min Limit: %s\n", lMinZActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[2]);
    Debug("                Max Limit: %s\n", lMaxZActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[2]);

	lIsActive = pNode->ScalingActive;
	lMinXActive = pNode->ScalingMinX;
	lMinYActive = pNode->ScalingMinY;
	lMinZActive = pNode->ScalingMinZ;
	lMaxXActive = pNode->ScalingMaxX;
	lMaxYActive = pNode->ScalingMaxY;
	lMaxZActive = pNode->ScalingMaxZ;
	lMinValues = pNode->ScalingMin;
	lMaxValues = pNode->ScalingMax;

    Debug("        Scaling limits: %s\n", lIsActive ? "Active" : "Inactive");
    Debug("            X\n");
    Debug("                Min Limit: %s\n", lMinXActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[0]);
    Debug("                Max Limit: %s\n", lMaxXActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[0]);
    Debug("            Y\n");
    Debug("                Min Limit: %s\n", lMinYActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[1]);
    Debug("                Max Limit: %s\n", lMaxYActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[1]);
    Debug("            Z\n");
    Debug("                Min Limit: %s\n", lMinZActive ? "Active" : "Inactive");
    DisplayDouble("                Min Limit Value: %f\n", lMinValues[2]);
    Debug("                Max Limit: %s\n", lMaxZActive ? "Active" : "Inactive");
    DisplayDouble("                Max Limit Value: %f\n", lMaxValues[2]);
}

