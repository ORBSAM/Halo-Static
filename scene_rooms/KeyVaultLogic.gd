extends Node2D

# ==========================================
# KEY VAULT ROOM LOGIC
# Specialized room for key drops, high-value loot, and custom dialogue.
# ==========================================

@export var enemy_scenes: Array[PackedScene] = [preload("res://models/enemy_logic.tscn")]
@export var item_scenes: Array[PackedScene] = [preload("res://items/item_harmonic_chaotic.tscn")]

@onready var player_spawn: Marker2D = $Spawns/PlayerSpawn
@onready var enemy_spawns: Node2D = $Spawns/EnemySpawns
@onready var item_spawns: Node2D = $Spawns/ItemSpawns
@onready var entities: Node2D = $Entities

@onready var door_west: Area2D = $Doors/DoorWest
@onready var door_east: Area2D = $Doors/DoorEast
@onready var door_north: Area2D = $Doors/DoorNorth
@onready var door_south: Area2D = $Doors/DoorSouth

@onready var top_left_marker: Marker2D = $TopLeftMarker
@onready var bottom_right_marker: Marker2D = $BottomRightMarker

func _ready() -> void:
	if get_tree().get_nodes_in_group("player").size() == 0:
		spawn_test_entities()

func setup_room(coords: Vector2i, room_type: String, entry_direction: Vector2i = Vector2i.ZERO) -> void:	
	update_doors(coords)
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		
		# reset movement physics
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		
		# reposition player based on entry side
		var spawn_pos = get_spawn_position_for_entry(entry_direction)
		player.global_position = spawn_pos
	
	spawn_guaranteed_key_and_loot()
	spawn_random_enemies()
	trigger_vault_dialogue()

func get_spawn_position_for_entry(entry_dir: Vector2i) -> Vector2:
	# If player moved NORTH into this room, spawn them at the SOUTH spawn point
	match entry_dir:
		Vector2i.UP:
			var node = get_node_or_null("Spawns/SpawnSouth")
			if node: return node.global_position
		Vector2i.DOWN:
			var node = get_node_or_null("Spawns/SpawnNorth")
			if node: return node.global_position
		Vector2i.RIGHT:
			var node = get_node_or_null("Spawns/SpawnWest")
			if node: return node.global_position
		Vector2i.LEFT:
			var node = get_node_or_null("Spawns/SpawnEast")
			if node: return node.global_position
			
	# Default fallback marker
	var default_spawn = get_node_or_null("Spawns/PlayerSpawn")
	return default_spawn.global_position if default_spawn else global_position

# Transform local door positions into global grid directions based on room rotation
func update_doors(coords: Vector2i) -> void:
	if DungeonManager == null:
		return

	var door_map = {
		door_north: Vector2i.UP,
		door_east: Vector2i.RIGHT,
		door_south: Vector2i.DOWN,
		door_west: Vector2i.LEFT
	}

	for door in door_map.keys():
		if not door:
			continue
			
		# Account for room rotation (0, 90, 180, 270)
		var local_dir: Vector2i = door_map[door]
		var rotated_dir = rotate_grid_direction(local_dir, int(rotation_degrees))
		var neighbor_coords = coords + rotated_dir
		
		var has_neighbor = DungeonManager.grid.has(neighbor_coords)
		door.visible = has_neighbor
		door.set_deferred("monitoring", has_neighbor)

# Rotate a grid vector by degree steps
func rotate_grid_direction(dir: Vector2i, degrees: int) -> Vector2i:
	var steps = int(round(degrees / 90.0)) % 4
	if steps < 0:
		steps += 4
		
	var current = dir
	for i in range(steps):
		# Clockwise rotation: (x, y) -> (-y, x)
		current = Vector2i(-current.y, current.x)
	return current

# Handle door transitions considering rotation
func handle_door_transition(door_node: Area2D, local_dir: Vector2i) -> void:
	door_node.set_deferred("monitoring", false)
	var rotated_dir = rotate_grid_direction(local_dir, int(rotation_degrees))
	var target_coords = DungeonManager.current_room_coords + rotated_dir
	
	if DungeonManager and DungeonManager.has_method("transition_to_room"):
		DungeonManager.transition_to_room(target_coords)

func _on_door_west_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_door_transition(door_west, Vector2i.LEFT)
		var target_coords = DungeonManager.current_room_coords + Vector2i.LEFT
		DungeonManager.transition_to_room(target_coords)
		
func _on_door_east_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_door_transition(door_east, Vector2i.RIGHT)
		var target_coords = DungeonManager.current_room_coords + Vector2i.RIGHT
		DungeonManager.transition_to_room(target_coords)

func _on_door_north_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_door_transition(door_north, Vector2i.UP)
		var target_coords = DungeonManager.current_room_coords + Vector2i.UP
		DungeonManager.transition_to_room(target_coords)

func _on_door_south_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_door_transition(door_south, Vector2i.DOWN)
		var target_coords = DungeonManager.current_room_coords + Vector2i.DOWN
		DungeonManager.transition_to_room(target_coords)

# Key Vault specific item spawning: Guarantees 1 Key + Harmonic items
func spawn_guaranteed_key_and_loot() -> void:
	if item_scenes.is_empty() or not item_spawns:
		return
		
	var markers = item_spawns.get_children()
	if markers.is_empty():
		return
		
	# 1. Spawn guaranteed key at first marker
	var key_scene = item_scenes.pick_random()
	if key_scene:
		var key_item = key_scene.instantiate()
		key_item.global_position = markers[0].global_position
		key_item.item_type = Item.ItemType.KEY
		add_child(key_item)
		if key_item.has_method("update_item_appearance"):
			key_item.update_item_appearance()

	# 2. Spawn bonus loot (Harmonic Shards) at remaining markers
	for i in range(1, markers.size()):
		var item_scene = item_scenes.pick_random()
		if item_scene:
			var loot = item_scene.instantiate()
			loot.global_position = markers[i].global_position
			loot.item_type = Item.ItemType.HARMONIC
			add_child(loot)
			if loot.has_method("update_item_appearance"):
				loot.update_item_appearance()

func spawn_random_enemies() -> void:
	if enemy_scenes.is_empty() or not enemy_spawns:
		return
		
	for marker in enemy_spawns.get_children():
		var enemy_scene = enemy_scenes.pick_random()
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = marker.global_position
			add_child(enemy)

func spawn_test_entities() -> void:
	spawn_guaranteed_key_and_loot()
	spawn_random_enemies()

# key Vault specific entry dialogue
func trigger_vault_dialogue() -> void:
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if not dialogue_ui or dialogue_ui.is_active:
		return

	var vault_lines = [
		"This vault... it resonates with intense harmonic frequency.",
		"I should search for the key to the main chamber here."
	]
	dialogue_ui.start_dialogue("Protagonist", vault_lines)

func get_bounds() -> Rect2:
	if top_left_marker and bottom_right_marker:
		var top_left = top_left_marker.global_position
		var bottom_right = bottom_right_marker.global_position
		return Rect2(top_left, bottom_right - top_left)
	else:
		push_warning("Camera markers missing on Key Vault! Falling back to default bounds.")
		return Rect2(Vector2.ZERO, Vector2(1152, 648))
