// Copyright Inigo Quilez, 2022 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot host, display, distribute
// or share this Work neither as it is or altered, on Shadertoy or anywhere else,
// in any form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot sell this
// Work, mint an NFTs of it or train a neural network with it without my permission.
// I share this Work for educational purposes, and you can link to it through an URL
// with proper attribution and unmodified art. If these conditions are too
// restrictive contact me and we'll definitely work it out.


// I made this after I saw leon's shader for the Inercia Shader Royale 2022
// (https://www.shadertoy.com/view/md2GDD), not because of any particular reason
// (KIFS fractals are very popular and I've done my share
// https://www.shadertoy.com/view/lssGRM and https://www.shadertoy.com/view/4sX3R2)
// but because sometimes you just see something pretty and want to attempt doing
// something pretty too.
//
// I'm using smooth-minimum and smooth-abs to blend all spheres together into a
// single organic shape. The rest is color tweaking.
//
// The shader runs slow because I'm doing volumetric rendering so I get some sweet
// transparencies. With regular raymarching this runs at 60 fps in a full screen,
// but as usual I'm okey with doing something 4x slower if it looks 10% prettier!


// https://iquilezles.org/articles/intersectors/
vec2 sphIntersect( in vec3 ro, in vec3 rd, float ra )
{
	float b = dot( ro, rd );
	float c = dot( ro, ro ) - ra*ra;
	float h = b*b - c;
	if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
	return vec2(-b-h,-b+h);
}

// https://iquilezles.org/articles/smin/
vec4 smin( vec4 a, vec4 b, float k )
{
    float h = max( k-abs(a.x-b.x), 0.0 )/k;
    float m = h*h*0.5;
    float s = m*k*0.5;
    vec2 r = (a.x<b.x) ? vec2(a.x,m) : vec2(b.x,1.0-m);
    return vec4(r.x-s, mix( a.yzw, b.yzw, r.y ) );
}

// https://iquilezles.org/articles/functions/
float sabs( float x, float k )
{
    return sqrt(x*x+k);
}

vec2 rot( vec2 p, float a )
{
    float co = cos(a);
    float si = sin(a);
    return mat2(co,-si,si,co) * p;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(0.0, cos(cr),sin(cr));
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//======================================================================
// creature
//======================================================================

// euclidean distance to creature, and color at closest point
vec4 map( in vec3 p, float time )
{
    float d1 = 0.10*sin(-time*6.283185/8.0 +  3.0*p.y); // animate body
    float d2 = 0.05*sin( time*10.0         + 60.0*p.y); // animate flagellum

    vec4 dcol = vec4(1e20,0.0,0.0,0.0);
    float sc = 1.0;
    for( int i=0; i<20; i++ )
    {
        // rotate coords
        p.xz = rot(p.xz, 17.0*sc + d1*smoothstep( 5.0, 1.0,float(i))); // body
        p.yz = rot(p.yz, -1.0*sc + d2*smoothstep(10.0,12.0,float(i))); // flagellum
        
        // smooth mirror and translate coords
        p.x = sabs(p.x,0.0001*sc) - 0.22*sc;

        // distance
        float d = (i==19) ? length(p*vec3(1.0,1.0,0.1)) - 0.1*sc :
                            length(p) - (0.1*sc + 0.001*sc*sin(2000.0*p.y*sc));
        // color
        vec3 c = (i==9) ? vec3(0.75) :
                          vec3(0.4,0.2,0.2) + vec3(0.1,0.5,0.6)*float(i)/20.0 + 0.1*cos(vec3(0,1,2)-p*10.0);

        // blend in distance and color
        dcol = smin(dcol, vec4(d,c), 0.12*sc);
    
        // scale coords for next iteration
        sc /= 1.2;
    }
    
    return dcol;
}

// https://iquilezles.org/articles/nvscene2008/rwwtt.pdf
float calcAO( in vec3 pos, in vec3 nor, in float time )
{
	float occ = 0.0;
    for( int i=0; i<8; i++ )
    {
        float h = 0.01 + 0.4*float(i)/7.0;
        vec3  w = normalize( nor + normalize(sin(float(i)+vec3(0,2,4))));
        float d = map( pos + h*w, time ).x;
        occ += h-d;
    }
    return clamp( 1.0 - 0.71*occ, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, float dis, in float time )
{
    const vec2 e = vec2(0.001,0.0);
    return normalize( vec3( map( pos + e.xyy, time ).x,
                            map( pos + e.yxy, time ).x,
                            map( pos + e.yyx, time ).x)-dis );
}

//======================================================================
// CITA - Crap In The Air
//======================================================================

// a 3D dithered grid of spheres
vec4 mapCITA( in vec3 pos, in float time )
{
    pos.y += time*0.02;

    const float rep = 1.5;
    vec3 ip = floor(pos/rep);
    vec3 fp = fract(pos/rep);
    vec3 op = vec3( (fp.x<0.0)?-1.0:0.0, (fp.y<0.0)?-1.0:0.0, (fp.z<0.0)?-1.0:0.0 );
    
    // note we only need to check 8 cells, not 27
    vec4 dr = vec4(1e20);
    for( int i=0; i<2; i++ )
    for( int j=0; j<2; j++ )
    for( int k=0; k<2; k++ )
    {
        vec3 b = vec3( float(i), float(j), float(k) );
        vec3 id = ip + b + op;
        
        // random location per sphere
        vec3 ra = fract(sin(dot(id,vec3(1,123,1231))+vec3(0,1,2))*vec3(338.5453123,278.1459123,191.1234));
        vec3 o = 0.3*sin(6.283185*time/48.0 + 50.0*ra);
        vec3 r = b - fp + o;
        
        float d = dot(r,r);
        if( d<dr.x ) dr = vec4(d,r);
    }
    return vec4(sqrt(dr.x)*rep-0.02,dr.yzw);
}

// https://iquilezles.org/articles/raymarchingdf/
vec4 raycastCITA( in vec3 ro, in vec3 rd, in float px, in float tmax, in float time )
{
    float t = 0.0;
    vec3 res = vec3(0.0);
	for( int i=0; i<256; i++ )
	{
        vec3 pos = ro + t*rd;
        vec4 h = mapCITA( pos, time );
        res = h.yzw;
        if( h.x<0.0005*px*t || t>tmax ) break;
		t += h.x;
	}
	return (t<tmax) ? vec4(t,res) : vec4(-1.0);
}

//======================================================================
// rendering
//======================================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // coordinates
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
    
    float time = mod( iTime, 48.0 );
    
    // camera location and lense
    vec3  ta = 0.08*sin( 6.283185*time/24.0+vec3(0,2,4) );
    vec3  ro = ta + 1.85*vec3( cos(7.0*mo.x), 0.25, sin(7.0*mo.x) );
    float fl = 2.5;

    if( time>9.0 && time<16.0) { ta.z += 0.1; fl = 5.0; }    
    
    // camera-to-world transformation and ray direction
    mat3 ca = setCamera( ro, ta, 0.05 );
    vec3 rd = normalize( ca*vec3(p,fl) );
    
    // background
    vec3 back = vec3(0.0003,0.013,0.04)*(1.0-clamp(-1.25*rd.y,0.0,1.0));
    
    // render creature
    float ft = -1.0;
    vec3 col = back;
    
    // bounding sphere
    vec2 b = sphIntersect( ro, rd, 1.2 );
    if( b.y>0.0 )
    {
        // raymarch creature from bounding sphere's entry to exit point
        vec4  sum = vec4(0.0);
        float tmax = b.y;
        float t = max(0.0,b.x);
        for( int i=0; i<256 && t<tmax; i++ )
        {
            vec4  res = map( ro + t*rd, time );
            float dis = res.x;
            
            // raymarching step size (outter vs inner)
            float dt = (dis>0.0) ? dis*0.8+0.001 : (-dis+0.002);
            
            // inside creature
            if( dis<0.0 )
            {
                // record depth-buffer
                if( ft<0.0 ) ft=t; 
                
                // local geometry (position, normal, convexity)
                vec3  pos = ro + t*rd;
                vec3  nor = calcNormal( pos, res.x, time );
                float occ = calcAO( pos, nor, time );

                // color and opacity
                vec4 tmp = vec4(res.yzw*res.yzw,min(20.0*dt,1.0));

                // main light
                float ll = 15.0*exp2(-2.0*t);
                tmp.rgb *= (0.5+0.5*dot(nor,-rd))*ll*3.0/(1.0+ll);
                
                // subsurface scattering
                float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
                tmp.rgb += fre*fre*(0.5+0.5*tmp.rgb)*0.8;
                
                // occlusion
                tmp.rgb *= 1.6*mix(tmp.rgb*0.1+vec3(0.2,0.0,0.0),vec3(1.0),occ*1.4);
      
                // fog
                //tmp.rgb = mix( back, tmp.rgb, exp2(-0.1*t*vec3(4.0,3.5,3.0)/fl) );

                // composite front to back, and exit if opaque
                tmp.rgb *= tmp.a;
                sum += tmp*(1.0-sum.a);
                if( sum.a>0.995 ) break;
            }
            t += dt;
        }

        // composite with background
        sum = clamp(sum,0.0,1.0);
        col = col*(1.0-sum.w) + sum.xyz;
    }
    
    // render cita
    vec4  cita = raycastCITA( ro, rd, 2.0/fl, (ft>0.0) ? ft : 15.0, time );
    if( cita.x>0.0 )
    {
        // color
        vec3 citacol = vec3(0.9,1.0,1.0);
        // fog
        citacol = mix( back, citacol, exp2(-0.1*cita.x*vec3(4.0,3.5,3.0)/fl) );
        // blend in
        float fre = clamp(dot(normalize(cita.yzw),rd),0.0,1.0);
        col = mix( col, citacol, fre*0.3 );
    }

    // gain
    //col = col*3.0/(3.0+col);
    
    // gamma and color tweak
    col = pow( col, vec3(0.45,0.5,0.5) );
    
    // vignette
    col *= 1.2 - 0.35*length(p);
    
    // dither to remove banding in the background
    col += fract(sin(fragCoord.x*vec3(13,1,11)+fragCoord.y*vec3(1,7,5))*158.391832)/255.0;
 
    // return color
    fragColor = vec4(col, 1);
}