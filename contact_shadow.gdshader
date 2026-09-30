shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment(){float d=length(UV-vec2(0.5))*2.;ALBEDO=vec3(0.045,0.032,0.025); ALPHA=(1.-smoothstep(0.15,1.,d))*0.26;}
