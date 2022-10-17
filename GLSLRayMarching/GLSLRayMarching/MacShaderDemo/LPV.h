#ifndef _LPV_h_ 
#define _LPV_h_ 

#include "Component.h"
#include "Video.h"
#include "Vector3.h"
#include "Quaternion.h"
#include "Matrix4.h"
#include "Input.h"
#include "PicoGL.h"
#include "LPVDirectionLight.h"

class LPV
{
public:
	LPV(int _RSMsize = 512, int _LPVGridSize = 32);
	virtual ~LPV();

	void CreateInjectionPointCloud();
	void CreatePropagationPointCloud();
	void CreateInjectionDrawCall(PicoGL::Program* shaderProgram);
	void CreateGeometryInjectDrawCall(PicoGL::Program* shaderProgram);
	void CreatePropagationDrawCall(PicoGL::Program* shaderProgram);
	void CreateFramebuffer(int size);
	void LightInjection(PicoGL::Framebuffer* RSMFramebuffer);
	void GeometryInjection(PicoGL::Framebuffer*, LPVDirectionLight*);
	void LightPropagation(int lightPropagationIternation);
	void ClearAccumulatedBuffer();
	void ClearInjectionBuffer();
	void LightPropagationIteration(int iteration, PicoGL::Framebuffer* readLPV, PicoGL::Framebuffer* nextIterationLPV, PicoGL::Framebuffer* accumulatedLPV);

	int size;
	int framebufferSize;
	PicoGL::Framebuffer* injectionFramebuffer;
	PicoGL::Framebuffer* geometryInjectionFramebuffer;
	PicoGL::Framebuffer* propagationFramebuffer;
	PicoGL::Framebuffer* accumulatedBuffer;
};

#endif