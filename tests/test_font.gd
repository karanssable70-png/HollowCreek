extends SceneTree

func _init() -> void:
	var f = load("res://assets/fonts/citadel_of_blackrose.ttf")
	print("Loaded font: ", f)
	assert(f != null, "Font failed to load!")
	print("Font class: ", f.get_class())
	quit(0)
