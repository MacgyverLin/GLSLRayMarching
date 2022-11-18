#define PI 3.14159265358979323846

//This first part is all stuff related to creating the checker pattern


//basic rotation matrix
mat2 prot (float a)
{
 
    mat2 m = mat2(cos(a), -sin(a), sin(a), cos(a) );
    return m;
}

//creaes the golden frame, well just it's shape 
float stripes(vec2 p, float s, float e)
{
    p = fract(p*s);   
    return min(smoothstep(0.95, 0.97, p.x)+smoothstep(0.95, 0.97, p.y),1.0);
	//return smoothstep(0.92, 0.95, p.x)-step(0.95,p.x)/5.;
}

float chess (vec2 p, float s)
{
    vec2 c = floor(p*s);
    return mod(c.x +c.y, 2.0);    
}

vec3 pattern3(vec2 uv)
{
   // uv*=2.;
    float wobble = (sin(iTime*4.-0.79)/3.);//fract(-iTime)/400.;//*0.05*sin(20.*iTime);
    float smoothT = iTime/1. ;//+ sin(iTime)/16.;
    
    vec2 st = uv; ;//for vig later
        uv*=1.25;
     uv.x+=0.75;
    uv.y+=0.75;   

    vec2 sv =uv;//prot(PI*floor(uv.x))*uv;
    
    //adding teh bumpy pebble texture for the red squares
    vec3 col = vec3(pow(texture(iChannel2, sv).x, 3.))*1.;
											 //-sin(iTime/1.)/50. //add this to uv/2. of ichannel0 for movement
    
    //adding the moldy wood? texture for the black squares
    col = mix(col, vec3(1.0, 0.0, .0)*texture(iChannel0,sv/2.+vec2(0., smoothT+wobble)).x, vec3(chess(uv, 2.0))  );
    
    //adding the frame, this one required a lot of hacking
    
    col = mix(col, vec3(texture(iChannel1, uv*0.01+0.75)/1.2+0.1)
              //the sin portion is for the light movement
              +abs(sin(uv.x*3.)),  
              //this calles the stripes function
              vec3(stripes(uv, 2., 1.)) )

        -step(0.98, fract(2.*uv.x))/3.-step(0.98, fract(2.*uv.y))/3.;
    
    
    //This is for vignetting
     st *=  1.0 - st.yx;
    float vig = st.x*st.y*15.;
    vig = pow(vig, 0.09);
    
 return clamp(col, 0., 1.);
    
}

//and now the other stuff




vec2 rot(vec2 uv,float a){
	return vec2(uv.x*cos(a)-uv.y*sin(a),uv.y*cos(a)+uv.x*sin(a));
}

mat2 rot(float a)
{
    
 float si = sin(a);
    float cs = cos(a);
    
    mat2 mat= mat2(cs, -si, si, cs);
    return mat;
}


float getGrey(vec3 p)
{
    return p.x*0.299 + p.y*0.587 + p.z*0.114;
       }


vec3 triPlanar(sampler2D tex, vec3 p, vec3 n)
{
    
    ///old comments
    //this thing gets the normal, abs because we only need positive values, 
    //negative ones are going into the surface so not needed?
    //we get max I guess because I guess if the normal is 0 or too small it's not helpful lol
    //we get the sum and use it to get the percentage each component contributes to the whole.
 vec3 norm = max(abs(n), 0.0001);	//I'll keep it simple with just this
 float sum = norm.x+norm.y+norm.z;
 norm = norm/sum;//so now the normal is a weighting factor, each component is  weight out of 100 percent
   // p/=10.;
    //I kinda get this. it's doing the scaling here, but it's still hard to visualize 
    //that adding texures of the yz, xz, and xy planes would result it a crisp image.
    //for example, if the texture was a chess board pattern...hmmm maybe.
    return vec3(pattern3(p.yz*8.)*norm.x + 
                pattern3(p.xz*8.)*norm.y +
                pattern3(p.xy*8.)*norm.z ) ;
    
}


vec3 bumpMap(sampler2D tex, in vec3 p, in vec3 n, float bumpfactor)
{
    
   
    const vec3 eps = vec3(0.001, 0., 0.);//I use swizzling here, x is eps
    float ref = getGrey(triPlanar(tex, p, n));//reference value 
    
    vec3 grad = vec3(getGrey(triPlanar(tex, p - eps, n)) - ref,
                     //eps.yxz means 0.,0.001, 0. "swizzling
                     getGrey(triPlanar(tex, p - eps.yxz, n)) - ref,
                     getGrey(triPlanar(tex, p - eps.yzx, n)) - ref)/eps.xxx;
    
    //so grad is the normal...then he does:
    grad -= n*dot(grad, n);//takes the dot of the surface normal 

    return normalize(n + grad*bumpfactor);
}



float rect(vec3 p, vec3 b)
{
    float wobble=sin(12.*iTime+0.7);
    wobble *= (smoothstep(0.6,0.9,sin(-iTime*4.))/60.);
    p = abs(p)-b;
 return max(p.x, max(p.y, p.z));
}

float infRect(vec3 p, vec3 b)
{
    p = abs(p)-b;
    float f = max(p.x, p.y);
 return f;   
}

float cylCross(vec3 p, float r)
{
 p = abs(p);
    vec3 f = vec3(max(p.x, p.y), max(p.y, p.z), max(p.z,p.x));
    return min(length(p.xy), min(length(p.yz), length(p.xz)))-r;
}

float rCross(vec3 p)
{float wobble = (sin(iTime*4.-0.79)/3.);
    p = abs(p);
    vec3 f = vec3(max(p.x, p.y), max(p.y, p.z), max(p.z,p.x));
    float k = min(f.x, min(f.y, f.z) ) - 1./3.;
    
 return k;   
}

float repCross(vec3 p)
{
    
    vec3 q = mod(p+1., 2.)-1.;
    float f = rCross(q);

    
q = abs(q)-0.5;

   q = abs(q)-0.2;q = abs(q)-0.95;q = abs(q)-0.5;q = abs(q)-0.5;
    q=abs(q)-0.005;
    f = min(f, cylCross(q,0.101));
    

 return f;   
}

float repCylCross(vec3 p)
{
    vec3 q = mod(p+1., 2.)-1.;
    float f =  cylCross(q, 0.05) ;
 return f;   
}

float rcScale(vec3 p, float s)
{
    
 return repCross(p*s)/s;
}

float map(vec3 p)
   {
       //p = fract(p);
     p.y+=sin(p.z*2.+iTime)/200.;
      p.x+=sin(p.y*2.+iTime)/200.;
    float re = 0.0;
       float scale = 1.;
       
       for(int i=0; i<2 ;i++)
       {
        
        scale*=3.;
        re = max(re, -rcScale(p, scale)  );

       }
        
    return re;//rect(p, vec3(2.5));
    }

float trace(vec3 ro, vec3 rd)
{
    float eps = 0.001;
    float dist;
    float t = 0.0;
    for(int i = 0;i<96;i++)
    {
        dist = map(ro+rd*t);
    if(dist<eps || t > 120.)
        break;
    
    t +=dist*0.95;
    }
    
    return t;
	    
}
//based on shanes reflection tutorial
float rtrace(vec3 ro, vec3 rd)
{
    float eps = 0.0001;
    float dist;
   	float t = 0.0;
    
    for(int i=0; i<48; i++)
    {
     dist = map(ro + rd*t);
        if(dist<eps || t > 120.)
            break;
        
      t += dist;
        
    }
    
    
 return t;   
}
vec2 path(vec3 p)
{
    
 float a = sin(p.z*1.)/3. ;
     float b = cos(p.z)/3.;
    return vec2(a, b);
}



vec3 normal(vec3 sp)
{///had to adjust the normal cause I was getting these weird lines on edges.
    vec3 eps = vec3(.0014, 0.0, 0.0);
    
    vec3 normal = normalize (vec3( map(sp+eps) - map(sp-eps)
                       ,map(sp+eps.yxz) - map(sp-eps.yxz)
                       ,map(sp+eps.yzx) - map(sp-eps.yzx) ));
    
    
 return normal;   
}

//guess who this is from...shane
// "I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original."
float calculateAO(in vec3 pos, in vec3 nor)
{
	float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

//based on shanes lighting function but i added reflections using a cubemap
vec3 lighting(vec3 sp, vec3 sn, vec3 lp, vec3 rd)
{
vec3 color;
    

    sn = bumpMap(iChannel0, sp, sn, 0.0015);
    vec3 lv = lp - sp;
    float ldist = max(length(lv), 0.01);
    vec3 ldir = lv/ldist;
    
    float atte = 1.0/(1.0 + 0.002*ldist*ldist );
    
    float diff = dot(ldir, sn);
    float spec = pow(max(dot(reflect(-ldir, sn), -rd), 0.0), 10.);
    float fres = pow(max(dot(rd, sn) + 1., 0.0), 1.);
	float ao = calculateAO(sp, sn);
    
    vec3 refl = reflect(rd, sn);
    vec3 refr = refract(rd, sn, 0.7);
    
   vec3 color2 = vec3(0.2, 0.5, 0.9);
    vec3 color3 = vec3(0.0);

    vec3 coolSpec = vec3(.3, 0.5, 0.9);
    vec3 hotSpec = vec3(0.9,0.5, 0.2);
   color2 = triPlanar(iChannel0, sp, sn);
    
    //apply color options and add refl/refr options
    color = (diff*color2*8. +  spec*coolSpec*9.  )*atte;
	
    
    //apply ambient occlusion and return.
 return color*ao;   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv=uv*2.0-1.0;
    uv.x*=iResolution.x/iResolution.y;
    
    float wobble=sin(12.*iTime+0.7);
    
    wobble *= (smoothstep(0.6,0.9,sin(-iTime*4.))/60.);//fract(-iTime)/400.;//*0.05*sin(20.*iTime);
    float smoothT = iTime/1. ;
    
    //(fract(.1*(iTime-1.))>=0.5)?:0.;
    vec3 lk = vec3(0.,0. +wobble , 0.+iTime/16.);
    
    //lk.xy+=vec2(2.34,.34);//path(lk/4.);//lk.xz*=rot(lk.z);//;
    vec3 ro = lk + vec3(0., 0., -1.0);
    vec3 lp = ro + vec3(0, 0., 0.);//lp is ro so no area is too dark
   	float FOV = .57;
    
    vec3 fwd = normalize(lk - ro);
    vec3 up = vec3(0., -1., 0.0);
    vec3 rr = normalize(cross(up, fwd));
    vec3 uu = normalize(cross(rr, fwd));
    
    vec3 rd = normalize(vec3(rr*FOV*uv.x + uu*FOV*uv.y + fwd));
    
   rd.yz*=rot(iTime/5.);
    //rd.xz*=rot(iTime/10.);
    rd.xz*=rot(sin(iTime/8.)/1.);
    float t = trace(ro, rd);
    
     vec3 sp = ro + rd*t;
    vec3 sn = normal(sp);
   	
    float far = smoothstep(0.0, 1.0, t/4.);
    
    //get cube color from cubemap again this time to apply to the sky,
    //really just so that the reflections on the ground make sense
    
  //  vec4 cubeColor = texture(iChannel1, rd);
    vec3 color = lighting(sp, sn, lp, rd);//mix(stripes(ro+rd*t),vec3(t), far);
     //reflection trace based on shanes reflection tutorial
    vec3 refRay = reflect(rd, sn);
    float rt = rtrace(sp+refRay*0.01, refRay);
    vec3 rsp = sp + refRay*rt;
    vec3 rsn = normal(rsp);

    color = mix(color, vec3(2., 2.5, 3.) ,far);//

	fragColor = vec4(color+rsn.x*0.03,1.0);

}