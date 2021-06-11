uint wang_hash(inout uint seed)
{
    seed = uint(seed ^ uint(61)) ^ uint(seed >> uint(16));
    seed *= uint(9);
    seed = seed ^ (seed >> 4);
    seed *= uint(0x27d4eb2d);
    seed = seed ^ (seed >> 15);
    return seed;
}

float RandomFloat01(inout uint state)
{
    return float(wang_hash(state)) / 4294967296.0;
}

vec3 RandomUnitVector(inout uint state)
{
    float z = RandomFloat01(state) * 2.0f - 1.0f;
    float a = RandomFloat01(state) * c_twopi;
    float r = sqrt(1.0f - z * z);
    float x = r * cos(a);
    float y = r * sin(a);
    return vec3(x, y, z);
}

struct SMaterialInfo
{
    // Note: diffuse chance is 1.0f - (specularChance+refractionChance)
    vec3  albedo;              // the color used for diffuse lighting
    vec3  emissive;            // how much the surface glows
    float specularChance;      // percentage chance of doing a specular reflection
    float specularRoughness;   // how rough the specular reflections are
    vec3  specularColor;       // the color tint of specular reflections
    float IOR;                 // index of refraction. used by fresnel and refraction.
    float refractionChance;    // percent chance of doing a refractive transmission
    float refractionRoughness; // how rough the refractive transmissions are
    vec3  refractionColor;     // absorption for beer's law    
};
    
SMaterialInfo GetZeroedMaterial()
{
    SMaterialInfo ret;
    ret.albedo = vec3(0.0f, 0.0f, 0.0f);
    ret.emissive = vec3(0.0f, 0.0f, 0.0f);
    ret.specularChance = 0.0f;
    ret.specularRoughness = 0.0f;
    ret.specularColor = vec3(0.0f, 0.0f, 0.0f);
    ret.IOR = 1.0f;
    ret.refractionChance = 0.0f;
    ret.refractionRoughness = 0.0f;
    ret.refractionColor = vec3(0.0f, 0.0f, 0.0f);
    return ret;
}

struct SRayHitInfo
{
    bool fromInside;
    float dist;
    vec3 normal;
    SMaterialInfo material;
};

float ScalarTriple(vec3 u, vec3 v, vec3 w)
{
    return dot(cross(u, v), w);
}

bool TestQuadTrace(in vec3 rayPos, in vec3 rayDir, inout SRayHitInfo info, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    // calculate normal and flip vertices order if needed
    vec3 normal = normalize(cross(c-a, c-b));
    if (dot(normal, rayDir) > 0.0f)
    {
        normal *= -1.0f;
        
		vec3 temp = d;
        d = a;
        a = temp;
        
        temp = b;
        b = c;
        c = temp;
    }
    
    vec3 p = rayPos;
    vec3 q = rayPos + rayDir;
    vec3 pq = q - p;
    vec3 pa = a - p;
    vec3 pb = b - p;
    vec3 pc = c - p;
    
    // determine which triangle to test against by testing against diagonal first
    vec3 m = cross(pc, pq);
    float v = dot(pa, m);
    vec3 intersectPos;
    if (v >= 0.0f)
    {
        // test against triangle a,b,c
        float u = -dot(pb, m);
        if (u < 0.0f) return false;
        float w = ScalarTriple(pq, pb, pa);
        if (w < 0.0f) return false;
        float denom = 1.0f / (u+v+w);
        u*=denom;
        v*=denom;
        w*=denom;
        intersectPos = u*a+v*b+w*c;
    }
    else
    {
        vec3 pd = d - p;
        float u = dot(pd, m);
        if (u < 0.0f) return false;
        float w = ScalarTriple(pq, pa, pd);
        if (w < 0.0f) return false;
        v = -v;
        float denom = 1.0f / (u+v+w);
        u*=denom;
        v*=denom;
        w*=denom;
        intersectPos = u*a+v*d+w*c;
    }
    
    float dist;
    if (abs(rayDir.x) > 0.1f)
    {
        dist = (intersectPos.x - rayPos.x) / rayDir.x;
    }
    else if (abs(rayDir.y) > 0.1f)
    {
        dist = (intersectPos.y - rayPos.y) / rayDir.y;
    }
    else
    {
        dist = (intersectPos.z - rayPos.z) / rayDir.z;
    }
    
	if (dist > c_minimumRayHitTime && dist < info.dist)
    {
        info.fromInside = false;
        info.dist = dist;        
        info.normal = normal;        
        return true;
    }    
    
    return false;
}

float FresnelReflectAmount(float n1, float n2, vec3 normal, vec3 incident, float f0, float f90)
{
        // Schlick aproximation
        float r0 = (n1-n2) / (n1+n2);
        r0 *= r0;
        float cosX = -dot(normal, incident);
        if (n1 > n2)
        {
            float n = n1/n2;
            float sinT2 = n*n*(1.0-cosX*cosX);
            // Total internal reflection
            if (sinT2 > 1.0)
                return f90;
            cosX = sqrt(1.0-sinT2);
        }
        float x = 1.0-cosX;
        float ret = r0+(1.0-r0)*x*x*x*x*x;

        // adjust reflect multiplier for object reflectivity
        return mix(f0, f90, ret);
}

bool TestSphereTrace(in vec3 rayPos, in vec3 rayDir, inout SRayHitInfo info, in vec4 sphere)
{    
	//get the vector from the center of this sphere to where the ray begins.
	vec3 m = rayPos - sphere.xyz;

    //get the dot product of the above vector and the ray's vector
	float b = dot(m, rayDir);

	float c = dot(m, m) - sphere.w * sphere.w;

	//exit if r's origin outside s (c > 0) and r pointing away from s (b > 0)
	if(c > 0.0 && b > 0.0)
		return false;

	//calculate discriminant
	float discr = b * b - c;

	//a negative discriminant corresponds to ray missing sphere
	if(discr < 0.0)
		return false;
    
	//ray now found to intersect sphere, compute smallest t value of intersection
    bool fromInside = false;
	float dist = -b - sqrt(discr);
    if (dist < 0.0f)
    {
        fromInside = true;
        dist = -b + sqrt(discr);
    }
    
	if (dist > c_minimumRayHitTime && dist < info.dist)
    {
        info.fromInside = fromInside;
        info.dist = dist;        
        info.normal = normalize((rayPos+rayDir*dist) - sphere.xyz) * (fromInside ? -1.0f : 1.0f);
        return true;
    }
    
    return false;
}

void TestSceneTrace(in vec3 rayPos, in vec3 rayDir, inout SRayHitInfo hitInfo)
{

     // to move the scene around, since we can't move the camera yet
    vec3 sceneTranslation = vec3(0.0f, 0.0f,50.0f);
    vec4 sceneTranslation4 = vec4(sceneTranslation, 0.0f);
    
   	// back wall
    {
        vec3 A = vec3(-24.f, -24.f, 48.0f) + sceneTranslation;
        vec3 B = vec3( 24.f, -24.f, 48.0f) + sceneTranslation;
        vec3 C = vec3( 24.f,  24.f, 48.0f) + sceneTranslation;
        vec3 D = vec3(-24.f,  24.f, 48.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.7f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
        }
	}    
    
    // floor
    {
        vec3 A = vec3(-24.f, -24.f, 48.0f) + sceneTranslation;
        vec3 B = vec3( 24.f, -24.f, 48.0f) + sceneTranslation;
        vec3 C = vec3( 24.f, -24.f, 0.0f) + sceneTranslation;
        vec3 D = vec3(-24.f, -24.f, 0.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.7f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }
    
    // cieling
    {
        vec3 A = vec3(-24.f, 24.f, 48.0f) + sceneTranslation;
        vec3 B = vec3( 24.f, 24.f, 48.0f) + sceneTranslation;
        vec3 C = vec3( 24.f, 24.f, 0.0f) + sceneTranslation;
        vec3 D = vec3(-24.f, 24.f, 0.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.7f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }    
    
    // left wall
    {
        vec3 A = vec3(-24.f, -24.f, 48.0f) + sceneTranslation;
        vec3 B = vec3(-24.f, -24.f, 0.0f) + sceneTranslation;
        vec3 C = vec3(-24.f,  24.f, 0.0f) + sceneTranslation;
        vec3 D = vec3(-24.f,  24.f, 48.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.1f, 0.1f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }
    
    // right wall 
    {
        vec3 A = vec3( 24.f, -24.f, 48.0f) + sceneTranslation;
        vec3 B = vec3( 24.f, -24.f, 0.0f) + sceneTranslation;
        vec3 C = vec3( 24.f,  24.f, 0.0f) + sceneTranslation;
        vec3 D = vec3( 24.f,  24.f, 48.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.1f, 0.1f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }    
    
    // light
    {
        vec3 A = vec3(-9.0f, 24.0f,  30.f) + sceneTranslation;
        vec3 B = vec3( 9.0f, 24.0f,  30.f) + sceneTranslation;
        vec3 C = vec3( 9.0f, 24.0f,  16.f) + sceneTranslation;
        vec3 D = vec3(-9.0f, 24.0f,  16.f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.emissive = vec3(1.0f, 0.9f, 0.7f) * 50.0f;
        }        
    }
    
    //left reflective sphere
	if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(-12.0f, -16.f, 30.0f, 8.0f)+sceneTranslation4))
    {
        hitInfo.material.albedo = vec3(1.f, 1.f, 1.f);
        hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);     
                 
        hitInfo.material.specularChance = 0.9f;
        hitInfo.material.specularRoughness = 0.005;
        hitInfo.material.specularColor = vec3(1.0f, 1.0f, 1.0f);
        hitInfo.material.IOR = 1.f;
        hitInfo.material.refractionChance = 0.0f;
        hitInfo.material.refractionRoughness = 0.f;
        hitInfo.material.refractionColor = vec3(0.0f, 0.0f, 0.0f);
    } 
    
    //right refractive sphere
	if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(12.0f, -16.f, 20.0f, 8.0f)+sceneTranslation4))
    {
        hitInfo.material.albedo = vec3(1.f, 1.f, 1.f);
        hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);     
                 
        hitInfo.material.specularChance = 0.001f;
        hitInfo.material.specularRoughness = 0.0;
        hitInfo.material.specularColor = vec3(1.0f, 1.0f, 1.0f);
        hitInfo.material.IOR = 1.5f;
        hitInfo.material.refractionChance = 1.f;
        hitInfo.material.refractionRoughness = 0.0f;  
    }    
      


}

vec3 GetColorForRay(in vec3 startRayPos, in vec3 startRayDir, inout uint rngState)
{
    // initialize
    vec3 ret = vec3(0.0f, 0.0f, 0.0f);
    vec3 throughput = vec3(1.0f, 1.0f, 1.0f);
    vec3 rayPos = startRayPos;
    vec3 rayDir = startRayDir;
    int bounceIndex = 0;
    for (; bounceIndex <= c_numBounces; ++bounceIndex)
    {
        // shoot a ray out into the world
        SRayHitInfo hitInfo;
        hitInfo.material = GetZeroedMaterial();
        hitInfo.dist = c_superFar;
        hitInfo.fromInside = false;
        TestSceneTrace(rayPos, rayDir, hitInfo);
        
        // if the ray missed, we are done
        if (hitInfo.dist == c_superFar)
        {           
            break;
        }
        
        // do absorption if we are hitting from inside the object
        if (hitInfo.fromInside)
            throughput *= exp(-hitInfo.material.refractionColor * hitInfo.dist);
        
        // get the pre-fresnel chances
        float specularChance = hitInfo.material.specularChance;
        float refractionChance = hitInfo.material.refractionChance;
        //float diffuseChance = max(0.0f, 1.0f - (refractionChance + specularChance));
        
        // take fresnel into account for specularChance and adjust other chances.
        // specular takes priority.
        // chanceMultiplier makes sure we keep diffuse / refraction ratio the same.
        float rayProbability = 1.0f;
        if (specularChance > 0.0f)
        {
        	specularChance = FresnelReflectAmount(
            	hitInfo.fromInside ? hitInfo.material.IOR : 1.0,
            	!hitInfo.fromInside ? hitInfo.material.IOR : 1.0,
            	rayDir, hitInfo.normal, hitInfo.material.specularChance, 1.0f);
            
            float chanceMultiplier = (1.0f - specularChance) / (1.0f - hitInfo.material.specularChance);
            refractionChance *= chanceMultiplier;
            //diffuseChance *= chanceMultiplier;
        }
        
        // calculate whether we are going to do a diffuse, specular, or refractive ray
        float doSpecular = 0.0f;
        float doRefraction = 0.0f;
        float raySelectRoll = RandomFloat01(rngState);
		if (specularChance > 0.0f && raySelectRoll < specularChance)
        {
            doSpecular = 1.0f;
            rayProbability = specularChance;
        }
        else if (refractionChance > 0.0f && raySelectRoll < specularChance + refractionChance)
        {
            doRefraction = 1.0f;
            rayProbability = refractionChance;
        }
        else
        {
            rayProbability = 1.0f - (specularChance + refractionChance);
        }
        
        // numerical problems can cause rayProbability to become small enough to cause a divide by zero.
		rayProbability = max(rayProbability, 0.001f);
        
        // update the ray position
        if (doRefraction == 1.0f)
        {
            rayPos = (rayPos + rayDir * hitInfo.dist) - hitInfo.normal * c_rayPosNormalNudge;
        }
        else
        {
            rayPos = (rayPos + rayDir * hitInfo.dist) + hitInfo.normal * c_rayPosNormalNudge;
        }
         
        // Calculate a new ray direction.
        // Diffuse uses a normal oriented cosine weighted hemisphere sample.
        // Perfectly smooth specular uses the reflection ray.
        // Rough (glossy) specular lerps from the smooth specular to the rough diffuse by the material roughness squared
        // Squaring the roughness is just a convention to make roughness feel more linear perceptually.
        vec3 diffuseRayDir = normalize(hitInfo.normal + RandomUnitVector(rngState));
        
        vec3 specularRayDir = reflect(rayDir, hitInfo.normal);
        specularRayDir = normalize(mix(specularRayDir, diffuseRayDir, hitInfo.material.specularRoughness*hitInfo.material.specularRoughness));

        vec3 refractionRayDir = refract(rayDir, hitInfo.normal, hitInfo.fromInside ? hitInfo.material.IOR : 1.0f / hitInfo.material.IOR);
        refractionRayDir = normalize(mix(refractionRayDir, normalize(-hitInfo.normal + RandomUnitVector(rngState)), hitInfo.material.refractionRoughness*hitInfo.material.refractionRoughness));
                
        rayDir = mix(diffuseRayDir, specularRayDir, doSpecular);
        rayDir = mix(rayDir, refractionRayDir, doRefraction);
        
		// add in emissive lighting
        ret += hitInfo.material.emissive * throughput;
        
        // update the colorMultiplier. refraction doesn't alter the color until we hit the next thing, so we can do light absorption over distance.
        if (doRefraction == 0.0f)
        	throughput *= mix(hitInfo.material.albedo, hitInfo.material.specularColor, doSpecular);
        
        // since we chose randomly between diffuse, specular, refract,
        // we need to account for the times we didn't do one or the other.
        throughput /= rayProbability;
        
        // Russian Roulette
        // As the throughput gets smaller, the ray is more likely to get terminated early.
        // Survivors have their value boosted to make up for fewer samples being in the average.
        {
        	float p = max(throughput.r, max(throughput.g, throughput.b));
        	if (RandomFloat01(rngState) > p)
            	break;

        	// Add the energy we 'lose' by randomly terminating paths
        	throughput *= 1.0f / p;            
        }
    }
 
   // return pixel color
   #if SHOW_BOUNCE_VIS==1
       return c_colors[bounceIndex];
   #else
       return ret;
   #endif
}

void GetCameraVectors(out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraUp, out vec3 cameraRight)
{
    // if the mouse is at (0,0) it hasn't been moved yet, so use a default camera setup
    vec2 mouse = iMouse.xy;
    if (dot(mouse, vec2(1.0f, 1.0f)) == 0.0f)
    {
        cameraPos = vec3(0.0f, 0.0f, -c_cameraDistance);
        cameraFwd = vec3(0.0f, 0.0f, 1.0f);
        cameraUp = vec3(0.0f, 1.0f, 0.0f);
        cameraRight = vec3(1.0f, 0.0f, 0.0f);
        return;
    }
    
    // otherwise use the mouse position to calculate camera position and orientation
    
    float angleX = -mouse.x * 16.0f / float(iResolution.x);
    float angleY = mix(c_minCameraAngle, c_maxCameraAngle, mouse.y / float(iResolution.y));
    
    cameraPos.x = sin(angleX) * sin(angleY) * c_cameraDistance;
    cameraPos.y = -cos(angleY) * c_cameraDistance;
    cameraPos.z = cos(angleX) * sin(angleY) * c_cameraDistance;
    
    cameraPos += c_cameraAt;
    
    cameraFwd = normalize(c_cameraAt - cameraPos);
    cameraRight = normalize(cross(vec3(0.0f, 1.0f, 0.0f), cameraFwd));
    cameraUp = normalize(cross(cameraFwd, cameraRight));   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // initialize a random number state based on frag coord and frame
    uint rngState = uint(uint(fragCoord.x) * uint(1973) + uint(fragCoord.y) * uint(9277) + uint(iFrame) * uint(26699)) | uint(1);    
    
    // calculate subpixel camera jitter for anti aliasing
    vec2 jitter = vec2(RandomFloat01(rngState), RandomFloat01(rngState)) - 0.5f;

    // get the camera vectors
    vec3 cameraPos, cameraFwd, cameraUp, cameraRight;
    GetCameraVectors(cameraPos, cameraFwd, cameraUp, cameraRight);    
    vec3 rayDir;
    {   
        // calculate a screen position from -1 to +1 on each axis
        vec2 uvJittered = (fragCoord+jitter)/iResolution.xy;
		vec2 screen = uvJittered * 2.0f - 1.0f;
        
        // adjust for aspect ratio
        float aspectRatio = iResolution.x / iResolution.y;
        screen.y /= aspectRatio;
                
        // make a ray direction based on camera orientation and field of view angle
        float cameraDistance = tan(c_FOVDegrees * 0.5f * c_pi / 180.0f);       
        rayDir = vec3(screen, cameraDistance);
        rayDir = normalize(mat3(cameraRight, cameraUp, cameraFwd) * rayDir);
    }
    
    // raytrace for this pixel
    vec3 color = vec3(0.0f, 0.0f, 0.0f);
    for (int index = 0; index < c_numRendersPerFrame; ++index)
    	color += GetColorForRay(cameraPos, rayDir, rngState) / float(c_numRendersPerFrame);
    
    // see if space was pressed. if so we want to restart our render.
    // This is useful for when we go fullscreen for a bigger image.
    bool spacePressed = (texture(iChannel2, vec2(KEY_SPACE,0.25)).x > 0.1);
    
    // average the frames together
    vec4 lastFrameColor = texture(iChannel0, fragCoord / iResolution.xy);
    float blend = (iFrame < 2 || iMouse.z > 0.0 || lastFrameColor.a == 0.0f || spacePressed) ? 1.0f : 1.0f / (1.0f + (1.0f / lastFrameColor.a));
    color = mix(lastFrameColor.rgb, color, blend);

    // show the result
    fragColor = vec4(color, blend);
}