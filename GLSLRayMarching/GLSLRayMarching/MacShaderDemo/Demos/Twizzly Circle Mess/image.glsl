// "RayMarching starting point" 
// by Martijn Steinrucken aka The Art of Code/BigWings - 2020
// The MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
// Facebook: https://www.facebook.com/groups/theartofcode/
//
// You can use this shader as a template for ray marching shaders

// set these really low so my computer can handle it + dont mind the glitchy look
#define MAX_STEPS 40
#define MAX_DIST 20.
#define SURF_DIST 0.05

#define S smoothstep
#define T iTime

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
} 

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

float GetDist(vec3 p) {

    float sd = length(p - vec3(0,1.5 + 0.5 * cos(iTime),0)) 
               - 0.6  + 0.1 * cos(2. * iTime);

    float a = atan(p.x, p.z);
    float l = length(p.xz);
    float lf = length(fract(p.xz)-0.5);
 //   p.y += 0.2 * thc(2., 5. * l * (.5 + .5 * thc(2., 1. * l - iTime)) + a + 1. * iTime) / cosh(0.35 * l);
    
   // vec2 ipos = floor(p.xz) - 0.;
    //vec2 fpos = fract(p.xz) - 0.25;
    
    //p.y += 1./cosh(mix(12.,40., .5 + .5 * thc(4., iTime + 11. * h21(ipos))) * lf);
    p.y *= 1. / cosh(0.5 * l + cos(a + iTime));
    p.y += mix(0., 0.15, .5 + .5 * thc(2., 4. * l +  iTime)) * thc(4., 4. * l + iTime);
    float d = dot(p, vec3(0,1,0));//length(p) - 1.5;
    
   
    return  min(d, 1. * sd);
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

vec3 Bg(vec3 rd) {
    float k = rd.y*.5 + .5;
    
    vec3 col = mix(vec3(.5,0.,0.),vec3(0.),k);
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;
    float time = 0.25 * iTime;
    vec3 ro = vec3(4. * thc(5.,time), mix(2., 5., .5 + .5 * thc(3., 1.5 * time)), 4. * ths(5.,time));
    //ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd);

    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        vec3 rf = refract(rd, n,0.1);
        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = 0.42 *vec3(dif);
        
        float b = .5 + .5 * cos(iTime);
        
        uv = fragCoord.xy / iResolution.xy;
        col += 0.9 * texture(iChannel0,r / (0.5 + n)).rgb;
         
        float a = atan(rf.z, rf.x);
        float c = atan(rf.z,rf.y);
        col.r += 0.15 + .25 * thc(2.,10. * rf.x + iTime - 3.1415 / 2.);
        col.g += 0.15 + .25 * thc(2.,10. * rf.y + iTime);
        col.b += 0.15 + .25 * thc(2.,10. * rf.z + iTime + 3.1415 / 2.);
        
        float l = length(p);
        float pa = atan(p.x ,p.z);
        col *= 0.7 + .5 * thc(6. + 6. * cos(20. * l + 10. * pa + iTime), 
                              1.2 * l - 24. * pa - 0.5 * cos(l * 10. + 2. * pa + iTime) -  2. * iTime);
       // col *= 1.5;
    } else {
        col = texture(iChannel0, rd).rgb;
    }
    
    col.y = .5 * (col.x + col.z);
    
    col = pow(col, vec3(.4545));	// gamma correction
    
    fragColor = vec4(col,1.0);
}