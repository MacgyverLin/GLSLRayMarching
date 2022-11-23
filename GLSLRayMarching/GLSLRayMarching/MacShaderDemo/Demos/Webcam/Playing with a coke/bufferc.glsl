// Blur ( Buffer C and D ) is coming from TambakoJaguar here :
// https://www.shadertoy.com/view/XstGWB

const int blur_size = 14;
const float blur_width = 1.;

float gauss(float x, float e)
{
    return exp(-pow(x, 2.)/e); 
}

// Horizontal blurring
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 pos = fragCoord.xy / iResolution.xy;
   vec4 pixval = vec4(0.);
   float tot = 0.;
    
   const int nb = 2*blur_size+1;
   
   for (int x=0; x<nb; x++)
   { 
       float x2 = blur_width*float(x-blur_size);
       vec2 ipos = pos + vec2(x2/iResolution.x, 0.);
       float g = gauss(x2, float(20*blur_size));
       pixval+= g*texture(iChannel0, ipos);
       tot+= g;
   }
   fragColor = pixval/tot;
}