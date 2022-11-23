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

// 1, 2, 3 or 1
#define QUALITY 1
#define VR

#if QUALITY==1
 #define VIS_SAMPLES 4
 #define LIG_SAMPLES 10
 #define DETAIL_INTER 2
#endif
#if QUALITY==2
 #define VIS_SAMPLES 5
 #define LIG_SAMPLES 12
 #define DETAIL_INTER 2
#endif
#if QUALITY==3
 #define VIS_SAMPLES 8
 #define LIG_SAMPLES 12
 #define DETAIL_INTER 2
#endif
#if QUALITY==4
 #define VIS_SAMPLES 10
 #define LIG_SAMPLES 80
 #define DETAIL_INTER 2
#endif


float hash1( vec2  n ) { return fract(sin(dot(n,vec2(1.0,113.0)))*43758.5453123); }
float hash1( vec3  n ) { return fract(sin(dot(n,vec3(1.0,113.0,257.0)))*43758.5453123); }
vec2  hash2( float n ) { return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123)); }
vec2  hash2( vec2  n ) { return fract(sin(n)*vec2(3758.5453123)); }

float length2( in vec2 v ) { return dot(v,v); }

vec3 path( float t )
{
    t *= 2.0;
    vec2 p  = 100.0*sin( 0.010*t*vec2(1.0,1.2) + vec2(1.5,2.0) );
	     p +=  40.0*sin( 0.017*t*vec2(1.3,1.1) + vec2(3.0,0.0) );	
	return vec3( p.x, 0.0, p.y );
}

// voxel map
float map( vec3 c ) 
{
	vec3 p = c + 0.5;
	
	float h = textureLod( iChannel0, fract(p.xz/iChannelResolution[0].xy), 0.0 ).x;
    
    float dm = 1e10;
    for( int i=0; i<25; i++ )
    {
        vec2 pa = path( 60.0*float(i)/25.0 ).xz;
        dm = min( dm, length2(pa-p.xz) );
    }
    
    float isc = step( sqrt(dm), 5.0 );
    
    h = -10.0 + 16.0*h - 6.0*isc;//*(0.2 + h*2.0);
    
    h += 10.0*smoothstep( 0.9,0.91,textureLod( iChannel2, 0.25*fract(p.xz/iChannelResolution[2].xy), 0.0 ).x)*(1.0-isc);
    
	return h - p.y;
}

// distance field for each voxel
float map2( in vec3 p, in float id )
{
    float w = 0.05 + 0.35*id;
    return length(max(abs(p)-0.5+w,0.0))-w+0.001;
}

vec3 calcNormal( in vec3 pos, in float id )
{
    vec3 eps = vec3(0.01,0.0,0.0);

	return normalize( vec3(
           map2(pos+eps.xyy,id) - map2(pos-eps.xyy,id),
           map2(pos+eps.yxy,id) - map2(pos-eps.yxy,id),
           map2(pos+eps.yyx,id) - map2(pos-eps.yyx,id) ) );
}

float castRay( in vec3 ro, in vec3 rd, out vec3 oVos, out vec3 oDir )
{
	vec3 pos = floor(ro);
	vec3 ri = 1.0/rd;
	vec3 rs = sign(rd);
	vec3 ris = ri*rs;
	vec3 dis = (pos-ro + 0.5 + rs*0.5) * ri;
	float t = -1.0;
	
	vec3 mm = vec3(0.0);
	for( int i=0; i<256; i++ ) 
	{
		if( map(pos)>0.0 ) 
		{ 
            // intersect cube exactly			
			vec3 pr = pos+0.5-ro;
			vec3 mini = (pr-0.5*rs)*ri;
	        float s = max( mini.x, max( mini.y, mini.z ) );

            // raymarch internal shape			
			float id = hash1( pos );
			float h = 0.0;
			h = map2( -pr+rd*s, id ); s += max(0.0,h);
			h = map2( -pr+rd*s, id ); s += max(0.0,h);
			h = map2( -pr+rd*s, id ); s += max(0.0,h);
			h = map2( -pr+rd*s, id ); s += max(0.0,h);
			h = map2( -pr+rd*s, id ); s += max(0.0,h);
			h = map2( -pr+rd*s, id ); s += max(0.0,h);
			if( h<0.025 )
			{
				t = s;
				break; 
			}
		}
		vec3 mi = step( dis.xyz, dis.yzx ); 
		mm = mi*(1.0-mi.zxy);
		dis += mm * ris;
        pos += mm * rs;
        
        if( pos.y>21.0 ) break;
	}

	oDir = mm;
	oVos = pos;

	return t;
}

float castShadowRay( in vec3 ro, in vec3 rd, out vec3 oVos )
{
	vec3 pos = floor(ro);
	vec3 ri = 1.0/rd;
	vec3 rs = sign(rd);
	vec3 dis = (pos-ro + 0.5 + rs*0.5) * ri;
	vec3 ris = ri*rs;
	
	float res = 1.0;

    // detailed raymarching
    
    for( int i=0; i<DETAIL_INTER; i++ ) 
	{
		if( map(pos)>0.0 && i>0 )
		{
            float id = hash1( pos );
            vec3 mini = (pos-ro + 0.5 - 0.5*vec3(rs))*ri;
            float t = max ( mini.x, max ( mini.y, mini.z ) );
            float h = 0.0;
            vec3 ce = pos + 0.5;
            h = map2( ro+rd*t-ce,id ); t += max(0.0,h);
            h = map2( ro+rd*t-ce,id ); t += max(0.0,h);
            h = map2( ro+rd*t-ce,id ); t += max(0.0,h);
            h = map2( ro+rd*t-ce,id ); t += max(0.0,h);
            h = map2( ro+rd*t-ce,id ); t += max(0.0,h);
            h = map2( ro+rd*t-ce,id ); t += max(0.0,h);
            if( h<0.001 )
            {
                return 0.0;
                res=0.0; 
                break; 
			}
		}
		vec3 mi = step( dis.xyz, dis.yzx ); 
		vec3 mm = mi*(1.0-mi.zxy);
		dis += mm * ris;
        pos += mm * rs;
	}
	
    // coarse raymarching

	for( int i=0; i<(16-DETAIL_INTER); i++ ) 
	{
		if( map(pos)>0.0 && i>0 )
		{
            res=0.0; 
            break; 
		}
		vec3 mi = step( dis.xyz, dis.yzx ); 
		vec3 mm = mi*(1.0-mi.zxy);
		dis += mm * ris;
        pos += mm * rs;
	}
	
	oVos = pos;
	
	return res;
}

vec3 getVoxelColor( in vec3 pos )
{
	float id = hash1( pos.xz + 53.123  );
	
	float f = smoothstep( 0.8, 0.801, id );
	f *= smoothstep( 0.6, 0.8, sin(60.0*id + pos.y*0.3 + 2.0*iTime) );
    
	vec3 col = 0.55 + 0.45*sin( 16.0*id + 0.0 + vec3(0.0,0.6,1.5) );
	col = 0.9*normalize(col);	
	return f*col;
}

vec4 texcube( sampler2D sam, in vec3 p, in vec3 n )
{
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

vec3 render( in vec3 ro, in vec3 rd, in float ra )
{
    vec3 col = vec3(0.0);

    // raymarch	
    vec3 vos, dir;
    float t = castRay( ro, rd, vos, dir );
    if( t>0.0 )
    {
        vec3 pos = ro + rd*t;
        float id = hash1( vos );
        vec3 nor = calcNormal( fract(pos)-0.5, id );

        vec3 uvw = pos - vos;

        // lighting
        vec3 lin = vec3(0.0);
        vec3 occ = vec3(0.0);
        vec3 spp = vec3(0.0);
        #if 1
        vec3  ru  = normalize( cross( nor, vec3(0.0,1.0,1.0) ) );
        vec3  rv  = normalize( cross( ru, nor ) );
        for( int j=0; j<LIG_SAMPLES; j++ )
        {
            //vec2  aa = hash2( rr.x + float(j)*203.1 );
            vec2  aa = hash2( ra + float(j)*vec2(201.19,13.75) );
            float ra = sqrt(aa.y);
            float rx = ra*cos(6.2831*aa.x); 
            float ry = ra*sin(6.2831*aa.x);
            float rz = sqrt( 1.0-aa.y );
            vec3  rr = rx*ru + ry*rv + rz*nor;

            vec3 rpo = vec3( 0.0 );
            float sha = castShadowRay( pos, rr, rpo );

            vec3 irr = (1.0-sha) * getVoxelColor( rpo );
            lin += irr;
            spp += irr * pow( clamp( dot(reflect(rd,nor),rr), 0.0, 1.0 ), 12.0 );
            occ += sha;
        }
        float is = 1.0/float(LIG_SAMPLES);
        lin *= is;
        occ *= is;
        spp *= is;
        #else		
        lin = vec3(0.0);
        occ = vec3(1.0) * (0.6 + 0.4*nor.y);
        spp = vec3(0.0);
        #endif		

        // material			
        vec3 mate = getVoxelColor( vos );
        vec3 tex = (0.5+0.5*texture( iChannel0, fract(vos.xz/iChannelResolution[0].xy), -100.0 ).xyz);
        float spe = pow( clamp( -dot(nor,rd), 0.0, 1.0 ), 28.0 );
        
        //
        tex *=  0.15 + 0.85*id;
        tex = mix( tex, vec3(0.0,0.1,0.3)*0.1, step(0.8,id) );
        
        vec3 tt = texcube( iChannel0, 0.5*pos + id*111.143, nor ).xyz;
        tex *= 0.4 + 1.2*tt;

        // final color			
        col = vec3(0.0);
        col += 1.800*mate;
        col += 4.000*lin*(mate+tex);
        col += 0.040*occ*(mate+tex) * 6.0*(0.5+0.5*nor.y) * 0.75;
        col += 70.000*spe*(mate+tex)*lin*occ * 0.6;
        col += spp * 9.0 * (0.2+1.6*tt.x) * occ;
        col *= 1.8;

        // fog			
        float ff = 1.0 - smoothstep( 160.0, 256.0, t*1.73 );
        ff *= exp( -0.01*t );

        col = mix( col, vec3(0.0), 1.0-ff );
    }
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, in float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // inputs	
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 mo = iMouse.xy / iResolution.xy;
    if( iMouse.w<=0.00001 ) mo=vec2(0.0);
	
	// montecarlo	
	vec3 tot = vec3(0.0);
#if VIS_SAMPLES<2
	int a = 0;
	{
		vec4 rr = texture( iChannel1, (iTime*60.0*vec2(7.0,13.0)+fragCoord)/iChannelResolution[1].xy  ).xzyw;
        vec2 p = -1.0 + 2.0*(fragCoord.xy) / iResolution.xy;
#else
	for( int a=0; a<VIS_SAMPLES; a++ )
	{
		vec4 rr = texture( iChannel1, (iTime*60.0*vec2(7.0,13.0)+fragCoord+103.3137*float(a))/iChannelResolution[1].xy  ).xzyw;
        vec2 p = -1.0 + 2.0*(fragCoord.xy+rr.xz) / iResolution.xy;
#endif	

        p.x *= iResolution.x/ iResolution.y;

        float time = iTime + 1.0*(0.5/24.0)*rr.y + 50.0*mo.x;

		// camera
        vec3 ro = path( time );
        vec3 ta = path( time+2.0 );
        #ifndef VR
        ta.y -= 0.5;
        float cr = 0.2*cos(0.09*time);
        #else
        float cr = 0.0;
        #endif
	
        float r2 = p.x*p.x*0.32 + p.y*p.y;
        p *= (7.0-sqrt(37.5-11.5*r2))/(r2+1.0);

        // build ray
        mat3 cam = setCamera( ro, ta, cr );
        vec3 rd = cam * normalize( vec3(p,-3.0) );

        // dof
        #if VIS_SAMPLES>2
        vec3 fp = ro + rd * 8.0;
        //ro += (uu*(-1.0+2.0*rr.x) + vv*(-1.0+2.0*rr.w))*0.02;
        //rd = normalize( fp - ro );
        #endif
		
		vec3 col = render( ro, rd, rr.y );

        tot += col;
	}
	tot /= float(VIS_SAMPLES);
		
	// gamma	
	tot = pow( clamp( tot, 0.0, 1.0 ), vec3(0.45) );

	// vignetting	
	tot *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
	
	fragColor = vec4( tot, 1.0 );
}
    

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
	float ra = texture( iChannel1, (/*vec2(iRands.xy)*/ + iTime*60.0*vec2(7.0,13.0)+fragCoord)/iChannelResolution[1].xy  ).x;
    
    float time = iTime;

    // camera
    vec3 ro = path( time );
    vec3 ta = path( time+2.0 );

    // build ray
 	mat3 cam = setCamera( ro, ta, 0.0 );
   
    ro = ro + cam*fragRayOri;
    vec3 rd = cam*fragRayDir;

    
    vec3 col = render( ro, rd, ra );
		
	// gamma	
	col = pow( clamp( col, 0.0, 1.0 ), vec3(0.45) );

    fragColor = vec4( col, 1.0 );

}