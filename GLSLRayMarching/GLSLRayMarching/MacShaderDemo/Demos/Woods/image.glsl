// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

#define LIGHTRIG 1 // 0 or 1
//#define GODRAYS
//#define HIGH_QUALITY_NOISE 

//==============================================================================

float hash( vec2 n )
{
    return fract(sin(dot(n,vec2(1.0,113.0)))*13.5453123);
}

vec3 hash3( float n )
{
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(13.5453123,31.1459123,37.3490423));
}

vec2 hash2( vec2 x )
{
	float n = dot(x,vec2(1.0,113.00));
    return fract(sin(vec2(n,n+1.0))*vec2(13.5453123,31.1459123));
}


#ifndef HIGH_QUALITY_NOISE 
float noise( in vec2 x )
{
	//return texture( iChannel0, (x+0.5)/256.0 ).x;

	vec2 p = floor(x);
    vec2 f = fract(x);

	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);

	return textureLod( iChannel0, (uv+0.5)/256.0, -0.0 ).x;
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+0.5)/256.0, 0.0 ).yx;
	
	return mix( rg.x, rg.y, f.z );
}
#else
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

	f =  f*f*(3.0-2.0*f);

	float a = textureLod( iChannel0, (p+vec2(0.5,0.5))/256.0, 0.0 ).x;
	float b = textureLod( iChannel0, (p+vec2(1.5,0.5))/256.0, 0.0 ).x;
	float c = textureLod( iChannel0, (p+vec2(0.5,1.5))/256.0, 0.0 ).x;
	float d = textureLod( iChannel0, (p+vec2(1.5,1.5))/256.0, 0.0 ).x;

	return mix( mix( a, b, f.x ), mix( c, d, f.x ), f.y );

}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z);
	vec2 rga = textureLod( iChannel0, (uv+vec2(0.5,0.5))/256.0, 0.0 ).yx;
	vec2 rgb = textureLod( iChannel0, (uv+vec2(1.5,0.5))/256.0, 0.0 ).yx;
	vec2 rgc = textureLod( iChannel0, (uv+vec2(0.5,1.5))/256.0, 0.0 ).yx;
	vec2 rgd = textureLod( iChannel0, (uv+vec2(1.5,1.5))/256.0, 0.0 ).yx;
	
	vec2 rg = mix( mix( rga, rgb, f.x ),
				   mix( rgc, rgd, f.x ), f.y );
	
	return mix( rg.x, rg.y, f.z );
}
#endif

float fbm( in vec3 p )
{
    return 0.5000*noise(p*1.0)+
           0.2500*noise(p*2.0)+
           0.1250*noise(p*4.0)+
           0.0625*noise(p*8.0);
}

float fbm( in vec2 p )
{
    return 0.5000*noise(p*1.0)+
           0.2500*noise(p*2.0)+
           0.1250*noise(p*4.0)+
           0.0625*noise(p*8.0);
}

vec3 texturize( sampler2D sa, vec3 p, vec3 n )
{
	vec3 x = texture( sa, p.yz ).xyz;
	vec3 y = texture( sa, p.zx ).xyz;
	vec3 z = texture( sa, p.xy.yx ).xyz;

	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

#define ZERO (min(iFrame,0))

//==============================================================================

float treeBase( vec2 pos )
{
	float chsca = 0.2;
	vec2 chos = fract(chsca*pos) - 0.5;
	return length( chos );
}	

float terrain( vec2 pos )
{
	float h = 12.0*fbm( pos*0.1 );
	
	float r = treeBase( pos );
	r = max(0.0,r-0.1);
	float ar = 1.0*exp( -50.0*r*r );
	
	return h + ar;
}

vec2 grassDistr( in vec2 pos )
{
	float f = fbm( pos );
    return vec2( smoothstep( 0.45, 0.55, f ), smoothstep(0.4, 0.75, f) );
}

float mushroomAnim( float t )
{
    float f = sin( 0.5*t );		
	
	f = -1.0 + 2.0*smoothstep( 0.45, 0.55, 0.5 + 0.5*f );
	
	return 1.0 + 0.1*f;
}
	
float map( in vec3 pos, out vec4 suvw, out float info )
{
    float dis;
	
	//-----------------------------
	// terrain
	float h = terrain( pos.xz );
	float mindist = pos.y - h;

	float t = treeBase( pos.xz );
	float treeOcc = clamp(max(0.0,t-0.15)*3.0,0.0,1.0);
	suvw = vec4( 0.0, 0.0, 0.0, treeOcc );

	// grass
	vec2 gd = grassDistr(pos.xz);
	float hi = 1.0*clamp( 2.0*textureLod( iChannel0, pos.xz, 0.0 ).x, 0.0, 1.0 );
	float g = 0.2*hi * (gd.x * gd.y);
    mindist -= g;


	// mushroom position	
	float mushSca = 2.0;
	vec2  mushWPos = (0.5+floor(mushSca*pos.xz))/mushSca;
	vec3  mushPos = vec3( fract(mushSca*pos.x)-0.5, mushSca*(pos.y-h), fract(mushSca*pos.z)-0.5 );
    float mushID  = hash( floor(mushSca*pos.xz) );
	float mushToTree = treeBase(mushWPos);
	
	float sh = 0.2 * (0.5 + 1.0*mushID);
	
	suvw.w *= mix( 0.33 + 0.67*clamp( (length( mushPos.xz )-sh)*5.0, 0.0, 1.0 ), 1.0, 1.0*smoothstep( 0.35, 0.45, mushToTree + 0.5*(gd.x * gd.y) ) );
	suvw.w *= mix( smoothstep( 0.5, 1.0, hi ), 1.0, 1.0-gd.x );
	suvw.w *= 0.2 + 0.8*clamp( 2.0*abs(gd.x-0.5), 0.0, 1.0 );
	
	//-----------------------------
	// trees
	{
	float chsca = 0.2;
	vec3 chos = vec3( fract(chsca*pos.x)-0.5, chsca*(pos.y-h), fract(chsca*pos.z)-0.5 );
	float y = chos.y;
	float r = length( chos.xz );
		
	float ss = exp(-40.0*y*y);
	float dd = fbm( pos*vec3(1.0,0.1,1.0)*2.0 );
	float sh = 0.08 + (0.1+0.25*ss)*dd;
		
    dis = (r - sh)/chsca;
	if( dis<mindist )
	{
		mindist = dis;
		suvw.x = 1.0;
		suvw.y = y;
		suvw.z = smoothstep( 0.0, 1.0, dd );
		suvw.w = smoothstep( 0.0, 1.0, dd*1.4 ) * clamp(0.3+y*1.5, 0.0, 1.0);
		info = atan( chos.x, chos.z );
	}		
		
	}
	
	//-----------------------------
	// mushrooms
	if( mushToTree < 0.4)
	{
    float an = mushroomAnim( iTime*(1.0+mushID) + 6.28*mushID );		

	float y = mushPos.y - 0.2 * 0.5;
	float r = length( vec3(mushPos.xz,y*2.0) );
	float sh = 0.2 * (0.5 + 1.0*mushID);
    sh *= an;		
    dis = (r - sh)/mushSca;
	if( dis<mindist )
	{
		mindist = dis;
		suvw.x = 2.0;
		suvw.y = mushID;
		suvw.z = mushPos.x / an;
		suvw.w = clamp( 0.5 + 0.5*y/.1, 0.0, 1.0 ) * treeOcc;
		info = mushPos.z / an;
	}		
		
	}


	
    return mindist * 0.5;
}


float map2( in vec3 pos )
{
    float dis;
	
	//-----------------------------
	// terrain
	float h = terrain( pos.xz );
	float mindist = pos.y - h;

	// grass
	vec2 gd = grassDistr(pos.xz);
	float g = 0.2*(gd.x * gd.y);
    mindist -= g;


	// mushroom position	
	float rockSca = 2.0;
	vec2  rockWPos = (0.5+floor(rockSca*pos.xz))/rockSca;
	vec3  rockPos = vec3( fract(rockSca*pos.x)-0.5, rockSca*(pos.y-h), fract(rockSca*pos.z)-0.5 );
    float  rockID  = hash( floor(rockSca*pos.xz) );
	float rockToTree = treeBase(rockWPos);
	
	float sh = 0.2 * (0.5 + 1.0*rockID);
	
	
	//-----------------------------
	// trees
	{
	float chsca = 0.2;
	vec3 chos = vec3( fract(chsca*pos.x)-0.5, chsca*(pos.y-h), fract(chsca*pos.z)-0.5 );
	float y = chos.y;
	float r = length( chos.xz );
		
	float ss = exp(-40.0*y*y);
	float dd = fbm( pos*vec3(1.0,0.1,1.0)*2.0 );
	float sh = 0.08 + (0.1+0.25*ss)*dd;
		
    dis = (r - sh)/chsca;
	mindist = min( dis, mindist );
		
	}
	
	//-----------------------------
	// mushrooms
	if( rockToTree < 0.4)
	{
	float y = rockPos.y - 0.2 * 0.5;
	float r = length( vec3(rockPos.xz,y*2.0) );
	float sh = 0.2 * (0.5 + 1.0*rockID);
    sh *= mushroomAnim( iTime*(1.0+rockID) + 6.28*rockID );
    dis = (r - sh)/rockSca;
	mindist = min( dis, mindist );
		
	}


	
    return mindist;
}


vec3 calcNormal( in vec3 pos )
{
    vec4 kk;
	float kk2;
#if 0    
    float eps = 0.01;
	float ref = map(pos,kk,kk2);
	vec3 nor = vec3( map( vec3(pos.x+eps, pos.y, pos.z), kk, kk2 ) - ref,
                     map( vec3(pos.x, pos.y+eps, pos.z), kk, kk2 ) - ref,
                     map( vec3(pos.x, pos.y, pos.z+eps), kk, kk2 ) - ref );
	return normalize( nor );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*0.01,kk,kk2);
    }
    return normalize(n);
#endif    
    
    
}

float intersect( in vec3 ro, in vec3 rd, out vec4 suvw, out float info )
{
    const float maxd = 50.0;
	float precis = 0.01;
    float h = 1.0;
    float t = 0.0;
    suvw = vec4(0.0);
	info = 0.0;
    for( int i=0; i<128; i++ )
    {
        if( h<precis||t>maxd ) break;
	    h  = map( ro+rd*t, suvw, info );
        t += h*min(0.25+0.15*t,1.0);
    }

	if( t>maxd ) { t=-1.0; suvw=vec4(512.0); }
    return t;
}


float softshadow( in vec3 ro, in vec3 rd, float k, float l )
{
    float res = 1.0;
    float t = 0.1;
	vec4 kk;
	float kk2;
	float h = 1.0;

	for( int i=0; i<38; i++ )
    {
		h = map2( ro + rd*t );
		h = max( h, 0.0 );
        res = min( res, k*h/t );
		t += clamp( h, 0.001, 0.3 );
		if( h<0.0001 ) break;
    }
	
#ifdef GODRAYS
    // fake leaves shadow	
	vec3 pp = ro - rd*dot(rd,ro);
	res *= mix( 1.0, smoothstep( 0.3, 0.5, texture(iChannel2,2.0*pp.zx).x ), 0.5+0.5*l );
#endif	
    return clamp(res,0.0,1.0);
}

vec4 lpos[7];


vec3 shade( in vec3 pos, in vec3 nor, in vec3 rd, float matID, in vec3 uvw, in float info, in vec3 sunDirection )
{
	
    vec3 rgb = vec3(0.0);
	
    // ground
    if( matID<0.5 )
    {
		float f = grassDistr( pos.xz ).x;
			
		float rs = 1.5;
		vec3 stones = texture(iChannel3,rs*pos.xz).xyz;
		vec3 nnoise = texture( iChannel1, pos.xz*0.5 ).xyz;

        // dirt
 		vec3 ground = vec3(0.04,0.03,0.01);
		ground *= 0.33 + 1.25*nnoise.x;
		ground = mix( ground, ground+0.02, smoothstep( 0.2, 0.5, stones.x ) );

		// frass
		vec3 grass = vec3(0.1,0.1,0.0);
        // color variation		
		grass += 0.015*sin( nnoise.x*10.0 + vec3(0.0,1.0,2.0) );
        // flowers		
		float fl = smoothstep( 0.5, 0.6, texture(iChannel3,10.0*pos.xz).z ) ;
		fl *= smoothstep( 0.3, 0.35, nnoise.z );
		grass = mix( grass, vec3(0.4,0.3,0.1), fl );
		
		rgb = mix( ground, grass, f );
		
		rgb *= 0.3 + 0.7*texture( iChannel2, pos.xz*2.0 ).x;
		
        //bump		
		nor.x -= (1.0-f)*1.0*(smoothstep( 0.2, 0.5, texture(iChannel3,rs*pos.xz+vec2(0.05,0.0)).x) - smoothstep( 0.2, 0.5, texture(iChannel3,rs*pos.xz-vec2(0.05,0.0)).x));
		nor.z -= (1.0-f)*1.0*(smoothstep( 0.2, 0.5, texture(iChannel3,rs*pos.xz+vec2(0.0,0.05)).x) - smoothstep( 0.2, 0.5, texture(iChannel3,rs*pos.xz-vec2(0.0,0.05)).x));
		nor = normalize( nor );
    }
	// trees
    else if( matID<1.5 )
    {
        rgb = vec3(0.35,0.1,0.0);
		
		rgb = mix( rgb*0.15, vec3(0.2,0.12,0.03), smoothstep( 0.0, 1.0, uvw.y ) );
		
		float tt = texturize( iChannel1, 1.5*pos*vec3(1.0,0.5,1.0), nor ).x;
		rgb *= 0.2+1.5*tt;
		
		tt = texturize( iChannel1, 0.03*pos, nor ).x;
		
		float ff = texturize( iChannel1, 1.5*pos, nor ).x;
		float green = (1.0-smoothstep(0.0, 0.5, uvw.x*4.0 - tt + 0.1));
		rgb = mix( rgb, 2.4*vec3(0.045,0.05,0.00)*ff, 0.8*green );
		
		// bump
		vec2 cuv = vec2( uvw.x*3.0, info );
		float bu = 0.0;
		bu = 0.5 + 0.25*green;
		nor = normalize( nor + bu * (-1.0 + 2.0*texture( iChannel0, cuv ).xyz) );
	}   
    // mushrooms
    else if( matID<2.5 )
    {
        // base color		
		vec3 tcol = mix( vec3(0.1,0.01,0.00), vec3(0.14,0.04,0.0), pow( clamp(1.0+dot(rd,nor),0.0,1.0), 2.0 ) );
		
        // color variation		
		tcol += 0.03*sin( uvw.x*10.0 + vec3(0.0,1.0,2.0) );
		
		// white
        vec2 uv = vec2(uvw.y,info);
		vec2 iuv = floor(uv*9.0);
		vec2 fuv = fract(uv*9.0 );
		uv = fuv - 0.5 + 0.25*(-1.0+2.0*hash2( iuv ));
		uv *= 0.5 + 0.5*hash( iuv );
		float f = 1.0 - smoothstep( 0.1, 0.3, length( uv ) );
		f *= smoothstep( 0.3, 0.31, hash( iuv.yx*1.3 ) );
		f *= smoothstep( 0.4, 0.5, nor.y );
		rgb = mix( tcol, vec3(0.23,0.21,0.19), f );


		//float an = clamp(0.5 + 0.5*(mushroomAnim( iTime*(1.0+uvw.x) + 6.28*uvw.x )-1.0)/0.1,0.0,1.0);
        //rgb *= 0.25 + 2.5*an*vec3(1.0,0.7,0.5);
		
		rgb *= 0.9;
	}
	
	// lighting terms
	float occ = uvw.z;
	float sha = softshadow( pos, sunDirection, 64.0, 0.0 );
    float sun = clamp( dot( nor, sunDirection ), 0.0, 1.0 );
    float sky = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );
    float ind = clamp( dot( nor, normalize(sunDirection*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );
	float fre = pow( clamp( 1.0+dot(nor,rd), 0.0, 1.0 ), 5.0 );
	
	float spe = pow( clamp( dot( reflect( rd, nor ), sunDirection ), 0.0, 1.0 ), 16.0 );
	
    // compute lighting
    vec3 lin  = 3.5*sun*vec3(1.75,1.30,1.00)*pow(vec3(sha),vec3(1.0,1.2,1.5));
         lin += 2.5*sky*vec3(0.82,0.75,0.50)*occ;
         lin += 1.1*ind*vec3(0.30,0.35,0.25)*occ;
         lin += 6.0*spe*sha*(0.5+0.5*fre);
         lin *= 1.0 + 1.0*fre*occ*vec3(1.5,1.0,0.5);
    for( int i=0; i<7; i++ )
    {
        vec3 lig = lpos[i].xyz - pos;
        float llig = dot(lig,lig);
        float im = inversesqrt( llig );
        lig = lig * im;
		lin += vec3(1.0,0.5,0.2)*1.5*lpos[i].w * clamp(dot(lig,nor),0.0,1.0)*im*im*occ;
	}
			
	return rgb * lin * 1.3;
}


void moveLights( void )
{

    for( int i=0; i<7; i++ )
	{
		vec3 pos;
	    pos.x = 3.2*cos(0.0+0.08*iTime*2.0 + 17.0*float(i) );
	    pos.z = 3.2*cos(1.65+0.07*iTime*2.0 + 13.0*float(i) );
	    pos.y = terrain( pos.xz ) + 0.4;
		
		// make the lights avoid the trees
	    vec2 chos = 2.5 + 5.0*floor( pos.xz/5.0);
	    float r = length( pos.xz - chos);
	    pos.xz = chos + max( r, 1.5 )*normalize(pos.xz-chos);
		
		lpos[i].xyz = pos;
		lpos[i].w = smoothstep(5.0,10.0,iTime)*(0.85 + 0.15*sin(25.0*iTime+ 23.1*float(i)));
	}
}

float doFirefly( in vec3 ro, in vec3 rd, in float t, in vec3 lpo, in float ra )
{
	float h = 0.0;
	vec3 lv = ro - lpo;
	float ll = dot(lv,lv);
    if( ll < (t*t) ) // depth comparison
    {
		float b = dot(rd,lv);
		float c = ll - ra;
		h = max(b*b-c,0.0)/ra;
        h = h*h*h*h;
    }
	return h;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    
	p.y *= iResolution.y/iResolution.x;

    vec2 m = vec2(0.5); if( iMouse.z>0.0 ) m = iMouse.xy/iResolution.xy;

    // animate	
	moveLights();
		
    // camera
	float an = 7.5 + 0.0*0.2*sin(0.05*(iTime-10.0)) - m.x*3.0;

    vec3  ro = vec3( 5.0*sin(an), 0.0, 5.0*cos(an));
    vec3  ta = vec3( 0.0, 8.5, 0.0 );
	ro.y = terrain( ro.xz ) + max( 0.25, 1.0 - 2.0*(m.y-0.5) );
	//ro.y = 8.3;
	ta.y = terrain( ta.xz ) - 0.0;
	
    vec3  ww = normalize( ta - ro );
    vec3  uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3  vv = normalize( cross(uu,ww));
    vec3  rd = normalize( p.x*uu + p.y*vv + 1.11*ww );

	vec3 col = vec3(0.0);

    // ray march scene
	vec4 suvw;
	float info;
	float t = intersect( ro, rd, suvw, info );

    #if LIGHTRIG==0
	vec3 sunDirection = normalize( vec3(-0.1,0.5,-0.6) );
	#else
	vec3 sunDirection = normalize( vec3(0.4,0.4,-0.05) );
    #endif

	if( t>0.0 )
	{
	    vec3 pos = ro + t*rd;
	    vec3 nor = calcNormal( pos );

        #if LIGHTRIG==0
		col = shade( pos, nor, rd, suvw.x, suvw.yzw, info, sunDirection );
		#else
  	    // super trick
        vec3 sunDirectionA = normalize( vec3(0.54,0.1,0.0) );
		vec3 fakeSunDirection = normalize( mix(sunDirection,sunDirectionA,smoothstep(2.0,4.0,t)));
		col = shade( pos, nor, rd, suvw.x, suvw.yzw, info, fakeSunDirection );
        #endif

	}
    else
	{
		t = 1e10;
	}		

    // fog	
    col = mix( col, vec3(0.20,0.15,0.05), 1.0 - exp(-0.0007*t*t) );

    // godrays (only Linux)	
	#ifdef GODRAYS
	float v = 0.0;
	float s = 0.5 + 0.15*texture(iChannel0, fragCoord.xy/iChannelResolution[0].xy ).x;
	for( int i=ZERO; i<32; i++ )
    {
		if( s>t ) continue;
		vec3 pos = ro + rd*s;
		float h = softshadow( pos, sunDirection, 32.0, 1.0 );
		v += h * exp(-0.2*s);
		s += 0.15;
	}
	v /= 32.0;
	#if LIGHTRIG==1
	float vm = 2.0;
	#else
	float vm = 1.0;
	#endif
    col += vm*v*v*vec3(1.0,0.75,0.4);
    #endif	
		
	
	
	
	// iluminating fireflies
	for( int i=0; i<7; i++ )
	{
		col += 3.0*vec3(1.0,0.3,0.05)*lpos[i].w*doFirefly( ro, rd, t, lpos[i].xyz, 0.05 );
    }

	// non iluminating fireflies	
	for( int i=0; i<32; i++ )
	{
		vec3 rrr = 1.5*sin( hash3(float(i)) + float(i)*vec3(1.2,1.1,1.7) + vec3(0.0,1.0,2.0) + 0.01*iTime);
		float br = 0.5 + 0.5*sin(2.0*iTime+ 23.1*float(i));
		
		col += vec3(1.0,0.7,0.3)*br*doFirefly( ro, rd, t, rrr.xyz*vec3(1.5,1.0,1.5) + vec3(0.0,10.0,2.0), 0.0017 );
		col += vec3(1.0,0.7,0.3)*br*doFirefly( ro, rd, t, rrr.yzx*vec3(1.5,1.0,1.5) + vec3(0.0,10.0,2.0), 0.0017 );
		col += vec3(1.0,0.7,0.3)*br*doFirefly( ro, rd, t, rrr.zxy*vec3(1.5,1.0,1.5) + vec3(0.0,10.0,2.0), 0.0017 );
	}

	// gamma
	col = pow( clamp( col, 0.0, 1.0 ), vec3(0.45) );

    // contrast	
    col = col*0.7 + 0.3*col*col*(3.0-2.0*col); 
	
    // blue color balance darks	
	col = mix( col, vec3(0.0,0.0,1.0)*dot(col,vec3(0.33)), 0.25*pow( 1.0-dot(col,vec3(0.33)), 8.0 ) );
	
	// vigneting
	col *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    // fade	
	col *= smoothstep( 0.0, 3.0, iTime );

	fragColor = vec4( col, 1.0 );
}