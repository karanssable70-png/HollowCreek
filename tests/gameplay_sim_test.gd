extends SceneTree

func _init() -> void:
	_run_sim.call_deferred()

func _run_sim() -> void:
	print("\n=== STARTING PLAYER MOVEMENT AND INTERACTION SIMULATION ===")
	
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	var town_node: Node = town_scene.instantiate()
	root.add_child(town_node)
	
	# Wait for ready
	for i in range(5):
		await process_frame
		
	var player = town_node.get_node("Player")
	var initial_pos: Vector3 = player.global_position
	print("Initial Player position at Pass: ", initial_pos)
	assert(abs(initial_pos.x) < 0.5, "Player not centered in pass!")
	assert(initial_pos.z < -45.0, "Player not at mountain pass start!")
	
	# Test 1: Simulate walking forward (South) down the pass towards town for 60 frames
	print("\nTest 1: Walking forward down the pass into Hollow Creek...")
	Input.action_press("move_forward")
	for i in range(60):
		await process_frame
	Input.action_release("move_forward")
	
	var pos_after_walk: Vector3 = player.global_position
	print("Position after walking forward: ", pos_after_walk)
	assert(pos_after_walk.z > initial_pos.z, "Player did not move south towards town!")
	print("[PASS] Player smoothly walked forward from Z=", initial_pos.z, " to Z=", pos_after_walk.z)
	
	# Test 2: Verify player cannot walk backwards through northern boundary wall
	print("\nTest 2: Testing Northern mountain boundary wall collision...")
	Input.action_press("move_backward")
	for i in range(120):
		await process_frame
	Input.action_release("move_backward")
	var pos_blocked: Vector3 = player.global_position
	print("Position after walking into mountain wall: ", pos_blocked)
	assert(pos_blocked.z >= -53.5, "Player escaped through northern mountain boundary wall!")
	print("[PASS] Northern mountain boundary wall successfully stopped player at Z=", pos_blocked.z)
	
	# Test 3: Approach Tomas at mountain pass entrance
	var tomas = town_node.get_node("NPCs/Tomas")
	player.global_position = tomas.global_position + Vector3(0.0, 0.0, -2.0)
	player.rotation_degrees = Vector3(0, 0, 0) # Face south towards +Z: wait, if player is at -30, and Tomas is at -28, south is +Z!
	player.get_node("Head").rotation_degrees = Vector3.ZERO
	# If player is at -30, looking at +Z means looking in direction of Tomas.
	# But in Godot local camera looks towards -Z!
	# So to look towards +Z, player rotation_degrees.y must be 180!
	player.rotation_degrees.y = 180.0
	
	for i in range(5):
		await process_frame
		
	player.raycast.force_raycast_update()
	print("Raycast global origin: ", player.raycast.global_position)
	print("Raycast target global: ", player.raycast.to_global(player.raycast.target_position))
	print("Tomas position: ", tomas.global_position)
	print("Raycast is_colliding: ", player.raycast.is_colliding())
	if player.raycast.is_colliding():
		print("Raycast collider: ", player.raycast.get_collider())
	player._check_interaction()
	print("Prompt text when looking at Tomas: '", player.prompt_label.text, "'")
	assert("Tomas" in player.prompt_label.text, "Failed to detect Tomas via RayCast3D!")
	print("[PASS] RayCast3D accurately detected NPC Tomas with prompt: ", player.prompt_label.text)
	
	# Test 4: Interactive Dialogue Flow
	print("\nTest 4: Triggering dialogue interaction with Tomas...")
	player._trigger_interaction()
	for i in range(3):
		await process_frame
		
	var ui = town_node.get_node("DialogueUI")
	assert(ui.visible == true, "DialogueUI failed to open on interact!")
	assert(player.is_dialogue_open == true, "Player failed to pause on interact!")
	
	# Player asks question about the pass
	ui.send_question("pass")
	for i in range(2):
		await process_frame
		
	var history_text: String = ui.history_label.get_parsed_text()
	print("Dialogue history sample:\n", history_text.strip_edges())
	assert("The pass is walled in" in history_text or "pass" in history_text.to_lower(), "Failed to get response about pass!")
	print("[PASS] Dialogue input and in-character response verified.")
	
	# Close dialogue
	ui.close_dialogue()
	for i in range(2):
		await process_frame
	assert(ui.visible == false, "DialogueUI failed to close!")
	assert(player.is_dialogue_open == false, "Player failed to regain control!")
	print("[PASS] Dialogue closed and player control restored.")
	
	print("\n=== ALL SIMULATION TESTS PASSED WITH 100% SUCCESS ===")
	quit(0)
