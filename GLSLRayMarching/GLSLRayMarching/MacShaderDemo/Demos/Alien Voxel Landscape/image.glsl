//------------------------------------------------------------------------
// Alien Voxel Landscape
// by @BradyInstead
//------------------------------------------------------------------------

// based on https://iquilezles.org/articles/voxellines

//------------------------------------------------------------------------
// Camera
//------------------------------------------------------------------------

void doCamera( out vec3 camPos, out vec3 camTar, in float time)
{
    float zoom = 50.;
    vec3 initPos = vec3(zoom);
	camPos = initPos;
    camPos.z += iTime*16.; // movement
    camTar = camPos-initPos;
}


//------------------------------------------------------------------------
// Background 
//------------------------------------------------------------------------

vec3 doBackground( void )
{
    return vec3( 0.);
}


//------------------------------------------------------------------------
// Shaping 
//------------------------------------------------------------------------

// p = positions
// h = dimensions of elongation
vec4 opElongate( in vec3 p, in vec3 h )
{
    vec3 q = abs(p)-h;
    return vec4( max(q,0.0), min(max(q.x,max(q.y,q.z)),0.0) );
}

float opSmoothUnion( float d1, float d2, float k )
{
	float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
	return mix( d2, d1, h ) - k*h*(1.0-h);
}


//------------------------------------------------------------------------
// Modelling 
//------------------------------------------------------------------------

float noise( vec3 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Value3D.glsl

    // establish our grid cell and unit position
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    vec3 Pf_min1 = Pf - 1.0;

    // clamp the domain
    Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
    vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

    // calculate the hash
    vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    vec2 hash_mod = vec2( 1.0 / ( 635.298681 + vec2( Pi.z, Pi_inc1.z ) * 48.500388 ) );
    vec4 hash_lowz = fract( Pt * hash_mod.xxxx );
    vec4 hash_highz = fract( Pt * hash_mod.yyyy );

    //	blend the results and return
    vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
    vec4 res0 = mix( hash_lowz, hash_highz, blend.z );
    vec4 blend2 = vec4( blend.xy, vec2( 1.0 - blend.xy ) );
    return dot( res0, blend2.zxzx * blend2.wwyy );
}

float mapTerrain( vec3 p )
{
    p*=.35;
    p.y /= 2.;
	return noise(p);
}

float map(in vec3 p)
{
	float terrain = mapTerrain( p ) + 0.12*p.y;
	return step( terrain, 0.95 );
}


//------------------------------------------------------------------------
// Material
//------------------------------------------------------------------------

vec3 doMaterial( vec3 pos, vec3 vos )
{
    float h = vos.y/8.;
    
    vec3 primary = vec3(.9, .1, .2) ;
    vec3 secondary = vec3(.1, .5, 1.);
    
    return mix(primary, secondary, h)*h;
}

vec3 saturation(vec3 rgb, float adjustment)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

float maxcomp( in vec4 v )
{
    return max( max(v.x,v.y), max(v.z,v.w) );
}

float isEdge( in vec2 uv, vec4 va, vec4 vb, vec4 vc, vec4 vd )
{
    vec2 st = 1.0 - uv;

    // edges
    vec4 wb = smoothstep( 0.7, 0.99, vec4(uv.x,
                                           st.x,
                                           uv.y,
                                           st.y) ) * ( 1.0 - va + va*vc );
    // corners
    vec4 wc = smoothstep( 0.7, 0.99, vec4(uv.x*uv.y,
                                           st.x*uv.y,
                                           st.x*st.y,
                                           uv.x*st.y) ) * ( 1.0 - vb + vd*vb );
    return 1.0 - maxcomp( max(wb,wc) );
}

float calcOcc( in vec2 uv, vec4 va, vec4 vb, vec4 vc, vec4 vd )
{
    vec2 st = 1.0 - uv;

    // edges
    vec4 wa = vec4( uv.x, st.x, uv.y, st.y ) * vc;

    // corners
    vec4 wb = vec4(uv.x*uv.y,
                   st.x*uv.y,
                   st.x*st.y,
                   uv.x*st.y)*vd*(1.0-vc.xzyw)*(1.0-vc.zywx);
    
    return wa.x + wa.y + wa.z + wa.w +
           wb.x + wb.y + wb.z + wb.w;
}

vec3 doLighting( in vec3 pos, in vec3 nor, in vec3 rd, in float dis, in vec3 mal , vec3 vos, vec3 dir)
{
    vec3 uvw = pos - vos;
    
    vec3 v1  = vos + nor + dir.yzx;
	vec3 v2  = vos + nor - dir.yzx;
	vec3 v3  = vos + nor + dir.zxy;
	vec3 v4  = vos + nor - dir.zxy;
	vec3 v5  = vos + nor + dir.yzx + dir.zxy;
    vec3 v6  = vos + nor - dir.yzx + dir.zxy;
	vec3 v7  = vos + nor - dir.yzx - dir.zxy;
	vec3 v8  = vos + nor + dir.yzx - dir.zxy;
	vec3 v9  = vos + dir.yzx;
	vec3 v10 = vos - dir.yzx;
	vec3 v11 = vos + dir.zxy;
	vec3 v12 = vos - dir.zxy;
 	vec3 v13 = vos + dir.yzx + dir.zxy; 
	vec3 v14 = vos - dir.yzx + dir.zxy;
	vec3 v15 = vos - dir.yzx - dir.zxy;
	vec3 v16 = vos + dir.yzx - dir.zxy;

	vec4 vc = vec4( map(v1),  map(v2),  map(v3),  map(v4)  );
	vec4 vd = vec4( map(v5),  map(v6),  map(v7),  map(v8)  );
	vec4 va = vec4( map(v9),  map(v10), map(v11), map(v12) );
	vec4 vb = vec4( map(v13), map(v14), map(v15), map(v16) );
		
	vec2 uv = vec2( dot(dir.yzx, uvw), dot(dir.zxy, uvw) );
    
    // ambient occlusion
    float occ = 1.0;
    occ = calcOcc( uv, va, vb, vc, vd );
    float ocAm = 3.0;
    occ = 1.0 - occ/ocAm;
    occ = pow(occ, 5.);
    
    // fake lighting
    vec3 norC = abs(nor);
    float sum = min(1.0, norC.g + norC.r*.35 + norC.b*.2 + .05);
    vec3 col = mal*sum*isEdge(uv, va, vb, vc, vd);
    
    col = mix(col.rgb*occ, vec3(col.rg*occ, col.b), .2);
    
    return col;
}


//------------------------------------------------------------------------
// Raymarching
//------------------------------------------------------------------------

float calcIntersection( in vec3 ro, in vec3 rd, out vec3 oVos, out vec3 oDir, out int mat )
{
	vec3 pos = floor(ro);
	vec3 ri = 1.0/rd;
	vec3 rs = sign(rd);
	vec3 dis = (pos-ro + 0.5 + rs*0.5) * ri;
	
	float res = -1.0;
	vec3 mm = vec3(0.0);
	for( int i=0; i<200; i++ ) 
	{
		if( map(pos)>0.5 ) { res=1.0; break; }
		mm = step(dis.xyz, dis.yzx) * step(dis.xyz, dis.zxy);
		dis += mm * rs * ri;
        pos += mm * rs;
	}

	vec3 nor = -mm*rs;
	vec3 vos = pos;
	
    // intersect the cube	
	vec3 mini = (pos-ro + 0.5 - 0.5*vec3(rs))*ri;
	float t = max ( mini.x, max ( mini.y, mini.z ) );
	
	oDir = mm;
	oVos = vos;

	return t*res;
}

vec3 getColor(int r)
{
    switch(r)
    {
        // METAL
        case 0:
        	return vec3(86., 48., 107.) 	/256.;
        case 1:
        	return vec3(98., 67., 198.) 	/256.;
        case 2:
        	return vec3(102., 165., 250.)	/256.;
        case 3:
        	return vec3(186., 250., 236.)	/256.;
        
        // LAVA
        /*
        case 0:
        	return vec3(45., 19., 44.) 	/256.;
        case 1:
        	return vec3(128., 19., 54.) 	/256.;
        case 2:
        	return vec3(199., 44., 65.)	/256.;
        case 3:
        	return vec3(238., 69., 64.)	/256.;*/
        
        /*
        // CHROME
        case 0:
        	return vec3(80., 38., 167.) 	/256.;
        case 1:
        	return vec3(141., 68., 139.) 	/256.;
        case 2:
        	return vec3(204., 106., 135.)	/256.;
        case 3:
        	return vec3(236., 205., 143.)	/256.;*/
    }
    
    return vec3(0.);
}

//------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------

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
    p.x /= 1.25;

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
    
    // camera movement
    vec3 ro, ta;
    doCamera( ro, ta, iTime);

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
	// create view ray
	vec3 rd = normalize( vec3(p.xy,1.0) ); // lens length
    rd.y -= 1.0;

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = doBackground();

	// raymarch
    vec3 vos, dir;
    int mat;
    float t = calcIntersection( ro, rd, vos, dir, mat );
    if( t>0.0 )
    {
        // geometry
        vec3 pos = ro + t*rd;
        vec3 nor = -dir*sign(rd);

        // materials
        vec3 mal = doMaterial( pos, vos );

        col = doLighting( pos, nor, rd, t, mal, vos, dir);
	}

    
    col *= 1.5;
    col -= .03;
    
	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------
    // gamma
	col = pow( clamp(col,0.0,1.0), vec3(0.5) );
    
    // saturation
	//col = saturation(col, 2.0);   
    //col *= exp(-.01*t*t);
    
    // toon
    col *= vec3(6.);
    float colFract = abs(sin(fract(col.r) * 3.14 * 1.0));
    col = floor(col);
    
    
    // pallete
    col = mix(getColor(int(col.r-1.)), getColor(int(col.r)), colFract);
    
    fragColor = vec4( col, 1.0 );
}