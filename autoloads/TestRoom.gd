extends Node2D

const ROOM := preload("res://scene_rooms/Room_Base.tscn")
const PLAYER := preload("res://models/player_logic.tscn")

func _ready() -> void:
	var room = ROOM.instantiate()
	add_child(room)
	var player = PLAYER.instantiate()
	add_child(player)
	player.global_position = room.get_node("PlayerSpawn").global_position
