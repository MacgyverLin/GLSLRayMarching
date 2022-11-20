vec2 rot(vec2 p, float a) {
    a=radians(a);
    return cos(a)*p + sin(a)*vec2(p.y, -p.x);
}
vec2 saturate(vec2 p) { return clamp(p,0.,1.); }
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    const float n = 24.;
    const float a1 = -1.;
    const float a2 = -5.;
    vec2 uv = fragCoord/iResolution.xy;
    vec3 color = vec3(0);
    vec2 colorShift = vec2(2,1)/iResolution.xy;
    vec2 uv1 = uv+colorShift;
    vec2 uv2 = uv;
    vec2 uv3 = uv-colorShift;
    vec2 axis1 = rot(vec2(0,1.105/iResolution.y),-15.);
    vec2 axis2 = rot(vec2(0,0.953/iResolution.y),+65.);
    for(float delta = 0.; delta< n;delta++){
        float scale = .0625*.0625*(1.-.9875*delta/n);
        vec2 d1r = delta*rot(axis1,-a1);
        vec2 d1g = delta*axis1;
        vec2 d1b = delta*rot(axis1,+a1);
        vec4 texR1 = texture(iChannel0, saturate(uv1+d1r));
        vec4 texR2 = texture(iChannel0, saturate(uv1-d1r));
        vec4 texG1 = texture(iChannel0, saturate(uv2+d1g));
        vec4 texG2 = texture(iChannel0, saturate(uv2-d1g));
        vec4 texB1 = texture(iChannel0, saturate(uv3+d1b));
        vec4 texB2 = texture(iChannel0, saturate(uv3-d1b));
        vec3 aberr1 = vec3(dot(vec4(10,4,2,0),texR1+texR2),
                           dot(vec4(3,10,3,0),texG1+texG2),
                           dot(vec4(2,4,10,0),texB1+texB2));
        vec3 col1 = aberr1*max(aberr1.r,max(aberr1.g,aberr1.b));
        vec2 d2r = delta*rot(axis2,+a2);
        vec2 d2g = delta*axis2;
        vec2 d2b = delta*rot(axis2,-a2);
        vec4 texR3 = texture(iChannel0, saturate(uv1+d2r));
        vec4 texR4 = texture(iChannel0, saturate(uv1-d2r));
        vec4 texG3 = texture(iChannel0, saturate(uv2+d2g));
        vec4 texG4 = texture(iChannel0, saturate(uv2-d2g));
        vec4 texB3 = texture(iChannel0, saturate(uv3+d2b));
        vec4 texB4 = texture(iChannel0, saturate(uv3-d2b));
        vec3 aberr2 = vec3(dot(vec4(10,4,2,0),texR3+texR4),
                           dot(vec4(3,10,3,0),texG3+texG4),
                           dot(vec4(2,4,10,0),texB3+texB4));
        vec3 col2 = aberr2*max(aberr2.r,max(aberr2.g,aberr2.b));
        vec3 col = pow(scale*max(col1,col2)*3.7,vec3(5.2));
        color+=col;
    }
    fragColor = vec4(mix(texture(iChannel0,uv).rgb,
                         color,
                         smoothstep(.01,.2,min(uv.x,uv.y))*smoothstep(-.99,-.8,-max(uv.x,uv.y))),1);
}