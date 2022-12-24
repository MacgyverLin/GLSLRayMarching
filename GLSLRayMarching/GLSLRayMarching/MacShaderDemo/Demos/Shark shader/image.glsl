// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

const float PI = 3.14159265;
mat2 r2d(float a){float sa = sin(a);float ca=cos(a);return mat2(ca,sa,-sa,ca);}

float lenny(vec2 v)
{
  return abs(v.x)+abs(v.y);
}
float sat(float a)
{
  return clamp(a,0.,1.);
}
vec3 sat(vec3 v)
{
  return vec3(sat(v.x),sat(v.y), sat(v.z));
}

float _cir(vec2 uv, float sz)
{
  return length(uv)-sz;
}

float _sub(float a, float b)
{
  return max(a,-b);
}

vec4 shark(vec2 uv)
{
  float sharp = 80.;
  uv.x += .02*sin(10.*uv.y+iTime*2.);

  float yUp = 0.;
  float upOffX = .03;
  float bodyUp = float(uv.x >0.)*(1.-sat(_cir(vec2(2.,1.)*uv+vec2(upOffX,yUp),.2)*sharp))
  	+ float(uv.x <0.)*(1.-sat(_cir(vec2(2.,1.)*uv+vec2(-upOffX,yUp),.2)*sharp));
  float downy = .07;
  float dOffX = 0.05;
  float bodyDown = float(uv.x >0.)*(1.-sat(_cir(vec2(2.5,.7)*uv+vec2(dOffX,yUp+downy),.2)*sharp))
  +   float(uv.x <0.)*(1.-sat(_cir(vec2(2.5,.7)*uv+vec2(-dOffX,yUp+downy),.2)*sharp));
  float yArm = -.15;
  float armX = .0;
  float leftArm = (1.-sat(_sub(_cir(uv-vec2(armX,yArm),.2),_cir(uv-vec2(armX,yArm)+vec2(.0,.2),.3))*sharp));
  float yPalm = -.42;
  float palm = (1.-sat(_sub(_cir(.7*vec2(4.,1.)*uv-vec2(armX,yPalm),.15),_cir(.7*vec2(4.,1.)*uv-vec2(armX+sin(-PI+iTime)*.02,yPalm+.02*sin(iTime))+vec2(.0,.2),.3))*sharp));
  float y2 = -.3;
  float palm2 = (1.-sat(_sub(_cir(2.*uv-vec2(armX,y2),.2),_cir(2.*uv-vec2(armX,y2)+vec2(.0,.2),.3))*sharp));
  float y3 = -1.1;

  float palm3 = (1.-sat(_sub(_cir(3.*uv-vec2(armX,y3),.2),_cir(3.*uv-vec2(armX,y3)+vec2(.0,.2),.3))*sharp));

  return vec4(0.,0.1,0.1,sat(palm3+palm2+bodyUp+bodyDown+leftArm+palm));
}

vec3 rdrLand(vec2 uv, float drawShark)
{
  vec3 back = vec3(0.);
  vec3 dark = vec3(4.,32.,24.)/255.;
  vec3 light = vec3(123.,165.,103.)/255.;
  vec3 grad = dark+mix(light.yzx,dark,length(uv));
  vec2 sunP = (uv-vec2(.1))+.09*vec2(sin(55.*uv.y+iTime),sin(35.*uv.x+iTime*2.));
  vec3 sun = (1.-sat(_cir(sunP,.1)*50.))*light;
  vec3 sunHalo = pow((1.-sat(_cir(sunP,.1)*5.)),2.)*light.zyx;
  sun += sunHalo;
  float shark = shark(uv+vec2(0.,mod(-iTime*.1,2.)-1.)).w;
  back = back+grad+sun;
  return mix(back,grad*.7,shark*drawShark)*sat(1.-lenny(uv)+.3);
}

vec3 rdrScn(vec2 uv)
{
  float maskLand = 1.-sat(_cir(uv,.5)*50.);

  vec3 land = rdrLand(uv,1.);
  vec2 sp = uv-vec2(.1);
  float auv = iTime*.05+atan(-abs(sp.y),sp.x)/PI*2.;
  float freq = 55.;
  vec3 land2 = rdrLand(uv+vec2(sin(auv*freq),cos(auv*freq))*.02,.2)*.5;
  return mix(rdrLand(uv*.7,0.)*.5,land,maskLand)+(land2*.5)*length(uv*3.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 uv = fragCoord.xy / iResolution.xx;
  uv -= vec2(.5)*iResolution.xy/iResolution.xx;
  uv *= 2.;
  vec3 col = rdrScn(uv);
  fragColor = vec4(col, 1.0);
}