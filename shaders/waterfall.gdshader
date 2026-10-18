// Waterfall: streaks of the noise texture stretched along the fall and
// scrolling down, soft at the sides, a white rim where it is thickest.
// Stepped colors and alpha fit the pixel look.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
uniform float speed = 0.9;
uniform vec4 water : source_color = vec4(0.55, 0.78, 1.0, 1.0);
uniform vec4 foam : source_color = vec4(0.92, 0.97, 1.0, 1.0);
// Meters of fall per noise repeat: long streaks.
uniform float streak = 18.0;
uniform float height = 60.0;

void fragment() {
	float y = UV.y * height / streak;
	float a = texture(noise, vec2(UV.x * 1.5, y - TIME * speed)).r;
	float b = texture(noise, vec2(UV.x * 3.1 + 0.37, y * 1.6 - TIME * speed * 1.3)).r;
	float flow = a * 0.6 + b * 0.4;
	// Soft sides, a thinner veil near the top.
	float side = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.75, UV.x);
	float alpha = side * (0.45 + 0.5 * smoothstep(0.3, 0.75, flow)) * smoothstep(0.0, 0.04, UV.y);
	vec3 col = mix(water.rgb, foam.rgb, smoothstep(0.6, 0.9, flow));
	ALBEDO = floor(col * 8.0) / 8.0;
	ALPHA = floor(alpha * 6.0) / 6.0;
}
