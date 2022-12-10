/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/LavaTemple.glsl
*/

float time = 0.0;
float pi=0.0;

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}


float torus(vec3 p, float r, float s) {
  
  return length(vec2(length(p.xz)-r,p.y))-s;
}

float cyl(vec3 p, float r, float s) {
  
  return max(length(p.xz)-r,abs(p.y)-s);
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

#define rep(p,s) ((fract((p)/(s)-0.5)-0.5)*(s))

float stair(vec3 p, float size, float w) {
  
  p.x=rep(p.x,size*2.0);
  p.xy *= rot(pi*0.25);
  
  
  float d=box(p, vec3(size,size,w));
  
  return d;
}

// repeat r times around y axis
vec2 rota(vec2 p, float r) {
  float a=atan(p.y,p.x)/(2.0*pi);
  a=rep(a,1.0/r)*2.0*pi;
  return vec2(cos(a),sin(a))*length(p);
}

float temple(vec3 p) {
  
  p.y=-abs(p.y-20.0)+20.0;
    
  p.xz = rota(p.xz, 10.0);
  p.x -= 6.0;
  
  p.x = abs(p.x-15.0)-15.0;

  p.xz = abs(p.xz);
  if(p.x>p.z) p.xz=p.zx;
  
  p.y=-p.y;
  
  vec3 p2=p;
  p2.y=abs(p2.y)-1.0;
  float d=box(p2, vec3(1,0.1,2));
  d=min(d, box(p-vec3(1.0,0,2), vec3(0.1,2.,0.1)));
  d=min(d,box(p2-vec3(0,1,0), vec3(1.3,0.1,3)));
  d=min(d,box(p2-vec3(0,1.2,0), vec3(0.8,0.1,2.5)));
  
  vec3 p3=p;
  p3.zy *= rot(-pi*0.25);
  float d2=stair(p3.zyx-vec3(0,0.7,0.5), 0.1, 0.3);
  d2=min(d2,stair(p3.zyx-vec3(0,0.3,0.5), 0.3, 0.9));
  d2=max(d2, p.y+0.9);
  d=min(d, d2);
  
  return d;
}

float ground(vec3 p) {
  
  float d=10000.0;
  p.y-=8.0;
  for(float i=0.0; i<5.0; ++i) {
    //p.xz = rota(p.xz, 20);
    p.xz *= rot(0.3);
    p.xz = abs(p.xz);
    p.xz-=5.0;
    p.y+=0.1;
    float ouv = sin(p.z*0.8+ i)*0.5;
    d=min(d, box(p, vec3(2.0+ouv,3,5)));
    p.xy *= rot(0.03);
  }
  
  return d;
}

// glow for white lasers
float at=0.0;
// glow for yellow lava
float at2=0.0;
float map(vec3 p) {
  
  float d=temple(p);
  
  d=min(d, ground(p));
  
  // Lava
  float d3 = cyl(p-vec3(0,10,0), 30.0,2.0);
  at2 += 0.5/(0.5+abs(d3));
  d=min(d,d3);

  // lasers
  float d2 = abs(length(p.xz)-3.0);
  
  p.xz = rota(p.xz, 10.0);
  p.x -= 36.0;
  
  d2 = min(d2, max(p.y,abs(length(p.xz)-0.2)));
  
  at += 0.01/(0.1+d2*d2);
  //at += exp(-d2*2.0)*0.1;
  
  // we use max here so that the ray can never get close enough to the surface
  // so the ray go through the laser and continue
  d = min(d, max(d2,0.2));
  
  return d;
}

float getao(vec3 p, vec3 n, float dist) {
  return clamp(map(p+n*dist)/dist,0.0,1.0);
}

void cam(inout vec3 p) {
    float t=time*0.3;
  p.yz *= rot(sin(t*1.3)*0.2+0.5);
  p.xz *= rot(t);
}

float rnd(vec2 uv) {
  return fract(dot(sin(uv*427.542+uv.yx*741.521),vec2(274.511)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	time = iTime;
    pi=acos(-1.0);
    
  vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
  uv -= 0.5;
  uv /= vec2(iResolution.y / iResolution.x, 1);

  float dist = 50.0 + sin(time*0.2)*20.0 + sin(time*0.07)*10.0;
  vec3 s=vec3(0,0,-dist);
  cam(s);
  
  vec3 t=vec3(0,-10,0);
  vec3 cz=normalize(t-s);
  vec3 cx=normalize(cross(cz,vec3(sin(time*0.3)*0.1,1,0)));
  vec3 cy=normalize(cross(cz,cx));
  
  float fov=1.0;
  vec3 r=normalize(uv.x*cx+uv.y*cy+fov*cz);
  
  s.y+=10.0;
  
  float edgescreensize=0.0015;
  float edgesize = 0.05;
  
  vec3 p=s;
  float edge=0.0;
  bool nearsurface=false;
  float dd=0.0;
  
  float dither = mix(1.0,0.9,rnd(uv));

  for(int i=0; i<100; ++i) {
    float d=map(p)*dither;
    // This can be used to adjust the edge size according to distance
    //edgesize = edgescreensize*dd;
    
    // if close enough to the surface
    if(d<edgesize) {
      nearsurface=true;
    }
    // if we were close enough to the surface but we now are far again, we just missed a surface so this is an edge
    if(nearsurface && d>edgesize) {
      edge = 1.0;
    }
    if(d<0.001) {
      break;
    }
    if(d>200.0) break;
      
    p+=r*d;
    dd+=d;
  }
  
  float fog = 1.0-clamp(dd/200.0,0.0,1.0);
  
  
  vec3 col=vec3(0);
  
  vec2 off=vec2(0.01,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  
  vec3 l=normalize(-vec3(1,3,2));
  
  col+=max(0.0,dot(n,l))*vec3(0.2,0.4,1.0)*2.0;
  col *= fog;
  
  vec3 background = mix(vec3(0.6,0.3,0.8),vec3(0.6,0.6,0.0),smoothstep(0.1,0.8,r.y));
  background = mix(background,vec3(0.0,0.6,0.9),smoothstep(0.1,-0.9,r.y));
  
  // background lines, infinitely far away using ray direction
  vec3 r2 = r;
  for(float i=0.0; i<5.0; ++i) {
    float t=time*0.0+i+74.521;
    r2.xz *= rot(t);
    r2.xy *= rot(t*1.3);
    r2 = abs(r2)-0.2;
  }
  vec3 grid = smoothstep(0.49,0.5,abs(fract(r2.xyz*5.0)-0.5));
  background -= max(grid.x,max(grid.y,grid.z))*0.2;
  
  col += background*step(fog,0.01);
  
  // We use AO to put an edge on the crease of the surface
  float ao = getao(p,n, edgesize);
  if(ao<0.9) edge=max(edge,step(0.01,fog));
  
  // We use AO from inside the surface to put an edge on the outer edges of the surface
  float ao2 = getao(p,n, -edgesize);
  if(ao2<0.9) edge=max(edge,step(0.01,fog));
  
  // a little ao shadow below the temple
  float ao3 = getao(p,n, 5.0)*0.5+0.5;
  col *= ao3;
  
  col += at*0.4;
  col += at2*vec3(1,0.5,0.2)*0.1;
  
  col *= 1.0-edge;
  
  fragColor = vec4(col, 1);
}