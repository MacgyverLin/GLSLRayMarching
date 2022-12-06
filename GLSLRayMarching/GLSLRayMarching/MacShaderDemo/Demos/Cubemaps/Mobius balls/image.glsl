float pi = 3.141592;

vec2 r(vec2 v,float y)
{
    return cos(y)*v+sin(y)*vec2(-v.y,v.x);
}
 
vec3 textureAVG(samplerCube tex, vec3 tc) {
    const float diff0 = 0.35;
    const float diff1 = 0.12;
 	vec3 s0 = texture(tex,tc).xyz;
    vec3 s1 = texture(tex,tc+vec3(diff0)).xyz;
    vec3 s2 = texture(tex,tc+vec3(-diff0)).xyz;
    vec3 s3 = texture(tex,tc+vec3(-diff0,diff0,-diff0)).xyz;
    vec3 s4 = texture(tex,tc+vec3(diff0,-diff0,diff0)).xyz;
    
    vec3 s5 = texture(tex,tc+vec3(diff1)).xyz;
    vec3 s6 = texture(tex,tc+vec3(-diff1)).xyz;
    vec3 s7 = texture(tex,tc+vec3(-diff1,diff1,-diff1)).xyz;
    vec3 s8 = texture(tex,tc+vec3(diff1,-diff1,diff1)).xyz;
    
    return (s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8) * 0.111111111;
}

float somestep(float t)
{
    return pow(t, 4.0);
}

vec3 smin(vec3 a, vec3 b)
{
    if (a.x < b.x)
        return a;
    
    return b;
}

vec3 smax(vec3 a, vec3 b)
{
	if (a.x > b.x)
        return a;
    
    return b;
}

vec3 sinv(vec3 a)
{
	return vec3(-a.x, a.y, a.z);    
}

vec3 textureBlured(samplerCube tex, vec3 tc) {
   	vec3 r = textureAVG(tex,vec3(1.0,0.0,0.0));
    vec3 t = textureAVG(tex,vec3(0.0,1.0,0.0));
    vec3 f = textureAVG(tex,vec3(0.0,0.0,1.0));
    vec3 l = textureAVG(tex,vec3(-1.0,0.0,0.0));
    vec3 b = textureAVG(tex,vec3(0.0,-1.0,0.0));
    vec3 a = textureAVG(tex,vec3(0.0,0.0,-1.0));
        
    float kr = dot(tc,vec3(1.0,0.0,0.0)) * 0.5 + 0.5; 
    float kt = dot(tc,vec3(0.0,1.0,0.0)) * 0.5 + 0.5;
    float kf = dot(tc,vec3(0.0,0.0,1.0)) * 0.5 + 0.5;
    float kl = 1.0 - kr;
    float kb = 1.0 - kt;
    float ka = 1.0 - kf;
    
    kr = somestep(kr);
    kt = somestep(kt);
    kf = somestep(kf);
    kl = somestep(kl);
    kb = somestep(kb);
    ka = somestep(ka);    
    
    float d;
    vec3 ret;
    ret  = f * kf; d  = kf;
    ret += a * ka; d += ka;
    ret += l * kl; d += kl;
    ret += r * kr; d += kr;
    ret += t * kt; d += kt;
    ret += b * kb; d += kb;
    
    return ret / d;
}

//repeat around y axis n times
void rp(inout vec3 p, float n) {
	float w = 2.0*pi/n;
	float a = atan(p.z, p.x);
	float r = length(p.xz);
	a = mod(a+pi*.5, w)+pi-pi/n;
	p.xz = r*vec2(cos(a),sin(a));
}

vec3 moebius(vec3 p, vec3 q)
{
  float a = atan(p.z,p.x);
  vec2 p2 = vec2(length(p.xz),p.y);
  p2.x -= q.z;
  p2 = r(p2, a*0.5);
  vec2 p3 = r(p2, pi/4.0);
  vec2 tc = vec2(p3.y,a);
  float d = abs(p2.y)-q.x;
  d = max(d,abs(p2.x)-q.y);
  return vec3(d, tc);
}
 
vec3 dualmoebius(vec3 p)
{
	float bandSize = 1.5;
	float radius = 5.0;
	float bandThickness = 0.75;
	return smax(moebius(p, vec3(bandSize, bandThickness, radius)), sinv(moebius(p, vec3(bandSize - bandThickness, bandThickness+0.1, radius))));
}
 
vec3 sphere(vec3 p, float r)
{
    vec3 n = normalize(p);
    vec2 tc = asin(n.xz)/pi + 0.5;
	return vec3(length(p) - r, tc * 2.0);
}

vec3 spheres(vec3 p)
{
	rp(p, 12.0);
	p.x += 5.0;
	return sphere(p, 0.75);	
}

vec3 f( vec3 p )
{
	vec2 mouse = vec2(sin(iTime), cos(iTime));//iMouse.xy / iResolution.xy;
	//p.xz = r(p.xz, mouse.x);
	p.yz = r(p.yz, 0.1 * iTime);
    
    vec3 q = p;
	q.xz = r(q.xz, 0.5 * iTime);
    
	return smin(sphere(p, 3.0), smin(spheres(q), dualmoebius(q)));
}

vec4 getcolor(vec3 hit, vec3 ray, vec3 normal, float t, vec3 d) 
{
    vec4 background = vec4(texture(iChannel0, ray).xyz, 0.0);
    if( t < 26.0 )
    {
        // material
        float fresnel_pow = 2.0;
        float fresnel_bias = 0.125;
        float color_intensity = 1.5;
        float roughness_bias = 1.5;
        float roughness_coverage = 0.2;
        float shininess = 0.6;
        
        vec3 color_mod = (0.5+0.5*texture(iChannel1, d.yz).rgb) * color_intensity;
                
        // IBL
        vec3 ibl_diffuse = textureBlured(iChannel0,normal);
        
        // fresnel
        float fresnel = fresnel_bias + (1.0 - fresnel_bias) * max(1.0 - dot(normal,-ray), 0.0);
        fresnel = pow(fresnel,fresnel_pow);
        
        // surface roughness
        float rough = (1.0 - roughness_bias) + roughness_bias * length(texture(iChannel2, d.yz * 0.1).rgb);
        rough = 1.0 - ((1.0-rough) * smoothstep(0.4, 0.6, length(ibl_diffuse)));
        rough *= min(1.0, pow(length(color_mod), 2.0));
        
        vec4 foreground = vec4(((1.0 - roughness_coverage) + roughness_coverage * rough) * ibl_diffuse * color_mod, max(0.0, min(1.0, shininess * fresnel * rough)));
        return mix(foreground, background, smoothstep(0.0, 0.005, dot(normal, ray)));
    } 
    else 
    {   
        return background;
    }
}

// ao
float ao(vec3 v, vec3 n) 
{
    const int ao_iterations = 10;
    const float ao_step = 0.2;
    const float ao_scale = 0.75;
    
	float sum = 0.0;
	float att = 1.0;
	float len = ao_step;
    
	for (int i = 0; i < ao_iterations; i++)
    {
		sum += (len - f(v + n * len).x) * att;		
		len += ao_step;		
		att *= 0.5;
	}
	
	return 1.0 - max(sum * ao_scale, 0.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor.xyz = vec3(0);
    
    vec3 q = vec3((fragCoord.xy / iResolution.xy - 0.5), 1.0); 
    q.x *= iResolution.x / iResolution.y;
    vec3 p = vec3(0, 0.0, -10.0);
    q = normalize(q);

    p.xz = r(p.xz, 0.05*iTime);
    q.xz = r(q.xz, 0.05*iTime);

    const int reflectionCount = 3;
    const int raymarchingSteps = 80;
    vec3 colors[reflectionCount];
    float factors[reflectionCount];
    int reflections = 0;
    for (int iter = 0; iter < reflectionCount; ++iter)
    {
        float t=0.;
        vec3 d = vec3(0);
        float steps = 0.0;
        for (int tt=0; tt < raymarchingSteps; ++tt )
        {
            d = f(p+q*t);
            t += d.x * 0.95;
            if( !(t<=26.0)||d.x<=0.000001)
            {
                break;
            }
            steps = float(tt);
        }

        vec3 hit = p+q*t;

        vec2 e = vec2(0.001, 0.00);
        vec3 normal= vec3( f(hit + e.xyy).x - f(hit - e.xyy).x, f(hit + e.yxy).x - f(hit - e.yxy).x, f(hit + e.yyx).x - f(hit - e.yyx).x);
        normal= normalize(normal);
        
        vec4 color = getcolor(hit, q, normal, t, d);
        colors[iter] = color.rgb * (1.0 - color.w) * ao(hit, normal);
        factors[iter] = color.w;
        if (t >= 26.0)
            break;

        ++reflections;
        q = reflect(q, normal);
        p = hit + q * 0.001;   
    }

    float factor = 1.0;
    for (int i = 0; i < reflectionCount; ++i)
    {
        fragColor.xyz += factor * colors[i];
        factor *= factors[i] * 1.5;

        if (i >= reflections)
            break;        
    }
}