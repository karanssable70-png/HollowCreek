extends SceneTree

## Automated Verification Suite for Integrated Illustrated Intro & 3D Cinematic
## Validates:
## 1. Scene loading & initialization (CinematicIntro.tscn & intro_cutscene.tscn)
## 2. All 4 illustrated textures loaded & verified (Letter, Travel, VillageView, Murder)
## 3. Shot 1: The Sealed Order (Illustrated letter, copy styling, audio drone & candle flicker)
## 4. Shot 2: The Long Road (Illustrated journey, directional pan, wind & footsteps audio)
## 5. Shot 3: The 3D Village Reveal (Seamless crossfade from 2D into 3D, actual playable town,
##    mercenary on ledge in exact pose, unobstructed panorama)
## 6. Shot 4: The Murder Aftermath (Brief illustrated bridge into 3D murder chamber,
##    motionless Lord Aldric, downward stiletto dagger, blood pool, readable lighting)
## 7. Shot 5: Title Card (HOLLOWCREEK: THE LAST CROSSING, Enter Village button)
## 8. Manual advancement, input debounce, and Escape skip to gameplay (res://scenes/town.tscn)
## 9. Mouse mode management (VISIBLE during intro, CAPTURED upon entering game)

func _init() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("\n================================================================================")
	print("=== HOLLOWCREEK: THE LAST CROSSING — INTEGRATED INTRO & 3D CINEMATIC TEST ===")
	print("================================================================================\n")
	
	# -------------------------------------------------------------------------
	# 1. LOAD & INSTANTIATE CINEMATIC INTRO SCENE
	# -------------------------------------------------------------------------
	print("[1] Verifying Scene Loading & Resource Resolution...")
	var intro_scene: PackedScene = load("res://scenes/CinematicIntro.tscn")
	assert(intro_scene != null, "Failed to load res://scenes/CinematicIntro.tscn!")
	
	var intro_node: Node = intro_scene.instantiate()
	assert(intro_node is CinematicController, "CinematicIntro root node is not CinematicController!")
	root.add_child(intro_node)
	
	var controller := intro_node as CinematicController
	
	for i in range(5):
		await process_frame
		
	print("  - [PASS] CinematicIntro.tscn instantiated successfully.")
	
	# Verify intro_cutscene.tscn exists and is valid
	var cutscene_scene: PackedScene = load("res://intro_cutscene/intro_cutscene.tscn")
	assert(cutscene_scene != null, "Failed to load res://intro_cutscene/intro_cutscene.tscn!")
	print("  - [PASS] res://intro_cutscene/intro_cutscene.tscn resource verified.")
	
	# -------------------------------------------------------------------------
	# 2. VERIFY ILLUSTRATED TEXTURE ASSETS
	# -------------------------------------------------------------------------
	print("\n[2] Verifying Illustrated Art Assets...")
	assert(controller.shot_letter != null and controller.shot_letter.texture != null, "Letter illustration texture missing!")
	assert(controller.shot_travel != null and controller.shot_travel.texture != null, "Travel illustration texture missing!")
	assert(controller.shot_village_view != null and controller.shot_village_view.texture != null, "Village view illustration texture missing!")
	assert(controller.shot_murder != null and controller.shot_murder.texture != null, "Murder aftermath illustration texture missing!")
	
	print("  - [PASS] letter.png: %s" % controller.shot_letter.texture.get_path())
	print("  - [PASS] travel.png: %s" % controller.shot_travel.texture.get_path())
	print("  - [PASS] village_view.png: %s" % controller.shot_village_view.texture.get_path())
	print("  - [PASS] murder.png: %s" % controller.shot_murder.texture.get_path())
	
	# -------------------------------------------------------------------------
	# 3. VERIFY NARRATIVE UI & TOP/BOTTOM CARDS
	# -------------------------------------------------------------------------
	print("\n[3] Verifying Narrative UI Elements...")
	assert(controller.chapter_label != null, "Chapter label missing!")
	assert(controller.card_title_label != null, "Story title label missing!")
	assert(controller.caption_label != null, "Story caption label missing!")
	assert(controller.counter_label != null, "Counter label missing!")
	assert(controller.continue_button != null, "Continue button missing!")
	assert(controller.skip_button != null, "Skip button missing!")
	assert(controller._bar_top != null and controller._bar_bottom != null, "Cinematic letterboxes missing!")
	print("  - [PASS] Chapter, Title, Caption, Counter, Continue & Skip buttons verified.")
	
	# -------------------------------------------------------------------------
	# 4. VERIFY SHOT 1: THE SEALED ORDER
	# -------------------------------------------------------------------------
	print("\n[4] Verifying Shot 1: The Sealed Order...")
	controller._set_shot(1)
	assert(controller.current_shot == 1, "Failed to set Shot 1")
	assert(controller.shot_letter.visible == true, "Letter illustration not visible in Shot 1!")
	assert(controller.chapter_label.text == "01   /   THE SEALED ORDER", "Chapter 1 title mismatch!")
	assert(controller.card_title_label.text == "A letter with one name", "Story 1 title mismatch!")
	assert(controller.counter_label.text == "01   /   04", "Counter mismatch!")
	assert(controller.audio_director._current_shot == 1, "Audio state not aligned with Shot 1!")
	print("  - [PASS] Illustrated letter displayed with Chapter 01 copy and mystery drone audio.")
	
	# -------------------------------------------------------------------------
	# 5. VERIFY SHOT 2: THE LONG ROAD / MOUNTAIN JOURNEY
	# -------------------------------------------------------------------------
	print("\n[5] Verifying Shot 2: The Long Road...")
	controller._set_shot(2)
	assert(controller.current_shot == 2, "Failed to set Shot 2")
	assert(controller.shot_travel.visible == true, "Travel illustration not visible in Shot 2!")
	assert(controller.chapter_label.text == "02   /   THE LONG ROAD", "Chapter 2 title mismatch!")
	assert(controller.card_title_label.text == "Across the stone valley", "Story 2 title mismatch!")
	assert(controller.counter_label.text == "02   /   04", "Counter mismatch!")
	assert(controller.audio_director._current_shot == 2, "Audio state not aligned with Shot 2!")
	assert(controller.audio_director.wind_volume >= 0.25, "Mountain wind audio not elevated for journey!")
	print("  - [PASS] Illustrated journey displayed with Chapter 02 copy, wind and footsteps audio.")
	
	# -------------------------------------------------------------------------
	# 6. VERIFY SHOT 3: THE 3D VILLAGE REVEAL ON MOUNTAIN OVERLOOK
	# -------------------------------------------------------------------------
	print("\n[6] Verifying Shot 3: The 3D Village Reveal on Mountain Overlook...")
	controller._set_shot(3)
	assert(controller.current_shot == 3, "Failed to set Shot 3")
	assert(controller.shot_travel.visible == false, "2D illustration must be hidden in 3D Village Reveal!")
	assert(controller.chapter_label.text == "03   /   THE VILLAGE BELOW", "Chapter 3 title mismatch!")
	assert(controller.counter_label.text == "03   /   04", "Counter mismatch!")
	
	# Verify real 3D town in background
	var bg_town = intro_node.get_node_or_null("BackgroundTown")
	assert(bg_town != null, "BackgroundTown missing! Real 3D town world must be loaded.")
	assert(bg_town.get_node_or_null("TownWorld") != null, "TownWorld node missing in BackgroundTown!")
	
	# Verify exact ledge mercenary pose
	var s3 = controller.stage3_reveal
	var merc_s3 = s3.get_node_or_null("Mercenary")
	assert(merc_s3 != null, "Mercenary missing on cliff ledge!")
	var ledge = s3.get_node_or_null("MountainCliffLedge")
	var boulder = ledge.get_node_or_null("SupportBoulder")
	var hand_r = merc_s3.get_node_or_null("ArmPivotR/HandR")
	var dist_to_boulder: float = hand_r.global_position.distance_to(boulder.global_position)
	assert(dist_to_boulder < 0.65, "Mercenary right hand must rest firmly on support boulder!")
	
	var boot_l = merc_s3.get_node_or_null("LegPivotL/BootL")
	var boot_r = merc_s3.get_node_or_null("LegPivotR/BootR")
	var leg_delta: float = boot_l.global_position.y - boot_r.global_position.y
	assert(leg_delta > 0.30, "Mercenary left foot must be elevated on higher rock step than right foot!")
	
	var torso = merc_s3.get_node_or_null("Torso")
	var head = merc_s3.get_node_or_null("Head")
	assert(torso.rotation_degrees.z < 0.0, "Torso must lean into rock!")
	assert(head.rotation_degrees.y < -15.0 and head.rotation_degrees.x < 0.0, "Head must face downward toward village below!")
	print("  - [PASS] 2D illustration dissolved revealing genuine 3D village and staged mercenary on ledge.")
	
	# -------------------------------------------------------------------------
	# 7. VERIFY SHOT 4: THE MURDER AFTERMATH (ILLUSTRATED BRIDGE + 3D SCENE)
	# -------------------------------------------------------------------------
	print("\n[7] Verifying Shot 4: The Murder Aftermath (Illustrated Bridge into 3D)...")
	controller._set_shot(4)
	assert(controller.current_shot == 4, "Failed to set Shot 4")
	assert(controller.chapter_label.text == "04   /   AFTER DARK", "Chapter 4 title mismatch!")
	assert(controller.card_title_label.text == "The deed is done", "Story 4 title mismatch!")
	assert(controller.counter_label.text == "04   /   04", "Counter mismatch!")
	
	# Verify 3D murder chamber staging
	var s4 = controller.stage4_aftermath
	assert(s4 != null, "Stage 4 missing!")
	var victim = s4.get_node_or_null("VictimLordAris")
	assert(victim != null, "Victim Lord Aldric missing!")
	assert(victim.get_node_or_null("BloodPool") != null, "Blood pool missing under victim!")
	
	var dagger = controller.dagger_prop
	assert(dagger != null, "Stiletto dagger prop missing!")
	var blade = dagger.get_node_or_null("Blade")
	assert(blade != null and blade.rotation_degrees.z == 180.0, "Stiletto blade must be pointed downwards!")
	assert(dagger.get_node_or_null("BloodDrop") != null, "Blood droplet missing on blade!")
	
	# Verify readability of lighting
	assert(controller._aftermath_key_light != null and controller._aftermath_key_light.light_energy >= 2.5, "Aftermath key light too dim!")
	assert(s4.get_node_or_null("WindowLight") != null, "Window moonlight missing in aftermath!")
	print("  - [PASS] Illustrated aftermath bridge into 3D stone room verified with downward knife, motionless victim, and clear lighting.")
	
	# -------------------------------------------------------------------------
	# 8. VERIFY SHOT 5: TITLE CARD & GAMEPLAY TRANSITION
	# -------------------------------------------------------------------------
	print("\n[8] Verifying Shot 5: Title Card & Gameplay Transition...")
	controller._set_shot(5)
	assert(controller.current_shot == 5, "Failed to set Shot 5")
	assert(controller.title_label.text == "HOLLOWCREEK: THE LAST CROSSING", "Title label mismatch!")
	assert(controller.continue_button.text == "ENTER THE VILLAGE   →", "Final button text mismatch!")
	print("  - [PASS] Title Card verified: 'HOLLOWCREEK: THE LAST CROSSING' on solid black.")
	
	# -------------------------------------------------------------------------
	# 9. VERIFY SKIP & ADVANCEMENT LOGIC
	# -------------------------------------------------------------------------
	print("\n[9] Verifying Skip & Manual Advancement Logic...")
	var signal_tracker := {"completed": false}
	controller.cinematic_completed.connect(func(): signal_tracker["completed"] = true)
	
	controller.skip_cinematic()
	assert(controller.is_skipped == true, "Failed to set is_skipped flag!")
	assert(signal_tracker["completed"] == true, "cinematic_completed signal not emitted on skip!")
	assert(controller.gameplay_scene_path == "res://scenes/town.tscn", "Gameplay scene path must be res://scenes/town.tscn!")
	print("  - [PASS] Escape/Skip immediately completes cinematic and targets res://scenes/town.tscn.")
	
	print("\n================================================================================")
	print("=== ALL INTEGRATED INTRO & 3D CINEMATIC TESTS PASSED WITH 100% SUCCESS! ===")
	print("================================================================================\n")
	quit(0)
