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
    vec3 albedo;           // the color used for diffuse lighting
    vec3 emissive;         // how much the surface glows
    float percentSpecular; // percentage chance of doing specular instead of diffuse lighting
    float roughness;       // how rough the specular reflections are
    vec3 specularColor;    // the color tint of specular reflections
};

struct SRayHitInfo
{
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
        info.dist = dist;        
        info.normal = normal;        
        return true;
    }    
    
    return false;
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
        info.dist = dist;        
        info.normal = normalize((rayPos+rayDir*dist) - sphere.xyz) * (fromInside ? -1.0f : 1.0f);
        return true;
    }
    
    return false;
}

void TestSceneTrace(in vec3 rayPos, in vec3 rayDir, inout SRayHitInfo hitInfo)
{    
    // to move the scene around, since we can't move the camera yet
    vec3 sceneTranslation = vec3(0.0f, 0.0f, 10.0f);
    vec4 sceneTranslation4 = vec4(sceneTranslation, 0.0f);
    
   	// back wall
    {
        vec3 A = vec3(-12.6f, -12.6f, 25.0f) + sceneTranslation;
        vec3 B = vec3( 12.6f, -12.6f, 25.0f) + sceneTranslation;
        vec3 C = vec3( 12.6f,  12.6f, 25.0f) + sceneTranslation;
        vec3 D = vec3(-12.6f,  12.6f, 25.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.7f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.percentSpecular = 0.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.0f, 0.0f, 0.0f);
        }
	}
    
    // floor
    {
        vec3 A = vec3(-12.6f, -12.45f, 25.0f) + sceneTranslation;
        vec3 B = vec3( 12.6f, -12.45f, 25.0f) + sceneTranslation;
        vec3 C = vec3( 12.6f, -12.45f, 15.0f) + sceneTranslation;
        vec3 D = vec3(-12.6f, -12.45f, 15.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.7f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.percentSpecular = 0.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.0f, 0.0f, 0.0f);            
        }        
    }
    
    // cieling
    {
        vec3 A = vec3(-12.6f, 12.5f, 25.0f) + sceneTranslation;
        vec3 B = vec3( 12.6f, 12.5f, 25.0f) + sceneTranslation;
        vec3 C = vec3( 12.6f, 12.5f, 15.0f) + sceneTranslation;
        vec3 D = vec3(-12.6f, 12.5f, 15.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.7f, 0.7f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.percentSpecular = 0.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.0f, 0.0f, 0.0f);
        }        
    }    
    
    // left wall
    {
        vec3 A = vec3(-12.5f, -12.6f, 25.0f) + sceneTranslation;
        vec3 B = vec3(-12.5f, -12.6f, 15.0f) + sceneTranslation;
        vec3 C = vec3(-12.5f,  12.6f, 15.0f) + sceneTranslation;
        vec3 D = vec3(-12.5f,  12.6f, 25.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.7f, 0.1f, 0.1f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.percentSpecular = 0.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.0f, 0.0f, 0.0f);
        }        
    }
    
    // right wall 
    {
        vec3 A = vec3( 12.5f, -12.6f, 25.0f) + sceneTranslation;
        vec3 B = vec3( 12.5f, -12.6f, 15.0f) + sceneTranslation;
        vec3 C = vec3( 12.5f,  12.6f, 15.0f) + sceneTranslation;
        vec3 D = vec3( 12.5f,  12.6f, 25.0f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.1f, 0.7f, 0.1f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.percentSpecular = 0.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.0f, 0.0f, 0.0f);            
        }        
    }    
    
    // light
    {
        vec3 A = vec3(-5.0f, 12.4f,  22.5f) + sceneTranslation;
        vec3 B = vec3( 5.0f, 12.4f,  22.5f) + sceneTranslation;
        vec3 C = vec3( 5.0f, 12.4f,  17.5f) + sceneTranslation;
        vec3 D = vec3(-5.0f, 12.4f,  17.5f) + sceneTranslation;
        if (TestQuadTrace(rayPos, rayDir, hitInfo, A, B, C, D))
        {
            hitInfo.material.albedo = vec3(0.0f, 0.0f, 0.0f);
            hitInfo.material.emissive = vec3(1.0f, 0.9f, 0.7f) * 20.0f;
            hitInfo.material.percentSpecular = 0.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.0f, 0.0f, 0.0f);            
        }        
    }
    
	if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(-9.0f, -9.5f, 20.0f, 3.0f)+sceneTranslation4))
    {
        hitInfo.material.albedo = vec3(0.9f, 0.9f, 0.5f);
        hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);        
        hitInfo.material.percentSpecular = 0.1f;
        hitInfo.material.roughness = 0.2f;
        hitInfo.material.specularColor = vec3(0.9f, 0.9f, 0.9f);        
    } 
    
	if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(0.0f, -9.5f, 20.0f, 3.0f)+sceneTranslation4))
    {
        hitInfo.material.albedo = vec3(0.9f, 0.5f, 0.9f);
        hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);   
        hitInfo.material.percentSpecular = 0.3f;
        hitInfo.material.roughness = 0.2;
        hitInfo.material.specularColor = vec3(0.9f, 0.9f, 0.9f);        
    }    
    
    // a ball which has blue diffuse but red specular. an example of a "bad material".
    // a better lighting model wouldn't let you do this sort of thing
	if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(9.0f, -9.5f, 20.0f, 3.0f)+sceneTranslation4))
    {
        hitInfo.material.albedo = vec3(0.0f, 0.0f, 1.0f);
        hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);
        hitInfo.material.percentSpecular = 0.5f;
        hitInfo.material.roughness = 0.4f;
        hitInfo.material.specularColor = vec3(1.0f, 0.0f, 0.0f);        
    }
    
    // shiny green balls of varying roughnesses
    {
        if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(-10.0f, 0.0f, 23.0f, 1.75f)+sceneTranslation4))
        {
            hitInfo.material.albedo = vec3(1.0f, 1.0f, 1.0f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);        
            hitInfo.material.percentSpecular = 1.0f;
            hitInfo.material.roughness = 0.0f;
            hitInfo.material.specularColor = vec3(0.3f, 1.0f, 0.3f);       
        }     
        
        if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(-5.0f, 0.0f, 23.0f, 1.75f)+sceneTranslation4))
        {
            hitInfo.material.albedo = vec3(1.0f, 1.0f, 1.0f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);        
            hitInfo.material.percentSpecular = 1.0f;
            hitInfo.material.roughness = 0.25f;
            hitInfo.material.specularColor = vec3(0.3f, 1.0f, 0.3f);
        }            
        
        if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(0.0f, 0.0f, 23.0f, 1.75f)+sceneTranslation4))
        {
            hitInfo.material.albedo = vec3(1.0f, 1.0f, 1.0f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);        
            hitInfo.material.percentSpecular = 1.0f;
            hitInfo.material.roughness = 0.5f;
            hitInfo.material.specularColor = vec3(0.3f, 1.0f, 0.3f);
        }            
        
        if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(5.0f, 0.0f, 23.0f, 1.75f)+sceneTranslation4))
        {
            hitInfo.material.albedo = vec3(1.0f, 1.0f, 1.0f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);        
            hitInfo.material.percentSpecular = 1.0f;
            hitInfo.material.roughness = 0.75f;
            hitInfo.material.specularColor = vec3(0.3f, 1.0f, 0.3f);
        }        
        
        if (TestSphereTrace(rayPos, rayDir, hitInfo, vec4(10.0f, 0.0f, 23.0f, 1.75f)+sceneTranslation4))
        {
            hitInfo.material.albedo = vec3(1.0f, 1.0f, 1.0f);
            hitInfo.material.emissive = vec3(0.0f, 0.0f, 0.0f);        
            hitInfo.material.percentSpecular = 1.0f;
            hitInfo.material.roughness = 1.0f;
            hitInfo.material.specularColor = vec3(0.3f, 1.0f, 0.3f);
        }           
    }
}

vec3 GetColorForRay(in vec3 startRayPos, in vec3 startRayDir, inout uint rngState)
{
    // initialize
    vec3 ret = vec3(0.0f, 0.0f, 0.0f);
    vec3 throughput = vec3(1.0f, 1.0f, 1.0f);
    vec3 rayPos = startRayPos;
    vec3 rayDir = startRayDir;
    
    for (int bounceIndex = 0; bounceIndex <= c_numBounces; ++bounceIndex)
    {
        // shoot a ray out into the world
        SRayHitInfo hitInfo;
        hitInfo.dist = c_superFar;
        TestSceneTrace(rayPos, rayDir, hitInfo);
        
        // if the ray missed, we are done
        if (hitInfo.dist == c_superFar)
        {
            ret += SRGBToLinear(texture(iChannel1, rayDir).rgb) * c_skyboxBrightnessMultiplier * throughput;
            break;
        }
        
		// update the ray position
        rayPos = (rayPos + rayDir * hitInfo.dist) + hitInfo.normal * c_rayPosNormalNudge;
        
        // calculate whether we are going to do a diffuse or specular reflection ray 
        float doSpecular = (RandomFloat01(rngState) < hitInfo.material.percentSpecular) ? 1.0f : 0.0f;
 
        // Calculate a new ray direction.
        // Diffuse uses a normal oriented cosine weighted hemisphere sample.
        // Perfectly smooth specular uses the reflection ray.
        // Rough (glossy) specular lerps from the smooth specular to the rough diffuse by the material roughness squared
        // Squaring the roughness is just a convention to make roughness feel more linear perceptually.
        vec3 diffuseRayDir = normalize(hitInfo.normal + RandomUnitVector(rngState));
        vec3 specularRayDir = reflect(rayDir, hitInfo.normal);
        specularRayDir = normalize(mix(specularRayDir, diffuseRayDir, hitInfo.material.roughness * hitInfo.material.roughness));
        rayDir = mix(diffuseRayDir, specularRayDir, doSpecular);
        
		// add in emissive lighting
        ret += hitInfo.material.emissive * throughput;
        
        // update the colorMultiplier
        throughput *= mix(hitInfo.material.albedo, hitInfo.material.specularColor, doSpecular);      
        
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
    return ret;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // initialize a random number state based on frag coord and frame
    uint rngState = uint(uint(fragCoord.x) * uint(1973) + uint(fragCoord.y) * uint(9277) + uint(iFrame) * uint(26699)) | uint(1);
    
    // The ray starts at the camera position (the origin)
    vec3 rayPosition = vec3(0.0f, 0.0f, 0.0f);
    
    // calculate the camera distance
	float cameraDistance = 1.0f / tan(c_FOVDegrees * 0.5f * c_pi / 180.0f);     
    
    // calculate subpixel camera jitter for anti aliasing
    vec2 jitter = vec2(RandomFloat01(rngState), RandomFloat01(rngState)) - 0.5f;
    
    // calculate coordinates of the ray target on the imaginary pixel plane.
    // -1 to +1 on x,y axis. 1 unit away on the z axis
    vec3 rayTarget = vec3(((fragCoord+jitter)/iResolution.xy) * 2.0f - 1.0f, cameraDistance);
    
    // correct for aspect ratio
	float aspectRatio = iResolution.x / iResolution.y;
    rayTarget.y /= aspectRatio;
    
    // calculate a normalized vector for the ray direction.
    // it's pointing from the ray position to the ray target.
    vec3 rayDir = normalize(rayTarget - rayPosition);
    
    // raytrace for this pixel
    vec3 color = vec3(0.0f, 0.0f, 0.0f);
    for (int index = 0; index < c_numRendersPerFrame; ++index)
    	color += GetColorForRay(rayPosition, rayDir, rngState) / float(c_numRendersPerFrame);
    
    // see if space was pressed. if so we want to restart our render.
    // This is useful for when we go fullscreen for a bigger image.
    bool spacePressed = (texture(iChannel2, vec2(KEY_SPACE,0.25)).x > 0.1);
    
    // average the frames together
    vec4 lastFrameColor = texture(iChannel0, fragCoord / iResolution.xy);
    float blend = (lastFrameColor.a == 0.0f || spacePressed) ? 1.0f : 1.0f / (1.0f + (1.0f / lastFrameColor.a));
    color = mix(lastFrameColor.rgb, color, blend);

    // show the result
    fragColor = vec4(color, blend);
}