#ifndef _MeshFBXIO_h_
#define _MeshFBXIO_h_

#include "MeshIO.h"
#include "FBX.h"

class MeshFBXIO : public MeshIO<Mesh>
{
public:
	MeshFBXIO()
		: MeshIO<Mesh>()
	{
	}

	~MeshFBXIO()
	{
	}

	bool OnLoad(Mesh& mesh, const std::string& path) override
	{
		FbxManager* lSdkManager = NULL;
		FbxScene* lScene = NULL;
		bool lResult;

		// Prepare the FBX SDK.
		InitializeSdkObjects(lSdkManager, lScene);
		// Load the scene.

		// The example can take a FBX file as an argument.
		FbxString lFilePath(path.c_str());

		lResult = LoadScene(lSdkManager, lScene, lFilePath.Buffer());
		if (lResult == false)
		{
			// Destroy all objects created by the FBX SDK.
			DestroySdkObjects(lSdkManager, lResult);

			Debug("\n\nAn error occurred while loading the scene...");
			return false;
		}
		else
		{
			// Display the scene.
			DisplayMetaData(lScene);

			Debug("\n\n---------------------\nGlobal Light Settings\n---------------------\n\n");
			DisplayGlobalLightSettings(&lScene->GetGlobalSettings());

			Debug("\n\n----------------------\nGlobal Camera Settings\n----------------------\n\n");
			DisplayGlobalCameraSettings(&lScene->GetGlobalSettings());

			Debug("\n\n--------------------\nGlobal Time Settings\n--------------------\n\n");
			DisplayGlobalTimeSettings(&lScene->GetGlobalSettings());

			Debug("\n\n---------\nHierarchy\n---------\n\n");
			DisplayHierarchy(lScene);

			Debug("\n\n------------\nNode Content\n------------\n\n");
			DisplayContent(lScene);

			if (!LoadMeshScene(mesh, lScene))
				return false;

			Debug("\n\n----\nPose\n----\n\n");
			DisplayPose(lScene);

			Debug("\n\n---------\nAnimation\n---------\n\n");
			DisplayAnimation(lScene);

			Debug("\n\n---------\nGeneric Information\n---------\n\n");
			DisplayGenericInfo(lScene);

			// Destroy all objects created by the FBX SDK.
			DestroySdkObjects(lSdkManager, lResult);

			return true;
		}

	}

	bool OnSave(const Mesh& mesh, const std::string& path) override
	{
		return true;
	}
private:
	FbxAMatrix GetGeometryTransformation(FbxNode* inNode)
	{
		if (!inNode)
		{
			throw std::exception("Null for mesh geometry");
		}

		const FbxVector4 lT = inNode->GetGeometricTranslation(FbxNode::eSourcePivot);
		const FbxVector4 lR = inNode->GetGeometricRotation(FbxNode::eSourcePivot);
		const FbxVector4 lS = inNode->GetGeometricScaling(FbxNode::eSourcePivot);

		return FbxAMatrix(lT, lR, lS);
	}

	bool LoadMeshScene(Mesh& mesh, FbxScene* pScene)
	{
		int i;
		FbxNode* rootNode = pScene->GetRootNode();

		if (!rootNode)
			return false;

		for (i = 0; i < rootNode->GetChildCount(); i++)
		{
			if (!LoadMeshNode(mesh, rootNode->GetChild(i)))
				return false;
		}

		return true;
	}

	bool LoadMeshNode(Mesh& mesh, FbxNode* pNode)
	{
		FbxNodeAttribute::EType lAttributeType;
		int i;

		if (pNode->GetNodeAttribute() == NULL)
		{
			Debug("NULL Node Attribute\n\n");
		}
		else
		{
			lAttributeType = (pNode->GetNodeAttribute()->GetAttributeType());

			switch (lAttributeType)
			{
			default:
				break;
			case FbxNodeAttribute::eMesh:
				if (!LoadMesh(mesh, pNode))
					return false;
				break;
			}
		}

		for (i = 0; i < pNode->GetChildCount(); i++)
		{
			if (!LoadMeshNode(mesh, pNode->GetChild(i)))
				return false;
		}

		return true;
	}

	bool LoadMesh(Mesh& mesh, FbxNode* pNode)
	{
		FbxMesh* lMesh = (FbxMesh*)pNode->GetNodeAttribute();

		//Debug("Mesh Name: ", (char*)pNode->GetName());
		//DisplayMetaDataConnections(lMesh);
		LoadVertices(mesh, pNode, lMesh);
		LoadPolygons(mesh, lMesh);
		//DisplayMaterialMapping(lMesh);
		//DisplayMaterial(lMesh);
		//DisplayTexture(lMesh);
		//DisplayMaterialConnections(lMesh);
		//DisplayLink(lMesh);
		//DisplayShape(lMesh);

		//DisplayCache(lMesh);

		return true;
	}

	void LoadVertices(Mesh& mesh, FbxNode* pNode, FbxMesh* pMesh)
	{
		FbxAMatrix geometryTransform = GetGeometryTransformation(pNode);
		FbxAMatrix nodeTransform = pNode->EvaluateGlobalTransform(0);

		FbxAMatrix posTransform = nodeTransform * geometryTransform;
		FbxAMatrix dirTransform = posTransform;
		dirTransform.SetT(FbxVector4(0, 0, 0, 1));

		unsigned int numOfDeformers = pMesh->GetDeformerCount();
		for (unsigned int deformerIndex = 0; deformerIndex < numOfDeformers; ++deformerIndex)
		{
			FbxSkin* currSkin = reinterpret_cast<FbxSkin*>(pMesh->GetDeformer(deformerIndex, FbxDeformer::eSkin));
			if (!currSkin) { continue; }
		}

		FbxVector4* positions = pMesh->GetControlPoints();
		mesh.positions.resize(pMesh->GetControlPointsCount());
		for (int i = 0; i < mesh.positions.size(); i++)
		{
			FbxVector4 position = posTransform.MultT(positions[i]);
			//FbxVector4 position = positions[i];
			mesh.positions[i] = Vector3((float)position[0], (float)position[1], (float)position[2]);
		}

		//////////////////////////////////////////////////////////
		// Color data
		for (int l = 0; l < pMesh->GetElementVertexColorCount() && l < MAX_COLOR_SET_COUNT; l++)
		{
			FbxGeometryElementVertexColor* leVtxc = pMesh->GetElementVertexColor(l);
			auto& colors = leVtxc->GetDirectArray();

			mesh.colors[l].resize(leVtxc->GetDirectArray().GetCount());
			for (int i = 0; i < mesh.colors[l].size(); i++)
			{
				auto color = colors.GetAt(i);
				mesh.colors[l][i] = ColorRGBA((float)color[0], (float)color[1], (float)color[2], (float)color[3]);
			}
		}

		//////////////////////////////////////////////////////////
		// UV data
		for (int l = 0; l < pMesh->GetElementUVCount() && l < MAX_UV_SET_COUNT; ++l)
		{
			FbxGeometryElementUV* leUV = pMesh->GetElementUV(l);
			auto& uvs = leUV->GetDirectArray();

			mesh.uvs[l].resize(leUV->GetDirectArray().GetCount());
			for (int i = 0; i < mesh.uvs[l].size(); i++)
			{
				auto uv = uvs.GetAt(i);
				mesh.uvs[l][i] = Vector2((float)uv[0], (float)uv[1]);
			}
		}

		//////////////////////////////////////////////////////////
		// Normal data
		for (int l = 0; l < pMesh->GetElementNormalCount() && l < MAX_NORMAL_SET_COUNT; ++l)
		{
			FbxGeometryElementNormal* leNormal = pMesh->GetElementNormal(l);
			auto& normals = leNormal->GetDirectArray();

			mesh.normals[l].resize(leNormal->GetDirectArray().GetCount());
			for (int i = 0; i < mesh.normals[l].size(); i++)
			{
				auto normal = dirTransform.MultT(normals.GetAt(i));
				//normal = normals.GetAt(i);
				mesh.normals[l][i] = Vector3((float)normal[0], (float)normal[1], (float)normal[2]);
			}
		}

		//////////////////////////////////////////////////////////
		// Tangent data
		for (int l = 0; l < pMesh->GetElementTangentCount() && l < MAX_TANGENT_SET_COUNT; ++l)
		{
			FbxGeometryElementTangent* leTangent = pMesh->GetElementTangent(l);
			auto& tangents = leTangent->GetDirectArray();

			mesh.tangents[l].resize(leTangent->GetDirectArray().GetCount());
			for (int i = 0; i < mesh.tangents[l].size(); i++)
			{
				//auto tangent = dirTransform.MultT(tangents.GetAt(i));
				auto tangent = tangents.GetAt(i);
				mesh.tangents[l][i] = Vector3((float)tangent[0], (float)tangent[1], (float)tangent[2]);
			}
		}

		//////////////////////////////////////////////////////////
		// Binromal data
		for (int l = 0; l < pMesh->GetElementBinormalCount() && l < MAX_BINORMAL_SET_COUNT; ++l)
		{
			FbxGeometryElementBinormal* leBinormal = pMesh->GetElementBinormal(l);
			auto& binormals = leBinormal->GetDirectArray();

			mesh.binormals[l].resize(leBinormal->GetDirectArray().GetCount());
			for (int i = 0; i < mesh.binormals[l].size(); i++)
			{
				//auto binormal = dirTransform.MultT(binormals.GetAt(i));
				auto binormal = binormals.GetAt(i);
				mesh.binormals[l][i] = Vector3((float)binormal[0], (float)binormal[1], (float)binormal[2]);
			}
		}
	}

	void LoadPolygons(Mesh& mesh, FbxMesh* pMesh)
	{
		Debug("    Polygons");

		int vertexId = 0;
		for (int polygonIdx = 0; polygonIdx < pMesh->GetPolygonCount(); polygonIdx++)
		{
			DisplayInt("        Polygon ", polygonIdx);

			//////////////////////////////////////////////////////////
			// poly group
			for (int l = 0; l < pMesh->GetElementPolygonGroupCount(); l++)
			{
				FbxGeometryElementPolygonGroup* lePolgrp = pMesh->GetElementPolygonGroup(l);
				switch (lePolgrp->GetMappingMode())
				{
				case FbxGeometryElement::eByPolygon:
					if (lePolgrp->GetReferenceMode() == FbxGeometryElement::eIndex)
					{
						int polyGroupId = lePolgrp->GetIndexArray().GetAt(polygonIdx);
						DisplayInt("        Assigned to group: ", polyGroupId);
						break;
					}
				default:
					// any other mapping modes don't make sense
					Debug("        \"unsupported group assignment\"");
					break;
				}
			}

			std::vector<Mesh::Index> vertexIndices(pMesh->GetPolygonSize(polygonIdx));

			for (int j = 0; j < pMesh->GetPolygonSize(polygonIdx); j++)
			{
				//////////////////////////////////////////////////////////
				// vertex Indices 
				FbxVector4* lControlPoints = pMesh->GetControlPoints();
				int lControlPointIndex = pMesh->GetPolygonVertex(polygonIdx, j);
				{
					int id = -1;
					if (lControlPointIndex < 0)
					{
						Debug("            Coordinates: Invalid index found!");
						continue;
					}
					else
					{
						id = lControlPointIndex;
						Display3DVector("            Coordinates: ", lControlPoints[id]);
					}
					vertexIndices[j].vIdx = id;
				}

				//////////////////////////////////////////////////////////
				// Color Indices
				for (int l = 0; l < pMesh->GetElementVertexColorCount() && l < MAX_COLOR_SET_COUNT; l++)
				{
					FbxGeometryElementVertexColor* leVtxc = pMesh->GetElementVertexColor(l);

					int id = -1;

					switch (leVtxc->GetMappingMode())
					{
					default:
						break;
					case FbxGeometryElement::eByControlPoint:
						switch (leVtxc->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						{
							id = lControlPointIndex;
							DisplayColor("            Color vertex: ", leVtxc->GetDirectArray().GetAt(id));
						}
						break;
						case FbxGeometryElement::eIndexToDirect:
						{
							id = leVtxc->GetIndexArray().GetAt(lControlPointIndex);
							DisplayColor("            Color vertex: ", leVtxc->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
						break;

					case FbxGeometryElement::eByPolygonVertex:
					{
						switch (leVtxc->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						{
							id = vertexId;
							DisplayColor("            Color vertex: ", leVtxc->GetDirectArray().GetAt(id));
						}
						break;
						case FbxGeometryElement::eIndexToDirect:
						{
							id = leVtxc->GetIndexArray().GetAt(vertexId);
							DisplayColor("            Color vertex: ", leVtxc->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
					}
					break;

					case FbxGeometryElement::eByPolygon: // doesn't make much sense for UVs
					case FbxGeometryElement::eAllSame:   // doesn't make much sense for UVs
					case FbxGeometryElement::eNone:       // doesn't make much sense for UVs
						break;
					}

					vertexIndices[j].cIdx[l] = id;
				}


				//////////////////////////////////////////////////////////
				// UV Indices
				for (int l = 0; l < pMesh->GetElementUVCount() && l < MAX_UV_SET_COUNT; ++l)
				{
					FbxGeometryElementUV* leUV = pMesh->GetElementUV(l);

					int id = -1;

					switch (leUV->GetMappingMode())
					{
					default:
						break;
					case FbxGeometryElement::eByControlPoint:
						switch (leUV->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						{
							id = lControlPointIndex;
							Display2DVector("            Texture UV: ", leUV->GetDirectArray().GetAt(id));
						}
						break;
						case FbxGeometryElement::eIndexToDirect:
						{
							id = leUV->GetIndexArray().GetAt(lControlPointIndex);
							Display2DVector("            Texture UV: ", leUV->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
						break;

					case FbxGeometryElement::eByPolygonVertex:
					{
						int lTextureUVIndex = pMesh->GetTextureUVIndex(polygonIdx, j);
						switch (leUV->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						case FbxGeometryElement::eIndexToDirect:
						{
							id = lTextureUVIndex;
							Display2DVector("            Texture UV: ", leUV->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
					}
					break;

					case FbxGeometryElement::eByPolygon: // doesn't make much sense for UVs
					case FbxGeometryElement::eAllSame:   // doesn't make much sense for UVs
					case FbxGeometryElement::eNone:       // doesn't make much sense for UVs
						break;
					}

					vertexIndices[j].uvIdx[l] = id;
				}


				//////////////////////////////////////////////////////////
				// Normal Indices
				for (int l = 0; l < pMesh->GetElementNormalCount() && l < MAX_NORMAL_SET_COUNT; ++l)
				{
					FbxGeometryElementNormal* leNormal = pMesh->GetElementNormal(l);

					int id = -1;

					if (leNormal->GetMappingMode() == FbxGeometryElement::eByPolygonVertex)
					{
						switch (leNormal->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						{
							id = vertexId;
							Display3DVector("            Normal: ", leNormal->GetDirectArray().GetAt(id));
						}
						break;
						case FbxGeometryElement::eIndexToDirect:
						{
							id = leNormal->GetIndexArray().GetAt(vertexId);
							Display3DVector("            Normal: ", leNormal->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
					}

					vertexIndices[j].nIdx[l] = id;
				}


				//////////////////////////////////////////////////////////
				// Tangent Indices
				for (int l = 0; l < pMesh->GetElementTangentCount() && l < MAX_TANGENT_SET_COUNT; ++l)
				{
					FbxGeometryElementTangent* leTangent = pMesh->GetElementTangent(l);

					int id = -1;

					if (leTangent->GetMappingMode() == FbxGeometryElement::eByPolygonVertex)
					{
						switch (leTangent->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						{
							id = vertexId;
							Display3DVector("            Tangent: ", leTangent->GetDirectArray().GetAt(id));
						}
						break;
						case FbxGeometryElement::eIndexToDirect:
						{
							id = leTangent->GetIndexArray().GetAt(vertexId);
							Display3DVector("            Tangent: ", leTangent->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
					}

					vertexIndices[j].tIdx[l] = id;
				}

				//////////////////////////////////////////////////////////
				// Binromal Indices
				for (int l = 0; l < pMesh->GetElementBinormalCount() && l < MAX_BINORMAL_SET_COUNT; ++l)
				{
					FbxGeometryElementBinormal* leBinormal = pMesh->GetElementBinormal(l);

					int id = -1;

					if (leBinormal->GetMappingMode() == FbxGeometryElement::eByPolygonVertex)
					{
						switch (leBinormal->GetReferenceMode())
						{
						case FbxGeometryElement::eDirect:
						{
							id = vertexId;
							Display3DVector("            Binormal: ", leBinormal->GetDirectArray().GetAt(id));
						}
						break;
						case FbxGeometryElement::eIndexToDirect:
						{
							id = leBinormal->GetIndexArray().GetAt(vertexId);
							Display3DVector("            Binormal: ", leBinormal->GetDirectArray().GetAt(id));
						}
						break;
						default:
							break; // other reference modes not shown here!
						}
					}

					vertexIndices[j].bIdx[l] = id;
				}

				vertexId++;
			} // for polygonSize

			//Assert(vertexIndices.size() == 3);

			for (int j = 0; j < vertexIndices.size() - 2; j++)
			{
				mesh.indices.push_back(vertexIndices[0]);
				mesh.indices.push_back(vertexIndices[j + 1]);
				mesh.indices.push_back(vertexIndices[j + 2]);
			}
		} // for polygonCount
	}

	/////////////////////////////////////////////////////////////////
	void DisplayContent(FbxScene* pScene)
	{
		int i;
		FbxNode* lNode = pScene->GetRootNode();

		if (lNode)
		{
			for (i = 0; i < lNode->GetChildCount(); i++)
			{
				DisplayContent(lNode->GetChild(i));
			}
		}
	}

	void DisplayContent(FbxNode* pNode)
	{
		FbxNodeAttribute::EType lAttributeType;
		int i;

		if (pNode->GetNodeAttribute() == NULL)
		{
			Debug("NULL Node Attribute\n\n");
		}
		else
		{
			lAttributeType = (pNode->GetNodeAttribute()->GetAttributeType());

			switch (lAttributeType)
			{
			default:
				break;
			case FbxNodeAttribute::eMarker:
				DisplayMarker(pNode);
				break;

			case FbxNodeAttribute::eSkeleton:
				DisplaySkeleton(pNode);
				break;

			case FbxNodeAttribute::eMesh:
				DisplayMesh(pNode);
				break;

			case FbxNodeAttribute::eNurbs:
				DisplayNurb(pNode);
				break;

			case FbxNodeAttribute::ePatch:
				DisplayPatch(pNode);
				break;

			case FbxNodeAttribute::eCamera:
				DisplayCamera(pNode);
				break;

			case FbxNodeAttribute::eLight:
				DisplayLight(pNode);
				break;

			case FbxNodeAttribute::eLODGroup:
				DisplayLodGroup(pNode);
				break;
			}
		}

		DisplayUserProperties(pNode);
		DisplayTarget(pNode);
		DisplayPivotsAndLimits(pNode);
		DisplayTransformPropagation(pNode);
		DisplayGeometricTransform(pNode);

		for (i = 0; i < pNode->GetChildCount(); i++)
		{
			DisplayContent(pNode->GetChild(i));
		}
	}


	void DisplayTarget(FbxNode* pNode)
	{
		if (pNode->GetTarget() != NULL)
		{
			Debug("    Target Name: ", (char*)pNode->GetTarget()->GetName());
		}
	}

	void DisplayTransformPropagation(FbxNode* pNode)
	{
		Verbose("    Transformation Propagation\n");

		// 
		// Rotation Space
		//
		EFbxRotationOrder lRotationOrder;
		pNode->GetRotationOrder(FbxNode::eSourcePivot, lRotationOrder);

		Verbose("        Rotation Space: ");

		switch (lRotationOrder)
		{
		case eEulerXYZ:
			Verbose("Euler XYZ\n");
			break;
		case eEulerXZY:
			Verbose("Euler XZY\n");
			break;
		case eEulerYZX:
			Verbose("Euler YZX\n");
			break;
		case eEulerYXZ:
			Verbose("Euler YXZ\n");
			break;
		case eEulerZXY:
			Verbose("Euler ZXY\n");
			break;
		case eEulerZYX:
			Verbose("Euler ZYX\n");
			break;
		case eSphericXYZ:
			Verbose("Spheric XYZ\n");
			break;
		}

		//
		// Use the Rotation space only for the limits
		// (keep using eEulerXYZ for the rest)
		//
		FbxString lString;
		lString = "        Use the Rotation Space for Limit specification only: %s\n";
		lString += pNode->GetUseRotationSpaceForLimitOnly(FbxNode::eSourcePivot) ? "Yes" : "No";
		lString += "\n";
		Verbose(lString);

		//
		// Inherit Type
		//
		FbxTransform::EInheritType lInheritType;
		pNode->GetTransformationInheritType(lInheritType);

		Verbose("        Transformation Inheritance: ");

		switch (lInheritType)
		{
		case FbxTransform::eInheritRrSs:
			Verbose("RrSs\n");
			break;
		case FbxTransform::eInheritRSrs:
			Verbose("RSrs\n");
			break;
		case FbxTransform::eInheritRrs:
			Verbose("Rrs\n");
			break;
		}
	}

	void DisplayGeometricTransform(FbxNode* pNode)
	{
		FbxVector4 lTmpVector;

		Verbose("    Geometric Transformations\n");

		//
		// Translation
		//
		lTmpVector = pNode->GetGeometricTranslation(FbxNode::eSourcePivot);
		Display3DVector("        Translation: %f %f %f\n", lTmpVector);

		//
		// Rotation
		//
		lTmpVector = pNode->GetGeometricRotation(FbxNode::eSourcePivot);
		Display3DVector("        Rotation:    %f %f %f\n", lTmpVector);

		//
		// Scaling
		//
		lTmpVector = pNode->GetGeometricScaling(FbxNode::eSourcePivot);
		Display3DVector("        Scaling:     %f %f %f\n", lTmpVector);
	}


	void DisplayMetaData(FbxScene* pScene)
	{
		FbxDocumentInfo* sceneInfo = pScene->GetSceneInfo();
		if (sceneInfo)
		{
			Debug("\n\n--------------------\nMeta-Data\n--------------------\n\n");
			Debug("    Title: %s\n", sceneInfo->mTitle.Buffer());
			Debug("    Subject: %s\n", sceneInfo->mSubject.Buffer());
			Debug("    Author: %s\n", sceneInfo->mAuthor.Buffer());
			Debug("    Keywords: %s\n", sceneInfo->mKeywords.Buffer());
			Debug("    Revision: %s\n", sceneInfo->mRevision.Buffer());
			Debug("    Comment: %s\n", sceneInfo->mComment.Buffer());

			FbxThumbnail* thumbnail = sceneInfo->GetSceneThumbnail();
			if (thumbnail)
			{
				Debug("    Thumbnail:\n");

				switch (thumbnail->GetDataFormat())
				{
				case FbxThumbnail::eRGB_24:
					Debug("        Format: RGB\n");
					break;
				case FbxThumbnail::eRGBA_32:
					Debug("        Format: RGBA\n");
					break;
				}

				switch (thumbnail->GetSize())
				{
				default:
					break;
				case FbxThumbnail::eNotSet:
					DisplayInt("        Size: no dimensions specified (%ld bytes)\n", thumbnail->GetSizeInBytes());
					break;
				case FbxThumbnail::e64x64:
					DisplayInt("        Size: 64 x 64 pixels (%ld bytes)\n", thumbnail->GetSizeInBytes());
					break;
				case FbxThumbnail::e128x128:
					DisplayInt("        Size: 128 x 128 pixels (%ld bytes)\n", thumbnail->GetSizeInBytes());
				}
			}
		}
	}
};


#endif