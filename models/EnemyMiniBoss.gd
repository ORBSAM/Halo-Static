extends "res://models/EnemyBase.gd"

# ==========================================
# ENEMY MINI-BOSS
# 70 HP elite demon. Chases the player, then telegraphs and dashes in a
# straight line. It is exposed (takes extra damage) while it recovers.
#
# State loop:  CHASE -> WINDUP -> CHARGE -> RECOVER -> CHASE
# ==========================================

signal miniboss_defeated

enum State { CHASE, WINDUP, CHARGE, RECOVER }

# drop the final Mini_Boss_Demon art here (Inspector) when it is ready
@export var miniboss_texture: Texture2D

@export_group("Charge")
@export var charge_speed: float = 330.0
@export var windup_time: float = 0.7        # telegraph before the dash
@export var charge_time: float = 0.5        # how long the dash lasts
@export var recover_time: float = 1.0       # stunned afterwards
@export var charge_cooldown: float = 2.5    # time before the next dash
@export var charge_damage: float = 25.0
@export var charge_min_range: float = 60.0  # only charge from this far...
@export var charge_max_range: float = 280.0 # ...up to this far
@export var hit_radius: float = 26.0        # contact range during a dash
@export var recover_damage_multiplier: float = 1.5

var state: State = State.CHASE
var state_timer: float = 0.0
var cooldown_timer: float = 1.5             # short grace period after spawning
var charge_direction: Vector2 = Vector2.ZERO
var hit_this_charge: bool = false
var is_dying: bool = false
var base_tint: Color = Color.WHITE

# setup_random_variant
# EnemyBase calls this from _ready(), so overriding it replaces the
# random 25/45 HP demon stats with the mini-boss stats.
func setup_random_variant() -> void:
	max_health = 70.0
	current_health = max_health
	move_speed = 70.0
	attack_damage = 15.0
	attack_cooldown = 1.2
	stop_distance = 40.0

	if sprite == null:
		return

	if miniboss_texture:
		sprite.texture = miniboss_texture
	else:
		# placeholder look until the real art is dropped in
		sprite.texture = sprite_type_b
		sprite.modulate = Color(1.0, 0.6, 0.6)
	base_tint = sprite.modulate

# _physics_process
func _physics_process(delta: float) -> void:
	if is_dying:
		return

	if target_player == null:
		target_player = get_tree().get_first_node_in_group("player")
	if target_player == null:
		return

	cooldown_timer = max(0.0, cooldown_timer - delta)

	match state:
		State.CHASE:
			_process_chase()
		State.WINDUP:
			_process_windup(delta)
		State.CHARGE:
			_process_charge(delta)
		State.RECOVER:
			_process_recover(delta)

# _process_chase
func _process_chase() -> void:
	var to_player: Vector2 = target_player.global_position - global_position
	var dist: float = to_player.length()

	var move_dir := Vector2.ZERO
	if dist > stop_distance:
		move_dir += to_player.normalized()
	move_dir += get_separation_vector() * 1.2

	if move_dir != Vector2.ZERO:
		velocity = move_dir.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# regular melee swing when right next to the player
	if dist <= stop_distance + 8.0 and can_attack:
		attack_player()

	# start a charge when the player is at mid range
	if cooldown_timer <= 0.0 and dist >= charge_min_range and dist <= charge_max_range:
		_start_windup()

# _start_windup
# stand still and glow red so the player can read the attack
func _start_windup() -> void:
	state = State.WINDUP
	state_timer = windup_time
	velocity = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), windup_time)

# _process_windup
func _process_windup(delta: float) -> void:
	state_timer -= delta

	# keep aiming at the player until the last moment, then lock in
	charge_direction = (target_player.global_position - global_position).normalized()

	if state_timer <= 0.0:
		state = State.CHARGE
		state_timer = charge_time
		hit_this_charge = false

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

	# the dash ends on a timer, or early if we slam into a wall / body
	if state_timer <= 0.0 or get_slide_collision_count() > 0:
		_start_recover()

# _start_recover
func _start_recover() -> void:
	state = State.RECOVER
	state_timer = recover_time
	cooldown_timer = charge_cooldown
	velocity = Vector2.ZERO

	# bluish tint = "I'm stunned, hit me"
	sprite.modulate = Color(0.7, 0.7, 1.0)

# _process_recover
func _process_recover(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO

	if state_timer <= 0.0:
		state = State.CHASE
		sprite.modulate = base_tint

# take_damage
# overrides EnemyBase: heavier knockback is removed (it is a mini-boss) and
# it takes bonus damage while stunned.
func take_damage(amount: float, _knockback_source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying:
		return

	if state == State.RECOVER:
		amount *= recover_damage_multiplier

	super.take_damage(amount, Vector2.ZERO)
	_hit_flash()

# _hit_flash
func _hit_flash() -> void:
	if sprite == null or is_dying:
		return
	var tween := create_tween()
	sprite.self_modulate = Color(2.0, 2.0, 2.0)
	tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.15)

# die
func die() -> void:
	if is_dying:
		return
	is_dying = true

	# stop being a target right away
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	velocity = Vector2.ZERO

	# EnemyBase.die() counts kills toward the boss-room requirement, and this
	# override replaces it, so count the mini-boss here too
	if DungeonManager and DungeonManager.has_method("add_kill"):
		DungeonManager.add_kill()

	miniboss_defeated.emit()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)
