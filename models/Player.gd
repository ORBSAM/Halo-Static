extends CharacterBody2D

# ==========================================
# PLAYER CONTROLLER
# Handles 8-way movement, weapon aiming, hit flashes, and energy usage.
# ==========================================

signal weapon_changed(weapon: Weapon)

enum Weapon {
	SABER,
	ORB_OF_LIGHT,
}

@export var speed: float = 160.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var saber: Sprite2D = $WeaponPivot/Saber
@onready var orb_of_light: Sprite2D = $WeaponPivot/OrbOfLight

var is_blasting := false
var current_weapon: Weapon = Weapon.SABER

# directional tracking; vectors
var last_facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	equip_weapon(Weapon.SABER)
	print("Player spawned at: ", global_position)
	
# _physics_process
func _physics_process(_delta: float) -> void:
	handle_movement()
	handle_weapon_aiming()

# handle_movement
# For each movement, up,down, left, and right, set the velocity 
# and handle sprite flipping where needed.
func handle_movement() -> void:
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
	var mouse_position := get_global_mouse_position()
	weapon_pivot.look_at(mouse_position)

	# Keep right-facing weapon art upright while aiming to the left.
	weapon_pivot.scale.y = -1.0 if mouse_position.x < global_position.x else 1.0

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
	if event.is_action_pressed("weapon_saber"):
		equip_weapon(Weapon.SABER)
	elif event.is_action_pressed("weapon_orb"):
		equip_weapon(Weapon.ORB_OF_LIGHT)

func equip_weapon(weapon: Weapon) -> void:
	current_weapon = weapon
	saber.visible = weapon == Weapon.SABER
	orb_of_light.visible = weapon == Weapon.ORB_OF_LIGHT
	weapon_changed.emit(current_weapon)
	print("Equipped weapon: ", Weapon.keys()[current_weapon])

# play_hit_flash
# When player is damaged, "play" a red flash.
func play_hit_flash() -> void:
	# TODO: Modulate sprite tint to red brief color flash when damaged
	pass
