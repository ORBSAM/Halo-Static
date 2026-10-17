class_name Item
extends Area2D

enum ItemType { HARMONIC, CHAOTIC, KEY }

@export var item_type: ItemType = ItemType.HARMONIC:
	set(value):
		item_type = value
		# automatically update visuals if node is ready in tree
		if is_node_ready():
			update_item_appearance()

@export var item_name: String
@export var value: float = 25.0

# for any item that can be destroyed; this checks if it is destroyed
var _destroyed := false


# Color mapping for placeholders and glow
const TYPE_COLORS = {
	ItemType.HARMONIC: Color(0.869, 0.626, 0.938, 1.0), # Pink
	ItemType.CHAOTIC: Color(0.9, 0.2, 0.2),  # Red
	ItemType.KEY: Color(1.0, 0.85, 0.1)      # Gold
}

const TYPE_NAMES = {
	ItemType.HARMONIC: "Harmonic Shard",
	ItemType.CHAOTIC: "Chaotic Essence",
	ItemType.KEY: "Dungeon Key"
}

@onready var color_rect: ColorRect = $ColorRect
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var light: PointLight2D = get_node_or_null("PointLight2D")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	update_item_appearance()
	
func update_item_appearance() -> void:
	var item_color = TYPE_COLORS.get(item_type, Color.WHITE)
	item_name = TYPE_NAMES.get(item_type, "Item")
	
	# 1. Update ColorRect placeholder (if using ColorRect)
	if color_rect:
		color_rect.color = item_color
		
	# 2. Update Sprite tint (if using Sprite2D)
	if sprite:
		sprite.modulate = item_color

	# 3. Update PointLight2D glow color and energy
	if light:
		light.color = item_color
		light.energy = 1.5
	
	# only chaotic items can be shot or slashed
	if item_type == ItemType.CHAOTIC:
		add_to_group("destructible")
	else:
		remove_from_group("destructible")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node2D) -> void:
	match item_type:
		ItemType.HARMONIC:
			if player.has_method("add_harmonic_energy") and player.has_method("heal"):
				player.add_harmonic_energy(value)
				player.heal(value)
				print("Picked up Harmonic Shard (+", value, " energy & health)")
		ItemType.CHAOTIC:
			if player.has_method("take_damage"):
				player.take_damage(value)
				print("Picked up Chaotic Essence (-", value, " HP)")
		ItemType.KEY:
			if player.has_method("add_key"):
				player.add_key(1)
				print("Picked up Dungeon Key!")
	
	# general inventory tracking call if used
	if player.has_method("add_item"):
		player.add_item(item_type)
	
	# free item
	queue_free()

func take_damage(_amount: float, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if item_type != ItemType.CHAOTIC or _destroyed:
		return
	
	_destroyed = true
	
	set_deferred("monitoring", false)     # can't be picked up while it pops
	set_deferred("monitorable", false)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.6, 0.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	
	tw.finished.connect(queue_free)
