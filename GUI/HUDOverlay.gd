extends CanvasLayer
# ==========================================
# HUD OVERLAY
# Handles all HUD logic. That includes health, harmonic energy, room label
# and the kill count. The two saber and orb buttons are also there for the user
# to utilize.
# ==========================================

@onready var health_bar: ProgressBar = $"Control/TopLeft/Panel/VBoxContainer/Health Bar"
@onready var energy_bar: ProgressBar = $"Control/TopLeft/Panel/VBoxContainer/Harmony Bar"
@onready var room_label: Label = $"Control/TopRight/Panel/RoomTrack/RoomTrackerLabel"
@onready var kill_count_label: Label = $"Control/TopRight/Panel/KillCount/KillCountLabel"

@onready var key_icon: ColorRect = $Key_Icon_Place
@onready var saber_button: Button = $"Control/BoxContainer/HBoxContainer/E-Icon Weapon"
@onready var orb_button: Button = $"Control/BoxContainer/HBoxContainer/Q-Icon Weapon"


# _ready
# handles signals with dungeon manager, hides key icon, and connects buttons
# to the weapons
func _ready() -> void:
	# 1. connect DungeonManager signals
	if DungeonManager:
		DungeonManager.room_changed.connect(_on_room_changed)
		DungeonManager.kill_count_changed.connect(_on_kill_count_changed)
		_on_room_changed(DungeonManager.current_room_coords)
		_on_kill_count_changed(DungeonManager.enemy_kill_count, DungeonManager.REQUIRED_KILLS)
		
		
	# initially hide key icon
	if key_icon:
		key_icon.visible = false
		
	# connect GUI weapon button clicks
	if saber_button:
		saber_button.pressed.connect(_on_saber_button_pressed)
	if orb_button:
		orb_button.pressed.connect(_on_orb_button_pressed)
		
	# connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		connect_player_signals(player)
	else:
		get_tree().node_added.connect(_on_node_added)

# _on_node_added
# if the node's in the player group, connect it to the player signals
func _on_node_added(node: Node) -> void:
	if node.is_in_group("player"):
		connect_player_signals(node)

# connect_player_signals
# handle all player signals
func connect_player_signals(player: Node) -> void:
	if not player.health_changed.is_connected(update_health):
		player.health_changed.connect(update_health)
		
	if not player.harmonic_changed.is_connected(update_energy):
		player.harmonic_changed.connect(update_energy)
		
	if player.has_signal("key_collected") and not player.key_collected.is_connected(_on_key_collected):
		player.key_collected.connect(_on_key_collected)
		
	# connect DungeonManager kill signal
	if DungeonManager and not DungeonManager.kill_count_changed.is_connected(_on_kill_count_changed):
		DungeonManager.kill_count_changed.connect(_on_kill_count_changed)
		# Initialize display
		_on_kill_count_changed(DungeonManager.enemy_kill_count, DungeonManager.REQUIRED_KILLS)
		 
	# initialize initial values immediately
	update_health(player.current_health, player.max_health)
	update_energy(player.harmonic_energy, player.MAX_HARMONIC)

# update_health
# when player loses health or gains it, change meter here.
func update_health(current: float, max_val: float) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

# update_energy
# ditto but harmonic energy
func update_energy(current: float, max_val: float) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current

# _on_weapon_changed
# if the weapon is changed, change the appearance of the buttons here
func _on_weapon_changed(weapon_index: int) -> void:
	# highlight selected button and unhighlight the other
	# assuming 0 = Saber, 1 = Orb of Light
	if saber_button:
		saber_button.button_pressed = (weapon_index == 0)
	if orb_button:
		orb_button.button_pressed = (weapon_index == 1)

# _on_saber_button_pressed
# if the saber button is pressed, change weapon to the saber
func _on_saber_button_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("equip_weapon"):
		player.equip_weapon(player.Weapon.SABER)

# _on_orb_button_pressed
# if orb button is pressed, change weapon to the orb
func _on_orb_button_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("equip_weapon"):
		player.equip_weapon(player.Weapon.ORB_OF_LIGHT)

# _on_key_collected
# is the key collected? if so, display it here
func _on_key_collected(has_key: bool) -> void:
	if key_icon:
		key_icon.visible = has_key

# _on_room_changed
# update room count based on the visited rooms
func _on_room_changed(_coords: Vector2i) -> void:
	if room_label and DungeonManager:
		room_label.text = "Rooms: %d / %d" % [
			DungeonManager.visited_rooms.size(),
			DungeonManager.grid.size()
		]

# _on_kill_count_changed
# if the kill count is increased, change the label here
func _on_kill_count_changed(current: int, required: int) -> void:
	if kill_count_label:
		kill_count_label.text = "Kills: %d / %d" % [current, required]
