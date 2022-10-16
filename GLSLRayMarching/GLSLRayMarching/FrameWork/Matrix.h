///////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v1.0.0												 //
// Date   : 14/Jun/2016											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#ifndef _Matrix_h_
#define _Matrix_h_

#include "Maths.h"

template<class T, int M, int N>
class TMatrix
{
public:
	TMatrix()
	{
		SetZero();
	}

	TMatrix(const TMatrix& mat)
	{
		size_t uiSize = M * N * sizeof(T);

		memcpy(m, mat.m, uiSize);
	}

	TMatrix(const T* entry, bool rowMajor = true)
	{
		if (rowMajor)
		{
			::MemCpy(m, entry, M * N * sizeof(T));
		}
		else
		{
			for (int i = 0; i < M; i++)
			{
				int idx = i * N;
				for (int j = 0; j < N; j++)
				{
					m[idx + j] = entry[idx + j];
				}
			}
		}
	}

	TMatrix& SetZero()
	{
		size_t uiSize = M * N * sizeof(T);
		::MemSet(m, 0, uiSize);

		return *this;
	}

	operator const T* () const
	{
		return m;
	}

	operator T* ()
	{
		return m;
	}

	const T* operator[] (int row) const
	{
		return &m[I(row, 0)];
	}

	T* operator[] (int row)
	{
		return &m[I(row, 0)];
	}

	T operator() (int row, int col) const
	{
		return m[I(row, col)];
	}

	T& operator() (int row, int col)
	{
		return m[I(row, col)];
	}
private:
	// for indexing into the 1D array of the matrix, iCol+N*iRow
	static int I(int row, int col)
	{
		assert(0 <= row && row < M && 0 <= col && col < N);

		return col + N * row;
	}
private:
	T m[M * N];
};

typedef TMatrix<float, 2, 2> Matrix22;
typedef TMatrix<float, 3, 2> Matrix32;
typedef TMatrix<float, 4, 2> Matrix42;

typedef TMatrix<float, 2, 3> Matrix23;
typedef TMatrix<float, 3, 3> Matrix33;
typedef TMatrix<float, 4, 3> Matrix43;

typedef TMatrix<float, 2, 4> Matrix24;
typedef TMatrix<float, 3, 4> Matrix34;
typedef TMatrix<float, 4, 4> Matrix44;

#endif