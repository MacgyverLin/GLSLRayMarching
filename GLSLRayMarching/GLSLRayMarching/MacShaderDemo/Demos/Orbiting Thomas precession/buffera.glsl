// For details on how the keyboard input works, see iq's tutorial: https://www.shadertoy.com/view/lsXGzf

// Numbers are based on JavaScript key codes: https://keycode.info/
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

const float dt = .05;


vec2 m;

vec3 handleKeyboard() {     
    if(iMouse.xy==vec2(0))
         m = vec2(.5);
    else{
        m = (iMouse.xy-.5)/iResolution.xy;
    } 
    // texelFetch(iChannel1, ivec2(KEY, 0), 0).x will return a value of one if key is pressed, zero if not pressed
    vec3 left = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x * vec3(0, 0,1);
    vec3 up = texelFetch(iChannel1, ivec2(KEY_UP,0), 0).x * vec3(1, 0,0);
    vec3 right = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x * vec3(0, 0,-1);
    vec3 down = texelFetch(iChannel1, ivec2(KEY_DOWN, 0), 0).x * vec3(-1, 0,0);
    
    vec3 acceleration = (left + up + right + down) ;   
         acceleration.xy*=rot((m.y-.5)*PI);
         acceleration.xz*=rot(-(m.x-.5)*2.*PI);
    
    return acceleration;
}

vec3 centralForce(float c, vec3 center){

    int r = textureSize(iChannel2, 0).x;

    int i = (iFrame+r-1)%r;
    
    //object position in observer coordinates:
    vec4 pos = texelFetch( iChannel2, ivec2(i, 0), 0);
    
    vec3 pp=pos.xyz-center;
    
    vec3 force = -2.*pp; 
    
    return force*sqrt(c);    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //initial velocity and the corresponding 4velocity:
    vec3 initialv=vec3(initVelocity.x,0,-initVelocity.y);
    vec4 initial4v=vec4(0,0,0,1)*Lorentz(-initialv,c);    
   


    //Transforms coordinates from object to observer frame
    mat4 TransformMat = mat4(1,0,0,0,
                            0,1,0,0,
                            0,0,1,0,
                            0,0,0,1);
                        
    if(iFrame<10){    //set up:        
        for(int j=1; j<=4; j++)
            if(ivec2(fragCoord)==ivec2(0,j)){
                fragColor=TransformMat[j-1];
                }                    
    }else{     //get values from previous step:
        for(int j=1; j<=4; j++)
         {
             TransformMat[j-1]=texelFetch( iChannel0, ivec2(0, j), 0);
         } 
     }                 
    
        
    fragColor= texelFetch( iChannel0, ivec2(fragCoord), 0);
     
         
    //transforms coords from observer to object:
    mat4 Inverse= inverse(TransformMat);        
    
    vec4 fourvel = vec4(texelFetch( iChannel0, ivec2(0, 0), 0).rgb,0);
    
    
    
     //here boost is in observer coordinates. 
    //It will be transformed to object coordinates before making
    //the corresponding Lorentz transformation.
    vec3  boost=vec3(0,0,0); 
    boost = handleKeyboard();

    boost*=.8*sqrt(c);

    //add central force:
    vec3 force=centralForce(c, forceCenter);    
    boost+=force;   
    
    //switch the boost from observer to object coordinates:
    boost=(vec4(boost,0)*Inverse).xyz;        

    
    //get the boost transform
    mat4 NextBoost= Lorentz(-boost*dt,c);
    
    mat4 M=NextBoost*TransformMat;
    
    vec4 nextV=initial4v*M;
          
    //a practical restriction to avoid glitches:
    float contractionLimit=100.;
    if(length(nextV.xyz)<contractionLimit){
        //update stuff:
        TransformMat=M;
        fourvel =nextV;
        Inverse= inverse(TransformMat);
        }
    
    
    
    if(ivec2(fragCoord)==ivec2(0,0)){             
         fragColor= fourvel;          
    }else{
        //StoreMatrix:
        for(int j=1; j<=4; j++)
                if(ivec2(fragCoord)==ivec2(0,j)){
                    fragColor=TransformMat[j-1];
                    }
        for(int j=5; j<=8; j++)
                if(ivec2(fragCoord)==ivec2(0,j)){
                    fragColor=Inverse[j-5];
                    }
    }
 
}