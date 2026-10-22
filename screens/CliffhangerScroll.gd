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
	
	story_text = """The Sentinel stands victorious...

but the silence that follows is wrong.

	get_tree().change_scene_to_file("res://screens/title_screen.tscn")
Beneath the spire, something older stirs,
and it has been listening
to every ."""        # write your own
	super()

# _on_done
# when done, go to the credits
func _on_done() -> void:
	get_tree().change_scene_to_file("res://screens/credits.tscn")
