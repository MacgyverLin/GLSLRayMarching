// Copyright Inigo Quilez, 2015 - https://iquilezles.org/
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
//-----------------------------------------------------------------------------------

float hash1( float n ) { return fract(sin(n)*43758.5453123); }

float noise1( in float x )
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix( hash1(p+0.0), hash1(p+1.0), f );
}

//-----------------------------------------------------------------------------------

vec2 sd2Segment( vec3 a, vec3 b, vec3 p )
{
	vec3  pa = p - a;
	vec3  ba = b - a;
	float t = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	vec3  v = pa - ba*t;
	return vec2( dot(v,v), t );
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

//-----------------------------------------------------------------------------------

vec3 fishPos;
float fishTime;

vec3 sdFish( vec3 p )
{
    vec3 res = vec3( 1000.0, 0.0, 0.0 );

	p -= fishPos;
	
	if( dot(p,p)>16.0 ) return vec3(5.0);

	p *= vec3(1.2,0.8,1.2);
	vec3 q = p;
	
    vec3 a = vec3(0.0,0.0,0.0);
	
    
    a.x -= 0.25*sin(8.0*0.2*fishTime);
	vec3 oa = a;

	float or = 0.0;
	float th = 0.0;
	float hm = 0.0;

	#define NUMI 7
	#define NUMF 7.0
	vec3 p1 = a; vec3 d1=vec3(0.0);
	vec3 p2 = a; vec3 d2=vec3(0.0);
	vec3 mp = a;
	for( int i=0; i<NUMI; i++ )
	{	
		float ih = float(i)/NUMF;
		
		float an = or + 1.0*(0.2+0.8*ih)*sin(3.0*ih - 2.0*fishTime);
		float ll = 0.26;
		if( i==(NUMI-1) ) ll=0.4;
		vec3 b = a + ll*vec3(sin(an), 0.0, cos(an))*(16.0/NUMF);
		
		vec2 dis = sd2Segment( a, b, p );

		if( dis.x<res.x ) {res=vec3(dis.x,ih+dis.y/NUMF,0.0); mp=a+(b-a)*dis.y; }
		
		if( i==1 ) { p1=a; d1 = b-a; }
		
		a = b;
	}
	float h = res.y;
	float ra = 0.04 + h*(1.0-h)*(1.0-h)*2.7;

	// tail
	p.y /= 1.0 + 14.0*(1.0-smoothstep( 0.0, 0.13, 1.0-h));
    p.z += 0.08*(1.0-clamp(abs(p.y)/0.075,0.0,1.0))*(1.0-smoothstep( 0.0,0.1,1.0-h));
	res.x = 0.75 * (distance(p,mp) - ra);
	
	// mouth
	float d3 = 0.75*(length( (p - oa)*vec3(0.5,2.0,1.0) )-0.12);
	res.x = max( -d3, res.x );
	
	// upper central fin
	float fh = smoothstep(0.15,0.2,h) - smoothstep(0.25,0.8,h);
	fh -= 0.2*pow(0.5+0.5*sin(210.0*h),0.2)*fh;
	d3 = length(p.xz-mp.xz) - 0.01;
    d3 = max( d3, p.y - (mp.y+ra+0.2*fh) );
	d3 = max( d3, -p.y - 0.0 );
	res.x = min( res.x, d3 );
	
	// fins
	d1.xz = normalize(d1.xz);

	float flap = 0.7 + 0.3*sin(2.0*8.0*0.2*fishTime);
    vec2 dd = normalize(d1.xz + sign((p-p1).x)*flap*d1.zx*vec2(-1.0,1.0));
	mat2 mm = mat2( dd.y, dd.x, -dd.x, dd.y );
	vec3 sq = p-p1;
	sq.xz = mm*sq.xz;
	sq.y += 0.2;
	sq.x += -0.15;
	float d = length( (sq-vec3(0.5,0.0,0.0))*vec3(1.0,2.0,1.0) ) - 0.3;
	d = 0.5*max( d, sdBox( sq, vec3(1.0,1.0,0.01) ) );
    if( d<res.x ) res.z = smoothstep( 0.2, 0.7, sq.x );
	res.x = smin( d, res.x, 0.05 );

	sq = p-p1;
	sq.xz = mm*sq.xz;
	sq.y += 0.2;
	sq.x += 0.15;
	d = length( (sq-vec3(-0.5,0.0,0.0))*vec3(1.0,2.0,1.0) ) - 0.3;
	d = 0.5*max( d, sdBox( sq, vec3(1.0,1.0,0.01) ) );
    if( d<res.x ) res.z = smoothstep( 0.2, 0.7, sq.x );
	res.x = smin( d, res.x, 0.05 );

	return res;

}

vec3 sdSeaBed( in vec3 p )
{
	float h = 1.0;
	vec3 q = p;
	float th = smoothstep( 0.1, 0.4, textureLod( iChannel0, 0.002*q.xz, 0.0 ).x );
    float rr = smoothstep( 0.2, 0.5, textureLod( iChannel1, 2.0*0.02*q.xz, 0.0 ).y );
	h = 0.9 + (1.0-0.6*rr)*(1.5-1.0*th) * 0.1*(1.0-textureLod( iChannel0, 0.1*q.xz, 0.0 ).x);
	h += th*1.25;
    h -= 0.24*rr;
	h *= 0.75;
    return vec3( (p.y+h)*0.3, p.x, 0.0 );

}

vec4 map( in vec3 p )
{
    vec4 d1 = vec4( sdSeaBed(p), 0.0 );
	vec4 d2 = vec4( sdFish(p), 1.0 ); 
    return (d2.x<d1.x)?d2:d1;
}

vec4 intersect( in vec3 ro, in vec3 rd )
{
	const float maxd = 20.0;
	const float precis = 0.001;
    float h = precis*3.0;
    float t = 0.0;
    float m = 0.0;
	float l = 0.0;
	float r = 0.0;
    for( int i=0; i<80; i++ )
    {
	    vec4 res = map( ro+rd*t );
        if( h<precis || t>maxd ) break;
        h = res.x;
		l = res.y;
		r = res.z;
        m = res.w;			
		t += h;
    }

    if( t>maxd ) m=-1.0;
    return vec4( t, l, m, r);
}

vec3 calcNormal( in vec3 pos, in float e )
{
    vec3 eps = vec3(e,0.0,0.0);
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
    for( int i=0; i<40; i++ )
    {
        h = map(ro + rd*t).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
		t += clamp( h, 0.05, 0.5 );
		if( h<0.0001 ) break;
    }
    return clamp(res,0.0,1.0);
}

vec3 lig = normalize(vec3(0.9,0.35,-0.2));

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
	
	fishTime = iTime + 3.5*noise1(0.2*iTime);

	fishPos = vec3( 0.0, 0.0, -0.7*fishTime );
	
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

	float an = 1.5 + 0.1*iTime - 12.0*(m.x-0.5);

	vec3 ta = fishPos - vec3(0.0,0.0,-2.0);//vec3(0.0,1.0,2.0);
	vec3 ro = ta + vec3(4.0*sin(an),4.0,4.0*cos(an));

    // shake
	ro += 0.01*sin(4.0*iTime*vec3(1.1,1.2,1.3)+vec3(3.0,0.0,1.0) );
	ta += 0.01*sin(4.0*iTime*vec3(1.7,1.5,1.6)+vec3(1.0,2.0,1.0) );

    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
	
	// create view ray
    p.x += 0.012*sin( 3.0*sin(4.0*p.y+0.5*iTime) + 4.0*p.x + 0.5*iTime );
	vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = vec3(0.4,0.6,0.8);
	vec3 bcol = col;
	
	float pt = (1.0-ro.y)/rd.y;
	
	vec3 oro = ro;
	if( pt>0.0 ) ro=ro+rd*pt;
	
	// raymarch
    vec4 tmat = intersect(ro,rd);
    if( tmat.z>-0.5 )
    {
		float eps = 0.01 + 0.03*step(0.5,tmat.z);
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos,eps);
		vec3 ref = reflect( rd, nor );

        // materials
		vec4 mate = vec4(0.5,0.5,0.5,0.0);
		
		if( tmat.z<0.5 )
		{
			vec3 te = texture( iChannel0, 0.1*pos.xz ).xyz;
			te = 0.05 + te;
			
			mate.xyz = 0.6*te;
			mate.w = 5.0*(0.5+0.5*te.x);
			
				
			float th = smoothstep( 0.1, 0.4, texture( iChannel0, 0.002*pos.xz ).x );
			vec3 dcol = mix( vec3(0.1, 0.1, 0.0), 0.4*vec3(0.65, 0.4, 0.2), 0.2+0.8*th );

			mate.xyz = mix( mate.xyz*0.5, dcol, th*smoothstep( 0.0, 1.0, nor.y ) );

			float rr = smoothstep( 0.2, 0.4, texture( iChannel1, 2.0*0.02*pos.xz ).y );
			mate.xyz *= mix( vec3(1.0), vec3(0.2,0.2,0.2)*1.5, rr );
			
			mate.xyz *= 1.5;
		}
		else
		{
			mate.w = 8.0;
			mate.xyz = 1.0*vec3(0.24,0.17,0.22);

			vec3 te = 0.8+2.2*texture( iChannel0, vec2(2.0*tmat.y,pos.y) ).xyz;
			mate.xyz *= te;
			
			// belly/backfin
			float iscola = smoothstep( 0.0, 0.2, 1.0-tmat.y );
			mate.xyz = mix( mate.xyz, mix(vec3(te.x*0.5 + 1.5),
										  mix(1.0+0.5*sin(150.0*pos.y - sign(pos.y)*tmat.y*300.0),1.0,smoothstep( 0.0, 0.1, 1.0-tmat.y ))*vec3(2.6,1.5,1.0)*0.9 + 1.0*vec3(2.0,1.0,0.5)*(1.0-smoothstep( 0.0, 0.09, 1.0-tmat.y )),
										  1.0-iscola)*0.5, smoothstep(-0.4,0.0,-nor.y) );
			
			// stripes
			mate.xyz = mix( mate.xyz, (te.x+0.5)*1.0*vec3(0.5), 0.75*smoothstep( 0.5, 1.0, sin(1.0*te.x+tmat.y*100.0 + 13.0*nor.y) )*smoothstep(0.0,0.5,nor.y) );

			// escamas
			float ll = clamp( (tmat.y-0.2)/(0.8-0.2), 0.0, 1.0 );
			float ha = 1.0-4.0*ll*(1.0-ll);
			float pa = smoothstep( -1.0+2.0*ha, 1.0, sin( 50.0*pos.y ) )* smoothstep( -1.0, 0.0, sin( 560.0*tmat.y ) );
			pa *= 1.0-smoothstep( 0.1, 0.2, nor.y );
			mate.xyz *= 0.5 + 0.5*vec3(1.0) * (1.0-pa);
			
			// eye
			float r = length(vec2(5.0*tmat.y,pos.y)-vec2(0.5,0.13) );
			r /= 1.2;
			mate.xyz = mix( mate.xyz, vec3(1.5)*clamp(1.0-r*4.0,0.0,1.0), 0.5*(1.0-smoothstep(0.08,0.09,r)) );
			mate.xyz *= smoothstep(0.03,0.05,r);
			mate.xyz += vec3(4.0)*(1.0-smoothstep(0.0,0.1,r))*pow( texture( iChannel1, 4.0*vec2(0.2*fishPos.z+4.0*tmat.y,pos.y) ).x, 2.0 );
			r = length(vec2(5.0*tmat.y,pos.y)-vec2(0.48,0.14) );
			mate.xyz = mix( mate.xyz, vec3(2.0), (1.0-smoothstep(0.0,0.02,r)) );
			
			// mouth
			vec3 oa = fishPos;
	        oa.x -= 0.25*sin(8.0*0.2*fishTime);
			mate.xyz *= 0.1 + 0.9*step( 0.0, length( (pos - oa+vec3(0.0,0.0,-0.02))*vec3(1.5,2.0,1.0) ) - 0.14 );
			
			// top fin
	        float fh = smoothstep(0.15,0.2,tmat.y) - smoothstep(0.25,0.8,tmat.y);
	        float ra = 0.04 + tmat.y*(1.0-tmat.y)*(1.0-tmat.y)*2.7;
			float vv = clamp((pos.y-ra-0.1)/0.2,0.0,1.0);
			vec3 fincol = mix(1.0+0.5*sin(520.0*tmat.y),1.0,vv)*mix(vec3(0.8,0.2,0.2),vec3(1.5,1.4,1.5),vv);
            mate.xyz = mix( mate.xyz, fincol, fh*smoothstep(0.0,0.05,pos.y-ra-0.1) );
			
			// side fins
			float isFin = tmat.w;
			fincol = 0.5*vec3(3.0,2.0,2.0) * mix(1.0+0.2*sin(150.0*pos.y),1.0,0.0);
            mate.xyz = mix( mate.xyz, fincol, isFin );
			
			mate.xyz *= 0.17;
		}
		
		// lighting
        float sky = clamp(nor.y,0.0,1.0);
		float bou = clamp(-nor.y,0.0,1.0);
		float dif = max(dot(nor,lig),0.0);
        float bac = max(0.3 + 0.7*dot(nor,-vec3(lig.x,0.0,lig.z)),0.0);
		float sha = 0.0; if( dif>0.001 ) sha=softshadow( pos+0.01*nor, lig, 0.0005, 32.0 );
        float fre = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 5.0 );
        float spe = max( 0.0, pow( clamp( dot(lig,reflect(rd,nor)), 0.0, 1.0), mate.w ) ) * mate.w;
		float sss = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 3.0 );
		
		// lights
		vec3 lin = vec3(0.0);
		float cc  = 0.55*texture( iChannel2, 1.8*0.02*pos.xz + 0.007*iTime*vec2( 1.0, 0.0) ).x;
		      cc += 0.25*texture( iChannel2, 1.8*0.04*pos.xz + 0.011*iTime*vec2( 0.0, 1.0) ).x;
		      cc += 0.10*texture( iChannel2, 1.8*0.08*pos.xz + 0.014*iTime*vec2(-1.0,-1.0) ).x;
		cc = 0.6*(1.0-smoothstep( 0.0, 0.025, abs(cc-0.4))) + 
			 0.4*(1.0-smoothstep( 0.0, 0.150, abs(cc-0.4)));
		dif *= 1.0 + 2.0*cc;

		lin += 3.5*dif*vec3(1.00,1.00,1.00)*sha;
		lin += 3.0*sky*vec3(0.10,0.20,0.35);
		lin += 1.0*bou*vec3(0.20,0.20,0.20);
		lin += 2.0*bac*vec3(0.50,0.60,0.70);
        lin += 2.0*sss*vec3(0.20,0.20,0.20)*(0.2+0.8*dif*sha)*mate.w;
		lin += 2.0*spe*vec3(1.0)*sha*(0.3+0.7*fre);
		
		// surface-light interacion
		col = mate.xyz * lin;

		// fog
		tmat.x = max(0.0,tmat.x-1.3); col *= 0.65;
		float hh = 1.0-exp(-0.2*tmat.x); 
		col = col*(1.0-hh)*(1.0-hh) + 1.25*vec3(0.0,0.12,0.2)*hh;
	}
	
    // foam	
	vec2 uv = (oro + rd*pt).xz;
	float sur = texture( iChannel3, 0.06*uv ).x;
	sur = smoothstep( 0.5, 1.0, sur )*0.5 + 0.5*sur*sur*smoothstep(0.2,1.0,texture( iChannel2, 1.0*uv ).x);
	col = mix( col, vec3(1.0), 0.5*sur );

	// sun specular
	float sun = clamp( dot(lig, reflect( rd, vec3(0.0,1.0,0.0) ) ), 0.0, 1.0 );
	col += 0.2*vec3(1.0,0.95,0.9)*pow(sun,16.0);
	col += 0.5*vec3(1.0,0.95,0.9)*pow(sun,96.0);

	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------

	col = pow( clamp(col,0.0,1.0), vec3(0.45) );

    col = mix( col, vec3(dot(col,vec3(0.333))), -0.5 );
	
	col = 0.5*col + 0.5*col*col*(3.0-2.0*col);
	
	col *= 0.2 + 0.8*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
	
	col *= smoothstep( 0.0, 1.0, iTime );
	
	fragColor = vec4( col, 1.0 );
}
