shader_type canvas_item;

uniform float grain : hint_range(0.0, 0.2) = 0.05;
uniform float stain : hint_range(0.0, 0.3) = 0.07;
uniform float fiber : hint_range(0.0, 0.2) = 0.05;
uniform float line_alpha : hint_range(0.0, 0.5) = 0.0;     // set ~0.12 on panels only
uniform float line_spacing = 28.0;
uniform vec4 line_color : source_color = vec4(0.35, 0.45, 0.75, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
			   mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 p = FRAGCOORD.xy;
	float g = (hash(floor(p)) - 0.5) * grain;
	float s = (vnoise(p * 0.015) - 0.5) * stain;                 // soft stains
	float f = (vnoise(vec2(p.x * 0.5, p.y * 0.03)) - 0.5) * fiber;  // horizontal fibers
	float ln = smoothstep(1.2, 0.0, abs(mod(p.y, line_spacing) - line_spacing * 0.5)) * line_alpha;

	vec3 c = COLOR.rgb + g + s + f;
	c = mix(c, line_color.rgb, ln);
	COLOR = vec4(c, COLOR.a);          // alpha stays as drawn, so rounded corners are kept
}