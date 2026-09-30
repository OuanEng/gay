shader_type spatial;
render_mode depth_draw_never;
uniform float strength=1.0;
uniform vec3 stain_color : source_color = vec3(0.11,0.085,0.045);
void fragment(){
vec2 p=(UV-vec2(0.5))*2.0;
float noise=sin(p.x*19.0+sin(p.y*13.0))*0.09+sin(p.y*31.0)*0.08;
float shape=1.0-smoothstep(0.45,0.94,length(p)+noise);
ALBEDO=stain_color; ALPHA=shape*0.78*strength; ROUGHNESS=1.0; SPECULAR=0.0;
}
