shader_type canvas_item;

uniform vec2 light_center = vec2(0.5, 0.5);        // still set from DungeonManager
uniform float radius : hint_range(0.05, 1.5) = 0.55;
uniform float softness : hint_range(0.05, 1.5) = 0.8;
uniform float darkness : hint_range(0.0, 1.0) = 0.55;
uniform float ragged : hint_range(0.0, 0.3) = 0.1;     // inky, uneven edge
uniform vec4 ink_color : source_color = vec4(0.09, 0.07, 0.07, 1.0);
uniform vec4 paper_color : source_color = vec4(0.86, 0.79, 0.63, 1.0);
uniform float paper_tint : hint_range(0.0, 0.4) = 0.07; // warm wash over everything
uniform float fog_amount : hint_range(0.0, 1.0) = 0.18;
uniform float grain : hint_range(0.0, 0.2) = 0.05;
uniform float fiber : hint_range(0.0, 0.2) = 0.06;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
			   mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += vnoise(p) * a; p *= 2.0; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 q = UV * aspect;

	// ragged, slowly shifting edge so the dark looks like ink soaking into paper
	float edge = (fbm(q * 3.0 + vec2(TIME * 0.02, 0.0)) - 0.5) * ragged;
	float dist = length((UV - light_center) * aspect) + edge;
	float r = radius * (1.0 + 0.03 * sin(TIME * 1.1));
	float vig = smoothstep(r, r + softness, dist);

	float fog = fbm(q * 2.5 + vec2(TIME * 0.025, TIME * 0.012));
	fog = smoothstep(0.5, 1.0, fog) * fog_amount;

	// paper surface: pixel grain plus horizontal fibers and soft stains
	vec2 p = FRAGCOORD.xy;
	float tex = (hash(floor(p)) - 0.5) * grain
			  + (vnoise(vec2(p.x * 0.5, p.y * 0.03)) - 0.5) * fiber
			  + (vnoise(p * 0.01) - 0.5) * 0.06;

	vec3 col = mix(paper_color.rgb, ink_color.rgb, vig) + tex;
	float a = max(paper_tint, vig * darkness) + fog * (0.3 + 0.7 * vig);
	COLOR = vec4(col, clamp(a, 0.0, 0.92));
}