// Copyright Inigo Quilez, 2016 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

// A rainforest landscape.
//
// Making of Tutorial: https://www.youtube.com/watch?v=BFld4EBO2RE
// Buy a metal or paper print: https://www.redbubble.com/shop/ap/39843511
//
// Normals are analytical (true derivatives) for the terrain and for the
// clouds, including the noise, the fbm and the smoothsteps.
//
// Lighting and art composed for this shot/camera. The trees are really
// ellipsoids with noise, but they kind of do the job in distance and low
// image resolutions Also I used some basic reprojection technique to 
// smooth out the render.
//
// See here for more info: 
//  https://iquilezles.org/articles/fbm
//  https://iquilezles.org/articles/morenoise


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord/iResolution.xy;

    vec3 col = texture( iChannel0, p ).xyz;
  //vec3 col = texelFetch( iChannel0, ivec2(fragCoord-0.5), 0 ).xyz;

    col *= 0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.05 );
         
    fragColor = vec4( col, 1.0 );
}
