// Created by Hsiang Yun 2016 
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// This shader is inspired by the leaf in https://www.shadertoy.com/view/ld3Gz2  (iq's Snail)


/***************************
		Utility
****************************/

float rand(float id){
    return fract(sin(id * 37.0) * 43758.5453);
}

float smin( float a, float b, float k )
{
  	float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax ( float a, float b, float k )
{
    return -smin(-a,-b, k);
}

float sub ( float a , float b )
{
    return smax(-b, a, 0.10);
}
vec2 rot ( vec2 p, float a ) 
{
    a = radians(a);
    float s = sin(a);
    float c = cos(a);
    return mat2(vec2(c, s), vec2( -s, c )) * p; 
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 ) 
{
    float a =     det(b0,b2);
    float b = 2.0*det(b1,b0);
    float d = 2.0*det(b2,b1);
    float f = b*d - a*a;
    vec2  d21 = b2-b1;
    vec2  d10 = b1-b0;
    vec2  d20 = b2-b0;
    vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
    vec2  pp = -f*gf/dot(gf,gf);
    vec2  d0p = b0-pp;
    float ap = det(d0p,d20);
    float bp = 2.0*det(d10,d0p);
    float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
    return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}

vec4 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p )
{
	vec3 w = normalize( cross( c-b, a-b ) );
	vec3 u = normalize( c-b );
	vec3 v = normalize( cross( w, u ) );

	vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
	vec2 b2 = vec2( 0.0 );
	vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
	vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

	vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

	return vec4( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z, length(cp.xy), p3.z );
}

float sdEllipse( vec2 p, vec2 r ) 
{
    return ( length(p/r) - 1.0 ) * min(r.x,r.y);
}

/***************************
		Global
****************************/
#define INF 1.0e38
struct Hit
{
    float d;
    float mID;
    vec3 diff;
    float thickness;
};

float leafID;
vec3 darkgreen = vec3 ( 0.2,0.8,0.05) *0.02;
vec3 yellow = vec3 ( 0.8,0.8,0.2)*0.04;
vec3 leafClr()
{
    if ( leafID < 0.5 )
        return darkgreen;
    else if (leafID < 1.5 )
        return darkgreen.yxz;
    else if (leafID < 2.5 )
        return darkgreen.zxy;
    return yellow;
}
vec3 edgeClr()
{
    return yellow;
}

/***************************
	Alocasia Modeling
****************************/
vec2 sdVeins ( in vec3 p, in float rot_a, vec2 w, vec3 range, vec2 yoff, vec2 cnt_) 
{
    float cntR = cnt_.x;
    float cntL = cnt_.y;
    float cnt = (p.x> 0.0) ? cntR : cntL;
    float yoffsetR = yoff.x;
    float yoffsetL = yoff.y;
    float w2 = 0.01;
    vec3 q = p ;
    // stem 
    float dStem = abs(p.x) - w.x;
    // offset & mirror
    p.y += ( p.x > 0.0 ) ? yoffsetR : yoffsetL;
    p.x = abs(p.x);    
    q.x = abs(q.x);
    // rotate
    p.xy = rot ( p.xy, rot_a);
    q.xy = rot ( q.xy, rot_a);
    // repeat
    p.y = sin (cnt* p.y) / cnt;
    
    float dVeins = abs(p.y) - 0.0005;
    float dVeinRange = abs ( q.y + range.x  ) - range.y ;
    // intersetion with range
    dVeins = max ( dVeins, dVeinRange  ) ;
    dVeins = smin ( dVeins, dStem, 0.01);
    return vec2(dVeins, w.y);
}


Hit sdLeaf ( in vec3 p, float rbias ) 
{
    vec3 q = p;
    float a = atan ( p.y, p.x ) ;
    
    // sharpen the heart shape
    p.x = 1.1 * p.x * exp( -0.4*((p.y)));
    float r = 1.0 - sin ( a ) ;  r += rbias;
    
    // veins 
  	vec2 dVeins = sdVeins( p,28.0,  vec2(0.02,0.01), vec3(0.75,0.55,0.0), vec2(0.4,0.43), vec2(15.0,15.0));
    vec3 p1 = p;
    p1.x = abs(p1.x);
    p1.y +=0.4;
    p1.xy = rot(p1.xy,-110.0);
    vec2 dVeins2 = sdVeins (p1, 42.0, vec2(0.005,0.01),vec3(0.8,0.7,0.1), vec2(0.0,0.03), vec2(20.0,15.0) );

    vec3 p0 = p; 
    p.z += (1.0-smoothstep ( 0.0, 0.1, dVeins.x)) * 0.01; 
    p.z += (1.0-smoothstep ( 0.0, 0.05, dVeins2.x)) * 0.0025; 
   
    // domain operation  
    float dheart = length ( p ) -r ;
    float mID = (p.z > 0.0) ? 1.5 : 0.5;
    float dslab = abs(p.z) - 0.02;
    float dhole = sdEllipse ( q.xy + vec2(0,-0.3), vec2(0.05,0.4));
    float d = dheart ;
    d = smax( d, dslab, 0.4);
    d = sub ( d, dhole);   
      
    // vein material
    float mVein1 = (1.0-smoothstep ( 0.0, dVeins.y, dVeins.x));
    float mVein2 = (1.0-smoothstep ( 0.0, dVeins2.y, dVeins2.x));
    float mVein = max ( mVein1, mVein2);
   	// leaf material 
    vec3 mat = mix( leafClr(), edgeClr() , smoothstep(-0.5 ,0.0, dheart )) ;
    // final material  
    mat += yellow * mVein * (1.0-smoothstep(-1.0,-0.25, dheart));
    
    // material stuff
    Hit hit;
    hit.d = d;
    hit.mID = mID;
    hit.diff = (mID > 1.0 ) ? mat :  mix( mix(edgeClr()*5.0,leafClr()*5.0,0.7), leafClr()*5.0 , smoothstep(-0.9 ,0.0, dheart ));;
    hit.thickness = mVein * (1.0-clamp(smoothstep(-1.0,-0.35, dheart),0.0,1.0));
 	return hit;
}

Hit sdDistortLeaf ( vec3 p ) 
{
    // scale 
    p *= 0.45;
    // bias
    p.y -= 0.4;
    p.z -= length(p.xy) *0.3 ;
    p.z += 0.1;
    // z vibration around the edge
    vec3 q = p;
    if ( q.x < 0.0 ) q.y-= 0.2;
    q.x = abs(p.x);
    float w = smoothstep(0.3,1.0, -q.y ) ; 
    q.xy = rot (q.xy, 30.0);
    p.z += w * 0.1* sin(30.0*q.y*(1.0+q.y))* abs(p.x*p.x*p.x*q.x);
  
    // r vibration 
    vec3 v = q - vec3(0.0,-0.6,0.0);
    float a2 = atan ( v.y, v.x);
    float rbias = 0.04 * cos ( 22.0*a2);
    // alocasia shape 
    return sdLeaf( p, rbias)   ;    
}

Hit sdStem ( in vec3 p, vec3 a, vec3 b, vec3 c )
{
    float d = sdBezier( a, b, c, p ).x;
    d = abs(d) - mix(0.08, 0.1, clamp(-p.y,0.0,1.0));
	Hit hit;
    hit.d = d ;
    hit.mID = 2.5;
    vec3 yellow = vec3 ( 0.8,0.8,0.2)*0.08;
    hit.diff = yellow ;
    hit.thickness = 1.0;
    return hit;
}

Hit sdAlocasia( in vec3 p, vec3 a, vec3 b, vec3 c, float leaf_rot )
{
    // translate the leaf to the top of the stem
    vec3 offset =  a ;
    vec3 q = p ;
   	q = q - offset; 
    q.yz = rot (q.yz, leaf_rot) ;
    
    Hit hitA = sdDistortLeaf ( q  ) ; 
    Hit hitB = sdStem ( p, a, b,c ) ;
    Hit hit = hitA;
    if ( hitB.d < 0.0001 ) hit = hitB;
    hit.d = min ( hitA.d, hitB.d ) ;
    return hit;
}

Hit sdGround ( in vec3 p)
{
    Hit hit;
    hit.d = p.y - 0.3;
    hit.mID = 1.5;
    hit.diff = texture ( iChannel0 ,p.xz*0.05).xyz*0.2;
    hit.thickness = 1.0;
    return hit;
}

Hit sdScene ( in vec3 p )
{
    Hit h_grnd = sdGround ( p ) ;
    
    leafID = 0.0;    
    if ( p.z > 0.0 )
    {
        p *= 0.9;
        leafID = 0.0;
        if (p.x > 0.0 )
        {
            leafID = 1.0;
        }
    }
    else
    {
        leafID = 2.0;
        if (p.x > 0.0 )
        {
            p *= 0.85;
            leafID = 3.0;
        }
    }
    float heightBais = rand( leafID + 5.0 ) * 4.0;
    float sideBias = rand( leafID + 1.0 )* 1.5 +2.5; 
    vec3 a = vec3(0.0, 4.0+heightBais,sideBias);
    vec3 b = vec3(0.0, 2.0+heightBais,sideBias * 0.1); 
    vec3 c = vec3(0.0, 0.0,0.0);    
    p.x = abs(p.x);  
	p.z = abs(p.z);
    p.xz = rot(p.xz, 40.0);
    Hit h = sdAlocasia ( p, a, b, c, mix ( 30.0,40.0, rand(leafID))) ;
    
    
    h.d = min ( h.d, h_grnd.d ) ;
    if ( abs(h_grnd.d) < 0.001 )  return h_grnd;
    return h;
}

/***************************
		render
****************************/

Hit getMaterial( in vec3 p ) 
{
    return sdScene ( p ); 
}

float map( in vec3 p )
{
    return sdScene ( p ).d ;     
}

float raymarch( in vec3 ro, in vec3 rd )
{
	const float maxd = 50.0;          
	const float precis = 0.0001;      
    float h = precis*2.0;
    float t = 0.00;
	float res = INF;
    for( int i=0; i<90; i++ )         
    {
        //if( h<precis||t>maxd ) break;
	    h = map( ro+rd*t );
        t += h;
    }
    if( t<maxd ) res = t;
    return res;
}


vec3 calcNormal( in vec3 pos )
{
    const float eps = 0.001;            
    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);
	return normalize( v1*map( pos + v1*eps ) + 
					  v2*map( pos + v2*eps ) + 
					  v3*map( pos + v3*eps ) + 
					  v4*map( pos + v4*eps ) );
}

float softshadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.0001;                 
	float h = 1.0;
    for( int i=0; i<20; i++ )         
    {
        h = map(ro + rd*t);
        res = min( res, 32.0*h/t );   
		t += clamp( h, 0.02, 2.0 );
    }
    return clamp(res,0.0,1.0);
}

vec3 getLightPos()
{
    float t = iTime;
    return vec3(5.0*sin(t)*1.0,15.0+ 0.1*sin(t),cos(t)*5.0);
}

vec3 doLighting( in vec3 pos, in vec3 nml, in vec3 rd, in float dis, in Hit hit )
{
    vec3 lin = vec3(0.0);
    // ambient 
    lin += vec3(0.5);  
    // lighting factors
    vec3 ldir = normalize( getLightPos());    
    vec3 hal = normalize( ldir -rd );
    float fre = clamp(1.0+dot(nml,rd), 0.0, 1.0 );
    float ndl = dot( nml, ldir ) ;
    float dif = max(ndl,0.0);
    float spe1 = clamp( dot(nml,hal), 0.0, 3.0 );
    // shadow 
    float sha = 0.0; 
    if( dif>0.01 ) sha= softshadow( pos+0.01*nml, ldir );
    // simple lighiting
    lin += pow( spe1, 1.0  + 5.0) * vec3(0.0);
    lin += pow( fre,3.0) * dif * vec3(15.0) ;   
    lin += dif * vec3(7.00)*sha;
    
    vec3 col = vec3(0.0);
    col = hit.diff*lin;
    
    // leaf backface lighting 
    // http://http.developer.nvidia.com/GPUGems3/gpugems3_ch16.html
    if (hit.mID < 1.0)
    {       
	    float edl = clamp(dot (rd, ldir), 0.0, 1.0);
	    edl *= edl;     
    	lin +=  mix ( edl, -ndl, 0.1) *10.0* (1.0-hit.thickness);
       	col = hit.diff * lin;
    }
    // fog
	col *= exp(-0.01*dis*dis);

    return col;
}


mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/iResolution.y;
    vec2 m = iMouse.xy/iResolution.xy;
    // camera 
    vec3 ro, ta;
    float an = 0.3*iTime + 5.0*m.x;
    float r = 10.0;
	ro = vec3(r*sin(an), 3.0 +3.0* m.y,r*cos(an));
    ta = vec3(0.0,6.0,0.0);    
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  
	vec3 rd = normalize( camMat * vec3(p.xy,1.0) ); 
    
	vec3 col = vec3 (0.0);
	// raymarch
    float d  = raymarch( ro, rd );
    if( d != INF )
    {
        float t = d;
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);
        col = doLighting( pos, nor, rd, t,  getMaterial ( pos ) );        
	}
    // sprite
    vec3 ldir = normalize(getLightPos());
    float lsprite =  clamp(pow (dot ( normalize(getLightPos()- ro), rd )*0.5+0.5, 128.0),0.0, 10.0);
    lsprite = smoothstep(0.98,1.0, lsprite);
	col += lsprite* lsprite;

    // gamma
	col = pow( clamp(col,0.0,1.0), vec3(0.4545) );	   
    fragColor = vec4( col, 1.0 );
}
