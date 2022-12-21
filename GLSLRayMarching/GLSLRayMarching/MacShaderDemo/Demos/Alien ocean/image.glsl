const vec3 star_dir = vec3(0.,.199,.98);
const vec3 star_col = vec3(1.,.5,.06)*200.;

float ray(vec3 ro, vec3 rd, float t) 
{
    vec3 p = ro+t*rd;
    float h = 0.0;
    for (int i=0;i<50;i++) {
        float h = p.y-srf(p.xz,ITERS_RAY, iTime).x;
        t+=h;
        p+=rd*h;
        if (h<EPS*t) return t;
    }
    return t;
}

vec3 sky(vec3 rd)
{
    float z = rd.z*.5+.5;
    float v = max(dot(rd,star_dir),0.);
    vec3 star = pow(min(pow(v,5.),.992),450.)*star_col + pow(v,40.)*vec3(1.,.4,.03);
    star *= 1.-smoothstep(4e-3,3e-3,length(rd-vec3(-.049,.291,.955)))*.7;
    
    float mist_col = exp(min(-rd.y*8.,0.))*0.03;
    vec3 sky_col = mix(vec3(.2,.5,.8)*(z+1.)*.01,vec3(.25,.02,.01),z*z*.9)*1.5;
    vec3 col = sky_col+mist_col+star;
    return col;
}

float fresnel(vec3 rd, vec3 N, float n1, float n2)
{
    float I = acos(abs(dot(rd, N))-1e-5);
    float cosI = cos(I);
    float cosR = n1/n2 * sin(I);
    if(cosR > 1.) return 1.;
    cosR = sqrt(1. - cosR * cosR);
    float Rs = (n1*cosI - n2 * cosR)/(n1*cosI + n2 * cosR);
    float Rp = (n1*cosR - n2 * cosI)/(n1*cosR + n2 * cosI);
    return mix(Rs*Rs, Rp*Rp, .5);
}

void mainImage( out vec4 O, in vec2 u )
{
    vec2 R   = iResolution.xy,
         uv  = (2.*u-R)/R.x,
         muv = (2.*iMouse.xy-R)/R.x*-float(iMouse.z>1.)*PI;    
    
    //Camera
    vec3 vo = vec3(iTime,1.01,iTime),
         vd = camera_ray(vo,uv,muv,iTime),
    //Sky colour
         sky_col = sky(vd),
         col = sky_col;
    
    if ((1.0-vo.y)/vd.y>0.0) {
        //raymarch using previous pass
        float t = texelFetch(iChannel0,ivec2(u)>>3,0).x;
        t = ray(vo,vd, t);
        
        //normal using derivative
        vec3 p = vo+vd*t;
        vec3 N = norm(p.xz, max(ITERS_NORMAL+min(int(log(t)*-10.),0),1), iTime);
        
        //Reflected ray
        vec3 refd = reflect(vd,N);
        //Approx reflection occlusion from other waves
        float ref_hit = clamp((p.y+refd.y*100.-.5)*.5,0.,1.);
        //vec3 ref_col = mix(vec3(0),sky(refd),ref_hit);
        vec3 ref_col = mix(sky(normalize(refd+vec3(0,.2,0)))*.4,sky(refd),ref_hit);

        //approx SSS
        vec3 H = normalize(star_dir+N*.05);
        float thick = pow(1.-p.y,2.);
        float I = pow(max(dot(vd,H),0.), 8.)*.002;
        vec3 ss_col = I*star_col*pow(vec3(.8,.15,.02)*.5,vec3(.3+thick*2.));

        //Mix using fresnel
        col = mix(ss_col,ref_col,fresnel(vd,N,1.,1.333));
        
        //Fog
        col = mix(sky_col,col,exp(-pow(t,1.5)*.007));
        //col = ss_col;
    }
    
    vec2 d = pow(abs(uv*.5)+.1,vec2(4.));
	col *= pow(1.-.84*pow(d.x+d.y,.25),2.); //vignette
    col += col*col;
    col = 1.-exp(-col);
    col = pow(col,vec3(1./2.2));
    
    vec3 noise = pow(texelFetch(iChannel1, ivec2(u)%1024, 0).rgb,vec3(1./2.2));
    noise = (noise*2.-1.)*0.499*2.;
    col += noise/256.;
        
    O = vec4(col,1.);
}