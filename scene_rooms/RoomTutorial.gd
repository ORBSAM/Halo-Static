extends RoomLogic

@export var overlay_scene: PackedScene   # optional if the overlay is already a child
var overlay: Node = null
var _enemies: Array = []

func _ready() -> void:
	super()    # RoomLogic._ready builds the boundary walls

	var doors := get_node_or_null("Doors")
	if doors:
		for d in doors.get_children():
			if d is Area2D:
				d.set_deferred("monitoring", false)
				d.hide()

	overlay = get_node_or_null("TutorialUI")
	if overlay == null and overlay_scene:
		overlay = overlay_scene.instantiate()
		add_child(overlay)

func setup_room(_coords: Vector2i, _room_type: String, _entry: Vector2i = Vector2i.ZERO) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player_spawn:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		player.global_position = player_spawn.global_position
		print("tutorial spawn at ", player_spawn.global_position)

	_spawn_tutorial_enemies()
	spawn_random_items()   # overridden below: good items only

	await get_tree().create_timer(0.6).timeout

	if overlay:
		await overlay.play()          # walkthrough; player can move, enemies frozen
	else:
		push_error("TutorialRoom: no TutorialOverlay found (add it as a child or set overlay_scene)")

	for e in _enemies:                # the practice fight starts now
		if is_instance_valid(e):
			e.set_physics_process(true)

	if overlay:
		await overlay.leave_requested  # player presses Esc when ready
	else:
		await get_tree().create_timer(3.0).timeout

	DungeonManager.finish_tutorial()

func _spawn_tutorial_enemies() -> void:
	if enemy_scenes.is_empty():
		return
	var markers: Array = enemy_spawns.get_children() if enemy_spawns else []
	var center := (top_left_marker.global_position + bottom_right_marker.global_position) / 2.0
	for i in range(2):
		var e = enemy_scenes[0].instantiate()
		e.set("max_power_stacks", 0)   # tutorial enemies never eat items
		add_child(e)
		e.global_position = markers[i].global_position if i < markers.size() \
			else center + Vector2(80.0 * (i * 2 - 1), 0.0)
		e.set_physics_process(false)   # frozen; the player can still move
		_enemies.append(e)

# good items only, one per item marker
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
