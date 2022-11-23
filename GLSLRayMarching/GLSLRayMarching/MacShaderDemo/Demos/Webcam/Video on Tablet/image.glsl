/*
"Video on Tablet" by Emmanuel Keller aka Tambako - January 2016
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tamby@tambako.ch
*/

// Much code adapted from https://www.shadertoy.com/view/Xds3zN, thanks iq to let us use it! :)

#define pi 3.141593

// Switches, you can play with them!
#define shadow
#define reflections
//#define ambocc
#define specular
#define bumpmaps
#define smooth_floor_bump
#define complex_tab_light_color
#define spheres

struct Lamp
{
  vec3 position;
  vec3 color;
  float intensity;
  float attenuation;
};

struct RenderData
{
  vec3 col;
  vec3 pos;
  vec3 norm;
  int objnr;
};
    
Lamp lamps[3];

// Every object of the scene has its ID
#define SKY_OBJ      0
#define FLOOR_OBJ    1
#define TABLET_OBJ   2
#define IMAGE_OBJ    3
#define SPHERES_OBJ  4

// Campera options
vec3 campos;
vec3 camtarget = vec3(0., 1.8, 0.);
vec3 camdir;
float fov = 4.;

// Ambient light
const vec3 ambientColor = vec3(0., 0., 0.3);
const float ambientint = 0.05;

// Shading options
const float specint = 0.2;
const float specshin = 150.;
const float aoint = 0.5;
const float shi = 0.85;
const float shf = 0.4;

// Tracing options
const float normdelta = 0.002;
const float maxdist = 200.;
const int nbref = 2;

// Floor options
const float woodSize = 0.1;
float flpos = 0.;

// Tablet/image constants
const vec3 tabPos = vec3(0., 2.3, 0.);
const float tabWidth = 3.;
const float tabHeight = 2.;
const float tabletRounding = 0.3;
const float picWidth = 0.93;
const float picHeight = 0.96;
const float tcNbSampless = 5.;
const float tcNbSamplesc = 16.;
const vec2 tcWindowSize = vec2(0.2,0.4);
const float tcJitter = 0.035;
const float image_br = 0.55;

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.65;
const int aasamples = 1;

// 1D hash function
float hash( float n ){
	return fract(sin(n)*3538.5453);
}

// 2D hash function
vec2 hash2( vec2 n ){
	return fract(vec2(sin(n.x)*3538.5453, sin(n.y)*2753.8256));
}

vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

// Union operation from iq
vec2 rotateVec(vec2 vect, float angle)
{
    vec2 rv;
    rv.x = vect.x*cos(angle) - vect.y*sin(angle);
    rv.y = vect.x*sin(angle) + vect.y*cos(angle);
    return rv;
}

// Gets the coordinates of the image (0..1) from the world coordinates of the tablet point
// ToDo: use tabPos, tabWidth, tabHeight, picWidth and picHeight
vec2 pos2screen(vec3 pos)
{
   return pos.xy*vec2(-0.18, 0.148*iResolution.x/iResolution.y) + vec2(0.5, -0.1);
}

// Gets the light color at a given surface point. Not really realistic but also not too slow
// I could optimize it to get it nicer. Has some jitter to hide the sampling bands a bit
#ifdef complex_tab_light_color
vec3 getScreenColor(vec3 pos)
{
   //return vec3(0.8);
   //vec2 pos2screen = (pos-tabPos).xy/vec2(tabWidth*picWidth, tabHeight*picHeight) - vec2(0.5);
   vec2 screenpos = pos2screen(pos) + vec2(0., 0.09*pos.z);
    
   vec2 tcWindowSize2 = tcWindowSize*vec2(1. + abs(pos.z)/4.2, 1. + abs(pos.y)/6.);
    
   vec3 scol = vec3(0.);
   for (float y=0.; y<tcNbSamplesc; y++)  
   {
       for (float x=0.; x<tcNbSamplesc; x++)
       {
           vec2 coord = screenpos + vec2(
                 tcWindowSize2.x*x/(tcNbSamplesc-1.) - tcWindowSize2.x/2., 
                 tcWindowSize2.y*y/(tcNbSamplesc-1.) - tcWindowSize2.y/2.)
                 + tcJitter*hash2(vec2(pos.x, pos.z));
           scol+= texture(iChannel2, coord).rgb;
       }
   }
   return mix(clamp(1.5*scol/(tcNbSamplesc*tcNbSamplesc), 0., 0.65), vec3(0.7), 0.35);
}
#else
// This option just calculates the average color of the image
vec3 getScreenColor(vec3 pos)
{    
   vec3 scol = vec3(0.);
   for (float y=0.; y<tcNbSampless; y++)  
   {
       for (float x=0.; x<tcNbSampless; x++)
       {
           vec2 coord = vec2(
                 x/(tcNbSampless-1.), 
                 y/(tcNbSampless-1.));
           scol+= texture(iChannel2, coord).rgb;
       }
   }
   return mix(scol/(tcNbSampless*tcNbSampless), vec3(0.7), 0.2);
}
#endif

// Also a cheap and fast trick to simulate an arealight, the pos of the lamp is dynamic, it depends on the position of the sampling point
vec3 getScreenLampPosition(vec3 lamppos, vec3 pos)
{
    //return lamppos;
    
    pos-= tabPos;
    vec3 lamppos2 = vec3(min(max(pos.x, -tabWidth*picWidth), tabWidth*picWidth),
                         min(max(pos.y, -tabHeight*0.4), tabHeight*picHeight) + 0.3*pos.z,
                         lamppos.z - tabPos.z);
    lamppos2+= tabPos;
    return lamppos2;
}

// Whether or not the point is in the picture (only along X and Y axes)
bool inPic(vec3 pos)
{
   pos-= tabPos;
   return abs(pos.x)<tabWidth*picWidth && abs(pos.y)<tabHeight*picHeight;
}

// Distance mapping of the floor
float map_floor(vec3 pos, bool btext)
{
    float h=0.;
    #ifdef smooth_floor_bump
    #ifdef bumpmaps
   	h = texture(iChannel3, fract(woodSize*pos.xz)).x;
    #endif
    return pos.y - flpos - (btext?0.01*h:0.);
    #else
    #ifdef bumpmaps
    h = texture(iChannel0, woodSize*pos.xz).x;
    return pos.y - flpos - (btext?0.007*h:0.);
    #endif
    #endif
    #ifndef bumpmaps
    return pos.y - flpos;
    #endif
}

// Distance mapping of the tablet, based on the roundcube of iq. Has some bumpmapping on it
float map_tablet(vec3 pos, vec3 orig, vec3 size, float flatn, float r, bool btext)
{
    pos.z*= flatn;
    return length(max(abs(pos-orig)-size,0.0)) - r + (!btext || inPic(pos)?0.:0.008*texture(iChannel1, pos.xy*0.6).x);
}

// Distance mapping of four mirror rotating spheres. Just to have some more reflection! ;)
float map_spheres(vec3 pos, vec3 center, float d, float r)
{
    pos-= center;
    pos.xz = rotateVec(pos.xz, iTime*0.5);
    pos.x = abs(pos.x);
    pos.x-= d;
    pos.z = abs(pos.z);
    pos.z-= d;
    return length(pos) - r;   
}

// Combines all the distance fields
vec2 map(vec3 pos, bool btext)
{
    vec2 res = opU(vec2(map_floor (pos, btext)                                                            , FLOOR_OBJ),
                   vec2(map_tablet(pos, tabPos, vec3(tabWidth, tabHeight, 0.1), 5., tabletRounding, btext), TABLET_OBJ));
    #ifdef spheres
    res = opU(res, vec2(map_spheres(pos, vec3(.0, 0.45, 2.9), 1.7, 0.45)                                        , SPHERES_OBJ));
    #endif
    return res;
}

// Main tracing function
vec2 trace(vec3 cam, vec3 ray, float maxdist) 
{
    float t = 0.15;
    float objnr = 0.;
  	for (int i = 0; i < 200; ++i)
    {
    	vec3 pos = ray*t + cam;
        vec2 res = map(pos, false);
    	float dist = res.x;
        if (dist>maxdist || abs(dist)<0.0001)
            break;
        t+= dist*0.22;
        objnr = res.y;
  	}
  	return vec2(t, objnr);
}


// From https://www.shadertoy.com/view/MstGDM
// Here the texture maping is only used for the normal, not the raymarching, so it's a kind of bump mapping. Much faster
vec3 getNormal(vec3 pos, float e)
{  
    vec2 q = vec2(0, e);
    return normalize(vec3(map(pos + q.yxx, true).x - map(pos - q.yxx, true).x,
                          map(pos + q.xyx, true).x - map(pos - q.xyx, true).x,
                          map(pos + q.xxy, true).x - map(pos - q.xxy, true).x));
}

// Gets the color of the floor for given position
vec3 floor_color(vec3 pos)
{
    return mix(1.2*texture(iChannel0, woodSize*pos.xz).xyz, vec3(0.65), 0.2);
}
 
// Gets the color of the spheres for given position
vec3 spheres_color(vec3 pos)
{
    //return pos.x*pos.y<0.?vec3(1.3):vec3(1.5, 1.1, 0.5);
    return vec3(1.3);
}

// Gets the color of the tablet for given position
vec3 tablet_color(vec3 pos)
{
    return vec3(0.15);
}

// Gets the color of the image on the tablet for given position
vec3 image_color(vec3 pos)
{
    return texture(iChannel2, pos2screen(pos)).rgb;
}

// Gets the color of the sky
vec3 sky_color(vec3 ray)
{
    return vec3(0.1, 0.35, 0.7)*(1. - ray.y*0.5);
}

// Combines the colors
vec3 getColor(vec3 norm, vec3 pos, int objnr)
{
   return objnr==FLOOR_OBJ?floor_color(pos):(
          objnr==TABLET_OBJ?tablet_color(pos):(
          objnr==IMAGE_OBJ?image_color(pos):(
          objnr==SPHERES_OBJ?spheres_color(pos):sky_color(pos))));
}

// From https://www.shadertoy.com/view/Xds3zN, but I changed the code
float softshadow(vec3 ro, vec3 rd, float mint, float tmax)
{
	float res = 1.0;
    float t = mint;
    for(int i=0; i<50; i++)
    {
    	float h = map(ro + rd*t, false).x;
        res = min( res, 10.0*h/t + 0.02*float(i));
        t += 0.8*clamp( h, 0.01, 0.35 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAO( in vec3 p, in vec3 n, float maxDist, float falloff )
{
	float ao = 0.0;
	const int nbIte = 5;
	for( int i=0; i<nbIte; i++ )
	{
		float l = hash(float(i))*maxDist;
		vec3 rd = n*l;
		ao += (l - map(p + rd.x, false).x) / pow(1.+l, falloff);
	}
	return clamp( 1.35*(1.-ao/float(nbIte)), 0., 1.);
}

// Fresnel reflectance factor through Schlick's approximation: https://en.wikipedia.org/wiki/Schlick's_approximation
float fresnel(vec3 ray, vec3 norm, float n2)
{
   float n1 = 1.; // air
   float angle = acos(-dot(ray, norm));
   float r0 = dot((n1-n2)/(n1+n2), (n1-n2)/(n1+n2));
   float r = r0 + (1. - r0)*pow(1. - cos(angle), 5.);
   return r;
}

// Shading of the objects pro lamp
vec3 lampShading(Lamp lamp, vec3 norm, vec3 pos, vec3 ocol, int objnr, int lampnr)
{
	vec3 pl = normalize(lamp.position - pos);
    float dlp = distance(lamp.position, pos);
    vec3 pli = pl/pow(1. + lamp.attenuation*dlp, 2.);
      
    // Diffuse shading
    vec3 col = objnr==IMAGE_OBJ?ocol*image_br:ocol*lamp.color*lamp.intensity*clamp(dot(norm, pli), 0., 1.);
    
    // Specular shading
    #ifdef specular
    if (dot(norm, lamp.position - pos) > 0.0 && lampnr!=2)
        col+= lamp.color*lamp.intensity*specint*pow(max(0.0, dot(reflect(pl, norm), normalize(pos - campos))), specshin);
    #endif
    
    // Softshadow
    #ifdef shadow
    if (objnr!=IMAGE_OBJ)
       col*= shi*softshadow(pos, normalize(vec3(lamp.position.x, 4.9, lamp.position.z) - pos), shf, 100.) + 1. - shi;
    #endif
    
    return col;
}

// Shading of the objects over all lamps
vec3 lampsShading(vec3 norm, vec3 pos, vec3 ocol, int objnr)
{
    vec3 col = vec3(0.);
    for (int l=0; l<3; l++) // lamps.length()
        col+= lampShading(lamps[l], norm, pos, ocol, objnr, l);
    
    return col;
}

// Sets the position of the camera with the mouse and calculates its direction
void setCamera()
{
   campos = vec3(-20. + 40.*iMouse.x/iResolution.x,
                 18.5 - 15.*iMouse.y/iResolution.y,
                 16.);
   camdir = camtarget-campos;   
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

// Tracing and rendering a ray
RenderData trace0(vec3 tpos, vec3 ray, float maxdist)
{
    vec2 tr = trace(tpos, ray, maxdist);
    float tx = tr.x;
    int objnr = int(tr.y);
    vec3 col;
    vec3 pos = tpos + tx*ray;
    vec3 norm;
    
    lamps[0] = Lamp(vec3(-15., 10, 20.), vec3(1., 1., 1.), 0.7, 0.01);
    lamps[1] = Lamp(vec3(15., 10, 20.), vec3(1., 1., 1.), 0.7, 0.01);
    lamps[2] = Lamp(getScreenLampPosition(vec3(0., 5.5, 0.1), pos), getScreenColor(pos), 1.8, 0.001);
    
    if (tx<maxdist)
    {
        if (objnr==TABLET_OBJ && inPic(pos)) objnr=IMAGE_OBJ;
        norm = getNormal(pos, normdelta);
        col = getColor(norm, pos, objnr);
      
        // Shading
        col = ambientColor*ambientint + lampsShading(norm, pos, col, objnr);
        
        // Ambient occlusion
        #ifdef ambocc
        col*= 1. - aoint + aoint*vec3(calcAO(pos, norm, 7., 1.1));
        //col = vec3(calcAO(pos, norm, 7., 1.1));
        #endif
    }
    else
    {
        objnr = SKY_OBJ;
        col = sky_color(ray);
    }
    return RenderData(col, pos, norm, objnr);
}

// Main render function with reflections
vec4 render(vec2 fragCoord)
{   
  vec2 uv = fragCoord.xy / iResolution.xy; 
  uv = uv*2.0 - 1.0;
  uv.x*= iResolution.x / iResolution.y;

  vec3 ray = GetCameraRayDir(uv, camdir, fov);
    
  RenderData traceinf = trace0(campos, ray, maxdist);
  vec3 col = traceinf.col;
  #ifdef reflections
  float r = 1.;
  for (int i=0; i<nbref; i++)
  {
  	  if (traceinf.objnr==FLOOR_OBJ || traceinf.objnr==IMAGE_OBJ || traceinf.objnr==SPHERES_OBJ)
      {
          vec3 refray = reflect(ray, traceinf.norm);
          RenderData traceinf_ref = trace0(traceinf.pos, refray, 30.);
          if (traceinf.objnr==SPHERES_OBJ)
          {
              r*= 0.92;
              col = mix(col, col*traceinf_ref.col, r);
          }
          else
          {
              r*= 1.1*clamp(fresnel(ray, traceinf.norm, 2.5), 0.0, 0.3);
              col = mix(col, traceinf_ref.col, r);
          }
          ray = refray;
          traceinf = traceinf_ref;
      }
  }
  #endif

  return vec4(col, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    setCamera();
    
    // Antialiasing
    vec4 vs = vec4(0.);
    for (int j=0;j<aasamples ;j++)
    {
       float oy = float(j)*aawidth/max(float(aasamples-1), 1.);
       for (int i=0;i<aasamples ;i++)
       {
          float ox = float(i)*aawidth/max(float(aasamples-1), 1.);
          vs+= render(fragCoord + vec2(ox, oy));
       }
    }
    vec2 uv = fragCoord.xy / iResolution.xy;
    //fragColor = mix(vec4(0.8*getScreenColor(vec3(uv, 0.)), 0.), texture(iChannel2, uv), 0.05); 
    fragColor = vs/vec4(aasamples*aasamples);
}