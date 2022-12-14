// TURBULENCES //////////////////////////////////////////////////////////////////////////
vec2 hash( vec2 p ) {
	p = vec2( dot(p,vec2(127.1,311.7)),
			  dot(p,vec2(269.5,183.3)) );

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(in vec2 p) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

        vec2 i = floor( p + (p.x+p.y)*K1 );
        
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = step(a.yx,a.xy);    
    vec2 b = a - o + K2;
        vec2 c = a - 1.0 + 2.0*K2;

    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );

    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));

    return dot( n, vec3(70.0) );
}

float ridged(in vec2 p) {
    //r(p) = 2(0.5 −|0.5 −n(p)|)
    return 2.*(0.5 - abs(0.5 - noise(p)));
}

float turbulence(in vec2 p, in float amplitude, in float fbase, in float attenuation, in int noctave, in bool useRidged) {
    int i;
    float res = .0;
    float f = fbase;
    for (i=0;i<noctave;i++) {
        if (useRidged) {
            res = res+amplitude*ridged(f*p);
        } else {
            res = res+amplitude*noise(f*p);
        }
        amplitude = amplitude*attenuation;
        f = f*2.;
    }
    return res;
}

// TRANSFORMATIONS //////////////////////////////////////////////////////////////////////

// Rotation matrix around the X axis.
mat3 xRotationMat(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

// Rotation matrix around the Y axis.
mat3 yRotationMat(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

// Rotation matrix around the Z axis.
mat3 zRotationMat(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

// UTILITAIRES //////////////////////////////////////////////////////////////////////

vec2 identifyMin(float a, float b, float c) {
    float m = min(min(a, b), c);
    if (m == a) return vec2(m, 0.);
    if (m == b) return vec2(m, 1.);
    if (m == c) return vec2(m, 2.);
}

vec2 identifyMin(float a, float b, float c, float d) {
    vec2 im = identifyMin(a, b, c);
    if (min(im.x, d) == d) return vec2(d, 3.);
    return im;
}

// RAY MARCHING //////////////////////////////////////////////////////////////////////

//// SETTINGS

const int Steps = 1000;
const float Epsilon = 0.001;
const float T=1.;

const float rA=5.0;
const float rB=200.0; 

const float PI = 3.14;

float time() {
    return iTime+10.;
}

//// SDFs

vec3 camPos() {
    return vec3(-10., 8., 0.);
}

float sdfRelief(vec3 p) {
    return p.y - turbulence(p.xz+vec2(120.), 5.5, 0.02, 0.38, 9, true);
}

float sdfMer(vec3 p) {
    float level = -0.0;
    return p.y - level - (
        turbulence(p.xz+vec2(time()*0.8), 0.01, 1., 0.2, 1, false) +
        turbulence(p.xz+vec2(10.)+vec2(time(), -time()), 0.01, 1., 0.2, 1, false)
    );
}

float sdfSky(float dO) {
    return rB - dO;
}

vec3 sunPos() {
    return zRotationMat(time()/20. * 2. * PI)/*yRotationMat(time() * 2. * PI) 
        * zRotationMat(0.4*PI)*/
        * vec3(0., rB, 0.) + camPos();
}

float sdfSun(vec3 p) {
    return distance(p, sunPos()) - 5.;
}

vec2 object(vec3 p, float dO) {
    return identifyMin(
        sdfRelief(p),
        sdfMer(p),
        sdfSky(dO),
        sdfSun(p)
    );
} 

vec3 objectNormal(vec3 p, float dO) {
   float eps = Epsilon;
   vec3 n;
   float v = object(p, dO).x;
   n.x = object(vec3(p.x+eps, p.y, p.z), dO+eps).x - v;
   n.y = object(vec3(p.x, p.y+eps, p.z), dO+eps).x - v;
   n.z = object(vec3(p.x, p.y, p.z+eps), dO+eps).x - v;
   return normalize(n);
}

vec2 Trace(vec3 ro, vec3 rd)
{
    float id = 10.;
    float dO = rA;
    int s;

    for(s = 0; s < Steps; s++) {
       vec3 p = ro+dO*rd;

       vec2 obj = object(p, dO);
       float ds = obj.x;
       id = obj.y;

       dO += ds*T;

       if (ds < Epsilon) {
           break;
       }

       if (dO > rB) break;
    }

    return vec2(dO, id);
}

float sunOscilator() {
    // 1. at midnight -> 0. at noon
    return 0.5+cos(time()/20.*2.*PI)*0.5;
}

vec3 lightColor() {
    vec3 zenithColor = vec3(1., 0.95, 0.9);
    vec3 coucherColor = vec3(0.7, 0.3, 0.5);
    vec3 moonlightColor = vec3(0.2, 0.2, 0.25);
    return mix(mix(
        moonlightColor,
        coucherColor,
        smoothstep(0.45, 0.55, sunOscilator())
    ),
        zenithColor,
        smoothstep(0.5, 0.85, sunOscilator())
    );
}

void phong(vec3 p, vec3 n, inout vec3 c, float reflectAmount) {
    vec3 cws = c;
    vec3 pL = p + vec3(0., 0.1, 0.);
    vec3 rd = normalize(sunPos() - pL);

    float obstacle = Trace(pL, rd).y;
    vec3 shadowColor = vec3(0.078, 0.047, 0.109);
    if (obstacle == 1. || obstacle == 0.) {
        cws = mix( // OMBRE PAR BLOCAGE
            cws,
            shadowColor,
            0.95
        );
    } else {
        cws = mix( // OMBRE PAR DOT PRODUCT
            cws,
            shadowColor,
            1.-clamp(dot(n, rd), 0.05, 1.)
        );
        
        cws = mix( // REFLECTION DE PHONG
            cws,
            lightColor(),
            smoothstep(0.995, 1., dot(n, rd))*reflectAmount
        );
    }
    
    c = mix(c, cws, smoothstep(0.4, 0.6, sunOscilator()));
}

vec3 shadeSky(vec3 p, vec3 rd, float dO) {
    vec3 c = mix(mix(
        vec3(0.8, 0.9, 0.99), // ATHMOSPHERE
        vec3(0.45, 0.78, 1.),
        smoothstep(10., 50., p.y)
    ),
        lightColor()*4., // SUN
        smoothstep(-0.2, 2., 1.-dot(rd, p-sunPos()))
    );
    
    c *= lightColor();
    
    // STARS
    vec3 n = normalize(p - camPos());
    float a1 = mix(
        0.,
        turbulence(n.xz*100., 1.4, 0.5, 0.6, 1, false),
        smoothstep(0., 60., distance(camPos().y, p.y))
    );
    vec3 cws = mix(
        c,
        vec3(0.9, 0.9, 0.85),
        smoothstep(0.8, 1.9, a1)
        *(1.-smoothstep(0.5, 0.85, sunOscilator()))
    );
    
    // PLANET
    if(rd.z > 0.9 ){
        float rand = turbulence(p.xy, 3., 0.05, 1., 4, false);
        vec3 pColor = vec3(0.5,0.3,0.4);
        c = mix(mix(
            c,
            pColor * vec3(0.8, 0.8, 0.9),
            smoothstep(-0.5, 0.3, rd.x+rd.y)
        ),
            pColor,
            smoothstep(0., 1., rd.x+rd.y)
        );
    } else {
        c = cws;
    }
    
    // CLOUDS

    return c;
}

void shadeFog(vec3 p, float dO, inout vec3 c) {
    c = mix( // BOTTOM FOG
        c,
        vec3(0.45, 0.78, 1.)*lightColor(),
        (1.-smoothstep(-1., 3., p.y))*0.3
    );
    
    c = mix( // DISTANCE FOG
        c,
        vec3(0.807, 0.917, 0.992)*lightColor(),
        smoothstep(rB*0.5, rB*0.9, dO)*0.3
    );
}

vec3 shadeRelief(vec3 p, vec3 n, float dO) {
    float rand = turbulence(p.xz, 3., 0.5, 0.5, 10, false);
    float randY = p.y+(rand/40.);
    
    vec3 c = mix(mix(mix(mix(
        vec3(0.55,0.52,0.48), // DIRT
        vec3(0.35, 0.5, 0.45), // GRASS
        smoothstep(0.1, 0.5, randY)
        * smoothstep(0.7, 0.9, dot(n, vec3(0., 1., 0.)))
    ),
       vec3(0.45, 0.55, 0.5), // GRASS 2
       smoothstep(0.5, 1., randY)
       * smoothstep(0.8, 0.95, dot(n, vec3(0., 1., 0.)))
    ),
       vec3(0.8,0.8,0.85), // SNOW
       smoothstep(3., 3.6, randY)
       * smoothstep(0.85, 1., dot(n, vec3(0., 1., 0.)))
    ),
       vec3(0.7,0.7,0.6), // BEACH
       -smoothstep(0.1, 0.2, randY)
    );

    float crbNiv = smoothstep(0.9, 1., sin(p.y*20.))/(dO*0.1);
    c = mix(
        c,
        vec3(0.3, 0.3, 0.2),
        crbNiv
    );

    phong(p, n, c, 0.05);
    c *= lightColor();
    
    return c;
}

vec3 reflection(vec3 p, vec3 n, vec3 incRd) {
    vec3 rd = normalize(reflect(incRd, n));
    vec3 pL = p + rd*0.001;

    vec2 traceResult = Trace(pL, rd);
    float dO = traceResult.x;
    float id = traceResult.y;
    if (id == 1.) {
        return vec3(0.0,0.29,0.52);
    }

    vec3 rayFinalPos = pL+dO*rd;
    n = objectNormal(rayFinalPos, dO);
    
    vec3 reflC;
    if (id == 3.) {
        reflC = shadeSky(rayFinalPos, rd, dO);
    } else if (id == 2.) {
        reflC = shadeSky(rayFinalPos, rd, dO);
    } else {
        reflC = shadeRelief(rayFinalPos, n, dO);
    }
    
    shadeFog(rayFinalPos, dO, reflC);

    return reflC;
}

vec3 shadeSea(vec3 p, vec3 n, vec3 rd) {
    vec3 c = reflection(p, n, rd);
    
    float sdfRelief = sdfRelief(p);
    
    // DEEP WATERS
    c = mix(c, vec3(0., 0., 0.1), sdfRelief*0.04);
    
    // COASTAL WATERS
    float coastDistAtt = clamp(1.-sdfRelief*2., 0., 1.);
    float coastWaves = smoothstep(0., 1., sin(coastDistAtt*15.-time()*3.));
    c = mix(
        c,
        vec3(1.),
        coastDistAtt*coastWaves
    );

    phong(p, n, c, 0.6);
    c *= lightColor();
    
    return c;
}

vec3 Shade(vec3 p, vec3 n, vec3 rd, float dO, float id)
{
    vec3 c;
    if (id == 3.) {
        c = shadeSky(p, rd, dO);
    } else if (id == 2.) {
        c = shadeSky(p, rd, dO);
    } else if (id == 1.){
        c = shadeSea(p, n, rd);
    } else {
        c = shadeRelief(p, n, dO);
    }
    
    shadeFog(p, dO, c);

    return c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pixel = (gl_FragCoord.xy / iResolution.xy)*2.0-1.0;
    float aspectRatio = iResolution.x / iResolution.y;
    vec4 mouse = iMouse / iResolution.x;

    vec3 camPos = camPos();
    float camAngleY = -0.15*PI+mouse.x*-2.*PI;
    float camAngleX = ((mouse.y)*1.2*PI) - 0.3*PI;

    vec3 ro = vec3(0., 0., 0.);
    vec3 rd = vec3(aspectRatio*pixel.x, pixel.y, 1.5);

    ro = camPos;
    rd = (yRotationMat(camAngleY) * xRotationMat(camAngleX) * rd);
    rd = normalize(rd);

    vec2 traceResult = Trace(ro, rd);
    float dO = traceResult.x;
    float id = traceResult.y;

    vec3 rayFinalPos = ro+dO*rd;
    vec3 n = objectNormal(rayFinalPos, dO);
    vec3 rgb = Shade(rayFinalPos, n, rd, dO, id);

    fragColor=vec4(rgb, 1.0);
}