///////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v1.0.0												 //
// Date   : 14/Jun/2016											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#ifndef _Matrix3_h_
#define _Matrix3_h_

#include "Platform.h"
#include "Maths.h"
#include "Vector4.h"
#include "Vector3.h"

template<class T>
class TMatrix3
{
public:
    static const int RowStartIdxs[3];

    TMatrix3(bool bZero = true)
    {
        if (bZero)
        {
            SetZero();
        }
        else
        {
            SetIdentity();
        }
    }

    TMatrix3(const TMatrix3& mat)
    {
        size_t uiSize = 9 * sizeof(T);

        memcpy(m, mat.m, uiSize);
    }

    TMatrix3(const T& m00, const T& m01, const T& m02,
             const T& m10, const T& m11, const T& m12,
             const T& m20, const T& m21, const T& m22)
    {
        m[0] = m00;
        m[1] = m01;
        m[2] = m02;
        
        m[3] = m10;
        m[4] = m11;
        m[5] = m12;
        
        m[6] = m20;
        m[7] = m21;
        m[8] = m22;
    }

    TMatrix3(const T entry[9], bool rowMajor = true)
    {
        if (rowMajor)
        {
            size_t uiSize = 96 * sizeof(T);
            memcpy(m, entry, uiSize);
        }
        else
        {
            m[ 0] = entry[0]; m[ 1] = entry[3]; m[ 2] = entry[6];
            m[ 3] = entry[1]; m[ 4] = entry[4]; m[ 5] = entry[7];
            m[ 6] = entry[2]; m[ 7] = entry[5]; m[ 8] = entry[8];
        }
    }

    // input Mrc is in row r, column c.
    TMatrix3& Set(const T& m00, const T& m01, const T& m02, 
             const T& m10, const T& m11, const T& m12, 
             const T& m20, const T& m21, const T& m22)
    {
        m[0] = m00; m[1] = m01; m[2] = m02;
        m[3] = m10; m[4] = m11; m[5] = m12;
        m[6] = m20; m[7] = m21; m[8] = m22;

        return *this;
    }

    TMatrix3& SetZero()
    {
        size_t uiSize = 9 * sizeof(T);
        memset(m, 0, uiSize);

        return *this;
    }

    TMatrix3& SetIdentity()
    {
        m[0] = 1; m[1] = 0; m[2] = 0;
        m[3] = 0; m[4] = 1; m[5] = 0;
        m[6] = 0; m[7] = 0; m[8] = 1;
        
        return *this;
    }

    TMatrix3& SetEulerAngleX(const T& angle)
    {
        SetIdentity();

        T radian = angle * Math::Degree2Radian;
        T cosine = Math::Cos(radian);
        T sine = Math::Sin(radian);

        m[4] = cosine;
        m[7] = sine;
        m[5] = -sine;
        m[8] = cosine;

        return *this;
    }

    TMatrix3& SetEulerAngleY(const T& angle)
    {
        SetIdentity();

        T radian = angle * Math::Degree2Radian;
        T cosine = Math::Cos(radian);
        T sine = Math::Sin(radian);

        m[0] = cosine;
        m[6] = -sine;
        m[2] = sine;
        m[8] = cosine;

        return *this;
    }

    TMatrix3& SetEulerAngleZ(const T& angle)
    {
        SetIdentity();

        T radian = angle * Math::Degree2Radian;
        T cosine = Math::Cos(radian);
        T sine = Math::Sin(radian);

        m[0] = cosine;
        m[3] = sine;
        m[1] = -sine;
        m[4] = cosine;

        return *this;
    }

    TMatrix3& SetEulerAngleXYZ(const T& xAngle, const T& yAngle, const T& zAngle)
    {
        T xAngle1 = xAngle * Math::Degree2Radian;
        T yAngle1 = yAngle * Math::Degree2Radian;
        T zAngle1 = zAngle * Math::Degree2Radian;

        T fCos, fSin;
        fCos = Math::Cos(xAngle1);
        fSin = Math::Sin(xAngle1);        
        TMatrix3 kXMat(1.0,  0.0,   0.0,
                       0.0, fCos, -fSin,
                       0.0, fSin,  fCos);

        fCos = Math::Cos(yAngle1);
        fSin = Math::Sin(yAngle1);
        TMatrix3 kYMat(fCos, 0.0, fSin,
                        0.0, 1.0,  0.0,
                      -fSin, 0.0, fCos);

        fCos = Math::Cos(zAngle1);
        fSin = Math::Sin(zAngle1);
        TMatrix3 kZMat(fCos, -fSin, 0.0,
                       fSin,  fCos, 0.0,
                        0.0,   0.0, 1.0);

        *this = kXMat * kYMat * kZMat;

        return *this;
    }

    TMatrix3& SetEulerAngleXZY(const T& xAngle, const T& zAngle, const T& yAngle)
    {
        T xAngle1 = xAngle * Math::Degree2Radian;
        T yAngle1 = yAngle * Math::Degree2Radian;
        T zAngle1 = zAngle * Math::Degree2Radian;

        T fCos, fSin;
        fCos = Math::Cos(xAngle1);
        fSin = Math::Sin(xAngle1);
        TMatrix3 kXMat(1.0, 0.0,    0.0,
                       0.0, fCos, -fSin,
                       0.0, fSin,  fCos);

        fCos = Math::Cos(yAngle1);
        fSin = Math::Sin(yAngle1);
        TMatrix3 kYMat(fCos, 0.0, fSin,
                        0.0, 1.0,  0.0,
                      -fSin, 0.0, fCos);

        fCos = Math::Cos(zAngle1);
        fSin = Math::Sin(zAngle1);
        TMatrix3 kZMat(fCos, -fSin, 0.0,
                       fSin,  fCos, 0.0,
                        0.0,   0.0, 1.0);

        *this = kXMat * kZMat * kYMat;

        return *this;
    }

    TMatrix3& SetEulerAngleYXZ(const T& yAngle, const T& xAngle, const T& zAngle)
    {
        T xAngle1 = xAngle * Math::Degree2Radian;
        T yAngle1 = yAngle * Math::Degree2Radian;
        T zAngle1 = zAngle * Math::Degree2Radian;

        T fCos, fSin;
        fCos = Math::Cos(xAngle1);
        fSin = Math::Sin(xAngle1);
        TMatrix3 kXMat(1.0,  0.0,  0.0,
                       0.0, fCos, -fSin,
                       0.0, fSin,  fCos);

        fCos = Math::Cos(yAngle1);
        fSin = Math::Sin(yAngle1);
        TMatrix3 kYMat( fCos, 0.0, fSin,
                         0.0, 1.0,  0.0,
                       -fSin, 0.0, fCos);

        fCos = Math::Cos(zAngle1);
        fSin = Math::Sin(zAngle1);
        TMatrix3 kZMat(fCos, -fSin, 0.0,
                       fSin,  fCos, 0.0,
                        0.0,   0.0, 1.0);

        *this = kYMat * kXMat * kZMat;

        return *this;
    }

    TMatrix3& SetEulerAngleYZX(const T& yAngle, const T& zAngle, const T& xAngle)
    {
        T xAngle1 = xAngle * Math::Degree2Radian;
        T yAngle1 = yAngle * Math::Degree2Radian;
        T zAngle1 = zAngle * Math::Degree2Radian;

        T fCos, fSin;
        fCos = Math::Cos(xAngle1);
        fSin = Math::Sin(xAngle1);
        TMatrix3 kXMat(1.0,  0.0,   0.0,
                       0.0, fCos, -fSin,
                       0.0, fSin, fCos);

        fCos = Math::Cos(yAngle1);
        fSin = Math::Sin(yAngle1);
        TMatrix3 kYMat(fCos, 0.0, fSin,
                        0.0, 1.0,  0.0,
                      -fSin, 0.0, fCos);

        fCos = Math::Cos(zAngle);
        fSin = Math::Sin(zAngle);
        TMatrix3 kZMat(fCos, -fSin, 0.0,
                       fSin,  fCos, 0.0,
                        0.0,   0.0, 1.0);

        *this = kYMat * kZMat * kXMat;

        return *this;
    }

    TMatrix3& SetEulerAngleZXY(const T& zAngle, const T& xAngle, const T& yAngle)
    {
        T xAngle1 = xAngle * Math::Degree2Radian;
        T yAngle1 = yAngle * Math::Degree2Radian;
        T zAngle1 = zAngle * Math::Degree2Radian;

        T fCos, fSin;
        fCos = Math::Cos(xAngle1);
        fSin = Math::Sin(xAngle1);
        TMatrix3 kXMat(1.0,  0.0,   0.0,
                       0.0, fCos, -fSin,
                       0.0, fSin,  fCos);

        fCos = Math::Cos(yAngle1);
        fSin = Math::Sin(yAngle1);
        TMatrix3 kYMat( fCos, 0.0, fSin,
                         0.0, 1.0,  0.0,
                       -fSin, 0.0, fCos);

        fCos = Math::Cos(zAngle1);
        fSin = Math::Sin(zAngle1);
        TMatrix3 kZMat(fCos, -fSin, 0.0,
                       fSin,  fCos, 0.0,
                        0.0,   0.0, 1.0);

        *this = kZMat * kXMat * kYMat;

        return *this;
    }

    TMatrix3& SetEulerAngleZYX(const T& zAngle, const T& yAngle, const T& xAngle)
    {
        T xAngle1 = xAngle * Math::Degree2Radian;
        T yAngle1 = yAngle * Math::Degree2Radian;
        T zAngle1 = zAngle * Math::Degree2Radian;

        T fCos, fSin;
        fCos = Math::Cos(xAngle1);
        fSin = Math::Sin(xAngle1);
        TMatrix3 kXMat(1.0,  0.0,   0.0,
                       0.0, fCos, -fSin,
                       0.0, fSin,  fCos);

        fCos = Math::Cos(yAngle1);
        fSin = Math::Sin(yAngle1);
        TMatrix3 kYMat(fCos, 0.0, fSin,
                        0.0, 1.0,  0.0,
                      -fSin, 0.0, fCos);

        fCos = Math::Cos(zAngle1);
        fSin = Math::Sin(zAngle1);
        TMatrix3 kZMat(fCos, -fSin, 0.0,
                       fSin,  fCos, 0.0,
                        0.0,   0.0, 1.0);

        *this = kZMat * kYMat * kXMat;

        return *this;
    }

    TMatrix3& SetAxisAngle(const TVector3<T>& axis, const T& angle)
    {
        SetIdentity();

        T radian = angle * Math::Degree2Radian;
        T cos = Math::Cos(-radian);
        T sin = Math::Sin(-radian);
        T oneMinusCos = 1.0f - cos;
        T x2 = axis[0] * axis[0];
        T y2 = axis[1] * axis[1];
        T z2 = axis[2] * axis[2];
        T xyM = axis[0] * axis[1] * oneMinusCos;
        T xzM = axis[0] * axis[2] * oneMinusCos;
        T yzM = axis[1] * axis[2] * oneMinusCos;
        T xSin = axis[0] * sin;
        T ySin = axis[1] * sin;
        T zSin = axis[2] * sin;

        m[0] = x2 * oneMinusCos + cos;
        m[1] = xyM + zSin;
        m[2] = xzM - ySin;

        m[3] = xyM - zSin;
        m[4] = y2 * oneMinusCos + cos;
        m[5] = yzM + xSin;

        m[6] = xzM + ySin;
        m[7] = yzM - xSin;
        m[8] = z2 * oneMinusCos + cos;

        return *this;
    }

    TMatrix3& SetScale(const T& scale)
    {
        return SetScale(scale, scale, scale);
    }

    TMatrix3& SetScale(const T& x, const T& y, const T& z)
    {
        SetIdentity();

        m[0] = x;
        m[3] = y;
        m[6] = z;

        return *this;
    }

    TMatrix3& SetEulerAngleXYZScale(const T& rx, const T& ry, const T& rz, const T& scale)
    {
        SetEulerAngleXYZ(rx, ry, rz);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
    }

    TMatrix3& SetEulerAngleXZYScale(const T& rx, const T& rz, const T& ry, const T& scale)
    {
        SetEulerAngleXZY(rx, rz, ry);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
    }

    TMatrix3& SetEulerAngleYXZScale(const T& ry, const T& rx, const T& rz, const T& scale)
    {
        SetEulerAngleYXZ(ry, rx, rz);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
        return *this;
    }

    TMatrix3& SetEulerAngleYZXScale(const T& ry, const T& rz, const T& rx, const T& scale)
    {
        SetEulerAngleYZX(ry, rz, rx);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
    }

    TMatrix3& SetEulerAngleZXYScale(const T& rz, const T& rx, const T& ry, const T& scale)
    {
        SetEulerAngleZXY(rz, rx, ry);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
    }

    TMatrix3& SetEulerAngleZYXScale(const T& rz, const T& ry, const T& rx, const T& scale)
    {
        SetEulerAngleZYX(rz, ry, rx);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
    }

    TMatrix3& SetAxisAngleScale(const TVector3<T>& axis, const T& angle, const T& scale)
    {
        SetAxisAngle(axis, angle);

        m[0] *= scale;
        m[3] *= scale;
        m[6] *= scale;

        m[1] *= scale;
        m[4] *= scale;
        m[7] *= scale;

        m[2] *= scale;
        m[5] *= scale;
        m[8] *= scale;

        return *this;
    }

    //0  1  2  3   0 1 2
    //4  5  6  7   3 4 5
    //8  9 10 11   6 7 8
    void Orthonormalize()
    {
        T invLength = Math::InvSqrt(m[0] * m[0] + m[3] * m[3] + m[6] * m[6]);

        m[0] *= invLength;
        m[3] *= invLength;
        m[6] *= invLength;

        // Compute q1.
        T dot0 = m[0] * m[1] + m[3] * m[4] + m[6] * m[7];

        m[1] -= dot0 * m[0];
        m[4] -= dot0 * m[3];
        m[7] -= dot0 * m[6];

        invLength = Math::InvSqrt(m[1] * m[1] + m[4] * m[4] + m[7] * m[7]);

        m[1] *= invLength;
        m[4] *= invLength;
        m[7] *= invLength;

        // compute q2
        T dot1 = m[1] * m[2] + m[4] * m[5] + m[7] * m[8];

        dot0 = m[0] * m[2] + m[3] * m[5] + m[6] * m[8];

        m[2] -= dot0 * m[0] + dot1 * m[1];
        m[5] -= dot0 * m[3] + dot1 * m[4];
        m[8] -= dot0 * m[6] + dot1 * m[7];

        invLength = Math::InvSqrt(m[2] * m[2] + m[5] * m[5] + m[8] * m[8]);

        m[2] *= invLength;
        m[5] *= invLength;
        m[8] *= invLength;
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
        assert(0 <= row && row < 3);

        return &m[RowStartIdxs[row]];
    }

    T* operator[] (int row)
    {
        assert(0 <= row && row < 3);

        return &m[RowStartIdxs[row]];
    }

    T operator() (int row, int col) const
    {
        return m[I(row, col)];
    }

    T& operator() (int row, int col)
    {
        return m[I(row, col)];
    }

    void SetRow(int row, const TVector3<T>& v)
    {
        assert(0 <= row && row < 3);
        for (int col = 0, i = RowStartIdxs[row]; col < 3; col++, i++)
        {
            m[i] = v[col];
        }
    }

    TVector3<T> GetRow(int row) const
    {
        assert(0 <= row && row < 3);
        TVector3<T> v;
        for (int col = 0, i = RowStartIdxs[row]; col < 3; col++, i++)
        {
            v[col] = m[i];
        }
        return v;
    }

    void SetColumn(int col, const TVector3<T>& v)
    {
        assert(0 <= col && col < 3);
        for (int row = 0, i = col; row < 3; row++, i += 3)
        {
            m[i] = v[row];
        }
    }

    TVector3<T> GetColumn(int col) const
    {
        assert(0 <= col && col < 3);
        TVector3<T> v;
        for (int row = 0, i = col; row < 3; row++, i += 3)
        {
            v[row] = m[i];
        }
        return v;
    }

    void GetColumnMajor(T* columnMajor) const
    {
        for (int row = 0, i = 0; row < 3; row++)
        {
            for (int col = 0; col < 3; col++)
            {
                columnMajor[i++] = m[I(col, row)];
            }
        }
    }

    TMatrix3& operator= (const TMatrix3& mat)
    {
        size_t uiSize = 9 * sizeof(T);

        memcpy(m, mat.m, uiSize);

        return *this;
    }

    int CompareArrays(const TMatrix3& mat) const
    {
        return memcmp(m, mat.m, 9 * sizeof(T));
    }

    inline bool operator== (const TMatrix3& mat) const
    {
        return CompareArrays(mat) == 0;
    }

    inline bool operator!= (const TMatrix3& mat) const
    {
        return CompareArrays(mat) != 0;
    }

    inline bool operator<  (const TMatrix3& mat) const
    {
        return CompareArrays(mat) < 0;
    }

    inline bool operator<= (const TMatrix3& mat) const
    {
        return CompareArrays(mat) <= 0;
    }

    inline bool operator>  (const TMatrix3& mat) const
    {
        return CompareArrays(mat) > 0;
    }

    inline bool operator>= (const TMatrix3& mat) const
    {
        return CompareArrays(mat) >= 0;
    }

    TMatrix3 operator+ (const TMatrix3& mat) const
    {
        TMatrix3 sum;
        for (int i = 0; i < 9; i++)
        {
            sum.m[i] = m[i] + mat.m[i];
        }
        return sum;
    }

    TMatrix3 operator- (const TMatrix3& mat) const
    {
        TMatrix3 sum;
        for (int i = 0; i < 9; i++)
        {
            sum.m[i] = m[i] - mat.m[i];
        }
        return sum;
    }

    TMatrix3 operator* (const TMatrix3& mat) const
    {
        TMatrix3 result;

        result.m[0] = m[0] * mat.m[0] + m[1] * mat.m[3] + m[2] * mat.m[6];
        result.m[1] = m[0] * mat.m[1] + m[1] * mat.m[4] + m[2] * mat.m[7];
        result.m[2] = m[0] * mat.m[2] + m[1] * mat.m[5] + m[2] * mat.m[8];
        
        result.m[3] = m[3] * mat.m[0] + m[4] * mat.m[3] + m[5] * mat.m[6];
        result.m[4] = m[3] * mat.m[1] + m[4] * mat.m[4] + m[5] * mat.m[7];
        result.m[5] = m[3] * mat.m[2] + m[4] * mat.m[5] + m[5] * mat.m[8];

        result.m[6] = m[6] * mat.m[0] + m[7] * mat.m[3] + m[8] * mat.m[6];
        result.m[7] = m[6] * mat.m[1] + m[7] * mat.m[4] + m[8] * mat.m[7];
        result.m[8] = m[6] * mat.m[2] + m[7] * mat.m[5] + m[8] * mat.m[8];

        return result;
    }

    TMatrix3 operator* (const T& scale) const
    {
        TMatrix3 result;
        for (int i = 0; i < 9; i++)
        {
            result.m[i] = scale * m[i];
        }
        return result;
    }

    TMatrix3 operator/ (const T& scale) const
    {
        TMatrix3 result;
        int i;

        if (scale != (T)0.0)
        {
            T invScalar = ((T)1.0) / scale;
            for (i = 0; i < 9; i++)
            {
                result.m[i] = invScalar * m[i];
            }
        }
        else
        {
            for (i = 0; i < 9; i++)
            {
                result.m[i] = Math::MAX_REAL;
            }
        }

        return result;
    }

    TMatrix3 operator- () const
    {
        TMatrix3 result;
        for (int i = 0; i < 9; i++)
        {
            result.m[i] = -m[i];
        }
        return result;
    }

    TMatrix3& operator+= (const TMatrix3& mat)
    {
        for (int i = 0; i < 9; i++)
        {
            m[i] += mat.m[i];
        }
        return *this;
    }

    TMatrix3& operator-= (const TMatrix3& mat)
    {
        for (int i = 0; i < 9; i++)
        {
            m[i] -= mat.m[i];
        }
        return *this;
    }

    TMatrix3& operator*= (const T& scalar)
    {
        for (int i = 0; i < 9; i++)
        {
            m[i] *= scalar;
        }
        return *this;
    }

    TMatrix3& operator/= (const T& scalar)
    {
        int i;

        if (scalar != (T)0.0)
        {
            T invScalar = ((T)1.0) / scalar;
            for (i = 0; i < 9; i++)
            {
                m[i] *= invScalar;
            }
        }
        else
        {
            for (i = 0; i < 16; i++)
            {
                m[i] = Math::MAX_REAL;
            }
        }

        return *this;
    }

    TVector3<T> operator* (const TVector3<T>& v) const
    {
        Vector3 result;
        result[0] = m[0] * v[0] + m[1] * v[1] + m[2] * v[2];
        result[1] = m[3] * v[0] + m[4] * v[1] + m[5] * v[2];
        result[2] = m[6] * v[0] + m[7] * v[1] + m[8] * v[2];

        return result;
    }
    
    TMatrix3 Transpose() const
    {
        TMatrix3 transpose;
        for (int row = 0; row < 3; row++)
        {
            for (int col = 0; col < 3; col++)
            {
                transpose.m[I(row, col)] = m[I(col, row)];
            }
        }
        return transpose;
    }

    TMatrix3 TransposeTimes(const TMatrix3& mat) const
    {
        TMatrix3 result;

        for (int row = 0; row < 3; row++)
        {
            for (int col = 0; col < 3; col++)
            {
                int i = I(row, col);
                result.m[i] = 0.0;
                for (int mid = 0; mid < 3; mid++)
                {
                    result.m[i] += m[I(mid, row)] * mat.m[I(mid, col)];
                }
            }
        }
        return result;
    }

    TMatrix3 Inverse() const
    {
        float det = Determinant();
        if (Math::FAbs(det) <= Math::ZeroTolerance)
        {
            return TMatrix3::Zero;
        }

        float invDet = 1.0f / det;
        float a00 = m[0], a10 = m[1], a20 = m[2]; // transposed
        float a01 = m[3], a11 = m[4], a21 = m[5];
        float a02 = m[6], a12 = m[7], a22 = m[8];

        TMatrix3 inverse;
        inverse.m[0] =  (a11 * a22 - a12 * a21) * invDet;
        inverse.m[1] = -(a10 * a22 - a12 * a20) * invDet;
        inverse.m[2] =  (a10 * a21 - a11 * a20) * invDet;
        inverse.m[3] = -(a01 * a22 - a02 * a21) * invDet;
        inverse.m[4] =  (a00 * a22 - a02 * a20) * invDet;
        inverse.m[5] = -(a00 * a21 - a01 * a20) * invDet;
        inverse.m[6] =  (a01 * a12 - a02 * a11) * invDet;
        inverse.m[7] = -(a00 * a12 - a02 * a10) * invDet;
        inverse.m[8] =  (a00 * a11 - a01 * a10) * invDet;

        return inverse;
    }

    T Determinant() const
    {
        /*
        Vector3 a1(GetColumn(0));
        Vector3 a2(GetColumn(1));
        Vector3 a3(GetColumn(2));
        float d = a1.Cross(a2).Dot(a3);
        */

        T a11 = m[0], a12 = m[3], a13 = m[6];
        T a21 = m[1], a22 = m[4], a23 = m[7];
        T a31 = m[2], a32 = m[5], a33 = m[8];
        return a11 * a22 * a33 + a12 * a23 * a31 + a13 * a21 * a32 - a13 * a22 * a31 - a12 * a21 * a33 - a11 * a23 * a32;

        /*
        T fA0 = m[4] * m[8] - m[5] * m[7];
        T fA1 = m[3] * m[8] - m[5] * m[6];
        T fA2 = m[3] * m[7] - m[4] * m[6];

        T fDet = fA0 * m[0] - fA1 * m[1] + fA2 * m[2];
        return fDet;
        */
    }

    static const TMatrix3 Zero;
    static const TMatrix3 Identity;

    void Read(InputStream& is)
    {
        is.ReadBuffer(&m[0], sizeof(T) * 9);
    }

    void Write(OutputStream& os) const
    {
        os.WriteBuffer(&m[0], sizeof(T) * 9);
    }
private:
    // for indexing into the 1D array of the matrix, iCol+N*iRow
    static int I(int row, int col)
    {
        assert(0 <= row && row < 3 && 0 <= col && col < 3);

        // return iCol + 4*iRow;
        return col + RowStartIdxs[row];
    }

    T m[9];
};

typedef TMatrix3<bool> BMatrix3;
typedef TMatrix3<int> IMatrix3;
typedef TMatrix3<float> Matrix3;
typedef TMatrix3<double> DMatrix3;

#endif