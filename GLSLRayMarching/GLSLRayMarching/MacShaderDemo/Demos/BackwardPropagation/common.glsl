//MIT License

//Copyright (c) [2020] [Ender Doe]

//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

#define LEARNING_RATE 0.005
#define CLIP_DURATION 3.
#define TRAIN_DURATION (CLIP_DURATION * 20.)
#define PI 3.1415926535897932384626433832

// Each frag has an independent neural net composed
// of relu -> reulu -> (relu, relu, relu); a shape of (1,1,3)
// Buffer A is the shader being learned
// Buffer B C D are the bias and weights for nodes per frag
// There is some duplicated computation, trading storage for re compute
// Layers are updated one at a time so training is very stochastic

float getT(float iTime)
{
    return 0.5;// + 0.5 * cos(iTime * PI);
}

float rnd(vec2 n)
{
    return fract(sin(dot(n.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// alternate getT which randomly samples t values, pretty interesting
//float getT(float iTime)
//{
//    return step(TRAIN_DURATION, iTime) * mod(iTime, CLIP_DURATION) +
//           (1. - step(TRAIN_DURATION, iTime)) * rnd(vec2(iTime, iTime + 0.3));
//}

#define MAX_U 1.0
#define MAX_V 1.0
vec4 relu(vec4 x)
{
    return max(vec4(0.), x);
}

vec4 reluD(vec4 x)
{
    return step(0., x);
}

float relu(float x)
{
    return max(0., x);
}

float reluD(float x)
{
    return step(0., x);
}


float meanSquaredError(vec3 groundTruth, vec3 prediction)
{
    vec3 diff = groundTruth - prediction;
    float loss = ((diff.x * diff.x) + (diff.y * diff.y) + (diff.z * diff.z)) * (1. / 3.);

    return loss;
}

mat3 CIE_XYZ_MAT = mat3
(
    0.489989, 0.31000, 0.20000,
    0.176962, 0.81240, 0.01000,
    0.000000, 0.01000, 0.99000
);

vec3 meanSquaredErrorGrad(vec3 groundTruth, vec3 prediction)
{
    vec3 predXYZ = CIE_XYZ_MAT * prediction;
    vec3 truthXYZ = CIE_XYZ_MAT * groundTruth;

    return CIE_XYZ_MAT * vec3
    (
        (predXYZ.r - truthXYZ.r),
        (predXYZ.g - truthXYZ.g),
        (predXYZ.b - truthXYZ.b)
    );
}

vec3 forwardPropagationPrediction(float t, vec4 w1_b1_w2_b2, vec4 w3_b3_w4_b4, vec4 w5_b5_w6_b6)
{
    float a1 = relu(w1_b1_w2_b2.x * t + w1_b1_w2_b2.y);
    float a2 = relu(w1_b1_w2_b2.z * a1 + w1_b1_w2_b2.w);
    float a3 = relu(w3_b3_w4_b4.x * a2 + w3_b3_w4_b4.y);

    float r = relu(w3_b3_w4_b4.z * a3 + w3_b3_w4_b4.w);
    float g = relu(w5_b5_w6_b6.x * a3 + w5_b5_w6_b6.y);
    float b = relu(w5_b5_w6_b6.z * a3 + w5_b5_w6_b6.w);

    return vec3(r, g, b);
}


/*
void backwardPropagation
(
    float t,
    vec4 w1_b1_w2_b2,
    vec4 w3_b3_w4_b4,
    vec4 w5_b5_w6_b6,

    vec3 yGT,

    out float z1, out float a1, out float da1_dz1,
    out float z2, out float a2, out float da2_dz2,
    out float z3, out float a3, out float da3_dz3,
    out float zr, out float yr, out float dyr_dzr,
    out float zg, out float yg, out float dyg_dzg,
    out float zb, out float yb, out float dyb_dzb,
    out float dLr_dyr,
    out float dLg_dyg,
    out float dLb_dyb,

    out float layer3D)
{
    z1 = w1_b1_w2_b2.x *  t + w1_b1_w2_b2.y;
    a1 = relu(z1);

    z2 = w1_b1_w2_b2.z * a1 + w1_b1_w2_b2.w;
    a2 = relu(z2);

    z3 = w3_b3_w4_b4.x * a2 + w3_b3_w4_b4.y;
    a3 = relu(z3);

    zr = w3_b3_w4_b4.z * a3 + w3_b3_w4_b4.w;
    yr = relu(zr);

    zg = w5_b5_w6_b6.x * a3 + w5_b5_w6_b6.y;
    yg = relu(zg);

    zb = w5_b5_w6_b6.z * a3 + w5_b5_w6_b6.w;
    yb = relu(zb);

    vec3 y = vec3(yr, yg, yb);

    vec3 dLoss = meanSquaredErrorGrad(yGT, y);
    dLr_dyr   = dLoss.r;
    dLg_dyg   = dLoss.g;
    dLb_dyb   = dLoss.b;

    dyr_dzr   = reluD(zr);
    dyg_dzg   = reluD(zg);
    dyb_dzb   = reluD(zb);

    da3_dz3   = reluD(z3);
    da2_dz2   = reluD(z2);
    da1_dz1   = reluD(z1);

    layer3D = dot(vec3(w3_b3_w4_b4.z, w5_b5_w6_b6.x, w5_b5_w6_b6.z),
                  vec3(dyr_dzr * dLr_dyr, dyg_dzg * dLg_dyg, dyb_dzb * dLb_dyb));
}

vec4 updatedParametersBufferB(float t, vec4 w1_b1_w2_b2, vec4 w3_b3_w4_b4, vec4 w5_b5_w6_b6, vec3 yGT)
{
    float z1, a1, da1dz1;
    float z2, a2, da2dz2;
    float z3, a3, da3dz3;
    float zr, yr, dyrdzr;
    float zg, yg, dygdzg;
    float zb, yb, dybdzb;
    float dLr_dyr;
    float dLg_dyg;
    float dLb_dyb;
    float dargb_dzrgb;

    backwardPropagation
    (
        t,
        w1_b1_w2_b2,
        w3_b3_w4_b4,
        w5_b5_w6_b6,

        yGT,

        z1, a1, da1dz1,
        z2, a2, da2dz2,
        z3, a3, da3dz3,
        zr, yr, dyrdzr,
        zg, yg, dygdzg,
        zb, yb, dybdzb,
        dLr_dyr,
        dLg_dyg,
        dLb_dyb,
        dargb_dzrgb
    );

    return vec4
    (
        w1_b1_w2_b2.x - LEARNING_RATE * (da1dz1 * (da2dz2 * w1_b1_w2_b2.z) * (da3dz3 * w3_b3_w4_b4.x) * dargb_dzrgb) * t,
        w1_b1_w2_b2.y - LEARNING_RATE * (da1dz1 * (da2dz2 * w1_b1_w2_b2.z) * (da3dz3 * w3_b3_w4_b4.x) * dargb_dzrgb),
        w1_b1_w2_b2.z - LEARNING_RATE * (da2dz2 * (da3dz3 * w3_b3_w4_b4.x) * dargb_dzrgb) * a1,
        w1_b1_w2_b2.w - LEARNING_RATE * (da2dz2 * (da3dz3 * w3_b3_w4_b4.x) * dargb_dzrgb)
    );
}

vec4 updatedParametersBufferC(float t, vec4 w1_b1_w2_b2, vec4 w3_b3_w4_b4, vec4 w5_b5_w6_b6, vec3 yGT)
{
    float z1, a1, da1_dz1;
    float z2, a2, da2_dz2;
    float z3, a3, da3_dz3;
    float zr, yr, dyr_dzr;
    float zg, yg, dyg_dzg;
    float zb, yb, dyb_dzb;
    float dLr_dyr;
    float dLg_dyg;
    float dLb_dyb;
    float dargb_dzrgb;

    backwardPropagation
    (
        t,
        w1_b1_w2_b2,
        w3_b3_w4_b4,
        w5_b5_w6_b6,

        yGT,

        z1, a1, da1_dz1,
        z2, a2, da2_dz2,
        z3, a3, da3_dz3,
        zr, yr, dyr_dzr,
        zg, yg, dyg_dzg,
        zb, yb, dyb_dzb,
        dLr_dyr,
        dLg_dyg,
        dLb_dyb,
        dargb_dzrgb
    );

    return vec4
    (
        w3_b3_w4_b4.x - LEARNING_RATE * (dargb_dzrgb * da3_dz3) * a2,
        w3_b3_w4_b4.y - LEARNING_RATE * (dargb_dzrgb * da3_dz3),
        w3_b3_w4_b4.z - LEARNING_RATE * (dLr_dyr     * dyr_dzr) * a3,  // dL/dy dy/dz dz/dw3
        w3_b3_w4_b4.w - LEARNING_RATE * (dLr_dyr     * dyr_dzr)        // dL/dy dy/dz dz/db3
    );
}

vec4 updatedParametersBufferD(float t, vec4 w1_b1_w2_b2, vec4 w3_b3_w4_b4, vec4 w5_b5_w6_b6, vec3 yGT)
{
    float z1, a1, da1_dz1;
    float z2, a2, da2_dz2;
    float z3, a3, da3_dz3;
    float zr, yr, dyr_dzr;
    float zg, yg, dyg_dzg;
    float zb, yb, dyb_dzb;
    float dLr_dyr;
    float dLg_dyg;
    float dLb_dyb;
    float dargb_dzrgb;

    backwardPropagation
    (
        t,
        w1_b1_w2_b2,
        w3_b3_w4_b4,
        w5_b5_w6_b6,

        yGT,

        z1, a1, da1_dz1,
        z2, a2, da2_dz2,
        z3, a3, da3_dz3,
        zr, yr, dyr_dzr,
        zg, yg, dyg_dzg,
        zb, yb, dyb_dzb,
        dLr_dyr,
        dLg_dyg,
        dLb_dyb,
        dargb_dzrgb
    );

    return vec4
    (
        w5_b5_w6_b6.x - LEARNING_RATE * (dLg_dyg * dyg_dzg) * a3,    // dL/dy dy/dz dz/dw3
        w5_b5_w6_b6.y - LEARNING_RATE * (dLg_dyg * dyg_dzg),         // dL/dy dy/dz dz/db3
        w5_b5_w6_b6.z - LEARNING_RATE * (dLb_dyb * dyb_dzb) * a3,    // dL/dy dy/dz dz/dw3
        w5_b5_w6_b6.w - LEARNING_RATE * (dLb_dyb * dyb_dzb)          // dL/dy dy/dz dz/db3
    );
}
*/

vec4 updatedParametersBufferB(float t, vec4 w11_b11_w21_b21, vec4 w31_b31_w41_b41, vec4 w42_b42_w43_b43, vec3 yGT)
{
    // forward
    float z11, a11, dz11dw11, dz11db11;
    float z21, a21, dz21dw21, dz21db21;
    float z31, a31, dz31dw31, dz31db31;
    float z41, y41, dz41dw41, dz41db41;
    float z42, y42, dz42dw42, dz42db42;
    float z43, y43, dz43dw43, dz43db43;

    z11 = w11_b11_w21_b21.x * t + w11_b11_w21_b21.y;
    a11 = relu(z11);
    dz11dw11 = t;
    dz11db11 = 1.0;

    z21 = w11_b11_w21_b21.z * a11 + w11_b11_w21_b21.w;
    a21 = relu(z21);
    dz21dw21 = a11;
    dz21db21 = 1.0;

    z31 = w31_b31_w41_b41.x * a21 + w31_b31_w41_b41.y;
    a31 = relu(z31);
    dz31dw31 = a21;
    dz31db31 = 1.0;

    z41 = w31_b31_w41_b41.z * a31 + w31_b31_w41_b41.w;
    y41 = relu(z41);
    dz41dw41 = a31;
    dz41db41 = 1.0;

    z42 = w42_b42_w43_b43.x * a31 + w42_b42_w43_b43.y;
    y42 = relu(z42);
    dz42dw42 = a31;
    dz42db42 = 1.0;

    z43 = w42_b42_w43_b43.z * a31 + w42_b42_w43_b43.w;
    y43 = relu(z43);
    dz43dw43 = a31;
    dz43db43 = 1.0;

    vec3 y = vec3(y41, y42, y43);

    // backward
    vec3 dcdy123;
    float dcdz41;
    float dcdz42;
    float dcdz43;
    float dcdz31;
    float dcdz21;
    float dcdz11;

    dcdy123 = meanSquaredErrorGrad(yGT, y);
    dcdz41 = reluD(z41) * dcdy123.r;
    dcdz42 = reluD(z42) * dcdy123.g;
    dcdz43 = reluD(z43) * dcdy123.b;

    dcdz31 = reluD(z31) * (w31_b31_w41_b41.z * dcdz41 + w42_b42_w43_b43.x * dcdz42 + w42_b42_w43_b43.z * dcdz43);
    dcdz21 = reluD(z21) * (w31_b31_w41_b41.x * dcdz31);
    dcdz11 = reluD(z11) * (w11_b11_w21_b21.z * dcdz21);

    return vec4
    (
        w11_b11_w21_b21.x - LEARNING_RATE * dcdz11 * dz11dw11,
        w11_b11_w21_b21.y - LEARNING_RATE * dcdz11 * dz11db11,
        w11_b11_w21_b21.z - LEARNING_RATE * dcdz21 * dz21dw21,
        w11_b11_w21_b21.w - LEARNING_RATE * dcdz21 * dz21db21
    );
}

vec4 updatedParametersBufferC(float t, vec4 w11_b11_w21_b21, vec4 w31_b31_w41_b41, vec4 w42_b42_w43_b43, vec3 yGT)
{
    // forward
    float z11, a11, dz11dw11, dz11db11;
    float z21, a21, dz21dw21, dz21db21;
    float z31, a31, dz31dw31, dz31db31;
    float z41, y41, dz41dw41, dz41db41;
    float z42, y42, dz42dw42, dz42db42;
    float z43, y43, dz43dw43, dz43db43;

    z11 = w11_b11_w21_b21.x * t + w11_b11_w21_b21.y;
    a11 = relu(z11);
    dz11dw11 = t;
    dz11db11 = 1.0;

    z21 = w11_b11_w21_b21.z * a11 + w11_b11_w21_b21.w;
    a21 = relu(z21);
    dz21dw21 = a11;
    dz21db21 = 1.0;

    z31 = w31_b31_w41_b41.x * a21 + w31_b31_w41_b41.y;
    a31 = relu(z31);
    dz31dw31 = a21;
    dz31db31 = 1.0;

    z41 = w31_b31_w41_b41.z * a31 + w31_b31_w41_b41.w;
    y41 = relu(z41);
    dz41dw41 = a31;
    dz41db41 = 1.0;

    z42 = w42_b42_w43_b43.x * a31 + w42_b42_w43_b43.y;
    y42 = relu(z42);
    dz42dw42 = a31;
    dz42db42 = 1.0;

    z43 = w42_b42_w43_b43.z * a31 + w42_b42_w43_b43.w;
    y43 = relu(z43);
    dz43dw43 = a31;
    dz43db43 = 1.0;

    vec3 y = vec3(y41, y42, y43);

    // backward
    vec3 dcdy123;
    float dcdz41;
    float dcdz42;
    float dcdz43;
    float dcdz31;
    float dcdz21;
    float dcdz11;

    dcdy123 = meanSquaredErrorGrad(yGT, y);
    dcdz41 = reluD(z41) * dcdy123.r;
    dcdz42 = reluD(z42) * dcdy123.g;
    dcdz43 = reluD(z43) * dcdy123.b;

    dcdz31 = reluD(z31) * (w31_b31_w41_b41.z * dcdz41 + w42_b42_w43_b43.x * dcdz42 + w42_b42_w43_b43.z * dcdz43);
    dcdz21 = reluD(z21) * (w31_b31_w41_b41.x * dcdz31);
    dcdz11 = reluD(z11) * (w11_b11_w21_b21.z * dcdz21);

    return vec4
    (
        w31_b31_w41_b41.x - LEARNING_RATE * dcdz31 * dz31dw31,
        w31_b31_w41_b41.y - LEARNING_RATE * dcdz31 * dz31db31,
        w31_b31_w41_b41.z - LEARNING_RATE * dcdz41 * dz41dw41,
        w31_b31_w41_b41.w - LEARNING_RATE * dcdz41 * dz41db41
    );
}

vec4 updatedParametersBufferD(float t, vec4 w11_b11_w21_b21, vec4 w31_b31_w41_b41, vec4 w42_b42_w43_b43, vec3 yGT)
{
    // forward
    float z11, a11, dz11dw11, dz11db11;
    float z21, a21, dz21dw21, dz21db21;
    float z31, a31, dz31dw31, dz31db31;
    float z41, y41, dz41dw41, dz41db41;
    float z42, y42, dz42dw42, dz42db42;
    float z43, y43, dz43dw43, dz43db43;

    z11 = w11_b11_w21_b21.x * t + w11_b11_w21_b21.y;
    a11 = relu(z11);
    dz11dw11 = t;
    dz11db11 = 1.0;

    z21 = w11_b11_w21_b21.z * a11 + w11_b11_w21_b21.w;
    a21 = relu(z21);
    dz21dw21 = a11;
    dz21db21 = 1.0;

    z31 = w31_b31_w41_b41.x * a21 + w31_b31_w41_b41.y;
    a31 = relu(z31);
    dz31dw31 = a21;
    dz31db31 = 1.0;

    z41 = w31_b31_w41_b41.z * a31 + w31_b31_w41_b41.w;
    y41 = relu(z41);
    dz41dw41 = a31;
    dz41db41 = 1.0;

    z42 = w42_b42_w43_b43.x * a31 + w42_b42_w43_b43.y;
    y42 = relu(z42);
    dz42dw42 = a31;
    dz42db42 = 1.0;

    z43 = w42_b42_w43_b43.z * a31 + w42_b42_w43_b43.w;
    y43 = relu(z43);
    dz43dw43 = a31;
    dz43db43 = 1.0;

    vec3 y = vec3(y41, y42, y43);

    // backward
    vec3 dcdy123;
    float dcdz41;
    float dcdz42;
    float dcdz43;
    float dcdz31;
    float dcdz21;
    float dcdz11;

    dcdy123 = meanSquaredErrorGrad(yGT, y);
    dcdz41 = reluD(z41) * dcdy123.r;
    dcdz42 = reluD(z42) * dcdy123.g;
    dcdz43 = reluD(z43) * dcdy123.b;

    dcdz31 = reluD(z31) * (w31_b31_w41_b41.z * dcdz41 + w42_b42_w43_b43.x * dcdz42 + w42_b42_w43_b43.z * dcdz43);
    dcdz21 = reluD(z21) * (w31_b31_w41_b41.x * dcdz31);
    dcdz11 = reluD(z11) * (w11_b11_w21_b21.z * dcdz21);

    return vec4
    (
        w42_b42_w43_b43.x - LEARNING_RATE * dcdz42 * dz42dw42,
        w42_b42_w43_b43.y - LEARNING_RATE * dcdz42 * dz42db42,
        w42_b42_w43_b43.z - LEARNING_RATE * dcdz43 * dz43dw43,
        w42_b42_w43_b43.w - LEARNING_RATE * dcdz43 * dz43db43
    );
}