extends Node

# ==========================================
# DUNGEON MANAGER (AUTOLOAD SINGLETON)
# Manages 20-room generation, grid state, and scene loading.
# ==========================================

const GRID_WIDTH: int = 4
const GRID_HEIGHT: int = 5
const TOTAL_ROOMS: int = 20

# kill tracking & Boss requirements
var enemy_kill_count: int = 0
const REQUIRED_KILLS: int = 50

# store visited rooms
var visited_rooms: Array[Vector2i] = []

# door direction flags
enum DoorFlags {
	NORTH = 1,
	EAST = 2,
	SOUTH = 4,
	WEST = 8
}

# preload all rooms
@export var room_scenes: Dictionary = {
	"BASE": preload("res://scene_rooms/Room_Base.tscn"),          # Doors: N, E, S, W (Mask: 15)
	"BC": preload("res://scene_rooms/Room_Base_BC.tscn"),          # Doors: N, E       (Mask: 9)
	"SIDE": preload("res://scene_rooms/Room_Base_Side.tscn"),      # Doors: N, S, W    (Mask: 13)
	"TC": preload("res://scene_rooms/Room_Base_TC.tscn"),          # Doors: S, E      (Mask: 12)
	"BOSS": preload("res://scene_rooms/Room_Boss.tscn"),          # Doors: S          (Mask: 4)
	"KEY_VAULT": preload("res://scene_rooms/Room_KeyVault.tscn")  # Doors: N, E, S, W (Mask: 15)
}

const TEMPLATE_MASKS = {
	# base room has all sides
	"BASE": DoorFlags.NORTH | DoorFlags.EAST | DoorFlags.SOUTH | DoorFlags.WEST, # 15
	# the bottom corner has only the northern door, and the eastern door
	"BC": DoorFlags.NORTH | DoorFlags.EAST,                                      # 9
	# side room only is missing the eastern door
	"SIDE": DoorFlags.NORTH | DoorFlags.SOUTH | DoorFlags.WEST,                  # 13
	# top corner only has the southern door and the eastern door
	"TC": DoorFlags.SOUTH | DoorFlags.EAST,                                      # 12
	# the boss room only has the southern door
	"BOSS": DoorFlags.SOUTH,                                                     # 4
	# vault always has all doors
	"KEY_VAULT": DoorFlags.NORTH | DoorFlags.EAST | DoorFlags.SOUTH | DoorFlags.WEST # 15
}

@export var player_scene: PackedScene = preload("res://models/player_logic.tscn")
var player_instance: Node2D = null

var hud_instance: CanvasLayer = null

@export var boss_room_scene: PackedScene
@export var screen_fader: CanvasLayer

# grid stores RoomData: { "scene": PackedScene, "rotation": float, "type": String }
var grid: Dictionary = {}
var current_room_coords: Vector2i = Vector2i.ZERO
var current_room_instance: Node2D = null

var last_entry_direction: Vector2i = Vector2i.ZERO

# are we transitioning?
var is_transitioning: bool = false

# did the room change?
signal room_changed(coords: Vector2i)

# did we kill an enemy?
signal kill_count_changed(current: int, required: int)
# _ready
# let the main menu handle this with start_new_game
func _ready() -> void:
	pass	
	
# start_new_game
func start_new_game() -> void:
	enemy_kill_count = 0
	visited_rooms.clear()
	# 1. instantly remove the title screen / current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.queue_free() # schedule for cleanup
		current_scene.get_parent().remove_child(current_scene) # remove from tree IMMEDIATELY so it stops rendering!
		get_tree().current_scene = null

	# 2. re-enable and display the HUD overlay
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	elif has_node("/root/HUD_overlay"):
		get_node("/root/HUD_overlay").show()

	# 3. build layout and load starting room (0,0)
	generate_dungeon_layout()
	load_room(Vector2i.ZERO)

# generate_dungeon_layout
# Generate 2D Layout and Match Templates with Rotations
func generate_dungeon_layout() -> void:
	grid.clear()
	
	var layout_positions: Array[Vector2i] = []
	var curr = Vector2i.ZERO
	layout_positions.append(curr)
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	while layout_positions.size() < TOTAL_ROOMS:
		var dir = directions.pick_random()
		var next_pos = curr + dir
		
		if next_pos.x >= 0 and next_pos.x < GRID_WIDTH and next_pos.y >= 0 and next_pos.y < GRID_HEIGHT:
			if not layout_positions.has(next_pos):
				layout_positions.append(next_pos)
			curr = next_pos

	var room_required_doors: Dictionary = {}
	for pos in layout_positions:
		var mask = 0
		if layout_positions.has(pos + Vector2i.UP): mask |= DoorFlags.NORTH
		if layout_positions.has(pos + Vector2i.RIGHT): mask |= DoorFlags.EAST
		if layout_positions.has(pos + Vector2i.DOWN): mask |= DoorFlags.SOUTH
		if layout_positions.has(pos + Vector2i.LEFT): mask |= DoorFlags.WEST
		room_required_doors[pos] = mask

	var end_rooms: Array[Vector2i] = []
	for pos in layout_positions:
		if pos != Vector2i.ZERO and get_door_count(room_required_doors[pos]) == 1:
			end_rooms.append(pos)
			
	if end_rooms.size() < 2:
		end_rooms = layout_positions.slice(TOTAL_ROOMS - 3, TOTAL_ROOMS)

	var boss_pos = end_rooms.pop_back()
	var key_vault_pos = end_rooms.pop_back()

	for pos in layout_positions:
		var required_mask = room_required_doors[pos]
		var match_data = {}

		if pos == boss_pos:
			match_data = find_template_match(required_mask, ["BOSS"])
		elif pos == key_vault_pos:
			match_data = find_template_match(required_mask, ["KEY_VAULT", "BASE"])
		else:
			match_data = find_template_match(required_mask, ["BASE", "SIDE", "BC", "TC"])

		grid[pos] = match_data

# rotate_mask
func rotate_mask(mask: int, steps: int) -> int:
	var rotated = mask
	for i in range(steps):
		var new_mask = 0
		if rotated & DoorFlags.NORTH: new_mask |= DoorFlags.EAST
		if rotated & DoorFlags.EAST:  new_mask |= DoorFlags.SOUTH
		if rotated & DoorFlags.SOUTH: new_mask |= DoorFlags.WEST
		if rotated & DoorFlags.WEST:  new_mask |= DoorFlags.NORTH
		rotated = new_mask
	return rotated

# find_template_match
# Find a template and rotation angle matching required doors
func find_template_match(required_mask: int, allowed_templates: Array) -> Dictionary:
	for template_name in allowed_templates:
		var base_mask = TEMPLATE_MASKS[template_name]
		
		for steps in range(4): # 0, 90, 180, 270 degrees
			var rotated_base = rotate_mask(base_mask, steps)
			
			# Check if rotated mask matches required doors
			if (rotated_base & required_mask) == required_mask:
				return {
					"scene": room_scenes[template_name],
					"rotation": steps * 90.0,
					"type": template_name
				}
				
	# fallback to BASE template (contains all 4 doors)
	return {
		"scene": room_scenes["BASE"],
		"rotation": 0.0,
		"type": "BASE"
	}

# get_door_count
# get the number of doors in a room
func get_door_count(mask: int) -> int:
	var count = 0
	for i in range(4):
		if (mask & (1 << i)) != 0:
			count += 1
	return count

# transition_to_room
func transition_to_room(new_coords: Vector2i) -> void:
	print("Attempting transition to: ", new_coords, " | Exists in grid: ", grid.has(new_coords))
	
	if is_transitioning or not grid.has(new_coords):
		print("Transition blocked: No room exists at ", new_coords)
		return
		
	# check if entering the Boss Room requires key & 50+ kills
	var room_data = grid.get(new_coords, {})
	if room_data.get("type") == "BOSS":
		var player = get_tree().get_first_node_in_group("player")
		var has_key = player and player.has_dungeon_key
		var has_enough_kills = enemy_kill_count >= REQUIRED_KILLS
		
		if not (has_key and has_enough_kills):
			print("Boss door locked! Kills: ", enemy_kill_count, "/", REQUIRED_KILLS, " | Has Key: ", has_key)
			
			# optional: trigger dialogue warning if DialogueUI exists
			var dialogue_ui = get_node_or_null("/root/DialogueUI")
			if dialogue_ui and not dialogue_ui.is_active:
				dialogue_ui.start_dialogue("Protagonist", ["The door is sealed. I need the Dungeon Key and must defeat at least 50 corrupted entities first!"])
			return

	is_transitioning = true
	
	last_entry_direction = new_coords - current_room_coords
	
	if screen_fader and screen_fader.has_method("fade_out"):
		await screen_fader.fade_out(0.3)
	
	clear_active_projectiles()
	call_deferred("load_room", new_coords)
	
	if screen_fader and screen_fader.has_method("fade_in"):
		screen_fader.fade_in(0.3)

func load_room(coords: Vector2i) -> void:
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
		
	current_room_coords = coords
	var room_data = grid.get(coords, null)
	
	if room_data and room_data["scene"]:
		current_room_instance = room_data["scene"].instantiate()
		add_child(current_room_instance)
		
		# apply procedural rotation
		current_room_instance.rotation_degrees = room_data["rotation"]
		
		# instantiate or persist player
		if player_instance == null:
			player_instance = player_scene.instantiate()
			add_child(player_instance)
		
		# Pass entry direction into setup_room
		if current_room_instance.has_method("setup_room"):
			current_room_instance.setup_room(coords, room_data["type"], last_entry_direction)
			
	# track unique rooms visited
	if not visited_rooms.has(coords):
		visited_rooms.append(coords)
	
	update_camera_limits()
	room_changed.emit(coords)
	
	get_tree().create_timer(0.1).timeout.connect(func(): is_transitioning = false)

func update_camera_limits() -> void:
	if not player_instance or not current_room_instance:
		return
		
	var camera: Camera2D = player_instance.get_node_or_null("%Camera2D")
	if not camera:
		camera = player_instance.get_node_or_null("Camera2D")
		
	if camera and current_room_instance.has_method("get_bounds"):
		var bounds: Rect2 = current_room_instance.get_bounds()
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)
		camera.reset_smoothing()

func add_kill() -> void:
	enemy_kill_count += 1
	print("Enemies defeated: ", enemy_kill_count, "/", REQUIRED_KILLS)
	kill_count_changed.emit(enemy_kill_count, REQUIRED_KILLS)

func clear_active_projectiles() -> void:
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(proj):
			proj.queue_free()
	
	if screen_fader:
		screen_fader.fade_in(0.3)

func clear_current_dungeon() -> void:
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
		
		if player_instance:
			player_instance.queue_free()
			player_instance = null
