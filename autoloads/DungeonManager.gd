extends Node

# ==========================================
# DUNGEON MANAGER (AUTOLOAD SINGLETON)
# Manages 20-room generation, grid state, and scene loading.
# ==========================================

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 5
const TOTAL_ROOMS: int = 20
 
@export var room_scenes: Array[PackedScene] = [
	preload("res://scene_rooms/Room_Base.tscn")
]
@export var player_scene: PackedScene = preload("res://models/player_logic.tscn")
var player_instance: Node2D = null

var hud_instance: CanvasLayer = null

@export var boss_room_scene: PackedScene
@export var screen_fader: CanvasLayer

var grid: Dictionary = {} # Vector2i -> Room Instance / Data
var current_room_coords: Vector2i = Vector2i.ZERO
var current_room_instance: Node2D = null

# are we transitioning?
var is_transitioning: bool = false

signal room_changed(coords: Vector2i)


func _ready() -> void:
	pass	
	
func start_new_game() -> void:
	# 1. instantly remove the title screen / current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.queue_free() # Schedule for cleanup
		current_scene.get_parent().remove_child(current_scene) # Remove from tree IMMEDIATELY so it stops rendering!
		get_tree().current_scene = null

	# 2. re-enable and display the HUD overlay
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	elif has_node("/root/HUD_overlay"):
		get_node("/root/HUD_overlay").show()

	# 3. build layout and load starting room (0,0)
	generate_dungeon_layout()
	load_room(Vector2i.ZERO)

func generate_dungeon_layout() -> void:
	grid.clear()
	
	# sequentially create room coordinates from (0,0) to (TOTAL_ROOMS - 1, 0)
	for x in range(TOTAL_ROOMS):
		var pos = Vector2i(x, 0)
		var room_idx = randi() % max(1, room_scenes.size())
		grid[pos] = room_idx

func transition_to_room(new_coords: Vector2i) -> void:
	print("Attempting transition to: ", new_coords, " | Exists in grid: ", grid.has(new_coords))
	
	if is_transitioning or not grid.has(new_coords):
		print("Transition blocked: No room exists at ", new_coords)
		return
		
	is_transitioning = true
		
	if screen_fader:
		await screen_fader.fade_out(0.3)
	
	# defer load_room so physics finishes flushing before scenes swap
	call_deferred("load_room", new_coords)
	
	if screen_fader:
		screen_fader.fade_in(0.3)

func load_room(coords: Vector2i) -> void:
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
		
	current_room_coords = coords
	var room_index = grid.get(coords, 0)
	
	if room_scenes.size() > 0:
		current_room_instance = room_scenes[room_index].instantiate()
		add_child(current_room_instance)
		
		# ensure a single persistent player exists
		if player_instance == null:
			player_instance = player_scene.instantiate()
			add_child(player_instance)
		
		# call setup_room ONCE after the room and player exist
		if current_room_instance.has_method("setup_room"):
			current_room_instance.setup_room(coords, "regular")
			 
	update_camera_limits()

	# emit signal to notify HUD/UI
	room_changed.emit(coords)
	
	get_tree().create_timer(0.1).timeout.connect(func(): is_transitioning = false)
	
func update_camera_limits() -> void:
	if not player_instance or not current_room_instance:
		return
		  
	var camera: Camera2D = player_instance.get_node_or_null("%Camera2D")
	
	if not camera:
		print("No camera found!")
		return
		
	if current_room_instance.has_method("get_bounds"):
		var bounds: Rect2 = current_room_instance.get_bounds()
		
		# set limits directly from marker positionsa 
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)
		
		# force camera to update position immediately to new bounds
		camera.reset_smoothing()
	
func clear_current_dungeon() -> void:
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
		
		if player_instance:
			player_instance.queue_free()
			player_instance = null

func clear_active_projectiles() -> void:
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(proj):
			proj.queue_free()
