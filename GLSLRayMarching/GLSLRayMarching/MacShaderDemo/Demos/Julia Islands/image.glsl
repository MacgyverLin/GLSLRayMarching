float bumpiness = 1.0;

vec3 norm(in vec2 fragCoord)
{
    float dX = texture(iChannel0, (fragCoord + vec2(1,0))/iResolution.xy).x - texture(iChannel0, (fragCoord + vec2(-1,0))/iResolution.xy).x;
    float dY = texture(iChannel0, (fragCoord + vec2(0,1))/iResolution.xy).x - texture(iChannel0, (fragCoord + vec2(0,-1))/iResolution.xy).x;

    return normalize( vec3(-dX * bumpiness, -dY * bumpiness, 1.0) );
}

vec3 landColor(float h)
{
    float hn = h*0.5 + 0.5;
    return vec3(0.1, 0.3, 0.4) + vec3(hn, 0.7*hn, 0.4*hn);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Output to screen
    vec3 n = norm(fragCoord);
    vec3 c = vec3(1.0) * dot(n, normalize(vec3(-1.0, 1.0, 0.0)));
    float h = texture(iChannel0, uv).z;
    if(h < 0.0) {
        float rH = texture(iChannel0, uv+n.xy*0.5*h).z;
        fragColor = vec4(c.xyz, 1.0) + vec4(landColor(rH),1.0);
    } else {
        fragColor = vec4(landColor(h),1.0);
    }
}