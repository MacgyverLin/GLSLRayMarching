void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 texCoord = fragCoord.xy / iResolution.xy; 
    vec2 thetaphi = ((texCoord * 2.0) - vec2(1.0)) * vec2(3.1415926535897932384626433832795, 1.5707963267948966192313216916398); 
    vec3 rayDirection = vec3(cos(thetaphi.y) * cos(thetaphi.x), sin(thetaphi.y), cos(thetaphi.y) * sin(thetaphi.x));
	fragColor = texture(iChannel0, rayDirection);
    // for apply the equirectangular map like a cubemap:
    // rayDirection = normalize(rayDirection);
    // texture(uTexEnvMap, vec2((atan(rayDirection.z, rayDirection.x) / 6.283185307179586476925286766559) + 0.5, acos(rayDirection.y) / 3.1415926535897932384626433832795));    
}