// antialiasing, set it to 2 if you have a very fast machine
#define AA 1
// raymarching steps for volumetric fog
#define NUM_VOLUME_STEPS 16
const vec3 lig = normalize(vec3(.8,.85,-.9)); // sun direction

///////////////
// MODELLING //
///////////////

// hash function
float hash(float n) {return fract(sin(n)*43758.5453123);}

// 3d noise function by iq
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.-2.*f);

    float n = p.x + p.y*157. + 113.*p.z;

    return mix(mix(mix(hash(n+  0.), hash(n+  1.),f.x),
                   mix(hash(n+157.), hash(n+158.),f.x),f.y),
               mix(mix(hash(n+113.), hash(n+114.),f.x),
                   mix(hash(n+270.), hash(n+271.),f.x),f.y),f.z);
}

// 3d fractal noise
float fbm(vec3 p) {
    float f = 0.;
    f += .5*noise(p);
    f += .25*noise(2.*p);
    f += .125*noise(4.*p);
    return f;
}

// hash vec2 to float
float hash21(vec2 p) {
    p = fract(p*vec2(452.127,932.618));
    p += dot(p, p+123.23);
    return fract(p.x*p.y);
}

// 2d noise function by me
float noise(vec2 p) {
    vec2 q = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.-2.*f);
    return mix(mix(hash21(q+vec2(0,0)),hash21(q+vec2(1,0)),f.x),
               mix(hash21(q+vec2(0,1)),hash21(q+vec2(1,1)),f.x),f.y);
}

// 2d fractal noise
float fbm(vec2 p) {
    float a = .2;
    mat2 m = mat2(cos(a),-sin(a),sin(a),cos(a)); // rotation matrix
    float f = 0.;
    f += .5*noise(p); p *= m;
    f += .25*noise(p*2.); p *= m;
    f += .125*noise(p*4.); p *= m;
    f += .0625*noise(p*8.); p *= m;
    return f;
}

// squared length
float dot2(vec2 v) {return dot(v,v);}

// cone sdf
// thanks to iq: https://iquilezles.org/articles/distfunctions/
float sdCone(vec3 p, float h, float r1, float r2) {
    vec2 q = vec2(length(p.xz), p.y);
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2-r1,2.*h);
    vec2 ca = vec2(q.x-min(q.x,(q.y<0.)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0., 1.);
    float s = (cb.x<0. && ca.y<0.) ? -1. : 1.;
    return s*sqrt(min(dot2(ca),dot2(cb)));
}

// height of the terrain
float height(vec3 p) {
    return fbm(p.xz+3.)-noise(.4*p.xz-.2)+.8;
}

// union of two sdf
vec2 opU(vec2 a, vec2 b) {
    return a.x<b.x ? a : b;
}

#define MAT_TERRAIN 0.
#define MAT_WOOD 1.
#define MAT_LEAVE 2.

// sdf to scene
vec2 map(vec3 p) {
    vec2 d = vec2(1e10);
    
    // terrain
    d = opU(d, vec2(.9*(p.y+height(p)), MAT_TERRAIN));
    
    // trees
    
    // square size
    float s = 4.2;
    
    vec3 q = p;
    q.y += height(p); // tree at the ground height 
    q.xz = (fract(q.xz*s)-.5)/s; // repetition on x and z axis
    
    // add a bit of randomness
    float h = 123.*floor(p.x*s)+15.*floor(p.z*s);
    q.x += .2*sin(4.*h)/s;
    q.z += .2*sin(8.*h+2.)/s;
    
    // trunc
    vec2 trees = vec2(sdCone(q, .3, .03, .008), MAT_WOOD);
    
    // leaves
    q.y += .26*sin(h)/s;
    float leaves = 1e10;
    for (float i=0.; i<1.; i+=1./5.) {
        leaves = min(leaves, sdCone(q-vec3(0,.28*i+.3+.05,0), .03, .113*(1.-i), .0));
    }
    trees = opU(trees, vec2(leaves*.4, MAT_LEAVE));
    
    d = opU(d, trees);
            
    return d;
}

///////////////
// RENDERING //
///////////////

// raymarching loop, returns the distance and material index
vec2 intersect(vec3 ro, vec3 rd) {
    float t = 0.;
    
    for (int i=0; i<512 && t<64.; i++) {
        vec3 p = ro + rd*t;
        vec2 h = map(p);
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

// soft shadow function
// thanks to iq: https://iquilezles.org/articles/rmshadows/
float shadow(vec3 ro, vec3 rd, float tmax, float k) {
    float res = 1.;
    for (float t=.008; t<tmax;) {
        vec3 p = ro + rd*t;
        float h = map(p).x;
        if (h<.001) return 0.;
        res = min(res, k*h/t);
        t += h;
    }
    return res*res*(3.-2.*res);
}

// sky
vec3 background(vec3 rd) {
    vec3 col = mix(vec3(1), vec3(.3,.5,1), .5+.5*rd.y); // blue sky
    // add a bit of red
    return .65*mix(col, vec3(1,.05,.02), .34*clamp(exp(-rd.y*rd.y*32.),0.,1.));
}

// atmospheric perspective
vec3 atmosphere(vec3 col, float t, vec3 rd) {
    vec3 atm = 1.-exp(-t*t*.0008*vec3(1,1.5,2.2));
    return mix(col, background(rd), atm);
}

// density of the fog at point p
float fogMap(vec3 p) {
    return noise(2.*p+.3*iTime)*fbm(12.*p)*smoothstep(-.3,-.9,p.y)+4.*pow(fbm(15.*p+.4*iTime),12.);
}

vec3 volumetricFog(vec3 col, vec3 ro, vec3 rd, float tmax) {
    // bounding volume
    float b = ro.y/rd.y;
    if (b>0.) return col;
    
    float s = min(tmax, 12.) / float(NUM_VOLUME_STEPS); // step size
    float t = 0.;
    float acc = 0.; // accumulation
    for (int i=0; i<NUM_VOLUME_STEPS; i++) {
        vec3 p = ro + rd*t;
        float h = fogMap(p);
        acc += s*h;
        t += s;
    }
    acc = 1.-exp(-acc*.7); // density fallof
    col = mix(col, vec3(1), acc);
    return col;
}

// rendering function
vec3 render(vec3 ro, vec3 rd) {
    vec3 col = background(rd);
        
    // cheap clouds
    float b = 1./rd.y; // plane
    if (b>0.) {
        vec3 p = ro + rd*b;
        float m = fbm(p.xz);
        col = mix(col, vec3(1), smoothstep(.35,.7,m));
        col = atmosphere(col, b, rd);
    }    
    
    // material index and distance
    vec2 tm = intersect(ro, rd);
    float t = tm.x;
    float m = tm.y;

    if (t<64.) { // we hit the surface
        vec3 p = ro + rd*t; // hit point
        vec3 n = calcNormal(p); // normal of the surface
                
        float dif = clamp(dot(n, lig), 0., 1.); // diffuse light
        float bac = clamp(dot(n, -lig), 0., 1.); // back light
        float sha = shadow(p, lig, 16., 32.); // soft shadow
        // ambient occulsion
        float occ = smoothstep(.2,.6,p.y+height(p))+.35;
        occ *= .5+.5*map(p+n*.03).x/.03;
        
        // color of the object
        vec3 mat;
        if (m == MAT_TERRAIN) { // ground
            mat = mix(vec3(.5,.3,.2), vec3(1), smoothstep(.85-.5*fbm(24.*p),.9,n.y));
        } else if (m == MAT_WOOD) { // trunc of the trees
            mat = vec3(.5,.3,.2);
        } else { // leaves
            // random colors
            float h = 356.*floor(p.x*4.2)+27.*floor(p.z*4.2);
            mat = mix(vec3(.2,.35,.05), vec3(.25,.4,.0), sin(5.*h));
            mat = mix(mat, vec3(.05,.2,0), sin(15.*h+3.));
            // add snow on the top of the trees
            mat = mix(mat, vec3(1), smoothstep(.45,.65,p.y+height(p)+.1*sin(12.*h+2.)+.2*fbm(42.*p)));;
        }
        
        col = vec3(0);
        col += vec3(1,.8,.6)*dif*sha*mat; // sun light
        col += vec3(1,.8,.6)*occ*.025*mat*bac; // bounce light
        col += mat*.045*occ*vec3(.6,.8,1); // sky light
                                
        col = atmosphere(col, t, rd);
    }
    
    // fog
    col = volumetricFog(col, ro, rd, t);
    
    // sun glare
    float glare = clamp(dot(rd, lig), 0., 1.);
    col += 2.*vec3(1,.8,.6)*pow(glare, 7.);
    col += 2.*vec3(1,.2,.1)*pow(glare, 10.);
    
    return col;
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
    
    for (int m=0; m<AA; m++)
    for (int n=0; n<AA; n++) {
        vec2 off = vec2(m,n)/float(AA) - .5; // AA offset
        // pixel coordinates centered at the origin
        vec2 p = (fragCoord+off - .5*iResolution.xy) / iResolution.y;
    
        vec3 ro = vec3(1.-.6*sin(.1*iTime),.35,2.5); // ray origin
        vec3 ta = vec3(0); // target
        mat3 ca = setCamera(ro, ta); // camera matrix
        
        vec3 rd = ca * normalize(vec3(p,1.5)); // ray direction
    
        vec3 col = render(ro, rd);
        tot += col;
    }
    tot /= float(AA*AA);
            
    fragColor = vec4(tot,1.0);
}