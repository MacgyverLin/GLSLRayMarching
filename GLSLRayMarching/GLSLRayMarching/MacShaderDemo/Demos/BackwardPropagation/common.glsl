#define MOVABLE_IMAGE
#define BUBBLE_IMAGE
#define LEARNING_RATE 0.005
#define CLIP_DURATION 60.
#define TRAIN_DURATION (CLIP_DURATION)
#define PI 3.1415926535897932384626433832
#define MAX_U 1.0
#define MAX_V 1.0

#define FAST_TANH

float rnd(vec2 n)
{
    return fract(sin(dot(n.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float getT(float iTime)
{
    return 0.5 + 0.5 * cos(iTime * PI);
}

float ReLU(float x)
{
    return max(0., x);
}

float ReLUDerivative(float x)
{
    return step(0., x);
}

float sigmoid(float x)
{
    return 1.0 / (1.0 + exp(-x));
}

float sigmoidDerivative(float x)
{
    float s = sigmoid(x);

    return s * (1.0 - s);
}

#ifdef FAST_TANH
float Tanh(float x)
{
    float x2 = x * x;
    float a = x * (135135.0 + x2 * (17325.0 + x2 * (378.0 + x2)));
    float b = 135135.0 + x2 * (62370.0 + x2 * (3150.0 + x2 * 28.0));

    return a / b;
}
#else
float Tanh(float x)
{
    float s = exp(x);

    return (s - 1.0 / s) / (s + 1.0 / s);
}
#endif
float TanhDerivative(float x)
{
    float s = Tanh(x);

    return 1.0 - s * s;
}

float activation(float x)
{
    return ReLU(x);
    // return sigmoid(x);
    // return Tanh(x);
}

float activationDerivative(float x)
{
    return ReLUDerivative(x);
    // return sigmoidDerivative(x);
    // return TanhDerivative(x);
}

//
vec4 ReLU(vec4 x)
{
    return max(vec4(0.), x);
}

vec4 ReLUDerivative(vec4 x)
{
    return step(0., x);
}


vec4 sigmoid(vec4 x)
{
    return 1.0 / (1.0 + exp(-x));
}

vec4 sigmoidDerivative(vec4 x)
{
    vec4 s = sigmoid(x);

    return s * (1.0 - s);
}

#ifdef FAST_TANH
vec4 Tanh(vec4 x)
{
    vec4 x2 = x * x;
    vec4 a = x * (135135.0 + x2 * (17325.0 + x2 * (378.0 + x2)));
    vec4 b = 135135.0 + x2 * (62370.0 + x2 * (3150.0 + x2 * 28.0));

    return a / b;
}
#else
vec4 Tanh(vec4 x)
{
    vec4 s = exp(x);

    return (s - 1.0 / s) / (s + 1.0 / s);
}
#endif
vec4 TanhDerivative(vec4 x)
{
    vec4 s = Tanh(x);

    return 1.0 - s * s;
}


float MSE(vec4 y, vec4 yHat)
{
    vec4 diff = y - yHat;
    float loss = dot(diff, diff) * 0.25;

    return loss;
}

vec4 MSEDerivative(vec4 y, vec4 yHat)
{
    return y - yHat;
}

vec4 activation(vec4 x)
{
    return ReLU(x);
    // return sigmoid(x);
    // return Tanh(x);
}

vec4 activationDerivative(vec4 x)
{
    return ReLUDerivative(x);
    // return sigmoidDerivative(x);
    // return TanhDerivative(x);
}

float loss(vec4 y, vec4 yHat)
{
    return MSE(y, yHat);
}

vec4 lossDerivative(vec4 y, vec4 yHat)
{
    return MSEDerivative(y, yHat);
}



float meanSquaredError(vec3 groundTruth, vec3 prediction)
{
    vec3 diff = groundTruth - prediction;
    float loss = ((diff.x * diff.x) + (diff.y * diff.y) + (diff.z * diff.z)) * (1. / 3.);

    return loss;
}

vec3 meanSquaredErrorGrad(vec3 groundTruth, vec3 prediction)
{
    return prediction - groundTruth;

    vec3 predXYZ = prediction;
    vec3 truthXYZ = groundTruth;

    return vec3
    (
        (predXYZ.r - truthXYZ.r),
        (predXYZ.g - truthXYZ.g),
        (predXYZ.b - truthXYZ.b)
    );
}

vec3 forwardPropagationPrediction(float t, vec4 w1_b1_w2_b2, vec4 w3_b3_w4_b4, vec4 w5_b5_w6_b6)
{
    float a1 = activation(w1_b1_w2_b2.x * t + w1_b1_w2_b2.y);
    float a2 = activation(w1_b1_w2_b2.z * a1 + w1_b1_w2_b2.w);
    float a3 = activation(w3_b3_w4_b4.x * a2 + w3_b3_w4_b4.y);

    float r = activation(w3_b3_w4_b4.z * a3 + w3_b3_w4_b4.w);
    float g = activation(w5_b5_w6_b6.x * a3 + w5_b5_w6_b6.y);
    float b = activation(w5_b5_w6_b6.z * a3 + w5_b5_w6_b6.w);

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
    a11 = activation(z11);
    dz11dw11 = t;
    dz11db11 = 1.0;

    z21 = w11_b11_w21_b21.z * a11 + w11_b11_w21_b21.w;
    a21 = activation(z21);
    dz21dw21 = a11;
    dz21db21 = 1.0;

    z31 = w31_b31_w41_b41.x * a21 + w31_b31_w41_b41.y;
    a31 = activation(z31);
    dz31dw31 = a21;
    dz31db31 = 1.0;

    z41 = w31_b31_w41_b41.z * a31 + w31_b31_w41_b41.w;
    y41 = activation(z41);
    dz41dw41 = a31;
    dz41db41 = 1.0;

    z42 = w42_b42_w43_b43.x * a31 + w42_b42_w43_b43.y;
    y42 = activation(z42);
    dz42dw42 = a31;
    dz42db42 = 1.0;

    z43 = w42_b42_w43_b43.z * a31 + w42_b42_w43_b43.w;
    y43 = activation(z43);
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
    dcdz41 = activationDerivative(z41) * dcdy123.r;
    dcdz42 = activationDerivative(z42) * dcdy123.g;
    dcdz43 = activationDerivative(z43) * dcdy123.b;

    dcdz31 = activationDerivative(z31) * (w31_b31_w41_b41.z * dcdz41 + w42_b42_w43_b43.x * dcdz42 + w42_b42_w43_b43.z * dcdz43);
    dcdz21 = activationDerivative(z21) * (w31_b31_w41_b41.x * dcdz31);
    dcdz11 = activationDerivative(z11) * (w11_b11_w21_b21.z * dcdz21);

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
    a11 = activation(z11);
    dz11dw11 = t;
    dz11db11 = 1.0;

    z21 = w11_b11_w21_b21.z * a11 + w11_b11_w21_b21.w;
    a21 = activation(z21);
    dz21dw21 = a11;
    dz21db21 = 1.0;

    z31 = w31_b31_w41_b41.x * a21 + w31_b31_w41_b41.y;
    a31 = activation(z31);
    dz31dw31 = a21;
    dz31db31 = 1.0;

    z41 = w31_b31_w41_b41.z * a31 + w31_b31_w41_b41.w;
    y41 = activation(z41);
    dz41dw41 = a31;
    dz41db41 = 1.0;

    z42 = w42_b42_w43_b43.x * a31 + w42_b42_w43_b43.y;
    y42 = activation(z42);
    dz42dw42 = a31;
    dz42db42 = 1.0;

    z43 = w42_b42_w43_b43.z * a31 + w42_b42_w43_b43.w;
    y43 = activation(z43);
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
    dcdz41 = activationDerivative(z41) * dcdy123.r;
    dcdz42 = activationDerivative(z42) * dcdy123.g;
    dcdz43 = activationDerivative(z43) * dcdy123.b;

    dcdz31 = activationDerivative(z31) * (w31_b31_w41_b41.z * dcdz41 + w42_b42_w43_b43.x * dcdz42 + w42_b42_w43_b43.z * dcdz43);
    dcdz21 = activationDerivative(z21) * (w31_b31_w41_b41.x * dcdz31);
    dcdz11 = activationDerivative(z11) * (w11_b11_w21_b21.z * dcdz21);

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
    a11 = activation(z11);
    dz11dw11 = t;
    dz11db11 = 1.0;

    z21 = w11_b11_w21_b21.z * a11 + w11_b11_w21_b21.w;
    a21 = activation(z21);
    dz21dw21 = a11;
    dz21db21 = 1.0;

    z31 = w31_b31_w41_b41.x * a21 + w31_b31_w41_b41.y;
    a31 = activation(z31);
    dz31dw31 = a21;
    dz31db31 = 1.0;

    z41 = w31_b31_w41_b41.z * a31 + w31_b31_w41_b41.w;
    y41 = activation(z41);
    dz41dw41 = a31;
    dz41db41 = 1.0;

    z42 = w42_b42_w43_b43.x * a31 + w42_b42_w43_b43.y;
    y42 = activation(z42);
    dz42dw42 = a31;
    dz42db42 = 1.0;

    z43 = w42_b42_w43_b43.z * a31 + w42_b42_w43_b43.w;
    y43 = activation(z43);
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
    dcdz41 = activationDerivative(z41) * dcdy123.r;
    dcdz42 = activationDerivative(z42) * dcdy123.g;
    dcdz43 = activationDerivative(z43) * dcdy123.b;

    dcdz31 = activationDerivative(z31) * (w31_b31_w41_b41.z * dcdz41 + w42_b42_w43_b43.x * dcdz42 + w42_b42_w43_b43.z * dcdz43);
    dcdz21 = activationDerivative(z21) * (w31_b31_w41_b41.x * dcdz31);
    dcdz11 = activationDerivative(z11) * (w11_b11_w21_b21.z * dcdz21);

    return vec4
    (
        w42_b42_w43_b43.x - LEARNING_RATE * dcdz42 * dz42dw42,
        w42_b42_w43_b43.y - LEARNING_RATE * dcdz42 * dz42db42,
        w42_b42_w43_b43.z - LEARNING_RATE * dcdz43 * dz43dw43,
        w42_b42_w43_b43.w - LEARNING_RATE * dcdz43 * dz43db43
    );
}

//////////////////////////////////////////////////////////////
vec4 forwardPropagation(in vec4 x, in mat4 wLayer1, in vec4 bLayer1, in mat4 wLayer2, in vec4 bLayer2, in mat4 wLayer3, in vec4 bLayer3, in mat4 wLayer4, in vec4 bLayer4)
{
    vec4 z1, a1;
    vec4 z2, a2;
    vec4 z3, a3;
    vec4 z4, a4;
    vec4 yHat;

    z1 = wLayer1 * x + bLayer1;
    a1 = activation(z1);

    z2 = wLayer2 * a1 + bLayer2;
    a2 = activation(z2);

    z3 = wLayer3 * a2 + bLayer3;
    a3 = activation(z3);

    z4 = wLayer4 * a3 + bLayer4;
    a4 = activation(z4);

    yHat = a4;

    return yHat;
}

void backWardPropagation(in vec4 x, in vec4 yGT, inout mat4 wLayer1, inout vec4 bLayer1, inout mat4 wLayer2, inout vec4 bLayer2, inout mat4 wLayer3, inout vec4 bLayer3, inout mat4 wLayer4, inout vec4 bLayer4)
{
    // forward
    vec4 z1, a1;
    vec4 dz1_dwLayer1;
    vec4 dz1_dbLayer1;

    vec4 z2, a2;
    vec4 dz2_dwLayer2;
    vec4 dz2_dbLayer2;

    vec4 z3, a3;
    vec4 dz3_dwLayer3;
    vec4 dz3_dbLayer3;

    vec4 z4, a4;
    vec4 dz4_dwLayer4;
    vec4 dz4_dbLayer4;

    vec4 yHat;

    z1 = wLayer1 * x + bLayer1;
    a1 = activation(z1);
    dz1_dwLayer1 = x;
    dz1_dbLayer1 = vec4(1.0);

    z2 = wLayer2 * a1 + bLayer2;
    a2 = activation(z2);
    dz2_dwLayer2 = a1;
    dz2_dbLayer2 = vec4(1.0);

    z3 = wLayer3 * a2 + bLayer3;
    a3 = activation(z3);
    dz3_dwLayer3 = a2;
    dz3_dbLayer3 = vec4(1.0);

    z4 = wLayer4 * a3 + bLayer4;
    a4 = activation(z4);
    dz4_dwLayer4 = a3;
    dz4_dbLayer4 = vec4(1.0);

    yHat = a4;

    // backward  w = w - learningRate * dc/dw

    // 1) compute: dc/dy
    //    
    // 2) compute: dc/dz
    //             dc/dz4 = dy/dz4 * dc/dy
    //             dc/dz3 = da3/dz3 * dz4/da3 * dc/dz4
    //             dc/dz2 = da3/dz2 * dz4/da2 * dc/dz3
    //             dc/dz1 = da3/dz1 * dz4/da1 * dc/dz2
    // 3) compute dC/dw
    // 4) gradient descent

    // 1) compute: dc/dy
    vec4 dc_dy;
    dc_dy = lossDerivative(yGT, yHat);

    // 2) compute: dc/dz
    vec4 dc_dz4;
    vec4 dc_dz3;
    vec4 dc_dz2;
    vec4 dc_dz1;
    dc_dz4 = activationDerivative(z4) * dc_dy;
    dc_dz3 = activationDerivative(z3) * transpose(wLayer4) * dc_dz4; // activationD(z3) * transpose(wLayer4) * dc_dz4
    dc_dz2 = activationDerivative(z2) * transpose(wLayer3) * dc_dz3; // activationD(z2) * transpose(wLayer3) * dc_dz3
    dc_dz1 = activationDerivative(z1) * transpose(wLayer2) * dc_dz2; // activationD(z1) * transpose(wLayer2) * dc_dz2

    // 3) compute dC/dw
    mat4 dc_dwLayer4 = mat4
    (
        dz4_dwLayer4.x * dc_dz4,
        dz4_dwLayer4.y * dc_dz4,
        dz4_dwLayer4.z * dc_dz4,
        dz4_dwLayer4.w * dc_dz4
    );
    vec4 dc_dbLayer4 = dz4_dbLayer4 * dc_dz4;

    mat4 dc_dwLayer3 = mat4
    (
        dz3_dwLayer3.x * dc_dz3,
        dz3_dwLayer3.y * dc_dz3,
        dz3_dwLayer3.z * dc_dz3,
        dz3_dwLayer3.w * dc_dz3
    );
    vec4 dc_dbLayer3 = dz3_dbLayer3 * dc_dz3;

    mat4 dc_dwLayer2 = mat4
    (
        dz2_dwLayer2.x * dc_dz2,
        dz2_dwLayer2.y * dc_dz2,
        dz2_dwLayer2.z * dc_dz2,
        dz2_dwLayer2.w * dc_dz2
    );
    vec4 dc_dbLayer2 = dz2_dbLayer2 * dc_dz2;

    mat4 dc_dwLayer1 = mat4
    (
        dz1_dwLayer1.x * dc_dz1,
        dz1_dwLayer1.y * dc_dz1,
        dz1_dwLayer1.z * dc_dz1,
        dz1_dwLayer1.w * dc_dz1
    );
    vec4 dc_dbLayer1 = dz1_dbLayer1 * dc_dz1;

    // 4) gradient descent
    wLayer4 = wLayer4 - LEARNING_RATE * dc_dwLayer4; // dc_dz4 * dz4_dwLayer4;
    bLayer4 = bLayer4 - LEARNING_RATE * dc_dbLayer4; // dc_dz4 * dz4_dbLayer4;
    wLayer3 = wLayer3 - LEARNING_RATE * dc_dwLayer3; // dc_dz3 * dz3_dwLayer3;
    bLayer3 = bLayer3 - LEARNING_RATE * dc_dbLayer3; // dc_dz3 * dz3_dbLayer3;
    wLayer2 = wLayer2 - LEARNING_RATE * dc_dwLayer2; // dc_dz2 * dz2_dwLayer2;
    bLayer2 = bLayer2 - LEARNING_RATE * dc_dbLayer2; // dc_dz2 * dz2_dbLayer2;
    wLayer1 = wLayer1 - LEARNING_RATE * dc_dwLayer1; // dc_dz1 * dz1_dwLayer1;
    bLayer1 = bLayer1 - LEARNING_RATE * dc_dbLayer1; // dc_dz1 * dz1_dbLayer1;
}