// Daylight through the cave exit: a bright sky with a glowing horizon and
// slowly drifting clouds, seen through an arch-shaped opening (soft edge).
shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
uniform vec4 zenith : source_color = vec4(0.45, 0.68, 1.0, 1.0);
uniform vec4 horizon : source_color = vec4(1.0, 0.93, 0.75, 1.0);
uniform float brightness = 2.2;

void fragment() {
	// Arch: a half ellipse on a rectangle, edges fading into the rock.
	vec2 p = UV * 2.0 - 1.0;
	float arch = p.y < 0.0 ? 1.0 - length(vec2(p.x, p.y * 1.0)) : 1.0 - abs(p.x);
	float mask = smoothstep(0.0, 0.18, arch);
	float clouds = texture(noise, vec2(UV.x * 1.2 + TIME * 0.01, UV.y * 0.6)).r;
	vec3 sky = mix(horizon.rgb, zenith.rgb, smoothstep(0.75, 0.1, UV.y));
	sky = mix(sky, vec3(1.0), smoothstep(0.55, 0.85, clouds) * 0.5 * (1.0 - UV.y));
	ALBEDO = floor(sky * brightness * 6.0) / 6.0;
	ALPHA = mask;
}
