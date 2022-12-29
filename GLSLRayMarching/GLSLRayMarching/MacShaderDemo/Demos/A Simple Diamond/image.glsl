// Mainly from: https://www.shadertoy.com/view/4tyXDR
// Add object type 3, a diamond
#define REFRACTIVE_INDEX_OUTSIDE 1.00029
#define REFRACTIVE_INDEX_INSIDE  1.125

// lighting parameters
#define LIGHT_DIRECTIONAL_DIR   normalize(-vec3(1.0,2.0,1.0))
#define LIGHT_DIRECTIONAL_COLOR vec3(1.0)
#define LIGHT_AMBIENT           vec3(0.1)

// object type
#define OBJECT_TYPE 3 // 0 = sphere, 1 = box, 2 = geometric gem shape, 3 = diamond

// object color parameters
#define OBJECT_DIFFUSE      vec3(0.0)
#define OBJECT_SPECPOWER    0.0
#define OBJECT_REFLECTIVITY 0.01 // How reflective the object is. regardless of fresnel.
#define OBJECT_ABSORB       vec3(8.0, 8.0, 3.0) // for beers law

// object surface parameters
#define DO_REFRACTION 1  // 0 to turn off refraction
#define DO_REFLECTION 1  // 0 to turn off reflection
#define DO_FRESNEL    1  // 0 to turn off fresnel. fresnel will only show up if reflection is also on.

// rendering params
#define DO_AA           1  // 0 to turn off 16x jittered SSAA
#define MAX_RAY_BOUNCES 10 // For box, 2 seems to be max that makes a difference. For sphere, 1 seems to be!

// hash21 from https://www.shadertoy.com/view/4djSRW
#define HASHSCALE3 vec3(443.897, 441.423, 437.195)
//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p) {
  vec3 p3 = fract(vec3(p) * HASHSCALE3);
  p3 += dot(p3, p3.yzx + 19.19);
  return fract(vec2((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y));
}

//============================================================
// this is ibox() from https://www.shadertoy.com/view/ld23DV
// Just renamed some things to be more clear and minimized to needed functionality
// returns t and normal
vec4 RayIntersectBox(in vec3 rayOrigin, in vec3 rayDirection, in vec3 boxHalfSizes, out vec2 uv) {
	// ray-box intersection
  vec3 m = 1.0 / rayDirection;    // how many steps on each axis to travel 1 unit on that axis
  vec3 n = m * rayOrigin;         // how many steps on each axis the ray origin is from the object origin
  vec3 k = abs(m) * boxHalfSizes; // how many steps on each axis it takes to get from the center of the box to the edge

  vec3 t1 = -n - k;   // how many steps on each axis to get from the ray origin to the negative surface of the box.
  vec3 t2 = -n + k;   // how many steps on each axis to get from the ray origin to the positive surface of the box.

  float timeNear = max(max(t1.x, t1.y), t1.z);
  float timeFar = min(min(t2.x, t2.y), t2.z);

  if(timeNear > timeFar || timeFar < 0.0)
    return vec4(-1.0);

	//vec3 normal = -sign(rayDirection)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

  if(timeNear < 0.0)
    timeNear = timeFar;

  vec3 relPoint = rayOrigin + rayDirection * timeNear;

  vec3 absRelPoint = abs(relPoint) / boxHalfSizes;

  vec3 normal;
  vec3 uaxis;
  vec3 vaxis;
    // if Y isn't the biggest value it can't be the normal axis
  if(absRelPoint.x >= absRelPoint.y) {
        // if X is the winner
    if(absRelPoint.x >= absRelPoint.z) {
      normal = vec3(1.0, 0.0, 0.0) * -sign(rayDirection);
      uaxis = vec3(0.0, 1.0, 0.0);
      vaxis = vec3(0.0, 0.0, 1.0);
    }
        // else it's Z
    else {
      normal = vec3(0.0, 0.0, 1.0) * -sign(rayDirection);
      uaxis = vec3(1.0, 0.0, 0.0);
      vaxis = vec3(0.0, 1.0, 0.0);
    }
  }
    // else X isn't the biggest value so it can't be the normal axis
  else {
        // if Y is the winner
    if(absRelPoint.y >= absRelPoint.z) {
      normal = vec3(0.0, 1.0, 0.0) * -sign(rayDirection);
      uaxis = vec3(1.0, 0.0, 0.0);
      vaxis = vec3(0.0, 0.0, 1.0);
    }
        // else it's Z
    else {
      normal = vec3(0.0, 0.0, 1.0) * -sign(rayDirection);
      uaxis = vec3(1.0, 0.0, 0.0);
      vaxis = vec3(0.0, 1.0, 0.0);
    }
  }

  uv = vec2(dot(relPoint, uaxis), dot(relPoint, vaxis));

  return vec4(timeNear, normal);
}

//============================================================
// returns t and surface normal
// sphere xyz = position, w = radius
vec4 RayIntersectSphere(in vec3 rayPos, in vec3 rayDir, in vec4 sphere) {
	//get the vector from the center of this circle to where the ray begins.
  vec3 m = rayPos - sphere.xyz;

    //get the dot product of the above vector and the ray's vector
  float b = dot(m, rayDir);

  float c = dot(m, m) - sphere.w * sphere.w;

	//exit if r's origin outside s (c > 0) and r pointing away from s (b > 0)
  if(c > 0.0 && b > 0.0)
    return vec4(-1.0);

	//calculate discriminant
  float discr = b * b - c;

	//a negative discriminant corresponds to ray missing sphere
  if(discr < 0.0)
    return vec4(-1.0);

	//ray now found to intersect sphere, compute smallest t value of intersection
  float normalMultiplier = 1.0;
  float collisionTime = -b - sqrt(discr);
  if(collisionTime < 0.0) {
    collisionTime = -b + sqrt(discr);
    normalMultiplier = -1.0;
  }

    // calculate the normal, flipping it if we hit the inside of the sphere
  vec3 normal = normalize((rayPos + rayDir * collisionTime) - sphere.xyz) * normalMultiplier;

    // return the time t that the collision happened, as well as the surface normal
  return vec4(collisionTime, normal);
}

//============================================================
// returns t and surface normal
// plane xyz = normal, w = d
// from https://www.cs.princeton.edu/courses/archive/fall00/cs426/lectures/raycast/sld017.htm
vec4 RayIntersectPlane(in vec3 rayPos, in vec3 rayDir, in vec4 plane, out vec2 uv) {
  float collisionTime = -(dot(rayPos, plane.xyz) + plane.w) / dot(rayDir, plane.xyz);
  vec3 uaxis = normalize(cross(plane.xyz, vec3(0.0, 1.0, 0.0)));
  vec3 vaxis = normalize(cross(plane.xyz, uaxis));
  vec3 collisionPos = rayPos + rayDir * collisionTime;
  uv.x = dot(collisionPos, uaxis);
  uv.y = dot(collisionPos, vaxis);
  return vec4(collisionTime, plane.xyz);
}

//============================================================
void TrimRayInterval(vec3 rayPos, vec3 rayDir, inout vec2 rayMinMax, vec4 plane, inout vec3 nearNormal, inout vec3 farNormal) {
  vec2 uv;
  vec4 rayInfo = RayIntersectPlane(rayPos, rayDir, plane, uv);
  if(dot(rayInfo.yzw, rayDir) < 0.0) {
    if(rayInfo.x > rayMinMax.x) {
      rayMinMax.x = rayInfo.x;
      nearNormal = rayInfo.yzw;
    }
  } else {
    if(rayInfo.x < rayMinMax.y) {
      rayMinMax.y = rayInfo.x;
      farNormal = rayInfo.yzw;
    }
  }
}

//============================================================
vec4 RayIntersectObject(in vec3 rayPos, in vec3 rayDir) {
    #if OBJECT_TYPE == 0
  return RayIntersectSphere(rayPos, rayDir, vec4(0.0, 0.0, 0.0, 0.5));
    #elif OBJECT_TYPE == 1
  vec2 uv;
  vec4 ret = RayIntersectBox(rayPos, rayDir, vec3(0.5), uv);
  if(dot(rayDir, ret.yzw) > 0.0)
    ret.yzw *= -1.0;
  return ret;
    #elif OBJECT_TYPE == 2
  vec2 rayMinMax = vec2(-1.0, 1000.0);
  vec3 nearNormal;
  vec3 farNormal;

  float size = -0.5;
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(1.0, 0.2, -0.4)), size), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-1.0, 0.2, -0.4)), size), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, 1.0, 1.0)), size * 0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, -1.0, 0.0)), size), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, -0.3, 1.0)), size), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, 0.3, -1.0)), size), nearNormal, farNormal);

  if(rayMinMax.x > rayMinMax.y)
    return vec4(-1.0);

  if(rayMinMax.x > 0.0)
    return vec4(rayMinMax.x, nearNormal);
  else
    return vec4(rayMinMax.y, -farNormal);
    #else
  // Diamond's model from https://www.shadertoy.com/view/NlVSzh
  vec2 rayMinMax = vec2(-1.0, 1000.0);
  vec3 nearNormal;
  vec3 farNormal;

  // float size = -0.5;
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, 0.70711, 0.70711)), -0.53033), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.70711, -0.5, -0.5)), 0.), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, 0.0, -1.)), 0.0), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-0.70711, -0.5, -0.5)), -0.0), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-0., -1., 0.0)), -0.0), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.70711, 0.5, 0.5)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.5, 0.85355, 0.14645)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.0, 1.0, 0.0)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-0.5, 0.85355, 0.14645)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-0.70711, 0.5, 0.5)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-0.5, 0.14645, 0.85355)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(-0., 0.0, 1.0)), -0.5), nearNormal, farNormal);
  TrimRayInterval(rayPos, rayDir, rayMinMax, vec4(normalize(vec3(0.5, 0.14645, 0.85355)), -0.5), nearNormal, farNormal);

  if(rayMinMax.x > rayMinMax.y)
    return vec4(-1.0);

  if(rayMinMax.x > 0.0)
    return vec4(rayMinMax.x, nearNormal);
  else
    return vec4(rayMinMax.y, -farNormal);
    #endif
}

//============================================================
vec3 Checkerboard(vec2 uv) {
  return vec3(mod(floor(uv.x * 4.0) + floor(uv.y * 4.0), 2.0) < 1.0 ? 1.0 : 0.4);
}

//============================================================
vec3 LightPixel(vec3 rayPos, vec3 rayDir, vec3 diffuse, vec3 normal, float specPower, bool doShadow) {   
    // ambient
  vec3 pixelColor = diffuse * LIGHT_AMBIENT;

    // see if we are in shadow by casting in the light direction and seeing if we hit the object.
    // if we do hit the object, return just the ambient lighting shaded color we have already calculated.
  if(doShadow && normal.y >= 0.9 && RayIntersectObject(rayPos, -LIGHT_DIRECTIONAL_DIR).x >= 0.0)
    return pixelColor;

    // diffuse
  float dp = clamp(dot(normal, -LIGHT_DIRECTIONAL_DIR), 0.0, 1.0);
  pixelColor += diffuse * dp * LIGHT_DIRECTIONAL_COLOR;

    // specular highlight
  if(specPower > 0.0) {
    vec3 reflection = reflect(-LIGHT_DIRECTIONAL_DIR, normal);
    dp = clamp(dot(rayDir, reflection), 0.0, 1.0);
    pixelColor += LIGHT_DIRECTIONAL_COLOR * pow(dp, specPower);
  }

  return pixelColor;
}

//============================================================
float FresnelReflectAmount(float n1, float n2, vec3 normal, vec3 incident) {
    #if DO_FRESNEL
        // Schlick aproximation
  float r0 = (n1 - n2) / (n1 + n2);
  r0 *= r0;
  float cosX = -dot(normal, incident);
  if(n1 > n2) {
    float n = n1 / n2;
    float sinT2 = n * n * (1.0 - cosX * cosX);
            // Total internal reflection
    if(sinT2 > 1.0)
      return 1.0;
    cosX = sqrt(1.0 - sinT2);
  }
  float x = 1.0 - cosX;
  float ret = r0 + (1.0 - r0) * x * x * x * x * x;

        // adjust reflect multiplier for object reflectivity
  ret = (OBJECT_REFLECTIVITY + (1.0 - OBJECT_REFLECTIVITY) * ret);
  return ret;
    #else
  return OBJECT_REFLECTIVITY;
    #endif
}

//============================================================
vec3 GetSceneRayColor(in vec3 rayPos, in vec3 rayDir) {
    // Returns the lit RGB for this ray intersecting with the scene, ignoring the main object.
    // Used for reflection off the surface of the object, and refraction out the back of the object.

    // if we hit the box, return the lit box color
  vec2 uv;
  vec4 rayInfo = RayIntersectBox(rayPos + vec3(0.0, 1.51, 0.0), rayDir, vec3(1.0, 1.0, 1.0), uv);
  if(rayInfo.x >= 0.0)
    return LightPixel(rayPos + rayDir * rayInfo.x, rayDir, Checkerboard(uv), rayInfo.yzw, 100.0, true);
    // else return skybox color
  else
    return texture(iChannel0, rayDir).rgb;
}

//============================================================
vec3 GetObjectInternalRayColor(in vec3 rayPos, in vec3 rayDir) {
    // bounce around inside the object as many times as needed (or until max bounces) due total internal reflection
  float multiplier = 1.0;
  vec3 ret = vec3(0.0);
  float absorbDistance = 0.0;
  for(int i = 0; i < MAX_RAY_BOUNCES; ++i) {
        // try and intersect the object
    vec4 rayInfo = RayIntersectObject(rayPos, rayDir);

        // should "never" happen but handle it anyways
    if(rayInfo.x < 0.0)
      return ret;

        // move the ray position to the intersection point.
    rayPos = rayPos + rayDir * rayInfo.x;

        // calculate beer's law absorption.
    absorbDistance += rayInfo.x;
    vec3 absorb = exp(-OBJECT_ABSORB * absorbDistance);

        // calculate how much to reflect or transmit (refract or diffuse)
    float reflectMultiplier = FresnelReflectAmount(REFRACTIVE_INDEX_INSIDE, REFRACTIVE_INDEX_OUTSIDE, rayDir, rayInfo.yzw);
    float refractMultiplier = 1.0 - reflectMultiplier;

        // add in refraction outside of the object
    vec3 refractDir = refract(rayDir, rayInfo.yzw, REFRACTIVE_INDEX_INSIDE / REFRACTIVE_INDEX_OUTSIDE);
    ret += GetSceneRayColor(rayPos + refractDir * 0.001, refractDir) * refractMultiplier * multiplier * absorb;

        // add specular highlight based on refracted ray direction
    ret += LightPixel(rayPos, rayDir, OBJECT_DIFFUSE, refractDir, OBJECT_SPECPOWER, false) * refractMultiplier * multiplier * absorb; 

        // follow the ray down the internal reflection path.
    rayDir = reflect(rayDir, rayInfo.yzw);

        // move the ray slightly down the reflect path
    rayPos += rayDir * 0.001;

        // For reflection, we are only going to be reflecting what is refracted on further bounces.
        // So, we just need to make sure the next bounce is added in at the reflectMultiplier amount, recursively.
    multiplier *= reflectMultiplier;
  }

    // return the color we calculated
  return ret;
}

//============================================================
vec3 RayTracePixelColor(in vec3 rayPos, in vec3 rayDir) {
  vec4 bestRayHitInfo = vec4(1000.0, 0.0, 0.0, 0.0);
  vec3 rayHitDiffuse = vec3(1.0);
  vec3 additiveColor = vec3(0.0);

  vec3 ret = vec3(0.0);

    // see if we've hit the platform and remember if we have
  vec2 uv;
  vec4 rayInfo = RayIntersectBox(rayPos + vec3(0.0, 1.51, 0.0), rayDir, vec3(1.0, 1.0, 1.0), uv);
  if(rayInfo.x >= 0.0 && rayInfo.x < bestRayHitInfo.x) {
    bestRayHitInfo = rayInfo;
    rayHitDiffuse = Checkerboard(uv);
  }

    // if we've hit the main object, and it's closer than the platform
  // vec4 rayInfo = RayIntersectObject(rayPos, rayDir);
  rayInfo = RayIntersectObject(rayPos, rayDir);
  if(rayInfo.x >= 0.0 && rayInfo.x < bestRayHitInfo.x) {       
        // light the surface of the ball a bit
    additiveColor += LightPixel(rayPos, rayDir, OBJECT_DIFFUSE, rayInfo.yzw, OBJECT_SPECPOWER, false);

        // move the ray to the intersection point
    rayPos += rayDir * rayInfo.x;    

        // calculate how much to reflect or transmit (refract or diffuse)
    float reflectMultiplier = FresnelReflectAmount(REFRACTIVE_INDEX_OUTSIDE, REFRACTIVE_INDEX_INSIDE, rayDir, rayInfo.yzw);
    float refractMultiplier = 1.0 - reflectMultiplier;

        // get reflection color
        #if DO_REFLECTION
    vec3 reflectDir = reflect(rayDir, rayInfo.yzw);
    ret += GetSceneRayColor(rayPos + reflectDir * 0.001, reflectDir) * reflectMultiplier;
        #endif

        // get refraction color
        #if DO_REFRACTION
    vec3 refractDir = refract(rayDir, rayInfo.yzw, REFRACTIVE_INDEX_OUTSIDE / REFRACTIVE_INDEX_INSIDE);
    ret += GetObjectInternalRayColor(rayPos + refractDir * 0.001, refractDir) * refractMultiplier;
        #endif

    return ret + additiveColor;
  }
    // else we missed the object, so return either the skybox color, or the platform color, as appropriate
  else {
    if(bestRayHitInfo.x == 1000.0)
      return texture(iChannel0, rayDir).rgb;
    else {
            // move the ray to the intersection point (so we can shadow) and light the pixel
      rayPos += rayDir * bestRayHitInfo.x;
      return LightPixel(rayPos, rayDir, rayHitDiffuse, bestRayHitInfo.yzw, 100.0, true);
    }
  }
}

//============================================================
void mainImage(out vec4 fragColor, in vec2 fragCoord) {        
    //----- Camera Setup
  vec2 mouse = iMouse.xy / iResolution.xy;

  vec3 cameraAt = vec3(0.0);

  float angleX = iMouse.z > 0.0 ? 6.28 * mouse.x : 3.14 + iTime * 0.25;
  float angleY = iMouse.z > 0.0 ? (mouse.y * 6.28) - 0.4 : 0.5;
  vec3 cameraPos = (vec3(sin(angleX) * cos(angleY), sin(angleY), cos(angleX) * cos(angleY))) * 3.0;

  vec3 cameraFwd = normalize(cameraAt - cameraPos);
  vec3 cameraLeft = normalize(cross(normalize(cameraAt - cameraPos), vec3(0.0, sign(cos(angleY)), 0.0)));
  vec3 cameraUp = normalize(cross(cameraLeft, cameraFwd));

  float cameraViewWidth = 6.0;
  float cameraViewHeight = cameraViewWidth * iResolution.y / iResolution.x;
  float cameraDistance = 6.0;  // intuitively backwards!

    //----- Ray Setup
  vec2 rawPercent = (fragCoord.xy / iResolution.xy);
  vec2 percent = rawPercent - vec2(0.5, 0.5);

  vec3 rayTarget = (cameraFwd * vec3(cameraDistance, cameraDistance, cameraDistance)) - (cameraLeft * percent.x * cameraViewWidth) + (cameraUp * percent.y * cameraViewHeight);
  vec3 rayDir = normalize(rayTarget);    

    //----- Ray Trace
  vec3 finalColor = vec3(0.0);
    #if DO_AA
  for(int i = 1; i <= 16; ++i) {
            // calculate stratified subpixel jitter in a 4x4 grid
    float x = mod(float(i) - 1.0, 4.0);
    float y = mod(floor(float(i) / 4.0), 4.0);
    vec2 jitter = hash21(float(i)) / 4.0;
    jitter.x += x / 4.0;
    jitter.y += y / 4.0;

            // set up the jittered ray
    rawPercent = ((fragCoord.xy + jitter) / iResolution.xy);
    percent = rawPercent - vec2(0.5, 0.5);

    rayTarget = (cameraFwd * vec3(cameraDistance, cameraDistance, cameraDistance)) - (cameraLeft * percent.x * cameraViewWidth) + (cameraUp * percent.y * cameraViewHeight);
    rayDir = normalize(rayTarget);                

			// raytrace
    vec3 color = RayTracePixelColor(cameraPos, rayDir);

            // incrementally average our pixel color in
    finalColor = mix(finalColor, color, 1.0 / float(i));
  }
    #else
  finalColor = RayTracePixelColor(cameraPos, rayDir);
    #endif

    //----- Final color, gamma corrected
  fragColor = vec4(pow(finalColor, vec3(1.0 / 2.2)), 1.0);
}
