#include "ShaderToyCamera.h"
#include "Video.h"
#include "RenderStates.h"
//////////////////////////////////////////////////////////////
ShaderToyCamera::ShaderToyCamera(GameObject& gameObject_)
: CameraComponent(gameObject_)
{
}

ShaderToyCamera::~ShaderToyCamera()
{
}

bool ShaderToyCamera::OnInitiate()
{
	return true;
}

bool ShaderToyCamera::OnStart()
{
	return true;
}

bool ShaderToyCamera::OnUpdate()
{
	return true;
}

bool ShaderToyCamera::OnPause()
{
	return true;
}

void ShaderToyCamera::OnResume()
{
}

void ShaderToyCamera::OnStop()
{
}

void ShaderToyCamera::OnTerminate()
{
}

void ShaderToyCamera::OnRender()
{
	ClearState clearState;
	clearState.clearColor = ColorRGBA(0.0f, 0.0f, 0.0f, 1.0f);
	clearState.clearDepth = 1.0f;
	clearState.clearStencil = 0;
	clearState.enableClearColor = true;
	clearState.enableClearDepth = true;
	clearState.enableClearStencil = true;
	clearState.Apply();
}
