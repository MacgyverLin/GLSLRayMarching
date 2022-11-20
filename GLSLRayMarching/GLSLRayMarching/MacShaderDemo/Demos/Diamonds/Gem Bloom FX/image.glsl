///////////////////
// Gem Bloom
// by Timo Kinnunen
//
// Based on Gem Clock (improved) by keim
// @ https://www.shadertoy.com/view/MsfyRj
//
// Original shader in Buffer B, modified to bring out the gems from the scene.
// Buffer A adds a sort of bloom effect. There's probably a standard way of doing this.
// Main image combines bloom with the scene, making adjustments and gamma encoding.
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

const vec3  GAMMA = vec3(1./2.2);

vec4 gamma(in vec4 i) {
  return vec4(pow(i.xyz, GAMMA), i.w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord/iResolution.xy;
    vec4 res = texture(iChannel2,uv);
    vec4 glow = texture(iChannel3,uv);
    fragColor = gamma(max(vec4(0),sqrt(5.5*glow)*.015625)+res);
}
