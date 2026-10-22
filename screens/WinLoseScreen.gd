extends Control
class_name EndScreen

@export var continue_scene: String = "res://screens/cliffhanger.tscn"      # win: your cliffhanger scene path
@export var fade_time: float = 1.4
@export var stagger: float = 0.9
@export var start_delay: float = 0.8

const TITLE_SCENE := "res://screens/title_screen.tscn"

func _ready() -> void:
	get_tree().paused = false

	theme = PaperTheme.build()

	var stats := find_child("StatsLabel", true, false) as Label
	if stats and DungeonManager:
		stats.text = "Rooms explored: %d     Entities defeated: %d" % [
			DungeonManager.visited_rooms.size(), DungeonManager.enemy_kill_count]

	_bind("RetryButton", func(): DungeonManager.start_new_game())
	_bind("ContinueButton", func(): get_tree().change_scene_to_file(continue_scene))
	_bind("MainMenuButton", _to_menu)
	_bind("ExitButton", func(): get_tree().quit())

	var content := get_node_or_null("Content")
	
	if content == null:
		return
	
	var items: Array = content.get_children().filter(func(n): return n is CanvasItem)
	for n in items:
		n.modulate.a = 0.0
		if n is Button:
			n.disabled = true

	await get_tree().create_timer(start_delay).timeout
	for n in items:
		var tw := create_tween()
		tw.tween_property(n, "modulate:a", 1.0, fade_time)
		if n is Button:
			tw.finished.connect(func(): n.disabled = false)
		await get_tree().create_timer(stagger).timeout

func _bind(node_name: String, action: Callable) -> void:
	var b := find_child(node_name, true, false) as Button
	if b:
		b.pressed.connect(action)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var actions := {
		"RetryButton": func(): DungeonManager.start_new_game(),
		"ContinueButton": func(): get_tree().change_scene_to_file(continue_scene),
		"MainMenuButton": _to_menu,
		"ExitButton": func(): get_tree().quit(),
	}
	for node_name: String in actions:
		var button := find_child(node_name, true, false) as Button
		if button and button.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			actions[node_name].call()
			return

func _to_menu() -> void:
	DungeonManager.clear_current_dungeon()
	get_tree().change_scene_to_file(TITLE_SCENE)
