// Lava: two layers of the same noise drift against each other; the product
// is mapped to dark crust, glowing cracks and hot yellow. World-space UVs,
// so any lava box tiles seamlessly.
shader_type spatial;

uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
// Noise repeats per meter.
uniform float scale = 0.08;
uniform vec2 drift_a = vec2(0.02, 0.035);
uniform vec2 drift_b = vec2(-0.03, 0.015);
uniform float glow = 2.5;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz * scale;
	float a = texture(noise, uv + TIME * drift_a).r;
	float b = texture(noise, uv * 1.7 + TIME * drift_b).r;
	float heat = clamp(a * b * 2.6 - 0.25 + 0.15 * sin(TIME * 1.3 + uv.x * 9.0), 0.0, 1.0);
	vec3 crust = vec3(0.12, 0.03, 0.02);
	vec3 hot = vec3(1.0, 0.35, 0.05);
	vec3 white = vec3(1.0, 0.85, 0.35);
	vec3 col = mix(crust, hot, smoothstep(0.15, 0.55, heat));
	col = mix(col, white, smoothstep(0.7, 1.0, heat));
	// Snap to coarse steps: fits the pixel look.
	col = floor(col * 8.0) / 8.0;
	ALBEDO = col * 0.4;
	EMISSION = col * glow * smoothstep(0.1, 0.5, heat);
	ROUGHNESS = 0.8;
}
