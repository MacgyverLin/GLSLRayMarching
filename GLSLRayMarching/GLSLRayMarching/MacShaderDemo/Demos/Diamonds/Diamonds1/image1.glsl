#define PI 3.14159265359
vec3 direction_vector;
vec3 direction_vector_r;
vec3 direction_vector_b;
vec3 horizontal_vector;
vec3 eye_point;
vec3 vertical_vector;
float minimum_distance=0.0001;
float maximum_distance=100.0;
float sample_radius=0.001;
float transmittance=0.0;
float reflectance=0.0;
float reflectance_inner=0.0;
vec4 transmit_color=vec4(0.0);
vec4 reflection_color=vec4(0.0);
vec3 light_point=vec3(0.0,4.0,0.0);
vec4 light_color=vec4(0.5);
bool inside_object=false;
bool object_entered=false;
float refraction_amount=0.2;
float field_of_view=0.75;
mat3 rot_x(float a){
	float c=cos(a);
	float s=sin(a);
	return mat3(
		1.0,0.0,0.0,
		0.0,c,-s,
		0.0,s,c);
}
mat3 rot_y(float a){
	float c=cos(a);
	float s=sin(a);
	return mat3(
		c,0.0,s,
		0.0,1.0,0.0,
		-s,0.0,c);
}
mat3 rot_z(float a){
	float c=cos(a);
	float s=sin(a);
	return mat3(
		c,-s,0.0,
		s,c,0.0,
		0.0,0.0,1.0);
}
mat3 rot(vec3 z,float a){
	float c=cos(a);
	float s=sin(a);
	float ic=1.0-c;
	return mat3(
		ic*z.x*z.x+c,ic*z.x*z.y-z.z*s,ic*z.z*z.x+z.y*s,
		ic*z.x*z.y+z.z*s,ic*z.y*z.y+c,ic*z.y*z.z-z.x*s,
		ic*z.z*z.x-z.y*s,ic*z.y*z.z+z.x*s,ic*z.z*z.z+c);
}

vec4 cubeMap(sampler2D channel, vec3 dir)
{
	dir = normalize(dir);

	vec2 uv;
	uv.x = (atan(dir.x, dir.z) + (3.14)) / (2 * 3.14);
	uv.y = (asin(dir.y) + (3.14 / 2.0)) / (3.14);
	return texture(channel, uv);
}

float diamond_distance(vec3 point){
	float dist=-maximum_distance;
	vec3 point_0=point*rot_y(PI/4.0);
	vec3 point_1=point*rot_y(PI/8.0+PI/16.0);
	vec3 point_2=point*rot_y(PI/8.0-PI/16.0);
	vec3 point_3=point*rot_y(-PI/8.0+PI/16.0);
	vec3 point_4=point*rot_y(-PI/8.0-PI/16.0);
	vec3 temp;
	point_1=vec3(abs(point_1.x),-point_1.y,abs(point_1.z));
	point_2=vec3(abs(point_2.x),-point_2.y,abs(point_2.z));
	point_3=vec3(abs(point_3.x),-point_3.y,abs(point_3.z));
	point_4=vec3(abs(point_4.x),-point_4.y,abs(point_4.z));
	temp=normalize(vec3(1.0,1.5,1.0));
	dist=max(dot(abs(point),temp)-0.5*1.5,dist);
	dist=max(dot(abs(point_0),temp)-0.5*1.5,dist);	
	dist=max(point.y-0.5,dist);
	temp=normalize(vec3(1.0,1.4,1.0));
	dist=max(dot(point_1,temp)-0.762,dist);
	dist=max(dot(point_2,temp)-0.762,dist);
	dist=max(dot(point_3,temp)-0.762,dist);
	dist=max(dot(point_4,temp)-0.762,dist);
	point_1=vec3(point_1.x,-point_1.y,point_1.z);
	point_2=vec3(point_2.x,-point_2.y,point_2.z);
	point_3=vec3(point_3.x,-point_3.y,point_3.z);
	point_4=vec3(point_4.x,-point_4.y,point_4.z);
	temp=normalize(vec3(1.0,1.25,1.0));
	dist=max(dot(point_1,temp)-0.804,dist);
	dist=max(dot(point_2,temp)-0.804,dist);
	dist=max(dot(point_3,temp)-0.804,dist);
	dist=max(dot(point_4,temp)-0.804,dist);
	point_1=point*rot_y(PI/8.0);
	point_2=point*rot_y(-PI/8.0);
	point_1=vec3(abs(point_1.x),point_1.y,abs(point_1.z));
	point_2=vec3(abs(point_2.x),point_2.y,abs(point_2.z));
	temp=normalize(vec3(1.0,2.5,1.0));
	dist=max(dot(point_1,temp)-0.69,dist);
	dist=max(dot(point_2,temp)-0.69,dist);
	return dist;
}
float diamond(in vec3 point){
	float dist=diamond_distance(point);
	if((dist<0.0&&!inside_object)||(dist>0.0&&inside_object)){
		vec3 samplev=vec3(sample_radius,0.0,0.0);
		vec3 normal=normalize(
			vec3(
			diamond_distance(point+samplev.xyy)-dist,
			diamond_distance(point+samplev.yxy)-dist,
			diamond_distance(point+samplev.yyx)-dist)
		);
		if(!inside_object&&!object_entered){
			#define DISPERSION 0.1
			object_entered=true;
			inside_object=!inside_object;
			direction_vector_r=normalize(direction_vector_r-normal*(1.0-DISPERSION));
			direction_vector=normalize(direction_vector-normal);
			direction_vector_b=normalize(direction_vector_b-normal*(1.0+DISPERSION));
			transmittance=dot(direction_vector,-normal);
			reflectance=1.0-transmittance;
			vec3 reflection_direction=reflect(direction_vector,normal);
			reflection_color=cubeMap(iChannel0,reflection_direction);
		}else{
			float transmit_0=dot(direction_vector,normal);
			float transmit_1=transmittance*transmit_0;
			vec4 temp_color=vec4(0.0);
			temp_color.r=cubeMap(iChannel0,direction_vector_r+normal*(1.0-DISPERSION)).r;
			temp_color.g=cubeMap(iChannel0,direction_vector+normal).g;
			temp_color.b=cubeMap(iChannel0,direction_vector_b+normal*(1.0+DISPERSION)).b;
			transmit_color+=transmit_1*temp_color;
			transmittance-=transmit_1;
			direction_vector=reflect(direction_vector,-normal);
		}
	}
	return abs(dist);
}
vec4 trace_ray(){
	float dist;
	vec4 color=vec4(0.0);
	vec3 point=eye_point;
	for(int i=0;i<128;i++){
		dist=max(minimum_distance,diamond(point));
		if(length(point)>10.0){
			color=cubeMap(iChannel0,direction_vector);
			break;
		}
		point+=direction_vector*dist;
	}
	return color+transmit_color+reflection_color*reflectance;
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	float time=iTime/10.0;
	float ratio=iResolution.x/iResolution.y;
	vec2 mouse=vec2((iMouse.x-iResolution.x/2.0)/iResolution.x*ratio,(iMouse.y-iResolution.y/2.0)/iResolution.y);
	vec2 screen_point=vec2((fragCoord.x-iResolution.x/2.0)/iResolution.x*ratio,(fragCoord.y-iResolution.y/2.0)/iResolution.y);
	float view_radius=3.0;
	eye_point=vec3(0.0,0.0,view_radius);
	eye_point*=rot_x(PI*mouse.y+0.25*PI*sin(time));
	eye_point*=rot_y(2.0*PI*mouse.x+time);
	vec3 look_point=vec3(0.0,0.0,0.0);
	vec3 up_vector=vec3(0.0,1.0,0.0);
	direction_vector=normalize(look_point-eye_point);
	horizontal_vector=normalize(cross(direction_vector,up_vector));
	vertical_vector=normalize(cross(horizontal_vector,direction_vector));
	direction_vector*=rot(vertical_vector,field_of_view*screen_point.x);
	direction_vector*=rot(horizontal_vector,field_of_view*screen_point.y);
	direction_vector_r=direction_vector;
	direction_vector_b=direction_vector;
	fragColor=trace_ray();
}
