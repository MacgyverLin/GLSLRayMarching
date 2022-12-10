// The MIT License
// Copyright © 2019 David Gallardo @galloscript
// Just modeling over Original IQ Raymarching example https://www.shadertoy.com/view/Xds3zN

#define M_PI 3.142
#if HW_PERFORMANCE==0
#define AA 0
#else
#define AA 1  // make this 2 or 3 for antialiasing
#endif

//------------------------------------------------------------------

#define ZERO (min(iFrame,0))

//------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}


vec3 opCheapBend( in vec3 p, float k )
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}


float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

vec3 opMirrorX(in vec3 pos)
{
    vec3 lPos = pos;
    lPos.x = abs(lPos.x);
    return lPos;
}

vec3 opMirrorY(inout vec3 pos)
{
    pos.y = abs(pos.y);
    return pos;
}

vec2 map( in vec3 pos )
{
    vec2 res = vec2( 1e10, 0.0 );

    
    //----- Head -----
    float lHeadBox = sdBox( pos-vec3( 0.0, 0.64, 0.0), vec3(0.26,0.24,0.22) );
    if(res.x > lHeadBox)
    {
        vec3 lHeadStart = rotation(Y_AXIS, 0.5) * (pos - vec3(0.0, 0.64, -0.03));
        mat3 lRotX04 = rotation(X_AXIS, 0.4);
                //Main Head
        float   lHead = sdEllipsoid( lRotX04 * (lHeadStart), vec3(0.18, 0.15, 0.19));
                lHead = opSmoothUnion(lHead, sdEllipsoid( lHeadStart - vec3(0.0, 0.11, 0.00), vec3(0.15, 0.11, 0.14)), 0.1);
                //Nouse
                lHead = opSmoothUnion(lHead, sdCapsule(lHeadStart - vec3(0.0, 0.04, -0.16), vec3(0.0, 0.0, 0.0),  vec3(0.0, -0.01, -0.04), 0.025), 0.005);
                //Neck
                lHead = opSmoothUnion(lHead, sdCylinder( lHeadStart - vec3(0.0, -0.12, 0.0), vec2(0.05, 0.1) ), 0.03);
                //Ears
        vec3	lEarsPos = rotation(Y_AXIS, 0.6) * (opMirrorX(lHeadStart) - vec3(0.2, 0.018, 0.02));
        float 	lEars = sdEllipsoid( lEarsPos, vec3(0.05, 0.05, 0.02));
                lEars = fOpIntersectionRound(lEars, -sdEllipsoid( lEarsPos - vec3(0.0, 0.0, -0.025), vec3(0.03, 0.03, 0.02)), 0.015);

        lHead = opSmoothUnion(lHead, lEars, 0.02);
        res = opU( res, vec2( lHead, 2.0) );

        //Eyes
        float lEyes = sdEllipsoid(opMirrorX(lHeadStart) - vec3(0.05, 0.07, -0.16),  vec3(0.01, 0.016, 0.01));
        mat3 lRotZEB = rotation(Z_AXIS, 0.6);
        float lEyeBrows = sdEllipsoid(lRotZEB * (opMirrorX(lHeadStart) - vec3(0.06, 0.12, -0.14)),  vec3(0.02, 0.012, 0.03));
              lEyeBrows = fOpIntersectionRound(lEyeBrows, -sdEllipsoid(lRotZEB * (opMirrorX(lHeadStart) - vec3(0.06, 0.114, -0.14)), vec3(0.022, 0.011, 0.03)), 0.003);
              lEyes = min(lEyes, lEyeBrows);
        lEyes = max(lEyes, lHead);
        res = opU( res, vec2( lEyes, 4.0) );
		
        float lMouthBox = sdBox( lHeadStart-vec3(0.0, -0.05, -0.15), vec3(0.12,0.05,0.05) );
        if(res.x > lMouthBox)
        {
        	//Mouth
            vec3 lVariance = vec3(sin((pos.x - 20.14) * 200.0 )*0.003, 0.0, 0.0);
            float 	lMouth = sdEllipsoid(lHeadStart - vec3(0.0, -0.05, -0.15) - lVariance,  vec3(0.1, 0.05, 0.04));
                    lMouth = max(lMouth, -sdEllipsoid(lHeadStart - vec3(0.0, -0.043, -0.15) - lVariance,  vec3(0.098, 0.05, 0.05)));
                    lMouth = opSmoothUnion(lMouth, sdSphere(opMirrorX(lHeadStart) - vec3(0.1, -0.045, -0.15), 0.0045), 0.008);
                    lMouth = max(lMouth, lHead);
            res = opU( res, vec2( lMouth, 4.0) );
        }
        
        float lHairFrontBox = sdBox( lHeadStart-vec3( 0.0, 0.17, -0.11), vec3(0.1,0.05,0.05) );
        if(res.x > lHairFrontBox)
        {
            //Hair Front
            mat3 lRotXHair1 = rotation(X_AXIS, -0.8);
            vec3 	lHairFrontLeftStart = lRotXHair1 * (lHeadStart - vec3(0.03, 0.17, -0.11));
            float 	lHairFrontLeft = sdEllipsoid(lHairFrontLeftStart,  vec3(0.03, 0.02, 0.05));
                    lHairFrontLeft = max(lHairFrontLeft, -sdEllipsoid(lHairFrontLeftStart - vec3(0.0, 0.004, 0.0), vec3(0.025, 0.018, 0.05)));
            vec3 	lHairFrontRightStart = lRotXHair1 * (lHeadStart - vec3(-0.03, 0.18, -0.11));
            float 	lHairFrontRight = sdEllipsoid(lHairFrontRightStart,  vec3(0.04, 0.03, 0.05));
                    lHairFrontRight = max(lHairFrontRight, -sdEllipsoid(lHairFrontRightStart - vec3(0.0, 0.004, 0.0), vec3(0.037, 0.028, 0.05)));
            float	lHairFront = min(lHairFrontLeft, lHairFrontRight);
                    lHairFront = max(lHairFront, lHead);
            res = opU( res, vec2( lHairFront, 4.0) );
        }
        //Hair Back
        //TODO
    }
    //----- End Head ------
    
    vec3 lPosMirrorX = opMirrorX(pos);
    
    float lBottomBox = sdBox( pos-vec3( 0.0, 0.1, -0.05), vec3(0.12,0.1,0.12) );
    //res = opU( res, vec2( lBottomBox, 5.0) );
    if(res.x > lBottomBox)
    {
        //Shoes
        float lShoes = sdEllipsoid( lPosMirrorX - vec3(0.06, -0.0025, -0.05), vec3(0.045 , 0.04, 0.12));
              lShoes = opSmoothUnion(lShoes, sdEllipsoid( lPosMirrorX - vec3(0.06, -0.001, -0.08), vec3(0.028 , 0.03, 0.05)), 0.08);
              lShoes = opSmoothUnion(lShoes, sdEllipsoid( lPosMirrorX - vec3(0.06, -0.001,  0.02), vec3(0.02 , 0.018, 0.015)), 0.08);
        res = opU( res, vec2( lShoes, 5.0) );

        //Cordones
        float lCordones = sdEllipsoid( lPosMirrorX - vec3(0.06, 0.031, -0.12), vec3(0.035 , 0.02, 0.008));
             lCordones = min(lCordones, sdEllipsoid( lPosMirrorX - vec3(0.06, 0.035, -0.1), vec3(0.035 , 0.02, 0.008)));
        res = opU( res, vec2( lCordones, 4.0) );

        //Legs
        float lLegs = sdCone( lPosMirrorX - vec3(0.06, 0.02, -0.03), vec3(0.0), vec3(0.0, 0.15, 0.0), 0.03, 0.028);
        res = opU( res, vec2( lLegs, 2.0) );

        //Socks
        vec3 lVariance = vec3(sin((pos.x - 20.14) * 200.0 )*0.001, 0.0, 0.0);
        float lSocks = sdCone( lPosMirrorX - vec3(0.06, 0.03 + lVariance.x, -0.03), vec3(0.0), vec3(0.0, 0.035, 0.0), 0.04, 0.035);
        res = opU( res, vec2( lSocks, 3.0) );

        //Trousers
        float lTrousers = sdCone( lPosMirrorX - vec3(0.06, 0.1, -0.03), vec3(0.0), vec3(0.0, 0.1, 0.0), 0.05, 0.07);
        res = opU( res, vec2( lTrousers, 4.0) );
    }
    
    float lMiddleBox = sdBox( pos-vec3( 0.0, 0.31, -0.03), vec3(0.18,0.16,0.12) );
    
    //res = opU( res, vec2( lMiddleBox, 5.0) );
    if(res.x > lMiddleBox)
    {
        //Torso
        vec3 lTorsoPos =  pos - vec3(0.0, 0.26, -0.03);
        float lTorso = sdEllipsoid( lTorsoPos - vec3(0.0, -0.26, 0.0), vec3(0.15, 0.47, 0.12));
        float lTorsoCutter = sdBox(pos-vec3( 0.0, -0.14 , 0.0), vec3(0.3,0.3,0.3)); //+ lVariance.x * 0.5
              lTorso = fOpIntersectionRound(lTorso, -lTorsoCutter, 0.02 );
        //float lTorso = sdCone( lTorsoPos, vec3(0.0), vec3(0.0, 0.22, 0.0), 0.14, 0.06);
              //Mangas
        float lMangas = sdEllipsoid( rotation(Z_AXIS,-0.4) * (lPosMirrorX - vec3(0.1, 0.35, -0.03)),vec3(0.03, 0.09, 0.03));
              lMangas = max(lMangas, -sdCone( rotation(Z_AXIS,-0.4) * (lPosMirrorX - vec3(0.15, 0.22, -0.03)), vec3(0.0), vec3(0.0, 0.1, 0.0), 0.04, 0.04));
              lTorso = opSmoothUnion(lTorso, lMangas, 0.005);
		
        float lSolapa = sdTorus(lTorsoPos - vec3(0.0, 0.17, 0.0), vec2(0.051, 0.011));
              lSolapa = max(lSolapa, -sdTorus(lTorsoPos - vec3(0.0, 0.167, 0.0), vec2(0.058, 0.008)));
        float lSolapaCutter = sdEllipsoid(lTorsoPos - vec3(0.0, 0.17, -0.1), vec3(0.02, 0.02, 0.08));
        	  lSolapa = max(lSolapa, -lSolapaCutter);
        	  lTorso = min(lTorso, lSolapa);
        res = opU( res, vec2( lTorso, 3.0) );

        //Arms
        float 	lArms = sdCone( rotation(Z_AXIS,-0.19) * (lPosMirrorX - vec3(0.13, 0.2, -0.03)), vec3(0.0), vec3(0.0, 0.15, 0.0), 0.03, 0.028);
        //Fingers
        float 	lFingers  = 			  	sdEllipsoid( (lPosMirrorX - vec3(0.14, 0.20, -0.060)), vec3(0.010, 0.016, 0.01));
                lFingers  = min(lFingers, 	sdEllipsoid( (lPosMirrorX - vec3(0.148, 0.19, -0.040)), vec3(0.012, 0.015, 0.01)));
                lFingers  = min(lFingers, 	sdEllipsoid( (lPosMirrorX - vec3(0.148, 0.194, -0.025)), vec3(0.012, 0.015, 0.008)));
                lFingers  = min(lFingers, 	sdEllipsoid( (lPosMirrorX - vec3(0.142, 0.198, -0.008)), vec3(0.011, 0.015, 0.007)));
                lArms = opSmoothUnion(lArms, lFingers, 0.014);
        res = opU( res, vec2( lArms, 2.0) );

        //Torso Lines
        vec3 lInitialPos = pos - vec3(0.0, 0.0, -0.03);
        mat3 lAngleRot = rotation(Z_AXIS,  0.27 * M_PI);
        float 	lTorsoBoxes = 				   	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 0.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.018, 0.26, -0.06))), vec3(0.018,0.044,0.08) );
			  	lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 1.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.018, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 2.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.024, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 3.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.018, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 4.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.018, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 5.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.018, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 6.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.024, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		lTorsoBoxes = min(lTorsoBoxes, 	sdBox( ( lAngleRot * ( opMirrorX(rotation(Y_AXIS, 7.0 * 0.25 * M_PI) * lInitialPos)-vec3( 0.018, 0.26, -0.06))), vec3(0.018,0.044,0.08) ));
        		
        
        //lTorsoBoxes = min(lTorsoBoxes, sdBox( (rotation(Z_AXIS, 0.25 * M_PI) * ( opMirrorX(rotation(Y_AXIS, 0.5 * M_PI) * pos)-vec3( 0.025, 0.26, -0.06))), vec3(0.02,0.05,0.1) ));
        
        lTorsoBoxes = max(lTorsoBoxes, lTorso);
        res = opU( res, vec2( lTorsoBoxes, 4.0) );
    }
    
    
    //Debug reference
    //float lFront = sdSphere(pos - vec3(0.0, 0.66, -0.5), 0.08);
    //res = opU( res, vec2( lFront, 4.0) );
    return res;
}

// https://iquilezles.org/articles/boxfunctions
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	return vec2( max( max( t1.x, t1.y ), t1.z ),
	             min( min( t2.x, t2.y ), t2.z ) );
}

const float maxHei = 0.8;

vec2 castRay( in vec3 ro, in vec3 rd )
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 1.0;
    float tmax = 20.0;

    // raytrace floor plane
    float tp1 = (0.0-ro.y)/rd.y;
    if( tp1>0.0 )
    {
        tmax = min( tmax, tp1 );
        res = vec2( tp1, 1.0 );
    }
    //else return res;
    
    // raymarch primitives   
    vec2 tb = iBox( ro-vec3(0.8,0.8,-0.8), rd, vec3(4.0,4.0,4.0) );
    if( tb.x<tb.y && tb.y>0.0 && tb.x<tmax)
    {
        tmin = max(tb.x,tmin);
        tmax = min(tb.y,tmax);

        float t = tmin;
        for( int i=0; i<70 && t<tmax; i++ )
        {
            vec2 h = map( ro+rd*t );
            if( abs(h.x)<(0.0001*t) )
            { 
                res = vec2(t,h.y); 
                 break;
            }
            t += h.x;
        }
    }
    
    return res;
}


// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    // bounding volume
    float tp = (maxHei-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = mint;
    for( int i=ZERO; i<16; i++ )
    {
		float h = map( ro + rd*t ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
#if 1
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).x;
    }
    return normalize(n);
#endif    
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

// https://iquilezles.org/articles/checkerfiltering
float checkersGradBox( in vec2 p, in vec2 dpdx, in vec2 dpdy )
{
    // filter kernel
    vec2 w = abs(dpdx)+abs(dpdy) + 0.001;
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)*0.5)-0.5)-abs(fract((p+0.5*w)*0.5)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;                  
}

vec3 calcColor(float m, vec3 pos, vec3 nor, vec3 ro, vec3 rd, in vec3 rdx, in vec3 rdy)
{
	if( m<1.5 )
	{ 	// project pixel footprint into the plane
	    vec3 dpdx = ro.y*(rd/rd.y-rdx/rdx.y);
	    vec3 dpdy = ro.y*(rd/rd.y-rdy/rdy.y);
	    float f = checkersGradBox( 5.0*pos.xz, 5.0*dpdx.xz, 5.0*dpdy.xz );
	    return 0.15 + f*vec3(0.05);
	}
    else if(m < 2.5)
    { 	//Skin
    	return vec3(1.0, 0.807, 0.705) * 0.4;
    }
    else if(m < 3.5)
    { 	//Yellow
        return vec3(0.980, 0.654, 0.058) * 0.45;
    }
    else if(m < 4.5)
    { 	//Black
        return vec3(0.0, 0.0, 0.0);
    }
    else if(m < 5.5)
    { 	//Brown
        return vec3(0.745, 0.270, 0.062) * 0.2;
    }
    
    return vec3(0.0, 0.0, 0.0);
}


vec3 render( in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy )
{ 
    vec3 col = vec3(0.7, 0.7, 0.9) - max(rd.y,0.0)*0.3;
    vec2 res = castRay(ro,rd);
    float t = res.x;
	float m = res.y;
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = (m<1.5) ? vec3(0.0,1.0,0.0) : calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = calcColor(m, pos, nor, ro, rd, rdx, rdy);


        // lighting
        float occ = calcAO( pos, nor );
		vec3  lig = normalize( vec3(-0.5, 0.4, -0.6) );
        
		float amb = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.2, 0.2, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        
        dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );
        dom *= calcSoftshadow( pos, ref, 0.02, 2.5 );
        
        vec3  hal = normalize( lig-rd );
		float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

		vec3 lin = vec3(0.0);
        if(m < 2.5 && m > 1.5)
        {   //Gallo: trick for skin color, make shadows more yellowish
            lin += mix(vec3(2.0, 0.574, 0.488) * 0.45 , col,  dif) * 2.0;
            //exagerated fresnel like in 3D movie
            lin += 3.0*fre*vec3(1.00,1.00,1.00)*occ;
        }
        else if(m > 2.5 && m < 3.5)
    	{ 	//Yellow
        	return lin += mix(vec3(1.980, 0.454, 0.068) * 0.2, col,  dif) * 2.0;
    	}
        
        lin += 1.80*dif*vec3(1.30,1.00,0.70);
        lin += 0.55*amb*vec3(0.40,0.60,1.15)*occ;
        if( m < 1.5 )
        {
        	lin += 0.85*dom*vec3(0.40,0.60,1.30)*occ;
        }
        lin += 0.55*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
		col = col*lin;
		col += 0.50*spe*vec3(1.10,0.90,0.70);

        col = mix( col, vec3(0.7,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

	return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mo = iMouse.xy/iResolution.xy;
	float time = -20.0 + iTime*1.5;

    // camera	
    vec3 ro = vec3( 1.6*cos(0.1*time + 12.0*mo.x),  0.5 + 2.0*mo.y, 1.6*sin(0.1*time + 12.0*mo.x) );
    vec3 ta = vec3( 0.0, 0.4, 0.0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
#else    
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
#endif

        // ray direction
        vec3 rd = ca * normalize( vec3(p,2.0) );

         // ray differentials
        vec2 px = (-iResolution.xy+2.0*(fragCoord.xy+vec2(1.0,0.0)))/iResolution.y;
        vec2 py = (-iResolution.xy+2.0*(fragCoord.xy+vec2(0.0,1.0)))/iResolution.y;
        vec3 rdx = ca * normalize( vec3(px,2.0) );
        vec3 rdy = ca * normalize( vec3(py,2.0) );
        
        // render	
        vec3 col = render( ro, rd, rdx, rdy );

		// gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    
    fragColor = vec4( tot, 1.0 );
}