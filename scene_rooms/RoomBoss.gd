extends RoomLogic

@export var boss_scene: PackedScene = preload("res://models/boss_logic.tscn")
@onready var boss_spawn: Marker2D = $Spawns/BossSpawn

func setup_room(coords: Vector2i, room_type: String, entry_direction: Vector2i = Vector2i.ZERO) -> void:
	update_doors(coords)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		player.global_position = get_spawn_position_for_entry(entry_direction)

	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = boss_spawn.global_position
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)

	await get_tree().create_timer(0.5).timeout
	var dialogue_ui = get_node_or_null("/root/DialogueLogic")
	if dialogue_ui:
		var lines: Array = ["Ah... the intruder arrives.", "Your journey ends here!"]
		dialogue_ui.start_dialogue("Boss", lines, true)

func _on_boss_defeated() -> void:
	get_tree().change_scene_to_file("res://screens/win_splash.tscn")

func spawn_random_enemies() -> void: pass   # no ambient enemies in the boss room
func spawn_random_items() -> void: pass
func spawn_test_entities() -> void: pass
