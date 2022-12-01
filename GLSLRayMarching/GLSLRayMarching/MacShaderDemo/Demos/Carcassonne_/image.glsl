// Created by sebastien durand - 01/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// *****************************************************************************

// [Dave_Hoskins] Rolling hills - https://www.shadertoy.com/view/Xsf3zX
// [Shane] Voxel Corridor - https://www.shadertoy.com/view/MdVSDh
// [HLorenzi] Hand-drawn Sketch  - https://www.shadertoy.com/view/MsSGD1
// [Mercury] Lib - http://mercury.sexy/hg_sdf for updates
// [dr2] White Folly - https://www.shadertoy.com/view/ll2cDG

// Buf A: Calculate distance to scene
// Buf B: Calculate ao and shadows
// Buf C: Textures and light
// Image: DOF post processing


#define WITH_DOF
#define WITH_CONE_TEST


#ifdef WITH_DOF

const float aperture = 3.;

const float cosAngle = cos(radians(aperture/2.));
const float GA =2.399;  // golden angle = 2pi/(1+phi)
const mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
    

bool inCone(vec3 p, vec3 o, vec3 n, float side) {
	return side*dot(normalize(o-p), n) >= cosAngle;
}


//--------------------------------------------------------------------------
// eiffie's code for calculating the aperture size for a given distance...
float coc(float t) {
	return max(t*.08, (2./iResolution.y) * (1.+t));
}


vec3 RD(const vec2 q) {
    return normalize(vec3((2.* q.x - 1.) * iRes.x/iRes.y,  (2.* q.y - 1.), 3.));
}


vec3 dof(sampler2D tex, vec2 uv, float fdist) {
    
    const float amount = 1.;
	vec4 colMain = texture(tex, uv);
    
    fdist = min(30., fdist);
    float rad = min(.3, coc(abs(colMain.w-fdist)));//.3; // TODO calculate this for Max distance on picture
    float r=2.;
    
    vec3 cn = RD(uv),    // Cone axis    
         co = cn*fdist,  // Cone origin
         sum = vec3(0.),  
     	 bokeh = vec3(1),
         acc = vec3(0),
         pixPos;
    vec2 pixScreen,
         pixel = 1./iResolution.xy,        
         angle = vec2(0, rad);
    vec4 pixCol;
    
    bool isInCone = false;
	for (int j=0;j<60;j++) {  
        r += 1./r;
	    angle *= rot;
        pixScreen = uv + pixel*(r-1.)*angle; // Neighbourg Pixel
        pixCol = texture(tex, pixScreen);    // Color of pixel (w is depth)      
        pixPos = pixCol.w * RD(pixScreen);   // Position of 3D point in camera base
#ifdef WITH_CONE_TEST
        if (inCone(pixPos, co, cn, sign(fdist - pixCol.w))) 
#endif            
        {        // true if the point is effectivelly in the cone
            bokeh = pow(pixCol.xyz, vec3(9.)) * amount +.4;
            acc += pixCol.xyz * bokeh;			
            sum += bokeh;
            isInCone = true;
        }
	}
        
 	return (!isInCone) ? colMain.xyz : // Enable to deal with problem of precision when at thin begining of the cone
       acc.xyz/sum;
}


void mainImage(out vec4 fragColor,in vec2 fragCoord) {

    iRes = iResolution.xy;
	fCoord = fragCoord;
	time = iTime+100.*iMouse.x/iResolution.x;

	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	vec3 c;

    if (isDrawing()) {
        c = texture(iChannel0,uv).rgb;
    } else {
        float fdist = texture(iChannel0,vec2(0.,-.4)).w;//length(ro);//; 64.;
        c = dof(iChannel0,uv,fdist); 
    }
    c *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .3); // Vigneting

    fragColor = vec4(c,1.);
}

#else 


void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 c = texture(iChannel0,uv);
    c *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .25); // Vigneting
	fragColor = c; //*.01; 
}

#endif