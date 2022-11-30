//increase this number for a better GI
#define IndirectSamples 1

//increase to remove more noise, but might make the result blurrier
#define SamplesLimit 40

//GI bounces
#define Bounces 1


#define PixelAcceptance 1.5
#define PixelCheckDistance .5



#define Pi 3.14159265359

#define MaxStepsDirect 128
#define MaxStepsIndirect 32
#define MaxShadowSteps 32
#define MaxDist 4.
#define MinDist .015

#define DoFClamping .3
#define DoFSamples 32

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
    vec3 rot = vec3(0., (sin(time*.75)+time*.75)/4., .3);
    return Camera(vec3(0., 0., -20.) * rotationMatrix(rot), rot, 2., 17.5, .04);
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

    

float sdf(vec3 position){
    float Scale = 2.25;
    float Radius = .25;
    int Iterations = 6;
    mat3 Rotation;
    
    //float time = 75.;
    float time = 104.;
    //float time = 120.;
    
    Rotation = rotationMatrix(vec3(time, time*.7, time*.4)*.2);
    Scale += sin(time*.5)*.25;
    Radius += cos(time) *.25;
    
    position *= Rotation;
	vec4 scalevec = vec4(Scale, Scale, Scale, abs(Scale)) / Radius;
	float C1 = abs(Scale-1.0), C2 = pow(abs(Scale), float(1-Iterations));
	vec4 p = vec4(position.xyz, 1.0), p0 = vec4(position.xyz, 1.0);
	for (int i=0; i< Iterations; i++) {
    	p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
    	p.xyzw *= clamp(max(Radius/dot(p.xyz, p.xyz), Radius), 0.0, 1.0);
        if(i < 3) p.xyz *= Rotation;
    	p.xyzw = p*scalevec + p0;
	}
	return (length(p.xyz) - C1) / p.w - C2;
}

vec3 normalEstimation(vec3 pos){
  vec2 k = vec2(MinDist, 0);
  return normalize(vec3(sdf(pos + k.xyy) - sdf(pos - k.xyy),
	  					sdf(pos + k.yxy) - sdf(pos - k.yxy),
  						sdf(pos + k.yyx) - sdf(pos - k.yyx)));
}