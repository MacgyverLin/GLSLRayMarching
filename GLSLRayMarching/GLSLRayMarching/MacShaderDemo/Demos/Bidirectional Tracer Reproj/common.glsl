#define TWO_PI 6.28318530718
#define PI 3.14159265359
#define FOV 1.1
#define CAM_ANGLE 0.001
#define MAX_STEPS 90
#define MIN_DIST 1e-5
#define MAX_DIST 500.0

//(reused some of @ollj's code, made it more readible)

vec3 light = normalize(vec3(0,1,0));
const float light_bright =1.0;
const float light_ang = 0.1;

//specific controller buffer Addresses
const float CamP = 0.,     //camera position 
            CamA = 1.,     //camera rotation quaternion    
            CamV = 2.,     //camera velocity
            CamAV = 3.,    //camera rotation velocity
            PrevCamP = 4., //previous frame camera position
            PrevCamA = 5., //previous frame camera rotation quaternion
            PrevMouse = 6.,//previous mouse pos
            RayO = 7.,     //previous mouse pos
            RayD = 8.,     //previous mouse pos
            NAddr = 9.;    //max address count
            
#define get(i) texelFetch(iChannel2,ivec2(i,0),0)

float sqr(float x)
{
    return x*x;
}

vec3 reproject(mat3 pcam_mat, vec3 pcam_pos, vec2 iRes, vec3 p)
{
    float td = distance(pcam_pos, p);
    vec3 dir = (p - pcam_pos)/td;
    vec3 screen = dir*pcam_mat;
    return vec3(screen.xy*iRes.y/(FOV*screen.z) + 0.5*iRes.xy, td);
}

float iPlane( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
              in vec3 planeNormal, in float planeDist) {
    float a = dot(rd, planeNormal);
    float d = -(dot(ro, planeNormal)+planeDist)/a;
    if (a > 0. || d < distBound.x || d > distBound.y) {
        return MAX_DIST;
    } else {
        normal = planeNormal;
    	return d;
    }
}

float iSphere( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
               float sphereRadius ) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - sphereRadius*sphereRadius;
    float h = b*b - c;
    if (h < 0.) {
        return MAX_DIST;
    } else {
	    h = sqrt(h);
        float d1 = -b-h;
        float d2 = -b+h;
        if (d1 >= distBound.x && d1 <= distBound.y) {
            normal = normalize(ro + rd*d1);
            return d1;
        } else if (d2 >= distBound.x && d2 <= distBound.y) { 
            normal = normalize(ro + rd*d2);            
            return d2;
        } else {
            return MAX_DIST;
        }
    }
}

float iBox( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal, 
            in vec3 boxSize ) {
    vec3 m = sign(rd)/max(abs(rd), 1e-8);
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
    if (tN > tF || tF <= 0.) {
        return MAX_DIST;
    } else {
        if (tN >= distBound.x && tN <= distBound.y) {
        	normal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return tN;
        } else if (tF >= distBound.x && tF <= distBound.y) { 
        	normal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return tF;
        } else {
            return MAX_DIST;
        }
    }
}

float iCylinder( in vec3 ro, in vec3 rd, 
                in vec3 pa, in vec3 pb, float ra ) // extreme a, extreme b, radius
{
    vec3 ba = pb-pa;

    vec3  oc = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoc = dot(ba,oc);
    
    float k2 = baba            - bard*bard;
    float k1 = baba*dot(oc,rd) - baoc*bard;
    float k0 = baba*dot(oc,oc) - baoc*baoc - ra*ra*baba;
    
    float h = k1*k1 - k2*k0;
    if( h<0.0 ) return 1e10;
    h = sqrt(h);
    float t = (-k1-h)/k2;

    // body
    float y = baoc + t*bard;
    if( y>0.0 && y<baba ) return t;
    
    // caps
    t = ( ((y<0.0) ? 0.0 : baba) - baoc)/bard;
    if( abs(k1+k2*t)<h )
    {
        return t;
    }

    return 1e10;
}

//ollj quaternionRotation math
//
//ANY rotations in 3d are non-commutative!
//
//matrix rotations are just bulky, memory wasting
//EulerRotations almost certainly fail to rotate over the SHORTEST path.
//EulerRotations almost certainly will gimbalLock and get stuck along one axis
//QuaternionRotations are superior here.
//-> we only use EulerRorations for simple input devices (keyboard input)
//-> we convert to quaternions, buffered as vec4.

//quaternion Identity
vec4 qid() 
{
    return vec4(0, 0, 0, 1);
}

//return quaternion from axis and angle
vec4 aa2q(vec3 axis, float ang) 
{
    vec2 g = vec2(sin(ang), cos(ang)) * 0.5;
    return normalize(vec4(axis * g.x, g.y));
}

//return AxisAngle of NORMALIZED quaternion input
vec4 q2aa(vec4 q) 
{
    return vec4(q.xyz / sqrt(1.0 - q.w * q.w), acos(q.w) * 2.);
}

//return q2, rotated by q1, order matters (is non commutative) : (aka quaternion multiplication == AxisAngleRotation)
vec4 qq2q(vec4 q1, vec4 q2) 
{
    return vec4(q1.xyz * q2.w + q2.xyz * q1.w + cross(q1.xyz, q2.xyz), (q1.w * q2.w) - dot(q1.xyz, q2.xyz));
}

//extension to qq2q(), scaled by sensitivity [f] (==quaternion ANGULAR equivalent to slerp() )
vec4 qq2qLerp(vec4 a, vec4 b, float f) 
{
    float d = dot(a, b), t = acos(abs(d)), o = (1. / sin(t));
    return normalize(a * sin(t * (1.0 - f)) * o * sign(d) + b * sin(t * f) * o);
}

//doing qq2q() multiple times, you need to normalize() the quaternion, to fix rounding errors.
//how often you do this is up to you.

//normalize q (assuming length(q) is already close to 1, we can skip whe sqrt()
vec4 qn(vec4 q) 
{
    return q / dot(q,q);
}

//return quaternion, that is the shortest rotation, between looking to [a before], and looking to [b after] the rotation.
//http://wiki.secondlife.com/wiki/LlRotBetween
vec4 qBetween(vec3 a, vec3 b) 
{
    float v = sqrt(dot(a,a) * dot(a,a));

    if(v == 0.) return qid();
    
    v = dot(a, b) / v;
    vec3 c = a.yzx * b.zxy - a.zxy * b.yzx / v;
    float d = dot(c,c);
    
    if(d != 0.) 
    {
        float s = (v > - 0.707107) ? 1. + v : d / (1. + sqrt(1. - d));
        return vec4(c, s) / sqrt(d + s * s);
    }
    
    if(v > 0.) return qid();
    
    float m = length(a.xy);
    
    return (m != 0.) ? vec4(a.y, - a.x, 0, 0) / m : vec4(1, 0, 0, 0);
}

//return inverse of quaternion
vec4 qinv(vec4 q) 
{
    return vec4(- q.xyz, q.w) / dot(q,q);
}

//return VECTOR p, rotated by quaterion q;
vec3 qv2v(vec4 q, vec3 p) 
{
    return qq2q(q, qq2q(vec4(p, .0), qinv(q))).xyz;
}

//qv2v()  with swapped inputs
//return quaterion P (as vector), as if it is rotated by VECTOR p (as if it is a quaternion)
vec3 vq2v(vec3 p, vec4 q) 
{
    return qq2q(qinv(q), qq2q(vec4(p, 0.0), q)).xyz;
}

vec3 vq2v(vec4 a, vec3 b) 
{
    return qv2v(a, b);
}

//in case of namespace confuction
vec3 qv2v(vec3 a, vec4 b) 
{
    return vq2v(a, b);
}

//return mat3 of quaternion (rotation matrix without translation)
//https://www.shadertoy.com/view/WsGfWm
mat3 q2m(vec4 q) 
{
    vec3 a = vec3(-1, 1, 1);
    vec3 u = q.zyz * a, v = q.xyx * a.xxy;
    mat3 m = mat3(0.5) + mat3(0, u.x,u.y,u.z, 0, v.x,v.y,v.z, 0) * q.w + matrixCompMult(outerProduct(q.xyz, q.xyz), 1. - mat3(1));
    q *= q; 
    m -= mat3(q.y + q.z, 0, 0, 0, q.x + q.z, 0, 0, 0, q.x + q.y);
    return m * 2.0;
}

//return quaternion of orthogonal matrix (with determinant==1., or else quaternionm will not be normalized)
vec4 m2q(mat3 m) 
{
#define m2f(a,b) m[a][b]-m[b][a]
    //http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
    float q = 2. * sqrt(abs(1. + m[0][0] + m[1][1] + m[2][2]));
    return vec4(vec3(m2f(2, 1), m2f(0, 1), m2f(1, 0)) / q / 4., q);
#undef m2f
}

float at2e(vec2 a) 
{
    a *= 2.;
    return atan(a.x, 1. - a.y);
}

//return quaternion of Euler[yaw,pitch,roll]     
vec4 eYPR2q(vec3 o) 
{
    o *= .5;
    vec3 s = sin(o);
    //https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles#Source_code
    o = cos(o);
    vec4 a = vec4(s.xz, o.xz);
    return a.yyww * a.zxxz * o.y + a.wwyy * a.xzzx * s.y * vec4(-1, 1, -1, 1);
}

vec4 eYPR2q(vec2 o) 
{
    o *= .5;
    vec2 s = sin(o);
    o = cos(o);
    vec4 a = vec4(s.x, 0., o.x, 0.);
    return a.yyww * a.zxxz * o.y + a.wwyy * a.xzzx * s.y * vec4(- 1, 1, - 1, 1);
}

mat3 getCam(vec4 q) 
{
    return q2m(q);
}

//internal RNG state 
uvec4 s0, s1; 
ivec2 pixel;

void rng_initialize(vec2 p, int frame)
{
    pixel = ivec2(p);

    //white noise seed
    s0 = uvec4(p, uint(frame), uint(p.x) + uint(p.y));
    
    //blue noise seed
    s1 = uvec4(frame, frame*15843, frame*31 + 4566, frame*2345 + 58585);
}

// https://www.pcg-random.org/
uvec4 pcg4d(inout uvec4 v)
{
	v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    return v;
}

float rand(){ return float(pcg4d(s0).x)/float(0xffffffffu); }
vec2 rand2(){ return vec2(pcg4d(s0).xy)/float(0xffffffffu); }
vec3 rand3(){ return vec3(pcg4d(s0).xyz)/float(0xffffffffu); }
vec4 rand4(){ return vec4(pcg4d(s0))/float(0xffffffffu); }

vec2 nrand2(float sigma, vec2 mean)
{
	vec2 Z = rand2();
    return mean + sigma * sqrt(-2.0 * log(Z.x)) * 
           vec2(cos(TWO_PI * Z.y),sin(TWO_PI * Z.y));
}

vec3 nrand3(float sigma, vec3 mean)
{
	vec4 Z = rand4();
    return mean + sigma * sqrt(-2.0 * log(Z.xxy)) * 
           vec3(cos(TWO_PI * Z.z),sin(TWO_PI * Z.z),cos(TWO_PI * Z.w));
}

//uniformly spherically distributed
vec3 udir(vec2 rng)
{
    vec2 r = vec2(2.*PI*rng.x, acos(2.*rng.y-1.));
    vec2 c = cos(r), s = sin(r);
    return vec3(c.x*s.y, s.x*s.y, c.y);
}

const float PI2 = 6.2831853071;

const float aperture_size = 0.0;
vec2 aperture()
{
    vec2 r = rand2();
    return vec2(sin(TWO_PI*r.x), cos(TWO_PI*r.x))*sqrt(r.y);
}

float saturate (float x)
{
    return min(1.0, max(0.0,x));
}
vec3 saturate (vec3 x)
{
    return min(vec3(1.,1.,1.), max(vec3(0.,0.,0.),x));
}

vec3 bump3y (vec3 x, vec3 yoffset)
{
	vec3 y = vec3(1.,1.,1.) - x * x;
	y = saturate(y-yoffset);
	return y;
}
vec3 spectral_zucconi(float w)
{
    // w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);

	const vec3 cs = vec3(3.54541723, 2.86670055, 2.29421995);
	const vec3 xs = vec3(0.69548916, 0.49416934, 0.28269708);
	const vec3 ys = vec3(0.02320775, 0.15936245, 0.53520021);

	return bump3y (	cs * (x - xs), ys);
}

vec3 spectral_bruton (float w)
{
	vec3 c;

	if (w >= 380. && w < 440.)
		c = vec3
		(
			-(w - 440.) / (440. - 380.),
			0.0,
			1.0
		);
	else if (w >= 440. && w < 490.)
		c = vec3
		(
			0.0,
			(w - 440.) / (490. - 440.),
			1.0
		);
	else if (w >= 490. && w < 510.)
		c = vec3
		(	0.0,
			1.0,
			-(w - 510.) / (510. - 490.)
		);
	else if (w >= 510. && w < 580.)
		c = vec3
		(
			(w - 510.) / (580. - 510.),
			1.0,
			0.0
		);
	else if (w >= 580. && w < 645.)
		c = vec3
		(
			1.0,
			-(w - 645.) / (645. - 580.),
			0.0
		);
	else if (w >= 645. && w <= 780.)
		c = vec3
		(	1.0,
			0.0,
			0.0
		);
	else
		c = vec3
		(	0.0,
			0.0,
			0.0
		);

	return saturate(c);
}
vec3 spectral_zucconi6 (float w)
{
	// w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);

	const vec3 c1 = vec3(3.54585104, 2.93225262, 2.41593945);
	const vec3 x1 = vec3(0.69549072, 0.49228336, 0.27699880);
	const vec3 y1 = vec3(0.02312639, 0.15225084, 0.52607955);

	const vec3 c2 = vec3(3.90307140, 3.21182957, 3.96587128);
	const vec3 x2 = vec3(0.11748627, 0.86755042, 0.66077860);
	const vec3 y2 = vec3(0.84897130, 0.88445281, 0.73949448);

	return
		bump3y(c1 * (x - x1), y1) +
		bump3y(c2 * (x - x2), y2) ;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float capIntersect( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, in float r )
{
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoa = dot(ba,oa);
    float rdoa = dot(rd,oa);
    float oaoa = dot(oa,oa);

    float a = baba      - bard*bard;
    float b = baba*rdoa - baoa*bard;
    float c = baba*oaoa - baoa*baoa - r*r*baba;
    float h = b*b - a*c;
    if( h>=0.0 )
    {
        float t = (-b-sqrt(h))/a;
        float y = baoa + t*bard;
        // body
        if( y>0.0 && y<baba ) return t;
        // caps
        vec3 oc = (y<=0.0) ? oa : ro - pb;
        b = dot(rd,oc);
        c = dot(oc,oc) - r*r;
        h = b*b - c;
        if( h>0.0 ) return -b - sqrt(h);
    }
    return -1.0;
}


// Spectrum to xyz approx function from Sloan http://jcgt.org/published/0002/02/01/paper.pdf
// Inputs:  Wavelength in nanometers
float xFit_1931( float wave )
{
    float t1 = (wave-442.0)*((wave<442.0)?0.0624:0.0374),
          t2 = (wave-599.8)*((wave<599.8)?0.0264:0.0323),
          t3 = (wave-501.1)*((wave<501.1)?0.0490:0.0382);
    return 0.362*exp(-0.5*t1*t1) + 1.056*exp(-0.5*t2*t2)- 0.065*exp(-0.5*t3*t3);
}
float yFit_1931( float wave )
{
    float t1 = (wave-568.8)*((wave<568.8)?0.0213:0.0247),
          t2 = (wave-530.9)*((wave<530.9)?0.0613:0.0322);
    return 0.821*exp(-0.5*t1*t1) + 0.286*exp(-0.5*t2*t2);
}
float zFit_1931( float wave )
{
    float t1 = (wave-437.0)*((wave<437.0)?0.0845:0.0278),
          t2 = (wave-459.0)*((wave<459.0)?0.0385:0.0725);
    return 1.217*exp(-0.5*t1*t1) + 0.681*exp(-0.5*t2*t2);
}

#define xyzFit_1931(w) vec3( xFit_1931(w), yFit_1931(w), zFit_1931(w) ) 

// http://www.cie.co.at/technical-work/technical-resources
vec3 standardObserver1931[] =
    vec3[] (
    vec3( 0.001368, 0.000039, 0.006450 ), // 380 nm
    vec3( 0.002236, 0.000064, 0.010550 ), // 385 nm
    vec3( 0.004243, 0.000120, 0.020050 ), // 390 nm
    vec3( 0.007650, 0.000217, 0.036210 ), // 395 nm
    vec3( 0.014310, 0.000396, 0.067850 ), // 400 nm
    vec3( 0.023190, 0.000640, 0.110200 ), // 405 nm
    vec3( 0.043510, 0.001210, 0.207400 ), // 410 nm
    vec3( 0.077630, 0.002180, 0.371300 ), // 415 nm
    vec3( 0.134380, 0.004000, 0.645600 ), // 420 nm
    vec3( 0.214770, 0.007300, 1.039050 ), // 425 nm
    vec3( 0.283900, 0.011600, 1.385600 ), // 430 nm
    vec3( 0.328500, 0.016840, 1.622960 ), // 435 nm
    vec3( 0.348280, 0.023000, 1.747060 ), // 440 nm
    vec3( 0.348060, 0.029800, 1.782600 ), // 445 nm
    vec3( 0.336200, 0.038000, 1.772110 ), // 450 nm
    vec3( 0.318700, 0.048000, 1.744100 ), // 455 nm
    vec3( 0.290800, 0.060000, 1.669200 ), // 460 nm
    vec3( 0.251100, 0.073900, 1.528100 ), // 465 nm
    vec3( 0.195360, 0.090980, 1.287640 ), // 470 nm
    vec3( 0.142100, 0.112600, 1.041900 ), // 475 nm
    vec3( 0.095640, 0.139020, 0.812950 ), // 480 nm
    vec3( 0.057950, 0.169300, 0.616200 ), // 485 nm
    vec3( 0.032010, 0.208020, 0.465180 ), // 490 nm
    vec3( 0.014700, 0.258600, 0.353300 ), // 495 nm
    vec3( 0.004900, 0.323000, 0.272000 ), // 500 nm
    vec3( 0.002400, 0.407300, 0.212300 ), // 505 nm
    vec3( 0.009300, 0.503000, 0.158200 ), // 510 nm
    vec3( 0.029100, 0.608200, 0.111700 ), // 515 nm
    vec3( 0.063270, 0.710000, 0.078250 ), // 520 nm
    vec3( 0.109600, 0.793200, 0.057250 ), // 525 nm
    vec3( 0.165500, 0.862000, 0.042160 ), // 530 nm
    vec3( 0.225750, 0.914850, 0.029840 ), // 535 nm
    vec3( 0.290400, 0.954000, 0.020300 ), // 540 nm
    vec3( 0.359700, 0.980300, 0.013400 ), // 545 nm
    vec3( 0.433450, 0.994950, 0.008750 ), // 550 nm
    vec3( 0.512050, 1.000000, 0.005750 ), // 555 nm
    vec3( 0.594500, 0.995000, 0.003900 ), // 560 nm
    vec3( 0.678400, 0.978600, 0.002750 ), // 565 nm
    vec3( 0.762100, 0.952000, 0.002100 ), // 570 nm
    vec3( 0.842500, 0.915400, 0.001800 ), // 575 nm
    vec3( 0.916300, 0.870000, 0.001650 ), // 580 nm
    vec3( 0.978600, 0.816300, 0.001400 ), // 585 nm
    vec3( 1.026300, 0.757000, 0.001100 ), // 590 nm
    vec3( 1.056700, 0.694900, 0.001000 ), // 595 nm
    vec3( 1.062200, 0.631000, 0.000800 ), // 600 nm
    vec3( 1.045600, 0.566800, 0.000600 ), // 605 nm
    vec3( 1.002600, 0.503000, 0.000340 ), // 610 nm
    vec3( 0.938400, 0.441200, 0.000240 ), // 615 nm
    vec3( 0.854450, 0.381000, 0.000190 ), // 620 nm
    vec3( 0.751400, 0.321000, 0.000100 ), // 625 nm
    vec3( 0.642400, 0.265000, 0.000050 ), // 630 nm
    vec3( 0.541900, 0.217000, 0.000030 ), // 635 nm
    vec3( 0.447900, 0.175000, 0.000020 ), // 640 nm
    vec3( 0.360800, 0.138200, 0.000010 ), // 645 nm
    vec3( 0.283500, 0.107000, 0.000000 ), // 650 nm
    vec3( 0.218700, 0.081600, 0.000000 ), // 655 nm
    vec3( 0.164900, 0.061000, 0.000000 ), // 660 nm
    vec3( 0.121200, 0.044580, 0.000000 ), // 665 nm
    vec3( 0.087400, 0.032000, 0.000000 ), // 670 nm
    vec3( 0.063600, 0.023200, 0.000000 ), // 675 nm
    vec3( 0.046770, 0.017000, 0.000000 ), // 680 nm
    vec3( 0.032900, 0.011920, 0.000000 ), // 685 nm
    vec3( 0.022700, 0.008210, 0.000000 ), // 690 nm
    vec3( 0.015840, 0.005723, 0.000000 ), // 695 nm
    vec3( 0.011359, 0.004102, 0.000000 ), // 700 nm
    vec3( 0.008111, 0.002929, 0.000000 ), // 705 nm
    vec3( 0.005790, 0.002091, 0.000000 ), // 710 nm
    vec3( 0.004109, 0.001484, 0.000000 ), // 715 nm
    vec3( 0.002899, 0.001047, 0.000000 ), // 720 nm
    vec3( 0.002049, 0.000740, 0.000000 ), // 725 nm
    vec3( 0.001440, 0.000520, 0.000000 ), // 730 nm
    vec3( 0.001000, 0.000361, 0.000000 ), // 735 nm
    vec3( 0.000690, 0.000249, 0.000000 ), // 740 nm
    vec3( 0.000476, 0.000172, 0.000000 ), // 745 nm
    vec3( 0.000332, 0.000120, 0.000000 ), // 750 nm
    vec3( 0.000235, 0.000085, 0.000000 ), // 755 nm
    vec3( 0.000166, 0.000060, 0.000000 ), // 760 nm
    vec3( 0.000117, 0.000042, 0.000000 ), // 765 nm
    vec3( 0.000083, 0.000030, 0.000000 ), // 770 nm
    vec3( 0.000059, 0.000021, 0.000000 ), // 775 nm
    vec3( 0.000042, 0.000015, 0.000000 )  // 780 nm
);
float standardObserver1931_w_min = 380.0f;
float standardObserver1931_w_max = 780.0f;
int standardObserver1931_length = 81;

vec3 WavelengthToXYZLinear( float fWavelength )
{
    float fPos = ( fWavelength - standardObserver1931_w_min ) / (standardObserver1931_w_max - standardObserver1931_w_min);
    float fIndex = fPos * float(standardObserver1931_length);
    float fFloorIndex = floor(fIndex);
    float fBlend = clamp( fIndex - fFloorIndex, 0.0, 1.0 );
    int iIndex0 = int(fFloorIndex);
    int iIndex1 = iIndex0 + 1;
    iIndex1 = min( iIndex1, standardObserver1931_length - 1);

    return mix( standardObserver1931[iIndex0], standardObserver1931[iIndex1], fBlend );
}

vec3 XYZtosRGB( vec3 XYZ )
{
    // XYZ to sRGB
    // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
   mat3 m = mat3 (
        3.2404542, -1.5371385, -0.4985314,
		-0.9692660,  1.8760108,  0.0415560,
 		0.0556434, -0.2040259,  1.0572252 );
    
    return XYZ * m;
}

vec3 sRGBtoXYZ( vec3 RGB )
{
   // sRGB to XYZ
   // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html

   mat3 m = mat3(  	0.4124564,  0.3575761, 0.1804375,
 					0.2126729,  0.7151522, 0.0721750,
 					0.0193339,  0.1191920, 0.9503041 );
    
    
    return RGB * m;
}

vec3 WavelengthToXYZ( float f )
{    
    //return xyzFit_1931( f ) * mXYZtoSRGB;
    
    return WavelengthToXYZLinear( f );
}


struct Chromaticities
{
    vec2 R, G, B, W;
};
    
vec3 CIE_xy_to_xyz( vec2 xy )
{
    return vec3( xy, 1.0f - xy.x - xy.y );
}

vec3 CIE_xyY_to_XYZ( vec3 CIE_xyY )
{
    float x = CIE_xyY[0];
    float y = CIE_xyY[1];
    float Y = CIE_xyY[2];
    
    float X = (Y / y) * x;
    float Z = (Y / y) * (1.0 - x - y);
        
	return vec3( X, Y, Z );        
}

vec3 CIE_XYZ_to_xyY( vec3 CIE_XYZ )
{
    float X = CIE_XYZ[0];
    float Y = CIE_XYZ[1];
    float Z = CIE_XYZ[2];
    
    float N = X + Y + Z;
    
    float x = X / N;
    float y = Y / N;
    float z = Z / N;
    
    return vec3(x,y,Y);
}

Chromaticities Primaries_Rec709 =
Chromaticities(
        vec2( 0.6400, 0.3300 ),	// R
        vec2( 0.3000, 0.6000 ),	// G
        vec2( 0.1500, 0.0600 ), 	// B
        vec2( 0.3127, 0.3290 ) );	// W

Chromaticities Primaries_Rec2020 =
Chromaticities(
        vec2( 0.708,  0.292 ),	// R
        vec2( 0.170,  0.797 ),	// G
        vec2( 0.131,  0.046 ),  	// B
        vec2( 0.3127, 0.3290 ) );	// W

Chromaticities Primaries_DCI_P3_D65 =
Chromaticities(
        vec2( 0.680,  0.320 ),	// R
        vec2( 0.265,  0.690 ),	// G
        vec2( 0.150,  0.060 ),  	// B
        vec2( 0.3127, 0.3290 ) );	// W

mat3 RGBtoXYZ( Chromaticities chroma )
{
    // xyz is a projection of XYZ co-ordinates onto to the plane x+y+z = 1
    // so we can reconstruct 'z' from x and y
    
    vec3 R = CIE_xy_to_xyz( chroma.R );
    vec3 G = CIE_xy_to_xyz( chroma.G );
    vec3 B = CIE_xy_to_xyz( chroma.B );
    vec3 W = CIE_xy_to_xyz( chroma.W );
    
    // We want vectors in the directions R, G and B to form the basis of
    // our matrix...
    
	mat3 mPrimaries = mat3 ( R, G, B );
    
    // but we want to scale R,G and B so they result in the
    // direction W when the matrix is multiplied by (1,1,1)
    
    vec3 W_XYZ = W / W.y;
	vec3 vScale = inverse( mPrimaries ) * W_XYZ;
    
    return transpose( mat3( R * vScale.x, G * vScale.y, B * vScale.z ) );
}

mat3 XYZtoRGB( Chromaticities chroma )
{
    return inverse( RGBtoXYZ(chroma) );
}

// chromatic adaptation

// http://www.brucelindbloom.com/index.html?Eqn_ChromAdapt.html    

// Test viewing condition CIE XYZ tristimulus values of whitepoint.
vec3 XYZ_w = vec3( 1.09850,	1.00000,	0.35585); // Illuminant A
// Reference viewing condition CIE XYZ tristimulus values of whitepoint.
vec3 XYZ_wr = vec3(0.95047,	1.00000,	1.08883); // D65


const mat3 CA_A_to_D65_VonKries = mat3(
    0.9394987, -0.2339150,  0.4281177,
	-0.0256939,  1.0263828,  0.0051761,
 	0.0000000,  0.0000000,  3.0598005
    );


const mat3 CA_A_to_D65_Bradford = mat3(
    0.8446965, -0.1179225,  0.3948108,
	-0.1366303,  1.1041226,  0.1291718,
 	0.0798489, -0.1348999,  3.1924009
    );


const mat3 mCAT_VonKries = mat3 ( 
    0.4002400,  0.7076000, -0.0808100,
	-0.2263000,  1.1653200,  0.0457000,
 	0.0000000,  0.0000000,  0.9182200 );

const mat3 mCAT_02 = mat3( 	0.7328, 0.4296, -0.1624,
							-0.7036, 1.6975, 0.0061,
 							0.0030, 0.0136, 0.9834 );

const mat3 mCAT_Bradford = mat3 (  0.8951000, 0.2664000, -0.1614000,
								-0.7502000,  1.7135000,  0.0367000,
 								0.0389000, -0.0685000,  1.0296000 );


mat3 GetChromaticAdaptionMatrix()
{
    //return inverse(CA_A_to_D65_VonKries);    
    //return inverse(CA_A_to_D65_Bradford);
        
    //return mat3(1,0,0, 0,1,0, 0,0,1); // do nothing
    
	//mat3 M = mCAT_02;
    //mat3 M = mCAT_Bradford;
    mat3 M = mCAT_VonKries;
    //mat3 M = mat3(1,0,0,0,1,0,0,0,1);
    
    vec3 w = XYZ_w * M;
    vec3 wr = XYZ_wr * M;
    vec3 s = w / wr;
    
    mat3 d = mat3( 
        s.x,	0,		0,  
        0,		s.y,	0,
        0,		0,		s.z );
        
    mat3 cat = M * d * inverse(M);
    return cat;
}

float BlackBody( float t, float w_nm )
{
    float h = 6.6e-34; // Planck constant
    float k = 1.4e-23; // Boltzmann constant
    float c = 3e8;// Speed of light

    float w = w_nm / 1e9;

    // Planck's law https://en.wikipedia.org/wiki/Planck%27s_law
    
    float w5 = w*w*w*w*w;    
    float o = 2.*h*(c*c) / (w5 * (exp(h*c/(w*k*t)) - 1.0));

    return o;    
}