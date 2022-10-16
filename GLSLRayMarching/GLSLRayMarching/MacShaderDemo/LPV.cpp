#include "LPV.h"

//////////////////////////////////////////////////////////////
LPV::LPV(int shadowMapSmallSize, int lpvGridSize)
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

void LPV::CreateInjectionDrawCall(ShaderProgram* shaderProgram)
{
}

void LPV::CreateGeometryInjectDrawCall(ShaderProgram* shaderProgram)
{
}

void LPV::CreatePropagationDrawCall(ShaderProgram* shaderProgram)
{
}

void LPV::CreateFramebuffer(int size)
{
}

void LPV::LightInjection(FrameBuffer* RSMFramebuffer)
{
}

void LPV::GeometryInjection(FrameBuffer* _RSMFrameBuffer, LPVDirectionLight* directionalLight)
{
}

void LPV::ClearAccumulatedBuffer()
{
}

void LPV::ClearInjectionBuffer()
{
}

void LPV::LightPropagationIteration(int iteration, FrameBuffer* readLPV, FrameBuffer* nextIterationLPV, FrameBuffer* accumulatedLPV)
{
}