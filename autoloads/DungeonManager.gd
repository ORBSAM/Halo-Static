extends Node

# ==========================================
# DUNGEON MANAGER (AUTOLOAD SINGLETON)
# Manages 20-room generation, grid state, and scene loading.
# ==========================================

const GRID_RADIUS: int = 2                 # -2..2 = 5x5, start (0,0) is the center
const BOSS_POS := Vector2i(0, -3)          # hangs off the top-middle room
var vault_pos: Vector2i = Vector2i(1, 1)   # replaces the VAULT_POS const

# kill tracking & Boss requirements
var enemy_kill_count: int = 0
const REQUIRED_KILLS: int = 50

# store visited rooms
var visited_rooms: Array[Vector2i] = []

# door direction flags
enum DoorFlags {
	NORTH = 1,
	EAST = 2,
	SOUTH = 4,
	WEST = 8
}

const N = DoorFlags.NORTH
const E = DoorFlags.EAST
const S = DoorFlags.SOUTH
const W = DoorFlags.WEST

const BASE_SCENE = preload("res://scene_rooms/Room_Base.tscn")
const BOSS_SCENE = preload("res://scene_rooms/Room_Boss.tscn")
const VAULT_SCENE = preload("res://scene_rooms/Room_KeyVault.tscn")
const TUTORIAL_SCENE = preload("res://scene_rooms/Room_Tutorial.tscn")

# three primary cutscenes; all here for debug
const DEFEAT_SCENE := "res://screens/lose_splash.tscn"
const WIN_SCENE := "res://screens/win_splash.tscn"
const CLIFFHANGER_SCENE := "res://screens/cliffhanger.tscn" 

var tutorial_shown: bool = false    # session-only: resets when the game closes
var in_tutorial: bool = false

var can_pause: bool = false   # true only while a real run is in progress


# mask -> scene; add variants as you make them
var room_by_mask: Dictionary = {
	# all sides
	N|E|S|W: preload("res://scene_rooms/Room_Base.tscn"),
	N|E:     preload("res://scene_rooms/Room_Base_BL.tscn"),   # bottom-left-ish corner
	S|E:     preload("res://scene_rooms/Room_Base_TC.tscn"),   # top-left corner
	S|W:     preload("res://scene_rooms/Room_Base_TR.tscn"),   # top-right
	N|W:     preload("res://scene_rooms/Room_Base_BR.tscn"),   # bottom-right
	# side rooms
	# left / right edges (Side_X)
	N|S|E: preload("res://scene_rooms/Room_Base_X_L.tscn"),  # left edge, no west door
	N|S|W: preload("res://scene_rooms/Room_Base_X_R.tscn"),  # right edge, no east door
	# top / bottom edges (Side_Y)
	E|S|W: preload("res://scene_rooms/Room_Base_Y_T.tscn"),  # top edge, no north door
	N|E|W: preload("res://scene_rooms/Room_Base_Y_B.tscn"),  # bottom edge, no south door
	
	# ... N|S|E, E|S|W, N|E|W, N|S, E|W, and single-door ends
}

# debug for boss inside of the actual dungeon manager
@export var debug_skip_boss_lock: bool = false   # tick this in the inspector while testing

@export var player_scene: PackedScene = preload("res://models/player_logic.tscn")
var player_instance: Node2D = null

var hud_instance: CanvasLayer = null

# @export var boss_room_scene: PackedScene
@export var screen_fader: CanvasLayer

# shader logic
const DARK_SHADER = preload("res://screens/screen_shaders/DungeonDark.gdshader")
const AMBIENT_DEFAULT := Color(0.28, 0.26, 0.38)   # lower = darker

var ambient: CanvasModulate
var dark_layer: CanvasLayer
var dark_rect: ColorRect

# grid stores RoomData:w		 { "scene": PackedScene, "rotation": float, "type": String }
var grid: Dictionary = {}
var current_room_coords: Vector2i = Vector2i.ZERO
var current_room_instance: Node2D = null

var last_entry_direction: Vector2i = Vector2i.ZERO

# are we transitioning?
var is_transitioning: bool = false
# did the room change?
signal room_changed(coords: Vector2i)
# did we kill an enemy?
signal kill_count_changed(current: int, required: int)

# _ready
# let the main menu handle this with start_new_game
func _ready() -> void:
	_build_atmosphere()	
	
# start_new_game
func start_new_game() -> void:
	AudioManager.play_music("dungeon")
	enemy_kill_count = 0
	
	visited_rooms.clear()
	last_entry_direction = Vector2i.ZERO # ensures starting room uses PlayerSpawn!
	# make sure any transitioning logic is disabled
	is_transitioning = false
	
	# restart the player instance, so it's fresh.
	if player_instance:
		remove_child(player_instance)
		player_instance.queue_free()
		player_instance = null
	
	# 1. instantly remove the title screen / current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.queue_free() # schedule for cleanup
		current_scene.get_parent().remove_child(current_scene) # remove from tree IMMEDIATELY so it stops rendering!
		get_tree().current_scene = null
	
	# 2. re-enable and display the HUD overlay
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	elif has_node("/root/HUD_overlay"):
		get_node("/root/HUD_overlay").show()

	set_atmosphere(true)

	# 3. build layout and load starting room (0,0)
	# but first, go to the tutorial room if we have not already
	generate_dungeon_layout()
	if not tutorial_shown:
		tutorial_shown = true
		load_tutorial_room()
	else:
		load_room(Vector2i.ZERO)
	can_pause = true
	
# generate_dungeon_layout
# Generate 2D Layout and Match Templates with Rotations
func generate_dungeon_layout() -> void:
	grid.clear()

	# random interior cell (4 neighbors), never the start room
	var interior: Array[Vector2i] = []
	for x in range(-GRID_RADIUS + 1, GRID_RADIUS):
		for y in range(-GRID_RADIUS + 1, GRID_RADIUS):
			if Vector2i(x, y) != Vector2i.ZERO:
				interior.append(Vector2i(x, y))
	vault_pos = interior.pick_random()
	
	var positions: Array[Vector2i] = []
	for x in range(-GRID_RADIUS, GRID_RADIUS + 1):
		for y in range(-GRID_RADIUS, GRID_RADIUS + 1):
			positions.append(Vector2i(x, y))
	positions.append(BOSS_POS)          # no vault append anymore

	for pos in positions:
		var mask := 0
		if positions.has(pos + Vector2i.UP):    mask |= N
		if positions.has(pos + Vector2i.RIGHT): mask |= E
		if positions.has(pos + Vector2i.DOWN):  mask |= S
		if positions.has(pos + Vector2i.LEFT):  mask |= W

		var kind := "NORMAL"
		if pos == BOSS_POS:    kind = "BOSS"
		elif pos == vault_pos: kind = "VAULT"
		grid[pos] = make_room(mask, kind)

# load_tutorial_room
# load the tutorial room if player has never seen it
func load_tutorial_room() -> void:
	in_tutorial = true

	is_transitioning = true
	current_room_coords = Vector2i.ZERO
	current_room_instance = TUTORIAL_SCENE.instantiate()
	add_child(current_room_instance)
	if player_instance == null:
		player_instance = player_scene.instantiate()
		add_child(player_instance)
	current_room_instance.setup_room(Vector2i.ZERO, "TUTORIAL", Vector2i.ZERO)
	update_camera_limits()
	get_tree().create_timer(0.1).timeout.connect(func(): is_transitioning = false)

# finish_tutorial
# finish tutorial and transition to the first base room
func finish_tutorial() -> void:
	in_tutorial = false
	
	if is_transitioning:
		return
	is_transitioning = true
	
	if screen_fader and screen_fader.has_method("fade_out"):
		await screen_fader.fade_out(0.4)
	await get_tree().process_frame        # get out of any physics callback before swapping rooms

	# tutorial kills and damage don't carry over
	enemy_kill_count = 0
	kill_count_changed.emit(enemy_kill_count, REQUIRED_KILLS)
	for proj in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()
	var p = get_tree().get_first_node_in_group("player")
	if p:
		p.heal(9999.0)
		p.harmonic_energy = 0.0
		p.add_harmonic_energy(0.0)

	last_entry_direction = Vector2i.ZERO
	load_room(Vector2i.ZERO)              # removes the tutorial room and uses PlayerSpawn
	if screen_fader and screen_fader.has_method("fade_in"):
		screen_fader.fade_in(0.4)
	
	# NOW we can pause; here also just in case the unhandled input in the 
	# tutorial script doesn't work
	can_pause = true

func make_room(mask: int, kind: String) -> Dictionary:
	var scene: PackedScene
	match kind:
		"BOSS":  scene = BOSS_SCENE
		"VAULT": scene = VAULT_SCENE
		_:       scene = room_by_mask.get(mask, BASE_SCENE)
	return {"scene": scene, "rotation": 0.0, "type": kind, "mask": mask}

# transition_to_room
func transition_to_room(new_coords: Vector2i) -> void:
	print("Attempting transition to: ", new_coords, " | Exists in grid: ", grid.has(new_coords))
	
	if is_transitioning or not grid.has(new_coords):
		print("Transition blocked: No room exists at ", new_coords)
		return
		
	# check if entering the Boss Room requires key & 50+ kills
	var room_data = grid.get(new_coords, {})
	if room_data.get("type") == "BOSS":
		var player = get_tree().get_first_node_in_group("player")
		var has_key = player and player.has_dungeon_key
		var has_enough_kills = enemy_kill_count >= REQUIRED_KILLS
		
		if not debug_skip_boss_lock and not (has_key and has_enough_kills):
			# print("Boss door locked! Kills: ", enemy_kill_count, "/", REQUIRED_KILLS, " | Has Key: ", has_key)
			
			# optional: trigger dialogue warning if DialogueUI exists
			var dlg = get_node_or_null("/root/DialogueLogic")
			if dlg and not dlg.is_active:
				dlg.start_dialogue("Protagonist", ["The door is sealed. The Chaotic energy is too strong..."])
			return

	is_transitioning = true
	
	last_entry_direction = new_coords - current_room_coords
	
	if screen_fader and screen_fader.has_method("fade_out"):
		await screen_fader.fade_out(0.3)
	
	clear_active_projectiles()
	call_deferred("load_room", new_coords)
	
	if screen_fader and screen_fader.has_method("fade_in"):
		screen_fader.fade_in(0.3)

func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not (event is InputEventKey and event.pressed and not event.echo):
		return

	var p = get_tree().get_first_node_in_group("player")

	match event.keycode:
		KEY_BRACKETLEFT:   # [  give the kills
			enemy_kill_count = REQUIRED_KILLS
			kill_count_changed.emit(enemy_kill_count, REQUIRED_KILLS)
		KEY_BRACKETRIGHT:  # ]  give the key
			if p and p.has_method("add_key"):
				p.add_key(1)
		KEY_BACKSLASH:     # \  jump to the boss room
			if p:
				transition_to_room(BOSS_POS)
		KEY_6:             # full heal + full harmony
			if p:
				p.heal(9999.0)
				p.add_harmonic_energy(100.0)
		KEY_7:             # defeat screen
			game_over()
		KEY_8:             # win screen
			game_won()
		KEY_9:             # cliffhanger screen
			get_tree().change_scene_to_file(CLIFFHANGER_SCENE)

func load_room(coords: Vector2i) -> void:
	is_transitioning = true
	
	if current_room_instance:
		remove_child(current_room_instance)
		current_room_instance.queue_free()
		current_room_instance = null
		
	current_room_coords = coords
	var room_data = grid.get(coords, null)
	
	if room_data and room_data["scene"]:
		current_room_instance = room_data["scene"].instantiate()
		add_child(current_room_instance)
		
		# apply procedural rotation
		current_room_instance.rotation_degrees = room_data["rotation"]
		
		# instantiate or persist player
		if player_instance == null:
			player_instance = player_scene.instantiate()
			add_child(player_instance)
		
		# Pass entry direction into setup_room
		if current_room_instance.has_method("setup_room"):
			current_room_instance.setup_room(coords, room_data["type"], last_entry_direction)
			
	# track unique rooms visited
	if not visited_rooms.has(coords):
		visited_rooms.append(coords)
	
	update_camera_limits()
	room_changed.emit(coords)
	
	get_tree().create_timer(0.1).timeout.connect(func(): is_transitioning = false)
	
func update_camera_limits() -> void:
	if not player_instance or not current_room_instance:
		return
		
	var camera: Camera2D = player_instance.get_node_or_null("%Camera2D")
	if not camera:
		camera = player_instance.get_node_or_null("Camera2D")
		
	if camera and current_room_instance.has_method("get_bounds"):
		var bounds: Rect2 = current_room_instance.get_bounds()
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)
		camera.reset_smoothing()

func add_kill() -> void:
	enemy_kill_count += 1
	print("add_kill -> ", enemy_kill_count)
	kill_count_changed.emit(enemy_kill_count, REQUIRED_KILLS)

func clear_active_projectiles() -> void:
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(proj):
			proj.queue_free()
	
	if screen_fader:
		screen_fader.fade_in(0.3)

func clear_current_dungeon() -> void:
	can_pause = false

	in_tutorial = false
	set_atmosphere(false)
	
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
		
		if player_instance:
			player_instance.queue_free()
			player_instance = null

# game_over
# game is over!
func game_over() -> void:
	_end_run(DEFEAT_SCENE)

# game_won
# game has been won
func game_won() -> void:
	_end_run(WIN_SCENE)

func _end_run(path: String) -> void:
	can_pause = false # cannot pause
	
	if screen_fader and screen_fader.has_method("fade_out"):
		await screen_fader.fade_out(0.5)
	clear_current_dungeon()          # frees the room and player so they don't draw behind the screen
	
	for hud_name in ["HUD", "HUD_overlay"]:
		if has_node("/root/" + hud_name):
			get_node("/root/" + hud_name).hide()
	
	get_tree().change_scene_to_file(path)
	
	if screen_fader and screen_fader.has_method("fade_in"):
		screen_fader.fade_in(0.5)


func _build_atmosphere() -> void:
	ambient = CanvasModulate.new()
	ambient.color = AMBIENT_DEFAULT
	add_child(ambient)

	dark_layer = CanvasLayer.new()
	dark_layer.layer = 5                       # keep this BELOW your HUD and dialogue layers
	add_child(dark_layer)

	dark_rect = ColorRect.new()
	dark_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = DARK_SHADER
	dark_rect.material = mat
	dark_layer.add_child(dark_rect)

	set_atmosphere(false)                      # off for the main menu

func set_atmosphere(on: bool) -> void:
	ambient.visible = on
	dark_layer.visible = on

func set_ambient(color: Color, time: float = 0.8) -> void:
	create_tween().tween_property(ambient, "color", color, time)

func _process(_delta: float) -> void:
	if dark_layer == null or not dark_layer.visible:
		return
	# var p := get_tree().get_first_node_in_group("player") as Node2D
	#if p:
	#	var vp := get_viewport().get_visible_rect().size
	#	var c: Vector2 = p.get_global_transform_with_canvas().origin / vp
	#	(dark_rect.material as ShaderMaterial).set_shader_parameter("light_center", c)
