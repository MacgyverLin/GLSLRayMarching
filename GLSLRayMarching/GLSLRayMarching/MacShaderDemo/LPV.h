#ifndef _LPV_h_ 
#define _LPV_h_ 

#include "Component.h"
#include "Video.h"
#include "Vector3.h"
#include "Quaternion.h"
#include "Matrix4.h"
#include "Input.h"
#include "ShaderProgram.h"
#include "FrameBuffer.h"
#include "LPVDirectionLight.h"

class LPV
{
public:
	LPV(int _RSMsize = 512, int _LPVGridSize = 32);
	virtual ~LPV();

	void CreateInjectionPointCloud();
	void CreatePropagationPointCloud();
	void CreateInjectionDrawCall(ShaderProgram* shaderProgram);
	void CreateGeometryInjectDrawCall(ShaderProgram* shaderProgram);
	void CreatePropagationDrawCall(ShaderProgram* shaderProgram);
	void CreateFramebuffer(int size);
	void LightInjection(FrameBuffer* RSMFramebuffer);
	void GeometryInjection(FrameBuffer*, LPVDirectionLight*);
	void ClearAccumulatedBuffer();
	void ClearInjectionBuffer();
	void LightPropagationIteration(int iteration, FrameBuffer* readLPV, FrameBuffer* nextIterationLPV, FrameBuffer* accumulatedLPV);
public:
private:
	int size;
	int framebufferSize;
	FrameBuffer* injectionFramebuffer;
	FrameBuffer* geometryInjectionFramebuffer;
	FrameBuffer* propagationFramebuffer;
	FrameBuffer* accumulatedBuffer;
};

#endif