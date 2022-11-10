float vmax(vec2 v) {return max(v.x, v.y);}
float fBox2(vec2 p, vec2 b) {return vmax(abs(p)-b);}

mat2 rot(float a) {float s=sin(a), c=cos(a); return mat2(c,s,-s,c);}
float wf1(vec2 p){return sin(p.x) + cos(p.y);}

float cappedCylinder(vec3 p, float h, float r){
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r, h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 gl = vec3(0.);
float gl1 = 0.;
vec3 gl2 = vec3(0.);

vec3 map(vec3 p) {
    vec3 r = vec3(0.);
    vec3 d = vec3(0.);
    p.xz *= rot(iTime * .5);
    vec3 m = p;
    p.xz *= rot(sin(-p.y * .5) * 1.1);
    p.xz = abs(p.zx)-vec2(.8);
    float i = sin(p.y * 3. + iTime * 10.) * .5 + .5;
    float b = cappedCylinder(p,  5.5 , ((i - .5) * 2. * .3) * cos(p.y * .2));
    gl += (.0004/(.01+b*b)) * mix(vec3(1.,0.,1.), vec3(1.,1.,0.), p.y);
    r.x = max(cappedCylinder(p, 2., .3 + .2 * i), -cappedCylinder(p, 3., .2 + .25 * i));
    p.xz *= rot(p.y * 3. + iTime * 2.);
    vec3 q = p;
    q.xz *= rot(3.14/2.);
    if (fBox2(p.xy, vec2(.2, 10.)) < 0.) r.yz = vec2(3.,0.); 
    else if (fBox2(q.xy, vec2(.2, 10.)) < 0.) r.yz = vec2(4., 0.);
    else r.yz = vec2(1.);
    gl1 += (.000001/(.000001+pow(r.x+.003, 2.)));
    d.x = min(r.x, cappedCylinder(p, 8.5 , (.25 + (i - .5) * 2. * .15) * cos(p.y * .2)));
    d.y = 2.;
    if (r.x > d.x) r = d;
    p = m;
    d.x = length(p) - .45 - .1 * (sin(iTime * 10.) * .5 + .5);
    gl2 += (.0006/(.01+d.x*d.x)) * mix(vec3(1.,0.,1.), vec3(1.,1.,0.), m.y);
    if (r.x > d.x) r = d;
    p = m;
    if (p.y > 0.) p.xz *= rot(.3);
    p = abs(p);
    p.zx *= rot(-3.14/4.);
    p.xy *= rot(-3.14/4.);
    p.y -= 1.;
    q = p;
    p.yx *= rot( sin(p.y * 3.14) * .3 );
    d.x =  cappedCylinder(p, 1. , (.06 + (i - .5) * 2. * .04));
    p = q; p.y -= 1.;
    d.x = min(d.x, length(p) - .15 - .05 * (sin(iTime * 10. + 1.5) * .5 + .5));
    gl2 += (.0003/(.01+d.x*d.x)) * mix(vec3(1.,0.,1.), vec3(1.,1.,0.), -m.y);
    d.y = 2.;
    if (r.x > d.x) r = d;
    return r;
}

const vec2 e = vec2(.00035, -.00035);
vec3 norm(vec3 po) {
        return normalize(e.yyx*map(po+e.yyx).x + e.yxy*map(po+e.yxy).x +
                         e.xyy*map(po+e.xyy).x + e.xxx*map(po+e.xxx).x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    vec3 ro = vec3(0.,3.,-6.),
         rd = normalize(vec3(uv,1.)),
         p, h;
    rd.yz *= rot(-.4);
    float t = 0.;
    for(int i = 0; i < 120; i++) {
         p = ro + rd * t;
         h = map(p);
         if (h.x<.0001||t>40.) {
             if (h.z == 1.) h.x = abs(h.x) + .0001;
             else break;
         };
         t += h.x * .7;
    }
    vec3 ld = vec3(0., 1.,0.);
    vec3 ld1 = vec3(3., 3., 0.);
    ld1.xz *= rot(iTime * .3); 
    vec3 col = vec3(.1);
    if (h.x<.0001) {
        if (h.y == 1.) col = vec3(.1, .3, .2);
        if (h.y == 2.) col = vec3(.7,.7,.3);
        if (h.y == 3.) col = vec3(.5, .9, .5);
        if (h.y == 4.) col = vec3(.5, .5, .9);
    }
    col = mix(col, vec3(.1, .3, .2), clamp(gl1,0.,1.));
    col += gl;
    col += gl2;
    fragColor = vec4(col,1.0);
}