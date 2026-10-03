extends Node2D

# set the bounds for the current room, which will later be called by the dungeon manager to set up the camera
# from the player scene
func get_bounds() -> Rect2:
	var used: Rect2i = $TileMapLayer.get_used_rect()
	var tile_size: Vector2i = $TileMapLayer.tile_set.tile_size
	return Rect2(used.position * tile_size, used.size * tile_size)
