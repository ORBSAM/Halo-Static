extends CanvasLayer

@onready var health_bar: TextureProgressBar = $"Control/TopLeft/VBoxContainer/Health Bar"
@onready var energy_bar: TextureProgressBar = $"Control/TopLeft/VBoxContainer/Harmony Meter"
@onready var room_label: Label = $"Control/TopRight/RoomTrackerLabel"


func _ready() -> void:
	# register HUD with DungeonManager or connect player signals
	if DungeonManager:
		DungeonManager.room_changed.connect(_on_room_changed)
		_on_room_changed(DungeonManager.current_room_coords)


func update_health(current: float, max_val: float) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current


func update_energy(current: float, max_val: float) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current


func _on_room_changed(coords: Vector2i) -> void:
	if room_label:
		room_label.text = "Room %d / %d" % [coords.x + 1, DungeonManager.TOTAL_ROOMS]
