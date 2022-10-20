#include "LPVCamera.h"
#include "Video.h"
#include "RenderStates.h"
#include "Input.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVCamera::LPVCamera(const Vector3& position_, const Quaternion& orientation_)
: position(position_)
, orientation(orientation_)
, near(0.01f)
, far(1000.0f)
, fovDegrees(50.5f)
, viewMatrix(Matrix4::Identity)
, projectionMatrix(Matrix4::Identity)
, OnViewMatrixChange(nullptr)
, OnProjectionMatrixChange(nullptr)
, moveSpeed(0.05f)
, rotationSpeed(0.007f)
, controlsEnabled(false)
, currentMousePos(Vector2::Zero)
, lastMousePos(Vector2::Zero)
, keys()
{
	//Input::Manager::GetInstance().AddEventListener("keydown", std::bind(&LPVCamera::KeyDownListener, this, std::placeholders::_1));
	// Input::Manager::GetInstance().AddEventListener("keyup", std::bind(&LPVCamera::KeyUpListener, this, std::placeholders::_1));
	// Input::Manager::GetInstance().AddEventListener("mousedown", std::bind(&LPVCamera::MouseKeyDownListener, this, std::placeholders::_1));
	// Input::Manager::GetInstance().AddEventListener("mouseup", std::bind(&LPVCamera::MouseKeyUpListener, this, std::placeholders::_1));
	// Input::Manager::GetInstance().AddEventListener("mousemove", std::bind(&LPVCamera::MouseMoveListener, this, std::placeholders::_1));
}

LPVCamera::~LPVCamera()
{
	Input::Manager::GetInstance().RemoveEventListener(std::bind(&LPVCamera::KeyDownListener, this, std::placeholders::_1));
	Input::Manager::GetInstance().RemoveEventListener(std::bind(&LPVCamera::KeyUpListener, this, std::placeholders::_1));
	Input::Manager::GetInstance().RemoveEventListener(std::bind(&LPVCamera::MouseKeyDownListener, this, std::placeholders::_1));
	Input::Manager::GetInstance().RemoveEventListener(std::bind(&LPVCamera::MouseKeyUpListener, this, std::placeholders::_1));
	Input::Manager::GetInstance().RemoveEventListener(std::bind(&LPVCamera::MouseMoveListener, this, std::placeholders::_1));
}

void LPVCamera::KeyDownListener(const Input::Event& e)
{
	// ::Debug("KeyDownListener(%3.4f %3.4f %d %d %3.4f)\n", e.screenX, e.screenY, e.keyCode, e.keyState, e.timeStamp);

	SetKeyState(keys, e.keyCode, 1);

	if (e.keyCode == 27) {
		controlsEnabled = false;
	}
	else if (e.keyCode == 17) {
		controlsEnabled = true;
		lastMousePos = Vector2(-1, -1);
	}
}

void LPVCamera::KeyUpListener(const Input::Event& e)
{
	// ::Debug("KeyUpListener(%3.4f %3.4f %d %d %3.4f)\n", e.screenX, e.screenY, e.keyCode, e.keyState, e.timeStamp);
	SetKeyState(keys, e.keyCode, 0);
}

void LPVCamera::MouseKeyDownListener(const Input::Event& e)
{
	//::Debug("MouseKeyDownListener(%3.4f %3.4f %d %d %3.4f)\n", e.screenX, e.screenY, e.keyCode, e.keyState, e.timeStamp);
}

void LPVCamera::MouseKeyUpListener(const Input::Event& e)
{
	//::Debug("MouseKeyUpListener(%3.4f %3.4f %d %d %3.4f)\n", e.screenX, e.screenY, e.keyCode, e.keyState, e.timeStamp);
}

void LPVCamera::MouseMoveListener(const Input::Event& e)
{
//	::Debug("MouseMoveListener(%3.4f %3.4f %d %d %3.4f)\n", e.screenX, e.screenY, e.keyCode, e.keyState, e.timeStamp);
	currentMousePos[0] = e.x;
	currentMousePos[1] = e.y;
}

void LPVCamera::SetKeyState(Keys& map, int keyCode, int val)
{
	map[keyCode] = val;
}

void LPVCamera::Resize()
{
#if 0
	resize: function(width, height) {

		var aspectRatio = width / height;
		this.updateProjectionMatrix(aspectRatio);

	},
#endif
	float aspectRatio = Platform::GetWidth() / Platform::GetHeight();
	UpdateProjectionMatrix(aspectRatio);
}

void LPVCamera::UpdateProjectionMatrix(float aspectRatio)
{
#if 0
	updateProjectionMatrix: function(aspectRatio) {

		var fovy = this.fovDegrees / 180.0 * Math.PI;
		mat4.perspective(this.projectionMatrix, fovy, aspectRatio, this.near, this.far);

		if (this.onProjectionMatrixChange) {
			this.onProjectionMatrixChange(this.projectionMatrix);
		}

	},
#endif
	float fovy = fovDegrees;

	projectionMatrix.SetPerspective(fovy, aspectRatio, this->near, this->far);

	if (OnProjectionMatrixChange)
		OnProjectionMatrixChange(projectionMatrix);
}

void LPVCamera::UpdateViewMatrix()
{
#if 0
	updateViewMatrix: function() {

		mat4.fromRotationTranslation(this.viewMatrix, this.orientation, this.position);
		mat4.invert(this.viewMatrix, this.viewMatrix);

		if (this.onViewMatrixChange) {
			this.onViewMatrixChange(this.viewMatrix);
		}

	},
#endif
	//viewMatrix.SetTranslateRotateQuaternionScale(position.X(), position.Y(), position.Z(), orientation, 1.0);
	viewMatrix = viewMatrix.Inverse();

	if (OnViewMatrixChange)
		OnViewMatrixChange(viewMatrix);
}

bool LPVCamera::Initiate()
{
	return true;
}

bool LPVCamera::Start()
{
	return true;
}

bool LPVCamera::Update()
{
#if 0
	update: function() {

		if (!this.controlsEnabled) {
			return;
		}

		if (this.lastMousePos == = null) {
			this.lastMousePos = vec2.copy(vec2.create(), this.currentMousePos);
		}

		var didChange = false;

		// Translation
		{
			var keys = this.keys;
			var translation = vec3.fromValues(
				Math.sign(keys['d'] + keys['right'] - keys['a'] - keys['left']),
				Math.sign(keys['space'] - keys['shift']),
				Math.sign(keys['s'] + keys['down'] - keys['w'] - keys['up'])
			);

			if (translation[0] != 0 || translation[1] != 0 || translation[2] != 0) {

				vec3.normalize(translation, translation);
				vec3.scale(translation, translation, this.moveSpeed);

				vec3.transformQuat(translation, translation, this.orientation);
				vec3.add(this.position, this.position, translation);

				didChange = true;

			}
		}

		// Rotation
		{
			var dx = this.currentMousePos[0] - this.lastMousePos[0];
			var dy = this.currentMousePos[1] - this.lastMousePos[1];
			var dz = this.keys['e'] - this.keys['q'];

			if (dx != 0 || dy != 0 || dz != 0) {

				// Rotate around global up (0, 1, 0)
				var yRot = quat.create();
				quat.rotateY(yRot, yRot, -dx * this.rotationSpeed);

				// Rotate around local right-axis
				var rightAxis = vec3.fromValues(1, 0, 0);
				vec3.transformQuat(rightAxis, rightAxis, this.orientation);
				var xRot = quat.create();
				quat.setAxisAngle(xRot, rightAxis, -dy * this.rotationSpeed);

				// Rotate around local forward-axis
				var forwardAxis = vec3.fromValues(0, 0, -1);
				vec3.transformQuat(forwardAxis, forwardAxis, this.orientation);
				var zRot = quat.create();
				quat.setAxisAngle(zRot, forwardAxis, dz * this.rotationSpeed * 2.0);

				// Apply rotation
				quat.multiply(this.orientation, yRot, this.orientation);
				quat.multiply(this.orientation, xRot, this.orientation);
				quat.multiply(this.orientation, zRot, this.orientation);

				// current mouse pos -> last mouse pos
				vec2.copy(this.lastMousePos, this.currentMousePos);

				didChange = true;

			}
		}

		if (didChange) {
			this.updateViewMatrix();
		}

	}
#endif
	if (!this->controlsEnabled)
		return true;

	if (this->lastMousePos == Vector2(-1, -1))
		this->lastMousePos = this->currentMousePos;

	bool didChange = false;
	{
		Vector3 translation = Vector3
		(
			Math::Sign(keys[(int)Platform::KeyCode::D]     + keys[(int)Platform::KeyCode::RightArrow] - keys[(int)Platform::KeyCode::A] - keys[(int)Platform::KeyCode::LeftArrow]),
			Math::Sign(keys[(int)Platform::KeyCode::Space] - keys[(int)Platform::KeyCode::LeftShift]),
			Math::Sign(keys[(int)Platform::KeyCode::S]     + keys[(int)Platform::KeyCode::DownArrow] - keys[(int)Platform::KeyCode::W] - keys[(int)Platform::KeyCode::UpArrow])
		);

		if (translation[0] != 0 || translation[1] != 0 || translation[2] != 0) 
		{
			translation.Normalize();
			translation *= this->moveSpeed;

			vec3transformQuat(translation, translation, this->orientation);
			position += translation;

			//vec3.transformQuat(translation, translation, this.orientation);
			//vec3.add(this.position, this.position, translation);

			didChange = true;
		}

		// Rotation
		{
			float dx = this->currentMousePos[0] - this->lastMousePos[0];
			float dy = this->currentMousePos[1] - this->lastMousePos[1];
			float dz = this->keys[(int)Platform::KeyCode::E] - this->keys[(int)Platform::KeyCode::Q];

			if (dx != 0 || dy != 0 || dz != 0) 
			{
				// Rotate around global up (0, 1, 0)
				Matrix4 yRot = Matrix4();
				yRot.SetEulerAngleY(-dx * this->rotationSpeed);

				// Rotate around local right-axis
				Vector3 rightAxis(1, 0, 0);
				vec3transformQuat(rightAxis, rightAxis, this->orientation);
				Matrix4 xRot = Matrix4();
				xRot.SetAxisAngle(rightAxis, -dy * this->rotationSpeed);

				// Rotate around local forward-axis
				Vector3 forwardAxis(0, 0, -1);
				vec3transformQuat(forwardAxis, forwardAxis, this->orientation);
				Matrix4 zRot = Matrix4();
				zRot.SetAxisAngle(forwardAxis, dz * this->rotationSpeed * 2.0);

				// Apply rotation
				quatmultiply(this->orientation, yRot, this->orientation);
				quatmultiply(this->orientation, xRot, this->orientation);
				quatmultiply(this->orientation, zRot, this->orientation);

				// current mouse pos -> last mouse pos
				this->lastMousePos = this->currentMousePos;

				didChange = true;

			}
		}
	}

	if (didChange) 
	{
		UpdateViewMatrix();
	}

	return true;
}

bool LPVCamera::Pause()
{
	return true;
}

void LPVCamera::Resume()
{
}

void LPVCamera::Stop()
{
}

void LPVCamera::Terminate()
{
}

void LPVCamera::Render()
{
	ClearState clearState;
	clearState.clearColor = ColorRGBA(0.0f, 0.0f, 0.0f, 1.0f);
	clearState.clearDepth = 1.0f;
	clearState.clearStencil = 0;
	clearState.enableClearColor = true;
	clearState.enableClearDepth = true;
	clearState.enableClearStencil = true;
	clearState.Apply();

	CullFaceState cullFaceState;
	cullFaceState.mode = CullFaceState::Mode::BACK;
	cullFaceState.enabled = true;
	cullFaceState.Apply();

	BlendState blendState;
	blendState.enabled = false;
	blendState.Apply();
}
