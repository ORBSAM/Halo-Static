extends Control
class_name StoryScroll


# ===============
# STORY SCROLL
# Handles logic for the three scrolls: intro, cliffhanger, and credits.
# =========

@export var story_text: String = ""
@export var scroll_duration: float = 60.0
@export var font_size: int = 28
@export var side_margin: float = 120.0

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var vbox: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var label: Label = $ScrollContainer/VBoxContainer/StoryLabel

var _done := false
var _tween: Tween

# _ready
# set up the scroll container so it works properly
func _ready() -> void:
	# the scroll container should be Full Rect; margins keep the text off the edges
	scroll.offset_left = side_margin
	scroll.offset_right = -side_margin
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	label.text = story_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)

	# a screen of blank space above and below, so the text crawls up from the bottom
	var h := get_viewport_rect().size.y
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, h)
	vbox.add_child(top)
	vbox.move_child(top, 0)
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, h)
	vbox.add_child(bottom)

	_setup_skip_button()

	# wait for layout, then measure
	await get_tree().process_frame
	await get_tree().process_frame
	var max_scroll := int(vbox.get_combined_minimum_size().y - scroll.size.y)

	_tween = create_tween()
	_tween.tween_property(scroll, "scroll_vertical", max_scroll, scroll_duration)
	_tween.finished.connect(_finish)

func _setup_skip_button() -> void:
	var b := get_node_or_null("SkipButton") as Button
	if b == null:
		b = Button.new()
		b.name = "SkipButton"
		b.text = "Skip"
		add_child(b)
		b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		b.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.grow_vertical = Control.GROW_DIRECTION_BEGIN
		b.offset_right = -24
		b.offset_bottom = -24
	if not b.pressed.is_connected(_finish):
		b.pressed.connect(_finish)

# _input
# handles input for the skip button. later will fix the pause menu overlaying
func _input(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("ui_accept") or clicked:
		_finish()

# _on_skip_button_pressed
# kept so an existing signal connection in your intro scene still works
func _on_skip_button_pressed() -> void:
	_finish()

# _finish
# when done, kill the tween animation and pass
func _finish() -> void:
	if _done:
		return
	_done = true
	if _tween:
		_tween.kill()
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.5)
	await out.finished
	_on_done()

# _on_done
# override in the subclass; subclasses have different ways of finishing
func _on_done() -> void:
	pass
