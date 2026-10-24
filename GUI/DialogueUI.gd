extends CanvasLayer

# ==========================================
# DIALOGUE OVERLAY ENGINE
# Displays portraits, typewriter text using handwritten .ttf font, and input progression.
# ==========================================

@onready var panel: Panel = $Panel
@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_panel: Panel = $Panel/NamePanel
@onready var name_label: Label = $Panel/NamePanel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

@export var protagonist_portrait: Texture2D
@export var boss_portrait: Texture2D

const PROTAGONIST_BOX := preload("res://GUI/themes/style_box_theme.tres")
const BOSS_BOX := preload("res://GUI/themes/boss_dialogue_box.tres")
const ANTAG_FONT := preload("res://fonts/enemy_font.ttf")
const PROTAG_FONT := preload("res://fonts/Protagfont-Regular.ttf")
const PROTAGONIST_TEXT_COLOR := Color(0.8668957, 0.45357233, 0.67391104, 1.0)
const BOSS_TEXT_COLOR := Color(1.0, 0.82, 0.76, 1.0)
const BOSS_NAME_COLOR := Color(0.92, 0.22, 0.28, 1.0)

const PORTRAITS := {
	"protagonist": {
		"default": preload("res://models/player_images/protag_portrait.png"),
	},
	"boss": {
		"default": preload("res://models/enemy_images/boss_portrait.png"),
	},
}


var current_lines: Array = []
var current_speaker: String = ""
var line_index: int = 0
var is_typing: bool = false
var is_active: bool = false
var blocks_player: bool = false


signal dialogue_finished

# _ready
# hide the dialogue initially
func _ready() -> void:
	hide()

# start_dialogue
# prevent dialogue from plastering itself over another. freeze if in a boss room.
# otherwise, setup portrait and name based on the speaker
func start_dialogue(speaker: String, lines: Array, pause_player: bool=true) -> void:	
	if is_active:
		return # prevent interrupting active dialogue
	
	is_active = true
	current_speaker = speaker
	current_lines = lines
	line_index = 0
	
	AudioManager.play_sfx("dialogue_open")
	
	# freeze player ONLY if the room calls for it
	if blocks_player:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.velocity = Vector2.ZERO
			player.set_physics_process(false)

	# setup the speaker-specific textbox, portrait, and optional name
	var is_boss := speaker.to_lower() == "boss"
	_apply_speaker_style(is_boss)
	if is_boss and boss_portrait:
		portrait.texture = boss_portrait
	elif protagonist_portrait:
		portrait.texture = protagonist_portrait
		
	show()
	show_next_line()

# _apply_speaker_style
# explicitly style each of the two dialogue options. set portraits later.
func _apply_speaker_style(is_boss: bool) -> void:
	if is_boss:
		# --- BOSS STYLE ---
		panel.add_theme_stylebox_override("panel", BOSS_BOX)
		text_label.add_theme_color_override("font_color", BOSS_TEXT_COLOR)
		text_label.add_theme_font_override("font", ANTAG_FONT)
		text_label.add_theme_font_size_override("font_size", 50)
		
		name_panel.visible = true
		name_panel.add_theme_stylebox_override("panel", BOSS_BOX)
		name_label.text = "BOSS"
		name_label.add_theme_font_override("font", ANTAG_FONT)
		name_label.add_theme_font_size_override("font_size", 60)
		name_label.add_theme_color_override("font_color", BOSS_NAME_COLOR)
		
	else:
		# --- PROTAGONIST STYLE ---
		panel.add_theme_stylebox_override("panel", PROTAGONIST_BOX)
		text_label.add_theme_color_override("font_color", PROTAGONIST_TEXT_COLOR)
		
		text_label.add_theme_font_override("font", PROTAG_FONT) 
		text_label.add_theme_font_size_override("font_size", 20)
		
		name_panel.visible = true
		name_panel.add_theme_stylebox_override("panel", PROTAGONIST_BOX)
		name_label.text = "PROTAG"
		name_label.add_theme_font_override("font", PROTAG_FONT)
		name_label.add_theme_font_size_override("font_size", 40)
		name_label.add_theme_color_override("font_color", PROTAGONIST_TEXT_COLOR)
		
	set_portrait(is_boss)
		
# set_portrait
# set the portrait of both the protagonist and the boss
func set_portrait(is_boss: bool, mood: String = "default") -> void:
	var set_: Dictionary = PORTRAITS["boss" if is_boss else "protagonist"]
	# moods; never had them but they were a possibility.
	var tex: Texture2D = set_.get(mood, set_.get("default"))
	portrait.texture = tex
	portrait.visible = tex != null
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel art

# show_next_line
# show the next line if the current line is finished
func show_next_line() -> void:
	if line_index >= current_lines.size():
		close_dialogue()
		return

	var full_text = current_lines[line_index]
	line_index += 1
	await type_text(full_text)

	if not blocks_player:
		await get_tree().create_timer(2.0).timeout
		if is_active:   # may have been closed by a new room load
			show_next_line()

# type_text
# typewriter movement
func type_text(target_text: String) -> void:
	is_typing = true
	text_label.text = ""
	
	for i in range(target_text.length()):
		if not is_typing:
			text_label.text = target_text
			break
		text_label.text += target_text[i]
		await get_tree().create_timer(0.03).timeout
		
		if i % 2 == 0: AudioManager.play_sfx("dialogue_blip", -8.0, 0.12, 0.03)
	is_typing = false

# _unhandled_input
# if the player pressed a button or skip... the text finished with no typewriter
# animation
func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not blocks_player:
		return
		
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed:
		if is_typing:
			# skip typewriter animation
			is_typing = false
		else:
			show_next_line()

# close_dialogu3
# unfreeze player, change boolean, and play SFX
func close_dialogue() -> void:
	is_active = false
	hide()
	
	AudioManager.play_sfx("dialogue_close")
	# unfreeze player
	if blocks_player:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(true)
	blocks_player = false

	dialogue_finished.emit()

# reset
# just in case the dialogue needs to immediately be closed
func reset() -> void:
	is_active = false
	is_typing = false
	blocks_player = false
	hide()
