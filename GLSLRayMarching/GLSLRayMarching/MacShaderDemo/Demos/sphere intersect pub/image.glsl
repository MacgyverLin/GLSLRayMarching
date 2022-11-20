#define float3 vec3
#define float3x3 mat3

const float MAX_RAY_LENGTH=1e4;

float RSph(float3 p0, float r, float3 rp0, float3 rd)
{
    float t = 0.;
	float3 l=p0-rp0;
	float tc=dot(l,rd);
	if(tc<0.0)
    {
        t=MAX_RAY_LENGTH;
        return t;
    };

    float d2=r*r+tc*tc-dot(l,l);

	if(d2<0.0)
    {
        t=MAX_RAY_LENGTH;
        return t;
    };

	float thc=sqrt(d2);
    t=tc-thc;
    return t;
}

float cube(float3 ray, float3 dir, float3 bmin, float3 bmax) {
    vec3 ddir = 1.0 / dir;
    vec3 t1 = (bmin - ray) * ddir;
    vec3 t2 = (bmax - ray) * ddir;
    vec3 tmin = vec3(min(t1.x, t2.x), min(t1.y, t2.y), min(t1.z, t2.z));
    vec3 tmax = vec3(max(t1.x, t2.x), max(t1.y, t2.y), max(t1.z, t2.z));
    float tmin_max = max(tmin.x, max(tmin.y, tmin.z));
    float tmax_min = min(tmax.x, min(tmax.y, tmax.z));
    return tmax_min >= tmin_max ? tmin_max : -1.0;
}

vec3 background(float t, vec3 rd)
{
    vec2 pos = (rd.xy +vec2(3.2,0.7))* vec2(0.55,0.55);
    vec3 tex =  vec3(texture(iChannel0, pos));

//	vec3 light = normalize(vec3(3.14-((uSize.x/uTouch.x)*2.0), -0.5+(uSize.y/uTouch.y), -1.0));
    vec3 light = normalize(vec3(2.0, 1.5, (cos(t))));
	float sun = max(0.0, -dot(rd, light));

    vec3 light2 = normalize(vec3((sin(t/2.0)), 0.7, -abs(cos(t/2.0))));
    float sun2 = max(0.0, -dot(rd+vec3(0.0,-0.0,0.01), light2));

    vec3 light3 = normalize(vec3((cos(t/2.0)), -0.5, -abs(cos(t/2.0))));
    float sun3 = max(0.0, -dot(rd+vec3(0.0,-0.1,0.06), light3));

    float sky = max(0.0, dot(rd, vec3(1.0, 0.0, 0.0)));
	float ground = max(0.0, -dot(rd, vec3(1.0, 0.0, 0.0)));

    tex = vec3(0.0);
    vec3 outcolor =  (pow(sun, 256.0)+0.1*pow(sun, 1.0)+pow(sun2, 256.0)+0.2*pow(sun2, 1.0)+pow(sun3, 256.0))*vec3(1.0, 0.1, 0.1)+(tex.rgb / 4.0);

    if (length(rd.xy) < 0.7)
    {
    }

    return outcolor;
    }


// rendering params
const float sphsize=.7; // planet size
const float dist=.27; // distance for glow and distortion
const float perturb=.3; // distortion amount of the flow around the planet
const float displacement=.015; // hot air effect
const float windspeed=.4; // speed of wind flow
const float steps=15.; // number of steps for the volumetric rendering
const float stepsize=.025; 
const float brightness=.43;
const vec3 planetcolor=vec3(0.55,0.4,0.3);
const float fade=.005; //fade by distance
const float glow=3.5; // glow amount, mainly on hit side

const int iterations=14; 
const float fractparam=.7;
const vec3 offset=vec3(1.5,2.,-1.5);

float wind(vec3 p) {
	float d=max(0.,dist-max(0.,length(p)-sphsize)/sphsize)/dist; // for distortion and glow area
	float x=max(0.2,p.x*2.); // to increase glow on left side
	p.y*=1.+max(0.,-p.x-sphsize*.25)*1.5; // left side distortion (cheesy)
	p-=d*normalize(p)*perturb; // spheric distortion of flow
	p+=vec3((iTime/4.0)*windspeed,0.,0.); // flow movement
	p=abs(fract((p+offset)*.1)-.5); // tile folding 
	for (int i=0; i<iterations; i++) {  
		p=abs(p)/dot(p,p)-fractparam; // the magic formula for the hot flow
	}
	return length(p)*(1.+d*glow*x)+d*glow*x; // return the result with glow applied
}


float snow(vec2 uv)
{
        vec3 dir=vec3(-uv,1.0);
		vec3 tex3=vec3(0.0);

        vec3 from = vec3(0.0,0.0,1.0);

        float v=0., l=-0.0001;
        float t=0.1*windspeed*0.2;

        for (float r=8.0; r<steps; r++) {
            vec3 p=from+r*dir*stepsize;
            v+=min(50.,wind(p))*max(0.,1.-r*fade);
            
//            vec2 pol = vec2((cos(p.x),sin(p.y)*v));
            vec2 pol = vec2((p.x+iTime/6.0),(p.y));
            
            tex3 = vec3(texture(iChannel0, vec2(pol.x,pol.y)*2.5));
            }

        v/=steps; v*=brightness;
        
    
        return v*(tex3.r*(2.5+sin(iTime)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;

     // camera movement	
//	float an = 0.5*iTime;
    float an = 1.5*1.;
	vec3 ro = vec3( 2.5*cos(an), 0., 2.5*sin(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(iTime)/8.,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

	
    vec3 tex3 =  vec3(texture(iChannel0, rd.xy+sin(iTime)));
    tex3 =  vec3(texture(iChannel0, vec2(rd.x+(iTime/4.), rd.y)));

	// raytrace-plane
    float t = 1e4;
    t = RSph(vec3(0. + cos(iTime) / 6.,0.,0.0 + sin(iTime) / 10.), 1.40 - ((tex3.r) * 0.05), ro, rd);
//	t = cube(ro, rd, vec3(0.01,0.01,0.1), vec3(1.0,1.0,1.0-tex3.r));

	vec3 nml = normalize(vec3(0.0) - (ro+rd*t));
	rd = reflect(-rd, nml* 1.0);
    
    // shading/lighting	
	vec3 col = vec3(0.0);

	
	
	col = background(iTime, rd) * vec3(0.9, 0.8, 1.0) * 2.6;
//    col -= background(iTime - 2.0, rd - vec3(0,-0.03,0.0)) * vec3(0.9, 0.8, 1.0);
//    col = sqrt( col );
    
    rd = reflect(-rd, nml);
    
   	// get ray dir	
	vec2 uv = nml.xy;
	vec3 dir=vec3(uv,1.);
//	dir.x*=iResolution.x/iResolution.y;

    
    
    float snoise = (snow(vec2(uv.x,uv.y)));
    
    if((iTime > 30.0)){
    	col.b += snoise * abs(cos(iTime / 15.0)/1.0);
    }
    else{
        col += snoise * abs(sin(iTime / 5.0)/2.5);
    }    
    
    
    if (length(nml.xy+vec2(0.0,0.0)) < 0.95)
    {
        if (t > 10.01)
        {
            col = vec3(0.0,0.0,0.0);
//            col = vec3(1.0,1.0,1.0)*snoise;
        }
    }
    

    if (t < 10.0+sin(iTime))
    {
//    	snoise = (snow(nml.xy));
    	col.r += snoise;
    }

    
    
    if (length(nml.xy+vec2(-0.5,0.0)*(snoise/1.0)) < 0.55)
    {
        if (t > 2.71)
        {
//            col = tex3 + (col.rgb / 4.);
            col.r = snoise*2.0;
        }
    }
    
	fragColor = vec4( col, 1.0 );
//    fragColor = vec4( mix(col, col, step(0.0, t)), 1.0 );
}