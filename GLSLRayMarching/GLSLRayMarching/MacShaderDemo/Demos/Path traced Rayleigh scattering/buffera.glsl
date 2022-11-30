// spp per frame
const int SPP = 1;

const float PI = 3.141592653589793;

// Spectrum with its integral
const vec3 cie[48] = vec3[48](
    vec3( 0.000000f, 0.000000f, 0.000001f ),    // 360 nm
    vec3( 0.000006f, 0.000001f, 0.000026f ),    // 370 nm
    vec3( 0.000160f, 0.000017f, 0.000705f ),    // 380 nm
    vec3( 0.002362f, 0.000253f, 0.010482f ),    // 390 nm
    vec3( 0.019110f, 0.002004f, 0.086011f ),    // 400 nm
    vec3( 0.084736f, 0.008756f, 0.389366f ),    // 410 nm
    vec3( 0.204492f, 0.021391f, 0.972542f ),    // 420 nm
    vec3( 0.314679f, 0.038676f, 1.553480f ),    // 430 nm
    vec3( 0.383734f, 0.062077f, 1.967280f ),    // 440 nm
    vec3( 0.370702f, 0.089456f, 1.994800f ),    // 450 nm
    vec3( 0.302273f, 0.128201f, 1.745370f ),    // 460 nm
    vec3( 0.195618f, 0.185190f, 1.317560f ),    // 470 nm
    vec3( 0.080507f, 0.253589f, 0.772125f ),    // 480 nm
    vec3( 0.016172f, 0.339133f, 0.415254f ),    // 490 nm
    vec3( 0.003816f, 0.460777f, 0.218502f ),    // 500 nm
    vec3( 0.037465f, 0.606741f, 0.112044f ),    // 510 nm
    vec3( 0.117749f, 0.761757f, 0.060709f ),    // 520 nm
    vec3( 0.236491f, 0.875211f, 0.030451f ),    // 530 nm
    vec3( 0.376772f, 0.961988f, 0.013676f ),    // 540 nm
    vec3( 0.529826f, 0.991761f, 0.003988f ),    // 550 nm
    vec3( 0.705224f, 0.997340f, 0.000000f ),    // 560 nm
    vec3( 0.878655f, 0.955552f, 0.000000f ),    // 570 nm
    vec3( 1.014160f, 0.868934f, 0.000000f ),    // 580 nm
    vec3( 1.118520f, 0.777405f, 0.000000f ),    // 590 nm
    vec3( 1.123990f, 0.658341f, 0.000000f ),    // 600 nm
    vec3( 1.030480f, 0.527963f, 0.000000f ),    // 610 nm
    vec3( 0.856297f, 0.398057f, 0.000000f ),    // 620 nm
    vec3( 0.647467f, 0.283493f, 0.000000f ),    // 630 nm
    vec3( 0.431567f, 0.179828f, 0.000000f ),    // 640 nm
    vec3( 0.268329f, 0.107633f, 0.000000f ),    // 650 nm
    vec3( 0.152568f, 0.060281f, 0.000000f ),    // 660 nm
    vec3( 0.081261f, 0.031800f, 0.000000f ),    // 670 nm
    vec3( 0.040851f, 0.015905f, 0.000000f ),    // 680 nm
    vec3( 0.019941f, 0.007749f, 0.000000f ),    // 690 nm
    vec3( 0.009577f, 0.003718f, 0.000000f ),    // 700 nm
    vec3( 0.004553f, 0.001768f, 0.000000f ),    // 710 nm
    vec3( 0.002175f, 0.000846f, 0.000000f ),    // 720 nm
    vec3( 0.001045f, 0.000407f, 0.000000f ),    // 730 nm
    vec3( 0.000508f, 0.000199f, 0.000000f ),    // 740 nm
    vec3( 0.000251f, 0.000098f, 0.000000f ),    // 750 nm
    vec3( 0.000126f, 0.000050f, 0.000000f ),    // 760 nm
    vec3( 0.000065f, 0.000025f, 0.000000f ),    // 770 nm
    vec3( 0.000033f, 0.000013f, 0.000000f ),    // 780 nm
    vec3( 0.000018f, 0.000007f, 0.000000f ),    // 790 nm
    vec3( 0.000009f, 0.000004f, 0.000000f ),    // 800 nm
    vec3( 0.000005f, 0.000002f, 0.000000f ),    // 810 nm
    vec3( 0.000003f, 0.000001f, 0.000000f ),    // 820 nm
    vec3( 0.000002f, 0.000001f, 0.000000f )     // 830 nm
);

const float invSpecIntegral = 1.0 / 116.643;

float uintRangeToFloat(uint i)
{
    return float(i) / float(0xFFFFFFFFu);
}

// low-ish discrepency sequences

const uint LAMBDA = 0u;
const uint DOF_U = 1u;
const uint DOF_V = 2u;
const uint AA_U = 3u;
const uint AA_V = 4u;
const uint BASE = 5u;

const uint BRDF_U = 0u;
const uint BRDF_V = 1u;
const uint BOUNCE = 2u;

uint bounce;
uint frame;
uint pixel;
uint seed;


uint hash(uint i)
{
	i ^= i >> 12u;
	i *= 0xB5297A4Du;
	i ^= i >> 12u;
	i += 0x68E31DA4u;
	i ^= i >> 12u;
	i *= 0x1B56C4E9u;
	return i;
}

float random()
{
    return uintRangeToFloat(hash(seed++));
}


float prng(uint dimension)
{
    // 32 dimensional noise
    const int nDim = 32;
    
    // additive recurrence, using square roots of primes (some have been modified to not be too small)
    const uint sqPrimes[nDim] = uint[nDim](
        0x6a09e667u, 0xbb67ae84u, 0x3c6ef372u, 0xa54ff539u, 0x510e527fu, 0x9b05688au, 0x1f83d9abu, 0x5be0cd18u,
        0xcbbb9d5cu, 0x629a2929u, 0x91590159u, 0x452fecd8u, 0x67332667u, 0x8eb44a86u, 0xdb0c2e0bu, 0x47b5481du,
        0xae5f9155u, 0xcf6c85d1u, 0x2f73477du, 0x6d1826cau, 0x8b43d455u, 0xe360b595u, 0x1c456002u, 0x6f196330u,
        0xd94ebeafu, 0x9cc4a611u, 0x261dc1f2u, 0x5815a7bdu, 0x70b7ed67u, 0xa1513c68u, 0x44f93634u, 0x720dcdfcu
    );
    
    // low disrepency for dimensions < 32
    if (dimension < uint(nDim))
    {
        return uintRangeToFloat((frame + pixel) * sqPrimes[dimension]);
    }
    // noise after that
    else
    {
        return uintRangeToFloat(hash(frame + pixel));
    }
}


// implicit volume

float density(vec3 p)
{
    p = -p;
	vec3 w = p;
	float m = dot(w, w);
    
	for(int j = 0; j < 4; j++)
    {
		if(m > 1.2) break;
        
        #if 0
        
        // trig
        float a = 8.0 * acos(w.y * inversesqrt(m));
        float i = 8.0 * atan(w.x, w.z);
        w = m*m*m*m * vec3(sin(a) * sin(i), cos(a), sin(a) * cos(i)) + p;
        
        #elif 0
        
        // IQs
		float x = w.x;
		float y = w.y;
		float z = w.z;
        float x2 = x * x;
        float y2 = y * y;
        float z2 = z * z;
        float x4 = x2 * x2;
        float y4 = y2 * y2;
        float z4 = z2 * z2;
		float k3 = x2 + z2;
		float k2 = inversesqrt(k3 * k3 * k3 * k3 * k3 * k3 * k3);
		float k1 = x4 + y4 + z4 - 6.0 * y2 * z2 - 6.0 * x2 * y2 + 2.0 * z2 * x2;
		float k4 = x2 - y2 + z2;
		w.x = p.x +  64.0 * x * y * z * (x2 - z2) * k4 * (x4 - 6.0 * x2 * z2 + z4) * k1 * k2;
		w.y = p.y + -16.0 * y2 * k3 * k4 * k4 + k1 * k1;
		w.z = p.z + -8.0 * y * k4 * (x4 * x4 - 28.0 * x4 * x2 * z2 + 70.0 * x4 * z4 - 28.0 * x2 * z2 * z4 + z4 * z4) * k1 * k2;
        
        #else
        
        // faster version
		float x2 = w.x * w.x;
		float y2 = w.y * w.y;
		float z2 = w.z * w.z;
        float x4 = x2 * x2;
        float z4 = z2 * z2;
        float k1 = x2 * z2;
		float k2 = x2 + z2;
		float k3 = x4 + z4 + y2 * (y2 - 6.0 * k2) + 2.0 * k1;
        float k4 = k2 * k2 * k2;
		float k5 = k3 * inversesqrt(k4 * k4 * k2);
		float k6 = w.y * (k2 - y2);
		w.x = p.x + 64.0 * k6 * k5 * w.x * w.z * (x2 - z2) * (x4 - 6.0 * k1 + z4);
		w.y = p.y - 16.0 * k6 * k6 * k2 + k3 * k3;
		w.z = p.z - 8.0 * k6 * k5 * (x4 * (x4 - 28.0 * k1 + 70.0 * z4) + z4 * (z4 - 28.0 * k1));
        
        #endif
        
		m = dot(w, w);
	}
    
	return mix(1.0, 0.005, step(1.2, m));
}


// volume tracing using detla tracking

float trace(vec3 ro, vec3 rd, float l)
{
   
    float b = -dot(ro, rd);
    float d = b * b - dot(ro, ro) + 1.3;
    
    if(d < 0.0) return -1.0;
    
    float s = sqrt(d);
    
    float t = max(b - s, 0.0);
    float mt = b + s;
    
    float invMaxDensity = l*l*l*l * 2.0e-13;
    bool hit = false;
    for (int i = 0; i < 256 && !hit && t < mt; i++)
    {
        t -= log(1.0 - random()) * invMaxDensity;
        hit = random() < density(ro + rd * t);
    }
     
    return hit && t < mt ? t : -1.0;
}

// brdf importance sampling

vec3 brdfSample()
{
    vec2 r = vec2(2.0 * PI * prng(BASE + bounce * BOUNCE + BRDF_U),
                  acos(2.0 * prng(BASE + bounce * BOUNCE + BRDF_V) - 1.0));
    vec2 c = cos(r), s = sin(r);
    return vec3(s.y * s.x, s.y * c.x, c.y);
}

float brdfPdf(vec3 wi)
{
    return 0.25 / PI;
}


float brdf(vec3 wi)
{
    return 3.0 * (1.0 + wi.z * wi.z) / (PI * 16.0);
}

// wavelength importance sampling (proportional to luminance)

float lambdaSample()
{
    float y = prng(LAMBDA), g;
    
    int i;
    for (i = 0; i < 47 && y >= 0.0; i++)
    {
        g = cie[i].y * invSpecIntegral;
        y -= g * 10.0;
    }
    
    return float(355 + i * 10) + y / g;
}


float lambdaPdf(float l)
{
    int index = int(l * 0.1 - 35.5);
    if(index < 0 || index > 47) 
    {
        return 0.0;
    }
    return cie[index].y * invSpecIntegral;
}


vec3 wavelength2xyz(float l)
{
	float x = l * 0.1 - 36.0;
    int index = int(x);
    if(index < 0 || index >= 47) 
    {
        return vec3(0.0);
    }
    return mix(cie[index], cie[index + 1], fract(x)) * invSpecIntegral;
}


vec3 ortho(vec3 v)
{
    return normalize(abs(v.x) > abs(v.z) ? vec3(-v.y,v.x,0.) : vec3(0.,-v.z,v.y));
}


float blackbody(float l, float t)
{
    const float h = 6.62607004e-16;
    const float k = 1.38064852e-5;
    const float c = 299792458e9;
    
    float a = 2.0 * h * c * c;
    float b = h * c / (l * k * t);
    return a / (l*l*l*l*l  * (exp(b) - 1.0));
}


float background(vec3 rd, float l)
{
    return 0.0;
}


void mainImage(out vec4 o, vec2 u)
{
    pixel = hash(uint(gl_FragCoord.x) + uint(gl_FragCoord.y) * 0x452fecd8u);
    frame = iFrame == 0  || iMouse.z > 0.0 ? 0u : uint(texelFetch(iChannel0, ivec2(u), 0).a);
    seed = hash(frame) ^ pixel;
    
    o.rgb = iFrame == 0 ? vec3(0) : texelFetch(iChannel0, ivec2(u), 0).rgb;
    
    vec2 rot = PI * (iMouse.yx - iResolution.yx * 0.5) / iResolution.y;
    vec2 c = cos(rot), s = sin(rot);
    mat3 rx = mat3(1, 0, 0, 0, c.x, -s.x, 0, s.x, c.x);
    mat3 ry = mat3(c.y, 0, -s.y, 0, 1, 0, s.y, 0, c.y);
    mat3 r = ry * rx;
    
    for (int i = 0; i < SPP; i++)
    {
        float a = prng(DOF_U) * PI * 2.0;
        vec2 aperture = 0.05 * sqrt(prng(DOF_V)) * vec2(cos(a), sin(a));
        vec2 uv = (floor(u) + vec2(prng(AA_U), prng(AA_V)) - iResolution.xy * 0.5) / iResolution.y;
        vec3 ro = vec3(aperture, -4.0);
        vec3 rd = normalize(vec3(uv * 3.9 / 6.0 - aperture, 3.9));
        
        ro = r * ro;
        rd = r * rd;
        
        ro += vec3(0.0, 0.8, 0.0);
        
        float li = 0.0;
        float att = 1.0;
        
        float l = lambdaSample();
        
        for (bounce = 0u; bounce < 8u; bounce++)
        {
            float t = trace(ro, rd, l);
            
            if (t < 0.0)
            {
                li += att * background(rd, l);
                break;
            }
            
            ro += rd * t;
            
            vec3 b = ortho(rd);
            mat3 brdf2World = mat3(cross(b, rd), b, rd);
            mat3 world2Brdf = transpose(brdf2World);
            
            const vec3 lDir = normalize(vec3(1.0));
            
            if (trace(ro, lDir, l) < 0.0)
            {
                li += att * brdf(world2Brdf * lDir) * blackbody(l, 6400.0) * 0.0003;
            }
            
            rd = brdfSample();
            att *= brdf(rd) / brdfPdf(rd);
            
            rd = brdf2World * rd;
        }
        
        vec3 col = li / lambdaPdf(l) * wavelength2xyz(l);
        
        frame++;
        
        o = vec4(mix(o.rgb, col, 1.0 / float(frame)), frame);
    }
}