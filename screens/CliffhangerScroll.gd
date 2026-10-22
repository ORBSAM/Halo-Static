extends StoryScroll

func _ready() -> void:
	theme = PaperTheme.build()
	
	story_text = """The Sentinel stands victorious...

but the silence that follows is wrong.

	get_tree().change_scene_to_file("res://screens/title_screen.tscn")
Beneath the spire, something older stirs,
and it has been listening
to every ."""        # write your own
	super()

func _on_done() -> void:
	get_tree().change_scene_to_file("res://screens/credits.tscn")
