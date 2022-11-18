/**
 * Created by Steven Sell (ssell) / 2017
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * https://www.shadertoy.com/view/ldjBzt
 */

#define TerrainNearClip    0.1
#define TerrainFarClip     25000.0
#define TerrainMaxSteps    100
#define TerrainMaxHeight   800.0
#define TerrainTexScale    0.0005
#define TerrainPersistence 0.5

#define CityNearClip       0.1
#define CityFarClip        150.0
#define CityMaxSteps       200

#define NumPathPoints      20
#define PathClamp(x)       clamp(x, 0, NumPathPoints - 1)

const float TexDim      = 1.0 / 256.0;
const mat2  m2          = mat2(0.8, 0.6, -0.6, 0.8);

const vec3 SunDir       = normalize(vec3(0.5, 1.5, 1.25));
const vec3 SunColor     = vec3(1.0, 1.0, 0.7);

const vec3 SkyDir       = normalize(vec3(0.0, 1.0, 0.0));
const vec3 SkyColor     = vec3(0.0, 0.0, 1.0);

const vec3 AmbDir       = normalize(SunDir * vec3(-1.0, 0.0, -1.0));
const vec3 AmbColor     = vec3(1.0, 1.0, 1.0);

const vec3 StartPos     = vec3(1100.0, 0.0, 1000.0);
const vec3 EndPos       = vec3(1100.0, 0.0, 26100.0);
const vec3 CityPos      = vec3(1400.0, 200.0, 13500.0);

const float TimeStep    = 6.5;
const float SceneLength = TimeStep * float(NumPathPoints);

const vec2 Path[NumPathPoints] = vec2[]( vec2(1100.0, 1000.0), vec2(1100.0, 3000.0), vec2(1200.0, 4800.0), vec2(1100.0, 6500.0), vec2(1250.0, 8000.0), vec2(1400.0, 9500.0), vec2(1400.0, 11000.0), vec2(1000.0, 13000.0), vec2(1000.0, 14000.0), vec2(1800.0, 14000.0), vec2(1800.0, 13000.0), vec2(600.0, 12500.0), vec2(600.0, 14500.0), vec2(1400.0, 16000.0), vec2(1400.0, 17500.0), vec2(1250.0, 19300.0), vec2(1100.0, 20500.0), vec2(1200.0, 22300.0), vec2(1100.0, 24100.0), vec2(1100.0, 27100.0));


//------------------------------------------------------------------------------------------
// Ray 
//------------------------------------------------------------------------------------------
    
struct Ray
{
	vec3 origin;
    vec3 direction;
};
    
//------------------------------------------------------------------------------------------
// Camera Structures and Functions
//------------------------------------------------------------------------------------------

struct Camera
{
    vec3 right;
    vec3 up;
    vec3 forward;
    vec3 origin;
};

Ray Camera_GetRay(in Camera camera, vec2 uv)
{
    Ray ray;
    
    uv    = (uv * 2.0) - 1.0;
    uv.x *= (iResolution.x / iResolution.y);
    
    ray.origin    = camera.origin;
    ray.direction = normalize((uv.x * camera.right) + (uv.y * camera.up) + (camera.forward * 2.0));

    return ray;
}

Camera Camera_LookAt(vec3 origin, vec3 lookAt)
{
	Camera camera;
    
    camera.origin  = origin;
    camera.forward = normalize(lookAt - camera.origin);
    camera.right   = normalize(cross(camera.forward, vec3(0.0, 1.0, 0.0)));
    camera.up      = normalize(cross(camera.right, camera.forward));
    
    return camera;
}

// Catmull-Rom Matrix
const mat4 CRM = mat4(-0.7, 2.0 - 0.7, 0.7 - 2.0, 0.7, 2.0 * 0.7, 0.7 - 3.0, 3.0 - 2.0 * 0.7, -0.7, -0.7, 0.0, 0.7, 0.0, 0.0, 1.0, 0.0, 0.0);

vec2 InterpCRM(vec2 G1, vec2 G2, vec2 G3, vec2 G4, float t) 
{
    vec2 A = G1 * CRM[0][0] + G2 * CRM[0][1] + G3 * CRM[0][2] + G4 * CRM[0][3];
    vec2 B = G1 * CRM[1][0] + G2 * CRM[1][1] + G3 * CRM[1][2] + G4 * CRM[1][3];
    vec2 C = G1 * CRM[2][0] + G2 * CRM[2][1] + G3 * CRM[2][2] + G4 * CRM[2][3];
    vec2 D = G1 * CRM[3][0] + G2 * CRM[3][1] + G3 * CRM[3][2] + G4 * CRM[3][3];

    return t * (t * (t * A + B) + C) + D;
}

// Interpolates the camera along the pre-defined path. Updates only .xz position.
vec3 CameraPos(float time)
{
    float tmod = mod(iTime, SceneLength);  // Repeat the path every 'SceneLength' seconds
    
    int i = int(tmod / TimeStep);          // Determine the current path step.
                                           // We are on 'b' and heading to 'c'.
    int a = PathClamp(i - 1);              
    int b = PathClamp(i + 0);
    int c = PathClamp(i + 1);
    int d = PathClamp(i + 2);
    
    vec2 pxz = InterpCRM(Path[a], Path[b], Path[c], Path[d], mod(tmod, TimeStep) / TimeStep);
    
    return vec3(pxz.x, 0.0, pxz.y);
}

//------------------------------------------------------------------------
// Terrain Generation
//------------------------------------------------------------------------

float DistanceRatioCamera(vec2 p)
{
    // Returns ratio [0, 1] depending on distance to camera start/end position.
    // 0.0 = At camera start/end position.
    // 1.0 = 4000.0 or more units from camera start/end position.
    
	float ds = length(p - StartPos.xz);
    float de = length(p - EndPos.xz);
    
    float d = min(ds, de);
    
    return smoothstep(0.0, 1.0, clamp(d / 4000.0, 0.325, 1.0));
}

float DistanceRatioCity(vec2 p)
{
    // Returns ratio [0, 1] depending on distance to city position.
    // 0.0 = At city center.
    // 1.0 = 7500.0 or more units away from city center.
    
	float d = distance(p, CityPos.xz);
    float r = clamp(d / 7500.0, 0.0, 1.0);
    
    return smoothstep(0.0, 1.0, pow(r, 3.1));
}

// Returns the terrain noise heightmap value (.x) and it's derivate (.yz) for normals
vec3 TerrainNoiseRaw(vec2 p)
{
    vec2 pfract = fract(p);
    vec2 pfloor = floor(p);
    
    // Quintic interpolation factor (6x^5-15x^4+10x^3) and it's derivative (30x^4-60x^3+30x^2)
    vec2 lfactor = pfract * pfract * pfract * (pfract * (pfract * 6.0 - 15.0) + 10.0);
    vec2 lderiv  = 30.0 * pfract * pfract * (pfract * (pfract - 2.0) + 1.0);
    
    /** 
     * Noise LUT sample points (p = pfloor):
     *
     *      ©°©¤©¤©¤©Ð©¤©¤©¤©´
     *      ©¦ c ©¦ d ©¦
     *      ©À©¤©¤©¤©à©¤©¤©¤©È
     *      ©¦ a ©¦ b ©¦
     *      p©¤©¤©¤©Ø©¤©¤©¤©¼
	 */
    
    // Use textureLod instead of texture so that Angle (Windows Firefox) doesn't choke.
    float a = textureLod(iChannel0, (pfloor + vec2(0.5, 0.5)) * TexDim, 0.0).r;
    float b = textureLod(iChannel0, (pfloor + vec2(1.5, 0.5)) * TexDim, 0.0).r;
    float c = textureLod(iChannel0, (pfloor + vec2(0.5, 1.5)) * TexDim, 0.0).r;
    float d = textureLod(iChannel0, (pfloor + vec2(1.5, 1.5)) * TexDim, 0.0).r;
    
    /**
     * For the value (.r) we perform a bilinear interpolation with a 
     * quintic factor (biquintic?) over the four sampled points.
     *
     * .r could be written as:
     * 
     *    mix(mix(a, b, lfactor.x), mix(c, d, lfactor.x), lfactor.y)
     *
     * The mixes are factored out so that the individual components
     * (k0, k1, k2, k4) can be used in finding the derivative (for the normal).
     */
    
    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k4 = a - b - c + d;
    
	return vec3(
        k0 + (k1 * lfactor.x) + (k2 * lfactor.y) + (k4 * lfactor.x * lfactor.y),  // Heightmap value
        lderiv * vec2(k1 + k4 * lfactor.y, k2 + k4 * lfactor.x));                 // Value derivative
}

vec3 TerrainNoise(in vec2 p, int octaves)
{
    // Samples the terrain heightmap.
    // There are certain parts of the terrain that could be better (which
    // I wont point out so hopefully you don't notice it too), but I just
    // really like the first mountain at the start of the scene.
    
    float sratio = DistanceRatioCamera(p);   // Ratio [0, 1] to the camera start position.
    float cratio = DistanceRatioCity(p);     // Ratio [0, 1] to the city position.
    
    float amplitude = 1.0;
    float value     = 0.0;                   // Cumulative noise value
    
	vec2  deriv     = vec2(0.0);             // Cumulative noise derivative
	vec2  samplePos = (p * TerrainTexScale);
    
    for(int i = 0; i < octaves; ++i)
    {
        // For each iteration we accumulate the noise value, derivative, and
        // scale/adjust the sample position.
        
        vec3 noise = TerrainNoiseRaw(samplePos);
        
        // 'noise.x * amplitude': Reduce the contribution of each successive iteration
        // '* (sratio + 0.1)': Flatten out the terrain at camera start/end
        // '/ (...)': Sharpen the mountain slopes
        
        deriv += noise.yz;
        value += (noise.x * amplitude * (sratio + 0.1)) / (0.9 + dot(deriv, deriv));
        
        amplitude *= TerrainPersistence;
        samplePos  = m2 * samplePos * 1.9;
    }
    
    // Here we compose the height range for the terrain.
    // sratio and cratio are used to form the 'craters' or terrain openings
    // that the camera starts at (sratio) and the city resides in (cratio).
    // Without this, the entire terrain would be mountains and unusable.
    // The '+ p.y * 0.01' just accentuates the peaks.
    
    float height = mix(100.0, TerrainMaxHeight + p.y * 0.01, min(sratio, cratio));
    
	return vec3(height * value, deriv);
}

// Three levels of terrain quality:
//     High Quality:   Used for normals.
//     Medium Quality: Used for terrain geometry.
//     Low Quality:    Used for camera altitude.

vec3 TerrainNoiseHQ(vec2 p) { return TerrainNoise(p, 15); }
vec3 TerrainNoiseMQ(vec2 p) { return TerrainNoise(p, 9); }
vec3 TerrainNoiseLQ(vec2 p) { return TerrainNoise(p, 3); }

vec3 TerrainNormal(vec3 pos, float depth)
{
    /** 
     * Adjust the gradient epsilon based on geometry depth in scene.
     * This provides smoother results than fixed epsilon step sizes
     * when the scene is large. Example:
     *
     *     At depth N, adjacent texels may be 1 world unit apart.
     *     So having an epsilon in the range of 1 would produce 
     *     accurate and smooth normals.
     *
     *     But at depth N*M, adjacent texels may be 100 world units apart.
     *     So having an epsilon at range of 1 would produce potentially
     *     discontinous normals that appear noisy and inaccurate.
     */
    
    vec2 eps = vec2(0.002 * depth, 0.0 );
    
    return normalize(vec3(TerrainNoiseHQ(pos.xz - eps.xy).x - TerrainNoiseHQ(pos.xz + eps.xy).x,
                          2.0 * eps.x,
                          TerrainNoiseHQ(pos.xz - eps.yx).x - TerrainNoiseHQ(pos.xz + eps.yx).x));
}

vec2 MarchTerrain(Ray ray)
{
    vec3 pos = vec3(0.0);
    
    float depth = TerrainNearClip;
    float sdf   = 0.0;
    
    for(int steps = 0; steps < TerrainMaxSteps; ++steps)
    {
        pos = ray.origin + (ray.direction * depth);
        sdf = pos.y - TerrainNoiseMQ(pos.xz).x;
        
        if(sdf < (0.002 * depth) || (depth > TerrainFarClip))
        {
            break;
        }
        
        depth += sdf * 0.5;
    }
    
    return vec2(depth, 0.0);
}

//------------------------------------------------------------------------
// City Generation
//------------------------------------------------------------------------

vec3 RotX(in vec3 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    
    return vec3(p.x, (c * p.y) - (s * p.z), (s * p.y) + (c * p.z));
}

vec3 Repeat(vec3 p, vec3 c)
{
	return mod(p, c) - (0.5 * c);    
}
float Box(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
 	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float HexPrism(vec3 p, vec2 h)
{
    vec3 q = abs(p);
    return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
}

float smin( float a, float b, float k )
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0 - h);
}

vec2 Tower(vec3 pos)
{
    // Constructs the tower, which is the focal point of the scene.
    // Originally, the entire city was going to be made out of
    // 3D voronoi noise or similar, and there was not going to be
    // any central tower (there is no such tower in the AtMoM story).
    
    // But that didn't really pan out, so I started hand-making
    // a few building designs with the intent of repeating them at 
    // various sizes. Again, I wasn't happy with the result.
    
    // Then I stumbled across this design, and felt immediately
    // it should be the central landmark of the city and everything
    // should radiate out from it. 
    
    // It is alien enough to definitely not be of human origination.
    // But at the same time, if colored white, the sides start to 
    // resemble a spine or similar structure.
    
    // There is also the benefit that it looks fairly unassuming from
    // far away, particularly when shadowed.
    
    // The base shape of it is a box, but the width decreases slightly
    // from the bottom to the top (w variable). The change is subtle
    // but keeps it from being perfectly straight lines.
    
    float id   = 0.0;                                               // Used for later texturing
    float w    = mix(11.45, 10.0, clamp(pos.y / 50.0, 0.0, 1.0));   // Box width
    float smod = mix(0.65, 0.625, clamp(pos.y / 50.0, 0.0, 1.0));   // 's' modifier
    float box  = Box(pos, vec3(w, 130.0, w));                       // Base shape
    float s    = 5.0;                                               // Used in positioning and sphere size
    
    for(int i = 0; i < 7; ++i)
    {
        // For each iteration we cut away at the tower box with spheres.
        // Simple and cheap, just have to get the placement/size right.
        
        vec3 p  = Repeat(pos, vec3(3.55, 1.5, 3.55) * s);
        
    	float c = length(p) - s;
        float t = max(box, -c);
        
        s *= smod;
        
        if(t > box)
        {
            // Save the iteration (id) that this surface was cut for later shading.
            id = float(i);
            box = t;
        }
    }
    
    // smin with a sphere at the bottom of the tower where it connects
    // to the base. This gives the core a way to end plus adds on another
    // slight alien component.
    
    float ts = length(pos - vec3(0.0, -12.0, 0.0)) - 10.0;
    box = smin(box, ts, 10.0);
    
    return vec2(box, id);
}

vec2 Base(vec3 pos)
{
    // Constructs the base of the tower.
    // It is made of two stacked hexes (the bottom slightly wider
    // than the top) that are cut away to reveal floors, walls, etc.
    
    float id = 0.0;
    float s = 2.025;
    
    // Rotate the hexes onto their sides.
    vec3 rpos = RotX(pos, 3.14 * 0.5);
    
    // The top base hex and then the bottom, wider hex sminned onto it.
    float r = HexPrism(rpos, vec2(30.0, 45.0));
    r = smin(r, HexPrism(rpos + vec3(0.0, 0.0, 20.0), vec2(36.5, 52.5)), 10.0);
    
    for(int i = 0; i < 3; ++i)
    {
        // Each iteration we cut away at the base using boxes.
        // Earlier versions of this produced a base that resembled
        // the sides of a gothic cathedral. It was actually quite 
        // nice but the city obscures that portion of the base now.
        
        vec3 p = pos - vec3(0.0, 10.0, 0.0);
        p = Repeat(pos, vec3(3.0, 2.10, 3.0) * s);
        
    	float b = Box(p, vec3(s));
        float t = max(r, -b);
        
        s *= 0.65;
        
        if(t > r)
        {
            // Save the iteration (id) that this surface was cut for later shading.
            id = float(i);
            r = t;
        }
    }
    
    return vec2(r, id);
}

vec2 SCity(vec3 pos)
{
    // The city is composed of expanding hexes that are carved away. 
    // The goal was to make something that felt massive but has been
    // beaten away by countless years of harsh weather.
    
    // Each successive hex also gets slightly shorter. This helps to
    // make the city feel larger and also breaks up the horizon to 
    // reduce depth-related artifacts.
    
	vec3 rpos = RotX(pos, 3.14 * 0.5);    // Rotate the hex prisms on their sides
    
    float r = CityFarClip;
    float id = 0.0;
    
    float csize = 40.0;                   // Cut-out hex size
    float hsize = 80.0;                   // Primary hex size
    
    for(int i = 0; i < 4; ++i)            // Construct the city base structure.
    {                                   
        // We have a primary hex (h) and it's cutout (c).
        // This prevents outer hexes from overlapping inner ones, and also
        // provides separation which may have been roads at one point in time.
        
        float c = HexPrism(rpos, vec2(csize, 60.0));
        float h = HexPrism(rpos, vec2(hsize, 10.0 * mix(3.0, 1.0, float(i) / 3.0)));
        
        r = min(r, max(h, -c));
        
        csize = hsize * 1.1;
        hsize = csize * 2.0;
    }
    
    float s0 = 2.025;
    float s1 = 17.25;
    
    for(int i = 0; i < 3; ++i)
    {
        // Here we cut away at the hex bases.
        // This is sligtly modified from the Base algorithm.
        
        // There are two kinds of cuts being done: box and sphere.
        
        // The boxes create the appearance of floors, balconies, etc.
        // The spheres add a slight alien feel and also an increased sense of disrepair.
        
        vec3 p0 = Repeat(pos, vec3(3.0, 2.0, 3.0) * s0);
    	vec3 p1 = Repeat(pos, vec3(3.0, 2.0, 3.0) * s1); 
        
    	float b0 = Box(p0, vec3(s0));
        float b1 = length(p1) - s1;
        
        float t = max(r, -min(b0, b1));
        
        s0 *= 0.625;
        s1 *= 0.415;
        
        if(t > r)
        {
            // Save the iteration (id) that this surface was cut for later shading.
            id = float(i);
            r = t;
        }
    }
    
    return vec2(r, id);
}

vec2 CitySDF(vec3 pos)
{
    // Todo: Factor out all of these 'if' statements...
    
    pos -= CityPos;
    pos *= 0.165;      // Make the city larger to fill up the crater
    
    vec2 tower = Tower(pos - vec3(0.0, 50.0, 0.0));  // Main tower
    vec2 base  = Base(pos);                          // Base of the tower
    vec2 city  = SCity(pos);                         // Surrounding city
    
    if(tower.x < base.x && tower.x < city.x)
    {
        return tower;
    }
    
    if(base.x < tower.x && base.x < city.x)
    {
        return base;
    }
    
    // Snow build up at the bottom of the city
    float snow = smin(pos.y + 10.0, city.x, 2.0);
    
    if(snow < city.x)
    {
        return vec2(snow, -1.0);
    }
    
    return city;
}

vec2 MarchCity(in Ray ray)
{
	float depth = CityNearClip;
    vec2  sdf = vec2(0.0);
    
    vec3 pos = vec3(0.0);
    
    for(int i = 0; i < CityMaxSteps; ++i)
    {
   		pos = ray.origin + (ray.direction * depth);
        sdf = CitySDF(pos);
        
        if(sdf.x < CityNearClip)
        {
            return vec2(depth, sdf.y);
        }
        
        depth += sdf.x * 6.0;
    }
    
    return vec2(depth, -1.0);
}

float CalcShadow(vec3 pos, vec3 lDir)
{
    float tshadow = 1.0;    // Terrain shadow
    float cshadow = 1.0;    // City Shadow
    
    float deptht = 40.0;    // Terrain start depth
    float depthc = 10.0;    // City start depth
    
    float cratio = DistanceRatioCity(pos.xz);
    
    // If not within the flat bowl of the city
    if(cratio >= 0.20)
    {
        // Terrain Shadow
        for(int i = 0; i < 16; ++i)
        {
            vec3 pt = pos + (deptht * lDir);
            float sdft = pt.y - TerrainNoiseMQ(pt.xz).x;

            tshadow = min(tshadow, 8.0 * sdft / deptht);
            deptht += sdft;

            if((sdft < 0.01) || (pt.y > TerrainMaxHeight * 10.0))
            {
                break;
            }
        }
    }
    
    // If not in dark terrain shadow and near the city
    if((tshadow > 0.1) && (cratio < 0.35))
    {
        // City Shadow
    	for(int i = 0; i < 16; ++i)
        {
            vec3 pc = pos + (depthc * lDir);
            float sdfc = CitySDF(pc).x;
            
            cshadow = min(cshadow, 8.0 * sdfc / depthc);
            depthc += sdfc;
            
            if((sdfc < 0.01) || (sdfc > 20.0))
            {
                break;
            }
        }
    }
    
    return clamp(min(tshadow, cshadow), 0.1, 1.0);
}

vec3 CityNormal(vec3 pos, float t)
{
	vec2 eps = vec2(0.001 * t, 0.0);
    return normalize(
        vec3(CitySDF(pos + eps.xyy).x - CitySDF(pos - eps.xyy).x,
             CitySDF(pos + eps.yxy).x - CitySDF(pos - eps.yxy).x,
             CitySDF(pos + eps.yyx).x - CitySDF(pos - eps.yyx).x));
}

//------------------------------------------------------------------------
// Render Terrain
//------------------------------------------------------------------------

vec3 Sky(vec3 rd)
{
    float sun = pow(abs(dot(rd, SunDir)), 15.0);
    vec3 sky = mix(vec3(0.29804, 0.61569, 0.92157), vec3(0.20980, 0.41764, 0.79215), clamp(abs(rd.y) * 2.0, 0.0, 1.0));
    
    return mix(sky, vec3(1.0), sun);
}

vec3 Lighting(vec3 albedo, vec3 pos, vec3 norm, vec3 rd)
{
    float shadow = 1.0;
    float direct =  clamp(dot(norm, SunDir), 0.0, 1.0);
    
    if(direct > 0.01)
    {
        shadow = CalcShadow(pos, SunDir);
    }
    
    vec3 sunLight  = SunColor * direct * 1.5 * shadow;
    vec3 skyLight  = SkyColor * clamp(0.5 + (0.5 * norm.y), 0.0, 1.0) * 0.1;
    vec3 ambLight  = AmbColor * clamp(dot(norm, AmbDir), 0.0, 1.0) * 0.1;
  	vec3 diffLight = (sunLight + skyLight + ambLight) * albedo;
    
    vec3 reflVec   = reflect(-SunDir, norm);
    vec3 specLight = pow(max(0.0, dot(rd, -reflVec)), 16.0) * vec3(0.35) * shadow;
    
    return (diffLight + specLight);
}

vec3 CalcExpFog(vec3 color, vec3 pos, Ray ray)
{
    // We decrease fog intensity as we get closer to the city center
    // so that it is clearer to see. This also allows the opening
    // to be foggier/harsher weather conditions.
    
    float dist      = distance(ray.origin, pos);
    float fogAmount = 1.0 - exp(-dist * mix(0.0005, 0.00005, DistanceRatioCamera(ray.origin.xz)));
    vec3  fogColor  = Sky(ray.direction);  // Fog is the same color as the sky/sun
    
    return mix(color, fogColor, fogAmount);
}

vec3 TerrainTexture(vec3 pos, vec3 norm)
{
	vec3 cliff = vec3(0.1);
    vec3 snow = vec3(0.9);
    
    float slope = smoothstep(0.5, 0.9, norm.y) * smoothstep(0.0, 0.1, norm.x + 1.0);
    
    return mix(cliff, snow, smoothstep(0.1, 0.8, slope));
}

vec3 ShadeTerrain(vec3 pos, vec3 norm, Ray ray)
{
    vec3 albedo = TerrainTexture(pos, norm);
    vec3 color  = Lighting(albedo, pos, norm, ray.direction);
    
    return CalcExpFog(color, pos, ray);
}

vec4 RenderTerrain(Ray ray)
{
    vec2 march = MarchTerrain(ray);
    vec4 color = vec4(Sky(ray.direction), march.x);
    
    if(march.x < TerrainFarClip)
    {
        vec3 pos  = ray.origin + (ray.direction * march.x);
        vec3 norm = TerrainNormal(pos, march.x);
        
        color.rgb = ShadeTerrain(pos, norm, ray);
    }
    
    return color;
}


//------------------------------------------------------------------------
// Render City
//------------------------------------------------------------------------

const vec3 CityColors[7] = vec3[](vec3(0.05), vec3(0.2), vec3(0.05), vec3(0.3), vec3(0.1), vec3(0.4), vec3(0.1));

vec3 ShadeCity(float id, vec3 pos, vec3 norm, Ray ray)
{
    vec3 albedo = (id < 0.0 ? vec3(1.0) : CityColors[int(id)]);
    vec3 color  = Lighting(albedo, pos, norm, ray.direction);
    
    if(id > 3.0)
    {
        // Fake emissive on the tower core.
    	float timeRatio = sin(pos.y + iTime * 3.0);
        float distRatio = length(pos.xz - CityPos.xz) / (40.0 + timeRatio * 25.0);  
        
        vec3 core = mix(vec3(0.0, 1.7, 1.0), vec3(0.0, 1.2, 1.7), timeRatio);
        
        color = mix(color, core, clamp(1.0 - distRatio, 0.0, 1.0));
    }
    
    return CalcExpFog(color, pos, ray);
}

vec4 RenderCity(Ray ray)
{
    vec2 march = MarchCity(ray);
    vec4 color = vec4(vec3(0.1), march.x);
    
    if(march.x < TerrainFarClip)
    {
        vec3 pos = ray.origin + (ray.direction * march.x);
        vec3 norm = CityNormal(pos, march.x);
        
        color.rgb = ShadeCity(march.y, pos, norm, ray);
    }
    
    return color;
}

//------------------------------------------------------------------------
// Volumetric Fog
//------------------------------------------------------------------------

float tri(in float x){return abs(fract(x)-.5);}
vec3 tri3(in vec3 p){return vec3( tri(p.z+tri(p.y)), tri(p.z+tri(p.x)), tri(p.y+tri(p.x)));}
float Noise3D(in vec3 p) { float z  = 1.4; float rz = 0.0; vec3  bp = p; for(float i = 0.0; i <= 2.0; i++) { vec3 dg = tri3(bp); p += (dg); bp *= 2.0; z  *= 1.5; p  *= 1.3; rz += (tri(p.z+tri(p.x+tri(p.y))))/z; bp += 0.14; } return rz; }

float VolumeFogNoise(vec3 p)
{
    float time = iTime;
    
    p.x -= time * 220.0;
    p.z -= time * 40.0;
    p.y -= time * 25.5;
    
    return Noise3D(p * 0.002);
}

vec3 VolumeFog(vec3 sceneColor, float sceneDepth, in Ray ray)
{
    // Some cheap volumetric fog to mimic wind blowing across the surface.
    // The fog hangs very low to the ground as a full blown storm/squall is not desired.
    // It is most noticeable at the start of the scene even though it is present
    // the entire time. If the fog is too strong then it is overly apparent on
    // the city and does not look good. Right now it is barely perceptible on the
    // city but that is ok. The goal was to add an extra layer of harshness
    // to the opening and a bit of depth to the city.
    
    float depth = 1.0;
    vec3 hit = ray.origin + (ray.direction * (sceneDepth * TerrainFarClip - 50.0));
    
    // Notice the march does not begin at the ray origin like it does in
    // similar effects in other shaders. Those shaders want a fog/wind/etc. that
    // affects the whole scene, whereas this fog is just slightly above the ground.
    
    for(int i = 0; i < 2; ++i)
    {
        vec3 pos = hit + (ray.direction * depth);
        float fogNoise = VolumeFogNoise(pos);
        
        fogNoise   = mix(fogNoise, 0.0, clamp(pos.y / 1000.0, 0.0, 1.0));
        sceneColor = mix(sceneColor, sceneColor * vec3(0.05), fogNoise * fogNoise * 0.5);
        
        depth += min(depth * 1.5, 1.0);
    }
    
    return sceneColor;
}

//------------------------------------------------------------------------
// Render
//------------------------------------------------------------------------

vec3 Render(in Ray ray)
{
    vec4 terrain = RenderTerrain(ray);
    vec4 city    = vec4(vec3(0.0), TerrainFarClip * 2.0);
    
    // If we are in range of seeing the city then render it
    if(distance(ray.origin, CityPos) < 10000.0)
    {
        city = RenderCity(ray);
    }
    
    float sceneDepth = clamp(min(terrain.w, city.w) / TerrainFarClip, 0.0, 1.0);
    vec3  sceneColor = mix(terrain.rgb, city.rgb, step(city.w, terrain.w));
    
    return VolumeFog(sceneColor, sceneDepth, ray);
}

//------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------

mat2 Rotate(float a) 
{
	return mat2(cos(a),sin(a),-sin(a),cos(a));	
}

Ray GetCameraRay(vec2 uv)
{
    // Boils down to: if the mouse has not been used/or has been reset
    // to (0,0), then the camera looks at the top of the tower. Otherwise,
    // the camera direction is based on mouse position.
    
    vec2 halfRes = iResolution.xy * 0.5;
    vec2 mouse = iMouse.xy;
    
    vec3 ro = CameraPos(iTime);
    ro.y = TerrainNoiseLQ(ro.xz).x + mix(10.0, 340.0, DistanceRatioCamera(ro.xz));
    vec3 rt = ro + (vec3(0.0, 0.0, 1.0) * 1000.0);
    
    if(ivec2(mouse) == ivec2(0))
    {
        mouse = halfRes;
        rt = vec3(CityPos.x, CityPos.y + 600.0, CityPos.z);
    }
    
    Camera camera = Camera_LookAt(ro, rt);
    Ray ray = Camera_GetRay(camera, uv);
    
    vec2 d = (halfRes - mouse) * vec2(0.01, 0.005);
    
    ray.direction.yz *= Rotate(-d.y);
	ray.direction.xz *= Rotate(d.x);
    
    return ray;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    Ray ray = GetCameraRay(uv);
    
    vec3 color = Render(ray);
    color = pow(color, vec3(1.0 / 2.2));    // Gamma correction
    
    fragColor = vec4(color, 1.0);
}