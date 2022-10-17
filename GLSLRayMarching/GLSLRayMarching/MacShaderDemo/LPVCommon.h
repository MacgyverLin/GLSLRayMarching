#ifndef _LPVCommon_h_ 
#define _LPVCommon_h_ 

#include "Component.h"
#include "Video.h"
#include "Vector3.h"
#include "Quaternion.h"
#include "Matrix4.h"
#include "Input.h"
#include <map>
#include <string>
#include <vector>

static void vec3transformQuat(Vector3& out, const Vector3& v, const Quaternion& q)
{
	// Matrix4 rot;
	// q.GetRotationMatrix(rot);

	// out = rot * v;
}

static void vec3transformMat4(Vector3& out, const Vector3& v, const Matrix4& m)
{
	// out = m * v;
}

static void quatmultiply(Quaternion& out, const Matrix4& m1, const Quaternion& q)
{
	// Matrix4 m2;
	// q.GetRotationMatrix(m2);

	// out.SetRotationMatrix(m1 * m2);
}

/**
 * Rotate a 3D vector around the y-axis
 * @param {vec3} out The receiving vec3
 * @param {vec3} a The vec3 point to rotate
 * @param {vec3} b The origin of the rotation
 * @param {Number} c The angle of rotation
 * @returns {vec3} out
 */
static Vector3 vec3_rotateY(Vector3& out, const Vector3& a, const Vector3& b, float c) {
	Vector3 p;
	Vector3 r;

	////Translate point to the origin
	p = a - b;

	//perform rotation
	r[0] = p[2] * Math::Sin(c) + p[0] * Math::Cos(c);
	r[1] = p[1];
	r[2] = p[2] * Math::Cos(c) - p[0] * Math::Sin(c);

	//translate to correct position
	out = r + b;

	return out;
	/*
	  var p = [],
		  r = [];
	  //Translate point to the origin
	  p[0] = a[0] - b[0];
	  p[1] = a[1] - b[1];
	  p[2] = a[2] - b[2];

	  //perform rotation
	  r[0] = p[2] * Math.sin(c) + p[0] * Math.cos(c);
	  r[1] = p[1];
	  r[2] = p[2] * Math.cos(c) - p[0] * Math.sin(c);

	  //translate to correct position
	  out[0] = r[0] + b[0];
	  out[1] = r[1] + b[1];
	  out[2] = r[2] + b[2];

	  return out;
	*/

	return out;
}

static bool vec3_equals(const Vector3& a, const Vector3& b) {
	float a0 = a[0], a1 = a[1], a2 = a[2];
	float b0 = b[0], b1 = b[1], b2 = b[2];
	return Math::FAbs(a0 - b0) <= Math::Epsilon * Math::Max(1.0, Math::Max(Math::FAbs(a0), Math::FAbs(b0))) && Math::FAbs(a1 - b1) <= Math::Epsilon * Math::Max(1.0, Math::Max(Math::FAbs(a1), Math::FAbs(b1))) && Math::FAbs(a2 - b2) <= Math::Epsilon * Math::Max(1.0, Math::Max(Math::FAbs(a2), Math::FAbs(b2)));
}

static Quaternion quat_fromEuler(float x, float y, float z) {
	float halfToRad = 0.5 * Math::OnePi / 180.0;
	x *= halfToRad;
	y *= halfToRad;
	z *= halfToRad;

	float sx = Math::Sin(x);
	float cx = Math::Cos(x);
	float sy = Math::Sin(y);
	float cy = Math::Cos(y);
	float sz = Math::Sin(z);
	float cz = Math::Cos(z);

	Quaternion q;
	q.W() = sx * cy * cz - cx * sy * sz;
	q.X() = cx * sy * cz + sx * cy * sz;
	q.Y() = cx * cy * sz - sx * sy * cz;
	q.Z() = cx * cy * cz + sx * sy * sz;

	return q;
}

/**
 * Creates a matrix from a quaternion rotation, vector translation and vector scale
 * This is equivalent to (but much faster than):
 *
 *     mat4.identity(dest);
 *     mat4.translate(dest, vec);
 *     let quatMat = mat4.create();
 *     quat4.toMat4(quat, quatMat);
 *     mat4.multiply(dest, quatMat);
 *     mat4.scale(dest, scale)
 *
 * @param {mat4} out mat4 receiving operation result
 * @param {quat4} q Rotation quaternion
 * @param {vec3} v Translation vector
 * @param {vec3} s Scaling vector
 * @returns {mat4} out
 */
static Matrix4 mat4_fromRotationTranslationScale(const Quaternion& q, const Vector3& v, const Vector3& s) {
	// Quaternion math
	float x = q[0];
	float y = q[1];
	float z = q[2];
	float w = q[3];
	float x2 = x + x;
	float y2 = y + y;
	float z2 = z + z;
	
	float xx = x * x2;
	float xy = x * y2;
	float xz = x * z2;
	float yy = y * y2;
	float yz = y * z2;
	float zz = z * z2;
	float wx = w * x2;
	float wy = w * y2;
	float wz = w * z2;
	float sx = s[0];
	float sy = s[1];
	float sz = s[2];

	Matrix4 out;
	out[0][0] = (1 - (yy + zz)) * sx;
	out[1][0] = (xy + wz) * sx;
	out[2][0] = (xz - wy) * sx;
	out[3][0] = 0;
	
	out[0][1] = (xy - wz) * sy;
	out[1][1] = (1 - (xx + zz)) * sy;
	out[2][1] = (yz + wx) * sy;
	out[3][1] = 0;
	
	out[0][2] = (xz + wy) * sz;
	out[1][2] = (yz - wx) * sz;
	out[2][2] = (1 - (xx + yy)) * sz;
	out[3][2] = 0;
	
	out[0][3] = v[0];
	out[1][3] = v[1];
	out[2][3] = v[2];
	out[3][3] = 1;

	return out;
}


static bool mapHasOwnProperty(const std::map<std::string, std::string>& map, const std::string& includeFileName)
{
	return map.find(includeFileName) != map.end();
}

static bool arrayIncludes(const std::vector<std::string>& arr, const std::string& fileName)
{
	for (auto& a : arr)
	{
		if (a == fileName)
			return true;
	}

	return false;
}

static int string_indexOf(const std::string& s1, const char* s2)
{
	return s1.find(s2);
}


#endif