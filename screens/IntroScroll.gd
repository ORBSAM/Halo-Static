extends StoryScroll

func _ready() -> void:
	theme = PaperTheme.build(true)        # dark paper (pause menu, win screen)

	story_text = """In a realm fractured by chaotic frequencies,
the balance of harmony was shattered...

As the last Harmonic Sentinel, you must navigate
the echoing chambers of the ancient spire,
defeat the corrupted entities within,
and restore equilibrium before all falls into permanent discord."""
	super()

func _on_done() -> void:
	if DungeonManager:
		DungeonManager.start_new_game()
