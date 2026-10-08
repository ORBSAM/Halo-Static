shader_type canvas_item;

// Exposed settings to tweak colors in the Inspector
uniform vec4 color_top_left : source_color = vec4(1.0, 0.3, 0.1, 1.0);  // Orange-Red
uniform vec4 color_bottom_right : source_color = vec4(1.0, 0.2, 0.6, 1.0); // Pink-Yellow
uniform vec4 color_accent : source_color = vec4(1.0, 0.8, 0.2, 1.0);       // Soft Gold
uniform float animation_speed : hint_range(0.1, 3.0) = 0.5;

void fragment() {
	vec2 uv = UV;
	
	// Moving subtle wave effect based on TIME
	float wave1 = sin(uv.x * 3.0 + TIME * animation_speed) * 0.15;
	float wave2 = cos(uv.y * 3.0 + TIME * animation_speed * 0.8) * 0.15;
	
	// Adjusted UV coordinates with movement
	vec2 moved_uv = uv + vec2(wave1, wave2);
	
	// Mix top-left and bottom-right corner lights
	vec4 col1 = mix(color_top_left, color_bottom_right, moved_uv.x);
	vec4 col2 = mix(color_bottom_right, color_accent, moved_uv.y);
	
	// Final color blend
	COLOR = mix(col1, col2, 0.5 + wave1);
}