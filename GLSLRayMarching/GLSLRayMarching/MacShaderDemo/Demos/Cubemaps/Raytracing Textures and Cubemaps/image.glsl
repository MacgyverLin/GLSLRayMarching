#define PI 3.141592
#define TAU 6.283185
#define SOFT_SHADOW_SAMPLES 16 // soft shadows quality
#define AA 3 // antialiasing / set it to 1 if you have a slow computer

// rotation function
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

struct Ray {
    vec3 o, d; // origin and direction
};

struct Camera {
    vec3 o, d; // origin and direction
    float z; // zoom
};

//ray setup function
Ray getRay(vec2 uv, Camera c) {
    vec3 f = normalize(c.d - c.o);
    vec3 s = normalize(cross(vec3(0,1,0), f));
    vec3 u = cross(f, s);
    vec3 i = normalize(f*c.z + uv.x*s + uv.y*u);
    
    return Ray(c.o, i);
}

struct Record {
    float t;
    vec3 p, n; // position and normal
    int tex; // texture
};

// sphere intersection function
bool iSphere(vec3 c, float s, Ray r, inout Record rec) {
    float t = dot(c - r.o, r.d);
    vec3 p = r.o + r.d * t;
    float a = length(p - c);
    if (s*s - a*a > 0.0) {
        float b = sqrt(s*s - a*a);
        t -= b;
        if (t > 1e-6 && t < rec.t) {
            rec.t = t;
            rec.p = r.o + r.d * t;
            rec.n = normalize(rec.p - c);
            rec.tex = 1;
            return true;
        }
    }
    return false;
}

// plane intersection function
bool iPlane(vec3 n, float h, float s, Ray r, inout Record rec) {
    float t = (-h - dot(n, r.o)) / dot(n, r.d);
    vec3 p = r.o + r.d * t;
    
    if (t > 1e-6 && t < rec.t && length(p) < s+sin(p.x)*sin(p.z)) {
        rec.t = t;
        rec.p = p;
        rec.n = n;
        rec.tex = 2;
        return true;
    }
    return false;
}

// box intersection function by iq: https://www.shadertoy.com/view/ld23DV
bool iBox(vec3 p, vec3 s, Ray r, inout Record rec) {
    vec3 m = 1./r.d;
    vec3 n = m*(r.o - p);
    vec3 k = abs(m)*s;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    
    if( tN>tF || tF<1e-6) {
        return false;
    }
    if (tN > 1e-6 && tN < rec.t) {
        rec.t = tN;
        rec.p = r.o + r.d * tN;
        rec.n = -sign(r.d)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
        rec.tex = 0;
        return true;
    }
}

// intersect scene
bool intersect(Ray r, out Record rec) {
    rec.t = 1e10;
    bool hit = false;

    hit = iPlane(vec3(0,1,0), .5, 5., r, rec) || hit;
    hit = iBox(vec3(0), vec3(.5,.25,.75), r, rec) || hit;
    hit = iSphere(vec3(0,.9+.2*sin(2.5*iTime),0), .3, r, rec) || hit;
    
    return hit;
}

// biplanar mapping
vec3 applyTexture(sampler2D tex, vec3 p, vec3 n, float k) {
     p = .5+.5*p;   
     
     vec3 xy = texture(tex, p.xy).rgb;
     vec3 xz = texture(tex, p.xz).rgb;
     vec3 yz = texture(tex, p.yz).rgb;
            
     n = abs(n);
     n = pow(n, vec3(k));
     n /= dot(n, vec3(1));
            
     return xy*n.z + xz * n.y + yz*n.x;
}

// soft shadow
float calcSoftshadow(vec3 ro, vec3 rd, int q, float k) {
    Ray r;
    r.o = ro;
    Record rec;
    float res = 1.;
    for (int i = 0; i < q; i++) {
        float o = float(i)/float(q);
        r.d = normalize(rd + o*k*vec3(0,1,0)); 
        if (intersect(r, rec)) res -= 1./float(q);
    }
    return res;
}

vec3 render(Ray r) {
    Record rec;
    bool hit = intersect(r, rec);
        
    vec3 col = texture(iChannel3, r.d).rgb;
    if (hit) {
        // color / lighting
        vec3 lig = normalize(vec3(-3,4,-1) - rec.p);
        float dif = clamp(dot(rec.n, lig), 0., 1.); // difuse lighting
        float sha = calcSoftshadow(rec.p, lig, SOFT_SHADOW_SAMPLES, .1);
        float occ = .5+.5*rec.n.y; // fake occlusion
        float fre = pow(1.+dot(r.d, rec.n), 2.);

        if (rec.tex == 0) {
            col = applyTexture(iChannel0, rec.p, rec.n, 32.);
        } else if (rec.tex == 1) {
            col = applyTexture(iChannel1, rec.p, rec.n, 16.);
        } else if (rec.tex == 2) {
            col = applyTexture(iChannel2, rec.p*.5, rec.n, 16.);
        }
        
        float ref = calcSoftshadow(rec.p, reflect(r.d, rec.n), SOFT_SHADOW_SAMPLES, .0);
        
        vec3 refTex = texture(iChannel3, reflect(r.d, rec.n)).rgb;
        col += 1.5*refTex*ref*fre; // fake reflections
        col *= dif * sha + occ * vec3(.05,.1,.15);
    }
        
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mouse = iMouse.xy / iResolution.xy;
    
    // antialiasing by iq
    vec3 tot = vec3(0);
    for (int i = 0; i < AA; i++) {
    for (int j = 0; j < AA; j++) {
        vec2 o = vec2(i, j) / float(AA) - .5;
        vec2 uv = (fragCoord + o - .5 * iResolution.xy) / iResolution.y;

        vec3 camPos = vec3(0,mouse.y * 2.,-2);
        camPos.xz *= rot(-mouse.x*TAU - .5*iTime);
        
        Ray r = getRay(uv, Camera(camPos, vec3(0,.25,0), .9));
;
        vec3 col = render(r);
        
        col = pow(col, vec3(.4545)); // gamma corection
        col *= 1.-.15*dot(uv,uv); // vignetting
        tot += col;
    }
    }
    tot /= float(AA*AA);
        
    fragColor = vec4(tot,1.0);
}