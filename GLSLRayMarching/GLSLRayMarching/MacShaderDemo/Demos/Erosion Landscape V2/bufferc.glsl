//rendering
vec3 CAMERA_POS = vec3(-1.5, -1.5, 1.);
const vec3 CAMERA_LOOK = vec3(0.,0.,0.);


const float EPS = .01;
const float SHADOW_EPS = .03;
const float STEP_SIZE = .002;
const float SHADOW_STEP = .05;
vec3 SUN_DIR = normalize(vec3(.3, .5, .2));
const vec3 SUN_COL = vec3(1,.7,.4)*2.5;
const vec3 AMBIENT = vec3(.3,.35,.53)*.3;

const vec2 W_NRM_EPS = vec2(.001,0.);

const float CLOUDS_STEP = .01;
const int CLOUD_OCT = 6;
const float CLOUD_SCALE = .0016;
const float CLOUD_LIGHT_STEP = .04;
const float CLOUD_LIGHT_FAR = .1;

const int TERRAIN_BUMP_OCT = 4;

const vec2 T_NRM_EPS = vec2(.0017,0.);
struct Ray
{
    vec3 origin;
    vec3 dir;
};
Ray ConstructViewRay(vec2 screen_pos, vec3 pos, vec3 look_dir, vec3 up, float len)
{
    Ray r = Ray(pos, vec3(0));
    
    vec3 side = cross(up, look_dir);
    vec3 cam_up = cross(look_dir,side);
    
    r.dir = normalize(side*screen_pos.x+cam_up*screen_pos.y+look_dir*len);
    
    return r;
}

vec2 RayBoxIntersect( Ray r, vec3 boxSize, out vec3 outNormal ) 
{
    //from https://iquilezles.org/articles/intersectors
    vec3 m = 1.0/r.dir; // can precompute if traversing a set of aligned boxes
    vec3 n = m*r.origin;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m)*boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(FAR); // no intersection
    outNormal = -sign(r.dir)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    return vec2( tN, tF );
}

vec4 GetTerrain(vec2 p)
{
    if(p.x > 1. || p.y > 1.|| p.x < -1.|| p.y < -1.) return vec4(0,0,1,0);
    vec4 data = texture(iChannel0, (p+vec2(1.01))*.47);
    return data;
}

vec4 MarchTerrain(Ray r, float dist, float far)
{
    vec4 data = vec4(0);
    while(dist < far)
    {
        vec3 p = r.origin+r.dir*dist;
        data = GetTerrain(p.xy);
        if(p.z < data.w+EPS)return vec4(data.xyz, dist-STEP_SIZE/2.);
        dist += STEP_SIZE*(Rand3D(p+iTime).x+.5);
    }
    return vec4(data.xyz, FAR);
}
float MarchShadows(Ray ray, float k)
{
    float r = 1.;
    float dep = 0.001+SHADOW_EPS;
    while(dep < FAR)
    {
        vec3 p = ray.origin+ray.dir*dep;
        vec4 data = GetTerrain(p.xy);
        //if(p.z < dist+SHADOW_EPS) 0.;
        
        r = min(r, k*(p.z-data.w)/dep);
        dep += SHADOW_STEP;
    }
    return r;
}


float CloudDens(vec3 p)
{
   float s = 2.;
   float a = .5;
   float data = 0.;
   for(int i = 0; i < CLOUD_OCT; i++)
   {
       data += Noise3D(((p+vec3(float(i)*7.8936345, float(i)*-13.73467, float(i)*-36.71261))*s)+vec3(WIND,0.)*iTime)*a;
       s*= 1.8;
       a*= .6;
   }
   data = min(max(data-.7, 0.)*4., 1.);
   
   float h = max(1.-max(abs(p.z-.4)+4.93, 0.)*.2, 0.);
   
   return max(data*h*50.,0.);
       
}

vec3 MarchCloudLight(Ray r)
{
    float dep = 0.;
    float dens = 0.;
    while(dep < CLOUD_LIGHT_FAR)
    {
        vec3 pos = r.origin+r.dir*dep;
        dens += CloudDens(pos)*8.;
        dep += CLOUD_LIGHT_STEP;
    }
    return (vec3(exp(-(dens)))*SUN_COL*1.2+AMBIENT*.1)*vec3(.85,.87,1.3)*1.6;
}

vec4 MarchClouds(Ray r, float mi, float ma)
{
    float dep = mi;
    float trans = 1.;
    vec3 light = vec3(0.);
    while(dep < ma)
    {
        vec3 pos = r.origin+r.dir*dep;
        float cd = CloudDens(pos);
        dep += CLOUDS_STEP;
        if(cd>.01)
        {
            light += MarchCloudLight(Ray(pos, SUN_DIR))*cd*trans;
            trans *= exp(-cd);
        }
    }
    return vec4(light, trans);
}



float TerrainBump(vec2 p)
{
   float s = 60.;
   float a = .5;
   float data = 0.;
   for(int i = 0; i < TERRAIN_BUMP_OCT; i++)
   {
       data += Noise2D(((p.xy+vec2(float(i)*7.8936345, float(i)*-13.73467))*s))*a;
       s*= 1.8;
       a*= .6;
   }
   return data;
}

vec3 TerrainBumpNrm(vec2 p)
{
    vec3 nrm = vec3(0.);
    nrm.x = -(TerrainBump(p+T_NRM_EPS) - TerrainBump(p-T_NRM_EPS));
    nrm.y = -(TerrainBump(p+T_NRM_EPS.yx) - TerrainBump(p-T_NRM_EPS.yx));
    nrm.z = .8;
    nrm = normalize(nrm);
    
    return nrm;
}


float GetAO(vec2 p)
{
    vec2 t = vec2(EPS*3., 0);
    float ao = 0.;
    
    float b = GetTerrain(p).w;
    
    float x = (GetTerrain(p+t).w+GetTerrain(p-t).w+GetTerrain(p+t.yx).w+GetTerrain(p-t.yx).w)/4.;
    
    ao += b-x;
    
    return ao*16.+.4;
}

vec3 TextureTerrain(vec3 p, vec3 nrm, bool is_edge)
{
    vec3 col = vec3(0.);
    vec3 stone = vec3(.6);
    vec3 grass = vec3(.4, .6, .4);
    vec3 snow = vec3(1.1, 1.1, 1.2)*4.;

    float stone_mask = min(max((nrm.z-.75), 0.)*8.*smoothstep(0.12, .8, Noise3D(p*40.)), 1.);
    float snow_mask = min(max((p.z-.2)*Noise3D(p*30.), 0.)*64., 1.);
    
    vec3 ground = mix(grass, snow, snow_mask);
    
    col = mix(stone, ground, stone_mask)*mix(.6, 1., Noise3D(p*20.+41.));

    
    return col;
}

float CloudShadow(vec3 p)
{
    return 1.-CloudDens(p+SUN_DIR*max(dot(vec3(0,0,.4)-p, vec3(0,0,-1))/dot(SUN_DIR, vec3(0,0,-1)), 0.));
}

vec3 ShadeTerrain(vec3 p, vec3 nrm, vec3 dir, float dist, bool is_edge)
{

    vec3 col = TextureTerrain(p,nrm,is_edge);
    float sun = clamp(dot(SUN_DIR, nrm), 0.,1.);
    vec3 r = reflect(dir, nrm);
    vec3 ref = vec3(min(max((dot(r, SUN_DIR)-.85), 0.)*4., 1.));
    if(!is_edge)
    {
        float shadow = clamp(MarchShadows(Ray(p, SUN_DIR), 10.),0.,1.);
        shadow *= clamp(CloudShadow(p)*2.3-1.3,0.,1.);

        sun *= shadow;
        ref *= shadow;
        //return vec3(shadow);

    }
    vec3 light = SUN_COL*sun;
    light += AMBIENT;
    light += ref;
    light += vec3(.2, .2, .1)*max(dot(-SUN_DIR, nrm),0.);
    
    if(!is_edge)
    {
        float ao = GetAO(p.xy);

        light *= ao;
    }
    
  
    col *= light;
    //col = nrm;
    //col = vec3(shadow);
   
    return col;
}

vec3 DrawFog(vec3 p, float d, bool is_edge)
{
    if(is_edge)return vec3(0);
    d /= FAR;
    d = exp(d);
    float z = 1.-min(max(p.z-.03, 0.)*5., 1.);
    z *= d;
    return vec3(.7, .7, .9)*z*.2;
}

vec3 ShadeSky(vec3 d)
{
    vec3 col = mix(vec3(.8,.8, 1.), vec3(.025, .05, .7)*.8, clamp(d.z+.4, 0., 1.));
    
    
    col += SUN_COL*max(1.-max(distance(SUN_DIR, d)+.9, 0.), 0.)*10.;
    
    return col;
}

float WaterHeight(vec2 p)
{
    return Noise2D((p*100.2+144.)+WIND*iTime);
}

vec3 WaterNrm(vec2 p)
{
    vec3 nrm = vec3(0.);
    nrm.x = -(WaterHeight(p+W_NRM_EPS) - WaterHeight(p-W_NRM_EPS));
    nrm.y = -(WaterHeight(p+W_NRM_EPS.yx) - WaterHeight(p-W_NRM_EPS.yx));
    nrm.z = .5;
    nrm = normalize(nrm);
    
    return nrm;
}

vec3 Fresnel(float cosTheta, vec3 F0)
{
    //from https://learnopengl.com/PBR/Theory
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 ShadeWater(vec3 dir, float d, float wd, vec3 nrm)
{
    nrm = normalize(nrm+WaterNrm((CAMERA_POS+dir*wd).xy));
    float h = GetTerrain((CAMERA_POS+dir*wd).xy).w/WATER_HEIGHT*2.;
    float fr = Fresnel(dot(dir, nrm), vec3(1.055)).x;//Fresnel
    vec3 sky = ShadeSky(reflect(dir, nrm));

    return vec3(sky*fr*.5+h*.4);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = vec3(0);

    SUN_DIR.x = sin(iTime*.1-.8);
    SUN_DIR.y = cos(iTime*.1-.8);
    SUN_DIR = normalize(SUN_DIR);
    CAMERA_POS.y = sin(iTime*0.2)*2.5;
    CAMERA_POS.x = cos(iTime*0.2)*2.5;

    vec2 screen_pos = fragCoord.xy/iResolution.y*2.-1.-vec2(iResolution.x/iResolution.y/2.,0);

    
    Ray view_ray = ConstructViewRay(screen_pos, CAMERA_POS, normalize(-CAMERA_POS), vec3(0,0,1), 2.);

    vec3 b_nrm;
    vec3 box_s = vec3(1,1,FAR);
    vec2 b_dist = RayBoxIntersect(view_ray, box_s, b_nrm);
    col = ShadeSky(view_ray.dir);
    vec4 data = vec4(0,0,0,FAR);
    if(b_dist.x<FAR)
    {

        data = MarchTerrain(view_ray, b_dist.x, b_dist.y);
        if(data.w <= b_dist.x+EPS) data = vec4(b_nrm, b_dist.x);
        data.w = min(data.w, b_dist.y);
        vec3 pos = CAMERA_POS+view_ray.dir*data.w;

        bool is_edge = data.w <= b_dist.x;
        vec3 WaterNrm;
        vec2 water_d = RayBoxIntersect(view_ray, vec3(box_s.xy, WATER_HEIGHT), WaterNrm);
        //if(is_edge) data.xyz = b_nrm;
        if(data.w < b_dist.y)
        {
             if(!is_edge)data.xyz = normalize(data.xyz+TerrainBumpNrm(pos.xy));
             col = ShadeTerrain(pos, data.xyz, view_ray.dir, data.w,is_edge);
             col *= (is_edge) ? max(min(pos.z*.3+.1, 1.), 0.)+.01 : 1.;

             //col = data.xyz;
        }
        if(water_d.x < data.w)
        {

            col += ShadeWater(view_ray.dir, data.w, water_d.x, WaterNrm);
            data.w = water_d.x;
        }
        vec3 ndump;
        col += DrawFog(pos, data.w,is_edge);
        vec2 cbox = RayBoxIntersect(Ray(CAMERA_POS-vec3(0.,0.,.4), view_ray.dir), vec3(box_s.xy, .1),ndump);
        if(cbox.x < FAR)
        {
            vec4 cld = MarchClouds(Ray(CAMERA_POS, view_ray.dir+vec3(vec2(pcg2d(uvec2(fragCoord)+uint(iFrame)))/float(0xffffffffu)*.002, 0.)), cbox.x+.01, min(data.w, cbox.y));
            data.w = mix(data.w, cbox.x, 1.-cld.w);
            col = mix(cld.rgb, col, cld.w);
            //col = vec3(1.);
        }

        //col = vec3(cld.rgb);

    }
    
    //col = vec3(CloudDens(vec3(fragCoord/iResolution.xy*3., 1.)));
    
    //col = vec3(Noise2D(fragCoord/iResolution.xy*80.));
    // Output to screen
    fragColor = vec4(col, data.w);
}