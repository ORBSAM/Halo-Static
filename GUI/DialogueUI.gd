extends CanvasLayer

# ==========================================
# DIALOGUE OVERLAY ENGINE
# Displays portraits, typewriter text using handwritten .ttf font, and input progression.
# ==========================================

@onready var panel: Panel = $Control/Panel
@onready var portrait: TextureRect = $Control/Panel/HBox/Portrait
@onready var name_label: Label = $Control/Panel/HBox/VBox/NameLabel
@onready var text_label: Label = $Control/Panel/HBox/VBox/TextLabel

@export var protagonist_portrait: Texture2D
@export var boss_portrait: Texture2D

var current_lines: Array[String] = []
var current_speaker: String = ""
var line_index: int = 0
var is_typing: bool = false
var is_active: bool = false

signal dialogue_finished

func _ready() -> void:
	hide()

func start_dialogue(speaker: String, lines: Array[String]) -> void:
	if is_active:
		return # Prevent interrupting active dialogue
		
	is_active = true
	current_speaker = speaker
	current_lines = lines
	line_index = 0
	
	# Freeze player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		
	# Setup portrait and name
	name_label.text = speaker
	if speaker.to_lower() == "boss" and boss_portrait:
		portrait.texture = boss_portrait
	elif protagonist_portrait:
		portrait.texture = protagonist_portrait
		
	show()
	show_next_line()

func show_next_line() -> void:
	if line_index >= current_lines.size():
		close_dialogue()
		return
		
	var full_text = current_lines[line_index]
	line_index += 1
	type_text(full_text)

func type_text(target_text: String) -> void:
	is_typing = true
	text_label.text = ""
	
	for i in range(target_text.length()):
		if not is_typing:
			text_label.text = target_text
			break
		text_label.text += target_text[i]
		await get_tree().create_timer(0.03).timeout
		
	is_typing = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed:
		if is_typing:
			# Skip typewriter animation
			is_typing = false
		else:
			show_next_line()

func close_dialogue() -> void:
	is_active = false
	hide()
	
	# Unfreeze player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		
	dialogue_finished.emit()
