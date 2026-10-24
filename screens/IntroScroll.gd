extends StoryScroll

# ==========================================
# INTRO SCROLL
# Handles the intro scroll logic. Extends the story scroll script
# ==========================================

# _ready
# plaster the script into the scroll box here
func _ready() -> void:
	theme = PaperTheme.build(true)        # dark paper (pause menu, win screen)

	story_text = """Long before the first dawn,
the heavens were kept by archangels.

Each one was given a gift,
and a duty to guard the world below.

One of them grew weary of the quiet.

He called it peace.
He began to call it a cage.

So he turned to the darkness,
and the darkness answered.

From his shadow he conjured spirits,
restless things with hollow eyes
that crept down into the world
and into every heart they could find.

Fear spread. Villages emptied.
The light grew thin.

The remaining angels were too few,
and too far from the earth to stop him.

So one of them did something desperate.

In a forgotten toy shop,
there sat a doll, cracked and patient,
waiting for someone to love it.

The angel entered her,
and gave her a shard of light
set upon her brow.

It woke her.
It armed her.
It gave her a name: Sentinel.

She did not choose this.
But she can stand, and she can fight,
and she is the only one close enough
to reach him.

Now the spire waits,
and at its summit, his chamber.

Cut through the spirits.
Take the key.
End what he began.

The light is counting on you."""
	super()

# _on_done
# start a new game after the introduction
func _on_done() -> void:
	if DungeonManager:
		DungeonManager.start_new_game()
