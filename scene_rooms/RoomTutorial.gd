extends RoomLogic

@export var practice_fight: bool = true   # false = leave right after the overlays
@onready var overlay = get_node_or_null("TutorialOverlay")

var _enemies: Array = []

func _ready() -> void:
	# runs after RoomLogic._ready. Doors do nothing in the tutorial.
	var doors := get_node_or_null("Doors")
	if doors:
		for d in doors.get_children():
			if d is Area2D:
				d.set_deferred("monitoring", false)
				d.hide()

func setup_room(_coords: Vector2i, _room_type: String, _entry: Vector2i = Vector2i.ZERO) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player_spawn:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		player.global_position = player_spawn.global_position
		print("tutorial spawn at ", player_spawn.global_position)

	_spawn_tutorial_enemies()
	spawn_random_items()                  # overridden below: good items only

	await get_tree().create_timer(0.6).timeout
	if overlay:
		overlay.play()
		await overlay.finished

	for e in _enemies:
		if is_instance_valid(e):
			e.set_physics_process(true)   # the fight starts now
	if practice_fight:
		await _wait_for_enemies_dead()

	DungeonManager.finish_tutorial()

func _spawn_tutorial_enemies() -> void:
	if enemy_scenes.is_empty():
		return
	var markers: Array = enemy_spawns.get_children() if enemy_spawns else []
	var center := (top_left_marker.global_position + bottom_right_marker.global_position) / 2.0
	for i in range(2):                    # exactly two
		var e = enemy_scenes[0].instantiate()
		add_child(e)
		e.global_position = markers[i].global_position if i < markers.size() \
			else center + Vector2(80.0 * (i * 2 - 1), 0.0)
		e.set_physics_process(false)      # frozen, but the player can still move
		_enemies.append(e)

func _wait_for_enemies_dead() -> void:
	while true:
		_enemies = _enemies.filter(func(e): return is_instance_valid(e) and e.get("is_dead") != true)
		if _enemies.is_empty():
			return
		await get_tree().create_timer(0.25).timeout

# good items only, one at every item marker
func spawn_random_items() -> void:
	if item_scenes.is_empty() or not item_spawns:
		return
	for marker in item_spawns.get_children():
		var item = item_scenes.pick_random().instantiate()
		item.item_type = Item.ItemType.HARMONIC
		add_child(item)
		item.global_position = marker.global_position
		if item.has_method("update_item_appearance"):
			item.update_item_appearance()

func spawn_random_enemies() -> void: pass
func spawn_test_entities() -> void: pass
