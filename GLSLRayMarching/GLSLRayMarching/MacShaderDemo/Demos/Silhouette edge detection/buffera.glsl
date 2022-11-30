#define ROTATION_SPEED 0.12
#define ANIMATION_SPEED 0.5
#define LIGHT_DIR vec3(0.3, 1.0, -1.0)
#define PI_3 1.0471975512
#define PI_4 0.78539816339
#define TWO_PI 6.28318530718
#define TOWER_SIZE 0.26
#define PLATFORM_SIZE 0.26
#define STAIRS_SIZE 0.12
#define PLATFORM_THICKNESS 0.1
#define FLOOR_HEIGHT 0.5

// Utils
// ------------------
vec2 mirrorXZ(vec2 p)
{
    return abs(p);
}

vec2 rotate2D(vec2 p, float a) {
  return p * mat2(cos(a), -sin(a), sin(a),  cos(a));
}

// Rotates on the XZ plane by a multiple of PI/2.
vec2 rotate2D_PI2(vec2 p, int i) 
{
  return vec2(((i>0&&i<3)?-1.0:1.0)*((i%2==0)?p.x:p.y), ((i>1)?-1.0:1.0)*((i%2==0)?p.y:p.x));
}

vec3 rotate3D_PI2(vec3 p, int i)
{
    vec2 xz=rotate2D_PI2(p.xz, i);
    return vec3(xz.x, p.y, xz.y);
}

// Function that transforms the animation parameter [0, 1]
// to give a bit of anticipation and "overshoot" feel to the motion.
float overshoot(float t)
{
    return smoothstep(0.0, 1.0, t) - sin(t*TWO_PI)*0.15;
}

float overshootInterp(float a, float b, float s)
{
    float t=overshoot(s);
    return (1.0-t)*a + t*b;
}

vec3 overshootInterp(vec3 a, vec3 b, float s)
{
    float t=overshoot(s);
    return (1.0-t)*a + t*b;
}

// ------------------

// SDFs
// ------------------
float sdBox( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
// ------------------

float drawTower(vec3 p, float h1, float h2, float t, float minDist)
{
    float h = mix(h1, h2, t);
    float thickness = PLATFORM_THICKNESS;
    float towH = (h*0.5)+thickness;
    
    vec3 pTower = p-vec3(0.0, h*0.5-thickness, 0.0);
    minDist = sdBox(pTower, vec3(TOWER_SIZE, towH, TOWER_SIZE));
    
    vec3 pRoof =  p     - vec3(0.0, h+TOWER_SIZE, 0.0);
    vec3 pRoof2 = pRoof - vec3(0., TOWER_SIZE*1.2, 0.);
    vec3 pRoof3 = pRoof - vec3(0., TOWER_SIZE*1.2, 0.);
    vec3 pRoof4 = p     - vec3(0., h +.6*TOWER_SIZE, 0.);
    
    
    if(minDist<sdBox(pRoof - vec3(0., .2, 0.)*TOWER_SIZE, vec3(1., 1.2, 1.)*TOWER_SIZE))
        return minDist;
    
    minDist = min(minDist, sdBox(pRoof, vec3(1.)*TOWER_SIZE));
    
    // Doors
    // -----
    pRoof4.xz = rotate2D(pRoof4.xz, PI_4);
    pRoof4.xz = mirrorXZ(pRoof4.xz);
    pRoof4.xz = rotate2D(pRoof4.xz, -PI_4);
    minDist = max(minDist, -sdBox(pRoof4-vec3(.9*TOWER_SIZE, 0., 0.), vec3(.2*TOWER_SIZE, .6*TOWER_SIZE, STAIRS_SIZE)));
    minDist = max(minDist, -sdCappedCylinder((pRoof4-vec3(.9*TOWER_SIZE, .6*TOWER_SIZE, 0.)).zxy, STAIRS_SIZE, .2*TOWER_SIZE));
    
    // Battlements
    // -----------
    float k = .2*TOWER_SIZE;
    pRoof2.xz = min(pRoof.xz+4.*k, max( pRoof.xz-4.*k,mod(pRoof.xz+0.5*4.*k,4.*k)-0.5*4.*k));
    minDist = min(minDist,  sdBox(pRoof2, vec3(k)));
    minDist = max(minDist, -sdBox(pRoof3, vec3(.8, .5,.8)*TOWER_SIZE));

    return minDist;   
}

float drawPlatform(vec3 p, float h1, float h2, float t)
{
    float h = mix(h1, h2, t);
    float thickness = PLATFORM_THICKNESS;
    return sdBox(p-vec3(0.0, h-thickness, 0.0), vec3(PLATFORM_SIZE, thickness, PLATFORM_SIZE));
}

float drawStairs(vec3 p, float hFrom1,float hTo1, float hFrom2, float hTo2, float t, float minDist)
{
    float stairs = 5.0;
    float k = 2.0;
    float o = 1.0/(float(stairs)*k);
    float thickness = PLATFORM_THICKNESS*0.6;
    float minX = TOWER_SIZE+0.05;
    float maxX = 1.0 - PLATFORM_SIZE-0.05;
    float deltaX = (maxX-minX)/(stairs-1.0);
    
    float minH1 = min(hFrom1, hTo1);
    float maxH1 = max(hFrom1, hTo1);
    float minH2 = min(hFrom2, hTo2);
    float maxH2 = max(hFrom2, hTo2);
    
    float minH = mix(minH1, min(minH1, minH2), float(t>0.0))-2.0*thickness;
    float maxH = mix(maxH1, max(maxH1, maxH2), float(t>0.0));
    
    
    // Bbox test
    // ---------
    vec3 boxCenter = vec3(0.5*(minX+maxX),0.5*(minH+maxH), 0.0);
    vec3 boxSize   = vec3(0.5*(maxX-minX) + STAIRS_SIZE,0.5*(maxH-minH)*1.0 /*account for animation*/,STAIRS_SIZE);
    
    if(sdBox(p-boxCenter,boxSize)>minDist)
       return minDist;
   
    // Debug bounding box for culling
    // minDist = min(minDist, sdBox(p-boxCenter,boxSize));
    // return minDist;
    // ------------------------------
  
    for(float s=0.0; s<stairs; s++)
    {
        // Each stair has its animation offset.
        float tOff = min(max(0.0, (t-o*s)*k), 1.0);
        
        // The animation parameter is transformed to avoid 
        // perfectly linear motion.
        float hFrom = overshootInterp(hFrom1, hFrom2, tOff);
        float hTo   = overshootInterp(hTo1  , hTo2  , tOff);
        float h = ((hFrom) + s*(hTo-hFrom)/(stairs -1.0)) - thickness;
        
        minDist = min(sdBox(p-vec3(minX + deltaX*s, h, 0.0), vec3(deltaX*0.55, thickness, STAIRS_SIZE)), minDist);
    }
    
    return minDist;
}


float drawStairs(vec3 p, mat3 config, mat3 nextConfig,int fromCol, int fromRow, int toCol, int toRow, float t, float minDist)
{
    float hFrom1 =     config[fromCol][fromRow];
    float hTo1   =     config[toCol][toRow];
    float hFrom2 = nextConfig[fromCol][fromRow];
    float hTo2   = nextConfig[toCol][toRow];
    
    int dC = toCol-fromCol;
    int dR = toRow-fromRow;

    p.xz-=vec2(fromCol-1, fromRow-1);
    p=rotate3D_PI2(p, (((abs(dC)>abs(dR))?1:4)-(dC+dR))%4);
        
    return drawStairs(p, hFrom1, hTo1, hFrom2, hTo2, t, minDist);
}


float drawScene(vec3 p, mat3 config, mat3 nextConfig, float t)
{
    // ----------------------------------------------------------------------------------------------------------
    // The scene is layed out as a 3x3 grid. A "random" height is generated for each tower ([0, 2]*FLOOR_HEIGHT).
    // Each platform is placed at an appropriate height  to allow the towers to be connected.
    // Stairs are drawn to connect the towers through  the platforms.
    // ----------------------------------------------------------------------------------------------------------
    //
    //   XX         ||         XX
    // X 00 X --- | 10 | --- X 20 X
    //   XX         ||         XX
    //   !          !          !
    //   !  IV quad ! III quad !
    //   !          !          !
    //   ||         XX         ||
    // | 01 | --- X 11 X --- | 21 |
    //   ||         XX         ||
    //   !          !          !
    //   !  I quad  !  II quad !
    //   !          !          !
    //   XX         ||         XX
    // X 02 X --- | 12 | --- X 22 X
    //   XX         ||         XX
    //
    //
    //   XX             //   ||                //
    // X nn X -> TOWER  // | nn | -> PLATFORM  // --- -> STAIRS
    //   XX             //   ||                //
    
    float minDist = FAR;
    
    vec3 quadS  = vec3( 0.5 + TOWER_SIZE, FLOOR_HEIGHT + 1.2*TOWER_SIZE + PLATFORM_THICKNESS, .5);
    vec3 quad1C = vec3(-0.5, FLOOR_HEIGHT + 1.2*TOWER_SIZE, 0.5);
    vec3 quad2C = vec3( 0.5, FLOOR_HEIGHT + 1.2*TOWER_SIZE, 0.5);
    vec3 quad3C = vec3( 0.5, FLOOR_HEIGHT + 1.2*TOWER_SIZE,-0.5);
    vec3 quad4C = vec3(-0.5, FLOOR_HEIGHT + 1.2*TOWER_SIZE,-0.5);
    
    float boxDist;
   
    // BBoxes used for culling, one for each quadrant
    // minDist = sdBox((p - quad1C)     -vec3(0.0, 0.0, TOWER_SIZE), quadS);
    // minDist = sdBox((p - quad2C).zyx -vec3(0.0, 0.0, TOWER_SIZE), quadS);
    // minDist = sdBox((p - quad3C)     +vec3(0.0, 0.0, TOWER_SIZE), quadS);
    // minDist = sdBox((p - quad4C).zyx +vec3(0.0, 0.0, TOWER_SIZE), quadS);
   
   
    // Quadrant I
    // ----------
    if((boxDist = sdBox((p - quad1C)-vec3(0.0, 0.0, TOWER_SIZE), quadS))<=minDist)
    {
        minDist = min(drawPlatform(p-vec3( 0.0, 0.0, 1.0), config[1][2], nextConfig[1][2], t), minDist);
        minDist = min(drawTower(p-vec3(-1.0, 0.0, 1.0), config[0][2], nextConfig[0][2], t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 1,2,  0,2, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 0,1,  0,2, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 1,2,  1,1, t, minDist), minDist);
        
    } 
    
    // Quadrant II
    // -----------
    if((boxDist = sdBox((p - quad2C).zyx-vec3(0.0, 0.0, TOWER_SIZE), quadS))<=minDist)
    {
        minDist = min(drawPlatform(p-vec3( 1.0, 0.0, 0.0), config[2][1], nextConfig[2][1], t), minDist);
        minDist = min(drawTower(p-vec3(1.0, 0.0, 1.0), config[2][2], nextConfig[2][2], t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 1,2,  2,2, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 2,1,  2,2, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 2,1,  1,1, t, minDist), minDist);
    }
    
    // Quadrant III
    // ------------
    if((boxDist = sdBox((p - quad3C)+vec3(0.0, 0.0, TOWER_SIZE), quadS))<=minDist)
    {
        minDist = min(drawPlatform(p-vec3( 0.0, 0.0,-1.0), config[1][0], nextConfig[1][0], t), minDist);
        minDist = min(drawTower(p-vec3(1.0, 0.0, -1.0), config[2][0], nextConfig[2][0], t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 1,0,  2,0, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 2,1,  2,0, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 1,0,  1,1, t, minDist), minDist);
        
    }
    
    // Quadrant IV
    // -----------
    if((boxDist = sdBox((p - quad4C).zyx +vec3(0.0, 0.0, TOWER_SIZE), quadS))<=minDist)
    {
        minDist = min(drawPlatform(p-vec3(-1.0, 0.0, 0.0), config[0][1], nextConfig[0][1], t), minDist);
        minDist = min(drawTower(p-vec3(-1.0, 0.0, -1.0), config[0][0], nextConfig[0][0], t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 1,0,  0,0, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 0,1,  0,0, t, minDist), minDist);
        minDist = min(drawStairs(p, config, nextConfig, 0,1,  1,1, t, minDist), minDist);
        
    }
    
    minDist =min(drawTower(p-vec3( 0.0, 0.0, 0.0), config[1][1], nextConfig[1][1], t, minDist), minDist);
    
    return minDist;
}


float solvePlatform(float t0, float t1, float t2)
{
    float m = min(min(t0, t1), t2);
    float M = max(max(t0, t1), t2);
    
    return  m + floor((M-m)/2.0);

}

void solveConfig(inout mat3 config)
{
    config[1][0] = solvePlatform(config[0][0], config[2][0], config[1][1]);
    config[1][2] = solvePlatform(config[0][2], config[2][2], config[1][1]);
    config[0][1] = solvePlatform(config[0][0], config[0][2], config[1][1]);
    config[2][1] = solvePlatform(config[2][0], config[2][2], config[1][1]);

    // Adjust tower and platforms heights
    config*=FLOOR_HEIGHT;

}

int getTimedIndex()
{
    return int(iTime*ANIMATION_SPEED);

}

float getTimeParam()
{
    float t = fract(iTime*ANIMATION_SPEED);
    float ratio = 0.7;
    return max(0.0, t-ratio) * 1.0/(1.0-ratio);
}

void getConfiguration(int index, out mat3 config)
{
 
    // Random enough for its purpose...
    int texIdx = index%64;
    float rnd0 = floor(texelFetch(iChannel1, ivec2(texIdx, 0), 0).r*2.999);
    float rnd1 = floor(texelFetch(iChannel1, ivec2(texIdx, 1), 0).r*2.999);
    float rnd2 = floor(texelFetch(iChannel1, ivec2(texIdx, 2), 0).r*2.999);
    float rnd3 = floor(texelFetch(iChannel1, ivec2(texIdx, 3), 0).r*2.999);
    float rnd4 = floor(texelFetch(iChannel1, ivec2(texIdx, 4), 0).r*2.999);
    
    config = mat3(
    rnd0, 0.0,  rnd3,
    0.0 , rnd2, 0.0,
    rnd3, 0.0,  rnd4
    );
   
}

float sdScene(vec3 p)
{
    int index = getTimedIndex();
    float t = getTimeParam();
    
    mat3 config;
    mat3 nextConfig;
    
    getConfiguration(index, config);
    getConfiguration(index+1, nextConfig);
    
    solveConfig(config);
    solveConfig(nextConfig);
    
    return drawScene(p, config, nextConfig, t);
}

mat3 calcLookAtMatrix(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));

  return mat3(uu, vv, ww);
}

vec3 getRay(mat3 camMat, vec2 screenPos, float lensLength) {
  return normalize(camMat * vec3(screenPos, lensLength));
}

float calcRayIntersection(vec3 rayOrigin, vec3 rayDir, float mind, float maxd, float precis) {
  float latest = precis;
  float dist   = mind;
  float type   = -1.0;
  float res    = -1.0;

  for (int i = 0; i < 30; i++) {
    if (latest < precis) break;
    if (dist > maxd)     return -1.0;

    float result = sdScene(rayOrigin + rayDir * dist);

    latest = result;
    dist  += latest;
  }

  if (dist < maxd) {
    res = dist;
  }

  return res;
}

vec2 squareFrame(vec2 screenSize, vec2 coord) {
  vec2 position = 2.0 * (coord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}


float calcDepth(float zEye, float rayMinDist, float rayMaxDist)
{
        if(zEye == rayMaxDist) return -0.0001; // Background
        
        float dn = 1.0 / (rayMaxDist - rayMinDist);
        float zn = (-(rayMaxDist + rayMinDist)*dn*zEye - (2.0*rayMaxDist*rayMinDist*dn)) / -zEye;
        return zn * 0.5 + 0.5;
}

float calcZEye(vec3 rayDir, vec3 rayOrigin, vec3 rayTarget, float rayDist, float rayMinDist, float rayMaxDist)
{
    if(rayDist<0.0||rayDist>rayMaxDist - 0.001) return rayMaxDist; // No hit
    
    float ze =
        dot(rayDir, normalize(rayTarget - rayOrigin))*-rayDist;
        
    return  ze;
}

vec3 calcEyePos(vec3 camOrigin, vec3 ray, float t, mat3 viewMat)
{
    return transpose(viewMat) * (ray* t);
   
}

vec3 getCameraPositionSphere()
{
    bool mouseDown = (iMouse.z > 0.);
    return vec3
    (
        /* R     */ 5.4,
        /* Phi   */ mouseDown ? (iMouse.x/iChannelResolution[0].x)*12.5-6.25  : iTime * ROTATION_SPEED,
        /* Theta */ 0.48
    );
}

vec3 SphereToCartesian(vec3 s)
{
    float sinTetha = sin(s.z);
    float cosTetha = cos(s.z);
    float cosPhi   = cos(s.y);
    float sinPhi   = sin(s.y);
    
    return vec3
    (
        s.x*sinTetha*cosPhi,
        s.x*cosTetha,
       -s.x*sinTetha*sinPhi
    );
}

vec3 getCameraPosition()
{
    return SphereToCartesian(getCameraPositionSphere());
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {

  vec2 uv = squareFrame(iResolution.xy, fragCoord.xy);
  vec3 ro = getCameraPosition();
  vec3 ta = vec3(0, 0, 0);
  mat3 camMat = calcLookAtMatrix(ro, ta, 0.0);
  vec3 rd = getRay(camMat, uv, 2.0);
  float t = calcRayIntersection(ro, rd, NEAR, FAR, 0.001);
  vec3 pos = ro + rd * t;
  vec3 eyePos = calcEyePos(ro, rd, t, camMat);
  
  float depth = 
      (t < 0.0 )
      ? 1.0
      : calcDepth(-eyePos.z, NEAR, FAR);
   
  fragColor = vec4(
      eyePos.xyz, 
      depth);
}