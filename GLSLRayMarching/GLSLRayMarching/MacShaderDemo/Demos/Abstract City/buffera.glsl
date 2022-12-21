float seed; // randoms seed

// hash funcions by me
float hash1() {return fract(sin(seed+=.1)*4561.7564);}

vec2 hash2() {return fract(sin(seed+=.1)*vec2(8472.5636,9854.4213));}

vec3 hash3() {return fract(sin(seed+=.1)*vec3(7653.1285,6912.8512,5914.7134));}

// generate normalized random 3d vector
vec3 uniformVector() {
    vec3 v = hash3()*2.-1.;
    return normalize(v);
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

// hash21
float hash(vec2 p) {
    p = fract(p*vec2(345.193,493.184));
    p += dot(p, p+123.547);
    return fract(p.x*p.y);
}

// noise function by me
float noise(vec2 p) {
    vec2 q = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.-2.*f);
    return mix(mix(hash(q+vec2(0)),hash(q+vec2(1,0)),f.x),
               mix(hash(q+vec2(0,1)),hash(q+vec2(1,1)),f.x),f.y);
}

// fractal noise
float fbm(vec2 p) {
    float a = .3;
    mat2 m = mat2(cos(a),-sin(a),sin(a),cos(a)); // rotation matrix
    float f = 0.;
    f += noise(p); p *= m;
    f += .5*noise(p*2.); p *= m;
    f += .25*noise(p*4.); p *= m;
    f += .2*noise(p*8.); p *= m;
    f += .15*noise(p*16.); p *= m;
    return f/2.;
}

// box SDF
float sdBox(vec3 p, vec3 s) {
    vec3 q = abs(p) - s;
    return length(max(q,0.))+min(0.,max(q.x,max(q.y,q.z)));
}

// scene
float map(vec3 p) {
    float d = 1e10;
    
    d = min(d, (p.y+2.*fbm(p.xz)-.1)*.5+.2*hash1()); // clouds
    
    d = min(d, sdBox(p-vec3(0,-.3,0), vec3(.5,1,.5)));
    d = min(d, sdBox(p-vec3(0,.8,0), vec3(.4,.1,.4)));
    d = min(d, sdBox(p-vec3(0,1,0), vec3(.3,.1,.3)));
    d = min(d, sdBox(p-vec3(0,1.2,0), vec3(.2,.1,.2)));
    d = min(d, sdBox(p-vec3(0,1.4,0), vec3(.1,.1,.1)));
    d = min(d, sdBox(p-vec3(0,1.6,0), vec3(.02,.15,.02)));
    
    d = min(d, sdBox(p-vec3(1,-.6,1.3), vec3(.4,1,.4)));
    d = min(d, sdBox(p-vec3(1,.45,1.3), vec3(.3,.05,.3)));
    
    d = min(d, sdBox(p-vec3(-.6,-.8,1.9), vec3(.35,.6,.35)));
    d = min(d, sdBox(p-vec3(-.6,-.15,1.9), vec3(.25,.05,.25)));
    
    d = min(d, sdBox(p-vec3(-.4,-.9,-1.7), vec3(.35,1,.35)));
    d = min(d, sdBox(p-vec3(-.4,.15,-1.7), vec3(.25,.05,.25)));
    
    d = min(d, sdBox(p-vec3(.7,-.9,-1.15), vec3(.3,1,.3)));
    d = min(d, sdBox(p-vec3(.7,.15,-1.15), vec3(.2,.05,.2)));
    
    d = min(d, sdBox(p-vec3(-1.3,-.9,.35), vec3(.3,.65,.3)));
    d = min(d, sdBox(p-vec3(-1.3,-.2,.35), vec3(.2,.05,.2)));

    return d;
}

// raymarching loop
float intersect(vec3 ro, vec3 rd) {
    float t = 0.;
    for (int i=0; i<256 && t<24.; i++) {
        vec3 p = ro + rd*t;
        float h = map(p);
        if (h<.0001) break;
        t += h;
    }
    return t;
}

// shadow function
float shadow(vec3 ro, vec3 rd) {
    for (float t=0.; t<12.;) {
        vec3 p = ro + rd*t;
        float h = map(p);
        if (h<.001) return 0.;
        t += h;
    }
    return 1.;
}

vec3 calcNormal(vec3 p) {
    float h = map(p);
    const vec2 e = vec2(.0001,0);
    return normalize(h - vec3(map(p-e.xyy),
                              map(p-e.yxy),
                              map(p-e.yyx)));
}

// rendering function
vec3 render(vec3 ro, vec3 rd) {
    vec3 sunDir = normalize(vec3(1,1.7,1)+.05*uniformVector()); // sun direction
    vec3 sunCol = vec3(1,.9,.6);
    
    vec3 col = vec3(0);
    vec3 emit = vec3(1);
    
    vec3 trd = rd; // save the first ray direction
    float tt = 24.;
    
    for (int i=0; i<10; i++) { // GI bounces
        float t = intersect(ro, rd);
        if (i==0) tt = t;
        if (t<24.) {
            vec3 p = ro + rd*t; // point on surface
            vec3 n = calcNormal(p); // surface normal
            
            // coloring
            vec3 mat = .5+.5*vec3(noise(p.xz),noise(2.*p.xz+5345.376),noise(2.*p.xz-9325.34));
            emit *= mix(mat,vec3(1),smoothstep(-.2,.2,p.y+.2));
            
            ro = p+n*.01;
            rd = cosineDirection(n);
            
            float dif = clamp(dot(n, sunDir), 0., 1.); // diffuse light
            float sha = shadow(ro, sunDir); // shadow
            
            col += emit*4.*sunCol*dif*sha; // sun light
            
            // sky light
            sha = shadow(ro, rd);
            col += emit*.2*vec3(.6,.8,1)*sha;
        } else {
            break;
        }
    }
    // fog
    vec3 fog = 1.-exp(-tt*tt*tt*.0003*vec3(.5,.7,1));
    col = mix(col, 2.*mix(vec3(.8,.9,1),vec3(.5,.7,1),.5+.5*rd.y), fog);
    // sun glare
    col += sunCol*12.*pow(clamp(dot(trd, sunDir),0.,1.),4.);
        
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
    seed = iTime+dot(sin(fragCoord),vec2(443.712,983.234)); // init randoms seed
    seed += hash1()*434.251;
    
    vec2 of = hash2()-.5; // antialiasing offset
    vec2 p = (fragCoord+of - .5*iResolution.xy) / iResolution.y;

    vec3 ro = vec3(-3.4,1.5,.8); // ray origin
    vec3 ta = vec3(0); // target
    mat3 ca = setCamera(ro, ta); // camera matrix
    
    vec3 rd = ca * normalize(vec3(p,1)); // ray direction

    vec3 col = render(ro, rd);
    col = col*1.4/(1.+col); // tonemapping

    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    data += vec4(col,1);

    // output
    fragColor = data;
}