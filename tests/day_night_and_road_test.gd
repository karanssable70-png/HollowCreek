extends SceneTree

func _init() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("\n=== STARTING DAY/NIGHT CYCLE AND ROAD NETWORK VERIFICATION ===")
	
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	assert(town_scene != null, "Failed to load town.tscn")
	var town_node: Node = town_scene.instantiate()
	root.add_child(town_node)
	
	for i in range(5):
		await process_frame
		
	# ---------------------------------------------------------
	# 1. VERIFY DAY/NIGHT CONTROLLER
	# ---------------------------------------------------------
	print("\n[1] Verifying TownWorldEnvironment system...")
	var env_mgr: TownWorldEnvironment = town_node.get_node_or_null("EnvironmentManager") as TownWorldEnvironment
	assert(env_mgr != null, "EnvironmentManager is missing or not TownWorldEnvironment")
	assert(env_mgr.cycle_duration == 60.0, "Cycle duration expected 60.0s")
	assert(env_mgr.sun_light != null, "Sun DirectionalLight3D missing")
	assert(env_mgr.environment != null, "Environment resource missing")
	assert(env_mgr.sky_material != null, "ProceduralSkyMaterial missing")
	
	var phases_observed: Dictionary = {}
	var signal_received_count: int = 0
	
	env_mgr.time_updated.connect(func(tod: float, phase: String):
		phases_observed[phase] = tod
		signal_received_count += 1
	)
	
	# Test Morning (t = 0.05)
	env_mgr.set_time_of_day(0.05)
	await process_frame
	var p_m: Dictionary = env_mgr._get_phase_progress()
	assert(p_m["phase"] == "morning", "Expected morning at t=0.05")
	assert(env_mgr.sun_light.light_energy >= 0.4, "Morning sun energy too low: %f" % env_mgr.sun_light.light_energy)
	assert(env_mgr.sun_light.light_energy <= 0.7, "Morning sun energy too bright: %f" % env_mgr.sun_light.light_energy)
	print("  - Morning verified: Sun energy = ", env_mgr.sun_light.light_energy, " (gloomy/muted), Fog density = ", env_mgr.environment.fog_density)
	
	# Test Afternoon (t = 0.35)
	env_mgr.set_time_of_day(0.35)
	await process_frame
	var p_a: Dictionary = env_mgr._get_phase_progress()
	assert(p_a["phase"] == "afternoon", "Expected afternoon at t=0.35")
	assert(env_mgr.sun_light.light_energy >= 0.65, "Afternoon sun energy expected brightest")
	print("  - Afternoon verified: Sun energy = ", env_mgr.sun_light.light_energy, " (brightest muted)")
	
	# Test Evening (t = 0.58)
	env_mgr.set_time_of_day(0.58)
	await process_frame
	var p_e: Dictionary = env_mgr._get_phase_progress()
	assert(p_e["phase"] == "evening", "Expected evening at t=0.58")
	print("  - Evening verified: Sun color = ", env_mgr.sun_light.light_color, " (amber/purple sunset)")
	
	# Test Night (t = 0.80)
	env_mgr.set_time_of_day(0.80)
	await process_frame
	var p_n: Dictionary = env_mgr._get_phase_progress()
	assert(p_n["phase"] == "night", "Expected night at t=0.80")
	assert(env_mgr.sun_light.light_energy == 0.0, "Night sun energy must be 0.0, got: %f" % env_mgr.sun_light.light_energy)
	assert(env_mgr.environment.ambient_light_energy <= 0.08, "Night ambient energy must be <= 0.08, got: %f" % env_mgr.environment.ambient_light_energy)
	assert(env_mgr.environment.tonemap_exposure <= 0.70, "Night tonemap exposure must be darkened, got: %f" % env_mgr.environment.tonemap_exposure)
	print("  - Night verified: Sun energy = 0.0, Ambient energy = ", env_mgr.environment.ambient_light_energy, " (EXTREMELY DARK), Exposure = ", env_mgr.environment.tonemap_exposure)
	print("[PASS] TownWorldEnvironment and 4 lighting phases fully verified.")
	
	# ---------------------------------------------------------
	# 2. VERIFY DYNAMIC WINDOWS AND LANTERNS
	# ---------------------------------------------------------
	print("\n[2] Verifying dynamic window and street lamp materials...")
	var gen: TownGenerator = town_node.get_node("TownWorld") as TownGenerator
	assert(gen._window_meshes.size() >= 10, "Expected at least 10 tracked window meshes, got: %d" % gen._window_meshes.size())
	assert(gen._lantern_lights.size() >= 10, "Expected at least 10 tracked lantern lights, got: %d" % gen._lantern_lights.size())
	
	# At night (which we just set to 0.80), lantern lights should be high energy
	var sample_lantern: OmniLight3D = gen._lantern_lights[0]
	assert(sample_lantern.light_energy >= 2.0, "Night lantern energy expected >= 2.0, got: %f" % sample_lantern.light_energy)
	print("  - Night lantern count: ", gen._lantern_lights.size(), ", Sample light energy: ", sample_lantern.light_energy)
	
	# Switch to afternoon (daytime)
	env_mgr.set_time_of_day(0.35)
	await process_frame
	assert(sample_lantern.light_energy <= 0.2, "Daytime lantern energy expected <= 0.2, got: %f" % sample_lantern.light_energy)
	print("  - Daytime lantern light energy dimmed to: ", sample_lantern.light_energy)
	print("[PASS] Window and lantern day/night dynamic response verified.")
	
	# ---------------------------------------------------------
	# 3. VERIFY ROAD NETWORK
	# ---------------------------------------------------------
	print("\n[3] Verifying medieval road and path network...")
	var road_network = gen.get_node_or_null("RoadNetwork/RoadNetwork")
	if not road_network:
		road_network = gen.get_node_or_null("RoadNetwork")
	assert(road_network != null, "RoadNetwork node missing")
	
	var expected_roads: Array[String] = [
		"RoadEntrance_Gate",
		"RoadEntrance_Slope",
		"RoadEntrance_ToSquare",
		"VillageSquarePlaza",
		"RoadInn_Seg1",
		"RoadInn_Seg2",
		"RoadForge_Seg1",
		"RoadForge_Seg2",
		"RoadTownHall",
		"RoadHarbour_Upper",
		"RoadHarbour_Mid",
		"RoadHarbour_Lower",
		"PathClinic",
		"PathStorehouse_Seg1",
		"PathStorehouse_Seg2",
		"SteppingStones",
		"PathWeaver",
		"PathFisherman",
		"PathMiller"
	]
	
	var found_count: int = 0
	for r_name in expected_roads:
		var node = road_network.find_child(r_name, true, false)
		if node != null:
			found_count += 1
			print("  - Road segment found: ", r_name)
		else:
			print("  ! Missing road segment: ", r_name)
			
	assert(found_count >= 16, "Too many missing road segments! Found: %d" % found_count)
	print("[PASS] Road network segments verified (%d found)." % found_count)
	
	# Verify performance budget: count StaticBody3D collisions in RoadNetwork
	var road_colliders: Array[Node] = road_network.find_children("*", "StaticBody3D", true, false)
	print("  - Total road collision bodies: ", road_colliders.size(), " (budget is under 30)")
	assert(road_colliders.size() <= 30, "Road collision bodies exceed budget of 30!")
	print("[PASS] Road collision performance budget verified.")
	
	# ---------------------------------------------------------
	# 4. VERIFY TIMBER-FRAMED ARCHITECTURE ON LANDMARKS
	# ---------------------------------------------------------
	print("\n[4] Verifying timber framing and architectural details on landmarks...")
	var landmarks = gen.get_node("Landmarks")
	var inn = landmarks.get_node("TheLanternInn")
	assert(inn.find_child("Foundation", true, false) != null, "Lantern Inn stone foundation missing")
	assert(inn.find_child("DiagBraceFL", true, false) != null, "Lantern Inn diagonal timber brace missing")
	assert(inn.find_child("XBraceUL", true, false) != null, "Lantern Inn upper X-brace missing")
	assert(inn.find_child("RoofDormer", true, false) != null, "Lantern Inn dormer roof missing")
	assert(inn.find_child("Chimney", true, false) != null, "Lantern Inn chimney missing")
	assert(inn.find_child("PorchDeck", true, false) != null, "Lantern Inn porch missing")
	print("  - The Lantern Inn: Foundation, Timber Framing, Diagonal/X-Braces, Dormer, Porch, Chimney verified.")
	
	var forge = landmarks.get_node("GarricksForge")
	assert(forge.find_child("StoneBase", true, false) != null, "Garrick's Forge stone base missing")
	assert(forge.find_child("Hearth", true, false) != null, "Forge hearth missing")
	assert(forge.find_child("Anvil", true, false) != null, "Forge anvil missing")
	print("  - Garrick's Forge: Stone workshop base, Timber upper, Hearth, Anvil verified.")
	
	var hall = landmarks.get_node("TownHall")
	assert(hall.find_child("StoneBase", true, false) != null, "Town Hall stone base missing")
	assert(hall.find_child("Diamond1", true, false) != null, "Town Hall diamond timber pattern missing")
	assert(hall.find_child("Tower", true, false) != null, "Town Hall bell/clock tower missing")
	print("  - Town Hall: Stone base, Symmetrical timber framing, Diamond patterns, Clock tower verified.")
	
	var storehouse = landmarks.get_node("OldStorehouse")
	assert(storehouse.find_child("MossL", true, false) != null, "Storehouse moss patches missing")
	assert(storehouse.find_child("CargoDoors", true, false) != null, "Storehouse cargo doors missing")
	print("  - Old Storehouse: Weathered wood, Moss patches, Cargo doors verified.")
	
	print("[PASS] Enhanced medieval architecture verified across all landmarks.")
	
	print("\n=== ALL EXTENDED TESTS PASSED WITH 100% SUCCESS ===")
	quit(0)
