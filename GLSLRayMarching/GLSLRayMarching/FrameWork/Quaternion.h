///////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v1												 //
// Date   : 14/Jun/2016											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#ifndef _Quaternion_h_
#define _Quaternion_h_

#include "Platform.h" 
#include "Component.h"
#include "Vector2.h"
#include "Matrix4.h"

template<class T>
class TQuaternion
{
public:
	static const int ms_iNext[3];
	static const TQuaternion Identity;
	static const TQuaternion Zero;

	TQuaternion()
	{
		// uninitialized for performance in array construction
	}

	TQuaternion(T fW, T fX, T fY, T fZ)
	{
		m[0] = fW;
		m[1] = fX;
		m[2] = fY;
		m[3] = fZ;
	}

	TQuaternion(const TQuaternion& rkQ)
	{
		size_t uiSize = 4 * sizeof(T);
		memcpy(m, rkQ.m, uiSize);
	}

	TQuaternion(const TMatrix4<T>& rkRot)
	{
		SetRotationMatrix(rkRot);
	}

	TQuaternion(const TVector3<T>& rkAxis, T fAngle)
	{
		SetAxisAngle(rkAxis, fAngle);
	}

	TQuaternion(const TVector3<T> akRotColumn[3])
	{
		SetRotationMatrix(akRotColumn);
	}

	TQuaternion(const T& Z, const T& X, const T& Y)
	{
		SetEulerAngleZYX(Z, Y, X);
	}

	void Set(T fW, T fX, T fY, T fZ)
	{
		m[0] = fW;
		m[1] = fX;
		m[2] = fY;
		m[3] = fZ;
	}

	operator const T* () const
	{
		return m;
	}

	operator T* ()
	{
		return m;
	}

	T operator[] (int i) const
	{
		assert(0 <= i && i <= 3);
		return m[i];
	}

	T& operator[] (int i)
	{
		assert(0 <= i && i <= 3);
		return m[i];
	}

	T W() const
	{
		return m[0];
	}

	T& W()
	{
		return m[0];
	}

	T X() const
	{
		return m[1];
	}

	T& X()
	{
		return m[1];
	}

	T Y() const
	{
		return m[2];
	}

	T& Y()
	{
		return m[2];
	}

	T Z() const
	{
		return m[3];
	}

	T& Z()
	{
		return m[3];
	}

	TQuaternion& operator= (const TQuaternion& rkQ)
	{
		size_t uiSize = 4 * sizeof(T);
		memcpy(m, rkQ.m, uiSize);
		return *this;
	}

	int CompareArrays(const TQuaternion& rkQ) const
	{
		return memcmp(m, rkQ.m, 4 * sizeof(T));
	}

	bool operator== (const TQuaternion& rkQ) const
	{
		return CompareArrays(rkQ) == 0;
	}

	bool operator!= (const TQuaternion& rkQ) const
	{
		return CompareArrays(rkQ) != 0;
	}

	bool operator< (const TQuaternion& rkQ) const
	{
		return CompareArrays(rkQ) < 0;
	}

	bool operator<= (const TQuaternion& rkQ) const
	{
		return CompareArrays(rkQ) <= 0;
	}

	bool operator> (const TQuaternion& rkQ) const
	{
		return CompareArrays(rkQ) > 0;
	}

	bool operator>= (const TQuaternion& rkQ) const
	{
		return CompareArrays(rkQ) >= 0;
	}

	TQuaternion operator+ (const TQuaternion& rkQ) const
	{
		TQuaternion kSum;
		for (int i = 0; i < 4; i++)
		{
			kSum.m[i] = m[i] + rkQ.m[i];
		}
		return kSum;
	}

	TQuaternion operator- (const TQuaternion& rkQ) const
	{
		TQuaternion kDiff;
		for (int i = 0; i < 4; i++)
		{
			kDiff.m[i] = m[i] - rkQ.m[i];
		}
		return kDiff;
	}

	TQuaternion operator* (const TQuaternion& rkQ) const
	{
		// NOTE:  Multiplication is not generally commutative, so in most
		// cases p*q != q*p.

		TQuaternion kProd;

		kProd.m[0] =
			m[0] * rkQ.m[0] -
			m[1] * rkQ.m[1] -
			m[2] * rkQ.m[2] -
			m[3] * rkQ.m[3];

		kProd.m[1] =
			m[0] * rkQ.m[1] +
			m[1] * rkQ.m[0] +
			m[2] * rkQ.m[3] -
			m[3] * rkQ.m[2];

		kProd.m[2] =
			m[0] * rkQ.m[2] +
			m[2] * rkQ.m[0] +
			m[3] * rkQ.m[1] -
			m[1] * rkQ.m[3];

		kProd.m[3] =
			m[0] * rkQ.m[3] +
			m[3] * rkQ.m[0] +
			m[1] * rkQ.m[2] -
			m[2] * rkQ.m[1];

		return kProd;
	}


	TQuaternion operator* (T fScalar) const
	{
		TQuaternion kProd;
		for (int i = 0; i < 4; i++)
		{
			kProd.m[i] = fScalar * m[i];
		}
		return kProd;
	}

	TQuaternion operator/ (T fScalar) const
	{
		TQuaternion kQuot;
		int i;

		if (fScalar != 0)
		{
			T fInvScalar = (1.0) / fScalar;
			for (i = 0; i < 4; i++)
			{
				kQuot.m[i] = fInvScalar * m[i];
			}
		}
		else
		{
			for (i = 0; i < 4; i++)
			{
				kQuot.m[i] = Math::MAX_REAL;
			}
		}

		return kQuot;
	}

	TQuaternion operator- () const
	{
		TQuaternion kNeg;
		for (int i = 0; i < 4; i++)
		{
			kNeg.m[i] = -m[i];
		}
		return kNeg;
	}

	friend TQuaternion operator* (T fScalar, const TQuaternion& rkQ)
	{
		TQuaternion kProd;
		for(int i = 0; i < 4; i++)
		{
			kProd[i] = fScalar * rkQ[i];
		}
		return kProd;
	}

	TQuaternion& operator+= (const TQuaternion& rkQ)
	{
		for (int i = 0; i < 4; i++)
		{
			m[i] += rkQ.m[i];
		}
		return *this;
	}

	TQuaternion& operator-= (const TQuaternion& rkQ)
	{
		for (int i = 0; i < 4; i++)
		{
			m[i] -= rkQ.m[i];
		}
		return *this;
	}

	TQuaternion& operator*= (T fScalar)
	{
		for (int i = 0; i < 4; i++)
		{
			m[i] *= fScalar;
		}
		return *this;
	}

	TQuaternion& operator/= (T fScalar)
	{
		int i;

		if (fScalar != 0)
		{
			T fInvScalar = (1.0) / fScalar;
			for (i = 0; i < 4; i++)
			{
				m[i] *= fInvScalar;
			}
		}
		else
		{
			for (i = 0; i < 4; i++)
			{
				m[i] = Math::MAX_REAL;
			}
		}

		return *this;
	}

	TQuaternion& SetRotationMatrix(const TMatrix4<T>& rkRot)
	{
		// Algorithm in Ken Shoemake's article in 1987 SIGGRAPH course notes
		// article "TQuaternion Calculus and Fast Animation".

		T fTrace = rkRot(0, 0) + rkRot(1, 1) + rkRot(2, 2);
		T fRoot;

		if (fTrace > 0)
		{
			// |w| > 1/2, may as well choose w > 1/2
			fRoot = Math::Sqrt(fTrace + 1);  // 2w
			m[0] = (0.5) * fRoot;
			fRoot = (0.5) / fRoot;  // 1/(4w)
			m[1] = (rkRot(2, 1) - rkRot(1, 2)) * fRoot;
			m[2] = (rkRot(0, 2) - rkRot(2, 0)) * fRoot;
			m[3] = (rkRot(1, 0) - rkRot(0, 1)) * fRoot;
		}
		else
		{
			// |w| <= 1/2
			int i = 0;
			if (rkRot(1, 1) > rkRot(0, 0))
			{
				i = 1;
			}
			if (rkRot(2, 2) > rkRot(i, i))
			{
				i = 2;
			}
			int j = ms_iNext[i];
			int k = ms_iNext[j];

			fRoot = Math::Sqrt(rkRot(i, i) - rkRot(j, j) - rkRot(k, k) + 1);
			T* apfQuat[3] = { &m[1], &m[2], &m[3] };
			*apfQuat[i] = (0.5) * fRoot;
			fRoot = (0.5) / fRoot;
			m[0] = (rkRot(k, j) - rkRot(j, k)) * fRoot;
			*apfQuat[j] = (rkRot(j, i) + rkRot(i, j)) * fRoot;
			*apfQuat[k] = (rkRot(k, i) + rkRot(i, k)) * fRoot;
		}

		return *this;
	}

	void GetRotationMatrix(TMatrix4<T>& rkRot) const
	{
		T fTx = (2.0) * m[1];
		T fTy = (2.0) * m[2];
		T fTz = (2.0) * m[3];
		T fTwx = fTx * m[0];
		T fTwy = fTy * m[0];
		T fTwz = fTz * m[0];
		T fTxx = fTx * m[1];
		T fTxy = fTy * m[1];
		T fTxz = fTz * m[1];
		T fTyy = fTy * m[2];
		T fTyz = fTz * m[2];
		T fTzz = fTz * m[3];

		rkRot[0][0] = 1f - (fTyy + fTzz);
		rkRot[0][1] = fTxy - fTwz;
		rkRot[0][2] = fTxz + fTwy;
		rkRot[0][3] = 0;

		rkRot[1][0] = fTxy + fTwz;
		rkRot[1][1] = 1f - (fTxx + fTzz);
		rkRot[1][2] = fTyz - fTwx;
		rkRot[1][3] = 0;

		rkRot[2][0] = fTxz - fTwy;
		rkRot[2][1] = fTyz + fTwx;
		rkRot[2][2] = 1f - (fTxx + fTyy);
		rkRot[2][3] = 0;

		rkRot[3][0] = 0;
		rkRot[3][1] = 0;
		rkRot[3][2] = 0;
		rkRot[3][3] = 1;
	}

	TQuaternion& SetRotationMatrix(const TVector3<T> akRotColumn[3])
	{
		TMatrix4<T> kRot;
		for (int iCol = 0; iCol < 3; iCol++)
		{
			kRot(0, iCol) = akRotColumn[iCol][0];
			kRot(1, iCol) = akRotColumn[iCol][1];
			kRot(2, iCol) = akRotColumn[iCol][2];
		}
		return FromRotationMatrix(kRot);
	}

	void GetRotationMatrix(TVector3<T> akRotColumn[3]) const
	{
		TMatrix4<T> kRot;
		ToRotationMatrix(kRot);
		for (int iCol = 0; iCol < 3; iCol++)
		{
			akRotColumn[0][iCol] = kRot(0, iCol);
			akRotColumn[1][iCol] = kRot(1, iCol);
			akRotColumn[2][iCol] = kRot(2, iCol);
		}
	}

	TQuaternion& SetAxisAngle(const TVector3<T>& rkAxis, T fAngle)
	{
		// assert:  axis[] is unit length
		//
		// The TQuaternion representing the rotation is
		//   q = cos(A/2)+sin(A/2)*(x*i+y*j+z*k)

		T fHalfAngle = (0.5) * fAngle;
		T fSin = Math::Sin(fHalfAngle);
		m[0] = Math::Cos(fHalfAngle);
		m[1] = fSin * rkAxis[0];
		m[2] = fSin * rkAxis[1];
		m[3] = fSin * rkAxis[2];

		return *this;
	}

	void GetAxisAngle(TVector3<T>& rkAxis, T& rfAngle) const
	{
		// The TQuaternion representing the rotation is
		//   q = cos(A/2)+sin(A/2)*(x*i+y*j+z*k)

		T fSqrLength = m[1] * m[1] + m[2] * m[2]
			+ m[3] * m[3];
		if (fSqrLength > Math::ZERO_TOLERANCE)
		{
			rfAngle = (2.0) * Math::ACos(m[0]);
			T fInvLength = Math::InvSqrt(fSqrLength);
			rkAxis[0] = m[1] * fInvLength;
			rkAxis[1] = m[2] * fInvLength;
			rkAxis[2] = m[3] * fInvLength;
		}
		else
		{
			// angle is 0 (mod 2*pi), so any axis will do
			rfAngle = 0;
			rkAxis[0] = 1;
			rkAxis[1] = 0;
			rkAxis[2] = 0;
		}
	}

	void SetEulerAngleXYZ(const T& X, const T& Y, const T& Z)
	{
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		double cx = Math::Cos(X * 0.5);
		double sx = Math::Sin(X * 0.5);
		double cy = Math::Cos(Y * 0.5);
		double sy = Math::Sin(Y * 0.5);
		double cz = Math::Cos(Z * 0.5);
		double sz = Math::Sin(Z * 0.5);

		m[0] = cx * cy * cz + sx * sy * sz;
		m[1] = sx * cy * cz - cx * sy * sz;
		m[2] = cx * sy * cz + sx * cy * sz;
		m[3] = cx * cy * sz - sx * sy * cz;
	}

	void SetEulerAngleXZY(const T& X, const T& Z, const T& Y)
	{
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		double cx = Math::Cos(X * 0.5);
		double sx = Math::Sin(X * 0.5);
		double cy = Math::Cos(Y * 0.5);
		double sy = Math::Sin(Y * 0.5);
		double cz = Math::Cos(Z * 0.5);
		double sz = Math::Sin(Z * 0.5);

		m[0] = cx * cz * cy + sx * sz * sy;
		m[1] = sx * cz * cy - cx * sz * sy;
		m[2] = cx * sz * cy + sx * cz * sy;
		m[3] = cx * cz * sy - sx * sz * cy;
	}

	void SetEulerAngleYXZ(const T& Y, const T& X, const T& Z)
	{
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		double cx = Math::Cos(X * 0.5);
		double sx = Math::Sin(X * 0.5);
		double cy = Math::Cos(Y * 0.5);
		double sy = Math::Sin(Y * 0.5);
		double cz = Math::Cos(Z * 0.5);
		double sz = Math::Sin(Z * 0.5);

		m[0] = cy * cx * cz + sy * sx * sz;
		m[1] = sy * cx * cz - cy * sx * sz;
		m[2] = cy * sx * cz + sy * cx * sz;
		m[3] = cy * cx * sz - sy * sx * cz;
	}

	void SetEulerAngleYZX(const T& Y, const T& Z, const T& X)
	{
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		double cx = Math::Cos(X * 0.5);
		double sx = Math::Sin(X * 0.5);
		double cy = Math::Cos(Y * 0.5);
		double sy = Math::Sin(Y * 0.5);
		double cz = Math::Cos(Z * 0.5);
		double sz = Math::Sin(Z * 0.5);

		m[0] = cy * cz * cx + sy * sz * sx;
		m[1] = sy * cz * cx - cy * sz * sx;
		m[2] = cy * sz * cx + sy * cz * sx;
		m[3] = cy * cz * sx - sy * sz * cx;
	}

	void SetEulerAngleZXY(const T& Z, const T& X, const T& Y)
	{
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		double cx = Math::Cos(X * 0.5);
		double sx = Math::Sin(X * 0.5);
		double cy = Math::Cos(Y * 0.5);
		double sy = Math::Sin(Y * 0.5);
		double cz = Math::Cos(Z * 0.5);
		double sz = Math::Sin(Z * 0.5);

		m[0] = cz * cx * cy + sz * sx * sy;
		m[1] = sz * cx * cy - cz * sx * sy;
		m[2] = cz * sx * cy + sz * cx * sy;
		m[3] = cz * cx * sy - sz * sx * cy;
	}

	void SetEulerAngleZYX(const T& Y, const T& Z, const T& X)
	{
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		double cx = Math::Cos(X * 0.5);
		double sx = Math::Sin(X * 0.5);
		double cy = Math::Cos(Y * 0.5);
		double sy = Math::Sin(Y * 0.5);
		double cz = Math::Cos(Z * 0.5);
		double sz = Math::Sin(Z * 0.5);

		m[0] = cz * cy * cx + sz * sy * sx;
		m[1] = sz * cy * cx - cz * sy * sx;
		m[2] = cz * sy * cx + sz * cy * sx;
		m[3] = cz * cy * sx - sz * sy * cx;
	}

	void GetEulerAngleZXY(T& Z, T& X, T& Y)
	{
		/*
		double test = q1.x*q1.y + q1.z*q1.w;
		if (test > 0.499) { // singularity at north pole
			heading = 2 * atan2(q1.x,q1.w);
			attitude = Math.PI/2;
			bank = 0;
			return;
		}	if (test < -0.499) { // singularity at south pole
			heading = -2 * atan2(q1.x,q1.w);
			attitude = - Math.PI/2;
			bank = 0;
			return;
		}    double sqx = q1.x*q1.x;    double sqy = q1.y*q1.y;    double sqz = q1.z*q1.z;
		heading = atan2(2*q1.y*q1.w-2*q1.x*q1.z , 1 - 2*sqy - 2*sqz);
		attitude = asin(2*test);
		bank = atan2(2*q1.x*q1.w-2*q1.y*q1.z , 1 - 2*sqx - 2*sqz)
		*/

		double test = m[1] * m[2] + m[3] * m[0];
		if (test > 0.499)
		{
			// singularity at north pole
			Y = 2 * Math::ATan2(m[1], m[0]);
			X = Math::OnePi / 2;
			Z = 0;
			return;
		}
		if (test < -0.499)
		{
			// singularity at south pole
			Y = -2 * Math::ATan2(m[1], m[0]);
			X = -Math::OnePi / 2;
			Z = 0;
			return;
		}

		T sqx = m[1] * m[1];
		T sqy = m[2] * m[2];
		T sqz = m[3] * m[3];
		Y = Math::ATan2(2 * m[2] * m[0] - 2 * m[1] * m[3], 1 - 2 * sqy - 2 * sqz);
		X = Math::ASin(2 * test);
		Z = Math::ATan2(2 * m[1] * m[0] - 2 * m[2] * m[3], 1 - 2 * sqx - 2 * sqz);
	}

	T Length() const
	{
		return Math::Sqrt(
			m[0] * m[0] +
			m[1] * m[1] +
			m[2] * m[2] +
			m[3] * m[3]);
	}

	T SquaredLength() const
	{
		return
			m[0] * m[0] +
			m[1] * m[1] +
			m[2] * m[2] +
			m[3] * m[3];
	}

	T Dot(const TQuaternion& rkQ) const
	{
		T fDot = 0;
		for (int i = 0; i < 4; i++)
		{
			fDot += m[i] * rkQ.m[i];
		}
		return fDot;
	}

	T Normalize()
	{
		T fLength = Length();
		int i;

		if (fLength > Math::ZERO_TOLERANCE)
		{
			T fInvLength = (1.0) / fLength;
			for (i = 0; i < 4; i++)
			{
				m[i] *= fInvLength;
			}
		}
		else
		{
			fLength = 0;
			for (i = 0; i < 4; i++)
			{
				m[i] = 0;
			}
		}

		return fLength;
	}

	TQuaternion Inverse() const
	{
		TQuaternion kInverse;

		T fNorm = 0;
		int i;
		for (i = 0; i < 4; i++)
		{
			fNorm += m[i] * m[i];
		}

		if (fNorm > 0)
		{
			T fInvNorm = (1.0) / fNorm;
			kInverse.m[0] = m[0] * fInvNorm;
			kInverse.m[1] = -m[1] * fInvNorm;
			kInverse.m[2] = -m[2] * fInvNorm;
			kInverse.m[3] = -m[3] * fInvNorm;
		}
		else
		{
			// return an invalid result to flag the error
			for (i = 0; i < 4; i++)
			{
				kInverse.m[i] = 0;
			}
		}

		return kInverse;
	}

	TQuaternion Conjugate() const
	{
		return TQuaternion(m[0], -m[1], -m[2], -m[3]);
	}

	TQuaternion Exp() const
	{
		// If q = A*(x*i+y*j+z*k) where (x,y,z) is unit length, then
		// exp(q) = cos(A)+sin(A)*(x*i+y*j+z*k).  If sin(A) is near zero,
		// use exp(q) = cos(A)+A*(x*i+y*j+z*k) since A/sin(A) has limit 1.

		TQuaternion kResult;

		T fAngle = Math::Sqrt(m[1] * m[1] +	m[2] * m[2] + m[3] * m[3]);

		T fSin = Math::Sin(fAngle);
		kResult.m[0] = Math::Cos(fAngle);

		int i;

		if (Math::FAbs(fSin) >= Math::ZERO_TOLERANCE)
		{
			T fCoeff = fSin / fAngle;
			for (i = 1; i <= 3; i++)
			{
				kResult.m[i] = fCoeff * m[i];
			}
		}
		else
		{
			for (i = 1; i <= 3; i++)
			{
				kResult.m[i] = m[i];
			}
		}

		return kResult;
	}

	TQuaternion Log() const
	{
		// If q = cos(A)+sin(A)*(x*i+y*j+z*k) where (x,y,z) is unit length, then
		// log(q) = A*(x*i+y*j+z*k).  If sin(A) is near zero, use log(q) =
		// sin(A)*(x*i+y*j+z*k) since sin(A)/A has limit 1.

		TQuaternion kResult;
		kResult.m[0] = 0;

		int i;

		if (Math::FAbs(m[0]) < 1)
		{
			T fAngle = Math::ACos(m[0]);
			T fSin = Math::Sin(fAngle);
			if (Math::FAbs(fSin) >= Math::ZERO_TOLERANCE)
			{
				T fCoeff = fAngle / fSin;
				for (i = 1; i <= 3; i++)
				{
					kResult.m[i] = fCoeff * m[i];
				}
				return kResult;
			}
		}

		for (i = 1; i <= 3; i++)
		{
			kResult.m[i] = m[i];
		}
		return kResult;
	}

	TVector3<T> Rotate(const TVector3<T>& rkVector) const
	{
		// Given a vector u = (x0,y0,z0) and a unit length TQuaternion
		// q = <w,x,y,z>, the vector v = (x1,y1,z1) which represents the
		// rotation of u by q is v = q*u*q^{-1} where * indicates TQuaternion
		// multiplication and where u is treated as the TQuaternion <0,x0,y0,z0>.
		// Note that q^{-1} = <w,-x,-y,-z>, so no T work is required to
		// invert q.  Now
		//
		//   q*u*q^{-1} = q*<0,x0,y0,z0>*q^{-1}
		//     = q*(x0*i+y0*j+z0*k)*q^{-1}
		//     = x0*(q*i*q^{-1})+y0*(q*j*q^{-1})+z0*(q*k*q^{-1})
		//
		// As 3-vectors, q*i*q^{-1}, q*j*q^{-1}, and 2*k*q^{-1} are the columns
		// of the rotation matrix computed in ToRotationMatrix.
		// The vector v is obtained as the product of that rotation matrix with
		// vector u.  As such, the TQuaternion representation of a rotation
		// matrix requires less space than the matrix and more time to compute
		// the rotated vector.  Typical space-time tradeoff...

		TMatrix4<T> kRot;
		ToRotationMatrix(kRot);
		return kRot * rkVector;
	}

	TQuaternion& Slerp(T fT, const TQuaternion& rkP, const TQuaternion& rkQ)
	{
		T fCos = rkP.Dot(rkQ);
		T fAngle = Math::ACos(fCos);

		if (Math::FAbs(fAngle) >= Math::ZERO_TOLERANCE)
		{
			T fSin = Math::Sin(fAngle);
			T fInvSin = (1.0) / fSin;
			T fCoeff0 = Math::Sin((1 - fT) * fAngle) * fInvSin;
			T fCoeff1 = Math::Sin(fT * fAngle) * fInvSin;
			*this = fCoeff0 * rkP + fCoeff1 * rkQ;
		}
		else
		{
			*this = rkP;
		}

		return *this;
	}

	TQuaternion& SlerpExtraSpins(T fT,
		const TQuaternion& rkP, const TQuaternion& rkQ, int iExtraSpins)
	{
		T fCos = rkP.Dot(rkQ);
		T fAngle = Math::ACos(fCos);

		if (Math::FAbs(fAngle) >= Math::ZERO_TOLERANCE)
		{
			T fSin = Math::Sin(fAngle);
			T fPhase = Math::OnePi * iExtraSpins * fT;
			T fInvSin = (1.0) / fSin;
			T fCoeff0 = Math::Sin((1 - fT) * fAngle - fPhase) * fInvSin;
			T fCoeff1 = Math::Sin(fT * fAngle + fPhase) * fInvSin;
			*this = fCoeff0 * rkP + fCoeff1 * rkQ;
		}
		else
		{
			*this = rkP;
		}

		return *this;
	}

	TQuaternion& Intermediate(const TQuaternion& rkQ0,
		const TQuaternion& rkQ1, const TQuaternion& rkQ2)
	{
		// assert:  Q0, Q1, Q2 all unit-length
		TQuaternion kQ1Inv = rkQ1.Conjugate();
		TQuaternion kP0 = kQ1Inv * rkQ0;
		TQuaternion kP2 = kQ1Inv * rkQ2;
		TQuaternion kArg = -(0.25) * (kP0.Log() + kP2.Log());
		TQuaternion kA = rkQ1 * kArg.Exp();
		*this = kA;

		return *this;
	}

	TQuaternion& Squad(T fT, const TQuaternion& rkQ0,
		const TQuaternion& rkA0, const TQuaternion& rkA1, const TQuaternion& rkQ1)
	{
		T fSlerpT = (2.0) * fT * (1 - fT);
		TQuaternion kSlerpP = Slerp(fT, rkQ0, rkQ1);
		TQuaternion kSlerpQ = Slerp(fT, rkA0, rkA1);
		return Slerp(fSlerpT, kSlerpP, kSlerpQ);
	}

	TQuaternion& Align(const TVector3<T>& rkV1,
		const TVector3<T>& rkV2)
	{
		// If V1 and V2 are not parallel, the axis of rotation is the unit-length
		// vector U = Cross(V1,V2)/Length(Cross(V1,V2)).  The angle of rotation,
		// A, is the angle between V1 and V2.  The TQuaternion for the rotation is
		// q = cos(A/2) + sin(A/2)*(ux*i+uy*j+uz*k) where U = (ux,uy,uz).
		//
		// (1.0) Rather than extract A = acos(Dot(V1,V2)), multiply by 1/2, then
		//     compute sin(A/2) and cos(A/2), we reduce the computational costs by
		//     computing the bisector B = (V1+V2)/Length(V1+V2), so cos(A/2) =
		//     Dot(V1,B).
		//
		// (2) The rotation axis is U = Cross(V1,B)/Length(Cross(V1,B)), but
		//     Length(Cross(V1,B)) = Length(V1)*Length(B)*sin(A/2) = sin(A/2), in
		//     which case sin(A/2)*(ux*i+uy*j+uz*k) = (cx*i+cy*j+cz*k) where
		//     C = Cross(V1,B).
		//
		// If V1 = V2, then B = V1, cos(A/2) = 1, and U = (0,0,0).  If V1 = -V2,
		// then B = 0.  This can happen even if V1 is approximately -V2 using
		// Ting point arithmetic, since TVector3<T>::Normalize checks for
		// closeness to zero and returns the zero vector accordingly.  The test
		// for exactly zero is usually not recommend for Ting point
		// arithmetic, but the implementation of TVector3<T>::Normalize guarantees
		// the comparison is robust.  In this case, the A = pi and any axis
		// perpendicular to V1 may be used as the rotation axis.

		TVector3<T> kBisector = rkV1 + rkV2;
		kBisector.Normalize();

		T fCosHalfAngle = rkV1.Dot(kBisector);
		TVector3<T> kCross;

		m[0] = fCosHalfAngle;

		if (fCosHalfAngle != 0)
		{
			kCross = rkV1.Cross(kBisector);
			m[1] = kCross.X();
			m[2] = kCross.Y();
			m[3] = kCross.Z();
		}
		else
		{
			T fInvLength;
			if (Math::FAbs(rkV1[0]) >= Math::FAbs(rkV1[1]))
			{
				// V1.x or V1.z is the largest magnitude component
				fInvLength = Math::InvSqrt(rkV1[0] * rkV1[0] + rkV1[2] * rkV1[2]);
				m[1] = -rkV1[2] * fInvLength;
				m[2] = 0;
				m[3] = +rkV1[0] * fInvLength;
			}
			else
			{
				// V1.y or V1.z is the largest magnitude component
				fInvLength = Math::InvSqrt(rkV1[1] * rkV1[1] + rkV1[2] * rkV1[2]);
				m[1] = 0;
				m[2] = +rkV1[2] * fInvLength;
				m[3] = -rkV1[1] * fInvLength;
			}
		}

		return *this;
	}

	void DecomposeTwistTimesSwing(const TVector3<T>& rkV1, TQuaternion& rkTwist, TQuaternion& rkSwing)
	{
		TVector3<T> kV2 = Rotate(rkV1);
		rkSwing = Align(rkV1, kV2);
		rkTwist = (*this) * rkSwing.Conjugate();
	}

	void DecomposeSwingTimesTwist(const TVector3<T>& rkV1, TQuaternion& rkSwing, TQuaternion& rkTwist)
	{
		TVector3<T> kV2 = Rotate(rkV1);
		rkSwing = Align(rkV1, kV2);
		rkTwist = rkSwing.Conjugate() * (*this);
	}
private:
	T m[4];
};

typedef TQuaternion<int> IQuaternion;
typedef TQuaternion<float> Quaternion;
typedef TQuaternion<double> DQuaternion;

#endif