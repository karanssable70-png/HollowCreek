extends SceneTree

## Tool to capture screenshots of all cinematic shots for visual audit
const SCREENSHOT_DIR := "res://cinematic_screenshots/"

func _init() -> void:
	print("=== STARTING CINEMATIC SCREENSHOT CAPTURE ===")
	DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	_run_captures.call_deferred()

func _run_captures() -> void:
	var s: PackedScene = load("res://scenes/CinematicIntro.tscn")
	if s == null:
		print("ERROR: Failed to load CinematicIntro.tscn")
		quit(1)
		return

	var intro = s.instantiate()
	root.add_child(intro)

	var controller: CinematicController = intro as CinematicController
	if controller == null:
		print("ERROR: Not CinematicController")
		quit(1)
		return

	# Stop auto_play and engine process so we control timeline directly
	controller.auto_play = false
	controller.set_process(false)

	# We define timestamps to capture
	var capture_points = [
		{"time": 0.5,  "name": "shotA_01_letter_start"},
		{"time": 2.0,  "name": "shotA_02_letter_mid"},
		{"time": 3.8,  "name": "shotA_03_letter_close"},
		{"time": 4.8,  "name": "shotB_01_handover_start"},
		{"time": 6.8,  "name": "shotB_02_handover_transfer"},
		{"time": 8.5,  "name": "shotB_03_inspection_seal"},
		{"time": 9.8,  "name": "shotB_04_mercenary_hood"},
		{"time": 10.8, "name": "shotC_01_boot_gravel"},
		{"time": 12.8, "name": "shotC_02_rear_tracking"},
		{"time": 15.0, "name": "shotC_03_wide_crags"},
		{"time": 17.5, "name": "shotD_01_ledge_pose_start"},
		{"time": 20.5, "name": "shotD_02_reveal_orbit"},
		{"time": 24.0, "name": "shotD_03_village_panorama"},
		{"time": 26.0, "name": "shotE_01_knife_closeup"},
		{"time": 28.0, "name": "shotE_02_victim_reveal"},
		{"time": 30.5, "name": "shotE_03_standing_over_body"},
		{"time": 33.0, "name": "shotF_01_title_card"}
	]

	# Start cinematic at t = 0
	controller.start_cinematic()
	controller.set_process(false)

	var vp = root.get_viewport()

	for cp in capture_points:
		var target_t: float = cp["time"]
		controller.total_elapsed = target_t
		controller._update_cinematic(target_t, 0.0)

		# Make sure fade is cleared for in-scene captures
		if not cp["name"].begins_with("shotF"):
			controller.fade_rect.color.a = 0.0
		else:
			controller.fade_rect.color.a = 1.0
			controller.title_container.modulate.a = 1.0

		for f in range(2):
			await process_frame

		var img = vp.get_texture().get_image()
		if img:
			var path = SCREENSHOT_DIR + cp["name"] + ".png"
			img.save_png(path)
			print("  [CAPTURED] ", cp["name"], " at t=", target_t, "s -> ", path)
		else:
			print("  [FAILED] Could not get image for ", cp["name"])

	print("\n=== ALL CAPTURES FINISHED ===")
	quit(0)
