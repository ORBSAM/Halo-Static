extends RoomLogic

@export var boss_scene: PackedScene = preload("res://models/boss_logic.tscn")
@onready var boss_spawn: Marker2D = $Spawns/BossSpawn

@export var add_interval: float = 8.0
@export var max_adds: int = 4
@export var item_interval: float = 12.0
@export var max_floor_items: int = 2

var boss: Node = null
var _adds: Array = []
var _fighting: bool = false

func setup_room(coords: Vector2i, room_type: String, entry_direction: Vector2i = Vector2i.ZERO) -> void:
	update_doors(coords)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		player.global_position = get_spawn_position_for_entry(entry_direction)

	boss = boss_scene.instantiate()
	boss.process_mode = Node.PROCESS_MODE_DISABLED     # frozen until the intro ends
	add_child(boss)
	boss.global_position = boss_spawn.global_position
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)

	await _boss_intro(player)

	boss.process_mode = Node.PROCESS_MODE_INHERIT
	_start_fight_loops()

func _boss_intro(player: Node) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D") if player else null
	await get_tree().create_timer(0.4).timeout

	if cam:
		var tw := create_tween()
		tw.tween_property(cam, "offset", boss.global_position - player.global_position, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished

	var dlg = get_node_or_null("/root/DialogueLogic")
	if dlg:
		var lines: Array = ["Ah... the intruder arrives.", "Your journey ends here!"]
		dlg.start_dialogue("Boss", lines, true)
		await dlg.dialogue_finished

	if cam:
		var back := create_tween()
		back.tween_property(cam, "offset", Vector2.ZERO, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await back.finished

func _start_fight_loops() -> void:
	_fighting = true
	_loop_adds()
	_loop_items()

func _loop_adds() -> void:
	while _fighting and is_inside_tree():
		await get_tree().create_timer(add_interval).timeout
		if not _fighting or not is_inside_tree():
			return
		_adds = _adds.filter(func(e): return is_instance_valid(e))
		if _adds.size() >= max_adds or enemy_scenes.is_empty():
			continue
		var enemy = enemy_scenes.pick_random().instantiate()
		add_child(enemy)
		enemy.global_position = _random_point(48.0)
		_adds.append(enemy)

func _loop_items() -> void:
	while _fighting and is_inside_tree():
		await get_tree().create_timer(item_interval).timeout
		if not _fighting or not is_inside_tree() or item_scenes.is_empty():
			continue
		var floor_items := get_tree().get_nodes_in_group("items").filter(
			func(i): return is_instance_valid(i) and i.item_type == Item.ItemType.HARMONIC)
		if floor_items.size() >= max_floor_items:
			continue
		var item = item_scenes.pick_random().instantiate()
		item.item_type = Item.ItemType.HARMONIC       # boss room only ever drops good items
		add_child(item)
		item.global_position = _random_point(64.0)
		if item.has_method("update_item_appearance"):
			item.update_item_appearance()

func _random_point(inset: float) -> Vector2:
	var a := top_left_marker.global_position
	var b := bottom_right_marker.global_position
	return Vector2(randf_range(a.x + inset, b.x - inset), randf_range(a.y + inset, b.y - inset))

func _on_boss_defeated() -> void:
	_fighting = false
	get_tree().change_scene_to_file("res://screens/win_splash.tscn")

func spawn_random_enemies() -> void: pass
func spawn_random_items() -> void: pass
func spawn_test_entities() -> void: pass
