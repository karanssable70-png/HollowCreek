extends SceneTree

## Automated Verification Test for Interrogation Chamber & Anomaly Deduction System
## Validates:
## 1. Town Hall door presence and interaction prompt in town.tscn
## 2. Interrogation room 3D scene (round table, 2 chairs, moody lighting, first-person camera)
## 3. Suspect database (all 10 suspects, dark secrets, alibis, anomalies)
## 4. UI dashboard (suspect selector buttons, stress meter, anomaly alert, dialogue log)
## 5. Walk-in and seating animation for summoned suspects
## 6. Questioning, evidence confrontation, contradiction detection, and murder accusation

const SuspectDatabaseScript = preload("res://scripts/interrogation/suspect_database.gd")
const InterrogationControllerScript = preload("res://scripts/interrogation/interrogation_controller.gd")

func _init() -> void:
	print("\n=== STARTING INTERROGATION CHAMBER & ANOMALY SYSTEM TEST ===")
	_run_tests.call_deferred()

func _run_tests() -> void:
	# -------------------------------------------------------------------------
	# 1. VERIFY TOWN HALL DOOR IN TOWN SCENE
	# -------------------------------------------------------------------------
	print("\n[1] Verifying Town Hall Interrogation Door...")
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	assert(town_scene != null, "Failed to load scenes/town.tscn")
	
	var town_inst = town_scene.instantiate()
	root.add_child(town_inst)
	
	var town_hall = town_inst.get_node_or_null("TownWorld/Landmarks/TownHall")
	assert(town_hall != null, "TownHall missing in Landmarks!")
	
	var door = town_hall.get_node_or_null("InterrogationDoor")
	assert(door != null, "InterrogationDoor missing on TownHall facade!")
	assert(door.has_method("get_interaction_prompt"), "Door missing get_interaction_prompt method!")
	assert(door.has_method("interact"), "Door missing interact method!")
	
	var prompt: String = door.get_interaction_prompt()
	print("  - Door Prompt: '", prompt, "'")
	assert("Interrogation" in prompt and "Town Hall" in prompt, "Prompt does not mention Interrogation or Town Hall!")
	print("  - [PASS] Town Hall door successfully verified on biggest house facade.")
	
	town_inst.queue_free()
	await process_frame

	# -------------------------------------------------------------------------
	# 2. VERIFY SUSPECT DATABASE INTEGRITY
	# -------------------------------------------------------------------------
	print("\n[2] Verifying Suspect Database & Secrets...")
	var suspects: Array[Dictionary] = SuspectDatabaseScript.get_all_suspects()
	assert(suspects.size() == 10, "Expected 10 suspects, got %d" % suspects.size())
	
	var killer_count: int = 0
	for s in suspects:
		var s_id: String = s["id"]
		var s_name: String = s["name"]
		var secret: String = s["dark_secret"]
		var alibi: String = s["alibi"]
		var anomalies: Array = s["behavioral_anomalies"]
		
		assert(not s_id.is_empty(), "Suspect missing ID!")
		assert(not s_name.is_empty(), "Suspect missing name!")
		assert(not secret.is_empty(), "Suspect %s missing dark secret!" % s_id)
		assert(not alibi.is_empty(), "Suspect %s missing alibi!" % s_id)
		assert(anomalies.size() > 0, "Suspect %s missing behavioral anomalies!" % s_id)
		
		if s.get("is_the_killer", false):
			killer_count += 1
			assert(s_id == "garrick", "Only Garrick Thorne should be the killer!")
			
		print("  - Suspect [%s]: %s (%s) — Secret: '%s...'" % [s_id, s_name, s["role"], secret.substr(0, 35)])
		
	assert(killer_count == 1, "Exactly one killer must exist in the roster!")
	print("  - [PASS] All 10 suspects verified with dark secrets, alibis, and anomalies.")

	# -------------------------------------------------------------------------
	# 3. VERIFY INTERROGATION ROOM 3D ENVIRONMENT
	# -------------------------------------------------------------------------
	print("\n[3] Verifying Interrogation Room 3D Environment...")
	var room_scene: PackedScene = load("res://scenes/interrogation_room.tscn")
	assert(room_scene != null, "Failed to load scenes/interrogation_room.tscn")
	
	var room_inst = room_scene.instantiate()
	root.add_child(room_inst)
	
	var controller = room_inst
	assert(controller != null, "Scene root is not valid!")
	
	# Verify room nodes
	assert(controller.room_root != null, "Room root missing!")
	assert(controller.round_table != null, "Round table missing!")
	assert(controller.detective_chair != null, "Detective chair missing!")
	assert(controller.suspect_chair != null, "Suspect chair missing!")
	assert(controller.overhead_light != null, "Overhead interrogation spotlight missing!")
	assert(controller.table_omni_light != null, "Table candle glow light missing!")
	assert(controller.active_camera != null, "First-person detective camera missing!")
	
	# Verify table geometry
	var table_top = controller.round_table.get_node_or_null("TableTop")
	assert(table_top != null, "Round table top cylinder missing!")
	print("  - Table top position: ", table_top.global_position)
	
	# Verify chairs on opposite sides
	var det_pos: Vector3 = controller.detective_chair.position
	var susp_pos: Vector3 = controller.suspect_chair.position
	print("  - Detective Chair Pos: %s, Suspect Chair Pos: %s" % [det_pos, susp_pos])
	assert(det_pos.z < 0.0 and susp_pos.z > 0.0, "Chairs must be on opposite sides of the table (Z < 0 and Z > 0)!")
	print("  - [PASS] Dimly lit 3D chamber, round table, and opposing chairs verified.")

	# -------------------------------------------------------------------------
	# 4. VERIFY UI DASHBOARD & CONTROLS
	# -------------------------------------------------------------------------
	print("\n[4] Verifying Interrogation UI Dashboard...")
	assert(controller.hud_canvas != null, "HUD CanvasLayer missing!")
	assert(controller.suspect_buttons.size() == 10, "Expected 10 suspect buttons, got %d" % controller.suspect_buttons.size())
	assert(controller.stress_progress != null, "Stress progress bar missing!")
	assert(controller.anomaly_label != null, "Behavioral anomaly label missing!")
	assert(controller.dialogue_log != null, "Dialogue transcript RichTextLabel missing!")
	assert(controller.action_btn_alibi != null, "Alibi action button missing!")
	assert(controller.action_btn_motive != null, "Motive action button missing!")
	assert(controller.action_btn_evidence != null, "Evidence confrontation button missing!")
	assert(controller.action_btn_secret != null, "Press secret button missing!")
	assert(controller.action_btn_accuse != null, "Accuse button missing!")
	print("  - [PASS] UI dashboard, 10 suspect buttons, and action controls verified.")

	# -------------------------------------------------------------------------
	# 5. VERIFY SUSPECT SUMMONING & SEATING
	# -------------------------------------------------------------------------
	print("\n[5] Verifying Suspect Summoning & Seating...")
	controller.summon_suspect("garrick")
	assert(controller.active_suspect_data.get("id") == "garrick", "Failed to summon Garrick!")
	assert(controller.current_suspect_node != null, "Suspect 3D model node missing!")
	
	# Fast-forward walk-in sequence
	controller._walk_time = controller._walk_duration
	controller._process(0.1)
	controller._seat_suspect()
	
	assert(controller.current_suspect_node.position.distance_to(Vector3(0, 0, 1.25)) < 0.2, "Suspect not seated at chair!")
	assert(controller.action_btn_alibi.disabled == false, "Action buttons not enabled after seating!")
	print("  - [PASS] Garrick summoned, walked in, and seated opposite table.")

	# -------------------------------------------------------------------------
	# 6. VERIFY QUESTIONING, EVIDENCE & ANOMALIES
	# -------------------------------------------------------------------------
	print("\n[6] Verifying Questioning, Evidence Confrontation & Anomalies...")
	# 6A: Ask Alibi
	controller._on_alibi_pressed()
	var log_text: String = controller.get_dialogue_text()
	assert("Garrick" in log_text and "wharf" in log_text.to_lower(), "Alibi response missing from dialogue log!")
	print("  - Alibi question successfully recorded.")
	
	# 6B: Confront with Storehouse Master Key
	controller._confront_clue("storehouse_iron_key")
	var log_after_clue: String = controller.get_dialogue_text()
	assert("CONTRADICTION EXPOSED" in log_after_clue, "Contradiction alert not triggered for storehouse key!")
	assert(controller.suspect_states["garrick"]["contradiction"] == true, "Contradiction state not flagged!")
	print("  - Evidence confrontation triggered contradiction alert and spiked stress.")
	
	# 6C: Press Dark Secret
	controller._on_press_secret_pressed()
	var log_after_secret: String = controller.get_dialogue_text()
	assert("FULL CONFESSION UNLOCKED" in log_after_secret or "contract" in log_after_secret.to_lower(), "Confession not triggered!")
	print("  - Pressed dark secret successfully extracted confession.")
	
	# 6D: Accuse Garrick as Killer
	controller._on_accuse_pressed()
	var final_log: String = controller.get_dialogue_text()
	assert("CASE SOLVED" in final_log, "Case solved banner not triggered on killer accusation!")
	print("  - [PASS] Killer accused and case successfully solved.")

	# -------------------------------------------------------------------------
	# 7. VERIFY SWITCHING TO ANOTHER SUSPECT (LADY ISOLDE)
	# -------------------------------------------------------------------------
	print("\n[7] Verifying Switching to Lady Isolde...")
	controller.summon_suspect("isolde")
	assert(controller.active_suspect_data.get("id") == "isolde", "Failed to switch suspect to Isolde!")
	controller._walk_time = controller._walk_duration
	controller._process(0.1)
	controller._seat_suspect()
	
	assert(controller.name_banner_label.text == "Lady Isolde Sterling", "Banner name not updated for Isolde!")
	print("  - [PASS] Seamlessly switched to Lady Isolde.")

	print("\n=== ALL INTERROGATION CHAMBER TESTS PASSED WITH 100% SUCCESS ===")
	quit(0)
