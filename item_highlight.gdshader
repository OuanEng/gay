shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec3 ring_color : source_color = vec3(0.72, 0.92, 0.80);

void fragment() {
	float distance_from_center = length(UV - vec2(0.5)) * 2.0;
	float ring = smoothstep(0.56, 0.70, distance_from_center) * (1.0 - smoothstep(0.82, 0.96, distance_from_center));
	float pulse = 0.20 + sin(TIME * 2.4) * 0.045;
	ALBEDO = ring_color;
	EMISSION = ring_color * 0.42;
	ALPHA = ring * pulse;
}
