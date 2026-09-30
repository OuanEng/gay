shader_type spatial;
uniform vec3 paint_color : source_color = vec3(0.65);
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
float grain=fract(sin(dot(floor(world_pos*130.),vec3(12.9898,78.233,37.719)))*43758.5453);
float aging=sin(world_pos.x*1.8+world_pos.z*1.1)*sin(world_pos.y*3.5)*0.012;
ALBEDO=paint_color*(0.985+grain*0.025)+aging;
ROUGHNESS=1.; SPECULAR=0.05;
}
