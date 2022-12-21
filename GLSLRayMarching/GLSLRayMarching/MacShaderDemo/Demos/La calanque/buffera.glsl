// Created by anatole duprat - XT95/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float map( in vec3 p);
vec3 shade( in vec3 p, in vec3 n, in vec3 ro, in vec3 rd);

vec2 rotate( vec2 v, float a);
vec3 seaHit( in vec3 ro, in vec3 rd, float h, out float t );
vec3 raymarch( in vec3 ro, in vec3 rd, in vec2 clip);
vec3 raymarchSmall( in vec3 ro, in vec3 rd, in vec2 clip);

vec3 normal( in vec3 p, in float e );
float ambientOcclusion(vec3 p, vec3 n, vec2 a);

float noise( in vec3 x );
float displacement( vec3 p );
vec3 skyColor( in vec3 rd);






//Distance field maps
float rock( in vec3 p)
{
	float d = length(abs(p.xy)+vec2(-220.,50.))-200.; // 2 cylinders 
	d = max(d, -p.z-250.);
    
	d = d*.2  + noise(p*.04-.75)*7. + displacement(p*.25)*2.;
    
	return d;
}
float ground( in vec3 p )
{
	return p.y-clamp(p.z*.08-5.5,-20., 0.);
}
float map( in vec3 p )
{
	return min(ground(p), rock(p));
}


//Shading
vec3 shade( in vec3 p, in vec3 n, in vec3 ro, in vec3 rd)
{
	//Sky ?
	const vec3 sunDir = vec3(-0.128,0.946, -0.189);
	vec3 sky = skyColor(rd);
	float d = length(p-ro);
	if(d>500. )
		return sky;

    vec3 nn = normal(p,5.);
    
   	//Materials
	vec3 col;
	if(rock(p.xyz) < p.y ) //Rock
	{
		col = mix(vec3(1.), vec3(.2,.3/*+noise(p*0.4)*.5*/,.1)*.4, pow(clamp(nn.y*1.1,0.,1.),4.));
		col = mix(mix(vec3(.3,.2,.1), vec3(.3,.28,.22)*1.9, clamp(p.z-70.,0.,1.)), col, clamp(p.y*.3,0.,1.));
	}
	else //Sand
	{
		col = vec3(.3,.28,.22)*1.9*(noise(p*10.)*noise(p*vec3(.8,0.,3.))*.1+.8);
	}


    //BRDF 
    float shad = ambientOcclusion(p.xyz, sunDir, vec2(7.,12.));
    float ao = ambientOcclusion(p.xyz, n, vec2(1.,1.5)) * ambientOcclusion(p.xyz, n, vec2(5.,8.));
    
    vec3 amb = vec3(.9,.97,1.)*ao;
    vec3 diff = vec3(1.,.8,.5) * min( max(dot(n,sunDir),0.)*max(dot(nn,sunDir)*1.2,0.1)*shad*6., 1.);
    vec3 ind = vec3(1.,.8,.5) * max(dot(n,sunDir*vec3(-1.,0.,-1.)),0.);
    vec3 skylight = vec3(.9,.97,1.)*clamp( 0.5 + 0.5*n.y, 0.0, 1.0 )*ao;
    col *=  amb*.3 + diff*.8 + ind*.1 + .2*skylight;
    
    
    
    //Underwater blue
    float a = clamp(-p.y*.4,0.,1.);
    float b = pow(clamp(2.5-displacement(p*vec3(.5,1.,.3)*.05+1.)*6.*a, 0.8, 1.),4.);
    float c = pow(clamp(2.5-displacement(p*vec3(.5,1.,.4)*.08+10.)*5.*a, 0.8, 1.),4.);
	col = mix(col, vec3(.2,1.,.8)*.2*(b-c+1.), a);
    
    //A little fog
	col = mix( col, vec3(1.,.98,.9), clamp( (d-25.)*.0007,0.,1.) );

	return col;
}


vec3 shadeWater( in vec3 p, in vec3 n, in vec3 ro, in vec3 rd) 
{
	//Sky ?
	const vec3 sunDir = vec3(-0.0828,0.946, -0.189);
	vec3 sky = skyColor(rd);
	if( map(p)>1.)
		return sky;
    
    //BRDF
	float d = length(p-ro);
	vec3 col = vec3(.9,.97,1.)*.1 +  vec3(1.,.9,.6)*max(dot(n,sunDir),0.)*.3;
    
    //A little fog
	col = mix( col, vec3(1.,.98,.9), clamp( (d-25.)*.0007,0.,1.) );
    return col;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Screen coords
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 v = -1.0+2.0*q;
	v.x *= iResolution.x/iResolution.y;
    
	//Camera
	float ct = cos(iTime*.1);
    vec3 ro = vec3(20.*ct,10.,75.+20.*ct);
	vec3 rd = normalize( vec3(v.x, v.y, -1.5+length(v)*.5) );
	rd.xz = rotate(rd.xz, -.5*ct+1.57);
    
    
    //Compute pixel
    vec3 p = raymarch(ro, rd, vec2(.1,1800.));
	vec3 n = normal(p.xyz, 0.01);
    vec3 col = shade(p,n, ro,rd);
    
    //Water hit ?
	float t;
	vec3 pWater = seaHit(ro,rd,.1, t);
    float d = length(p-ro);
	if( t>0. && (length(pWater-ro) < d || d>800.) )
	{
		float depth =  map(pWater);
		ro = pWater.xyz;
		n = normalize( vec3(0.,1.,0.) + (noise(pWater+vec3(0.,0.,iTime))*2.-1.)*.025);
		float fre = (1.-max(dot(rd,n),0.));
		vec3 refd = reflect(rd, n);
    	p = raymarchSmall(pWater+n, refd, vec2(.1,800.));
    	n = normal(p.xyz, 5.);
    	vec3 col2= shadeWater(p,n, ro,refd);
		col = mix(col, col2, min(depth,1.)*.5*fre);
		col = mix( col, skyColor(rd), min( d*0.001,1.) );
	}
    
    //Little lens flare
    vec3 sundir = normalize( vec3(.5, .2, -1.) );
    col += pow( max(dot(rd, sundir),0.), 2.0)*(float(d<500.)*.8+.2) *.1;
    
    
    //Gamma correction
    col = pow( col, vec3(1./1.42) );
    
    fragColor = vec4(col, float(d>500.));
}








vec2 rotate( vec2 v, float a)
{
  return vec2( v.y*cos(a) - v.x*sin(a), v.x*cos(a) + v.y*sin(a));
}


vec3 seaHit( in vec3 ro, in vec3 rd, float h, out float t )
{
        vec4 pl = vec4(0.0,1.0,0.0,h);
         t = -(dot(pl.xyz,ro)+pl.w)/dot(pl.xyz,rd);
        return ro+rd*t;
}


vec3 raymarch( in vec3 ro, in vec3 rd, in vec2 clip)
{
    float accD=2.;
    for(int i=0; i<128; i++)
    {
		float d = map( ro+rd*accD);
        if(  accD > clip.y) break;
        accD += d*2.5;
        
    }
    return ro+rd*accD;
}

vec3 raymarchSmall( in vec3 ro, in vec3 rd, in vec2 clip)
{
    float accD=5.;
    for(int i=0; i<64; i++)
    {
		float d = map( ro+rd*accD);
        if( d < .01 || accD > clip.y) break;
        accD += d*2.5;
        
    }
    return ro+rd*accD;
}

vec3 normal( in vec3 p, in float e )
{
    vec3 eps = vec3(e,0.0,0.0);
    return normalize(vec3(
        map(p+eps.xyy)-map(p-eps.xyy),
        map(p+eps.yxy)-map(p-eps.yxy),
        map(p+eps.yyx)-map(p-eps.yyx)
    ));
}


float ambientOcclusion(vec3 p, vec3 n, vec2 a)
{
	float dlt = a.x;
	float oc = 0.0, d = a.y;
	for(int i = 0; i<5; i++)
	{
		oc += (float(i) * dlt - map(p + n * float(i) * dlt)) / d;
		d *= 2.0;
	}
	return clamp(1.0 - oc, 0.0, 1.0);
}





vec3 skyColor( in vec3 rd )
{
    vec3 sundir = normalize( vec3(-.5, .2, -1.) );
    
    float yd = min(rd.y+0.05, 0.);
    rd.y = max(rd.y+0.05, 0.05);
    
    vec3 col = vec3(0.);
    
    col += vec3(.4, .4 - exp( -rd.y*20. )*.3, .0) * exp(-rd.y*9.); // Red / Green 
    col += vec3(.3, .5, .6) * (1. - exp(-rd.y*8.) ) * exp(-rd.y*.9) ; // Blue
    
    col = mix(col*1.2, vec3(.3),  1.-exp(yd*100.)); // Fog
    
    col += vec3(1.0, .5, .0) * (pow( max(dot(rd,sundir),0.), 15. ) + pow( max(dot(rd, sundir),0.), 150.0)*.5)*.3; // Sun
    
    
    col -= vec3(.6)*displacement( vec3(rd.xz*1.5/(.001+rd.y),0.)-vec3(.0,.1,.05)*iTime )*rd.y-.2; //Clouds
    
    return max(col, vec3(0.))*.9;
}



const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float displacement( vec3 p ) //Thx to Inigo Quilez
{	
    p *= vec3(1.,.8,1.);
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.01;
    f += 0.2500*noise( p); p = m*p*3.5;
    f += 0.0425*noise( p ); /*p = m*p*2.01;
    f += 0.0625*noise( p ); */
	
    return f;
}

float noise(vec3 p) //Thx to Las^Mercury
{
	vec3 i = floor(p);
	vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
	vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
	a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
	a.xy = mix(a.xz, a.yw, f.y);
	return mix(a.x, a.y, f.z)*.5+.5;
}