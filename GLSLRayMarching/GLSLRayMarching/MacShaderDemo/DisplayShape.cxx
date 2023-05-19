/****************************************************************************************

   Copyright (C) 2015 Autodesk, Inc.
   All rights reserved.

   Use of this software is subject to the terms of the Autodesk license agreement
   provided at the time of installation or download, or which otherwise accompanies
   this software in either electronic or hard copy form.

****************************************************************************************/
#include "FBX.h"

void DisplayShapeLayerElements(const FbxShape* pShape, const FbxMesh* pMesh);

void DisplayShape(FbxGeometry* pGeometry)
{
	int lBlendShapeCount, lBlendShapeChannelCount, lTargetShapeCount;
	FbxBlendShape* lBlendShape;
	FbxBlendShapeChannel* lBlendShapeChannel;
	FbxShape* lShape;

	lBlendShapeCount = pGeometry->GetDeformerCount(FbxDeformer::eBlendShape);

	for (int lBlendShapeIndex = 0; lBlendShapeIndex < lBlendShapeCount; ++lBlendShapeIndex)
	{
		lBlendShape = (FbxBlendShape*)pGeometry->GetDeformer(lBlendShapeIndex, FbxDeformer::eBlendShape);
		Debug("    BlendShape ", (char *)lBlendShape->GetName());

		lBlendShapeChannelCount = lBlendShape->GetBlendShapeChannelCount();
		for (int lBlendShapeChannelIndex = 0; lBlendShapeChannelIndex < lBlendShapeChannelCount; ++lBlendShapeChannelIndex)
		{
			lBlendShapeChannel = lBlendShape->GetBlendShapeChannel(lBlendShapeChannelIndex);
			Debug("    BlendShapeChannel ", (char *)lBlendShapeChannel->GetName());
			DisplayDouble("    Default Deform Value: ", lBlendShapeChannel->DeformPercent.Get());

			lTargetShapeCount = lBlendShapeChannel->GetTargetShapeCount();
			for (int lTargetShapeIndex = 0; lTargetShapeIndex < lTargetShapeCount; ++lTargetShapeIndex)
			{
				lShape = lBlendShapeChannel->GetTargetShape(lTargetShapeIndex);
				Debug("    TargetShape ", (char *)lShape->GetName());

				if (pGeometry->GetAttributeType() == FbxNodeAttribute::eMesh)
				{
					DisplayShapeLayerElements(lShape, FbxCast<FbxMesh>(pGeometry));
				}
				else
				{
					int j, lControlPointsCount = lShape->GetControlPointsCount();
					FbxVector4* lControlPoints = lShape->GetControlPoints();
					FbxLayerElementArrayTemplate<FbxVector4>* lNormals = NULL;
					bool lStatus = lShape->GetNormals(&lNormals);

					for (j = 0; j < lControlPointsCount; j++)
					{
						DisplayInt("        Control Point ", j);
						Display3DVector("            Coordinates: ", lControlPoints[j]);

						if (lStatus && lNormals && lNormals->GetCount() == lControlPointsCount)
						{
							Display3DVector("            Normal Vector: ", lNormals->GetAt(j));
						}
					}
				}

				Debug("");
			}
		}
	}
}

void DisplayElementData(const FbxString& pHeader, const FbxVector4& pData, int index = -1)
{
    FbxString desc(pHeader);
    if (index != -1)
    {
        FbxString num = FbxString(" [") + index + "]: ";
        desc.FindAndReplace(":", num.Buffer());
    }
    Display3DVector(desc.Buffer(), pData);
}

void DisplayElementData(const FbxString& pHeader, const FbxVector2& pData, int index = -1)
{
    FbxString desc(pHeader);
    if (index != -1)
    {
        FbxString num = FbxString(" [") + index + "]: ";
        desc.FindAndReplace(":", num.Buffer());
    }
	Display2DVector(desc.Buffer(), pData);
}

void DisplayElementData(const FbxString&  pHeader, const FbxColor& pData, int index = -1)
{
    FbxString desc(pHeader);
    if (index != -1)
    {
        FbxString num = FbxString(" [") + index + "]: ";
        desc.FindAndReplace(":", num.Buffer());
    }
	DisplayColor(desc.Buffer(), pData);
}

void FillHeaderBasedOnElementType(FbxLayerElement::EType pComponent, FbxString& pHeader)
{
	switch (pComponent)
	{
	case FbxLayerElement::eNormal:
		pHeader = "        Normal: ";
		break;
	case FbxLayerElement::eBiNormal:
		pHeader = "        BiNormal: ";
		break;
	case FbxLayerElement::eTangent:
		pHeader = "        Tangent: ";
		break;
	case FbxLayerElement::eUV:
		pHeader = "        UV: ";
		break;
	case FbxLayerElement::eVertexColor:
		pHeader = "        Vertex Color: ";
		break;
	default:
		pHeader = "        Unsupported element: ";
		break;
	}
}

template<class T>
void DisplayLayerElement(FbxLayerElement::EType pComponent, const FbxLayer* pShapeLayer, const FbxMesh* pMesh)
{
	const FbxLayerElement* pLayerElement = pShapeLayer->GetLayerElementOfType(pComponent);
	if (pLayerElement)
	{
		FbxLayerElementTemplate<T>* pLayerElementTemplate = ((FbxLayerElementTemplate<T>*) pLayerElement);
		FbxLayerElementArrayTemplate<T>& pLayerElementArray = pLayerElementTemplate->GetDirectArray();		
		FbxString header;
		FillHeaderBasedOnElementType(pComponent, header);
		int lPolygonCount = pMesh->GetPolygonCount();
		int lPolynodeIndex = 0;
		for (int i = 0; i < lPolygonCount; ++i)
		{
			int lPolygonSize = pMesh->GetPolygonSize(i);
			for (int j = 0; j < lPolygonSize; ++j, ++lPolynodeIndex)
			{
				int lControlPointIndex = pMesh->GetPolygonVertex(i, j);
				switch (pLayerElementTemplate->GetMappingMode())
				{
				default:
					break;
				case FbxGeometryElement::eByControlPoint:
				{
					switch (pLayerElementTemplate->GetReferenceMode())
					{
					case FbxGeometryElement::eDirect:
						DisplayElementData(header, pLayerElementArray.GetAt(lControlPointIndex), lControlPointIndex);
						break;
					case FbxGeometryElement::eIndexToDirect:
					{
                        FbxLayerElementArrayTemplate<int>& pLayerElementIndexArray = pLayerElementTemplate->GetIndexArray();
						int id = pLayerElementIndexArray.GetAt(lControlPointIndex);
						if (id > 0) { DisplayElementData(header, pLayerElementArray.GetAt(id), id); }
					}
					break;
					default:
						break; // other reference modes not shown here!
					};
				}
				case FbxGeometryElement::eByPolygonVertex:
				{
					switch (pLayerElementTemplate->GetReferenceMode())
					{
					case FbxGeometryElement::eDirect:
						DisplayElementData(header, pLayerElementArray.GetAt(lPolynodeIndex), lPolynodeIndex);
						break;
					case FbxGeometryElement::eIndexToDirect:
					{
                        FbxLayerElementArrayTemplate<int>& pLayerElementIndexArray = pLayerElementTemplate->GetIndexArray();
						int id = pLayerElementIndexArray.GetAt(lPolynodeIndex);
						if (id > 0) { DisplayElementData(header, pLayerElementArray.GetAt(id), id); }
					}
					break;
					default:
						break; // other reference modes not shown here!
					}
				}
				break;
				}
			}
		}
	}
}

void DisplayShapeLayerElements(const FbxShape* pShape, const FbxMesh* pMesh)
{
    int lShapeControlPointsCount = pShape->GetControlPointsCount();
    int lMeshControlPointsCount = pMesh->GetControlPointsCount();
    bool lValidLayerElementSource = pShape && pMesh && lShapeControlPointsCount && lMeshControlPointsCount;
	if (lValidLayerElementSource)
	{
        if (lShapeControlPointsCount == lMeshControlPointsCount)
        {
            // Display control points that are different from the mesh
            FbxVector4* lShapeControlPoint = pShape->GetControlPoints();
            FbxVector4* lMeshControlPoint = pMesh->GetControlPoints();
            for (int j = 0; j < lShapeControlPointsCount; j++)
            {
                FbxVector4 delta = lShapeControlPoint[j] - lMeshControlPoint[j];
                if (!FbxEqual(delta, FbxZeroVector4))
                {
                    FbxString header("        Control Point: ");
                    DisplayElementData(header, lShapeControlPoint[j], j);
                }
            }
        }

		int lLayerCount = pShape->GetLayerCount();
		for (int i = 0; i < lLayerCount; ++i)
		{
			const FbxLayer *pLayer = pShape->GetLayer(i);
			DisplayLayerElement<FbxVector4>(FbxLayerElement::eNormal, pLayer, pMesh);
			DisplayLayerElement<FbxColor>(FbxLayerElement::eVertexColor, pLayer, pMesh);
			DisplayLayerElement<FbxVector4>(FbxLayerElement::eTangent, pLayer, pMesh);
			DisplayLayerElement<FbxColor>(FbxLayerElement::eBiNormal, pLayer, pMesh);
			DisplayLayerElement<FbxColor>(FbxLayerElement::eUV, pLayer, pMesh);
		}
	}
}

