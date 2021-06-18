// Third filtering pass (step size = 4).
// See the psvgf() function in Common.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  GBuffer g = psvgf(iChannel0, ivec2(fragCoord), 4);
  fragColor = packGBuffer(g);
}
