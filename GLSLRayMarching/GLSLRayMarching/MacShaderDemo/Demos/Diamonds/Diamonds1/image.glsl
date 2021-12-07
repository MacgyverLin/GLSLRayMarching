#define pi 3.141593

struct Lamp
{
  vec3 position;
  vec3 color;
  float intensity;
  float attenuation;
};

Lamp lamps[3];
    
struct RenderData
{
  vec3 col;
  vec3 pos;
  vec3 norm;
  int objnr;
};

vec3 campos = vec3(0., 0.5, 5.);
vec3 camdir = vec3(0., -0.1, -1.);
float fov = 5.;

const vec3 ambientColor = vec3(0.7);
const float ambientint = 0.08;

#define specular
//#define color_disp
//#define only_shape
//#define show_not_finished
const int nb_refr = 1; 

const float specint = 0.2;
const float specshin = 20.;

const float normdelta = 0.0004;
const float maxdist = 55.;

const float ior = 2.418;
const float ior_r = 2.408;
const float ior_g = 2.424;
const float ior_b = 2.432;
const vec3 diamondColor = vec3(0.0, 0.0, 0.9);

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.9;
const int aasamples = 1;

vec4 cubeMap(sampler2D channel, vec3 dir)
{
	dir = normalize(dir);

	vec2 uv;
	uv.x = (atan(dir.x, dir.z) + (3.14)) / (2 * 3.14);
	uv.y = (asin(dir.y) + (3.14 / 2.0)) / (3.14);
	return texture(channel, uv);
}

vec2 rotateVec(vec2 vect, float angle)
{
    vec2 rv;
    rv.x = vect.x*cos(angle) + vect.y*sin(angle);
    rv.y = vect.x*sin(angle) - vect.y*cos(angle);
    return rv;
}

float map_simple(vec3 pos)
{   
    float angle = 2.*pi*iMouse.x/iResolution.x;
    float angle2 = -2.*pi*iMouse.y/iResolution.y;
    
    vec3 posr = pos;
    posr = vec3(posr.x, posr.y*cos(angle2) + posr.z*sin(angle2), posr.y*sin(angle2) - posr.z*cos(angle2));
    posr = vec3(posr.x*cos(angle) + posr.z*sin(angle), posr.y, posr.x*sin(angle) - posr.z*cos(angle)); 
    
    float d = 1.05;
    float s = atan(posr.y, posr.x);
    
    vec3 flatvec = vec3(cos(s), sin(s), 1.444);
    vec3 flatvec2 = vec3(cos(s), sin(s), -1.072);
     
    float d1 = dot(flatvec, posr) - d;                        // Crown
    d1 = max(dot(flatvec2, posr) - d, d1);                    // Pavillon
    d1 = max(dot(vec3(0., 0., 1.), posr) - 0.35, d1);         // Table
    return d1;
}

float map(vec3 pos)
{     
    float angle = 2.*pi*iMouse.x/iResolution.x;
    float angle2 = -2.*pi*iMouse.y/iResolution.y;
    
    vec3 posr = pos;
    posr = vec3(posr.x, posr.y*cos(angle2) + posr.z*sin(angle2), posr.y*sin(angle2) - posr.z*cos(angle2));
    posr = vec3(posr.x*cos(angle) + posr.z*sin(angle), posr.y, posr.x*sin(angle) - posr.z*cos(angle));
    
    float d = 0.94;
    float b = 0.5;

    float af2 = 4./pi;
    float s = atan(posr.y, posr.x);
    float sf = floor(s*af2 + b)/af2;
    float sf2 = floor(s*af2)/af2;
    
    vec3 flatvec = vec3(cos(sf), sin(sf), 1.444);
    vec3 flatvec2 = vec3(cos(sf), sin(sf), -1.072);
    vec3 flatvec3 = vec3(cos(s), sin(s), 0);
    float csf1 = cos(sf + 0.21);
    float csf2 = cos(sf - 0.21);
    float ssf1 = sin(sf + 0.21);
    float ssf2 = sin(sf - 0.21);
    vec3 flatvec4 = vec3(csf1, ssf1, -1.02);
    vec3 flatvec5 = vec3(csf2, ssf2, -1.02);
    vec3 flatvec6 = vec3(csf2, ssf2, 1.03);
    vec3 flatvec7 = vec3(csf1, ssf1, 1.03);
    vec3 flatvec8 = vec3(cos(sf2 + 0.393), sin(sf2 + 0.393), 2.21);
     
    float d1 = dot(flatvec, posr) - d;                           // Crown, bezel facets
    d1 = max(dot(flatvec2, posr) - d, d1);                       // Pavillon, pavillon facets
    d1 = max(dot(vec3(0., 0., 1.), posr) - 0.3, d1);             // Table
    d1 = max(dot(vec3(0., 0., -1.), posr) - 0.865, d1);          // Cutlet
    d1 = max(dot(flatvec3, posr) - 0.911, d1);                   // Girdle
    d1 = max(dot(flatvec4, posr) - 0.9193, d1);                  // Pavillon, lower-girdle facets
    d1 = max(dot(flatvec5, posr) - 0.9193, d1);                  // Pavillon, lower-girdle facets
    d1 = max(dot(flatvec6, posr) - 0.912, d1);                   // Crown, upper-girdle facets
    d1 = max(dot(flatvec7, posr) - 0.912, d1);                   // Crown, upper-girdle facets
    d1 = max(dot(flatvec8, posr) - 1.131, d1);                   // Crown, star facets
    return d1;
}

float trace(vec3 cam, vec3 ray, float maxdist, bool inside) 
{
    float t = 4.2;
    float dist;
    
    // "Bounding" tracing
    if (!inside)
    {
  		for (int i = 0; i < 12; ++i)
    	{
    		vec3 pos = ray*t + cam;
    		dist = map_simple(pos);
        	if (dist>maxdist || abs(dist)<0.001)
            	break;
        	t+= dist*0.95;
  		}
    }

    // "Actual" tracing
  	for (int i = 0; i < 30; ++i)
    {
    	vec3 pos = ray*t + cam;
    	dist = inside?-map(pos):map(pos);
        if (dist>maxdist)
            break;
        t+= dist*(inside?0.4:0.8);
  	}
  	return t;
}

// Old slower version (but a bit more precise)
float trace_sl(vec3 cam, vec3 ray, float maxdist, bool inside) 
{
    float t = 4.;
  	for (int i = 0; i < 80; ++i)
    {
    	vec3 pos = ray*t + cam;
    	float dist = inside?-map(pos):map(pos);
        if (dist>(inside?3.:maxdist) || abs(dist)<0.001 || (inside && i>30))
            break;
        t+= dist*0.4;
  	}
  	return t;
}

// From https://www.shadertoy.com/view/MstGDM
vec3 getNormal(vec3 pos, float e, bool inside)
{
    vec2 q = vec2(0, e);
    return (inside?-1.:1.)*normalize(vec3(map(pos + q.yxx) - map(pos - q.yxx),
                          map(pos + q.xyx) - map(pos - q.xyx),
                          map(pos + q.xxy) - map(pos - q.xxy)));
}

vec3 obj_color(vec3 norm, vec3 pos)
{
  	#ifdef only_shape
  	return vec3(0.35, 0.7, 1.0);
  	#else
    return vec3(0.);
    #endif
}

vec3 sky_color(vec3 ray)
{
	vec3 rc = cubeMap(iChannel0, ray).rgb;
    for (int l=0; l<3; l++)
        rc+= 1.5*normalize(lamps[l].color)*lamps[l].intensity*specint*pow(max(0.0, dot(ray, normalize(lamps[l].position - campos))), 200.);
    return rc;
}

// Fresnel reflectance factor through Schlick's approximation: https://en.wikipedia.org/wiki/Schlick's_approximation
float fresnel(vec3 ray, vec3 norm, float n2)
{
   float n1 = 1.; // air
   float angle = clamp(acos(-dot(ray, norm)), -pi/2.15, pi/2.15);
   float r0 = pow((n1-n2)/(n1+n2), 2.);
   float r = r0 + (1. - r0)*pow(1. - cos(angle), 5.);
   return clamp(0., 0.9, r);
}

vec3 lampShading(Lamp lamp, vec3 norm, vec3 pos, vec3 ocol, bool inside)
{
	vec3 pl = normalize(lamp.position - pos);
    float dlp = distance(lamp.position, pos);
    vec3 pli = pl/pow(1. + lamp.attenuation*dlp, 2.);
      
    vec3 col;
    
    // Diffuse shading
    if (!inside)
    {
    	float diff = clamp(dot(norm, pli), 0., 1.);
    	col = ocol*normalize(lamp.color)*lamp.intensity*smoothstep(0., 1.04, pow(diff, 0.78));
    }
    
    // Specular shading
    #ifdef specular
    if (dot(norm, lamp.position - pos) > 0.0)
        col+= normalize(lamp.color)*lamp.intensity*specint*pow(max(0.0, dot(reflect(pl, norm), normalize(pos - campos))), specshin);
    #endif
    
    return col;
}

vec3 lampsShading(vec3 norm, vec3 pos, vec3 ocol, bool inside)
{
    vec3 col = vec3(0.);
    for (int l=0; l<3; l++) // lamps.length()
        col+= lampShading(lamps[l], norm, pos, ocol, inside);
    
    return col;
}

// From https://www.shadertoy.com/view/lsSXzD, modified
vec3 GetCameraRayDir(vec2 vWindow, vec3 vCameraDir, float fov)
{
	vec3 vForward = normalize(vCameraDir);
	vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
	vec3 vUp = normalize(cross(vForward, vRight));
    
	vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * fov);

	return vDir;
}

RenderData trace0(vec3 tpos, vec3 ray, bool inside)
{
    float tx = trace(tpos, ray, maxdist, inside);
    vec3 col;
    int objnr;
    
    vec3 pos = tpos + tx*ray;
    vec3 norm;
    if (tx<10.)
    {
        norm = getNormal(pos, normdelta, inside);
        if (!inside)
        {
            // Coloring
        	col = obj_color(norm, pos) + ambientColor*ambientint;
        	objnr = 1;
        }
        
        // Shading
        col = lampsShading(norm, pos, col, inside);
  }
  else
  {
      // Sky
      col = sky_color(ray);
      objnr = 3;
  }
  return RenderData(col, pos, norm, objnr);
}

vec4 render(vec2 fragCoord, vec3 campos, float ior)
{   
  lamps[0] = Lamp(vec3(0., 4.5, 10.), vec3(1., 1., 1.), 5., 0.1);
  lamps[1] = Lamp(vec3(12., -0.5, 6.), vec3(.7, .8, 1.), 5., 0.1);
  lamps[2] = Lamp(vec3(-1.3, 0.8, -1.5), vec3(1., .95, .8), 3.5, 0.1);
    
  vec2 uv = fragCoord.xy / iResolution.xy; 
  uv = uv*2.0 - 1.0;
  uv.x*= iResolution.x / iResolution.y;

  vec3 ray = GetCameraRayDir(uv, camdir, fov);
    
  RenderData traceinf = trace0(campos, ray, false);
  vec3 col = traceinf.col;
    
  #ifdef only_shape
  	return vec4(col, 1.0);
  #else
    
  if (traceinf.objnr==1)
  {
  		vec3 norm = traceinf.norm;
        vec3 ray_r = refract(ray, traceinf.norm, 1./ior);
        vec3 ray_r2;
      
        int n2;
        for (int n=0; n<nb_refr; n++)
        {
        	traceinf = trace0(traceinf.pos, ray_r, true);
        	col+= traceinf.col;
        	col*= diamondColor;
      		ray_r2 = refract(ray_r, traceinf.norm, ior);
        	if (length(ray_r2)!=0.)
            {
           		col+= sky_color(ray_r2)*diamondColor;
                break;
            }
            ray_r2 = reflect(ray_r, traceinf.norm);
            ray_r = ray_r2;
            n2 = n;
        }
        if (n2==nb_refr-1)
            #ifdef show_not_finished
            col = vec3(1., 0., 1.);
      		#else
            col+= sky_color(ray_r2)*diamondColor;
      		#endif
                      
        // Outer reflection
        float r = fresnel(ray, norm, ior) * 0.5;
        col = mix(col, sky_color(reflect(ray, norm)), r);
  }
  return vec4(col, 1.0);
  #endif
}

vec4 render_rgb(vec2 fragCoord, vec3 campos)
{
    #ifdef color_disp
    	vec4 col;
    	col.r = render(fragCoord, campos, ior_r).r;
    	col.g = render(fragCoord, campos, ior_g).g;
    	col.b = render(fragCoord, campos, ior_b).b;
    	col.a = 1.;
	return col;
    #else
    	return render(fragCoord, campos, ior);
    #endif
}

vec4 render_aa(vec2 fragCoord, vec3 campos)
{
    // Antialiasing
    vec4 vs = vec4(0.);
    for (int j=0;j<aasamples ;j++)
    {
       float oy = float(j)*aawidth/max(float(aasamples-1), 1.);
       for (int i=0;i<aasamples ;i++)
       {
          float ox = float(i)*aawidth/max(float(aasamples-1), 1.);
          vs+= render_rgb(fragCoord + vec2(ox, oy), campos);
       }
    }
    return vs/vec4(aasamples*aasamples);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
       fragColor = render_aa(fragCoord, campos);    
}