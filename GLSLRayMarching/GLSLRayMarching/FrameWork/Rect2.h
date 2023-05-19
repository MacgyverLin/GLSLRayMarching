//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Rect2_h_
#define _Rect2_h_

#include "Platform.h"
#include "Maths.h"
#include "Vector2.h"
#include "InputStream.h"
#include "OutputStream.h"

template<class T>
class TRect2
{
public:
	TRect2()
	{
		// uninitialized for performance in array construction
	}

	TRect2(T x, T y, T w, T h)
	{
		m[0] = x;
		m[1] = y;
		m[2] = w;
		m[3] = h;
	}

	TRect2(const T* values)
	{
		m[0] = values[0];
		m[1] = values[1];
		m[2] = values[2];
		m[3] = values[3];
	}

	TRect2(const TRect2& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		m[3] = v.m[3];
	}

	void Set(T x, T y, T w, T h)
	{
		m[0] = x;
		m[1] = y;
		m[2] = h;
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

	T Width() const
	{
		return m[2];
	}

	T& Width()
	{
		return m[2];
	}

	T Height() const
	{
		return m[3];
	}

	T& Height()
	{
		return m[3];
	}

	TRect2& operator= (const TRect2& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		m[3] = v.m[3];
		return *this;
	}

	int CompareArrays(const TRect2& v) const
	{
		return memcmp(m, v.m, 4 * sizeof(T));
	}

	bool operator== (const TRect2& v) const
	{
		return CompareArrays(v) == 0;
	}

	bool operator!= (const TRect2& v) const
	{
		return CompareArrays(v) != 0;
	}

	bool operator< (const TRect2& v) const
	{
		return CompareArrays(v) < 0;
	}

	bool operator<= (const TRect2& v) const
	{
		return CompareArrays(v) <= 0;
	}

	bool operator> (const TRect2& v) const
	{
		return CompareArrays(v) > 0;
	}

	bool operator>= (const TRect2& v) const
	{
		return CompareArrays(v) >= 0;
	}

	TRect2 operator + (const TRect2& v) const
	{
		T minX = Math::Min(m[0], v.m[0]);
		T minY = Math::Min(m[1], v.m[1]);
		T maxX = Math::Max(m[0] + m[2], v.m[0] + v.m[2]);
		T maxY = Math::Max(m[1] + m[3], v.m[1] + v.m[3]);

		return TRect2
		(
			minX,
			minY,
			maxX - minX,
			maxY - minY
		);
	}

	TRect2 operator* (T scalar) const
	{
		return TRect2
		(
			m[0],
			m[1],
			scalar * m[2],
			scalar * m[3]
		);
	}

	TRect2 operator/ (T scalar) const
	{
		TRect2 quotient;

		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			quotient.m[0] = m[0];
			quotient.m[1] = m[1];
			quotient.m[2] = invScalar * m[2];
			quotient.m[3] = invScalar * m[3];
		}
		else
		{
			quotient.m[0] = m[0];
			quotient.m[1] = m[1];
			quotient.m[2] = Math::MaxValue;
			quotient.m[3] = Math::MaxValue;
		}

		return quotient;
	}

	friend TRect2 operator* (T scalar, const TRect2& v)
	{
		return TRect2
		(
			v[0],
			v[1],
			scalar * v[2],
			scalar * v[3]
		);
	}

	TRect2& operator += (const TRect2& v)
	{
		T minX = Math::Min(m[0], v.m[0]);
		T minY = Math::Min(m[1], v.m[1]);
		T maxX = Math::Max(m[0] + m[2], v.m[0] + v.m[2]);
		T maxY = Math::Max(m[1] + m[3], v.m[1] + v.m[3]);

		m[0] = minX;
		m[1] = minY;
		m[2] = maxX - minX;
		m[3] = maxY - minY;
		return *this;
	}

	TRect2& operator*= (T scalar)
	{
		m[2] *= scalar;
		m[3] *= scalar;
		return *this;
	}

	TRect2& operator/= (T scalar)
	{
		if (scalar != 0.0f)
		{
			T invScalar = 1.0f / scalar;
			m[2] *= invScalar;
			m[3] *= invScalar;
		}
		else
		{
			m[2] = Math::MaxValue;
			m[3] = Math::MaxValue;
		}

		return *this;
	}

	TVector2<T> Position() const
	{
		return TVector2<T>(m[0], m[1]);
	}

	TVector2<T> Size() const
	{
		return TVector2<T>(m[2], m[3]);
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
	static const TRect2 Zero;			// (0,0,0,0)
	static const TRect2 Square;			// (0, 0, 1, 1)
protected:
private:

	//////////////////////////////////////////////////////////////
public:
protected:
private:
	T m[4];
};

typedef TRect2<int> IRect2;
typedef TRect2<float> Rect2;
typedef TRect2<double> DRect2;

#endif