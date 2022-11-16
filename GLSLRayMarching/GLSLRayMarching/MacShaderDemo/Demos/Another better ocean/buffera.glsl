
float oct(vec2 p){
    return fract(4768.1232345456 * sin((p.x+p.y*43.0)));
}
float noise2d(vec2 x){
    vec2 p = floor(x);
    vec2 fr = fract(x);
    vec2 LB = p;
    vec2 LT = p + vec2(0.0, 1.0);
    vec2 RB = p + vec2(1.0, 0.0);
    vec2 RT = p + vec2(1.0, 1.0);

    float LBo = oct(LB);
    float RBo = oct(RB);
    float LTo = oct(LT);
    float RTo = oct(RT);

    float noise1d1 = mix(LBo, RBo, fr.x);
    float noise1d2 = mix(LTo, RTo, fr.x);

    float noise2d = mix(noise1d1, noise1d2, fr.y);

    return noise2d;
}
float fbm(vec2 uv){
    return noise2d(uv) * 0.5 + 
        noise2d(uv*3.0) * 0.25 + 
        noise2d(uv*6.0) * 0.125 + 
        noise2d(uv*12.0) * 0.064 + 
        noise2d(uv*24.0) * 0.032 + 
        noise2d(uv*48.0) * 0.032; 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    float n = fbm(uv * 30.0 + fbm(uv * 30.0));
    float clouds = smoothstep(0.15,1.0, n);
    fragColor = vec4(clouds);
}