class_name EnemyBase
extends CharacterBody2D

# ==========================================
# BASE ENEMY AI
# Basic 10 HP demon pathfinding and contact damage logic.
# ==========================================
@export var max_hp: int = 10
@export var speed: float = 80.0

var current_hp: int
var target_player: Node2D = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# _ready
# 
func _ready() -> void:
	current_hp = max_hp
	# find player in group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

# _physics_process
# 
func _physics_process(_delta: float) -> void:
	if current_hp <= 0 or not target_player:
		return
		
	nav_agent.target_position = target_player.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var dir = global_position.direction_to(next_path_pos)
		velocity = dir * speed
		move_and_slide()

# take_damage
# Enemy's HP subtracts from current amount
func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die()

# die
# enemy dies, and is removed. play particles.
func die() -> void:
	# Add death particle effects or drop items here
	queue_free()
