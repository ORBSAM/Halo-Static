extends Node2D

@export var boss_scene: PackedScene = preload("res://scene_rooms/Room_Boss.tscn")
@onready var boss_spawn: Marker2D = $Spawns/BossSpawn

@onready var top_left_marker: Marker2D = $TopLeftMarker
@onready var bottom_right_marker: Marker2D = $BottomRightMarker


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
