//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Vector3_h_
#define _Vector3_h_

#include "Platform.h"
#include "Maths.h"
#include "InputStream.h"
#include "OutputStream.h"

template<class T>
class TVector3
{
public:
	TVector3()
	{
		// uninitialized for performance in array construction
	}

	TVector3(T x, T y, T z)
	{
		m[0] = x;
		m[1] = y;
		m[2] = z;
	}

	TVector3(const T* v)
	{
		m[0] = v[0];
		m[1] = v[1];
		m[2] = v[2];
	}

	TVector3(const TVector3& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
	}

	void Set(T x, T y, T z)
	{
		m[0] = x;
		m[1] = y;
		m[2] = z;
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
		Assert(0 <= i && i <= 2);
		return m[i];
	}

	T& operator[] (int i)
	{
		Assert(0 <= i && i <= 2);
		return m[i];
	}

	T X() const
	{
		return m[0];
	}

	T& X()
	{
		return m[0];
	}

	T Y() const
	{
		return m[1];
	}

	T& Y()
	{
		return m[1];
	}

	T Z() const
	{
		return m[2];
	}

	T& Z()
	{
		return m[2];
	}

	TVector3& operator= (const TVector3& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		return *this;
	}

	int CompareArrays(const TVector3& v) const
	{
		return MemCmp(m, v.m, 3 * sizeof(T));
	}

	bool operator!= (const TVector3& v) const
	{
		return CompareArrays(v) != 0;
	}

	bool operator== (const TVector3& other) const
	{
		// return CompareArrays(v) == 0;
		return m[0] == other.m[0] && m[1] == other.m[1] && m[2] == other.m[2];
	}

	bool operator < (const TVector3& other) const
	{
		bool less = false;

		if (m[0] < other.m[0])
		{
			less = true;
		}
		else if (m[0] == other.m[0])
		{
			if (m[1] < other.m[1])
			{
				less = true;
			}
			else if (m[1] == other.m[1])
			{
				less = (m[2] < other.m[2]);
			}
		}

		return less;
	}

	bool operator> (const TVector3& v) const
	{
		return CompareArrays(v) > 0;
	}

	bool operator>= (const TVector3& v) const
	{
		return CompareArrays(v) >= 0;
	}

	TVector3 operator- () const
	{
		return TVector3(-m[0], -m[1], -m[2]);
	}

	friend TVector3 operator + (const TVector3& v0, const TVector3& v1)
	{
		return TVector3
		(
			v0.m[0] + v1.m[0],
			v0.m[1] + v1.m[1],
			v0.m[2] + v1.m[2]
		);
	}

	friend TVector3 operator - (const TVector3& v0, const TVector3& v1)
	{
		return TVector3
		(
			v0.m[0] - v1.m[0],
			v0.m[1] - v1.m[1],
			v0.m[2] - v1.m[2]
		);
	}

	friend TVector3 operator * (const TVector3& v0, const TVector3& v1)
	{
		return TVector3
		(
			v0.m[0] * v1.m[0],
			v0.m[1] * v1.m[1],
			v0.m[2] * v1.m[2]
		);
	}

	friend TVector3 operator / (const TVector3& v0, const TVector3& v1)
	{
		return TVector3
		(
			v0.m[0] / v1.m[0],
			v0.m[1] / v1.m[1],
			v0.m[2] / v1.m[2]
		);
	}

	friend TVector3 operator * (const TVector3& v, T scalar)
	{
		return TVector3
		(
			v.m[0] * scalar,
			v.m[1] * scalar,
			v.m[2] * scalar
		);
	}

	friend TVector3 operator / (const TVector3& v, T scalar)
	{
		TVector3 quotient;

		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			quotient.m[0] = invScalar * v.m[0];
			quotient.m[1] = invScalar * v.m[1];
			quotient.m[2] = invScalar * v.m[2];
		}
		else
		{
			quotient.m[0] = Math::MaxValue;
			quotient.m[1] = Math::MaxValue;
			quotient.m[2] = Math::MaxValue;
		}

		return quotient;
	}

	friend TVector3 operator * (T scalar, const TVector3& v)
	{
		return v * scalar;
	}

	TVector3& operator+= (const TVector3& v)
	{
		m[0] += v.m[0];
		m[1] += v.m[1];
		m[2] += v.m[2];

		return *this;
	}

	TVector3& operator-= (const TVector3& v)
	{
		m[0] -= v.m[0];
		m[1] -= v.m[1];
		m[2] -= v.m[2];

		return *this;
	}

	TVector3& operator*= (const TVector3& v)
	{
		m[0] *= v.m[0];
		m[1] *= v.m[1];
		m[2] *= v.m[2];

		return *this;
	}

	TVector3& operator/= (const TVector3& v)
	{
		m[0] /= v.m[0];
		m[1] /= v.m[1];
		m[2] /= v.m[2];

		return *this;
	}

	TVector3& operator*= (T scalar)
	{
		m[0] *= scalar;
		m[1] *= scalar;
		m[2] *= scalar;

		return *this;
	}

	TVector3& operator/= (T scalar)
	{
		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			m[0] *= invScalar;
			m[1] *= invScalar;
			m[2] *= invScalar;
		}
		else
		{
			m[0] = Math::MaxFloat;
			m[1] = Math::MaxFloat;
			m[2] = Math::MaxFloat;
		}

		return *this;
	}

	T Length() const
	{
		return Math::Sqrt(SquaredLength());
	}

	T SquaredLength() const
	{
		return
			m[0] * m[0] +
			m[1] * m[1] +
			m[2] * m[2];
	}

	T Dot(const TVector3& v) const
	{
		return
			m[0] * v.m[0] +
			m[1] * v.m[1] +
			m[2] * v.m[2];
	}

	T Normalize()
	{
		T length = Length();

		if (length > Math::Epsilon)
		{
			T invLength = 1.0f / length;
			m[0] *= invLength;
			m[1] *= invLength;
			m[2] *= invLength;
		}
		else
		{
			length = 0.0f;
			m[0] = 0.0f;
			m[1] = 0.0f;
			m[2] = 0.0f;
		}

		return length;
	}

	TVector3 Cross(const TVector3& v) const
	{
		return TVector3
		(
			m[1] * v.m[2] - m[2] * v.m[1],
			m[2] * v.m[0] - m[0] * v.m[2],
			m[0] * v.m[1] - m[1] * v.m[0]
		);
	}

	TVector3 UnitCross(const TVector3& v) const
	{
		TVector3 result
		(
			m[1] * v.m[2] - m[2] * v.m[1],
			m[2] * v.m[0] - m[0] * v.m[2],
			m[0] * v.m[1] - m[1] * v.m[0]
		);
		result.Normalize();
		return result;
	}

	void GetBarycentrics(const TVector3& v0,
		const TVector3& v1, const TVector3& v2,
		const TVector3& v3, T bary[4]) const
	{
		TVector3 diff[4] =
		{
			v0 - v3,
			v1 - v3,
			v2 - v3,
			*this - v3
		};

		T maxValue = 0.0f;
		int i;
		for (i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				T value = Math::FAbs(diff[i][j]);
				if (value > maxValue)
				{
					maxValue = value;
				}
			}
		}

		// scale down only large data
		if (maxValue > 1.0)
		{
			T invMax = 1.0f / maxValue;
			for (i = 0; i < 4; i++)
			{
				diff[i] *= invMax;
			}
		}

		T det = diff[0].Dot(diff[1].Cross(diff[2]));
		TVector3 e1ce2 = diff[1].Cross(diff[2]);
		TVector3 e2ce0 = diff[2].Cross(diff[0]);
		TVector3 e0ce1 = diff[0].Cross(diff[1]);
		if (Math::FAbs(det) > Math::ZeroTolerance)
		{
			T invDet = 1.0f / det;
			bary[0] = diff[3].Dot(e1ce2) * invDet;
			bary[1] = diff[3].Dot(e2ce0) * invDet;
			bary[2] = diff[3].Dot(e0ce1) * invDet;
			bary[3] = 1.0f - bary[0] - bary[1] - bary[2];
		}
		else
		{
			TVector3 e02 = v0 - v2;
			TVector3 e12 = v1 - v2;
			TVector3 e02ce12 = e02.Cross(e12);
			T maxSqrArea = e02ce12.SquaredLength();
			int maxIndex = 3;
			T sqrArea = e0ce1.SquaredLength();
			if (sqrArea > maxSqrArea)
			{
				maxIndex = 0;
				maxSqrArea = sqrArea;
			}
			sqrArea = e1ce2.SquaredLength();
			if (sqrArea > maxSqrArea)
			{
				maxIndex = 1;
				maxSqrArea = sqrArea;
			}
			sqrArea = e2ce0.SquaredLength();
			if (sqrArea > maxSqrArea)
			{
				maxIndex = 2;
				maxSqrArea = sqrArea;
			}

			if (maxSqrArea > Math::ZeroTolerance)
			{
				T invSqrArea = 1.0f / maxSqrArea;
				TVector3 tmp;
				if (maxIndex == 0)
				{
					tmp = diff[3].Cross(diff[1]);
					bary[0] = e0ce1.Dot(tmp) * invSqrArea;
					tmp = diff[0].Cross(diff[3]);
					bary[1] = e0ce1.Dot(tmp) * invSqrArea;
					bary[2] = 0.0f;
					bary[3] = 1.0f - bary[0] - bary[1];
				}
				else if (maxIndex == 1)
				{
					bary[0] = 0.0f;
					tmp = diff[3].Cross(diff[2]);
					bary[1] = e1ce2.Dot(tmp) * invSqrArea;
					tmp = diff[1].Cross(diff[3]);
					bary[2] = e1ce2.Dot(tmp) * invSqrArea;
					bary[3] = 1.0f - bary[1] - bary[2];
				}
				else if (maxIndex == 2)
				{
					tmp = diff[2].Cross(diff[3]);
					bary[0] = e2ce0.Dot(tmp) * invSqrArea;
					bary[1] = 0.0f;
					tmp = diff[3].Cross(diff[0]);
					bary[2] = e2ce0.Dot(tmp) * invSqrArea;
					bary[3] = 1.0f - bary[0] - bary[2];
				}
				else
				{
					diff[3] = *this - v2;
					tmp = diff[3].Cross(e12);
					bary[0] = e02ce12.Dot(tmp) * invSqrArea;
					tmp = e02.Cross(diff[3]);
					bary[1] = e02ce12.Dot(tmp) * invSqrArea;
					bary[2] = 1.0f - bary[0] - bary[1];
					bary[3] = 0.0f;
				}
			}
			else
			{
				T maxSqrLength = diff[0].SquaredLength();
				maxIndex = 0;  // <V0,V3>
				T sqrLength = diff[1].SquaredLength();
				if (sqrLength > maxSqrLength)
				{
					maxIndex = 1;  // <V1,V3>
					maxSqrLength = sqrLength;
				}
				sqrLength = diff[2].SquaredLength();
				if (sqrLength > maxSqrLength)
				{
					maxIndex = 2;  // <V2,V3>
					maxSqrLength = sqrLength;
				}
				sqrLength = e02.SquaredLength();
				if (sqrLength > maxSqrLength)
				{
					maxIndex = 3;  // <V0,V2>
					maxSqrLength = sqrLength;
				}
				sqrLength = e12.SquaredLength();
				if (sqrLength > maxSqrLength)
				{
					maxIndex = 4;  // <V1,V2>
					maxSqrLength = sqrLength;
				}
				TVector3 kE01 = v0 - v1;
				sqrLength = kE01.SquaredLength();
				if (sqrLength > maxSqrLength)
				{
					maxIndex = 5;  // <V0,V1>
					maxSqrLength = sqrLength;
				}

				if (maxSqrLength > Math::ZeroTolerance)
				{
					T invSqrLength = 1.0f / maxSqrLength;
					if (maxIndex == 0)
					{
						// P-V3 = t*(V0-V3)
						bary[0] = diff[3].Dot(diff[0]) * invSqrLength;
						bary[1] = 0.0f;
						bary[2] = 0.0f;
						bary[3] = 1.0f - bary[0];
					}
					else if (maxIndex == 1)
					{
						// P-V3 = t*(V1-V3)
						bary[0] = 0.0f;
						bary[1] = diff[3].Dot(diff[1]) * invSqrLength;
						bary[2] = 0.0f;
						bary[3] = 1.0f - bary[1];
					}
					else if (maxIndex == 2)
					{
						// P-V3 = t*(V2-V3)
						bary[0] = 0.0f;
						bary[1] = 0.0f;
						bary[2] = diff[3].Dot(diff[2]) * invSqrLength;
						bary[3] = 1.0f - bary[2];
					}
					else if (maxIndex == 3)
					{
						// P-V2 = t*(V0-V2)
						diff[3] = *this - v2;
						bary[0] = diff[3].Dot(e02) * invSqrLength;
						bary[1] = 0.0f;
						bary[2] = 1.0f - bary[0];
						bary[3] = 0.0f;
					}
					else if (maxIndex == 4)
					{
						// P-V2 = t*(V1-V2)
						diff[3] = *this - v2;
						bary[0] = 0.0f;
						bary[1] = diff[3].Dot(e12) * invSqrLength;
						bary[2] = 1.0f - bary[1];
						bary[3] = 0.0f;
					}
					else
					{
						// P-V1 = t*(V0-V1)
						diff[3] = *this - v1;
						bary[0] = diff[3].Dot(kE01) * invSqrLength;
						bary[1] = 1.0f - bary[0];
						bary[2] = 0.0f;
						bary[3] = 0.0f;
					}
				}
				else
				{
					// tetrahedron is a nearly a point, just return equal weights
					bary[0] = 0.25f;
					bary[1] = bary[0];
					bary[2] = bary[0];
					bary[3] = bary[0];
				}
			}
		}
	}

	void Orthonormalize(TVector3& u, TVector3& v, TVector3& w)
	{
		// compute u0
		u.Normalize();

		// compute u1
		T dot0 = u.Dot(v);
		v -= u * dot0;
		v.Normalize();

		// compute u2
		T dot1 = v.Dot(w);
		dot0 = u.Dot(w);
		w -= u * dot0 + v * dot1;
		w.Normalize();
	}

	void Orthonormalize(TVector3* v)
	{
		Orthonormalize(v[0], v[1], v[2]);
	}

	void GenerateOrthonormalBasis(TVector3& u, TVector3& v, TVector3& w, bool unitLength = false)
	{
		if (!unitLength)
		{
			w.Normalize();
		}

		T invLength;

		if (Math::FAbs(w.m[0]) >= Math::FAbs(w.m[1]))
		{
			invLength = Math::InvSqrt(w.m[0] * w.m[0] + w.m[2] * w.m[2]);
			u.m[0] = -w.m[2] * invLength;
			u.m[1] = 0.0f;
			u.m[2] = +w.m[0] * invLength;
			v.m[0] = w.m[1] * u.m[2];
			v.m[1] = w.m[2] * u.m[0] - w.m[0] * u.m[2];
			v.m[2] = -w.m[1] * u.m[0];
		}
		else
		{
			invLength = Math::InvSqrt(w.m[1] * w.m[1] + w.m[2] * w.m[2]);
			u.m[0] = 0.0f;
			u.m[1] = +w.m[2] * invLength;
			u.m[2] = -w.m[1] * invLength;
			v.m[0] = w.m[1] * u.m[2] - w.m[2] * u.m[1];
			v.m[1] = -w.m[0] * u.m[2];
			v.m[2] = w.m[0] * u.m[1];
		}
	}

	void ComputeExtremes(int quantity, const TVector3* points, TVector3& min, TVector3& max)
	{
		Assert(quantity > 0 && points);

		min = points[0];
		max = min;
		for (int i = 1; i < quantity; i++)
		{
			const TVector3& rkPoint = points[i];
			for (int j = 0; j < 3; j++)
			{
				if (rkPoint[j] < min[j])
				{
					min[j] = rkPoint[j];
				}
				else if (rkPoint[j] > max[j])
				{
					max[j] = rkPoint[j];
				}
			}
		}
	}

	TVector3 Lerp(const TVector3& other, T t)
	{
		return (*this) * (1 - t) + other * t;
	}

	friend TVector3 Lerp(const TVector3& v0, const TVector3& v1, T t)
	{
		return v0 * (1 - t) + v1 * t;
	}

	static TVector3 Sin(const TVector3& v)
	{
		return TVector3
		(
			Math::Sin(v.X()),
			Math::Sin(v.Y()),
			Math::Sin(v.Z())
		);
	}

	static TVector3 Cos(const TVector3& v)
	{
		return TVector3
		(
			Math::Cos(v.X()),
			Math::Cos(v.Y()),
			Math::Cos(v.Z())
		);
	}

	static TVector3 Tan(const TVector3& v)
	{
		return TVector3
		(
			Math::Tan(v.X()),
			Math::Tan(v.Y()),
			Math::Tan(v.Z())
		);
	}

	static TVector3 ACos(const TVector3& v)
	{
		return TVector3
		(
			Math::ACos(v.X()),
			Math::ACos(v.Y()),
			Math::ACos(v.Z())
		);
	}

	static TVector3 ASin(const TVector3& v)
	{
		return TVector3
		(
			Math::ASin(v.X()),
			Math::ASin(v.Y()),
			Math::ASin(v.Z())
		);
	}

	static TVector3 ATan(const TVector3& v)
	{
		return TVector3
		(
			Math::ATan(v.X()),
			Math::ATan(v.Y()),
			Math::ATan(v.Z())
		);
	}

	static TVector3 ATan2(const TVector3& v0, const TVector3& v1)
	{
		return TVector3
		(
			Math::ATan2(v0.X(), v1.X()),
			Math::ATan2(v0.Y(), v1.X()),
			Math::ATan2(v0.Z(), v1.X())
		);
	}

	static TVector3 Ceil(const TVector3& v)
	{
		return TVector3
		(
			Math::Ceil(v.X()),
			Math::Ceil(v.Y()),
			Math::Ceil(v.Z())
		);
	}

	static TVector3 Floor(const TVector3& v)
	{
		return TVector3
		(
			Math::Floor(v.X()),
			Math::Floor(v.Y()),
			Math::Floor(v.Z())
		);
	}

	static TVector3 FAbs(const TVector3& v)
	{
		return TVector3
		(
			Math::FAbs(v.X()),
			Math::FAbs(v.Y()),
			Math::FAbs(v.Z())
		);
	}

	static TVector3 FMod(const TVector3& v0, const TVector3& v1)
	{
		return TVector3
		(
			Math::FMod(v0.X(), v1.X()),
			Math::FMod(v0.Y(), v1.X()),
			Math::FMod(v0.Z(), v1.X())
		);
	}

	static TVector3 Exp(const TVector3& v)
	{
		return TVector3
		(
			Math::Exp(v.X()),
			Math::Exp(v.Y()),
			Math::Exp(v.Z())
		);
	}

	static TVector3 Log(const TVector3& v)
	{
		return TVector3
		(
			Math::Log(v.X()),
			Math::Log(v.Y()),
			Math::Log(v.Z())
		);
	}

	static TVector3 Pow(const TVector3& base, const TVector3& exponent)
	{
		return TVector3
		(
			Math::Pow(base.X(), exponent.X()),
			Math::Pow(base.Y(), exponent.Y()),
			Math::Pow(base.Z(), exponent.Z())
		);
	}

	static TVector3 Sqr(const TVector3& v)
	{
		return TVector3
		(
			Math::Sqr(v.X()),
			Math::Sqr(v.Y()),
			Math::Sqr(v.Z())
		);
	}

	static TVector3 Sqrt(const TVector3& v)
	{
		return TVector3
		(
			Math::Sqrt(v.X()),
			Math::Sqrt(v.Y()),
			Math::Sqrt(v.Z())
		);
	}

	static TVector3 InvSqrt(const TVector3& v)
	{
		return TVector3
		(
			Math::InvSqrt(v.X()),
			Math::InvSqrt(v.Y()),
			Math::InvSqrt(v.Z())
		);
	}


	static TVector3 Min(const TVector3& v0_, const TVector3& v1_)
	{
		return TVector3
		(
			Math::Min(v0_.X(), v1_.X()),
			Math::Min(v0_.Y(), v1_.Y()),
			Math::Min(v0_.Z(), v1_.Z())
		);
	}

	static TVector3 Max(const TVector3& v0_, const TVector3& v1_)
	{
		return TVector3
		(
			Math::Max(v0_.X(), v1_.X()),
			Math::Max(v0_.Y(), v1_.Y()),
			Math::Max(v0_.Z(), v1_.Z())
		);
	}

	static TVector3 Clamp(const TVector3& v_, const TVector3& min_, const TVector3& max_)
	{
		return TVector3
		(
			Math::Clamp(v_.X(), min_.X(), max_.X()),
			Math::Clamp(v_.Y(), min_.Y(), max_.Y()),
			Math::Clamp(v_.Z(), min_.Z(), max_.Z())
		);
	}

	static TVector3 Sign(const TVector3& v_)
	{
		return TVector3
		(
			Math::Sign(v_.X()),
			Math::Sign(v_.Y()),
			Math::Sign(v_.Z())
		);
	}

	static TVector3 UnitRandom(unsigned int uiSeed_ = 0)
	{
		return TVector3
		(
			Math::UnitRandom(uiSeed_),
			Math::UnitRandom(uiSeed_),
			Math::UnitRandom(uiSeed_)
		);
	}

	static TVector3 SymmetricRandom(unsigned int uiSeed_ = 0)
	{
		return TVector3
		(
			Math::SymmetricRandom(uiSeed_),
			Math::SymmetricRandom(uiSeed_),
			Math::SymmetricRandom(uiSeed_)
		);
	}

	static TVector3 IntervalRandom(const TVector3& min_, const TVector3& max_, unsigned int uiSeed_ = 0)
	{
		return TVector3
		(
			Math::IntervalRandom(min_.X(), max_.X(), uiSeed_),
			Math::IntervalRandom(min_.Y(), max_.Y(), uiSeed_),
			Math::IntervalRandom(min_.Z(), max_.Z(), uiSeed_)
		);
	}

	void Read(InputStream& is)
	{
		is.ReadBuffer(&m[0], sizeof(T) * 3);
	}

	void Write(OutputStream& os) const
	{
		os.WriteBuffer(&m[0], sizeof(T) * 3);
	}

	// special vectors
	static const TVector3 Zero;      // (0,0,0)
	static const TVector3 UnitX;     // (1,0,0)
	static const TVector3 UnitY;     // (0,1,0)
	static const TVector3 UnitZ;     // (0,0,1)
	static const TVector3 One;       // (1,1,1)
protected:
private:
	T m[3];
};

typedef TVector3<bool> BVector3;
typedef TVector3<int> IVector3;
typedef TVector3<float> Vector3;
typedef TVector3<double> DVector3;

typedef TVector3<unsigned int> UIVector3;

#endif