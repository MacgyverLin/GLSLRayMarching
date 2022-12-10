mat2 Rotate(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec3 color,point;
    float index,effect,g, complexity;
    
    for(color++; index++<90.; color-=.01/exp(effect*effect*1e5)){
    
        point = vec3((fragCoord.xy-.5*iResolution.xy)/iResolution.y*g,g-5.);
        point.y -= point.z*.31;
        point.x -= point.z*sin(iTime)*.2; // wobble
        point.x += sin((point.z+=iTime*2.)*.9);
        
        effect = point.y - tanh(point.x*point.x*.9);
        for (complexity=1.; complexity<17.; effect += abs( dot(sin(point.yz*complexity), iResolution.xy/iResolution.xy/complexity*.5) )) 
            
        point.xz = point.xz*Rotate(complexity+=complexity);
                
        g+=effect*.3;
    }
  
    // Water effect
    if (point.y < .0) {       
        color = vec3(.9, .9, .1) + (color/point.y)*.1 ;        
    }
    
    color = 1.-color;
    color.r += point.y*0.1;
    color.g -= point.y;
    color.b -= point.y*2.;
    color -= effect;        
    
    fragColor = vec4(color,1.0);
}