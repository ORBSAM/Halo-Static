extends CanvasLayer

@onready var container: Control = $Control

func _ready() -> void:
	# hide pause menu initially
	hide()
	
	container.theme = PaperTheme.build()

	# CRITICAL: This ensures the pause menu can still process input 
	# and button clicks even when get_tree().paused is true!
	process_mode = Node.PROCESS_MODE_ALWAYS

# _unhandled_input
# toggles pause when pressing escape
func _unhandled_input(event: InputEvent) -> void:
	# if the tutorial is currently happening, do not trigger this pause menu
	if DungeonManager.in_tutorial:
		return                      # Esc belongs to the tutorial overlay here
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

# toggle_pause
func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	AudioManager.play_sfx("pause_open" if new_pause_state else "pause_close")
	
	# optional: release mouse capture if your game uses mouse aiming
	if new_pause_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED # or HIDDEN depending on setup

# _on_resume_button_pressed
# Button signal connections
func _on_resume_button_pressed() -> void:
	toggle_pause()

# on_restart_button_pressed
func _on_restart_button_pressed() -> void:
	# Unpause before resetting the game state
	get_tree().paused = false
	if DungeonManager:
		DungeonManager.start_new_game()
	else:
		get_tree().reload_current_scene()
	# put the pause screen back to the default state of hidden
	_ready() 

# _on_main_menu_pressed
func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	# clear active dungeon entities if returning to title screen
	if DungeonManager and DungeonManager.has_method("clear_current_dungeon"):
		DungeonManager.clear_current_dungeon()
	# return to title screen
	get_tree().change_scene_to_file("res://screens/title_screen.tscn")
	_ready()
