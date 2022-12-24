// Math.
# define PI 3.1415926538

// Input.
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
const int KEY_SHIFT = 16;
const int KEY_CTRL  = 17;
const int KEY_SPACE  = 32;
const int KEY_W  = 87;
const int KEY_A = 65;
const int KEY_S  = 83;
const int KEY_D  = 68;
const int KEY_C  = 67;
const int KEY_V  = 86;
const int KEY_Q  = 81;
const int KEY_E  = 69;
const int KEY_R  = 82;
const int KEY_1  = 49;
const int KEY_2  = 50;
const int KEY_3  = 51;

# define MAP_WIDTH 30.
const int CAMERA_POS = 0;
const int CAMERA_SENSITIVITY = 1;
const int CAMERA_DIRECTION = 2;
const int CHANGE_SEED = 3;
const int SCREEN_RESOLUTION = 4;
const int DO_BUFFER_UPDATE = 5;
# define PRECISION_NUMBER 16777216
# define PRECISION_NUMBER_F 16777216.
const int PRECISION_TEST = 6;
const int MOVEMENT_MODE = 7;
# define MOVE_MODE_AUTO 0.
# define MOVE_MODE_WALK 1.
# define MOVE_MODE_FREE 2.
const int VELOCITY = 8;
//2^24 = 16777216
    
// Auto parameters.
# define AUTO_MOVEMENT_SPEED 0.04
# define START_TIME 40.

// --Hash function--
/*
Inspired by Adam Smith.
source: https://groups.google.com/forum/#!msg/proceduralcontent/AuvxuA1xqmE/T8t88r2rfUcJ
*/
# define PRECISION 3
// 2^32-1
# define LARGEST_UINT 4294967295u
# define LARGEST_UINT_AS_FLOAT 4294967295.
// 2^31-1 = 2147483647
# define LARGEST_INT 2147483647
# define LARGEST_INT_AS_FLOAT 2147483647.
# define SMALLEST_INT -2147483648
# define SMALLEST_INT_AS_FLOAT -2147483648.
// 2^32 = 4294967296
# define LARGEST_SMALLEST_INT_DIFFERENCE_AS_FLOAT 4294967296.

int rotate (int x, int b) {
    return (x << b) ^ (x >> (32-b));
}

int pcg (int a) {
    int b = a;
    for (int i = 0; i < PRECISION; i++) {
        a = rotate((a^0xcafebabe) + (b^0xfaceb00c), 23);
        b = rotate((a^0xdeadbeef) + (b^0x8badf00d), 5);
    }
    return a^b;
}

float pcgUnit (int a) {
    return (float(pcg(a))-SMALLEST_INT_AS_FLOAT) / LARGEST_SMALLEST_INT_DIFFERENCE_AS_FLOAT;
}

int pcg (int a, int b) {
    for (int i = 0; i < PRECISION; i++) {
        a = rotate((a^0xcafebabe) + (b^0xfaceb00c), 23);
        b = rotate((a^0xdeadbeef) + (b^0x8badf00d), 5);
    }
    return a^b;
}

float pcgUnit (int a, int b) {
    return (float(pcg(a,b))-SMALLEST_INT_AS_FLOAT) / LARGEST_SMALLEST_INT_DIFFERENCE_AS_FLOAT;
}

int pcg (int a, int b, int c) {
    for (int i = 0; i < PRECISION; i++) {
        a = rotate((a^0xcafebabe) + (b^0xfaceb00c) + (c^0xcabba6e5), 23);
        b = rotate((a^0xdeadbeef) + (b^0x8badf00d) + (c^0x0b5e55ed), 5);
        c = rotate((a^0x5eaf00d5) + (b^0xdecea5ed) + (c^0xba5eba11), 16);
    }
    // https://www.dcode.fr/words-containing
    return a^b^c;
}

float pcgUnit (int a, int b, int c) {
    return (float(pcg(a,b,c))-SMALLEST_INT_AS_FLOAT) / LARGEST_SMALLEST_INT_DIFFERENCE_AS_FLOAT;
}

// --Noise functions--
float boxNoise(vec3 pos, int seed){
	ivec3 ind = ivec3(floor(pos));
    
    vec3 f = fract(pos);
    
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    //return mix(mix(mix( pcgUnit(ind.x+0, ind.y+0, ind.z+0), pcgUnit(ind.x+1, ind.y+0, ind.z+0), u.x),
    //               mix( pcgUnit(ind.x+0, ind.y+1, ind.z+0), pcgUnit(ind.x+1, ind.y+1, ind.z+0), u.x), u.y),
    //           mix(mix( pcgUnit(ind.x+0, ind.y+0, ind.z+1), pcgUnit(ind.x+1, ind.y+0, ind.z+1), u.x),
    //               mix( pcgUnit(ind.x+0, ind.y+1, ind.z+1), pcgUnit(ind.x+1, ind.y+1, ind.z+1), u.x), u.y), u.z);
    
    // Optimized version.
    // 15485863 and 179424673 are primes.
    ivec2 yS = ivec2(ind.y*15485863, (ind.y+1)*15485863);
    ivec2 zS = ivec2(ind.z*179424673, (ind.z+1)*179424673);
    return mix(mix(mix( pcgUnit(ind.x + yS.x + zS.x, seed), pcgUnit(ind.x+1 + yS.x + zS.x, seed), u.x),
                   mix( pcgUnit(ind.x + yS.y + zS.x, seed), pcgUnit(ind.x+1 + yS.y + zS.x, seed), u.x), u.y),
               mix(mix( pcgUnit(ind.x + yS.x + zS.y, seed), pcgUnit(ind.x+1 + yS.x + zS.y, seed), u.x),
                   mix( pcgUnit(ind.x + yS.y + zS.y, seed), pcgUnit(ind.x+1 + yS.y + zS.y, seed), u.x), u.y), u.z);
}
float boxNoise(vec3 pos){
    return boxNoise(pos, 0);
}

float layeredBoxNoise(vec3 pos, int numLayers, int seed){
    seed = pcg(seed);
	float result = 0.;
    float scale = 1.;
    float denominator = 0.;
    for (int i = 0; i < numLayers; i++) {
        result += scale * boxNoise(pos, ++seed);
        denominator += scale;
        pos *= 2.;
        pos += PI*0.;
        scale *= 0.5;
    }
    return result/denominator;
}

float perlinNoise(vec3 pos, int seed, int tileSize){
    ivec3 ind = ivec3(floor(pos));
    
    vec3 f = fract(pos);
    
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    f = f;
    
    // 2038074743 and 179424673 are primes.
    //ivec2 yS = ivec2(ind.y*15485863, (ind.y+1)*15485863);
    //ivec2 zS = ivec2(ind.z*179424673, (ind.z+1)*179424673);
    // 7907 and 7919 are primes.
    ivec3 modInd = ivec3(mod(vec3(ind), float(tileSize)));
    ivec3 modIndP = ivec3(mod(vec3(ind+1), float(tileSize)));
    modInd.y *= 7907;
    modIndP.y *= 7907;
    modInd.z *= 7919;
    modIndP.z *= 7919;
    
    float nf = 2./float(0x3ff);
    
    int x0y0z0H = pcg(modInd.x + modInd.y + modInd.z, seed);
    float x0y0z0 = dot(
        vec3(
            (float(0x000003ff & x0y0z0H)*nf-1.),
            (float((0x000ffc00 & x0y0z0H) >> 10)*nf-1.),
            (float((0x3ff00000 & x0y0z0H) >> 20)*nf-1.)
        ),
        f
    );
    
    int x1y0z0H = pcg(modIndP.x + modInd.y + modInd.z, seed);
    float x1y0z0 = dot(
        vec3(
            (float(0x000003ff & x1y0z0H)*nf-1.),
            (float((0x000ffc00 & x1y0z0H) >> 10)*nf-1.),
            (float((0x3ff00000 & x1y0z0H) >> 20)*nf-1.)
        ),
        vec3(f.x-1., f.y, f.z)
    );
    
    int x0y1z0H = pcg(modInd.x + modIndP.y + modInd.z, seed);
    float x0y1z0 = dot(
        vec3(
            (float(0x000003ff & x0y1z0H)*nf-1.),
            (float((0x000ffc00 & x0y1z0H) >> 10)*nf-1.),
            (float((0x3ff00000 & x0y1z0H) >> 20)*nf-1.)
        ),
        vec3(f.x, f.y-1., f.z)
    );
    
    int x1y1z0H = pcg(modIndP.x + modIndP.y + modInd.z, seed);
    float x1y1z0 = dot(
        vec3(
            (float(0x000003ff & x1y1z0H)*nf-1.),
            (float((0x000ffc00 & x1y1z0H) >> 10)*nf-1.),
            (float((0x3ff00000 & x1y1z0H) >> 20)*nf-1.)
        ),
        vec3(f.x-1., f.y-1., f.z)
    );
    
    int x0y0z1H = pcg(modInd.x + modInd.y + modIndP.z, seed);
    float x0y0z1 = dot(
        vec3(
            (float(0x000003ff & x0y0z1H)*nf-1.),
            (float((0x000ffc00 & x0y0z1H) >> 10)*nf-1.),
            (float((0x3ff00000 & x0y0z1H) >> 20)*nf-1.)
        ),
        vec3(f.x, f.y, f.z-1.)
    );
    
    int x1y0z1H = pcg(modIndP.x + modInd.y + modIndP.z, seed);
    float x1y0z1 = dot(
        vec3(
            (float(0x000003ff & x1y0z1H)*nf-1.),
            (float((0x000ffc00 & x1y0z1H) >> 10)*nf-1.),
            (float((0x3ff00000 & x1y0z1H) >> 20)*nf-1.)
        ),
        vec3(f.x-1., f.y, f.z-1.)
    );
    
    int x0y1z1H = pcg(modInd.x + modIndP.y + modIndP.z, seed);
    float x0y1z1 = dot(
        vec3(
            (float(0x000003ff & x0y1z1H)*nf-1.),
            (float((0x000ffc00 & x0y1z1H) >> 10)*nf-1.),
            (float((0x3ff00000 & x0y1z1H) >> 20)*nf-1.)
        ),
        vec3(f.x, f.y-1., f.z-1.)
    );
    
    int x1y1z1H = pcg(modIndP.x + modIndP.y + modIndP.z, seed);
    float x1y1z1 = dot(
        vec3(
            (float(0x000003ff & x1y1z1H)*nf-1.),
            (float((0x000ffc00 & x1y1z1H) >> 10)*nf-1.),
            (float((0x3ff00000 & x1y1z1H) >> 20)*nf-1.)
        ),
        vec3(f.x-1., f.y-1., f.z-1.)
    );
    
    return mix(mix(mix( x0y0z0, x1y0z0, u.x),
                   mix( x0y1z0, x1y1z0, u.x), u.y),
               mix(mix( x0y0z1, x1y0z1, u.x),
                   mix( x0y1z1, x1y1z1, u.x), u.y), u.z);
}

float layeredPerlinNoise(vec3 pos, int numLayers, int seed, int tileSize){
    seed = pcg(seed);
	float result = 0.;
    float scale = 1.;
    float denominator = 0.;
    for (int i = 0; i < numLayers; i++) {
        result += scale * perlinNoise(pos, ++seed, tileSize);
        tileSize *= 2;
        denominator += scale;
        pos *= 2.;
        pos += PI*0.;
        scale *= 0.5;
    }
    return result/denominator;
}

// --Signed distance functions. (SDF)--
float sdSphere(in vec3 pos, in vec3 center, in float radius){
   	return length(pos-center) - radius;
}
void sdSphereNormal(in vec3 pos, in vec3 center, in float radius, inout vec3 normal, inout float sd){
	sd = sdSphere(pos, center, radius);
    vec2 e = vec2(0.01, 0.);
    normal = normalize(sd - vec3(
    	sdSphere(pos - e.xyy, center, radius),
    	sdSphere(pos - e.yxy, center, radius),
    	sdSphere(pos - e.yyx, center, radius)
    ));
}

# define MOUNTAIN_FUNCTIONS \
bool DisCallingNormal = false;\
/* Mountain.*/\
float getMountainHeight(vec2 pos){\
    vec2 uv = pos/MAP_WIDTH;\
	uv.x *= iResolution.y/iResolution.x;\
    /* Tile texture.*/\
    vec2 coordinate = uv.xy*iResolution.xy;\
    const float roundingMargin = 0.00001;\
    coordinate.y = mod(coordinate.y, iResolution.y-roundingMargin);\
    coordinate.x = mod(coordinate.x, iResolution.y-roundingMargin);\
    vec4 samp = texelFetch(iChannel1, ivec2(coordinate), 0);\
    vec2 frac = fract(coordinate);\
    float h = mix(\
    	mix(samp.x, samp.y, frac.x),\
    	mix(samp.z, samp.w, frac.x),\
        frac.y\
    );\
    \
    return h;\
}\
float sdMountain(in vec3 pos, float resolution, bool differentiable){\
    vec2 flatPos = pos.xz;\
    \
    /* Share.*/\
    vec2 share = vec2(\
        cos(flatPos.x),\
        cos(flatPos.y)\
    );\
    vec2 sharedPos = flatPos + pos.y*share*1.2;\
    \
    /**/\
    float height = 0.;\
    float scale = 1.;\
    float heightDiff;\
    int numIte = int(ceil(resolution));\
    /* Rotation.*/\
    const float rotSin = sin(2.*PI*(1./16.));\
    const float rotCos = cos(2.*PI*(1./16.));\
    const mat2 rotMat = mat2(rotCos, -rotSin, rotSin, rotCos);\
    /**/\
    for(int i=0;i<numIte;i++){\
        /* Rotate.*/\
        sharedPos = rotMat*sharedPos;\
        flatPos = rotMat*flatPos;\
        /**/\
        sharedPos = mix(sharedPos, flatPos, 0.5);\
        float factor = min(resolution - float(i), 1.);\
        float h = getMountainHeight(sharedPos * scale);\
        h = h/scale * factor;\
    	height += h;\
        scale *= 16.;\
        heightDiff = pos.y - height;\
        if(!differentiable && heightDiff > 4./scale && i < numIte-1){\
        	heightDiff = heightDiff - 2./scale;\
            break;\
        }\
    }\
    \
    heightDiff = pos.y - height;\
    \
    const float maxSlope = 3.;\
    float nextDist = heightDiff/sqrt(maxSlope*maxSlope + 1.);\
    \
    return nextDist;\
}\
void sdMountainNormal(in vec3 pos, out vec3 normal, out float sd, in float resolution, in float df){\
    DisCallingNormal = true;\
	sd = sdMountain(pos, resolution, /*differentiable=*/true);\
    /*float df = 0.002;*/\
    vec2 e = vec2(df, 0.);\
    normal = normalize(sd - vec3(\
    	sdMountain(pos - e.xyy, resolution, /*differentiable=*/true),\
    	sdMountain(pos - e.yxy, resolution, /*differentiable=*/true),\
    	sdMountain(pos - e.yyx, resolution, /*differentiable=*/true)\
    ));\
    DisCallingNormal = false;\
}
