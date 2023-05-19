///////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v1.0.0												 //
// Date   : 14/Jun/2016											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#include "Matrix3.h"

const int Matrix3::RowStartIdxs[3] = { 0, 3, 6 };

const BMatrix3 BMatrix3::Zero
(
    false, false, false, 
    false, false, false, 
    false, false, false
);

const BMatrix3 BMatrix3::Identity
(
     true, false, false,
    false,  true, false,
    false, false,  true
);

const IMatrix3 IMatrix3::Zero
(
    0, 0, 0,
    0, 0, 0,
    0, 0, 0
);

const IMatrix3 IMatrix3::Identity
(
    1, 0, 0,
    0, 1, 0,
    0, 0, 1
);

const Matrix3 Matrix3::Zero
(
    0.0f, 0.0f, 0.0f,
    0.0f, 0.0f, 0.0f,
    0.0f, 0.0f, 0.0f
);

const Matrix3 Matrix3::Identity
(
    1.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 1.0f
);

const DMatrix3 DMatrix3::Zero
(
    0.0, 0.0, 0.0, 
    0.0, 0.0, 0.0, 
    0.0, 0.0, 0.0
);

const DMatrix3 DMatrix3::Identity
(
    1.0, 0.0, 0.0, 
    0.0, 1.0, 0.0, 
    0.0, 0.0, 1.0
);