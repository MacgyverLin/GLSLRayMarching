#ifndef _IK2DNJoint_h_
#define _IK2DNJoint_h_

#include "IK2DBase.h"
#include "GradientDescent.h"
#include <functional>

class IK2DNJoint : public IK2DBase
{
public:
	IK2DNJoint()
	{
	}

	virtual ~IK2DNJoint()
	{
	}

	IK2DNJoint& Begin(float sampleDistance_, float learningRate_)
	{
		gradientDescent.Begin(sampleDistance_, learningRate_);
		jointPositions.clear();

		return *this;
	}

	IK2DNJoint& AddJoint(const Vector2& jointPosition_, const float& minimun, const float& maximun)
	{
		gradientDescent.PushValue(0, minimun, maximun);
		jointPositions.push_back(jointPosition_);

		return *this;
	}

	bool End(const Vector2& effectorPosition_)
	{
		effectorPosition = effectorPosition_;
		return gradientDescent.End();
	}

	virtual bool OnInitiate() override
	{
		return true;
	}

	virtual void OnUpdate(const Vector2& targetValue) override
	{
		gradientDescent.Update(targetValue, std::bind(&IK2DNJoint::CostFunction, this, std::placeholders::_1, std::placeholders::_2));
	}

	virtual void OnTerminate() override
	{
	}

	float CostFunction(const Vector2& targetValue, const std::vector<float>& values)
	{
		Vector2 currentEffectorPos;
		for (int i = jointPositions.size() - 1; i >= 0; i--)
		{
			if (i == jointPositions.size() - 1)
				currentEffectorPos = Vector2(GetLength(i), 0);
			else
				currentEffectorPos += Vector2(GetLength(i), 0);
			
			currentEffectorPos = Rotate(values[i], currentEffectorPos);
		}

		currentEffectorPos += GetRoot();

		return (currentEffectorPos - targetValue).Length();
	}

	Vector2 Rotate(float angle, const Vector2& hand)
	{
		Matrix4 m;
		m.SetEulerAngleZ(angle);

		Vector3 r = m * Vector3(hand.X(), hand.Y(), 0.0);
		return Vector2(r.X(), r.Y());
	}

	const Vector2& GetRoot() const
	{
		return jointPositions[0];
	}

	const Vector2& GetEffectorPosition() const
	{
		return effectorPosition;
	}

	float GetLength(int i) const
	{
		if (i < jointPositions.size() - 1)
			return (jointPositions[i + 1] - jointPositions[i]).Length();
		else
			return (effectorPosition - jointPositions[i]).Length();
	}

	float GetJointCount() const
	{
		return gradientDescent.GetValueCount();
	}

	float GetJointAngle(int i) const
	{
		return gradientDescent.GetValue(i);
	}
private:
	Vector2 effectorPosition;
	std::vector<Vector2> jointPositions;

	GradientDescent<Vector2> gradientDescent;
};

#endif