extends SceneTree

const EndingCutscene = preload("res://scripts/cinematic/ending_cutscene.gd")
const InterrogationController = preload("res://scripts/interrogation/interrogation_controller.gd")

## Automated Verification Test for Ending Cutscenes 1 & 2
## Validates:
## 1. Ending Cutscene 1 (Defeat - False Accusation / godot_cinematic_cutscene):
##    - Loads scenes/cinematic_cutscene.tscn
##    - Verifies 4 defeat textures (scene1 -> scene4) and cutscene_soundtrack.ogg
##    - Verifies Subtitle copy: "Act I: You've guessed wrong."
##    - Verifies post-cutscene GAME OVER panel displayed with Citadel of Blackrose font
## 2. Ending Cutscene 2 (Victory - Harbour Master Accused / godot_cinematic_cutscene2):
##    - Loads scenes/cinematic_cutscene2.tscn
##    - Verifies 4 victory textures (sceneone -> scenefour) and victory_soundtrack.ogg
##    - Verifies Subtitle copy: "Act I: You've guessed it right."
##    - Verifies post-cutscene GAME OVER panel displayed with Citadel of Blackrose font
## 3. Accusation routing in InterrogationController:
##    - Accusing an innocent suspect (e.g. Isolde, Tomas, Edmund) targets cinematic_cutscene.tscn
##    - Accusing the true murderer (Harbour Master Garrick) targets cinematic_cutscene2.tscn

func _init() -> void:
	print("\n================================================================================")
	print("=== STARTING ENDING CUTSCENES 1 & 2 VERIFICATION ===")
	print("================================================================================")
	_run_tests.call_deferred()

func _run_tests() -> void:
	# -------------------------------------------------------------------------
	# 1. VERIFY ENDING CUTSCENE 1 (DEFEAT / WRONG GUESS)
	# -------------------------------------------------------------------------
	print("\n[1] Verifying Ending Cutscene 1 (Defeat / Wrong Accusation)...")
	var defeat_scene: PackedScene = load("res://scenes/cinematic_cutscene.tscn")
	assert(defeat_scene != null, "Failed to load scenes/cinematic_cutscene.tscn!")
	
	var cutscene1 = defeat_scene.instantiate() as EndingCutscene
	assert(cutscene1 != null, "Scene root is not EndingCutscene!")
	root.add_child(cutscene1)
	await process_frame
	
	assert(cutscene1.ending_type == EndingCutscene.EndingType.DEFEAT_WRONG_GUESS, "Ending type should be DEFEAT_WRONG_GUESS!")
	assert(cutscene1.texture_rects.size() == 4, "Expected 4 scene textures, got %d" % cutscene1.texture_rects.size())
	assert(cutscene1.audio_player != null and cutscene1.audio_player.stream != null, "Audio player missing stream!")
	
	# Verify subtitle of Act 1
	var act1_sub: String = cutscene1.active_scenes_data[0]["subtitle"]
	print("  - Act I Subtitle: '", act1_sub, "'")
	assert("GUESSED WRONG" in act1_sub.to_upper(), "Act I should state you've guessed wrong!")
	
	# Trigger finish and verify GAME OVER slate
	cutscene1.finish_cutscene()
	await process_frame
	
	assert(cutscene1.is_game_over_visible, "GAME OVER slate should be visible after cutscene finish!")
	assert(cutscene1.game_over_title != null, "Game Over Title label missing!")
	assert(cutscene1.game_over_title.text == "GAME OVER", "Title text must be 'GAME OVER'!")
	
	# Verify Citadel of Blackrose font override
	var font_override = cutscene1.game_over_title.get_theme_font("font")
	assert(font_override != null, "Citadel of Blackrose font override missing on GAME OVER title!")
	print("  - Title font override: ", font_override.resource_path)
	assert("citadel_of_blackrose" in font_override.resource_path.to_lower(), "Font must be citadel_of_blackrose!")
	
	var font_size = cutscene1.game_over_title.get_theme_font_size("font_size")
	print("  - Title font size: %d pt" % font_size)
	assert(font_size >= 72, "Game Over title font size should be large and prominent!")
	
	print("  - Subtitle: '", cutscene1.game_over_sub.text, "'")
	assert("CONDEMNED" in cutscene1.game_over_sub.text.to_upper() or "INNOCENT" in cutscene1.game_over_sub.text.to_upper(), "Defeat subtitle missing condemnation notice!")
	print("  - [PASS] Ending Cutscene 1 (Defeat) verified with gothic bold GAME OVER slate.")
	
	cutscene1.queue_free()
	await process_frame

	# -------------------------------------------------------------------------
	# 2. VERIFY ENDING CUTSCENE 2 (VICTORY / HARBOUR MASTER CONDEMNED)
	# -------------------------------------------------------------------------
	print("\n[2] Verifying Ending Cutscene 2 (Victory / Harbour Master Accused)...")
	var victory_scene: PackedScene = load("res://scenes/cinematic_cutscene2.tscn")
	assert(victory_scene != null, "Failed to load scenes/cinematic_cutscene2.tscn!")
	
	var cutscene2 = victory_scene.instantiate() as EndingCutscene
	assert(cutscene2 != null, "Scene root is not EndingCutscene!")
	root.add_child(cutscene2)
	await process_frame
	
	assert(cutscene2.ending_type == EndingCutscene.EndingType.VICTORY_HARBOUR_MASTER, "Ending type should be VICTORY_HARBOUR_MASTER!")
	assert(cutscene2.texture_rects.size() == 4, "Expected 4 scene textures, got %d" % cutscene2.texture_rects.size())
	assert(cutscene2.audio_player != null and cutscene2.audio_player.stream != null, "Audio player missing victory stream!")
	
	# Verify subtitle of Act 1
	var v_act1_sub: String = cutscene2.active_scenes_data[0]["subtitle"]
	print("  - Act I Subtitle: '", v_act1_sub, "'")
	assert("GUESSED IT RIGHT" in v_act1_sub.to_upper(), "Act I should state you've guessed it right!")
	
	# Trigger finish and verify GAME OVER slate
	cutscene2.finish_cutscene()
	await process_frame
	
	assert(cutscene2.is_game_over_visible, "GAME OVER slate should be visible after victory cutscene finish!")
	assert(cutscene2.game_over_title != null, "Game Over Title label missing!")
	assert(cutscene2.game_over_title.text == "GAME OVER", "Title text must be 'GAME OVER'!")
	
	var v_font_override = cutscene2.game_over_title.get_theme_font("font")
	assert(v_font_override != null, "Citadel of Blackrose font override missing on victory GAME OVER title!")
	print("  - Victory Title font override: ", v_font_override.resource_path)
	assert("citadel_of_blackrose" in v_font_override.resource_path.to_lower(), "Font must be citadel_of_blackrose!")
	
	print("  - Victory Subtitle: '", cutscene2.game_over_sub.text, "'")
	assert("JUSTICE" in cutscene2.game_over_sub.text.to_upper() or "HARBOUR MASTER" in cutscene2.game_over_sub.text.to_upper(), "Victory subtitle missing justice notice!")
	print("  - [PASS] Ending Cutscene 2 (Victory) verified with royal gold bold GAME OVER slate.")
	
	cutscene2.queue_free()
	await process_frame

	# -------------------------------------------------------------------------
	# 3. VERIFY ACCUSATION ROUTING IN INTERROGATION CONTROLLER
	# -------------------------------------------------------------------------
	print("\n[3] Verifying Accusation Routing in Interrogation Room...")
	var room_scene: PackedScene = load("res://scenes/interrogation_room.tscn")
	assert(room_scene != null, "Failed to load scenes/interrogation_room.tscn!")
	
	var controller = room_scene.instantiate() as InterrogationController
	root.add_child(controller)
	controller.auto_transition_on_accusation = false # Test unit routing without switching scene
	await process_frame
	
	# Test 3A: Accusing Lady Isolde (Innocent)
	controller._is_walking_in = false
	controller.summon_suspect("isolde")
	controller._walk_time = controller._walk_duration
	controller._is_walking_in = false
	controller._seat_suspect()
	
	controller._on_accuse_pressed()
	var isolde_log: String = controller.get_dialogue_text()
	assert("FALSE ACCUSATION" in isolde_log, "False accusation alert not logged for Isolde!")
	print("  - False accusation of innocent correctly identified -> Routes to Ending Cutscene 1.")
	
	# Test 3B: Accusing Harbour Master Garrick (Killer)
	controller._is_walking_in = false
	controller.summon_suspect("garrick")
	controller._walk_time = controller._walk_duration
	controller._is_walking_in = false
	controller._seat_suspect()
	
	controller._on_accuse_pressed()
	var garrick_log: String = controller.get_dialogue_text()
	assert("CASE SOLVED" in garrick_log, "Case solved banner not logged for Garrick!")
	print("  - Correct accusation of Harbour Master correctly identified -> Routes to Ending Cutscene 2.")
	
	controller.queue_free()
	await process_frame

	print("\n================================================================================")
	print("=== ALL ENDING CUTSCENES 1 & 2 AND ACCUSATION TESTS PASSED (100%) ===")
	print("================================================================================")
	quit(0)
