vec2 random2(vec2 st) {
	st = vec2(dot(st, vec2(127.1, 311.7)),
		dot(st, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(st) * 43758.5453123 * 0.7897);
}

// Gradient Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/XdXGW8
float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(dot(random2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
		dot(random2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(random2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(random2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 x) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
	// Rotate to reduce axial bias
	mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
	for (int i = 0; i < 5; ++i) {
		v += a * noise(x);
		x = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

float sdf(vec3 point) {
    float plane = length(max(point.y, 0.0)) + fbm(point.xz/10.0)*10.0-0.5;
    
    return plane;
}

float rayMarch(vec3 rayOrigin, vec3 rayDir) {
    float distMarched = 0.0;
    
    for (int i = 0; i < 100; i++) {
        float dist = sdf(rayOrigin);
        
        rayOrigin += rayDir * dist;
        distMarched += dist;
        
        if (distMarched < 0.01 || dist > 100.0) {
            break;
        }
    }
    
    return distMarched;
}

vec3 getNormal(vec3 point) {
    float dist = sdf(point);
    vec3 norm = dist - vec3(
        sdf(point - vec3(0.01, 0.0, 0.0)),
        sdf(point - vec3(0.0, 0.01, 0.0)),
        sdf(point - vec3(0.0, 0.0, 0.01))
    );
    return normalize(norm);
}

vec3 getColor(vec3 point) {
    float n = fbm(point.xz*10.0)+0.5;
    if (point.y > 0.6) {
        return vec3(1.0) * n;
    }
    else if (point.y > 0.4) {
        return vec3(0.0, 1.0, 0.0)*n;
    }
    else {
        return vec3(0.0, 0.0, 1.0)*n;
    }
}

float getSpecular(vec3 point, vec3 lightDir, vec3 cameraPos) {
    vec3 viewDir = normalize(cameraPos-point);
    vec3 reflectDir = reflect(-lightDir, getNormal(point));
    return pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
}

float getSpecularity(vec3 point) {
    if (point.y < 0.4) {
        return 2.0;
    }
    return 1.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.x;

    vec3 cameraPos = vec3(0.0, 3.5+sin(iTime/5.0), iTime);
    vec3 rayDir = vec3(uv.x+sin(iTime/5.0), uv.y-0.25, 1.0);
    vec3 lightDir = vec3(0.5, 0.5, 0.7);
    float dist = rayMarch(cameraPos, rayDir);
    vec3 point = rayDir * dist + cameraPos;
    vec3 normal = getNormal(point);
    float light = dot(normal, lightDir);
    float lightDist = rayMarch(point+normal*0.01, lightDir);
    
    if (lightDist < 90.0) {
        light *= 0.1;
    }
    
    vec3 col = vec3(light*vec3(0.7, 0.7, 1.0));
    
    col = mix(col, vec3(0.7, 0.7, 1.0), dist/100.0);
    col = mix(col, vec3(0.0), point.y/10.0);
    col *= getColor(point) + getSpecular(point, lightDir, cameraPos) * getSpecularity(point);

    // Output to screen
    fragColor = vec4(col,1.0);
}