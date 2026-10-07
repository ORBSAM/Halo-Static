extends Control

@export var intro_scene_path: String = "res://scenes/intro_scene.tscn"

@onready var start_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/MenuContainer/Quit


func _ready() -> void:
	# Hide HUD overlay on title screen
	if has_node("/root/HUD"):
		get_node("/root/HUD").hide()
	elif has_node("/root/HUD_overlay"):
		get_node("/root/HUD_overlay").hide()
		
	start_button.grab_focus() # enables keyboard/gamepad navigation
	# Connect with print debug
	if start_button:
		start_button.grab_focus()
		if not start_button.pressed.is_connected(_on_start_pressed):
			start_button.pressed.connect(_on_start_pressed)
			
	if quit_button:
		if not quit_button.pressed.is_connected(_on_quit_pressed):
			quit_button.pressed.connect(_on_quit_pressed)


# _on_start_pressed
# for now, go to the dungeon manager and start the game
func _on_start_pressed() -> void:
	# Option A: Go to intro scene first
	# get_tree().change_scene_to_file(intro_scene_path)
	
	# Option B: Or go directly to main_game.tscn if skipping intro for testing:
	if DungeonManager:
		DungeonManager.start_new_game()
	

func _on_quit_pressed() -> void:
	get_tree().quit()
