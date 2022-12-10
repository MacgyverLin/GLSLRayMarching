#define rot(spin) mat2(cos(spin),sin(spin),-sin(spin),cos(spin))

const int MAX_MARCHING_STEPS = 1000;
const float MIN_DIST = 0.0;
const float MAX_DIST = 1000000.0;
const float EPSILON = 0.001;

const float size = 1000.0;


const float scale = EPSILON/10.0; //to prevent rendering artifacts

float planet_surface(vec3 p){
    vec3 p1 = p/size;
    p = (sin(p1)+cos(p1.yzx))*size;
    return length(p) - size+10.0;
}

float sceneSDF(vec3 p) {
    p /= scale;
    float result = 0.0;
    float i = 1.0;
    for(int k = 0; k < 3; k++){
    	result = max(result, planet_surface(p*i)/(i));
        i *= 10.0;
    }
    //float result = sceneSDF1(p/1000.0+sceneSDF1(p/1000.0));
    return result*scale/2.0;
}