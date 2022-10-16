//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Vector2_h_
#define _Vector2_h_

#include "Platform.h"
#include "Maths.h"
#include "InputStream.h"
#include "OutputStream.h"

template<class T>
class TVector2
{
public:
	TVector2()
	{
		// uninitialized for performance in array construction
	}

	TVector2(T x, T y)
	{
		m[0] = x;
		m[1] = y;
	}

	TVector2(const T* v)
	{
		m[0] = v[0];
		m[1] = v[1];
	}

	TVector2(const TVector2& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
	}

	void Set(T x, T y)
	{
		m[0] = x;
		m[1] = y;
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
		Assert(0 <= i && i <= 1);

		return m[i];
	}

	T& operator[] (int i)
	{
		Assert(0 <= i && i <= 1);

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

	TVector2& operator= (const TVector2& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];

		return *this;
	}

	int CompareArrays(const TVector2& v) const
	{
		return MemCmp(m, v.m, 2 * sizeof(T));
	}

	bool operator!= (const TVector2& v) const
	{
		return CompareArrays(v) != 0;
	}

	bool operator== (const TVector2& other) const
	{
		// return CompareArrays(v) == 0;
		return m[0] == other.m[0] && m[1] == other.m[1];
	}

	bool operator < (const TVector2& other) const
	{
		bool less = false;

		if (m[0] < other.m[0])
		{
			less = true;
		}
		else if (m[0] == other.m[0])
		{
			less = (m[1] < other.m[1]);
		}

		return less;
	}

	bool operator> (const TVector2& v) const
	{
		return CompareArrays(v) > 0;
	}

	bool operator>= (const TVector2& v) const
	{
		return CompareArrays(v) >= 0;
	}

	TVector2 operator- () const
	{
		return TVector2(-m[0], -m[1]);
	}

	friend TVector2 operator + (const TVector2& v0, const TVector2& v1)
	{
		return TVector2
		(
			v0.m[0] + v1.m[0],
			v0.m[1] + v1.m[1]
		);
	}

	friend TVector2 operator - (const TVector2& v0, const TVector2& v1)
	{
		return TVector2
		(
			v0.m[0] - v1.m[0],
			v0.m[1] - v1.m[1]
		);
	}

	friend TVector2 operator * (const TVector2& v0, const TVector2& v1)
	{
		return TVector2
		(
			v0.m[0] * v1.m[0],
			v0.m[1] * v1.m[1]
		);
	}

	friend TVector2 operator / (const TVector2& v0, const TVector2& v1)
	{
		return TVector2
		(
			v0.m[0] / v1.m[0],
			v0.m[1] / v1.m[1]
		);
	}

	friend TVector2 operator * (const TVector2& v, T scalar)
	{
		return TVector2
		(
			v.m[0] * scalar,
			v.m[1] * scalar
		);
	}

	friend TVector2 operator / (const TVector2& v, T scalar)
	{
		TVector2 quotient;

		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			quotient.m[0] = invScalar * v.m[0];
			quotient.m[1] = invScalar * v.m[1];
		}
		else
		{
			quotient.m[0] = Math::MaxValue;
			quotient.m[1] = Math::MaxValue;
		}

		return quotient;
	}

	friend TVector2 operator * (T scalar, const TVector2& v)
	{
		return v * scalar;
	}

	TVector2& operator+= (const TVector2& v)
	{
		m[0] += v.m[0];
		m[1] += v.m[1];

		return *this;
	}

	TVector2& operator-= (const TVector2& v)
	{
		m[0] -= v.m[0];
		m[1] -= v.m[1];

		return *this;
	}

	TVector2& operator*= (const TVector2& v)
	{
		m[0] *= v.m[0];
		m[1] *= v.m[1];

		return *this;
	}

	TVector2& operator/= (const TVector2& v)
	{
		m[0] /= v.m[0];
		m[1] /= v.m[1];

		return *this;
	}

	TVector2& operator*= (T scalar)
	{
		m[0] *= scalar;
		m[1] *= scalar;

		return *this;
	}

	TVector2& operator/= (T scalar)
	{
		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			m[0] *= invScalar;
			m[1] *= invScalar;
		}
		else
		{
			m[0] = Math::MaxFloat;
			m[1] = Math::MaxFloat;
		}

		return *this;
	}

	T Length() const
	{
		return Math::Sqrt(SquaredLength());
	}

	T SquaredLength() const
	{
		return m[0] * m[0] + m[1] * m[1];
	}

	T Dot(const TVector2& v) const
	{
		return m[0] * v.m[0] + m[1] * v.m[1];
	}

	T Normalize()
	{
		T length = Length();

		if (length > Math::Epsilon)
		{
			T invLength = 1.0f / length;
			m[0] *= invLength;
			m[1] *= invLength;
		}
		else
		{
			length = 0.0f;
			m[0] = 0.0f;
			m[1] = 0.0f;
		}

		return length;
	}

	TVector2 Perp(const TVector2& v) const
	{
		return TVector2(-m[1], m[0]);
	}

	TVector2 UnitPerp(const TVector2& v) const
	{
		TVector2 result(-m[1], m[0]);
		result.Normalize();

		return result;
	}

	void Orthonormalize(TVector2& u, TVector2& v, TVector2& w)
	{
		// compute u0
		u.Normalize();

		// compute u1
		T dot0 = u.Dot(v);
		v -= u * dot0;
		v.Normalize();
	}

	void Orthonormalize(TVector2* v)
	{
		Orthonormalize(v[0], v[1], v[2]);
	}

	void ComputeExtremes(int quantity, const TVector2* points, TVector2& min, TVector2& max)
	{
		Assert(quantity > 0 && points);

		min = points[0];
		max = min;
		for (int i = 1; i < quantity; i++)
		{
			const TVector2& rkPoint = points[i];
			for (int j = 0; j < 2; j++)
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

	TVector2 Lerp(const TVector2& other, T t)
	{
		return (*this) * (1 - t) + other * t;
	}

	friend TVector2 Lerp(const TVector2& v0, const TVector2& v1, T t)
	{
		return v0 * (1 - t) + v1 * t;
	}

	static TVector2 Sin(const TVector2& v)
	{
		return TVector2
		(
			Math::Sin(v.X()),
			Math::Sin(v.Y())
		);
	}

	static TVector2 Cos(const TVector2& v)
	{
		return TVector2
		(
			Math::Cos(v.X()),
			Math::Cos(v.Y())
		);
	}

	static TVector2 Tan(const TVector2& v)
	{
		return TVector2
		(
			Math::Tan(v.X()),
			Math::Tan(v.Y())
		);
	}

	static TVector2 ACos(const TVector2& v)
	{
		return TVector2
		(
			Math::ACos(v.X()),
			Math::ACos(v.Y())
		);
	}

	static TVector2 ASin(const TVector2& v)
	{
		return TVector2
		(
			Math::ASin(v.X()),
			Math::ASin(v.Y())
		);
	}

	static TVector2 ATan(const TVector2& v)
	{
		return TVector2
		(
			Math::ATan(v.X()),
			Math::ATan(v.Y())
		);
	}

	static TVector2 ATan2(const TVector2& v0, const TVector2& v1)
	{
		return TVector2
		(
			Math::ATan2(v0.X(), v1.X()),
			Math::ATan2(v0.Y(), v1.X())
		);
	}

	static TVector2 Ceil(const TVector2& v)
	{
		return TVector2
		(
			Math::Ceil(v.X()),
			Math::Ceil(v.Y())
		);
	}

	static TVector2 Floor(const TVector2& v)
	{
		return TVector2
		(
			Math::Floor(v.X()),
			Math::Floor(v.Y())
		);
	}

	static TVector2 FAbs(const TVector2& v)
	{
		return TVector2
		(
			Math::FAbs(v.X()),
			Math::FAbs(v.Y())
		);
	}

	static TVector2 FMod(const TVector2& v0, const TVector2& v1)
	{
		return TVector2
		(
			Math::FMod(v0.X(), v1.X()),
			Math::FMod(v0.Y(), v1.X())
		);
	}

	static TVector2 Exp(const TVector2& v)
	{
		return TVector2
		(
			Math::Exp(v.X()),
			Math::Exp(v.Y())
		);
	}

	static TVector2 Log(const TVector2& v)
	{
		return TVector2
		(
			Math::Log(v.X()),
			Math::Log(v.Y())
		);
	}

	static TVector2 Pow(const TVector2& base, const TVector2& exponent)
	{
		return TVector2
		(
			Math::Pow(base.X(), exponent.X()),
			Math::Pow(base.Y(), exponent.Y())
		);
	}

	static TVector2 Sqr(const TVector2& v)
	{
		return TVector2
		(
			Math::Sqr(v.X()),
			Math::Sqr(v.Y())
		);
	}

	static TVector2 Sqrt(const TVector2& v)
	{
		return TVector2
		(
			Math::Sqrt(v.X()),
			Math::Sqrt(v.Y())
		);
	}

	static TVector2 InvSqrt(const TVector2& v)
	{
		return TVector2
		(
			Math::InvSqrt(v.X()),
			Math::InvSqrt(v.Y())
		);
	}


	static TVector2 Min(const TVector2& v0_, const TVector2& v1_)
	{
		return TVector2
		(
			Math::Min(v0_.X(), v1_.X()),
			Math::Min(v0_.Y(), v1_.Y())
		);
	}

	static TVector2 Max(const TVector2& v0_, const TVector2& v1_)
	{
		return TVector2
		(
			Math::Max(v0_.X(), v1_.X()),
			Math::Max(v0_.Y(), v1_.Y())
		);
	}

	static TVector2 Clamp(const TVector2& v_, const TVector2& min_, const TVector2& max_)
	{
		return TVector2
		(
			Math::Clamp(v_.X(), min_.X(), max_.X()),
			Math::Clamp(v_.Y(), min_.Y(), max_.Y())
		);
	}

	static TVector2 Sign(const TVector2& v_)
	{
		return TVector2
		(
			Math::Sign(v_.X()),
			Math::Sign(v_.Y())
		);
	}

	static TVector2 UnitRandom(unsigned int uiSeed_ = 0)
	{
		return TVector2
		(
			Math::UnitRandom(uiSeed_),
			Math::UnitRandom(uiSeed_)
		);
	}

	static TVector2 SymmetricRandom(unsigned int uiSeed_ = 0)
	{
		return TVector2
		(
			Math::SymmetricRandom(uiSeed_),
			Math::SymmetricRandom(uiSeed_)
		);
	}

	static TVector2 IntervalRandom(const TVector2& min_, const TVector2& max_, unsigned int uiSeed_ = 0)
	{
		return TVector2
		(
			Math::IntervalRandom(min_.X(), max_.X(), uiSeed_),
			Math::IntervalRandom(min_.Y(), max_.Y(), uiSeed_)
		);
	}

	void Read(InputStream& is)
	{
		is.ReadBuffer(&m[0], sizeof(T) * 2);
	}

	void Write(OutputStream& os) const
	{
		os.WriteBuffer(&m[0], sizeof(T) * 2);
	}

	// special vectors
	static const TVector2 Zero;      // (0,0)
	static const TVector2 UnitX;     // (1,0)
	static const TVector2 UnitY;     // (0,1)
	static const TVector2 One;       // (1,1)
protected:
private:
	T m[2];
};

typedef TVector2<bool> BVector2;
typedef TVector2<int> IVector2;
typedef TVector2<float> Vector2;
typedef TVector2<double> DVector2;

typedef TVector2<unsigned int> UIVector2;

#endif