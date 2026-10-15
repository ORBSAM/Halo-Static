extends Control

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var story_label: Label = $ScrollContainer/VBoxContainer/StoryLabel
@export var scroll_duration: float = 30.0

var is_fading_out: bool = false

func _ready() -> void:
	story_label.text = """In a realm fractured by chaotic frequencies, 

the balance of harmony was shattered...

As the last Harmonic Sentinel, you must navigate 
the echoing chambers of the ancient spire, 

defeat the corrupted entities within, 
and restore equilibrium before all falls into permanent discord.
"""
	await get_tree().process_frame
	start_scroll_tween()

func start_scroll_tween() -> void:
	var v_bar = scroll_container.get_v_scroll_bar()
	var max_scroll = v_bar.max_value - scroll_container.size.y
	
	if max_scroll <= 0:
		# Fallback if text is short
		max_scroll = 200.0 

	var tween = create_tween()
	# Smoothly tween the scroll_vertical property from 0 to max_scroll over X seconds
	tween.tween_property(scroll_container, "scroll_vertical", int(max_scroll), scroll_duration)
	tween.finished.connect(start_game)

func _unhandled_input(event: InputEvent) -> void:
	# Allow player to skip by pressing Space, Enter, or clicking
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton:
		start_game()

func _on_skip_button_pressed() -> void:
	start_game()

func start_game() -> void:
	if is_fading_out:
		return
	is_fading_out = true
	
	if DungeonManager:
		DungeonManager.start_new_game()
