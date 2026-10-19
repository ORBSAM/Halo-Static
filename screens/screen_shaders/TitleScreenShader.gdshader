shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.3;
uniform float speed = 18.0;
uniform vec4 tint : source_color = vec4(0.87, 0.63, 0.94, 1.0);   // harmonic pink

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = floor(TIME * speed);

	// rare horizontal glitch bands
	float band = step(0.985, hash(vec2(floor(uv.y * 40.0), t)));
	uv.x += band * (hash(vec2(t, uv.y)) - 0.5) * 0.12;

	float n = hash(floor(uv * vec2(320.0, 180.0)) + t);   // chunky pixel noise
	float scan = 0.85 + 0.15 * sin(UV.y * 600.0);
	vec3 col = mix(vec3(0.02, 0.02, 0.06), tint.rgb, n * intensity) * scan;

	// occasional red chaotic flash
	float flash = step(0.995, hash(vec2(t, 7.0)));
	col += vec3(0.4, 0.0, 0.0) * flash * 0.3;

	float vig = smoothstep(0.95, 0.25, length(UV - 0.5));
	COLOR = vec4(col * vig, 1.0);
}