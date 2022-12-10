// water simulation
// waterlevel at 0.0
// xyzw: h1, h2, landscape height, 0

float waterlevel = 0.5;
float pi = 3.14159265359;


float hit(in vec2 fragCoord) {
    float h = smoothstep(2.0, 1.0, distance(fragCoord, iMouse.xy));
        
    return h;
}
float rain(in vec2 fragCoord) {
    vec2 dropPos = vec2((sin(iTime*pi*161.8)*0.5+0.5)*iResolution.x, (cos(iTime*pi*100.0)*0.5 + 0.5)*iResolution.y);
    float h = smoothstep(2.0, 1.0, distance(fragCoord, dropPos.xy));
    return h;
    //return smoothstep(0.99, 1.0, sin(fragCoord.x*iTime)*cos(fragCoord.y*iTime))*1.0;
}

vec2 simStep(in vec2 fragCoord) {
   if(texture(iChannel0, fragCoord/iResolution.xy).z < 0.0) {
       return vec2(((texture(iChannel0, (fragCoord + vec2(-1,0))/iResolution.xy).x +
           texture(iChannel0, (fragCoord + vec2( 1,0))/iResolution.xy).x +
           texture(iChannel0, (fragCoord + vec2( 0,-1))/iResolution.xy).x +
           texture(iChannel0, (fragCoord + vec2(0,1))/iResolution.xy).x) * 0.5 -
           texture(iChannel0, fragCoord/iResolution.xy).y) * 0.99,
           texture(iChannel0, fragCoord/iResolution.xy).x);
   } else {
       return vec2(0.0, texture(iChannel0, fragCoord/iResolution.xy).x);
   }
}

float landscapeSin(in vec2 fragCoord) {
    return sin(fragCoord.x*10.0)*cos(fragCoord.y*10.0)-0.5;
}

// Juliaset
const int maxIt = 16;
 
vec2 cSqr(vec2 c){
    return vec2(c.x*c.x - c.y*c.y, 2.0*c.x*c.y);
}

float landscapeJulia(in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord)*2.0;
    int it = 0;
    vec2 z = uv;
    vec2 c = vec2(-0.7, 0.6);
    float minD = length(z);
    for(int i=0; i< maxIt;i++){
        z = cSqr(z) + c;
        if(length(z) > 50.0) break;
        it++;
        minD = min(length(z), minD);
    }
    // Time varying pixel color
    
    return -1.0 + 1.5*float(it)/float(maxIt);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec2 pointer = iMouse.xy/iResolution.xy;
    
    // initialize landscape
    if(iFrame == 0 || iMouse.w > 0.5) {
        fragColor.z = landscapeJulia(uv);
    } else {
        fragColor.z = texture(iChannel0, fragCoord/iResolution.xy).z;
    }
    
    // Time varying pixel color
    vec2 height = simStep(fragCoord) + hit(fragCoord) + rain(fragCoord);
    //float height = sin(fragCoord.x*0.1);


    // Output to buffer
    fragColor.xy = vec2(height.x, height.y);
}

