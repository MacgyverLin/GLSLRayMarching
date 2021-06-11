#define APERTURE 0.2      /* diameter of the lens */
#define VERTICAL_FOV 25.  /* degrees */

#define MAX_BOUNCES 7
#define SAMPLES_PER_PIXEL 8

// Feature flags
#define DIFFUSE 1
#define SPECULAR 1
#define EMISSIVE 1
#define SKY 1

#define SRGB_TO_LINEAR(R,G,B) pow(vec3(R,G,B) / vec3(255,255,255), vec3(2.2))
const vec3 _gold   = SRGB_TO_LINEAR(255,226,115);
const vec3 _silver = SRGB_TO_LINEAR(252,250,245);
const vec3 _copper = SRGB_TO_LINEAR(250,208,192);

const float _skyBrightness = .3;
vec3 _skyColor;

const int _numRows = 6;
const int _numColumns = 6;
const int _numSpheres = (_numRows) * (_numColumns) + 2;
Sphere[_numSpheres] _spheres;

void InitScene()
{
    vec3 v = vec3(.15,.5,.85);
    
    // Ground
	_spheres[0].Center = vec3(0,-1000,0);
    _spheres[0].Radius = 1000.;
    _spheres[0].Mat.BaseColor = v.bbb;
    _spheres[0].Mat.Metalness = 0.;
    _spheres[0].Mat.Roughness = 0.33;
    _spheres[0].Mat.Emissive = 0.;
    _spheres[0].Mat.IsCheckerHack = true;
    
    // Light    
	_spheres[1].Center = vec3(20);
    _spheres[1].Radius = 10.;
    _spheres[1].Mat.BaseColor = vec3(1);
    _spheres[1].Mat.Metalness = 0.;
    _spheres[1].Mat.Roughness = 0.;
    _spheres[1].Mat.Emissive = 15.;
    _spheres[1].Mat.IsCheckerHack = true;
    
    int i = 2;
    for (int z = 0; z < _numColumns; z++)
    {
        for (int x = 0; x < _numRows; x++)
        {
            _spheres[i].Center = vec3(-2.5 * _numRows / 2 + 2.5 * x, 2., -2.5 * _numColumns / 2 + 2.5 * z);
            _spheres[i].Radius = 1.;
            _spheres[i].Mat.BaseColor = _silver;
            _spheres[i].Mat.Metalness = float(x) / _numRows + 0.1;
            _spheres[i].Mat.Roughness = float(z) / _numColumns + 0.1;
            _spheres[i].Mat.Emissive = 0.;
            _spheres[i].Mat.IsCheckerHack = false;

            i++;
        }
    }
}


// OTHER //////////////////////////////////////////////////////////////////////////////////
    
vec4 EncodeNumFramesAccumulated(float frame)
{
    return vec4(frame,0,0,0);
}

float DecodeNumFramesAccumulated()
{
    return texelFetch(iChannel0, ivec2(0,0), 0).r;
}

mat3 ViewLookAtMatrix(vec3 eye, vec3 target, float roll)
{
	vec3 rollVec = vec3(sin(roll), cos(roll), 0.);
	vec3 w = normalize(eye-target); // right handed TODO Change all math to left handed? 
	vec3 u = normalize(cross(rollVec,w));
	vec3 v = normalize(cross(w,u));
    return mat3(u, v, w);
}
      

// SCENE //////////////////////////////////////////////////////////////////////////////////
           
bool HitSphere(Sphere sph, Ray ray, float tMin, float tMax, inout Hit outHit)
{
    vec3 oc = ray.Origin - sph.Center;
    
    float a = dot(ray.Dir, ray.Dir);
    float half_b = dot(oc, ray.Dir);
    float c = length2(oc) - sph.Radius*sph.Radius;
    float discriminant = half_b*half_b - a*c;
    
    
    if (discriminant > 0.) 
    {
        float root = sqrt(discriminant);
        float temp = (-half_b - root)/a;
       
        if (temp > tMin && temp < tMax) 
        {
            outHit.LengthAlongRay = temp;
            outHit.Pos = ray.Origin + ray.Dir*temp;
            
            //vec3 outwardNormal = (hit.Pos - sph.Center) / sph.Radius;
            //hit.IsFrontFace = dot(outwardNormal, ray.Dir) < 0.;
            //hit.Normal = hit.IsFrontFace ? outwardNormal : -outwardNormal;
            outHit.Normal = (outHit.Pos - sph.Center) / sph.Radius;
            outHit.Mat = sph.Mat;
        	return true;
        }
        
        temp = (-half_b + root)/a;
        if (temp > tMin && temp < tMax)
        { 
            outHit.LengthAlongRay = temp;
            outHit.Pos = ray.Origin + ray.Dir*temp;
            
            //vec3 outwardNormal = (hit.Pos - sph.Center) / sph.Radius;
            //hit.IsFrontFace = dot(outwardNormal, ray.Dir) < 0.;
            //hit.Normal = hit.IsFrontFace ? outwardNormal : -outwardNormal;
            outHit.Normal = (outHit.Pos - sph.Center) / sph.Radius;
            outHit.Mat = sph.Mat;
        	return true;
        }
    }
    
    return false;
}

bool FindClosestHit(Ray ray, inout Hit outHit)
{
    float tMin = 0.0001;
    float closestSoFar = BIG_FLOAT;
    
    bool hitAnything = false;

    Hit tempHit;
    for (int i = 0; i < _numSpheres; i++)
    {
        Sphere sph = _spheres[i];
        if (HitSphere(sph, ray, tMin, closestSoFar, tempHit))
        {
			hitAnything = true;
            closestSoFar = tempHit.LengthAlongRay;
            outHit = tempHit;
        }
    }
    
    return hitAnything;
}

vec3 ColorPBR(Ray ray, float seed)
{
	const float epsilon = 0.001;
    
    vec3 accumulatedLight = vec3(0);
	vec3 attenuation = vec3(1);
    Hit hit;
    
    for (int bounce = 0; bounce < MAX_BOUNCES; bounce++)
    {
		if (FindClosestHit(ray, hit))
        {
            // Quick hack to add some checkery goodness
            if (hit.Mat.IsCheckerHack) 
            {
            	vec3 fragPos = 0.3 * (ray.Origin + ray.Dir*hit.LengthAlongRay); 
                
                 // xor checker pattern from iq
                vec2 q = floor(vec2(fragPos.x, fragPos.z));
    			float f = mod(q.x+q.y, 2.0); 
                
                hit.Mat.BaseColor = mix(_copper, vec3(0.12), f);
                hit.Mat.Metalness = mix(0., 0., f);
                hit.Mat.Roughness = mix(0.5, 0.1, f);
            }
            
            
        	float raySeed = seed + 7.1*float(iFrame) + 5681.123 + float(bounce)*92.13;
            
            // Inputs
            vec3 X = ray.Origin + ray.Dir*hit.LengthAlongRay; 	// x   - The location in space
            vec3 O = normalize(ray.Origin - X); 				// wo - Direction of the outgoing light
            vec3 I = hit.Normal + RandomUnitVector(raySeed); 	// wi - Degative direction of the incoming light
            vec3 N = hit.Normal;								// n   - The surface normal at x
                
            float NdotI = max(dot(N,I), 0.0);
            
            
            // Emissive term - L_e(x, wo, lambda, t) - the light emitted from this object
            vec3 emissive = vec3(0);
            #if EMISSIVE
            if (hit.Mat.Emissive > 0.0001)
            {
                emissive = hit.Mat.Emissive * vec3(hit.Mat.BaseColor);
            	accumulatedLight += attenuation * emissive;
                
                // TODO TODO TODO!
                
                // Confirm this iterative algo actually solves the rendering equation. I fear emissive and radiance aren't factored in correctly.
                
                // Idea: On paper, plot expected values for a few bounces of diff colours and emissivity as though run through a recursive algo
                //   then compare with results from this iterative algo.
                
                // Example scene. Ray path from camera hits red(1,.5,.5), blu_emissive(0,0,1), green(.5,1,.5), sky_emissive(.3,.3,.3)
                
                // TODO TODO TODO!
                
                
                // Reset the attenuation
                //attenuation = hit.Mat.BaseColor;
            }
            #endif
            
			// BRDF term - fr(x, wi, wo, lambda, t) - the material response to light
            vec3 brdf;
            {
                vec3 H = normalize(O + I); // half vec
                float NdotH = max(dot(N,H), 0.0);
            	float NdotO = max(dot(N,O), 0.0);
                float HdotO = max(dot(H,O), 0.0);
                
                // Fresnel term
                vec3 F0 = vec3(0.04); // Good average 'Fresnel at 0 degrees' value for common dielectrics
                F0 = mix(F0, hit.Mat.BaseColor, vec3(hit.Mat.Metalness));
                vec3 F = Fresnel_Schlick(HdotO, F0);
                
                // BRDF - Cook-Torrance
                float NDF = Distribution_GGX(NdotH, hit.Mat.Roughness);
                float G = Geometry_Smith(NdotO, NdotI, hit.Mat.Roughness);
                float denominator = 4.0 * NdotO * NdotI;
                vec3 specular = NDF*G*F / max(denominator, 0.0000001); // safe guard div0

                // Diffuse vs Specular contribution
                //vec3 kS = F;                      // Specular contribution
                vec3 kD = vec3(1.0) - F;           	// Diffuse contribution - Note: 1-kS ensures energy conservation
                kD *= 1.0 - hit.Mat.Metalness; 		// Remove diffuse contribution for metals

                vec3 diffuse = kD*hit.Mat.BaseColor/PI;
                
                #if DIFFUSE == 0
                diffuse = vec3(0);
                #endif
                
                #if SPECULAR == 0
                specular = vec3(0);
                #endif
              
                brdf = diffuse + specular;
            }
            
            
            // Incoming Radiance - Li(x, wi, lambda, t) - the loop solves this part!
            vec3 radiance = vec3(1);
            
            
            // The weakening term that scales incoming light by the angle it hits the surface
            float cosTheta = NdotI;
           
            
            // Outgoing Radiance - Lo = Le + fr*Li*cosTheta
            vec3 Lo = emissive + brdf*radiance*cosTheta;
            
            
            attenuation *= Lo;
            ray.Dir = normalize(I);  // Not 100% if ray must be unit length, but it gives me peace of mind.
        	ray.Origin = hit.Pos + hit.Normal * epsilon; // Slightly off the hit surface stops self intersection
        }
        else
        {
            // We hit sky!
            #if SKY
            accumulatedLight += attenuation * _skyColor;
            #endif
            break; // End tracing
        }
    }
    
    return accumulatedLight;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float aspect = iResolution.x / iResolution.y;
    //vec2 uv = (2.*(fragCoord) - iResolution.xy) / iResolution.yy; // -(aspect,1) -> (aspect,1)
    vec2 uvNorm = (fragCoord) / iResolution.xy;                     //       (0,0) -> (1,1)
	vec2 m = iMouse.xy == vec2(0) 
        ? vec2(.16,-0.2)                                            // Put default cam somewhere perdy
        : (2.*iMouse.xy - iResolution.xy) / iResolution.yy;         // -(aspect,1) -> (aspect,1)
       
    vec3 oldCol = vec3(0);
    
    // HandleState
    float numFramesAccumulated = DecodeNumFramesAccumulated();
    {
        oldCol = texelFetch(iChannel0, ivec2(fragCoord), 0).xyz;       
        
        if(iFrame == 0 || numFramesAccumulated == 0.) {
            oldCol = vec3(0,0,0);
        }

        // Track accumulated frames
        if (ivec2(fragCoord) == ivec2(0,0))
        {
            numFramesAccumulated++;

             // Get mouse state
            bool mousePressed = iMouse.z > 0.0;
            if (mousePressed) { 
                numFramesAccumulated = 0.; 
            }

            fragColor = EncodeNumFramesAccumulated(numFramesAccumulated);
            return;
        }
    }
 
    
    InitScene();
    
    
    vec3 newCol = vec3(0);
    for (int sampleId = 0; sampleId < SAMPLES_PER_PIXEL; sampleId++) // TODO Test if stratifying samples improves convergence
    {
    	float seed = hash11( dot( fragCoord, vec2(12.9898, 78.233) ) + 1113.1*hash11(numFramesAccumulated*float(sampleId)) );
    
        // Camera ray
        Ray ray;
        {
            // Position the camera
            vec3 camPos = 24. * vec3(
                sin(-m.x*PI), 
                mix(0.05, 2., smoothstep(-.75,.75,m.y)), 
                cos(m.x*PI));
            vec3 camTarget = vec3(0,1,0);

            
            // Compute ray at origin from lens
            vec3 rayStart = APERTURE * 0.5 * vec3(RandomInUnitCircle(seed + 84.123), 0.);
            vec3 lensRay;
            {
                // Sub pixel offset
                vec2 pixelOffset = hash21(seed+13.271) / iResolution.xy;
                float s = uvNorm.x + pixelOffset.x;
                float t = uvNorm.y + pixelOffset.y;

                // Calc point in target image plane
	            float focalDist = length(camTarget - camPos);
                float vertical = focalDist* 2.*tan(radians(VERTICAL_FOV/2.));
                float horizontal = vertical*aspect;
                vec3 lowerLeftCorner = -vec3(horizontal/2., vertical/2., focalDist);
                vec3 rayEnd = lowerLeftCorner + vec3(s*horizontal, t*vertical, 0.);
                
                lensRay = normalize(rayEnd - rayStart);
            }

            
            // Aim the ray
            mat3 viewMat = ViewLookAtMatrix(camPos, camTarget, 0.);
            ray.Origin = camPos + viewMat * rayStart;
            ray.Dir = viewMat * lensRay;
        }

        _skyColor = _skyBrightness*mix(vec3(1.), 2.*vec3(.5,.7,1.), 0.5*uvNorm.y + .5);
        
    	newCol += clamp(ColorPBR(ray, seed), 0., 500.);
    }
    newCol /= float(SAMPLES_PER_PIXEL);
    
    fragColor = vec4(oldCol + newCol, 1.0);
}

