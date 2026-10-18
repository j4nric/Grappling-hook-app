// Speed lines: thin streaks racing outward at the screen edges. Drawn in
// coarse pixels so they match the pixel look of the 3D view.
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
// Streak slots around the screen.
uniform float lines = 70.0;
// Resolution the streaks are snapped to (the pixel view's size).
uniform vec2 pixel_size = vec2(360.0, 640.0);
uniform vec4 tint : source_color = vec4(0.9, 0.95, 1.0, 1.0);

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	vec2 uv = (floor(UV * pixel_size) + 0.5) / pixel_size;
	vec2 p = uv - 0.5;
	p.x *= pixel_size.x / pixel_size.y;
	float r = length(p);
	float slot_pos = (atan(p.y, p.x) / TAU + 0.5) * lines;
	float slot = floor(slot_pos);
	float across = abs(fract(slot_pos) - 0.5);
	float h = hash(slot);
	// More slots light up with more speed.
	float on = step(1.0 - intensity * 0.8, h);
	// Each streak runs outward, wrapping around.
	float head = 0.25 + fract(hash(slot + 17.0) + TIME * (1.2 + h * 1.5)) * 0.6;
	float len = 0.08 + h * 0.12;
	float body = smoothstep(head - len, head, r) * step(r, head);
	float thin = step(across, 0.12);
	float edge = smoothstep(0.22, 0.45, r);
	COLOR = vec4(tint.rgb, tint.a * on * body * thin * edge * intensity * 0.4);
}
