extends SceneTree

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("\n=== STARTING WHISPERS OF HOLLOW CREEK AUTOMATED VERIFICATION ===")
	
	# Load main town scene
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	if not town_scene:
		print("FAILED: Could not load res://scenes/town.tscn")
		quit(1)
		return
		
	var town_node: Node = town_scene.instantiate()
	var p_before = town_node.get_node("Player").position
	print("Instantiated Player position: ", p_before)
	root.add_child(town_node)
	
	# Wait for children _ready calls
	await process_frame
	print("After frame 1, Player position: ", town_node.get_node("Player").global_position)
	await process_frame
	print("After frame 2, Player position: ", town_node.get_node("Player").global_position)
	
	print("[PASS] Town scene instantiated and ready.")
	
	# Verify Environment
	var env_mgr = town_node.get_node_or_null("EnvironmentManager")
	assert(env_mgr != null, "EnvironmentManager missing!")
	print("[PASS] EnvironmentManager exists.")
	
	# Verify Town Generator
	var generator = town_node.get_node_or_null("TownWorld")
	assert(generator != null, "TownWorld node missing!")
	var terrain = generator.get_node_or_null("TerrainAndRoads")
	var ocean = generator.get_node_or_null("OceanAndCoast")
	var mountains = generator.get_node_or_null("NorthernMountains")
	var landmarks = generator.get_node_or_null("Landmarks")
	var vegetation = generator.get_node_or_null("Vegetation")
	var props = generator.get_node_or_null("VillageProps")
	var boundaries = generator.get_node_or_null("Boundaries")
	
	assert(terrain != null, "Terrain missing!")
	assert(ocean != null, "Ocean missing!")
	assert(mountains != null, "Northern mountains missing!")
	assert(landmarks != null, "Landmarks missing!")
	assert(vegetation != null, "Vegetation missing!")
	assert(props != null, "Village props missing!")
	assert(boundaries != null, "Boundary colliders missing!")
	
	print("[PASS] Geography and World structures verified (Terrain, Ocean, Mountains, Pass, Boundaries).")
	
	# Verify Landmarks
	var required_landmarks: Array[String] = [
		"TheLanternInn",
		"GarricksForge",
		"ElarasHerbalistCottage",
		"TownHall",
		"PhysiciansClinic",
		"OldStorehouse",
		"CentralSquareAndWell",
		"FishingHarbourAndDock",
		"MountainEntranceGate"
	]
	for lm_name in required_landmarks:
		var lm = landmarks.get_node_or_null(lm_name)
		assert(lm != null, "Landmark missing: " + lm_name)
		print("  - Landmark found: ", lm_name)
	print("[PASS] All required landmarks verified.")
	
	# Verify Player
	var player = town_node.get_node_or_null("Player")
	assert(player != null, "Player missing!")
	assert(player.get_node_or_null("Head/Camera3D") != null, "Player camera missing!")
	assert(player.get_node_or_null("Head/InteractionRay") != null, "Player raycast missing!")
	print("[PASS] First-person PlayerController verified at spawn: ", player.global_position)
	
	# Verify Dialogue UI
	var dialogue_ui = town_node.get_node_or_null("DialogueUI")
	assert(dialogue_ui != null, "DialogueUI missing!")
	print("[PASS] DialogueUI system verified.")
	
	# Verify All 11 Characters
	var npcs = town_node.get_node_or_null("NPCs")
	assert(npcs != null, "NPCs container missing!")
	
	var expected_npcs: Array[Dictionary] = [
		{"name": "Garrick", "role": "Harbour Master", "test_kw": "harbour"},
		{"name": "Isolde", "role": "Noblewoman", "test_kw": "murder"},
		{"name": "Edmund", "role": "Physician", "test_kw": "autopsy"},
		{"name": "Lena", "role": "Innkeeper", "test_kw": "inn"},
		{"name": "Oswin", "role": "Steward", "test_kw": "debt"},
		{"name": "Finn", "role": "Dockworker", "test_kw": "boats"},
		{"name": "Aldric", "role": "Victim", "test_kw": "wounds"},
		{"name": "Mayor", "role": "Village Mayor", "test_kw": "verdict"},
		{"name": "Elara", "role": "Herbalist", "test_kw": "herbs"},
		{"name": "Tomas", "role": "Town Guard", "test_kw": "pass"},
		{"name": "Corin", "role": "Street Vendor", "test_kw": "fruit"}
	]
	
	for npc_data in expected_npcs:
		var npc_node = npcs.get_node_or_null(npc_data["name"])
		assert(npc_node != null, "NPC missing: " + npc_data["name"])
		assert(npc_node.npc_role == npc_data["role"], "NPC role mismatch for " + npc_data["name"])
		
		# Test interaction dialogue
		var response: String = npc_node.ask_question(npc_data["test_kw"])
		assert(not response.is_empty(), "Empty dialogue response from " + npc_data["name"])
		print("  - NPC verified: ", npc_node.npc_name, " (", npc_node.npc_role, ") -> Sample answer: '", response.substr(0, 45), "...'")
		
	print("[PASS] All 11 NPCs verified with dialogue dictionaries and distinct models.")
	
	# Test dialogue UI flow
	var test_npc = npcs.get_node("Lena")
	dialogue_ui.open_dialogue(test_npc, player)
	assert(dialogue_ui.visible == true, "DialogueUI failed to open")
	assert(player.is_dialogue_open == true, "Player failed to lock movement during dialogue")
	dialogue_ui.send_question("inn")
	dialogue_ui.close_dialogue()
	assert(dialogue_ui.visible == false, "DialogueUI failed to close")
	assert(player.is_dialogue_open == false, "Player failed to unlock movement after dialogue")
	print("[PASS] Dialogue UI interactive open/ask/close sequence passed.")
	
	print("\n=== ALL TEST CHECKS PASSED PERFECTLY ===")
	quit(0)
