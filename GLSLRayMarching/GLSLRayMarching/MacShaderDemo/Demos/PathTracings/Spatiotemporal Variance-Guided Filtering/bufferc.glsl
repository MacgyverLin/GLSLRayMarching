// Second filtering pass (step size = 2)
// See the psvgf() function in Common.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  GBuffer g = psvgf(iChannel0, ivec2(fragCoord), 2);
  fragColor = packGBuffer(g);
}
