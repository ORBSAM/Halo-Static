extends Node

# ==========================================
# DUNGEON MANAGER (AUTOLOAD SINGLETON)
# Manages 30-room generation, grid state, and scene loading.
# ==========================================

# TODO: Preload base room, key room, boss room, and standard variant scenes
# TODO: Create array dungeon_grid to store 30 room dictionaries
# TODO: Track current_room_index (0 to 29)

func _ready() -> void:
	# TODO: Call generate_dungeon_layout() on launch
	pass

func generate_dungeon_layout() -> void:
	# TODO: Clear previous grid array
	# TODO: Assign Room 0 as Tutorial
	# TODO: Assign Room 29 as Final Boss Chamber
	# TODO: Randomly pick index between 14-23 for Key Vault
	# TODO: Populate remaining slots with random standard room variants
	pass

func change_room(target_index: int) -> void:
	# TODO: Verify target_index is valid
	# TODO: Check if target is Boss Room (Room 29) -> verify GlobalManager.has_key
	# TODO: Trigger ScreenFader transition
	# TODO: Unload current room and instantiate target room scene
	pass
