extends Node2D

@export var enemy_scenes: Array[PackedScene] = [preload("res://models/enemy_logic.tscn")]
@export var item_scenes: Array[PackedScene] = [preload("res://items/item_harmonic_chaotic.tscn")]

@onready var player_spawn: Marker2D = $Spawns/PlayerSpawn
@onready var enemy_spawns: Node2D = $Spawns/EnemySpawns
@onready var item_spawns: Node2D = $Spawns/ItemSpawns
@onready var entities: Node2D = $Entities

@onready var door_west: Area2D = $Doors/DoorWest
@onready var door_east: Area2D = $Doors/DoorEast

@onready var top_left_marker: Marker2D = $TopLeftMarker
@onready var bottom_right_marker: Marker2D = $BottomRightMarker

# _ready
func _ready() -> void:
	# if running this room directly (F6 testing), spawn placeholders automatically
	if get_tree().get_nodes_in_group("player").size() == 0:
		spawn_test_entities()

# setup_room
func setup_room(coords: Vector2i, room_type: String) -> void:
	update_doors(coords)
	
	# reposition player to spawn marker upon entering
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and player_spawn:
		var player = players[0]

		# 1. reset velocity so gravity accumulated during transition doesn't pull down
		if "velocity" in player:
			player.velocity = Vector2.ZERO

		# 2. update global position
		player.global_position = player_spawn.global_position
	
	spawn_random_enemies()
	spawn_random_items()
	
func update_doors(coords: Vector2i) -> void:
	if DungeonManager == null:
		return
		
	var has_west_room = DungeonManager.grid.has(coords + Vector2i.LEFT)
	var has_east_room = DungeonManager.grid.has(coords + Vector2i.RIGHT)
	
	if door_west:
		door_west.visible = has_west_room
		door_west.set_deferred("monitoring", has_west_room)
		
	if door_east:
		door_east.visible = has_east_room
		door_east.set_deferred("monitoring", has_east_room)

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
		
	var markers = $Spawns/ItemSpawns.get_children() if has_node("ItemMarkers") else []
	for marker in markers:
		var item_scene = item_scenes.pick_random()
		if item_scene:
			var item = item_scene.instantiate()
			item.global_position = marker.global_position
			add_child(item)

# spawn_test_entities
func spawn_test_entities() -> void:
	# Fallback for standalone F6 testing
	spawn_random_enemies()
	spawn_random_items()

# _on_door_west_body_entered
func _on_door_west_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_west.set_deferred("monitoring", false)
		if DungeonManager and DungeonManager.has_method("transition_to_room"):
			DungeonManager.transition_to_room(DungeonManager.current_room_coords + Vector2i.LEFT)

# _on_door_east_body_entered
func _on_door_east_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_east.set_deferred("monitoring", false) # prevents spam
		var target_coords = DungeonManager.current_room_coords + Vector2i.RIGHT
		if DungeonManager and DungeonManager.has_method("transition_to_room"):
			DungeonManager.transition_to_room(target_coords)

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
