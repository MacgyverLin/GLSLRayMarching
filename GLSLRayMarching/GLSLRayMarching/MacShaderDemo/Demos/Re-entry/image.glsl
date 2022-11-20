// Re-entry by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/4dGyRh
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

#define ITR 35
#define FAR 15.
#define time iTime

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

vec3 objmov(vec3 p)
{
    p.xz *= mm2(-time*3.4 + sin(time*1.11));
    p.yz *= mm2(time*2.7 + cos(time*2.5));
    return p;
}

float tri(in float x){return abs(fract(x)-0.5)-.25;}
float trids(in vec3 p){return max(tri(p.z),min(tri(p.x),tri(p.y)));}
float tri2(in float x){return abs(fract(x)-.5);}
vec3 tri3(in vec3 p){return vec3( tri(p.z+tri(p.y*1.0)), tri(p.z+tri(p.x*1.05)), tri(p.y+tri(p.x*1.1)));}                           

mat2 m2 = mat2( 0.970,  0.242, -0.242,  0.970 );
float triNoise3d(in vec3 p, in float spd)
{
    float z = 1.45;
	float rz = 0.;
    vec3 bp = p;
	for (float i=0.; i<4.; i++ )
	{
        vec3 dg = tri3(bp);
        p += (dg+time*spd+10.1);
        bp *= 1.65;
		z *= 1.5;
		p *= .9;
        p.xz*= m2;
        
        rz+= (tri2(p.z+tri2(p.x+tri2(p.y))))/z;
        bp += 0.9;
	}
	return rz;
}

float map(vec3 p)
{
    p*= 1.5;
	p = objmov(p);
    float d = length(p)-1.;
    d -= trids(p*1.2)*.7;
    return d/1.5;
}

float map2(vec3 p)
{
    p = objmov(p);
    return length(p)-1.3;
}

float march(in vec3 ro, in vec3 rd)
{
	float precis = 0.001;
    float h=precis*2.0;
    float d = 0.;
    for( int i=0; i<ITR; i++ )
    {
        if( abs(h)<precis || d>FAR ) break;
        d += h;
	    float res = map(ro+rd*d);
        h = res;
    }   
	return d;
}

vec3 normal(const in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.04;   
	return normalize(e.yxx*map(p + e.yxx) + e.xxy*map(p + e.xxy) + 
					 e.xyx*map(p + e.xyx) + e.yyy*map(p + e.yyy) );   
}

float gradm(in vec3 p)
{
    float e = .06;
    float d = map2(vec3(p.x,p.y-e,p.z))-map2(vec3(p.x,p.y+e,p.z));
    d += map2(vec3(p.x-e,p.y,p.z))-map2(vec3(p.x+e,p.y,p.z));
    d += map2(vec3(p.x,p.y,p.z-e))-map2(vec3(p.x,p.y,p.z+e));
	return d;
}

//Main fireball
float mapVol(vec3 p, in float spd)
{
    float f = smoothstep(0.0, 1.25, 1.7-(p.y + dot(p.xz,p.xz)*.62));   
    float g = p.y;
    p.y *= .27;
    p.z += gradm(p*0.73)*3.5;
    p.y += time*6.;
    float d = triNoise3d(p*vec3(0.3,0.27,0.3) - vec3(0,time*.0,0),spd*0.7)*1.4 + 0.01;
    d += max((g-0.)*0.3,0.);    
   	d *= f;
    
    return clamp(d,0.,1.);
}

vec3 marchVol( in vec3 ro, in vec3 rd, in float t, in float mt )
{
	vec4 rz = vec4(0);
    #if 1
    t -= (dot(rd, vec3(0,1,0))+1.);
    #endif
	float tmt = t +15.;
	for(int i=0; i<25; i++)
	{
		if(rz.a > 0.99)break;

		vec3 pos = ro + t*rd;
        float r = mapVol( pos,.1 );
        float gr =  clamp((r - mapVol(pos+ vec3(.0,.7,0.0),.1))/.3, 0., 1. );
        vec3 lg = vec3(0.72,0.28,.0)*1.2 + 1.3*vec3(0.55, .77, .9)*gr;
        vec4 col = vec4(lg,r*r*r*2.5); //Could increase this to simulate entry
        col *= smoothstep(t-0.0,t+0.2,mt);
        
        pos.y *= .7;
        pos.zx *= ((pos.y-5.)*0.15 - 0.4);
        float z2 = length(vec3(pos.x,pos.y*.75 - .5,pos.z))-.75;
        col.a *= smoothstep(.4,1.2,.7-map2(vec3(pos.x,pos.y*.17,pos.z)));
		col.rgb *= col.a;
		rz = rz + col*(1. - rz.a);
		
        t += abs(z2)*.1 + 0.12;
        if (t>mt || t > tmt)break;
	}
	
    rz.g *= rz.w*0.9+0.12;
    rz.r *= rz.w*0.5+0.48;
	return clamp(rz.rgb, 0.0, 1.0);
}

// "Particles"
float mapVol2(vec3 p, in float spd)
{
    p *= 1.3;
    float f = smoothstep(0.2, 1.0, 1.3-(p.y+length(p.xz)*0.4));
    p.y *= .05;
    p.y += time*1.7;
    float d = triNoise3d(p*1.1,spd);
    d = clamp(d-0.15, 0.0, 0.75);
    d *= d*d*d*d*47.;
   	d *= f;
    
    return d;
}

vec3 marchVol2( in vec3 ro, in vec3 rd, in float t, in float mt )
{
    
    vec3 bpos = ro +rd*t;
    t += length(vec3(bpos.x,bpos.y,bpos.z))-1.;
    t -= dot(rd, vec3(0,1,0));
	vec4 rz = vec4(0);
	float tmt = t +1.5;
	for(int i=0; i<25; i++)
	{
		if(rz.a > 0.99)break;

		vec3 pos = ro + t*rd;
        float r = mapVol2( pos,.01 );
        vec3 lg = vec3(0.7,0.3,.2)*1.5 + 2.*vec3(1,1,1)*0.75;
        vec4 col = vec4(lg,r*r*r*3.);
        col *= smoothstep(t-0.25,t+0.2,mt);
        
        float z2 = length(vec3(pos.x,pos.y*.9,pos.z))-.9;
        col.a *= smoothstep(.7,1.7, 1.-map2(vec3(pos.x*1.1,pos.y*.4,pos.z*1.1)));
		col.rgb *= col.a;
		rz = rz + col*(1. - rz.a);
		
        t += z2*.015 + abs(.35-r)*0.09;
        if (t>mt || t > tmt)break;
        
	}
	
	return clamp(rz.rgb, 0.0, 1.0);
}

// MIT Licensed hash From Dave_Hoskins (https://www.shadertoy.com/view/4djSRW)
vec3 hash33(vec3 p)
{
    p = fract(p * vec3(443.8975,397.2973, 491.1871));
    p += dot(p.zxy, p.yxz+19.27);
    return fract(vec3(p.x * p.y, p.z*p.x, p.y*p.z));
}

vec3 stars(in vec3 p)
{
    vec3 c = vec3(0.);
    float res = iResolution.x*0.8;
    
	for (float i=0.;i<4.;i++)
    {
        vec3 q = fract(p*(.15*res))-0.5;
        vec3 id = floor(p*(.15*res));
        vec2 rn = hash33(id).xy;
        float c2 = 1.-smoothstep(0.,.6,length(q));
        c2 *= step(rn.x,.0005+i*i*0.001);
        c += c2*(mix(vec3(1.0,0.49,0.1),vec3(0.75,0.9,1.),rn.y)*0.25+0.75);
        p *= 1.4;
    }
    return c*c*.65;
}

float curv(in vec3 p, in float w)
{
    vec2 e = vec2(-1., 1.)*w;   
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    return 1.0/e.y *(t1 + t2 + t3 + t4 - 4. * map(p));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
	vec2 p = fragCoord.xy/iResolution.xy-0.5;
	p.x*=iResolution.x/iResolution.y;
	vec2 mo = iMouse.xy / iResolution.xy-.5;
    mo = vec2(-0.27,0.31);
	mo.x *= iResolution.x/iResolution.y;
    const float roz = 7.3;
	vec3 ro = vec3(-1.5,0.5,roz);
    vec3 rd = normalize(vec3(p,-1.5));
    mo.x += sin(time*0.3 + sin(time*0.05))*0.03+0.03;
    mo.y += sin(time*0.4 + sin(time*0.06))*0.03;
    mat2 mx = mm2(mo.x*6.);
    mat2 my = mm2(mo.y*6.); 
    ro.xz *= mx;rd.xz *= mx;
    ro.xy *= my;rd.xy *= my;
    
	float rz = march(ro,rd); //march geometry
    vec3 col = stars(rd);   
    float maxT = rz;
    if (rz > FAR)
        maxT = 25.;
    vec3 mv = marchVol(ro,rd, roz-1.5,maxT);
    
    if ( rz < FAR )
    {
        vec3 pos = ro+rz*rd;
        vec3 nor= normal( pos );
        float crv = clamp(curv(pos, 0.3)*0.35,0.,1.3);
        
        vec3 col2 = vec3(1,0.1,0.02)*(crv*0.8+0.2)*0.5;
        float frict = dot(pos, normalize(vec3(0.,1.,0.)));
        col = col2*(frict*0.3+0.7);
        
        col += vec3(1,0.3,0.1)*(crv*0.7+0.3)*max((frict*0.5+0.5),0.)*1.3;
        col += vec3(.8,0.8,.5)*(crv*0.9+0.1)*pow(max(frict,0.), 1.5)*1.9;
        pos = objmov(pos);
        
        col *= 1.2-mv;
        col *= triNoise3d(pos*2.8,0.)*0.25+0.45;
        col = pow(col, vec3(1.5,1.2,1.2))*.9;
    }
    col += mv;
    col += marchVol2(ro,rd, roz-5.5,rz);
	col = pow(col,vec3(1.4))*1.1;
    
	fragColor = vec4( col, 1.0 );
}