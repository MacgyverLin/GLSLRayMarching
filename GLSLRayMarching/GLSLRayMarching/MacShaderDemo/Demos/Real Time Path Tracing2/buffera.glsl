#define RAYS_PER_PIXEL 32
#define MAX_BOUNCES    4
#define TEMPORAL       0.75
#define NEXT_EVENT_ESTIMATION



///////////////////////
// Scene description //
///////////////////////

#define DIFF   0
#define GLOSSY 1
#define METAL  2

struct Sphere {
    vec3 color, position;
    float radius;
    int material;
};

#define NB_LIGHTS 1
Sphere lights[NB_LIGHTS] = Sphere[](
    Sphere(vec3(10.0), vec3(0.0), 0.2, 0) // position set in main
);

#define RWALL 1e2    // Radius of wall spheres
#define RADIUS 0.4   // Radius of spheres
#define NB_SPHERES 7
const Sphere spheres[NB_SPHERES] = Sphere[](
    Sphere(vec3(0.9, 0.9, 0.9), vec3( 0.0  ,  0.0  ,  RWALL       ), RWALL - 1.0, DIFF  ), // top
    Sphere(vec3(0.9, 0.9, 0.9), vec3( 0.0  ,  0.0  , -RWALL       ), RWALL - 1.0, DIFF  ), // bottom
    Sphere(vec3(0.9, 0.9, 0.9), vec3( RWALL,  0.0  ,  0.0         ), RWALL - 1.0, DIFF  ), // front
    Sphere(vec3(0.9, 0.1, 0.1), vec3( 0.0  ,  RWALL,  0.0         ), RWALL - 1.0, DIFF  ), // left red
    Sphere(vec3(0.1, 0.1, 0.9), vec3( 0.0  , -RWALL,  0.0         ), RWALL - 1.0, DIFF  ), // right blue
    Sphere(vec3(0.1, 0.9, 0.1), vec3(-0.4  , -0.4  ,  RADIUS - 1.0), RADIUS     , GLOSSY), // green sphere
    Sphere(vec3(0.9, 0.9, 0.1), vec3( 0.4  ,  0.4  ,  RADIUS - 1.0), RADIUS     , METAL )  // yellow sphere
);



////////////////
// Raytracing //
////////////////

// Intersect a sphere with a ray starting at O with direction D
// If intersection is found before tmax, return true and update tmax with the new intersection distance
// Back faces are ignored
bool intersect(Sphere s, vec3 O, vec3 D, inout float tmax) {
    vec3 L = s.position - O;
    float tc = dot(D, L);
    float t = tc - sqrt(s.radius * s.radius + tc * tc - dot(L, L));
    if (t > 0.0 && t < tmax) {
        tmax = t;
        return true;
    }
    return false;
}

// Intersect all the spheres
// Return the intersected sphere index, or -1 if no sphere found before tmax
// If intersection is found, tmax is updated with the new intersection distance
int intersectSpheres(vec3 O, vec3 D, inout float tmax) {
    int imin = -1;
    for (int i = 0; i < NB_SPHERES; i++)
        if (intersect(spheres[i], O, D, tmax))
            imin = i;
    return imin;
}

// Intersect all the lights
// Return the intersected light index, or -1 if no light found before tmax
// If intersection is found, tmax is updated with the new intersection distance
int intersectLights(vec3 O, vec3 D, inout float tmax) {
    int imin = -1;
    for (int i = 0; i < NB_LIGHTS; i++)
        if (intersect(lights[i], O, D, tmax))
            imin = i;
    return imin;
}

// Evaluate diffuse direct lighting from all lights, for next event estimation
#ifdef NEXT_EVENT_ESTIMATION
vec3 directLighting(vec3 O, vec3 N, vec2 r) {
    vec3 color = vec3(0.0);
    for (int i = 0; i < NB_LIGHTS; i++) {
        Sphere l = lights[i];
        vec3 LC = l.position - O;
        float d2 = dot(LC, LC);
        float invd = inversesqrt(d2);
        float cosL = sqrt(d2 - l.radius * l.radius) * invd;
        vec3 L = coneSample(LC * invd, cosL, r);
        float t = 1e5;
        if (intersect(l, O, L, t) && intersectSpheres(O, L, t) < 0)
            color += 2.0 * (1.0 - cosL) * max(0.0, dot(N, L)) * l.color;
    }

    return color;
}
#endif

// Compute the light radiance along a ray starting at O, with direction D.
// The computation may need to continue with a new ray to get the final color (accumulation),
// in which case it returns true and update O and D as the new ray to cast.
// indirectOnly is set to true when direct light evaluation has been done just before,
// to avoid taking direct illumination into account twice.
bool radiance(inout vec3 O, inout vec3 D, inout vec3 accumulation, inout vec3 throughput, inout bool indirectOnly, int bounces) {
    float t = 1e5;
    int iSphere = intersectSpheres(O, D, t);
    int iLight = indirectOnly ? -1 : intersectLights(O, D, t);

    if (iLight >= 0) {
        // A light has been hit, terminate the path
        accumulation += throughput * lights[iLight].color;
    } else if (iSphere >= 0) {
        // A sphere has been hit, evaluate material
        Sphere s = spheres[iSphere];
        O += t * D;
        vec3 N = normalize(O - s.position);
        float cosND = max(0.0, dot(N, -D));
        
        // Choose whether to evaluate specular or diffuse for glossy material
        bool evalSpecular = rand.z < fresnel(cosND, vec3(0.04)).x;
        bool allowCaustics = bounces < 1; // ugly hack to avoid noise from caustics
        indirectOnly = false;
        
        if (s.material == METAL && allowCaustics) {
            // Tinted mirror
            throughput *= fresnel(cosND, s.color);
            D = reflect(D, N);
        } else if (s.material == GLOSSY && evalSpecular && allowCaustics) {
            // Mirror white specular
            D = reflect(D, N);
        } else {
            // Diffuse, attenuate color with sphere color
            throughput *= s.color;
            
            // Evaluate direct lighting to help converge faster
            #ifdef NEXT_EVENT_ESTIMATION
                accumulation += throughput * directLighting(O, N, rand.xy);
                indirectOnly = true;
            #endif

            // Continue bouncing around randomly
            D = cosineSample(N, rand.xy);
        }
        
        return true;
    }
    // Else: the ray hits nothing, it escapes the scene and will not contribute

    return false;
}



//////////
// Main //
//////////

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    const uint raysPerPixel = uint(RAYS_PER_PIXEL);
    vec3 blueNoiseSeed = texelFetch(iChannel0, ivec2(fragCoord) & 0x3FF, 0).xyz;
    
    // Animate light
    if (iMouse.z < 0.5) {
        lights[0].position.xy = 0.5 * vec2(cos(0.5 * iTime), sin(iTime));
        lights[0].position.z = 0.15 * sin(0.25 * iTime) + 0.4;
    } else {
        lights[0].position.xyz = 1.5 * (iMouse.xxy / iResolution.xxy - 0.5);
        lights[0].position.y *= -1.0;
    }

    // Camera initialization
    const vec3 camPos = vec3(-2.0, 0.25, -0.5);
    const float fovy = 60.0, tanFov = tan(fovy * PI / 360.0);
    float aspectRatio = iResolution.x / iResolution.y;

    // Raytrace the pixel and accumulate result
    fragColor.rgb = vec3(0.0);
    for (uint r = 0u; r < raysPerPixel + uint(ZERO); r++) {
        // Reset random seed for maximum coherency. Blue noise takes care of the decorrelation.
        perFrameSeed = uint(iFrame) * raysPerPixel + r;
        rand = toroidalJitter(sequence3D(perFrameSeed), blueNoiseSeed);

        // Ray setup
        vec2 uv = 2.0 * (fragCoord + rand.yz) / iResolution.xy - 1.0;
        uv.x *= -aspectRatio;
        vec3 O = camPos;
        vec3 D = normalize(vec3(1.0, tanFov * uv));
        vec3 accumulation = vec3(0.0);
        vec3 throughput = vec3(1.0); // Neutral value

        // Trace
        int bounces = 0;
        bool indirectOnly = false;
        while (radiance(O, D, accumulation, throughput, indirectOnly, bounces) && bounces++ < MAX_BOUNCES)
            rand = toroidalJitter(sequence3D(perFrameSeed = lcg(perFrameSeed)), blueNoiseSeed);

        fragColor.rgb += accumulation;
    }

    fragColor.rgb *= 1.0 / float(raysPerPixel);
    fragColor.a = 1.0;
    
    // Accumulate with previous frames
    fragColor.rgb = mix(fragColor.rgb, texelFetch(iChannel1, ivec2(fragCoord), 0).rgb, TEMPORAL);
}