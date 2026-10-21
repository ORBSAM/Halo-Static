shader_type canvas_item;

uniform vec2 light_center = vec2(0.5, 0.5);        // set from script (player position)
uniform float radius : hint_range(0.05, 1.0) = 0.28;
uniform float softness : hint_range(0.05, 1.0) = 0.5;
uniform float darkness : hint_range(0.0, 1.0) = 0.8;
uniform vec4 fog_color : source_color = vec4(0.10, 0.08, 0.18, 1.0);
uniform float fog_amount : hint_range(0.0, 1.0) = 0.3;
uniform float grain : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
			   mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += vnoise(p) * a;
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float dist = length((UV - light_center) * aspect);

	// slow "breathing" so the dark feels alive
	float r = radius * (1.0 + 0.04 * sin(TIME * 1.1) + 0.02 * sin(TIME * 3.7));
	float vig = smoothstep(r, r + softness, dist);

	// two layers of mist drifting in different directions
	vec2 p = UV * aspect * 3.0;
	float fog = fbm(p + vec2(TIME * 0.03, TIME * 0.015));
	fog += fbm(p * 1.7 - vec2(TIME * 0.02, 0.0)) * 0.5;
	fog = smoothstep(0.45, 1.0, fog) * fog_amount;

	float g = (hash(UV / SCREEN_PIXEL_SIZE + floor(TIME * 24.0)) - 0.5) * grain;

	vec3 col = mix(fog_color.rgb, vec3(0.0), vig);
	float a = clamp(vig * darkness + fog * (0.4 + 0.6 * vig) + g, 0.0, 1.0);
	COLOR = vec4(col, a);
}