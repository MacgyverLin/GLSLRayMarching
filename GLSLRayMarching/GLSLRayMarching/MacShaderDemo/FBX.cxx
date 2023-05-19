/****************************************************************************************

   Copyright (C) 2015 Autodesk, Inc.
   All rights reserved.

   Use of this software is subject to the terms of the Autodesk license agreement
   provided at the time of installation or download, or which otherwise accompanies
   this software in either electronic or hard copy form.

****************************************************************************************/

#include "FBX.h"

#ifdef IOS_REF
	#undef  IOS_REF
	#define IOS_REF (*(pManager->GetIOSettings()))
#endif

void DisplayVersion(const char* pHeader, int major, int minor, int revision, const char* pSuffix)
{
    FbxString lString;

    lString = pHeader;
    lString += major;
    lString += minor;
    lString += revision;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void DisplayMetaDataConnections(FbxObject* pObject)
{
    int nbMetaData = pObject->GetSrcObjectCount<FbxObjectMetaData>();
    if (nbMetaData > 0)
        DisplayString("    MetaData connections ");

    for (int i = 0; i < nbMetaData; i++)
    {
        FbxObjectMetaData* metaData = pObject->GetSrcObject<FbxObjectMetaData>(i);
        DisplayString("        Name: ", (char*)metaData->GetName());
    }
}


void DisplayString(const char* pHeader, const char* pValue, const char* pSuffix)
{
    FbxString lString;

    lString = pHeader;
    lString += pValue;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void DisplayBool(const char* pHeader, bool pValue, const char* pSuffix)
{
    FbxString lString;

    lString = pHeader;
    lString += pValue ? "true" : "false";
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void DisplayInt(const char* pHeader, int pValue, const char* pSuffix)
{
    FbxString lString;

    lString = pHeader;
    lString += pValue;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}

void DisplayDouble(const char* pHeader, double pValue, const char* pSuffix)
{
    FbxString lString;
    FbxString lFloatValue = (float)pValue;

    lFloatValue = pValue <= -HUGE_VAL ? "-INFINITY" : lFloatValue.Buffer();
    lFloatValue = pValue >= HUGE_VAL ? "INFINITY" : lFloatValue.Buffer();

    lString = pHeader;
    lString += lFloatValue;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void Display2DVector(const char* pHeader, FbxVector2 pValue, const char* pSuffix)
{
    FbxString lString;
    FbxString lFloatValue1 = (float)pValue[0];
    FbxString lFloatValue2 = (float)pValue[1];

    lFloatValue1 = pValue[0] <= -HUGE_VAL ? "-INFINITY" : lFloatValue1.Buffer();
    lFloatValue1 = pValue[0] >= HUGE_VAL ? "INFINITY" : lFloatValue1.Buffer();
    lFloatValue2 = pValue[1] <= -HUGE_VAL ? "-INFINITY" : lFloatValue2.Buffer();
    lFloatValue2 = pValue[1] >= HUGE_VAL ? "INFINITY" : lFloatValue2.Buffer();

    lString = pHeader;
    lString += lFloatValue1;
    lString += ", ";
    lString += lFloatValue2;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void Display3DVector(const char* pHeader, FbxVector4 pValue, const char* pSuffix)
{
    FbxString lString;
    FbxString lFloatValue1 = (float)pValue[0];
    FbxString lFloatValue2 = (float)pValue[1];
    FbxString lFloatValue3 = (float)pValue[2];

    lFloatValue1 = pValue[0] <= -HUGE_VAL ? "-INFINITY" : lFloatValue1.Buffer();
    lFloatValue1 = pValue[0] >= HUGE_VAL ? "INFINITY" : lFloatValue1.Buffer();
    lFloatValue2 = pValue[1] <= -HUGE_VAL ? "-INFINITY" : lFloatValue2.Buffer();
    lFloatValue2 = pValue[1] >= HUGE_VAL ? "INFINITY" : lFloatValue2.Buffer();
    lFloatValue3 = pValue[2] <= -HUGE_VAL ? "-INFINITY" : lFloatValue3.Buffer();
    lFloatValue3 = pValue[2] >= HUGE_VAL ? "INFINITY" : lFloatValue3.Buffer();

    lString = pHeader;
    lString += lFloatValue1;
    lString += ", ";
    lString += lFloatValue2;
    lString += ", ";
    lString += lFloatValue3;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}

void Display4DVector(const char* pHeader, FbxVector4 pValue, const char* pSuffix)
{
    FbxString lString;
    FbxString lFloatValue1 = (float)pValue[0];
    FbxString lFloatValue2 = (float)pValue[1];
    FbxString lFloatValue3 = (float)pValue[2];
    FbxString lFloatValue4 = (float)pValue[3];

    lFloatValue1 = pValue[0] <= -HUGE_VAL ? "-INFINITY" : lFloatValue1.Buffer();
    lFloatValue1 = pValue[0] >= HUGE_VAL ? "INFINITY" : lFloatValue1.Buffer();
    lFloatValue2 = pValue[1] <= -HUGE_VAL ? "-INFINITY" : lFloatValue2.Buffer();
    lFloatValue2 = pValue[1] >= HUGE_VAL ? "INFINITY" : lFloatValue2.Buffer();
    lFloatValue3 = pValue[2] <= -HUGE_VAL ? "-INFINITY" : lFloatValue3.Buffer();
    lFloatValue3 = pValue[2] >= HUGE_VAL ? "INFINITY" : lFloatValue3.Buffer();
    lFloatValue4 = pValue[3] <= -HUGE_VAL ? "-INFINITY" : lFloatValue4.Buffer();
    lFloatValue4 = pValue[3] >= HUGE_VAL ? "INFINITY" : lFloatValue4.Buffer();

    lString = pHeader;
    lString += lFloatValue1;
    lString += ", ";
    lString += lFloatValue2;
    lString += ", ";
    lString += lFloatValue3;
    lString += ", ";
    lString += lFloatValue4;
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void DisplayColor(const char* pHeader, FbxPropertyT<FbxDouble3> pValue, const char* pSuffix)

{
    FbxString lString;

    lString = pHeader;
    //lString += (float) pValue.mRed;
    //lString += (double)pValue.GetArrayItem(0);
    lString += " (red), ";
    //lString += (float) pValue.mGreen;
    //lString += (double)pValue.GetArrayItem(1);
    lString += " (green), ";
    //lString += (float) pValue.mBlue;
    //lString += (double)pValue.GetArrayItem(2);
    lString += " (blue)";
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}


void DisplayColor(const char* pHeader, FbxColor pValue, const char* pSuffix)
{
    FbxString lString;

    lString = pHeader;
    lString += (float)pValue.mRed;

    lString += " (red), ";
    lString += (float)pValue.mGreen;

    lString += " (green), ";
    lString += (float)pValue.mBlue;

    lString += " (blue)";
    lString += pSuffix;
    lString += "\n";
    Verbose(lString);
}

void InitializeSdkObjects(FbxManager*& pManager, FbxScene*& pScene)
{
    //The first thing to do is to create the FBX Manager which is the object allocator for almost all the classes in the SDK
    pManager = FbxManager::Create();
    if( !pManager )
    {
        DisplayString("Error: Unable to create FBX Manager!\n");
        exit(1);
    }
	else DisplayString("Autodesk FBX SDK version %s\n", pManager->GetVersion());

	//Create an IOSettings object. This object holds all import/export settings.
	FbxIOSettings* ios = FbxIOSettings::Create(pManager, IOSROOT);
	pManager->SetIOSettings(ios);

	//Load plugins from the executable directory (optional)
	FbxString lPath = FbxGetApplicationDirectory();
	pManager->LoadPluginsDirectory(lPath.Buffer());

    //Create an FBX scene. This object holds most objects imported/exported from/to files.
    pScene = FbxScene::Create(pManager, "My Scene");
	if( !pScene )
    {
        DisplayString("Error: Unable to create FBX scene!\n");
        exit(1);
    }
}

void DestroySdkObjects(FbxManager* pManager, bool pExitStatus)
{
    //Delete the FBX Manager. All the objects that have been allocated using the FBX Manager and that haven't been explicitly destroyed are also automatically destroyed.
    if( pManager ) pManager->Destroy();
	if( pExitStatus ) DisplayString("Program Success!\n");
}


bool SaveScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename, int pFileFormat, bool pEmbedMedia)
{
    int lMajor, lMinor, lRevision;
    bool lStatus = true;

    // Create an exporter.
    FbxExporter* lExporter = FbxExporter::Create(pManager, "");

    if( pFileFormat < 0 || pFileFormat >= pManager->GetIOPluginRegistry()->GetWriterFormatCount() )
    {
        // Write in fall back format in less no ASCII format found
        pFileFormat = pManager->GetIOPluginRegistry()->GetNativeWriterFormat();

        //Try to export in ASCII if possible
        int lFormatIndex, lFormatCount = pManager->GetIOPluginRegistry()->GetWriterFormatCount();

        for (lFormatIndex=0; lFormatIndex<lFormatCount; lFormatIndex++)
        {
            if (pManager->GetIOPluginRegistry()->WriterIsFBX(lFormatIndex))
            {
                FbxString lDesc =pManager->GetIOPluginRegistry()->GetWriterFormatDescription(lFormatIndex);
                const char *lASCII = "ascii";
                if (lDesc.Find(lASCII)>=0)
                {
                    pFileFormat = lFormatIndex;
                    break;
                }
            }
        } 
    }

    // Set the export states. By default, the export states are always set to 
    // true except for the option eEXPORT_TEXTURE_AS_EMBEDDED. The code below 
    // shows how to change these states.
    IOS_REF.SetBoolProp(EXP_FBX_MATERIAL,        true);
    IOS_REF.SetBoolProp(EXP_FBX_TEXTURE,         true);
    IOS_REF.SetBoolProp(EXP_FBX_EMBEDDED,        pEmbedMedia);
    IOS_REF.SetBoolProp(EXP_FBX_SHAPE,           true);
    IOS_REF.SetBoolProp(EXP_FBX_GOBO,            true);
    IOS_REF.SetBoolProp(EXP_FBX_ANIMATION,       true);
    IOS_REF.SetBoolProp(EXP_FBX_GLOBAL_SETTINGS, true);

    // Initialize the exporter by providing a filename.
    if(lExporter->Initialize(pFilename, pFileFormat, pManager->GetIOSettings()) == false)
    {
        DisplayString("Call to FbxExporter::Initialize() failed.\n");
        DisplayString("Error returned: \n\n", lExporter->GetStatus().GetErrorString());
        return false;
    }

    FbxManager::GetFileFormatVersion(lMajor, lMinor, lRevision);
    DisplayVersion("FBX file format version \n\n", lMajor, lMinor, lRevision);

    // Export the scene.
    lStatus = lExporter->Export(pScene); 

    // Destroy the exporter.
    lExporter->Destroy();
    return lStatus;
}

bool LoadScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename)
{
    int lFileMajor, lFileMinor, lFileRevision;
    int lSDKMajor,  lSDKMinor,  lSDKRevision;
    //int lFileFormat = -1;
    int lAnimStackCount;
    bool lStatus;
    char lPassword[1024];

    // Get the file version number generate by the FBX SDK.
    FbxManager::GetFileFormatVersion(lSDKMajor, lSDKMinor, lSDKRevision);

    // Create an importer.
    FbxImporter* lImporter = FbxImporter::Create(pManager,"");

    // Initialize the importer by providing a filename.
    const bool lImportStatus = lImporter->Initialize(pFilename, -1, pManager->GetIOSettings());
    lImporter->GetFileVersion(lFileMajor, lFileMinor, lFileRevision);

    if( !lImportStatus )
    {
        FbxString error = lImporter->GetStatus().GetErrorString();
        DisplayString("Call to FbxImporter::Initialize() failed.\n");
        DisplayString("Error returned: \n\n", error.Buffer());

        if (lImporter->GetStatus().GetCode() == FbxStatus::eInvalidFileVersion)
        {
            DisplayVersion("FBX file format version for this FBX SDK is \n", lSDKMajor, lSDKMinor, lSDKRevision);
            DisplayVersion("FBX file format version for file is \n\n", lFileMajor, lFileMinor, lFileRevision);
        }

        return false;
    }

    DisplayVersion("FBX file format version for this FBX SDK is \n", lSDKMajor, lSDKMinor, lSDKRevision);

    if (lImporter->IsFBX())
    {
        DisplayVersion("FBX file format version for file is \n\n", lFileMajor, lFileMinor, lFileRevision);

        // From this point, it is possible to access animation stack information without
        // the expense of loading the entire file.

        DisplayString("Animation Stack Information\n");

        lAnimStackCount = lImporter->GetAnimStackCount();

        DisplayInt("    Number of Animation Stacks: \n", lAnimStackCount);
        DisplayString("    Current Animation Stack: \n", lImporter->GetActiveAnimStackName().Buffer());
        DisplayString("\n");

        for(int i = 0; i < lAnimStackCount; i++)
        {
            FbxTakeInfo* lTakeInfo = lImporter->GetTakeInfo(i);

            DisplayInt("    Animation Stack ", i);
            DisplayString("         Name: ", lTakeInfo->mName.Buffer());
            DisplayString("         Description: ", lTakeInfo->mDescription.Buffer());

            // Change the value of the import name if the animation stack should be imported 
            // under a different name.
            DisplayString("         Import Name: ", lTakeInfo->mImportName.Buffer());

            // Set the value of the import state to false if the animation stack should be not
            // be imported. 
            DisplayString("         Import State: ", lTakeInfo->mSelect ? "true" : "false");
            DisplayString("\n");
        }

        // Set the import states. By default, the import states are always set to 
        // true. The code below shows how to change these states.
        IOS_REF.SetBoolProp(IMP_FBX_MATERIAL,        true);
        IOS_REF.SetBoolProp(IMP_FBX_TEXTURE,         true);
        IOS_REF.SetBoolProp(IMP_FBX_LINK,            true);
        IOS_REF.SetBoolProp(IMP_FBX_SHAPE,           true);
        IOS_REF.SetBoolProp(IMP_FBX_GOBO,            true);
        IOS_REF.SetBoolProp(IMP_FBX_ANIMATION,       true);
        IOS_REF.SetBoolProp(IMP_FBX_GLOBAL_SETTINGS, true);
    }

    // Import the scene.
    lStatus = lImporter->Import(pScene);
	if (lStatus == true)
	{
		// Check the scene integrity!
		FbxStatus status;
		FbxArray< FbxString*> details;
		FbxSceneCheckUtility sceneCheck(FbxCast<FbxScene>(pScene), &status, &details);
		lStatus = sceneCheck.Validate(FbxSceneCheckUtility::eCkeckData);
		bool lNotify = (!lStatus && details.GetCount() > 0) || (lImporter->GetStatus().GetCode() != FbxStatus::eSuccess);
		if (lNotify)
		{
            DisplayString("\n");
            DisplayString("********************************************************************************\n");
			if (details.GetCount())
			{
                DisplayString("Scene integrity verification failed with the following errors:\n");
				for (int i = 0; i < details.GetCount(); i++)
                    DisplayString("   %s\n", details[i]->Buffer());
				
				FbxArrayDelete<FbxString*>(details);
			}
             
			if (lImporter->GetStatus().GetCode() != FbxStatus::eSuccess)
			{
                DisplayString("\n");
                DisplayString("WARNING:\n");
                DisplayString("   The importer was able to read the file but with errors.\n");
                DisplayString("   Loaded scene may be incomplete.\n\n");
                DisplayString("   Last error message: ", lImporter->GetStatus().GetErrorString());
			}
            DisplayString("********************************************************************************\n");
            DisplayString("\n");
		}
	}

    if(lStatus == false && lImporter->GetStatus().GetCode() == FbxStatus::ePasswordError)
    {
        DisplayString("Please enter password: ");

        lPassword[0] = '\0';

        FBXSDK_CRT_SECURE_NO_WARNING_BEGIN
        scanf("%s", lPassword);
        FBXSDK_CRT_SECURE_NO_WARNING_END

        FbxString lString(lPassword);

        IOS_REF.SetStringProp(IMP_FBX_PASSWORD,      lString);
        IOS_REF.SetBoolProp(IMP_FBX_PASSWORD_ENABLE, true);

        lStatus = lImporter->Import(pScene);

        if(lStatus == false && lImporter->GetStatus().GetCode() == FbxStatus::ePasswordError)
        {
            DisplayString("\nPassword is wrong, import aborted.\n");
        }
    }

    // Destroy the importer.
    lImporter->Destroy();

    return lStatus;
}
