shader_type spatial;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world_pos.xz;
 float row = floor(p.x / 0.24);
 vec2 plank = vec2(fract(p.x / 0.24), fract((p.y + mod(row, 3.0) * 0.61) / 1.83));
 float id = fract(sin(row * 37.1 + floor((p.y + mod(row, 3.0)*0.61)/1.83)*19.7)*437.3);
 float grain = sin(p.x*110.0 + sin(p.y*4.0)*2.0 + sin(p.y*13.0)) * 0.010;
 float seam = step(0.014,plank.x)*step(plank.x,0.986)*step(0.003,plank.y)*step(plank.y,0.997);
 ALBEDO = mix(vec3(0.16,0.11,0.075),mix(vec3(0.29,0.18,0.10),vec3(0.48,0.33,0.20),id)+grain,seam);
 ROUGHNESS = 0.78;
}
