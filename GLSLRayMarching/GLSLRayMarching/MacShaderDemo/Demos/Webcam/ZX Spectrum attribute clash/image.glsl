
// adjust input camera gamma
#define CAMPOW 1.0

// chunky pixel size
#define LOWREZ 4.0

// color brightnesses
#define CFULL 1.0
#define CHALF 0.8431372549

// dither amount, 0 to 1
#define DITHER 1.0


vec4 smap(vec3 c)
{
    c=pow(c,vec3(CAMPOW));
    if( (c.r>CHALF) || (c.g>CHALF) || (c.b>CHALF) ) // bright?
    {
		return vec4( c.rgb , 1.0);
    }
    else
    {
		return vec4( min( (c.rgb/CHALF) , vec3(1.0,1.0,1.0) ) , 0.0 );
    }
}

vec4 bmap(vec3 c)
{
    c=pow(c,vec3(CAMPOW));
    if( (c.r>CHALF) || (c.g>CHALF) || (c.b>CHALF) ) // bright?
    {
		return vec4( floor(c.rgb+vec3(0.5)) , 1.0);
    }
    else
    {
		return vec4( min( floor((c.rgb/CHALF)+vec3(0.5)) , vec3(1.0,1.0,1.0) ) , 0.0 );
    }
}

vec3 fmap(vec4 c)
{
    if(c.a>=0.5)
    {
        return c.rgb*vec3(CFULL,CFULL,CFULL);
    }
    else
    {
        return c.rgb*vec3(CHALF,CHALF,CHALF);
    }
}


void zxspectrum_clash( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pv = floor(fragCoord.xy/LOWREZ);
    vec2 bv = floor(pv/8.0)*8.0;
    vec2 sv = floor(iResolution.xy/LOWREZ);
    
    
    vec4 min_cs=vec4(1.0,1.0,1.0,1.0);
    vec4 max_cs=vec4(0.0,0.0,0.0,0.0);
    float bright=0.0;

    
    for(int py=1;py<8;py++)
    {
        for(int px=0;px<8;px++)
        {
		    vec4 cs=bmap( (texture(iChannel0,(bv+vec2(px,py))/sv).rgb) );
            bright+=cs.a;
        	min_cs=min(min_cs,cs);
        	max_cs=max(max_cs,cs);
        }
    }
    
    vec4 c;
    
    if(bright>=24.0)
    {
        bright=1.0;
    }
    else
    {
        bright=0.0;
    }
    
    if( max_cs.rgb==min_cs.rgb )
    {
        min_cs.rgb=vec3(0.0,0.0,0.0);
    }

    if( max_cs.rgb==vec3(0.0,0.0,0.0) )
    {
        bright=0.0;
        max_cs.rgb=vec3(0.0,0.0,1.0);
        min_cs.rgb=vec3(0.0,0.0,0.0);
    }
    
    vec3 c1=fmap(vec4(max_cs.rgb,bright));
    vec3 c2=fmap(vec4(min_cs.rgb,bright));
    
    vec3 cs=texture(iChannel0,pv/sv).rgb;
    
    vec3 d= (cs+cs) - (c1+c2) ;
    float dd=d.r+d.g+d.b;

    if( mod(pv.x+pv.y,2.0)==1.0)
    {
        fragColor=vec4(
                dd>=-(DITHER*0.5) ? c1.r : c2.r,
                dd>=-(DITHER*0.5) ? c1.g : c2.g,
                dd>=-(DITHER*0.5) ? c1.b : c2.b,
                1.0);
    }
    else
    {
        fragColor=vec4(
                dd>=(DITHER*0.5) ? c1.r : c2.r,
                dd>=(DITHER*0.5) ? c1.g : c2.g,
                dd>=(DITHER*0.5) ? c1.b : c2.b,
                1.0);
    }
 
//    fragColor.rgb=c1;
}

void zxspectrum_colors( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pv = floor(fragCoord.xy/LOWREZ);
    vec2 sv = floor(iResolution.xy/LOWREZ);
                
    vec4 cs=smap(texture(iChannel0,pv/sv).rgb);
    
    if( mod(pv.x+pv.y,2.0)==1.0)
    {
		fragColor = vec4(fmap(vec4(floor(cs.rgb+vec3(0.5+(DITHER*0.3))),cs.a)),1.0);
    }
    else
    {  
		fragColor = vec4(fmap(vec4(floor(cs.rgb+vec3(0.5-(DITHER*0.3))),cs.a)),1.0);
    }

}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
//    zxspectrum_colors(fragColor,fragCoord);
    zxspectrum_clash(fragColor,fragCoord);
}