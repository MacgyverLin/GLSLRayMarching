// Copyright 2020 Alexander Dzhoganov
//
// MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/*
 *
 * Real-time global illumination via Monte Carlo path tracing
 * with Spatiotemporal Variance-Guided Filtering.
 *
 * >>>
 * >>> Use the mouse and WASD (or arrow keys) to move the camera.
 * >>>
 *
 * You can increase or decrease the quality (and performance) by changing
 * NUM_SAMPLES in Buffer A. HISTORY_BLEND_FACTOR in Buffer C controls the
 * trade-off between ghosting and noise.
 *
 * The code is pretty well commented and hopefully easy to read.
 * Various quality trade-offs were made due to the very thin gbuffer layout and
 * not enough buffers.
 *
 * > Spatiotemporal Variance-Guided Filtering:
 *
 * Dundr 2018, "Progressive Spatiotemporal Variance-Guided Filtering"
 * https://pdfs.semanticscholar.org/a81a/4eed7f303f7e7f3ca1914ccab66351ce662b.pdf
 *
 * NVIDIA 2017, "Spatiotemporal Variance-Guided Filtering: Real-Time
 * Reconstruction for Path-Traced Global Illumination"
 * https://cg.ivd.kit.edu/publications/2017/svgf/svgf_preprint.pdf
 *
 * Dammertz, Sewtz, Hanika, Lensch 2010, "Edge-Avoiding À-Trous Wavelet
 * Transform for fast Global Illumination Filtering"
 * https://jo.dreggn.org/home/2010_atrous.pdf
 *
 * > Pseudorandom number generation for Monte Carlo integration:
 *
 * GPU Gems 3, "Efficient Random Number Generation and Application Using CUDA"
 * https://developer.nvidia.com/gpugems/gpugems3/part-vi-gpu-computing/chapter-37-efficient-random-number-generation-and-application
 *
 * > Branchless construction of an orthonormal basis:
 *
 * Pixar 2017, "Building an Orthonormal Basis, Revisited"
 * https://graphics.pixar.com/library/OrthonormalB/paper.pdf
 *
 */

// different debug view modes
#define DEBUG_MODE 0
// 0 - debug off
// 1 - albedo
// 2 - normals
// 3 - depth
// 4 - irradiance
// 5 - variance
// 6 - age

bool debugDrawGbuffer(GBuffer gbuf, out vec4 fragColor) {
  switch (DEBUG_MODE) {
  case 1: // albedo
    fragColor = vec4(gbuf.albedo, 1.0);
    break;
  case 2: // normals
    fragColor = vec4(vec3(gbuf.normal * 0.5 + 0.5), 1.0);
    break;
  case 3: // depth
    fragColor = vec4(vec3(gbuf.depth * 0.01), 1.0);
    break;
  case 4: // radiance
    fragColor = vec4(vec3(pow(gbuf.radiance, 1.0 / 2.2)), 1.0);
    break;
  case 5: // variance
    fragColor = vec4(vec3(gbuf.variance), 1.0);
    break;
  case 6: // age
    fragColor = vec4(vec3(gbuf.age), 1.0);
    break;
  }

  return DEBUG_MODE != 0;
}

// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 aces(vec3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // fourth filtering pass (step size = 8)
  GBuffer g = psvgf(iChannel0, ivec2(fragCoord), 8);

  // if any debug mode is active draw it and bail
  if (debugDrawGbuffer(g, fragColor)) {
    return;
  }

  // calculate the final color value of the pixel
  vec3 color = g.albedo * g.radiance;

  // hack to avoid showing first frame artifacts
  if (iFrame == 0) {
    color = vec3(0.0);
  }

  // tonemapping
  color = aces(color);

  // gamma correction
  color = pow(color, vec3(1.0 / 2.2));

  fragColor = vec4(color, 1.0);
}
