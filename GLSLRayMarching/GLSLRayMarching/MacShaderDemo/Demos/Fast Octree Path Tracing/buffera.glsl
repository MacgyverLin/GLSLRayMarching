float boxSize = 1.0;
float seed;
float bluenoise(vec2 uv)
{
    uv += 1337.0*fract(iTime);
    float v = texture( iChannel2 , (uv + 0.5) / iChannelResolution[2].xy, 0.0).x;
    return v;
}
vec2 hash2() 
{
    return fract(sin(vec2(seed+=1.0,seed+=1.0))*vec2(43758.5453123,22578.1459123));
}
float D_GGX(float Roughness, float NoH)
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float d = (NoH * a2 - NoH) * NoH + 1.0;	       
	return a2 / (3.1415926535*d*d);					
}
vec3 F_Schlick(vec3 S, float VoH)
{
	float Fc = pow(1.0 - VoH, 5.0);
	return S + (1.0-S)*Fc;
}
float F_Schlick_S(float S, float VoH)
{
	float Fc = pow(1.0 - VoH, 5.0);
	return S + (1.0-S)*Fc;
}
float Vis_Schlick( float Roughness, float NoV, float NoL )
{
	float k = sqrt( Roughness ) * 0.5;
	float Vis_SchlickV = NoV * (1.0 - k) + k;
	float Vis_SchlickL = NoL * (1.0 - k) + k;
	return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
}
vec3 ImportanceSampleCos(vec3 d) 
{
    vec2 rand = hash2();
    float phi = 6.28318530718*rand.x;
    float xiy = rand.y;
    float r = sqrt(xiy);
    float x = r*cos(phi);
    float y = r*sin(phi);
    float z = sqrt(max(0.0,1.0-x*x-y*y));
	vec3 w = d;
	vec3 u = cross(w.yzx, w);
	vec3 v = cross(w, u);
    return w*z+u*x+v*y;
}
vec3 ImportanceSampleGGX(vec3 d,vec3 V,float roughness,out vec3 H)
{
    roughness =max(0.04,roughness);
    vec2 rand = hash2();
    float phi = 6.28318530718*rand.x;
    float xiy = rand.y;
	float a = roughness * roughness;
	float CosTheta = sqrt((1.0 - xiy) / (1.0 + (a*a - 1.0) * xiy));
	float SinTheta = sqrt(1.0 - CosTheta * CosTheta);
	H = vec3(SinTheta * cos(phi),SinTheta * sin(phi), CosTheta);
	vec3 w = (d);
	vec3 u = (cross(w.yzx, w));
	vec3 v = cross(w, u);
	H = v * H.x + u * H.y + w * H.z;
	vec3 R = H*2.0 * dot(V,H)  - V;
    return normalize(R);
}
vec4 SpecularBRDF_PDF(vec3 L,vec3 V,vec3 N,float roughness,float Spec,float M,vec3 C,out vec3 F,vec3 H)
{
     roughness =max(0.04,roughness);
	 float NoL = dot(N, L);
	 float NoV = dot(N, V);
	 float NoH = dot(N, H);
	 float VoH = dot(V, H);

	 float D = D_GGX( roughness, NoH );
	 float Vis = Vis_Schlick( roughness, NoV, NoL );
     vec3 F0 =  mix(vec3(0.04+0.04*Spec),C*Spec,M);
	 F = F_Schlick( F0, VoH );
	 return vec4(max((D * Vis ) * F, 0.00001),max(D * NoH /(4.0*VoH), 0.00001));
}
// Ray-box intersection.
vec2 box(vec3 ro,vec3 rd,vec3 p0,vec3 p1)
{
    vec3 t0 = (mix(p1, p0, step(0., rd * sign(p1 - p0))) - ro) / rd;
    vec3 t1 = (mix(p0, p1, step(0., rd * sign(p1 - p0))) - ro) / rd;
    return vec2(max(t0.x, max(t0.y, t0.z)),min(t1.x, min(t1.y, t1.z)));
}
vec3 boxNormal(vec3 rp,vec3 p0,vec3 p1)
{
    rp = rp - (p0 + p1) / 2.0;
    vec3 arp = abs(rp) / (p1 - p0);
    return normalize(step(arp.yzx, arp) * step(arp.zxy, arp) * sign(rp));
}
float trace(vec3 ro, vec3 rd, inout vec3 outn,out int id,int ignore)
{
    vec2 ob = box(ro, rd, vec3(-boxSize), vec3(boxSize));
    
    float tt = max(0., ob.x);
    vec3 n = vec3(0, 1, 0);
    for(int j = 0; j < 23; ++j)//should be 1.41*2*2^n，layer:n(1~6):6,12,23,46,91,181
    {
        if(tt > ob.y - 1e-4)
        {
            break;
        }
        vec3 p2 = ro + rd * tt;
        vec3 p = p2 + sign(rd) * 1e-4;
        vec3 p0 = vec3(-boxSize), p1 = vec3(+boxSize);
        id = 0;
        for(int i = 0; i < 3; ++i)
        {
            vec3 c = p0 + (p1 - p0) * (0.5);
            vec3 o = step(c, p);
            id = int(float(id) * 8.0 + dot(o, vec3(1, 2, 4)));
            p0 = p0 + (c - p0) * o;
            p1 = p1 + (c - p1) * (vec3(1) - o);
        }
        if(id!=ignore&&cos(float(id))>0.5)//cos:random empty
        {
            n = (boxNormal(p2,p0,p1));//+(p2 - (p0 + p1) / 2.) / (p1 - p0)
            break;
        }        
        vec2 b = box(ro, rd, p0, p1);
        tt = b.y;
    }
    outn = n;//normalize(pow(abs(n), vec3(16)) * sign(n));
    return tt;
}
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
#define USE_MOUSE
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    vec2 st = fragCoord / iResolution.xy;
    vec2 texelsize = vec2(1.0)/iResolution.xy;
    
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 LightDir = normalize(vec3(0.5,2.0,1.0));
    vec3 LightColor = vec3(2.5);
#ifdef USE_MOUSE
    float a = 1.7 - 1.7 * iMouse.y / iResolution.y;
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    float a2 = 0.6 - 2. * iMouse.x / iResolution.x+0.05*iTime;
    mat2 m2 = mat2(cos(a2), sin(a2), -sin(a2), cos(a2));
#else
    float a = 0.6;// - 1.7 * iMouse.y / iResolution.y;
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    float a2 = 0.02*iTime;
    mat2 m2 = mat2(cos(a2), sin(a2), -sin(a2), cos(a2));
#endif
    
    seed = bluenoise(fragCoord.xy);
    seed = mod( seed*55.24317542, 3.14352);
        
    vec3 acc = vec3(0.0); 
    float normal_identity =0.0;
#define S 12   
#define D 4
    for(int samples =0;samples<S;samples++)
    {
        vec2 offset = 2.0*texelsize*(hash2());
        vec3 ro = vec3(0, -.1, 3.0);
        vec3 rd = normalize(vec3(uv+offset, -2.0));

        ro.yz *= m;
        rd.yz *= m;
        ro.xz *= m2;
        rd.xz *= m2;
        
        
        // Scene AABB.
        vec2 ob = box(ro, rd, vec3(-boxSize), vec3(boxSize)); 
        vec3 nro = ro;      
        vec3 nrd = rd;
        //trace
        int hitid=-1;
        int ignoreid=-1;

        vec3 n = vec3(0, 1, 0);
        vec3 radiance = vec3(0.0);
        vec3 mask = vec3(1.0);
        vec3 n_last = n;
        
        for(int depth=0;depth<D;depth++)
        {
          float tt = trace(nro, nrd, n,hitid,ignoreid);
          ignoreid = hitid;        
          bool hit = !(ob.y < ob.x || tt >= ob.y - 1e-4);           
          vec3 color;
          float metallic =step(sin(float(hitid)),0.0);
          float specular =1.0;
          float roughness = 0.2*step(cos(float(hitid+21)),0.0);
          normal_identity += (depth==0?(hit?dot(vec3(int(n.x>0.0),int(n.y>0.0),int(n.y>0.0)),vec3(4.0,2.0,1.0))/8.0:0.0):0.0);
          if(hit)
          {
              
              
              color = hsv2rgb(vec3(cos(float(hitid)*0.5+0.5),0.7,0.99));//vec3(0.0);
              float preF = min(0.4,F_Schlick_S( mix(0.04+0.04*specular,length(color*specular),metallic), dot(-nrd,n) ));
              float diffuseTerm = (mix(0.6,0.3,metallic)*0.5+mix(0.8,0.6,specular)*0.5)*(1.0-preF);                
              if(hash2().x<diffuseTerm)
              {            
                  nro = nro+nrd*tt;
                  vec3 d = ImportanceSampleCos(n);  
                  vec3 H = normalize(d-nrd);
                  vec3 F0 =  mix(vec3(0.04+0.04*specular),color*specular,metallic);
	              vec3 F = F_Schlick( F0, dot(-nrd,H) );
                  vec3 diffuse = (1.0-metallic)*(vec3(1.0) - F)*color/diffuseTerm;
                  mask*=diffuse/3.1415926;
                  nrd = d;
              }
              else
              {
                  nro = nro+nrd*tt;
                  vec3 H = vec3(0.5);
                  vec3 d = ImportanceSampleGGX(n,-nrd,roughness,H);
			      vec3 F=vec3(0.0);
                  vec4 brdf_pdf = SpecularBRDF_PDF(d,-nrd,n, roughness,specular,metallic,color,F,H);
			      float NoL = max(dot(n, d), 0.0);
                  vec3 specular = (NoL*(brdf_pdf.xyz))/brdf_pdf.w/(1.0-diffuseTerm);
                  mask*=specular;
                  nrd = d;
              }
              vec2 ob2 = box(nro, LightDir, vec3(-boxSize), vec3(boxSize));
              vec3 nn;
              int hitid2 = -1;
              int igid2 = ignoreid;
              float tt2 = trace(nro, LightDir, nn,hitid2,igid2);
              hit = !(ob2.y < ob2.x || tt2 >= ob2.y - 1e-4);
              vec3 suncolor = hit||depth==0?vec3(0.0):LightColor*max(dot(LightDir,n),0.0);
              radiance +=mask*suncolor;
          }
          else//hit the sky
          {
              vec2 ob2 = box(nro, LightDir, vec3(-boxSize), vec3(boxSize));
              vec3 nn;
              int hitid2 = -1;
              int igid2 = ignoreid;
              float tt2 = trace(nro, LightDir, nn,hitid2,igid2);
              hit = !(ob2.y < ob2.x || tt2 >= ob2.y - 1e-4);
              vec3 suncolor = hit||depth==0?vec3(0.0):LightColor*max(dot(LightDir,n_last),0.0);
              color=1.0*texture(iChannel1, nrd).xyz+suncolor;
              radiance +=mask*color;            
              break;   
          }

          n_last = n;   
          ob = box(nro, nrd, vec3(-boxSize), vec3(boxSize));
        } 
        acc +=clamp(radiance,0.0,10.0);
    }
    
    acc/=float(S);
    normal_identity/=float(S);
    acc = clamp(acc,0.0,1.0);
        
    
    
#define R 4
#define V 10.0
#define V2 0.75

    vec3 acc_re = vec3(0.0);
    float acc_weight = 0.0;
    for(int i=-R;i<=R;i++)
    for(int j=-R;j<=R;j++)
    {
        vec4 last = texture(iChannel0,st+vec2(i,j)*texelsize);
        float weight = max(dot(last.rgb,acc),0.1)*pow((1.0-abs(last.a-normal_identity)),16.0)/(length(vec2(i,j))+1.0);
        acc_re+=last.rgb*weight;
        acc_weight+=weight;
    }
    vec4 last = texture(iChannel0,st);
    acc_re+=V*acc;
    acc_re/=(acc_weight+V);
    acc_re = mix(acc_re,last.rgb,V2);
    fragColor.rgb = acc_re;
    fragColor.a = normal_identity;
}



