#define AA 1   // make this 2 or even 3 if you have a really powerful GPU
#define SC (250.0)

// value noise, and its analytical derivatives
vec3 noise_derivative( in vec2 x )
{
    vec2 f = fract(x);
    vec2 u = f*f*(3.0-2.0*f);

#if 1
    // texel fetch version
    ivec2 p = ivec2(floor(x));
    float a = texelFetch( iChannel0, (p+ivec2(0,0))&255, 0 ).x;
	float b = texelFetch( iChannel0, (p+ivec2(1,0))&255, 0 ).x;
	float c = texelFetch( iChannel0, (p+ivec2(0,1))&255, 0 ).x;
	float d = texelFetch( iChannel0, (p+ivec2(1,1))&255, 0 ).x;
#else    
    // texture version    
    vec2 p = floor(x);
	float a = textureLod( iChannel0, (p+vec2(0.5,0.5))/256.0, 0.0 ).x;
	float b = textureLod( iChannel0, (p+vec2(1.5,0.5))/256.0, 0.0 ).x;
	float c = textureLod( iChannel0, (p+vec2(0.5,1.5))/256.0, 0.0 ).x;
	float d = textureLod( iChannel0, (p+vec2(1.5,1.5))/256.0, 0.0 ).x;
#endif
    
	return vec3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y, 
                6.0*f*(1.0-f)*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}

const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);

float terrainH( in vec2 x )
{
	vec2  p = x*0.003/SC;
    float a = 0.0;
    float b = 1.0;
	vec2  d = vec2(0.0);
    for( int i=0; i<16; i++ )
    {
        vec3 n = noise_derivative(p);
        d += n.yz;
        a += b * n.x / (1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }

	return SC*120.0*a;
}

float terrainM( in vec2 x )
{
	vec2  p = x*0.003/SC;
    float a = 0.0;
    float b = 1.0;
	vec2  d = vec2(0.0);
    for( int i=0; i<9; i++ )
    {
        vec3 n = noise_derivative(p);
        d += n.yz;
        a += b*n.x/(1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }
	return SC*120.0*a;
}

float terrainL( in vec2 x )
{
	vec2  p = x*0.003/SC;
    float a = 0.0;
    float b = 1.0;
	vec2  d = vec2(0.0);
    for( int i=0; i<3; i++ )
    {
        vec3 n = noise_derivative(p);
        d += n.yz;
        a += b*n.x/(1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }

	return SC*120.0*a;
}

float raycast( in vec3 ro, in vec3 rd, in float tmin, in float tmax )
{
    float t = tmin;
	for( int i=0; i<300; i++ )
	{
        vec3 pos = ro + t*rd;
		float h = pos.y - terrainM( pos.xz );
		if( abs(h)<(0.0015*t) || t>tmax ) break;
		t += 0.4*h;
	}

	return t;
}

float softShadow(in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.001;
	for( int i=0; i<80; i++ )
	{
	    vec3  p = ro + t*rd;
        float h = p.y - terrainM( p.xz );
		res = min( res, 16.0*h/t );
		t += h;
		if( res<0.001 ||p.y>(SC*200.0) ) break;
	}
	return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos, float t )
{
    vec2  eps = vec2( 0.001*t, 0.0 );
    return normalize( vec3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
                            2.0*eps.x,
                            terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
}

float fbm( vec2 p )
{
    float f = 0.0;
    f += 0.5000*texture( iChannel0, p/256.0 ).x; p = m2*p*2.02;
    f += 0.2500*texture( iChannel0, p/256.0 ).x; p = m2*p*2.03;
    f += 0.1250*texture( iChannel0, p/256.0 ).x; p = m2*p*2.01;
    f += 0.0625*texture( iChannel0, p/256.0 ).x;
    return f/0.9375;
}

const float kMaxT = 5000.0*SC;

#define SKY_BASE_COLOR (vec3(0.3,0.5,0.85))
#define SKY_MIST_COLOR (0.85*vec3(0.7,0.75,0.85))
#define SUN_COLOR1 (0.25*vec3(1.0,0.7,0.4))
#define SUN_COLOR2 (0.25*vec3(1.0,0.8,0.6))
#define SUN_COLOR3 (0.20*vec3(1.0,0.8,0.6))

#define HORIZON_COLOR  (0.68*vec3(0.4,0.65,1.0))
#define CLOUD_COLOR    (vec3(1.0,0.95,1.0))

#define ROCK_COLOR1     vec3(0.08,0.05,0.03)
#define ROCK_COLOR2     vec3(0.10,0.09,0.08)
#define GRASS_COLOR1    (0.20*vec3(0.45,.30,0.15))
#define GRASS_COLOR2    (0.15*vec3(0.30,.30,0.10))

#define SNOW_COLOR      (0.29*vec3(0.62,0.65,0.7))

#define SNOW_THICKNESS1 55.0
#define SNOW_THICKNESS2 80.0

#define AMBIENT_LIGHT   0.5
#define AMBIENT_LIGHT_AUGMENTATION  (0.5 * nor.y)
#define AMBIENT_LIGHT_SCALE   (vec3(0.40,0.60,1.00) * 1.2)
#define MOUNTAIN_AMBIENT_MIN 0.2
#define MOUNTAIN_AMBIENT_RANGE 0.8
#define MOUNTAIN_AMBIENT_SCALE vec3(0.40,0.50,0.60)

#define DIRECTIONAL_LIGHT_SCALE (vec3(8.00,5.00,3.00) * 1.3)

#define FOG_COLOR 0.65*vec3(0.4, 0.65, 1.0)
#define SUN_SCATTER_COLOR 0.3*vec3(1.0,0.7,0.3)

vec4 render( in vec3 ro, in vec3 rd )
{
    vec3 lightDir1 = normalize( vec3(-0.8,0.4,-0.3) );
    // bounding plane
    float tmin = 1.0;
    float tmax = kMaxT;
#if 1
    float maxh = 300.0*SC;
    float tp = (maxh-ro.y)/rd.y;
    if( tp>0.0 )
    {
        if( ro.y>maxh ) 
            tmin = max( tmin, tp );
        else
            tmax = min( tmax, tp );
    }
#endif
	float sundot = clamp(dot(rd,lightDir1),0.0,1.0);
	vec3 col;
    float t = raycast( ro, rd, tmin, tmax );
    if( t>tmax)
    {
        col = vec3(0.0, 0.0, 0.0);

        // sky		
        col = SKY_BASE_COLOR - rd.y*rd.y*0.5;
        col = mix(col, SKY_MIST_COLOR, pow( 1.0-max(rd.y,0.0), 4.0 ));

        // sun
		col += SUN_COLOR1 * pow( sundot, 5.0 );   // sun falloff 1
		col += SUN_COLOR2 * pow( sundot, 64.0 );  // sun falloff 2
		col += SUN_COLOR3 * pow( sundot, 512.0 ); // sun falloff 3

        // clouds
		vec2 sc = ro.xz + rd.xz * (SC * 1000.0 - ro.y) / rd.y;
		col = mix( col, CLOUD_COLOR, 0.5*smoothstep(0.5, 0.8, fbm(0.0005*sc/SC)) );

        // horizon
        col = mix( col, HORIZON_COLOR, pow( 1.0-max(rd.y,0.0), 16.0 ) );

        t = -1.0;
	}
	else
	{
        // mountains		
		vec3 pos = ro + t*rd;
        vec3 nor = calcNormal ( pos, t );
        vec3 ref = reflect( rd, nor );

        vec3 hal = normalize(lightDir1-rd);
        float fre = clamp( 1.0+dot(rd, nor), 0.0, 1.0 );

        // rock
        float rock = texture( iChannel0, (7.0/SC)*pos.xz/256.0 ).x;
        col = (rock*0.25 + 0.75) * mix( ROCK_COLOR1, ROCK_COLOR2, 
                                      texture(iChannel0,0.00007*vec2(pos.x,pos.y*48.0)/SC).x );
		col = mix( col, GRASS_COLOR1*(0.50*rock + 0.50),smoothstep(0.70,0.9,nor.y) );
        col = mix( col, GRASS_COLOR2*(0.75*rock + 0.25),smoothstep(0.95,1.0,nor.y) );
		col *= 0.1 + 1.8 * sqrt(fbm(pos.xz*0.04) * fbm(pos.xz*0.005));

		// snow
		float h = smoothstep(SNOW_THICKNESS1, SNOW_THICKNESS2, pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
        float e = smoothstep(1.0 - 0.5 * h, 1.0 - 0.1 * h, nor.y);
        float o = 0.3 + 0.7 * smoothstep(0.0, 0.1, nor.x + h * h);
        float snow = h * e * o;
        col = mix( col, SNOW_COLOR, smoothstep( 0.1, 0.9, snow ) );
        
        // lighting	
        float amb = clamp( AMBIENT_LIGHT + AMBIENT_LIGHT_AUGMENTATION, 0.0, 1.0); // 
		float bac = clamp( MOUNTAIN_AMBIENT_MIN + MOUNTAIN_AMBIENT_RANGE * dot( normalize( vec3(-lightDir1.x, 0.0, lightDir1.z ) ), nor ), 0.0, 1.0 );
		float dif = clamp( dot( lightDir1, nor ), 0.0, 1.0 );
		float sh = 1.0; 
        if(dif>=0.0001)
            sh = softShadow(pos+lightDir1*SC*0.05,lightDir1);
		
		vec3 lin = vec3(0.0);
		lin += amb * AMBIENT_LIGHT_SCALE;
        lin += bac * MOUNTAIN_AMBIENT_SCALE;
		lin += dif * DIRECTIONAL_LIGHT_SCALE * sh;// * vec3(sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh);
		col *= lin;

        col += (0.7+0.3*snow)*(0.04+0.96*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0)) *
               vec3(7.0,5.0,3.0)*dif*sh*
               pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
        col += snow*0.65*pow(fre,4.0)*vec3(0.3,0.5,0.6)*smoothstep(0.0,0.6,ref.y);

        // mickey!!!!!!!!!!!!!!!!!!!
		// fog
        float fogfactor = 1.0 - exp(-pow(0.001*t/SC, 1.5) );
        col = mix(col, FOG_COLOR, fogfactor);
	}
    // sun scatter
    col += SUN_SCATTER_COLOR * pow(sundot, 8.0);

    // gamma
	col = sqrt(col);
    
	return vec4( col, t );
}

vec3 camPath( float time )
{
	return SC*1100.0*vec3( cos(0.0+0.23*time), 0.0, cos(1.5+0.21*time) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, in float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void moveCamera( float time, out vec3 oRo, out vec3 oTa, out float oCr, out float oFl )
{
	vec3 ro = camPath( time );
	vec3 ta = camPath( time + 3.0 );
	ro.y = terrainL( ro.xz ) + 22.0*SC;
	ta.y = ro.y - 20.0*SC;
	float cr = 0.2*cos(0.1*time);
    oRo = ro;
    oTa = ta;
    oCr = cr;
    oFl = 3.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iTime*0.03 - 0.1 + 0.3;// + 4.0*iMouse.x/iResolution.x;

    // camera position
    vec3 ro, ta; float cr, fl;
    moveCamera( time, ro, ta, cr, fl );

    // camera2world transform    
    mat3 cam = setCamera( ro, ta, cr );

    // pixel
    vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;

    float t = kMaxT;
    vec3 tot = vec3(0.0);
	#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 s = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
	#else    
        vec2 s = p;
	#endif

        // camera ray    
        vec3 rd = cam * normalize(vec3(s,fl));

        vec4 res = render( ro, rd );
        t = min( t, res.w );
 
        tot += res.xyz;
	#if AA>1
    }
    tot /= float(AA*AA);
	#endif


    //-------------------------------------
	// velocity vectors (through depth reprojection)
    //-------------------------------------
    float vel = 0.0;
    if( t<0.0 )
    {
        vel = -1.0;
    }
    else
    {

        // old camera position
        float oldTime = time - 0.1 * 1.0/24.0; // 1/24 of a second blur
        vec3 oldRo, oldTa; float oldCr, oldFl;
        moveCamera( oldTime, oldRo, oldTa, oldCr, oldFl );
        mat3 oldCam = setCamera( oldRo, oldTa, oldCr );

        // world space
        #if AA>1
        vec3 rd = cam * normalize(vec3(p,fl));
        #endif
        vec3 wpos = ro + rd*t;
        // camera space
        vec3 cpos = vec3( dot( wpos - oldRo, oldCam[0] ),
                          dot( wpos - oldRo, oldCam[1] ),
                          dot( wpos - oldRo, oldCam[2] ) );
        // ndc space
        vec2 npos = oldFl * cpos.xy / cpos.z;
        // screen space
        vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);


        // compress velocity vector in a single float
        vec2 uv = fragCoord/iResolution.xy;
        spos = clamp( 0.5 + 0.5*(spos - uv)/0.25, 0.0, 1.0 );
        vel = floor(spos.x*1023.0) + floor(spos.y*1023.0)*1024.0;
    }
    
    fragColor = vec4( tot, vel );
}