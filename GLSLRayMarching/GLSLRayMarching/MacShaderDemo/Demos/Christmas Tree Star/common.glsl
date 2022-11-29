const float whiteSoftness = 0.2; // this mostly affects the diffuse light - rewind to recompute it!

vec3 HDRtoLDR( vec3 col )
{
    // soft clamp to white (oh this is so good)
    float w2 = whiteSoftness*whiteSoftness;
    col += w2;
    col = (1.-col)*.5;
    col = 1. - (sqrt(col*col+w2) + col);
    
    // linear to sRGB (approx)
    col = pow( col, vec3(1./2.2) );

    return col;
}

vec3 LDRtoHDR( vec3 col )
{
    // sRGB to linear (approx)
    col = pow( col, vec3(2.2) );
    
    col = clamp(col,0.,.99);
    
    float w2 = whiteSoftness*whiteSoftness;
    col = (w2 - col*col + 2.*col - 1.)/(2.*(col - 1.)); // inverted by wolfram
    col = 1.-col*2.;
    col -= w2;
    
    return col;
}
