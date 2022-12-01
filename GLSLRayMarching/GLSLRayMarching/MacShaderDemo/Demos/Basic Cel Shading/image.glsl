#define DEFAULT_CEL_STEPS 5.

float dstScene(vec3 p) {
	float dst = length(p)-1.;
    dst = min(dst, length(max(abs(vec3(0.,0.,5.6)-p)-vec3(6.,3.,1.),0.)));
    return dst;
}

float cel(float x, float steps) {
    return floor(x*steps)/steps;
}
float cel(float x) {
    return cel(x, DEFAULT_CEL_STEPS);
}
vec3 cel(vec3 v, float steps) {
	return floor(v*steps)/steps;
}

vec3 getLightVector(vec3 p) {
    float t = iTime * 2.5;
	return vec3(cos(t),0.,sin(t))*4. - p;
}

float raymarch(vec3 ori, vec3 dir) {
    float t = 0.;
    for(int i = 0; i < 256; i++) {
    	float dst = dstScene(ori+dir*t);
        if(dst < .001 || t > 256.)
            break;
        t += dst * .75;
    }
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    
    vec3 ori = vec3(sin(4.+iTime*.5)*2.5,0.,-3.);
    vec3 dir = vec3(uv, 1.);
    
    if(iMouse.z > 0.) ori.x = 2.5*-((iMouse.x/iResolution.x)*2.-1.);
    
    vec3 f = normalize(-ori);
    vec3 u = normalize(cross(f, vec3(0.,1.,0.)));
    vec3 v = normalize(cross(u, f));
    dir = mat3(u,v,f)*dir;
    
    dir = normalize(dir);
    
    float t  = raymarch(ori,dir);
    vec3 col = cel(texture(iChannel1,dir).xyz, 16.);
    
    if(t < 256.) {
        vec2 e = vec2(.001,0.);
        vec3 p = ori+dir*t;
   		vec3 n = vec3(dstScene(p+e.xyy)-dstScene(p-e.xyy),
                      dstScene(p+e.yxy)-dstScene(p-e.yxy),
                      dstScene(p+e.yyx)-dstScene(p-e.yyx));
        n = normalize(n);
        vec3 r = normalize(reflect(dir,n));
        
        vec3 lv = getLightVector(p);
        vec3 ld = normalize(lv);
        float d = cel(max(dot(ld,n),0.));
        float s = cel(pow(max(dot(ld,r),0.),30.));
        
        if(raymarch(p+ld*.01,ld) < length(lv))
            d = s = 0.;
        
        vec2 uv = p.xy;
        if(p.z < 3.) {
            uv = asin(n.xy)/3.14159+.5;
        }
        col = cel(texture(iChannel0,uv).xyz,8.)*(.4+d)+s;
    }
    
    vec3 lv = getLightVector(ori);
    vec3 ld = normalize(lv);
    float s = 1.;
    if(raymarch(ori,ld) < length(lv)) {
    	s = 0.;   
    }
    col += cel(pow(max(dot(ld,dir),0.),60.), 16.)*s;
    
	fragColor = vec4(col,1.);
}