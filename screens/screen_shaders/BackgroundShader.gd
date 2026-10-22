@tool
extends ColorRect
class_name StaticBG

# =========
# BACKGROUND SHADER
# handles the logic for the screen backgrounds. dungeon ambience is another
# file/shader.
# =========

enum Look { PAUSE_WHITE, WIN_WHITE, DEFEAT_GREY, SCROLL_DARK }
@export var look: Look = Look.PAUSE_WHITE:
	set(v):
		look = v
		if is_inside_tree():
			_apply()

const SHADER := preload("res://screens/screen_shaders/StaticBGShader.gdshader")

# PRESETS
# pause_white is for the pause menu
# win_white is for the win menu
# defeat_grey is for the defeat menu
# scroll_dark is for the scrolling menus
const PRESETS := {
	Look.PAUSE_WHITE: {
		"base_color": Color(0.93, 0.93, 0.96), "speck_color": Color(0.45, 0.45, 0.5),
		"base_alpha": 0.45, "noise_alpha": 0.2, "noise_strength": 0.8,
		"grid": Vector2(320, 180), "scanlines": 0.06, "glitch": 0.0, "vignette": 0.2, "speed": 16.0,
	},
	Look.WIN_WHITE: {
		"base_color": Color(1.0, 1.0, 1.0), "speck_color": Color(0.55, 0.55, 0.6),
		"base_alpha": 0.5, "noise_alpha": 0.2, "noise_strength": 0.7,
		"grid": Vector2(320, 180), "scanlines": 0.04, "glitch": 0.2, "vignette": 0.25, "speed": 12.0,
	},
	Look.DEFEAT_GREY: {
		"base_color": Color(0.28, 0.28, 0.3), "speck_color": Color(0.7, 0.7, 0.72),
		"base_alpha": 0.88, "noise_alpha": 0.12, "noise_strength": 0.8,
		"grid": Vector2(240, 135), "scanlines": 0.12, "glitch": 0.6, "vignette": 0.6, "speed": 20.0,
	},
	Look.SCROLL_DARK: {
		"base_color": Color(0.02, 0.02, 0.04), "speck_color": Color(0.35, 0.35, 0.42),
		"base_alpha": 0.9, "noise_alpha": 0.05, "noise_strength": 0.35,
		"grid": Vector2(400, 225), "scanlines": 0.05, "glitch": 0.0, "vignette": 0.5, "speed": 10.0,
	},
}

# _ready
# handle the application here
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply()

# _apply
# apply the theme here based on the desired look
func _apply() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	for key in PRESETS[look]:
		mat.set_shader_parameter(key, PRESETS[look][key])
	material = mat
