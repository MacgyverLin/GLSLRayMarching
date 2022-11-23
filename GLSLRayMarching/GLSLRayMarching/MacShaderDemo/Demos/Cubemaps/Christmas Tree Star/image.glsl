// Christmas Tree Star
// by Hazel Quantock 2019
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. http://creativecommons.org/licenses/by-nc-sa/4.0/


// reduce this to improve frame rate in windowed mode
#define AA_QUALITY .5

// allow a little bleed between pixels - I think this looks more photographic, but blurrier
#define AA_ROUND true
#define AA_ROUND_RADIUS 0.7071


// very silly effect, but it kinda shows some of how the branch and bauble placement works
//#define PATTERN_SCROLL vec3(0,.3,0)
#define PATTERN_SCROLL vec3(0)

// uncomment this to fill space with christmas tree stars!
//#define CLONES 1


//--

// hashes from https://www.shadertoy.com/view/4dVBzz
#define M1 1597334677U     //1719413*929
#define M2 3812015801U     //140473*2467*11
#define M3 3299493293U     //467549*7057

#define F0 exp2(-32.)
//(1.0/float(0xffffffffU))

#define hash(n) n*(n^(n>>15))

#define coord1(p) (p*M1)
#define coord2(p) (p.x*M1^p.y*M2)
#define coord3(p) (p.x*M1^p.y*M2^p.z*M3)

float hash1(uint n){return float(hash(n))*F0;}
vec2 hash2(uint n){return vec2(hash(n)*uvec2(0x1U,0x3fffU))*F0;}
vec3 hash3(uint n){return vec3(hash(n)*uvec3(0x1U,0x1ffU,0x3ffffU))*F0;}
vec4 hash4(uint n){return vec4(hash(n)*uvec4(0x1U,0x7fU,0x3fffU,0x1fffffU))*F0;}


float TreeBoundsSDF( vec3 pos )
{
    // just a cone
    float r = length(pos.xz);
    return max(//max(
        dot( vec2(pos.y-7.,r), normalize(vec2(.3,1)) ),
        //pos.y-7.), // something goes wrong with the cone SDF?
        -pos.y+1.8+r*.6
        );
}


/*
Warp space into a series of repeated cells ("branches") around the y axis
This causes some distortion, causing marching errors near the axis when branches are
particularly sparse. But this can be worked round by tweaking the SDF.

Cells are mirrored so whatever's placed in them will tile with itself!

yByOutStep - tilts branches along the axis, but breaks vertical tiling.
*/
vec3 HelixGrid( out ivec2 grid, vec3 pos, int numSpokes, float yStepPerRotation, float yByOutStep )
{
    // convert to polar coordinates
    vec3 p = vec3(atan(pos.x,pos.z),pos.y,length(pos.xz));

    p.y -= yByOutStep*p.z;
    float l = sqrt(1.+yByOutStep*yByOutStep);
    
    // draw a grid of needles
    vec2 scale = vec2(6.283185/float(numSpokes),yStepPerRotation);
    p.xy /= scale;
    
    // rotate and skew the grid to get a spiral with nice irrational period
    float sn = 1./float(numSpokes); // so we step by an integer number of rows

    p.xy += p.yx*vec2(-1,1)*sn;

//p.x += iTime; // Fun!
    
    // make horizontal triangle-waved, so edges of cells match up no matter what's put inside them!
    grid = ivec2(floor(p.xy));
    vec2 pair = fract((p.xy + 1.)*.5)*2.-1.;
    p.xy = (abs(pair)-.5);
    vec2 flip = step(0.,pair)*2.-1.; // sign() but without a 0.
    p.xy *= scale;

    // unshear...
    p.y += flip.y*yByOutStep*p.z;
    
    // reconstruct a non-bent space
    p.xz = p.z*vec2(sin(p.x),cos(p.x));

    // ...and apply rotation to match the shear (now we've sorted out the grid stuff)
    p.yz = ( p.yz + flip.yy*p.zy*vec2(-1,1)*yByOutStep )/l; // dammit - I think it breaks the wrap
    
// might be worth returning a bound on y to mask the discontinuous area
// I think it will just be yByAngleStep/sqrt(1.+yByOutStep*yByOutStep) which caller can do if desired
// Or, could make z NOT start at 0 - so caller has to bound using parent-level's length (totally viable and I'm doing it a lot)
// so mirroring WOULD line up!
    
    return p;
}



struct TreeSpace
{
    vec3 branch;
    vec3 twig;
    vec3 needle;
    ivec2 branchGrid;
    ivec2 twigGrid;
    ivec2 needleGrid;
};


TreeSpace GetTreeSpace( in vec3 pos )
{
    TreeSpace o;
    o.branch = HelixGrid( o.branchGrid, pos, 12, .5, .5 ); //.5
    o.twig = HelixGrid( o.twigGrid, o.branch.xzy, 5, .5, 1. );
    o.needle = HelixGrid( o.needleGrid, o.twig.xzy, 9, .04, 1. );
    
    return o;
}


float TreeSDF( vec3 pos )
{
    float bounds = TreeBoundsSDF(pos);
    
    if ( bounds > 1. ) return bounds-.0;
    
    pos += PATTERN_SCROLL*iTime;
	TreeSpace ts = GetTreeSpace(pos);

	float branchRand = hash1(coord2(uvec2(ts.branchGrid+0x10000)));
    float branchEndLength = .3*(branchRand-.5);
    
    return
        min(
            max(
                min(
                    min(
                        // twig
                        length(ts.twig.xy)-.005,
                        // needle
                        length( vec3( ts.needle.xy, max(0.,ts.needle.z-.05) ) ) - .003
                    ),
                    // branch
                    max(
                    	(length(ts.branch.xy
                               + .004*sin(vec2(0,6.283/4.)+ts.branch.z*6.283/.1) // spiral wobble
                              )-.01)*.9,
                    	bounds - branchEndLength - .2 // trim branches shorter than twigs
                    )
            	),
            	// branch length (with rounded tip to clip twigs nicely)
                length( vec3(ts.branch.xy,max(0.,bounds
                                              -branchEndLength  // this seems to cause more floating twigs (or more obvious ones)
                                             )) )-.3
            ),
            max(
                // trunk
                length(pos.xz)-.03,
                bounds  // this will give a sharp point - better to just chop it - but might not show it
            )
        )*.7; // the helical distortion bends the SDF, so gradient can get higher than 1:1
}


// baubles only spawn in negative areas of this mask
float BaubleBoundsSDF( vec3 pos )
{
    return abs(TreeBoundsSDF(pos))-.3; // half the width of the area bauble centres can be placed in
}


// pass different seeds and densities to generate different sets of baubles
// if spacing = radius*2. the baubles will lie on a grid touching each other
float BaublesSDF( vec3 pos, uint seed, float spacing, float radius, float power, float twist )
{
    // avoid looping over every bauble - find closest one from a handful of candidates, using a jittered grid
    float f = BaubleBoundsSDF(pos);
    f -= radius;
    
    float margin = .1; // distance at which to start computing bauble SDFs - affects speed of marching (trial and error suggests .1 is fairly optimal)
    if ( f > margin ) return f;
    
	vec3 offset = spacing*(hash3(coord1(seed))-.5); // use a different grid for each set of baubles
    offset += PATTERN_SCROLL*iTime;
	pos += offset;

    // find closest centre point
    vec3 c = floor(pos/spacing);
    ivec3 ic = ivec3(c);
    c = (c+.5)*spacing; // centre of the grid square
    
    c += (spacing*.5 - radius /*- margin*/) * ( hash1(coord3(uvec3(ic+63356))^seed)*2. - 1. );
    
    // cull it if it's outside bounds
    if ( BaubleBoundsSDF(c-offset) > 0. ) return margin; // could do max (margin, distance to grid cell edge)
    
//    float f = length(pos-c)-radius;
    vec3 v = pos-c;
    v.xz = v.xz*cos(v.y*twist) + v.zx*vec2(1,-1)*sin(v.y*twist);
    v = abs(v)/radius;
    f = (pow(dot(v,pow(v,vec3(power-1.))),1./power)-1.)*radius;
    return min( f, margin ); // don't return values > margin otherwise we'll overshoot in next cell!
}

float Baubles1( vec3 pos ) { return BaublesSDF( pos, 0x1002U, .8, .08, 2.1, -150. ); }
float Baubles2( vec3 pos ) { return BaublesSDF( pos, 0x2037U, 1., .08, 1.2, -45. ); }
float Baubles3( vec3 pos ) { return BaublesSDF( pos, 0x3003U, .8, .08, 1.8, 50. ); }


float Ground( vec3 pos )
{
    return length(pos-vec3(0,-2,0))-2.-1.7 + .003*textureLod(iChannel2,pos.xz*5.,0.).x - .04*textureLod(iChannel2,pos.xz*.4,0.).x;
}


vec3 FoldSpace( vec3 pos )
{
#ifdef CLONES
    pos = (abs(fract(pos/60.+.25)-.5)-.25)*70.; // tile space
#endif
    
    // mirror space in an octahedron, tilted so one face points up
    vec3 k = vec3(0,sqrt(1./3.),sqrt(2./3.));
    vec3 i = vec3(k.z*sqrt(3./4.),k.y,-k.z*sqrt(1./4.)); //rotate 120 about y
    vec3 j = i*vec3(-1,1,1);
    
    // mirror on each axis
    pos = pos + i*max(0.,-dot(i,pos)*2.);
    pos = pos + j*max(0.,-dot(j,pos)*2.);
    pos = pos + k*max(0.,-dot(k,pos)*2.);

//    pos += sin(iTime*8.*vec3(.11,.13,.102))*vec3(1,0,1);

    return pos;
}

float SDF( vec3 pos )
{
	pos = FoldSpace(pos);
    
    return min(min(min(min(
        	TreeSDF(pos),
        	Baubles1(pos)),
        	Baubles2(pos)),
        	Baubles3(pos)),
        	Ground(pos));
}


// assign a material index to each of the SDFs
// return whichever one we're closest to at this point in space
int GetMat( vec3 pos )
{
    struct MatDist { int mat; float dist; };
    MatDist mats[] = MatDist[](
        	MatDist( 0, TreeSDF(pos) ),
        	MatDist( 1, Baubles1(pos) ),
        	MatDist( 2, Baubles2(pos) ),
        	MatDist( 3, Baubles3(pos) ),
        	MatDist( 4, Ground(pos) )
        );
    
    MatDist mat = mats[0];
    for ( int i=1; i < mats.length(); i++ )
    {
        if ( mats[i].dist < mat.dist ) mat = mats[i];
    }
    
    return mat.mat;
}


float epsilon = .0004; // todo: compute from t everywhere it's used (see "size of pixel"\/\/)
int loopCount = 400; // because of the early out this can actually be pretty high without costing much

float Trace( vec3 rayStart, vec3 rayDirection, float far, out int count )
{
	float t = epsilon;
    for ( int i=0; i < loopCount; i++ )
    {
        float h = SDF(rayDirection*t+rayStart);
        t += h;
        if ( t > far || h < epsilon ) // *t )
            return t;
    }
    
    return t;
}


void mainImage2( out vec4 fragColour, in vec2 fragCoord )
{
    float time = 3.-3.*cos(iTime/5.);//fract(iTime/12.)*12.;
    
    vec3 camPos = mix( vec3(2,3,-5), vec3(0,-5,-24), smoothstep(.5,6.,time) );
    vec2 a = vec2(-.05,1.35-(iTime/5.-sin(iTime/5.))*.25)+.02*sin(vec2(1,.618)*iTime/3.);
    
    if ( iMouse.z > 0. ) a += ((iMouse.xy/iResolution.xy).yx-.5)*vec2(-3,6);
    
    camPos.yz = camPos.yz*cos(a.x)+sin(a.x)*vec2(-1,1)*camPos.zy;
    camPos.zx = camPos.zx*cos(a.y)+sin(a.y)*vec2(-1,1)*camPos.xz;

	vec3 camLook = mix( vec3(0,3,0), vec3(0,1,0), smoothstep(.5,5.5,time) );

    vec3 camK = normalize(camLook-camPos);
    vec3 camI = normalize(cross(vec3(0,1,0),camK));
    vec3 camJ = cross(camK,camI);
    
    camPos -= camI*(.5+1.*smoothstep(.5,5.5,time));
    
    float zoom = 5.-3.*smoothstep(.5,5.5,time);
    vec3 ray = vec3((fragCoord-.5*iResolution.xy)/iResolution.y,zoom);
    ray = ray.x*camI + ray.y*camJ + ray.z*camK;
    ray = normalize(ray);
    
    int count = 0;
    const float far = exp2(5.5
#ifdef CLONES
                           +3.5
#endif
                          );
    float t = Trace( camPos, ray, far, count );
    
    fragColour = vec4(vec3(.05),1);
    
    if ( t < far )
    {
    	vec3 pos = camPos + t*ray;

        // size of 1 pixel
		// tan(a) = h / zoom
		// h = .5 / (resolution.y*.5)
        vec2 d = vec2(-1,1) * t / (zoom*iResolution.y);
        vec3 normal = normalize(
            	SDF(pos+d.xxx)*d.xxx +
            	SDF(pos+d.xyy)*d.xyy +
            	SDF(pos+d.yxy)*d.yxy +
            	SDF(pos+d.yyx)*d.yyx
            );

        vec3 uvw = FoldSpace(pos);

        int matIdx = GetMat(uvw);
        
        struct Material
        {
            vec3 albedo;
            vec3 subsurfaceColour;
            float metallicity;
            float roughness; // blurriness of the metallicity
        };
           
		Material mat = Material[](
            Material( vec3(0/*overridden*/), vec3(0/*overridden*/), 0., 0. ), // tree
            Material( vec3(1,.7,.5), vec3(0), .5, .7 ),
            Material( vec3(1,.4,.1), vec3(0), 1., .0 ),
            Material( vec3(1,.1,.15), vec3(0), 1., .4 ),
            Material( vec3(.9)*smoothstep(-.8,1.5,TreeBoundsSDF(uvw)), vec3(.2), .0, .05 ) // not getting enough shine on the snow so make it metallic
		)[matIdx]; // is this bad? I kind of like it!

        if ( matIdx == 3 )
        {
            // glitter bauble / snow
            normal += .4*(hash3(coord3(uvec3(pos/.002 + 65536.)))-.5);
            normal = normalize(normal);
        }
        
        vec3 refl = reflect( ray, normal );
        
        // very broad AO - just use the tree's bound SDF
        float AO = exp2(min(0.,TreeBoundsSDF(uvw)-.3)/.3);
        
		TreeSpace ts = GetTreeSpace(uvw);
        if ( matIdx == 0 )
        {
			// compute tree albedo
            
            float leafness = smoothstep(.0,.05, ts.needle.z) // // gradient along needle
                			* smoothstep(.01,.04, length(ts.branch.xy))
                			* smoothstep(.03,.06, length(uvw.xz));
            
            // blend wood to leaf colour
        	mat.albedo = mix( vec3(.05,.025,.01), vec3(0,.3,0), leafness );
            mat.subsurfaceColour = mix( vec3(0), vec3(.04,.5,0), leafness );
            
            // snow
            float snow = textureLod(iChannel2,pos.xz/.02,log2(t/iResolution.x)+13.).r;
            snow = smoothstep(.1,.5,normal.y*.1+snow-.3*(1.-AO));
            mat.albedo = mix( mat.albedo, vec3(1), snow );
            mat.subsurfaceColour = mix( mat.subsurfaceColour, vec3(.1), snow );
            
        	// and use the same things to paint the albedo trunk/branch colours
            mat.roughness = .7;
        }
            
        // fake reflection of the tree
		// I can probably afford a reflection trace - but I want to blur it based on roughness
        float SO = smoothstep(-1.,1.,(TreeBoundsSDF(uvw + refl*1.)
			                              -1.*(texture(iChannel2,refl.yz*2.,0.).r*2.-.7)*pow(1.-mat.roughness,5.)
                                      +.4)/(1.*(mat.roughness+.3))
                             );
        
        vec4 diffuseSample = texture( iChannel0, normal, 0. );
        vec3 diffuseLight = diffuseSample.rgb/diffuseSample.a;
        
        // sub surface scattering
        vec4 subsurfaceSample = texture( iChannel0, -normal, 0. );
        diffuseLight += mat.subsurfaceColour * subsurfaceSample.rgb/subsurfaceSample.a;
        
        diffuseLight *= AO;
        
		vec3 specularLight = LDRtoHDR(textureLod( iChannel1, refl, mix(4.,9.,mat.roughness) ).rgb);
        specularLight = mix( vec3(.01,.02,.0)+.0, specularLight, SO ); // blend to a rough tree colour
        
        float fresnel = pow(1.-abs(dot(ray,normal)),5.);
        
        fragColour.rgb =
            mix(
                mix ( mat.albedo, vec3(1.), mat.metallicity*(1.-mat.roughness)*fresnel ) *
                mat.albedo *
                mix(
                    diffuseLight,
                    specularLight,
                    mat.metallicity
                ),
                specularLight,
                mix( .02, 1., fresnel )*(1.-mat.roughness)
            );

        // debug colours
		//fragColour.rgb = fract( pos );
        //fragColour.rgb = normal*.5+.5;
    }
    else
    {
        fragColour.rgb = LDRtoHDR(textureLod( iChannel1, ray, 0. ).rgb);
    }
}


void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    // todo: compute numSamples dynamically
    int numSamples = max( 1, int((1920.*1080.*AA_QUALITY) / (iResolution.x*iResolution.y)) ); // I get 35fps at 1080p

    fragColour = vec4(0);
    for ( int i=0; i < numSamples; i++ )
    {
        uvec2 quasi2 = uvec2(0xC13FA9A9u,0x91E10DA5u);
        uint seed = uint(i);
        //seed += uint(iFrame*numSamples); // randomize per frame - causes shimmering
        if ( numSamples > 1 ) seed += uint(fragCoord.x)*quasi2.x+uint(fragCoord.y)*quasi2.y; // randomize per pixel - this looks bad at low sample counts (and at high counts it's less important)
        vec2 jitter = vec2( quasi2 * seed ) / exp2(32.);

        if ( AA_ROUND )
        {
            // circle of confusion slightly bigger than a pixel - should look more photographic
            jitter.x *= 6.283185;
            jitter = AA_ROUND_RADIUS*(1.-jitter.y*jitter.y)*vec2(cos(jitter.x),sin(jitter.x));
        }
        else
        {
            jitter -= .5;
        }
        
        vec4 col;
        mainImage2( col, fragCoord + jitter );
        fragColour += col;
    }
    fragColour /= float(numSamples);
    
    // exposure
    fragColour.rgb *= 1.8;
    
    fragColour.rgb = HDRtoLDR( fragColour.rgb );
}