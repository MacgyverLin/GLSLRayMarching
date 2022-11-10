// Created by David Gallardo - xjorma/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

// Pressure solver 2nd interation

// Impired by https://www.shadertoy.com/view/MdSczK by Trirop
// Since in shadertoy we don't have countless passed we need to do many pass at once.


float div(int x,int y)
{
    return texelFetch(iChannel0, ivec2(gl_FragCoord.xy) + ivec2(x,  y) , 0).y;
}

float pre(int x,int y)
{
    return texelFetch(iChannel0, ivec2(gl_FragCoord.xy) + ivec2(x,  y) , 0).x;
}

float getPre( void )
{
    float p = 0.;
    p += 1.*pre(-10, 0);
    p += 10.*pre(-9, -1);
    p += 10.*pre(-9, 1);
    p += 45.*pre(-8, -2);
    p += 100.*pre(-8, 0);
    p += 45.*pre(-8, 2);
    p += 120.*pre(-7, -3);
    p += 450.*pre(-7, -1);
    p += 450.*pre(-7, 1);
    p += 120.*pre(-7, 3);
    p += 210.*pre(-6, -4);
    p += 1200.*pre(-6, -2);
    p += 2025.*pre(-6, 0);
    p += 1200.*pre(-6, 2);
    p += 210.*pre(-6, 4);
    p += 252.*pre(-5, -5);
    p += 2100.*pre(-5, -3);
    p += 5400.*pre(-5, -1);
    p += 5400.*pre(-5, 1);
    p += 2100.*pre(-5, 3);
    p += 252.*pre(-5, 5);
    p += 210.*pre(-4, -6);
    p += 2520.*pre(-4, -4);
    p += 9450.*pre(-4, -2);
    p += 14400.*pre(-4, 0);
    p += 9450.*pre(-4, 2);
    p += 2520.*pre(-4, 4);
    p += 210.*pre(-4, 6);
    p += 120.*pre(-3, -7);
    p += 2100.*pre(-3, -5);
    p += 11340.*pre(-3, -3);
    p += 25200.*pre(-3, -1);
    p += 25200.*pre(-3, 1);
    p += 11340.*pre(-3, 3);
    p += 2100.*pre(-3, 5);
    p += 120.*pre(-3, 7);
    p += 45.*pre(-2, -8);
    p += 1200.*pre(-2, -6);
    p += 9450.*pre(-2, -4);
    p += 30240.*pre(-2, -2);
    p += 44100.*pre(-2, 0);
    p += 30240.*pre(-2, 2);
    p += 9450.*pre(-2, 4);
    p += 1200.*pre(-2, 6);
    p += 45.*pre(-2, 8);
    p += 10.*pre(-1, -9);
    p += 450.*pre(-1, -7);
    p += 5400.*pre(-1, -5);
    p += 25200.*pre(-1, -3);
    p += 52920.*pre(-1, -1);
    p += 52920.*pre(-1, 1);
    p += 25200.*pre(-1, 3);
    p += 5400.*pre(-1, 5);
    p += 450.*pre(-1, 7);
    p += 10.*pre(-1, 9);
    p += 1.*pre(0, -10);
    p += 100.*pre(0, -8);
    p += 2025.*pre(0, -6);
    p += 14400.*pre(0, -4);
    p += 44100.*pre(0, -2);
    p += 63504.*pre(0, 0);
    p += 44100.*pre(0, 2);
    p += 14400.*pre(0, 4);
    p += 2025.*pre(0, 6);
    p += 100.*pre(0, 8);
    p += 1.*pre(0, 10);
    p += 10.*pre(1, -9);
    p += 450.*pre(1, -7);
    p += 5400.*pre(1, -5);
    p += 25200.*pre(1, -3);
    p += 52920.*pre(1, -1);
    p += 52920.*pre(1, 1);
    p += 25200.*pre(1, 3);
    p += 5400.*pre(1, 5);
    p += 450.*pre(1, 7);
    p += 10.*pre(1, 9);
    p += 45.*pre(2, -8);
    p += 1200.*pre(2, -6);
    p += 9450.*pre(2, -4);
    p += 30240.*pre(2, -2);
    p += 44100.*pre(2, 0);
    p += 30240.*pre(2, 2);
    p += 9450.*pre(2, 4);
    p += 1200.*pre(2, 6);
    p += 45.*pre(2, 8);
    p += 120.*pre(3, -7);
    p += 2100.*pre(3, -5);
    p += 11340.*pre(3, -3);
    p += 25200.*pre(3, -1);
    p += 25200.*pre(3, 1);
    p += 11340.*pre(3, 3);
    p += 2100.*pre(3, 5);
    p += 120.*pre(3, 7);
    p += 210.*pre(4, -6);
    p += 2520.*pre(4, -4);
    p += 9450.*pre(4, -2);
    p += 14400.*pre(4, 0);
    p += 9450.*pre(4, 2);
    p += 2520.*pre(4, 4);
    p += 210.*pre(4, 6);
    p += 252.*pre(5, -5);
    p += 2100.*pre(5, -3);
    p += 5400.*pre(5, -1);
    p += 5400.*pre(5, 1);
    p += 2100.*pre(5, 3);
    p += 252.*pre(5, 5);
    p += 210.*pre(6, -4);
    p += 1200.*pre(6, -2);
    p += 2025.*pre(6, 0);
    p += 1200.*pre(6, 2);
    p += 210.*pre(6, 4);
    p += 120.*pre(7, -3);
    p += 450.*pre(7, -1);
    p += 450.*pre(7, 1);
    p += 120.*pre(7, 3);
    p += 45.*pre(8, -2);
    p += 100.*pre(8, 0);
    p += 45.*pre(8, 2);
    p += 10.*pre(9, -1);
    p += 10.*pre(9, 1);
    p += 1.*pre(10, 0);
    return  p / 1048576.;
}

void mainImage( out vec4 fragColor, in vec2 C )
{ 
    float p = getPre() - div(0,0);
    fragColor = vec4(p,vec3(1));
}