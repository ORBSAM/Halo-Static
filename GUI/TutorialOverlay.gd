extends CanvasLayer
signal finished

@export var steps: Array[Control] = [$"1", $"2"]
@export var step_seconds: float = 7.0
@export var fade_time: float = 0.3

var _skip := false

func _ready() -> void:
	layer = 110
	for s in steps:
		s.hide()
		s.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):    # Escape skips the current panel
		_skip = true
		get_viewport().set_input_as_handled()

func play() -> void:
	for s in steps:
		_skip = false
		s.show()
		create_tween().tween_property(s, "modulate:a", 1.0, fade_time)
		var t := 0.0
		while t < step_seconds and not _skip:
			await get_tree().process_frame
			t += get_process_delta_time()
		var out := create_tween()
		out.tween_property(s, "modulate:a", 0.0, fade_time)
		await out.finished
		s.hide()
	finished.emit()
