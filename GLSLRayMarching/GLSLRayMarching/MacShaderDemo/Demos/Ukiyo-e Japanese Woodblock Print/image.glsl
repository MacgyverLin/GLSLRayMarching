#define sky_upper        vec3(0.76,  0.74,  0.64)
#define sky_lower        vec3(0.81,  0.68,  0.53)
#define mountain_color   vec3(0.25,  0.35,  0.45)
#define mountain_outline vec3(0.24,  0.28,  0.31)*0.9
#define hill_upper       vec3(0.71,0.53,0.26)
#define hill_lower       vec3(0.71,0.53,0.26)
#define hill_natural     vec3(0.77,0.61,0.37)
#define hill_outline     vec3(0.57,0.37,0.14)
#define cloud_upper      vec3(0.85,  0.79,  0.69)
#define cloud_lower      vec3(0.72,  0.7,   0.63)
#define cloud_outline    vec3(0.64,  0.6,   0.48) * 0.9
#define border_color     vec3(0.250, 0.250, 0.250)
#define bush_color_far   vec3(0.63,0.35,0.16)
#define bush_color_far2  vec3(0.51,0.25,0.14)
#define d_tree_outline   vec3(0.42,0.17,0.05)
#define tree_close_trunk vec3(0.39,0.3,0.15)
#define tree_leaves      vec3(0.56,0.26,0.11)
#define tree_leaves2     vec3(0.61,0.4,0.22)
#define leaves_outline   vec3(0.35,0.22,0.09)
#define paper_color      vec3(0.84,0.79,0.66)
#define paper_outline    vec3(0.61,0.58,0.47)
#define paper_col_dark   vec3(0.78,0.72,0.6)

#define TAU  6.28318530718
#define PI   3.14159265359

// -----------------------------------------------
// From https://www.shadertoy.com/view/XdXGW8

vec2 grad( ivec2 z )  // replace this anything that returns a random vector
{
    // 2D to 1D  (feel free to replace by some other)b
    int n = z.x+z.y*11111;

    // Hugo Elias hash (feel free to replace by another one)
    n = (n<<13)^n;
    n = (n*(n*n*15731+789221)+1376312589)>>16;

#if 0

    // simple random vectors
    return vec2(cos(float(n)),sin(float(n)));
    
#else

    // Perlin style vectors
    n &= 7;
    vec2 gr = vec2(n&1,n>>1)*2.0-1.0;
    return ( n>=6 ) ? vec2(0.0,gr.x) : 
           ( n>=4 ) ? vec2(gr.x,0.0) :
                              gr;
#endif                              
}

float noise( in vec2 p )
{
    ivec2 i = ivec2(floor( p ));
     vec2 f =       fract( p );
	
	vec2 u = f*f*(3.0-2.0*f); // feel free to replace by a quintic smoothstep instead

    return mix( mix( dot( grad( i+ivec2(0,0) ), f-vec2(0.0,0.0) ), 
                     dot( grad( i+ivec2(1,0) ), f-vec2(1.0,0.0) ), u.x),
                mix( dot( grad( i+ivec2(0,1) ), f-vec2(0.0,1.0) ), 
                     dot( grad( i+ivec2(1,1) ), f-vec2(1.0,1.0) ), u.x), u.y);
}


float rand(float seed) 
{
  return fract(sin(mod(seed,1000.) *52.02) * 7632.2);
}

float rand2D(vec2 seed) 
{
  return fract(sin(dot(mod(seed, vec2(1000.)), vec2(18.612, 52.624)) *52.02) * 842.2);
}

// From https://github.com/glslify/glsl-aastep/blob/master/index.glsl
float aaStep(float threshold, float x)
{
    float afwidth = clamp(length(vec2(dFdx(x), dFdy(x))) * 0.70710678118654757, 0. ,0.05);
    return smoothstep(threshold-afwidth, threshold+afwidth, x);
}

float tWave(float x, float amplitude, float frequency){
      return abs((fract(x*frequency) *2.)-1.) * amplitude;   
}


float distanceWithAspectRatio(vec2 v1, vec2 v2, float aspectRatio)
{
   vec2 t = v2 - v1; 
   return sqrt(t.x* t.x*(aspectRatio*aspectRatio)  + t.y *t.y);
}

void DrawWithOutline(inout vec3 col, vec3 paintCol, vec3 outlineCol, float threshold, float value, float thickness)
{
       vec3 maskCol = mix(outlineCol, paintCol, aaStep(thickness, threshold - value));
       col = mix(maskCol, col, aaStep(threshold, value));
}


float distanceOnNormalizedAngle(float angle, float refPoin)
{
  
  float d =abs( angle - refPoin);
  if(d> 0.5) d = 1. - d;
  return d;
}


void DrawBetweenTwoPoints(vec2 origin, vec2 end, vec2 uv, float size, vec3 lineColor, inout vec3 sceneColor){
    
    
    vec2 vector = end - origin;
          uv  -= origin;
    float len  = length(vector);
       vector /= len;
    float v2   = dot(vector, vector);
    float vUv  = dot(vector, uv);
    vec2  p    = vector * clamp(vUv, 0.,len) /v2;
    float d    = distance(p, uv);

    sceneColor = mix(lineColor, sceneColor, clamp(aaStep(size, d), 0. ,1.)); 
}

// -----------------------------------------------

void PaintSky(inout vec3 col, in vec2 uv)
{

   
    col = mix( sky_lower, sky_upper, smoothstep(0.5, 0.70, uv.y));
    col = mix(col, paper_color ,  pow(texture(iChannel0,uv*2.).x,5.));
}


float cloudsHeightFunction(float coord_x, float baseamplitude, float baseFrequency, float height, vec2 coord_i, float distanceToEdge)
{

   float upperPart = rand2D(coord_i + vec2(51.2, 82.58))*0.15;
   
   float upOrDown = step(0.,height);
   
   for(float f = 1.; f <6.0; f++)
     {
       upperPart += abs(sin(coord_x * baseFrequency * f + rand2D(coord_i + 
       vec2(f*51.2 +72.124, f*82.58+ 93.125))
       + iTime*0.2)) * baseamplitude/f;
     };
     
     float lowerPart = 0.0f;
     
      for(float f = 1.; f <4.0; f++)
     {
       lowerPart += abs(sin(coord_x * baseFrequency * f*0.5 + 
       rand2D(coord_i+ vec2(f*12.8231+53.838, f*62.61+ 12.09)))) * baseamplitude * 0.5/f;
     };
     
     return mix(upperPart, lowerPart, mix(upOrDown, 1.,  1.-distanceToEdge));
}
void PaintMountain(inout vec3 col, in vec2 uv)
{


    float fogHeight = sin(uv.x*2.) *0.1;



     float f  = 0.40;
     float baseAmplitude = 0.12;
     float baseFrequency = 1.;
     
     f += fogHeight;
     
     
     for(float i = 1.; i<10. ; i++)
     {
        f += tWave(uv.x + rand(i), baseAmplitude / i,  baseFrequency * i);
     }
     
     fogHeight += tWave(uv.x + 21.521, 0.1,  0.4);
     
    vec3 mountainAndFog = mix(mountain_color, sky_lower, smoothstep(0.1, 0.3 , fogHeight *0.5 + 0.6  - uv.y) ); 
     
     
     
     
     
     float fracUV_y = uv.y;
     
     fracUV_y-= f;
  
     float uv_i_y = floor(fracUV_y *12.);
     fracUV_y = fract(fracUV_y *12.);
  
     
     float outline = aaStep(0.02 , 
                            abs(fracUV_y - 0.5 + sin(uv.x*20.) * 0.5)) - 
                            abs(sin(uv.x*8. + rand(uv_i_y*10.)*6.4)) *0.008 
                      + abs(sin(uv.x *10. + rand((uv_i_y +24.12)*10.)*6.4)) ;
           outline = clamp(outline, 0. , 1.);
    
        mountainAndFog = mix(mountain_outline, mountainAndFog, outline);
        mountainAndFog = mix(mountainAndFog, paper_color ,  pow(texture(iChannel0,uv*5.).x,6.));
        
        DrawWithOutline(col, mountainAndFog, mountain_outline, f, uv.y, 0.004 + abs(sin(uv.x*5.)) *0.004);
     
}

void DetermineHillHeights(inout vec3 col, in vec2 uv, out float hillHeight)
{
    hillHeight =   (sin(uv.x*7. +2.5) *0.5 + 0.5) *0.05  + 0.4 +
          + sin(uv.x*3. + 2.3) *0.06+ (sin(uv.x*88.+ 7.) ) * 0.0025  + sin(uv.x*30. + 3.3 ) *0.01;
}

void PaintHills(inout vec3 col, in vec2 uv, in float hillHeight)
{
    vec3 hillWithGradient = mix(hill_upper, hill_lower, smoothstep(0.1, 0.5, sin(uv.x*8.) *0.05 + 0.3 - uv.y) ); 


    float innerLinesWave = (abs(sin(uv.x*2.) + 0.05))*( 1.-min(1., (hillHeight - uv.y)))* 0.25;
    
    vec2 coord   = uv - vec2(0., hillHeight + innerLinesWave); 
    vec2 coord_f = fract(coord* vec2(2., 10.) );
    vec2 coord_i = floor(coord* vec2(2., 10.) );
    
    float sinWaveOne =  sin(uv.x* 13. + rand(coord_i.y*252.125 + 521.2)*612.21);
    float outline = aaStep(0.0, 
    abs(coord_f.y - 0.5 +sinWaveOne*0.2) - 0.0025
    + sin(uv.x* 15. + rand(coord_i.y*252.125)*612.21)*0.015 );
    
           
           
           
     mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
     vec2 noiseUV = (coord +vec2(0., sinWaveOne)*0.03 ) * vec2(69., 80.);
    float noisef  = noise(noiseUV); noiseUV = m* noiseUV;
          noisef += 0.5*noise(noiseUV); noiseUV = m* noiseUV;
          noisef += 0.25*noise(noiseUV); noiseUV = m* noiseUV;
          noisef += 0.125*noise(noiseUV);
          noisef += noise(coord * 5.);
    float texturefactor = clamp(abs(noisef),0., 1.);
    
    hillWithGradient = mix(hillWithGradient, hill_natural, texturefactor);
    
    hillWithGradient = mix(hill_outline ,hillWithGradient,outline);
    
    hillWithGradient = mix(hillWithGradient, paper_color ,  pow(texture(iChannel0,uv*2.).x,5.));
    
    DrawWithOutline(col, hillWithGradient, hill_outline, 0.001,uv.y -hillHeight , 0.0025 + abs(sin(uv.x*5.)) *0.003);
    
}

void PaintHClouds(inout vec3 col, in vec2 uv, float aspectRatio)
{
    vec2 uv_cloud_i = floor(uv * vec2(2., 8.)) ;
    vec2 uv_cloud_f = fract(uv * vec2(2., 8.) + vec2( rand(uv_cloud_i.y*3.) * 0.5, 0.)) ;
    vec2 uv_cloud_r = floor(uv * vec2(2., 8.) + vec2( rand(uv_cloud_i.y*3.) * 0.5, 0.)) ;
     aspectRatio =  4./aspectRatio  ;
    
    vec2 center      = vec2(rand2D(uv_cloud_r + vec2(21.51,73.)), rand2D(uv_cloud_r + vec2(2., 51.51)));
         center.x    = center.x *2. - 1.;
         center      = vec2(0.5, 0.25) + center *vec2(0.3, 0.0); 
         
         
         // Determine cloud starting and ending point
   float leftPoint   = 0.1       + (center.x - 0.1)  * rand2D(uv_cloud_r *vec2(572.21, 72.823) + vec2(94.1, 46.87));
   float rightPoint  = center.x  + (0.9 - center.x ) * rand2D(uv_cloud_r *vec2(55.93, 287.23) + vec2(2.215,912.2));
         
   float endsAsdots  =  aaStep(0.02, min(distanceWithAspectRatio(vec2(leftPoint, center.y),uv_cloud_f, aspectRatio),
                 distanceWithAspectRatio(vec2(rightPoint, center.y),uv_cloud_f, aspectRatio)));

         // Determining the projection of the current pixel on the line between left and right points
         
    float projectionPos = min(max(leftPoint, uv_cloud_f.x), rightPoint);
    float distanceToEdge =  min(uv_cloud_f.x - leftPoint , rightPoint - uv_cloud_f.x); 


    float distanceToLine  = distanceWithAspectRatio(vec2(projectionPos, center.y), uv_cloud_f,aspectRatio )*0.5;
          distanceToLine -= cloudsHeightFunction(uv_cloud_f.x, 0.1, 10., 
          center.y - uv_cloud_f.y, uv_cloud_r* vec2(51.251, 72.21), smoothstep(0., 0.01, distanceToEdge)) 
          * smoothstep(-0.05, 0.05, distanceToEdge);

    float maskCoord  = distanceToLine ;
    float threshold  = 0.01;
          threshold -= step(7., uv_cloud_i.y);
          threshold -= step(0.5, rand2D(uv_cloud_r));
          
    vec3  cloudColGrad =mix(cloud_lower, cloud_upper, uv_cloud_f.y) ;
        cloudColGrad = mix(cloudColGrad, paper_color ,  pow(texture(iChannel0,uv*2.).x,5.));
    DrawWithOutline(col, cloudColGrad, cloud_outline, threshold, maskCoord, 0.004 + abs(sin(uv.x*12.)) *0.01);
    
}

float GetFarTreeDisplacement(float Domain, float baseFrequency, float baseAmplitude, float seed)
{
  float d = 0.0;
  


        d += (sin((Domain + rand(seed*25.521 + 0.0)) *baseFrequency ) *0.5 + 0.5)* baseAmplitude; 
        baseAmplitude *= 0.9;
        baseFrequency *= 1.2;
        
        d += (sin((Domain + rand(seed*25.521 + 61.21)) *baseFrequency ) *0.5 + 0.5)* baseAmplitude; 
        
        baseAmplitude *= 0.9;
        baseFrequency *= 1.5;
        
        d += (sin((Domain + rand(seed*25.521 + 21.6231)) *baseFrequency ) *0.5 + 0.5)* baseAmplitude; 
        baseAmplitude *= 0.5;
        baseFrequency *= 3.5;
        
        d += (sin((Domain + rand(seed*12.521 + 93.8236)) *baseFrequency ) *0.5 + 0.5)* baseAmplitude; 
        d += (sin((Domain + rand(seed*12.521 + 62.8787)) *120. ) *0.5 + 0.5)* 0.05; 
        
  return d;
}


void PaintDistanceTrees(inout vec3 col, in vec2 uv, in float terrainHeight, float seed, float aspectRatio)
{
   vec2 uv_bush_i = floor(uv * vec2(15., 1.));
   vec2 uv_bush_f = fract(uv * vec2(15., 1.));
        uv_bush_f.y = uv_bush_f.y - terrainHeight;
        uv_bush_f.y *= 15. * aspectRatio;
  
   float threshold = 0.3;
   float shoulDraw = step(0.4, rand(uv_bush_i.x +1. + seed));
         threshold-=  shoulDraw;
         
         float treeCenterY = (rand((uv_bush_i.x+seed)*65.)*2.0-1.0) * 0.4;
         
         vec2 toTreeCenter = vec2(0.5, treeCenterY) - uv_bush_f;
         
         float randOne = rand(seed*251.221 + uv_bush_i.x*2.521);
   float f         = length(toTreeCenter);
   float angle     = fract(atan(toTreeCenter.y, toTreeCenter.x) / TAU + 0.5 + 0.25);
   float dis       = GetFarTreeDisplacement(angle, 
                     6.+randOne*10.,
                     0.2,  seed + uv_bush_i.x);
         f        -= dis * distanceOnNormalizedAngle(angle, 0.);
   
   float sinOne = sin((uv_bush_f.x + seed *82.12+ uv_bush_i.x*10.67) *35.);
   float colorFactor = abs(noise(uv_bush_f*2.
   + vec2(0., sinOne*0.1 )));
   
   colorFactor +=  smoothstep(treeCenterY+0.1, treeCenterY-0.3, uv_bush_f.y  + sinOne*0.01);
   
  vec3 bushColor  = mix( bush_color_far, bush_color_far2, colorFactor);
  
    // Draw trunk
    
    float thickness = abs(sin(angle*12. + seed*6.21 + uv_bush_i.x*5.214 + uv.y*30.));
    
    DrawBetweenTwoPoints(vec2(0.5, treeCenterY), vec2(0.5, treeCenterY-0.5),
    uv_bush_f + vec2(0., 0.), 0.005 - shoulDraw + thickness*0.03 , mix(d_tree_outline, bush_color_far, 0.25), col);
    
    // Draw inner leaves
    
    
    float coord_leaves =  distance(uv_bush_f, vec2(0.5, treeCenterY-0.5))*5.;
    float coord_l_i    = floor(coord_leaves);
          coord_leaves = fract(coord_leaves);
    float sinTwo   = sin(uv_bush_f.x *82. + randOne *65.61+ coord_l_i*82.21);
    float sinThree = sin(uv_bush_f.x *10. + randOne *65.61+ coord_l_i*52.21);
          coord_leaves = abs(coord_leaves - 0.5 + sinTwo*0.05+ sinThree*0.4);
          coord_leaves = aaStep(-0.031, coord_leaves  + sinThree*0.1);
    bushColor = mix(bush_color_far2,bushColor, coord_leaves);
    
      bushColor = mix(bushColor, paper_color ,  pow(texture(iChannel0,uv*3.).x,6.));
    
   DrawWithOutline(col, bushColor, d_tree_outline, threshold, f,
   0.008 + thickness*0.01);
   
   
   
}



vec4 LineSegCoord(vec2 p1, vec2 p2, vec2 uv, out float segmentLength){
    

    vec2 vector = p2 - p1;                         // Find the vector between the two lines
          uv   -= p1;                              // Move the entire coord system so that the point 1 sits on the origin, it is either that or always adding point 1 when you want to find your actual point
    float len   = max(length(vector), 0.01);                  // Find the ditance between the two points
       vector  /= len;                             // normalize the vector 
    float vUv   = dot(vector, uv);                 // Find out how far the projection of the current pixel on the line goes along the line using dot product
    vec2  p     = vector * clamp(vUv, 0.,len) ;    // since vector is normalized, the if you multiplied it with the projection amount, you will get to the coordinate of where the current uv has the shortest distance on the line. The clamp there ensures that this point always remains between p1 and p2, take this out if you want an infinite line
    vec2 ToLine = p - uv;                       
    float d     = length(ToLine);                  // the actual distance between the current pixel and its projection on the line
    
    vec2 ortho    = vec2(vector.y, -vector.x);     // For 3D you would have to use cross product or something
    float signedD = dot(ortho, ToLine);            // this gives you a signed distance between the current pixel and the line. in contrast to the value d, first this value is signed, so different on the different sides of the line, and second, for a line segment with finite ends, beyond the finit end, the magnitude of this value and d start to differ. This value will continue to get smaller, as you go around the corner on the finit edge and goes into negative
    segmentLength = len;
    
                                                   // fourth component is used for drawing the branch thickness, is a noramlized value stating how far the pixel is between p1 nad p2
    return vec4(vUv, d, signedD, clamp(vUv, 0.,len)/ len); 
}

float determineBranchThickness(float size, vec4 branchCoord)
{
    size = mix(size, max(size, 0.8),  branchCoord.w);
    return mix(0.05, 0., size);
}




float GetBranchDisplacement(vec2 uv, float seed)
{
  float d  =  (sin((uv.x + rand(seed*82.521 + 0.0)) *10. ) *0.5 + 0.5)* 0.1; 
        d  =  (sin((uv.y + rand(seed*82.521 + 0.0)) *10. ) *0.5 + 0.5)* 0.1; 
        d +=  (sin((uv.x + rand(seed*12.57 + 2.6123)) *15. ) *0.5 + 0.5)* 0.08;
        d +=  (sin((uv.y + rand(seed*68.2146 + 5.84746)) *40. ) *0.5 + 0.5)* 0.025;
        d +=  (sin((uv.y + rand(seed*90.572 + 73.232)) *60. ) *0.5 + 0.5)* 0.03;
        return abs(d);
}

float GetLeaveShapes(vec4 branchCoord, float segmentLength, float treeShouldExist, float seed, out float randLeaveSpace)
{
   
  vec2 leaveCoord_f = fract(vec2(branchCoord.x*4. + sign(branchCoord.z)*0.2, branchCoord.z));
  vec2 leaveCoord_i = floor(vec2(branchCoord.x*4. + sign(branchCoord.z)*0.2, branchCoord.z));
  
  float leaveIsOnBranch = step( segmentLength, (leaveCoord_i.x +0.5)/4.);
        leaveIsOnBranch += step((leaveCoord_i.x +0.5)/4., 0.);
  
  randLeaveSpace =  rand(seed + rand2D(leaveCoord_i + vec2(51.61,87.21)));
  
  float laeveShape = abs(leaveCoord_f.x - 0.5);
        laeveShape = leaveIsOnBranch+ treeShouldExist
        + laeveShape - mix(0., mix(0.2,0.25 + abs(sin(2.35* branchCoord.x/TAU
        + rand(randLeaveSpace+2.731 + sign(branchCoord.y)*20.0231)))*0.2, randLeaveSpace),  
        abs(sin(PI*clamp(branchCoord.z/mix(0.2, 0.35, rand(randLeaveSpace+52.731)), -1.,1.))));


     
  return laeveShape;  
}

void DrawLeaves(inout vec3 col, vec4 branchCoord, float segmentLength, float treeShouldExist, float seed, vec2 uv)
{
     float randLeaveSpace;

   branchCoord.x += sin(branchCoord.z*5. + rand(seed) * 6.12)*0.05;

   float leaveShape = GetLeaveShapes(branchCoord, segmentLength, treeShouldExist, seed , randLeaveSpace);
   
   float noiseMask = pow(texture(iChannel0,uv*3.).x,5.);
   vec3 leaveColor = mix(tree_leaves, tree_leaves2,randLeaveSpace);
 leaveColor = mix(leaveColor, paper_color ,  noiseMask);
   
   float leaveOutlineThickness = sin(branchCoord.x*20.+randLeaveSpace);
   DrawWithOutline(col, leaveColor, leaves_outline, -0.03, leaveShape, 0.05 + abs(leaveOutlineThickness*0.06));
   branchCoord.x += /*sin(branchCoord.z*5. + rand(seed+62.721) * 6.12 )*0.05 + */
                    sin(branchCoord.x*5. + rand(seed+62.721) * 6.12 )*0.05  ;
   leaveShape = GetLeaveShapes(branchCoord + vec4(0.15,0.,0.,0.), segmentLength, treeShouldExist, seed +62.213, randLeaveSpace);
   leaveOutlineThickness = sin(branchCoord.x*20.+randLeaveSpace);
  
  leaveColor = mix(tree_leaves, tree_leaves2,randLeaveSpace);
 leaveColor = mix(leaveColor, paper_color ,  noiseMask);
  
  DrawWithOutline(col, leaveColor, leaves_outline, -0.03, leaveShape, 0.05 + abs(leaveOutlineThickness*0.06));
   
    leaveShape = GetLeaveShapes(branchCoord + vec4(-0.1521,0.,0.,0.), segmentLength, treeShouldExist, seed +9.213, randLeaveSpace);
   leaveOutlineThickness = sin(branchCoord.x*20.+randLeaveSpace);
   
   leaveColor = mix(tree_leaves, tree_leaves2,randLeaveSpace);
 leaveColor = mix(leaveColor, paper_color ,  noiseMask);
   
   DrawWithOutline(col, leaveColor, leaves_outline, -0.03, leaveShape, 0.05 + abs(leaveOutlineThickness*0.06));
   
     leaveShape = GetLeaveShapes(branchCoord + vec4(0.1,0.,0.,0.), segmentLength, treeShouldExist, seed -24.173, randLeaveSpace);
   leaveOutlineThickness = sin(branchCoord.x*20.+randLeaveSpace);
  
  leaveColor = mix(tree_leaves, tree_leaves2,randLeaveSpace);
 leaveColor = mix(leaveColor, paper_color ,  noiseMask);
  
  
  DrawWithOutline(col, leaveColor, leaves_outline, -0.03, leaveShape, 0.05 + abs(leaveOutlineThickness*0.06));

 
}

#define trunkBorder 0.25
#define branchStartRange 0.7
#define treeEndPad 0.2
void PaintCloseUpTrees(inout vec3 col, vec2 uv, float seed)
{


  uv.x += sin(uv.y*10. + uv.x + seed)*0.02 + sin(uv.y*20. + uv.x + seed)*0.01;

  vec2 uv_trunk_i = floor(uv * vec2(10., 7.));
  vec2 uv_trunk_f = fract(uv * vec2(10., 7.));
  
  float range_x_dis = 1. - trunkBorder*2.;
  
  vec2 p0 = vec2( rand2D(uv_trunk_i)                * range_x_dis + trunkBorder, 0.);
  vec2 p1 = vec2( rand2D(uv_trunk_i + vec2(0., 1.)) * range_x_dis + trunkBorder, 1.);
  
  
  vec2 p0To1  = normalize(p1 - p0);
  vec2 p0Touv = uv_trunk_f - p0;
  
  float dot_x   = dot(p0Touv, p0To1);
  float error_y = distance(uv_trunk_f- p0,  dot_x * p0To1);
  

  float treeShouldExist  = step(.15,rand(uv_trunk_i.x +52.12 + seed*5.213)) ;
  float trunkHeight      = rand(uv_trunk_i.x)*4.0;
        treeShouldExist  = max(treeShouldExist, step(trunkHeight, uv_trunk_i.y));
  float thicknessControl = min(1., (uv_trunk_i.y + uv_trunk_f.y)/ trunkHeight); 
  
  
  // --- branches
  // - left  
  float cellRandOne = rand2D(uv_trunk_i + vec2(5.21 + seed, 1.2541 + seed));
  float branchLeftStartf   =  cellRandOne
                             * min(trunkHeight - uv_trunk_i.y, branchStartRange + treeEndPad);
  vec2  branchLeftStartv   = p0 + p0To1 * branchLeftStartf;
  vec2  branchLeftEndv     = vec2(treeEndPad + rand2D(uv_trunk_i + vec2(2.712,  16.41)) * (branchLeftStartv.x - treeEndPad), 
                                  rand2D(uv_trunk_i + vec2(93.221 + seed, 22.83 + seed))
                                  * (1. - branchLeftStartv.y - treeEndPad) +  branchLeftStartv.y );  
 
  float branchThickStart   = min(1., (uv_trunk_i.y + branchLeftStartv.y)/ trunkHeight); 
  
  
  float segmentLength = 0.0;
  vec4 branchCoord = LineSegCoord(branchLeftStartv, branchLeftEndv, uv_trunk_f, segmentLength);
  

 float  branch = aaStep(0.001, branchCoord.y - determineBranchThickness(branchThickStart, branchCoord));
 
  
   float randLeaveSpace;
   DrawLeaves(col, branchCoord, segmentLength, treeShouldExist, seed + cellRandOne, uv);
 
  // - right 
  
  float branchRightStartf   = rand2D(uv_trunk_i + vec2(251.24, 7.1281)) 
  * min(trunkHeight - uv_trunk_i.y, branchStartRange + treeEndPad);
  vec2  branchRightStartv   = p0 + p0To1 * branchRightStartf;
  vec2  branchRightEndv     = vec2(rand2D(uv_trunk_i + vec2(71.22,  96.12)) * (1. - branchRightStartv.x - treeEndPad) +  branchRightStartv.x , 
                                   rand2D(uv_trunk_i + vec2(0.21, 83.16)) * (1. - branchRightStartv.y - treeEndPad) +  branchRightStartv.y);  
  
        branchThickStart    = min(1., (uv_trunk_i.y + branchRightStartv.y)/ trunkHeight); 

     
     
     branchCoord = LineSegCoord(branchRightStartv, branchRightEndv, uv_trunk_f, segmentLength);
     
        branch *= aaStep(0.001, branchCoord.y - determineBranchThickness(branchThickStart, branchCoord));
       DrawLeaves(col, branchCoord, segmentLength, treeShouldExist, seed + cellRandOne, uv);
      vec3 trunkCol = mix(tree_close_trunk, paper_color ,  pow(texture(iChannel0,uv*2.).x,5.));
  col = mix(trunkCol, col, max(aaStep(0., error_y - mix(0.05, 0., thicknessControl))* branch,treeShouldExist));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
         uv.y = 1.5 * uv.y  - 0.25;
    vec3 col = vec3(0., 0., 0.);
    uv.x += iTime*0.01;


    float aspectRation = (iResolution.y / 1.5)/ iResolution.x;
    PaintSky(col, uv);
 
    PaintHClouds(col, uv, aspectRation);
      uv.x += iTime*0.0065;
      
    PaintHClouds(col, uv * vec2(1., 0.8)+ vec2(7.213, 0.05 ), aspectRation);
            uv.x += iTime*0.015;
    PaintMountain(col, uv );
    uv.x += iTime*0.1;
    float hillHeights;
    DetermineHillHeights(col, uv, hillHeights);
    PaintDistanceTrees(col, uv*1.1, hillHeights+0.05, 0., aspectRation);
    PaintHills(col, uv, hillHeights);
    PaintDistanceTrees(col, (uv * 0.9) + vec2(5.2134, 0.), hillHeights-0.05, 51.613, aspectRation);
    
     uv.x += iTime*0.1;
    
    PaintCloseUpTrees(col, uv , -24.0);
    
     uv.x += iTime*0.1;
    PaintCloseUpTrees(col, uv *0.95+ vec2(25.421, 0.05), 58.612);
    
    vec2 uvUnchanged = fragCoord/iResolution.xy;
         uvUnchanged.x *= iResolution.x/iResolution.y;
    
     
    vec2 shaderToyBorder      = vec2(0.0, 0.120 );
    vec2 paperBorderThickness = vec2(0.045, 0.045);
    float outlineThickness = 0.003 + abs(sin(uvUnchanged.x*5. +2.612) *0.1 + sin(uvUnchanged.y*5.)*0.1)*0.015;
    
    
    vec3 outlineColor =  mix(paper_outline, paper_color ,  pow(texture(iChannel0,uvUnchanged*3.).x,3.));
    
    col = mix(outlineColor , col,  step(shaderToyBorder.y + paperBorderThickness.y + outlineThickness, uvUnchanged.y)
              * (1.- step(1.- (shaderToyBorder.y + paperBorderThickness.y + outlineThickness), uvUnchanged.y)));
    
    col = mix(outlineColor , col,  step(shaderToyBorder.x + paperBorderThickness.x + outlineThickness, uvUnchanged.x)
              * (1.- step((iResolution.x/iResolution.y) - (shaderToyBorder.x + paperBorderThickness.x + outlineThickness), uvUnchanged.x)));
    
    
    vec3 pape = mix(paper_color, paper_col_dark ,  pow(texture(iChannel0,uvUnchanged*2.).x,2.)); 
    
    
    col = mix(pape , col,  step(shaderToyBorder.y + paperBorderThickness.y, uvUnchanged.y)
              * (1.- step(1.- (shaderToyBorder.y + paperBorderThickness.y), uvUnchanged.y)));
    
    col = mix(pape , col,  step(shaderToyBorder.x + paperBorderThickness.x, uvUnchanged.x)
              * (1.- step((iResolution.x/iResolution.y) - (shaderToyBorder.x + paperBorderThickness.x), uvUnchanged.x)));
    
    
    
    
    
    col = mix(border_color , col,  step(shaderToyBorder.x, uvUnchanged.x) 
    * (1.- step((iResolution.x/iResolution.y)- shaderToyBorder.x, uvUnchanged.x)));
    
    col = mix(border_color , col,  step(shaderToyBorder.y, uvUnchanged.y) 
    * (1.- step(1.-shaderToyBorder.y, uvUnchanged.y)));


    

    // Output to screen
    fragColor = vec4(col,1.0);
}