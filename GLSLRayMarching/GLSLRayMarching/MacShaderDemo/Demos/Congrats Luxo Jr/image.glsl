
// **************************************************************************
// CONSTANTS

#define PI 3.14159
#define TWO_PI 6.28318
#define PI_OVER_TWO 1.570796
#define ONE_OVER_PI 0.318310

#define SMALL_FLOAT 0.0001
#define BIG_FLOAT 1000000.

// **************************************************************************
// DEFINES

#define COWL_MATL 1.
#define LAMP_MATL 2.
#define BULB_MATL 3.
#define FLOOR_MATL 4.
#define SPRING_MATL 5.
#define TAIL_MATL 6.
#define WALL_MATL 7.
#define DEBUG_MATL 10.

//#define DEBUG_ACCEL_MARCH 1
#define CALC_SHADOWS 1
//#define CALC_AMBIENTOCCLUSION 1

// **************************************************************************
// KINEMATIC STATE

struct LuxoData
{
    vec3 footorient;
    vec3 footjoint;
    vec3 midjoint;
    vec3 headjoint;
    vec3 headorient;
    float celbowang;
    float selbowang;
};

// **************************************************************************
// GLOBALS

vec3  g_camPointAt   = vec3(0.);
vec3  g_camOrigin   = vec3(0.);

float g_time        = 0.;
vec4  g_debugcolor  = vec4(0.);

// Default Pose
LuxoData g_lux = LuxoData(vec3(0., -.4, 0.),
                          vec3(0., -.1, 0.),
                          vec3(.22, .18, 0.),
                          vec3(-0.16, .76, 0.),
                          vec3(-1.0, 0.5, 0.),
                          1., 0.);

// **************************************************************************
// UTILITIES

// Rotate the input point around the y-axis by the angle given as a  cos(angle)
// and sin(angle) argument.  There are many times where  I want to reuse the
// same angle on different points, so why do the  heavy trig twice.
vec3 rot_around_y( vec3 point, float cosangle, float sinangle )
{
    return vec3(point.x * cosangle  + point.z * sinangle,
                point.y,
                point.x * -sinangle + point.z * cosangle);
}

// Rotate the input point around the x-axis by the angle given as a  cos(angle)
// and sin(angle) argument.  There are many times where  I want to reuse the
// same angle on different points, so why do the  heavy trig twice.
vec3 rot_around_x( vec3 point, float cosangle, float sinangle )
{
    return vec3(point.x,
                point.y * cosangle - point.z * sinangle,
                point.y * sinangle + point.z * cosangle);
}

// Rotate the input point around the 2d origin by the angle given as a cos(angle)
// and sin(angle) argument.
vec2 rot_vec2( vec2 xy, float cosangle, float sinangle )
{
    return vec2(xy.x * cosangle - xy.y * sinangle,
                xy.x * sinangle + xy.y * cosangle);
}

vec3 orient_to_y( vec3 p, vec3 lookdir )
{
    // assume lookdir is a normalized vector that we will use to
    // normalize with the y-axis

    // if lookdir is pointing exactly in the positive or negative
    // y direction, then we can return the positive or negative
    // identity respectively.
    if (abs(lookdir.y) >= 1.) return sign(lookdir.y) * p;

    vec3 v1 = lookdir;
    vec3 up = vec3(0., 1., 0.); // assuming up vector in world is y
    vec3 v3 = normalize( cross(v1, up) );
    vec3 v2 = cross(v3, v1);
    
    // orthogonal matrix so inverse == transpose
    return vec3( dot(p,v2),
                 dot(p,v1),
                 dot(p,v3) );
}

float pow5(float v)
{
    float tmp = v*v;
    return tmp*tmp*v;
}

vec2 mergeobjs(vec2 a, vec2 b) { return mix(b, a, step(a.x, b.x)); }
float uniondf(float a, float b) { return min(a, b); }
float intersdf(float a, float b) { return max(a, b); }
float diffdf(float a, float b) { return max(a, -b); }

#define NOISE_DIMENSION 64.

float noise1f( float n )
{   
    
    vec2 coords = vec2(mod(floor(n),NOISE_DIMENSION)/NOISE_DIMENSION, 
                       floor(n/NOISE_DIMENSION)/NOISE_DIMENSION);
    
    return texture(iChannel0, coords, -100. ).r;
} 

// **************************************************************************
// INTERSECTION FOR ACCELERATION STRUCTURE

// intersection for a sphere with a ray. If the ray origin is inside the
// sphere or there is any interesection, >1 is returned, otherwise 0.

float intersect_sphere(vec3 ro, vec3 rd, float r, vec3 sphc)
{

    vec3 so = ro - sphc;

    float a = dot(rd, rd);
    float b = dot(so, rd);
    float c = dot(so, so) - r*r;
    float discr = b*b - a*c;

    float zero_discr = step(SMALL_FLOAT, discr);
    float tmin = (-b - sqrt(discr))/a;

    return zero_discr * (step(0., tmin) + step(dot(so, so), r*r)); 
}

// **************************************************************************
// DISTANCE FIELDS

float roundboxdf( vec3 p, vec3 bounds, float r )
{
    return length(max(abs(p)-bounds * vec3(1., .5, 1.),0.0))-r;
}

float cylinderdf( vec3 p, float r, float h)
{
    return max( length(p.xz)-r, abs(p.y) - h*.5 );
}

float spheredf( vec3 p, float r )
{
    return length(p) - r;    
}

float clippedconedf( vec3 p, vec2 dims, vec2 clips )
{
    
    vec2 q = vec2( length(p.xz), p.y );
    return max( max( dot(q, dims.xy), p.y), max(p.y+clips.x, -p.y-clips.y ));
}

float torusdf( vec3 p, float r, float d )
{
  vec2 q = vec2(length(p.xz)-r,p.y);
  return length(q)-d;
}

float oroundboxdf( vec3 p, vec3 a, vec3 b, 
                   vec3 bounds, float r )
{
    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a)); o.y -= bounds.y * .5;
    return roundboxdf(o, bounds, r);
}

float ocylinderdf( vec3 p, vec3 a, vec3 b, 
                   float r, float h)
{
    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a)); o.y -= h * .5;
    return cylinderdf(o, r, h);
}


float ospheredf( vec3 p, vec3 a, vec3 b,
                float r )
{
    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a)); o.y *= -1.; o.y += r;
    return spheredf(o, r);
}

float oclippedconedf( vec3 p, vec3 a, vec3 b, 
                      vec2 dims, vec2 clips)
{
    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a));
    
    return clippedconedf(o, dims, clips);
}


vec2 lampobj( vec3 p, vec3 rd, vec3 a, vec3 b )
{

    vec2 obj = vec2(BIG_FLOAT, -1.);

    vec3 o = p - a;    
    o = orient_to_y(o, normalize(b - a)); // EXPENSIVE
    
    obj.x = uniondf( obj.x, spheredf(o - vec3(0., .16, 0.), .365));
    
    o.x += -.09;
    
    float ty = -.04;

    // cowl
    vec2 cowl = vec2(BIG_FLOAT, COWL_MATL);
    vec3 cowlo = o; cowlo.y += ty;

    float c = min(0., -.55*cos(4.8*cowlo.y-.25)*(1.2 * cowlo.y- .06) - .1);

    cowlo.xz += .7 * c * normalize(cowlo.xz);
    
    float m = .11;

    cowlo *= -1.; cowlo.y -= .4;
    cowl.x = clippedconedf(cowlo, 
                  vec2(.4, m), vec2(0.21, 0.7));

    cowl.x = diffdf( cowl.x, clippedconedf( cowlo, 
                     vec2(.4, m * .95), vec2(0.22, 1.)));

    // - vent slits
    float numSlits = 16.;
    float ang = TWO_PI * (mod(atan(o.x,o.z)/TWO_PI, 1./numSlits) - (.5/numSlits));
    float l = length(o.xz);
    vec3 modo = vec3(l * cos(ang), o.y + ty, l * sin(ang));

    cowl.x = diffdf(cowl.x, ocylinderdf(modo, 
                                         vec3(.08, -0.16, 0.0), vec3(.42, 1., 0.), 
                                        .008, .07)); // EXPENSIVE


    // + nubbin and base
    cowl.x = uniondf(cowl.x, cylinderdf(o + vec3(0., .18 + ty, 0.), .017, .08));
    cowl.x = uniondf(cowl.x, spheredf((vec3(.6, 1., 0.6) * o) + vec3(0., .22 + ty, 0.), .018));

    // + bulb seat
    cowl.x = uniondf(cowl.x, cylinderdf(o + vec3(0., .12 + ty, 0.), .045, .12));
                     
    // + bulb
    vec2 bulb = vec2(BIG_FLOAT, BULB_MATL);
    bulb.x = spheredf(o - vec3(0., .12 - ty, 0.), .15);

    obj = mergeobjs(cowl, bulb);

    return obj;
}

vec2 upperarm( vec3 p, vec3 rd, vec3 a, vec3 b)
{
    vec2 obj = vec2(BIG_FLOAT, LAMP_MATL);

    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a)); // EXPENSIVE

    vec3 t = vec3(-0.05, -.045, 0.);
    o += t;

    // symmetry along the xy plane
    o.z = abs(o.z);

    // neck
    obj.x = cylinderdf(o - vec3(-.05, .51, 0.), .025, .12);

    obj.x = uniondf( obj.x, cylinderdf(o - vec3(-.05, .59, 0.),  .04, .07));

    // + rear top block
    obj.x = uniondf( obj.x, oroundboxdf(o - vec3(-.06, .5,.035),
                                        vec3(0.), vec3(.25, -.25, .0),
                                        vec3(.022, .19, .01), .002)); // EXPENSIVE

    // + front top block
    obj.x = uniondf( obj.x, oroundboxdf(o - vec3(-.05, .5, .035),
                                        vec3(.0), vec3(-.08, -.3, .0),
                                        vec3(.022, .19, .01), .002)); // EXPENSIVE

    // + rear top rod
    obj.x = uniondf( obj.x,
                    cylinderdf(o - vec3(.06, .24, .0), .025, .35));

    // + front top rod
    obj.x = uniondf( obj.x,
                    cylinderdf(o - vec3(-.09, .22, .0), .025, .35));

    // + bolts
    obj.x = uniondf( obj.x, spheredf(o - vec3(-.05,  .48, .04), .016));
    obj.x = uniondf( obj.x, spheredf(o - vec3(.06, .38, .04), .016));
    obj.x = uniondf( obj.x, spheredf(o - vec3(-.09, .35, .04), .016));

    // + horizontal rods and nubs
    vec3 hrodo = o - vec3(0.06, .09, 0.);
    hrodo = orient_to_y(hrodo, normalize(vec3(0., 0., 1.))); // EXPENSIVE

    obj.x = uniondf( obj.x, cylinderdf(hrodo, .01, .15));
    obj.x = uniondf( obj.x, cylinderdf(hrodo - vec3(.0, .07, .0), .015, .01));
    obj.x = uniondf( obj.x, cylinderdf(hrodo - vec3(.125, .0, .15), .01, .15));
    obj.x = uniondf( obj.x, cylinderdf(hrodo - vec3(.125, .07, .15), .015, .01));

    // + upper spring
    vec2 springobj = vec2(BIG_FLOAT, SPRING_MATL);

    vec3 springo = o;
    springo -= vec3(.055, .09, .06);
    springo = orient_to_y(springo, normalize(vec3(-1., 0.85, 0.))); // EXPENSIVE
    springo.y -= .1;
    float  c = cos(240.0*springo.y);
    float  s = sin(240.0*springo.y);
    mat2   m = mat2(c,s,-s,c);
    springo.xz = m*springo.xz;
    springo -= vec3(.0, .0, .01);
    springobj.x = cylinderdf(springo, .0095, .2);

    obj = mergeobjs(obj, springobj);


    return obj;
}

vec2 elbow( vec3 p, vec3 rd, vec3 a, vec3 b)
{
    
    vec2 obj = vec2(BIG_FLOAT, LAMP_MATL);
    
    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a)); // EXPENSIVE

    vec3 t = vec3(-0.05, -.045, 0.);
    o += t;

    // symmetry along the xy plane
    o.z = abs(o.z);

    // rear mid block   
    vec3 baro = o - vec3(-.063, -.04, .035);
    vec3 barb = vec3(.3, .3, .01);
    vec3 bounds = vec3(.05, .21, .01);
    baro = orient_to_y(baro, normalize(barb)); baro.y -= bounds.y * .5; // EXPENSIVE
    baro.x *= mix(1., 2.5, smoothstep(-.2, .26, baro.y));
    obj.x = uniondf( obj.x, roundboxdf(baro, bounds, .002));

    // + front mid block
    obj.x = uniondf( obj.x, oroundboxdf(o - vec3(-.06, -.08, .035),
                                        vec3(.0), vec3(-.1644, .9864, .0),
                                        vec3(.025, .21, .01), .002)); // EXPENSIVE  
    // + bolt
    obj.x = uniondf( obj.x, spheredf(o - vec3(.0, .0, .04)-t, .016));

    return obj;
}

vec2 lowerarm( vec3 p, vec3 rd, vec3 a, vec3 b)
{
    vec2 obj = vec2(BIG_FLOAT, LAMP_MATL);

    vec3 o = p - a;
    o = orient_to_y(o, normalize(b - a)); 

    // symmetry along the xy plane
    o.z = abs(o.z);

    // rear bottom rod
    obj.x = roundboxdf(o - vec3(0.01, .2, 0.),
                       vec3(0.022, .35, 0.012), .007);

    // + rear ankle joint    
    vec2 rearank = rot_vec2(vec2(0.9578, 0.2873), g_lux.celbowang, g_lux.selbowang);
    obj.x = uniondf( obj.x, oroundboxdf(o - vec3(-.01, .04,.035),
                                        vec3(0.), vec3(rearank.x, rearank.y, .0),
                                        vec3(.022, .25, .01), .002));

    // + front ankle joint
    vec2 frontank = rot_vec2(vec2(0.9987, -.05), g_lux.celbowang, g_lux.selbowang);
    obj.x = uniondf( obj.x, oroundboxdf(o - vec3(-.01, .04,.035),
                                        vec3(0.), vec3(frontank.x, frontank.y, .0),
                                        vec3(.018, .18, .01), .002));

    // + horizontal rods and nubs
    
    vec2 tfo = vec2(-.01, .04) + .155 * frontank;
    vec2 tro = vec2(-.01, .04) + .22 * rearank;

    vec3 hrodo = orient_to_y(o, normalize(vec3(0., 0., 1.)));
	
    obj.x = uniondf( obj.x, cylinderdf(hrodo-vec3(tfo.y, 0., -tfo.x), .01, .26));    
    obj.x = uniondf( obj.x, cylinderdf(hrodo-vec3(tfo.y + 0.15, 0., -tfo.x), .01, .2));
    obj.x = uniondf( obj.x, cylinderdf(hrodo-vec3(tro.y, 0., -tro.x), .01, .16));

    // + zig zag strut    
    obj.x = uniondf( obj.x, roundboxdf(o - vec3(tfo.x, tfo.y + .09, 0.105),
                       vec3(0.011, .2, 0.008), .007));

    obj.x = uniondf( obj.x, oroundboxdf(o - vec3(tfo.x, tfo.y + .185, 0.105),
                                        vec3(0.), vec3(0., 1., -1.),
                                        vec3(0.008, .05, 0.011), .007));

    obj.x = uniondf( obj.x, roundboxdf(o - vec3(tfo.x, tfo.y + .285, 0.07),
                       vec3(0.011, .13, 0.008), .007));

    // + bolts
    vec2 bfo = vec2(-.01, .04) + .02 * frontank;
    obj.x = uniondf( obj.x, spheredf(o - vec3(bfo.x, bfo.y, .04), .016));
    obj.x = uniondf( obj.x, spheredf(o - vec3(tfo.x, tfo.y + .33, .085), .016));

    // + lower spring
    vec2 springobj = vec2(BIG_FLOAT, SPRING_MATL);

    vec3 so = vec3(tfo.x + .03, tfo.y + .115, .07);
    vec3 springo = orient_to_y(o - so, normalize(vec3(tro.x - so.x, tro.y - so.y, 0.)));
    springo.y *= 0.06/length(vec3(tro.x - so.x, tro.y - so.y, 0.));
    float  c = cos(300.0*springo.y);
    float  s = sin(300.0*springo.y);
    mat2   m = mat2(c,s,-s,c);
    springo.xz = m*springo.xz;
    springo -= vec3(.0, .0, .01);
    springobj.x = cylinderdf(springo, .0095, .1);

    obj = mergeobjs(obj, springobj);
    
    return obj;
}

vec2 base( vec3 p, vec3 rd, vec3 a, vec3 b)
{    
    vec2 obj = vec2(BIG_FLOAT, LAMP_MATL);

    vec3 o = p - a;    

    o = orient_to_y(o, normalize(b - a));
    
    vec3 baseo = o;
    baseo *= vec3(.9, .9, .9);
    baseo.y += -.16;

    // base ring rounded curve
    obj.x = torusdf( baseo, .3, .05);

    // + base cylinder
    obj.x = uniondf( obj.x, cylinderdf( baseo, .3, .1));

    // - base bottom
    obj.x = diffdf( obj.x, -baseo.y );

    // + base bottom piping
    obj.x = uniondf( obj.x, torusdf(baseo, .35, .015));

    baseo.y += .0603;

    // + base neck scarf
    float baseneck = cylinderdf( baseo, .08, .05);
    baseneck = diffdf( baseneck, torusdf(baseo + vec3(0., .012, 0.), .07, .024));
    obj.x = uniondf( obj.x, baseneck);

    baseo.y += .025;

    // + base neck piping 
    obj.x = uniondf( obj.x, torusdf(baseo, .045, .015));

    // + base neck
    obj.x = uniondf( obj.x, cylinderdf(baseo, .025, .2));
    
    return obj;
}

vec2 tailobj( vec3 p, vec3 rd, vec3 a)
{    
    vec2 obj = vec2(BIG_FLOAT, TAIL_MATL);

    vec3 o = p - a;    
    
    o.z += .2 * sin(2. * o.x);

    obj.x = ocylinderdf( o, vec3(.4, -.18, 0.2), vec3(1., -.18, 0.2), .015, 5.);// EXPENSIVE

    return obj;
}

vec2 floorobj( vec3 pos ) 
{
    return vec2(abs( pos.y + 0.3 ), FLOOR_MATL);
}

vec2 wallsobj( vec3 pos )
{
    return vec2(10. - length(pos.xz), WALL_MATL);
}

// **************************************************************************
// SCENE MARCHING

vec2 scenedf( vec3 pos, vec3 rd )
{
    vec2 obj = vec2(BIG_FLOAT, -1.);
    
    // Base
    vec3 sphc = g_lux.footjoint - vec3(0., .34, .0);
    float sphr = .44;
    if (intersect_sphere(pos, rd, sphr, sphc) > .5)
    {    
        obj = mergeobjs(obj, base( pos, rd, g_lux.footjoint, g_lux.footorient));

        #ifdef DEBUG_ACCEL_MARCH
        obj = mergeobjs(obj, vec2(spheredf(pos - sphc, sphr), DEBUG_MATL));
        #endif
    }

    // Lower Arm
    sphc = .4 * (g_lux.footjoint + g_lux.midjoint);
    sphr = .85 * length(g_lux.midjoint - g_lux.footjoint);
    if (intersect_sphere(pos, rd, sphr, sphc) > .5)
    {    
        obj = mergeobjs(obj, lowerarm( pos, rd, g_lux.footjoint, g_lux.midjoint));

        #ifdef DEBUG_ACCEL_MARCH
        obj = mergeobjs(obj, vec2(spheredf(pos - sphc, sphr), DEBUG_MATL));
        #endif
    }
    
    // Elbow
    sphc = g_lux.midjoint + vec3(-.01, .12, .0);
    sphr = .18;
    if (intersect_sphere(pos, rd, sphr, sphc) > .5)
    {    
        obj = mergeobjs(obj, elbow(pos, rd, g_lux.midjoint, g_lux.headjoint));

        #ifdef DEBUG_ACCEL_MARCH
        obj = mergeobjs(obj, vec2(spheredf(pos - sphc, sphr), DEBUG_MATL));
        #endif
    }

    // Upper Arm
    sphc = .5 * (g_lux.midjoint + g_lux.headjoint);
    sphr = .5 * length(g_lux.headjoint - g_lux.midjoint);
    if (intersect_sphere(pos, rd, sphr, sphc) > .5)
    {    
        obj = mergeobjs(obj, upperarm(pos, rd, g_lux.midjoint, g_lux.headjoint));

        #ifdef DEBUG_ACCEL_MARCH
        obj = mergeobjs(obj, vec2(spheredf(pos - sphc, sphr), DEBUG_MATL));
        #endif
    }

    // Lamp Head 
    sphc = g_lux.headjoint + vec3(-.2, .05, 0.);
    sphr = .5;
    if (intersect_sphere(pos, rd, sphr, sphc) > .5)
    {    
        obj = mergeobjs(obj, lampobj( pos, rd, g_lux.headjoint, g_lux.headorient) );
        #ifdef DEBUG_ACCEL_MARCH
        obj = mergeobjs(obj, vec2(spheredf(pos - sphc, sphr), DEBUG_MATL));
        #endif
    }

    // Lamp Tail
    obj = mergeobjs(obj, tailobj( pos, rd, g_lux.footjoint) );

    // distance from a floor
    obj = mergeobjs(obj, floorobj( pos ));
    
    // distance from surrounding cylinder wall
    obj = mergeobjs(obj, wallsobj( pos ));
    
    return obj;
}

#define DISTMARCH_STEPS 60
#define DISTMARCH_MAXDIST 40.

vec2 distmarch( vec3 ro, vec3 rd, float maxd )
{    
    float dist = 10. * SMALL_FLOAT;
    float t = 0.;
    float material = 0.;
    for (int i=0; i < DISTMARCH_STEPS; i++) 
    {
        if ( abs(dist) < SMALL_FLOAT || t > maxd ) break;
        // advance the distance of the last lookup
        t += dist;
        vec2 dfresult = scenedf( ro + t * rd, rd );
        dist = dfresult.x;
        material = dfresult.y;
    }

    if( t > maxd ) material = -1.0; 
    return vec2( t, material );
}

// **************************************************************************
// SHADOWING & NORMALS

vec3 compute_normal( vec3 p )
{
    vec3 d = vec3( 0.001, 0.0, 0.0 );
    vec3 n = vec3(
        scenedf(p + d.xyy, normalize(d.xyy)).x - scenedf(p - d.xyy, -normalize(d.xyy)).x,
        scenedf(p + d.yxy, normalize(d.yxy)).x - scenedf(p - d.yxy, -normalize(d.yxy)).x,
        scenedf(p + d.yyx, normalize(d.yyx)).x - scenedf(p - d.yyx, -normalize(d.yyx)).x );
    return normalize( n );
}

#define SOFTSHADOW_STEPS 90
#define SOFTSHADOW_STEPSIZE .025

float soft_shadow( vec3 ro, 
                      vec3 rd, 
                      float mint, 
                      float maxt, 
                      float k )
{
    float shadow = 1.0;
    float t = mint;

    for( int i=0; i < SOFTSHADOW_STEPS; i++ )
    {
        if( t < maxt )
        {
            float h = scenedf( ro + rd * t, rd ).x;
            shadow = min( shadow, k * h / t );
            t += SOFTSHADOW_STEPSIZE;
        }
    }
    return clamp( shadow, 0.0, 1.0 );

}

#define AO_NUMSAMPLES 8
#define AO_STEPSIZE .02
#define AO_STEPSCALE .7

float ambient_occlusion( vec3 p, 
              vec3 n )
{
    float ao = 0.0;
    float aoscale = 1.0;

    for( int aoi=0; aoi < AO_NUMSAMPLES ; aoi++ )
    {
        float step = 0.01 + AO_STEPSIZE * float(aoi);
        vec3 aop =  n * step + p;
        
        float d = scenedf( aop, n ).x;
        ao += -(d-step)*aoscale;
        aoscale *= AO_STEPSCALE;
    }
    
    return clamp( ao, 0.0, 1.0 );
}

// **************************************************************************
// CAMERA

struct CameraData
{
    vec3 origin;
    vec3 dir;
    vec2 st;
};

CameraData setup_camera(vec2 fragCoord)
{

    // aspect ratio
    float invar = iResolution.y / iResolution.x;
    vec2 st = fragCoord.xy / iResolution.xy - .5;
    st.y *= invar;

    // calculate the ray origin and ray direction that represents
    // mapping the image plane towards the scene
    vec3 iu = vec3(0., 1., 0.);

    vec3 iz = normalize( g_camPointAt - g_camOrigin );
    vec3 ix = normalize( cross(iz, iu) );
    vec3 iy = cross(ix, iz);

    vec3 dir = normalize( st.x*ix + st.y*iy + 1.0 * iz );

    return CameraData(g_camOrigin, dir, st);

}

// **************************************************************************
// SHADING

struct SurfaceData
{
    vec3 point;
    vec3 normal;
    vec3 basecolor;
    vec3 emissive;
    float roughness;
    float specular;
    float metallic;
    float ambocc_amount;
    float cowl_shadow;
};

#define INITSURF(p, n) SurfaceData(p, n, vec3(0.), vec3(0.), 0., 1., 0., 1., 1.)

struct BRDFVars
{
    // vdir is the view direction vector
    vec3 vdir;
    // The half vector of a microfacet model 
    vec3 hdir;
    // cos(theta_h) - theta_h is angle between half vector and normal
    float costh; 
    // cos(theta_d) - theta_d is angle between half vector and light dir/view dir
    float costd;      
    // cos(theta_l) - theta_l is angle between the light vector and normal
    float costl;
    // cos(theta_v) - theta_v is angle between the viewing vector and normal
    float costv;
};


void calc_material(float matid,
                   inout SurfaceData surf)
{
    vec3 surfcol = vec3(1.);
    if (matid - .5 < COWL_MATL) 
    { 
        surf.basecolor = vec3(.95); 
        surf.roughness = .25;
        surf.metallic = .0;
        surf.specular = 1.;
        surf.ambocc_amount = 0.;
        surf.cowl_shadow = 0.;
    } 
    else if (matid - .5 < LAMP_MATL) 
    { 
        surf.basecolor =  vec3(.95); 
        surf.roughness = .25;
        surf.metallic = 0.;
        surf.specular = 1.;
    } 
    else if (matid - .5 < BULB_MATL)
    {
        surf.ambocc_amount = 0.;
        surf.basecolor = vec3(.3);
        surf.emissive = 2.8 * vec3(1., 1., .6);
        surf.roughness = 0.;
        surf.specular = 1.;
    }
    else if (matid - .5 < FLOOR_MATL)
    {
        float board = 1.2 * surf.point.x;
        float rboard = noise1f(floor(board));
        float grainrot = mix(-.5, .5, rboard);
        vec2 boarduv = rot_vec2(vec2(.5, 1.) * surf.point.zx, cos(grainrot), sin(grainrot)) + vec2(40.323, 17.232) * rboard;
        
        vec4 pavem = texture(iChannel1, boarduv);
        float floordivide = smoothstep(.0, .03, fract(board)) * smoothstep(1., .99, fract(board));
        surf.basecolor = pavem.rgb * (.3 + .7 * floordivide);
        surf.metallic = .0;
        surf.roughness = .2;
        surf.specular = .1;

        // hacky bump map
        surf.normal.xz += .2 * pavem.bg + vec2(mix(-.1, .1, rboard), 0.);
        surf.normal = normalize(surf.normal);
    }
    else if (matid - .5 < SPRING_MATL)
    {
        surf.basecolor = vec3(.2, .2, .3);
        surf.metallic = 1.;
        surf.roughness = .02;
        surf.specular = .5;
    }
    else if (matid - .5 < TAIL_MATL)
    {
        surf.basecolor = vec3(1.);
        surf.metallic = .0;
        surf.roughness = .8;
        surf.specular = .2;
    }
    else if (matid - .5 < DEBUG_MATL)
    {
        surf.basecolor = vec3(.6, 0., 0.);
        surf.metallic = 0.;
        surf.roughness = 1.;
        surf.specular = 0.;
        surf.emissive = vec3(.3, 0., 0.);
    }

}


BRDFVars calc_BRDFvars(SurfaceData surf, vec3 ldir)
{
    vec3 vdir = normalize( g_camOrigin - surf.point );
    vec3 hdir = normalize(ldir + vdir);
	/*
    float costh = max(0., dot(surf.normal, hdir)); 
    float costd = max(0., dot(ldir, hdir));      
    float costl = max(0., dot(surf.normal, ldir));
    float costv = max(0., dot(surf.normal, vdir));
	*/
    
    float costh = dot(surf.normal, hdir); 
    float costd = dot(ldir, hdir);      
    float costl = dot(surf.normal, ldir);
    float costv = dot(surf.normal, vdir);
    return BRDFVars(vdir, hdir, costh, costd, costl, costv);

}

vec3 integrate_dirlight(vec3 ldir, vec3 lcolor, float shadowAtten, SurfaceData surf)
{

    BRDFVars bvars = calc_BRDFvars( surf, ldir );

    vec3 cout = vec3(0.);

    if (bvars.costl > SMALL_FLOAT)
    {
        float frk = .5 + 2.* bvars.costd * bvars.costd * surf.roughness;        
        vec3 diff = surf.basecolor * ONE_OVER_PI * (1. + (frk - 1.)*pow5(1.-bvars.costl)) * (1. + (frk - 1.) * pow5(1.-bvars.costv));

        float rroughness = max(0.05, surf.roughness);
        // D(h) factor
        // using the GGX approximation where the gamma factor is 2.

        float alpha = rroughness * rroughness;
        float denom = bvars.costh * bvars.costh * (alpha*alpha - 1.) + 1.;
        float D = (alpha*alpha)/(PI * denom*denom); 

        // G(h,l,v) factor    
        // remap hotness of roughness for analytic lights
        float k = rroughness / 2.;
        float Gv = step(0., bvars.costv) * (bvars.costv/(bvars.costv * (1. - k) + k));
        float Gl = step(0., bvars.costl) * (bvars.costl/(bvars.costl * (1. - k) + k));

        float G = Gl * Gv;

        // F(h,l) factor
        vec3 F0 = surf.specular * mix(vec3(1.), surf.basecolor, surf.metallic);
        vec3 F = F0 + (1. - F0) * pow5(1. - bvars.costd);

        vec3 spec = D * F * G / (4. * bvars.costl * bvars.costv);
        
        float shad = 1.;
        #ifdef CALC_SHADOWS
        if ( bvars.costl > SMALL_FLOAT && shadowAtten > SMALL_FLOAT)
        {        
            shad = mix(1., soft_shadow( surf.point, ldir, 0.1, 2.5, 50.), shadowAtten);
        }
        #endif

        cout  += diff * bvars.costl * shad * lcolor;
        cout  += spec * bvars.costl * shad * lcolor;
    }
    cout += surf.emissive;
    
    return cout;
}

vec3 shade(SurfaceData surf)
{    

    // ambient occlusion is amount of occlusion.  So 1 is fully occluded
    // and 0 is not occluded at all.  Makes math easier when mixing 
    // shadowing effects.
    float ao = 0.;
    #ifdef CALC_AMBIENTOCCLUSION
    ao = ambient_occlusion(surf.point, surf.normal) * surf.ambocc_amount;
    //g_debugcolor = vec4(vec3(ao), 1.);
    #endif
    
    // MAIN KEY
    vec3 keydir = normalize(vec3(-1.5, 1.,-0.8));
    vec3 keyillum  = vec3(3.);
    vec3 cout   = (1. - 2.5 * ao) * integrate_dirlight(keydir, keyillum, 1., surf);
    
    // LAMP
    vec3 lamporient = normalize(g_lux.headorient - g_lux.headjoint);
    vec3 lamppos = .32 * lamporient + g_lux.headjoint;
    
    vec3 lampv = lamppos - surf.point;
    float lampvl = length(lampv);
    vec3 lampdir = normalize(lampv);
    
    float lampatten = 15./(lampvl * lampvl);
    lampatten *= mix(1., smoothstep(.0, .4, dot(-lamporient, lampdir)), surf.cowl_shadow);
    lampatten *= .04 + .96 * surf.cowl_shadow;
    vec3 lampillum = lampatten * vec3(1., 1., .8);    
    
    if (lampatten > SMALL_FLOAT)
    {
        cout   += integrate_dirlight(lampdir, lampillum, 0., surf);
    }
    
    // AMBIENT
    vec3 amb = vec3(.15) * surf.basecolor;
    
    // BOUNCE
    vec3 bncpos = (.5 * lamporient + g_lux.headjoint) * vec3(1., -1., 1.);
    vec3 bncv = bncpos - surf.point;
    float bncvl = length(bncv);
    vec3 bncdir = normalize(bncv);
    float ndbnc =  max(0., dot(bncdir, surf.normal));
    vec3 bnc = surf.basecolor * vec3(1., .9, .8) * (1./(bncvl * bncvl)) * ndbnc * ndbnc;
    //g_debugcolor = vec4(bnc, 1.) * max(0., (1. - 5.5 * ao));
    cout       += (amb + bnc) * max(0., (1. - 5.5 * ao));

    return cout;

}

// **************************************************************************
// GLOBALS

// reference: https://www.shadertoy.com/view/ldlGR7
vec3 ik_solve( vec3 foot,
               vec3 head,
               float larm,
               float uarm)
{
 
    vec3 q = head - foot;
    q = q * ( 0.5 + 0.5*(larm*larm-uarm*uarm)/dot(q, q ) );
    float s = larm*larm/dot(q,q) - 1.0;
    return q + q.yxz*sqrt( s ) + foot;
}

void animate_globals()
{
    // remap the mouse click ([-1, 1], [-1/ar, 1/ar])
    vec2 click = iMouse.xy / iResolution.xx;    
    click = 2.0 * click - 1.0;  
    
    g_time = iTime;

    // camera position
    g_camOrigin = vec3(3., 0.0, 3.);
    
    float rotXAng    = -PI * (.5 * sin(.88 * PI * click.y) + .5);
    float cosrotXAng = cos(rotXAng);
    float sinrotXAng = sin(rotXAng);
    
    float rotYAng    = .2 * g_time + TWO_PI * click.x;
    float cosrotYAng = cos(rotYAng);
    float sinrotYAng = sin(rotYAng);

    // Rotate the camera around the origin
    g_camOrigin = rot_around_x(g_camOrigin, cosrotXAng, sinrotXAng);
    g_camOrigin = rot_around_y(g_camOrigin, cosrotYAng, sinrotYAng);

    g_camPointAt   = vec3(0., 0.2, 0.);

    // animate luxo
    g_lux.headjoint.y += -.03 + .12 * sin(3.8 * g_time);
    g_lux.headorient.z += .05 * cos(3.6 * g_time);   
    g_lux.headorient.y += .2 * sin(.8 * g_time) - .1;    
     
    
    g_lux.midjoint = ik_solve(g_lux.footjoint, 
                              g_lux.headjoint,
                              .45, .6);
    
    vec3 larmv = normalize(g_lux.midjoint - g_lux.footjoint);
    vec3 uarmv = normalize(g_lux.headjoint - g_lux.midjoint);
    float larmang = atan( larmv.y, larmv.x );
    float uarmang = atan( uarmv.y, uarmv.x );
    // change in elbow angle from the default modeled position
    float elbowang = -(.9048 - 2.1508) + (larmang - uarmang);
    g_lux.celbowang = cos(elbowang);
    g_lux.selbowang = sin(elbowang);
    
    g_lux.headorient.z += .5 * sin(3.8 * g_time);  

}


// **************************************************************************
// MAIN

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    
    // ----------------------------------
    // Animate globals

    animate_globals();

    // ----------------------------------
    // Setup Camera

    CameraData cam = setup_camera(fragCoord);

    // ----------------------------------
    // SCENE MARCHING

    vec2 scenemarch = distmarch( cam.origin, 
                                 cam.dir, 
                                 DISTMARCH_MAXDIST );
    
    // ----------------------------------
    // SHADING
    vec3 scenecol = vec3(0.);
    if (scenemarch.y > 0.5)
    {
        vec3 mp = cam.origin + scenemarch.x * cam.dir;
        vec3 mn = compute_normal( mp );

        SurfaceData currSurf = INITSURF(mp, mn);
        calc_material(scenemarch.y, currSurf);

        scenecol = shade( currSurf );
    }
    
    // ----------------------------------
    // POST PROCESSING
    
    // fall off exponentially into the distance (as if there is a spot light
    // on the point of interest).
    scenecol *= exp( -0.05*scenemarch.x*scenemarch.x );

    // Gamma correct
    scenecol = pow(scenecol, vec3(0.45));

    if (g_debugcolor.a > 0.) {        
        fragColor.rgb = g_debugcolor.rgb;
    } else {
        fragColor.rgb = scenecol;
    }
    fragColor.a = 1.;
}