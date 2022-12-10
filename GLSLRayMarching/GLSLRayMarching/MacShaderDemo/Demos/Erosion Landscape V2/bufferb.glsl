//particles https://michaelmoroz.github.io/Reintegration-Tracking/
const int AREA = 5;
float SIZE = .0005;
const float FRICTION = .98;
const float SPEED = .3;
const float ERR_STR =.000007;
bool BBOX_intersect(vec4 a, vec4 b)
{
     return !(b.x > a.z
        || b.z < a.x
        || b.y > a.w
        || b.w < a.y);
}
vec4 BBOX_overlap(vec4 a, vec4 b)
{
    vec4 r = vec4(0);
    r.xy = max(a.xy,b.xy);
    r.zw = min(a.zw,b.zw);
    if(r.x > r.z || r.y > r.w)return vec4(-1);
    return r;
}

float BBOX_size(vec4 bbox)
{
    return max((bbox.x-bbox.z)*(bbox.y-bbox.w),0.);
}
float BBOX_percent(vec4 a, vec4 b)
{
    return BBOX_size(a)/BBOX_size(b);
}
 
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    SIZE*=iResolution.x;
    fragColor = vec4(0);
    
    if(!(iFrame < 5 || IsSpaceDown(iChannel2)))
    {
        vec4 bbox = vec4(fragCoord-.5, fragCoord+.5);
        for(int x = -AREA; x < AREA; x++)
        {
            for(int y = -AREA; y < AREA; y++)
            {
                vec2 pos = fragCoord+vec2(x,y);

                vec4 data = texture(iChannel0, pos/iResolution.xy);
                pos += data.xy*0.01;
           
                
              
                
                vec4 prbox = vec4(pos-SIZE,pos+SIZE);
                if(BBOX_intersect(bbox,prbox))
                {
                    vec4 overlap = BBOX_overlap(prbox, bbox);
                    float amt = BBOX_percent(overlap, prbox);

                    
                    fragColor += data*amt;
                }
           
                
            }
        }
    
       
    }
    vec4 data = texelFetch(iChannel1, ivec2(fragCoord), 0); 
    if(Rand2D((fragCoord*iTime*100000.3261*iTimeDelta)).x>.9 && data.w > WATER_HEIGHT)
    {
        fragColor.xy += normalize(Rand2D((fragCoord+iTime*12.3261*iTimeDelta))*2.-1.)*50.;
        fragColor.z += Rand2D((fragCoord*iTime*300000.3261*iTimeDelta)).x*.005;
 
    }
    if(fragColor.z != 0.)
    {
        
        vec2 vel = vec2(0);
        vel += normalize(Rand2D((fragCoord*14124.*iTime*12.3261*iTimeDelta))*2.-1.)*50.;
        
        vel += data.xy*10.;
        //vel += vec2(0,-5.);
        vel *=SPEED;
        fragColor.xy += vel;
        fragColor.z+=ERR_STR*length(fragColor.xy)-.0005;
        
        //fragColor.xy/=fragColor.z;
        fragColor.xy*=FRICTION;
        fragColor.z*=.99;
        //fragColor.xy = normalize(fragColor.xy);
        //fragColor *= (data.w < WATER_HEIGHT) ? vec4(vec2(0.95), .99, 1.) : vec4(1.);
        
        
        
       
        
    }
   

    
}