/*
	Desert Canyon
	-------------

	Just a simple canyon fly through. Since the laws of physics aren't adhered to (damn stray floating 
	rocks), you can safely assume the setting is a dry, rocky desert on a different planet... in an 
	alternate reality. :)

	I thought I'd do a daytime scene for a change. I like the way they look, but I find they require
	more effort to light up correctly. In this particular example, I had to find the balance between
	indoor and outdoor lighting, but keep it simple enough to allow reasonable frame rates for swift 
	camera movement. For that reason, I was really thankful to have some of Dave Hoskins's and IQ's 
	examples to refer to.

	The inspiration for this particular scene came from Dr2's flyby examples. This is obviously less
	complicated, since his involve flybys with actual planes. Really cool, if you've never seen them.

	Anyway, I'll put up a more interesting one at a later date.
	

	Outdoor terrain shaders:

	Elevated - iq
	https://www.shadertoy.com/view/MdX3Rr
	Based on his (RGBA's) famous demo, Elevated.
	http://www.pouet.net/prod.php?which=52938

	// How a canyon's really done. :)
	Canyon - iq
	https://www.shadertoy.com/view/MdBGzG

	// Too many good ones to choose from, but here's one.
	// Mountains - Dave_Hoskins
	https://www.shadertoy.com/view/4slGD4

	// Awesome.
    River Flight - Dr2
    https://www.shadertoy.com/view/4sSXDG

*/

// The far plane. I'd like this to be larger, but the extra iterations required to render the 
// additional scenery starts to slow things down on my slower machine.
#define FAR 65.

// Frequencies and amplitudes of the "path" function, used to shape the tunnel and guide the camera.
const float freqA = .15/3.75;
const float freqB = .25/2.75;
const float ampA = 20.;
const float ampB = 4.;

// 2x2 matrix rotation. Angle vector, courtesy of Fabrice.
mat2 rot2( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// 1x1 and 3x1 hash functions.
float hash(float n){ return fract(cos(n)*45758.5453); }
float hash(vec3 p){ return fract(sin(dot(p, vec3(7, 157, 113)))*45758.5453); }

// Grey scale.
float getGrey(vec3 p){ return dot(p, vec3(0.299, 0.587, 0.114)); }

/*
// IQ's smooth minium function. 
float sminP(float a, float b , float s){
    
    float h = clamp(.5 + .5*(b - a)/s, 0., 1.);
    return mix(b, a, h) - h*(1.0-h)*s;
}
*/

// Smooth maximum, based on the function above.
float smaxP(float a, float b, float s){
    
    float h = clamp(.5 + .5*(a - b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ return vec2(ampA*sin(z * freqA), ampB*cos(z * freqB) + 3.*(sin(z*0.025)  - 1.)); }

// The canyon, complete with hills, gorges and tunnels. I would have liked to provide a far
// more interesting scene, but had to keep things simple in order to accommodate slower machines.
float map(in vec3 p){
    
    // Indexing into the pebbled texture to provide some rocky surface detatiling. I like this
    // texture but I'd much rather produce my own. From what I hear, Shadertoy will be providing
    // fixed offscreen buffer sizes (like 512 by 512, for instance) at a later date. When that
    // happens, I'll really be able to do some damage. :)
    float tx = textureLod(iChannel0, p.xz/16. + p.xy/80., 0.).x;
  
    // A couple of sinusoidal layers to produce the rocky hills.
    vec3 q = p*.25;
    float h = dot(sin(q)*cos(q.yzx), vec3(.222)) + dot(sin(q*1.5)*cos(q.yzx*1.5), vec3(.111));
    
    
    // The terrain, so to speak. Just a flat XZ plane, at zero height, with some hills added.
    float d = p.y + h*6.;
  
    // Reusing "h" to provide an undulating base layer on the tunnel walls.
    q = sin(p*.5 + h);
    h = q.x*q.y*q.z;
  
	// Producing a single winding tunnel. If you're not familiar with the process, this is it.
    // We're also adding some detailing to the walls via "h" and the rocky "tx" value.
    p.xy -= path(p.z);
    float tnl = 1.5 - length(p.xy*vec2(.33, .66)) + h + (1. - tx)*.25;

	// Smoothly combine the terrain with the tunnel - using a smooth maximum - then add some
    // detailing. I've also added a portion of the tunnel term onto the end, just because
    // I liked the way it looked more. 
    return smaxP(d, tnl, 2.) - tx*.5 + tnl*.8; 

}


// Log-Bisection Tracing
// https://www.shadertoy.com/view/4sSXzD
//
// Log-Bisection Tracing by nimitz (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Contact: nmz@Stormoid.com
//
// Notes: This is a trimmed down version of Nitmitz's original. If you're interested in the function 
// itself, refer to the original function in the link above. There, you'll find a good explanation as to 
// how it works too.
//
// For what it's worth, I've tried most of the standard raymarching methods around, and for difficult 
// surfaces to hone in on, like the one in this particular example, "Log Bisection" is my favorite.

float logBisectTrace(in vec3 ro, in vec3 rd){


    float t = 0., told = 0., mid, dn;
    float d = map(rd*t + ro);
    float sgn = sign(d);

    for (int i=0; i<96; i++){

        // If the threshold is crossed with no detection, use the bisection method.
        // Also, break for the usual reasons. Note that there's only one "break"
        // statement in the loop. I heard GPUs like that... but who knows?
        if (sign(d) != sgn || d < 0.001 || t > FAR) break;
 
        told = t;
        
        // Branchless version of the following:   
        // if(d>1.) t += d; else t += log(abs(d) + 1.1);     
        t += step(d, 1.)*(log(abs(d) + 1.1) - d) + d;
        //t += log(abs(d) + 1.1);
        //t += d;//step(-1., -d)*(d - d*.5) + d*.5;
        
        d = map(rd*t + ro);
    }
    
    // If a threshold was crossed without a solution, use the bisection method.
    if (sign(d) != sgn){
    
        // Based on suggestions from CeeJayDK, with some minor changes.

        dn = sign(map(rd*told + ro));
        
        vec2 iv = vec2(told, t); // Near, Far

        // 6 iterations seems to be more than enough, for most cases...
        // but there's an early exit, so I've added a couple more.
        for (int ii=0; ii<8; ii++){ 
            //Evaluate midpoint
            mid = dot(iv, vec2(.5));
            float d = map(rd*mid + ro);
            if (abs(d) < 0.001)break;
            // Suggestion from movAX13h - Shadertoy is one of those rare
            // sites with helpful commenters. :)
            // Set mid to near or far, depending on which side we're on.
            iv = mix(vec2(iv.x, mid), vec2(mid, iv.y), step(0.0, d*dn));
        }

        t = mid; 
        
    }
    

    return min(t, FAR);
}


// Tetrahedral normal, courtesy of IQ.
vec3 normal(in vec3 p)
{  
    vec2 e = vec2(-1, 1)*.001;   
	return normalize(e.yxx*map(p + e.yxx) + e.xxy*map(p + e.xxy) + 
					 e.xyx*map(p + e.xyx) + e.yyy*map(p + e.yyy) );   
}


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
   
    n = max(n*n, .001);
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}


// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 doBumpMap( sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor){
   
    const float eps = .001;
    vec3 grad = vec3( getGrey(tex3D(tex, vec3(p.x - eps, p.y, p.z), nor)),
                      getGrey(tex3D(tex, vec3(p.x, p.y - eps, p.z), nor)),
                      getGrey(tex3D(tex, vec3(p.x, p.y, p.z - eps), nor)));
    
    grad = (grad - getGrey(tex3D(tex, p, nor)))/eps; 
            
    grad -= nor*dot(nor, grad);          
                      
    return normalize(nor + grad*bumpfactor);
	
}

// The iterations should be higher for proper accuracy, but in this case, I wanted less accuracy, just to leave
// behind some subtle trails of light in the caves. They're fake, but they look a little like light streaming 
// through some cracks... kind of.
float softShadow(in vec3 ro, in vec3 rd, in float start, in float end, in float k){

    float shade = 1.;
    // Increase this and the shadows will be more accurate, but the wispy light trails in the caves will disappear.
    // Plus more iterations slow things down, so it works out, in this case.
    const int maxIterationsShad = 10; 

    // The "start" value, or minimum, should be set to something more than the stop-threshold, so as to avoid a collision with 
    // the surface the ray is setting out from. It doesn't matter how many times I write shadow code, I always seem to forget this.
    // If adding shadows seems to make everything look dark, that tends to be the problem.
    float dist = start;
    float stepDist = end/float(maxIterationsShad);

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){
        // End, or maximum, should be set to the distance from the light to surface point. If you go beyond that
        // you may hit a surface not between the surface and the light.
        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0., 1., k*h/dist));
        
        // What h combination you add to the distance depends on speed, accuracy, etc. To be honest, I find it impossible to find 
        // the perfect balance. Faster GPUs give you more options, because more shadow iterations always produce better results.
        // Anyway, here's some posibilities. Which one you use, depends on the situation:
        // +=max(h, 0.001), +=clamp( h, 0.01, 0.25 ), +=min( h, 0.1 ), +=stepDist, +=min(h, stepDist*2.), etc.
        
        // In this particular instance the light source is a long way away. However, we're only taking a few small steps
        // toward the light and checking whether anything "locally" gets in the way. If a part of the scene a long distance away
        // is between our hit point and the light source, it won't be accounted for. Technically that's not correct, but the local
        // shadows give that illusion... kind of.
        dist += clamp(h, .2, stepDist*2.);
        
        // There's some accuracy loss involved, but early exits from accumulative distance function can help.
        if (abs(h)<.001 || dist > end) break; 
    }

    // I usually add a bit to the final shade value, which lightens the shadow a bit. It's a preference thing. Really dark shadows 
    // look too brutal to me.
    return min(max(shade, 0.) + .1, 1.); 
}





// Ambient occlusion, for that self shadowed look. Based on the original by XT95. I love this 
// function and have been looking for an excuse to use it. For a better version, and usage, 
// refer to XT95's examples below:
//
// Hemispherical SDF AO - https://www.shadertoy.com/view/4sdGWN
// Alien Cocoons - https://www.shadertoy.com/view/MsdGz2
float calculateAO( in vec3 p, in vec3 n, float maxDist )
{
	float ao = 0., l;
	const float nbIte = 6.;
	//const float falloff = .9;
    for(float i=1.; i< nbIte+.5; i++){
    
        l = (i + hash(i))*.5/nbIte*maxDist;
        
        ao += (l - map( p + n*l))/(1. + l);// / pow(1.+l, falloff);
    }
	
    return clamp(1. - ao/nbIte, 0., 1.);
}

// More concise, self contained version of IQ's original 3D noise function.
float noise3D(in vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
	const vec3 s = vec3(7, 157, 113);
	
	vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	p -= ip; // Cell's fractional component.
	
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
	
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
	
}

// Simple fBm to produce some clouds.
float fbm(in vec3 p){
    
    // Four layers of 3D noise.
    return .5333*noise3D(p) + .2667*noise3D(p*2.02) + .1333*noise3D(p*4.03) + .0667*noise3D(p*8.03);

}


// Pretty standard way to make a sky. 
vec3 getSky(in vec3 ro, in vec3 rd, vec3 sunDir){

	
	float sun = max(dot(rd, sunDir), 0.); // Sun strength.
	float horiz = pow(1.0-max(rd.y, 0.), 3.)*.35; // Horizon strength.
	
	// The blueish sky color. Tinging the sky redish around the sun. 		
	vec3 col = mix(vec3(.25, .35, .5), vec3(.4, .375, .35), sun*.75);//.zyx;
    // Mixing in the sun color near the horizon.
	col = mix(col, vec3(1, .9, .7), horiz);
    
    // Sun. I can thank IQ for this tidbit. Producing the sun with three
    // layers, rather than just the one. Much better.
	col += .25*vec3(1, .7, .4)*pow(sun, 5.);
	col += .25*vec3(1, .8, .6)*pow(sun, 64.);
	col += .2*vec3(1, .9, .7)*max(pow(sun, 512.), .3);
    
    // Add a touch of speckle, to match up with the slightly speckly ground.
    col = clamp(col + hash(rd)*.05 - .025, 0., 1.);
	
	// Clouds. Render some 3D clouds far off in the distance. I've made them sparse and wispy,
    // since we're in the desert, and all that.
	vec3 sc = ro + rd*FAR*100.; sc.y *= 3.;
    
    // Mix the sky with the clouds, whilst fading out a little toward the horizon (The rd.y bit).
	return mix( col, vec3(1, .95, 1), .5*smoothstep(.5, 1., fbm(.001*sc)) * clamp(rd.y*4., 0., 1.) );
	

}

// Cool curve function, by Shadertoy user, Nimitz.
//
// It gives you a scalar curvature value for an object's signed distance function, which 
// is pretty handy for all kinds of things. Here's it's used to darken the crevices.
//
// From an intuitive sense, the function returns a weighted difference between a surface 
// value and some surrounding values - arranged in a simplex tetrahedral fashion for minimal
// calculations, I'm assuming. Almost common sense... almost. :)
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
float curve(in vec3 p){

    const float eps = .05, amp = 4., ampInit = .5;

    vec2 e = vec2(-1, 1)*eps; // 0.05->3.5 - 0.04->5.5 - 0.03->10.->0.1->1.
    
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    
    return clamp((t1 + t2 + t3 + t4 - 4.*map(p))*amp + ampInit, 0., 1.);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

	
	// Screen coordinates.
	vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lookAt = vec3(0, 0, iTime*8.);  // "Look At" position.
	vec3 ro = lookAt + vec3(0, 0, -.25); // Camera position, doubling as the ray origin.
 
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera and "look at" vectors down the tunnel. The "path" function is 
	// synchronized with the distance function.
	lookAt.xy += path(lookAt.z);
	ro.xy += path(ro.z);

    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159/3.; // FOV - Field of view.
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0, -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    vec3 rd = normalize(forward + FOV*u.x*right + FOV*u.y*up);
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy = rot2( path(lookAt.z).x/64. )*rd.xy;
    
    
	
    // Usually, you'd just make this a unit directional light, and be done with it, but I
    // like some of the angular subtleties of point lights, so this is a point light a
    // long distance away. Fake, and probably not advisable, but no one will notice.
    vec3 lp = vec3(FAR*.5, FAR, FAR) + vec3(0, 0, ro.z);
 

	// Raymarching, using Nimitz's "Log Bisection" method. Very handy on stubborn surfaces. :)
	float t = logBisectTrace(ro, rd);
    
    // Standard sky routine. Worth learning. For outdoor scenes, you render the sky, then the
    // terrain, then mix together with a fog falloff. Pretty straight forward.
    vec3 sky = getSky(ro, rd, normalize(lp - ro));
    
    // The terrain color. Can't remember why I set it to sky. I'm sure I had my reasons.
    vec3 col = sky;
    
    // If we've hit the ground, color it up.
    if (t < FAR){
    
        vec3 sp = ro+t*rd; // Surface point.
        vec3 sn = normal(sp); // Surface normal.

        
        // Light direction vector. From the sun to the surface point. We're not performing
        // light distance attenuation, since it'll probably have minimal effect.
        vec3 ld = lp-sp;
        ld /= max(length(ld), 0.001); // Normalize the light direct vector.

        
        // Texture scale factor.        
        const float tSize1 = 1./6.;
        
        // Bump mapping with the sandstone texture to provide a bit of gritty detailing.
        // This might seem counter intuitive, but I've turned off mip mapping and set the
        // texture to linear, in order to give some grainyness. I'm dividing the bump
        // factor by the distance to smooth it out a little. Mip mapped textures without
        // anisotropy look too smooth at certain viewing angles.
        sn = doBumpMap(iChannel1, sp*tSize1, sn, .007/(1. + t/FAR));//max(1.-length(fwidth(sn)), .001)*hash(sp)/(1.+t/FAR)
        
        float shd = softShadow(sp, ld, .05, FAR, 8.); // Shadows.
        float curv = curve(sp)*.9 +.1; // Surface curvature.
        float ao = calculateAO(sp, sn, 4.); // Ambient occlusion.
        
        float dif = max( dot( ld, sn ), 0.); // Diffuse term.
        float spe = pow(max( dot( reflect(-ld, sn), -rd ), 0. ), 5.); // Specular term.
        float fre = clamp(1.0 + dot(rd, sn), 0., 1.); // Fresnel reflection term.

       

        // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float fre2 = mix(.2, 1., Schlick);  //F0 = .2 - Hard clay... or close enough.
       
        // Overal global ambience. Without it, the cave sections would be pretty dark. It's made up,
        // but I figured a little reflectance would be in amongst it... Sounds good, anyway. :)
        float amb = fre*fre2 + .06*ao;
        
        // Coloring the soil - based on depth. Based on a line from Dave Hoskins's "Skin Peeler."
        col = clamp(mix(vec3(.8, .5, .3), vec3(.5, .25, .125),(sp.y+1.)*.15), vec3(.5, .25, .125), vec3(1));
        
        // Give the soil a bit of a sandstone texture. This line's made up.
        col =  smoothstep(-.5, 1., tex3D(iChannel1, sp*tSize1, sn))*(col + .25);
        // One thing I really miss when using Shadertoy is anisotropic filtering, which makes mapped 
        // textures appear far more crisp. It requires just a few lines in the backend code, and doesn't 
        // appear to effect frame rate, but I'm assuming the developers have their reasons. Anyway, this
        // line attempts to put a little definition back in, but it's definitely not the same thing. :)     
        col = clamp(col + noise3D(sp*48.)*.3 - .15, 0., 1.);
        
        // Edit: This shader needs gamma correction, so I've hacked this and a postprocessing line
        // in to counter the dark shading... I'll do it properly later.
        col = pow(col, vec3(1.5));
        
        // Tweaking the curvature value a bit, then using it to color in the crevices with a 
        // brownish color... in a lame attempt to make the surface look dirt-like.
        curv = smoothstep(0., .7, curv);
        col *= vec3(curv, curv*.95, curv*.85);
 
        
        // A bit of sky reflection. Not really accurate, but I've been using fake physics since the 90s. :)
        col += getSky(sp, reflect(rd, sn), ld)*fre*fre2*.5;
        
        
        // Combining all the terms from above. Some diffuse, some specular - both of which are
        // shadowed and occluded - plus some global ambience. Not entirely correct, but it's
        // good enough for the purposes of this demonstation.        
        col = (col*(dif + .1) + fre2*spe)*shd*ao + amb*col;
       
        
    }
    
    
    // Combine the terrain with the sky using some distance fog. This one is designed to fade off very
    // quickly a few units out from the horizon. Account for the clouds, change "FAR - 15." to zero, and 
    // the fog will be way more prominent. You could also use "1./(1 + t*scale)," etc.
    col = mix(col, sky, sqrt(smoothstep(FAR - 15., FAR, t)));
    

    // Edit: This shader needs gamma correction, so I've hacked this and a line above in
    // to counter the dark shading... I'll do it properly later.
    col = pow(max(col, 0.), vec3(.75));

    
    // Standard way to do a square vignette. Note that the maxium value value occurs at "pow(0.5, 4.) = 1./16," 
    // so you multiply by 16 to give it a zero to one range. This one has been toned down with a power
    // term to give it more subtlety.
    u = fragCoord/iResolution.xy;
    col *= pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .0625);

    // Done.
	fragColor = vec4(clamp(col, 0., 1.), 1);
}