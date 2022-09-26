#ifndef _Camera_h_
#define _Camera_h_

#include "Platform.h"
#include "Vector3.h"

#include "Matrix4.h"
#include "Frustum.h"
#include "Frame3.h"

class Camera : public Frame3
{
public:
	enum class ProjectionMode
	{
		Orthogonal = 0,
		Perspective
	};

	Camera()
		: l(-1)
		, r(1)
		, t(-1)
		, b(1)
		, n(1)
		, f(100)

		, validProjection(false)
		, projectionTransform(Matrix4::Identity)
		, projectionMode(ProjectionMode::Perspective)
	{
	}

	~Camera()
	{
	}

	void SetOrthogonal(float width_, float height_, float n_, float f_)
	{
		l = -width_/2;
		r = width_ / 2;
		t = height_ / 2;
		b = -height_ / 2;
		n = n_;
		f = f_;

		projectionMode = ProjectionMode::Orthogonal;

		InValidateProjection();
	}

	void SetOrthogonal(float l_, float r_, float t_, float b_, float n_, float f_)
	{
		l = l_;
		r = r_;
		t = t_;
		b = b_;
		n = n_;
		f = f_;

		projectionMode = ProjectionMode::Orthogonal;

		InValidateProjection();
	}

	void SetPerspectiveFov(float fovY_, float aspect_, float n_, float f_)
	{
		t = Math::Tan(fovY_ * Math::Degree2Radian / 2.0) * n_;
		r = t * aspect_;

		b = -t;
		l = -r;

		n = n_;
		f = f_;

		projectionMode = ProjectionMode::Perspective;
		
		InValidateProjection();
	}

	void SetPerspective(float width_, float height_, float n_, float f_)
	{
		l = -width_ / 2;
		r = width_ / 2;
		t = height_ / 2;
		b = -height_ / 2;
		n = n_;
		f = f_;

		projectionMode = ProjectionMode::Perspective;

		InValidateProjection();
	}

	void SetPerspective(float l_, float r_, float t_, float b_, float n_, float f_)
	{
		l = l_;
		r = r_;
		t = t_;
		b = b_;
		n = n_;
		f = f_;

		projectionMode = ProjectionMode::Perspective;

		InValidateProjection();
	}

	const Matrix4& GetProjectionTransform()
	{
		ValidateProjection();

		return projectionTransform;
	}

	Frustum GetFrustum()
	{
		return Frustum(GetGlobalTransform(), l, r, b, t, n, f);
	}

	void GetFrustumVertices(std::vector<Vector3>& vertices_)
	{
		Vector3 v0 = Vector3(l, t, -n);
		Vector3 v1 = Vector3(l * f / n, t * f / n, -n * f / n);
		Vector3 v2 = Vector3(l * f / n, b * f / n, -n * f / n);
		Vector3 v3 = Vector3(l, b, -n);

		Vector3 v4 = Vector3(r, t, -n);
		Vector3 v5 = Vector3(r, b, -n);
		Vector3 v6 = Vector3(r * f / n, b * f / n, -n * f / n);
		Vector3 v7 = Vector3(r * f / n, t * f / n, -n * f / n);

		vertices_.push_back(v0);
		vertices_.push_back(v1);
		vertices_.push_back(v2);
		vertices_.push_back(v3);

		vertices_.push_back(v4);
		vertices_.push_back(v5);
		vertices_.push_back(v6);
		vertices_.push_back(v7);

		vertices_.push_back(v0);
		vertices_.push_back(v4);
		vertices_.push_back(v7);
		vertices_.push_back(v1);

		vertices_.push_back(v3);
		vertices_.push_back(v2);
		vertices_.push_back(v5);
		vertices_.push_back(v6);

		vertices_.push_back(v0);
		vertices_.push_back(v3);
		vertices_.push_back(v5);
		vertices_.push_back(v4);

		vertices_.push_back(v7);
		vertices_.push_back(v1);
		vertices_.push_back(v2);
		vertices_.push_back(v6);
	}
private:
	void ValidateProjection()
	{
		if (!validProjection)
		{
			if (projectionMode == ProjectionMode::Perspective)
				projectionTransform.SetPerspectiveOffCenter(l, r, b, t, n, f);
			else
				projectionTransform.SetOrthogonalOffCenter(l, r, b, t, n, f);

			validProjection = true;
		}
	}

	void InValidateProjection()
	{
		validProjection = false;
	}

	bool IsValidProjection()
	{
		return validProjection;
	}

	bool validProjection;
	float l;
	float r;
	float t;
	float b;
	float n;
	float f;
	Matrix4 projectionTransform;
	ProjectionMode projectionMode;
};


#endif