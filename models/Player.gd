extends CharacterBody2D

# ==========================================
# PLAYER CONTROLLER
# Handles 8-way movement, weapon aiming, hit flashes, and energy usage.
# ==========================================

# TODO: Export movement speed (e.g., const SPEED = 150.0)
# TODO: Reference Sprite2D, WeaponPivot node, and AnimationPlayer/Shader

# _physics_process
func _physics_process(delta: float) -> void:
	# TODO: Get 8-way directional input vector (WASD / Arrows)
	# TODO: Normalize vector and set velocity
	# TODO: Update sprite orientation and flip_h based on horizontal velocity
	# TODO: Move character using move_and_slide()
	# TODO: Update WeaponPivot rotation to look_at(get_global_mouse_position())
	pass

# _unhandled_input
func _unhandled_input(event: InputEvent) -> void:
	# TODO: Detect Q / E key presses for weapon attack
	# TODO: Calculate HP & energy drain scaling based on current Harmonic Energy
	# TODO: Play weapon swing animation on active weapon
	pass

# play_hit_flash
# When player is damaged, "play" a red flash.
func play_hit_flash() -> void:
	# TODO: Modulate sprite tint to red brief color flash when damaged
	pass
