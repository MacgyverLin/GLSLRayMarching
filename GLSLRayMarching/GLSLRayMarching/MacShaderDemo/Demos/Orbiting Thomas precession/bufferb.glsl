//Observer-time step:
#define dt .001*sqrt(c)



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{


    int r= textureSize(iChannel1, 0).x;

    int present=(iFrame+r)%r;
    
    int i=int(fragCoord.x);
    int j=int(fragCoord.y);
        
    if(i!=present&&j==0){
        //just copy previous frame:
        fragColor=texelFetch( iChannel1, ivec2(i, 0), 0);
        }
    
    else if(i==present&&j==0){
        //update:
        int prev= (present-1);   
        
        prev=(prev+r)%r;
        
        vec4 pos = texelFetch( iChannel1, ivec2(prev, 0), 0);
        // Return the offset value from the last frame (zero if it's first frame)
        vec4 fourvel = texelFetch( iChannel0, ivec2(0, 0), 0);       
        
        // Pass in the offset of the last frame and return a new offset based on keyboard input
        pos += fourvel*dt;
    
        // Store offset in the XY values of every pixel value and pass this data to the "Image" shader and the next frame of Buffer A
        fragColor = pos;
    
        }
    else if(i!=present&&j>=1&&j<=4){
        vec4 column=texelFetch( iChannel1, ivec2(i, j), 0);
             fragColor=column;   
        }    
    else if(i==present&&j>=1&&j<=4){
        
        //new j th column of the matrix:
        vec4 column = texelFetch( iChannel0, ivec2(0, j), 0);       
    
        // Store offset in the XY values of every pixel value and pass this data to the "Image" shader and the next frame of Buffer A
        fragColor = column;        } 
    else if(i!=present&&j>=5&&j<=8){
        vec4 column=texelFetch( iChannel1, ivec2(i, j), 0);
             fragColor=column;   
        }    
    else if(i==present&&j>=5&&j<=8){
        
        //new j th column of the matrix:
        vec4 column = texelFetch( iChannel0, ivec2(0, j), 0);       
    
        // Store offset in the XY values of every pixel value and pass this data to the "Image" shader and the next frame of Buffer A
        fragColor = column;       
        }
    
}