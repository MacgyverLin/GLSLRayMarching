// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
    Iain M. Banks Culture ships "Mistake Not" and "Ethics Gradient"

    Voxel code blatently borrowed from IQs Voxel Edges
    https://www.shadertoy.com/view/4dfGzs

    Model adapted from
    
    GSV
    https://www.shadertoy.com/view/lstfz4

	Mistake Not
    https://www.shadertoy.com/view/4llfDl

*/

#define BODY 6.0
#define GLOW 7.0
#define CHROME 8.0

//Nimitz
float tri(float x) {
    return abs(x - floor(x) - 0.5);
} 

vec3 pointOnLine(in vec3 a, in vec3 b, in float t) {
    return a + normalize(b-a)*length(b-a)*t;    
}

//IQ SDF Functions
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdEllipsoid(vec3 p, vec3 r) {
    return (length(p / r) - 1.0) * min(min(r.x, r.y), r.z);
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xy) - t.x, p.z);
    return length(q) - t.y;
}

float sdTorus2(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.yz) - t.x, p.x);
    return length(q) - t.y;
}

float sdConeSection(vec3 p, float h, float r1, float r2) {
    float d1 = -p.y - h,
          q = p.y - h,
          si = 0.5 * (r1 - r2) / h,
          d2 = max(sqrt(dot(p.xz, p.xz) * (1.0 - si * si)) + q * si - r2, q);
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float smin(float a, float b, float k) {
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

//Mercury SDF Functions
float fCylinder(vec3 p, float r, float height) {
	float d = length(p.xz) - r;
	d = max(d, abs(p.y) - height);
	return d;
}

float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.0 * PI / repetitions,
          a = atan(p.y, p.x) + angle / 2.0,
          r = length(p),
          c = floor(a / angle);
    a = mod(a, angle) - angle / 2.0;
    p = vec2(cos(a), sin(a)) * r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions / 2.0)) c = abs(c);
    return c;
}

vec2 nearest(vec2 a, vec2 b){ 
    float s = step(a.x, b.x);
    return s * a + (1. - s) * b;
}

vec2 dfGun(vec3 rp) {
    float grey = fCylinder(rp.xzy - vec3(0.0, 0.8, 0.0), 0.1, 0.4);
    rp.z = abs(rp.z);
    grey = min(grey, fCylinder(rp.xzy - vec3(0.0, 0.4, 0.0), 0.4, 0.04));   
    pModPolar(rp.yx, 3.0);
    float body = fCylinder(rp.xzy - vec3(0.0, 0.5, 0.2), 0.1, 0.1);
    return nearest(vec2(body, BODY), vec2(grey, CHROME));
}

vec2 dfManipulator(vec3 rp, float ma) {
    rp.yz *= rot(ma);
    vec3 j5b = vec3(0.2, 0.0, 0.0),
         j5a = j5b + vec3(0.0, 0.0, -1.0) * 0.2,
         j5c = j5b + vec3(0.0, 0.0, 1.0) * 0.2,
         j5d = vec3(0.0, j5c.yz);    
    float body = fCylinder(rp.xzy - j5d.xzy, 0.4, 0.02),
          manipulator = sdConeSection(rp.xzy - vec3(0.0, 1.2, 0.0), 1.0, 0.16, 0.01);
    rp.x = abs(rp.x);
    manipulator = min(manipulator, sdTorus2(rp - vec3(0.3,0.0,0.0), vec2(0.1, 0.04)));
    body = min(body, fCylinder(rp.zxy - j5b.zxy, 0.14, 0.1));
    float chrome = sdCapsule(rp, j5a, j5c, 0.05);
    vec2 near = nearest(vec2(body, BODY), vec2(chrome, CHROME));
    return nearest(near, vec2(manipulator, GLOW));
}

//la - lower arm angle, ua - upper arm angle, ma - manipulator angle 
vec4 dfArm(vec3 rp, float la, float ua, float ma, inout vec3 tipPos) {  
    //calculate joint positions
    vec3 lad = vec3(0.0, 1.0, 0.0);
    lad.yz *= rot(la);
    //lower arm
    vec3 j1a = vec3(0.1, 0.0, 0.45),
         j1b = j1a + lad * 2.0,
         j1c = j1a + lad * 3.0,
         j1d = j1a + lad * 4.0;
    //lower arm piston
    vec3 j2a = vec3(0.0, 0.0, -0.3),
         j2b = vec3(0.0, j1b.yz),  
         lad2 = normalize(j2b - j2a);
    float adt = length(j2b - j2a);
    vec3 j2c = j2a + lad2 * 0.4,
         j2d = j2a + lad2 * (adt - 0.8);
    //upper arm
    vec3 uad = vec3(0.0, 0.0, 1.0),
         uad2 = vec3(0.0, 0.0, 1.0);
    uad.yz *= rot(ua);
    uad2.yz *= rot(ua);
    vec3 j3b = vec3(0.0, j1c.yz),
         j3a = j3b + uad2 * -0.6,
         j3c = j3b + uad * 3.5,
         j3d = j3b + uad * 7.0;
    //upper arm piston
    vec3 j4a = vec3(0.0, j1d.yz),
         ud3 = normalize(j3c - j4a),
         j4b = j4a + ud3 * 0.6,
         j4c = j4a + ud3 * 2.2,
         j4d = vec3(0.2, j4c.yz),
         j4e = vec3(0.2, j3c.yz),
         j4f = j4a + ud3 * 1.8;
    //lower arm piston
    float body = fCylinder(rp.zxy - j2a.zxy, 0.14, 0.3),
          chrome = sdCapsule(rp, j2a, j2b, 0.05);
    body = min(body, sdCapsule(rp, j2c, j2d, 0.1));
    //upper arm
    chrome = min(chrome, sdCapsule(rp, j3a, j3d, 0.05));
    body = min(body, fCylinder(rp.zxy - j3c.zxy, 0.14, 0.3));
    body = min(body, fCylinder(rp.zxy - j3d.zxy, 0.14, 0.1));
    //upper arm piston top
    body = min(body, sdCapsule(rp, j4b, j4f, 0.1));
    chrome = min(chrome, sdCapsule(rp, j4a, j4c, 0.05));
    //manipulator
    tipPos += j3d;
    vec3 tipDir = vec3(0,0,1);
    tipDir.yz *= rot(-ma);
    tipPos += tipDir*2.2;
    vec2 manipulator = dfManipulator(rp - j3d, ma);
    rp.x = abs(rp.x);
    //glow joints
    float glow = sdTorus2(rp - vec3(0.3, j3c.y, j3c.z), vec2(0.1, 0.04));
    glow = min(glow, sdTorus2(rp - vec3(0.3, j2a.y, j2a.z), vec2(0.1, 0.04)));
    glow = min(glow, sdTorus2(rp - vec3(0.2, j1a.y, j1a.z), vec2(0.1, 0.04)));
    glow = min(glow, sdTorus2(rp - vec3(0.2, j1b.y, j1b.z), vec2(0.1, 0.04)));
    glow = min(glow, sdTorus2(rp - vec3(0.2, j1c.y, j1c.z), vec2(0.1, 0.04)));
    glow = min(glow, sdTorus2(rp - vec3(0.2, j1d.y, j1d.z), vec2(0.1, 0.04)));
    //lower arm
    body = min(body, fCylinder(rp.zxy - j1a.zxy, 0.14, 0.1));    
    chrome = min(chrome, sdCapsule(rp, j1a, j1d, 0.05));
    body = min(body, fCylinder(rp.zxy - j1b.zxy, 0.14, 0.1));
    body = min(body, fCylinder(rp.zxy - j1c.zxy, 0.14, 0.1));
    body = min(body, fCylinder(rp.zxy - j1d.zxy, 0.14, 0.1));
    //upper arm piston   
    chrome = min(chrome, sdCapsule(rp, j4c, j4d, 0.05));
    chrome = min(chrome, sdCapsule(rp, j4d, j4e, 0.05));
    //get nearest
    vec2 near = nearest(vec2(body, BODY), vec2(chrome, CHROME));
    near = nearest(near, vec2(glow, GLOW));
    return vec4(nearest(near, manipulator), glow, manipulator.x);
}

vec4 dfShip(vec3 p, inout vec3 tipPos) {   
    vec3 q = p;
    vec4 ani = texture(iChannel0, ARM/R);
    p.xy *= rot(ani.w);
    //ship body
    float body = max(sdEllipsoid(p, vec3(0.5, 0.5, 4.0)), p.z*-1.0);
    body = min(body, sdSphere(p, 0.5));
    body = max(body, -fCylinder(p.xzy, 0.3, 1.0));
    q.xy *= rot(PI / 3.0);
    pModPolar(q.yx, 3.0);
    body = max(body, -sdEllipsoid(q - vec3(0.0, 0.4, 3.0), vec3(0.2, 0.3, 2.0)));
    body = min(body, sdTorus(p - vec3(0,0,2.6), vec2(0.34, 0.03)));
    //gun mount
    body = smin(body, sdBox(q - vec3(0.0, 0.6, 0.4), vec3(0.05, 0.8, 0.2)), 0.2);
    body = min(body, fCylinder(q.xzy - vec3(0.0, 0.4, 1.5), 0.2, 0.4));
    vec2 gun = dfGun(q - vec3(0.0, 1.5, 0.4));
    //engine
    float enginecowl = max(sdConeSection(p.xzy - vec3(0,-0.3,0), 0.3, 0.36, 0.46),
                           -fCylinder(p.xzy, 0.3, 1.0));
    float enginecore = sdSphere(p, 0.38);
    //window
    float window = sdEllipsoid(p, vec3(0.40, 0.40, 3.9));
    window = max(window, p.z*-1.0);
    q = p;
    pModPolar(q.yx, 3.0); //arm platforms
    body = smin(body, sdBox(q - vec3(0.0, 0.5, 0.6), vec3(0.1, 0.3, 0.6)), 0.2);
    //armature mounts
    float amount1 = fCylinder(q.zxy - vec3(1.0, 0.0, 0.5), 0.6, 0.01);
    amount1 = max(amount1, q.z - 1.15);
    body = min(body, amount1);
    //arms
    tipPos += vec3(0.0, 1.0, 0.5);
    vec4 arm = dfArm(q - vec3(0.0, 1.0, 0.5), ani.x, ani.y, ani.z, tipPos);
    tipPos.xy *= rot(-ani.w);
    //armature mounts
    q.x = abs(q.x);
    float amount2 = fCylinder(q.zxy - vec3(0.1, 0.08, 0.5), 0.6, 0.01);
    amount2 = max(amount2, -q.z + 0.05);
    body = min(body, amount2);
    //get nearest
    vec2 near = vec2(body, BODY);
    near = nearest(near, vec2(window, GLOW));
    near = nearest(near, vec2(enginecowl, CHROME));
    near = nearest(near, vec2(enginecore, GLOW));
    near = nearest(near, gun);
    return vec4(nearest(near, arm.xy), arm.z, arm.w);
}

struct Ship {
    float t;
    float id;
    float glj;
    float glt;
    vec3 tp;
};

Ship map(vec3 p) {
    vec4 shipPos = texture(iChannel0, SP/R);
    vec4 ship = dfShip(p - shipPos.xyz, shipPos.xyz);
    return Ship(ship.x, ship.y, ship.z, ship.w, shipPos.xyz);
}

vec3 normal(vec3 p) {  
    vec2 e = vec2(-1., 1.) * EPS;   
	return normalize(e.yxx * map(p + e.yxx).t + e.xxy * map(p + e.xxy).t + 
					 e.xyx * map(p + e.xyx).t + e.yyy * map(p + e.yyy).t);   
}

Ship march(vec3 ro, vec3 rd, float maxt) {
    vec3 tipPos = vec3(0.0);
    float t = 0.0,
          id = 0.0,
          glj = 0.0,
          glt = 0.0;
    for (int i=ZERO; i<128; i++) {
        vec3 p = ro + rd*t;
        Ship ship = map(p);
        tipPos = ship.tp;
        if (abs(ship.t)<EPS) {
            id = ship.id;
            break;
        }
        //glow
        glj += 0.1 / (1.0 + ship.glj*ship.glj*500.0);
        glt += 0.1 / (1.0 + ship.glt*ship.glt*800.0);
        if (t>FAR) break;
        t += ship.t*0.8;
    }
    return Ship(t, id, glj, glt, tipPos);
}

vec3 fog(vec3 ro, vec3 rd, float maxt) {
    vec3 pc = vec3(0);
    float t = 0.0;
    for (int i=ZERO; i <64; i++) {
        vec3 p = ro + rd*t;
        float light = 1.0 - vMap(vec3(p.x, 11.0, p.z));  //inverse
        float dist = 20.0 - p.y;
        float atten = 0.06 / (1.0 + dist*dist * 0.08);
        pc += vec3(0.8,1,0.8) * atten * light;
        pc += n3D(p+T*-2.6)*0.006; 
        t += 0.4 + hash12(p.xz*3.0)*0.2;
        if (t>maxt) break;
    }
    return pc;
}

vec2 eMap(vec3 p, vec3 ballPos, vec3 tipPos1) {
    
    float amt = max(0.0, 1.0 - length(ballPos - p));
    vec3 q = p;
    q.xy *= rot(1.4 * amt * sin(T*0.6));
	q.xy += tri(p.y*1.7 + T*2.6)*0.2;
	q.xy += tri(p.y*4.9 - T*11.6)*0.1;
    float width = 0.0008 * n3D(q*22.0 + T*12.7);
    
	vec4 buf1a = texture(iChannel0, vec2(0.5, ELC1)/R),
	     buf1b = texture(iChannel0, vec2(1.5, ELC1)/R),
	     buf2a = texture(iChannel0, vec2(0.5, ELC2)/R),
	     buf2b = texture(iChannel0, vec2(1.5, ELC2)/R),
	     buf3a = texture(iChannel0, vec2(0.5, ELC3)/R),
	     buf3b = texture(iChannel0, vec2(1.5, ELC3)/R);
    
    vec3 h3 = clamp(hash33(p), 0.1, 0.4);
    vec3 tipPos2 = tipPos1,
         tipPos3 = tipPos1;
    tipPos2.xy *= rot(2.094395);
    tipPos3.xy *= rot(4.188790);
    vec3 ballPos1a = ballPos + buf1a.xyz,
         ballPos1b = pointOnLine(tipPos1, ballPos1a, h3.x),
         ballPos2a = ballPos + buf2a.xyz,
         ballPos2b = pointOnLine(tipPos2, ballPos2a, h3.y),
         ballPos3a = ballPos + buf3a.xyz,
         ballPos3b = pointOnLine(tipPos3, ballPos3a, h3.z);

    float t = sdCapsule(q, tipPos1, ballPos1a, width);
    t = min(t, sdCapsule(q, ballPos1b, ballPos + buf1b.xyz, width));
    t = min(t, sdCapsule(q, tipPos2, ballPos2a, width));
    t = min(t, sdCapsule(q, ballPos2b, ballPos + buf2b.xyz, width));
    t = min(t, sdCapsule(q, tipPos3, ballPos + buf3a.xyz, width));
    t = min(t, sdCapsule(q, ballPos3b, ballPos + buf3b.xyz, width));
    
    return vec2(t, width);
}

vec3 electric(vec3 ro, vec3 rd, float maxt, vec3 ballPos, vec3 tipPos) {

    vec3 pc = vec3(0.0);
       
    float t = 0.0;
    for (int i=ZERO; i<64; i++) {
        vec3 p = ro + rd*t;
        vec2 es = eMap(p, ballPos, tipPos);
		if (t>maxt) break;        
        pc += vec3(0,1,0) * 0.2 / (1.0 + es.x*es.x*200.0);
        pc += vec3(0.6,1,0.6) * es.y * 500.0 / (1.0 + es.x*es.x*100.0);
        
        t += es.x;
    }
    
    return pc;
}

void mainImage(out vec4 C, in vec2 U) {
    
    vec3 pc = vec3(0),
         ro = texture(iChannel0, CP/R).xyz,
         la = texture(iChannel0, LA/R).xyz,  
         sp = texture(iChannel0, SP/R).xyz,
         lgt = texture(iChannel0, LGT/R).xyz,
         rd = camera(U, R, ro, la, FL);
    
    float mint = FAR;
    
    vec4 buf = texture(iChannel1, U/R);
    pc = buf.xyz;
    mint = buf.w;
    
    //ball
    vec4 ball = texture(iChannel0, BP/R);
    vec2 bi = sphIntersect(ro, rd, ball);
    float w = sphDensity(ro, rd, ball, FAR);
    if (bi.x>0.0) {
        mint = bi.x;   
        vec3 p = ro + rd*bi.x;
        vec3 bn = sphNormal(p, ball);
        vec3 ld = normalize(ro - p);
        pc = vec3(0.2) * max(0.05, dot(ld, bn));
        float spec = pow(max(dot(reflect(-ld, bn), -rd), 0.0), 16.0);
        pc += vec3(1) * spec;
        pc += vec3(0.0, 1.0, 0.0) *w*w;
        pc += vec3(0.4, 1.0, 0.2) *pow(w, 16.0) * 4.0;
    }
   	vec2 ballB = sphIntersect(ro, rd, vec4(ball.xyz, 3.0));

    //ship with bounds
    vec2 shipB = sphIntersect(ro, rd, vec4(sp,9.0));
    Ship ship = march(ro, rd, mint);
    if (shipB.x>0.0 || shipB.y>0.0) {
        if (ship.t>0.0 && ship.t<mint) {
            mint = ship.t;
            vec3 p = ro +rd*ship.t;
            vec3 n = normal(p);
            vec3 ld = normalize(ro - p);
            vec3 bld = normalize(ball.xyz - p);
            float blt = length(ball.xyz - p);
            float atten = 1.0 / (1.0 + blt*blt*0.1);
            float spec = pow(max(dot(reflect(-ld, n), -rd), 0.0), 16.0);
            float fres = pow(clamp(dot(n, rd) + 1.0, 0.0, 1.0), 2.0);
            float light = 1.0 - vMap(vec3(p.x, 11.0, p.z));
            
            vec3 sc = vec3(0);
            if (ship.id == GLOW) {
                sc = vec3(0,1,0);    
            } else if (ship.id == BODY) {
                sc = vec3(0.1);
                pc += vec3(0,0.4,0) * light * max(0.0, n.y);
            } else if (ship.id == CHROME) {
                sc = vec3(0.6);
                pc += vec3(0,0.4,0) * light * max(0.0, n.y);
            } 

            pc = sc * max(0.05, dot(ld, n));
            pc += vec3(0,0.2,0) * light * max(0.0, n.y);
            pc += vec3(0,0,0.1) * max(0.0, n.y*-1.0);
            pc += 0.4*renderVoxels(p, reflect(rd, n), ro, ball.xyz, lgt.x, ZERO, 96).xyz;
            pc += vec3(0.8,1,0.8) * max(0.05, dot(bld, n)) * atten * lgt.x;
            pc += vec3(0.8,1,0.8) * spec;
        }
    }
    
    pc += vec3(0,1,0)*ship.glj;
    pc += vec3(0,1,0)*ship.glt * lgt.x;
    pc += fog(ro, rd, FAR) * 0.3;
    
    if ((ballB.x > 0.0 || ballB.y > 0.0) && ballB.x < mint) {
        vec3 p = ro + rd*ballB.x;
        pc += lgt.x * electric(p, rd, ballB.y - ballB.x, ball.xyz, ship.tp);
    }

    /*
    //debug ship bounds
    if (shipB.x > 0.0 || shipB.y > 0.0) {
        pc += vec3(1,0,0) * 0.3;   
    }
    //*/
    
    C = vec4(pc, 1.0);
}