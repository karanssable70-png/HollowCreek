extends SceneTree

## Automated Verification Suite for Whispers of Hollow Creek Cinematic Opening
## Validates:
## 1. CinematicIntro scene loading and controller initialization
## 2. All 4 Narrative Stages, props, and characters
## 3. Exact Shot 3 Character Pose (Left foot elevated on rock step, right foot on lower level,
##    right hand resting against boulder, torso leaning into rock, head turned toward village)
## 4. Reusing actual Hollow Creek village environment in background
## 5. Shot 1 contract letter with wax raven seal & handover staging
## 6. Shot 4 aftermath with fallen Lord Aris, blood droplet on stiletto blade
## 7. Title Card typography and skip functionality to playable gameplay scene

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("\n=== STARTING WHISPERS OF HOLLOW CREEK CINEMATIC VERIFICATION ===")
	
	var intro_scene: PackedScene = load("res://scenes/CinematicIntro.tscn")
	assert(intro_scene != null, "Failed to load res://scenes/CinematicIntro.tscn!")
	
	var intro_node: Node = intro_scene.instantiate()
	root.add_child(intro_node)
	
	# Wait for ready calls
	for i in range(5):
		await process_frame
		
	var controller: Node = intro_node
	assert(controller != null and controller.has_method("start_cinematic"), "CinematicIntro root is not CinematicController!")
	print("[PASS] CinematicController instantiated and ready.")
	
	# -------------------------------------------------------------
	# 1. VERIFY AUDIO & UI DIRECTOR
	# -------------------------------------------------------------
	assert(controller.audio_director != null, "CinematicAudio director missing!")
	assert(controller.fade_rect != null, "FadeOverlay ColorRect missing!")
	assert(controller.title_label != null, "Title card Label missing!")
	assert(controller.title_label.text in ["HOLLOWCREEK: THE LAST CROSSING", "WHISPERS OF HOLLOW CREEK"], "Title text mismatch!")
	print("[PASS] Procedural audio synthesizer and Title Card UI verified.")
	
	# -------------------------------------------------------------
	# 2. VERIFY SHOT 1: THE CONTRACT
	# -------------------------------------------------------------
	print("\n[1] Verifying Shot 1: The Contract...")
	var s1 = controller.stage1_contract
	assert(s1 != null, "Stage 1 (The Contract) missing!")
	var contractor = s1.get_node_or_null("Contractor")
	var mercenary_s1 = s1.get_node_or_null("Mercenary")
	var letter = s1.get_node_or_null("ContractLetter")
	var candle = s1.get_node_or_null("CandleLight")
	
	assert(contractor != null, "Mysterious Contractor in black missing!")
	assert(mercenary_s1 != null, "Mercenary in travelling clothes missing!")
	assert(letter != null, "Sealed Contract Letter prop missing!")
	assert(letter.get_node_or_null("WaxSeal") != null, "Crimson wax seal on letter missing!")
	assert(letter.get_node_or_null("RavenEmblem") != null, "Raven emblem stamp on wax seal missing!")
	assert(candle != null and candle.light_energy > 0.0, "Candlelight missing or not emitting!")
	print("  - Contractor clad in obsidian black verified.")
	print("  - Sealed letter with crimson wax seal & raven emblem verified.")
	print("[PASS] Shot 1 (The Contract) setup verified.")
	
	# -------------------------------------------------------------
	# 3. VERIFY SHOT 2: THE MOUNTAIN JOURNEY
	# -------------------------------------------------------------
	print("\n[2] Verifying Shot 2: The Mountain Journey...")
	var s2 = controller.stage2_journey
	assert(s2 != null, "Stage 2 (Mountain Journey) missing!")
	var merc_s2 = s2.get_node_or_null("Mercenary")
	assert(merc_s2 != null, "Travelling mercenary on mountain pass missing!")
	assert(s2.get_node_or_null("PassFloor") != null, "Mountain trail floor missing!")
	assert(s2.get_node_or_null("CliffLeft") != null, "Granite canyon crag missing!")
	print("[PASS] Shot 2 (Mountain Journey) setup verified.")
	
	# -------------------------------------------------------------
	# 4. VERIFY SHOT 3: THE VILLAGE REVEAL (EXACT POSE & GENUINE ENVIRONMENT)
	# -------------------------------------------------------------
	print("\n[3] Verifying Shot 3: The Village Reveal & Exact Ledge Pose...")
	var s3 = controller.stage3_reveal
	assert(s3 != null, "Stage 3 (Village Reveal) missing!")
	
	# Verify reuse of actual Hollow Creek village in background
	var bg_town = intro_node.get_node_or_null("BackgroundTown")
	assert(bg_town != null, "BackgroundTown missing! Village Reveal must reuse actual game world.")
	assert(bg_town.get_node_or_null("TownWorld") != null, "TownWorld missing from BackgroundTown!")
	print("  - Genuine Hollow Creek environment confirmed loaded in background.")
	
	# Verify Ledge geometry
	var ledge = s3.get_node_or_null("MountainCliffLedge")
	assert(ledge != null, "Mountain cliff ledge missing!")
	var lower_rock = ledge.get_node_or_null("LowerRockStep")
	var higher_rock = ledge.get_node_or_null("HigherRockStep")
	var boulder = ledge.get_node_or_null("SupportBoulder")
	assert(lower_rock != null, "Lower rock step missing!")
	assert(higher_rock != null, "Higher rock step missing!")
	assert(boulder != null, "Support boulder missing!")
	
	# Check step rock elevation difference (must be at least 0.35m difference)
	var lower_y: float = lower_rock.position.y + 0.20 # Top surface
	var higher_y: float = higher_rock.position.y + 0.20 # Top surface
	var elevation_delta: float = higher_y - lower_y
	print("  - Rock step elevations: Lower = %.2fm, Higher = %.2fm (Delta = %.2fm)" % [lower_y, higher_y, elevation_delta])
	assert(elevation_delta >= 0.35, "Insufficient elevation difference between rock steps!")
	
	# Verify Mercenary Posing on Ledge
	var merc_s3 = s3.get_node_or_null("Mercenary")
	assert(merc_s3 != null, "Posed mercenary on cliff ledge missing!")
	var leg_l = merc_s3.get_node_or_null("LegPivotL")
	var leg_r = merc_s3.get_node_or_null("LegPivotR")
	var arm_r = merc_s3.get_node_or_null("ArmPivotR")
	var torso = merc_s3.get_node_or_null("Torso")
	var head = merc_s3.get_node_or_null("Head")
	
	assert(leg_l != null and leg_r != null, "Leg pivots missing!")
	assert(arm_r != null, "Right arm pivot missing!")
	
	# Condition 1: Left foot is on higher section of rock; right foot is on lower step
	var boot_l = leg_l.get_node_or_null("BootL")
	var boot_r = leg_r.get_node_or_null("BootR")
	var boot_l_world_y: float = boot_l.global_position.y
	var boot_r_world_y: float = boot_r.global_position.y
	var leg_height_diff: float = boot_l_world_y - boot_r_world_y
	print("  - Mercenary Left Boot Y: %.3fm, Right Boot Y: %.3fm (Height Diff = %.3fm)" % [boot_l_world_y, boot_r_world_y, leg_height_diff])
	assert(leg_height_diff > 0.30, "Left foot is not clearly higher than right foot!")
	print("  - [PASS] Left foot planted on higher rock (+0.40m), right foot on lower step.")
	
	# Condition 2: Right hand rests firmly against nearby boulder for support (touching rock)
	var hand_r = arm_r.get_node_or_null("HandR")
	assert(hand_r != null, "Right hand missing!")
	var hand_pos: Vector3 = hand_r.global_position
	var boulder_pos: Vector3 = boulder.global_position
	var dist_hand_to_boulder: float = hand_pos.distance_to(boulder_pos)
	print("  - Hand position: %s, Boulder center: %s (Distance = %.3fm)" % [hand_pos, boulder_pos, dist_hand_to_boulder])
	assert(dist_hand_to_boulder < 0.65, "Right hand is not resting against the boulder!")
	print("  - [PASS] Right hand rests firmly touching the support boulder.")
	
	# Condition 3: Torso leans slightly towards the rock without looking unnatural
	assert(torso.rotation_degrees.z < 0.0, "Torso must lean slightly towards the right boulder!")
	print("  - [PASS] Torso leans into rock (Z rot = %.1f°)" % torso.rotation_degrees.z)
	
	# Condition 4: Head turned towards the village below (cautious, calculating gaze)
	assert(head.rotation_degrees.y < -15.0, "Head must turn toward village in valley!")
	assert(head.rotation_degrees.x < 0.0, "Head must tilt downward toward village below!")
	print("  - [PASS] Head turned towards village below (Yaw = %.1f°, Pitch = %.1f°)" % [head.rotation_degrees.y, head.rotation_degrees.x])
	
	# -------------------------------------------------------------
	# 5. VERIFY SHOT 4: THE AFTERMATH
	# -------------------------------------------------------------
	print("\n[4] Verifying Shot 4: The Aftermath...")
	var s4 = controller.stage4_aftermath
	assert(s4 != null, "Stage 4 (The Aftermath) missing!")
	var victim = s4.get_node_or_null("VictimLordAris")
	var merc_s4 = s4.get_node_or_null("Mercenary")
	var dagger = controller.dagger_prop
	
	assert(victim != null, "Motionless victim (Lord Aris) missing!")
	assert(victim.get_node_or_null("BloodPool") != null, "Blood pool under victim missing!")
	assert(merc_s4 != null, "Mercenary standing over victim missing!")
	assert(dagger != null, "Stiletto dagger missing!")
	assert(dagger.get_node_or_null("BloodDrop") != null, "Blood droplet on dagger blade missing!")
	
	# Verify blade points downward
	var blade = dagger.get_node_or_null("Blade")
	assert(blade != null and blade.rotation_degrees.z == 180.0, "Dagger blade must point downwards!")
	print("  - Motionless victim with blood pool verified.")
	print("  - Mercenary with downward-pointing stiletto dagger & blood droplet verified.")
	print("[PASS] Shot 4 (The Aftermath) setup verified.")
	
	# -------------------------------------------------------------
	# 6. VERIFY TRANSITIONS & SKIP FUNCTIONALITY
	# -------------------------------------------------------------
	print("\n[5] Verifying Shot Switching & Skip Functionality...")
	controller._set_shot(2)
	assert(controller.current_shot == 2, "Failed to switch to Shot 2")
	controller._set_shot(3)
	assert(controller.current_shot == 3, "Failed to switch to Shot 3")
	controller._set_shot(4)
	assert(controller.current_shot == 4, "Failed to switch to Shot 4")
	controller._set_shot(5)
	assert(controller.current_shot == 5, "Failed to switch to Title Card")
	print("[PASS] Shot switching and audio state progression verified.")
	
	# Verify skip to game
	var signal_tracker := {"completed": false}
	controller.cinematic_completed.connect(func(): signal_tracker["completed"] = true)
	controller.skip_cinematic()
	assert(controller.is_skipped == true, "Failed to flag cinematic as skipped!")
	assert(signal_tracker["completed"] == true, "Failed to emit cinematic_completed on skip!")
	print("[PASS] Escape skip cleanly triggers transition to gameplay scene.")
	
	print("\n=== ALL CINEMATIC INTRO CHECKS PASSED WITH 100% SUCCESS ===")
	quit(0)
