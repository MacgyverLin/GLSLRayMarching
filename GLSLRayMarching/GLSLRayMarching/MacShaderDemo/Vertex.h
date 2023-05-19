#ifndef _Vertex_h_
#define _Vertex_h_

#include "Vector2.h"
#include "Vector3.h"
#include "ColorRGBA.h"

class Vertex
{
public:
	Vector3 p;
	ColorRGBA c;
	Vector2 uv;

	Vector3 n;
	Vector3 t;
	Vector3 b;

	Vertex()
		: p(Vector3::Zero)
		, c(ColorRGBA::Black)
		, uv(Vector2::Zero)
		, n(Vector3::Zero)
		, t(Vector3::Zero)
		, b(Vector3::Zero)
	{
	}

	Vertex(
		const Vector3& p_,
		const ColorRGBA& c_,
		const Vector2& uv_,
		const Vector3& n_,
		const Vector3& t_,
		const Vector3& b_)
		: p(p_)
		, c(c_)
		, uv(uv_)
		, n(n_)
		, t(t_)
		, b(b_)
	{
	}

	Vertex(const Vertex& other)
	{
		p = other.p;
		c = other.c;
		uv = other.uv;
		n = other.n;
		t = other.t;
		b = other.b;
	}

	Vertex& operator = (const Vertex& other)
	{
		p = other.p;
		c = other.c;
		uv = other.uv;
		n = other.n;
		t = other.t;
		b = other.b;

		return *this;
	}

	Vertex& operator += (const Vertex& v)
	{
		p += v.p;
		c += v.c;
		uv += v.uv;
		n += v.n;
		t += v.t;
		b += v.b;

		return *this;
	}

	Vertex& operator -= (const Vertex& v)
	{
		p -= v.p;
		c -= v.c;
		uv -= v.uv;
		n -= v.n;
		t -= v.t;
		b -= v.b;

		return *this;
	}

	Vertex& operator *= (float scaler)
	{
		p *= scaler;
		c *= scaler;
		uv *= scaler;
		n *= scaler;
		t *= scaler;
		b *= scaler;

		return *this;
	}

	Vertex& operator /= (float scaler)
	{
		p /= scaler;
		c /= scaler;
		uv /= scaler;
		n /= scaler;
		t /= scaler;
		b /= scaler;

		return *this;
	}

	friend Vertex operator + (const Vertex& v0, const Vertex& v1)
	{
		Vertex v;

		v.p = v0.p + v1.p;
		v.c = v0.c + v1.c;
		v.uv = v0.uv + v1.uv;
		v.n = v0.n + v1.n;
		v.t = v0.t + v1.t;
		v.b = v0.b + v1.b;

		return v;
	}

	friend Vertex operator - (const Vertex& v0, const Vertex& v1)
	{
		Vertex v;

		v.p = v0.p - v1.p;
		v.c = v0.c - v1.c;
		v.uv = v0.uv - v1.uv;
		v.n = v0.n - v1.n;
		v.t = v0.t - v1.t;
		v.b = v0.b - v1.b;

		return v;
	}

	friend Vertex operator * (const Vertex& v0, float scaler)
	{
		Vertex v;

		v.p = v0.p * scaler;
		v.c = v0.c * scaler;
		v.uv = v0.uv * scaler;
		v.n = v0.n * scaler;
		v.t = v0.t * scaler;
		v.b = v0.b * scaler;

		return v;
	}

	friend Vertex operator / (const Vertex& v0, float scaler)
	{
		Vertex v;

		v.p = v0.p / scaler;
		v.c = v0.c / scaler;
		v.uv = v0.uv / scaler;
		v.n = v0.n / scaler;
		v.t = v0.t / scaler;
		v.b = v0.b / scaler;

		return v;
	}

	bool operator < (const Vertex& other) const
	{
		bool less = false;
		if (p < other.p)
		{
			less = true;
		}
		else if (p == other.p)
		{
			if (c < other.c)
			{
				less = true;
			}
			else if (c == other.c)
			{
				if (uv < other.uv)
				{
					less = true;
				}
				else if (uv == other.uv)
				{
					if (n < other.n)
					{
						less = true;
					}
					else if (n == other.n)
					{
						if (t < other.t)
						{
							less = true;
						}
						else if (t == other.t)
						{
							less = (b < other.b);
						}
					}
				}
			}
		}

		return less;
	}

	bool IsClose(const Vertex& other, float threshold) const
	{
		float dP = (p - other.p).SquaredLength();
		float dC = (c - other.c).SquaredLength();
		float dUV = (uv - other.uv).SquaredLength();
		float dN = (n - other.n).SquaredLength();
		float dT = (t - other.t).SquaredLength();
		float dB = (b - other.b).SquaredLength();

		return dP < threshold && dC < threshold && dUV < threshold && dN < threshold && dT < threshold && dB < threshold;
	}
};

#endif