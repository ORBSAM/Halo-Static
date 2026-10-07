class_name Item
extends Area2D

enum ItemType { HARMONIC, CHAOTIC, KEY }

@export var item_type: ItemType = ItemType.HARMONIC
@export var item_name: String = "Harmonic Shard"
@export var value: float = 25.0  # Added missing value variable

# Color tint for placeholders
const TYPE_COLORS = {
	ItemType.HARMONIC: Color(0.2, 0.8, 1.0), # cyan for harmonic
	ItemType.CHAOTIC: Color(0.9, 0.2, 0.2),  # red for chaotic
	ItemType.KEY: Color(1.0, 0.85, 0.1)      # gold for key
}

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Apply placeholder color based on item type
	if color_rect:
		color_rect.color = TYPE_COLORS.get(item_type, Color.WHITE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node2D) -> void:
	match item_type:
		ItemType.HARMONIC:
			if player.has_method("add_harmonic_energy"):
				player.add_harmonic_energy(value)
		ItemType.CHAOTIC:
			if player.has_method("take_damage"):
				player.take_damage(value)
		ItemType.KEY:
			if player.has_method("add_key"):
				player.add_key(1)
	
	# General inventory tracking call if used
	if player.has_method("add_item"):
		player.add_item(item_type)
	
	queue_free() # Remove item on pickup 
