const mat3 im_convm = mat3( 1.0,  2.0,  1.0,
                            2.0,  3.0,  2.0,
                            1.0,  2.0,  1.0);

vec4 iconv(mat3 mat, vec2 pos)
{
   vec4 pixval = vec4(0.);
   float csum =0.;
   
   for (int y=0; y<3; y++)
   {
       for (int x=0; x<3; x++)
       {
           vec2 ipos = pos + vec2(float(x-1)/iResolution.x, float(y-1)/iResolution.y);
           pixval+= texture(iChannel0, ipos)*mat[x][y];
           csum+= mat[x][y];
       }
   }
   return pixval/csum;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = iconv(im_convm, uv);
}