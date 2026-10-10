extends Node2D

@export var boss_scene: PackedScene = preload("res://scene_rooms/Room_Boss.tscn")
@onready var boss_spawn: Marker2D = $Spawns/BossSpawn

func setup_room(coords: Vector2i, room_type: String) -> void:
	# Spawn boss
	if boss_scene and boss_spawn:
		var boss = boss_scene.instantiate()
		boss.global_position = boss_spawn.global_position
		add_child(boss)
		
		if boss.has_signal("boss_defeated"):
			boss.boss_defeated.connect(_on_boss_defeated)

	# trigger Boss Dialogue
	if has_node("/root/DialogueUI"):
		get_node("/root/DialogueUI").start_dialogue("Boss", [
			"Ah... the intruder arrives.",
			"Your journey ends here!"
		])

func _on_boss_defeated() -> void:
	print("Boss Defeated!")
	# Transition to Game Complete / Cliffhanger scene
	get_tree().change_scene_to_file("res://scenes/GameComplete.tscn")
