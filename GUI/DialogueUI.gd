extends CanvasLayer

# ==========================================
# DIALOGUE OVERLAY ENGINE
# Displays portraits, typewriter text using handwritten .ttf font, and input progression.
# ==========================================

# TODO: Reference NinePatchRect frame, RichTextLabel, and TextureRect portraits
# TODO: Declare array of dialogue line dictionaries [{ "speaker": "Boss", "text": "..." }]
# TODO: Track current_line_index and is_typing status

# start_dialogue
func start_dialogue(lines: Array) -> void:
	# TODO: Pause player input / game world
	# TODO: Make CanvasLayer visible
	# TODO: Load first line and trigger typewriter effect
	pass

# _unhandled_input
func _unhandled_input(event: InputEvent) -> void:
	# TODO: If action "ui_accept" or click pressed:
	#   - If text is still typing -> display full line immediately
	#   - If line finished -> advance to next line
	#   - If no lines left -> hide UI and unpause player input
	pass
