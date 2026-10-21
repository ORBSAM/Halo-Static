extends CharacterBody2D

@export var max_health: float = 30.0
var current_health: float = 30.0

@export var move_speed: float = 80.0
@export var attack_damage: float = 5
@export var attack_cooldown: float = 1.0

# movement distances
@export var stop_distance: float = 45.0       # stop moving when within this range of player
@export var separation_radius: float = 24.0   # push away from other enemies closer than this

@export var item_seek_radius: float = 240.0
@export var max_power_stacks: int = 3

# two demon png paths
@onready var sprite: Sprite2D = $Sprite2D
var sprite_type_a = preload("res://models/enemy_images/demon_01.png")
var sprite_type_b = preload("res://models/enemy_images/demon_02.png")

var can_attack: bool = true
var is_attacking: bool = false
var target_player: Node2D = null

var power_stacks: int = 0
var target_item: Node2D = null
var _scan_timer: float = 0.0

var is_dead := false


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	
	setup_random_variant()

func setup_random_variant() -> void:
	if sprite == null:
		return

	# pick randomly (0 or 1)
	var variant = randi() % 2
	
	if variant == 0:
		sprite.texture = sprite_type_a
		# Variant A: Standard enemy
		move_speed = 85.0
		max_health = 25.0
	else:
		sprite.texture = sprite_type_b
		# Variant B: Tankier, slightly slower
		move_speed = 65.0
		max_health = 45.0
		
	current_health = max_health

func _physics_process(delta: float) -> void:
	if target_player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
	if target_player == null:
		return

	# rescan a few times a second, not every frame
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.4
		if power_stacks < max_power_stacks and not is_instance_valid(target_item):
			target_item = _find_item()
		elif is_instance_valid(target_item) and not target_item.is_consumable():
			target_item = null

	var dist_to_player = global_position.distance_to(target_player.global_position)
	var move_dir = Vector2.ZERO
	var chasing_item := is_instance_valid(target_item) and power_stacks < max_power_stacks

	if chasing_item:
		if global_position.distance_to(target_item.global_position) < 14.0:
			_consume_item(target_item)
		else:
			move_dir += (target_item.global_position - global_position).normalized()
	elif dist_to_player > stop_distance and not is_attacking:
		move_dir += (target_player.global_position - global_position).normalized()

	move_dir += get_separation_vector() * 1.2
	velocity = move_dir.normalized() * move_speed if move_dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	if dist_to_player <= (stop_distance + 8.0) and can_attack:
		attack_player()

# calculates push vector to keep enemies spaced apart
func get_separation_vector() -> Vector2:
	var push_vector = Vector2.ZERO
	var neighbor_count = 0
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < separation_radius and dist > 0:
				# Push directly away from neighbor
				push_vector += (global_position - enemy.global_position).normalized() / dist
				neighbor_count += 1
				
	return push_vector

func attack_player() -> void:
	if target_player and target_player.has_method("take_damage"):
		can_attack = false
		is_attacking = true
		
		target_player.take_damage(attack_damage)
		
		# pause briefly during attack swing
		await get_tree().create_timer(0.6).timeout
		is_attacking = false
		
		await get_tree().create_timer(attack_cooldown - 0.6).timeout
		can_attack = true

func take_damage(amount: float, knockback_source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	
	spawn_damage_number(amount)
	
	# apply noticeable knockback pulse away from attack source
	if knockback_source_pos != Vector2.ZERO:
		var knockback_dir = (global_position - knockback_source_pos).normalized()
		# stronger push back on hit so they don't stick during combat
		global_position += knockback_dir * 50.0
		
	if current_health <= 0:
		die()

func spawn_damage_number(amount: float) -> void:
	var template_label = $DamageLabel
	if not is_instance_valid(template_label):
		return

	# Duplicate the template label so the original on the enemy isn't destroyed
	var label: Label = template_label.duplicate()
	label.text = str(round(amount))
	label.z_index = 100
	label.global_position = global_position + Vector2(-10, -30)
	label.visible = true  # ensure it is visible
	label.modulate.a = 1.0 # reset alpha in case template was faded
	
	# spawn in the world tree (parent) so it doesn't move with the enemy
	get_parent().add_child(label)
	
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 30.0, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(label.queue_free)

func _find_item() -> Node2D:
	var best: Node2D = null
	var best_d := item_seek_radius
	for it in get_tree().get_nodes_in_group("items"):
		if is_instance_valid(it) and it.has_method("is_consumable") and it.is_consumable():
			var d := global_position.distance_to(it.global_position)
			if d < best_d:
				best_d = d
				best = it
	return best

func _consume_item(item: Node2D) -> void:
	item.consume_by_enemy()
	target_item = null
	power_stacks += 1
	attack_damage += 1.0
	move_speed *= 1.08
	max_health += 8.0
	current_health = min(max_health, current_health + 10.0)
	# grow and redden the sprite only (scaling the body would change its collision)
	sprite.scale *= 1.08
	sprite.modulate = Color(1.0, 1.0 - 0.2 * power_stacks, 1.0 - 0.2 * power_stacks)

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	remove_from_group("enemies")
	set_physics_process(false)
	
	hide()
	
	if DungeonManager:
		DungeonManager.add_kill()
	
	queue_free()
