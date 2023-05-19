/****************************************************************************************

   Copyright (C) 2015 Autodesk, Inc.
   All rights reserved.

   Use of this software is subject to the terms of the Autodesk license agreement
   provided at the time of installation or download, or which otherwise accompanies
   this software in either electronic or hard copy form.

****************************************************************************************/
#ifndef _COMMON_H
#define _COMMON_H

#include "Platform.h"
#include <fbxsdk.h>

void InitializeSdkObjects(FbxManager*& pManager, FbxScene*& pScene);
void DestroySdkObjects(FbxManager* pManager, bool pExitStatus);

bool SaveScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename, int pFileFormat=-1, bool pEmbedMedia=false);
bool LoadScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename);

void DisplayMetaDataConnections(FbxObject* pObject);
void DisplayVersion(const char* pHeader, int major, int minor, int revision, const char* pSuffix = "");
void DisplayString(const char* pHeader, const char* pValue = "", const char* pSuffix = "");
void DisplayBool(const char* pHeader, bool pValue, const char* pSuffix = "");
void DisplayInt(const char* pHeader, int pValue, const char* pSuffix = "");
void DisplayDouble(const char* pHeader, double pValue, const char* pSuffix = "");
void Display2DVector(const char* pHeader, FbxVector2 pValue, const char* pSuffix = "");
void Display3DVector(const char* pHeader, FbxVector4 pValue, const char* pSuffix = "");
void Display4DVector(const char* pHeader, FbxVector4 pValue, const char* pSuffix = "");
void DisplayColor(const char* pHeader, FbxPropertyT<FbxDouble3> pValue, const char* pSuffix = "");
void DisplayColor(const char* pHeader, FbxColor pValue, const char* pSuffix = "");

#endif // #ifndef _COMMON_H


