#define CAM_FLOATING_HEIGHT 1.0

#define PI 3.14
#define EPSILON 0.00001

#define RAY_MARCH_MAX_ITER 256
#define RAY_MARCH_INIT_STEP 0.1
#define RAY_MARCH_STOP_APPROX 0.001

#define ERR_COLOR vec3(1, 0, 0)

#define SKY_COLOR vec3(0.27, 0.55, 1.0)

#define TERRAIN_GRASS_METALLIC_ROUGHNESS vec2(0.1, 0.8)

#define TERRAIN_ROCK_ALBEDO vec3(0.46, 0.29, 0.09)
#define TERRAIN_ROCK_MATERIAL vec2(0.1, 0.2)

#define TREE_AABB_SIZE vec3(3.5, 4.0, 3.5)

#define TREE_TRUNK_HEIGHT 1.5
#define TREE_TRUNK_RADIUS 0.2
#define TREE_TRUNK_ALBEDO vec3(0.46, 0.29, 0.09)
#define TREE_TRUNK_METALLIC_ROUGHNESS vec2(0.7, 0.3)

#define TREE_FOLIAGE_HEIGHT 1.6
#define TREE_FOLIAGE_RADIUS 1.0
#define TREE_FOLIAGE_ALBEDO vec3(0.17, 0.6, 0.23)
#define TREE_DARK_FOLIAGE_ALBEDO vec3(0.11, 0.27, 0.14)
#define TREE_FOLIAGE_METALLIC_ROUGHNESS vec2(0.1, 0.9)

#define SUNLIGHT_COLOR vec3(1.0, 1.0, 0.4)
#define SUNLIGHT_DIR normalize(vec3(0, -1, 1))

#define NO_HIT -1
#define HIT_TERRAIN 0x00
#define HIT_TREE_BB 0x10
#define HIT_TREE_TRUNK 0x11
#define HIT_TREE_FOLIAGE 0x12
// ...

float rand(vec2 n)
{
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p)
{
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

vec4 cylIntersect( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, float ra )
{
    vec3 ca = pb-pa;
    vec3 oc = ro-pa;
    float caca = dot(ca,ca);
    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    float a = caca - card*card;
    float b = caca*dot( oc, rd) - caoc*card;
    float c = caca*dot( oc, oc) - caoc*caoc - ra*ra*caca;
    float h = b*b - a*c;
    if( h<0.0 ) return vec4(-1.0); //no intersection
    h = sqrt(h);
    float t = (-b-h)/a;
    // body
    float y = caoc + t*card;
    if( y>0.0 && y<caca ) return vec4( t, (oc+t*rd-ca*y/caca)/ra );
    // caps
    t = (((y<0.0)?0.0:caca) - caoc)/card;
    if( abs(b+a*t)<h ) return vec4( t, ca*sign(y)/caca );
    return vec4(-1.0); //no intersection
}

vec2 sphere_uv(vec3 n)
{
    return vec2(
        atan(n.x, n.z) / (2.0 * PI) + 0.5,
        n.y * 0.5 + 0.5
    );
}

float snake_pattern(vec2 repeat_each, float curve_strength, vec2 uv)
{
    float li = mod(floor(uv.y / repeat_each.y), 2.0);
   
    float re = abs(mod(floor(uv.x / repeat_each.x), 2.0) - li);
    float le = 1.0 - re;
   
    float lv = exp(-curve_strength * mod(uv.x, repeat_each.x) / repeat_each.x) * repeat_each.y;
    float rv = exp(curve_strength * (mod(uv.x, repeat_each.x) / repeat_each.x - 1.0)) * repeat_each.y;
   
    float d = mod(uv.y, repeat_each.y) - (lv * le + rv * re);
    float dw = d / repeat_each.y;
    
    return dw;
}

// ------------------------------------------------------------------------------------------------
// Terrain
// ------------------------------------------------------------------------------------------------

float get_terrain_height_norm(vec2 p)
{
    return noise(p * 0.3);
}

float get_terrain_height(vec2 p)
{
    return get_terrain_height_norm(p) * 3.0;
}

vec3 get_terrain_norm(vec2 p)
{
    float cur_h = get_terrain_height(p);
   
    vec3 d1 = vec3(0, get_terrain_height(p + vec2(0, EPSILON)) - cur_h, EPSILON);
    vec3 d2 = vec3(EPSILON, get_terrain_height(p + vec2(EPSILON, 0)) - cur_h, 0);
    
    return normalize(cross(d1, d2));
}

vec2 get_terrain_uv(vec2 p)
{
    return mod(p, vec2(1.0));
}

void get_terrain_material(vec2 p, out vec3 mat_albedo, out vec2 mat_metallic_roughness)
{
    const float k_line_width = 0.04;
    const vec2 k_repeat_each = vec2(0.6);
    const vec3 k_grass_color = vec3(0.17, 0.6, 0.23);
    const vec3 k_darker_grass_color = vec3(0.11, 0.27, 0.14);

    float h = get_terrain_height_norm(p);
    float tm = 0.5 + (noise(p) * 2.0 - 1.0) * 0.15;
    float bm = 0.2 + (noise(p) * 2.0 - 1.0) * 0.15;

    float grass_enable = clamp(ceil(h - tm), 0.0, 1.0) + clamp(ceil(bm - h), 0.0, 1.0);
    float rock_enable = 1.0 - grass_enable;
    
    vec2 uv = get_terrain_uv(p);
    
    float grass_border_enable = clamp(ceil(0.05 - abs(h - tm)) + ceil(0.05 - abs(h - bm)), 0.0, 1.0);
    
    vec3 grass_color =
        k_grass_color * (1.0 - grass_border_enable) + k_darker_grass_color * grass_border_enable;
    
    mat_albedo = mix(TERRAIN_ROCK_ALBEDO, grass_color, grass_enable);
    mat_metallic_roughness = grass_enable * vec2(0.2, 0.8) + rock_enable * vec2(0.2, 0.8);
}


// ------------------------------------------------------------------------------------------------
// Tree
// ------------------------------------------------------------------------------------------------

bool hasTreeAt(vec2 p)
{
    return rand(floor(p / TREE_AABB_SIZE.xz)) >= 0.7;
}

vec3 get_tree_pos(vec3 p)
{
    vec3 tree_pos;
    tree_pos.xz = floor(p.xz / TREE_AABB_SIZE.xz) * TREE_AABB_SIZE.xz + TREE_AABB_SIZE.xz / 2.0;
    tree_pos.y = get_terrain_height(tree_pos.xz);
    return tree_pos;
}

bool ray_hit_tree_aabb(vec3 p)
{
    float baseY = get_terrain_height(p.xz);
    return hasTreeAt(p.xz) && p.y - baseY <= TREE_AABB_SIZE.y;
}

int ray_hit_tree_test(vec3 ro, vec3 rd, vec3 tree_pos, out float hit_t, out vec3 hit_norm)
{
    vec3 foliage_center = tree_pos + vec3(0, TREE_FOLIAGE_HEIGHT, 0);
    vec3 trunk_from = tree_pos;
    vec3 trunk_to = tree_pos + vec3(0, TREE_TRUNK_HEIGHT, 0);
   
    hit_t = sphIntersect(ro, rd, foliage_center, TREE_FOLIAGE_RADIUS).x;
    if (hit_t >= 0.0)
    {
        hit_norm = normalize((ro + rd * hit_t) - foliage_center);
        return HIT_TREE_FOLIAGE;
    }
    
    hit_t = cylIntersect(ro, rd, trunk_from, trunk_to, TREE_TRUNK_RADIUS).x;
    if (hit_t >= 0.0)
    {
        return HIT_TREE_TRUNK;
    }
    
    return NO_HIT;  
}

vec3 get_foliage_color(vec3 n)
{
    vec2 uv = sphere_uv(n);
    
    const vec2 repeat_each = vec2(0.025, 0.1);
    const float line_width = 3.0;
    
    float d = snake_pattern(repeat_each, line_width / 2.0, uv);
    float be = 1.0 - clamp(ceil(abs(d / 0.07) - 2.0), 0.0, 1.0);
    
    return mix(TREE_FOLIAGE_ALBEDO, TREE_DARK_FOLIAGE_ALBEDO, be);
}

// ------------------------------------------------------------------------------------------------
// Camera
// ------------------------------------------------------------------------------------------------

mat3 rotX(float a)
{
    return mat3(
        1, 0, 0,
        0, cos(a), -sin(a),
        0, sin(a), cos(a)
    );
}

mat3 rotY(float a)
{
    return mat3(
        cos(a), 0, sin(a),
        0, 1, 0,
        -sin(a), 0, cos(a)
    );
}

mat3 rotAroundAxis(vec3 axis, float a)
{
    axis = normalize(axis);
    float s = sin(a);
    float c = cos(a);
    float oc = 1.0 - c;
    
    return mat3(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
    );
}

vec3 getCameraPos(float t)
{
    vec3 p;
    p.xz = vec2(0, t);
    p.y = get_terrain_height(p.xz) + CAM_FLOATING_HEIGHT;
    return p;
}

mat3 getCameraDir(float t)
{
    float yaw = 0.0;
    float pitch = 0.0;
    return rotY(yaw) * rotX(pitch);
}

// ------------------------------------------------------------------------------------------------
// Ray marching
// ------------------------------------------------------------------------------------------------

/** This function is used to enhance the ray marched position of the terrain collision. */
void ray_march_terrain(vec3 ro, vec3 rd, inout float hit_t, out vec3 hit_norm)
{
    float curStep = RAY_MARCH_INIT_STEP;
    
    float t = hit_t;
    
    int iter = 0;
    while (curStep > RAY_MARCH_STOP_APPROX && iter < RAY_MARCH_MAX_ITER)
    {
        vec3 ray_pos = ro + rd * t;
        
        if (ray_pos.y < get_terrain_height(ray_pos.xz))
        {
            hit_t = t;
            hit_norm = get_terrain_norm(ray_pos.xz);
        
            t -= curStep;
            curStep /= 2.0;

            if (t < 0.0) {
                return;
            }
        }

        t += curStep;
        iter++;
    }
}

int ray_march(vec3 ro, vec3 rd, out float hit_t, out vec3 hit_norm)
{
    float t = 0.0;

    int hit = NO_HIT;
    
    int iter = 0;
    while (iter < RAY_MARCH_MAX_ITER)
    {
        vec3 ray_pos = ro + rd * t;
        hit_t = t;

        if (ray_pos.y < get_terrain_height(ray_pos.xz))
        {
            ray_march_terrain(ro, rd, hit_t, hit_norm);
            return HIT_TERRAIN;
        }

        // If the intersection happens between the ray and the tree's AABB,
        // then we have to check whether the collision actually happened with the tree
        // if so we can return the exact hit position.
        if (ray_hit_tree_aabb(ray_pos))
        {
            int hit = ray_hit_tree_test(ro, rd, get_tree_pos(ray_pos), hit_t, hit_norm);
            if (hit != NO_HIT) {
                return hit;
            }
        }
        
        t += RAY_MARCH_INIT_STEP; // always increment of a fixed step here
   
        iter++;
    }
    
    return hit;
}

// ------------------------------------------------------------------------------------------------
// PBR
// ------------------------------------------------------------------------------------------------

// https://learnopengl.com/PBR/Theory

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}
  
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 F_r(vec3 V, vec3 L, vec3 N, vec3 mat_albedo, vec2 mat_metallic_roughness)
{
    vec3 H = normalize(V + L);
    
    // cook-torrance brdf
    float NDF = DistributionGGX(N, H, mat_metallic_roughness.y);        
    float G   = GeometrySmith(N, V, L, mat_metallic_roughness.y);
    
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, mat_albedo, mat_metallic_roughness.x);
    vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);       

    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - mat_metallic_roughness.x;	 
    
    vec3 numerator    = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
    vec3 specular     = numerator / max(denominator, 0.001);  
    
    // lambert bdrf
    vec3 diffuse = kD * mat_albedo / PI;
    return diffuse + specular;
}

// ------------------------------------------------------------------------------------------------
// Lighting
// ------------------------------------------------------------------------------------------------

int is_sun_occluded(vec3 p, out float occ_hit_t, out vec3 occ_hit_norm)
{
    return ray_march(p, -SUNLIGHT_DIR, occ_hit_t, occ_hit_norm);
}

vec3 shade(int hit, vec3 ro, vec3 rd, float hit_t, vec3 hit_norm)
{
    vec3 hit_pos = ro + rd * hit_t;

    vec3 hit_albedo;
    vec2 hit_metallic_roughness;
    
    if (hit == HIT_TERRAIN)
    {
        get_terrain_material(hit_pos.xz, hit_albedo, hit_metallic_roughness);
    }
    else if (hit == HIT_TREE_TRUNK)
    {
        hit_albedo = TREE_TRUNK_ALBEDO;
        hit_metallic_roughness = TREE_TRUNK_METALLIC_ROUGHNESS;
    }
    else if (hit == HIT_TREE_FOLIAGE)
    {
        hit_albedo = get_foliage_color(hit_norm);
        hit_metallic_roughness = TREE_FOLIAGE_METALLIC_ROUGHNESS;
    }
    else
    {
        hit_albedo = ERR_COLOR;
        hit_metallic_roughness = vec2(0, 1);
    }

    // Shadowing
    float occ_hit_t;
    vec3 occ_hit_norm;
    
    bool occluded = false;
    occluded = occluded || (is_sun_occluded(ro + rd * (hit_t - 0.01), occ_hit_t, occ_hit_norm) != NO_HIT);

    // Lighting
    //vec3 hit_albedo = TERRAIN_GRASS_ALBEDO;
    //vec2 hit_metallic_roughness = TERRAIN_GRASS_METALLIC_ROUGHNESS;
    
    vec3 light_dir = SUNLIGHT_DIR;
    vec3 light_col = SUNLIGHT_COLOR;
    
    vec3 tot_light = vec3(0);
    
    if (!occluded)
    {
        tot_light +=
            F_r(-rd, -light_dir, hit_norm, hit_albedo, hit_metallic_roughness) *
            light_col *
            max(dot(hit_norm, -light_dir), 0.0);
    }

    vec3 ambient = vec3(0.03) * hit_albedo;
    vec3 color = ambient + tot_light;

    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0 / 2.2));

    return color;
}

// ------------------------------------------------------------------------------------------------
// Main
// ------------------------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 screen_pos = (fragCoord / iResolution.xy * 2.0) - 1.0;
    float aspect_ratio = iResolution.x / iResolution.y;
    
    const float fov = PI / 4.0; // 45°
    
    vec3 camPos = getCameraPos(iTime);
    mat3 camDir = getCameraDir(iTime);
    
    vec3 camForward = camDir[2];
    vec3 camUp = camDir[1];
    vec3 camRight = camDir[0];
    
    vec3 camRay = camForward;
    camRay = rotAroundAxis(camUp, screen_pos.x * fov) * camRay;
    camRay = rotAroundAxis(camRight, screen_pos.y * (fov / aspect_ratio)) * camRay;
    
    float hit_t;
    vec3 hit_norm;
    int hit = ray_march(camPos, camRay, hit_t, hit_norm);
    if (hit == NO_HIT) {
        fragColor = vec4(SKY_COLOR, 1.0);
    } else {
        fragColor = vec4(shade(hit, camPos, camRay, hit_t, hit_norm), 1.0);
    }
}
