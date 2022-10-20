#include "LPV.h"

//////////////////////////////////////////////////////////////
LPV::LPV(int shadowMapSmallSize, int lpvGridSize)
: injectionFramebuffer(nullptr)
, geometryInjectionFramebuffer(nullptr)
, propagationFramebuffer(nullptr)
, accumulatedBuffer(nullptr)
{
}

LPV::~LPV()
{
}

void LPV::CreateInjectionPointCloud()
{
}

void LPV::CreatePropagationPointCloud()
{
}

void LPV::CreateInjectionDrawCall(PicoGL::Program* shaderProgram)
{
}

void LPV::CreateGeometryInjectDrawCall(PicoGL::Program* shaderProgram)
{
}

void LPV::CreatePropagationDrawCall(PicoGL::Program* shaderProgram)
{
}

void LPV::CreateFramebuffer(int size)
{
}

void LPV::LightInjection(PicoGL::Framebuffer* RSMFramebuffer)
{
}

void LPV::GeometryInjection(PicoGL::Framebuffer* _RSMFrameBuffer, LPVDirectionLight* directionalLight)
{
}

void LPV::LightPropagation(int lightPropagationIternation)
{
}


void LPV::ClearAccumulatedBuffer()
{
}

void LPV::ClearInjectionBuffer()
{
}

void LPV::LightPropagationIteration(int iteration, PicoGL::Framebuffer* readLPV, PicoGL::Framebuffer* nextIterationLPV, PicoGL::Framebuffer* accumulatedLPV)
{
}