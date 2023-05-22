#ifndef _MeshProcessingScene_h_
#define _MeshProcessingScene_h_

#include "Scene.h"
#include "Mesh.h"
#include "TetrahedronMesh.h"
#include "SkinningInfo.h"

#include "MeshFBXIO.h"
#include "MeshObjIO.h"
#include "TetrahedronMeshObjIO.h"
#include "TriangleMeshObjIO.h"
#include "GeometryConverter.h"

#include "TetrahedronizedMeshGenerator.h"
#include "ProxyInfoGenerator.h"



 
class MeshProcessingScene : public Scene
{
public:
	MeshProcessingScene()
		: Scene()

		, physicsDemoCameraComponent(physicsWorldGameObject)

		, rigidbodyComponent(physicsBodyGameObject)
		, softBodyComponent(physicsBodyGameObject)

		, testGraphicComponent(testGraphic)
		, primitivesRenderer(testGraphic)
	{
	}

	virtual ~MeshProcessingScene()
	{
	}
protected:
	virtual bool OnInitiate() override
	{
		int resolution = 10;
		int minQualityExp = -3;
		float scale = 0.8f;

		if (!InitCloth("assets/hair1.FBX", "assets/hair1proxy.FBX", resolution, minQualityExp, scale))
			return false;

		primitivesRenderer.Clear();
		primitivesRenderer.DrawGrid(-10.0f, 10.0f, 0.1f, ColorRGBA(0.5, 0.5, 0.5, 0.5));

		return true;
	}

	virtual bool OnStart() override
	{
		return true;
	}

	virtual bool OnUpdate() override
	{
		testGraphicComponent.SetWorldTransform
		(
			physicsDemoCameraComponent.GetWorldTransform(),
			physicsDemoCameraComponent.GetViewTransform(),
			physicsDemoCameraComponent.GetProjectionTransform()
		);

		primitivesRenderer.SetWorldTransform
		(
			physicsDemoCameraComponent.GetWorldTransform(),
			physicsDemoCameraComponent.GetViewTransform(),
			physicsDemoCameraComponent.GetProjectionTransform()
		);




		return true;
	}

	virtual bool OnPause() override
	{
		return true;
	}

	virtual void OnResume() override
	{
	}

	virtual void OnStop() override
	{
	}

	virtual void OnTerminate() override
	{
	}


	bool InitCloth(const std::string& visualMeshPath, const std::string& proxyMeshPath, int resolution, float minQualityExp, float scale)
	{
		//inputPath = "assets/test.fbx";
		MeshFBXIO meshFBXIO;
		MeshObjIO meshObjIO;
		TetrahedronMeshObjIO tetrahedronMeshObjIO;
		TriangleMeshObjIO triangleMeshObjIO;
		bool isClosed;

		if (!meshFBXIO.Load(visualMesh, visualMeshPath))
			return false;
		isClosed = visualMesh.IsClosed();
		if (!meshObjIO.Save(visualMesh, "assets/visualMesh.obj"))
			return false;

		TriangleMesh visualTriangleMesh;
		GeometryConverter::Convert(visualTriangleMesh, visualMesh);
		if (!triangleMeshObjIO.Save(visualTriangleMesh, "assets/visualTriangleMesh.obj"))
			return false;

		if (!meshFBXIO.Load(proxyMesh, proxyMeshPath))
			return false;
		isClosed = proxyMesh.IsClosed();
		if (!meshObjIO.Save(proxyMesh, "assets/proxyMesh.obj"))
			return false;

		TetrahedronizedMeshGenerator tetrahedronizedMeshGenerator;
		tetrahedronizedMeshGenerator.Generate(tetrahedronMesh, proxyMesh, resolution, minQualityExp, scale);
		if (!tetrahedronMeshObjIO.Save(tetrahedronMesh, "assets/tetrahedronMesh.obj"))
			return false;

		ProxyInfoGenerator proxyInfoGenerator;
		proxyInfoGenerator.ComputeSkinningInfo(skinningInfo, visualMesh, tetrahedronMesh);
		proxyInfoGenerator.ComputeSkinMesh(skinMesh, visualMesh, tetrahedronMesh, skinningInfo);

		return true;
	}
private:
	GameObject physicsWorldGameObject;
	PhysicsDemoCameraComponent physicsDemoCameraComponent;

	GameObject physicsBodyGameObject;
	Physics3D::RigidbodyComponent rigidbodyComponent;
	Physics3D::SoftbodyComponent softBodyComponent;


	GameObject testGraphic;
	PrimitivesRenderer primitivesRenderer;
	TestGraphicComponent testGraphicComponent;




	Mesh visualMesh;
	Mesh proxyMesh;

	TetrahedronMesh tetrahedronMesh;

	std::vector<SkinningInfo> skinningInfo;
	Mesh skinMesh;
};

#endif