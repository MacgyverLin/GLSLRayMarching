//#define MOVE_CAMERA
#define SAMPLES 2 // renders per frame
#define S smoothstep

// materials indices
#define ROUGH 1 // metal and lambertian
#define DIELECTRIC 2 // glass

float seed; // randoms seed

// hash functions by me
float hash1() {return fract(sin(seed+=.1)*4561.7564);}

vec2 hash2() {return fract(sin(seed+=.1)*vec2(8472.5636,9854.4213));}

vec3 hash3() {return fract(sin(seed+=.1)*vec3(7653.1285,6912.8512,5914.7134));}

// random normalized vector
vec3 uniformVector() {
    vec3 v = hash3()*2.-1.;
    return normalize(v);
}

// sphere intersection function
// thanks to iq: https://iquilezles.org/articles/intersectors/
float sphIntersect(vec3 ro, vec3 rd, vec3 ce, float ra, vec3 mat, int type, vec2 v,
                   float tmax, inout vec3 outn, inout vec3 outmat, inout int outtype, inout vec2 outv) {
    vec3 oc = ro - ce;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - ra*ra;
    float h = b*b - c;
    if (h<0.) return tmax;
    
    h = sqrt(h);
    float t1 = -b - h;
    float t2 = -b + h;
    float t = t1<.0001 ? t2 : t1;
    if (t>.0001 && t<tmax) {
        outn = (oc + rd*t)/ra;
        outmat = mat;
        outtype = type;
        outv = v;
        return t;
    }
    return tmax;
}

// plane intersection function
// thanks to iq: https://iquilezles.org/articles/intersectors/
float plaIntersect(vec3 ro, vec3 rd, vec3 n, float h, vec3 mat, int type, vec2 v, 
                   float tmax, inout vec3 outn, inout vec3 outmat, inout int outtype, inout vec2 outv) {
    float t = (h-dot(n,ro))/dot(rd,n);
    if (t>.0001 && t<tmax) {
		outn = n;
        vec3 p = ro + rd*t;
        outmat = pow(texture(iChannel2, p.xz*.5).rgb,vec3(2.2)); // wood texture
        outtype = type;
        outv = v;
	    return t;
    }
    return tmax;
}

// torus sdf
float sdTorus(vec3 p, float ra, float rb) {
    return length(vec2(length(p.xz)-ra,p.y))-rb;
}

float sdBox(vec3 p, vec3 s) {
    return length(max(abs(p)-s,0.));
}

// full torus sdf
float sdTorusF(vec3 p, float ra, float rb) {
    return length(max(vec2(length(p.xz)-ra,p.y),0.))-rb;
}

// glass curve
// https://www.desmos.com/calculator/u9oxcvjhqp
float glassCurve(float x) {
    return .3*S(.95,1.,x)+.35*S(.56,.4,x)*S(-1.3,.4,x);
}

// glass sdf
float sdGlass(vec3 p) {
    p.y -= 1.;
    float h = clamp(-p.y*0.6779661017, 0., 1.);
    return sdTorus(p + vec3(0,1.475,0)*h, glassCurve(h), .02);
}

// full glass sdf
float sdGlassF(vec3 p) {
    p.y -= 1.;
    float h = clamp(-p.y*0.6779661017, 0., 1.);
    return sdTorusF(p + vec3(0,1.475,0)*h, glassCurve(h)-.022, 0.);
}

// bottle curve
// https://www.desmos.com/calculator/nftvjzacqh
float bottleCurve(float x) {
    return .07+.12*pow(S(.2,.57,x),1.2);
}

// bottle sdf
float sdBottle(vec3 p) {
    p.y -= 1.;
    float h = clamp(-p.y*0.6779661017, 0., 1.);
    return sdTorus(p + vec3(0,1.475,0)*h, bottleCurve(h), .025);
}

// full bottle sdf
float sdBottleF(vec3 p) {
    p.y -= 1.;
    float h = clamp(-p.y*0.6779661017, 0., 1.);
    return sdTorusF(p + vec3(0,1.475,0)*h, bottleCurve(h)-.027, 0.);
}

// materials indices
#define MAT_GLASS 0.
#define MAT_BOTTLE 1.
#define MAT_WINE 2.

// union of two objects
vec2 opU(vec2 a, vec2 b) {return a.x<b.x ? a : b;}

// scene sdf
vec2 map(vec3 p) {
    vec2 d = vec2(1e10);

    // wine
    d = opU(d, vec2(max(sdGlassF(p*.5),abs(p.y-1.15+.4)-.4), MAT_WINE));
    d = opU(d, vec2(max(sdGlassF(p*.5-vec3(1.4,0,.2)),abs(p.y-1.08+.4)-.4), MAT_WINE));
    d = opU(d, vec2(max(sdBottleF((p-vec3(-1.8,.975,1.7))*.25),abs(p.y-1.5+1.2)-1.2), MAT_WINE));    

    // glasses
    d = opU(d, vec2(sdGlass(p*.5)*.5, MAT_GLASS));
    d = opU(d, vec2(sdGlass(p*.5-vec3(1.4,0,.2))*.5, MAT_GLASS));
        
    // bottle
    d = opU(d, vec2(sdBottle((p-vec3(-1.8,.975,1.7))*.25), MAT_BOTTLE));
        
    return d;
}

vec3 calcNormal(vec3 p) {
    float h = map(p).x;
    const vec2 e = vec2(.0001,0);
    
    return normalize(h - vec3(map(p-e.xyy).x,
                              map(p-e.yxy).x,
                              map(p-e.yyx).x));
}

// raymarching loop
float raymarch(vec3 ro, vec3 rd, float tmax, inout vec3 outn, inout vec3 outmat, inout int outtype, inout vec2 outv) {
    float t; // distance
    float s = sign(map(ro).x); // inside and outside the surface
    vec2 h; // scene sdf + material idx;
    
    float ttmax = tmax;
    tmax = min(tmax, 16.);
    
    for (int i=0; i<256 && t<tmax; i++) {
        vec3 p = ro + rd*t;
        h = map(p); h.x *= s;
        if (abs(h.x)<.0001) break;
        t += h.x;
    }
    
    if (t>.0001 && t<tmax) {
        vec3 p = ro + rd*t; // hit point
        outn = calcNormal(p);
        outtype = DIELECTRIC;
        
        if (h.y==MAT_GLASS) { // glass
            outmat = vec3(.99);
            outv = vec2(1.5,0); // ior 1.5
        } else if (h.y==MAT_BOTTLE) { // bottle
            outmat = vec3(.2,.7,.2);
            outv = vec2(1.4,0); // ior 1.4
        } else if (h.y==MAT_WINE) { // wine
            outmat = vec3(.15,0,0);
            outv = vec2(1.3,0); // ior 1.3
        }
        return t;
    }
    return ttmax;
}

// scene intersection function
// n is the normal, mat is the object albedo, type is the material type
// v is the material propreties: 
//  ROUGH -> rougness and reflectance
//  DIELECTRIC -> refraction index
float intersect(vec3 ro, vec3 rd, out vec3 n, out vec3 mat, out int type, out vec2 v) {
    float t = 1e10;
    
    t = plaIntersect(ro, rd, vec3(0,1,0), -1., vec3(1), ROUGH, vec2(1,-.5), t, n, mat, type, v);
    
    t = sphIntersect(ro, rd, vec3(-.1,-.5,-1), .5, vec3(1), DIELECTRIC, vec2(1.5,0), t, n, mat, type, v);
    t = sphIntersect(ro, rd, vec3(1.1,-.5,-1), .5, vec3(.2,.5,1), ROUGH, vec2(1,.03), t, n, mat, type, v);
    t = sphIntersect(ro, rd, vec3(-1.9,-.55,-.6), .45, vec3(1,.3,.1), ROUGH, vec2(1,.05), t, n, mat, type, v);
    t = sphIntersect(ro, rd, vec3(1,-.55,-2.65), .45, vec3(1,.4,.2), ROUGH, vec2(0,-1e10), t, n, mat, type, v);
    t = sphIntersect(ro, rd, vec3(1.5,-.5,3), .5, vec3(.6,.4,.7), DIELECTRIC, vec2(1.4,0), t, n, mat, type, v);
        
    t = raymarch(ro, rd, t, n, mat, type, v);
  
    return t;
}

// diffuse BRDF
vec3 cosineDirection(vec3 n) {
  	vec2 r = hash2();
    
	vec3 u = normalize(cross(n, vec3(0,1,1)));
	vec3 v = cross(u, n);
	
	float ra = sqrt(r.y);
	float rx = ra*cos(2.*3.141592*r.x); 
	float ry = ra*sin(2.*3.141592*r.x);
	float rz = sqrt(1.-r.y);
	return normalize(rx*u + ry*v + rz*n);
}

// rendering function
vec3 render(vec3 ro, vec3 rd) {
    vec3 col = vec3(1);
    
    for (int i=0; i<12; i++) { // ray bounces
        vec3 n, mat; int type; vec2 v;
        float t = intersect(ro, rd, n, mat, type, v);
        if (t>=1e10) {
            // hdr skybox
            vec3 sky = pow(texture(iChannel1, rd).rgb,vec3(4));
            sky = 10.*pow(sky,vec3(.9,.9,1));
            return col*sky;
        } else {
            vec3 p = ro + rd*t; // hit point
            ro = p;
            
            float fre = dot(rd, n); // fresnel
            if (type==ROUGH) {
                vec3 rd0 = reflect(rd, n); // reflected ray
                vec3 rd1 = cosineDirection(n); // diffuse ray
                
                float refProb = v.y + (1.-v.y)*pow(1.+fre, 5.);
                if (hash1()<refProb) {
                    rd = rd0;
                } else {
                    rd = normalize(mix(rd0, rd1, v.x));
                    col *= mat;
                }
            } else if (type==DIELECTRIC) { // transparent
                float cosine;
                if (fre>0.) {
                    cosine = sqrt(1.-v.x*v.x*(1.-fre*fre));
                } else {
                    cosine = -fre;
                }
                float s = sign(fre);
                vec3 m = -n*s;
                float i = (.5-.5*s)/v.x+v.x*(.5+.5*s);
    
                fre = dot(rd, m);
                
                float refProb;
                // reflected and refracted ray
                vec3 rd1, rd0 = reflect(rd, n);
                
                float h = 1.-i*i*(1.-fre*fre);
                if (h>0.) {
                    rd1 = i*(rd - m*fre) - m*sqrt(h); // refraction
                    
                    float r0 = (1.-v.x)/(1.+v.x);
                    r0 = r0*r0;
                    refProb = r0 + (1.-r0)*pow((1.-cosine),5.);
                } else {
                    refProb = 1.;
                }
        
                if (hash1()<refProb) {
                    rd = rd0;
                } else {
                    ro -= m*.0009; // bump the point
                    rd = rd1;
                    col *= mat;
                }
            }
        }
    }
    return vec3(0); // return black if the ray stops
}

// camera function
mat3 setCamera(vec3 ro, vec3 ta) {
	vec3 w = normalize(ta - ro);
	vec3 u = normalize(cross(w, vec3(0,1,0)));
	vec3 v = cross(u, w);
    return mat3(u, v, w);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 tot = vec3(0);
    for (int i=0; i<SAMPLES; i++) {
    // init randoms seed
    seed = float(i)+iTime+dot(sin(fragCoord),vec2(443.712,983.234));
    seed += hash1()*434.251;
    
    vec2 of = hash2()-.5; // AA offset
    vec2 p = (fragCoord+of - .5*iResolution.xy) / iResolution.y;
    
    #ifdef MOVE_CAMERA
    float an = (-iMouse.x/iResolution.x-.5)*3.141592;
    vec3 ro = vec3(8.*sin(an), iMouse.y/iResolution.y*4.-2., 8.*cos(an)); // camera position
    #else
    vec3 ro = vec3(8.*sin(3.8), .3, 8.*cos(3.8)); // camera position
    #endif
    vec3 ta = vec3(0,.5,0); // target
    mat3 ca = setCamera(ro, ta); // camera matrix
    vec3 rd = ca * normalize(vec3(p,1.78)); // ray direction
    
    // depth of field
    vec3 n, mat; int type; vec2 v;
    float t = intersect(ro, normalize(ta - ro), n, mat, type, v);
    vec3 fp = ro + rd*t; // focus plane
    ro += uniformVector()*.12; // <- change this value for the aperture
    rd = normalize(fp - ro);

    vec3 col = render(ro, rd);

    tot += col;
    }
    tot /= float(SAMPLES);
    
    // accumulate
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    #ifdef MOVE_CAMERA
    if (iMouse.z>0.) data *= 0.;
    #endif
    data += vec4(tot,1);

    // output
    fragColor = data;
}