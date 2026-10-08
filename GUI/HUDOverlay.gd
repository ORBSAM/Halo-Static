extends CanvasLayer

@onready var health_bar: ProgressBar = $"Control/TopLeft/Panel/VBoxContainer/Health Bar"
@onready var energy_bar: ProgressBar = $"Control/TopLeft/Panel/VBoxContainer/Harmony Bar"
@onready var room_label: Label = $"Control/TopRight/RoomTrackerLabel"

func _ready() -> void:
	# 1. Connect DungeonManager signals
	if DungeonManager:
		DungeonManager.room_changed.connect(_on_room_changed)
		_on_room_changed(DungeonManager.current_room_coords)
		
	# 2. Connect Player signals dynamically
	var player = get_tree().get_first_node_in_group("player")
	if player:
		connect_player_signals(player)
	else:
		# If player spawns slightly later, wait for node
		get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.is_in_group("player"):
		connect_player_signals(node)

func connect_player_signals(player: Node) -> void:
	if not player.health_changed.is_connected(update_health):
		player.health_changed.connect(update_health)
	if not player.harmonic_changed.is_connected(update_energy):
		player.harmonic_changed.connect(update_energy)
		 
	# Initialize initial values immediately
	update_health(player.current_health, player.max_health)
	update_energy(player.harmonic_energy, player.MAX_HARMONIC)

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
