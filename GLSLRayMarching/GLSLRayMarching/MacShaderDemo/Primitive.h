#ifndef _Primitive_h_
#define _Primitive_h_

#include "Vector3.h"
#include "ColorRGBA.h"
#include "Vector2.h"

class Primitive
{
public:
	class Vertex
	{
	public:
		Vector3 p;
		ColorRGBA c;
		Vector2 uv;

		Vertex()
			: p(Vector3::Zero)
			, c(ColorRGBA::Black)
			, uv(Vector2::Zero)
		{
		}

		Vertex(
			const Vector3& p_,
			const ColorRGBA& c_,
			const Vector2& uv_)
			: p(p_)
			, c(c_)
			, uv(uv_)
		{
		}

		Vertex(const Vertex& other)
		{
			p = other.p;
			c = other.c;
			uv = other.uv;
		}

		Vertex& operator = (const Vertex& other)
		{
			p = other.p;
			c = other.c;
			uv = other.uv;

			return *this;
		}

		Vertex& operator += (const Vertex& v)
		{
			p += v.p;
			c += v.c;
			uv += v.uv;

			return *this;
		}

		Vertex& operator -= (const Vertex& v)
		{
			p -= v.p;
			c -= v.c;
			uv -= v.uv;

			return *this;
		}

		Vertex& operator *= (float scaler)
		{
			p *= scaler;
			c *= scaler;
			uv *= scaler;

			return *this;
		}

		Vertex& operator /= (float scaler)
		{
			p /= scaler;
			c /= scaler;
			uv /= scaler;

			return *this;
		}

		friend Vertex operator + (const Vertex& v0, const Vertex& v1)
		{
			Vertex v;

			v.p = v0.p + v1.p;
			v.c = v0.c + v1.c;
			v.uv = v0.uv + v1.uv;

			return v;
		}

		friend Vertex operator - (const Vertex& v0, const Vertex& v1)
		{
			Vertex v;

			v.p = v0.p - v1.p;
			v.c = v0.c - v1.c;
			v.uv = v0.uv - v1.uv;

			return v;
		}

		friend Vertex operator * (const Vertex& v0, float scaler)
		{
			Vertex v;

			v.p = v0.p * scaler;
			v.c = v0.c * scaler;
			v.uv = v0.uv * scaler;

			return v;
		}

		friend Vertex operator / (const Vertex& v0, float scaler)
		{
			Vertex v;

			v.p = v0.p / scaler;
			v.c = v0.c / scaler;
			v.uv = v0.uv / scaler;

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
					return uv < other.uv;
				}
			}

			return less;
		}

		bool IsClose(const Vertex& other, float threshold) const
		{
			float dP = (p - other.p).SquaredLength();
			float dC = (c - other.c).SquaredLength();
			float dUV = (uv - other.uv).SquaredLength();

			return dP < threshold && dC < threshold && dUV;
		}
	};

	enum Mode
	{
		POINTS = 0,
		LINES = 1,
		TRIANGLES = 2
	};

	Primitive::Mode mode;
	std::vector<Vertex> vertices;
public:
	Primitive()
	{
	}

	~Primitive()
	{
	}

#define AddVertex(p0, c0) { Vertex v; v.p = p0; v.c = c0; vertices.push_back(v); 	}

	void DrawPoint(const Vector3& p, const ColorRGBA& c)
	{
		mode = Primitive::POINTS;

		AddVertex(p, c);
	}

	void DrawLine(const Vector3& p0, const Vector3& p1, const ColorRGBA& c)
	{
		mode = Primitive::LINES;

		AddVertex(p0, c);
		AddVertex(p1, c);
	}

	void DrawLine(const Vector3& p0, const ColorRGBA& c0, const Vector3& p1, const ColorRGBA& c1)
	{
		mode = Primitive::LINES;

		AddVertex(p0, c0);
		AddVertex(p1, c1);
	}

	void DrawLines(const std::vector<Vector3>& p, const std::vector<ColorRGBA>& c)
	{
		mode = Primitive::LINES;


		for (int i = 0; i < p.size(); i++)
		{
			AddVertex(p[i], c[i]);
		}
	}

	void DrawTriangle(const Vector3& p0, const Vector3& p1, const Vector3& p2, const ColorRGBA& c)
	{
		mode = Primitive::TRIANGLES;

		AddVertex(p0, c);
		AddVertex(p1, c);
		AddVertex(p2, c);
	}

	void DrawTriangle(const Vector3& p0, const ColorRGBA& c0, const Vector3& p1, const ColorRGBA& c1, const Vector3& p2, const ColorRGBA& c2)
	{
		mode = Primitive::TRIANGLES;

		AddVertex(p0, c0);
		AddVertex(p1, c1);
		AddVertex(p2, c2);
	}

	void DrawTriangles(const std::vector<Vector3>& p, const std::vector<ColorRGBA>& c)
	{
		mode = Primitive::TRIANGLES;

		for (int i = 0; i < p.size(); i++)
		{
			AddVertex(p[i], c[i]);
		}
	}

	void DrawQuad(const Vector3& p0, const Vector3& p1, const Vector3& p2, const Vector3& p3, const ColorRGBA& c)
	{
		mode = Primitive::TRIANGLES;

		AddVertex(p0, c);
		AddVertex(p1, c);
		AddVertex(p2, c);

		AddVertex(p2, c);
		AddVertex(p1, c);
		AddVertex(p3, c);
	}

	void DrawQuad(const Vector3& p0, const ColorRGBA& c0, const Vector3& p1, const ColorRGBA& c1, const Vector3& p2, const ColorRGBA& c2, const Vector3& p3, const ColorRGBA& c3)
	{
		mode = Primitive::TRIANGLES;

		AddVertex(p0, c0);
		AddVertex(p1, c1);
		AddVertex(p2, c2);

		AddVertex(p2, c2);
		AddVertex(p1, c1);
		AddVertex(p3, c3);
	}

	void DrawQuads(const std::vector<Vector3>& p, const std::vector<ColorRGBA>& c)
	{
		mode = Primitive::TRIANGLES;

		for (int i = 0; i < p.size(); i++)
		{
			AddVertex(p[i], c[i]);
		}
	}
};

#endif