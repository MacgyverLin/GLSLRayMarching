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

// Uncomment the following define in order to see the bridge in 3D!
//#define STEREO

//----------------------------------------------------------------

// https://iquilezles.org/articles/distfunctions
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// https://iquilezles.org/articles/distfunctions
float sdCone( vec3 p, vec2 c )
{
    float q = length(p.xz);
    return max( dot(c,vec2(q,p.y)), p.y );
}

// https://iquilezles.org/articles/distfunctions
float sdSphere( in vec3 p, in vec4 e )
{
	vec3 di = p - e.xyz;
	return length(di) - e.w;
}

//----------------------------------------------------------------

// https://iquilezles.org/articles/smin
vec2 smin( vec2 a, vec2 b )
{
    const float k = 1.6;
	float h = clamp( 0.5 + 0.5*(b.x-a.x)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

//----------------------------------------------------------------

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return -1.0 + 2.0*textureLod( iChannel2, (uv+0.5)/256.0, 0.0 ).x;
}

// https://iquilezles.org/articles/biplanar
vec3 texturize( sampler2D sa, vec3 p, vec3 n )
{
	vec3 x = texture( sa, p.yz ).xyz;
	vec3 y = texture( sa, p.zx ).xyz;
	vec3 z = texture( sa, p.xy ).xyz;
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

//----------------------------------------------------------------

float bridge( in vec3 pos )
{
    float f = 0.5-0.5*cos(3.14159*pos.z/20.0);

    vec3 xpos = vec3( pos.x, 1.0-6.0+pos.y + f*4.0, pos.z );

    float g = 0.5+0.5*xpos.x/4.0;
    g = 1.0 - (smoothstep( 0.15, 0.25, g )-smoothstep( 0.75, 0.85, g ));
    vec3 xpos5 = vec3( xpos.x, xpos.y + 10.0*f*f*g, xpos.z );

    float mindist = sdBox(xpos5, vec3(4.0,0.5 + 10.0*f*f*g,20.0)-0.1  )-0.1;

    float dis = sdBox( xpos, vec3(4.2,0.1,20.0) );
    mindist = min( dis, mindist );
	
    vec3 sxpos = vec3( abs(xpos.x), xpos.y, xpos.z );
    dis = sdBox( sxpos-vec3(4.0-0.4,1.5,0.0), vec3(0.4,0.2,20.0)-0.05 )-0.05;
    mindist = min( dis, mindist );

    if( abs(xpos.z)<20.0 )
    {
        int cid = int(floor( xpos.z ));
        if( cid == 0 || cid==14 || cid==-14 )
        {
            vec3 xpos2 = vec3( abs(xpos.x)-3.4, xpos.y-1.0, mod(1000.0+xpos.z,1.0)-0.5 );

            dis = sdBox( xpos2, vec3(0.8,1.0,0.45) );
            mindist = min( dis, mindist );
			
            dis = sdBox( xpos2+vec3(-0.8,0.0,0.0), vec3(0.15,0.9,0.35) );
            mindist = max( mindist, -dis );

            dis = sdSphere( xpos2, vec4(0.0, 1.3, 0.0, 0.35 ) );
            mindist = min( dis, mindist );
        }
        else
        {
            vec3 xpos2 = vec3( abs(xpos.x)-(4.0-0.2), xpos.y-0.8, mod(1000.0+xpos.z,1.0)-0.5 );
            vec3 xposc = vec3( length( xpos2.xz ), xpos2.y, 0.0 );

            float mo = 0.8 + 0.2*cos(2.0*6.2831*xpos2.y);

            float ma = cos(4.0*atan(xpos2.x,xpos2.z));
            mo -= 0.1*(1.0-ma*ma);

            dis = sdBox( xposc, vec3(0.2*mo,0.5,0.0)  );
            mindist = min( dis, mindist );
        }
    }

    return 0.25*mindist;
}


float terrain( vec2 x )
{
	vec2 z = x*0.05;
	
	x *= 0.06*1.0; x += 227.3;
	
	vec2 p = floor(x);
    vec2 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float a = textureLod(iChannel1,(p+vec2(0.5,0.5))/1024.0,0.0).x;
	float b = textureLod(iChannel1,(p+vec2(1.5,0.5))/1024.0,0.0).x;
	float c = textureLod(iChannel1,(p+vec2(0.5,1.5))/1024.0,0.0).x;
	float d = textureLod(iChannel1,(p+vec2(1.5,1.5))/1024.0,0.0).x;
	float r = mix(mix( a, b,f.x), mix( c, d,f.x), f.y);

    r -= 0.04*(noise( 5.0*z ));
	
	r = r*15.0 + 5.0;
	float ss = smoothstep( 0.5, 2.2, abs(z.y) );
	r = mix( r, -3.0, 1.0-ss );
	
	float cc = 1.0-smoothstep( 0.1, 1.0, abs(z.x) );
	cc *= smoothstep( 0.5, 1.0, abs(z.y) );
	r = mix( r, 0.5, cc );

	return r;
}

float trees( vec3 p )
{
    vec2 ip = floor( p.xz/4.0 );
	vec2 fp = mod(   p.xz,4.0 );

    float d = 4.0+p.y;
    
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 off = vec2(i,j);
        vec2 iq = ip + off;
        vec2 q = iq*4.0;
        
        float e = smoothstep( 0.4, 0.6, texelFetch(iChannel1,(ivec2(iq)*4)&1023, 0).x );
        e *= smoothstep( 23.0, 24.0, -q.y );
        if( e<0.001 ) continue;

        vec2 ce = vec2(2.0) + 1.0*(1.0-2.0*texelFetch(iChannel2,ivec2(iq)&255, 0 ).xy);

        ce += off*4.0;
        
        float h = terrain( q+ce );
        
        float dc = sdCone( vec3(fp.x,p.y,fp.y)-vec3(ce.x,h+6.0*e,ce.y), vec2(0.98,0.199) );
        dc += 0.1*sin(6.0*p.y)*sin(8.0*atan(fp.x-ce.x,fp.y-ce.y));

        d = min( d, dc );

    }
    return d;
}

vec2 map( in vec3 p )
{
    vec2 res = vec2(1000.0,-1.0);

	// terrain
	float h = terrain( p.xz );
	float dd = (p.y - h);
		
	res = vec2( 0.75*dd, 0.0 );


    // bridge
    float bd = sdBox(p,vec3(10.0,8.0,25.0)); // bounding volume
    if( bd<res.x )    
    {
	float dis = bridge( p );
	res = smin( res, vec2(dis,1.0) );
    }
	
    // water
    {
    float dis = p.y - (-2.0);	
	if( dis<res.x ) res = vec2( dis, 2.0 );
    }

    // trees	
    bd = p.z-23.0;
    if( bd<res.x )
    {
	float dis = trees(p);
	if( dis<res.x ) res = vec2( dis, 0.0 );
    }

    return res;
}

const float precis = 0.015;

vec3 raycast( in vec3 ro, in vec3 rd )
{
	float maxd = 250.0;
    float tp = (25.0-ro.y)/rd.y;
    if( tp>0.0 ) maxd = min(maxd,tp);
    float t = 0.0;
	float d = 0.0;
    float m = 1.0;
    for( int i=0; i<256; i++ )
    {
	    vec2 res = map( ro+rd*t );
        if( abs(res.x)<precis||t>maxd ) break;
		d = res.y;
		m = res.y;
        t += res.x*0.9;
    }

    if( t>maxd ) m=-1.0;
    return vec3( t, d, m );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*precis;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
}

// https://iquilezles.org/articles/rmshadows
float softshadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.0;
	float h = 1.0;

    float maxd = 250.0;
    float tp = (25.0-ro.y)/rd.y;
    if( tp>0.0 ) maxd = min(maxd,tp);

    for( int i=0; i<60; i++ )
    {
        h = map(ro + rd*t).x;
        res = min( res, k*h/t );
		t += clamp( h, 0.02, 1.0 );
		if( h<0.001 || t>maxd) break;
    }
    return clamp(res,0.0,1.0);
}

float calcOcc( in vec3 pos, in vec3 nor )
{
	float totao = 0.0;
    for( int aoi=0; aoi<8; aoi++ )
    {
        float hr = 0.1 + 1.5*pow(float(aoi)/8.0,2.0);
        vec3 aopos = pos + nor * hr;
        float dd = map( aopos ).x;
        //totao += clamp( (hr-dd)*0.1-0.01,0.0,1.0);
		totao += max( 0.0, hr-3.0*dd-0.01);
    }
    return clamp( 1.0 - 0.15*totao, 0.0, 1.0 );
}

const vec3 lig = normalize(vec3(-0.5,0.25,-0.3));

void shade( in vec3 pos, in vec3 nor, in vec3 rd, in float matID, 
		    out vec3 bnor, out vec4 mate, out vec2 mate2 )
{
    bnor = vec3(0.0);
	mate = vec4(0.0);
	mate2 = vec2(0.0);
		
	if( matID<0.5 )
    {
        mate.xyz = vec3(0.1,0.2,0.0)*0.5;
        mate.w = 0.0;
    }
    else if( matID<1.5 )
    {
        mate.xyz = 0.3*pow( texturize( iChannel0, 0.45*pos, nor ).xyz, vec3(2.0) );
        mate.w = 0.0;
    }
    else if( matID<2.5 )
    {
        mate.w = 1.0;
        float h = clamp( (pos.y - terrain(pos.xz))/10.0, 0.0, 1.0 );
			
        mate.xyz = 0.3*mix( vec3(0.1,0.4,0.2), vec3(0.1,0.2,0.3), h );
			
		bnor = vec3(0.0,1.0,0.0);
	    bnor.xz  = 0.20*(-1.0 + 2.0*texture( iChannel2, 0.05*pos.xz*vec2(1.0,0.3) ).xz);
	    bnor.xz += 0.15*(-1.0 + 2.0*texture( iChannel2, 0.10*pos.xz*vec2(1.0,0.3) ).xz);
	    bnor.xz += 0.10*(-1.0 + 2.0*texture( iChannel2, 0.20*pos.xz*vec2(1.0,0.3) ).xz);
		bnor = 10.0*normalize(bnor);
    }
	else //if( matID<3.5 )
    {
		mate = vec4(0.0);
	}
	
	if( matID<2.5 )
	{
	float iss = smoothstep( 0.5, 0.9, nor.y );
    iss = mix( iss, 0.9, 0.75*smoothstep( 0.1, 1.0, texturize( iChannel1, 0.1*pos, nor ).x ) );
	
	vec3 scol = vec3( 0.8 );
	
	vec3 cnor = normalize( -1.0 + 2.0*texture( iChannel2, 0.15*pos.xz ).xyz );
	cnor.y = abs( cnor.y );
	float spe = max( 0.0, pow( clamp( dot(lig,reflect(rd,cnor)), 0.0, 1.0), 16.0 ) );
    mate2.y = spe*iss;
	
    mate.xyz = mix( mate.xyz, scol, iss );
	}
}

float cloudShadow( in vec3 pos )
{
	vec2 cuv = pos.xz + lig.xz*(100.0-pos.y)/lig.y;
	float cc = 0.1 + 0.9*smoothstep( 0.1, 0.35, textureLod( iChannel1, 0.0003*cuv + 0.1+0.013*iTime, 0.0 ).x );
	
	return cc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(0.5);
	if( iMouse.z>0.0 ) m = iMouse.xy/iResolution.xy;

	#ifdef STEREO
	float eyeID = mod(fragCoord.x + mod(fragCoord.y,2.0),2.0);
    #endif

    //-----------------------------------------------------
    // animate
    //-----------------------------------------------------

	float ctime = iTime;

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

	float an = sin(5.3+0.05*ctime) - 6.2831*(m.x-0.5);

	vec3 ro = vec3(30.0*sin(an),4.5,30.0*cos(an));
    vec3 ta = vec3(2.0,1.0,0.0);

    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

	#ifdef STEREO
	vec3 fo = ro + rd*100.0; // put focus plane behind Mike
	ro -= 0.5*uu*eyeID;    // eye separation
	rd = normalize(fo-ro);
    #endif

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = 2.5*vec3(0.18,0.33,0.45) - rd.y*1.5;
	col *= 0.9;
    float sun = clamp( dot(rd,lig), 0.0, 1.0 );
	col += vec3(2.0,1.5,0.0)*0.8*pow( sun, 32.0 );

    vec3 bgcol = col;
	
	vec2 cuv = ro.xz + rd.xz*(100.0-ro.y)/rd.y;
	float cc = texture( iChannel1, 0.0003*cuv +0.1+ 0.013*iTime ).x;
	cc = 0.65*cc + 0.35*texture( iChannel1, 0.0003*2.0*cuv + 0.013*.5*iTime ).x;
	cc = smoothstep( 0.3, 1.0, cc );
	col = mix( col, vec3(1.0,1.0,1.0)*(0.95+0.20*(1.0-cc)*sun), 0.7*cc );
	
	// raymarch
    vec3 tmat = raycast(ro,rd);
    if( tmat.z>-0.5 )
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos);

        // materials
		vec4 mate = vec4(0.0);
		vec2 mate2 = vec2(0.0);
		vec3 bnor = vec3(0.0);
		shade( pos, nor, rd, tmat.z, bnor, mate, mate2 );
        nor = normalize( nor + bnor );

		vec3 ref = reflect( rd, nor );

		// lighting
		float occ = calcOcc(pos,nor) * clamp(0.7 + 0.3*nor.y,0.0,1.0);
        float sky = 0.6 + 0.4*nor.y;
		float bou = clamp(-nor.y,0.0,1.0);
		float dif = max(dot(nor,lig),0.0);
        float bac = max(0.2 + 0.8*dot(nor,normalize(vec3(-lig.x,0.0,-lig.z))),0.0);
		float sha = 0.0; if( dif>0.01 ) sha=softshadow( pos+0.01*nor, lig, 64.0 );
		sha *= cloudShadow( pos );
        float fre = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 3.0 );

		// lights
		vec3 lin = vec3(0.0);
		lin += 1.0*dif*vec3(1.70,1.15,0.70)*pow(vec3(sha),vec3(1.0,1.2,2.0));
		lin += 1.0*sky*vec3(0.05,0.20,0.45)*occ;
		lin += 1.0*bac*vec3(0.20,0.25,0.25)*occ;
		lin += 1.2*bou*vec3(0.15,0.20,0.20)*(0.5+0.5*occ);
        lin += 1.0*fre*vec3(1.00,1.25,1.30)*occ*0.5*(0.5+0.5*dif*sha);
		lin += 1.0*mate2.y*vec3(1.00,0.60,0.50)*4.0*occ*dif*(0.1+0.9*sha);

		// surface-light interacion
		col = mate.xyz*lin;

		// fog
		col = mix( bgcol, col, exp(-0.0015*pow(tmat.x,1.0)) );
	}

	// sun glow
    col += vec3(1.0,0.6,0.2)*0.4*pow( sun, 4.0 );

	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------
    // gamma
	col = pow( clamp(col,0.0,1.0), vec3(0.45) );

    // contrast, desat, tint and vignetting	
	col = col*0.8 + 0.2*col*col*(3.0-2.0*col);
	col = mix( col, vec3(col.x+col.y+col.z)*0.333, 0.25 );
	col *= vec3(1.0,1.02,0.96);
	col *= 0.6 + 0.4*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    #ifdef STEREO
    col *= vec3( eyeID, 1.0-eyeID, 1.0-eyeID );
	#endif

    fragColor = vec4( col, 1.0 );
}