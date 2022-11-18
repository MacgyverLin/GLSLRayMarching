#define PI 3.14159265359
#define rot(a) mat2(cos(a + PI*0.25*vec4(0,6,2,0)))
#define FOV 2.0
#define HEX vec2(1, 1.73205080757)

#define LIGHT_ENABLE
#define LIGHT_FREQ 0.3
#define LIGHT_COLOR vec3(0.05, 0.2, 0.8)

// Dave Hoskins hash
float hash13( in vec3 p3 ) {
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// hexagonal tiling
vec2 hexCenter( in vec2 p ) {
    vec2 centerA = (floor(p.xy*HEX)+0.5)/HEX;
    vec2 centerB = (floor((p.xy+HEX*0.5)*HEX)+0.5)/HEX-HEX*0.5;
    vec2 a = p.xy-centerA.xy; vec2 b = p.xy-centerB.xy;
    return dot(a,a)<dot(b,b) ? centerA : centerB;
}

// control sphere height
vec3 getSphereCenter( in vec2 c ) {
    return vec3(c, sin(c.x-c.y*4.3+iTime)*0.2);
}

// main distance function, returns distance and color
float de( in vec3 p, in vec3 dir, in float r, out vec3 color ) {
    
    // translate and get the center
    p.xy += iTime;
    vec2 center = hexCenter(p.xy);
    // find out where the red light is
    float red = floor(iTime*LIGHT_FREQ)+0.5;
    float fRed = smoothstep(0.5, 0.0, abs(fract(iTime*LIGHT_FREQ)-0.5));
    vec3 centerRed = getSphereCenter(hexCenter(red/LIGHT_FREQ + vec2(0.5, 1.5)));
    
    #ifndef LIGHT_ENABLE
    fRed = 0.0;
    #endif
    
    // accumulate distance and color
    float d = 9e9;
    color = vec3(0);
    float colorAcc = 0.0;
    for (int i = 0 ; i < 7 ; i++) {
        float theta = float(i) * (2.0*PI/6.0);
        vec2 offset = vec2(sin(theta), cos(theta))*min(1.0/HEX.y, float(i));
        vec3 sphere = getSphereCenter(center + offset);
        vec3 inCenter = p - sphere;
        float len = length(inCenter);
        vec3 norm = inCenter / len;
        vec3 toRed = sphere-centerRed;

        // select the nearest sphere
        float dist = len-0.3;
        d = min(d, dist);

        // colors and light
        vec3 albedo = vec3(sin(sphere.x*90.0+sphere.y*80.0)*0.45+0.5);
        vec3 colorHere = vec3(0);
        
        if (dot(toRed, toRed) < 0.001) {
            albedo = mix(albedo, vec3(0.0), fRed);
            colorHere += LIGHT_COLOR*fRed*4.0;
        } else {
            vec3 lightDir = centerRed-p;
            float len = dot(lightDir, lightDir);
            lightDir *= inversesqrt(len);
            vec3 col = LIGHT_COLOR*fRed/(len+1.0)*2.0;
            colorHere += albedo*max(0.0, dot(norm, lightDir)+0.5/len)*col;
            colorHere += albedo*pow(max(0.0, dot(lightDir, reflect(dir, norm))), 8.0)*col;
        }
        
        const vec3 lightDir = normalize(vec3(1, -1, 3));
        colorHere += albedo*max(0.0, dot(lightDir, norm));
        colorHere += albedo*pow(max(0.0, dot(lightDir, reflect(dir, norm))), 8.0);
        
        // accumulate color across neighborhood
        float alpha = max(0.0001, smoothstep(r, -r, dist));
        color += colorHere*alpha;
        colorAcc += alpha;
    }
    
    color /= colorAcc;
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
	vec3 from = vec3(0, 0, 1.2);
	vec3 dir = normalize(vec3(uv, -1.0/tan(FOV*0.5)));
	dir.yz *= rot(-0.85);
    dir.xy *= rot(0.2);
    
    float focal = 2.5;
    if (iMouse.z > 0.5) focal = 1.0+iMouse.y/iResolution.y*4.0;
    float sinPix = sin(FOV / iResolution.y);
    vec4 acc = vec4(0, 0, 0, 1);
    vec3 dummy = vec3(0);
    float totdist = de(from, dir, 0.0, dummy)*hash13(vec3(fragCoord, iFrame));
    for (int i = 0 ; i < 100 ; i++) {
		vec3 p = from + totdist * dir;
        float r = max(totdist*sinPix, abs((totdist-focal)*0.1));
        vec3 color = vec3(1);
        float dist = de(p, dir, r, color);
        
        // cone trace the surface
		float alpha = smoothstep(r, -r, dist);
        acc.rgb += acc.a * (alpha*color.rgb);
        acc.a *= (1.0 - alpha);
        
        // hit a surface, stop
        if (acc.a < 0.01) break;
        // continue forward
        totdist += max(abs(dist), r*0.5);
	}
    
    fragColor.rgb = clamp(acc.rgb, vec3(0), vec3(1));
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0/2.2));
    fragColor.a = 1.0;
}