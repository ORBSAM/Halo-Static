extends Node2D

# ==========================================
# BOSS TEST ARENA
# Open tests/boss_test.tscn and press F6 (Run Current Scene).
# A bare walled room with the player, so the MiniBoss and Boss can be
# tried without playing through the dungeon.
#
#   1  spawn MiniBoss        2  spawn Boss
#   K  deal 25 damage to it  H  heal the player
#   R  reset the arena
# ==========================================

const PLAYER_SCENE := preload("res://models/player_logic.tscn")
const MINIBOSS_SCENE := preload("res://models/miniboss_logic.tscn")
const BOSS_SCENE := preload("res://models/boss_logic.tscn")

const ARENA := Rect2(0, 0, 960, 540)
const WALL_THICKNESS := 40.0

var player: Node2D = null
var boss: Node = null
var info: Label = null
var last_event: String = "Press 1 for the MiniBoss or 2 for the Boss"

# _ready
func _ready() -> void:
	_build_arena()
	_spawn_player()
	_build_overlay()

# _build_arena
func _build_arena() -> void:
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.25, 0.25, 0.33)
	floor_rect.position = ARENA.position
	floor_rect.size = ARENA.size
	floor_rect.z_index = -10
	add_child(floor_rect)

	# four walls on layers 1 + 2 (value 3) so the player, the bosses and
	# the boss projectiles all collide with them
	var walls: Array[Rect2] = [
		Rect2(-WALL_THICKNESS, -WALL_THICKNESS, ARENA.size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS),
		Rect2(-WALL_THICKNESS, ARENA.size.y, ARENA.size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS),
		Rect2(-WALL_THICKNESS, 0, WALL_THICKNESS, ARENA.size.y),
		Rect2(ARENA.size.x, 0, WALL_THICKNESS, ARENA.size.y),
	]
	for rect in walls:
		var body := StaticBody2D.new()
		body.collision_layer = 3
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		body.position = rect.position + rect.size / 2.0
		body.add_child(shape)
		add_child(body)

# _spawn_player
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = Vector2(220, 270)

	# keep the camera inside the arena
	var camera: Camera2D = player.get_node_or_null("CharacterBody2D/Camera2D")
	if camera:
		camera.limit_left = int(ARENA.position.x)
		camera.limit_top = int(ARENA.position.y)
		camera.limit_right = int(ARENA.end.x)
		camera.limit_bottom = int(ARENA.end.y)

# _build_overlay
func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	info = Label.new()
	info.position = Vector2(12, 8)
	info.add_theme_color_override("font_color", Color.WHITE)
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	info.add_theme_constant_override("outline_size", 4)
	layer.add_child(info)

# _spawn_boss
func _spawn_boss(scene: PackedScene) -> void:
	if is_instance_valid(boss):
		boss.queue_free()

	boss = scene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(720, 270)

	if boss.has_signal("miniboss_defeated"):
		boss.miniboss_defeated.connect(func(): last_event = "MiniBoss defeated!")
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(func(): last_event = "boss_defeated emitted (RoomBoss would load the ending)")
	if boss.has_signal("phase_changed"):
		boss.phase_changed.connect(func(p: int): last_event = "Boss entered phase %d" % p)

	last_event = "Spawned %s" % boss.name

# _reset
func _reset() -> void:
	get_tree().reload_current_scene()

# _unhandled_key_input
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_1:
			_spawn_boss(MINIBOSS_SCENE)
		KEY_2:
			_spawn_boss(BOSS_SCENE)
		KEY_K:
			if is_instance_valid(boss) and boss.has_method("take_damage"):
				boss.take_damage(25.0)
		KEY_H:
			if player:
				var body: Node = player.get_node_or_null("CharacterBody2D")
				if body and body.has_method("heal"):
					body.heal(100.0)
		KEY_R:
			_reset()

# _process
func _process(_delta: float) -> void:
	if info == null:
		return

	var text := "1: MiniBoss   2: Boss   K: -25 HP   H: heal player   R: reset\n"

	if is_instance_valid(boss) and "current_health" in boss:
		text += "%s   HP %d / %d" % [boss.name, boss.current_health, boss.max_health]
		if "phase" in boss:
			text += "   phase %d" % boss.phase
		if "state" in boss:
			text += "   state %d" % boss.state
		text += "\n"

	text += last_event
	info.text = text
