extends Area2D

# ==========================================
# ENEMY PROJECTILE
# A simple glowing orb fired by the boss. Built entirely in code,
# so it needs no scene or art. Hurts the player, disappears on walls.
# ==========================================

var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var damage: float = 10.0
var lifetime: float = 4.0
var radius: float = 6.0
var color: Color = Color(0.95, 0.15, 0.45)

# _ready
func _ready() -> void:
	# tagged so the DungeonManager can clear it on room transitions
	add_to_group("projectiles")

	# detect walls (layers 1 & 2) and the player; never hit other enemies
	collision_layer = 0
	collision_mask = 3
	z_index = 3

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)
	queue_redraw()

# _physics_process
func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

# _draw
# soft glow + solid core
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 1.7, Color(color, 0.25))
	draw_circle(Vector2.ZERO, radius, color)

# _on_body_entered
func _on_body_entered(body: Node2D) -> void:
	# boss projectiles pass through other enemies
	if body.is_in_group("enemies"):
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	else:
		# hit a wall
		queue_free()
