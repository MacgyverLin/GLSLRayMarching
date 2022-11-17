#define PI 3.14159265359
#define SOFT_STEPS 16
#define RAYS_STEPS 100

// uncomment this to show a closeup of the ant
// #define SHOW_ANT

// hopefully this should compile to a const mat2
#define rot_const(a) (mat2(cos(a), sin(a), -sin(a), cos(a)))

// Fabrice's rotation matrix
mat2 rot( in float a ) {
    vec2 v = sin(vec2(PI*0.5, 0) + a);
    return mat2(v, -v.y, v.x);
}

// Dave Hoskins hash function
vec3 hash33( in vec3 p3 ) {
    #define HASHSCALE3 vec3(.1031, .1030, .0973)
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// iq's functions
float sdBox( in vec3 p, in vec3 b ) {
	vec3 d = abs(p) - b;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdCapsule( in vec3 p, in vec3 a, in vec3 b, in float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
float sdEllipsoid( in vec3 p, in vec3 r ) {
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}
float smin( in float a, in float b, in float s ) {
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0.0, 1.0 );
    return mix(b, a, h) - h*(1.0-h)*s;
}
float smax( in float a, in float b, in float s ) {
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0.0, 1.0 );
    return mix(b, a, h) + h*(1.0-h)*s;
}

// intersection of 2 circles, by eiffie (used for the legs IKs)
vec2 intersect(vec3 c0, vec3 c1) {
    vec2 dxy = vec2(c1.xy - c0.xy);
    float d = length(dxy);
    float a = (c0.z*c0.z - c1.z*c1.z + d*d)/(2.*d);
    vec2 p2 = c0.xy + (a / d)*dxy;
    float h = sqrt(c0.z*c0.z - a*a);
    vec2 rxy = vec2(-dxy.y, dxy.x) * (h/d);
    return p2 + rxy;
}

// ant's legs distance function
float deAntLeg(in vec3 p, in vec3 anchor, in vec3 legStart,
               in float lenStart, in vec3 legEnd, in float lenEnd) {
    
	// express coordinates from the starting leg
    vec3 inLeg = p - legStart;
    vec3 legEndInStart = legEnd - legStart;
    // express coordinates in the leg plane
    vec3 xDir = normalize(vec3(legEnd.xy - legStart.xy, 0));
    vec2 planar = vec2(dot(inLeg, xDir), inLeg.z);
    vec2 endInPlanar = vec2(dot(legEndInStart, xDir), legEndInStart.z);
    
    // get intersection
    vec2 jointPlanar = intersect( vec3(0, 0, lenStart), vec3(endInPlanar, lenEnd) );
    // go back to 3D space
    vec3 joint = legStart + xDir*jointPlanar.x + vec3(0, 0, 1)*jointPlanar.y;
    
    float d = sdCapsule( p, anchor, legStart, 0.03 );
    d = smin(d, sdCapsule( p, legStart, joint, 0.02 ), 0.02);
    d = smin(d, sdCapsule( p, joint, legEnd, 0.015 ), 0.02);
    return d;
    
}

// ant distance function, phase is the animation (between 0 and 1)
float deAnt( in vec3 p, in float phase, out vec3 color1, out vec3 color2, out float roughness ) {
    
    color1 = vec3(0.90, 0.18, 0.01);
    color2 = vec3(0.35, 0.10, 0.01);
    roughness = 12.0;
    
    p = p.zyx;
    
    // bounding box optimization
    float bb = sdBox(p, vec3(1.1, 0.5, 0.5));
    if (bb > 0.5) {
        return bb;
    }
    
    p -= vec3(-0.05, 0, 0.75);
    
    // 3 parts for the ant
    const vec2 slopeCenter = vec2(0.4, 0.8);
    vec2 inSlope = slopeCenter - p.xz;
    float slope = atan(inSlope.y, inSlope.x);
    slope /= PI;
    float part = clamp(floor(slope * 10.0), 3.0, 5.0);
    slope = (part + 0.5) / 10.0;
    slope *= PI;
    vec2 center = slopeCenter - vec2(cos(slope), sin(slope)) * 1.6;
    vec3 partCenter = vec3(center.x, 0.0, center.y);
    
    vec3 inPart = p - partCenter;
    float side = sign(inPart.y);
    inPart.y = abs(inPart.y);
    
    float dist = bb;
    
    if (part > 4.5) {
        
        // rotation
        inPart.x += 0.3;
        float r = sin(phase*2.0*PI)*0.05;
        inPart.xz *= rot(r-0.1);
        inPart.x -= 0.3;
        
        // abdomen
        inPart -= vec3(0.33, 0.0, -0.02);
        float radius = 0.1 + smoothstep(-0.2, 0.7, -inPart.x) * 0.5;
        
        // add ridges
        float s = cos(-inPart.x*40.0)*0.5+0.5;
        s *= s; s *= s;
        radius -= s*0.005;
        
        dist = length(inPart) - radius;
        float sMix = pow(s, 8.0);
        color1 = mix(vec3(0.1, 0.05, 0.01), vec3(0.6, 0.5, 0.4), sMix);
        color2 = mix(vec3(0.05, 0.02, 0.01), vec3(0.5, 0.4, 0.2), sMix);
        roughness = 16.0 - s*12.0;
        
    } else if (part > 3.5) {
        
        // thorax
        inPart += vec3(0.02, 0.0, -0.05);
        inPart.xz *= rot_const(-0.3);
        
        // pronotum
        vec3 inThoraxA = inPart - vec3(-0.13, 0.0, 0.05);
        float radiusA = 0.10 + smoothstep(-0.1, 0.5, inThoraxA.x) * 0.2;
        radiusA -= smoothstep(-0.1, 0.2, inThoraxA.z) * 0.1;
        float thoraxDistA = length(inThoraxA) - radiusA;
        
        // propodeum
        vec3 inThoraxB = inPart - vec3(0.06, 0.0, 0.03);
        float radiusB = 0.05 + smoothstep(-0.1, 0.4, inThoraxB.x) * 0.2;
        radiusB -= smoothstep(-0.1, 0.4, inThoraxA.z) * 0.1;
        float thoraxDistB = length(inThoraxB) - radiusB;
        dist = smin(thoraxDistA, thoraxDistB, 0.05);
        
        // petiole
        vec3 inThoraxC = inPart - vec3(0.24, 0.0, 0.0);
        float radiusC = 0.05 - smoothstep(-0.1, 0.2, inThoraxC.z-inThoraxC.x*0.3) * 0.04;
        float thoraxDistC = sdCapsule( inThoraxC, vec3(0), vec3(-0.03, 0, 0.11), radiusC);
        dist = smin(dist, thoraxDistC, 0.03);
        
        // add ridges
        vec3 inRidges = inPart - vec3(0.01, 0.0, 0.1);
        float ridgesDist = abs(length(inRidges) - 0.12);
        dist += smoothstep(0.02, 0.0, ridgesDist) * 0.004;
        
    } else if (part > 2.5) {
        
        // head
        inPart -= vec3(-0.09, 0.0, -0.06);
        inPart.xz *= rot_const(0.3);
        float radius = 0.07 + smoothstep(-0.15, 0.4, inPart.x) * 0.3;
        radius -= smoothstep(0.0, 0.4, abs(inPart.z))*0.2;
        dist = length(inPart) - radius;
        
        // frontal carina
        vec3 inCarina = inPart - vec3(0.02, 0.0, 0.09);
        inCarina.xy *= rot_const(-0.4);
        inCarina.xz *= rot_const(0.1);
        float carina = sdBox( inCarina, vec3(0.1, 0.05, 0.01) ) - 0.01;
        dist = smin(dist, carina, 0.05);
        
        // antenna
        vec3 inAntenna = inPart - vec3(-0.03, 0.1, 0.1);
        inAntenna.yz *= rot_const(-0.4);
        inAntenna.xz *= rot(sin((phase+side*0.25)*2.0*PI)*0.3-0.2);
        const vec3 funiculusStart = vec3(0, 0, 0.3);
        float scapeRadius = 0.007 + inAntenna.z*0.04;
        float scape = sdCapsule( inAntenna, vec3(0), funiculusStart, scapeRadius );
        vec3 funiculusDir = normalize(vec3(-0.5, 0.0, -0.1));
        funiculusDir.xz *= rot(sin((phase+side*0.25)*4.0*PI)*0.2);
        float funiculusRadius = dot(funiculusDir, inAntenna - funiculusStart);
        funiculusRadius = abs(sin(funiculusRadius*67.0));
        funiculusRadius = 0.01 + funiculusRadius*0.004;
        float funiculus = sdCapsule(inAntenna, funiculusStart, 
                                    funiculusStart+funiculusDir*0.5, funiculusRadius );
        float antennaDist = min(scape, funiculus);
        dist = min(dist, antennaDist);
        
        // mandibles
        vec3 inMandibles = inPart;
        inMandibles.xy *= rot(sin(phase*4.0*PI)*0.1-0.1);
        float mandiblesOuter = sdEllipsoid( inMandibles, vec3(0.25, 0.14, 0.1) );
        float mandiblesInner = sdEllipsoid( inMandibles, vec3(0.15, 0.1, 0.4) );
        float mandibles = smax(mandiblesOuter, -mandiblesInner, 0.05);
        mandibles = smax(mandibles, 0.005-inMandibles.y+sin(inMandibles.x*300.0)*0.005, 0.01);
        dist = smin(dist, mandibles, 0.05);
        
        // eyes
        float eyes = sdEllipsoid( inPart - vec3(0.21, 0.15, 0.03), vec3(0.06, 0.05, 0.05 ) );
        if (eyes < dist) {
            color1 = color2 = vec3(0.05);
            roughness = 32.0;
            dist = eyes;
        }

    }
    
    // add a capsule in the center to connect the parts
    float connector = sdCapsule( p, vec3(-0.15, 0, -0.63), vec3(0.5, 0, -0.83), 0.03);
    dist = min(dist, connector);
    
    // add legs
    vec3 inLegs = p;
    inLegs.y = abs(inLegs.y);
    phase += side*0.25;
    
    float angleA = (phase)*PI*2.0;
    vec3 legAOffset = vec3(cos(angleA), 0, max(0.0, sin(angleA)))*0.2;
    float legA = deAntLeg(inLegs, vec3(0.05, 0.0, -0.75),
                          vec3(0.1, 0.1, -0.82), 0.25, 
                          vec3(-0.2, 0.4, -1.2)+legAOffset, 0.5);
    float angleB = (phase+0.33)*PI*2.0;
    vec3 legBOffset = vec3(cos(angleB), 0, max(0.0, sin(angleB)))*0.2;
    float legB = deAntLeg(inLegs, vec3(0.18, 0.0, -0.8),
                          vec3(0.2, 0.1, -0.85), 0.3, 
                          vec3(0.3, 0.5, -1.2)+legBOffset, 0.6);
    float angleC = (phase+0.66)*PI*2.0;
    vec3 legCOffset = vec3(cos(angleC), 0, max(0.0, sin(angleC)))*0.2;
    float legC = deAntLeg(inLegs, vec3(0.25, 0.0, -0.8),
                          vec3(0.3, 0.1, -0.85), 0.4, 
                          vec3(0.6, 0.4, -1.2)+legCOffset, 0.7);
    
    float distLegs = min(min(legA, legB), legC);
    if (distLegs < dist) {
        color1 = vec3(0.35, 0.10, 0.01);
        color2 = vec3(0.05, 0.02, 0.01);
        dist = distLegs;
    }
    
    return dist;
}

// main distance function, coordinates in, distance and surface parameters out
float de( in vec3 p, out vec3 color1, out vec3 color2, out float roughness ) {
    
    color1 = vec3(0.7);
    color2 = vec3(0.7);
    roughness = 4.0;
    
    #ifdef SHOW_ANT
    return deAnt(p.zxy, fract(iTime), color1, color2, roughness);
    #endif
    
    // perimeter of the moebius strip is 38
    #define RADIUS (1.0/(PI*2.0)*38.0)
    
    // cylindrical coordinates
    vec2 cyl = vec2(length(p.xy), p.z);
    float theta = atan(p.x, p.y);
    vec2 inCyl = vec2(RADIUS, 0) - cyl;
    // rotate 180бу to form the loop
    inCyl *= rot(theta*1.5-2.0);
    // coordinates in a torus (cylindrical coordinates + position on the stripe)
    vec3 inTor = vec3(inCyl, theta * RADIUS);
    
    // add the band
    float bandDist = sdBox(inTor, vec3(0.05, 1, 100)) - 0.05;
    float d = bandDist;
    // add holes
    vec3 inHole = vec3(mod(inTor.yz, vec2(0.5)) - vec2(0.25), inTor.x);
    inHole.xyz = inHole.zxy;
    float holeDist = sdBox(inHole, vec3(0.18));
    d = smax(d, -holeDist, 0.05);
    
    // add ants
    vec3 inTorObj = vec3(abs(inTor.x), inTor.y, inTor.z + iTime*1.3 + sign(inTor.x));
    float ant = floor(inTorObj.z / 4.0);
    vec3 objCenter = vec3(0.6, 0, ant * 4.0 + 2.0);
    float phase = fract(iTime) + mod(ant, 9.0) / 9.0;
    vec3 antColor1 = vec3(0.0);
    vec3 antColor2 = vec3(0.0);
    float antRoughness = 0.0;
    float antDist = deAnt(inTorObj-objCenter, phase, antColor1, antColor2, antRoughness);
    if (antDist < d) {
        color1 = antColor1;
        color2 = antColor2;
        roughness = antRoughness;
        return antDist;
    }
    
	return d;
}

float de( in vec3 p ) {
    vec3 dummy1 = vec3(0);
    vec3 dummy2 = vec3(0);
    float dummy3 = 0.0;
    return de(p, dummy1, dummy2, dummy3);
}

// normal from backward difference
vec3 computeNormal( in vec3 p, in float d ) {
	const vec3 e = vec3(0.0, 0.01, 0.0);
	return normalize(vec3(
		d-de(p-e.yxx),
		d-de(p-e.xyx),
		d-de(p-e.xxy)));	
}

// cone trace the soft shadows
float computeSoftShadows( in vec3 from, in vec3 dir, in float theta ) {
    float sinTheta = sin(theta);
    float acc = 1.0;
    float totdist = 0.0;
    for (int i = 0 ; i < SOFT_STEPS ; i++) {
        vec3 p = from + totdist * dir;
        float dist = de(p);
        float prox = dist / (totdist*sinTheta);
        acc *= clamp(prox * 0.5 + 0.5, 0.0, 1.0);
        if (acc < 0.01) break;
        totdist += max(0.01, dist*0.85);
    }
    return acc;
}

// compute lighting at this position
vec3 computeColor( in vec3 p, in vec3 dir, in vec2 fragCoord ) {
    
    // sunlight and ambient
    const vec3 sunLight = vec3(0.9, 0.8, 0.6)*9.0;
    const vec3 sunLightDir = normalize(vec3(-2, -1, 3));
    const vec3 subLight = vec3(0.4, 0.4, 0.8)*3.0;
    const vec3 subLightDir = normalize(vec3(2, -1, -8));
    const vec3 ambLight = vec3(0.7, 0.7, 0.9)*4.0;
    
    // compute distance to get the surface albedo
    vec3 albedo1 = vec3(0);
    vec3 albedo2 = vec3(0);
    float roughness = 0.0;
    float dist = de(p, albedo1, albedo2, roughness);
    
    // compute surface normal
    vec3 normal = computeNormal(p, dist);
    
    float specScale = (roughness+1.0)*0.25;
    float sunLightDiff = max(0.0, dot(normal, sunLightDir));
    float sunLightSpec = pow(max(0.0, dot(sunLightDir, reflect(dir, normal))), roughness);
    sunLightSpec *= specScale;
    float subLightDiff = max(0.0, dot(normal, subLightDir));
    float subLightSpec = pow(max(0.0, dot(subLightDir, reflect(dir, normal))), roughness);
    subLightSpec *= specScale;
    
   	// soft shadows
    float soft = 0.0;
    if (sunLightDiff > 0.01) {
        soft = computeSoftShadows(p+normal*0.05, sunLightDir, 0.2);
    }
    
    // fake subsurface scattering
    float subsurface = max(0.0, dot(normal, -dir));
    subsurface = pow(subsurface, 4.0);
    vec3 albedo = mix(albedo2, albedo1, subsurface);
    
    // do some arty sketchy stuff on the light
    float sun = (sunLightDiff+sunLightSpec)*soft;
    float sub = (subLightDiff+subLightSpec);
    float amb = 1.0;
    vec3 lightValues = vec3(sun, sub, amb);
    
    // exposition
    lightValues *= 0.06;
    // gamma correction
    lightValues = pow( lightValues, vec3(1.0/2.2) );
    // cel shading
    lightValues = floor(lightValues * 7.0) / 6.0;
    
    // compose color
    vec3 color = vec3(0);
    color += albedo*sunLight*lightValues.x;
    color += albedo*subLight*lightValues.y;
    color += albedo*ambLight*lightValues.z;
    
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	
    // position of the camera
    vec3 camPos = vec3(-40, 0, 0);
    // user input
    vec2 mouse=(iMouse.xy / iResolution.xy - 0.5) * 0.5;
    mouse *= step(1.0, iMouse.z);
    camPos.xz *= rot(mouse.y*-3.0+0.4);
    camPos.xy *= rot(mouse.x*-10.0+0.2);
    
    // direction of the camera
    vec3 forward = normalize(vec3(0) - camPos);
    // right and top vector
    vec3 right = normalize(cross(vec3(0, 0, 1), forward));
    vec3 top = cross(forward, right);
    
    // create direction
    vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
	uv.y *= iResolution.y / iResolution.x;
    uv *= 0.2;
    #ifdef SHOW_ANT
    uv *= 0.2;
    #endif
    vec3 dir = normalize(forward + right*uv.x + top*uv.y);
    
    // some noise is always useful
    vec3 noise = hash33(vec3(fragCoord.xy, iFrame));
    
    bool hit = false;
    float prevDist = 0.0;
    float borderAcc = 1.0;
    
    float totdist = 0.0;
    totdist += de(camPos)*noise.x;
    
	for (int i = 0 ; i < RAYS_STEPS ; i++) {
		vec3 p = camPos + totdist * dir;
        float dist = de(p);
        
// if you replace 0.0015 by the sine of the pixel angle, you get the average opacity in a pixel
// by accumulating the opacity front to back you can get an anti-aliased edge
// problem is you have to compute the normal to shade the surface and get the effective color
// computing the normal at every steps is too expensive (unless the normal is analytical)
// nonetheless the border color is constant so we can cone trace it without any trouble
        
        // cone trace the border
        if (dist > prevDist) {
            float prox = dist / (totdist*0.0015);
            float alpha = clamp(prox * 0.5 + 0.5, 0.0, 1.0);
            borderAcc *= alpha;
        }
        
        // hit a surface, stop here
        if (dist < 0.01) {
            hit = true;
            break;
        }
        
        // continue forward
        totdist += min(dist*0.85, 100.0);
        prevDist = dist;
	}
    
    // color and lights
    if (hit) {
        vec3 p = camPos + totdist * dir;
    	fragColor.rgb = computeColor(p, dir, fragCoord.xy);
    } else {
        fragColor.rgb = vec3(0.8, 0.8, 0.9);
    }
    
    // add a black border
    borderAcc = pow(borderAcc, 8.0);
    fragColor.rgb = mix(vec3(0), fragColor.rgb, borderAcc);
    
    // vigneting
    vec2 p = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
    fragColor.rgb = mix(fragColor.rgb, vec3(0), dot(p, p)*0.2);
	
    // add some noise
    fragColor.rgb += noise * 0.08 - 0.04;
    
    fragColor.a = 1.0;
}