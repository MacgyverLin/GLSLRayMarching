
// Particles Party

// simple colorful particles system
// will try voronoi tracking next time

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 color = vec3(0);
    
    // coordinates
    vec2 uv = fragCoord/iResolution.xy;
    float rng = texture(iChannel1, fragCoord/1024.).r;
    vec2 aspect = vec2(iResolution.y/iResolution.x, 1.);
    
    // data
    vec4 data = texture(iChannel0, uv);
    float shade = data.r;
    float mat = data.g;
    
    // rainbow
    color = .5+.5*cos(vec3(1,2,3)*4.9 + mat);
    
    // light
    vec3 un = vec3(0.005*aspect, 0);
    #define T(un) texture(iChannel0, uv+un).r
    vec3 normal = normalize(vec3(T(un.xz)-T(-un.xz),T(un.zy)-T(-un.zy), .5));
    float d = dot(normal, normalize(vec3(0,-2,1)))*.5+.5;
    color += pow(d, 10.);
    
    // shadow
    color *= smoothstep(.0,.01,shade);

    fragColor = vec4(color, 1);
}