extends SceneTree

func _init() -> void:
	print("Loading intro_cutscene_theme.mp3...")
	var a1 = ResourceLoader.load("res://assets/audio/intro_cutscene_theme.mp3")
	print("Intro theme: ", a1)
	
	print("Loading interrogation_chamber_theme.mp3...")
	var a2 = ResourceLoader.load("res://assets/audio/interrogation_chamber_theme.mp3")
	print("Interrogation theme: ", a2)
	
	assert(a1 != null, "Failed to load intro theme!")
	assert(a2 != null, "Failed to load interrogation theme!")
	print("SUCCESS: Both MP3 audio streams loaded and imported cleanly!")
	quit(0)
