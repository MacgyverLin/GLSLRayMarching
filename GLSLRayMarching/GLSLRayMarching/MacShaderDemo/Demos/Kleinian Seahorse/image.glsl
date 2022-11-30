vec3 aces(vec3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec4 tex = texelFetch(iChannel0, ivec2(fragCoord.xy), 0);
    vec3 col = tex.rgb / tex.a;

    col = aces(col);
    col = pow( col, vec3(1./2.2) );
    
    fragColor = vec4(col, 1);
}

