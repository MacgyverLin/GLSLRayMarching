#define HALF_PI 1.570796326794896
#define ONE_PI 3.141592653589793
#define TWO_PI 6.283185307179586

#define ID_3X3      mat3( 1., 0., 0.,   0., 1., 0.,   0., 0., 1.)
#define ROT_X       mat3( 1., 0., 0.,   0., 0., 1.,   0.,-1., 0.)
#define ROT_X_INV   mat3( 1., 0., 0.,   0., 0.,-1.,   0., 1., 0.)
#define ROT_Y       mat3( 0., 0.,-1.,   0., 1., 0.,   1., 0., 0.)
#define ROT_Y_INV   mat3( 0., 0., 1.,   0., 1., 0.,  -1., 0., 0.)
#define ROT_Z       mat3( 0., 1., 0.,  -1., 0., 0.,   0., 0., 1.)
#define ROT_Z_INV   mat3( 0.,-1., 0.,   1., 0., 0.,   0., 0., 1.)

#define E1 vec3(1.0, 0.0, 0.0)
#define E2 vec3(0.0, 1.0, 0.0)
#define E3 vec3(0.0, 0.0, 1.0)

#define TAN_HALF_FOVY 0.5773502691896257
#define CAM_Z_NEAR 0.1
#define CAM_Z_FAR 50.0

#define MIN_DIST 0.005
#define MAX_DIST 50.0
#define GRAD_EPS 0.01

#define MAX_BRANCH_DEPTH 18

#define SPHERE_CENTER vec3(0.0)
#define SPHERE_RADIUS 2.0
#define SPHERE_BUFFER 0.1

#define SUBSPHERE_ZOOM 2.75
#define SUBSPHERE_RADIUS (SPHERE_RADIUS/SUBSPHERE_ZOOM)
#define SUBSPHERE_CENTER_L vec3(-SUBSPHERE_RADIUS-0.001, 0.0, 0.0)
#define SUBSPHERE_CENTER_R vec3( SUBSPHERE_RADIUS+0.001, 0.0, 0.0)

#define Q_RADIUS (0.5*(SPHERE_RADIUS-SPHERE_BUFFER-2.0*SUBSPHERE_RADIUS)-0.001)

// If we move to the "left" subsphere center infinitely many times, based on the
// left subsphere transform (cf. makeTL) we end up at the following point:
#define L_INF_X (SUBSPHERE_CENTER_L.x/(1.0+1.0/(SUBSPHERE_ZOOM*SUBSPHERE_ZOOM)))
#define L_INF_POS vec3(L_INF_X, L_INF_X/SUBSPHERE_ZOOM, 0.0)

// =============================================
// Some generic helpers
// =============================================

// Find t so that mix(a,b,t) = x
float unmix(float a, float b, float x) {
    return (x - a)/(b - a);
}

float distsq(vec3 p, vec3 q) {
    vec3 pq = q - p;
    return dot(pq, pq);
}

mat4 getClipToWorld(float aspectWoverH, vec3 nvCamFw, vec3 nvCamFixedUp) {
    mat4 clipToEye = mat4(
        aspectWoverH * TAN_HALF_FOVY, 0.0, 0.0, 0.0,
        0.0, TAN_HALF_FOVY, 0.0, 0.0,
        0.0, 0.0,  0.0, (CAM_Z_NEAR - CAM_Z_FAR)/(2.0 * CAM_Z_NEAR * CAM_Z_FAR),
        0.0, 0.0, -1.0, (CAM_Z_NEAR + CAM_Z_FAR)/(2.0 * CAM_Z_NEAR * CAM_Z_FAR)
    );

    vec3 nvCamRt = normalize(cross(nvCamFw, nvCamFixedUp));
    vec3 nvCamUp = cross(nvCamRt, nvCamFw);
    mat4 eyeToWorld = mat4(
         nvCamRt, 0.0,
         nvCamUp, 0.0,
        -nvCamFw, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    return eyeToWorld * clipToEye;
}

void computeLighting(
    in float diffuseCoefficient,
    in float specularCoefficient,
    in float specularExponent,
    in vec3 lightColor,
    in vec3 texColor,
    in vec3 nvNormal,
    in vec3 nvFragToLight,
    in vec3 nvFragToCam,
    out vec3 litColor
) {
    float valDiffuse = max(0.0, dot(nvNormal, nvFragToLight));
    valDiffuse *= diffuseCoefficient;

    vec3 blinnH = normalize(nvFragToLight + nvFragToCam);
    float valSpecular = pow(max(0.0, dot(nvNormal, blinnH)), specularExponent);
    valSpecular *= specularCoefficient;

    litColor = valDiffuse*texColor*lightColor + valSpecular*lightColor;
}

void sphereClip(
    in vec3 center, in float radius,
    in vec3 p, in vec3 v,
    out vec2 tRange, out float didHit
) {
    // Solve quadratic in t: |p+tv - center|^2 = radius^2
    // Or, |A+tB|^2 = 1, with A = (p-center)/radius, B = v/radius
    // Solution: t = (-A.B +- sqrt(D))/|B|^2, D = (A.B)^2 + |B|^2 * (1-|A|^2).

    vec3 A = (p - center) / radius;
    vec3 B = v / radius;

    float AA = dot(A,A);
    float AB = dot(A,B);
    float BB = dot(B,B);

    float D = AB*AB + BB*(1.0 - AA);
    float sqD = sqrt(abs(D));
    didHit = 1.0 - step(D, 0.0);

    float t0 = (-AB + sqD)/BB;
    float t1 = (-AB - sqD)/BB;
    tRange = vec2(min(t0,t1), max(t0,t1));
}

// =============================================
// Recursive transform helpers
// =============================================

// Treats the bits of an integer as a stack, with
// "0" meaning "left branch" and "1" meaning "right branch"

void pushBranch(inout int branch, inout int branchDepth, int val) {
    if (branchDepth == 0) {
        branch = val;
    } else {
        branch = 2*branch + val;
    }
    branchDepth++;
}

int popBranch(inout int branch, inout int branchDepth) {
    int b2 = branch % 2;
    branch = (branch - b2) / 2;
    branchDepth--;
    return b2;
}

void makeTL(out mat3 transM, out mat3 transMInv, out vec3 transO) {
    transM = SUBSPHERE_ZOOM*ROT_Z_INV;
    transMInv = (1.0/SUBSPHERE_ZOOM)*ROT_Z;
    transO = SUBSPHERE_CENTER_L;
}

void makeTR(out mat3 transM, out mat3 transMInv, out vec3 transO) {
    transM = SUBSPHERE_ZOOM*ROT_X*ROT_Y;
    transMInv = (1.0/SUBSPHERE_ZOOM)*ROT_Y_INV*ROT_X_INV;
    transO = SUBSPHERE_CENTER_R;
}

void makeT(
    in int branch, in int branchDepth,
    out mat3 transM, out mat3 transMInv, out vec3 transO
) {
    transMInv = ID_3X3;
    transM = ID_3X3;
    transO = vec3(0.0);

    int b = branch;
    for (int i=0; i<branchDepth; i++) {
        int b2 = b % 2;

        mat3 curM;
        mat3 curMInv;
        vec3 curO;

        if (b2 == 0) {
            makeTL(curM, curMInv, curO);
        } else {
            makeTR(curM, curMInv, curO);
        }

        transM = transM * curM;
        transMInv = curMInv * transMInv;
        transO = curO + curMInv*transO;

        b = (b - b2) / 2;
    }
}

// =============================================
// "Object" helpers
// =============================================

// circT maps circle in xy plane to desired circle:
// i.e., mat3("zero angle direction", "90 degrees direction", circ plane normal)
// and circTInv is the transpose
// uvAng is (theta,phi) where theta is 0 in the "zero angle direction"
void cpCirc(
    in vec3 circCenter, in float circRadius,
    in mat3 circT, in mat3 circTInv, in vec3 p,
    out vec3 cp, out vec2 uvAng
) {
    vec3 v = circTInv*(p - circCenter);

    vec3 vProj = vec3(v.xy, 0.0);
    float vProjLen = length(v.xy);
    vec3 cpT = (circRadius/vProjLen)*vProj;

    uvAng = vec2(
        atan(v.y, v.x),
        atan(v.z, vProjLen-circRadius)
    );
    cp = circT*cpT + circCenter;
}

vec3 cpTuple2(vec3 q0, vec3 q1, vec3 p) {
    vec3 q = q0;
    return mix(q, q1, step( distsq(p,q1), distsq(p,q) ));
}

float radiusMultiplier(vec2 uvAng, float maxAngle) {
    float rt = abs(uvAng.s)/maxAngle;
    return mix(1.0, 1.0/SUBSPHERE_ZOOM, smoothstep(0.4, 0.9, rt));
}

vec2 uvAng_to_uv(vec2 uvAng, float maxAngle) {
    return vec2(
        unmix(-maxAngle, maxAngle, uvAng.s),
        unmix(-ONE_PI, ONE_PI, uvAng.t)
    );
}

void sdBaseUV(in vec3 p, out vec3 uv, out float sd) {
    // ---------------------------------------------------
    // Basic geometry piece is a circle which hits 3 points:
    // - (-x0,   0 ): Q_RADIUS from the left-most edge of main sphere
    // - ( x1, +-y1): Top and bottom of right subsphere

    const float x0 = SPHERE_RADIUS-SPHERE_BUFFER - Q_RADIUS;
    const float x1 = SUBSPHERE_CENTER_R.x;
    const float y1 = x0/SUBSPHERE_ZOOM;
    float linkCenter = (x1-x0)/2.0 + (y1/2.0)*(1.0/(x0+x1)) * y1;
    float linkRadius = x0 + linkCenter;
    float maxAngle = atan(y1, -(x1 - linkCenter));
    // ---------------------------------------------------

    // "Left" link (in xz-plane):
    vec3 cpL;
    vec2 uvAngL;
    cpCirc(
        vec3(linkCenter,0.0,0.0), linkRadius,
        mat3(-E1,E3,E2), mat3(-E1,E3,E2), p, cpL, uvAngL
    );
    float dsqL = distsq(p, cpL);

    // "Right" link (in xy-plane):
    vec3 cpR;
    vec2 uvAngR;
    cpCirc(
        vec3(-linkCenter,0.0,0.0), linkRadius,
        mat3(E1,E2,E3), mat3(E1,E2,E3), p, cpR, uvAngR
    );
    float dsqR = distsq(p, cpR);

    // "Parent" link: right-link with inv. left-transform applied (or reverse!)
    mat3 transLM;
    mat3 transLMInv;
    vec3 transLO;
    makeTL(transLM, transLMInv, transLO);

    vec3 pT = transLMInv*p + transLO;
    vec3 cpP;
    vec2 uvAngP;
    cpCirc(
        vec3(-linkCenter,0.0,0.0), linkRadius,
        mat3(E1,E2,E3), mat3(E1,E2,E3), pT, cpP, uvAngP
    );
    float cull = step( maxAngle, abs(uvAngP.s) );
    cpP = mix( cpP, cpTuple2(vec3(-x1,-y1,0.0), vec3(-x1,y1,0.0), pT), cull );
    cpP = transLM*(cpP - transLO);
    float dsqP = distsq(p, cpP);

    float hitRadius = Q_RADIUS;
    if (dsqP < dsqL && dsqP < dsqR) {
        // NOTE: uv.p is used to correct the smoothBranchDepth elsewhere
        uv = vec3(uvAng_to_uv(uvAngP, maxAngle), 1.0);
        hitRadius *= SUBSPHERE_ZOOM;
        sd = distance(p, cpP) - hitRadius * radiusMultiplier(uvAngP, maxAngle);
    } else if (dsqL < dsqR) {
        uv = vec3(uvAng_to_uv(uvAngL, maxAngle), 0.0);
        sd = distance(p, cpL) - hitRadius * radiusMultiplier(uvAngL, maxAngle);
    } else {
        uv = vec3(uvAng_to_uv(uvAngR, maxAngle), 0.0);
        sd = distance(p, cpR) - hitRadius * radiusMultiplier(uvAngR, maxAngle);
    }
}

void objNormal(in vec3 p, out vec3 hitNormal) {
    float fXA, fXB, fYA, fYB, fZA, fZB;
    vec3 uv;

    sdBaseUV(p - vec3(GRAD_EPS, 0.0, 0.0), uv, fXA);
    sdBaseUV(p + vec3(GRAD_EPS, 0.0, 0.0), uv, fXB);
    sdBaseUV(p - vec3(0.0, GRAD_EPS, 0.0), uv, fYA);
    sdBaseUV(p + vec3(0.0, GRAD_EPS, 0.0), uv, fYB);
    sdBaseUV(p - vec3(0.0, 0.0, GRAD_EPS), uv, fZA);
    sdBaseUV(p + vec3(0.0, 0.0, GRAD_EPS), uv, fZB);

    hitNormal = vec3(fXB-fXA, fYB-fYA, fZB-fZA);
}

void hitObject(
    in vec3 p, in vec3 nv, in vec2 tRange,
    out float didHit, out float tHit, out vec3 uvHit
) {
    didHit = 0.0;
    vec3 curPos = p + tRange.s*nv;
    tHit = tRange.s;

    for (int i=0; i<50; i++) {
        float tAdd;
        sdBaseUV(curPos, uvHit, tAdd);

        if (abs(tAdd) < MIN_DIST) {
            didHit = 1.0;
            break;
        }

        curPos += tAdd * nv;
        tHit += tAdd;

        if (tHit > tRange.t) {
            break;
        }
    }
}

// =============================================
// Recursive scene
// =============================================

float inInterval(float t, vec2 tRange) {
    return step(tRange.s, t) * (1.0 - step(tRange.t, t));
}

vec2 minHitData(float t, vec2 minData, vec2 tRangeAllowed, float typeId) {
    float doUse = inInterval(t, tRangeAllowed) * step(t, minData.x);
    return mix( minData, vec2(t, typeId), doUse );
}

void march(
    in vec3 p, in vec3 nv,
    out float didHit, out vec3 hitPos,
    out vec3 nvHitNormal, out vec3 hitUV, out int hitBranchDepth
) {
    // Update range for root sphere
    vec2 tRangeRoot;
    float didHitSphere;
    sphereClip(SPHERE_CENTER, SPHERE_RADIUS, p, nv, tRangeRoot, didHitSphere);
    if (didHitSphere < 0.5) {
        didHit = 0.0;
        return;
    }

    // transform is p \mapsto M(p - O)
    mat3 transMInv = ID_3X3;
    mat3 transM = ID_3X3;
    vec3 transO = vec3(0.0);

    vec3 pTransRay = p;
    vec3 nvTransRay = nv;
    vec2 tRangeCur = tRangeRoot;

    int branchDepth = 0;
    int branch = -1;

    for (int i=0; i<100; i++) { // TODO

        vec2 hitData = vec2(tRangeCur.t, 0.0);

        // Check object hit within sphere
        float didHitObject;
        float tHitObject;
        vec3 uvHitObject;
        hitObject(
            pTransRay, nvTransRay, vec2(max(0.0, tRangeCur.s), tRangeCur.t),
            didHitObject, tHitObject, uvHitObject
        );
        if (didHitObject > 0.5) {
            hitData = minHitData(tHitObject, hitData, tRangeCur, 0.1);
        }

        // Check "left" subsphere hit
        vec2 tRangeSubsphereL;
        float didHitL;
        sphereClip(
            SUBSPHERE_CENTER_L, SUBSPHERE_RADIUS, pTransRay, nvTransRay,
            tRangeSubsphereL, didHitL
        );
        if (branchDepth < MAX_BRANCH_DEPTH && didHitL > 0.5) {
            hitData = minHitData(tRangeSubsphereL.s, hitData, tRangeCur, 0.2);
        }

        // Check "right" subsphere hit
        vec2 tRangeSubsphereR;
        float didHitR;
        sphereClip(
            SUBSPHERE_CENTER_R, SUBSPHERE_RADIUS, pTransRay, nvTransRay,
            tRangeSubsphereR, didHitR
        );
        if (branchDepth < MAX_BRANCH_DEPTH && didHitR > 0.5) {
            hitData = minHitData(tRangeSubsphereR.s, hitData, tRangeCur, 0.3);
        }

        if (hitData.y < 0.05) {

            // Exiting sphere: "pop" transform to parent sphere

            if (branchDepth == 0) {
                break;
            }
            popBranch(branch, branchDepth);
            makeT(branch, branchDepth, transM, transMInv, transO);

            pTransRay = transM * (p - transO);
            nvTransRay = normalize( transM * nv );

            vec2 tRangeParent;
            float didHitSphereParent;
            sphereClip(
                SPHERE_CENTER, SPHERE_RADIUS, pTransRay, nvTransRay,
                tRangeParent, didHitSphereParent
            );
            tRangeCur = vec2(tRangeCur.t/SUBSPHERE_ZOOM, tRangeParent.t);

        } else if (hitData.y < 0.15) {

            // Hit object--done!

            didHit = 1.0;
            vec3 hitPosTrans = pTransRay + tHitObject*nvTransRay;
            hitPos = transMInv*hitPosTrans + transO;

            vec3 hitNormal;
            objNormal(hitPosTrans, hitNormal);
            nvHitNormal = normalize(transMInv*hitNormal);

            hitUV = uvHitObject;
            hitBranchDepth = branchDepth;

            break;

        } else if (hitData.y < 0.25) {

            // Entered "left" subsphere; push transform and continue

            pushBranch(branch, branchDepth, 0);
            makeT(branch, branchDepth, transM, transMInv, transO);

            pTransRay = transM * (p - transO);
            nvTransRay = normalize( transM * nv );
            tRangeCur = tRangeSubsphereL * SUBSPHERE_ZOOM;

        } else if (hitData.y < 0.35) {

            // Entered "right" subsphere; push transform and continue

            pushBranch(branch, branchDepth, 1);
            makeT(branch, branchDepth, transM, transMInv, transO);

            pTransRay = transM * (p - transO);
            nvTransRay = normalize( transM * nv );
            tRangeCur = tRangeSubsphereR * SUBSPHERE_ZOOM;

        }
    }

}

void camConfig(
    out float scfa,
    out vec3 camPos,
    out vec3 nvCamFw,
    out vec3 nvCamFixedUp
) {
    float itAdj = iTime/3.0;
    if (iMouse.z > 0.0) {
        itAdj = 12.0*iMouse.y/iResolution.y;
    }
    float ft4 = fract(itAdj/4.0)*4.0;

    // scfa is the scale factor at the current cam pos: how much things are
    // scaled relative to the "base object" in the root/parent sphere
    scfa = pow(1.0/SUBSPHERE_ZOOM, ft4+2.0);

    float ct = cos(itAdj*HALF_PI);
    float st = sin(itAdj*HALF_PI);

    vec3 camOffset = normalize(vec3(1.0, 1.5*ct, 1.0));
    camPos = L_INF_POS + camOffset*scfa;
    nvCamFw = normalize(-camOffset);
    nvCamFixedUp = normalize(vec3(cos(0.5*ct), 0.0, sin(0.5*ct)));
}

vec3 skybox(vec3 nvDir) {
    float sep = -0.15;
    float blend = 0.025;
    return mix(
        mix(vec3(1.0), vec3(0.8, 0.45, 0.25), unmix(-1.0, sep, nvDir.x)),
        mix(vec3(1.0), vec3(0.7, 0.6, 1.0), unmix(sep, 1.0, nvDir.x)),
        smoothstep(sep-blend, sep+blend, nvDir.x)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    float scfa;
    vec3 camPos;
    vec3 nvCamFw;
    vec3 nvCamFixedUp;
    camConfig(scfa, camPos, nvCamFw, nvCamFixedUp);

    float aspectWoverH = iResolution.x/iResolution.y;
    mat4 clipToWorld = getClipToWorld(aspectWoverH, nvCamFw, nvCamFixedUp);

    vec4 vWorld = clipToWorld * vec4(uv*2.0 - 1.0, 1.0, 1.0);
    vec3 nvCamDir = normalize(vWorld.xyz / vWorld.w);

    vec4 color = vec4(1.0);

    float didHit;
    vec3 hitPos;
    vec3 nvHitNormal;
    vec3 hitUV;
    int hitBranchDepth;
    march(camPos, nvCamDir, didHit, hitPos, nvHitNormal, hitUV, hitBranchDepth);
    if (didHit > 0.5) {

        vec3 nvCamRt = normalize(cross(nvCamFw, nvCamFixedUp));
        vec3 nvCamUp = normalize(cross(nvCamRt, nvCamFw));
        vec3 lightPos = mix(camPos, L_INF_POS, 0.5);

        float smoothBranchDepth = (
            float(hitBranchDepth) + 2.0*abs(hitUV.s - 0.5) - hitUV.p
        );
        float ct = fract(smoothBranchDepth/4.0);
        float ctt = fract(-0.2*iTime + smoothBranchDepth/4.0);
        vec3 matColor = 0.5 + 0.5*vec3(
            cos(TWO_PI * ct),
            cos(TWO_PI * (ct - 1.0/3.0)),
            cos(TWO_PI * (ct - 2.0/3.0))
        );
        float pulse = 1.0 - step(0.25+0.25*sin(iTime), abs(ctt-0.5));
        matColor = mix(matColor, vec3(0.0), pulse);

        vec3 nvFragToCam = normalize(camPos - hitPos);
        vec3 nvFragToLight = normalize(lightPos - hitPos);

        vec3 litColor;
        computeLighting(
            0.8, 1.0, 50.0,
            vec3(1.0), matColor, nvHitNormal,
            nvFragToLight,
            nvFragToCam,
            litColor
        );

        vec3 nvRefl = normalize(reflect( hitPos-camPos, nvHitNormal ));
        vec3 skyColor = skybox(nvRefl);

        vec3 finalColor = litColor;
        finalColor += 0.4*skyColor; //reflective
        finalColor += 0.25*matColor; //emissive
        finalColor = clamp(finalColor, 0.0, 1.0);

        float dScale = length(hitPos-camPos)/length(L_INF_POS-camPos);
        float dVal = clamp( unmix(0.0, 20.0, dScale), 0.0, 1.0 );
        float dA = 100.0; // higher gives more detail on nearer values
        float finalDepth = log(dA*dVal+1.0)/log(dA+1.0);

        color = vec4(finalColor, finalDepth);

    }

    fragColor = color;
}
