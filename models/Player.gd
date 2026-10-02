extends CharacterBody2D

# ==========================================
# PLAYER CONTROLLER
# Handles 8-way movement, weapon aiming, hit flashes, and energy usage.
# ==========================================

@export var speed: float = 160.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
var is_blasting := false


# directional tracking; vectors
var last_facing_direction: Vector2 = Vector2.DOWN

# debug 
func _ready() -> void:
	# debug
	print("Player spawned at: ", global_position)
	
# _physics_process
func _physics_process(delta: float) -> void:
	handle_movement()
	handle_weapon_aiming()
	pass

# handle_movement
# For each movement, up,down, left, and right, set the velocity 
# and handle sprite flipping where needed.
func handle_movement() -> void:
	print(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	# get the 8-way movement vector
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# set velocity and apply physics movement
	velocity = input_direction * speed
	move_and_slide()

	# handle sprite flipping for left-right movement
	if input_direction != Vector2.ZERO:
		last_facing_direction = input_direction

	update_animation(input_direction)

# handle_weapon_aiming
# Make sure that the weapon pivot object is actively looking at the mouse.
func handle_weapon_aiming() -> void:
	# keep the weapon pivot looking at the mouse position
	if weapon_pivot:
		weapon_pivot.look_at(get_global_mouse_position())

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
