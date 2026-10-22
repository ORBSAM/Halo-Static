extends Control

# ===========
# TITLE SCREEN
# Handles all title screen logic.
# ===========

@export var intro_scene_path: String = "res://screens/intro_scene.tscn"
@export var credits_scene_path: String = "res://screens/credits.tscn"


@onready var start_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Quit
@onready var credits_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Credits

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

	start_button.grab_focus()


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	# Keep the menu clickable inside Godot's embedded game window.
	if start_button.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		_on_start_pressed()
	elif quit_button.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		_on_quit_pressed()
	elif credits_button.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		_on_credits_pressed()

# _on_start_pressed
# go to the introduction scene
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(intro_scene_path)

# _on_quit_pressed
# just quit the game
func _on_quit_pressed() -> void:
	get_tree().quit()

# on_credits_pressed
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(credits_scene_path)
