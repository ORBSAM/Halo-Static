class_name Item
extends Area2D

enum ItemType { HARMONIC, CHAOTIC, KEY }

@export var item_type: ItemType = ItemType.HARMONIC
@export var item_name: String = "Harmonic Shard"

# color tint for placeholders; not really ready quite yet
const TYPE_COLORS = {
	ItemType.HARMONIC: Color(0.2, 0.8, 1.0), # cyan color for good!
	ItemType.CHAOTIC: Color(0.9, 0.2, 0.2),  # red for bad!
	ItemType.KEY: Color(1.0, 0.85, 0.1)      # gold
}

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# apply placeholder color based on item type
	if color_rect:
		color_rect.color = TYPE_COLORS.get(item_type, Color.WHITE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node2D) -> void:
	# add custom inventory or pickup logic here
	if player.has_method("add_item"):
		player.add_item(item_type)
	
	# Play sound or effect if needed
	queue_free()
