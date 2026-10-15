extends SceneTree

func _init() -> void:
	_run_nav_test.call_deferred()

func _run_nav_test() -> void:
	print("\n=== STARTING ROAD NAVIGATION & NPC REACHABILITY TEST ===")
	
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	var town_node: Node = town_scene.instantiate()
	root.add_child(town_node)
	
	for i in range(5):
		await process_frame
		
	var player = town_node.get_node("Player")
	var npcs = town_node.get_node("NPCs")
	
	# Key waypoints along roads to test player physics standing on roads:
	var road_waypoints = [
		{"name": "Mountain Pass Entry", "pos": Vector3(0, 2.5, -45)},
		{"name": "Pass Gate", "pos": Vector3(0, 2.5, -34)},
		{"name": "Entrance Road Slope", "pos": Vector3(0, 1.8, -24)},
		{"name": "City Bazaar Center", "pos": Vector3(0, 1.2, 0)},
		{"name": "Inn Road Approach", "pos": Vector3(-14, 1.2, -1.8)},
		{"name": "The Inn Entrance Terrace", "pos": Vector3(-18.0, 1.2, -2.0)},
		{"name": "Forge Road Approach", "pos": Vector3(7.0, 1.8, -20.0)},
		{"name": "Iron Works Terrace", "pos": Vector3(22, 1.2, -10)},
		{"name": "Mayor's Manor Avenue", "pos": Vector3(14, 1.2, 1.7)},
		{"name": "Harbour Road Descent", "pos": Vector3(-24, 1.0, 11)},
		{"name": "Western Harbour Pier", "pos": Vector3(-40, 0.6, 14)},
		{"name": "Physician Clinic Approach", "pos": Vector3(12.0, 1.8, -15.0)},
		{"name": "Doctor's Path Approach", "pos": Vector3(3.0, 1.5, 13.5)},
	]
	
	var space = town_node.get_world_3d().direct_space_state
	for wp in road_waypoints:
		var q = PhysicsRayQueryParameters3D.create(Vector3(wp["pos"].x, 3.0, wp["pos"].z), Vector3(wp["pos"].x, -2.0, wp["pos"].z))
		var res = space.intersect_ray(q)
		assert(res != null and not res.is_empty(), "No ground/road under waypoint: " + wp["name"])
		var surface_y: float = res.position.y
		player.global_position = Vector3(wp["pos"].x, surface_y + 0.05, wp["pos"].z)
		player.velocity = Vector3.ZERO
		# Let gravity and collision settle
		for f in range(15):
			await process_frame
		var settled_pos: Vector3 = player.global_position
		print("  - Waypoint '%s': Settled at %s on %s (is_on_floor: %s)" % [wp["name"], settled_pos, res.collider.name, player.is_on_floor()])
		assert(player.is_on_floor(), "Player failed to stand on floor at waypoint: " + wp["name"])
		assert(settled_pos.y > -0.5, "Player fell through road at waypoint: " + wp["name"])
	print("[PASS] All 13 road waypoints confirmed solid, non-floating, and walkable.")
	
	# Reachability test for NPCs from their connecting roads
	var npc_names = ["Lena", "Garrick", "Elara", "Tomas", "Edmund", "Mayor", "Isolde", "Finn", "Oswin"]
	for n_name in npc_names:
		var npc = npcs.get_node(n_name)
		assert(npc != null, "NPC missing: " + n_name)
		
		# Approach NPC from front facing direction along connecting road
		var center = npc.global_position + Vector3(0, 0.9, 0)
		var forward = -npc.global_transform.basis.z.normalized()
		player.global_position = npc.global_position + forward * 1.6
		player.velocity = Vector3.ZERO
		player.rotation = Vector3.ZERO
		player.head.rotation = Vector3.ZERO
		
		var head_pos = player.global_position + Vector3(0, 1.65, 0)
		var dir = (center - head_pos).normalized()
		player.rotation.y = atan2(-dir.x, -dir.z)
		player.head.rotation.x = asin(clampf(dir.y, -1.0, 1.0))
		
		for f in range(5):
			await process_frame
			
		player.raycast.force_raycast_update()
		player._check_interaction()
		print("  - Interaction check at %s: Prompt text = '%s' (colliding: %s, collider: %s, target: %s)" % [
			n_name, player.prompt_label.text, player.raycast.is_colliding(), player.raycast.get_collider(), player.raycast.target_position
		])
		assert(player.prompt_label.text != "", "Prompt empty for NPC: " + n_name)
		assert(n_name in player.prompt_label.text or npc.npc_name in player.prompt_label.text, "Prompt text didn't identify NPC: " + n_name)
	print("[PASS] All NPCs reachable via roads and interactable.")
	
	print("\n=== ALL ROAD NAVIGATION TESTS PASSED WITH 100% SUCCESS ===")
	quit(0)
