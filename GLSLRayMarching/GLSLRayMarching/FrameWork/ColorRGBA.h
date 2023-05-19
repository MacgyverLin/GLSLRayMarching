//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _ColorRGBA_h_
#define _ColorRGBA_h_

#include "Platform.h"
#include "Maths.h"
#include "InputStream.h"
#include "OutputStream.h"

template<class T>
class TColorRGBA
{
public:
	TColorRGBA()
	{
		// uninitialized for performance in array construction
	}

	TColorRGBA(T r, T g, T b)
	{
		m[0] = r;
		m[1] = g;
		m[2] = b;
		m[3] = 1;
	}

	TColorRGBA(T r, T g, T b, T a)
	{
		m[0] = r;
		m[1] = g;
		m[2] = b;
		m[3] = a;
	}

	TColorRGBA(const T* values)
	{
		m[0] = values[0];
		m[1] = values[1];
		m[2] = values[2];
		m[3] = values[3];
	}

	TColorRGBA(const TColorRGBA& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		m[3] = v.m[3];
	}

	void Set(T r, T g, T b, T a)
	{
		m[0] = r;
		m[1] = g;
		m[2] = b;
		m[3] = a;
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
		Assert(0 <= i && i < 4);

		return m[i];
	}

	T& operator[] (int i)
	{
		Assert(0 <= i && i < 4);

		return m[i];
	}

	T R() const
	{
		return m[0];
	}

	T& R()
	{
		return m[0];
	}

	T G() const
	{
		return m[1];
	}

	T& G()
	{
		return m[1];
	}

	T B() const
	{
		return m[2];
	}

	T& B()
	{
		return m[2];
	}

	T A() const
	{
		return m[3];
	}

	T& A()
	{
		return m[3];
	}

	TColorRGBA& operator= (const TColorRGBA& v)
	{
		m[0] = v.m[0];
		m[1] = v.m[1];
		m[2] = v.m[2];
		m[3] = v.m[3];
		return *this;
	}

	int CompareArrays(const TColorRGBA& v) const
	{
		return memcmp(m, v.m, 4 * sizeof(T));
	}

	bool operator == (const TColorRGBA& v) const
	{
		return m[0] == v.m[0] && m[1] == v.m[1] && m[2] == v.m[2] && m[3] == v.m[3];
	}

	bool operator!= (const TColorRGBA& v) const
	{
		return CompareArrays(v) != 0;
	}

	bool operator< (const TColorRGBA& v) const
	{
		bool less = false;

		if (m[0] < v.m[0])
		{
			less = true;
		}
		else if (m[0] == v.m[0])
		{
			if (m[1] < v.m[1])
			{
				less = true;
			}
			else if (m[1] == v.m[1])
			{
				if (m[2] < v.m[2])
				{
					less = true;
				}
				else if (m[2] == v.m[2])
				{
					less = (m[3] < v.m[3]);
				}
			}
		}

		return less;
	}

	bool operator<= (const TColorRGBA& v) const
	{
		return CompareArrays(v) <= 0;
	}

	bool operator> (const TColorRGBA& v) const
	{
		return CompareArrays(v) > 0;
	}

	bool operator>= (const TColorRGBA& v) const
	{
		return CompareArrays(v) >= 0;
	}

	TColorRGBA operator+ (const TColorRGBA& v) const
	{
		return TColorRGBA
		(
			m[0] + v.m[0],
			m[1] + v.m[1],
			m[2] + v.m[2],
			m[3] + v.m[3]
		);
	}

	TColorRGBA operator- (const TColorRGBA& v) const
	{
		return TColorRGBA
		(
			m[0] - v.m[0],
			m[1] - v.m[1],
			m[2] - v.m[2],
			m[3] - v.m[3]
		);
	}

	TColorRGBA operator* (T scalar) const
	{
		return TColorRGBA
		(
			scalar * m[0],
			scalar * m[1],
			scalar * m[2],
			scalar * m[3]
		);
	}

	TColorRGBA operator/ (T scalar) const
	{
		TColorRGBA quotient;

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

	TColorRGBA operator- () const
	{
		return TColorRGBA
		(
			-m[0],
			-m[1],
			-m[2],
			-m[3]
		);
	}

	friend TColorRGBA operator* (T scalar, const TColorRGBA& v)
	{
		return TColorRGBA
		(
			scalar * v[0],
			scalar * v[1],
			scalar * v[2],
			scalar * v[3]
		);
	}

	TColorRGBA& operator+= (const TColorRGBA& v)
	{
		m[0] += v.m[0];
		m[1] += v.m[1];
		m[2] += v.m[2];
		m[3] += v.m[3];
		return *this;
	}

	TColorRGBA& operator-= (const TColorRGBA& v)
	{
		m[0] -= v.m[0];
		m[1] -= v.m[1];
		m[2] -= v.m[2];
		m[3] -= v.m[3];
		return *this;
	}

	TColorRGBA& operator*= (T scalar)
	{
		m[0] *= scalar;
		m[1] *= scalar;
		m[2] *= scalar;
		m[3] *= scalar;
		return *this;
	}

	TColorRGBA& operator/= (T scalar)
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

	T Dot(const TColorRGBA& v) const
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
	static const TColorRGBA Black;
	static const TColorRGBA Blue;
	static const TColorRGBA Green;
	static const TColorRGBA Cyan;
	static const TColorRGBA Red;
	static const TColorRGBA Mangenta;
	static const TColorRGBA Brown;
	static const TColorRGBA Grey;
	static const TColorRGBA BrightBlue;
	static const TColorRGBA BrightGreen;
	static const TColorRGBA BrightCyan;
	static const TColorRGBA BrightRed;
	static const TColorRGBA BrightMangenta;
	static const TColorRGBA Yellow;
	static const TColorRGBA White;
protected:
private:

	//////////////////////////////////////////////////////////////
public:
protected:
private:
	T m[4];
};

typedef TColorRGBA<float> ColorRGBA;

#endif