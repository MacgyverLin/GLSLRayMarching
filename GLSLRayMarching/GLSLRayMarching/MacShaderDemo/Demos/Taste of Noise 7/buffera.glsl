// taste of noise 7 by leon denise 2021/10/14
// result of experimentation with organic patterns
// using code from Inigo Quilez, David Hoskins and NuSan
// thanks to Fabrice Neyret for code reviews
// licensed under hippie love conspiracy

// global variable
float material;
float rng;

// sdf
float map (vec3 p)
{
    // time stretched with noise
    float t = iTime*1. + rng*0.9;
    
    // domain repetition
    float grid = 5.;
    vec3 cell = floor(p/grid);
    p = repeat(p,grid);
    
    // distance from origin
    float dp = length(p);
    
    // rotation parameter
    vec3 angle = vec3(.1,-.5,.1) + dp*.5 + p*.1 + cell;
    
    // shrink sphere size
    float size = sin(rng*3.14);
    
    // stretch sphere
    float wave = sin(-dp*1.+t+hash13(cell)*6.28)*.5;
    
    // kaleidoscopic iterated function
    const int count = 4;
    float a = 1.0;
    float scene = 1000.;
    float shape = 1000.;
    for (int index = 0; index < count; ++index)
    {
        // fold and translate
        p.xz = abs(p.xz)-(.5+wave)*a;
        
        // rotate
        p.xz *= rot(angle.y/a);
        p.yz *= rot(angle.x/a);
        p.yx *= rot(angle.z/a);
        
        // sphere
        shape = length(p)-0.2*a*size;
        
        // material blending
        material = mix(material, float(index), smoothing(shape, scene, 0.3*a));
        
        // add with a blend
        scene = smin(scene, shape, 1.*a);
        
        // falloff transformations
        a /= 1.9;
    }
        
    return scene;
}

// return color from pixel coordinate
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // reset color
    fragColor = vec4(0,0,0,1);
    material = 0.0;
    
    // camera coordinates
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
    vec3 eye = vec3(1,1,1.);
    vec3 at = vec3(0,0,0);
    vec3 z = normalize(at-eye);
    vec3 x = normalize(cross(z, vec3(0,1,0)));
    vec3 y = cross(x, z);
    vec3 ray = normalize(vec3(z + uv.x * x + uv.y * y));
    vec3 pos = eye;
    
    // camera control
    vec2 M = 6.28*(iMouse.xy-.5);
    ray.xz *= rot(M.x), pos.xz *= rot(M.x);
    ray.xy *= rot(M.y), pos.xy *= rot(M.y);
    
    // white noise
    vec3 seed = vec3(fragCoord.xy, iTime);
    rng = hash13(seed);
    
    // raymarch
    const float steps = 30.0;
    float index;
    for (index = steps; index > 0.0; --index)
    {
        // volume estimation
        float dist = map(pos);
        if (dist < 0.01)
        {
            break;
        }
        
        // dithering
        dist *= 0.9 + .1 * rng;
        
        // raymarch
        pos += ray * dist;
    }
    
    // ambient occlusion from steps count
    float shade = index/steps;

    // compute normal by NuSan (https://www.shadertoy.com/view/3sBGzV)
    vec2 off=vec2(.001,0);
    vec3 normal = normalize(map(pos)-vec3(map(pos-off.xyy), map(pos-off.yxy), map(pos-off.yyx)));

    // Inigo Quilez color palette (https://iquilezles.org/articles/palettes)
    vec3 tint = .5+.5*cos(vec3(3,2,1)+material*.5+length(pos)*.5);

    // lighting
    float ld = dot(reflect(ray, normal), vec3(0,1,0))*0.5+0.5;
    vec3 light = vec3(1.000,0.502,0.502) * sqrt(ld);
    ld = dot(reflect(ray, normal), vec3(0,0,-1))*0.5+0.5;
    light += vec3(0.400,0.714,0.145) * sqrt(ld)*.5;

    // pixel color
    fragColor.rgb = (tint + light) * shade;

    // temporal buffer
    fragColor = max(fragColor, texture(iChannel0, fragCoord/iResolution.xy) - 0.01);
}

