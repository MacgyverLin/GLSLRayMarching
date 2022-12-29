#define NEW_SKY

#define MIN_DIST .005
#define MAX_STEPS 200

float height(vec3 ro) {return texture(iChannel0,vec2(ro.x/100.,ro.z/100.)).x*7.;}

vec2 plane(vec3 ro, vec3 pos) {
    float h = height(ro);
    h += texture(iChannel1,vec2(ro.x/2.,ro.z/2.)).x/4.;
 	return vec2(ro.y-pos.y-h, abs(sin(ro.x/2.)+cos(ro.z/2.)));   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
	uv -= .5;
    uv *= 2.;
    uv.x *= iResolution.x/iResolution.y;
    
    float speed = 2.;
    float zoom = 2.;
    float angle = 0.;
    vec3 up = vec3(sin(angle),cos(angle),0.);
    vec3 ro = vec3(2.*sin(.2*iTime),4.1,speed*iTime);
    ro.y = height(ro)+.3;
    float heightFront = height(vec3(ro.x,ro.y,ro.z+.75));
    vec3 target = vec3(4.*sin(.1+.2*iTime)/heightFront,heightFront+.5,ro.z+1.);
    vec3 f = normalize(target-ro);
    vec3 r = normalize(cross(up,f));
    vec3 u = cross(f,r);
    vec3 c = ro + f*zoom;
    vec3 camera = c + uv.x*r + uv.y*u;
    vec3 rd = normalize(camera-ro);
    vec3 ray = ro;
    
    vec3 col = vec3(0.);
    
    // Sky
    #ifdef NEW_SKY
    float skyHeight = 200.;
    float d = skyHeight - ro.y;
    float numsteps = d / rd.y;
    vec3 intersection = ro - rd*numsteps;
    vec2 skyUv = intersection.xz * .00013;
    vec3 skyBaseColor = vec3(0.,.6,1.);
    
    if (rd.y > 0.)
        col = skyBaseColor + vec3(texture(iChannel0, skyUv).r)*vec3(1.5,0.,0.);
    #else
    col = vec3(0.,.6,1.)+vec3(texture(iChannel0,vec2((uv.x+camera.x*2.)/6.,uv.y+camera.y*2.)).r);
    #endif
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 d = plane(ray, vec3(0.,0.,0.));
        if (d.x < MIN_DIST) {
          float light = .3/pow(distance(ray,ro)/5.+.1,1.6)*distance(ray,ro)*.1;
          light += .1/pow(distance(ray,ro)+.1,2.6);
          col = vec3(.14*light+.01,.6*light+.04,.13*light+.01)*2.;
          break;
        }
        
        ray += rd*d.x;
    }
    
    // Output to screen
    fragColor = vec4(col,1.0);
}