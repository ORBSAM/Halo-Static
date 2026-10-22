extends CanvasLayer

# ==========================================
# DIALOGUE OVERLAY ENGINE
# Displays portraits, typewriter text using handwritten .ttf font, and input progression.
# ==========================================

@onready var panel: Panel = $Panel
@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NamePanel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

@export var protagonist_portrait: Texture2D
@export var boss_portrait: Texture2D

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

	# setup portrait and name
	name_label.text = speaker
	if speaker.to_lower() == "boss" and boss_portrait:
		portrait.texture = boss_portrait
	elif protagonist_portrait:
		portrait.texture = protagonist_portrait
		
	show()
	show_next_line()

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
