# make sure that it extends the default room so it has the same logic
extends RoomLogic

# ==========================================
# KEY VAULT ROOM LOGIC
# Specialized room for key drops, high-value loot, and custom dialogue.
# ==========================================

# setup_room
# handle the room logic here. spawn only key item
func setup_room(coords: Vector2i, room_type: String, entry_direction: Vector2i = Vector2i.ZERO) -> void:
	update_doors(coords)

	var player = get_tree().get_first_node_in_group("player")
	if player and player_spawn:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		player.global_position = get_spawn_position_for_entry(entry_direction)

	spawn_guaranteed_key_and_loot(player)
	spawn_random_enemies()

	await get_tree().create_timer(0.5).timeout
	trigger_vault_dialogue()

func spawn_guaranteed_key_and_loot(player: Node = null) -> void:
	if item_scenes.is_empty() or not item_spawns:
		return
	var markers = item_spawns.get_children()
	if markers.is_empty():
		return

	var already_has_key: bool = _player_has_key(player)
	
	for i in range(markers.size()):
		var is_key := (i == 0)
		if is_key and already_has_key:
			continue   # don't respawn the key once it's been picked up

		var item = item_scenes.pick_random().instantiate()
		item.item_type = Item.ItemType.KEY if is_key else Item.ItemType.HARMONIC
		add_child(item)
		item.global_position = markers[i].global_position
		if item.has_method("update_item_appearance"):
			item.update_item_appearance()

func spawn_test_entities() -> void:
	spawn_guaranteed_key_and_loot()
	spawn_random_enemies()

func trigger_vault_dialogue() -> void:
	var dialogue_ui = get_node_or_null("/root/DialogueLogic")
	if not dialogue_ui or dialogue_ui.is_active:
		return
	var player = _get_player() 
	if _player_has_key(player):
		return   # no need to repeat the hint once they have the key
	dialogue_ui.start_dialogue("Protagonist", [
		"This vault... it resonates with intense harmonic frequency.",
		"I should search for the key to the main chamber here."
	], false)

func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _player_has_key(player: Node) -> bool:
	return player != null and player.get("has_dungeon_key") == true
