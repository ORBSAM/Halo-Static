extends StoryScroll
# ===========
# CREDITS SCROLL 
# Handles all logic for the credits at the end of the game
# ============

# heading lines
const BEFORE := [
	["HARMONIC SENTINEL", ["Design, art and code: your name"]],
	["ART", [
		"Enemy sprites: ...",
		"Fire animation: ...",
	]],
]
const AFTER := [
	["TOOLS", ["Godot Engine"]],
	["THANK YOU FOR PLAYING", []],
]

func _ready() -> void:
	theme = PaperTheme.build(true)
	scroll_duration = 35.0

	var blocks: Array = []
	blocks.append_array(BEFORE)

	var music := AudioManager.music_credit_lines()
	if not music.is_empty():
		blocks.append(["MUSIC", music])
	var sfx := AudioManager.sfx_credit_lines()
	if not sfx.is_empty():
		blocks.append(["SOUND EFFECTS", sfx])

	blocks.append_array(AFTER)

	var s := ""
	for block in blocks:
		s += block[0] + "\n\n"
		for line in block[1]:
			s += line + "\n"
		s += "\n\n"
	story_text = s
	super()

func _on_done() -> void:
	get_tree().change_scene_to_file("res://screens/title_screen.tscn")
