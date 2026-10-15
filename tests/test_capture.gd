extends SceneTree

func _init() -> void:
	print("Checking rendering drivers and viewport capture capability...")
	var s = load("res://scenes/CinematicIntro.tscn")
	var node = s.instantiate()
	root.add_child(node)
	_capture_steps.call_deferred(node)

func _capture_steps(controller: Node) -> void:
	for i in range(10):
		await process_frame
	
	var vp = root.get_viewport()
	var img = vp.get_texture().get_image()
	if img:
		print("Image captured! Size: ", img.get_size(), " Format: ", img.get_format())
		DirAccess.make_dir_absolute("user://cinematic_shots")
		img.save_png("user://cinematic_shots/test_cap.png")
		print("Saved to user://cinematic_shots/test_cap.png")
	else:
		print("Viewport texture get_image() returned null in current mode.")
	quit(0)
