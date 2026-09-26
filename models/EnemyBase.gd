extends CharacterBody2D

# ==========================================
# BASE ENEMY AI
# Basic 10 HP demon pathfinding and contact damage logic.
# ==========================================

# TODO: Export stats: max_hp = 10, move_speed = 80.0, contact_damage = 5
# TODO: Reference NavigationAgent2D and Player node

# _physics_process
func _physics_process(delta: float) -> void:
	# TODO: Get player global position
	# TODO: Set navigation agent target_position to player position
	# TODO: Calculate direction vector to next path point
	# TODO: Set velocity and execute move_and_slide()
	pass
# receive_damage
func receive_damage(amount: int) -> void:
	# TODO: Subtract amount from enemy HP
	# TODO: Flash sprite white/red
	# TODO: If HP <= 0 -> spawn drop item (Harmonic/Chaotic) and call queue_free()
	pass

# on_body_entered
func _on_body_entered(body: Node2D) -> void:
	# TODO: Check if body is in "Player" group
	# TODO: Call body.take_damage(contact_damage)
	pass
