// Postcard by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/XdBSWd
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
	Implementation of: https://iquilezles.org/articles/dynclouds
	
	Added some raymarched mountains and normal mapped water to complete the scene.

	One thing I did differently is modyfying the scale of the fbm based on the distance
	from the shaded clouds allowing for a much less "planar" look to the cloud layer.  
*/

//Compare with simple clouds
//#define BASIC_CLOUDS

#define time iTime*2.
#define FAR 420.

//------------------------------------------------------------------
//----------------------Utility functions---------------------------
//------------------------------------------------------------------
vec3 rotx(vec3 p, float a){
    float s = sin(a), c = cos(a);
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z);
}
vec3 roty(vec3 p, float a){
    float s = sin(a), c = cos(a);
    return vec3(c*p.x + s*p.z, p.y, -s*p.x + c*p.z);
}
float nmzHash(vec2 q)
{
    uvec2 p = uvec2(ivec2(q));
    p = p*uvec2(374761393U,22695477U) + p.yx;
    p.x = p.x*(p.y^(p.x>>15U));
    return float(p.x^(p.x >> 16U))*(1.0/float(0xffffffffU));
}
float noise(in vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
	vec2 u = fp*fp*(3.0-2.0*fp);
    return -1.0+2.0*mix( mix( nmzHash( ip + vec2(0.0,0.0) ), nmzHash( ip + vec2(1.0,0.0) ), u.x),
                mix(nmzHash( ip + vec2(0.0,1.0) ), nmzHash( ip + vec2(1.0,1.0)), u.x), u.y);
}
//------------------------------------------------------------------
//---------------------------Terrain--------------------------------
//------------------------------------------------------------------
float terrain(in vec2 p)
{
    p*= 0.035;
    float rz = 0.;
    float m = 1.;
    float z = 1.;
    for(int i=0; i<=2; i++) 
    {
        rz += (sin(noise(p/m)*1.7)*0.5+0.5)*z;
        m *= -0.25;
        z *= .2;
    }
    rz=exp2(rz-1.5);
    rz -= sin(p.y*.2+sin(p.x*.45));
    return rz*20.-14.;
}

float tmap(in vec3 p){ return p.y-terrain(p.zx);}
//Using "cheap AA" from eiffie (https://www.shadertoy.com/view/XsSXDt)
vec3 tmarch(in vec3 ro, in vec3 rd, in float d)
{
	float precis = 0.01;
    float h=precis*2.0;
    float hm = 100., dhm = 0.;
    for( int i=0; i<15; i++ )
    {   
        d += h = tmap(ro+rd*d)*1.5;
        if (h < hm)
        {
            hm = h;
            dhm = d;
        }
        if( abs(h)<precis||d>FAR ) break;
    }
	return vec3(d, hm, dhm);
}


vec3 normal( in vec3 pos, float t )
{
	float e = 0.001*t;
    vec2  eps = vec2(e,0.0);
    float h = terrain(pos.xz);
    return normalize(vec3( terrain(pos.xz-eps.xy)-h, e, terrain(pos.xz-eps.yx)-h ));
}

float plane( in vec3 ro, in vec3 rd, vec3 c, vec3 u, vec3 v )
{
	vec3 q = ro - c;
	vec3 n = cross(u,v);
    return -dot(n,q)/dot(rd,n);
}
//------------------------------------------------------------------
//-------------------------2d Clouds--------------------------------
//------------------------------------------------------------------
vec3 lgt = normalize(vec3(-1.0,0.1,.0));
vec3 hor = vec3(0);

float nz(in vec2 p){return texture(iChannel0, p*.01).x;}
mat2 m2 = mat2( 0.80,  0.60, -0.60,  0.80 );
float fbm(in vec2 p, in float d)
{	
	d = smoothstep(0.,100.,d);
    p *= .3/(d+0.2);
    float z=2.;
	float rz = 0.;
    p  -= time*0.02;
	for (float i= 1.;i <=5.;i++ )
	{
		rz+= (sin(nz(p)*6.5)*0.5+0.5)*1.25/z;
		z *= 2.1;
		p *= 2.15;
        p += time*0.027;
        p *= m2;
	}
    return pow(abs(rz),2.-d);
}

vec4 clouds(in vec3 ro, in vec3 rd, in bool wtr)
{   
	
    //Base sky coloring is from iq's "Canyon" (https://www.shadertoy.com/view/MdBGzG)
    float sun = clamp(dot(lgt,rd),0.0,1.0 );
    hor = mix( 1.*vec3(0.70,1.0,1.0), vec3(1.3,0.55,0.15), 0.25+0.75*sun );
    vec3 col = mix( vec3(0.5,0.75,1.), hor, exp(-(4.+ 2.*(1.-sun))*max(0.0,rd.y-0.05)) );
    col *= 0.4;
	
    if (!wtr)
    {
        col += 0.8*vec3(1.0,0.8,0.7)*pow(sun,512.0);
        col += 0.2*vec3(1.0,0.4,0.2)*pow(sun,32.0);
    }
    else 
    {
        col += 1.5*vec3(1.0,0.8,0.7)*pow(sun,512.0);
        col += 0.3*vec3(1.0,0.4,0.2)*pow(sun,32.0);
    }
    col += 0.1*vec3(1.0,0.4,0.2)*pow(sun,4.0);
    
	float pt = (90.0-ro.y)/rd.y; 
    vec3 bpos = ro + pt*rd;
    float dist = sqrt(distance(ro,bpos));
    float s2p = distance(bpos,lgt*100.);
    
    const float cls = 0.002;
    float bz = fbm(bpos.xz*cls,dist);
    float tot = bz;
    const float stm = .0;
    const float stx = 1.15;
    tot = smoothstep(stm,stx,tot);
    float ds = 2.;
    for (float i=0.;i<=3.;i++)
    {

        vec3 pp = bpos + ds*lgt;
        float v = fbm(pp.xz*cls,dist);
        v = smoothstep(stm,stx,v);
        tot += v;
        #ifndef BASIC_CLOUDS
        ds *= .14*dist;
        #endif
    }

    col = mix(col,vec3(.5,0.5,0.55)*0.2,pow(bz,1.5));
    tot = smoothstep(-7.5,-0.,1.-tot);
    vec3 sccol = mix(vec3(0.11,0.1,0.2),vec3(.2,0.,0.1),smoothstep(0.,900.,s2p));
    col = mix(col,sccol,1.-tot)*1.6;
    vec3 sncol = mix(vec3(1.4,0.3,0.),vec3(1.5,.65,0.),smoothstep(0.,1200.,s2p));
    float sd = pow(sun,10.)+.7;
    col += sncol*bz*bz*bz*tot*tot*tot*sd;
    
    if (wtr) col = mix(col,vec3(0.5,0.7,1.)*0.3,0.4); //make the water blue-er
    return vec4(col,tot);
}
//------------------------------------------------------------------
//-------------------------------Extras-----------------------------
//------------------------------------------------------------------
float bnoise(in vec2 p)
{
    float d = sin(p.x*1.5+sin(p.y*.2))*0.1;
    return d += texture(iChannel0,p.xy*0.01+time*0.001).x*0.04;
}

vec3 bump(in vec2 p, in vec3 n, in float t)
{
    vec2 e = vec2(40.,0)/(t*t);
    float n0 = bnoise(p);
    vec3 d = vec3(bnoise(p+e.xy)-n0,2., bnoise(p+e.yx)-n0)/e.x;
    n = normalize(n-d);
    return n;
}
//------------------------------------------------------------------
//------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    vec2 bp = fragCoord.xy/iResolution.xy*2.-1.;
    vec2 p  = bp;
	p.x*=iResolution.x/iResolution.y;
	vec2 mo = iMouse.xy / iResolution.xy-.5;
    mo = (mo==vec2(-.5))?mo=vec2(-0.4,-0.15):mo;
	mo.x *= iResolution.x/iResolution.y;
	vec3 ro = vec3(140.,0.,100.);
    vec3 rd = normalize(vec3(p,-2.7));
    rd = rotx(rd,0.15+mo.y*0.4);rd = roty(rd,1.5+mo.x*0.5);
    vec3 brd = rd;
    vec3 col = vec3(0);
		
	float pln = plane(ro, rd, vec3(0.,-4.,0), vec3(1.,0.,0.), vec3(0.0,.0,1.0));
    vec3 ppos = ro + rd*pln;
    bool wtr = false;
    vec3 bm = vec3(0);
    if (pln < 500. && pln > 0.)
    {
        vec3 n = vec3(0,1,0);
        float d= distance(ro,ppos);
        n = bump(ppos.xz,n,d);
        bm = n;
        rd = reflect(rd,n);
        wtr = true;
    }
    vec4 clo = clouds(ro, rd, wtr);
    col = clo.rgb;
    
    vec3 rz = tmarch(ro,brd,350.);
    float px = 3.5/iResolution.y;
    if (rz.x < FAR && (rz.x < pln || pln < 0.))
    {
        vec3 pos = ro + brd*rz.x;
        float dst = distance(pos, ro);
        vec3 nor = normal(pos,dst);
        float nl = clamp(dot(nor,lgt),0.,1.);
        vec3 mcol = vec3(0.04)+vec3(nl)*0.4*vec3(.5,0.35,0.1);
        mcol = mix(mcol,hor,smoothstep(210.,400.,rz.x-(pos.y+18.)*5.));//fogtains
        col = mix(mcol,col,clamp(rz.y/(px*rz.z),0.,1.));
    }
    
    //smooth water edge
    if (wtr && rz.x > pln)col = mix(col,hor*vec3(0.3,0.4,.6)*0.4,smoothstep(10.,200.,pln));
    
    //post
    col = pow(clamp(col,0.0,1.0), vec3(.9));
    col.g *= 0.93;
    //fancy vignetting
    float vgn1 = pow(smoothstep(0.0,.3,(bp.x + 1.)*(bp.y + 1.)*(bp.x - 1.)*(bp.y - 1.)),.5);
    float vgn2 = 1.-pow(dot(vec2(bp.x*.3, bp.y),bp),3.);
    col *= mix(vgn1,vgn2,.4)*.5+0.5;
	fragColor = vec4( col, 1.0 );
}