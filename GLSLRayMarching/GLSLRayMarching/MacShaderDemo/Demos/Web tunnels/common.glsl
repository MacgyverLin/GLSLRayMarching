#define image_scale 8.0
#define rot(spin) mat2(cos(spin),sin(spin),-sin(spin),cos(spin))

const int MAX_MARCHING_STEPS = 500;
const float MIN_DIST = 0.0;
const float MAX_DIST = 1000.0;
const float EPSILON = 0.001;

const float size = 1000.0;


const float scale = EPSILON; //to prevent rendering artifacts

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */


float planet_surface(vec3 p,float i){
    
    vec3 p1 = p/size;
    p = (sin(sin(p1.yzx)*i+cos(p1)*i))*size;
    return length(p) - size;
}



float sceneSDF(vec3 p,float anim) {
    p /= scale;
    //p += vec3(1,-10,170);
    float result = 0.0;
    float i = 1.0;
    for(int i1 = 0; i1 < 4; i1++){
        
    	//p += mod(sin(p/i),i);
        result = max(result, planet_surface(p,i)/(i));
    	i *= -3.0;
    }
    //float result = sceneSDF1(p/1000.0+sceneSDF1(p/1000.0));
    return result*scale/2.0;
}

float sceneSDF(vec3 p){
	return sceneSDF(p,1.0);
}