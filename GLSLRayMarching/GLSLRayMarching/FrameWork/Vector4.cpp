//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Vector4.h"

const BVector4 BVector4::Zero(false, false, false, false);
const BVector4 BVector4::UnitX(true, false, false, false);
const BVector4 BVector4::UnitY(false, true, false, false);
const BVector4 BVector4::UnitZ(false, false, true, false);
const BVector4 BVector4::UnitW(false, false, true, false);
const BVector4 BVector4::One(true, true, true, true);
const BVector4 BVector4::MaxValue(true, true, true, true);

const IVector4 IVector4::Zero(0, 0, 0, 0);
const IVector4 IVector4::UnitX(1, 0, 0, 0);
const IVector4 IVector4::UnitY(0, 1, 0, 0);
const IVector4 IVector4::UnitZ(0, 0, 1, 0);
const IVector4 IVector4::UnitW(0, 0, 0, 1);
const IVector4 IVector4::One(1, 1, 1, 1);
const IVector4 IVector4::MaxValue(Math::MaxInteger, Math::MaxInteger, Math::MaxInteger, Math::MaxInteger);

const Vector4 Vector4::Zero(0.0f, 0.0f, 0.0f, 0.0f);
const Vector4 Vector4::UnitX(1.0f, 0.0f, 0.0f, 0.0f);
const Vector4 Vector4::UnitY(0.0f, 1.0f, 0.0f, 0.0f);
const Vector4 Vector4::UnitZ(0.0f, 0.0f, 1.0f, 0.0f);
const Vector4 Vector4::UnitW(0.0f, 0.0f, 0.0f, 1.0f);
const Vector4 Vector4::One(1.0f, 1.0f, 0.0f, 0.0f);
const Vector4 Vector4::MaxValue(Math::MaxValue, Math::MaxValue, Math::MaxValue, Math::MaxValue);

const DVector4 DVector4::Zero(0.0, 0.0, 0.0, 0.0);
const DVector4 DVector4::UnitX(1.0, 0.0, 0.0, 0.0);
const DVector4 DVector4::UnitY(0.0, 1.0, 0.0, 0.0);
const DVector4 DVector4::UnitZ(0.0, 0.0, 1.0, 0.0);
const DVector4 DVector4::UnitW(0.0, 0.0, 0.0, 1.0);
const DVector4 DVector4::One(1.0, 1.0, 1.0, 1.0);
const DVector4 DVector4::MaxValue(Math::MaxValue, Math::MaxValue, Math::MaxValue, Math::MaxValue);