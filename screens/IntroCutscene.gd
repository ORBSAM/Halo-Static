extends Control

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var story_label: Label = $ScrollContainer/VBoxContainer/StoryLabel
@export var scroll_speed: float = 30.0

var auto_scroll: bool = true

func _ready() -> void:
	story_label.text = """In a realm fractured by chaotic frequencies, 

the balance of harmony was shattered...

As the last Harmonic Sentinel, you must navigate 
the echoing chambers of the ancient spire, 

defeat the corrupted entities within, 
and restore equilibrium before all falls into permanent discord.
"""

func _process(delta: float) -> void:
	if auto_scroll and scroll_container:
		scroll_container.scroll_vertical += int(scroll_speed * delta)
		
		# check if scrolled to bottom
		var max_scroll = scroll_container.get_v_scroll_bar().max_value - scroll_container.size.y
		if scroll_container.scroll_vertical >= max_scroll:
			start_game()

func _on_skip_button_pressed() -> void:
	start_game()

func start_game() -> void:
	if DungeonManager:
		DungeonManager.start_new_game()
	else:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
