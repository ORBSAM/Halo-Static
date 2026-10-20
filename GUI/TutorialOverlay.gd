extends CanvasLayer

signal leave_requested

@export var page_seconds: float = 6.0
@export var fade_time: float = 0.25

@onready var ready_prompt: Control = get_node_or_null("ReadyPrompt")

enum State { IDLE, PAGES, READY }
var _state: State = State.IDLE
var _next := false
var _skip_all := false
var _ready_at := 0

func _ready() -> void:
	layer = 110
	_ignore_mouse(self)
	for step in _steps():
		step.hide()
		for page in _pages(step):
			page.hide()
	if ready_prompt:
		ready_prompt.hide()

func _ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)

func _steps() -> Array:
	return get_children().filter(func(c): return c is Control and c != ready_prompt)

func _pages(step: Control) -> Array:
	var kids := step.get_children().filter(func(c): return c is Control)
	return kids if not kids.is_empty() else [step]

func play() -> void:
	_state = State.PAGES
	_skip_all = false
	for step in _steps():
		if _skip_all:
			break
		step.show()
		for page in _pages(step):
			if _skip_all:
				break
			await _show_page(page)
		step.hide()

	_state = State.READY
	_ready_at = Time.get_ticks_msec()
	if ready_prompt:
		ready_prompt.show()

func _show_page(page: Control) -> void:
	page.modulate.a = 0.0
	page.show()
	create_tween().tween_property(page, "modulate:a", 1.0, fade_time)
	_next = false
	var t := 0.0
	while t < page_seconds and not _next and not _skip_all:
		await get_tree().process_frame
		t += get_process_delta_time()
	var out := create_tween()
	out.tween_property(page, "modulate:a", 0.0, fade_time)
	await out.finished
	page.hide()

func _unhandled_input(event: InputEvent) -> void:
	match _state:
		State.PAGES:
			if event.is_action_pressed("ui_accept"):
				_next = true
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_cancel"):
				_skip_all = true
				get_viewport().set_input_as_handled()
		State.READY:
			# short grace period so the Esc that skipped the pages doesn't also leave
			if event.is_action_pressed("ui_cancel") and Time.get_ticks_msec() - _ready_at > 400:
				_state = State.IDLE
				get_viewport().set_input_as_handled()
				leave_requested.emit()
