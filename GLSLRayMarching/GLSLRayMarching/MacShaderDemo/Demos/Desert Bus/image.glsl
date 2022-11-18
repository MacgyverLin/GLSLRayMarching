const float pi = acos(-1.);
const float SPEED = 3.;
const float BUSSTOP_WAVELENGTH = 1000.;

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
    vec3 d = abs(p) - b;
    return length(max(d,0.0)) - r
        + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdCylinder(vec3 p, float r)
{
    return length(p.xy) - r;
}

float sdCappedCylinder(vec3 p, float r, float h, float steer)
{
    p.xz = rotate(p.xz, steer);
    return max(sdCylinder(p, r), abs(p.z)-h);
}

float bettersin(float a)
{
    return sin(a*pi*2.-.5*pi)*.5+.5;
}

vec2 steering(float time)
{
    time = mod(time, 8.);
    float t;
    if (time < 7.)
        t = (time / 7.);
    else
        t = 1.-(time-7.);
    return vec2(
        smoothstep(0.,1.,t)*2.-1.,
        time>7.?bettersin(t)*.5:0.
    );
}

float shadowscene(vec3 p)
{
    vec2 steer = steering(iTime);

    vec3 bp = p;
    bp.y += sin(iTime*10.)*.03;
    bp.z += steer.x;
    float bus = sdRoundBox(bp-vec3(0,-.1,0), vec3(4.,.8,1)-.1, .3);

    float ground = p.y + 1.5;
    ground = max(ground, length(p+vec3(0,1.5,0))-7.);

    return min(bus, ground);
}

vec2 scene(vec3 p)
{
    vec2 steer = steering(iTime);

    vec3 bp = p;
    bp.y += sin(iTime*10.)*.03;
    bp.z += steer.x;
    float bus = sdRoundBox(bp-vec3(0,-.1,0), vec3(4.,.8,1)-.1, .3);
    bus = max(bus, -sdCylinder(bp - vec3(3,-1,0), .5));
    bus = max(bus, -sdCylinder(bp - vec3(-3,-1,0), .5));
    bus = max(bus, -sdCylinder(bp - vec3(-2,-1,0), .5));

    vec3 wp = p;
    wp.z += steer.x;
    wp.z = abs(wp.z);
    wp.z -= 1.;
    float wheels = 1000.;
    wheels = min(wheels, sdCappedCylinder(wp - vec3( 3,-1,0), .4, .2, steer.y));
    wheels = min(wheels, sdCappedCylinder(wp - vec3(-3,-1,0), .4, .2, 0.));
    wheels = min(wheels, sdCappedCylinder(wp - vec3(-2,-1,0), .4, .2, 0.));

    float hubcaps = 1000.;
    hubcaps = min(hubcaps, sdCappedCylinder(wp - vec3( 3,-1,0), .17, .3, steer.y));
    hubcaps = min(hubcaps, sdCappedCylinder(wp - vec3(-3,-1,0), .17, .3, 0.));
    hubcaps = min(hubcaps, sdCappedCylinder(wp - vec3(-2,-1,0), .17, .3, 0.));

    float windows = sdRoundBox(bp - vec3(4,.1,0), vec3(.8,.3,.8), .1);
    windows = min(windows, sdRoundBox(bp - vec3(2.8 +bp.y*.7,.1,0), vec3(.5,.3,2), .1));
    windows = min(windows, sdRoundBox(bp - vec3(1.4 +bp.y*.7,.1,0), vec3(.5,.3,2), .1));
    windows = min(windows, sdRoundBox(bp - vec3(     bp.y*.7,.1,0), vec3(.5,.3,2), .1));
    windows = min(windows, sdRoundBox(bp - vec3(-1.4+bp.y*.7,.1,0), vec3(.5,.3,2), .1));
    windows = min(windows, sdRoundBox(bp - vec3(-2.8+bp.y*.7,.1,0), vec3(.5,.3,2), .1));

    float ground = p.y + 1.5;
    ground = max(ground, length(p+vec3(0,1.5,0))-7.);

    vec3 bsp = p;
    float bst = mod(iTime*SPEED*5., BUSSTOP_WAVELENGTH)-BUSSTOP_WAVELENGTH*.5;
    float busstop = sdCappedCylinder(bsp.xzy+vec3(bst,4.2,.5), .05, 1., 0.);
    busstop = min(busstop, sdCappedCylinder(bsp.yzx+vec3(-.9,4.2,bst), .4, .05, 0.));
    busstop = max(busstop, sdCylinder(bsp.xzy, 7.));

    float mat = 0.;
    float best = 1000.;
    if (ground < best) { mat = 1.; best = ground; }
    if (bus < best) { mat = 2.; best = bus; }
    if (wheels < best) { mat = 3.; best = wheels; }
    if (busstop < best) { mat = 5.; best = busstop; }

    if (mat == 2. && windows < bus)
        mat = 4.;

    if (mat == 3. && hubcaps < wheels)
        mat = 2.;

    return vec2(
        best,
        mat
    );
}

float sdCircle(vec2 uv, float r)
{
    return length(uv)-r;
}

float sceneLRR(vec2 uv)
{
    uv.y -= .3;
    float circles = min(
        min(
            sdCircle(uv+vec2(.14,0), .033),
            sdCircle(uv+vec2(.24,0), .033)
        ),
        min(
            sdCircle(uv+vec2(.34,0), .033),
            sdCircle(uv+vec2(-.03,0), .1)
        )
    );
    uv.y = abs(uv.y);
    float chevron = dot(vec3(uv,1),vec3(1,2.3,-.4));
    chevron = max(.1-uv.x, chevron);
    chevron = max(-sdCircle(uv+vec2(-.05,0), .15), chevron);

    return min(chevron, circles);
}

void mainImage(out vec4 out_color, vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy - .5;
    uv.x *= iResolution.x / iResolution.y;

    vec3 cam = vec3(0,0,-15);
    vec3 dir = normalize(vec3(uv,1));

    cam.yz = rotate(cam.yz, .3);
    dir.yz = rotate(dir.yz, .3);

    cam.xz = rotate(cam.xz, pi/3.);
    dir.xz = rotate(dir.xz, pi/3.);

    float t=0.;
    vec2 k=vec2(0);
    for(int i=0;i<100;++i)
    {
        k=scene(cam+dir*t);
        t+=k.x;
        if (k.x<.001)
            break;
    }
    vec3 h = cam+dir*t;
    vec2 o = vec2(.01, 0);
    vec3 n = normalize(vec3(
        scene(h+o.xyy).x-scene(h-o.xyy).x,
        scene(h+o.yxy).x-scene(h-o.yxy).x,
        scene(h+o.yyx).x-scene(h-o.yyx).x
    ));
    out_color.rgb = n*.5+.5;
    //out_color.rgb = fract(h);

    if (k.x > 1.)
        k.y = 0.;

    float fakeAO = shadowscene(h+n*.8)/.8;
    fakeAO = clamp(fakeAO, 0., 1.) * .4 + .6;


    vec3 albedo = vec3(1);
    float mat = k.y;
    if (mat == 0.)
    { // sky
        float d = sceneLRR(uv);
        vec3 light = vec3(.4,.6,1);
        vec3 dark  = vec3(.1,0,.6);
        out_color.rgb = mix(light, dark, smoothstep(-.001, .001, d));
        return;
    }
    else if (mat == 1.)
    { // ground
        h.z = abs(h.z);

        albedo = vec3(.9, .6, 0);

        if (h.z < 3.2 && h.y > -1.6)
            albedo = vec3(.4);
        else if (h.z < 4. && h.y > -1.6)
            albedo = vec3(.6,.4,0);

            if (h.z < .3 && fract(h.x*.2+iTime*SPEED) < .5 && h.y > -1.6)
                albedo = vec3(1,.9,.2);
            }
    else if (mat == 2.)
    { // bus
        albedo = vec3(.7,.8,.9);
    }
    else if (mat == 3.)
    { // wheels
        albedo = vec3(.1);
    }
    else if (mat == 4.)
    { // windows
        albedo = vec3(.1);
    }
    else if (mat == 5.)
    { // busstop
        albedo = h.y > .5 ? vec3(1,0,0) : vec3(.8);
    }

    float light = dot(n, normalize(vec3(2,3,1)))*.5+.5;

    out_color.rgb = albedo * light * fakeAO;

    //out_color = vec4(step(screenUV.y, steering(screenUV.x * 8)));
}