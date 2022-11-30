//increase this number for a better GI
#define IndirectSamples 1

//increase to remove more noise, but might make the result blurrier
#define SamplesLimit 150

//GI bounces
#define Bounces 1


#define PixelAcceptance 1.5
#define PixelCheckDistance .5



#define Pi 3.14159265359

#define MaxStepsDirect 128
#define MaxStepsIndirect 32
#define MaxShadowSteps 32
#define FogSteps 8

#define MaxDist 4.
#define MinDist .015

#define DoFClamping .3
#define DoFSamples 128

#define Density vec3(.0025, .0045, .006)
#define Anisotropy .4
#define FogRange 13.


vec3 LightDir = normalize(vec3(.0, .0, -1));
vec3 LightColor = vec3(1.) * 6.;
float LightRadius = .02;

struct Camera {
    vec3 pos, rot;
    float focalLength, focalDistance, aperture;
};


mat3 rotationMatrix(vec3 rotEuler){
    float c = cos(rotEuler.x), s = sin(rotEuler.x);
    mat3 rx = mat3(1, 0, 0, 0, c, -s, 0, s, c);
    c = cos(rotEuler.y), s = sin(rotEuler.y);
    mat3 ry = mat3(c, 0, -s, 0, 1, 0, s, 0, c);
    c = cos(rotEuler.z), s = sin(rotEuler.z);
    mat3 rz = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    
    return rz * rx * ry;
}

Camera getCam(float time){
    //time = 0.;
    vec3 rot = vec3(cos(time*.4)/6., 1. + time*.2 + sin(time*.2)/4., .5);
    return Camera(vec3(0., 0., -10.) * rotationMatrix(rot), rot, 1., 7.5, .025);
}

vec3 uv2dir(Camera cam, vec2 uv){
    return normalize(vec3(uv, cam.focalLength)) * rotationMatrix(cam.rot);
}

vec2 pos2uv(Camera cam, vec3 pos){
    vec3 dir = normalize(pos - cam.pos) * inverse(rotationMatrix(cam.rot));
    return dir.xy * cam.focalLength / dir.z;
}

vec3 dirFromUv(Camera cam, vec2 uv){
    return normalize(vec3(uv, cam.focalLength)) * rotationMatrix(cam.rot);
}


float sdf(vec3 position, out vec3 diffuseColor, out vec3 emissionColor){
    diffuseColor = vec3(1.);
    emissionColor = vec3(0.);
    float Scale = 2.25;
    float Radius = .25;
    mat3 Rotation;
    
    float time = 15.;
    
    Rotation = rotationMatrix(vec3(time, time*.7, time*.4)*.2);
    Scale += sin(time*.5)*.25;
    Radius += cos(time) *.25;
    
	vec4 scalevec = vec4(Scale, Scale, Scale, abs(Scale)) / Radius;
	float C1 = abs(Scale-1.0), C2 = pow(abs(Scale), float(1- /*iterations*/7));
	vec4 p = vec4(position.xyz*Rotation, 1.0), p0 = p;
	for (int i = 0; i<7; i++) {
    	p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
    	p.xyzw *= clamp(max(Radius/dot(p.xyz, p.xyz), Radius), 0.0, 1.0);
        if(i < 3) p.xyz *= Rotation;
    	p.xyzw = p*scalevec + p0;
	}
    /*diffuseColor = fract(p0.x)<.1 ? vec3(.2) : vec3(1.);
    emissionColor = fract(p0.x)<.1 ? (normalize(p.xyz)*.5+.5)*10. : vec3(0.);*/
	return (length(p.xyz) - C1) / p.w - C2;
}

float sdf(vec3 position){
    vec3 dc, ec;
    return sdf(position, dc, ec);
}

vec3 normalEstimation(vec3 pos){
  vec2 k = vec2(MinDist, 0);
  return normalize(vec3(sdf(pos + k.xyy) - sdf(pos - k.xyy),
	  					sdf(pos + k.yxy) - sdf(pos - k.yxy),
  						sdf(pos + k.yyx) - sdf(pos - k.yyx)));
}

float henyeyGreenstein(vec3 dirI, vec3 dirO){
	float cosTheta = dot(dirI, dirO);
 	return Pi/4.0 * (1.0-Anisotropy*Anisotropy) / pow(1.0 + Anisotropy*Anisotropy - 2.0*Anisotropy*cosTheta, 3.0/2.0);
}

vec3 directLight(vec3 pos, vec3 normal){
    //return vec3(0.);
    float dotLight = -dot(normal, LightDir);
    if(dotLight < 0.0) return vec3(0);
    vec3 pos0 = pos;
    float minAngle = LightRadius;
    for(int i = 0; i < MaxShadowSteps; i++){
        float dist = sdf(pos);
        if(dist > MaxDist) break;
        if(dist < MinDist) return vec3(0.0);
        pos -= LightDir * dist * 2.5;	//goes 2.5 times faster since we don't need details
        minAngle = min(asin(dist/length(pos-pos0)), minAngle);
    }
    return LightColor * dotLight * clamp(minAngle/LightRadius, .0, 1.0);
}