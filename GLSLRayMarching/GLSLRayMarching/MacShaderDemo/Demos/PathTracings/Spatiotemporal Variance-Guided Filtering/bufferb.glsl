
const float HISTORY_BLEND_FACTOR = 0.05;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // first filtering pass (step size = 1)
  GBuffer g = psvgf(iChannel0, ivec2(fragCoord), 1);

  // recreate the ray for this pixel from the camera data
  CameraData camera = unpackCameraData(texelFetch(iChannel0, ivec2(0, 0), 0));
  mat4 cameraMatrix = getInvViewMatrix(camera);
  vec3 ro = camera.position;
  vec3 rd = rayDirection(55.0, iResolution.xy, fragCoord);
  rd = (cameraMatrix * vec4(rd, 0.0)).xyz;

  // fetch the camera data from the previous frame
  // we'll use it to reproject the pixel onto the history buffer
  CameraData prevCamera =
      unpackCameraData(texelFetch(iChannel0, ivec2(1, 0), 0));

  // view matrix from previous frame
  mat4 prevView = getViewMatrix(prevCamera);

  // projection matrix from previous frame
  mat4 prevProj = getProjMatrix(55.0, iResolution.xy, 1.0, 2.0);

  // reconstruct world-space position from ray and depth
  vec3 worldPos = ro + rd * g.depth;

  // project world-space position to screen-space
  vec3 projPos = project2Screen(prevView, prevProj, worldPos);

  // fetch the reprojected pixel from history
  GBuffer prevG = unpackGBuffer(
      texelFetch(iChannel1, ivec2(projPos.xy * iResolution.xy), 0));

  // bounds check
  bvec4 inside = bvec4(projPos.x >= 0.0, projPos.y >= 0.0,
                       projPos.x <= iResolution.x, projPos.y <= iResolution.y);

  // if in bounds and not the first frame blend between the current frame and
  // history buffer (section 4.2 from "Progressive Spatiotemporal
  // Variance-Guided Filtering")
  if (all(inside) && iFrame != 0) {
    const float disocclusionFrames = 10.0;
    const float disocclusionFactor = 5.0;

    float disocclusion = abs(g.depth - prevG.depth);
    if (disocclusion < disocclusionFactor) {
      // increment the pixel's age
      g.age = saturate(prevG.age + 1.0 / disocclusionFrames);

      // r = blending factor
      float r = max(HISTORY_BLEND_FACTOR, saturate(1.0 - g.age));

      // mix the radiance and variance according to r
      g.radiance = mix(prevG.radiance, g.radiance, r);
      g.variance = mix(prevG.variance, g.variance, r);
    } else {
      // discard history value on disocclusion
      g.age = 0.0;
    }
  } else {
    g.age = 0.0;
  }

  fragColor = packGBuffer(g);
}
