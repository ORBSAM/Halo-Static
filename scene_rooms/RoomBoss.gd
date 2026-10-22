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

# setup_room
# set up the room logic for the bosss; ensure the player enters correctly
# and the phases are executed correctly
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

	# play the boss music after the dialogue	
	AudioManager.play_music("boss")
	
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	_start_fight_loops()

# _boss_intro
# logic for handling the boss introduction; mainly focuses on the camera logic
# and the dialogue that plays
func _boss_intro(player: Node) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D") if player else null
	await get_tree().create_timer(0.4).timeout

	var base_zoom := cam.zoom if cam else Vector2.ONE
	if cam:
		var focus_zoom := base_zoom * 1.35
		var tw := create_tween().set_parallel(true)
		tw.tween_property(cam, "zoom", focus_zoom, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(cam, "offset",
			_focus_offset(player, boss.global_position, focus_zoom.x), 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished

	var dlg = get_node_or_null("/root/DialogueLogic")
	if dlg:
		var lines: Array = ["Ah... the intruder arrives.", "Your journey ends here!"]
		dlg.start_dialogue("Boss", lines, true)
		await dlg.dialogue_finished

	if cam:
		var back := create_tween().set_parallel(true)
		back.tween_property(cam, "zoom", base_zoom, 0.6)
		back.tween_property(cam, "offset", Vector2.ZERO, 0.6)
		await back.finished

# _focus_offset
# offset that centers the view on target_pos without the view leaving the room
func _focus_offset(player: Node2D, target_pos: Vector2, zoom_level: float) -> Vector2:
	var b := get_bounds()
	var half := get_viewport_rect().size / zoom_level / 2.0
	var lo := b.position + half
	var hi := b.end - half
	var c := target_pos
	c.x = (b.position.x + b.end.x) / 2.0 if lo.x > hi.x else clampf(c.x, lo.x, hi.x)
	c.y = (b.position.y + b.end.y) / 2.0 if lo.y > hi.y else clampf(c.y, lo.y, hi.y)
	return c - player.global_position

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
		var floor_items := get_tree().get_nodes_in_group("Items").filter(
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
	DungeonManager.game_won()

# let it spawn random enemies; but otherwise just skip it
func spawn_random_items() -> void: pass
func spawn_test_entities() -> void: pass
