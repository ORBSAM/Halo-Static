shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);   // the "floor" colour
uniform vec4 speck_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);  // what the noise pulls toward
uniform float base_alpha : hint_range(0.0, 1.0) = 0.4;               // translucency with no noise
uniform float noise_alpha : hint_range(0.0, 1.0) = 0.2;              // extra opacity where noise is bright
uniform float noise_strength : hint_range(0.0, 1.0) = 0.7;
uniform float speed = 16.0;
uniform vec2 grid = vec2(320.0, 180.0);                              // lower = chunkier static
uniform float scanlines : hint_range(0.0, 0.5) = 0.08;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;                   // rare horizontal tears
uniform float vignette : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = floor(TIME * speed);
	vec2 uv = UV;

	float band = step(1.0 - 0.015 * glitch, hash(vec2(floor(uv.y * 40.0), t)));
	uv.x += band * (hash(vec2(t, uv.y)) - 0.5) * 0.15;

	float n = hash(floor(uv * grid) + t);
	float scan = 1.0 - scanlines * (0.5 + 0.5 * sin(UV.y * grid.y * 6.28318));

	vec3 col = mix(base_color.rgb, speck_color.rgb, n * noise_strength) * scan;
	float a = base_alpha + noise_alpha * n;

	float vig = 1.0 - vignette * smoothstep(0.35, 0.95, length(UV - 0.5));
	COLOR = vec4(col * vig, clamp(a, 0.0, 1.0));
}