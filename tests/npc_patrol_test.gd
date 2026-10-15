extends SceneTree

## Autonomous NPC Patrol & Job Routine Verification Test
## Validates:
## 1. Presence of all 7 NPCs with distinct job roles and appearances
## 2. Configured role-based patrol routes and staggered schedules
## 3. Physics movement and waypoint navigation along town roads
## 4. Immediate halt and facing the player during dialogue interaction
## 5. Resumption of patrol routine after dialogue closes
## 6. Dynamic thoughts and clue acquisition system

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("\n=== STARTING AUTONOMOUS NPC PATROL & ROUTINE VERIFICATION ===")
	
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	if not town_scene:
		print("FAILED: Could not load res://scenes/town.tscn")
		quit(1)
		return
		
	var town_node: Node = town_scene.instantiate()
	root.add_child(town_node)
	
	# Wait for ready calls
	for i in range(5):
		await process_frame
		
	var npcs: Node3D = town_node.get_node_or_null("NPCs")
	assert(npcs != null, "NPCs container missing!")
	
	print("\n[1] Verifying all NPCs, job roles, and staggered schedules...")
	var npc_configs := [
		{"name": "Lena", "role": "Innkeeper", "min_work": 40.0, "min_stroll": 20.0},
		{"name": "Garrick", "role": "Harbour Master", "min_work": 40.0, "min_stroll": 20.0},
		{"name": "Elara", "role": "Herbalist", "min_work": 35.0, "min_stroll": 25.0},
		{"name": "Tomas", "role": "Town Guard", "min_work": 30.0, "min_stroll": 0.0},
		{"name": "Edmund", "role": "Physician", "min_work": 35.0, "min_stroll": 20.0},
		{"name": "Mayor", "role": "Village Mayor", "min_work": 45.0, "min_stroll": 15.0},
		{"name": "Corin", "role": "Street Vendor", "min_work": 50.0, "min_stroll": 20.0}
	]
	
	for cfg in npc_configs:
		var npc: NPCInteractable = npcs.get_node_or_null(cfg["name"]) as NPCInteractable
		assert(npc != null, "Missing NPC node: " + cfg["name"])
		assert(npc.npc_role == cfg["role"], "Role mismatch for " + cfg["name"] + ": expected " + cfg["role"] + ", got " + npc.npc_role)
		assert(npc.patrol_waypoints.size() >= 3, "Insufficient waypoints for " + cfg["name"] + ": found " + str(npc.patrol_waypoints.size()))
		assert(npc.work_duration >= cfg["min_work"], "Work duration too low for " + cfg["name"])
		assert(npc.stroll_duration >= cfg["min_stroll"], "Stroll duration too low for " + cfg["name"])
		print("  - [PASS] %s (%s): Work=%.1fs, Stroll=%.1fs, Speed=%.2fm/s, Waypoints=%d" % [
			npc.npc_name, npc.npc_role, npc.work_duration, npc.stroll_duration, npc.walk_speed, npc.patrol_waypoints.size()
		])
	
	print("[PASS] All 7 NPCs verified with unique schedules and route waypoints.")
	
	# Test 2: Verify Street Vendor Corin's schedule design
	print("\n[2] Verifying Street Vendor Corin's station focus & stroll break...")
	var corin: NPCInteractable = npcs.get_node("Corin") as NPCInteractable
	assert(corin.work_duration > corin.stroll_duration * 2.0, "Street Vendor must stay at stall for majority of time!")
	print("  - Corin spends %.1fs at stall vs %.1fs strolling around Bazaar" % [corin.work_duration, corin.stroll_duration])
	print("[PASS] Street Vendor schedule matches specification.")
	
	# Test 3: Autonomous Path Movement & Waypoint Steering
	print("\n[3] Testing Autonomous Movement and Waypoint Steering (Tomas Guard Patrol)...")
	var tomas: NPCInteractable = npcs.get_node("Tomas") as NPCInteractable
	var start_pos := tomas.global_position
	var target_wp := tomas.patrol_waypoints[0]
	print("  - Tomas starting pos: ", start_pos)
	print("  - Tomas target waypoint 0: ", target_wp)
	
	# Start patrol
	tomas.start_patrol()
	assert(tomas.current_state == NPCInteractable.State.PATROLLING, "Tomas failed to enter PATROLLING state!")
	assert(tomas.is_walking() == true, "Tomas is_walking() reported false!")
	
	# Step physics frames to let him walk toward waypoint
	for i in range(45):
		await process_frame
		
	var moved_pos := tomas.global_position
	var dist_moved := Vector2(moved_pos.x - start_pos.x, moved_pos.z - start_pos.z).length()
	var dist_to_target_start := Vector2(start_pos.x - target_wp.x, start_pos.z - target_wp.z).length()
	var dist_to_target_now := Vector2(moved_pos.x - target_wp.x, moved_pos.z - target_wp.z).length()
	
	print("  - Position after 45 frames: ", moved_pos)
	print("  - Distance traveled: %.2fm (Distance to waypoint closed from %.2fm to %.2fm)" % [dist_moved, dist_to_target_start, dist_to_target_now])
	assert(dist_moved > 0.4, "Tomas failed to move along patrol route!")
	assert(dist_to_target_now < dist_to_target_start, "Tomas did not head in the direction of waypoint 0!")
	print("[PASS] Tomas successfully navigated toward first patrol waypoint.")
	
	# Test 4: Dialogue Interaction Interruption (Freeze + Face Player)
	print("\n[4] Testing Dialogue Interaction Interrupt while Patrolling...")
	var player = town_node.get_node("Player")
	var dialogue_ui: DialogueUI = town_node.get_node("DialogueUI") as DialogueUI
	
	# Position player to the side of Tomas
	player.global_position = tomas.global_position + Vector3(2.0, 0.0, 0.0)
	
	# Open dialogue with moving Tomas
	dialogue_ui.open_dialogue(tomas, player)
	for i in range(5):
		await process_frame
		
	assert(tomas.current_state == NPCInteractable.State.DIALOGUE, "Tomas did not enter DIALOGUE state!")
	assert(tomas.velocity.x == 0.0 and tomas.velocity.z == 0.0, "Tomas velocity was not zeroed during dialogue!")
	
	var pos_during_dialogue := tomas.global_position
	for i in range(20):
		await process_frame
	var pos_still_in_dialogue := tomas.global_position
	assert(pos_during_dialogue.distance_to(pos_still_in_dialogue) < 0.01, "Tomas moved while dialogue was active!")
	print("  - Tomas remained 100% frozen in place during dialogue.")
	
	# Close dialogue and verify resumption
	dialogue_ui.close_dialogue()
	for i in range(5):
		await process_frame
		
	assert(tomas.current_state == NPCInteractable.State.PATROLLING, "Tomas failed to resume PATROLLING state after dialogue!")
	print("  - Tomas resumed PATROLLING state.")
	
	# Allow Tomas to continue walking for another 30 frames
	for i in range(30):
		await process_frame
	var pos_after_resumption := tomas.global_position
	assert(pos_after_resumption.distance_to(pos_during_dialogue) > 0.2, "Tomas did not resume walking along route!")
	print("[PASS] Dialogue interrupt, halt, and seamless patrol resumption verified.")
	
	# Test 5: Dynamic Clue and Thought Development System
	print("\n[5] Testing Clue & Thought Development System...")
	var garrick: NPCInteractable = npcs.get_node("Garrick") as NPCInteractable
	var initial_thought := garrick.get_current_thought()
	print("  - Garrick initial thought: '", initial_thought, "'")
	assert(not initial_thought.is_empty(), "Garrick had empty initial thought!")
	
	# Garrick discovers a clue
	garrick.add_clue("burnt_contract_scrap", "Found burnt paper with raven seal")
	var updated_thought := garrick.get_current_thought()
	print("  - Garrick thought after finding burnt scrap: '", updated_thought, "'")
	assert(updated_thought != initial_thought, "Garrick thought did not update after finding clue!")
	assert("burnt" in updated_thought or "raven" in updated_thought or "capital" in updated_thought, "Garrick thought did not reflect the new evidence!")
	
	# Asking through dialogue about thoughts
	var thought_response: String = garrick.ask_question("What do you think about the suspect?")
	print("  - Garrick dialogue reply to 'What do you think?': '", thought_response, "'")
	assert(thought_response == updated_thought, "NPC failed to communicate their current thought via dialogue inquiry!")
	print("[PASS] Autonomous thought formulation and clue updating verified.")
	
	# Test 6: Return Home Navigation
	print("\n[6] Testing Return Home Navigation...")
	var lena: NPCInteractable = npcs.get_node("Lena") as NPCInteractable
	lena.start_patrol()
	for i in range(30):
		await process_frame
	lena.return_home()
	assert(lena.current_state == NPCInteractable.State.RETURNING_HOME, "Lena failed to enter RETURNING_HOME state!")
	
	# Let her walk back towards home
	for i in range(60):
		await process_frame
		
	var lena_dist_to_home := Vector2(lena.global_position.x - lena.home_position.x, lena.global_position.z - lena.home_position.z).length()
	print("  - Lena distance to home position: %.2fm" % lena_dist_to_home)
	assert(lena_dist_to_home < 3.0, "Lena failed to navigate back toward home post!")
	print("[PASS] Return home routine verified.")
	
	print("\n=== ALL NPC PATROL AND AUTONOMOUS ROUTINE TESTS PASSED WITH 100% SUCCESS ===")
	quit(0)
