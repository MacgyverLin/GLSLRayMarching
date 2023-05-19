//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Vector2.h"

const BVector2 BVector2::Zero(false, false);
const BVector2 BVector2::UnitX(true, false);
const BVector2 BVector2::UnitY(false, true);
const BVector2 BVector2::One(true, true);
const BVector2 BVector2::MaxValue(true, true);

const IVector2 IVector2::Zero(0, 0);
const IVector2 IVector2::UnitX(1, 0);
const IVector2 IVector2::UnitY(0, 1);
const IVector2 IVector2::One(1, 1);
const IVector2 IVector2::MaxValue(Math::MaxInteger, Math::MaxInteger);

const Vector2 Vector2::Zero(0.0f, 0.0f);
const Vector2 Vector2::UnitX(1.0f, 0.0f);
const Vector2 Vector2::UnitY(0.0f, 1.0f);
const Vector2 Vector2::One(1.0f, 1.0f);
const Vector2 Vector2::MaxValue(Math::MaxValue, Math::MaxValue);

const DVector2 DVector2::Zero(0.0, 0.0);
const DVector2 DVector2::UnitX(1.0, 0.0);
const DVector2 DVector2::UnitY(0.0, 1.0);
const DVector2 DVector2::One(1.0, 1.0);
const DVector2 DVector2::MaxValue(Math::MaxValue, Math::MaxValue);