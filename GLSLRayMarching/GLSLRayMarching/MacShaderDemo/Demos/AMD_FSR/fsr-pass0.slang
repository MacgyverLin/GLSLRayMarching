#version 450
// SPDX-License-Identifier: Unlicense
#pragma name FSR_EASU

// FSR - [EASU] EDGE ADAPTIVE SPATIAL UPSAMPLING

// filter_linear0 = true
// scale_type0 = viewport
// scale0 = 1.0

uniform vec4 uSourceSize;
uniform vec4 uOriginalSize;
uniform vec4 uOutputSize;
uniform uint uFrameCount;
uniform float uFSR_SHARPENING;
uniform float uFSR_FILMGRAIN;
uniform float uFSR_GRAINCOLOR;
uniform float uFSR_GRAINPDF;

// #pragma parameter uFSR_SHARPENING "FSR RCAS Sharpening Amount (Lower = Sharper)" 0.2 0.0 2.0 0.1
// #pragma parameter uFSR_FILMGRAIN "FSR LFGA Film Grain Intensity" 0.3 0.0 2.0 0.02
// #pragma parameter uFSR_GRAINCOLOR "FSR LFGA Film Grain Color: Gray | RGB" 1.0 0.0 1.0 1.0
// #pragma parameter uFSR_GRAINPDF "FSR LFGA Grain PDF Curve (0.5 = Triangular, Lower = Gaussian)" 0.3 0.1 0.5 0.05

/////////////////////////////////////////////////////////////////////////////////////////
uniform mat4 MVP;
#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main() {
    gl_Position = MVP * Position;
    vTexCoord = TexCoord;
}

/////////////////////////////////////////////////////////////////////////////////////////
#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define A_GPU 1
#define A_GLSL 1
#include "ffx_a.h"

#define FSR_EASU_F 1
AU4 con0, con1, con2, con3;

AF4 FsrEasuRF(AF2 p) { return textureGather(Source, p, 0); }
AF4 FsrEasuGF(AF2 p) { return textureGather(Source, p, 1); }
AF4 FsrEasuBF(AF2 p) { return textureGather(Source, p, 2); }

#include "ffx_fsr1.h"

void main() {
    FsrEasuCon(con0, con1, con2, con3,
        uSourceSize.x, uSourceSize.y,  // Viewport size (top left aligned) in the input image which is to be scaled.
        uSourceSize.x, uSourceSize.y,  // The size of the input image.
        uOutputSize.x, uOutputSize.y); // The output resolution.

    AU2 gxy = AU2(vTexCoord.xy * uOutputSize.xy); // Integer pixel position in output.
    AF3 Gamma2Color = AF3(0, 0, 0);
    FsrEasuF(Gamma2Color, gxy, con0, con1, con2, con3);

    FragColor = vec4(Gamma2Color, 1.0);
}
