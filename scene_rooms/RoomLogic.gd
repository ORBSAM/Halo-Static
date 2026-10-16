extends Node2D

# =====================
# ROOM LOGIC
# 
# All room logic for base rooms are stored here. Other instances such as the boss room and the key room may be different.
# ================

@export var enemy_scenes: Array[PackedScene] = [preload("res://models/enemy_logic.tscn")]
@export var item_scenes: Array[PackedScene] = [preload("res://items/item_harmonic_chaotic.tscn")]

@onready var player_spawn: Marker2D = $Spawns/PlayerSpawn
@onready var enemy_spawns: Node2D = $Spawns/EnemySpawns
@onready var item_spawns: Node2D = $Spawns/ItemSpawns
@onready var entities: Node2D = $Entities

# not every room will have these doors, so make it "get_node_or_null"
@onready var door_west: Area2D = get_node_or_null("Doors/DoorWest")
@onready var door_east: Area2D = get_node_or_null("Doors/DoorEast")
@onready var door_north: Area2D = get_node_or_null("Doors/DoorNorth")
@onready var door_south: Area2D = get_node_or_null("Doors/DoorSouth")

@onready var top_left_marker: Marker2D = $TopLeftMarker
@onready var bottom_right_marker: Marker2D = $BottomRightMarker

# _ready
func _ready() -> void:
	# if running this room directly (F6 testing), spawn placeholders automatically
	if get_tree().get_nodes_in_group("player").size() == 0:
		spawn_test_entities()

# setup_room
func setup_room(coords: Vector2i, room_type: String, entry_direction: Vector2i = Vector2i.ZERO) -> void:	
	update_doors(coords)
	
	# reposition player to spawn marker upon entering
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and player_spawn:
		var player = players[0]

		# 1. reset velocity so gravity accumulated during transition doesn't pull down
		if "velocity" in player:
			player.velocity = Vector2.ZERO

		# 2. update global position
		var spawn_pos = get_spawn_position_for_entry(entry_direction)
		player.global_position = spawn_pos
	
	spawn_random_enemies()
	spawn_random_items()

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
			
	# default fallback marker
	var default_spawn = get_node_or_null("Spawns/PlayerSpawn")
	return default_spawn.global_position if default_spawn else global_position
	
func update_doors(coords: Vector2i) -> void:
	var open := {
		door_west:  DungeonManager.grid.has(coords + Vector2i.LEFT),
		door_east:  DungeonManager.grid.has(coords + Vector2i.RIGHT),
		door_north: DungeonManager.grid.has(coords + Vector2i.UP),
		door_south: DungeonManager.grid.has(coords + Vector2i.DOWN),
	}
	# everything off first
	for door in open.keys():
		if door:
			door.visible = open[door]
			door.set_deferred("monitoring", false)

	# re-enable after the player has been placed and had time to walk off the spawn
	await get_tree().create_timer(0.4).timeout
	for door in open.keys():
		if door and open[door]:
			door.monitoring = true

func spawn_random_enemies() -> void:
	if enemy_scenes.is_empty():
		return
		
	# find all Marker2D nodes in EnemySpawns
	var markers = $Spawns/EnemySpawns.get_children()
	for marker in markers:
		var enemy_scene = enemy_scenes.pick_random()
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = marker.global_position
			add_child(enemy)

func spawn_random_items() -> void:
	if item_scenes.is_empty():
		return
		
	var markers = $Spawns/ItemSpawns.get_children()  
	for marker in markers:
		# 30% chance to spawn an item at each marker
		if randf() > 0.3:
			continue
			
		# inside spawn_random_items() in Room_Base.gd:
		var item_scene = item_scenes.pick_random()
		if item_scene:
			var item = item_scene.instantiate()
			item.global_position = marker.global_position
	
			# determine type directly
			var rand_val = randf()
			if rand_val < 0.6:
				item.item_type = Item.ItemType.HARMONIC
			else:
				item.item_type = Item.ItemType.CHAOTIC
  
			# add to scene tree
			add_child(item)
	
			# force visual refresh after entering tree
			if item.has_method("update_item_appearance"):
				item.update_item_appearance()

# spawn_test_entities
func spawn_test_entities() -> void:
	# fallback for standalone F6 testing
	spawn_random_enemies()
	spawn_random_items()

# ==========================================
# CARDINAL DOOR TRANSITIONS
# ==========================================

# _on_door_west_body_entered
# when you enter the western door, go "down" one on the X-axis
func _on_door_west_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_west.set_deferred("monitoring", false)
		if DungeonManager and DungeonManager.has_method("transition_to_room"):
			DungeonManager.transition_to_room(DungeonManager.current_room_coords + Vector2i.LEFT)

# _on_door_east_body_entered
# when you enter an eastern door, go up one on the X-axis
func _on_door_east_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_east.set_deferred("monitoring", false) # prevents spam
		var target_coords = DungeonManager.current_room_coords + Vector2i.RIGHT
		if DungeonManager and DungeonManager.has_method("transition_to_room"):
			DungeonManager.transition_to_room(target_coords)
			
# _on_door_north_body_entered
# when you enter a northern door, go up one on the Y-axis
func _on_door_north_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_north.set_deferred("monitoring", false)
		DungeonManager.transition_to_room(DungeonManager.current_room_coords + Vector2i.UP)

# _on_door_south_body_entered
# when you enter a southern door, go down one on the Y-axis
func _on_door_south_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_south.set_deferred("monitoring", false)
		DungeonManager.transition_to_room(DungeonManager.current_room_coords + Vector2i.DOWN)

# trigger_room_dialogue
# Trigger a random snippet of dialogue whenever the protagonist enters a room.
# Slim chance of this happening.
func trigger_room_dialogue(is_boss_room: bool = false) -> void:
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if not dialogue_ui or dialogue_ui.is_active:
		return

	if is_boss_room:
		dialogue_ui.start_dialogue("Boss", ["You made it far, hero...", "This room will be your grave!"])
	else:
		# 30% chance on entering a regular room
		if randf() < 0.3:
			var random_quotes = [
				"Something feels off in this sector...",
				"The harmonic energy here is unstable.",
				"I need to keep moving."
			]
			dialogue_ui.start_dialogue("Protagonist", [random_quotes.pick_random()])

# get_bounds
# set the bounds for the current room (using the walls), which will later be called by the dungeon manager to set up the camera
# 
func get_bounds() -> Rect2:
	if top_left_marker and bottom_right_marker:
		var top_left = top_left_marker.global_position
		var bottom_right = bottom_right_marker.global_position
		
		var width = bottom_right.x - top_left.x
		var height = bottom_right.y - top_left.y
		
		return Rect2(top_left, Vector2(width, height))
	else:
		push_warning("Camera markers missing on room! Falling back to default bounds.")
		return Rect2(Vector2.ZERO, Vector2(1152, 648))
