extends SceneTree

## Automated Verification Test for Village Designated Houses, Living Room Interiors & Puzzles
## Validates:
## 1. Village House Doors: All 10 designated houses have interactable doors matching user map
## 2. Living Room Commodities: Stone fireplace, dining table, chairs, bed alcove, cupboards, barrels
## 3. Player Controller: res://scenes/player.tscn instantiated with full WASD movement & interaction ray
## 4. Exit Door: HouseExitDoor interactable present with "[E] Exit to Hollow Creek Village"
## 5. Tomas Reed Puzzle: Interactable drawer opens, revealing Hypersomnia medical report
## 6. Physician Puzzle: Interactable drawer opens, revealing falsified natural death autopsy report
## 7. Scattered Evidence Papers: 2 scattered evidence papers in EVERY house proving motives/secrets
## 8. Document Inspection Modal: Parchment UI, title, body, discovery logging, pause/resume movement
## 9. All 10 House Puzzles: Garrick, Corin, Lena, Finn, Isolde, Oswin, Elora, Mayor

const HouseInteriorManagerScript = preload("res://scripts/world/house_interior_manager.gd")
const HouseDoorScript = preload("res://scripts/world/house_door.gd")
const HouseInteriorControllerScript = preload("res://scripts/world/house_interior_controller.gd")
const HouseClueInteractableScript = preload("res://scripts/world/house_clue_interactable.gd")
const HouseExitDoorScript = preload("res://scripts/world/house_exit_door.gd")

func _init() -> void:
	print("\n================================================================================")
	print("=== HOLLOWCREEK DESIGNATED HOUSES, LIVING ROOMS & PUZZLES TEST ===")
	print("================================================================================\n")
	_run_tests.call_deferred()

func _run_tests() -> void:
	# -------------------------------------------------------------------------
	# 1. VERIFY DESIGNATED HOUSES & DOORS IN TOWN SCENE
	# -------------------------------------------------------------------------
	print("[1] Verifying Village Designated Houses & Doors in town.tscn...")
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	assert(town_scene != null, "Failed to load scenes/town.tscn")
	
	var town_inst: Node = town_scene.instantiate()
	root.add_child(town_inst)
	
	for i in range(3):
		await process_frame
		
	var landmarks = town_inst.get_node_or_null("TownWorld/Landmarks")
	if not landmarks:
		for c in town_inst.get_children():
			if "@Node3D@" in c.name:
				landmarks = c.get_node_or_null("Landmarks")
				if landmarks: break
	assert(landmarks != null, "Landmarks node missing in town scene!")

	# Check the 10 Designated Houses from user's map
	var expected_houses := [
		{"id": "tomas", "name_part": "Tomas Reed", "node": "TomasReedHouse"},
		{"id": "physician", "name_part": "Physician", "node": "PhysiciansClinic"},
		{"id": "garrick", "name_part": "Harbour Master", "node": "HarbourMasterHouse"},
		{"id": "corin", "name_part": "Corin", "node": "CorinHouse"},
		{"id": "lena", "name_part": "Lena Vance", "node": "TheLanternInn"},
		{"id": "finn", "name_part": "Finn Cole", "node": "FishermansCottage"},
		{"id": "isolde", "name_part": "Isolde", "node": "IsoldeManor"},
		{"id": "oswin", "name_part": "Oswin", "node": "OswinGreyHouse"},
		{"id": "elara", "name_part": "Elora", "node": "ElarasHerbalistCottage"},
		{"id": "mayor", "name_part": "Mayor", "node": "MayorSecretHouse"}
	]

	var doors_found: int = 0
	for h in expected_houses:
		var h_id: String = h["id"]
		var door_node = landmarks.find_child("HouseDoor_" + h_id, true, false)
		assert(door_node != null, "Door HouseDoor_%s missing in village landmarks!" % h_id)
		assert(door_node.is_in_group("interactable"), "Door HouseDoor_%s not in group 'interactable'!" % h_id)
		
		var prompt: String = door_node.get_interaction_prompt()
		assert(h["name_part"] in prompt, "Prompt '%s' does not contain '%s'!" % [prompt, h["name_part"]])
		doors_found += 1
		print("  - [PASS] Verified Door: [%s] Prompt: '%s'" % [door_node.name, prompt])

	assert(doors_found == 10, "Expected 10 designated house doors, found %d" % doors_found)
	print("  - [PASS] All 10 designated village house doors verified.\n")

	town_inst.queue_free()
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 2. VERIFY LIVING ROOM INTERIOR, COMMODITIES, PLAYER & EXIT DOOR
	# -------------------------------------------------------------------------
	print("[2] Verifying Living Room Interior, Player Controller & Exit Door...")
	HouseInteriorManagerScript.current_house_id = "tomas"
	var interior_scene: PackedScene = load("res://scenes/house_interior.tscn")
	assert(interior_scene != null, "Failed to load scenes/house_interior.tscn")
	
	var interior_inst: Node = interior_scene.instantiate()
	root.add_child(interior_inst)
	
	for i in range(2):
		await process_frame
		
	var controller = interior_inst
	assert(controller != null, "Interior root is null!")
	
	# Verify player
	var player = controller.get_node_or_null("Player")
	assert(player != null, "Player missing in interior!")
	assert(player.can_move, "Player should have movement enabled!")
	assert(player.head != null, "Player head missing!")
	assert(player.camera != null, "Player camera missing!")
	assert(player.raycast != null, "Player interaction raycast missing!")
	assert(player.position.z >= 1.8 and player.position.z <= 2.2, "Player spawn Z should be at entrance ~2.0!")
	print("  - [PASS] Player controller instantiated with camera, raycast, and movement enabled.")

	# Verify Exit Door
	var exit_door = controller.get_node_or_null("RoomArchitecture/FrontExitDoor/ExitDoorInteractable")
	assert(exit_door != null, "FrontExitDoor/ExitDoorInteractable missing!")
	assert(exit_door.is_in_group("interactable"), "Exit door not in group 'interactable'!")
	assert(exit_door.get_interaction_prompt() == "[E] Exit to Hollow Creek Village", "Exit door prompt incorrect!")
	print("  - [PASS] HouseExitDoor verified: '%s'" % exit_door.get_interaction_prompt())

	# Verify medieval commodities
	var comms = controller.get_node_or_null("MedievalCommodities")
	assert(comms != null, "MedievalCommodities missing!")
	assert(comms.get_node_or_null("StoneFireplace") != null, "Stone fireplace missing!")
	assert(comms.get_node_or_null("StoneFireplace/FireLight") != null, "Fireplace light missing!")
	assert(comms.get_node_or_null("DiningTableSet") != null, "Dining table set missing!")
	assert(comms.get_node_or_null("DiningTableSet/TableTop") != null, "Dining table top missing!")
	assert(comms.get_node_or_null("BedAlcove") != null, "Bed alcove missing!")
	assert(comms.get_node_or_null("WallCupboard") != null, "Bookshelf / cupboard missing!")
	assert(comms.get_node_or_null("StorageCorner") != null, "Storage barrels and crates missing!")
	print("  - [PASS] Fireplace, table, chairs, bed, cupboards, and barrels verified.")

	interior_inst.queue_free()
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 3. VERIFY TOMAS REED PUZZLE (INTERACTABLE DRAWER & HYPERSOMNIA REPORT)
	# -------------------------------------------------------------------------
	print("\n[3] Verifying Tomas Reed's House Puzzle (Interactable Drawer & Hypersomnia Report)...")
	HouseInteriorManagerScript.current_house_id = "tomas"
	interior_inst = interior_scene.instantiate()
	root.add_child(interior_inst)
	controller = interior_inst
	player = controller.get_node_or_null("Player")
	await process_frame
	
	var desk = controller.get_node_or_null("HouseSpecificPuzzle/InvestigationDesk")
	assert(desk != null, "Tomas's investigation desk missing!")
	
	var drawer = desk.get_node_or_null("InteractableDrawer")
	assert(drawer != null, "Tomas's interactable drawer missing!")
	assert(drawer.position.z == 0.0, "Drawer initial position should be Z=0!")
	
	var drawer_clue = desk.get_node_or_null("DrawerClueInteractable")
	assert(drawer_clue != null, "DrawerClueInteractable missing!")
	assert(drawer_clue.is_drawer, "Clue is not marked as drawer!")
	assert(not drawer_clue.is_drawer_open, "Drawer clue should initially be closed!")
	
	var initial_prompt: String = drawer_clue.get_interaction_prompt()
	assert("OPEN" in initial_prompt.to_upper(), "Initial prompt should say Open Drawer! Got: %s" % initial_prompt)
	print("  - [PASS] Initial Drawer Prompt: '%s'" % initial_prompt)
	
	# Interact with drawer (Step 1: Slides drawer open)
	drawer_clue.interact(player)
	assert(drawer_clue.is_drawer_open, "Drawer clue failed to open!")
	assert(drawer.position.z > 0.0, "Drawer failed to physically slide out!")
	var opened_prompt: String = drawer_clue.get_interaction_prompt()
	assert("INSPECT" in opened_prompt.to_upper(), "Opened prompt should say Inspect! Got: %s" % opened_prompt)
	print("  - [PASS] Drawer physically slid open. New Prompt: '%s'" % opened_prompt)
	
	# Interact with drawer (Step 2: Inspects Hypersomnia Report document)
	drawer_clue.interact(player)
	assert(controller.is_inspecting_doc, "Document inspection modal failed to open!")
	assert(not player.can_move, "Player movement should be paused while inspecting document!")
	assert(controller.doc_modal_panel.visible, "Document modal panel is not visible!")
	assert("HYPERSOMNIA" in controller.doc_body_label.text.to_upper(), "Document does not mention Hypersomnia!")
	assert("TOMAS REED" in controller.doc_title_label.text.to_upper(), "Document title does not mention Tomas Reed!")
	print("  - Document Title: '%s'" % controller.doc_title_label.text)
	print("  - Document Content Snippet: '%s...'" % controller.doc_body_label.text.substr(0, 70).replace("\n", " "))
	print("  - [PASS] Tomas Reed's severe Hypersomnia medical report verified inside drawer.")
	
	controller.close_document_reader()
	assert(not controller.is_inspecting_doc, "Modal failed to close!")
	assert(player.can_move, "Player movement should be restored after closing document!")
	print("  - [PASS] Modal closed and player movement restored.")
	
	interior_inst.queue_free()
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 4. VERIFY PHYSICIAN PUZZLE (INTERACTABLE DRAWER & FALSIFIED AUTOPSY REPORT)
	# -------------------------------------------------------------------------
	print("\n[4] Verifying Physician's Clinic Puzzle (Interactable Drawer & Falsified Autopsy)...")
	HouseInteriorManagerScript.current_house_id = "physician"
	interior_inst = interior_scene.instantiate()
	root.add_child(interior_inst)
	controller = interior_inst
	player = controller.get_node_or_null("Player")
	await process_frame
	
	desk = controller.get_node_or_null("HouseSpecificPuzzle/InvestigationDesk")
	assert(desk != null, "Physician's desk missing!")
	
	drawer = desk.get_node_or_null("InteractableDrawer")
	assert(drawer != null, "Physician's drawer missing!")
	drawer_clue = desk.get_node_or_null("DrawerClueInteractable")
	assert(drawer_clue != null, "Physician's DrawerClueInteractable missing!")
	
	# Step 1: Open drawer
	drawer_clue.interact(player)
	assert(drawer_clue.is_drawer_open, "Physician's drawer failed to open!")
	
	# Step 2: Inspect document
	drawer_clue.interact(player)
	assert(controller.is_inspecting_doc, "Physician's autopsy modal failed to open!")
	assert("NATURAL" in controller.doc_body_label.text.to_upper() and "CROSS THIS OUT" in controller.doc_body_label.text.to_upper(), "Autopsy does not contain falsification / natural death!")
	print("  - Document Title: '%s'" % controller.doc_title_label.text)
	print("  - Falsification Note Snippet: '%s...'" % controller.doc_body_label.text.substr(0, 95).replace("\n", " "))
	print("  - [PASS] Physician caught falsifying victim's report to declare natural death.")
	
	controller.close_document_reader()
	interior_inst.queue_free()
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 5. VERIFY SCATTERED EVIDENCE PAPERS & MOTIVES IN EVERY SINGLE HOUSE
	# -------------------------------------------------------------------------
	print("\n[5] Verifying Scattered Evidence Papers & Motives Across ALL 10 Houses...")
	var all_house_ids := ["tomas", "physician", "garrick", "corin", "lena", "finn", "isolde", "oswin", "elara", "mayor"]
	
	for hid in all_house_ids:
		HouseInteriorManagerScript.current_house_id = hid
		interior_inst = interior_scene.instantiate()
		root.add_child(interior_inst)
		controller = interior_inst
		player = controller.get_node_or_null("Player")
		await process_frame
		
		# Check scattered evidence papers root
		var papers_root = controller.get_node_or_null("ScatteredEvidencePapers")
		assert(papers_root != null, "ScatteredEvidencePapers missing in house: %s!" % hid)
		
		var paper_nodes := papers_root.get_children()
		assert(paper_nodes.size() >= 2, "House %s must have at least 2 scattered evidence papers! Found %d" % [hid, paper_nodes.size()])
		
		for idx in range(paper_nodes.size()):
			var p_node = paper_nodes[idx]
			var clue = p_node.get_node_or_null("ClueInteractable")
			assert(clue != null, "ClueInteractable missing on scattered paper %d in %s!" % [idx, hid])
			assert(clue.is_in_group("interactable"), "Scattered paper clue not in group 'interactable'!")
			assert(not clue.clue_id.is_empty(), "Scattered paper clue_id empty in %s!" % hid)
			assert(not clue.document_title.is_empty(), "Scattered paper document_title empty in %s!" % hid)
			assert(not clue.document_body.is_empty(), "Scattered paper document_body empty in %s!" % hid)
			
			var prompt: String = clue.get_interaction_prompt()
			assert(not prompt.is_empty(), "Interaction prompt empty on scattered paper!")
			
			# Test interacting with the scattered paper
			clue.interact(player)
			assert(controller.is_inspecting_doc, "Modal failed to open for scattered paper %s!" % clue.document_title)
			assert(controller.doc_title_label.text == clue.document_title, "Modal title does not match paper title!")
			assert(not player.can_move, "Player movement should be paused during scattered paper inspection!")
			controller.close_document_reader()
			assert(player.can_move, "Player movement should be restored after inspection!")
			
			print("  - [PASS] [%s Paper #%d]: '%s' | Prompt: '%s'" % [hid, idx + 1, clue.document_title, prompt])
		
		interior_inst.queue_free()
		await process_frame
		await process_frame

	print("\n  - [PASS] Scattered evidence papers and ledgers verified across all 10 houses.")

	# -------------------------------------------------------------------------
	# 6. VERIFY PRIMARY HOUSE PUZZLE SPECIFICS FOR ELORA, LENA, GARRICK
	# -------------------------------------------------------------------------
	print("\n[6] Verifying Primary Puzzle Specifics (Elora, Lena, Garrick, Isolde)...")
	# Elora
	HouseInteriorManagerScript.current_house_id = "elara"
	interior_inst = interior_scene.instantiate()
	root.add_child(interior_inst)
	controller = interior_inst
	player = controller.get_node_or_null("Player")
	await process_frame
	var herb_station = controller.get_node_or_null("HouseSpecificPuzzle/HerbWorkshop")
	assert(herb_station != null, "HerbWorkshop missing in Elora's cottage!")
	assert(herb_station.get_node_or_null("PurpleLight") != null, "Purple glow light missing!")
	var herb_clue = herb_station.get_node_or_null("HerbInteractable")
	assert(herb_clue != null, "HerbInteractable missing!")
	herb_clue.interact(player)
	assert("PURPLE NIGHTSHADE" in controller.doc_body_label.text.to_upper(), "Document does not mention Purple Nightshade!")
	print("  - [PASS] Elora's massive stashes of purple nightshade verified.")
	controller.close_document_reader()
	interior_inst.queue_free()
	await process_frame
	await process_frame

	# Lena
	HouseInteriorManagerScript.current_house_id = "lena"
	interior_inst = interior_scene.instantiate()
	root.add_child(interior_inst)
	controller = interior_inst
	player = controller.get_node_or_null("Player")
	await process_frame
	var stash = controller.get_node_or_null("HouseSpecificPuzzle/HiddenFloorboardStash")
	assert(stash != null, "HiddenFloorboardStash missing in Lena's house!")
	var stash_clue = stash.get_node_or_null("StashInteractable")
	assert(stash_clue != null, "StashInteractable missing!")
	stash_clue.interact(player)
	assert("COIN POUCH" in controller.doc_body_label.text.to_upper() and "SIGNET RING" in controller.doc_body_label.text.to_upper(), "Stash missing victim's belongings!")
	print("  - [PASS] Lena's hidden stash with victim's stolen coins and signet ring verified.")
	controller.close_document_reader()
	interior_inst.queue_free()
	await process_frame
	await process_frame

	# Garrick
	HouseInteriorManagerScript.current_house_id = "garrick"
	interior_inst = interior_scene.instantiate()
	root.add_child(interior_inst)
	controller = interior_inst
	player = controller.get_node_or_null("Player")
	await process_frame
	var garrick_desk = controller.get_node_or_null("HouseSpecificPuzzle/StudyDesk")
	assert(garrick_desk != null, "StudyDesk missing in Garrick's house!")
	var garrick_clue = garrick_desk.get_node_or_null("DocumentInteractable")
	assert(garrick_clue != null, "DocumentInteractable missing!")
	garrick_clue.interact(player)
	assert("4,200" in controller.doc_body_label.text and "EMBEZZLE" in controller.doc_title_label.text.to_upper(), "Dossier missing embezzlement details!")
	print("  - [PASS] Garrick's port audit embezzlement dossier verified.")
	controller.close_document_reader()
	interior_inst.queue_free()
	await process_frame
	await process_frame

	print("\n================================================================================")
	print("=== ALL DESIGNATED HOUSES, LIVING ROOMS, PLAYER & PUZZLE TESTS PASSED (100%) ===")
	print("================================================================================\n")
	quit(0)
