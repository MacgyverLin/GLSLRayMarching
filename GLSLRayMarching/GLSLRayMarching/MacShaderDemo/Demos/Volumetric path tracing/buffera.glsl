#define Pi 3.14159265359

#define VolumePrecision .3
#define SceneRadius 1.2
#define ShadowRaysPerStep .2
#define MaxSteps 100
#define MaxAbso .8
#define MaxShadowAbso .6

vec3 CamPos = vec3(0, 0, -2.5);
vec3 CamRot = vec3(.7, -2.4, .0);
float CamFocalLength = 3.2;
float CamFocalDistance = 2.3;
float CamAperture = .02;

vec3 LightColor = vec3(1.7);
vec3 LightDir = normalize(vec3(-1, -.2, 0));

float Power = 8.0;
float PhiShift = 0.0;
float ThetaShift = 0.0;

float Density = 200.0;

float StepSize;

vec3 VolumeColor = vec3(.9, .9, .95);

vec2 seed;

float rand(vec2 n) {
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float randomFloat(){
  seed += vec2(1.153535, -1.1231354);
  return rand(seed);
}

mat3 rotationMatrix(vec3 rotEuler){
    float c = cos(rotEuler.x), s = sin(rotEuler.x);
    mat3 rx = mat3(1, 0, 0, 0, c, -s, 0, s, c);
    c = cos(rotEuler.y), s = sin(rotEuler.y);
    mat3 ry = mat3(c, 0, -s, 0, 1, 0, s, 0, c);
    c = cos(rotEuler.z), s = sin(rotEuler.z);
    mat3 rz = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    
    return rz * rx * ry;
}

float maxV(vec3 v){
    return v.x > v.y ? v.x > v.z ? v.x : v.z : v.y > v.z ? v.y : v.z;
}

vec3 backgroundColor(vec3 dir){
    vec3 col = texture(iChannel1, dir).rgb;
    return col*col + col;
}

vec3 randomDir(){
    return vec3(1, 0, 0) * rotationMatrix(vec3(randomFloat()*2.0*Pi, 0, randomFloat()*2.0*Pi));
}

float distanceEstimation(vec3 pos) {
    
    pos.y = -pos.y;
    
    float r = length(pos);
    vec3 z = pos;
    vec3 c = pos;
	float dr = 1.0, theta, phi;
	for (int i = 0; i < 6; i++) {
		r = length(z);
		if (r>SceneRadius) break;
		theta = acos(z.y/r);
		phi = atan(z.z,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		theta *= Power + ThetaShift;
		phi *= Power + PhiShift;
		z = pow(r,Power)*vec3(sin(theta)*cos(phi), cos(theta), sin(phi)*sin(theta)) + c;
	}
	return 0.5*log(r)*r/dr;
}

vec3 directLight(vec3 pos){
    
    vec3 absorption = vec3(1.0);
    
    for(int i = 0; i < MaxSteps; i++){
        float dist = distanceEstimation(pos);
        pos -= LightDir * max(dist, StepSize);
        if(dist < StepSize) {
            float abStep = StepSize * randomFloat();
            pos -= LightDir * (abStep-StepSize);
            if(dist < 0.0){
                float absorbance = exp(-Density*abStep);
                absorption *= absorbance;
                if(maxV(absorption) < 1.0-MaxShadowAbso) break;
            }
        }
        
        if(length(pos) > SceneRadius) break;
    }
    return LightColor * max((absorption+MaxShadowAbso-1.0) / MaxShadowAbso, vec3(0));
}

vec3 pathTrace(vec3 rayPos, vec3 rayDir){
    
   	rayPos += rayDir * max(length(rayPos)-SceneRadius, 0.0);
    
    vec3 outColor = vec3(0.0);
    vec3 absorption = vec3(1.0);
    
    for(int i = 0; i < MaxSteps; i++){
        float dist = distanceEstimation(rayPos);
        rayPos += rayDir * max(dist, StepSize);
        if(dist < StepSize && length(rayPos) < SceneRadius) {
            float abStep = StepSize * randomFloat();
            rayPos += rayDir * (abStep-StepSize);
            if(dist < 0.0){
                
                float absorbance = exp(-Density*abStep);
                float transmittance = 1.0-absorbance;
                
                //surface glow for a nice additional effect
                //if(dist > -.0001) outColor += absorption * vec3(.2, .2, .2);
                
                if(randomFloat() < ShadowRaysPerStep) outColor += 1.0/ShadowRaysPerStep * absorption * transmittance * VolumeColor * directLight(rayPos);
                if(maxV(absorption) < 1.0-MaxAbso) break;
                if(randomFloat() > absorbance) {
                    rayDir = randomDir();
                    absorption *= VolumeColor;
                }
            }
        }
        
        if(length(rayPos) > SceneRadius && dot(rayDir, rayPos) > 0.0)
            return outColor + backgroundColor(rayDir) * absorption;
    }
    
    return outColor;
}

//n-blade aperture
vec2 sampleAperture(int nbBlades, float rotation){
    
    float alpha = 2.0*Pi / float(nbBlades);
    float side = sin(alpha/2.0);
    
    int blade = int(randomFloat() * float(nbBlades));
    
    vec2 tri = vec2(randomFloat(), -randomFloat());
    if(tri.x+tri.y > 0.0) tri = vec2(tri.x-1.0, -1.0-tri.y);
    tri.x *= side;
    tri.y *= sqrt(1.0-side*side);
    
    float angle = rotation + float(blade)/float(nbBlades) * 2.0 * Pi;
    
    return vec2(tri.x * cos(angle) + tri.y * sin(angle),
                tri.y * cos(angle) - tri.x * sin(angle));
}

//used to store values in the unused alpha channel of the buffer
void setVector(int index, vec4 v, vec2 fragCoord, inout vec4 fragColor){
    fragCoord -= vec2(.5);
    if(fragCoord.y == float(index)){
        if(fragCoord.x == 0.0) fragColor.a = v.x;
        if(fragCoord.x == 1.0) fragColor.a = v.y;
        if(fragCoord.x == 2.0) fragColor.a = v.z;
        if(fragCoord.x == 3.0) fragColor.a = v.a;
    }
}

vec4 getVector(int index){
    return vec4(texelFetch(iChannel0, ivec2(0, index), 0).a,
                texelFetch(iChannel0, ivec2(1, index), 0).a,
                texelFetch(iChannel0, ivec2(2, index), 0).a,
                texelFetch(iChannel0, ivec2(3, index), 0).a
               );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    StepSize = min(1.0/(VolumePrecision*Density), SceneRadius/2.0);
    
    vec2 uv = (fragCoord+vec2(randomFloat(), randomFloat())-iResolution.xy/2.0) / iResolution.y;
    
    seed = fragCoord/iResolution.xy * 1000.0 + log(vec2(iFrame));
    
    float samples = texelFetch(iChannel0, ivec2(0, 0), 0).a;
    if(iFrame > 0) CamRot = getVector(1).xyz;
    vec4 prevMouse = getVector(2);
    
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    
    bool mouseDragged = iMouse.z >= 0.0 && prevMouse.z >= 0.0 && iMouse != prevMouse;
    
    if(mouseDragged) CamRot.yx += (prevMouse.xy-iMouse.xy)/iResolution.y * 2.0;
    
    if(iFrame == 0 || mouseDragged){
        fragColor = vec4(0.0);
        samples = 0.0;
    }
    
    setVector(1, vec4(CamRot, 0), fragCoord, fragColor);
    setVector(2, iMouse, fragCoord, fragColor);
    if(fragCoord-vec2(.5) == vec2(0)) fragColor.a = samples+1.0;
    
    vec3 focalPoint = vec3(uv * CamFocalDistance / CamFocalLength, CamFocalDistance);
    vec3 aperture = CamAperture * vec3(sampleAperture(6, 0.0), 0.0);
    vec3 rayDir = normalize(focalPoint-aperture);
    
    mat3 CamMatrix = rotationMatrix(CamRot);

    CamPos *= CamMatrix;
    rayDir *= CamMatrix;
    aperture *= CamMatrix;
    
    fragColor.rgb = mix(fragColor.rgb,pathTrace(vec3(0, .8, 0) + CamPos+aperture,rayDir),1.0/(samples+1.0));
    
}