//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Vector4_h_
#define _Vector4_h_

#include "Platform.h"
#include "Maths.h"
#include "InputStream.h"
#include "OutputStream.h"

template<class T>
class TVector4
{
public:
	TVector4()
	{
		// uninitialized for performance in array construction
	}

	TVector4(T x, T y, T z, T w)
	{
		m[0] = x;
		m[1] = y;
		m[2] = z;
		m[3] = w;
	}

	TVector4(const T* values)
	{
		m[0] = values[0];
		m[1] = values[1];
		m[2] = values[2];
		m[3] = values[3];
	}

	TVector4(const TVector4& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		m[3] = v.m[3];
	}

	void Set(T x, T y, T z, T w)
	{
		m[0] = x;
		m[1] = y;
		m[2] = z;
		m[3] = w;
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
		Assert(0 <= i && i <= 3);
		return m[i];
	}

	T& operator[] (int i)
	{
		Assert(0 <= i && i <= 3);
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

	T W() const
	{
		return m[3];
	}

	T& W()
	{
		return m[3];
	}

	TVector4& operator= (const TVector4& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		m[3] = v.m[3];
		return *this;
	}

	int CompareArrays(const TVector4& v) const
	{
		return memcmp(m, v.m, 4 * sizeof(T));
	}

	bool operator== (const TVector4& v) const
	{
		return CompareArrays(v) == 0;
	}

	bool operator!= (const TVector4& v) const
	{
		return CompareArrays(v) != 0;
	}

	bool operator< (const TVector4& v) const
	{
		return CompareArrays(v) < 0;
	}

	bool operator<= (const TVector4& v) const
	{
		return CompareArrays(v) <= 0;
	}

	bool operator> (const TVector4& v) const
	{
		return CompareArrays(v) > 0;
	}

	bool operator>= (const TVector4& v) const
	{
		return CompareArrays(v) >= 0;
	}

	TVector4 operator+ (const TVector4& v) const
	{
		return TVector4
		(
			m[0] + v.m[0],
			m[1] + v.m[1],
			m[2] + v.m[2],
			m[3] + v.m[3]
		);
	}

	TVector4 operator- (const TVector4& v) const
	{
		return TVector4
		(
			m[0] - v.m[0],
			m[1] - v.m[1],
			m[2] - v.m[2],
			m[3] - v.m[3]
		);
	}

	TVector4 operator* (T scalar) const
	{
		return TVector4
		(
			scalar * m[0],
			scalar * m[1],
			scalar * m[2],
			scalar * m[3]
		);
	}

	TVector4 operator/ (T scalar) const
	{
		TVector4 quotient;

		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			quotient.m[0] = invScalar * m[0];
			quotient.m[1] = invScalar * m[1];
			quotient.m[2] = invScalar * m[2];
			quotient.m[3] = invScalar * m[3];
		}
		else
		{
			quotient.m[0] = Math::MaxValue;
			quotient.m[1] = Math::MaxValue;
			quotient.m[2] = Math::MaxValue;
			quotient.m[3] = Math::MaxValue;
		}

		return quotient;
	}

	TVector4 operator- () const
	{
		return TVector4
		(
			-m[0],
			-m[1],
			-m[2],
			-m[3]
		);
	}

	friend TVector4 operator* (T scalar, const TVector4& v)
	{
		return TVector4
		(
			scalar * v[0],
			scalar * v[1],
			scalar * v[2],
			scalar * v[3]
		);
	}

	TVector4& operator+= (const TVector4& v)
	{
		m[0] += v.m[0];
		m[1] += v.m[1];
		m[2] += v.m[2];
		m[3] += v.m[3];
		return *this;
	}

	TVector4& operator-= (const TVector4& v)
	{
		m[0] -= v.m[0];
		m[1] -= v.m[1];
		m[2] -= v.m[2];
		m[3] -= v.m[3];
		return *this;
	}

	TVector4& operator*= (T scalar)
	{
		m[0] *= scalar;
		m[1] *= scalar;
		m[2] *= scalar;
		m[3] *= scalar;
		return *this;
	}

	TVector4& operator/= (T scalar)
	{
		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			m[0] *= invScalar;
			m[1] *= invScalar;
			m[2] *= invScalar;
			m[3] *= invScalar;
		}
		else
		{
			m[0] = Math::MaxValue;
			m[1] = Math::MaxValue;
			m[2] = Math::MaxValue;
			m[3] = Math::MaxValue;
		}

		return *this;
	}

	T Length() const
	{
		return Math::Sqrt
		(
			m[0] * m[0] +
			m[1] * m[1] +
			m[2] * m[2] +
			m[3] * m[3]
		);
	}

	T SquaredLength() const
	{
		return
			m[0] * m[0] +
			m[1] * m[1] +
			m[2] * m[2] +
			m[3] * m[3];
	}

	T Dot(const TVector4& v) const
	{
		return
			m[0] * v.m[0] +
			m[1] * v.m[1] +
			m[2] * v.m[2] +
			m[3] * v.m[3];
	}

	T Normalize()
	{
		T length = Length();

		if (length > Math::ZeroTolerance)
		{
			T invLength = 1.0f / length;
			m[0] *= invLength;
			m[1] *= invLength;
			m[2] *= invLength;
			m[3] *= invLength;
		}
		else
		{
			length = 0.0f;
			m[0] = 0.0f;
			m[1] = 0.0f;
			m[2] = 0.0f;
			m[3] = 0.0f;
		}

		return length;
	}

	void Read(InputStream& is)
	{
		is.ReadBuffer(&m[0], sizeof(T) * 4);
	}

	void Write(OutputStream& os) const
	{
		os.WriteBuffer(&m[0], sizeof(T) * 4);
	}

	// special vectors
	static const TVector4 Zero;      // (0,0,0,0)
	static const TVector4 UnitX;     // (1,0,0,0)
	static const TVector4 UnitY;     // (0,1,0,0)
	static const TVector4 UnitZ;     // (0,0,1,0)
	static const TVector4 UnitW;     // (0,0,0,1)
	static const TVector4 One;       // (1,1,1,1)
protected:
private:

	//////////////////////////////////////////////////////////////
public:
protected:
private:
	T m[4];
};

typedef TVector4<bool> BVector4;
typedef TVector4<int> IVector4;
typedef TVector4<float> Vector4;
typedef TVector4<double> DVector4;

typedef TVector4<unsigned int> UIVector4;

#endif