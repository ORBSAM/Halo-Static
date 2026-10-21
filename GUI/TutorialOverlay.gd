extends CanvasLayer

signal leave_requested
signal _advance

@export var fade_time: float = 0.25
@export var lines: Array[String] = [
	"Welcome, Sentinel. Your health is the top bar...",
	"...and your harmony is the bar below it. Fill it to unleash a blast.",
	"Press E for the saber, Q for the orb of light.",
	"Corrupted entities will hunt you. Pink shards help you; red essence hurts.",
	"Good luck."
]

@onready var box: Control = $Bottom/TutorialBox
@onready var text: Label = $Bottom/TutorialBox/TutorialText
@onready var hint: Label = $ContinueHint
@onready var ready_prompt: Label = $ReadyPrompt

enum State { IDLE, PAGES, READY }
var _state: State = State.IDLE

func _ready() -> void:
	layer = 110
	for c in [box, text, hint, ready_prompt]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.hide()
	hint.hide()
	ready_prompt.hide()
	_bob(hint)

# floating hint: loops forever, tied to the node
func _bob(n: Control) -> void:
	var y := n.position.y
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "position:y", y - 6.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(n, "position:y", y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _pulse(n: Control) -> void:
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "modulate:a", 0.3, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func play() -> void:
	_state = State.PAGES
	box.modulate.a = 0.0
	box.show()
	create_tween().tween_property(box, "modulate:a", 1.0, fade_time)

	for line in lines:
		text.text = line
		text.modulate.a = 0.0
		var tin := create_tween()
		tin.tween_property(text, "modulate:a", 1.0, fade_time)
		await tin.finished

		hint.show()
		await _advance
		hint.hide()

		var tout := create_tween()
		tout.tween_property(text, "modulate:a", 0.0, fade_time)
		await tout.finished

	var bout := create_tween()
	bout.tween_property(box, "modulate:a", 0.0, fade_time)
	await bout.finished
	box.hide()

	# tutorial finished: only now can Esc leave
	_state = State.READY
	ready_prompt.show()
	_pulse(ready_prompt)

func _unhandled_input(event: InputEvent) -> void:
	match _state:
		State.PAGES:
			if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
				_advance.emit()
				get_viewport().set_input_as_handled()
		State.READY:
			if event.is_action_pressed("ui_cancel"):
				_state = State.IDLE
				get_viewport().set_input_as_handled()
				leave_requested.emit()
