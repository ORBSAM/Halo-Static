extends StoryScroll

# ==========
# CLIFFHANGER SCROLL
# a descendent from story scroll; handles the cliffhanger text you see
# before the credits
# ==========

# _ready
# build theme, and plaster text on the scroll block
func _ready() -> void:
	theme = PaperTheme.build()
	
	story_text = """The archangel falls to his knees.

The darkness around him unravels,
and the spirits fade like smoke.

For a moment, the chamber is quiet.

He looks up at you.
Not with hatred, but with something like relief.

"You think I was the one who wanted this?"

The marble cracks beneath him.
A seam of red light spreads across the floor.

He does not fight it.
He sinks, slowly,
down through the stone,
down past the foundations of the spire,
into a place the heavens never speak of.

Hell.

The shard on your brow flickers,
then goes dark.

Far below, something answers.

It is older than the archangels.
It is patient.
And it has been waiting for him
to open the door.

You step to the edge of the pit.

The doll's cracked hands shake.
The angel within her is silent.

There is no one left to tell you what to do.

But you are still standing.

And the way down is open."""      # write your own
	super()

# _on_done
# when done, go to the credits
func _on_done() -> void:
	get_tree().change_scene_to_file("res://screens/credits.tscn")
