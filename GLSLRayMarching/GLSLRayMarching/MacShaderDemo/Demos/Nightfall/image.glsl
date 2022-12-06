// Created by Vinicius Graciano Santos - vgs/2015
// Mostly based on iq's presentation at Function 2009.
// https://iquilezles.org/www/material/function2009/function2009.htm

#define STEPS 256
#define EPS (2.0/iResolution.x)
#define FAR 6.0
#define PI 3.14159265359

#define iGT (iTime+10.0)

vec3 noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Quintic because everyone else is using the cubic! :D
    vec2 df = 30.0*f*f*(f*(f-2.0)+1.0);
    f = f*f*f*(f*(f*6.-15.)+10.);
    
    float a = texture(iChannel0, (i+vec2(0.5, 0.5))/256., -100.0).r;
    float b = texture(iChannel0, (i+vec2(1.5, 0.5))/256., -100.0).r;
    float c = texture(iChannel0, (i+vec2(0.5, 1.5))/256., -100.0).r;
    float d = texture(iChannel0, (i+vec2(1.5, 1.5))/256., -100.0).r;
    
    float k = a-b-c+d;
    float n = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    
    return vec3(n, vec2(b-a+k*f.y, c-a+k*f.x)*df);
}

mat2 m = mat2(0.8,-0.6,0.6,0.8);
float fbmSimple(vec2 p) {
    float f = 0.0;
    f += 0.5*noise(p).x; p = 2.0*m*p;
    f += 0.25*noise(p).x; p = 2.0*m*p;
    f += 0.125*noise(p).x; p = 2.0*m*p;
    f += 0.0625*noise(p).x;
    return f/0.9375;
}

float fbmL(vec2 p) {
    vec2 df = vec2(0.0);
    float f = 0.0, w = 0.5;
    
    for (int i = 0; i < 2; ++i) {
        vec3 n = noise(p);
        df += n.yz;
        f += abs(w * n.x/ (1.0 + dot(df, df)));
        w *= 0.5; p = 2.*m*p;
    }
    return f;
}

float fbmM(vec2 p) {
    vec2 df = vec2(0.0);
    float f = 0.0, w = 0.5;
    
    for (int i = 0; i < 4; ++i) {
        vec3 n = noise(p);
        df += n.yz;
        f += abs(w * n.x/ (1.0 + dot(df, df)));
        w *= 0.5; p = 2.*m*p;
    }
    return f;
}

float fbmH(vec2 p) {
    vec2 df = vec2(0.0);
    float f = 0.0, w = 0.5;
    
    for (int i = 0; i < 10; ++i) {
        vec3 n = noise(p);
        df += n.yz;
        f += abs(w * n.x/ (1.0 + dot(df, df)));
        w *= 0.5; p = 2.*m*p;
    }
    return f;
}

float map(vec3 p) {
    return p.y - fbmM(p.xz);
}

float mapL(vec3 p) {
    return p.y - fbmL(p.xz);
}

float mapH(vec3 p) {
    return p.y - fbmH(p.xz);
}

vec3 normal(vec3 p) {
    vec2 q = vec2(0., EPS);
    return normalize(vec3(mapH(p+q.yxx) - mapH(p-q.yxx),
                		  mapH(p+q.xyx) - mapH(p-q.xyx),
                		  mapH(p+q.xxy) - mapH(p-q.xxy)));
}

vec3 normalL(vec3 p) {
    vec2 q = vec2(0., EPS);
    return normalize(vec3(mapL(p+q.yxx) - mapL(p-q.yxx),
                		  mapL(p+q.xyx) - mapL(p-q.xyx),
                		  mapL(p+q.xxy) - mapL(p-q.xxy)));
}

vec3 skyCol = 2.5*pow(vec3(40., 56., 84.)/255., vec3(2.2));
vec3 moonCol = pow(vec3(168., 195., 224.)/255., vec3(2.2));

vec3 fogColor(vec3 sundir, vec3 dir) {
    vec3 col = skyCol + moonCol*pow(max(dot(sundir, dir), 0.0), 16.0)*max(0.0, -dir.z);
    return col / (col + 1.0);
}

vec3 fullSky(vec3 sundir, vec3 dir) {
    vec3 stars = vec3(smoothstep(0.8, 0.95, fbmSimple(100.0*dir.xy/(dir.z+EPS))));
    
    vec3 clouds = vec3(0.0);
    float s = 0.25;
    for (int i = 0; i < 3; ++i) {
    	clouds += fbmSimple(dir.xz/(dir.y+EPS)-s*iGT);
        s *= 1.35;
    }
    
    vec3 col = skyCol + 0.15*clouds*max(0.0, dir.y);
    col += 2.0*stars*max(0.0, dir.y);
    
    col += max(0.0, -dir.z)*moonCol*pow(max(dot(sundir, dir), 0.0), 16.0);
    vec2 moonPos = dir.xy/dir.z - sundir.xy/sundir.z;
    col = mix(col, vec3(1.65), max(0.0, -dir.z)*fbmSimple(8.5*moonPos)*smoothstep(0.37, 0.35, length(moonPos)));
    
    return col / (col + 1.0);
}

vec3 material(vec3 p, vec3 n) {
    vec3 brown = pow(vec3(185., 122., 87.)/255., vec3(2.2));
    return mix(vec3(1.0), brown, smoothstep(0.6*n.y, 1.0*n.y, fbmH(p.xz)));
}

vec3 shade(vec3 ro, vec3 rd, float t) {
    vec3 l = normalize(vec3(1.0, 0.0, -1.0));
      
    vec3 col = fullSky(l, rd);
    
    if (t > 0.0) {
        vec3 p = ro +t*rd;
        vec3 n = normal(p);
        vec3 h = normalize(l - rd);
        vec3 r = reflect(rd, h);
    	        
        float shin = 5.0, r0 = 0.25;
        float fresnel = (r0 + (1.0 - r0)*pow((1.0-dot(-rd, h)), 5.0));
        vec3 spec_light = fogColor(l, r);
        vec3 spec_brdf = vec3(1.0)*fresnel*(shin + 8.0)/(8.0*PI)*pow(max(dot(n, h), 0.0), shin);
        
        vec3 tex = material(p, n);
        vec3 diff_light = pow(vec3(168., 195., 224.)/255., vec3(2.2));
        vec3 diff_brdf = tex*(1.0-fresnel)/PI;
        
        float shadow = clamp(5.0*dot(normalL(p), l), 0.0, 1.0);
            
        float fog = 1.0 - exp(-0.25*t);
        vec3 lcol = (diff_brdf*diff_light + spec_brdf*spec_light)*shadow*max(dot(n, l), 0.0);
    	col = mix(0.97*lcol + 0.03*tex*n.y, fogColor(l, rd), fog);
    }
    return clamp(col / (col + 1.0), 0.0, 1.0);
}

float raymarch(vec3 ro, vec3 rd) {
    float d = 0., t = 0.0;
    for (int i = 0; i < STEPS; ++i) {
        d = map(ro + t*rd);
        if (d < EPS*t || t > FAR)
            break;
        t += max(0.35*d, 2.*EPS*t);
    }
   
    return d < EPS*t ? t : -1.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;
    
    vec3 ro = vec3(0.0, 0.0, -0.2*iGT); ro.y = 0.15 + 1.2*fbmL(ro.xz);
    vec3 rd = normalize(vec3(uv, -1.0));
    
    float t = raymarch(ro, rd);
    vec3 col = pow(shade(ro, rd, t), vec3(1.0/2.2));
    
    col = smoothstep(0.0, 1.0, col);
    col *= 1.2;
    
	fragColor = vec4(col, 1.);
}