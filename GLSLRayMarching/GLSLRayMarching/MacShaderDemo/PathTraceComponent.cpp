#include "PathTraceComponent.h"

//////////////////////////////////////////////////////////////
PathTraceComponent::PathTraceComponent(GameObject& gameObject_)
: Graphics3Component(gameObject_)
{
}

PathTraceComponent::~PathTraceComponent()
{
}

void PathTraceComponent::OnRender()
{
	pathTrace.Render();
}

bool PathTraceComponent::OnInitiate()
{
	return true;
}

bool PathTraceComponent::OnStart()
{
	std::string sceneName =
		// "ferrai.scene"
		//"ajax.scene"
		// "bedroom.scene"
		// "boy.scene"
		"coffee_cart.scene"
		// "coffee_maker.scene"
		// "cornell_box.scene"
		// "cornell_box2.scene"
		// "diningroom.scene"
		// "dragon.scene"
		// "furnace.scene"
		// "hyperion.scene"
		// "hyperion2.scene"
		// "mustang.scene"
		// "mustang_red.sce"
		// "panther.scene"
		// "spaceship.scene"
		// "staircase.scene"
		// "stormtrooper.scene"
		//  "teapot.scene"
		;

	if (!pathTrace.Initiate(sceneName.c_str()))
		return false;
	
	return true;
}

bool PathTraceComponent::OnUpdate()
{
	return pathTrace.Update();
}

bool PathTraceComponent::OnPause()
{
	return true;
}

void PathTraceComponent::OnResume()
{
}

void PathTraceComponent::OnStop()
{
}

void PathTraceComponent::OnTerminate()
{
	pathTrace.Terminate();
}