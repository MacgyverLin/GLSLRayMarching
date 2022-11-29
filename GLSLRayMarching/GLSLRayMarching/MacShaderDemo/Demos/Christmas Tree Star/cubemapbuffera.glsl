// Make a diffuse convolution of the LDRtoHDR of the cube map
// This is not an efficient approach - it's based on code I use for Monte Carlo rendering - but it converges to the right solution pretty quickly

// quasi random numbers from: http://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
const uvec2 quasi2 = uvec2(3242174889u,2447445413u);

// input rand = 2 floats in range [0,1)
vec3 SphereRand( vec2 rand )
{
    float sina = rand.x*2. - 1.;
    float b = 6.283*rand.y;
    float cosa = sqrt(1.-sina*sina);
    return vec3(cosa*cos(b),sina,cosa*sin(b));
}

vec3 PowRand( vec2 rand, vec3 axis, float fpow )
{
    vec3 r = SphereRand(rand);
    
    // redistribute samples
    float d = dot(r,axis);

    // map sphere to cylinder
    r -= d*axis;
    r = normalize(r); // hahaha! I'd forgotten this, very clever

    // project onto a spike
    // h = pow(1.-radius,m)*2-1
    // radius = 1.-pow(h*.5+.5,1/m)
    // ^ WRONG! That's radius squared, otherwise POW=1 gives a spike
    float h = d*.5+.5;
    //        r *= sqrt(1.-pow(h,1./POW));
    // ^ wrong again! Need to solve the integral with that sqrt in,
    // and needed a factor of /radius for sample density
    r *= sqrt( 1. - pow( h, 2./(fpow+1.) ) ); // YES!!!!

    // and down onto the hemisphere
    r += axis*sqrt(1.-dot(r,r));

    return r;
}

vec3 HemisphereRand( vec3 axis, uint seed )
{
    return PowRand( vec2(quasi2*seed)/exp2(32.), axis, 1. );
}

void mainCubemap( out vec4 fragColour, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    fragColour = textureLod( iChannel0, rayDir, 0. ); // this needs NEAREST filter on the texture
	if ( iFrame == 0 ) fragColour = vec4(0);

    // wait for texture to load (I know the top of the cubemap should not be black)
    if ( textureLod( iChannel1, vec3(0,1,0), 0. ).r == 0. ) return;
    
    // early-out once we've got a good enough result
    if ( fragColour.a > 16.*60.*3. ) return;
    
    const int n = 16;
    for ( int i = 0; i < n; i++ )
    {
        vec3 ray = HemisphereRand(rayDir,uint(i+n*iFrame));

        fragColour.rgb += LDRtoHDR(textureLod( iChannel1, ray, 0. ).rgb);
        fragColour.a += 1.;
    }
}