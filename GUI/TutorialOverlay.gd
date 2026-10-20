extends CanvasLayer

signal leave_requested

@export var fade_time: float = 0.25

@onready var ready_prompt: Control = get_node_or_null("ReadyPrompt")
@onready var continue_hint: Control = get_node_or_null("ContinueHint")  # optional "Press Enter" label

signal _advance                      # emitted when the player presses Enter/Space

enum State { IDLE, PAGES, READY }
var _state: State = State.IDLE

func _ready() -> void:
	layer = 110
	_ignore_mouse(self)
	for step in _steps():
		step.hide()
		for page in _pages(step):
			page.hide()
	if ready_prompt:
		ready_prompt.hide()
	if continue_hint:
		continue_hint.hide()

func _ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)

func _steps() -> Array:
	return get_children().filter(func(c): return c is Control and c != ready_prompt and c != continue_hint)

func _pages(step: Control) -> Array:
	var kids := step.get_children().filter(func(c): return c is Control)
	return kids if not kids.is_empty() else [step]

func play() -> void:
	_state = State.PAGES
	for step in _steps():
		step.show()
		for page in _pages(step):
			await _show_page(page)
		step.hide()

	# every page has been seen: now Esc is allowed to leave
	if continue_hint:
		continue_hint.hide()
	_state = State.READY
	if ready_prompt:
		ready_prompt.show()

func _show_page(page: Control) -> void:
	page.modulate.a = 0.0
	page.show()

	var tin := create_tween()
	tin.tween_property(page, "modulate:a", 1.0, fade_time)
	await tin.finished

	if continue_hint:
		continue_hint.show()
	await _advance                      # waits for a key press, no timer

	if continue_hint:
		continue_hint.hide()
	var tout := create_tween()
	tout.tween_property(page, "modulate:a", 0.0, fade_time)
	await tout.finished
	page.hide()

func _unhandled_input(event: InputEvent) -> void:
	match _state:
		State.PAGES:
			# Enter/Space advances. Esc is deliberately ignored here.
			if event.is_action_pressed("ui_accept"):
				_advance.emit()
				get_viewport().set_input_as_handled()
		State.READY:
			if event.is_action_pressed("ui_cancel"):
				_state = State.IDLE
				get_viewport().set_input_as_handled()
				leave_requested.emit()
