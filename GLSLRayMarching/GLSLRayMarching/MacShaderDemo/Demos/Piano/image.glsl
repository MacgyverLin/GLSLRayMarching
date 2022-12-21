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

#if HW_PERFORMANCE==0
#define AA 1
#else
// try 2 for higher quality
#define AA 1
#endif


// https://iquilezles.org/articles/distfunctions
float udRoundBox( vec3 p, vec3 b, vec3 r )
{
    return length(max(abs(p)-b,0.0))-r.x;
}

// https://iquilezles.org/articles/distfunctions
float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// https://iquilezles.org/articles/distfunctions
float sdCylinder( vec3 p, vec2 h )
{
    return max( length(p.xz)-h.x, abs(p.y)-h.y );
}

// https://iquilezles.org/articles/distfunctions
float opRepLim( in float p, in float s, in float mi, in float ma )
{
    return p-s*clamp(round(p/s),mi,ma);
}

vec3 hash3( float n )
{
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(13.5453123,31.1459123,37.3490423));
}

//----------------------------

float obj1( in vec3 p )
{
    vec3 q = vec3( opRepLim(p.x+0.1,0.2,-22.0,23.0), p.yz-0.1 );
	return udRoundBox( q, vec3(0.091,0.075,0.6)-0.005, vec3(0.01) );
}

float obj2( in vec3 p, in float d )
{
    vec3 q = vec3( opRepLim(p.x,0.2,-21.0,23.0), p.y-0.185, p.z - 0.3 );
	float k = mod( round( p.x/0.2 ), 7.0 );

	if( k==2.0 || k==6.0 ) return d;

	return udRoundBox( q, vec3(0.06,0.075,0.4)-0.01, vec3(0.01,0.01,0.01) );
}

float obj3( in vec3 p )
{
	float d = udRoundBox( p - vec3(0.0, 0.0,1.7), vec3(5.4,0.6,1.0), vec3(0.05) );
	float t;
    
    t = udRoundBox( p - vec3(0.0,-0.3,0.1), vec3(5.4,0.3,0.6), vec3(0.05) );
    d = min(d,t);
    
	t = udRoundBox( p - vec3(0.0,-1.0,2.5), vec3(5.4,3.0,1.0), vec3(0.05) );
    d = min(d,t);
    
	t = sdCylinder( vec3(abs(p.x),p.y,p.z) - vec3(5.25,-2.2,-0.35), vec2(0.1,2.0) );
    t -= 0.03*smoothstep(-0.7,0.7,sin(18.0*p.y)) + 0.017*p.y + 0.025;
    d = min(d,t);
    
	t = udRoundBox( vec3(abs(p.x),p.y,p.z) - vec3(5.05,0.0,0.3), vec3(0.35,0.2,0.8), vec3(0.05) );
    d = min(d,t);
    
	return d;
}

float obj4( in vec3 p )
{
    return 3.75+p.y;
}

float obj5( in vec3 p )
{
    return min( 3.5-p.z, p.x+6.5 );
}

float obj6( in vec3 p )
{
	vec3 q = p - vec3(0.0,1.3,1.1);
	float x = abs(q.x);
	q.z += 0.15*4.0*x*(1.0-x);
	q.yz = mat2(0.9,-0.43,0.43,0.9)*q.yz;
    return 0.5*udRoundBox( q, vec3(1.0,0.7,0.0), vec3(0.01) );
}

float obj8( in vec3 p )
{
	vec3 q = p - vec3(-0.5,-1.8,-2.0);
	
	q.xz = mat2( 0.9,0.44,-0.44,0.9)*q.xz;
	
	float y = 0.5 + 0.5*sin(8.0*q.x)*sin(8.0*q.z);
	y = 0.1*pow(y,3.0) * smoothstep( 0.1,0.4,q.y );
    float d = udRoundBox( q, vec3(1.5,0.25,0.6), vec3(0.3) );
	d += y;
	
    q.xz = abs(q.xz);
	float d2 = sdCylinder( q - vec3(1.4,-1.5,0.6), vec2(0.15,1.5) );
	return min( d, d2 );
}

float obj7( in vec3 p )
{
	vec3 q = p - vec3(1.0,-3.6,1.2);
    q.x = opRepLim(q.x,0.5,-1.0,1.0);
    return udRoundBox( q, vec3(0.05,0.0,0.38), vec3(0.08) );
}

vec2 map( in vec3 p )
{
	// white keys
    vec2 res = vec2( obj1( p ), 0.0 );

	// black keys
    vec2 ob2 = vec2( obj2( p, res.x ), 1.0 );
	if( ob2.x<res.x ) res=ob2;

    // piano body
    vec2 ob3 = vec2( obj3( p ), 2.0 );
    if( ob3.x<res.x ) res=ob3;

    // floor
    vec2 ob4 = vec2( obj4( p ), 3.0 );
    if( ob4.x<res.x ) res=ob4;

    // wall
    vec2 ob5 = vec2( obj5( p ), 4.0 );
    if( ob5.x<res.x ) res=ob5;

	// paper
    vec2 ob6 = vec2( obj6( p ), 5.0 );
    if( ob6.x<res.x ) res=ob6;
	
	// pedals
    vec2 ob7 = vec2( obj7( p ), 6.0 );
    if( ob7.x<res.x ) res=ob7;

	// bench
    vec2 ob8 = vec2( obj8( p ), 7.0 );
    if( ob8.x<res.x ) res=ob8;

	return res;
}

// https://iquilezles.org/articles/biplanar
float boxmap( vec3 p, vec3 n )
{
	p *= 0.15;
	float x = texture( iChannel0, p.yz ).x;
	float y = texture( iChannel0, p.zx ).x;
	float z = texture( iChannel0, p.xy ).x;
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

float floorBump( vec2 pos, out vec2 id )
{
    pos *= 0.25;
    float w = 0.015;
    float y = mod( pos.x*8.0, 1.0 );
    float iy = floor(pos.x*8.0);
    float x = mod( pos.y*1.0 + sin(iy)*8.0, 1.0 );
    float f = smoothstep( 0.0, w,     y ) - smoothstep( 1.0-w,     1.0, y );
         f *= smoothstep( 0.0, w/8.0, x ) - smoothstep( 1.0-w/8.0, 1.0, x );
    id = vec2( iy, floor(pos.y*1.0 + sin(iy)*8.0) );
    return f;
}

vec4 floorColor( vec3 pos, out vec3 bnor )
{
	pos *= 0.75;
	bnor = vec3(0.0);

	vec2 id;
    vec2 e = vec2( 0.005, 0.0 );
    float er = floorBump( pos.xz, id );
    
    vec3 col = vec3(0.6,0.35,0.25);
	float f = 0.5+0.5*texture( iChannel0, 0.1*pos.xz*vec2(6.0,0.5)+0.5*id ).x;
    col = mix( col, vec3(0.4,0.15,0.05), f );
	
	col.x *= 0.8;

	col *= 0.85 + 0.15*texture( iChannel0, 2.0*pos.xz ).x;

    // frekles
    f = smoothstep( 0.4, 0.9, texture( iChannel0, pos.xz*0.2 - id*10.0).x );
    col = mix( col, vec3(0.07), f*0.25 );

    col *= 1.0 + 0.2*sin(32.0*(id.x-id.y));
    col.x += 0.009*sin(0.0+32.0*(id.x+id.y));
    col.y += 0.009*sin(1.0+32.0*(id.x+id.y));
    col.z += 0.009*sin(2.0+32.0*(id.x+id.y));

	return vec4( col*0.5, 0.35 );
}

vec4 pianoColor( in vec3 pos, in vec3 nor )
{
    float o = boxmap( 0.25*pos, nor );
    float f = smoothstep( -0.25, 0.5, boxmap( 8.0*o + 1.0*pos*vec3(0.5,8.0,0.5), nor ) );
	float sp = f;
	vec3 col = 0.14*mix( 0.4*vec3(0.24,0.22,0.18), vec3(0.26,0.22,0.18), f );

	f = floor(pos.y*4.0) + 13.0*floor(abs(nor.x*pos.z + nor.z*pos.x)*0.4);			
	col *= 0.6 + 0.4*fract(sin(f)*13.5453);

	col += 0.0012*sin( f*6.2831 + vec3(0.0,1.0,2.0) );
    return vec4( col*0.6, 0.007*sp );
}

vec4 wallColor( in vec3 pos, in vec3 nor )
{
    vec3 col = 2.0*vec3(0.30,0.30,0.30);

	float f = 1.0-0.4*pow( boxmap( 1.5*pos*vec3(1.0,0.25,1.0), nor ), 1.7 );
    col *= f;

    return vec4(col,0.01*f);
}

vec4 paperColor( in vec3 pos, in vec3 nor )
{
    vec3 col = 0.7*vec3(0.22,0.21,0.18);
	col = mix( col, col*vec3(1.0,0.9,0.8), clamp(0.5 + 0.5*abs(pos.x),0.0,1.0) );
	col *= clamp(0.75 + 0.25*abs(2.0*pos.x),0.0,1.0);
	
	float f = smoothstep( 0.5,1.0, sin(250.0*pos.y) );
	f *=      smoothstep(-0.1,0.1, sin(250.0*pos.y/10.0) );
	f *= smoothstep( 0.1,0.11, abs(pos.x) ) - smoothstep( 0.85,0.86, abs(pos.x) );
	col *= 1.0-f;

	f = smoothstep( -0.8,-0.2, sin(250.0*pos.y) );
	f *=      smoothstep(-0.1,0.1, sin(250.0*pos.y/10.0) );
	f *= smoothstep( 0.1,0.11, abs(pos.x) ) - smoothstep( 0.85,0.86, abs(pos.x) );
	
	float of = floor(0.5*250.0*pos.y/6.2831);
	float g = 1.0-smoothstep( 0.2,0.3,texture( iChannel0, pos.xy*vec2(0.5,0.01) + 0.15*of).x);
	col *= mix( 1.0, 1.0-g, f );
	
	col *= 0.5 + 0.7*texture( iChannel0, 0.02*pos.xy ).x;
		
    return vec4(col,0.0);
}

vec4 benchColor( in vec3 pos, in vec3 nor )
{
    vec3 col = vec3(0.01,0.01,0.01);
	
	float g = smoothstep( 0.0, 1.0, boxmap( 1.0*pos*vec3(1.0,0.5,1.0), nor ) );
	col = mix( col, vec3(0.021,0.015,0.015), g );

	float f = smoothstep( 0.3, 1.0, boxmap( 16.0*pos*vec3(1.0,1.0,1.0), nor ) );
	col = mix( col, vec3(0.04,0.03,0.02), f );

	return vec4( 0.2*col*vec3(1.3,0.9,1.0), 0.005*(1.0-g) );
}	
		
vec4 calcColor( in vec3 pos, in vec3 nor, float matID, out vec3 bnor )
{
    bnor = vec3(0.0);

	vec4 mate = vec4(0.0);
	     if( matID<0.5 ) mate = vec4(0.22,0.19,0.15,0.2); // white keys
	else if( matID<1.5 ) mate = vec4(0.00,0.00,0.00,0.1); // black keys
	else if( matID<2.5 ) mate = pianoColor(pos,nor);      // piano
	else if( matID<3.5 ) mate = floorColor(pos,bnor);     // floor
	else if( matID<4.5 ) mate = wallColor(pos,nor);       // wall
	else if( matID<5.5 ) mate = paperColor(pos,nor);      // paper
	else if( matID<6.5 ) mate = vec4(0.04,0.03,0.01,0.9); // pedals
	else                 mate = benchColor(pos,nor);      // bench
	return mate;
}

vec2 raycast( in vec3 ro, in vec3 rd )
{
	float maxd = 25.0;
    float t = 0.0;
    float m = -1.0;
    for( int i=0; i<64; i++ )
    {
	    vec2 h = map( ro+rd*t );
	    m = h.y;
        if( abs(h.x)<0.001 || t>maxd ) break;
        t += h.x;
    }

    return (t<maxd) ? vec2( t, m ) : vec2(-1.0);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    const vec3 eps = vec3(0.0002,0.0,0.0);

	return normalize( vec3(
           map(pos+eps.xyy).x - map(pos-eps.xyy).x,
           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

// https://iquilezles.org/articles/rmshadows
float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<45; i++ )
    {
        float h = map(ro + rd*t).x;
        res = min( res, k*h/t);
        t += clamp( h, 0.04, 0.1 );
		if( res<0.01 ) break;
    }
    return smoothstep(0.0,1.0,res);
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<8; i++ )
    {
        float hr = 0.01 + 1.2*pow(float(i)/8.0,1.5);
        vec3 aopos =  pos + nor*hr;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.85;
    }
    return clamp( 1.0 - 0.6*occ, 0.0, 1.0 );
}

float calcEdges( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    for( int i=0; i<4; i++ )
    {
		vec3 aopos = normalize(hash3(float(i)*213.47));
		aopos = aopos - dot(nor,aopos)*nor;
		aopos = pos + aopos*0.5;
        float dd = clamp( map( aopos ).x*10.0, 0.0, 1.0 );
        occ += dd;
    }
	occ /= 4.0;
	
    return smoothstep( 0.5, 1.0, occ );
}

#define ZERO (min(iFrame,0))

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2  mo = iMouse.xy/iResolution.xy;
	float an = 2.0 + 1.5*(0.5+0.5*sin(0.15*iTime - 6.283185*mo.x));
    vec3  ra = 8.0*normalize(vec3(sin(an),0.4-0.3*mo.y, cos(an)));
    vec3  ta = vec3( -1.0, -1.7, 3.0 );
    vec3  ww = normalize( ta - ra );
    vec3  uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3  vv = normalize( cross(uu,ww));

    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 of = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 px = fragCoord+of;
        #else    
        vec2 px = fragCoord;
        #endif
        vec2 p = (2.0*px-iResolution.xy)/iResolution.y;
	
        // camera
        float r2 = p.x*p.x*0.32 + p.y*p.y;
        p *= 0.5 + 0.5*(7.0-sqrt(37.5-11.5*r2))/(r2+1.0);
        vec3 ro = ra;
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

        // render
        vec3 col = vec3(0.0);
        float atten = 1.0;
        for( int k=0; k<2; k++ )
        {
            // raymarch
            vec2 tmat = raycast(ro,rd);
            if( tmat.y>-0.5 )
            {
                // geometry
                vec3 pos = ro + tmat.x*rd;
                vec3 nor = calcNormal(pos);
                vec3 ref = reflect(rd,nor);
                vec3 lig = normalize(vec3(-0.5,2.0,-1.0));
                float edg = calcEdges(pos,nor);
                float occ = calcAO( pos, nor );

                // material
                vec3 bnor = vec3(0.0);
                vec4 mate = calcColor( pos, nor, tmat.y, bnor );
                nor = normalize( nor + bnor );

                if( tmat.y>1.5 && tmat.y<2.5 ) 
                {
                float ru = edg*smoothstep( 0.3, 0.6, 0.1-0.2*occ + boxmap(pos,nor) );
                mate = mix( mate, 0.25*vec4(0.3,0.28,0.2,0.0), ru );
                }

                // lights
                float amb = 0.6 + 0.4*nor.y;
                float dif = max(dot(nor,lig),0.0);
                float spe = pow(clamp(dot(lig,ref),0.0,1.0),3.0);
                float sha = 1.0;

                // window frame shadows
                vec3 win = pos + lig* (-10.0-pos.y)/lig.y;
                win.xz -= vec2(.0,4.0);
                float wpa = pow( pow(abs(win.x),16.0) + pow(abs(win.z),16.0), 1.0/16.0 );
                float wbw = 1.0-smoothstep( 3.0, 6.2, wpa*0.8 );
                float wbg = 1.0-smoothstep( 3.5,14.0, wpa*0.8 );
                wpa *= 1.0-smoothstep( 2.5, 3.5, wpa*0.8 );
                wpa *= smoothstep( 0.1, 0.45, abs(win.x) );
                wpa *= smoothstep( 0.1, 0.45, abs(win.z) );
                sha *= wpa;
                
                // object shadows (only if necessary)
                if( (sha*dif)>0.001 )
                sha *= softshadow( pos, lig, 0.01, 10.0 );
                

                vec3 lin = vec3(0.0);
                lin  = 4.00*dif*vec3(1.5,0.85,0.55)*pow( vec3(sha), vec3(1.0,1.2,1.4) );
                lin += 0.50*wbg*wbw*vec3(1.2,0.6,0.3)*(0.5+0.5*clamp(0.5-0.5*nor.y,0.0,1.0))*pow(1.0-smoothstep(0.0,3.5,3.8+pos.y),2.0)*(0.2+0.8*occ);
                lin += 0.025*wbg*amb*vec3(0.75,0.85,0.9)*(0.1+0.9*occ);
                lin += (1.0-mate.xyz)*0.15*occ*vec3(1.0,0.5,0.1)*clamp(0.5+0.5*nor.x,0.0,1.0)*pow(clamp(0.5*(pos.x-1.5),0.0,1.0),2.0);

                col += atten*mate.xyz*lin;
                col += atten*10.0*mate.w*mate.w*(0.5+0.5*mate.xyz)*spe*sha*occ*vec3(1.0,0.95,0.9);

                atten *= 2.0*mate.w;
                ro = pos + 0.001*nor;
                rd = ref;
            }
        }

        // gain
        col = 1.2*col/(1.0+col);

        // desat
        col = mix( col, vec3(dot(col,vec3(0.33))), 0.3 );

        // gamma
        col = pow( col, vec3(0.45) );
        
	    tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

	// tint
	tot *= vec3(1.0,1.04,1.0);
	
	// vignetting
	vec2 q = fragCoord / iResolution.xy;
	tot *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
	
    fragColor = vec4( tot,1.0 );
}