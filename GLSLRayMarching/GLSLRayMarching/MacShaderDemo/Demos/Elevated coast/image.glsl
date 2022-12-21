// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S.Guillitte 

#define time -iTime


float dh = 0.;

                                 
mat2 m2 = mat2(0.8,  0.6, -0.6,  0.8);
mat2 im2 = mat2(0.8,  -0.6, 0.6,  0.8);

float noise(in vec2 p){

    float res=0.;
    float f=1.;
	for( int i=0; i< 3; i++ ) 
	{		
        p=m2*p*f+.6;     
        f*=1.2;
        res+=sin(p.x+sin(2.*p.y));
	}        	
	return res/3.;
}

vec3 noised(in vec2 p){//noise with derivatives
	float res=0.;
    vec2 dres=vec2(0.);
    float f=1.;
    mat2 j=m2;
	for( int i=0; i< 3; i++ ) 
	{		
        p=m2*p*f+.6;     
        f*=1.2;
        float a=p.x+sin(2.*p.y);
        res+=sin(a);
        dres+=cos(a)*vec2(1.,2.*cos(2.*p.y))*j;
        j*=m2*f;
        
	}        	
	return vec3(res,dres)/3.;
}


float fbmabs( vec2 p ) {
	
	float f=1.;   
	float r = 0.0;	
    for(int i = 0;i<8;i++){	
		r += abs(noise( p*f )+.5)/f;       
	    f *=2.;
        p=im2*p;
       
	}
	return 1.-r*.5;
}

float sea( vec2 p ) 
{
	float f=1.;   
	float r = 0.0;	
    for(int i = 0;i<8;i++){	
		r += (1.-abs(noise( p*f +.9*time)))/f;       
	    f *=2.;
        p-=vec2(-.01,.04)*(r-.2*iTime/(.1-f));
	}
	return r/4.+.5;
}



float terrainIq( in vec2 x )//from IQ's Elevated : https://www.shadertoy.com/view/MdX3Rr
{
	vec2  p = x;
    float a = 0.0;
    float b = 1.0;
	vec2  d = vec2(0.0);
    for( int i=0; i<6; i++ )
    {
        vec3 n = noised(p);
        d += n.yz;
        a += b*n.x/(1.0+dot(d,d));
		b *= 0.5;
        p = m2*p*2.0;
    }

	return .3*a+.5;
}

float swissTurbulence(vec2 p )//from http://www.decarpentier.nl/scape-procedural-extensions
{
     
    float lacunarity = 2.0;
    float gain = 0.5;
    float warp = 0.15;
    float sum = 0.;
     float freq = 1.0, amp = 1.0;
     vec2 dsum = vec2(0.);
     for(int i=0; i < 7; i++)
     {
         vec3 n = noised((p + warp * dsum)*freq);
         sum += amp * (1. - abs(n.x));
         dsum += amp * n.yz * -n.x;
         freq *= lacunarity;
         amp *= gain * clamp(sum,0.,1.);
    }
    return sum/3.;
}

float jordanTurbulence(vec2 p)//from http://www.decarpentier.nl/scape-procedural-extensions
{
    
    
    float lacunarity = 2.0;
    float gain1 = 0.8;
    float gain = 0.5;
    float warp0 = 0.4;
    float warp = 0.35;
    float damp0 = 1.0;
    float damp = 0.8;
    float damp_scale = 1.0;
    vec3 n = noised(p);
    vec3 n2 = n * n.x;
    float sum = n2.x;
    vec2 dsum_warp = warp0*n2.yz;
    vec2 dsum_damp = damp0*n2.yz;

    float amp = gain1;
    float freq = lacunarity;
    float damped_amp = amp * gain;

    for(int i=1; i < 8; i++)
    {
        n = noised(p * freq + dsum_warp.xy);
        n2 = n * n.x;
        sum += damped_amp * n2.x;
        dsum_warp += warp * n2.yz;
        dsum_damp += damp * n2.yz;
        freq *= lacunarity;
        amp *= gain;
        damped_amp = amp * (1.-damp_scale/(1.+dot(dsum_damp,dsum_damp)));
    }
    return sum/2.+.5;
}

float rocks(vec2 p){
   //return jordanTurbulence(p );
   // return swissTurbulence(p );
   return terrainIq(p);
   //return fbmabs(p)*.5+.5;   
}

float map( vec3 p)
{
	float d1 =p.y-.1*p.z+.2-rocks(p.xz);
    float d2 =p.y-.4*sea(p.xz);
    dh = d2-d1;
    float d = min(d1,d2);
	return d;	
       	
}

vec3 normalRocks(in vec2 p)
{
	const vec2 e = vec2(0.004, 0.0);
	return normalize(vec3(
		rocks(p + e.xy) - rocks(p - e.xy),
        .008,
		rocks(p + e.yx) - rocks(p - e.yx)
		));
}

vec3 normalSea(in vec2 p)
{
	const vec2 e = vec2(0.002, 0.0);
	return normalize(vec3(
		sea(p + e.xy) - sea(p - e.xy),
        .004,
		sea(p + e.yx) - sea(p - e.yx)
		));
}

vec3 sky(in vec2 p)
{	
	//return sin(vec3(1.7,1.5,1.)+1.8- .9*fbmabs(p*4.-.02*time))+.2;
    return sin(vec3(1.7,1.5,1)+ .7+ .9*fbmabs(p*4.-.02*time))+.25;
}

float march(in vec3 ro, in vec3 rd)
{
	const float maxd = 35.0;
	const float precis = 0.001;
    float h = precis * 2.0;
    float t = 0.0;
	float res = -1.0;
    for(int i = 0; i < 128; i++)
    {
        if(h < precis*t || t > maxd) break;
	    h = map(ro + rd * t);
        t += h;
    }
    if(t < maxd) res = t;
    return res;
}

vec3 transform(in vec3 p)
{
    
    p.zx = p.xz;
    p.z=-p.z;
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	
    vec2 p = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
	vec3 col = vec3(0.);
   	vec3 rd = normalize(vec3(p, -2.));
	vec3 ro = vec3(0.0, 2.0, -2.+.2*time);
    vec3 li = normalize(vec3(-2., 2., -4.));
    ro = transform(ro);
	rd = transform(rd);
    
    
    
    float t = march(ro, rd);
    if(t > -0.001)
    {
        //if(dh<0.)t-=dh;
        vec3 pos = ro + t * rd;
        
        float k=rocks(pos.xz)*2.;
        
        vec3 nor = normalRocks(pos.xz);
        float r = max(dot(nor, li),0.05)/2.;
        if(dh<0.&&dh>-.02)r+=.5*exp(20.*dh);
        
        vec3 col1 =vec3(r*k*k, r*k, r*.8);
        if(dh<0.02){
        	vec3 nor = normalSea(pos.xz);
        	nor = reflect(rd, nor);
            col1+=vec3(0.9,.2,.05)*dh*.4;
        	col1 += pow(max(dot(li, nor), 0.0), 5.0)*vec3(.8);
        	col1 +=.2* sky(nor.xz/(.5+nor.y));
            
        }
	    col = .1+col1;
        
	}
    else //sky
        col = sky(rd.xz*(.1+rd.y));
    
   	fragColor = vec4(col, 1.0);
}