shader_type spatial;
render_mode billboard, unshaded, depth_draw_opaque, cull_disabled;

uniform float health_percent : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 fill_color = vec3(0.40169957, 0.8482101, 0.0);
	vec3 bg_color   = vec3(0.2, 0.2, 0.2);
	ALBEDO = UV.x < health_percent ? fill_color : bg_color;
}
