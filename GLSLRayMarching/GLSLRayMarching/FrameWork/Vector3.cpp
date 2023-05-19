//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Vector3.h"

const BVector3 BVector3::Zero(false, false, false);
const BVector3 BVector3::UnitX(true, false, false);
const BVector3 BVector3::UnitY(false, true, false);
const BVector3 BVector3::UnitZ(false, false, true);
const BVector3 BVector3::One(true, true, true);
const BVector3 BVector3::MaxValue(true, true, true);

const IVector3 IVector3::Zero(0, 0, 0);
const IVector3 IVector3::UnitX(1, 0, 0);
const IVector3 IVector3::UnitY(0, 1, 0);
const IVector3 IVector3::UnitZ(0, 0, 1);
const IVector3 IVector3::One(1, 1, 1);
const IVector3 IVector3::MaxValue(Math::MaxValue, Math::MaxValue, Math::MaxValue);

const Vector3 Vector3::Zero(0.0f, 0.0f, 0.0f);
const Vector3 Vector3::UnitX(1.0f, 0.0f, 0.0f);
const Vector3 Vector3::UnitY(0.0f, 1.0f, 0.0f);
const Vector3 Vector3::UnitZ(0.0f, 0.0f, 1.0f);
const Vector3 Vector3::One(1.0f, 1.0f, 0.0f);
const Vector3 Vector3::MaxValue(Math::MaxValue, Math::MaxValue, Math::MaxValue);

const DVector3 DVector3::Zero(0.0, 0.0, 0.0);
const DVector3 DVector3::UnitX(1.0, 0.0, 0.0);
const DVector3 DVector3::UnitY(0.0, 1.0, 0.0);
const DVector3 DVector3::UnitZ(0.0, 0.0, 1.0);
const DVector3 DVector3::One(1.0, 1.0, 1.0);
const DVector3 DVector3::MaxValue(Math::MaxValue, Math::MaxValue, Math::MaxValue);