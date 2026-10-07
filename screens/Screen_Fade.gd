extends CanvasLayer

signal fade_out_complete
signal fade_in_complete

@onready var color_rect: ColorRect = $grey_fade

# set the color of the rectangle here
func _ready() -> void:
	color_rect.color.a = 0.0

# fade_out
# Fades out of one scene to another
func fade_out(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	fade_out_complete.emit()

# fade_in
# Fades in to one scene from another
func fade_in(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	fade_in_complete.emit()
