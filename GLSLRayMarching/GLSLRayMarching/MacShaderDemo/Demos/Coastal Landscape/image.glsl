// Author: bitless
// Title: Coastal Landscape

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) ) //IQ's palette function (https://www.iquilezles.org/www/articles/palettes/palettes.htm)
#define sp(t) p(t,vec3(.26,.76,.77),vec3(1,.3,1),vec3(.8,.4,.7),vec3(0,.12,.54)) //sky palette
#define hue(v) ( .6 + .76 * cos(6.3*(v) + vec4(0,23,21,0) ) ) //hue

// "Hash without Sine" by Dave_Hoskins.
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
  vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
  vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
////////////////////////

vec2 rotate2D (vec2 st, float a){
    return  mat2(cos(a),-sin(a),sin(a),cos(a))*st;
}

float st(float a, float b, float s) //AA bar
{
    return smoothstep (a-s, a+s, b);
}

float noise( in vec2 p ) //gradient noise
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.-2.*f);

    return mix( mix( dot( hash22( i+vec2(0,0) ), f-vec2(0,0) ), 
                     dot( hash22( i+vec2(1,0) ), f-vec2(1,0) ), u.x),
                mix( dot( hash22( i+vec2(0,1) ), f-vec2(0,1) ), 
                     dot( hash22( i+vec2(1,1) ), f-vec2(1,1) ), u.x), u.y);
}

void mainImage( out vec4 O, in vec2 g)
{
    vec2 r = iResolution.xy
        ,uv = (g+g-r)/r.y
        ,sun_pos = vec2(r.x/r.y*.42,-.53) //sun position 
        ,tree_pos = vec2(-r.x/r.y*.42,-.2) //tree position 
        ,sh, u, id, lc, t;

    vec3 f, c;
    float xd, yd, h, a, l;
    vec4 C;
    
    float sm = 3./r.y; //smoothness factor for AA

    sh = rotate2D(sun_pos, noise(uv+iTime*.25)*.3); //big noise on the sky
     
    if (uv.y > -.4) //drawing the sky
    {
        u = uv + sh;
        
        yd = 60.; //number of rings 
        
        id =  vec2((length(u)+.01)*yd,0); //segment id: x - ring number, y - segment number in the ring  
        xd = floor(id.x)*.09; //number of ring segments
        h = (hash12(floor(id.xx))*.5+.25)*(iTime+10.)*.25; //ring shift
        t = rotate2D (u,h); //rotate the ring to the desired angle
    
        id.y = atan(t.y,t.x)*xd;
        lc = fract(id); //segment local coordinates
        id -= lc;
    
        // determining the coordinates of the center of the segment in uv space
        t = vec2(cos((id.y+.5)/xd)*(id.x+.5)/yd,sin((id.y+.5)/xd)*(id.x+.5)/yd); 
        t = rotate2D(t,-h) - sh;
    
        h = noise(t*vec2(.5,1)-vec2(iTime*.2,0)) //clouds
            * step(-.25,t.y); //do not draw clouds below -.25
        h = smoothstep (.052,.055, h);
        
        
        lc += (noise(lc*vec2(1,4)+id))*vec2(.7,.2); //add fine noise
        
        f = mix (sp(sin(length(u)-.1))*.35, //sky background
                mix(sp(sin(length(u)-.1)+(hash12(id)-.5)*.15),vec3(1),h), //mix sky color and clouds
                st(abs(lc.x-.5),.4,sm*yd)*st(abs(lc.y-.5),.48,sm*xd));
    };

    if (uv.y < -.35) //drawing water
    {

        float cld = noise(-sh*vec2(.5,1)  - vec2(iTime*.2,0)); //cloud density opposite the center of the sun
        cld = 1.- smoothstep(.0,.15,cld)*.5;

        u = uv*vec2(1,15);
        id = floor(u);

        for (float i = 1.; i > -1.; i--) //drawing a wave and its neighbors from above and below
        {
            if (id.y+i < -5.)
            {
                lc = fract(u)-.5;
                lc.y = (lc.y+(sin(uv.x*12.-iTime*3.+id.y+i))*.25-i)*4.; //set the waveform and divide it into four strips
                h = hash12(vec2(id.y+i,floor(lc.y))); //the number of segments in the strip and its horizontal offset
                
                xd = 6.+h*4.;
                yd = 30.;
                lc.x = uv.x*xd+sh.x*9.; //divide the strip into segments
                lc.x += sin(iTime * (.5 + h*2.))*.5; //add a cyclic shift of the strips horizontally
                h = .8*smoothstep(5.,.0,abs(floor(lc.x)))*cld+.1; //determine brightness of the sun track 
                f = mix(f,mix(vec3(0,.1,.5),vec3(.35,.35,0),h),st(lc.y,0.,sm*yd)); //mix the color of the water and the color of the track for the background of the water 
                lc += noise(lc*vec2(3,.5))*vec2(.1,.6); //add fine noise to the segment
                
                f = mix(f,                                                                         //mix the background color 
                    mix(hue(hash12(floor(lc))*.1+.56).rgb*(1.2+floor(lc.y)*.17),vec3(1,1,0),h)     //and the stroke color
                    ,st(lc.y,0.,sm*xd)
                    *st(abs(fract(lc.x)-.5),.48,sm*xd)*st(abs(fract(lc.y)-.5),.3,sm*yd)
                    );
            }
        }
    }
    
    O = vec4(f,1);

    ////////////////////// drawing the grass
    a = 0.;
    u = uv+noise(uv*2.)*.1 + vec2(0,sin(uv.x*1.+3.)*.4+.8);
    
    f = mix(vec3(.7,.6,.2),vec3(0,1,0),sin(iTime*.2)*.5+.5); //color of the grass, changing from green to yellow and back again
    O = mix(O,vec4(f*.4,1),step(u.y,.0)); //draw grass background

    xd = 60.;  //grass size
    u = u*vec2(xd,xd/3.5); 
    

    if (u.y < 1.2)
    {
        for (float y = 0.; y > -3.; y--)
          {
            for (float x = -2.; x <3.; x++)
            {
                id = floor(u) + vec2(x,y);
                lc = (fract(u) + vec2(1.-x,-y))/vec2(5,3);
                h = (hash12(id)-.5)*.25+.5; //shade and length for an individual blade of grass

                lc-= vec2(.3,.5-h*.4);
                lc.x += sin(((iTime*1.7+h*2.-id.x*.05-id.y*.05)*1.1+id.y*.5)*2.)*(lc.y+.5)*.5;
                t = abs(lc)-vec2(.02,.5-h*.5);
                l =  length(max(t,0.)) + min(max(t.x,t.y),0.); //distance to the segment (blade of grass)

                l -= noise (lc*7.+id)*.1; //add fine noise
                C = vec4(f*.25,st(l,.1,sm*xd*.09)); //grass outline                
                C = mix(C,vec4(f                  //grass foregroud
                            *(1.2+lc.y*2.)  //the grass is a little darker at the root
                            *(1.8-h*2.5),1.)    //brightness variations for individual blades of grass
                            ,st(l,.04,sm*xd*.09));
                
                O = mix (O,C,C.a*step (id.y,-1.));
                a = max (a, C.a*step (id.y,-5.));  //a mask to cover the trunk of the tree with grasses in the foreground
            }
        }
    }

    float T = sin(iTime*.5); //tree swing cycle
 
    if (abs(uv.x+tree_pos.x-.1-T*.1) < .6) // drawing the tree
    {
        u = uv + tree_pos;
        // draw the trunk of the tree first
        u.x -= sin(u.y+1.)*.2*(T+.75); //the trunk bends in the wind
        u += noise(u*4.5-7.)*.25; //trunk curvature
        
        xd = 10., yd = 60.; 
        t = u * vec2(1,yd); //divide the trunk into segments
        h = hash12(floor(t.yy)); //horizontal shift of the segments and the color tint of the segment  
        t.x += h*.01;
        t.x *= xd;
        
        lc = fract(t); //segment local coordinates
        
        float m = st(abs(t.x-.5),.5,sm*xd)*step(abs(t.y+20.),45.); //trunk mask
        C = mix(vec4(.07) //outline color
                ,vec4(.5,.3,0,1)*(.4+h*.4) //foreground color 
                ,st(abs(lc.y-.5),.4,sm*yd)*st(abs(lc.x-.5),.45,sm*xd));
        C.a = m;
        
        xd = 30., yd = 15.;
        
        for (float xs =0.;xs<4.;xs++) //drawing four layers of foliage
        {
            u = uv + tree_pos + vec2 (xs/xd*.5 -(T +.75)*.15,-.7); //crown position
            u += noise(u*vec2(2,1)+vec2(-iTime+xs*.05,0))*vec2(-.25,.1)*smoothstep (.5,-1.,u.y+.7)*.75; //leaves rippling in the wind
    
            t = u * vec2(xd,1.);
            h = hash12(floor(t.xx)+xs*1.4); //number of segments for the row
            
            yd = 5.+ h*7.;
            t.y *= yd;
    
            sh = t;
            lc = fract(t);
            h = hash12(t-lc); //segment color shade
    
            
            t = (t-lc)/vec2(xd,yd)+vec2(0,.7);
            
            m = (step(0.,t.y)*step (length(t),.45) //the shape of the crown - the top 
                + step (t.y,0.)*step (-0.7+sin((floor(u.x)+xs*.5)*15.)*.2,t.y)) //the bottom
                *step (abs(t.x),.5) //crown size horizontally
                *st(abs(lc.x-.5),.35,sm*xd*.5); 
    
            lc += noise((sh)*vec2(1.,3.))*vec2(.3,.3); //add fine noise
            
            f = hue((h+(sin(iTime*.2)*.5+.5))*.2).rgb-t.x; //color of the segment changes cyclically
    
            C = mix(C,
                    vec4(mix(f*.15,f*.6*(.7+xs*.2), //mix outline and foreground color
                        st(abs(lc.y-.5),.47,sm*yd)*st(abs(lc.x-.5),.2,sm*xd)),m)
                    ,m);
        }

        O = mix (O,C,C.a*(1.-a));
    }
}