extends CanvasLayer

@onready var health_bar: ProgressBar = $"Control/TopLeft/VBoxContainer/Health Bar"
@onready var energy_bar: ProgressBar = $"Control/TopLeft/VBoxContainer/Harmony Bar"
@onready var room_label: Label = $"Control/TopRight/RoomTrackerLabel"

func _ready() -> void:
	if not DungeonManager.room_changed.is_connected(_on_room_changed):
		DungeonManager.room_changed.connect(_on_room_changed)
	_on_room_changed(DungeonManager.current_room_coords)

	if not GlobalManager.health_changed.is_connected(update_health):
		GlobalManager.health_changed.connect(update_health)
	if not GlobalManager.energy_changed.is_connected(update_energy):
		GlobalManager.energy_changed.connect(update_energy)

	update_health(GlobalManager.current_health, GlobalManager.max_health)
	update_energy(
		GlobalManager.harmonic_energy,
		GlobalManager.MAX_HARMONIC_ENERGY
	)

func update_health(current: float, max_val: float) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func update_energy(current: float, max_val: float) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current

func _on_room_changed(coords: Vector2i) -> void:
	if room_label and DungeonManager:
		room_label.text = "Room %d / %d" % [coords.x + 1, DungeonManager.TOTAL_ROOMS]
