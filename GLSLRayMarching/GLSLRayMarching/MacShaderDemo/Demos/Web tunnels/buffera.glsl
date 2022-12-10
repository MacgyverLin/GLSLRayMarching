//this is based on https://www.shadertoy.com/view/4tcGDr



vec3 surface_color(vec3 p)
{
    //p = floor(mod(p,10.0));
    return sin(floor(vec3(planet_surface(p,3.0),planet_surface(p,5.0),planet_surface(p,7.0))))/10.0+vec3(.6);
}


/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the ey to march before giving up
 */
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON*(1.0+depth*.1)*image_scale) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
} 

/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * fragCoord: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}


/**
 * Return a transform matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction. See rayDirection.
 */
mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
		if (fragCoord.x*image_scale<iResolution.x && fragCoord.y*image_scale<iResolution.y){
    fragCoord *= image_scale;
    vec3 viewDir = rayDirection(45.0, iResolution.xy, fragCoord);
    if (length(iMouse.xy) > 40.0) {
        viewDir.yz *= rot(3.14*0.5-iMouse.y/iResolution.y*3.14);
        viewDir.xz *= rot(3.14-iMouse.x/iResolution.x*3.14*2.0);
    }
    
    const float speed = 10.0;
	vec3 eye = vec3(iTime*speed,0,1.0);
    
    mat3 viewToWorld = -viewMatrix(eye, eye+vec3(-5,sin(iTime*speed/10.0), cos(iTime*speed/10.0)), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = viewToWorld * viewDir;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    fragColor = vec4(p, 1.0);
    }
}