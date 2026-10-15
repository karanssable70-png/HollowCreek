class_name TownGenerator
extends Node3D
## Generates the complete Hollow Creek village following the layout from Pictures 1-3
## (Central City Bazaar, Western Loop via Lady X's house, Eastern Manor, and West Coast Harbour)
## and the stylized fantasy medieval architecture from Picture 4 (steep swooping gables,
## curved apex finials, slate-blue roofs, chunky timber corbels, arched gothic windows,
## gallows lamps, and blue-banded barrels).
## Features towering layered mountain ranges in brown, weathered grey, and snow-capped white.

# ---------------------------------------------------------------------------
# Material cache
# ---------------------------------------------------------------------------
var materials: Dictionary = {}

# Lighting arrays for day/night cycle control
var _window_meshes: Array[MeshInstance3D] = []
var _lantern_meshes: Array[MeshInstance3D] = []
var _lantern_lights: Array[OmniLight3D] = []
var _forge_lights: Array[OmniLight3D] = []

# Material references for dynamic emission
var _mat_window_day: StandardMaterial3D
var _mat_window_night: StandardMaterial3D
var _mat_lantern_day: StandardMaterial3D
var _mat_lantern_night: StandardMaterial3D

# Road builder reference
var _road_builder: RefCounted

func _ready() -> void:
	_init_materials()
	_init_dynamic_materials()
	if not has_node("TerrainAndRoads"):
		_generate_world()
	else:
		_collect_existing_lights(self)
	if not _has_baked_roofs():
		MedievalRoofBuilder.upgrade_all_building_roofs(self)
	_ensure_interrogation_door()
	_ensure_all_house_doors()
	_connect_day_night()

func _find_landmarks_node() -> Node3D:
	var lms := get_node_or_null("Landmarks") as Node3D
	if lms: return lms
	for c in get_children():
		if c.name == "Landmarks":
			return c as Node3D
		if "@Node3D@" in c.name:
			var alt = c.get_node_or_null("Landmarks")
			if alt: return alt as Node3D
	var tw = get_node_or_null("TownWorld/Landmarks")
	if tw: return tw as Node3D
	return self

func _ensure_house_door(parent_node: Node3D, h_id: String, h_name: String, offset: Vector3) -> Area3D:
	if not parent_node:
		return null
	var door_name := "HouseDoor_" + h_id
	if parent_node.has_node(door_name):
		return parent_node.get_node(door_name) as Area3D

	var door_area := Area3D.new()
	door_area.name = door_name
	var door_script = load("res://scripts/world/house_door.gd")
	if door_script:
		door_area.set_script(door_script)
	door_area.set("house_id", h_id)
	door_area.set("house_name", h_name)
	door_area.set("prompt_text", "[E] Enter " + h_name)
	door_area.position = offset

	var col := CollisionShape3D.new()
	col.name = "DoorCollision"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.6, 3.4, 2.0)
	col.shape = box_shape
	door_area.add_child(col)

	_create_door_sign_and_lantern(door_area, h_name)

	parent_node.add_child(door_area)
	print("[TownGenerator] Attached HouseDoor for %s (%s) at %s" % [h_name, h_id, door_area.global_position])
	return door_area

func _create_door_sign_and_lantern(door_node: Node3D, title_text: String) -> void:
	var mat_plaque: Material = materials.get("timber_dark", null)
	if not mat_plaque:
		mat_plaque = StandardMaterial3D.new()
		(mat_plaque as StandardMaterial3D).albedo_color = Color(0.2, 0.14, 0.08)
	_box(door_node, "SignPlaque", Vector3(1.3, 0.32, 0.08), Vector3(0, 1.45, 0.1), Vector3.ZERO, mat_plaque, false)

	var mat_glow := StandardMaterial3D.new()
	mat_glow.albedo_color = Color(1.0, 0.85, 0.3)
	mat_glow.emission_enabled = true
	mat_glow.emission = Color(1.0, 0.8, 0.25)
	mat_glow.emission_energy_multiplier = 2.0
	_box(door_node, "DoorLantern", Vector3(0.18, 0.28, 0.18), Vector3(0.75, 1.1, 0.2), Vector3.ZERO, mat_glow, false)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.4)
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position = Vector3(0.75, 1.1, 0.35)
	door_node.add_child(light)

func _ensure_all_house_doors() -> void:
	var lms := _find_landmarks_node()
	if not lms:
		return

	# 1. Tomas Reed (North-East, Gate area)
	var tomas_house := lms.get_node_or_null("TomasReedHouse") as Node3D
	if not tomas_house:
		tomas_house = _build_fachwerk_house(lms, "TomasReedHouse", Vector3(8.0, 1.2, -26.0), 180.0, Vector3(6.5, 4.4, 5.0), true, true, true)
	_ensure_house_door(tomas_house, "tomas", "Tomas Reed's House", Vector3(-1.4, 1.1, 2.8))

	# 2. Dr. Edmund Wren (Physician's Clinic)
	var phys_house := lms.get_node_or_null("PhysiciansClinic") as Node3D
	if phys_house:
		_ensure_house_door(phys_house, "physician", "Physician's Clinic (Dr. Edmund Wren)", Vector3(-1.8, 1.1, 3.8))

	# 3. Garrick Thorne (Harbour Master's House)
	var garrick_house := lms.get_node_or_null("HarbourMasterHouse") as Node3D
	if not garrick_house:
		garrick_house = _build_fachwerk_house(lms, "HarbourMasterHouse", Vector3(-18.0, 0.6, 26.0), -65.0, Vector3(7.2, 4.8, 5.5), true, true, true)
	_ensure_house_door(garrick_house, "garrick", "Harbour Master's House (Garrick Thorne)", Vector3(-1.5, 1.1, 3.0))

	# 4. Corin Fletcher (Bazaar Merchant)
	var corin_house := lms.get_node_or_null("CorinHouse") as Node3D
	if not corin_house:
		corin_house = lms.get_node_or_null("WeaversCottage") as Node3D
	if not corin_house:
		corin_house = _build_fachwerk_house(lms, "CorinHouse", Vector3(-10.0, 0.9, -16.0), 45.0, Vector3(6.5, 4.4, 5.0), true, true, true)
	_ensure_house_door(corin_house, "corin", "Corin Fletcher's House (Bazaar Merchant)", Vector3(-1.6, 1.1, 3.2))

	# 5. Lena Vance (The Lantern Inn)
	var lena_house := lms.get_node_or_null("TheLanternInn") as Node3D
	if lena_house:
		_ensure_house_door(lena_house, "lena", "Lena Vance's House (The Lantern Inn)", Vector3(-2.8, 1.1, 4.2))

	# 6. Finn Cole (Dockworker)
	var finn_house := lms.get_node_or_null("FishermansCottage") as Node3D
	if not finn_house:
		finn_house = lms.get_node_or_null("FinnColeHouse") as Node3D
	if finn_house:
		_ensure_house_door(finn_house, "finn", "Finn Cole's House (Dockworker)", Vector3(-1.5, 1.1, 3.0))

	# 7. Lady Isolde Sterling (Estate)
	var isolde_house := lms.get_node_or_null("IsoldeManor") as Node3D
	if not isolde_house:
		isolde_house = lms.get_node_or_null("MillersShed") as Node3D
	if not isolde_house:
		isolde_house = _build_fachwerk_house(lms, "IsoldeManor", Vector3(-22.0, 1.0, -24.0), 70.0, Vector3(8.5, 5.2, 6.0), true, true, true)
	_ensure_house_door(isolde_house, "isolde", "Lady Isolde's Estate", Vector3(-1.8, 1.1, 3.4))

	# 8. Oswin Grey (Town Scribe)
	var oswin_house := lms.get_node_or_null("OswinGreyHouse") as Node3D
	if not oswin_house:
		oswin_house = _build_fachwerk_house(lms, "OswinGreyHouse", Vector3(-10.0, 0.8, 2.0), 90.0, Vector3(6.2, 4.2, 4.8), true, true, true)
	_ensure_house_door(oswin_house, "oswin", "Oswin Grey's Home (Town Scribe)", Vector3(-1.4, 1.1, 2.7))

	# 9. Elora Nightshade (Herbalist)
	var elora_house := lms.get_node_or_null("ElarasHerbalistCottage") as Node3D
	if elora_house:
		_ensure_house_door(elora_house, "elara", "Elora's Cottage (Herbalist)", Vector3(-1.5, 1.1, 3.6))

	# 10. Mayor Eldridge (Secret House)
	var mayor_house := lms.get_node_or_null("MayorSecretHouse") as Node3D
	if not mayor_house:
		mayor_house = lms.get_node_or_null("OldStorehouse") as Node3D
	if mayor_house:
		_ensure_house_door(mayor_house, "mayor", "Mayor Eldridge's Secret House", Vector3(0, 1.5, 3.8))

func _ensure_interrogation_door() -> void:
	var town_hall := get_node_or_null("Landmarks/TownHall")
	if not town_hall:
		for c in get_children():
			if "@Node3D@" in c.name:
				town_hall = c.get_node_or_null("TownHall")
				if town_hall: break
	if not town_hall:
		return

	if town_hall.has_node("InterrogationDoor"):
		return

	var door_area := Area3D.new()
	door_area.name = "InterrogationDoor"
	var door_script = load("res://scripts/world/interrogation_door.gd")
	if door_script:
		door_area.set_script(door_script)
	door_area.position = Vector3(0, 2.0, 5.65)

	var col := CollisionShape3D.new()
	col.name = "DoorCollision"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(3.2, 4.0, 1.8)
	col.shape = box_shape
	door_area.add_child(col)

	town_hall.add_child(door_area)
	print("[TownGenerator] Attached InterrogationDoor to TownHall facade at ", door_area.global_position)

func _has_baked_roofs() -> bool:
	var inn_roof := get_node_or_null("Landmarks/TheLanternInn/RoofMain") as MeshInstance3D
	if inn_roof and inn_roof.mesh is ArrayMesh:
		return true
	for c in get_children():
		if "@Node3D@" in c.name:
			var alt_roof := c.get_node_or_null("TheLanternInn/RoofMain") as MeshInstance3D
			if alt_roof and alt_roof.mesh is ArrayMesh:
				return true
	return false

func _collect_existing_lights(node: Node) -> void:
	if node is MeshInstance3D:
		var n_name := node.name.to_lower()
		if "win" in n_name or "glass" in n_name:
			_window_meshes.append(node)
		elif "lantern" in n_name or "torch" in n_name:
			_lantern_meshes.append(node)
	elif node is OmniLight3D:
		var p_name := node.get_parent().name.to_lower() if node.get_parent() else ""
		if "forge" in p_name or "hearth" in p_name or "coal" in p_name:
			_forge_lights.append(node)
		else:
			_lantern_lights.append(node)
			
	for child in node.get_children():
		_collect_existing_lights(child)

# ---------------------------------------------------------------------------
# MATERIALS
# ---------------------------------------------------------------------------
func _init_materials() -> void:
	# Plaster / walls
	materials["plaster_cream"]    = _mk(Color(0.84, 0.78, 0.70), 0.88)
	materials["plaster_aged"]     = _mk(Color(0.74, 0.70, 0.64), 0.92)
	materials["plaster_grey"]     = _mk(Color(0.60, 0.58, 0.56), 0.90)
	
	# Timber (chunky dark rustic fantasy wood)
	materials["timber_dark"]      = _mk(Color(0.20, 0.13, 0.08), 0.80)
	materials["timber_plank"]     = _mk(Color(0.38, 0.28, 0.18), 0.82)
	materials["timber_weathered"] = _mk(Color(0.28, 0.26, 0.24), 0.92)
	materials["timber_mossy"]     = _mk(Color(0.25, 0.28, 0.22), 0.90)
	
	# Roofing (Rich dark burgundy-red, muted crimson, dusty plum, and reddish-purple)
	materials["roof_slate"]           = _mk(Color(0.24, 0.32, 0.45), 0.70)
	materials["roof_terracotta"]      = MedievalRoofBuilder.get_roof_material("burgundy")
	materials["roof_terracotta_dark"] = MedievalRoofBuilder.get_roof_material("wine")
	materials["roof_dark_red"]        = MedievalRoofBuilder.get_roof_material("plum")
	
	# Stone (matching reference image masonry)
	materials["stone_wall"]       = _mk(Color(0.48, 0.50, 0.54), 0.90)
	materials["stone_foundation"] = _mk(Color(0.38, 0.40, 0.44), 0.92)
	materials["stone_path"]       = _mk(Color(0.45, 0.42, 0.40), 0.88)
	
	# Terrain
	materials["grass"]            = _mk(Color(0.22, 0.38, 0.18), 0.92)
	materials["grass_dark"]       = _mk(Color(0.18, 0.30, 0.14), 0.92)
	materials["sand"]             = _mk(Color(0.72, 0.65, 0.48), 0.95)
	
	# Multi-toned Mountain Strata (Brown, White, Grey-ish)
	materials["rock_mountain_base"] = _mk(Color(0.36, 0.30, 0.26), 0.92) # Earthy brown-grey base
	materials["rock_mountain_mid"]  = _mk(Color(0.48, 0.46, 0.44), 0.88) # Weathered granite grey
	materials["rock_mountain_ridge"]= _mk(Color(0.64, 0.62, 0.60), 0.85) # Light stone crag
	materials["rock_mountain_snow"] = _mk(Color(0.88, 0.90, 0.94), 0.70) # Frosted white snowcap
	materials["rock_mountain_dark"] = _mk(Color(0.24, 0.20, 0.18), 0.92) # Dark basalt
	materials["rock_mountain"]      = materials["rock_mountain_mid"]
	materials["rock_dark"]          = materials["rock_mountain_dark"]
	
	# Vegetation
	materials["pine"]             = _mk(Color(0.12, 0.26, 0.14), 0.92)
	materials["oak"]              = _mk(Color(0.25, 0.42, 0.18), 0.88)
	materials["bush"]             = _mk(Color(0.20, 0.35, 0.16), 0.92)
	materials["flower_red"]       = _mk(Color(0.78, 0.15, 0.18), 0.82)
	materials["flower_yellow"]    = _mk(Color(0.85, 0.72, 0.12), 0.82)
	materials["flower_blue"]      = _mk(Color(0.25, 0.38, 0.72), 0.82)
	materials["mushroom_red"]     = _mk(Color(0.82, 0.18, 0.15), 0.80)
	
	# Metal & Props
	materials["iron"]             = _mk(Color(0.20, 0.21, 0.23), 0.42, 0.82)
	materials["iron_blue"]        = _mk(Color(0.34, 0.46, 0.58), 0.45, 0.55) # Blue-painted iron barrel hoops
	materials["awning_red"]       = _mk(Color(0.72, 0.22, 0.20), 0.85)
	materials["awning_cream"]     = _mk(Color(0.88, 0.84, 0.75), 0.85)
	
	# Emissive (swapped dynamically)
	materials["window_glow"]      = _mk_emissive(Color(0.85, 0.70, 0.40), Color(0.95, 0.72, 0.35), 1.8)
	materials["lantern_glow"]     = _mk_emissive(Color(0.90, 0.75, 0.40), Color(0.95, 0.72, 0.30), 2.5)
	materials["forge_glow"]       = _mk_emissive(Color(0.95, 0.40, 0.08), Color(0.95, 0.30, 0.05), 3.2)
	
	# Water
	materials["water"]            = _mk_water(Color(0.06, 0.25, 0.35, 0.85), 0.12)
	materials["water_shallow"]    = _mk_water(Color(0.14, 0.45, 0.45, 0.70), 0.18)

func _init_dynamic_materials() -> void:
	# Pre-create day and night variants for windows and lanterns
	_mat_window_day = _mk(Color(0.28, 0.32, 0.40), 0.50)  # dark glass during day
	_mat_window_night = _mk_emissive(Color(0.95, 0.78, 0.42), Color(1.0, 0.78, 0.38), 3.5)
	_mat_lantern_day = _mk(Color(0.45, 0.35, 0.25), 0.70)  # dim housing during day
	_mat_lantern_night = _mk_emissive(Color(1.0, 0.82, 0.42), Color(1.0, 0.78, 0.32), 4.0)

func _mk(albedo: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	return m

func _mk_emissive(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.emission_enabled = true
	m.emission = emission
	m.emission_energy_multiplier = energy
	m.roughness = 0.35
	return m

func _mk_water(albedo: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = roughness
	m.metallic = 0.15
	return m

# ---------------------------------------------------------------------------
# WORLD GENERATION
# ---------------------------------------------------------------------------
func _generate_world() -> void:
	for child in get_children():
		child.queue_free()

	var terrain := Node3D.new(); terrain.name = "TerrainAndRoads"; add_child(terrain)
	_build_landmass(terrain)

	var ocean := Node3D.new(); ocean.name = "OceanAndCoast"; add_child(ocean)
	_build_ocean_and_coastline(ocean)

	var mountains := Node3D.new(); mountains.name = "NorthernMountains"; add_child(mountains)
	_build_northern_mountains_and_pass(mountains)

	var roads := Node3D.new(); roads.name = "RoadNetwork"; add_child(roads)
	_build_road_network(roads)

	var landmarks := Node3D.new(); landmarks.name = "Landmarks"; add_child(landmarks)
	_build_all_landmarks(landmarks)

	var vegetation := Node3D.new(); vegetation.name = "Vegetation"; add_child(vegetation)
	_build_vegetation(vegetation)

	var props := Node3D.new(); props.name = "VillageProps"; add_child(props)
	_build_props(props)

	var bounds := Node3D.new(); bounds.name = "Boundaries"; add_child(bounds)
	_build_boundary_colliders(bounds)

# ---------------------------------------------------------------------------
# DAY/NIGHT INTEGRATION
# ---------------------------------------------------------------------------
func _connect_day_night() -> void:
	await get_tree().process_frame
	var env_mgr := get_parent().get_node_or_null("EnvironmentManager")
	if env_mgr and env_mgr.has_signal("time_updated"):
		env_mgr.connect("time_updated", _on_time_updated)

func _on_time_updated(time_of_day: float, phase: String) -> void:
	var window_emission: float = 0.0
	var lantern_emission: float = 0.0
	var lantern_light_energy: float = 0.0

	match phase:
		"morning":
			window_emission = 0.15
			lantern_emission = 0.1
			lantern_light_energy = 0.3
		"afternoon":
			window_emission = 0.05
			lantern_emission = 0.0
			lantern_light_energy = 0.1
		"evening":
			var t := _get_evening_progress(time_of_day)
			window_emission = lerpf(0.3, 1.0, t)
			lantern_emission = lerpf(0.2, 1.0, t)
			lantern_light_energy = lerpf(0.5, 2.5, t)
		"night":
			window_emission = 1.0
			lantern_emission = 1.0
			lantern_light_energy = 2.8

	# Update window materials
	for wm in _window_meshes:
		if is_instance_valid(wm):
			if window_emission > 0.3:
				wm.material_override = _mat_window_night
				_mat_window_night.emission_energy_multiplier = lerpf(1.5, 4.0, window_emission)
			else:
				wm.material_override = _mat_window_day

	# Update lantern meshes
	for lm in _lantern_meshes:
		if is_instance_valid(lm):
			if lantern_emission > 0.3:
				lm.material_override = _mat_lantern_night
				_mat_lantern_night.emission_energy_multiplier = lerpf(1.5, 5.0, lantern_emission)
			else:
				lm.material_override = _mat_lantern_day

	# Update lantern point lights
	for ll in _lantern_lights:
		if is_instance_valid(ll):
			ll.light_energy = lantern_light_energy

	# Forge lights always glow but brighten at night
	for fl in _forge_lights:
		if is_instance_valid(fl):
			fl.light_energy = lerpf(1.5, 3.5, window_emission)

func _get_evening_progress(tod: float) -> float:
	var evening_start := 0.5
	var evening_end := 0.667
	if tod < evening_start: return 0.0
	if tod > evening_end: return 1.0
	return (tod - evening_start) / (evening_end - evening_start)

# ---------------------------------------------------------------------------
# 1. TERRAIN (Landmass with west-facing harbour slope and surrounding ocean)
# ---------------------------------------------------------------------------
func _build_landmass(root: Node3D) -> void:
	# Main island plateau (surface at Y = 0.60)
	_box(root, "MainIslandPlateau", Vector3(92, 3.0, 80), Vector3(0, -0.9, 0), Vector3.ZERO, materials["grass"], true)
	# Northern mountain pass entrance ramp (Z = -48 to -34, height ~1.80)
	_box(root, "PassRamp", Vector3(14, 2.5, 24), Vector3(0, 0.55, -41), Vector3.ZERO, materials["grass_dark"], true)
	# Entrance slope embankment connecting gate at Z=-34 (Y=1.80) to bazaar at Z=-10 (Y=0.60)
	_box(root, "EntranceRampSlope", Vector3(14, 2.5, 25), Vector3(0, 0.05, -22), Vector3(-2.8, 0, 0), materials["grass_dark"], true)
	# Eastern bluff where Mayor's manor overlooks the coast (surface at Y = 0.80)
	_box(root, "EastBluff", Vector3(32, 2.0, 48), Vector3(32, -0.2, 5), Vector3.ZERO, materials["grass_dark"], true)
	# Forge road embankment connecting Entrance slope to East Bluff
	_box(root, "ForgeRoadEmbankment", Vector3(18, 1.8, 14), Vector3(14, -0.1, -16), Vector3(0, 15, -1.5), materials["grass_dark"], true)
	# Western beach slope descending to the Harbour on the west coast
	_box(root, "WestBeachSlope", Vector3(22, 1.2, 55), Vector3(-42, -1.0, 10), Vector3(0, 0, 6), materials["sand"], true)
	# Harbour road embankment grading from Bazaar (0.60) down to Pier (0.12)
	_box(root, "HarbourRoadEmbankment", Vector3(12, 1.6, 32), Vector3(-24, -0.35, 11), Vector3(0, 78, 1.2), materials["grass_dark"], true)
	# Southern beach slope toward ocean
	_box(root, "SouthBeachSlope", Vector3(72, 1.2, 22), Vector3(2, -1.0, 38), Vector3(-6, 0, 0), materials["sand"], true)

# ---------------------------------------------------------------------------
# 2. OCEAN AND COASTLINE
# ---------------------------------------------------------------------------
func _build_ocean_and_coastline(root: Node3D) -> void:
	var ocean_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new(); plane.size = Vector2(340, 340)
	ocean_mi.mesh = plane; ocean_mi.material_override = materials["water"]
	ocean_mi.position = Vector3(0, -0.42, 20); root.add_child(ocean_mi)

	# Shallow turquoise water bands
	_add_plane(root, Vector2(30, 85), Vector3(-48, -0.38, 12), materials["water_shallow"])
	_add_plane(root, Vector2(85, 28), Vector3(5, -0.38, 42), materials["water_shallow"])

	# Coastal rock clusters (west harbour cove and southern cliffs)
	var rocks := [
		[Vector3(-52, 0.2, 2), Vector3(5.0, 3.8, 5.5), 25.0],
		[Vector3(-50, 0.4, 22), Vector3(4.2, 3.2, 4.8), -15.0],
		[Vector3(-55, 0.8, 14), Vector3(6.5, 5.5, 6.0), 18.0],
		[Vector3(-46, 0.1, 30), Vector3(4.5, 3.0, 5.0), 32.0],
		[Vector3(47, 1.2, -18), Vector3(5.5, 4.8, 6.5), -30.0],
		[Vector3(49, 0.8, -2), Vector3(6.0, 5.2, 7.0), 10.0],
		[Vector3(51, 1.0, 16), Vector3(5.0, 4.5, 5.8), -45.0],
		[Vector3(48, 0.5, 32), Vector3(6.5, 4.0, 6.0), 22.0],
		[Vector3(-18, 0.0, 48), Vector3(5.0, 3.0, 5.2), 35.0],
		[Vector3(24, 0.2, 52), Vector3(6.0, 3.8, 5.5), -20.0],
	]
	for r in rocks:
		_rock(root, r[0], r[1], r[2], materials["rock_mountain_dark"])

# ---------------------------------------------------------------------------
# 3. TOWERING LAYERED MOUNTAINS (Brown, White, Grey-ish)
# ---------------------------------------------------------------------------
func _build_northern_mountains_and_pass(root: Node3D) -> void:
	# West Mountain Range (flanking the pass to the west and towering north-west)
	var west_peaks := [
		# pos, size, rot_y, has_snow
		{"pos": Vector3(-13, 12, -43), "sz": Vector3(16, 28, 16), "rot": 18.0, "snow": true},
		{"pos": Vector3(-22, 16, -49), "sz": Vector3(20, 34, 18), "rot": -24.0, "snow": true},
		{"pos": Vector3(-34, 19, -47), "sz": Vector3(24, 40, 22), "rot": 32.0, "snow": true},
		{"pos": Vector3(-48, 18, -51), "sz": Vector3(26, 38, 24), "rot": -16.0, "snow": true},
		{"pos": Vector3(-62, 15, -45), "sz": Vector3(22, 32, 20), "rot": 40.0, "snow": true},
		# Foothill crags and spurs
		{"pos": Vector3(-14, 8, -32),  "sz": Vector3(12, 18, 12), "rot": -12.0, "snow": false},
		{"pos": Vector3(-28, 10, -35), "sz": Vector3(15, 22, 14), "rot": 20.0, "snow": false},
		{"pos": Vector3(-44, 11, -36), "sz": Vector3(17, 24, 16), "rot": -20.0, "snow": false},
	]
	for p in west_peaks:
		_grand_mountain(root, "MtnWest", p["pos"], p["sz"], p["rot"], p["snow"])

	# East Mountain Range (flanking the pass to the east and towering north-east)
	var east_peaks := [
		{"pos": Vector3(13, 12, -43),  "sz": Vector3(16, 28, 16), "rot": -18.0, "snow": true},
		{"pos": Vector3(22, 16, -49),  "sz": Vector3(20, 34, 18), "rot": 24.0, "snow": true},
		{"pos": Vector3(34, 19, -47),  "sz": Vector3(24, 40, 22), "rot": -32.0, "snow": true},
		{"pos": Vector3(48, 18, -51),  "sz": Vector3(26, 38, 24), "rot": 16.0, "snow": true},
		{"pos": Vector3(62, 15, -45),  "sz": Vector3(22, 32, 20), "rot": -40.0, "snow": true},
		# Foothill crags and spurs
		{"pos": Vector3(14, 8, -32),   "sz": Vector3(12, 18, 12), "rot": 12.0, "snow": false},
		{"pos": Vector3(28, 10, -35),  "sz": Vector3(15, 22, 14), "rot": -20.0, "snow": false},
		{"pos": Vector3(44, 11, -36),  "sz": Vector3(17, 24, 16), "rot": 20.0, "snow": false},
	]
	for p in east_peaks:
		_grand_mountain(root, "MtnEast", p["pos"], p["sz"], p["rot"], p["snow"])

	# High Northern Backdrop Barrier behind the pass entry (blocking escape)
	_grand_mountain(root, "MtnBackDrop", Vector3(0, 16, -60), Vector3(24, 34, 16), 0.0, true)
	_rock(root, Vector3(-3.2, 2.2, -54.5), Vector3(5.0, 4.2, 5.0), 18.0, materials["rock_mountain_base"])
	_rock(root, Vector3(3.0, 2.0, -54.8), Vector3(4.8, 4.0, 4.5), -25.0, materials["rock_mountain_mid"])

# ---------------------------------------------------------------------------
# 4. ROAD NETWORK
# ---------------------------------------------------------------------------
func _build_road_network(root: Node3D) -> void:
	var rb_script = load("res://scripts/world/road_builder.gd")
	if rb_script:
		_road_builder = rb_script.new(materials)
		_road_builder.build_road_network(root)
	else:
		_build_simple_roads(root)

func _build_simple_roads(root: Node3D) -> void:
	var sp: Material = materials["stone_path"]
	_cyl(root, "SquarePlaza", 13.5, 13.5, 0.12, Vector3(0, 0.72, 0), Vector3.ZERO, sp, true)
	_box(root, "RdPassToSquare", Vector3(4.8, 0.10, 34), Vector3(0, 0.72, -17), Vector3.ZERO, sp, false)
	_box(root, "RdInPass", Vector3(4.2, 0.10, 24), Vector3(0, 1.85, -42), Vector3(5.5, 0, 0), sp, false)
	_box(root, "RdWestInn", Vector3(26, 0.10, 3.8), Vector3(-13, 0.72, -2.5), Vector3(0, -8, 0), sp, false)
	_box(root, "RdEastForge", Vector3(34, 0.10, 3.8), Vector3(17, 0.72, -4), Vector3(0, 6, 0), sp, false)
	_box(root, "RdSouthDock", Vector3(4, 0.10, 36), Vector3(3, 0.5, 18), Vector3(0, -4, 0), sp, false)

# ---------------------------------------------------------------------------
# 5. ALL LANDMARKS (Following Pictures 1-4)
# ---------------------------------------------------------------------------
func _build_all_landmarks(root: Node3D) -> void:
	_build_the_lantern_inn(root)
	_build_garricks_forge(root)
	_build_elaras_cottage(root)
	_build_town_hall(root)
	_build_physicians_clinic(root)
	_build_old_storehouse(root)
	_build_village_square_and_well(root)
	_build_fishing_harbour_and_dock(root)
	_build_mountain_entrance_gate(root)
	_build_secondary_cottages(root)

# ===== LANDMARK 1: THE INN (THE LANTERN INN) =====
# Positioned West of City Bazaar facing the square (matching Picture 2 & 3)
func _build_the_lantern_inn(root: Node3D) -> void:
	var b := Node3D.new(); b.name = "TheLanternInn"
	b.position = Vector3(-24, 0.7, -2); b.rotation_degrees.y = 90.0
	root.add_child(b)

	# 1. Stone ground floor base with quoins
	_box(b, "Foundation", Vector3(12.5, 0.8, 9.5), Vector3(0, 0.4, 0), Vector3.ZERO, materials["stone_foundation"], true)
	_stone_quoins(b, 12.5, 3.2, 9.5)

	# Ground floor stone walls
	_box(b, "GndWalls", Vector3(11.8, 2.6, 9.0), Vector3(0, 2.1, 0), Vector3.ZERO, materials["stone_wall"], true)

	# Corner posts on stone base
	for cx in [-5.9, 5.9]:
		for cz in [-4.4, 4.4]:
			_box(b, "GPost", Vector3(0.25, 3.4, 0.25), Vector3(cx, 1.7, cz), Vector3.ZERO, materials["timber_dark"], false)

	# 2. Overhanging jetty floor with perimeter girth beam and corbels
	_box(b, "GirthBeam", Vector3(13.2, 0.28, 10.2), Vector3(0, 3.4, 0), Vector3.ZERO, materials["timber_dark"], false)
	for bx in [-5.4, -2.7, 0.0, 2.7, 5.4]:
		_box(b, "CorbelBracket", Vector3(0.22, 0.42, 0.42), Vector3(bx, 3.2, 4.8), Vector3(25, 0, 0), materials["timber_dark"], false)

	# 3. Upper half-timbered floor
	_box(b, "UpperWalls", Vector3(12.6, 3.0, 9.6), Vector3(0, 4.9, 0.1), Vector3.ZERO, materials["plaster_cream"], true)

	# Timber framing posts and horizontal beams
	_box(b, "BeamGH1", Vector3(13.1, 0.20, 0.20), Vector3(0, 3.5, 5.05), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "BeamGH2", Vector3(13.1, 0.20, 0.20), Vector3(0, 6.7, 5.05), Vector3.ZERO, materials["timber_dark"], false)
	for cx in [-6.2, 6.2]:
		for cz in [-4.8, 5.0]:
			_box(b, "CornerPost", Vector3(0.24, 3.2, 0.24), Vector3(cx, 5.1, cz), Vector3.ZERO, materials["timber_dark"], false)

	# Diagonal and X-braces on upper facade
	_box(b, "DiagBraceFL", Vector3(0.16, 3.2, 0.16), Vector3(-4.2, 5.1, 5.06), Vector3(0, 0, 30), materials["timber_dark"], false)
	_box(b, "DiagBraceFR", Vector3(0.16, 3.2, 0.16), Vector3(4.2, 5.1, 5.06), Vector3(0, 0, -30), materials["timber_dark"], false)
	_box(b, "XBraceUL", Vector3(0.14, 2.8, 0.14), Vector3(-1.8, 5.1, 5.06), Vector3(0, 0, 25), materials["timber_dark"], false)
	_box(b, "XBraceUR", Vector3(0.14, 2.8, 0.14), Vector3(1.8, 5.1, 5.06), Vector3(0, 0, -25), materials["timber_dark"], false)

	# Side cantilevered bay window with mini terracotta roof
	_side_bay_window(b, Vector3(-6.55, 4.9, 0), Vector3(0, -90, 0))

	# 4. Terracotta Clay Tiled Roofs
	_terracotta_roof(b, "RoofMain", Vector3(11.2, 4.4, 14.0), Vector3(0, 8.9, 0), Vector3(0, 90, 0), true)
	_dormer_window(b, Vector3(2.5, 8.4, 4.2), Vector3(-12, 0, 0))

	# Stone masonry chimney
	_masonry_chimney(b, Vector3(-4.4, 7.8, -3.0), 3.8)

	# Porch Deck with steps leading out to City Bazaar
	_box(b, "PorchDeck", Vector3(7.2, 0.35, 3.6), Vector3(0, 0.18, 6.3), Vector3.ZERO, materials["timber_plank"], true)
	_box(b, "PorchStep1", Vector3(6.0, 0.18, 0.8), Vector3(0, 0.09, 8.1), Vector3.ZERO, materials["stone_path"], true)
	for px in [-3.3, 3.3]:
		_cyl(b, "PorchPost", 0.14, 0.16, 3.2, Vector3(px, 1.75, 7.6), Vector3.ZERO, materials["timber_dark"], true)
	_terracotta_roof(b, "PorchRoof", Vector3(7.8, 0.35, 4.2), Vector3(0, 3.4, 6.3), Vector3(14, 0, 0), true)

	# Arched wooden plank doorway with stone surround
	_box(b, "DoorSurround", Vector3(1.8, 2.6, 0.14), Vector3(0, 1.35, 4.76), Vector3.ZERO, materials["stone_foundation"], false)
	_box(b, "Door", Vector3(1.4, 2.4, 0.10), Vector3(0, 1.30, 4.78), Vector3.ZERO, materials["timber_dark"], false)

	# Windows (cross-mullion windows)
	var win_pos := [
		Vector3(-3.2, 1.8, 4.78),
		Vector3(3.2, 1.8, 4.78),
		Vector3(-3.4, 5.2, 5.08),
		Vector3(0, 5.2, 5.08),
		Vector3(3.4, 5.2, 5.08),
		Vector3(6.52, 1.8, 0),
		Vector3(6.52, 5.2, 0),
	]
	for wp in win_pos:
		var rot := Vector3(0, 90, 0) if absf(wp.x) > 6.0 else Vector3.ZERO
		_fachwerk_window(b, wp, rot, absf(wp.y) < 3.0)

	# Hanging Tavern Sign & Gallows Lantern
	var sp := _box(b, "SignPole", Vector3(1.8, 0.12, 0.12), Vector3(3.8, 3.8, 5.0), Vector3.ZERO, materials["iron"], false)
	_box(sp, "SignBoard", Vector3(1.4, 0.9, 0.06), Vector3(0, -0.5, 0), Vector3.ZERO, materials["timber_plank"], false)
	_gallows_lamp(b, Vector3(3.6, 0.0, 7.8))

	# Outdoor picnic tables & Blue-banded barrels
	_picnic_table(b, Vector3(6.5, 0, 5.5), 15.0)
	_picnic_table(b, Vector3(7.8, 0, 0.8), -20.0)
	_blue_barrel(b, Vector3(-4.2, 0.45, 5.5))
	_blue_barrel(b, Vector3(-4.8, 0.45, 5.2))

# ===== LANDMARK 2: IRON WORKS / GARRICK'S FORGE =====
# Positioned along North-East road near Physician's Clinic (matching Picture 1)
func _build_garricks_forge(root: Node3D) -> void:
	var b := Node3D.new(); b.name = "GarricksForge"
	b.position = Vector3(25, 0.9, -12); b.rotation_degrees.y = -65.0
	root.add_child(b)

	# 1. Stone workshop base with quoins
	_box(b, "StoneBase", Vector3(10.5, 4.2, 8.5), Vector3(0, 2.1, 0), Vector3.ZERO, materials["stone_wall"], true)
	_stone_quoins(b, 10.5, 4.2, 8.5)

	# 2. Overhanging upper timber living quarters
	_box(b, "GirthBeam", Vector3(11.2, 0.26, 9.2), Vector3(0, 4.2, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "UpperTimber", Vector3(11.0, 2.8, 9.0), Vector3(0, 5.7, 0.1), Vector3.ZERO, materials["plaster_cream"], true)
	_box(b, "FBeamH", Vector3(11.1, 0.18, 0.18), Vector3(0, 4.4, 4.55), Vector3.ZERO, materials["timber_dark"], false)

	# Diagonal braces on upper facade
	_box(b, "ForgeDiagL", Vector3(0.14, 2.2, 0.14), Vector3(-3.8, 5.7, 4.56), Vector3(0, 0, 32), materials["timber_dark"], false)
	_box(b, "ForgeDiagR", Vector3(0.14, 2.2, 0.14), Vector3(3.8, 5.7, 4.56), Vector3(0, 0, -32), materials["timber_dark"], false)

	# 3. Terracotta Clay Tiled Roof with Dormer
	_terracotta_roof(b, "Roof", Vector3(9.8, 3.8, 12.2), Vector3(0, 8.5, 0), Vector3(0, 90, 0), true)
	_dormer_window(b, Vector3(2.4, 8.0, 3.8), Vector3(-12, 0, 0))

	# Massive stone forge chimney with stone cap
	_box(b, "Chimney", Vector3(2.2, 9.2, 2.2), Vector3(-3.8, 4.6, -2.8), Vector3.ZERO, materials["stone_wall"], true)
	_box(b, "ChimneyCap", Vector3(2.5, 0.28, 2.5), Vector3(-3.8, 9.3, -2.8), Vector3.ZERO, materials["stone_foundation"], false)

	# Open-air smithy shed
	_box(b, "ShedDeck", Vector3(6.5, 0.18, 5.0), Vector3(0.5, 0.09, 6.2), Vector3.ZERO, materials["stone_path"], true)
	_cyl(b, "ShedPostL", 0.18, 0.20, 3.4, Vector3(-2.5, 1.7, 8.5), Vector3.ZERO, materials["timber_dark"], true)
	_cyl(b, "ShedPostR", 0.18, 0.20, 3.4, Vector3(3.5, 1.7, 8.5), Vector3.ZERO, materials["timber_dark"], true)
	_terracotta_roof(b, "ShedRoof", Vector3(7.2, 0.35, 5.6), Vector3(0.5, 3.4, 6.2), Vector3(12, 0, 0), true)

	# Forge hearth with glowing coals
	_box(b, "Hearth", Vector3(1.8, 1.2, 1.8), Vector3(-1.5, 0.6, 5.5), Vector3.ZERO, materials["stone_wall"], true)
	_box(b, "Coals", Vector3(1.4, 0.15, 1.4), Vector3(-1.5, 1.25, 5.5), Vector3.ZERO, materials["forge_glow"], false)
	var fl := _point_light(b, Vector3(-1.5, 1.6, 5.5), Color(1.0, 0.45, 0.10), 3.5, 9.0)
	_forge_lights.append(fl)

	# Anvil & stump
	_cyl(b, "Stump", 0.42, 0.48, 0.85, Vector3(0.8, 0.42, 6.0), Vector3.ZERO, materials["timber_dark"], true)
	_box(b, "Anvil", Vector3(0.75, 0.40, 0.38), Vector3(0.8, 1.0, 6.0), Vector3.ZERO, materials["iron"], true)

	# Water trough, woodpile, and blue barrels
	_box(b, "Trough", Vector3(1.6, 0.7, 0.9), Vector3(2.8, 0.35, 5.0), Vector3.ZERO, materials["timber_weathered"], true)
	_box(b, "Woodpile", Vector3(2.4, 1.3, 1.0), Vector3(-4.2, 0.65, 3.0), Vector3.ZERO, materials["timber_plank"], true)
	_blue_barrel(b, Vector3(2.2, 0.45, 7.5))

	# Upper windows
	_fachwerk_window(b, Vector3(3.0, 5.6, 4.55), Vector3.ZERO)
	_fachwerk_window(b, Vector3(-2.0, 5.6, 4.55), Vector3.ZERO)

# ===== LANDMARK 3: DOCTOR / HERBALIST COTTAGE =====
# Positioned South of City Bazaar (matching Doctor in Pictures 2 & 3)
func _build_elaras_cottage(root: Node3D) -> void:
	var b := Node3D.new(); b.name = "ElarasHerbalistCottage"
	b.position = Vector3(4, 0.7, 24); b.rotation_degrees.y = 180.0
	root.add_child(b)

	# 1. Ground floor stone masonry base with quoins
	_box(b, "Foundation", Vector3(8.0, 2.6, 6.5), Vector3(0, 1.3, 0), Vector3.ZERO, materials["stone_wall"], true)
	_stone_quoins(b, 8.0, 2.6, 6.5)

	# 2. Overhanging upper floor with girth beam and corbels
	_box(b, "GirthBeam", Vector3(8.6, 0.26, 7.1), Vector3(0, 2.6, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "Walls", Vector3(8.4, 2.4, 6.9), Vector3(0, 3.9, 0), Vector3.ZERO, materials["plaster_cream"], true)

	# Timber framing posts and diagonal braces
	_box(b, "ElaraDiagL", Vector3(0.12, 1.8, 0.12), Vector3(-2.8, 3.9, 3.5), Vector3(0, 0, 32), materials["timber_dark"], false)
	_box(b, "ElaraDiagR", Vector3(0.12, 1.8, 0.12), Vector3(2.8, 3.9, 3.5), Vector3(0, 0, -32), materials["timber_dark"], false)

	# 3. Terracotta roof with dormer and stone chimney
	_terracotta_roof(b, "Roof", Vector3(7.4, 3.2, 9.4), Vector3(0, 6.4, 0), Vector3(0, 90, 0), true)
	_dormer_window(b, Vector3(1.8, 6.0, 2.8), Vector3(-12, 0, 0))
	_masonry_chimney(b, Vector3(-2.6, 5.6, -1.8), 3.0)

	# Door with stone surround (facing North toward road)
	_box(b, "DoorSurround", Vector3(1.3, 2.2, 0.14), Vector3(-1.6, 1.1, 3.32), Vector3.ZERO, materials["stone_foundation"], false)
	_box(b, "Door", Vector3(1.0, 2.05, 0.10), Vector3(-1.6, 1.05, 3.34), Vector3.ZERO, materials["timber_dark"], false)

	# Windows
	_fachwerk_window(b, Vector3(1.6, 1.3, 3.32), Vector3.ZERO, true)
	_fachwerk_window(b, Vector3(0.0, 4.0, 3.52), Vector3.ZERO, false)

	# Doctor / herbalist medicine planters
	for p in [Vector3(2.2, 0.35, 4.2), Vector3(-2.2, 0.35, 4.2)]:
		_box(b, "Planter", Vector3(1.8, 0.5, 0.7), p, Vector3.ZERO, materials["timber_plank"], true)
		_sphere(b, "Herbs", 0.3, p + Vector3(-0.4, 0.4, 0), materials["flower_red"])
		_sphere(b, "Herbs", 0.3, p + Vector3(0.0, 0.4, 0), materials["flower_yellow"])
		_sphere(b, "Herbs", 0.3, p + Vector3(0.4, 0.4, 0), materials["flower_blue"])

	# Garden perimeter fence with open gate in center
	_fence_line(b, Vector3(-4.8, 0, 4.8), Vector3(-1.4, 0, 4.8))
	_fence_line(b, Vector3(1.4, 0, 4.8), Vector3(4.8, 0, 4.8))

# ===== LANDMARK 4: MAYOR'S RESIDENCE (TOWN HALL) =====
# Positioned East of City Bazaar (matching Mayor's Residence in Pictures 1 & 2)
func _build_town_hall(root: Node3D) -> void:
	var b := Node3D.new(); b.name = "TownHall"
	b.position = Vector3(25, 0.8, 2); b.rotation_degrees.y = -90.0
	root.add_child(b)

	# 1. Grand stone masonry base with quoins
	_box(b, "StoneBase", Vector3(15.0, 3.6, 11.0), Vector3(0, 1.8, 0), Vector3.ZERO, materials["stone_wall"], true)
	_stone_quoins(b, 15.0, 3.6, 11.0)

	# 2. Upper timber-framed manor section with overhang
	_box(b, "GirthBeam", Vector3(15.6, 0.30, 11.6), Vector3(0, 3.6, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "UpperSection", Vector3(15.4, 4.2, 11.4), Vector3(0, 5.7, 0.2), Vector3.ZERO, materials["plaster_cream"], true)

	# Symmetrical decorative timber framing on facade
	_box(b, "FBeamBot", Vector3(15.2, 0.22, 0.22), Vector3(0, 3.6, 5.75), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "FBeamMid", Vector3(15.2, 0.22, 0.22), Vector3(0, 6.0, 5.85), Vector3.ZERO, materials["timber_dark"], false)
	for sx in [-6.2, -3.8, -1.2, 1.2, 3.8, 6.2]:
		_box(b, "FStud", Vector3(0.18, 4.2, 0.18), Vector3(sx, 5.7, 5.85), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "Diamond1", Vector3(0.14, 3.0, 0.14), Vector3(-1.2, 5.7, 5.86), Vector3(0, 0, 38), materials["timber_dark"], false)
	_box(b, "Diamond2", Vector3(0.14, 3.0, 0.14), Vector3(1.2, 5.7, 5.86), Vector3(0, 0, -38), materials["timber_dark"], false)

	# 3. Terracotta Roofs & Spire
	_terracotta_roof(b, "MainRoof", Vector3(13.5, 5.0, 17.0), Vector3(0, 10.3, 0), Vector3(0, 90, 0), true)
	_dormer_window(b, Vector3(-4.0, 9.8, 5.0), Vector3(-12, 0, 0))
	_dormer_window(b, Vector3(4.0, 9.8, 5.0), Vector3(-12, 0, 0))

	# Towering central clock / bell spire
	_box(b, "Tower", Vector3(3.8, 7.0, 3.8), Vector3(0, 13.0, 0), Vector3.ZERO, materials["stone_wall"], true)
	_prism(b, "SpireRoof", Vector3(4.4, 5.5, 4.4), Vector3(0, 19.0, 0), Vector3.ZERO, materials["roof_terracotta"], true)
	_cyl(b, "ClockFace", 0.75, 0.75, 0.08, Vector3(0, 14.0, 2.0), Vector3(90, 0, 0), materials["sand"], false)

	# Entrance portico with grand stone pillars
	_box(b, "Steps", Vector3(7.5, 0.5, 3.2), Vector3(0, 0.25, 6.8), Vector3.ZERO, materials["stone_path"], true)
	_cyl(b, "PillarL", 0.32, 0.38, 5.2, Vector3(-2.8, 2.85, 7.4), Vector3.ZERO, materials["stone_wall"], true)
	_cyl(b, "PillarR", 0.32, 0.38, 5.2, Vector3(2.8, 2.85, 7.4), Vector3.ZERO, materials["stone_wall"], true)
	_box(b, "Pediment", Vector3(7.0, 1.2, 2.6), Vector3(0, 5.8, 6.8), Vector3.ZERO, materials["stone_wall"], true)
	_box(b, "DoubleDoor", Vector3(2.6, 3.6, 0.18), Vector3(0, 2.0, 5.65), Vector3.ZERO, materials["timber_dark"], false)

	# Windows
	for wx in [-5.0, 5.0]:
		_fachwerk_window(b, Vector3(wx, 2.4, 5.65), Vector3.ZERO, true)
	for wx in [-5.2, 0.0, 5.2]:
		_fachwerk_window(b, Vector3(wx, 6.0, 5.85), Vector3.ZERO, false)

# ===== LANDMARK 5: PHYSICIAN'S CLINIC (EDMUND WREN) =====
# Positioned along North-East road / Path 4 (Services & Clinic)
func _build_physicians_clinic(root: Node3D) -> void:
	var b := Node3D.new(); b.name = "PhysiciansClinic"
	b.position = Vector3(14, 0.9, -18); b.rotation_degrees.y = -35.0
	root.add_child(b)

	# 1. Stone foundation plinth with quoins
	_box(b, "Foundation", Vector3(8.2, 0.6, 7.2), Vector3(0, 0.3, 0), Vector3.ZERO, materials["stone_foundation"], true)
	_stone_quoins(b, 8.2, 2.6, 7.2)

	# Ground floor stone walls
	_box(b, "StoneBase", Vector3(7.6, 2.2, 6.6), Vector3(0, 1.7, 0), Vector3.ZERO, materials["stone_wall"], true)

	# 2. Overhanging upper floor with timber girth beam
	_box(b, "GirthBeam", Vector3(8.8, 0.26, 7.8), Vector3(0, 2.8, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "Walls", Vector3(8.6, 2.6, 7.6), Vector3(0, 4.1, 0), Vector3.ZERO, materials["plaster_cream"], true)

	_box(b, "ClinicDiagL", Vector3(0.12, 2.0, 0.12), Vector3(-3.0, 4.1, 3.84), Vector3(0, 0, 32), materials["timber_dark"], false)
	_box(b, "ClinicDiagR", Vector3(0.12, 2.0, 0.12), Vector3(3.0, 4.1, 3.84), Vector3(0, 0, -32), materials["timber_dark"], false)

	# 3. Terracotta Roof with Dormer and Stone Chimney
	_terracotta_roof(b, "Roof", Vector3(8.0, 3.4, 9.8), Vector3(0, 6.8, 0), Vector3(0, 90, 0), true)
	_dormer_window(b, Vector3(1.8, 6.4, 3.2), Vector3(-12, 0, 0))
	_masonry_chimney(b, Vector3(-2.8, 6.0, -1.8), 3.2)

	# Porch & Door
	_box(b, "Porch", Vector3(5.2, 0.25, 2.6), Vector3(0, 0.12, 4.6), Vector3.ZERO, materials["timber_plank"], true)
	_box(b, "DoorSurround", Vector3(1.3, 2.2, 0.14), Vector3(-1.4, 1.15, 3.65), Vector3.ZERO, materials["stone_foundation"], false)
	_box(b, "Door", Vector3(1.0, 2.05, 0.10), Vector3(-1.4, 1.10, 3.68), Vector3.ZERO, materials["timber_dark"], false)
	_fachwerk_window(b, Vector3(1.6, 1.4, 3.68), Vector3.ZERO, true)
	_fachwerk_window(b, Vector3(0.0, 4.2, 3.84), Vector3.ZERO, false)

	# Outdoor Investigation Evidence Board
	var bp := _box(b, "BoardPost", Vector3(0.18, 2.5, 0.18), Vector3(3.0, 1.25, 4.6), Vector3.ZERO, materials["timber_dark"], true)
	var bd := _box(bp, "Board", Vector3(1.8, 1.2, 0.08), Vector3(0, 0.5, 0), Vector3.ZERO, materials["timber_plank"], true)
	_box(bd, "Note1", Vector3(0.35, 0.45, 0.02), Vector3(-0.4, 0.2, 0.05), Vector3(0, 0, 8), materials["sand"], false)
	_box(bd, "Note2", Vector3(0.3, 0.4, 0.02), Vector3(0.35, -0.1, 0.05), Vector3(0, 0, -5), materials["sand"], false)
	_box(bd, "RedString", Vector3(0.7, 0.03, 0.02), Vector3(0, 0.05, 0.06), Vector3(0, 0, 25), materials["flower_red"], false)
	_lantern_light(b, Vector3(3.0, 2.4, 4.9))

func _build_detective_office(root: Node3D) -> void:
	_build_physicians_clinic(root)

# ===== LANDMARK 6: HOUSE OF HARBOR MASTER (OLD STOREHOUSE) =====
# Positioned near the Western Harbour (matching Picture 2 & 3)
func _build_old_storehouse(root: Node3D) -> void:
	var b := Node3D.new(); b.name = "OldStorehouse"
	b.position = Vector3(-30, 0.6, 20); b.rotation_degrees.y = 45.0
	root.add_child(b)

	# 1. Heavy stone and weathered timber construction
	_box(b, "StoneBase", Vector3(11.5, 2.6, 8.0), Vector3(0, 1.3, 0), Vector3.ZERO, materials["stone_wall"], true)
	_stone_quoins(b, 11.5, 2.6, 8.0)

	_box(b, "GirthBeam", Vector3(12.0, 0.26, 8.5), Vector3(0, 2.6, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(b, "Walls", Vector3(11.8, 2.8, 8.3), Vector3(0, 4.0, 0), Vector3.ZERO, materials["timber_weathered"], true)

	_box(b, "MossL", Vector3(2.0, 1.5, 0.04), Vector3(-4.5, 1.5, 4.05), Vector3.ZERO, materials["timber_mossy"], false)
	_box(b, "MossR", Vector3(1.5, 2.0, 0.04), Vector3(4.2, 2.0, 4.05), Vector3.ZERO, materials["timber_mossy"], false)

	# 2. Terracotta roof with dormer
	_terracotta_roof(b, "Roof", Vector3(9.5, 3.6, 12.8), Vector3(0, 6.8, 0), Vector3(0, 90, 0), true)
	_dormer_window(b, Vector3(2.0, 6.4, 3.6), Vector3(-12, 0, 0))

	# Heavy cargo doors with iron bar
	_box(b, "CargoDoors", Vector3(3.4, 3.2, 0.18), Vector3(0, 1.6, 4.05), Vector3.ZERO, materials["timber_dark"], true)
	_box(b, "IronBar", Vector3(3.6, 0.22, 0.28), Vector3(0, 1.8, 4.15), Vector3.ZERO, materials["iron"], false)

	# Crates & blue-banded barrels
	_crate(b, Vector3(3.6, 0.5, 4.8), 1.0)
	_crate(b, Vector3(4.6, 0.5, 4.6), 1.0)
	_blue_barrel(b, Vector3(-3.5, 0.45, 4.6))
	_blue_barrel(b, Vector3(-4.4, 0.45, 4.8))

# ===== LANDMARK 7: CITY BAZAAR (CENTRAL SQUARE & WELL) =====
# Center of Hollow Creek (matching "City Bazaar" in Picture 2 & 3)
func _build_village_square_and_well(root: Node3D) -> void:
	var s := Node3D.new(); s.name = "CentralSquareAndWell"
	s.position = Vector3(0, 0.7, 0); root.add_child(s)

	# Stone well in the center
	var w := Node3D.new(); w.name = "VillageWell"; s.add_child(w)
	_cyl(w, "WellWall", 1.45, 1.50, 1.0, Vector3(0, 0.5, 0), Vector3.ZERO, materials["stone_wall"], true)
	_cyl(w, "WellWater", 1.15, 1.15, 0.08, Vector3(0, 0.35, 0), Vector3.ZERO, materials["water"], false)
	_box(w, "PostL", Vector3(0.18, 2.6, 0.18), Vector3(-1.2, 1.55, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(w, "PostR", Vector3(0.18, 2.6, 0.18), Vector3(1.2, 1.55, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(w, "Crossbeam", Vector3(2.7, 0.18, 0.18), Vector3(0, 2.7, 0), Vector3.ZERO, materials["timber_dark"], false)
	_prism(w, "WellRoof", Vector3(2.8, 1.2, 2.2), Vector3(0, 3.3, 0), Vector3(0, 90, 0), materials["roof_slate"], true)
	_cyl(w, "Bucket", 0.25, 0.2, 0.35, Vector3(0, 1.2, 0), Vector3.ZERO, materials["timber_plank"], false)

	# Noticeboard
	var nb := Node3D.new(); nb.name = "Noticeboard"; nb.position = Vector3(-4.5, 0, -4.5); nb.rotation_degrees.y = 40.0
	s.add_child(nb)
	_box(nb, "PostL", Vector3(0.16, 2.6, 0.16), Vector3(-1, 1.3, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(nb, "PostR", Vector3(0.16, 2.6, 0.16), Vector3(1, 1.3, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(nb, "Board", Vector3(2.2, 1.4, 0.06), Vector3(0, 1.5, 0), Vector3.ZERO, materials["timber_plank"], true)
	_box(nb, "Roof", Vector3(2.5, 0.12, 0.5), Vector3(0, 2.3, 0), Vector3(15, 0, 0), materials["roof_slate"], false)
	_box(nb, "Notice1", Vector3(0.4, 0.5, 0.02), Vector3(-0.4, 1.5, 0.04), Vector3(0, 0, 3), materials["sand"], false)
	_box(nb, "Notice2", Vector3(0.35, 0.45, 0.02), Vector3(0.4, 1.55, 0.04), Vector3(0, 0, -4), materials["sand"], false)

	# Market Stalls for the City Bazaar
	_market_stall(s, Vector3(6.5, 0, -4.5), -45.0, "ProduceStall")
	_market_stall(s, Vector3(-5.5, 0, 5.0), 135.0, "FishStall")
	_market_stall(s, Vector3(5.5, 0, 5.5), -135.0, "PotteryStall")

	# Benches around the square
	_bench(s, Vector3(-7.5, 0, 0.0), 90.0)
	_bench(s, Vector3(7.5, 0, 0.0), -90.0)
	_bench(s, Vector3(0.0, 0, -7.5), 0.0)

# ===== LANDMARK 8: FISHING HARBOUR & DOCK =====
# Positioned on Western / South-Western Coastline (matching Pictures 2 & 3)
func _build_fishing_harbour_and_dock(root: Node3D) -> void:
	var d := Node3D.new(); d.name = "FishingHarbourAndDock"
	d.position = Vector3(-42, 0.1, 14); b_look_at_ocean(d)
	root.add_child(d)

	# Main pier extending into the western sea
	_box(d, "PierDeck", Vector3(4.8, 0.35, 16.0), Vector3(0, 0, 8.0), Vector3.ZERO, materials["timber_plank"], true)
	_box(d, "PierT", Vector3(12.0, 0.35, 4.5), Vector3(0, 0, 16.0), Vector3.ZERO, materials["timber_plank"], true)

	# Heavy pilings
	for p in [Vector3(-2.2, -1.2, 2.0), Vector3(2.2, -1.2, 2.0), Vector3(-2.2, -1.2, 7.0), Vector3(2.2, -1.2, 7.0),
			  Vector3(-2.2, -1.2, 12.0), Vector3(2.2, -1.2, 12.0), Vector3(-5.8, -1.2, 16.0), Vector3(5.8, -1.2, 16.0)]:
		_cyl(d, "Piling", 0.24, 0.26, 3.0, p, Vector3.ZERO, materials["timber_weathered"], true)

	# Mooring bollards
	for bp in [Vector3(-2.2, 0.3, 4.0), Vector3(2.2, 0.3, 9.0), Vector3(-5.5, 0.3, 16.0), Vector3(5.5, 0.3, 16.0)]:
		_cyl(d, "Bollard", 0.14, 0.16, 0.5, bp, Vector3.ZERO, materials["timber_dark"], false)

	# Rowboats moored at the dock
	_rowboat(d, Vector3(-4.8, -0.28, 8.0), 12.0)
	_rowboat(d, Vector3(5.0, -0.28, 12.0), -15.0)

	# Fish rack, barrels, and dock lantern
	_box(d, "FishRack", Vector3(2.6, 1.5, 0.6), Vector3(-1.2, 0.8, 15.5), Vector3.ZERO, materials["timber_weathered"], true)
	_blue_barrel(d, Vector3(1.6, 0.45, 5.0))
	_blue_barrel(d, Vector3(1.6, 0.45, 6.2))
	_crate(d, Vector3(1.6, 0.4, 7.6), 0.8)
	_lantern_light(d, Vector3(-2.0, 0.0, 1.5))

func b_look_at_ocean(node: Node3D) -> void:
	# Rotate pier towards ocean on the west
	node.rotation_degrees.y = -90.0

# ===== LANDMARK 9: MOUNTAIN ENTRANCE GATE =====
# Positioned at Pass Entry (matching Pictures 1 & 2)
func _build_mountain_entrance_gate(root: Node3D) -> void:
	var g := Node3D.new(); g.name = "MountainEntranceGate"
	g.position = Vector3(0, 1.85, -34); root.add_child(g)

	_cyl(g, "PostL", 0.38, 0.44, 5.8, Vector3(-3.4, 2.9, 0), Vector3.ZERO, materials["timber_dark"], true)
	_cyl(g, "PostR", 0.38, 0.44, 5.8, Vector3(3.4, 2.9, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(g, "ArchBeam", Vector3(8.2, 0.55, 0.55), Vector3(0, 5.4, 0), Vector3.ZERO, materials["timber_dark"], true)

	var sign := _box(g, "Sign", Vector3(4.2, 1.1, 0.12), Vector3(0, 4.2, 0), Vector3.ZERO, materials["timber_plank"], false)
	_box(sign, "Text", Vector3(3.8, 0.48, 0.02), Vector3(0, 0, 0.07), Vector3.ZERO, materials["sand"], false)

	# Heavy iron gate torches
	_box(g, "TorchL", Vector3(0.12, 0.6, 0.12), Vector3(-3.2, 3.6, 0.4), Vector3.ZERO, materials["iron"], false)
	_lantern_light(g, Vector3(-3.2, 3.9, 0.5))
	_box(g, "TorchR", Vector3(0.12, 0.6, 0.12), Vector3(3.2, 3.6, 0.4), Vector3.ZERO, materials["iron"], false)
	_lantern_light(g, Vector3(3.2, 3.9, 0.5))

	# Town Guard Sentry Watchpost (for Guard Tomas at entrance to Hollow Creek)
	var sp := Node3D.new(); sp.name = "GuardWatchpost"
	sp.position = Vector3(4.2, 0, 1.8)
	g.add_child(sp)

	# Timber sentry shelter
	_box(sp, "SentryDeck", Vector3(2.6, 0.20, 2.6), Vector3(0, 0.10, 0), Vector3.ZERO, materials["timber_plank"], true)
	_box(sp, "SentryBack", Vector3(2.6, 2.8, 0.14), Vector3(0, 1.5, -1.25), Vector3.ZERO, materials["timber_dark"], true)
	_box(sp, "SentrySide", Vector3(0.14, 2.8, 2.4), Vector3(1.25, 1.5, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(sp, "SentryRoof", Vector3(2.8, 0.15, 2.8), Vector3(0, 2.9, 0), Vector3(8, 0, 0), materials["roof_terracotta"], true)

	# Guard weapon rack with halberds
	var wr := _box(sp, "WeaponRack", Vector3(1.4, 1.2, 0.35), Vector3(0, 0.6, -1.0), Vector3.ZERO, materials["timber_dark"], true)
	_cyl(wr, "Spear1", 0.04, 0.04, 2.2, Vector3(-0.4, 0.5, 0), Vector3(0, 0, 8), materials["iron"], false)
	_cyl(wr, "Spear2", 0.04, 0.04, 2.2, Vector3(0.4, 0.5, 0), Vector3(0, 0, -8), materials["iron"], false)

	# Guard warning bell
	_cyl(sp, "WarningBell", 0.22, 0.28, 0.45, Vector3(-1.0, 2.4, 0), Vector3.ZERO, materials["iron"], false)

	# Roadside inspection barrier beam
	_box(sp, "Barrier", Vector3(2.8, 0.14, 0.14), Vector3(-1.8, 1.0, 0), Vector3.ZERO, materials["timber_weathered"], false)

# ===== LANDMARK 10: SECONDARY COTTAGES =====
# Innkeeper's House, Lady X's House, and Cop Station (matching Reference Image & Pictures 1-3)
func _build_secondary_cottages(root: Node3D) -> void:
	# Innkeeper's House (North curve):
	_build_fachwerk_house(root, "WeaversCottage", Vector3(-12, 1.1, -22), 30.0,
		Vector3(7.5, 4.8, 5.5), true, true, true)
	# Cop Station (Guard Post in South-West):
	_build_fachwerk_house(root, "FishermansCottage", Vector3(-14, 0.7, 18), -35.0,
		Vector3(6.8, 4.6, 5.2), true, false, true)
	# Lady X's House (Small cottage on the western curve):
	_build_fachwerk_house(root, "MillersShed", Vector3(-28, 0.75, -14), 70.0,
		Vector3(6.2, 4.4, 4.8), true, true, true)

# ---------------------------------------------------------------------------
# 6. VEGETATION
# ---------------------------------------------------------------------------
func _build_vegetation(root: Node3D) -> void:
	var pines := [
		Vector3(-5.5, 2.5, -45), Vector3(5.8, 2.8, -43),
		Vector3(-6.2, 2.0, -36), Vector3(6.5, 2.2, -37),
		Vector3(-8.0, 1.5, -28), Vector3(8.5, 1.5, -27),
		Vector3(-36, 0.8, -18),  Vector3(-38, 0.7, -8),
		Vector3(-20, 0.8, -20),  Vector3(-34, 0.7, 4),
		Vector3(18, 0.9, -24),   Vector3(32, 0.9, -18),
		Vector3(36, 0.8, -5),    Vector3(38, 0.8, 12),
		Vector3(-22, 0.6, 26),   Vector3(-10, 0.5, 26),
		Vector3(12, 0.5, 26),    Vector3(22, 0.6, 28),
	]
	for p in pines:
		_pine_tree(root, p, randf_range(0.9, 1.3))

	var oaks := [
		Vector3(-10, 0.72, 8),   Vector3(10, 0.72, 8),
		Vector3(-18, 0.72, -8),  Vector3(18, 0.75, 12),
		Vector3(-24, 0.72, 8),   Vector3(16, 0.85, -8),
	]
	for o in oaks:
		_oak_tree(root, o, randf_range(0.95, 1.25))

	var bushes := [
		Vector3(-3, 0.72, 4.5),  Vector3(3.2, 0.72, 4.8),
		Vector3(-5, 0.72, -2.0), Vector3(5.0, 0.72, -2.0),
		Vector3(-14, 0.65, 12),  Vector3(-24, 0.65, 14),
		Vector3(10, 0.72, -10),  Vector3(20, 0.75, -6),
	]
	for bs in bushes:
		_sphere(root, "Bush", 0.75, bs, materials["bush"])
		# Small stylized fantasy mushrooms
		_mushroom(root, bs + Vector3(0.6, -0.3, 0.4))

# ---------------------------------------------------------------------------
# 7. VILLAGE PROPS (Gallows street lamps & blue-hooped barrels)
# ---------------------------------------------------------------------------
func _build_props(root: Node3D) -> void:
	var lamps := [
		Vector3(3.6, 0.60, -10.0),   # City Bazaar North entrance roadside
		Vector3(-3.5, 0.60, 9.5),    # City Bazaar South exit roadside
		Vector3(-11.5, 0.60, 4.5),   # City Bazaar West perimeter
		Vector3(10.5, 0.60, -4.5),   # City Bazaar East perimeter
		Vector3(3.6, 1.80, -31.0),   # Gate entrance sentry roadside
		Vector3(-3.5, 1.15, -22.5),  # Slope road grass verge
		Vector3(10.5, 0.88, -14.2),  # Clinic road grass verge
		Vector3(20.5, 0.80, -7.5),   # Iron works forge verge
		Vector3(18.5, 0.78, 5.2),    # Mayor's manor avenue lawn
		Vector3(-9.2, 1.15, -25.5),  # Innkeeper road hillside
		Vector3(-21.2, 0.75, -16.0), # Lady X road inner verge
		Vector3(-18.0, 0.60, -5.5),  # The Inn approach terrace
		Vector3(-14.2, 0.46, 12.8),  # Harbour road bank
		Vector3(-29.5, 0.28, 9.8),   # Harbour road descent rocky beach
		Vector3(-44.8, 0.12, 14.0),  # Harbour dock pier railing
		Vector3(6.0, 0.60, 17.5),    # Doctor cottage garden roadside
		Vector3(-16.0, 0.60, 16.5),  # Cop station roadside
		Vector3(-26.5, 0.48, 23.5),  # Harbor master house verge
	]
	for lp in lamps:
		_gallows_lamp(root, lp)

	# Transport Carts
	_cart(root, Vector3(5.5, 0.60, -8), 25.0)
	_cart(root, Vector3(-12, 0.60, 2), -45.0)
	_cart(root, Vector3(22, 0.80, 10), 75.0)

# ---------------------------------------------------------------------------
# 8. BOUNDARY COLLIDERS
# ---------------------------------------------------------------------------
func _build_boundary_colliders(root: Node3D) -> void:
	_boundary(root, Vector3(20, 12, 2.0), Vector3(0, 6, -53))
	_boundary(root, Vector3(2.5, 10, 105), Vector3(-51, 3, 5))
	_boundary(root, Vector3(2.5, 10, 105), Vector3(51, 3, 5))
	_boundary(root, Vector3(50, 10, 2.5), Vector3(-25, 3, 48))
	_boundary(root, Vector3(50, 10, 2.5), Vector3(32, 3, 48))
	_boundary(root, Vector3(22, 10, 2.5), Vector3(5, 3, 53))

func _boundary(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new(); sb.name = "Boundary"; sb.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new(); shape.size = size; col.shape = shape
	sb.add_child(col); parent.add_child(sb)

# ===========================================================================
# STYLIZED MOUNTAIN BUILDER (Brown, White, Grey-ish)
# ===========================================================================
func _grand_mountain(parent: Node, m_name: String, pos: Vector3, sz: Vector3, rot_y: float, has_snow: bool) -> void:
	var mtn := StaticBody3D.new()
	mtn.name = m_name
	mtn.position = pos
	mtn.rotation_degrees.y = rot_y
	parent.add_child(mtn)

	# 1. Base Mountain Mass (brown-grey earthy rock)
	var base_mi := MeshInstance3D.new()
	var base_prism := PrismMesh.new()
	base_prism.size = sz
	base_mi.mesh = base_prism
	base_mi.material_override = materials["rock_mountain_base"]
	mtn.add_child(base_mi)

	# 2. Mid Faceted Granite Crag (weathered granite grey)
	var mid_mi := MeshInstance3D.new()
	var mid_prism := PrismMesh.new()
	mid_prism.size = Vector3(sz.x * 0.78, sz.y * 0.85, sz.z * 0.75)
	mid_mi.mesh = mid_prism
	mid_mi.material_override = materials["rock_mountain_mid"]
	mid_mi.position = Vector3(sz.x * 0.12, -sz.y * 0.05, sz.z * 0.12)
	mid_mi.rotation_degrees.y = 22.0
	mtn.add_child(mid_mi)

	# 3. Upper Jagged Ridge (light stone grey)
	var ridge_mi := MeshInstance3D.new()
	var ridge_prism := PrismMesh.new()
	ridge_prism.size = Vector3(sz.x * 0.50, sz.y * 0.65, sz.z * 0.50)
	ridge_mi.mesh = ridge_prism
	ridge_mi.material_override = materials["rock_mountain_ridge"]
	ridge_mi.position = Vector3(-sz.x * 0.08, sz.y * 0.12, -sz.z * 0.08)
	ridge_mi.rotation_degrees.y = -18.0
	mtn.add_child(ridge_mi)

	# 4. Snowy / Frosted Summit Cap (crisp white-grey snow)
	if has_snow:
		var snow_mi := MeshInstance3D.new()
		var snow_prism := PrismMesh.new()
		snow_prism.size = Vector3(sz.x * 0.35, sz.y * 0.32, sz.z * 0.35)
		snow_mi.mesh = snow_prism
		snow_mi.material_override = materials["rock_mountain_snow"]
		snow_mi.position = Vector3(0, sz.y * 0.34, 0)
		mtn.add_child(snow_mi)

	# Single solid collision shape
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(sz.x * 0.85, sz.y, sz.z * 0.85)
	cs.shape = sh
	mtn.add_child(cs)

# ===========================================================================
# STYLIZED TIMBER-FRAMED & TERRACOTTA ARCHITECTURE HELPERS (from Reference Image)
# ===========================================================================

## 3D staggered stone quoins / corner relief blocks on stone base
func _stone_quoins(parent: Node, w: float, h: float, d: float) -> void:
	var hw := w * 0.5
	var hd := d * 0.5
	var steps := int(h / 0.65)
	for i in range(steps):
		var y := 0.32 + float(i) * 0.62
		var q_len: float = 0.42 if (i % 2 == 0) else 0.28
		for cx in [-hw, hw]:
			for cz in [-hd, hd]:
				var sx: float = cx + (0.10 if cx < 0 else -0.10)
				var sz: float = cz + (0.10 if cz < 0 else -0.10)
				_box(parent, "Quoin", Vector3(q_len, 0.26, 0.28), Vector3(sx, y, sz), Vector3.ZERO, materials["stone_foundation"], false)

## Authentic medieval steep roof with stepped tile courses and prominent ridge cap
func _terracotta_roof(parent: Node, r_name: String, size: Vector3, pos: Vector3, rot: Vector3, col: bool = true) -> MeshInstance3D:
	var roof_node := MeshInstance3D.new()
	roof_node.name = r_name
	var rm := MedievalRoofBuilder.build_steep_medieval_roof_mesh(size.x, size.y, size.z)
	roof_node.mesh = rm
	roof_node.material_override = materials["roof_terracotta"]
	roof_node.position = pos
	roof_node.rotation_degrees = rot
	parent.add_child(roof_node)

	if col:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(size.x, size.y * 0.75, size.z)
		cs.shape = sh
		sb.add_child(cs)
		roof_node.add_child(sb)

	return roof_node

## Multi-pane window with cross mullions (2x2 panes) and dark timber frame
func _fachwerk_window(parent: Node, pos: Vector3, rot: Vector3 = Vector3.ZERO, with_stone_surround: bool = false) -> MeshInstance3D:
	var win_container := Node3D.new()
	win_container.position = pos
	win_container.rotation_degrees = rot
	parent.add_child(win_container)

	if with_stone_surround:
		_box(win_container, "Sill", Vector3(1.25, 0.14, 0.18), Vector3(0, -0.65, 0), Vector3.ZERO, materials["stone_foundation"], false)
		_box(win_container, "Lintel", Vector3(1.25, 0.14, 0.18), Vector3(0, 0.65, 0), Vector3.ZERO, materials["stone_foundation"], false)

	# Glowing glass panel
	var wm := MeshInstance3D.new()
	wm.name = "WindowGlow"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.92, 1.15, 0.06)
	wm.mesh = bm
	wm.material_override = materials["window_glow"]
	win_container.add_child(wm)
	_window_meshes.append(wm)

	# Dark timber window frame
	_box(win_container, "FrameT", Vector3(1.05, 0.09, 0.10), Vector3(0, 0.55, 0.02), Vector3.ZERO, materials["timber_dark"], false)
	_box(win_container, "FrameB", Vector3(1.05, 0.09, 0.10), Vector3(0, -0.55, 0.02), Vector3.ZERO, materials["timber_dark"], false)
	_box(win_container, "FrameL", Vector3(0.09, 1.15, 0.10), Vector3(-0.48, 0, 0.02), Vector3.ZERO, materials["timber_dark"], false)
	_box(win_container, "FrameR", Vector3(0.09, 1.15, 0.10), Vector3(0.48, 0, 0.02), Vector3.ZERO, materials["timber_dark"], false)

	# 2x2 cross mullions
	_box(win_container, "MullionV", Vector3(0.06, 1.10, 0.08), Vector3(0, 0, 0.02), Vector3.ZERO, materials["timber_dark"], false)
	_box(win_container, "MullionH", Vector3(0.92, 0.06, 0.08), Vector3(0, 0, 0.02), Vector3.ZERO, materials["timber_dark"], false)

	return wm

## Gabled dormer window protruding from the roof slope
func _dormer_window(parent: Node, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var dormer := Node3D.new()
	dormer.name = "RoofDormer"
	dormer.position = pos
	dormer.rotation_degrees = rot
	parent.add_child(dormer)

	_box(dormer, "DWalls", Vector3(1.4, 1.3, 1.4), Vector3(0, 0.65, 0), Vector3.ZERO, materials["plaster_cream"], true)
	_box(dormer, "DPostL", Vector3(0.12, 1.3, 0.12), Vector3(-0.65, 0.65, 0.65), Vector3.ZERO, materials["timber_dark"], false)
	_box(dormer, "DPostR", Vector3(0.12, 1.3, 0.12), Vector3(0.65, 0.65, 0.65), Vector3.ZERO, materials["timber_dark"], false)

	_terracotta_roof(dormer, "DRoof", Vector3(1.65, 0.85, 1.65), Vector3(0, 1.65, 0), Vector3(0, 90, 0), true)

	var dw := _box(dormer, "DWin", Vector3(0.65, 0.65, 0.06), Vector3(0, 0.65, 0.72), Vector3.ZERO, materials["window_glow"], false)
	_window_meshes.append(dw)
	_box(dormer, "DWinMullion", Vector3(0.05, 0.65, 0.08), Vector3(0, 0.65, 0.73), Vector3.ZERO, materials["timber_dark"], false)

	return dormer

## Stone masonry chimney with stone cap
func _masonry_chimney(parent: Node, pos: Vector3, height: float = 3.2) -> Node3D:
	var ch := Node3D.new()
	ch.name = "Chimney"
	ch.position = pos
	parent.add_child(ch)

	_box(ch, "Shaft", Vector3(1.15, height, 1.15), Vector3(0, height * 0.5, 0), Vector3.ZERO, materials["stone_wall"], true)
	_box(ch, "Cap", Vector3(1.40, 0.24, 1.40), Vector3(0, height + 0.10, 0), Vector3.ZERO, materials["stone_foundation"], false)
	_box(ch, "Flue", Vector3(0.70, 0.08, 0.70), Vector3(0, height + 0.22, 0), Vector3.ZERO, materials["stone_foundation"], false)

	return ch

## Cantilevered side bay window with mini terracotta roof
func _side_bay_window(parent: Node, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var bay := Node3D.new()
	bay.name = "SideBay"
	bay.position = pos
	bay.rotation_degrees = rot
	parent.add_child(bay)

	_box(bay, "CorbelL", Vector3(0.14, 0.35, 0.50), Vector3(-0.45, -0.25, 0), Vector3(25, 0, 0), materials["timber_dark"], false)
	_box(bay, "CorbelR", Vector3(0.14, 0.35, 0.50), Vector3(0.45, -0.25, 0), Vector3(25, 0, 0), materials["timber_dark"], false)
	_box(bay, "BayPlaster", Vector3(1.20, 1.35, 0.65), Vector3(0, 0.65, 0.28), Vector3.ZERO, materials["plaster_cream"], true)
	_box(bay, "BayPostL", Vector3(0.12, 1.35, 0.12), Vector3(-0.55, 0.65, 0.56), Vector3.ZERO, materials["timber_dark"], false)
	_box(bay, "BayPostR", Vector3(0.12, 1.35, 0.12), Vector3(0.55, 0.65, 0.56), Vector3.ZERO, materials["timber_dark"], false)
	_terracotta_roof(bay, "BayRoof", Vector3(1.40, 0.55, 0.90), Vector3(0, 1.55, 0.32), Vector3(0, 90, 0), false)

	var bw := _box(bay, "BayWin", Vector3(0.75, 0.85, 0.06), Vector3(0, 0.65, 0.61), Vector3.ZERO, materials["window_glow"], false)
	_window_meshes.append(bw)
	_box(bay, "BayMullionV", Vector3(0.05, 0.85, 0.08), Vector3(0, 0.65, 0.62), Vector3.ZERO, materials["timber_dark"], false)

	return bay

## Complete stylized half-timbered house matching reference image
func _build_fachwerk_house(
	parent: Node3D,
	h_name: String,
	pos: Vector3,
	rot_y: float,
	dims: Vector3,
	has_dormer: bool = true,
	has_bay: bool = true,
	has_chimney: bool = true
) -> Node3D:
	var house := Node3D.new()
	house.name = h_name
	house.position = pos
	house.rotation_degrees.y = rot_y
	parent.add_child(house)

	var h_ground := dims.y * 0.52
	var h_upper := dims.y * 0.48
	var gw := dims.x
	var gd := dims.z

	# 1. GROUND FLOOR (Stone masonry with quoins & heavy corner posts)
	_box(house, "StoneBase", Vector3(gw, h_ground, gd), Vector3(0, h_ground * 0.5, 0), Vector3.ZERO, materials["stone_wall"], true)
	_stone_quoins(house, gw, h_ground, gd)

	for cx in [-gw * 0.5 + 0.10, gw * 0.5 - 0.10]:
		for cz in [-gd * 0.5 + 0.10, gd * 0.5 - 0.10]:
			_box(house, "GPost", Vector3(0.22, h_ground, 0.22), Vector3(cx, h_ground * 0.5, cz), Vector3.ZERO, materials["timber_dark"], false)

	# Arched wooden plank door with stone arch surround
	var hz := gd * 0.5
	_box(house, "DoorSurround", Vector3(1.35, 2.25, 0.16), Vector3(-gw * 0.22, 1.12, hz + 0.04), Vector3.ZERO, materials["stone_foundation"], false)
	_box(house, "Door", Vector3(1.0, 2.05, 0.10), Vector3(-gw * 0.22, 1.05, hz + 0.06), Vector3.ZERO, materials["timber_plank"], false)
	_box(house, "DoorIronHinges", Vector3(0.85, 0.06, 0.03), Vector3(-gw * 0.22, 1.55, hz + 0.12), Vector3.ZERO, materials["iron"], false)
	_box(house, "DoorIronLatch", Vector3(0.12, 0.12, 0.05), Vector3(-gw * 0.22 + 0.35, 1.05, hz + 0.12), Vector3.ZERO, materials["iron"], false)

	# Ground-floor cross-mullion window
	_fachwerk_window(house, Vector3(gw * 0.24, 1.35, hz + 0.05), Vector3.ZERO, true)

	# 2. JETTY / OVERHANG (Upper floor overhangs ground floor by 0.3m on all sides)
	var uw := gw + 0.60
	var ud := gd + 0.60
	var jetty_y := h_ground

	# Thick horizontal girth beam
	_box(house, "GirthBeam", Vector3(uw + 0.15, 0.28, ud + 0.15), Vector3(0, jetty_y + 0.14, 0), Vector3.ZERO, materials["timber_dark"], false)

	# Corner corbel brackets supporting the overhang
	for cx in [-gw * 0.5 + 0.05, gw * 0.5 - 0.05]:
		for cz in [-gd * 0.5 + 0.05, gd * 0.5 - 0.05]:
			var dir_x: float = 1.0 if cx > 0 else -1.0
			var dir_z: float = 1.0 if cz > 0 else -1.0
			_box(house, "Corbel", Vector3(0.18, 0.38, 0.38), Vector3(cx + dir_x * 0.12, jetty_y - 0.12, cz + dir_z * 0.12), Vector3(25 * dir_z, 0, -25 * dir_x), materials["timber_dark"], false)

	# 3. UPPER FLOOR (Cream plaster with half-timber framing)
	var upper_base_y := jetty_y + 0.28
	_box(house, "UpperPlaster", Vector3(uw, h_upper, ud), Vector3(0, upper_base_y + h_upper * 0.5, 0), Vector3.ZERO, materials["plaster_cream"], true)

	var uhw := uw * 0.5
	var uhd := ud * 0.5
	for cx in [-uhw + 0.08, uhw - 0.08]:
		for cz in [-uhd + 0.08, uhd - 0.08]:
			_box(house, "UPost", Vector3(0.18, h_upper, 0.18), Vector3(cx, upper_base_y + h_upper * 0.5, cz), Vector3.ZERO, materials["timber_dark"], false)

	_box(house, "MidRail", Vector3(uw + 0.06, 0.16, ud + 0.06), Vector3(0, upper_base_y + h_upper * 0.5, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(house, "TopPlate", Vector3(uw + 0.08, 0.18, ud + 0.08), Vector3(0, upper_base_y + h_upper + 0.09, 0), Vector3.ZERO, materials["timber_dark"], false)

	var brace_y := upper_base_y + h_upper * 0.5
	_box(house, "DiagBraceFL", Vector3(0.12, 1.8, 0.12), Vector3(-uhw + 0.65, brace_y, uhd + 0.04), Vector3(0, 0, 32), materials["timber_dark"], false)
	_box(house, "DiagBraceFR", Vector3(0.12, 1.8, 0.12), Vector3(uhw - 0.65, brace_y, uhd + 0.04), Vector3(0, 0, -32), materials["timber_dark"], false)

	for sx in [-uhw * 0.45, uhw * 0.45]:
		_box(house, "StudV", Vector3(0.12, h_upper, 0.12), Vector3(sx, brace_y, uhd + 0.04), Vector3.ZERO, materials["timber_dark"], false)

	_fachwerk_window(house, Vector3(-uhw * 0.25, upper_base_y + h_upper * 0.5, uhd + 0.04), Vector3.ZERO, false)
	_fachwerk_window(house, Vector3(uhw * 0.25, upper_base_y + h_upper * 0.5, uhd + 0.04), Vector3.ZERO, false)

	if has_bay:
		_side_bay_window(house, Vector3(-uhw - 0.05, upper_base_y + h_upper * 0.45, 0), Vector3(0, 90, 0))

	# 4. GABLE ROOF & ATTIC
	var roof_base_y := upper_base_y + h_upper + 0.18
	var roof_height := 3.4
	_terracotta_roof(house, "Roof", Vector3(uw + 0.9, roof_height, ud + 0.9), Vector3(0, roof_base_y + roof_height * 0.5, 0), Vector3(0, 90, 0), true)

	var gaw := _box(house, "AtticWinF", Vector3(0.55, 0.65, 0.05), Vector3(0, roof_base_y + roof_height * 0.35, uhd + 0.04), Vector3.ZERO, materials["window_glow"], false)
	_window_meshes.append(gaw)
	_box(house, "AtticWinTrim", Vector3(0.65, 0.75, 0.08), Vector3(0, roof_base_y + roof_height * 0.35, uhd + 0.05), Vector3.ZERO, materials["timber_dark"], false)

	if has_dormer:
		_dormer_window(house, Vector3(uhw * 0.25, roof_base_y + roof_height * 0.35, uhd * 0.45), Vector3(-12, 0, 0))

	if has_chimney:
		_masonry_chimney(house, Vector3(-uhw * 0.35, roof_base_y + roof_height * 0.6, -uhd * 0.2), 3.2)

	return house

# ===========================================================================
# STYLIZED FANTASY ARCHITECTURE HELPERS (from Picture 4)
# ===========================================================================

## Fantasy steep gabled roof with flared eaves and decorative ridge apex finials
func _fantasy_roof(parent: Node, r_name: String, size: Vector3, pos: Vector3, rot: Vector3, roof_mat: Material, has_finials: bool) -> MeshInstance3D:
	var roof_node := MeshInstance3D.new()
	roof_node.name = r_name
	var pm := PrismMesh.new()
	pm.size = size
	roof_node.mesh = pm
	roof_node.material_override = roof_mat
	roof_node.position = pos
	roof_node.rotation_degrees = rot
	parent.add_child(roof_node)

	# Solid collision
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(size.x, size.y * 0.75, size.z)
	cs.shape = sh
	sb.add_child(cs)
	roof_node.add_child(sb)

	# Decorative curved timber ridge finials at roof peaks (iconic Picture 4 feature)
	if has_finials:
		var half_len := size.z * 0.48
		var finial_height := size.y * 0.50
		for fz in [-half_len, half_len]:
			var fin := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.24, 0.75, 0.24)
			fin.mesh = bm
			fin.material_override = materials["timber_dark"]
			fin.position = Vector3(0, finial_height + 0.35, fz)
			fin.rotation_degrees.x = -15.0 if fz > 0 else 15.0
			roof_node.add_child(fin)

	return roof_node

## Pointed arched gothic window with vertical muntin and glowing amber core
func _arched_window(parent: Node, pos: Vector3, rot: Vector3) -> MeshInstance3D:
	var win_container := Node3D.new()
	win_container.position = pos
	win_container.rotation_degrees = rot
	parent.add_child(win_container)

	# Glowing glass panel
	var wm := MeshInstance3D.new()
	wm.name = "WindowGlow"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.95, 1.25, 0.08)
	wm.mesh = bm
	wm.material_override = materials["window_glow"]
	win_container.add_child(wm)
	_window_meshes.append(wm)

	# Pointed arch top pediment
	var arch := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(1.05, 0.50, 0.12)
	arch.mesh = pm
	arch.material_override = materials["timber_dark"]
	arch.position = Vector3(0, 0.85, 0)
	win_container.add_child(arch)

	# Center vertical timber mullion
	var mul := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.08, 1.25, 0.10)
	mul.mesh = mm
	mul.material_override = materials["timber_dark"]
	win_container.add_child(mul)

	# Shutters on sides
	var shut_l := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.06, 1.25, 0.50)
	shut_l.mesh = sm
	shut_l.material_override = materials["timber_dark"]
	shut_l.position = Vector3(-0.55, 0, 0.02)
	win_container.add_child(shut_l)

	var shut_r := MeshInstance3D.new()
	shut_r.mesh = sm
	shut_r.material_override = materials["timber_dark"]
	shut_r.position = Vector3(0.55, 0, 0.02)
	win_container.add_child(shut_r)

	return wm

## Gallows-style timber street lamp with cantilever arm and hanging lantern
func _gallows_lamp(parent: Node, pos: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.name = "StreetLamp"
	lamp.position = pos
	parent.add_child(lamp)

	# Stone base
	_box(lamp, "Base", Vector3(0.45, 0.35, 0.45), Vector3(0, 0.18, 0), Vector3.ZERO, materials["stone_foundation"], true)
	# Heavy square timber post
	_box(lamp, "Post", Vector3(0.20, 3.6, 0.20), Vector3(0, 1.8, 0), Vector3.ZERO, materials["timber_dark"], true)
	# Cantilever arm
	_box(lamp, "Arm", Vector3(1.1, 0.14, 0.14), Vector3(0.55, 3.45, 0), Vector3.ZERO, materials["timber_dark"], false)
	# 45-degree brace
	_box(lamp, "Brace", Vector3(0.12, 0.85, 0.12), Vector3(0.28, 3.05, 0), Vector3(0, 0, 45), materials["timber_dark"], false)
	# Iron hanging bracket
	_cyl(lamp, "Chain", 0.03, 0.03, 0.35, Vector3(0.95, 3.25, 0), Vector3.ZERO, materials["iron"], false)

	# Lantern housing
	var lm := _box(lamp, "Lantern", Vector3(0.35, 0.48, 0.35), Vector3(0.95, 2.9, 0), Vector3.ZERO, materials["lantern_glow"], false)
	_lantern_meshes.append(lm)
	var ll := _point_light(lamp, Vector3(0.95, 2.9, 0), Color(1.0, 0.80, 0.36), 2.2, 8.5)
	_lantern_lights.append(ll)

## Barrel with blue-painted iron hoops (from Picture 4)
func _blue_barrel(parent: Node, pos: Vector3) -> void:
	var b_node := Node3D.new()
	b_node.name = "Barrel"
	b_node.position = pos
	parent.add_child(b_node)

	# Wooden barrel core
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.34
	cyl.bottom_radius = 0.36
	cyl.height = 0.90
	mi.mesh = cyl
	mi.material_override = materials["timber_dark"]
	b_node.add_child(mi)

	# Blue-grey iron hoops
	for hy in [-0.28, 0.28]:
		var hoop := MeshInstance3D.new()
		var hc := CylinderMesh.new()
		hc.top_radius = 0.365
		hc.bottom_radius = 0.365
		hc.height = 0.08
		hoop.mesh = hc
		hoop.material_override = materials["iron_blue"]
		hoop.position = Vector3(0, hy, 0)
		b_node.add_child(hoop)

	# Solid collision
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.38
	sh.height = 0.90
	cs.shape = sh
	sb.add_child(cs)
	b_node.add_child(sb)

## Bazaar market stall with striped awning canopy and produce crate
func _market_stall(parent: Node, pos: Vector3, rot_y: float, s_name: String) -> void:
	var s := Node3D.new()
	s.name = s_name
	s.position = pos
	s.rotation_degrees.y = rot_y
	parent.add_child(s)

	# Wooden trestle counter
	_box(s, "Counter", Vector3(2.6, 0.85, 1.2), Vector3(0, 0.42, 0), Vector3.ZERO, materials["timber_plank"], true)
	# Canopy timber corner posts
	for px in [-1.2, 1.2]:
		for pz in [-0.55, 0.55]:
			_box(s, "Post", Vector3(0.12, 2.6, 0.12), Vector3(px, 1.3, pz), Vector3.ZERO, materials["timber_dark"], false)
	# Striped cloth canopy
	_box(s, "Canopy", Vector3(2.8, 0.10, 1.5), Vector3(0, 2.5, 0), Vector3(8, 0, 0), materials["awning_red"], false)
	# Produce crates
	_box(s, "Crate1", Vector3(0.65, 0.35, 0.5), Vector3(-0.7, 0.95, 0.1), Vector3.ZERO, materials["timber_plank"], false)
	_box(s, "Crate2", Vector3(0.65, 0.35, 0.5), Vector3(0.7, 0.95, 0.1), Vector3.ZERO, materials["timber_plank"], false)

## Small fantasy mushrooms
func _mushroom(parent: Node, pos: Vector3) -> void:
	var m := Node3D.new()
	m.position = pos
	parent.add_child(m)
	_cyl(m, "Stem", 0.04, 0.05, 0.22, Vector3(0, 0.11, 0), Vector3.ZERO, materials["sand"], false)
	_sphere(m, "Cap", 0.14, Vector3(0, 0.22, 0), materials["mushroom_red"])

# ===========================================================================
# PRIMITIVE HELPERS
# ===========================================================================
func _box(parent: Node, n: String, size: Vector3, pos: Vector3, rot: Vector3, mat: Material, col: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = n
	var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	if mat: mi.material_override = mat
	mi.position = pos; mi.rotation_degrees = rot
	parent.add_child(mi)
	if col:
		var sb := StaticBody3D.new(); sb.name = n + "Col"
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh
		sb.add_child(cs); mi.add_child(sb)
	return mi

func _cyl(parent: Node, n: String, rt: float, rb: float, h: float, pos: Vector3, rot: Vector3, mat: Material, col: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = n
	var cm := CylinderMesh.new(); cm.top_radius = rt; cm.bottom_radius = rb; cm.height = h; cm.radial_segments = 12
	mi.mesh = cm
	if mat: mi.material_override = mat
	mi.position = pos; mi.rotation_degrees = rot
	parent.add_child(mi)
	if col:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new(); sh.radius = maxf(rt, rb); sh.height = h
		cs.shape = sh; sb.add_child(cs); mi.add_child(sb)
	return mi

func _prism(parent: Node, n: String, size: Vector3, pos: Vector3, rot: Vector3, mat: Material, col: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = n
	var pm := PrismMesh.new(); pm.size = size; mi.mesh = pm
	if mat: mi.material_override = mat
	mi.position = pos; mi.rotation_degrees = rot
	parent.add_child(mi)
	if col:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new(); sh.size = Vector3(size.x, size.y * 0.75, size.z)
		cs.shape = sh; sb.add_child(cs); mi.add_child(sb)
	return mi

func _sphere(parent: Node, n: String, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = n
	var sm := SphereMesh.new(); sm.radius = r; sm.height = r * 2.0; sm.radial_segments = 8; sm.rings = 6
	mi.mesh = sm
	if mat: mi.material_override = mat
	mi.position = pos; parent.add_child(mi)
	return mi

func _add_plane(parent: Node, size: Vector2, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = size; mi.mesh = pm
	mi.material_override = mat; mi.position = pos; parent.add_child(mi)

func _rock(parent: Node, pos: Vector3, sz: Vector3, rot_y: float, mat: Material) -> void:
	var sb := StaticBody3D.new(); sb.name = "Rock"; sb.position = pos; sb.rotation_degrees.y = rot_y
	parent.add_child(sb)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0; sm.radial_segments = 7; sm.rings = 5
	mi.mesh = sm; mi.material_override = mat; mi.scale = sz; sb.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new(); sh.size = sz; cs.shape = sh; sb.add_child(cs)

func _point_light(parent: Node, pos: Vector3, col: Color, energy: float, r: float) -> OmniLight3D:
	var pl := OmniLight3D.new(); pl.position = pos; pl.light_color = col
	pl.light_energy = energy; pl.omni_range = r; pl.shadow_enabled = false
	parent.add_child(pl)
	return pl

func _lantern_light(parent: Node, pos: Vector3) -> void:
	var lamp := Node3D.new(); lamp.name = "StreetLamp"; lamp.position = pos
	parent.add_child(lamp)
	_cyl(lamp, "Post", 0.10, 0.14, 3.5, Vector3(0, 1.75, 0), Vector3.ZERO, materials["timber_dark"], true)
	_box(lamp, "Arm", Vector3(0.8, 0.08, 0.08), Vector3(0.3, 3.45, 0), Vector3.ZERO, materials["iron"], false)
	var lm := _box(lamp, "Lantern", Vector3(0.32, 0.42, 0.32), Vector3(0.6, 3.25, 0), Vector3.ZERO, materials["lantern_glow"], false)
	_lantern_meshes.append(lm)
	var ll := _point_light(lamp, Vector3(0.6, 3.25, 0), Color(1.0, 0.78, 0.32), 2.2, 8.0)
	_lantern_lights.append(ll)

func _bench(parent: Node, pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new(); n.name = "Bench"; n.position = pos; n.rotation_degrees.y = rot_y
	parent.add_child(n)
	_box(n, "Seat", Vector3(2.0, 0.1, 0.5), Vector3(0, 0.45, 0), Vector3.ZERO, materials["timber_plank"], true)
	_box(n, "Back", Vector3(2.0, 0.4, 0.08), Vector3(0, 0.75, -0.22), Vector3.ZERO, materials["timber_plank"], false)
	_box(n, "LegL", Vector3(0.12, 0.45, 0.45), Vector3(-0.85, 0.22, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(n, "LegR", Vector3(0.12, 0.45, 0.45), Vector3(0.85, 0.22, 0), Vector3.ZERO, materials["timber_dark"], false)

func _picnic_table(parent: Node, pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new(); n.name = "PicnicTable"; n.position = pos; n.rotation_degrees.y = rot_y
	parent.add_child(n)
	_box(n, "Top", Vector3(2.2, 0.12, 1.1), Vector3(0, 0.8, 0), Vector3.ZERO, materials["timber_plank"], true)
	_box(n, "B1", Vector3(2.2, 0.08, 0.35), Vector3(0, 0.45, 0.85), Vector3.ZERO, materials["timber_plank"], true)
	_box(n, "B2", Vector3(2.2, 0.08, 0.35), Vector3(0, 0.45, -0.85), Vector3.ZERO, materials["timber_plank"], true)
	_box(n, "LL", Vector3(0.12, 0.8, 1.8), Vector3(-0.85, 0.4, 0), Vector3.ZERO, materials["timber_dark"], false)
	_box(n, "LR", Vector3(0.12, 0.8, 1.8), Vector3(0.85, 0.4, 0), Vector3.ZERO, materials["timber_dark"], false)

func _rowboat(parent: Node, pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new(); n.name = "Rowboat"; n.position = pos; n.rotation_degrees.y = rot_y
	parent.add_child(n)
	_prism(n, "Bow", Vector3(1.4, 0.65, 1.6), Vector3(0, 0.2, 1.4), Vector3(180, 0, 0), materials["timber_weathered"], true)
	_box(n, "Mid", Vector3(1.4, 0.65, 2.2), Vector3(0, 0.2, -0.3), Vector3.ZERO, materials["timber_weathered"], true)
	_box(n, "OarL", Vector3(0.06, 0.06, 2.0), Vector3(-0.7, 0.45, -0.1), Vector3(15, 0, 20), materials["timber_dark"], false)
	_box(n, "OarR", Vector3(0.06, 0.06, 2.0), Vector3(0.7, 0.45, -0.1), Vector3(15, 0, -20), materials["timber_dark"], false)

func _cart(parent: Node, pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new(); n.name = "Cart"; n.position = pos; n.rotation_degrees.y = rot_y
	parent.add_child(n)
	_box(n, "Bed", Vector3(1.4, 0.5, 2.4), Vector3(0, 0.7, 0), Vector3.ZERO, materials["timber_plank"], true)
	_cyl(n, "WL", 0.45, 0.45, 0.12, Vector3(-0.8, 0.45, 0), Vector3(0, 0, 90), materials["timber_dark"], true)
	_cyl(n, "WR", 0.45, 0.45, 0.12, Vector3(0.8, 0.45, 0), Vector3(0, 0, 90), materials["timber_dark"], true)
	_box(n, "ShL", Vector3(0.08, 0.08, 1.8), Vector3(-0.4, 0.5, 1.8), Vector3(-12, 0, 0), materials["timber_dark"], false)
	_box(n, "ShR", Vector3(0.08, 0.08, 1.8), Vector3(0.4, 0.5, 1.8), Vector3(-12, 0, 0), materials["timber_dark"], false)
	_box(n, "Hay", Vector3(1.1, 0.6, 1.8), Vector3(0, 0.95, 0), Vector3.ZERO, materials["sand"], false)

func _crate(parent: Node, pos: Vector3, s: float) -> void:
	_box(parent, "Crate", Vector3(s, s, s), pos, Vector3.ZERO, materials["timber_plank"], true)

func _pine_tree(parent: Node, pos: Vector3, sc: float) -> void:
	var t := Node3D.new(); t.name = "Pine"; t.position = pos; t.scale = Vector3(sc, sc, sc)
	parent.add_child(t)
	_cyl(t, "Trunk", 0.24, 0.32, 2.2, Vector3(0, 1.1, 0), Vector3.ZERO, materials["timber_dark"], true)
	var f1 := _prism(t, "T1", Vector3(3.4, 2.5, 3.4), Vector3(0, 2.6, 0), Vector3.ZERO, materials["pine"], false)
	var f2 := _prism(t, "T2", Vector3(2.6, 2.1, 2.6), Vector3(0, 3.8, 0), Vector3.ZERO, materials["pine"], false)
	var f3 := _prism(t, "T3", Vector3(1.8, 1.7, 1.8), Vector3(0, 5.0, 0), Vector3.ZERO, materials["pine"], false)
	f1.rotation_degrees.y = 15.0; f2.rotation_degrees.y = -30.0; f3.rotation_degrees.y = 45.0

func _oak_tree(parent: Node, pos: Vector3, sc: float) -> void:
	var t := Node3D.new(); t.name = "Oak"; t.position = pos; t.scale = Vector3(sc, sc, sc)
	parent.add_child(t)
	_cyl(t, "Trunk", 0.35, 0.45, 2.5, Vector3(0, 1.25, 0), Vector3.ZERO, materials["timber_dark"], true)
	_sphere(t, "CM", 2.2, Vector3(0, 3.6, 0), materials["oak"])
	_sphere(t, "CL", 1.5, Vector3(-1.1, 3.2, 0.5), materials["oak"])
	_sphere(t, "CR", 1.5, Vector3(1.1, 3.2, -0.4), materials["oak"])

func _fence_line(parent: Node, start: Vector3, end: Vector3) -> void:
	var dist := start.distance_to(end)
	var steps := int(dist / 1.5)
	var dir := (end - start).normalized()
	for i in range(steps + 1):
		var p := start + dir * (float(i) * 1.5)
		_box(parent, "FPost", Vector3(0.12, 1.0, 0.12), p + Vector3(0, 0.5, 0), Vector3.ZERO, materials["timber_weathered"], true)
		if i < steps:
			var mid := p + dir * 0.75
			var r := rad_to_deg(atan2(dir.x, dir.z))
			_box(parent, "FRail", Vector3(0.08, 0.1, 1.5), mid + Vector3(0, 0.7, 0), Vector3(0, r, 0), materials["timber_weathered"], false)
