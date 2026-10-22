class_name Item
extends Area2D

# ==========================================
# ITEM
# Handles all item logic. Harmonic, chaotic, and key.
# ==========================================

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

# color mapping for placeholders and glow
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

const ITEM_LAYER := 1 << 4   # layer 5; check Project Settings > Layer Names that it's free


# _ready
# add the items to the item group, and update item based on a roll of the die
func _ready() -> void:
	add_to_group("items")
	body_entered.connect(_on_body_entered)
	update_item_appearance()

# update_item_appearance
# update appearance of items based on their type
func update_item_appearance() -> void:
	var item_color = TYPE_COLORS.get(item_type, Color.WHITE)
	item_name = TYPE_NAMES.get(item_type, "Item")
	
	# 1. update ColorRect placeholder (if using ColorRect)
	if color_rect:
		color_rect.color = item_color
		
	# 2. update Sprite tint (if using Sprite2D)
	if sprite:
		sprite.modulate = item_color

	# 3. update PointLight2D glow color and energy
	if light:
		light.color = item_color
		light.energy = 1.5
	
	# only chaotic items can be shot or slashed
	if item_type == ItemType.CHAOTIC:
		add_to_group("destructible")
	else:
		remove_from_group("destructible")

# _on_body_entered
# only player collects items
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

# collect
# handle all collection logic.
func collect(player: Node2D) -> void:
	match item_type:
		ItemType.HARMONIC:
			if player.has_method("add_harmonic_energy") and player.has_method("heal"):
				player.add_harmonic_energy(value)
				player.heal(value)
				AudioManager.play_sfx("pickup_good")
				print("Picked up Harmonic Shard (+", value, " energy & health)")
		ItemType.CHAOTIC:
			if player.has_method("take_damage"):
				player.take_damage(value)
				AudioManager.play_sfx("pickup_bad")
				print("Picked up Chaotic Essence (-", value, " HP)")
		ItemType.KEY:
			if player.has_method("add_key"):
				player.add_key(1)
				AudioManager.play_sfx("key")
				print("Picked up Dungeon Key!")
	
	# general inventory tracking call if used
	if player.has_method("add_item"):
		player.add_item(item_type)
	
	# free item
	queue_free()

# is_consumable
# consumable by the enemy?
func is_consumable() -> bool:
	return item_type == ItemType.CHAOTIC and not _destroyed

# consume_by_enemy
# let the enemy consume the chaotic items
func consume_by_enemy() -> void:
	if _destroyed:
		return
	_destroyed = true
	set_deferred("monitoring", false)
	queue_free()

# take_damage
# make sure that it can take damage as a chaotic item
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
