#define SC (250.0)

vec2 noise(in vec2 uv)
{
    //return sin(uv.x/1.6)+cos(-uv.y*1.6);
    return vec2(sin(uv.x),cos(uv.y))+vec2(1.);
}

#define OCTAVES 8
float fbm1(in vec2 uv,int octaves,float i1,float value1)
{
    //this function generates the terrain height
    
    float f = 2.15; //change this number to change the spacing of the mountains 
    //Another interesting variation:
    //float f = 2.15+(sin(uv.x/i1)+cos(uv.x/i1))*value1;
    
    float value = value1;
    float amplitude = i1*value1;
    float freq = i1/f;
    float n1 = 0.;
    vec2 noise2,noise1;
    for (int i = 0; i < octaves; i++)
    {
        
        
        noise2 = noise(noise1.yx-uv/freq);
        noise1 = noise2-vec2(value)-noise1.yx*freq;
        freq /= -f;
        n1 = noise1.x+noise1.y;

        value += n1*(amplitude-freq);

        uv -= noise2.yx*freq;
    }
    
    return value/(4.);
}

float fbm(vec2 uv, int oct){
    float result = 0.;
    //uv /= 2.;
    for(float i = 1.; i < 3.; i++){
        float i1 = i*i;
        result = fbm1(uv,oct,i1,result-result/i1);
        oct /= 2;
    }
    return result;
}

float fbm(in vec2 uv){
    return fbm(uv,OCTAVES);
}

float f(in vec3 p,int iters)
{   
    float h = fbm(p.xz,iters);
    return h;
}

float f(in vec3 p)
{   
    float h = fbm(p.xz,OCTAVES);
    return h;
}

vec3 getNormal(vec3 p, float t)
{
    vec3 eps=vec3(.001 * t, .0, .0);
    vec3 n=vec3(f(p - eps.xyy) - f(p + eps.xyy),
                2. * eps.x,
                f(p - eps.yyx) - f(p + eps.yyx));
  
    return normalize(n);
}

float rayMarching(in vec3 ro, in vec3 rd, float tMin, float tMax)
{
    float t = tMin;
	for( int i = 0; i < 300; i++ )
	{
        vec3 pos = ro + t * rd;
		float h = pos.y - f(pos,OCTAVES);
		if( abs(h) < (0.0015 * t) || t > tMax ) 
            break;
		t += 0.4 * h;
	}

	return t;
}

/*
//raymarching with LOD
float rayMarching(in vec3 ro, in vec3 rd, float tMin, float tMax)
{
    float t = tMin;
    int oct = 2;
	for( int i = 0; i < 300; i++ )
	{
        vec3 pos = ro + t * rd;
		float h = pos.y - f(pos,OCTAVES);
		if( abs(h) < (0.0015 * t) || t > tMax ) 
            if(oct < 8) oct += 2;
            else break;
		t += 0.4 * h;
	}

	return t;
}
*/

vec3 lighting(vec3 p, vec3 normal, vec3 L, vec3 V)
{
    vec3 sunColor = vec3(1., .956, .839);
    vec3 albedo = vec3(1.);
   	vec3 diff = max(dot(normal, L) * albedo, 0.);
    
    vec3 refl = normalize(reflect(L, normal));
    float spec = max(dot(refl, -normalize(V)), 0.);
    spec = pow(spec, 18.);
    spec = clamp(spec, 0., 1.);
    float sky = max(0.0, dot(vec3(0.,1.,0.), normal));
    
    //float amb = 0.5 * smoothstep(0.0, 2.0, p.y);
    
    vec3 col = diff * sunColor;
    col += spec * sunColor;
    col += sky * vec3(0., .6, 1.) * .1;
    //col += amb * .2;
    
   	return col;
}

mat3 lookAt(vec3 origin, vec3 target, float roll)
{
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));

    return mat3(uu, vv, ww);
}

vec3 camerapath(float t)
{
    vec3 p=vec3(-13.0+3.5*cos(t),3.3,-1.1+2.4*cos(2.4*t+2.0));
	return p;
}

#define rot(spin) mat2(cos(spin),sin(spin),-sin(spin),cos(spin))

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
	
    vec3 lightDir = normalize(vec3(0., 1., -1.));
    
    vec3 camStep = vec3(-1., 0., 0.) * (iTime+12.)/8.;
    vec3 camPos = vec3(8., 2., 5.+sin(iTime/2.)/4.) + camStep;
    vec3 camTarget = vec3(1., 1., 4.) + camStep;

    
    mat3 mat = lookAt(camPos, camTarget, 0.0);
    
    vec3 ro = camPos;
    ro.y += fbm(ro.xz,OCTAVES)/2.-1.6;

    vec3 rd = normalize(mat * vec3(uv.xy, 1.0));
        
    if (length(iMouse.xy) > 40.0) {
        rd.yx *= rot(3.14*0.5-iMouse.y/iResolution.y*3.14);
        rd.xz *= rot(3.14-iMouse.x/iResolution.x*3.14*2.0);
    }

    
    float tMin = .1;
    float tMax = 20.;
    float t = rayMarching(ro, rd, tMin, tMax);
    
    vec3 col = vec3(0.);
    
    if (t > tMax)
    {
        // from iq's shader, https://www.shadertoy.com/view/MdX3Rr
        float sundot = clamp(dot(rd, lightDir), 0.0, 1.0);
        col = vec3(0.3,0.5,0.85) - rd.y*rd.y*0.5;
        col = mix( col, 0.85*vec3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
        // sun
		col += 0.25*vec3(1.0,0.7,0.4)*pow( sundot,5.0 );
		col += 0.25*vec3(1.0,0.8,0.6)*pow( sundot,64.0 );
		col += 0.2*vec3(1.0,0.8,0.6)*pow( sundot,512.0 );
        // clouds
		vec2 sc = ro.xz + rd.xz*(SC*1000.0-ro.y)/rd.y;
		col = mix( col, vec3(1.0,0.95,1.0), 0.5*smoothstep(0.5,0.8,fbm(0.0005*sc/SC)) );
        // horizon
        col = mix( col, 0.68*vec3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
    }
    else
    {
        vec3 p = ro + rd * t;
        vec3 normal = getNormal(p, t);
        vec3 viewDir = normalize(ro - p);
        
        // lighting terrian
        col = lighting(p, normal, lightDir, viewDir);
        
        // fog
        float fo = 1.0-exp(-pow(30. * t/SC,1.5) );
        vec3 fco = 0.65*vec3(0.4,0.65,1.0);
        col = mix( col, fco, fo);
    }
    
    // Gama correction
    col = pow(clamp(col, 0., 1.), vec3(.45)); 
    
    fragColor = vec4(vec3(col), 1.0);
}