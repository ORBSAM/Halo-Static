extends Control

# ===========
# TITLE SCREEN
# Handles all title screen logic.
# ===========

@export var intro_scene_path: String = "res://screens/intro_scene.tscn"

@onready var start_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Quit

# _ready
# hide HUD, build the theme, and make sure the buttons are connected properly
func _ready() -> void:
	# stop all music and play menu theme
	AudioManager.play_music("menu")
	
	theme = PaperTheme.build(true)
	
	# hide HUD overlay on title screen
	if has_node("/root/HUD"):
		get_node("/root/HUD").hide()
	elif has_node("/root/HUD_overlay"):
		get_node("/root/HUD_overlay").hide()

	# connect with print debug
	if start_button and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
			
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

# _on_start_pressed
# go to the introduction scene
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(intro_scene_path)

# _on_quit_pressed
# just quit the game
func _on_quit_pressed() -> void:
	get_tree().quit()
