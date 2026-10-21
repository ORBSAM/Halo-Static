shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform vec4 speck_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform float base_alpha : hint_range(0.0, 1.0) = 0.4;
uniform float noise_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.7;
uniform float speed = 16.0;
uniform vec2 grid = vec2(320.0, 180.0);
uniform float scanlines : hint_range(0.0, 0.5) = 0.08;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;

// paper lines
uniform vec4 line_color : source_color = vec4(0.35, 0.45, 0.75, 1.0);
uniform float line_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float line_count = 16.0;            // rows on screen
uniform float line_scroll = 0.03;           // screens per second (0 = still)
uniform float line_thickness : hint_range(0.005, 0.2) = 0.04;
uniform vec4 margin_color : source_color = vec4(0.85, 0.25, 0.3, 1.0);
uniform float margin_x : hint_range(0.0, 0.5) = 0.1;
uniform float margin_alpha : hint_range(0.0, 1.0) = 0.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = floor(TIME * speed);
	vec2 uv = UV;

	float band = step(1.0 - 0.015 * glitch, hash(vec2(floor(uv.y * 40.0), t)));
	uv.x += band * (hash(vec2(t, uv.y)) - 0.5) * 0.15;

	// ruled lines, drifting and slightly wobbly
	float y = (uv.y + TIME * line_scroll) * line_count + sin(uv.x * 9.0 + TIME * 0.4) * 0.06;
	float cell = fract(y);
	float line = smoothstep(line_thickness, 0.0, cell) * line_alpha;

	// vertical margin line, jittering with the glitch bands
	float margin = smoothstep(0.0015, 0.0, abs(uv.x - margin_x)) * margin_alpha;

	// static
	float n = hash(floor(uv * grid) + t);
	vec3 col = mix(base_color.rgb, speck_color.rgb, n * noise_strength);
	col = mix(col, line_color.rgb, line);
	col = mix(col, margin_color.rgb, margin);
	col *= 1.0 - scanlines * (0.5 + 0.5 * sin(UV.y * grid.y * 6.28318));

	float a = base_alpha + noise_alpha * n + (line + margin) * 0.25;
	float vig = 1.0 - vignette * smoothstep(0.35, 0.95, length(UV - 0.5));
	COLOR = vec4(col * vig, clamp(a, 0.0, 1.0));
}