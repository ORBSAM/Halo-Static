extends "res://models/EnemyBase.gd"

# ==========================================
# ENEMY BOSS (the Demon Lord)
# Final boss, 250-300 HP. Fights in three phases that unlock as it takes
# damage. Each phase is faster and adds attacks:
#
#   Phase 1 (100-66% HP): slow chase + 3-orb spread shot
#   Phase 2 ( 66-33% HP): faster, spread shot + charge dash
#   Phase 3 ( 33- 0% HP): enraged, orb burst ring + charge dash
#
# Room_Boss (RoomBoss.gd) connects to the boss_defeated signal.
# ==========================================

signal boss_defeated
signal phase_changed(new_phase: int)
signal boss_health_changed(current_health: float, max_health: float)

enum State { INTRO, CHASE, TELEGRAPH, CHARGE, RECOVER, TRANSITION, DEAD }

const PROJECTILE_SCRIPT = preload("res://models/EnemyProjectile.gd")

# drop the final Boss_Demon art here (Inspector) when it is ready
@export var boss_texture: Texture2D
# GDD range is 250-300 HP
@export_range(250.0, 300.0) var boss_max_health: float = 300.0
@export var intro_time: float = 1.5             # stands still when the fight starts
@export var transition_time: float = 1.2        # pause + roar between phases

@export_group("Charge")
@export var charge_speed: float = 380.0
@export var charge_time: float = 0.55
@export var charge_damage: float = 30.0
@export var recover_time: float = 1.2
@export var hit_radius: float = 26.0

@export_group("Projectiles")
@export var projectile_speed: float = 190.0
@export var projectile_damage: float = 12.0

# per-phase tuning: move speed, time between attacks, attack pool
const PHASE_DATA: Dictionary = {
	1: {"speed": 55.0, "cooldown": 2.6, "attacks": ["spread"], "tint": Color(1.0, 1.0, 1.0)},
	2: {"speed": 75.0, "cooldown": 2.2, "attacks": ["spread", "charge"], "tint": Color(1.0, 0.75, 0.75)},
	3: {"speed": 95.0, "cooldown": 1.6, "attacks": ["burst", "charge"], "tint": Color(1.0, 0.45, 0.55)},
}

var state: State = State.INTRO
var phase: int = 1
var state_timer: float = 0.0
var attack_timer: float = 2.0
var pending_attack: String = ""
var charge_direction: Vector2 = Vector2.ZERO
var hit_this_charge: bool = false
var is_dying: bool = false
var base_tint: Color = Color.WHITE

# setup_random_variant
# EnemyBase calls this from _ready(); overriding it swaps the random demon
# stats for the boss stats.
func setup_random_variant() -> void:
	max_health = boss_max_health
	current_health = max_health
	move_speed = PHASE_DATA[1]["speed"]
	attack_damage = 20.0
	attack_cooldown = 1.5
	stop_distance = 60.0

	state = State.INTRO
	state_timer = intro_time

	if sprite == null:
		return

	if boss_texture:
		sprite.texture = boss_texture
	else:
		# placeholder look until the real art is dropped in
		sprite.texture = sprite_type_a
	base_tint = sprite.modulate

	boss_health_changed.emit(current_health, max_health)

# _physics_process
func _physics_process(delta: float) -> void:
	if is_dying:
		return

	if target_player == null:
		target_player = get_tree().get_first_node_in_group("player")
	if target_player == null:
		return

	match state:
		State.INTRO:
			_process_intro(delta)
		State.CHASE:
			_process_chase(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.CHARGE:
			_process_charge(delta)
		State.RECOVER:
			_process_recover(delta)
		State.TRANSITION:
			_process_transition(delta)

# _process_intro
func _process_intro(delta: float) -> void:
	velocity = Vector2.ZERO
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.CHASE

# _process_chase
func _process_chase(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)

	var to_player: Vector2 = target_player.global_position - global_position
	var dist: float = to_player.length()

	var move_dir := Vector2.ZERO
	if dist > stop_distance:
		move_dir += to_player.normalized()

	if move_dir != Vector2.ZERO:
		velocity = move_dir.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# melee swing if the player hugs the boss
	if dist <= stop_distance + 8.0 and can_attack:
		attack_player()

	# pick the next special attack
	if attack_timer <= 0.0:
		_start_telegraph(_choose_attack())

# _choose_attack
func _choose_attack() -> String:
	var pool: Array = PHASE_DATA[phase]["attacks"]
	return pool.pick_random()

# _start_telegraph
# a short, readable wind-up before every attack
func _start_telegraph(attack: String) -> void:
	state = State.TELEGRAPH
	pending_attack = attack
	velocity = Vector2.ZERO

	# the dash gets a longer warning than the orbs
	state_timer = 0.8 if attack == "charge" else 0.6

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), state_timer)

# _process_telegraph
func _process_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO

	# keep aiming at the player until the last moment
	charge_direction = (target_player.global_position - global_position).normalized()

	if state_timer > 0.0:
		return

	match pending_attack:
		"spread":
			_fire_spread(3 if phase == 1 else 5, 30.0 if phase == 1 else 60.0)
			_finish_attack()
		"burst":
			_fire_burst(10)
			_finish_attack()
		"charge":
			state = State.CHARGE
			state_timer = charge_time
			hit_this_charge = false

# _finish_attack
# go back to chasing and start the cooldown for the next attack
func _finish_attack() -> void:
	state = State.CHASE
	attack_timer = PHASE_DATA[phase]["cooldown"]
	sprite.modulate = PHASE_DATA[phase]["tint"] * base_tint

# _process_charge
func _process_charge(delta: float) -> void:
	state_timer -= delta
	velocity = charge_direction * charge_speed
	move_and_slide()

	# contact damage, once per dash
	var reach: float = hit_radius * scale.x
	if not hit_this_charge and global_position.distance_to(target_player.global_position) <= reach:
		hit_this_charge = true
		if target_player.has_method("take_damage"):
			target_player.take_damage(charge_damage)

	# ends on a timer, or early if we slam into a wall / body
	if state_timer <= 0.0 or get_slide_collision_count() > 0:
		state = State.RECOVER
		state_timer = recover_time
		velocity = Vector2.ZERO
		sprite.modulate = Color(0.7, 0.7, 1.0)

# _process_recover
func _process_recover(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	if state_timer <= 0.0:
		_finish_attack()

# _process_transition
# the boss freezes and cannot be hurt while it changes phase
func _process_transition(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	if state_timer <= 0.0:
		_finish_attack()

# _fire_spread
# a fan of orbs aimed at the player
func _fire_spread(count: int, arc_degrees: float) -> void:
	var base_angle: float = (target_player.global_position - global_position).angle()

	for i in range(count):
		var t: float = 0.5 if count == 1 else float(i) / float(count - 1)
		var offset: float = deg_to_rad(lerp(-arc_degrees / 2.0, arc_degrees / 2.0, t))
		_spawn_projectile(Vector2.RIGHT.rotated(base_angle + offset))

# _fire_burst
# a full ring of orbs
func _fire_burst(count: int) -> void:
	var start_angle: float = randf() * TAU

	for i in range(count):
		_spawn_projectile(Vector2.RIGHT.rotated(start_angle + TAU * float(i) / float(count)))

# _spawn_projectile
func _spawn_projectile(dir: Vector2) -> void:
	var projectile = PROJECTILE_SCRIPT.new()
	projectile.direction = dir
	projectile.speed = projectile_speed * (1.25 if phase == 3 else 1.0)
	projectile.damage = projectile_damage

	# parent is the room, so projectiles are removed with it
	get_parent().add_child(projectile)
	projectile.global_position = global_position

# take_damage
# overrides EnemyBase: no knockback on the boss, and it is invulnerable
# while changing phase.
func take_damage(amount: float, _knockback_source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying or state == State.TRANSITION:
		return

	super.take_damage(amount, Vector2.ZERO)

	if is_dying:
		return

	boss_health_changed.emit(current_health, max_health)
	_hit_flash()
	_check_phase()

# _check_phase
func _check_phase() -> void:
	var fraction: float = current_health / max_health
	var new_phase: int = 1
	if fraction <= 0.33:
		new_phase = 3
	elif fraction <= 0.66:
		new_phase = 2

	if new_phase > phase:
		phase = new_phase
		move_speed = PHASE_DATA[phase]["speed"]
		state = State.TRANSITION
		state_timer = transition_time
		velocity = Vector2.ZERO
		_clear_projectiles()
		phase_changed.emit(phase)

		# roar: quick scale pulse + new tint
		var tween := create_tween()
		sprite.modulate = PHASE_DATA[phase]["tint"] * base_tint
		tween.tween_property(sprite, "scale", sprite.scale * 1.25, transition_time / 2.0)
		tween.tween_property(sprite, "scale", sprite.scale, transition_time / 2.0)

# _clear_projectiles
func _clear_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		if projectile.get_script() == PROJECTILE_SCRIPT:
			projectile.queue_free()

# _hit_flash
func _hit_flash() -> void:
	if sprite == null:
		return
	sprite.self_modulate = Color(2.0, 2.0, 2.0)
	var tween := create_tween()
	tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.15)

# die
# GDD: the boss speaks once more before the credits. boss_defeated is
# emitted AFTER that dialogue so the room can cut to the ending.
func die() -> void:
	if is_dying:
		return
	is_dying = true
	state = State.DEAD

	# stop being a target right away
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	velocity = Vector2.ZERO
	_clear_projectiles()
	boss_health_changed.emit(0.0, max_health)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	await tween.finished

	await _play_defeat_dialogue()

	boss_defeated.emit()
	queue_free()

# _play_defeat_dialogue
func _play_defeat_dialogue() -> void:
	# the autoload is called DialogueLogic in project.godot
	var ui: Node = get_node_or_null("/root/DialogueLogic")
	if ui == null:
		ui = get_node_or_null("/root/DialogueUI")
	if ui == null or not ui.has_method("start_dialogue"):
		return

	# don't wait on a dialogue that never starts
	if "is_active" in ui and ui.is_active:
		return

	var lines: Array[String] = [
		"No... not like this...",
		"The static... it never ends..."
	]
	ui.start_dialogue("Boss", lines)
	await ui.dialogue_finished
