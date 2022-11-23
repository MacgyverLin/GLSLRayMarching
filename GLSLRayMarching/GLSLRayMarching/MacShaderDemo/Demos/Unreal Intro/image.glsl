// Created by Edd Biddulph
// License for this shader: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This is a recreation of the castle fly-by sequence from the original Unreal, released in 1998 and
// developed by Epic MegaGames. http://epicgames.com/
//
// This was mostly inspired by P_Malin's amazing Doom shader - https://www.shadertoy.com/view/lsSXzD
//
// I made a custom tool to convert the geometry from the original files from the game, but the textures
// were made 'by hand'. Unreal's levels are composed of convex shapes called 'brushes'. The brushes
// are combined using CSG operations to produce the level geometry. My tool detects cuboid-shaped brushes
// from which a distance field is simple to create. Most of the non-cuboid-shaped brushes can be created
// by cutting a cuboid with less than 4 oriented planes so my tool first generates a cuboid and adds
// those planes into the distance field code.


#define time (iTime-6.0)
float flagTime=0.0;

float hash(float n)
{
    return fract(sin(n)*43758.5453);
}

float smoothNoise2(vec2 p)
{
    p=fract(p/256.0);
    return textureLod(iChannel0, p, 0.0).r;
}

// Distorted texture coordinates for the rippling flag.
vec2 flagTC(vec2 p)
{
    float tm=-flagTime*1.4;
    return vec2(p.x+p.x*(cos(p.x*7.0+tm*6.0))*0.02+cos(p.y*6.0+tm*7.5)*0.01*p.x,p.y+p.x*cos(p.x*4.0+tm*5.0)*0.01);
}

vec3 flagTexture2(vec2 p)
{
    p.x+=0.05;
    p.y+=0.05;
    float d=1e2;
    d=min(d,length(p-vec2(-0.85,-0.13+p.x*-0.4))-0.5);
    d=min(d,length(p-vec2(-0.8,-1.2))-0.9);
    d=min(d,length(max(vec2(0.0),abs(p-vec2(0.4,-0.63))-vec2(0.5,0.3))));
    d=min(d,length(max(vec2(0.0),abs(p-vec2(0.9,0.0))-vec2(0.3,0.8))));
    d=min(d,length(max(vec2(0.0),abs(p-vec2(-0.9,0.0))-vec2(0.3,0.8))));
    vec2 p2=p+vec2(0.0,-0.07);
    d=min(d,length((p2-vec2(0.1,0.2))*vec2(1.0,0.9))+0.1-p2.y*1.3);
    d=max(d,-length(p-vec2(0.1,0.5))+0.15);
    vec2 p3=p+vec2(0.0,0.1);
    d=min(d,max(p.x, max(-(length((p3-vec2(0.1,0.2))*vec2(1.0,0.9))+0.1-p3.y*1.1), dot(p-vec2(0.0,0.12),normalize(vec2(-0.75,-1.0))))));
    return mix(vec3(0.2,0.1,0.1),vec3(1.0,0.2,0.1)*0.9,(0.3+(1.0-smoothstep(0.0,0.02,d))))*
        mix(0.7,1.0,smoothNoise2(p*40.0)*0.25+smoothNoise2(p*20.0)*0.25);
}

vec4 flagTexture(vec2 p2)
{
    vec2 p=p2.xy*0.7+vec2(0.5);
    vec2 c=flagTC(p);
    vec2 e=vec2(1e-2,0.0);
    float g=max(length((flagTC(p+e.xy)-c)/e.x),length((flagTC(p+e.yx)-c)/e.x));

    float b=step(abs(c.y-0.5),0.3)*step(c.x,0.8);
    float nb=-1.0+abs(c.y-0.5)*3.3;
    return vec4(flagTexture2((c*2.0-vec2(1.0))*vec2(-1.0,1.0))*(1.0-smoothstep(0.0,2.0,g)),
                step(abs(c.y-0.5)*2.0,0.7)*step(abs(c.x-0.5)*2.0,1.0)*smoothstep(nb+0.199,nb+0.2,smoothNoise2(c*vec2(32.0,0.5))));
}


// Brick pattern for tex_wmbrrw.
float brickt3(vec2 p2)
{
    vec2 fp2=fract(p2);
    float brick=length(max(vec2(0.0),abs(fp2-vec2(0.5))-vec2(0.4,0.36)));
    return 1.0-smoothstep(0.01,0.2,brick)-smoothNoise2(p2*vec2(7.0,4.0)*3.0)*0.2;
}

// Brick pattern for tex_nfloor6.
float brickt2(vec2 p2)
{
    vec2 fp2=fract(p2);
    float brick=length(max(vec2(0.0),abs(fp2-vec2(0.5))-vec2(0.465,0.465)));
    return 1.0-smoothstep(0.0,0.04,brick)+smoothNoise2(p2*vec2(4.0,4.0)*3.0)*0.0;
}

// Brick pattern for tex_wmcs.
float brickt(vec2 p2)
{
    vec2 fp2=fract(p2);
    float brick=length(max(vec2(0.0),abs(fp2-vec2(0.5))-vec2(0.44,0.32))*vec2(11.0/4.0,1.0));
    return 1.0-smoothstep(0.0,0.18,brick)+smoothNoise2(p2*vec2(8.0,4.0)*3.0)*0.4;
}

// Roof texture.
vec3 tex_Roof(vec2 p)
{
    vec2 tc0=floor(p*vec2(6.0,3.0));
    p.y+=0.5/3.0;
    vec2 tc=floor(p*vec2(6.0,3.0));
    vec2 tt=fract(p*vec2(6.0,3.0));

    tt.x+=smoothNoise2(p*10.0)*0.05+smoothNoise2(p*30.0)*0.02;

    float spike=smoothstep(0.8,1.0,smoothNoise2(vec2(p.x*100.0,tc.y*7.0+tc.x*1.0)))*0.4;
    float j=smoothNoise2(vec2(p.x*8.0,tc.y*3.0+tc.x*8.0))*0.1;
    float sh=1.0-(smoothstep(-spike,0.05,tt.y-0.5+j)-sqrt(smoothstep(0.05,0.7,tt.y-0.5+j)));
    sh*=smoothstep(0.0,0.1,tt.x)-smoothstep(0.9,1.0,tt.x+cos(tc0.x*9.0+tc0.y*2.0)*0.1);   

    vec3 col=mix(vec3(1.4,0.9,0.5)*0.5,vec3(1.0,0.7,0.5),smoothNoise2(p*vec2(128.0,8.0)))*mix(0.1,1.0,sh)*0.5;
    col*=vec3(1.0)+3.0*vec3(0.5,0.5,0.7)*pow(smoothNoise2(p+tc0),4.0);
    col*=sqrt(smoothNoise2(p*8.0-tc0*4.0)*0.5+smoothNoise2(p*64.0-tc0*1.0)*0.2);

    return col;
}

vec3 tex_wrck(vec2 p)
{
    p+=smoothNoise2(p)*0.2;
    vec3 col=mix(vec3(0.1,0.22,0.1)*0.3,vec3(0.3,0.4,0.25),smoothNoise2(p*2.0)*0.5+smoothNoise2(p*8.0)*0.25+smoothNoise2(p*32.0)*0.125);
    col=mix(vec3(0.4,0.3,0.1)*0.4,col*0.8,sqrt(smoothNoise2(p*64.0)*0.5+smoothNoise2(p*13.0)*0.125));
    vec2 p2=p+smoothNoise2(p*4.0)*0.3;
    col+=3.0*vec3(0.2,0.3,0.3)*pow(smoothNoise2(p2*4.0)*0.5,4.0);

    float ly=fract(p.y*12.0)-0.5+smoothNoise2(vec2(p.x*14.0,floor(p.y)))*0.2+smoothNoise2(vec2(p.x*5.0,floor(p.y*12.0)))*0.68;
    float lines=1.0-(smoothstep(0.0,0.1,ly)-smoothstep(0.1,0.8,ly))*0.3;

    col=mix(col,col*lines*(1.0+(smoothstep(-0.05,0.0,ly)-smoothstep(0.0,0.05,ly))*0.5),smoothstep(0.0,0.5,smoothNoise2(p*4.0)));
    col*=mix(0.7,1.0,smoothNoise2(p*16.0));
    col=mix(col,vec3(dot(col,vec3(1.0/3.0))),0.75);

    return col*0.8;
}

vec3 tex_wmbrrw(vec2 p)
{
    float s=mix(0.5,1.2,sqrt(smoothNoise2(p*3.0))+smoothNoise2(p*80.0));
    vec3 col=mix(mix(vec3(0.1),vec3(0.7,0.25,0.05),0.4)*0.4,
                 mix(vec3(0.1),vec3(0.3,0.2,0.09),0.4)*0.7*s,
                 sqrt(max(0.0,smoothNoise2(p*8.0)+0.15*smoothNoise2(p*32.0))))*0.7;
    vec2 p2=p*vec2(5.0,12.0)+vec2(smoothNoise2(p*24.0),smoothNoise2(p*24.0+vec2(2.0)))*0.05;
    p2.x+=floor(p2.y)*0.5;

    float bh=pow(0.5+0.5*cos(floor(p2.y)*14.0)*cos(floor(p2.x)*1.0),2.0)*0.5;

    float brick=brickt3(p2);
    vec3 bn=normalize(vec3(brickt3(p2+vec2(1e-3,0.0))-brick,brickt3(p2+vec2(0.0,1e-3))-brick,0.04));

    col*=mix(vec3(2.0),vec3(0.3+bh*1.0),brick);

    col.rgb*=vec3(0.5)+vec3(0.5)*dot(bn,normalize(vec3(1.0,-1.0,1.0)));

    vec2 shadp=fract(p*2.0-vec2(0.12,0.04));
    float shadow=mix(0.2,1.0,1.0-smoothstep(0.05,0.3,length(max(vec2(0.0),abs(shadp-vec2(0.5))-vec2(0.2,0.21)))));
    col*=shadow;
    vec2 beamp=fract(p*2.0);
    float hbeammask=1.0-smoothstep(0.07,0.08,abs(beamp.y-0.1));
    float vbeammask=1.0-smoothstep(0.07,0.08,abs(beamp.x-0.1));

    col*=1.0-2.0*vec3(0.4,0.4,0.5)*smoothstep(0.5,1.0,pow(max(0.0,smoothNoise2((p.yx*20.0)*vec2(1.0,1.0))),2.0));

    col=mix(col,0.3*mix(vec3(1.0,0.6,0.4)*0.5,vec3(1.0,0.7,0.4)*0.3,
                        smoothNoise2(beamp*vec2(5.0,128.0))+smoothNoise2(beamp*vec2(4.0,256.0)*2.0)*0.75
                       ),hbeammask);

    col*=smoothstep(0.05,0.16,abs(beamp.x-0.1))*smoothstep(0.05,0.16,abs(beamp.x-1.1));

    col=mix(col,0.3*mix(vec3(1.0,0.6,0.4)*0.5,vec3(1.0,0.7,0.4)*0.3,
                        smoothNoise2(beamp*vec2(128.0,5.0))+smoothNoise2(beamp*vec2(256.0,4.0)*2.0)*0.75
                       ),vbeammask);

    vec2 nn=vec2(smoothNoise2(p*1.0),smoothNoise2(p*10.0+vec2(23.0)))*2.0;
    col*=1.0+vec3(0.4,0.4,0.5)*smoothstep(0.5,1.0,smoothNoise2((p.yx*20.0+nn)*vec2(1.0,2.0))+
                                          smoothNoise2(p*8.0)*0.2)+smoothNoise2(p.yx*128.0)*0.3;


    col*=1.0+vec3(0.4)*smoothstep(0.5,1.0,smoothNoise2(p.yx*2.0+nn)+smoothNoise2(p*7.0)*0.2)+smoothNoise2(p.yx*128.0)*0.3;

    return col*1.75;
}

vec3 tex_nfloor6(vec2 p)
{
    p.x+=floor(hash(floor(p.y*2.0))*10.0);
    p.y+=floor(hash(floor(p.x*2.0))*10.0);
    float s=mix(0.5,1.2,sqrt(smoothNoise2(p*3.0))+smoothNoise2(p*80.0));
    vec3 col=mix(mix(vec3(0.1),vec3(0.18,0.25,0.05),0.4)*0.4,
                 mix(vec3(0.1),vec3(0.2,0.175,0.09),0.4)*0.7*s,
                 sqrt(max(0.0,smoothNoise2(p*8.0)+0.15*smoothNoise2(p*32.0))))*0.7;
    vec2 p2=p*vec2(2.0,2.0)+vec2(smoothNoise2(p*24.0),smoothNoise2(p*24.0+vec2(2.0)))*0.02;

    float bh=pow(0.5+0.5*cos(floor(p2.y)*14.0)*cos(floor(p2.x)*1.0),2.0)*0.5;

    float brick=brickt2(p2);
    vec3 bn=normalize(vec3(brickt2(p2+vec2(1e-3,0.0))-brick,brickt2(p2+vec2(0.0,1e-3))-brick,0.04));

    col*=mix(1.1,1.1+bh*1.0,brick);
    vec2 nn=vec2(smoothNoise2(p*4.0),smoothNoise2(p*10.0+vec2(23.0)))*4.0;
    col*=1.0+2.0*vec3(0.25,0.33,0.5)*smoothstep(0.5,1.0,smoothNoise2(p.yx*20.0+nn)+smoothNoise2(p*7.0)*0.2)+smoothNoise2(p.yx*128.0)*0.3;

    col*=1.0+1.0*vec3(0.4)*smoothstep(0.5,1.0,smoothNoise2(p.yx*2.0+nn)+smoothNoise2(p*7.0)*0.2)+smoothNoise2(p.yx*128.0)*0.3;

    col+=vec3(0.1)*smoothstep(0.4,0.9,smoothNoise2(p.yx*40.0))*smoothstep(0.8,0.9,smoothNoise2(p*50.0));
    col*=1.2;

    col.rgb*=vec3(0.6)+vec3(0.3)*dot(bn,normalize(vec3(1.0,-1.0,1.0)));

    col.rgb*=vec3(1.0)+0.5*vec3(2.0,0.75,0.5)*max(0.0,1.0-abs(brick-0.6)*2.0)*1.0;

    return col;
}

vec3 tex_wmcs(vec2 p)
{
    float s=mix(0.2,1.2,sqrt(smoothNoise2(p*3.0)));
    vec3 col=mix(vec3(0.15,0.2,0.2)*0.4,vec3(0.2,0.15,0.11)*0.7*s,sqrt(max(0.0,smoothNoise2(p*8.0)+0.15*smoothNoise2(p*32.0))))*0.7;
    vec2 p2=p*vec2(4.0,10.0)+vec2(smoothNoise2(p*24.0),smoothNoise2(p*24.0+vec2(2.0)))*0.02;
    p2.x+=floor(p2.y)*0.5;

    float bh=pow(0.5+0.5*cos(floor(p2.y)*14.0)*cos(floor(p2.x)*1.0),2.0);

    float brick=brickt(p2);
    vec3 bn=normalize(vec3(brickt(p2+vec2(1e-3,0.0))-brick,brickt(p2+vec2(0.0,1e-3))-brick,0.04));

    col*=mix(0.9,1.4+bh*1.0,brick);
    col*=1.0+0.4*smoothstep(0.8,0.9,smoothNoise2(p.yx*20.0)+smoothNoise2(p*70.0)*0.2)+smoothNoise2(p.yx*128.0)*0.4;
    col*=1.0+0.5*smoothstep(0.8,0.9,smoothNoise2(p.yx*60.0)+smoothNoise2(p*7.0)*0.15)+smoothNoise2(p.yx*64.0)*0.2;
    col*=1.1;
    col+=vec3(0.2)*smoothstep(0.4,0.9,smoothNoise2(p.yx*20.0))*smoothstep(0.8,0.9,smoothNoise2(p*40.0));

    col.rgb*=0.5+0.5*dot(bn,normalize(vec3(1.0,-1.0,1.0)));

    col.rgb*=1.0+max(0.0,1.0-abs(brick-0.7)*2.0);

    return col;
}

vec2 rotate(float angle, vec2 v)
{
    return vec2(cos(angle) * v.x + sin(angle) * v.y, cos(angle) * v.y - sin(angle) * v.x);
}

// Distance to a (non-rounded) cuboid.
float cuboid(vec3 p,vec3 a,vec3 b)
{
    vec3 d=abs(p-(a+b))-(b-a);
    return max(d.x,max(d.y,d.z));
}

float smallerTower0(vec3 p)
{
    float d=1e5;
    p.xz=abs(p.xz);

    {
        float d2=dot(p.xz,normalize(vec2(1.0)))-(-1285.0 - -1680.0);
        d=min(d,max(d2,p.y-(4257.0-2880.0)));
    }

    {
        float d2=dot(p-(vec3(normalize(vec2(1.0))*(-1285.0- -1680.0),4257.0 - 2880.0).xzy),
                     normalize(vec3(normalize(vec2(1.0))*(4371.0-4257.0),-(-1088.0 - -1285.0)).xzy));
        d=min(d,max(d2,p.y-(4371.0-2880.0)));
    }

    {
        float d2=dot(p-(vec3(normalize(vec2(1.0))*0.0,5404.0 - 2880.0).xzy),
                     normalize(vec3(normalize(vec2(1.0))*-(4371.0 - 5404.0),(-1088.0 - -1680.0)).xzy));
        d=min(d,max(d2,abs(p.y-((4371.0+5404.0)*0.5-2880.0))-(5404.0-4371.0)*0.5));
    }

    return d;
}

float smallerTower(vec3 p)
{
    p-=vec3(-1680, 2880, -448);
    vec3 p2=vec3(dot(normalize(vec2(1.0)),p.xz),p.y,dot(normalize(vec2(1.0,-1.0)),p.xz));

    return max(smallerTower0(p),smallerTower0(p2));
}

float tower0(vec3 p)
{
    float d=1e5;
    p.xz=abs(p.xz);

    {
        float d2=dot(p.xz,normalize(vec2(1.0)))-(2166.0-1536.0);
        d=min(d,max(d2,p.y-(7639.0-5440.0)));
    }

    {
        float d2=dot(p-(vec3(normalize(vec2(1.0))*(2166.0-1536.0),7639.0-5440.0).xzy),
                     normalize(vec3(normalize(vec2(1.0))*(7822.0-7639.0),-(2482.0-2166.0)).xzy));
        d=min(d,max(d2,p.y-(7639.0-5440.0)));
    }

    {
        float d2=dot(p-(vec3(normalize(vec2(1.0))*(2482.0-1536.0),7822.0-5440.0).xzy),
                     normalize(vec3(normalize(vec2(1.0))*(9472.0-7822.0),(2482.0-1536.0)).xzy));
        d=min(d,max(d2,abs(p.y-((7822.0+9472.0)*0.5-5440.0))-(9472.0-7822.0)*0.5));
    }

    return d;
}

float tower(vec3 p)
{
    p-=vec3(1536, 5440, -192);
    vec3 p2=vec3(dot(normalize(vec2(1.0)),p.xz),p.y,dot(normalize(vec2(1.0,-1.0)),p.xz));

    return max(tower0(p),tower0(p2));
}

float mountains(vec3 p)
{
    p=(p-vec3(640.0,28.0,65.0)).xzy;

    p.y+=smoothNoise2(p.xz*20e-4)*500.0;

    return dot(vec2(length(p.xz),p.y+5000.0), normalize(vec2(-1.8,1.0)))*0.75;
}


float sceneMaterial(vec3 p)
{
    p=p.xzy;

    float material2=step(mountains(p),2.0)*2.0;

    // Name=Brush1247
    float material_d=min(cuboid(p,vec3(-16.00,-992.00,688.00),vec3(224.00,-864.00,2208.00)),
                         cuboid(p,vec3(384.00,-992.00,688.00),vec3(624.00,-864.00,2208.00)));

    // Name=Brush72
    material_d=min(material_d,smallerTower(p.xzy));

    return max(material2,max(step(material_d,1.0+step(-1600.0,p.y)),step(7640.0,p.z)));
}

// The distance to the level geometry covering the whole scene. Most of the code in this
// function was generated by my tool.
float scene(vec3 p)
{
    float d=-1e5;
    p=p.xzy;

    d=max(d,2.0-cuboid(p,vec3(-3020.00,-2984.00,64.00),vec3(2996.00,3032.00,5504.00))); // Name=Brush1244
    d=min(d,mountains(p));

    // Name=Brush1247
    d=min(d,cuboid(p,vec3(-432.00,-864.00,800.00),vec3(1232.00,416.00,1880.00))); // Name=Brush852
    d=max(d,2.0-cuboid(p,vec3(-416.00,-848.00,1856.00),vec3(1216.00,400.00,1880.00))); // Name=Brush856
    d=min(d,cuboid(p,vec3(-304.00,-736.00,1856.00),vec3(1104.00,288.00,2208.00))); // Name=Brush858
    d=min(d,cuboid(p,vec3(-16.00,-992.00,688.00),vec3(224.00,-864.00,2208.00))); // Name=Brush854
    d=min(d,cuboid(p,vec3(384.00,-992.00,688.00),vec3(624.00,-864.00,2208.00))); // Name=Brush860
    { float pls=max(dot(p,vec3(0.941742,0.000000,0.336336)) - 2406.554199,dot(p,vec3(-0.941742,0.000000,0.336336)) - 477.866821);
     d=max(d,2.0-max(pls,cuboid(p,vec3(472.00,-992.00,1696.00),vec3(552.00,-864.00,2144.00)))); // Name=Brush82
    }
    { float pls=max(dot(p,vec3(0.941742,0.000000,0.336336)) - 1653.160645,dot(p,vec3(-0.941742,0.000000,0.336336)) - 1231.260254);
     d=max(d,2.0-max(pls,cuboid(p,vec3(72.00,-992.00,1696.00),vec3(152.00,-864.00,2144.00)))); // Name=Brush84
    }
    d=min(d,cuboid(p,vec3(-1128.00,-608.00,1248.00),vec3(-360.00,160.00,1472.00))); // Name=Brush86
    d=min(d,cuboid(p,vec3(-1896.00,-608.00,672.00),vec3(-1128.00,16.00,1152.00))); // Name=Brush88
    d=max(d,2.0-cuboid(p,vec3(-1880.00,-592.00,1120.00),vec3(-1368.00, 0.00,1152.00))); // Name=Brush90
    d=max(d,2.0-cuboid(p,vec3(-1112.00,-592.00,1440.00),vec3(-440.00,144.00,1472.00))); // Name=Brush92
    d=min(d,cuboid(p,vec3(-1752.00,-480.00,1120.00),vec3(-1368.00,-96.00,1376.00))); // Name=Brush94
    d=min(d,cuboid(p,vec3(-1160.00,-640.00,672.00),vec3(-1000.00,-480.00,1568.00))); // Name=Brush113
    d=min(d,cuboid(p,vec3(-1160.00,32.00,672.00),vec3(-1000.00,192.00,1568.00))); // Name=Brush105
    d=min(d,cuboid(p,vec3(-424.00,288.00,672.00),vec3(1256.00,736.00,2208.00))); // Name=Brush106
    d=max(d,2.0-cuboid(p,vec3(-408.00,288.00,1856.00),vec3(-296.00,400.00,2016.00))); // Name=Brush107
    d=max(d,2.0-cuboid(p,vec3(1112.00,288.00,1856.00),vec3(1224.00,400.00,2016.00))); // Name=Brush108
    d=max(d,2.0-cuboid(p,vec3(-232.00,-672.00,1856.00),vec3(1048.00,288.00,2208.00))); // Name=Brush118
    d=min(d,cuboid(p,vec3(-808.00,-416.00,1440.00),vec3(-424.00,-32.00,1880.00))); // Name=Brush109
    { float pls=max(dot(p,vec3(-0.847999,0.000000,-0.529998)) - -2313.337891,max(dot(p,vec3(-0.000001,-0.768222,-0.640184)) - -1302.897705,max(dot(p,vec3(0.847998,-0.000000,-0.529999)) - -1960.569824,dot(p,vec3(-0.000000,0.768221,-0.640184)) - -3859.543457)));
     d=min(d,max(pls,cuboid(p,vec3(-76.00,-1072.00,2208.00),vec3(284.00,-592.00,2400.00)))); // Name=Brush120
    }
    { float pls=max(dot(p,vec3(-0.847999,0.000000,-0.529998)) - -2991.736328,max(dot(p,vec3(-0.000001,-0.768222,-0.640184)) - -1302.898071,max(dot(p,vec3(0.847999,-0.000000,-0.529998)) - -1282.169800,dot(p,vec3(-0.000000,0.768221,-0.640184)) - -3859.543701)));
     d=min(d,max(pls,cuboid(p,vec3(324.00,-1072.00,2208.00),vec3(684.00,-592.00,2400.00)))); // Name=Brush121
    }
    d=min(d,cuboid(p,vec3(224.00,-936.00,1920.00),vec3(384.00,-912.00,1952.00))); // Name=Brush122
    d=min(d,cuboid(p,vec3(408.00,-480.00,1856.00),vec3(1112.00,736.00,2720.00))); // Name=Brush123
    d=max(d,2.0-cuboid(p,vec3(-64.00,-1056.00,2360.00),vec3(272.00,-608.00,2400.00))); // Name=Brush124
    d=max(d,2.0-cuboid(p,vec3(336.00,-1056.00,2360.00),vec3(672.00,-608.00,2400.00))); // Name=Brush125
    d=min(d,cuboid(p,vec3(472.00,-592.00,2304.00),vec3(600.00,-480.00,2400.00))); // Name=Brush126
    d=max(d,2.0-cuboid(p,vec3(488.00,-608.00,2360.00),vec3(584.00,-480.00,2400.00))); // Name=Brush127
    d=min(d,cuboid(p,vec3(284.00,-864.00,2304.00),vec3(324.00,-736.00,2400.00))); // Name=Brush128
    d=max(d,2.0-cuboid(p,vec3(272.00,-848.00,2360.00),vec3(336.00,-752.00,2400.00))); // Name=Brush129
    d=max(d,2.0-cuboid(p,vec3(72.00,-1072.00,2360.00),vec3(136.00,-1056.00,2400.00))); // Name=Brush130
    d=max(d,2.0-cuboid(p,vec3(472.00,-1072.00,2360.00),vec3(536.00,-1056.00,2400.00))); // Name=Brush131
    { float pls=max(dot(p,vec3(0.664365,0.000000,0.747409)) - 3130.480957,dot(p,vec3(-0.664365,0.000000,0.747409)) - 2322.613525);
     d=max(d,2.0-max(pls,cuboid(p,vec3(232.00,-944.00,1568.00),vec3(376.00,-720.00,1824.00)))); // Name=Brush132
    }
    d=max(d,2.0-cuboid(p,vec3(24.00,-720.00,1568.00),vec3(600.00,-544.00,1824.00))); // Name=Brush39
    d=max(d,2.0-cuboid(p,vec3(488.00,-480.00,2360.00),vec3(584.00,-464.00,2504.00))); // Name=Brush40
    d=max(d,2.0-cuboid(p,vec3(424.00,-464.00,2360.00),vec3(984.00,-192.00,2688.00))); // Name=Brush41
    d=max(d,2.0-cuboid(p,vec3(424.00,288.00,2208.00),vec3(760.00,720.00,2688.00))); // Name=Brush46
    d=max(d,2.0-cuboid(p,vec3(408.00,552.00,2208.00),vec3(424.00,680.00,2336.00))); // Name=Brush93
    d=max(d,2.0-cuboid(p,vec3(-408.00,304.00,2192.00),vec3(408.00,720.00,2208.00))); // Name=Brush49
    d=max(d,2.0-cuboid(p,vec3(280.00,288.00,2192.00),vec3(408.00,304.00,2208.00))); // Name=Brush50
    { float pls=dot(p,vec3(0.000000,0.316228,0.948683)) - 4690.290527;
     d=min(d,max(pls,cuboid(p,vec3(616.00,288.00,2272.00),vec3(632.00,600.00,2376.00)))); // Name=Brush53
    }
    { float pls=dot(p,vec3(-0.406138,0.000000,0.913812)) - 3651.997070;
     d=min(d,max(pls,cuboid(p,vec3(472.00,600.00,2208.00),vec3(616.00,720.00,2272.00)))); // Name=Brush54
    }
    d=min(d,cuboid(p,vec3(616.00,480.00,2208.00),vec3(760.00,720.00,2272.00))); // Name=Brush55
    d=min(d,cuboid(p,vec3(616.00,352.00,2208.00),vec3(760.00,416.00,2272.00))); // Name=Brush56

    // Name=Brush58
    d=min(d,tower(p.xzy));

    { float pls=dot(p,vec3(0.000000,0.307820,0.951445)) - 4668.122559;
     d=min(d,max(pls,cuboid(p,vec3(616.00,288.00,2272.00),vec3(760.00,560.00,2360.00)))); // Name=Brush65
    }
    d=min(d,cuboid(p,vec3(-496.00,-2136.00,672.00),vec3(592.00,-1688.00,1584.00))); // Name=Brush66
    d=max(d,2.0-cuboid(p,vec3(80.00,-1704.00,1448.00),vec3(144.00,-1688.00,1512.00))); // Name=Brush69
    d=max(d,2.0-cuboid(p,vec3(-176.00,-1704.00,1448.00),vec3(-112.00,-1688.00,1512.00))); // Name=Brush70
    d=max(d,2.0-cuboid(p,vec3(-432.00,-1704.00,1448.00),vec3(-368.00,-1688.00,1512.00))); // Name=Brush71

    // Name=Brush72
    d=min(d,smallerTower(p.xzy));

    { float pls=max(dot(p,vec3(-0.707107,0.000000,-0.707106)) - 531.747742,max(dot(p,vec3(-0.000001,-0.707107,-0.707106)) - -1267.131348,max(dot(p,vec3(0.707107,-0.000000,-0.707106)) - -3880.601807,dot(p,vec3(-0.000000,0.707107,-0.707107)) - -2081.721680)));
     d=min(d,max(pls,cuboid(p,vec3(-1848.00,-576.00,1376.00),vec3(-1272.00, 0.00,1568.00)))); // Name=Brush73
    }
    d=max(d,2.0-cuboid(p,vec3(-1831.53,-559.53,1536.00),vec3(-1288.47,-16.47,1568.00))); // Name=Brush866
    d=min(d,cuboid(p,vec3(-1368.00,-352.00,1120.00),vec3(-1112.00,-96.00,1568.00))); // Name=Brush864
    { float pls=dot(p,vec3(-0.316228,0.000000,-0.948683)) - -2028.916870;
     d=max(d,2.0-max(pls,cuboid(p,vec3(-1368.00,-328.00,1440.00),vec3(-1112.00,-120.00,1568.00)))); // Name=Brush76
    }
    d=min(d,cuboid(p,vec3(152.00,-560.00,1568.00),vec3(176.00,-544.00,1824.00))); // Name=Brush95
    d=min(d,cuboid(p,vec3(448.00,-560.00,1568.00),vec3(472.00,-544.00,1824.00))); // Name=Brush97
    d=min(d,cuboid(p,vec3(176.00,-544.00,1568.00),vec3(448.00,-536.00,1824.00))); // Name=Brush99
    d=min(d,cuboid(p,vec3(232.00,-804.00,1706.00),vec3(376.00,-796.00,1718.00))); // Name=Brush155
    { float pls=max(dot(p,vec3(0.000000,-0.470588,0.882353)) - 3512.470703,dot(p,vec3(0.000000,0.454709,-0.890640)) - -3531.819092);
     d=min(d,max(pls,cuboid(p,vec3(-232.00,48.00,2016.00),vec3(264.00,288.00,2144.00)))); // Name=Brush159
    }
    d=max(d,2.0-cuboid(p,vec3(-616.00,-400.00,1856.00),vec3(-408.00,-48.00,1880.00))); // Name=Brush167
    d=min(d,cuboid(p,vec3(-664.00,-288.00,1856.00),vec3(-520.00,-160.00,2048.00))); // Name=Brush168
    d=max(d,2.0-cuboid(p,vec3(-664.00,-256.00,1856.00),vec3(-520.00,-192.00,2016.00))); // Name=Brush169
    { float pls=max(dot(p,vec3(0.229039,0.000000,-0.973417)) - -3312.824951,dot(p,vec3(-0.229039,0.000000,0.973417)) - 3530.870605);
     d=max(d,2.0-max(pls,cuboid(p,vec3(-1384.00,-328.00,1376.00),vec3(-1112.00,-240.00,1552.00)))); // Name=Brush265
    }
    d=max(d,2.0-cuboid(p,vec3(-408.00,304.00,1856.00),vec3(1240.00,416.00,2016.00))); // Name=Brush323
    d=min(d,cuboid(p,vec3(-1384.00,-352.00,1505.50),vec3(-1309.00,-240.00,1568.00))); // Name=Brush353
    { float pls=dot(p,vec3(-0.311770,0.000000,-0.950157)) - -2045.926514;
     d=max(d,2.0-max(pls,cuboid(p,vec3(-1400.00,-240.00,1525.50),vec3(-1368.00,-120.00,1536.00)))); // Name=Brush355
    }
    d=max(d,2.0-cuboid(p,vec3(88.00,-608.00,2360.00),vec3(152.00,-592.00,2400.00))); // Name=Brush360
    d=max(d,2.0-cuboid(p,vec3(384.00,-896.00,1568.00),vec3(392.00,-864.00,1584.00))); // Name=Brush523
    d=max(d,2.0-cuboid(p,vec3(232.00,-896.00,1568.00),vec3(240.00,-864.00,1584.00))); // Name=Brush524
    // Name=Brush784
    // Name=Brush785
    d=min(d,cuboid(p,vec3(224.00,-1824.00,688.00),vec3(384.00,-864.00,1584.00))); // Name=Brush851
    { float pls=max(dot(p,vec3(0.000000,0.576682,0.816969)) - 741.234497,dot(p,vec3(0.000000,-0.576682,0.816969)) - 3859.928955);
     d=max(d,2.0-max(pls,cuboid(p,vec3(224.00,-1488.00,736.00),vec3(384.00,-1216.00,1408.00)))); // Name=Brush853
    }
    d=min(d,cuboid(p,vec3(216.00,-1488.00,688.00),vec3(392.00,-1442.00,1312.00))); // Name=Brush855
    { float pls=max(dot(p,vec3(0.000000,0.536233,-0.844070)) - -3762.050537,dot(p,vec3(0.000000,-0.576683,0.816968)) - 3859.932861);
     d=min(d,max(pls,cuboid(p,vec3(216.00,-1488.00,1312.00),vec3(392.00,-1352.00,1408.00)))); // Name=Brush857
    }
    { float pls=max(dot(p,vec3(0.000000,-0.536233,-0.844070)) - -862.103333,dot(p,vec3(0.000000,0.576683,0.816968)) - 741.230042);
     d=min(d,max(pls,cuboid(p,vec3(216.00,-1352.00,1312.00),vec3(392.00,-1216.00,1408.00)))); // Name=Brush859
    }
    d=min(d,cuboid(p,vec3(216.00,-1262.00,688.00),vec3(392.00,-1216.00,1312.00))); // Name=Brush861
    d=max(d,2.0-cuboid(p,vec3(232.00,-1824.00,1568.00),vec3(376.00,-864.00,1584.00))); // Name=Brush865
    d=max(d,2.0-cuboid(p,vec3(-480.00,-2112.00,1568.00),vec3(576.00,-1704.00,1584.00))); // Name=Brush867
    d=min(d,cuboid(p,vec3(376.00,-1728.00,1376.00),vec3(456.00,-1648.00,1632.00))); // Name=Brush67
    d=min(d,cuboid(p,vec3(152.00,-1728.00,1376.00),vec3(232.00,-1648.00,1632.00))); // Name=Brush68
    d=min(d,cuboid(p,vec3(224.00,-1448.00,872.00),vec3(384.00,-1256.00,928.00))); // Name=Brush1140
    { float pls=max(dot(p,vec3(-0.832049,0.000000,0.554702)) - 2658.138916,dot(p,vec3(0.832049,0.000000,0.554702)) - 5187.567871);
     d=max(d,2.0-max(pls,cuboid(p,vec3(728.00,-416.00,3392.00),vec3(792.00,-384.00,3536.00)))); // Name=Brush1229
    }
    { float pls=dot(p,vec3(-0.707107,0.000000,-0.707107)) - -1448.154785;
     d=min(d,max(pls,cuboid(p,vec3(-544.00,-592.00,1440.00),vec3(-416.00,-400.00,1696.00)))); // Name=Brush57
    }
    d=max(d,2.0-cuboid(p,vec3(-544.00,-544.00,1440.00),vec3(-400.00,-416.00,1552.00))); // Name=Brush60
    { float pls=dot(p,vec3(0.000000,-0.780869,-0.624695)) - -1214.406372;
     d=min(d,max(pls,cuboid(p,vec3(-432.00,-464.00,1492.00),vec3(-352.00,-416.00,1552.00)))); // Name=Brush63
    }
    { float pls=dot(p,vec3(0.000000,0.780869,-0.624695)) - -2713.674805;
     d=min(d,max(pls,cuboid(p,vec3(-432.00,-544.00,1492.00),vec3(-352.00,-496.00,1552.00)))); // Name=Brush74
    }
    { float pls=max(dot(p,vec3(-0.975610,-0.000000,0.219512)) - 282.536896,max(dot(p,vec3(0.871576,0.000000,0.490261)) - 2339.308105,max(dot(p,vec3(-0.800001,-0.000000,0.599999)) - 1638.397461,dot(p,vec3(-0.284087,0.000000,0.958798)) - 3174.972900)));
     d=max(d,2.0-max(pls,cuboid(p,vec3(208.00,-2848.00,1568.00),vec3(400.00,-2112.00,1760.00)))); // Name=Brush465
    }
    // Name=Brush869
    // Name=Brush862
    d=min(d,cuboid(p,vec3(-844.00,-228.00,2664.00),vec3(-836.00,-220.00,2920.00))); // Name=Brush100
    d=min(d,cuboid(p,vec3(1220.00,-860.00,1856.00),vec3(1228.00,-852.00,2112.00))); // Name=Brush10
    // Name=Brush1175
    // Name=Brush111
    // Name=Brush114
    // Name=Brush115
    // Name=Brush116
    // Name=Brush117
    // Name=Brush119
    d=min(d,cuboid(p,vec3(408.00,-480.00,2720.00),vec3(424.00,736.00,2752.00))); // Name=Brush110
    d=min(d,cuboid(p,vec3(1096.00,-480.00,2720.00),vec3(1112.00,736.00,2752.00))); // Name=Brush112
    d=min(d,cuboid(p,vec3(424.00,720.00,2720.00),vec3(1096.00,736.00,2752.00))); // Name=Brush42
    d=min(d,cuboid(p,vec3(424.00,-480.00,2720.00),vec3(1096.00,-464.00,2752.00))); // Name=Brush43
    // Name=Brush101
    { float pls=dot(p,vec3(0.000000,-0.430730,0.902481)) - 3708.376465;
     d=min(d,max(pls,cuboid(p,vec3(280.00,-416.00,1856.00),vec3(408.00,288.00,2192.00)))); // Name=Brush51
    }
    { float pls=dot(p,vec3(0.000000,-0.431455,0.902134)) - 3735.306152;
     d=min(d,max(pls,cuboid(p,vec3(264.00,-448.00,1856.00),vec3(280.00,288.00,2208.00)))); // Name=Brush52
    }
    // Name=Brush1
    d=min(d,cuboid(p,vec3(188.00,-1692.00,1408.00),vec3(196.00,-1684.00,1664.00))); // Name=Brush9
    d=min(d,cuboid(p,vec3(412.00,-1692.00,1408.00),vec3(420.00,-1684.00,1664.00))); // Name=Brush44
    d=max(d,2.0-cuboid(p,vec3(1096.00,520.00,2736.00),vec3(1112.00,648.00,2752.00))); // Name=Brush91
    { float pls=max(dot(p,vec3(-0.195090,0.980785,0.000000)) - 668.334656,max(dot(p,vec3(0.195090,-0.980785,0.000000)) - -604.334656,max(dot(p,vec3(0.980785,0.195091,-0.000000)) - 2393.832764,dot(p,vec3(-0.980785,-0.195091,0.000000)) - -2361.832764)));
     d=min(d,max(pls,cuboid(p,vec3(1093.03,526.75,2736.00),vec3(1114.97,561.25,2752.00)))); // Name=Brush61
    }
    d=min(d,cuboid(p,vec3(1069.26,618.11,2719.03),vec3(1106.74,645.89,2752.97))); // Name=Brush64
    { float pls=max(dot(p,vec3(-0.471398,0.881921,0.000000)) - 73.059395,max(dot(p,vec3(0.471398,-0.881921,0.000000)) - -9.059571,max(dot(p,vec3(0.881922,0.471395,-0.000000)) - 2450.862061,dot(p,vec3(-0.881922,-0.471395,0.000000)) - -2418.862305)));
     d=min(d,max(pls,cuboid(p,vec3(1049.40,574.12,2720.00),vec3(1078.60,609.88,2736.00)))); // Name=Brush75
    }
    // Name=Brush78
    // Name=Brush80
    d=max(d,2.0-cuboid(p,vec3(800.00,720.00,2736.00),vec3(928.00,736.00,2752.00))); // Name=Brush83
    { float pls=max(dot(p,vec3(-0.773011,0.634392,0.000000)) - -355.351471,max(dot(p,vec3(0.773011,-0.634392,0.000000)) - 419.351379,max(dot(p,vec3(0.634392,0.773011,-0.000000)) - 2217.433838,dot(p,vec3(-0.634392,-0.773011,0.000000)) - -2185.433838)));
     d=min(d,max(pls,cuboid(p,vec3(830.56,711.67,2736.00),vec3(865.44,744.33,2752.00)))); // Name=Brush85
    }
    { float pls=max(dot(p,vec3(-0.923879,-0.382685,0.000000)) - -2156.288574,max(dot(p,vec3(0.923879,0.382685,-0.000000)) - 2220.288574,max(dot(p,vec3(-0.382683,0.923880,0.000000)) - 616.273071,dot(p,vec3(0.382683,-0.923880,0.000000)) - -584.272949)));
     d=min(d,max(pls,cuboid(p,vec3(878.16,682.49,2720.00),vec3(913.84,709.51,2736.00)))); // Name=Brush87
    }
    { float pls=max(dot(p,vec3(-0.509803,0.000000,0.860291)) - 2943.598877,max(dot(p,vec3(0.947492,0.000000,0.319779)) - -100.432518,max(dot(p,vec3(-0.975610,0.000000,-0.219512)) - 888.975403,dot(p,vec3(-0.970143,0.000000,0.242536)) - 1967.017944)));
     d=max(d,2.0-max(pls,cuboid(p,vec3(-720.00,1632.00,1104.00),vec3(-464.00,1888.00,1360.00)))); // Name=Brush259
    }
    d=min(d,cuboid(p,vec3(-720.00,1696.00,1104.00),vec3(-568.00,1888.00,1164.00))); // Name=Brush402
    d=min(d,cuboid(p,vec3(-720.00,1696.00,1164.00),vec3(-568.00,1712.00,1180.00))); // Name=Brush467
    d=min(d,cuboid(p,vec3(-584.00,1816.00,1164.00),vec3(-568.00,1888.00,1180.00))); // Name=Brush469
    d=min(d,cuboid(p,vec3(-720.00,1712.00,1164.00),vec3(-704.00,1888.00,1180.00))); // Name=Brush470
    { float pls=dot(p,vec3(-0.355995,0.000000,0.934488)) - 3215.349365;
     d=min(d,max(pls,cuboid(p,vec3(-736.00, 4.00,1440.00),vec3(-568.00,108.00,1504.00)))); // Name=Brush48
    }
    d=max(d,2.0-cuboid(p,vec3(-702.67,1888.00,1164.00),vec3(-576.00,2176.00,1284.00))); // Name=Brush2
    // Name=Brush133

    d=min(d,p.z-1400.0);

    return d;
}

// The camera position and Euler angles for a given point in time. The original spline
// control points are accessible in the original level data, but it was too costly to store
// them in the shader so I manually created an approximate path with some custom additions.
void cameraPoint(float t, inout vec3 pos, inout vec3 rot)
{
    t=mod(t,29.0);

    pos.y=3300.0;
    pos.y+=(1.0-smoothstep(0.0,1.0,(abs(t-8.0)-2.0)*0.25)) * 2500.0;
    pos.y-=(1.0-smoothstep(0.0,1.0,(abs(t-15.0)-0.8)*0.5)) * 1200.0;
    pos.y+=(1.0-smoothstep(0.0,1.0,(abs(t-3.5)-0.0))) * 1000.0;
    pos.y+=(1.0-smoothstep(0.0,1.0,(abs(t-18.0))*0.25)) * 600.0;

    pos.x=600.0;
    pos.x-=(1.0-smoothstep(0.0,1.0,(abs(t-7.0)-0.7)*0.35)) * 3000.0;
    pos.x+=(1.0-smoothstep(0.0,1.0,(abs(t-12.0)-2.0)*0.4)) * 3500.0;
    pos.x-=(1.0-smoothstep(0.0,1.0,(abs(t-19.0)-0.0)*0.1)) * 2500.0;

    pos.z=-4200.0;
    pos.z+=(1.0-smoothstep(0.0,1.0,(abs(t-8.1))*0.122)) * 6000.0;
    pos.z+=(1.0-smoothstep(0.0,1.0,(abs(t-15.0)-1.0)*0.5)) * 1000.0;
    pos.z+=(1.0-smoothstep(0.0,1.0,(abs(t-19.0)-0.5)*0.2)) * 600.0;

    rot.x=0.0;
    rot.x+=(1.0-smoothstep(0.0,1.0,abs(t-5.0)*0.5-0.0))*0.5;
    rot.x-=(1.0-smoothstep(0.0,1.0,abs(t-10.0)*0.25-0.0))*0.15;
    rot.x-=(1.0-smoothstep(0.0,1.0,abs(t-3.5)*0.75-0.0))*0.4;
    rot.x-=(1.0-smoothstep(0.0,1.0,abs(t-2.0)*0.3-0.0))*0.1;
    rot.x-=(1.0-smoothstep(0.0,1.0,(abs(t-20.0)-1.0)*0.25))*0.1;
    rot.x+=(1.0-smoothstep(0.0,1.0,(abs(t-9.0)-1.0)))*0.1;
    rot.x+=(1.0-smoothstep(0.0,1.0,(abs(t-12.0)-1.0)))*0.3;
    rot.x-=(1.0-smoothstep(0.0,1.0,(abs(t-8.0))))*0.15;

    rot.y=1.0;
    rot.y+=(1.0-smoothstep(0.0,1.0,abs(t-5.0)*0.5-0.0))*0.5;
    rot.y+=(1.0-smoothstep(0.0,1.0,abs(t-8.0)*0.5-1.0))*1.3;
    rot.y+=(1.0-smoothstep(0.0,1.0,abs(t-13.0)*0.5-1.0))*0.4;
    rot.y-=(1.0-smoothstep(0.0,1.0,abs(t-21.0)*0.5-1.5))*0.15;
    rot.y-=(1.0-smoothstep(0.0,1.0,abs(t-10.0)*0.75))*0.9;
    rot.y+=(1.0-smoothstep(0.0,1.0,(abs(t-14.0)*0.8)))*0.3;

    rot.z-=(1.0-smoothstep(0.0,1.0,abs(t-20.0)*0.25-0.2))*0.1;
    rot.z+=(1.0-smoothstep(0.0,1.0,abs(t-12.0)*0.3-0.0))*0.1;

    rot.xz*=smoothstep(0.0,2.0,t)*(1.0-smoothstep(24.0,26.0,t));
}


float flareMask(vec2 p,vec2 o,vec2 d,float l,float r,float g)
{
    p-=o;
    float u=dot(p,d);
    float v=length(p-u*d);

    return (1.0-(max(0.0,u)/l))*max(0.0,(smoothstep(-r,0.0,u)-smoothstep(l-r,l,u)-smoothstep(0.0,max(r,r+u*g),v)));
}

float fireFbm(vec2 p)
{
    float f=0.0;
    for(int i=0;i<3;i+=1)
        f+=smoothNoise2(p*pow(2.0,float(i)))/pow(2.0,float(i+1));
    return f;
}

vec3 fire(vec2 p, float tm)
{
    float a=0.0;

    vec2 p2=p+vec2(cos(p.y*8.0-tm*3.0)*0.05*clamp(p.y,0.0,1.0),0.0);
    float fn=fireFbm(p2*5.0+vec2(0.0,-tm*4.2));
    float fm=flareMask(p2,vec2(0.0),vec2(0.0,1.0),1.1,0.3,0.0);
    fm*=smoothstep(0.0,0.1,p.y)*(1.0-smoothstep(0.0,max(0.0,0.5-p.y*0.4),abs(p.x)));
    a+=pow(mix(fm*pow(max(0.0,fn),4.0),fm,fm*fm*0.9),0.4)*1.25;

    a*=0.9;

    return mix(vec3(1.4,0.25,0.2)*0.9,vec3(1.5,1.5,0.6),a)*a;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - vec2(1.0);
    uv.x*=iResolution.x/iResolution.y;

    // Set up the primary ray.
    vec3 rd=normalize(vec3(uv.xy,-1.52));
    vec3 ro=vec3(0.0),angs=vec3(0.0);
    cameraPoint(time*0.5,ro,angs);

    rd.yz=rotate(angs.x*3.1415926,rd.yz);
    rd.xy=rotate(angs.z*3.1415926,rd.xy);
    rd.zx=rotate(angs.y*3.1415926,rd.zx);

    // Raymarch through the scene.
    float t=70.0,d=0.0;
    vec3 rp=ro;
    float material=0.0;
    for(int i=0;i<130;i+=1)
    {
        rp=ro+rd*t;
        d=scene(rp);
        if(d<0.1)
            break;
        t+=d;
    }

    // Obtain distance field gradient for material selection.
    float d3=scene(rp+vec3(0.0,0.1,0.0))-d;

    // Obtain a material index for the shading point.
    material = sceneMaterial(rp);

    vec3 rp2=rp;
    rp2.xz=rotate(3.1415926*0.125,rp2.xz);

    vec2 mtc0 = rp.xz*0.004;
    vec2 mtc1 = rp.xz*2e-3;
    vec2 mtc2 = (rp2.xy+vec2(rp2.z,0.0))*1e-3*vec2(2.0,1.0);

    vec3 col=vec3(1.0);
    if(material > 1.5)
    {
        col=tex_wrck(vec2(abs(atan(rp.z,rp.x)/3.1415926-0.0)*8.0,rp.y*4e-4));
    }
    else if(d3>1e-2)
    {
        col=mix(tex_nfloor6(mtc0), tex_Roof(mtc0)*0.7,  material);
    }
    else
    {
        vec2 ttc=mix(mtc2, mtc1, step(d3, -1e-2));
        col=mix(tex_wmcs(ttc), tex_wmbrrw(ttc * 2.0), material);
    }

    // Apply some good old ambient occlusion.
    float ao = 1.0;
    {
        float ao_strength = 0.25, ao_eps = 80.0;
        float w = ao_strength / ao_eps;
        float dist = 2.0 * ao_eps;
        for(int i = 0; i < 2; i++)
        {
            float d = scene(rp + normalize(vec3(-2.0,2.0,-4.0)) * dist);
            ao -= (dist - d) * w;
            w *= 0.5;
            dist = dist * 2.0 - ao_eps;
        }
    }
    ao=clamp(ao, 0.0, 1.0);


    vec3 sun=vec3(0.5,0.5,0.4)*pow(0.5+0.5*dot(rd,normalize(vec3(-2.0,2.0,-4.0))),2.0);
    vec3 absrp=abs(rp-vec3(-40.0,4028.0,65.0));
    if(max(absrp.x,max(absrp.y,absrp.z))>6000.0)
    {
        vec2 cloudtc=rd.xz/rd.y;
        fragColor.rgb=mix(vec3(0.0),vec3(0.3,0.3,0.4),0.5+0.5*rd.y)*0.75;
        fragColor.rgb+=sun;
        fragColor.rgb=mix(fragColor.rgb,vec3(1.0),(smoothNoise2(cloudtc*4.0)*0.25+
                                                         smoothNoise2(cloudtc*2.0)*0.5+smoothNoise2(cloudtc))*max(0.0,rd.y));
    }
    else
    {
    	// Obtain distance field gradient for lighting.
        float d2=scene(rp+normalize(vec3(-1.0,10.0,-1.0)))-d;
        
        // Apply lighting and hardcoded shadows.
        vec3 dl=vec3(0.2,0.2,0.4)*(0.3+max(0.0,0.7+d3*7.0))*4.0*mix(0.4,1.0,ao)*smoothstep(2000.0,9000.0,rp.y+1000.0);
        dl+=vec3(0.5,0.5,0.4)*(0.5+max(0.0,0.3+d2*7.0))*0.9*ao*smoothstep(1000.0,8000.0,rp.y+1000.0);
        dl+=vec3(0.1,0.15,0.1)*max(0.8,(0.5+max(0.1,10.0-d2*8.0)))*0.2*(1.0-smoothstep(1000.0,3500.0,rp.y+1000.0));
        dl*=smoothstep(0.0,1200.0,distance(rp,vec3(604.0,3228.0,-546.0)));
        dl*=max(step(-1345.855957,rp.z),smoothstep(400.0,800.0,distance(rp,vec3(804.0,3928.0,-946.0))));
        dl*=smoothstep(200.0,900.0,distance(rp,vec3(1204.0,4028.0,1146.0)));
        dl*=smoothstep(20.0,900.0,distance(rp,vec3(1905.0,3728.0,1046.0)));
        {
            vec3 lp=rp-vec3(604.0,3228.0,-3366.0);
            lp.x=abs(lp.x);
            float sh=max(smoothstep(-120.0,100.0,lp.y),smoothstep(1.0,10.0,length(max(vec2(0.0),abs(lp.xz-vec2(225.0,0.0))-vec2(100.0)))));
            dl+=(0.9+0.1*cos(time*15.0))*sh*2.0*max(0.0,0.2+d3*17.0)*vec3(1.0,0.65,0.3)*(1.0-smoothstep(0.0,280.0,distance(lp,vec3(225.0,0.0,0.0))));
        }
        dl*=1.0-smoothstep(1000.0,15000.0,distance(rp.xz,vec2(604.080750,1366.0)));
        fragColor.rgb=col*dl*1.7;
    }

    // Render the first flag.
    {
        flagTime=time;
        float ft=(ro.z+454.0)/-rd.z;
        vec3 frp=ro+rd*ft;
        frp.x-=-1505.0;
        frp.y-=5712.0;
        frp.xy=frp.xy*4e-3;
        if(abs(frp.x)<1.0 && abs(frp.y)<0.6)
        {
            vec4 fl=flagTexture(frp.xy);
            fragColor.rgb=mix(fragColor.rgb,fl.rgb,fl.a*step(ft,t)*step(0.0,ft));
        }
    }

	// Render the second flag.
    {
        flagTime=time+10.0;
        float ft=(ro.z+1720.0)/-rd.z;
        vec3 frp=ro+rd*ft;
        frp.x-=2614.0;
        frp.y-=4095.0;
        frp.xy=frp.xy*4e-3;
        if(abs(frp.x)<1.0 && abs(frp.y)<0.6)
        {
            vec4 fl=flagTexture(frp.xy);
            fragColor.rgb=mix(fragColor.rgb,fl.rgb,fl.a*step(ft,t)*step(0.0,ft));
        }
    }

    // Apply some fog.
    fragColor.rgb=mix(vec3(0.15,0.15,0.18)*4.2,fragColor.rgb,exp(-t*5e-6));


    // Render the torch flames and their reflections.
    {
        float ft=(ro.z+3380.0)/-rd.z;
        vec3 frp=ro+rd*ft;
        frp.x=abs(frp.x-600.0);
        frp.y-=3200.0;
        float refl=step(frp.y,0.0);
        frp.y=abs(frp.y);
        frp.xy=(frp.xy-vec2(225.0,120.0))*4e-3;
        if(abs(frp.x)<0.8 && abs(frp.y)<1.0)
        {
            vec3 ff=fire(frp.xy,time)*step(0.0,ft);
            ff*=vec3((1.0-refl)*step(ft,t))+col*refl*step(0.0,rd.z)*1.5;
            fragColor.rgb=mix(fragColor.rgb,vec3(0.0),clamp(dot(ff,vec3(1.0/3.0))*2.0,0.0,1.0));
            fragColor.rgb+=ff;
        }
    }


    fragColor.rgb+=vec3(1.0,0.6,0.3)*(1.0-smoothstep(0.0,0.5,abs(mod(time*0.5,29.0)-1.5)))*0.12;

    fragColor.rgb+=sun*0.28;
    fragColor.rgb*=1.25;
}


