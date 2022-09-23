#ifndef _Frame3_h_
#define _Frame3_h_

#include "Platform.h"
#include "Vector3.h"
#include "Matrix4.h"

/**
* Frame3 is a base class for describing tree structure of the scene graph.
* It provides tree function such as add, remove, query, child
* global and local transform.
* convient function for initialing the transforms
*/
class Frame3
{
public:
	/**
	* Frame3 Constructor.
	* To Construct the Frame3 for the owner.
	*/
	Frame3();

	/**
	* Frame3 Destructor.
	* To Destruct Frame3 and remove from its owner.
	*/
	virtual ~Frame3();

	/**
	* Set all element of of the local transform as 0
	*/
	void Set(const Matrix4& mat);

	/**
	* Set all element of the local transform
	*/
	void Set(float m00, float m01, float m02, float m03,
		float m10, float m11, float m12, float m13,
		float m20, float m21, float m22, float m23,
		float m30, float m31, float m32, float m33);

	/**
	* Set all element of the local transform
	*/
	void Set(const float entry[16], bool rowMajor = true);

	// init
	/**
	* Set all element of of the local transform as 0
	*/
	void SetZero();

	/**
	* Set the Frame3's local transform as identity
	*/
	void SetIdentity();

	/**
	* Set the Frame3's local transform translation
	* @param x, float, x translation
	* @param y, float, y translation
	* @param z, float, z translation
	*/
	void SetTranslate(float x, float y, float z);

	/**
	* Set the Frame3's local transform rotation around X Axis
	* @param x, float, rotation in radian
	*/
	void SetEulerAngleX(float angle);

	/**
	* Set the Frame3's local transform rotation around Y Axis
	* @param y, float, rotation in radian
	*/
	void SetEulerAngleY(float angle);

	/**
	* Set the Frame3's local transform rotation around Z Axis
	* @param z, float, rotation in radian
	*/
	void SetEulerAngleZ(float angle);

	/**
	* Set the Frame3's local transform rotation around Y Axis, X Axis, Z Axis consecutively
	* @param z, float, rotation around Z Axis in radian
	* @param x, float, rotation around X Axis in radian
	* @param y, float, rotation around Y Axis in radian
	*/
	void SetEulerAngleXYZ(float xAngle, float yAngle, float zAngle);

	/**
	* Set the Frame3's local transform rotation around Z Axis, Y Axis, X Axis consecutively
	* @param z, float, rotation around Z Axis in radian
	* @param y, float, rotation around Y Axis in radian
	* @param x, float, rotation around X Axis in radian
	*/
	void SetEulerAngleXZY(float xAngle, float zAngle, float yAngle);

	/**
	* Set the Frame3's local transform rotation about an axis and an angle in radian
	* @param z, float, rotation around Z Axis in radian
	* @param y, float, rotation around Y Axis in radian
	* @param x, float, rotation around X Axis in radian
	*/
	void SetEulerAngleYXZ(float yAngle, float xAngle, float zAngle);

	/**
	* Set the Frame3's local transform rotation about an axis and an angle in radian
	* @param z, float, rotation around Z Axis in radian
	* @param y, float, rotation around Y Axis in radian
	* @param x, float, rotation around X Axis in radian
	*/
	void SetEulerAngleYZX(float yAngle, float zAngle, float xAngle);

	/**
	* Set the Frame3's local transform rotation about an axis and an angle in radian
	* @param z, float, rotation around Z Axis in radian
	* @param y, float, rotation around Y Axis in radian
	* @param x, float, rotation around X Axis in radian
	*/
	void SetEulerAngleZXY(float zAngle, float xAngle, float yAngle);

	/**
	* Set the Frame3's local transform rotation about an axis and an angle in radian
	* @param z, float, rotation around Z Axis in radian
	* @param y, float, rotation around Y Axis in radian
	* @param x, float, rotation around X Axis in radian
	*/
	void SetEulerAngleZYX(float zAngle, float yAngle, float xAngle);

	/**
	* Set the Frame3's local transform for uniform scale
	* @param axis, Vector3, a unit vector for axis of rotation
	* @param angle, float, rotation around the axis in radian
	*/
	void SetAxisAngle(const Vector3& axis, float angle);

	/**
	* Set the Frame3's local transform for uniform scale
	* @param scale, float, the scale
	*/
	void SetScale(float scale);

	/**
	* Set the Frame3's local transform for non-uniform scale
	* @param x, float, the scale of x direction
	* @param y, float, the scale of y direction
	* @param z, float, the scale of z direction
	*/
	void SetScale(float x, float y, float z);

	/**
	* Set the Frame3's local transform. First by scale, then rotation around Z Axis, X Axis, Y Axis consecutively, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param rz, float, rotation around Z Axis in radian
	* @param rx, float, rotation around X Axis in radian
	* @param ry, float, rotation around Y Axis in radian
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateEulerAngleXYZScale(float tx, float ty, float tz, float rx, float ry, float rz, float scale);

	/**
	* Set the Frame3's local transform. First by scale, then rotation around Z Axis, Y Axis, X Axis consecutively, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param rz, float, rotation around Z Axis in radian
	* @param ry, float, rotation around Y Axis in radian
	* @param rx, float, rotation around X Axis in radian
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateEulerAngleXZYScale(float tx, float ty, float tz, float rx, float rz, float ry, float scale);

	/**
	* Set the Frame3's local transform. First by scale, then rotate about an axis and an angle in radian, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param axis, Vector3, a unit vector for axis of rotation
	* @param angle, float, rotation around the axis in radian
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateEulerAngleYXZScale(float tx, float ty, float tz, float ry, float rx, float rz, float scale);

	/**
	* Set the Frame3's local transform. First by scale, then rotate about an axis and an angle in radian, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param axis, Vector3, a unit vector for axis of rotation
	* @param angle, float, rotation around the axis in radian
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateEulerAngleYZXScale(float tx, float ty, float tz, float ry, float rz, float rx, float scale);

	/**
	* Set the Frame3's local transform. First by scale, then rotate about an axis and an angle in radian, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param axis, Vector3, a unit vector for axis of rotation
	* @param angle, float, rotation around the axis in radian
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateEulerAngleZXYScale(float tx, float ty, float tz, float rz, float rx, float ry, float scale);

	/**
	* Set the Frame3's local transform. First by scale, then rotate about an axis and an angle in radian, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param axis, Vector3, a unit vector for axis of rotation
	* @param angle, float, rotation around the axis in radian
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateEulerAngleZYXScale(float tx, float ty, float tz, float rz, float ry, float rx, float scale);

	/**
	* Set the Frame3's local transform for uniform scale
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param axis, Vector3, a unit vector for axis of rotation
	* @param angle, float, rotation around the axis in radian
	* @param scale, float, the uniform scale in all direction* 
	*/
	void SetTranslateAxisAngleScale(float tx, float ty, float tz, const Vector3& axis, float angle, float scale);
	
	/**
	* Set the Frame3's local transform. First by scale, then translate
	* @param tx, float, translation in X direction
	* @param ty, float, translation in Y direction
	* @param tz, float, translation in Z direction
	* @param scale, float, the uniform scale in all direction
	*/
	void SetTranslateScale(float tx, float ty, float tz, float scale);

	/**
	* Set the Frame3's local transform. Look At objective from position, head point up
	* @param position, Vector3, Observer's position
	* @param target, Vector3, Observer's target
	* @param up, Vector3, upward direction
	*/
	void SetLookAt(const Vector3& position, const Vector3& objective, const Vector3& up);

	/**
	* Set the Frame3's local transform. Look At objective from position, head point up, then uniformly scale
	* @param position, Vector3, Observer's position
	* @param target, Vector3, Observer's target
	* @param up, Vector3, upward direction
	* @param scale, float, the uniform scale
	*/
	void SetLookAtScale(const Vector3& position, const Vector3& objective, const Vector3& up, float scale);

	/**
	* Set the Frame3's local transform. Stand on a surface with normal vector up. Look At objective from position
	* @param position, Vector3, Observer's position
	* @param target, Vector3, Observer's target
	* @param up, Vector3, upward direction the Observer stand on
	*/
	void SetStandOn(const Vector3& position, const Vector3& objective, const Vector3& up);

	/**
	* Set the Frame3's local transform. Stand on a surface with normal vector up. Look At objective from position, then uniformly scale
	* @param position, Vector3, Observer's position
	* @param target, Vector3, Observer's target
	* @param up, Vector3, upward direction the Observer stand on
	* @param scale, float, the uniform scale
	*/
	void SetStandOnScale(const Vector3& position, const Vector3& objective, const Vector3& up, float scale);

	// setter
	/**
	* Set the Frame3's local transform by directly setting the Local Transform Matrix
	* @param localtransform_, Matrix4, the local transform
	*/
	void SetLocalTransform(const Matrix4& localtransform_);

	/**
	* Set the Frame3's local transform by directly setting the Local Position
	* @param localposition_, Vector3, the local position
	*/
	void SetLocalPosition(const Vector3& localposition_);

	/**
	* Set the Frame3's local transform by directly setting the a Global Transform Matrix
	* @param globaltransform_, Matrix4, the global transform
	*/
	void SetGlobalTransform(const Matrix4& globaltransform_);

	/**
	* Set the Frame3's local transform by directly setting the a Global Position
	* @param globalposition_, Vector3, the global position
	*/
	void SetGlobalPosition(const Vector3& globalposition_);
	// getter

	/**
	* Get the Frame3's local transform
	* @return const Matrix4 &, the global transform
	*/
	const Matrix4& GetLocalTransform() const;

	/**
	* Get the Frame3's local position
	* @return Vector3, the local position
	*/
	Vector3 GetLocalPosition() const;

	/**
	* Get the Frame3's local x axis
	* @return Vector3, the local x axis
	*/
	Vector3 GetLocalXAxis() const;

	/**
	* Get the Frame3's local y axis
	* @return Vector3, the local y axis
	*/
	Vector3 GetLocalYAxis() const;

	/**
	* Get the Frame3's local z axis
	* @return Vector3, the local z axis
	*/
	Vector3 GetLocalZAxis() const;

	/**
	* Get the Frame3's global transform
	* @return const Matrix4 &, the global transform
	*/
	const Matrix4& GetGlobalTransform();

	/**
	* Get the Frame3's global position
	* @return Vector3, the global position
	*/
	Vector3 GetGlobalPosition();

	/**
	* Get the Frame3's local x axis
	* @return Vector3, the local x axis
	*/
	Vector3 GetGlobalXAxis();

	/**
	* Get the Frame3's local y axis
	* @return Vector3, the local y axis
	*/
	Vector3 GetGlobalYAxis();

	/**
	* Get the Frame3's local z axis
	* @return Vector3, the local z axis
	*/
	Vector3 GetGlobalZAxis();

	/**
	* Get the Frame3's inverse transform
	* @return Matrix4, the inverse transform
	*/
	Matrix4 GetInverseGlobalTransform();

	/*
	const Matrix4 &getParentGlobalTransform();
	Vector3 getParentGlobalPosition();
	Vector3 getParentGlobalXAxis();
	Vector3 getParentGlobalYAxis();
	Vector3 getParentGlobalZAxis();
	*/

	// setter
	/**
	* add a child to this Frame3's children list
	* @param child_, the child to be added
	*/
	void AddChild(Frame3* child_);

	/**
	* set i-th child for this Frame3's
	* @param child_, the child to be set to
	* @param index_, the index_ position
	*/
	void SetChild(Frame3* child_, int index_);

	/**
	* insert a child to this Frame3's at index_
	* @param child_, the child to be set to
	* @param index_, the index_ position
	*/
	void InsertChild(Frame3* child_, int index_);

	/**
	* remove all children from this Frame3
	*/
	void RemoveAllChildren();

	/**
	* remove child at index_
	*/
	void RemoveChild(int index_);

	/**
	* remove child_
	*/
	void RemoveChild(Frame3* child_);

	// getter
	/**
	* get all children from this Frame3
	*/
	int GetAllChildren(std::vector<Frame3*>& children_);

	/**
	* Get a child of this frame at index_
	* @param index_, the index_ position
	* @return Frame3 *, the i-th child
	*/
	Frame3* GetChild(int index_) const;

	/**
	* Get an index of child
	* @param child_, Frame3 *
	* @return int, the index of child. if child is not in children list, return -1
	*/
	int IndexOfChild(Frame3* child_) const;

	/**
	* Get the number of children
	* @return int, the number of children
	*/
	int GetNumChildren() const;

	/**
	* Get a the parent of this frame
	* @return Frame3 *, this frame's parent. if this frame has no parent, return 0
	*/
	Frame3* GetParent();

	/**
	* Get a the parent of this frame
	* @return const Frame3 *, this frame's parent. if this frame has no parent, return 0
	*/
	const Frame3* GetParent() const;
protected:
	void ValidateGlobal();
	void InValidateGlobal();
	bool IsValidGlobal();

	void ValidateGlobalInverse();
	void InValidateGlobalInverse();
	bool IsValidGlobalInverse();
private:
	Frame3* parent;
	std::vector<Frame3*> children;

	Matrix4 localTransform;
	Matrix4 globalTransform;
	bool validGlobal;

	Matrix4 globalTransformInverse;
	bool validGlobalInverse;
};

#endif