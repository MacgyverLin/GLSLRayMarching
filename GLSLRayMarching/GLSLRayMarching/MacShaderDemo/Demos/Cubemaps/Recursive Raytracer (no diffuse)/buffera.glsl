#define MAX_RECURSION 8 // max ray bounces
#define REFRACTION_IDX 1.5// index of refraction

// 0 - wine glass
// 1 - cocktail glass

const int GLASS_LOOK = 0;

// materials idx
#define MAT_WOOD 0.
#define MAT_GLASS 1.
#define MAT_METAL 2.

// rotation function
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    vec3 q = abs(p) - s;
    return length(max(q,0.)) + min(0.,max(q.x,max(q.y,q.z)));
}

// torus sdf
float sdTorus(vec3 p, float ra, float rb) {
    return length(vec2(length(p.xz)-ra,p.y))-rb;
}

// smoothstep but not smooth
float mstep(float a, float b, float x) {
    return clamp((x-a)/(b-a),0.,1.);
}

// glass curve
// https://www.desmos.com/calculator/jfyacmb6pr
float func(float x) {
    if (GLASS_LOOK==0)
        return .3*smoothstep(.95,1.,x)+.35*smoothstep(.56,.4,x)*smoothstep(-1.3,.4,x);
    else
        return .25*smoothstep(.95,1.,x)+.45*mstep(.45,.0,x);
}

// glass sdf
float sdGlass(vec3 p) {
    p.y -= 1.;
    float h = clamp(-p.y*0.6779661017, 0., 1.);
    return sdTorus(p + vec3(0,1.475,0)*h, func(h), .025);
}

// union of two objects
vec2 opU(vec2 a, vec2 b) {
    return a.x<b.x ? a : b;
}

// scene
vec2 map(vec3 p) {
    vec2 d = vec2(1e10);
    
    d = opU(d, vec2(p.y+.5+.001*sin(6.*p.x)*sin(6.*p.z), MAT_WOOD)); // plane

    // glass
    vec3 q = p;
    q.x = fract(q.x+.5)-.5; // repetition on the x axis
    float glass = sdGlass(q)*.5;
    d = opU(d, vec2(glass, MAT_GLASS));

    // metal cubes
    p.xz = abs(p.xz);
    d = opU(d, vec2(sdBox(p-vec3(.6,-.3,.6), vec3(.16))-.04, MAT_METAL));
            
    return d;
}

// raymarching loop
// returns the distance and the material idx
vec2 intersect(vec3 ro, vec3 rd) {
    float t = 0.;
    float s = sign(map(ro).x); // inside and outside the surface
    
    for (int i=0; i<256 && t<16.; i++) {
        vec3 p = ro + rd*t;
        vec2 h = map(p);
        h.x *= s;
        if (abs(h.x)<.0001*t) return vec2(t,h.y);
        t += h.x;
    }
    return vec2(t,-1);
}

vec3 calcNormal(vec3 p) {
    float h = map(p).x;
    const vec2 e = vec2(.0001,0);
    
    return normalize(h - vec3(map(p-e.xyy).x,
                              map(p-e.yxy).x,
                              map(p-e.yyx).x));
}

// ambien occlusion
float calcAO(vec3 p, vec3 n, float k) {
    float res = clamp(.5+.5*map(p+n*k).x/k,0.,1.);
    return res;
}

// soft shadow function
// thanks to iq: https://iquilezles.org/articles/rmshadows/
float shadow(vec3 ro, vec3 rd, float tmax, float k) {
    float res = 1.;
    for (float t=.01; t<tmax;) {
        vec3 p = ro + rd*t;
        float h = map(p).x*2.;
        if (h<.001) return 0.;
        res = min(res, k*h/t);
        t += h;
    }
    return res*res*(3.-2.*res);
}

// sky texture
vec3 skyTex(vec3 rd) {
    vec3 col = pow(texture(iChannel1, rd).rgb,vec3(2.));
    return col+2.*pow(col,vec3(3.));
}

// ground texture
vec3 groundTex(vec3 p) {
    return pow(texture(iChannel0, p.xz*.5).rgb,vec3(2.2));
}

// wood lighting and color function
vec3 woodLighting(vec3 p, vec3 n, vec3 rd) {
    vec3 r = reflect(rd, n); // reflected vector
    
    float occ = .5+.5*calcAO(p, n, .1); // occulsion
    occ = occ*occ*(3.-2.*occ);
    float ref = shadow(p, r, 8., 24.); // reflection (specular)
    
    vec3 col = groundTex(p);
    col += (.3+.7*skyTex(r))*.1*ref; // skybox reflection
    col *= occ;
        
    return col;
}

// pathtracing function
vec3 pathtrace(vec3 ro, vec3 rd, bool ref) {
    vec3 col = vec3(1);
    
    for (int i=0; i<MAX_RECURSION; i++) { // ray bounces
        vec2 tmat = intersect(ro, rd);
        float t = tmat.x; // distance
        float mat = tmat.y; // material
        if (t<16.) {
            vec3 p = ro + rd*t;
            vec3 n = calcNormal(p);

            if (mat==MAT_GLASS) {
                if (ref) {
                    ro = p+n*.005;
                    rd = reflect(rd, n);
                } else {
                    // refraction
                    float fre = dot(rd, n);
                    float s = sign(fre);
                    vec3 m = -n*s;
                    float ior = REFRACTION_IDX;
                    float v = (.5-.5*s)/ior+ior*(.5+.5*s);

                    ro = p-m*.005;
                    rd = refract(rd, m, v);
                }
            } else if (mat==MAT_WOOD) {
                col *= woodLighting(p, n, rd);
                return col;
            } else if (mat==MAT_METAL){
                // reflection
                ro = p+n*.005;
                rd = reflect(rd, n);
            }
        } else {
            break;
        }
    }
    
    return col*skyTex(rd);
}

// rendering function
vec3 render(vec3 ro, vec3 rd) {
    vec3 col = skyTex(rd);
    
    vec2 tmat = intersect(ro, rd);
    float t = tmat.x; // distance
    float mat = tmat.y; // material
    if (t<16.) {
        vec3 p = ro + rd*t;
        vec3 n = calcNormal(p);
        vec3 r = reflect(rd, n); // reflected ray
        
        // lighting and coloring
        
        vec3 refl = pathtrace(ro, rd, true); // reflected color
        vec3 refr = pathtrace(ro, rd, false); // refracted color
        
        // ambient occlusion
        float occ = .4+.6*calcAO(p, n, .1);
        occ = occ*occ*(3.-2.*occ);
        
        if (mat==MAT_WOOD) {
            col = woodLighting(p, n, rd);
        } else if (mat==MAT_GLASS) {
            // schlick aproximation
            float fre = 1.+dot(rd, n);
            float r0 = (1.-REFRACTION_IDX)/(1.+REFRACTION_IDX);
            r0 = r0*r0;
            float schlick = r0 + (1.-r0)*pow(fre, 5.);
            col = mix(refr, refl, schlick); // blending the reflected ray with the refracted ray
        } else if (mat==MAT_METAL){
            col = refr;
            col *= occ;
        }
    }
    
    return col;
}

// camera matrix
mat3 setCamera(vec3 ro, vec3 ta) {
    vec3 w = normalize(ta - ro);
    vec3 u = normalize(cross(w, vec3(0,1,0)));
    vec3 v = cross(u, w);
    return mat3(u, v, w);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (fragCoord - .5*iResolution.xy) / iResolution.y;
    vec2 m = (iMouse.xy - .5*iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0,.2,-3.5); // ray origin
    ro.xz *= rot(-.2*iTime+3.141592*m.x-.7); // ray origin rotation
    vec3 ta = vec3(0,.3,0); // target
    mat3 ca = setCamera(ro, ta); // camera matrix
    
    vec3 rd = ca * normalize(vec3(p,1.6)); // ray direction

    vec3 col = render(ro, rd);
    float t = intersect(ro, rd).x; // distance to the scene (for the dof)

    // output
    fragColor = vec4(col,t);
}