// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define R iResolution.xy
#define T mod(iTime, DURATION)

#define LIGHT1 vec4( 11.3, 0.0, 11.3, 5.0)
#define LIGHT2 vec4(-11.3, 0.0, 11.3, 6.0)  

float g_seed = 0.0;

//
// Hash functions by Nimitz:
// https://www.shadertoy.com/view/Xt3cDn
//

uint base_hash(uvec2 p) {
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}

float hash1(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    return float(n)/float(0xffffffffU);
}

vec2 hash2(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec2 rz = uvec2(n, n*48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU))/float(0x7fffffff);
}

vec3 hash3(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3(rz & uvec3(0x7fffffffU))/float(0x7fffffff);
}

//reinder    
vec2 randomInUnitDisk(inout float seed) {
    vec2 h = hash2(seed) * vec2(1.,6.28318530718);
    float phi = h.y;
    float r = sqrt(h.x);
	return r * vec2(sin(phi),cos(phi));
}

//reinder    
vec3 randomInUnitSphere(inout float seed) {
    vec3 h = hash3(seed) * vec3(2.,6.28318530718,1.)-vec3(1,0,0);
    float phi = h.y;
    float r = pow(h.z, 1./3.);
	return r * vec3(sqrt(1.-h.x*h.x)*vec2(sin(phi),cos(phi)),h.x);
}

//IQ - Intesectors, sphere and box functions
//https://iquilezles.org/www/index.htm
float sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
	vec3 oc = ro - sph.xyz;
	float b = dot(oc, rd);
	float c = dot(oc, oc) - sph.w*sph.w;
	float h = b*b - c;
	if (h<0.) return -1.0;
	return -b - sqrt(h);
}

float sphDensity(vec3 ro, vec3 rd, vec4 sph) {
    float ndbuffer = FAR/sph.w;
    vec3  rc = (ro - sph.xyz)/sph.w;
	
    float b = dot(rd,rc);
    float c = dot(rc,rc) - 1.0;
    float h = b*b - c;
    if( h<0.0 ) return 0.0;
    h = sqrt( h );
    float t1 = -b - h;
    float t2 = -b + h;

    if( t2<0.0 || t1>ndbuffer ) return 0.0;
    t1 = max( t1, 0.0 );
    t2 = min( t2, ndbuffer );

    float i1 = -(c*t1 + b*t1*t1 + t1*t1*t1/3.0);
    float i2 = -(c*t2 + b*t2*t2 + t2*t2*t2/3.0);
    return (i2-i1)*(3.0/4.0);
}

vec3 sphNormal(vec3 pos, vec4 sph) {
    return normalize(pos - sph.xyz);
}

vec4 uvWall(HitSphere sphere) {

    float AT = floor(T*0.1);
    
    //vec2 hash = hash22(sphere.id);
    vec3 q = sphere.p - sphere.c;
    
    float rep = 40.0;
    float hRep = 3.0;
    
    //left, right and rear walls
    vec3 o = q.xzy;
    if (sphere.id==3.0 || sphere.id==4.0) {
        //floor and ceiling
        o = q.yzx;
        rep = 80.0;
    }

    //panels
    float a = (atan(o.x, o.y) + PI)/PI*0.5;
    float ia = fract(a*rep);
    float t = step(ia, 0.94) * step(0.06, ia);    
    
    float h = mod(o.z, hRep) / hRep;
    t *= step(0.06, h) * step(h, 0.96);
    
    float id = hash12(AT+vec2(floor(a*rep), AT+floor(o.z/hRep)));
   
    //panel lights
    float lc = step(length(vec2(0.8) - vec2(ia, h)), 0.06) +
               step(length(vec2(0.2) - vec2(ia, h)), 0.06);
    
    float lt = length(vec2(0.5) - vec2(ia, h));
    
    return vec4(t, lc, id, lt);
}

vec3 uvFill(HitSphere sphere) {
    
    float h = mod(sphere.p.y, 4.0) / 4.0;
    float t = step(0.2, h) * step(h, 0.8);    
    t *= sin((sphere.p.y + T * .4) * 10.0) * 0.4 + 0.36;

    return vec3(1.0, t, 0.0);
}

void assignMaterial(inout HitSphere hit) {

    vec4 uvw = uvWall(hit);
    vec3 uvf = uvFill(hit);
    float atdl = step(0.8, uvw.z); //dotted light panel
    float atpl = step(uvw.z, 0.1) * step(16., T); //panel light
    vec3 panelColour = palette2(uvw.z*3.0);
    float lt = 1.0 / (1.0 + uvw.w*uvw.w*10.0);
    float roughness = max(0.02, 0.92 - T*0.0625);
    if (hit.id<5.0) {
        
        //WALL PANELS
        if (uvw.x>0.0) {
            
            //*
            if (atpl*(uvw.x-uvw.y)==1.0) {
                //wall panel light
                hit.mat = Material(PANEL_LIGHT, 
                                          panelColour, 
                                          panelColour * 2.0 * lt, 
                                          0.0);
            } else if (atdl*uvw.y==1.0) {    
                //wall panel dot light
                hit.mat = Material(DIFFUSE_LIGHT, 
                                   vec3(0.0), 
                                   panelColour * 2.0, 
                                   0.0);
            } else if (atdl*uvw.x==1.0) {    
                //wall panel
                hit.mat = Material(LAMBERTIAN, 
                                         panelColour, 
                                         vec3(0.0), 
                                         0.02);
            } else {
                //wall panel
                hit.mat = Material(LAMBERTIAN, 
                                         panelColour, 
                                         vec3(0.0), 
                                         roughness);
            }

        }
    } else if (hit.id==5.0 || hit.id==6.0) {
        
        //SIDE FILLS
        if (uvf.y>0.0) {
            //wall fill light
            hit.mat = Material(DIFFUSE_LIGHT, 
                                  vec3(0.0), 
                                  vec3(1.0,0.9, 0.6)*uvf.y, 
                                  1.0);
        } else {
            //wall fill
            hit.mat = Material(LAMBERTIAN, 
                                  vec3(0.0), 
                                  vec3(0.0), 
                                  1.0);
        }
    } else {
        
        vec3 ballCol = mix(vec3(1), 
                           palette1(hit.id-6.0/2.0), 
                           clamp(T*0.5-5., 0.0, 1.0));
        ballCol = mix(ballCol, 
                      vec3(1), 
                      clamp(T*0.5-25., 0.0, 1.0));
        
        //animated sphere
        hit.mat = Material(METAL, 
                           ballCol, 
                           vec3(0.0), 
                           0.02);
    }
}

bool materialScatter(
        Ray rayIn, 
        HitSphere sphere, 
        inout Ray scattered) {

    if (sphere.mat.type==LAMBERTIAN) {
        vec3 rd = reflect(rayIn.d, sphere.n);
        scattered = Ray(sphere.p, normalize(rd + sphere.mat.v*randomInUnitSphere(g_seed)*0.3));
        return true;        
    } else if (sphere.mat.type==METAL) {
        vec3 rd = reflect(rayIn.d, sphere.n);
        scattered = Ray(sphere.p, normalize(rd + sphere.mat.v*randomInUnitSphere(g_seed)));
        return true;        
    } else if (sphere.mat.type==PANEL_LIGHT) {
        vec3 rd = reflect(rayIn.d, sphere.n);
        scattered = Ray(sphere.p, normalize(rd + sphere.mat.v*randomInUnitSphere(g_seed)*0.3));
        return false;        
    }

    return false;
}

bool traceScene(Ray ray, inout HitSphere ns) {
    
    bool hit = false;
    
    for (int i=0; i<NBALLS; i++) {
        vec4 sphere = load(iChannel1, R, i, POS);
        float si = sphIntersect(ray.o, ray.d, sphere);
        if (si>0.0 && si<ns.t) {
            //nearest sphere so far
            //do all the surface calcs here as it's only a small scene
            hit = true;
            vec3 p = ray.o + ray.d*si;
            ns = HitSphere(si,
                           p,
                           sphNormal(p, sphere),
                           sphere.xyz, 
                           sphere.w, 
                           float(i), 
                           MISS_MATERIAL);     
            assignMaterial(ns);
        }
    }

    return hit;
}

vec3 fillLight(vec4 light,
              vec3 lightCol,
              Ray ray,
              HitSphere hit) {
 
    vec3 colour = vec3(0);
    
    vec3 lightDir = normalize(light.xyz - hit.p);
    vec3 fuzzyLightDir = normalize(light.xyz + 0.6*randomInUnitSphere(g_seed) - hit.p);
    lightDir.y *= 0.3;
    fuzzyLightDir.y *= 0.3;
    
    float lightDist = length(light.xyz - hit.p);
    float diffuse = max(0.05, dot(lightDir, hit.n));
    float atten = 1.0 / (1. + lightDist*lightDist*0.1);
    float spec = pow(max(dot(reflect(-fuzzyLightDir, hit.n), -ray.d), 0.0), 16.);
    float fre = pow(clamp(dot(ray.d, hit.n) + 1.0, 0.0, 1.0), 32.0);

    colour = hit.mat.albedo * lightCol * diffuse * atten;
    colour += lightCol * (spec+fre) * atten;
    
    float sh = 1.0;
    HitSphere shadowHit = HIT_MISS;
    Ray shadowRay = Ray(hit.p + hit.n*EPS, fuzzyLightDir); 
    if (traceScene(shadowRay, shadowHit)) {
        if (shadowHit.id!=light.w) {
            sh =  0.0;
        } else {
            if (length(shadowHit.mat.emit)==0.0) sh = 0.0;
        }
    }
    colour *= sh;
    
    return colour;
}


vec3 directLight(Ray ray, HitSphere hit) {
 
    if (hit.mat.type==0) return vec3(0.0);
    if (hit.mat.type==DIFFUSE_LIGHT) return hit.mat.emit; 

    vec3 colour = fillLight(LIGHT1,
                            vec3(1.0),
                            ray,
                            hit);
    colour += fillLight(LIGHT2,
                        vec3(1.0),
                        ray,
                        hit);

    return colour;
}

vec3 render(Ray ray) {

    vec3 colourMask = vec3(1.0);
    vec3 accCol = vec3(0.0);

    float reflectionTerm = 1.0;
    
    for (int i=0; i<BOUNCES; i++) {
        
        HitSphere hit = HIT_MISS; //miss
        if (traceScene(ray, hit)) {
            
            //hit scene                
            Ray scattered;
            if (materialScatter(
                ray, 
                hit, 
                scattered)) {
                
                colourMask = mix(colourMask,
                                 colourMask * hit.mat.albedo,
                                 reflectionTerm);
                
                //direct light
                vec3 iColour = directLight(ray, hit);
                
                accCol = mix(accCol,
                             accCol + colourMask * iColour,
                             reflectionTerm);
                
                ray = scattered;
                    
            } else {
                
                //hit a light
                accCol += colourMask * hit.mat.emit * reflectionTerm;
                if (hit.mat.type==PANEL_LIGHT) {
                    ray = scattered;
                } else {
                    break;
                }
            }
            
            float fre = pow(clamp(dot(ray.d, hit.n) + 1.0, 0.0, 1.0), 32.0);
            reflectionTerm = (1.0 - hit.mat.v) * fre;
            
        } else {
            //missed scene
            break;
        }
        //optimised break condition from Reinder
        if (dot(colourMask, colourMask) < 0.0001) break; 
    }
    
    return accCol;
}

//IQ
mat3 setCamera(vec3 ro, vec3 ta, float cr) {
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv =          (cross(cu, cw));
    return mat3(cu, cv, -cw);
}

void mainImage(out vec4 C, vec2 U) {
        
    g_seed = float(base_hash(floatBitsToUint(U))) / float(0xffffffffU) + iTime;
	vec2 off = hash2(g_seed) - 0.5;

    vec3 lookFrom = vec3(sin(iTime*0.2)*3.0, cos(iTime*0.097)*2.0, -14.0),
         lookAt = vec3(0.0, 0.0, 0.0),
         pixelColour = vec3(0.0);
    
    vec2 p = (2.0*(U+off)-R.xy)/R.y;
    
    float focalLength = 2.;
    mat3 camIQ = setCamera(lookFrom, lookAt, 0.0);
    vec3 rd = normalize(camIQ * vec3(p, -focalLength));
    
    vec3 accColour = vec3(0.0);
    float t = 0.0;
    for (int i=0; i<RAYS; i++) {
        accColour += render(Ray(lookFrom, rd));
    }
    pixelColour = accColour / float(RAYS);
    
    C = vec4(pixelColour, 1.0);    
}