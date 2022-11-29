// Author : SÃ©bastien BÃ©rubÃ©
// Created : Dec 2015
// Modified : Jan 2016
//
// A ShaderToy implementation of Image Based PBR Material.
// I struggled quite a bit with the TextureCubes available :
// 		-One is gamma corrected, the other is not.
//      -The skylight boundary between low and the high detail Cubemaps won't align
//       with each other, unless the sky color value is cranked up very much where saturated.
//       With the Cubemaps "HDR remapped", they finally aligned properly.
//       
// Importance Sampling is used, where mipmaps would usually be used in a game engine (much more efficient).
// I ended up using a mix between random samples and a fixed sampling pattern.
// Random sampling was too jittery, unless a very high sample count was used.
//
// Platic Materials lack a diffuse base. I have a WIP coming for this. It requires another cubemap lightness
// hemisphere integration, for the diffuse part. Should be done in a seperate pass, not to kill the framerate.
//
// Regarding the IBL version of the PBR Equation, I also struggled to balance lighting. Most articles
// and code examples are about point lights, and some pieces of code I found could not be used in the 
// IBL Scenario. A popular version of the geometric term as proposed by Disney, for example, has a modified "k" value 
// to "reduce hotness", which don't give good results with IBL (edges reflections, at grazing angles, would be
// too dark, see Unreal4 2013SiggraphPresentationsNotes pdf link p.3 below).
// Also, GGX Distribution term must not be used with IBL, because 1) it will look like garbage and 2)it makes no
// sense (for "perfect" reflection angles (H==N), GGX value goes to the stratosphere, which you really don't want
// with IBL). Energy conservation problems don't show as much with point lights, but they really do with Image Based
// Lighting.
//
// HDR Color was choosen arbitrarily. You can change from red to blue using the second rightmost slider.
// 
// Sources:
// https://de45xmedrsdbp.cloudfront.net/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
// https://seblagarde.wordpress.com/2011/08/17/feeding-a-physical-based-lighting-mode/
// http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_slides_v2.pdf
// https://www.youtube.com/watch?v=LP7HgIMv4Qo [impressive realtime materials with Substance, see 16m00s, 25m00s]
// http://sirkan.iit.bme.hu/~szirmay/fresnel.pdf
// http://www.codinglabs.net/article_physically_based_rendering_cook_torrance.aspx
// http://refractiveindex.info/?shelf=3d&book=liquids&page=water
// http://www.filmetrics.com/refractive-index-database/Al/Aluminium
// https://www.shadertoy.com/view/4djSRW Dave Hoskin's hash without sine
//
// License : Creative Commons Non-commercial (NC) license
//

//----------------------
// Constants 
const float GEO_MAX_DIST   = 50.0;
const int MATERIALID_SKY    = 2;
const int MATERIALID_SPHERE = 3;
const vec3  F_ALU_N  = vec3(1.600,0.912,0.695); //(Red ~ 670 nm; Green ~ 540 nm; Blue ~ 475 nm)
const vec3  F_ALU_K  = vec3(8.010,6.500,5.800); //(Red ~ 670 nm; Green ~ 540 nm; Blue ~ 475 nm)

//----------------------
// Slider bound globals. Use the slider, don't change the value here.
float ROUGHNESS_AMOUNT       = 0.85;//Valid range : [0-1] 0=shiny, 1=rough map
float SKY_COLOR              = 0.0; //[0.0=Red, 1.0=Blue)
float ABL_LIGHT_CONTRIBUTION = 0.0; //[0-1] Additional ABL Light Contribution

#define saturate(x) clamp(x,0.0,1.0)

//PBR Equation for both (IBL) or (ABL), plastic or metal.
vec3 PBR_Equation(vec3 V, vec3 L, vec3 N, float roughness, const vec3 ior_n, const vec3 ior_k, const bool metallic, const bool bIBL)
{
    float cosT = saturate( dot(L, N) );
    float sinT = sqrt( 1.0 - cosT * cosT);
	vec3 H = normalize(L+V);
	float NdotH = dot(N,H);//Nn.H;
	float NdotL = dot(N,L);//Nn.Ln;
	float VdotH = dot(V,H);//Vn.H;
    float NdotV = dot(N,V);//Nn.Vn;
    
    //Distribution Term
    float PI = 3.14159;
    float alpha2 = roughness * roughness;
    float NoH2 = NdotH * NdotH;
    float den = NoH2*(alpha2-1.0)+1.0;
    float D = 1.0; //Distribution term is externalized from IBL version
    if(!bIBL)
        D = (NdotH>0.)?alpha2/(PI*den*den):0.0; //GGX Distribution.
	
    //Fresnel Term
	vec3 F;
    if(metallic)
    {
        float cos_theta = 1.0-NdotV;
        F =  ((ior_n-1.)*(ior_n-1.)+ior_k*ior_k+4.*ior_n*pow(1.-cos_theta,5.))
		    /((ior_n+1.)*(ior_n+1.)+ior_k*ior_k);
    }
    else //Dielectric (Note: R/G/B do not really differ for dielectric materials)
    {
        float F0 = pow((1.0 - ior_n.x) / (1.0 + ior_n.x),2.0);
  		F = vec3(F0 + (1.-F0) * pow( 1. - VdotH, 5.));
    }
    
    //Geometric term (Source: Real Shading in Unreal Engine 4 2013 Siggraph Presentation p.3/59)
    //k = Schlick model (IBL) : Disney's modification to reduce hotness (point light)
    float k = bIBL?(roughness*roughness/2.0):(roughness+1.)*(roughness+1.)/8.; 
    float Gl = max(NdotL,0.)/(NdotL*(1.0-k)+k);
    float Gv = max(NdotV,0.)/(NdotV*(1.0-k)+k);
    float G = Gl*Gv;
    
    float softTr = 0.1; // Valid range : [0.001-0.25]. Transition softness factor, close from dot(L,N) ~= 0
    float angleLim = 0.;//2.75; // Valid range : [0-0.75]. Compensates for IBL integration suface size.
    //sinT = 1.;
    if(bIBL)
        return (F*G*(angleLim+sinT)/(angleLim+1.0) / (4.*NdotV*saturate(NdotH)*(1.0-softTr)+softTr));
    else
        return D*F*G / (4.*NdotV*NdotL*(1.0-softTr)+softTr);
}

vec3 PBR_HDRremap(vec3 c)
{
    float fHDR = smoothstep(2.900,3.0,c.x+c.y+c.z);
    vec3 cRedSky   = mix(c,1.3*vec3(4.5,2.5,2.0),fHDR);
    vec3 cBlueSky  = mix(c,1.8*vec3(2.0,2.5,3.0),fHDR);
    return mix(cRedSky,cBlueSky,SKY_COLOR);
}

vec3 PBR_HDRCubemap(vec3 sampleDir, float LOD_01)
{
    vec3 linearGammaColor_sharp = PBR_HDRremap(pow(texture( iChannel2, sampleDir ).rgb,vec3(2.2)));
    vec3 linearGammaColor_blur  = PBR_HDRremap(pow(texture( iChannel3, sampleDir ).rgb,vec3(1)));
    vec3 linearGammaColor = mix(linearGammaColor_sharp,linearGammaColor_blur,saturate(LOD_01));
    return linearGammaColor;
}

//Arbitrary axis rotation (around u, normalized)
mat3 PBR_axisRotationMatrix( vec3 u, float ct, float st ) //u=axis, co=cos(t), st=sin(t)
{
    return mat3(  ct+u.x*u.x*(1.-ct),     u.x*u.y*(1.-ct)-u.z*st, u.x*u.z*(1.-ct)+u.y*st,
	              u.y*u.x*(1.-ct)+u.z*st, ct+u.y*u.y*(1.-ct),     u.y*u.z*(1.-ct)-u.x*st,
	              u.z*u.x*(1.-ct)-u.y*st, u.z*u.y*(1.-ct)+u.x*st, ct+u.z*u.z*(1.-ct) );
}

vec3 PBR_importanceSampling(vec3 sampleDir, float roughness, float e1, float e2, out float range)
{
    const float PI = 3.14159;
    range = atan( roughness*sqrt(e1)/sqrt(1.0-e1) );
    float phi = 2.0*PI*e2;
    //Improve this? https://blog.selfshadow.com/2011/10/17/perp-vectors/
    vec3 notColinear   = (abs(sampleDir.y)<0.8)?vec3(0,1,0):vec3(1,0,0);
    vec3 othogonalAxis = normalize(cross(notColinear,sampleDir));
	mat3 m1 = PBR_axisRotationMatrix(normalize(othogonalAxis), cos(range), sin(range));
	mat3 m2 = PBR_axisRotationMatrix(normalize(sampleDir),     cos(phi),   sin(phi));
	return sampleDir*m1*m2;
}

vec3 PBR_visitSamples(vec3 V, vec3 N, float roughness, bool metallic, vec3 ior_n, vec3 ior_k )
{
    const float MIPMAP_SWITCH  = 0.29; //sampling angle delta (rad) equivalent to the lowest LOD.
    const ivec2 SAMPLE_COUNT = ivec2(05,15); //(5 random, 15 fixed) samples
    const vec2 weight = vec2(1./float(SAMPLE_COUNT.x),1./float(SAMPLE_COUNT.y));
    float angularRange = 0.;    
    vec3 vCenter = reflect(-V,N);
    
    //Randomized Samples : more realistic, but jittery
    float randomness_range = 0.75; //Cover only the closest 75% of the distribution. Reduces range, but improves stability.
    float fIdx = 0.0;              //valid range = [0.5-1.0]. Note : it is physically correct at 1.0.
    vec3 totalRandom = vec3(0.0);
    for(int i=0; i < SAMPLE_COUNT[0]; ++i)
    {
        //Random noise from DaveHoskin's hash without sine : https://www.shadertoy.com/view/4djSRW
        vec3 p3 = fract(vec3(fIdx*10.0+vCenter.xyx*100.0) * vec3(.1031,.11369,.13787)); 
    	p3 += dot(p3.zxy, p3.yzx+19.19);
    	vec2 jitter = fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
        vec3 sampleDir    = PBR_importanceSampling(vCenter, roughness, jitter.x*randomness_range, jitter.y, angularRange);
        vec3 sampleColor  = PBR_HDRCubemap( sampleDir, angularRange/MIPMAP_SWITCH);
        vec3 contribution = PBR_Equation(V, sampleDir, N, roughness, ior_n, ior_k, metallic, true)*weight[0];
    	totalRandom += contribution*sampleColor;
		++fIdx;
    }
    
    //Fixed Samples : More stable, but can create sampling pattern artifacts (revealing the sampling pattern)
    fIdx = 0.0;
    vec3 totalFixed = vec3(0.0);
    for(int i=0; i < SAMPLE_COUNT[1]; ++i)
    {
        vec2 jitter = vec2( clamp(weight[1]*fIdx,0.0,0.50), fract(weight[1]*fIdx*1.25)+3.14*fIdx); //Fixed sampling pattern.
        vec3 sampleDir    = PBR_importanceSampling(vCenter, roughness, jitter.x, jitter.y, angularRange);
        vec3 sampleColor  = PBR_HDRCubemap( sampleDir, angularRange/MIPMAP_SWITCH);
        vec3 contribution = PBR_Equation(V, sampleDir, N, roughness, ior_n, ior_k, metallic, true)*weight[1];
        totalFixed += contribution*sampleColor;
		++fIdx;
    }
    
    return (totalRandom*weight[1]+totalFixed*weight[0])/(weight[0]+weight[1]);
}

vec4 MAT_triplanarTexturing(vec3 p, vec3 n)
{
    p = fract(p+0.5);
    
    float sw = 0.20; //stiching width
    vec3 stitchingFade = vec3(1.)-smoothstep(vec3(0.5-sw),vec3(0.5),abs(p-0.5));
    
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    vec4 cX = abs(n.x)*texture(iChannel1,p.zy);
    vec4 cY = abs(n.y)*texture(iChannel1,p.xz);
    vec4 cZ = abs(n.z)*texture(iChannel1,p.xy);
    
    return  vec4(stitchingFade.y*stitchingFade.z*cX.rgb
                +stitchingFade.x*stitchingFade.z*cY.rgb
                +stitchingFade.x*stitchingFade.y*cZ.rgb,cX.a+cY.a+cZ.a)/fTotal;
}

struct TraceData
{
    float rayLen; //Run Distance
    vec3  rayDir; //Run Direction
    vec3  normal; //Hit normal
    int   matID;  //Hit material ID
};

//The main material function.
vec3 MAT_apply(vec3 pos, TraceData traceData)
{
    //Roughness texture
    vec4 roughnessBuffer = MAT_triplanarTexturing(pos*1.5,traceData.normal);
    roughnessBuffer += MAT_triplanarTexturing(pos*1.5+0.75,traceData.normal);
    float roughness = (roughnessBuffer.x+roughnessBuffer.y+roughnessBuffer.z)/3.0;
    roughness = roughnessBuffer.w+saturate(roughness-1.00+ROUGHNESS_AMOUNT)*0.25;
    
    //IBL and ABL PBR Lighting
    vec3 rd  = traceData.rayDir;
    vec3 V = normalize(-traceData.rayDir);
    vec3 N = traceData.normal;
    vec3 L = normalize(vec3(1,1,0));
    vec3 col = PBR_visitSamples(V,N,roughness, true, F_ALU_N, F_ALU_K);
    vec3 L0  = PBR_Equation(V,L,N,roughness+0.01, F_ALU_N, F_ALU_K, true, false);
    col     += PBR_HDRremap(vec3(1))*L0*ABL_LIGHT_CONTRIBUTION;
    
    //Anti-aliasing trick (normal-based)
    vec3 backgroundColor = pow(texture( iChannel2, traceData.rayDir ).xyz,vec3(2.2));
    float aaAmount = 0.095;
    float smoothFactor = 1.0-clamp(-dot(N,traceData.rayDir)/(aaAmount), 0.0, 1.0);
    col = (dot(N,-traceData.rayDir)<aaAmount)? mix(col, backgroundColor, smoothFactor) : col;
    
    return traceData.matID==MATERIALID_SKY?backgroundColor:col;
}

float map( in vec3 pos )
{
    const float GEO_SPHERE_RAD = 0.5;
    return length(pos)-GEO_SPHERE_RAD;
}

//o=ray origin, d=ray direction
TraceData TRACE_geometry(vec3 o, vec3 d)
{
    float t = 0.0;
    float tmax = GEO_MAX_DIST;
    float dist = GEO_MAX_DIST;
    for( int i=0; i<50; i++ )
    {
	    dist = map( o+d*t );
        if( abs(dist)<0.001 || t>GEO_MAX_DIST ) break;
        t += dist;
    }
    
    vec3 dfHitPosition  = o+t*d;
    bool bBackground = (dist>0.01 || t>GEO_MAX_DIST);
    
    return TraceData(t,d,normalize(dfHitPosition),bBackground?MATERIALID_SKY:MATERIALID_SPHERE);
}

vec4 processSliders(in vec2 fragCoord)
{
    vec4 sliderVal = texture(iChannel0,vec2(0,0));
	ROUGHNESS_AMOUNT        = sliderVal[1];
    SKY_COLOR               = sliderVal[2];
    ABL_LIGHT_CONTRIBUTION  = sliderVal[3];
    
    if(length(fragCoord.xy-vec2(0,0))>1.)
    {
    	return texture(iChannel0,fragCoord.xy/iResolution.xy);
    }
    return vec4(0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Camera & setup
    vec4 cSlider = processSliders(fragCoord);
    float rotX = ((iMouse.z>0.)&&any(lessThan(iMouse.xy/iResolution.xy,vec2(0.9,0.80))))?
	             ((iMouse.x/iResolution.x)*2.0*3.14) : (iTime*0.3);
    vec2 uv = 2.5*(fragCoord.xy-0.5*iResolution.xy) / iResolution.xx;
    vec3 camO = vec3(cos(rotX),0.4,sin(rotX))*0.95;
    vec3 camD = normalize(vec3(0)-camO);
    vec3 camR = normalize(cross(camD,vec3(0,1,0)));
    vec3 camU = cross(camR,camD);
   	vec3 dir =  normalize(uv.x*camR+uv.y*camU+camD);
    
    //Raytrace
    TraceData geometryTraceData = TRACE_geometry(camO, dir);
    vec3 ptGeo = (geometryTraceData.rayLen < GEO_MAX_DIST)? camO+dir*geometryTraceData.rayLen : vec3(0);
    
    //Material
    vec3 c = MAT_apply(ptGeo,geometryTraceData).xyz;
    
    //Post-processing
    float sin2 = dot(uv/1.6,uv/1.6);
    float vignetting = pow(1.0-min(sin2*sin2,1.0),2.);
    c = pow(c*vignetting,vec3(0.4545)); //2.2 Gamma compensation
    
    //Slider overlay
    fragColor = vec4(mix(c,cSlider.rgb,cSlider.a),1.0);
}