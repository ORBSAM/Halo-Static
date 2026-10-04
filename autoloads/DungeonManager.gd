extends Node

# ==========================================
# DUNGEON MANAGER (AUTOLOAD SINGLETON)
# Manages 30-room generation, grid state, and scene loading.
# ==========================================

const GRID_WIDTH: int = 6
const GRID_HEIGHT: int = 5
const TOTAL_ROOMS: int = 30

@export var room_scenes: Array[PackedScene] = [] # assign room variations in Inspector
@export var screen_fader: CanvasLayer

var grid: Dictionary = {} # Vector2i -> Room Instance / Data
var current_room_coords: Vector2i = Vector2i.ZERO
var current_room_instance: Node2D = null


func _ready() -> void:
	generate_dungeon_layout()
	load_room(Vector2i.ZERO)

func generate_dungeon_layout() -> void:
	var count = 0
	var current_pos = Vector2i.ZERO
	grid[current_pos] = 0 # starting room index
	count += 1
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	while count < TOTAL_ROOMS:
		var dir = directions.pick_random()
		var next_pos = current_pos + dir
		
		# keep within boundaries
		if next_pos.x >= 0 and next_pos.x < GRID_WIDTH and next_pos.y >= 0 and next_pos.y < GRID_HEIGHT:
			if not grid.has(next_pos):
				grid[next_pos] = randi() % max(1, room_scenes.size())
				count += 1
			current_pos = next_pos

func transition_to_room(new_coords: Vector2i) -> void:
	if not grid.has(new_coords):
		return
		
	if screen_fader:
		await screen_fader.fade_out(0.3)
	
	load_room(new_coords)
	
	if screen_fader:
		screen_fader.fade_in(0.3)

func load_room(coords: Vector2i) -> void:
	if current_room_instance:
		current_room_instance.queue_free()
		
	current_room_coords = coords
	var room_index = grid.get(coords, 0)
	
	if room_scenes.size() > 0:
		current_room_instance = room_scenes[room_index].instantiate()
		add_child(current_room_instance)
