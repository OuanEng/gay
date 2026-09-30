shader_type spatial;
render_mode depth_draw_never;
uniform float strength=1.0;
uniform float highlight=0.0;
uniform vec3 stain_color : source_color = vec3(0.11,0.085,0.045);
uniform vec3 highlight_color : source_color = vec3(0.20,0.95,0.70);
void fragment(){
vec2 p=(UV-vec2(0.5))*2.0;
float noise=sin(p.x*19.0+sin(p.y*13.0))*0.09+sin(p.y*31.0)*0.08;
float distance_field=length(p)+noise;
float shape=1.0-smoothstep(0.45,0.94,distance_field);
float outline=smoothstep(0.52,0.67,distance_field)*(1.0-smoothstep(0.86,1.0,distance_field));
float pulse=0.72+sin(TIME*4.0)*0.18;
float glow=outline*highlight*pulse;
ALBEDO=mix(stain_color,highlight_color,glow*0.62);
EMISSION=highlight_color*glow*1.8;
ALPHA=max(shape*0.78*strength,glow*0.90);
ROUGHNESS=1.0; SPECULAR=0.0;
}
