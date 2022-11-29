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

float hash( float n )
{
    return fract(sin(n)*43758.5453123);
}

vec3 hash3( float n )
{
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*157.0;

    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+157.0), hash(n+158.0),f.x),f.y);
}

const mat2 m2 = mat2( 0.80, -0.60, 0.60, 0.80 );

float fbm( vec2 p )
{
    float f = 0.0;

    f += 0.5000*noise( p ); p = m2*p*2.02;
    f += 0.2500*noise( p ); p = m2*p*2.03;
    f += 0.1250*noise( p ); p = m2*p*2.01;
    f += 0.0625*noise( p );

    return f/0.9375;
}

//----------------------------------------------------------------

vec2 sdSegment( vec3 a, vec3 b, vec3 p )
{
	vec3 pa = p - a;
	vec3 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	
	return vec2( length( pa - ba*h ), h );
}

float smin( float a, float b )
{
    float k = 0.01;
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 map( vec3 p )
{
	vec3 op = p;
	{
	float an = 0.35;
	float co = cos( an );
	float si = sin( an );
	mat2  ma = mat2( co, -si, si, co );
	p.xy = ma*p.xy;
	}
	
	p.y -= 4.0;

    float d = length( (p-vec3(0.0,-0.1,0.0))*vec3(1.0,3.0,1.0)) - 0.4;
	vec2 res = vec2( d/3.0, 1.0 );
	

	if( p.y>0.0 )
	{

	// palito
	vec3 pp = p;
		
		//vec3 q = p - vec3(0.0,-0.25,0.0);
		vec3 q = (p-vec3(0.0,-0.15,0.0))*vec3(1.0,1.5,1.0);
		pp.y = length(q);
		#if 1
		pp.x = 0.35*0.5*atan( q.x, q.z );
		pp.z = 0.35*acos( q.y/length(q) );
		#else
		//pp.xz *= 1.0 + 2.0*length(p.xz)/(0.5+p.y);
		pp.xz -= normalize(pp.xz) * p.y * 0.5;
		
		#endif
	
	pp.xz = (mod(20.0*(pp.xz+0.5),1.0) - 0.5)/20.0;
	
		
		float hh = 0.0;
	vec2 h = sdSegment( vec3(0,0.0,0.0), vec3(0.0,0.5+hh,0.0), pp );
	float sr = 0.01 + 0.001*smoothstep( 0.9,0.99,h.y );
	d = h.x - sr;
	d *= 0.5;
	res.x = smin( d, res.x );
	}

	p.xz = abs(p.xz);

	
	for( int i=0; i<4; i++ )
	{
		float an = 6.2831*float(i)/14.0;
		float id = an;
		float co = cos( an );
		float si = sin( an );
		mat2  ma = mat2( co, -si, si, co );

		vec2  r = ma*p.xz;//-vec2(1.0,0.0));
		vec3  q = vec3( r.x, p.y, r.y );

		an = 0.02*sin(10.0*an);

		co = cos(0.2+an);
		si = sin(0.2+an);
		q.xy = mat2( co, -si, si, co )*q.xy;

		float ss = 1.0 + 0.1*sin(171.0*an);
		q.x *= ss;
		q.x -= 1.0;
		q.y -= 0.15*q.x*(1.0-q.x);
		
        float ra = 1.0 - 0.3*sin(1.57*q.x);
		d = 0.05*(length( q*vec3(1.0,20.0,4.0*ra) ) - 1.0*0.8);
		
        if( d<res.x ) res = vec2( d, 2.0 );
	}
	
	{
    p = op;	
	float an = 0.35*clamp( p.y/3.8, 0.0, 1.0 );
	float co = cos( an );
	float si = sin( an );
	mat2  ma = mat2( co, -si, si, co );
	p.xy = ma*p.xy;

	vec2 h = sdSegment( vec3(0,0.0,0.0), vec3(0.0,4.0-0.2,0.0), p );
	d = h.x - 0.07;
    if( d<res.x ) res = vec2( d, 3.0 );
	}

	return res;
}

vec3 intersect( in vec3 ro, in vec3 rd )
{
	float maxd = 10.0;
	float precis = 0.001;
    float h = 1.0;
    float t = 0.0;
	float d = 0.0;
    float m = 1.0;
    for( int i=0; i<100; i++ )
    {
        if( h<precis || t>maxd ) break;
        t += h;
	    vec2 res = map( ro+rd*t );
        h = res.x;
		d = res.y;
		m = res.y;
    }

    if( t>maxd ) m=-1.0;
    return vec3( t, d, m );
}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3(0.002,0.0,0.0);

	return normalize( vec3(
           map(pos+eps.xyy).x - map(pos-eps.xyy).x,
           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
	float h = 1.0;
    for( int i=0; i<50; i++ )
    {
        h = map(ro + rd*t).x;
        res = min( res, k*h/t );
		t += clamp( h, 0.02, 2.0/50.0 );
		if( res<0.01 ) break;
    }
    return clamp(res,0.0,1.0);
}


float occlusion( in vec3 pos, in vec3 nor )
{
	float totao = 0.0;
    for( int aoi=0; aoi<16; aoi++ )
    {
		vec3 aopos = -1.0+2.0*hash3(float(aoi)*213.47);
		aopos *= sign( dot(aopos,nor) );
		aopos = pos + aopos*0.2;
        float dd = clamp( map( aopos ).x, 0.0, 1.0 );
        totao += dd;
    }
	totao /= 16.0;
	
    return clamp( totao*8.0, 0.0, 1.0 );
}


vec3 lig = normalize(vec3(0.5,0.35,-0.7));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(0.5);
	if( iMouse.z>0.0 ) m = iMouse.xy/iResolution.xy;


    //-----------------------------------------------------
    // animate
    //-----------------------------------------------------
	
	float ctime = iTime;

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
	
	float an = 3.5 + 0.05*ctime - 6.2831*(m.x-0.5);

    vec3  ta = vec3(-1.0,3.5,0.0);
	vec3  ro = ta + 1.1*vec3(2.0*sin(an),1.5,2.0*cos(an));
	float rr = 0.0*sin(0.04*iTime) ;

    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(rr),cos(rr),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );


    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = vec3(1.0);

	col = texture( iChannel0, rd ).yxz;
	col = pow( col, vec3(2.0,2.0,2.2) )*6.0;
	
	// raymarch
    vec3 tmat = intersect(ro,rd);
    if( tmat.z>-0.5 )
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos);
		vec3 ref = reflect( rd, nor );
		
        // materials
		vec4 mate = vec4(0.0);// col, spec
		vec2 mate2 = vec2(0.0);

        if( tmat.z<1.5 )
		{
			float an = 0.35;
			float co = cos( an );
			float si = sin( an );
			mat2  ma = mat2( co, -si, si, co );
			vec3 uvw = pos;
			uvw.xy = ma*pos.xy;
			
			mate = vec4(0.9,0.15,0.1,0.8);
			float ff = 1.0 - smoothstep( 0.1, 0.3, length(uvw.xz) );
			mate.xyz = mix( mate.xyz, vec3(0.7,0.1,0.0), ff );
            mate.xyz *= 0.5;

		}
		else if( tmat.z<2.5 )
		{
			mate = vec4(0.6,0.6,0.6,0.8);
			
			float an = 0.35;
			float co = cos( an );
			float si = sin( an );
			mat2  ma = mat2( co, -si, si, co );
			vec3 uvw = pos;
			uvw.xy = ma*pos.xy;


			float a = atan( uvw.z, uvw.x );
			float r = length( uvw.xz );
			
			float rr = smoothstep( 0.0, 1.0, 0.5 - 0.5*cos(1.0*14.0*a) );
			
			float ll = 1.0-smoothstep( 0.5, 1.3, r + 0.16*rr);
			
            mate.xyz = mix( mate.xyz, vec3(0.4,0.3,0.1), ll );

            float mo = noise( 10.0*vec2(8.0*a,0.3*r) );			
			
			mate.xyz -= 0.2*mo*(1.0-smoothstep(0.4,1.5,r));
			
			mo = mix( 0.0, 1.0-mo*mo, smoothstep(0.5,1.0,r) );
			mate = mix( mate, vec4(0.7,0.4,0.0,0.0), 0.1*mo );


			// borders
		
			float nv = noise( 8.0*vec2(4.0*a,0.1*r) );			
			rr = smoothstep( 1.4,1.8,r + 0.5*nv);
			mate = mix( mate, 0.2*vec4(0.6,0.2,0.3,0.0), rr );

			// dots
			float sp = clamp((r-0.8)*5.0,0.0,1.0)*smoothstep(0.6,0.9,fbm( 64.0*uvw.xz ))*smoothstep(0.6,0.7,nor.y);;
			mate.xyz -= vec3(0.4,0.6,0.8)*sp*0.3*(1.0-rr);
			mate.xyz = max( mate.xyz, 0.0 );

			mate2.x = 2.0*(1.0-ll);
			mate2.x *= 1.0 + smoothstep( 0.0, 2.0, 0.5 - 0.5*cos(1.0*14.0*a) );
				
			// more face occ...
			mate.xyz *= clamp(r*2.0,0.0,1.0);
            mate.xyz *= 0.6;
		}
		else if( tmat.z<3.5 )
		{
			mate = 0.3*vec4(0.02,0.1,0.0,0.2);
			float e = pow( max(1.0+dot( rd, nor ),0.0), 1.0 );
			
			mate.xyz += vec3(e)*0.2*vec3(0.8,1.0,0.5);
		}
		
		// lighting
		float occ = occlusion( pos, nor );
        float amb = 0.5 + 0.5*nor.y;
		float bou = clamp(-nor.y,0.0,1.0);
		float dif = max(dot(nor,lig),0.0);
        float bac = max(0.3 + 0.7*dot(nor,-lig),0.0);
		float sha = 0.0; if( dif>0.01 ) sha=softshadow( pos+0.001*nor, lig, 0.005, 64.0 );
        float fre = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 3.0 );
        float spe = max( 0.0, pow( clamp( dot(lig,ref), 0.0, 1.0), 16.0 ) );
		float bif = clamp(0.4+0.6*dot(-nor,lig),0.0,1.0);
	
		
		// lights
		vec3 brdf = vec3(0.0);
        brdf += 8.0*dif*vec3(1.20,0.90,0.50)*pow(vec3(sha),vec3(1.0,1.2,1.5))*(0.8+0.2*occ);
        brdf += 1.0*bou*vec3(0.10,0.20,0.10)*occ;
		brdf += 1.4*amb*vec3(0.10,0.25,0.40)*occ*(0.5+0.5*nor.y);
		brdf += 1.0*bac*vec3(0.40,0.35,0.30)*occ;
        brdf += 1.0*fre*vec3(1.00,1.00,1.00)*occ*2.0*mate.w*(0.5+0.5*dif*sha);
		brdf += 1.0*spe*vec3(1.00,1.00,1.00)*occ*1.0*sha;
		brdf += 1.0*bif*vec3(1.80,1.50,0.70)*occ*0.2*mate.xyz*mate2.x;//*(0.8+0.2*sha*dif);

        // surface-light interaction
		col = mate.xyz* brdf + vec3(2.5)*mate.w*spe*sha;
        
        col = pow(col,vec3(0.8,0.9,1.0));
	}


	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------
    // gamma
	col = pow( clamp(col,0.0,1.0), vec3(0.45) );
	
	// vigneting
    col *= 0.7 + 0.3*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );

    fragColor = vec4( col, 1.0 );
}
