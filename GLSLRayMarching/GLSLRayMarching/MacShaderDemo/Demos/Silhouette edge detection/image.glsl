//-----------------------------------------//
// This is an attempt to detect 1px wide   //
// silhouette edges* from depth data while //
// trying to avoid the shortcomings of     //
// gradient based methods (such as  dark   //
// triangles when looking edge-on).        // 
//                                         //
// *by silhouette edges I mean edges       //
// shared by a front-facing and a          //
// back-facing triangle (with respect to   //
// the view direction).                    //
//-----------------------------------------//

// Uncomment to get better settings for
// 4K displays.
// ----------------------------------------
// #define HI_RES_DISPLAY

// Uncomment to switch to a sobel filter
// based method (for comparison).
// ----------------------------------------
// #define USE_SOBEL
#define SOBEL_SENSITIVITY 1.8
#define SOBEL_BIAS 1.8

// Makes edges thicker. 
// Roughly as wide as the value, in pixels.
// ----------------------------------------
#ifdef HI_RES_DISPLAY
    #define INFLATE 2
#else
    #define INFLATE 1
#endif

// Uncomment to show silhouette-edges only.
// ----------------------------------------
// #define SILHO_ONLY

// Shading constants
// ----------------------------------------
#define LIGHT_DIR  vec3(0.0 , 0.0 , 1.0) 
#define COL_BRIGHT vec3(1.0 , 0.51, 0.4)
#define COL_DIM    vec3(0.05, 0.53, 0.5)
#define COL_BG     vec3(0.8 , 0.6 , 0.4)
#define COL_GRND   vec3(1.0 , 0.9 , 0.8)

// Macros
// ----------------------------------------
#define GOOCH(NdotL) (mix(COL_DIM, COL_BRIGHT, NdotL))

#ifdef HI_RES_DISPLAY
    #define DITHER(intCoords) ( float((intCoord.x+int(intCoord.y%8>=4)*4)%8>=4) )
#else
    #define DITHER(intCoords) ( float((intCoord.x+int(intCoord.y%4>=2)*2)%4>=2) )
#endif

#define SAT(x) ( clamp(x, 0.0, 1.0) )


float GetTolerance(float d, float k)
{
    // -------------------------------------------
    // Find a tolerance for depth that is constant
    // in view space (k in view space).
    //
    // tol = k*ddx(ZtoDepth(z))
    // -------------------------------------------
    
    float A=-   (FAR+NEAR)/(FAR - NEAR);
    float B=-2.0*FAR*NEAR /(FAR -NEAR);
    
    d = d*2.0-1.0;
    
    return -k*(d+A)*(d+A)/B;   
}

float DetectSilho(ivec2 fragCoord, ivec2 dir)
{
    // -------------------------------------------
    //   x0 ___ x1----o 
    //          :\    : 
    //       r0 : \   : r1
    //          :  \  : 
    //          o---x2 ___ x3
    //
    // r0 and r1 are the differences between actual
    // and expected (as if x0..3 where on the same
    // plane) depth values.
    // -------------------------------------------
    
    float x0 = abs(texelFetch(iChannel0, (fragCoord + dir*-2), 0).a);
    float x1 = abs(texelFetch(iChannel0, (fragCoord + dir*-1), 0).a);
    float x2 = abs(texelFetch(iChannel0, (fragCoord + dir* 0), 0).a);
    float x3 = abs(texelFetch(iChannel0, (fragCoord + dir* 1), 0).a);
    
    float d0 = (x1-x0);
    float d1 = (x2-x3);
    
    float r0 = x1 + d0 - x2;
    float r1 = x2 + d1 - x1;
    
    float tol = GetTolerance(x2, 0.04);
    
    return smoothstep(0.0, tol*tol, max( - r0*r1, 0.0));

}

float DetectSilho(ivec2 fragCoord)
{
    return max(
        DetectSilho(fragCoord, ivec2(1,0)), // Horizontal
        DetectSilho(fragCoord, ivec2(0,1))  // Vertical
        );
}

// Sobel-based edge detection.
// From: https://github.com/ssell/UnitySobelOutline
// ------------------------------------------------
float SobelDepth(float ldc, float ldl, float ldr, float ldu, float ldd)
{
    return 
        abs(ldl - ldc) +
        abs(ldr - ldc) +
        abs(ldu - ldc) +
        abs(ldd - ldc);
}

float SobelDepth(vec2 uvCoord, vec3 offset)
{
    return SobelDepth
    (
        texture(iChannel0, uvCoord + offset.zz).b, 
        texture(iChannel0, uvCoord - offset.xz).b, 
        texture(iChannel0, uvCoord + offset.xz).b, 
        texture(iChannel0, uvCoord + offset.zy).b, 
        texture(iChannel0, uvCoord - offset.zy).b
    );
}

float SobelDepth(vec2 fragCoord)
{
    // The size is ~2px to be consistent with the other
    // approach (1px wide edges + inflate later).
    // If you were to use the SobelDepth approach you could just
    // set a bigger offset here to increase edge thickness.
    vec3 offset = vec3
    (
        1.0/iChannelResolution[0].x,
        1.0/iChannelResolution[0].y,
        0.0
    );
    
    vec2 uvCoord = fragCoord/iChannelResolution[0].xy;
    
    return pow(SobelDepth(uvCoord, offset) * SOBEL_SENSITIVITY, SOBEL_BIAS);
}

float DetectSilhoWithSobel(vec2 fragCoord)
{
    return SobelDepth(fragCoord);
}
// -----------------------------------------------------


float Silho(vec2 fragCoord)
{
    return
    
#ifdef USE_SOBEL
         DetectSilhoWithSobel(fragCoord.xy);
#else
         DetectSilho(ivec2(fragCoord.xy));         
#endif
}

vec3 getEyePos(vec4 buffVal)
{ 
    return buffVal.xyz * vec3(1,1,-1); 
}

vec3 getEyeNormal(ivec2 intCoord)
{
    // Compute view space normals from view positions.
    // For each dimension (x/y) take the derivative with the lowest
    // absolute value to avoid some of the artifacts of the
    // cross(dFdx, dFdy) method.
    float sgn = 1.0;
    
    vec3 c   = getEyePos(texelFetch(iChannel0, intCoord.xy, 0));
    vec3 pDx = getEyePos(texelFetch(iChannel0, intCoord.xy + ivec2( 1.0, 0.0), 0));
    vec3 nDx = getEyePos(texelFetch(iChannel0, intCoord.xy + ivec2(-1.0, 0.0), 0));
    vec3 pDy = getEyePos(texelFetch(iChannel0, intCoord.xy + ivec2( 0.0, 1.0), 0));
    vec3 nDy = getEyePos(texelFetch(iChannel0, intCoord.xy + ivec2( 0.0,-1.0), 0));
    
    vec3 dx = pDx;
    vec3 dy = pDy;
    
    if(abs(nDx.z-c.z)<abs(pDx.z-c.z)) {dx = nDx; sgn*=-1.0;}
    if(abs(nDy.z-c.z)<abs(pDy.z-c.z)) {dy = nDy; sgn*=-1.0;}
    
    return normalize(cross(dx-c, dy-c))*sgn;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  
  vec2 uv = fragCoord.xy / iResolution.xy;
  ivec2 intCoord= ivec2(fragCoord);
  vec4 buf = texture(iChannel0, fragCoord.xy / iResolution.xy);
  
  float depth = buf.a;
  vec3 eyeNormal = getEyeNormal(intCoord);
  
  vec3 col = COL_BG;
  
  // Silhouette-edge value
  float s = Silho(fragCoord.xy); 

#ifdef INFLATE 

  // Makes silhouettes thicker.
  for(int i=1;i<=INFLATE; i++)
  {
     s = max(s, Silho(fragCoord.xy + vec2(i, 0)));
     s = max(s, Silho(fragCoord.xy + vec2(0, i)));
  }   
#endif
  
#ifndef SILHO_ONLY

  // Gooch shading.
  float NdotL = dot(eyeNormal, normalize(LIGHT_DIR));
  col = GOOCH(NdotL);
  
  // Dither effect for low-lit areas
  col = mix(col,vec3(0.0, 0.2, 0.2), DITHER(intCoord) * SAT(0.4-NdotL)*4.);
  
  // Background with kind of vignette.
  col = mix(col, COL_BG  , float(depth==1.0));
  col = mix(col, COL_GRND, float(depth==1.0) * SAT(1.0-length(uv-0.5)));  
   
  // Silhouettes
  col = mix(col, vec3(0.0, 0.0, 0.0),s);
  
#else
  
  // Shows only silhouettes on a white bg.
  col = mix(vec3(1.0), vec3(0.0), s);
  
#endif
  
  fragColor = vec4(col, 1.0);
}