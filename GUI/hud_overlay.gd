extends CanvasLayer

@onready var meter: TextureProgressBar = $"Health Bar"

func update_meter(current_val: float, max_val: float) -> void:
	meter.max_value = max_val
	meter.value = current_val
