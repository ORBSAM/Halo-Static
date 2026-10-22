extends StoryScroll

# ==========================================
# INTRO SCROLL
# Handles the intro scroll logic. Extends the story scroll script
# ==========================================

# _ready
# plaster the script into the scroll box here
func _ready() -> void:
	theme = PaperTheme.build(true)        # dark paper (pause menu, win screen)

	story_text = """In a realm fractured by chaotic frequencies,
the balance of harmony was shattered...

As the last Harmonic Sentinel, you must navigate
the echoing chambers of the ancient spire,
defeat the corrupted entities within,
and restore equilibrium before all falls into permanent discord."""
	super()

# _on_done
# start a new game after the introduction
func _on_done() -> void:
	if DungeonManager:
		DungeonManager.start_new_game()
