extends CharacterBody2D

# ==========================================
# PLAYER CONTROLLER
# Handles 8-way movement, weapon aiming, hit flashes, and energy usage.
# ==========================================

# signals
signal health_changed(current_health: float, max_health: float)
signal harmonic_changed(current_energy: float, max_energy: float)
signal weapon_changed(current_weapon: Weapon)

# stats
@export var max_health: float = 100.0
var current_health: float = 100.0

# harmonic energy system
var harmonic_energy: float = 0.0 # 0 to 100
const MAX_HARMONIC: float = 100.0
const BLAST_THRESHOLD: float = 100.0

# base Combat Stats
@export var base_weapon_damage: float = 10.0
@export var speed: float = 160.0

# weapon Types
enum Weapon {
	SABER,
	ORB_OF_LIGHT,
}
var current_weapon: Weapon = Weapon.SABER

# Base Weapon Stats
var weapon_stats = {
	Weapon.SABER: {
		"base_damage": 15.0,
		"energy_gain": 6.0,
		"hitbox": null # assigned in _ready
	},
	Weapon.ORB_OF_LIGHT: {
		"base_damage": 8.0,
		"energy_gain": 4.0,
		"hitbox": null
	}
}

# preload weapon textures
var saber_texture = preload("res://weapons/saber_weapon.png")
var orb_texture = preload("res://weapons/orb_of_light_weapon.png")

# node references
@onready var saber_hitbox: Area2D = $WeaponPivot/Saber/SaberHitbox
@onready var orb_hitbox: Area2D = $WeaponPivot/OrbOfLight/OrbOfLightHitbox
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var saber: Sprite2D = $WeaponPivot/Saber
@onready var orb_of_light: Sprite2D = $WeaponPivot/OrbOfLight

# state tracking
var is_blasting: bool = false
var is_attacking: bool = false
var last_facing_direction: Vector2 = Vector2.DOWN

enum AttackType { SWING, THRUST }
var current_attack: AttackType = AttackType.SWING

func _ready() -> void:
	add_to_group("player")
	
	# set textures at run time
	saber.texture = saber_texture
	orb_of_light.texture = orb_texture
	
	weapon_stats[Weapon.SABER]["hitbox"] = saber_hitbox
	weapon_stats[Weapon.ORB_OF_LIGHT]["hitbox"] = orb_hitbox
	
	# ensure hitboxes start disabled
	saber_hitbox.monitoring = false
	orb_hitbox.monitoring = false
	
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	emit_signal("harmonic_changed", harmonic_energy, MAX_HARMONIC)
	
	# Equip default weapon
	equip_weapon(Weapon.SABER)
	
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)
	
	print("Player spawned at: ", global_position)

func _physics_process(_delta: float) -> void:
	handle_movement()
	handle_weapon_aiming()

func _input(event: InputEvent) -> void:
	# weapon Switching
	if event.is_action_pressed("weapon_saber"):
		equip_weapon(Weapon.SABER)
	elif event.is_action_pressed("weapon_orb"):
		equip_weapon(Weapon.ORB_OF_LIGHT)
		
	# combat Actions
	if event.is_action_pressed("attack") and not is_attacking:
		execute_attack()
	elif event.is_action_pressed("harmonic_blast"): # "B" key or Shift
		trigger_harmonic_blast()

# Movement logic
func handle_movement() -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed
	move_and_slide()

	if input_direction != Vector2.ZERO:
		last_facing_direction = input_direction

	update_animation(input_direction)

# handle_weapon_aiming
# aim weapon pivot towards mouse
func handle_weapon_aiming() -> void:
	var mouse_position := get_global_mouse_position()
	weapon_pivot.look_at(mouse_position)
	weapon_pivot.scale.y = -1.0 if mouse_position.x < global_position.x else 1.0

# equip_weapon
# equip weapon and update visibility
func equip_weapon(weapon: Weapon) -> void:
	current_weapon = weapon
	saber.visible = weapon == Weapon.SABER
	orb_of_light.visible = weapon == Weapon.ORB_OF_LIGHT
	weapon_changed.emit(current_weapon)
	print("Equipped weapon: ", Weapon.keys()[current_weapon])

# execute_attack
# track execution & hitbox check
func execute_attack() -> void:
	if is_attacking:
		return
		
	is_attacking = true

	if current_weapon == Weapon.ORB_OF_LIGHT:
		fire_orb_duplicate()
		is_attacking = false
		return

	# saber Attack Logic
	var stats = weapon_stats[Weapon.SABER]
	var active_hitbox: Area2D = stats["hitbox"]
	
	if anim_player and anim_player.has_animation("swing_saber"):
		anim_player.play("swing_saber")

	if active_hitbox:
		var hit_enemies = [] # prevent damaging the same enemy twice in 1 swing
		
		# define hit detection function
		var check_and_hit = func(body: Node2D):
			if body.is_in_group("enemies") and body.has_method("take_damage") and not body in hit_enemies:
				hit_enemies.append(body)
				body.take_damage(get_scaled_damage(stats["base_damage"]), global_position)
				add_harmonic_energy(stats["energy_gain"])

		# 1. Dynamic connection while swing is active
		var connection = active_hitbox.body_entered.connect(check_and_hit)
		active_hitbox.monitoring = true
		
		# 2. Check any enemies already standing inside hitbox on frame 1
		await get_tree().physics_frame
		for body in active_hitbox.get_overlapping_bodies():
			check_and_hit.call(body)

		# 3. leave hitbox active long enough for swing to pass through enemies
		if anim_player and anim_player.has_animation("swing_saber"):
			anim_player.speed_scale = 1.8 # play attack animation 1.8x faster
			anim_player.play("swing_saber")

	   # reduce the active hitbox duration to match the faster swing:
		await get_tree().create_timer(0.12).timeout # reduced from 0.25s
		
		active_hitbox.monitoring = false
		if active_hitbox.body_entered.is_connected(check_and_hit):
			active_hitbox.body_entered.disconnect(check_and_hit)

	is_attacking = false

# fire_orb_dupe
# fires a duplicate orb rather than using another scene entirely
func fire_orb_duplicate() -> void:
	if orb_texture == null:
		print("ERROR: orb_texture is missing!")
		return

	# 1. Create a new projectile Area2D
	var projectile = Area2D.new()
	projectile.add_to_group("projectiles") # Group tag for easy cleanup on room transition
	
	projectile.collision_layer = orb_hitbox.collision_layer
	projectile.collision_mask = orb_hitbox.collision_mask

	# 2. Add Sprite2D with Z-index boost so it draws ABOVE the floor
	var sprite_node = Sprite2D.new()
	sprite_node.texture = orb_texture
	sprite_node.scale = Vector2(0.003, 0.003)
	sprite_node.z_index = 10 # Guarantees rendering over TileMap layers
	projectile.add_child(sprite_node)

	# 3. Add CollisionShape2D
	var shape_node = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	shape_node.shape = circle
	projectile.add_child(shape_node)

	# 4. Attach to the current room scene node
	var current_room = get_tree().current_scene
	if current_room:
		current_room.add_child(projectile)
	else:
		get_parent().add_child(projectile)

	projectile.global_position = weapon_pivot.global_position
	projectile.visible = true
	projectile.monitoring = true

	# Compute direction toward mouse
	var target_dir = (get_global_mouse_position() - global_position).normalized()
	var proj_damage = get_scaled_damage(weapon_stats[Weapon.ORB_OF_LIGHT]["base_damage"])

	# 5. Connect hit detection
	var on_hit = func(body: Node2D):
		if body == self or body.is_in_group("player"):
			return

		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(proj_damage, projectile.global_position)
			add_harmonic_energy(weapon_stats[Weapon.ORB_OF_LIGHT]["energy_gain"])
			projectile.queue_free()
		elif body is TileMap or body is TileMapLayer:
			projectile.queue_free()

	projectile.body_entered.connect(on_hit)

	# 6. Launch projectile with Tween
	var travel_distance = 400.0
	var proj_speed = 450.0
	var duration = travel_distance / proj_speed
	var target_pos = projectile.global_position + (target_dir * travel_distance)

	var tween = create_tween()
	tween.tween_property(projectile, "global_position", target_pos, duration)
	tween.finished.connect(projectile.queue_free)

# add_harmonic_energy
func add_harmonic_energy(amount: float) -> void:
	harmonic_energy = clamp(harmonic_energy + amount, 0.0, MAX_HARMONIC)
	harmonic_changed.emit(harmonic_energy, MAX_HARMONIC)

# get_scaled_damage
func get_scaled_damage(base_damage: float) -> float:
	# damage scales up to 2x at 100 Harmonic Energy
	var multiplier = 1.0 + (harmonic_energy / 100.0)
	return base_damage * multiplier

# trigger_harmonic_blast
# triggers the blast 
func trigger_harmonic_blast() -> void:
	if harmonic_energy < BLAST_THRESHOLD:
		print("Harmonic Energy not ready! Current: ", harmonic_energy)
		return
		
	print("HARMONIC BLAST UNLEASHED!")
	harmonic_energy = 0.0
	harmonic_changed.emit(harmonic_energy, MAX_HARMONIC)
	
	is_blasting = true
	
	# AOE Blast: Deals 35+ damage to all enemies within 250px
	var blast_radius = 250.0
	var blast_damage = 35.0
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= blast_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(blast_damage)
				
	await get_tree().create_timer(0.4).timeout
	is_blasting = false

# take_damage
func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	play_hit_flash()
	
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die() -> void:
	print("Player defeated!")
	# signal to DungeonManager or handle game over

# update_animation
# update the animation as the player moves
func update_animation(dir: Vector2) -> void:
	if is_blasting:
		return
	if dir == Vector2.ZERO:
		sprite.play("idle")
	elif abs(dir.x) > abs(dir.y):
		sprite.play("move_side")
		sprite.flip_h = dir.x < 0
	elif dir.y < 0:
		sprite.play("move_up")
	else:
		sprite.play("move_down")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "swing_saber" or anim_name == "thrust_saber":
		is_attacking = false

# play_hit_flash
# plays red flash
func play_hit_flash() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
