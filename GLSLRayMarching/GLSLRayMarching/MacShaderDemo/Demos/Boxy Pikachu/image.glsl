#define AA 4 // Anti-aliasing sampling box size factor. Total number of samples will be AA ^ 2

#define PI 3.141592653589

float time;

// 2D rotation matrix
mat2 rotmat(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

// Rounded box distance with internal distance, 2D version.
float box(vec3 p,vec3 s)
{
    p=abs(p)-s;
    float d=max(p.x,max(p.y,p.z));
    return max(d,length(max(p,vec3(0))));
}

// Rounded box distance with internal distance, 3D version.
float box(vec2 p,vec2 s)
{
    p=abs(p)-s;
    float d=max(p.x,p.y);
    return max(d,length(max(p,vec2(0))));
}

// The main body SDF, sans mouth.
float body(vec3 p)
{
    float d=1e4;
    p.y+=.05;

    // Tail, made of some rotated boxes.
    float taild;
    vec3 tp=p;
    tp.xy*=rotmat(0.2);
    taild=box(tp-vec3(1,0.4,1.2),vec3(.5,.3,.1))-.1;
    taild=min(taild,box(tp-vec3(1.2,1.3,1.2),vec3(.3,.7,.1))-.1);
    taild=min(taild,box(tp-vec3(1.9,1.5,1.2),vec3(.9,.5,.1))-.1);

    d=min(d,taild);

    // Rest of the body is symmetrical.
    p.x=abs(p.x);

    // Torso / head.
    d=min(d,box(p,vec3(.93,.7,.95))-.2);
    
    // Ears
    d=min(d,box(p-vec3(.6,1,-.6+p.y/8.),vec3(.2,1.1,.05))-.1);

    // Feet
    p-=vec3(-.1,.05,.1);
    d=min(d,box(vec3(p.xy,abs(p.z-.1))-vec3(.7,-1,.7),vec3(.23,.4,.15))-.06);
    p-=vec3(.7,-1.4,-.0);
    p.z=abs(p.z);
    d=min(d,box(p-vec3(0,0,0.7),vec3(.23,.05,.2))-.06);
    
    return d;
}

// The complete body.
float bodyWithMouth(vec3 p)
{
    float d=body(p);
    
    p.x=abs(p.x);
    
    // Main mouth shape.
    d=max(d,-(box(p-vec3(0,-.4,-2),vec3(.34,.14,1.2))-.012));
    
    // The upper triangular part, which is just a rotated box.
    p.y+=.21;
    p.z+=2.;
    p.xy*=rotmat(-1.);
    d=max(d,-(box(p,vec3(.1,.05,1.2))-.012));
    
    return d;
}

// Scene SDF.
float f(vec3 p)
{
    return bodyWithMouth(p);
}

// Linstep, for cheaper smoothening of texture edges.
float linstep(float a,float b,float x)
{
    return clamp((x-a)/(b-a),0.,1.);
}

// Face texture.
vec3 face(vec2 p)
{
    p.y*=1.1;
    vec3 c=vec3(1,1,.2);
    
    // Mirrored through X axis.
    p.x=abs(p.x);
    
    // Eyes
    c=mix(c,vec3(0),linstep(.02,.01,box(p-vec2(.45,.3),vec2(.15,.17))));
    c=mix(c,vec3(1),linstep(.02,.01,box(p-vec2(.4,.39),vec2(.04,.04))));
    
    // Nose
    c=mix(c,vec3(0),linstep(.02,.01,box(p-vec2(0,-.02),vec2(.07,.03))));
    
    // Cheeks
    c=mix(c,vec3(1,.15,.04),linstep(.02,.01,box(p-vec2(0.7,-.25),vec2(.18,.2))));
    
    return c;
}

// Maps [0, 1] x [0, 1] to unit disc.
vec2 disc(vec2 uv)
{
   float a = uv.x * PI * 2.;
   float r = sqrt(uv.y);
   return vec2(cos(a), sin(a)) * r;
}

// Maps [0, 1] x [0, 1] to disc with linear distribution.
vec2 tent(vec2 uv)
{
	return disc(vec2(uv.x, 1. - sqrt(1. - uv.y)));
}

vec3 sampleScene(vec2 coord)
{
    vec2 t = coord / iResolution.xy * 2. - 1.;
	t.x *= iResolution.x / iResolution.y;
    
    // Set up primary ray.
    float an=7.;
    vec3 ro=vec3(.3,0.6,15.);
    vec3 rd=normalize(vec3(t.xy,-5.));

    // Intersect with ground plane.
    float groundt=(-1.55-ro.y)/rd.y;

	// Compositional orientation.
    rd.xz=mat2(cos(an),sin(an),sin(an),-cos(an))*rd.xz;
    ro.xz=mat2(cos(an),sin(an),sin(an),-cos(an))*ro.xz;

    // Animating orientation.
    mat2 rx=rotmat(cos(time*7.)*.1);
    mat2 rz=rotmat(cos(time*3.)*.1);

    ro.y-=abs(sin(time*7.+PI))/8.+.05;
    ro.yz*=rx;
    rd.yz*=rx;

    ro.xy*=rz;
    rd.xy*=rz;

    // Reject negative ground plane intersection distance.
    if(groundt<0.)
        groundt=1e4;

    float dt=5.,d=0.;
    
    // Trace through SDF.
    for(int i=0;i<140;++i)
    {
        d=f(ro+rd*dt);
        if(abs(d)<1e-3||dt>20.||dt>groundt)
            break;
        dt+=d;
    }

    // Backdrop colour.
    vec3 c=vec3(.5,15,.3)*.9;
    
    if(groundt<dt)
    {
        // Ground is nearer. Just apply some basic shadow shape.
        vec3 rp=ro+rd*groundt;
        c*=mix(.7,1.,linstep(0.,.1,box(rp.xz,vec2(1.))-.5));
    }
    else if(dt<20.)
    {   
        // SDF is nearer.
        float d2=f(ro+rd*dt+normalize(vec3(-2,2,-1))*1e-2);
        float l=.5+.5*(d2-d)/1e-2;

        // Get the intersection point.
        vec3 rp=ro+rd*dt;

        // Determine a colour based on where the ray hit is.
        
        c=vec3(1,1,.2);

        if(bodyWithMouth(rp)>body(rp))
            // Main body.
            c=vec3(1.3,.5,1)/2.*mix(.5,1.,smoothstep(.3,.6,l));
        else if(rp.z<-1.)
            // Face texture.
            c=face(rp.xy);
        else if(rp.y>1.2&&rp.z<0.)
            // Tips of ears.
            c=mix(c,vec3(0),linstep(0.,.01,rp.y-1.7));

        // Stripes on back.
        rp.xz=abs(rp.xz-vec2(0,.3))-vec2(0,.3);
        rp.y-=.8;
        float stripesd=box(rp,vec3(6,.5,.15))-.02;
        c=mix(c,vec3(1,.5,.1)/4.,linstep(.01,0.,stripesd));

		// Apply some directional light.
        c*=mix(vec3(1,1,.8)*.9,vec3(1),smoothstep(.3,.31,l));
    }
    
    return c;
}


// Hash function from IQ.
float hash(float n)
{
    return fract(sin(n)*43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    time = iTime;
	fragColor.a = 1.;

    fragColor.rgb = vec3(0);
    
    // Toroidal shift for anti-aliasing samples.
    float hashindex=fragCoord.x+fragCoord.y*957.;
    vec2 uvshift=vec2(hash(hashindex*2.),hash(hashindex*2.+1.));
    
    // Anti-aliasing loop.
    for(int y=0;y<AA;++y)
        for(int x=0;x<AA;++x)
        {
            // Get a filter kernel samplepoint. Here a tent filter is used.
            vec2 uv=fract(vec2(float(x)+.5,float(y)+.5)/float(AA)+uvshift);
            vec2 offset = tent(uv);
            
            // Sample the scene.
		    fragColor.rgb += clamp(sampleScene(fragCoord + offset), 0., 1.);
        }
    
    fragColor.rgb /= float(AA * AA);
    
    // Gamma correction.
    fragColor.rgb=pow(fragColor.rgb,vec3(1./2.2));
}

