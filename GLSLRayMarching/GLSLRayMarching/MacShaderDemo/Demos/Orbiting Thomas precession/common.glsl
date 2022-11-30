const float frames = 70.;
#define t float(iFrame)/frames
#define PI 3.14159265359

const float c=10.;


const vec3 forceCenter= vec3(-.1,0,.0);
const vec2 initVelocity=vec2(.0,-.55)*c;


mat4 Lorentz(vec3 v, float c){
     float beta= length(v)/c;
     float gamma = pow(1.-beta*beta,-.5);
    
    float v2=dot(v,v);
        
    return mat4(1.+(gamma-1.)*v.x*v.x/v2, 0., (gamma-1.)*v.x*v.z/v2, -gamma*v.x/c,
                 0., 1., 0.,0.,
                 (gamma-1.)*v.z*v.x/v2, 0., 1.+(gamma-1.)*v.z*v.z/v2, -gamma*v.z/c ,
                 -gamma*v.x/c, 0., -gamma*v.z/c,   gamma);                            
}

mat2 rot(float a){ 
    return mat2(cos(a), -sin(a),sin(a),cos(a));
}

vec3 pal( in float x, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*x+d) );
}






