extends SceneTree

# Builds the village expansion scene with medieval architecture, central plaza details,
# 5 branching path signage, and environmental props matching Phase 4 and Phase 5.
func _init() -> void:
	_build.call_deferred()

func _build() -> void:
	print("\n=== GENERATING VILLAGE EXPANSION SCENE ===")
	
	var root_node := Node3D.new()
	root_node.name = "VillageExpansion"
	
	# Load roof materials
	var mat_burgundy: StandardMaterial3D = load("res://resources/roofs/materials/mat_roof_burgundy.tres")
	var mat_plum: StandardMaterial3D = load("res://resources/roofs/materials/mat_roof_plum.tres")
	var mat_wine: StandardMaterial3D = load("res://resources/roofs/materials/mat_roof_wine.tres")
	
	# Create shared medieval architectural materials
	var mat_plaster := StandardMaterial3D.new()
	mat_plaster.albedo_color = Color(0.88, 0.85, 0.76)
	mat_plaster.roughness = 0.90
	
	var mat_timber := StandardMaterial3D.new()
	mat_timber.albedo_color = Color(0.24, 0.17, 0.12)
	mat_timber.roughness = 0.85
	
	var mat_stone_found := StandardMaterial3D.new()
	mat_stone_found.albedo_color = Color(0.38, 0.36, 0.34)
	mat_stone_found.roughness = 0.92
	
	var mat_parchment := StandardMaterial3D.new()
	mat_parchment.albedo_color = Color(0.92, 0.86, 0.72)
	mat_parchment.roughness = 0.80
	
	var mat_cloth_burgundy := StandardMaterial3D.new()
	mat_cloth_burgundy.albedo_color = Color(0.55, 0.18, 0.22)
	mat_cloth_burgundy.roughness = 0.85
	
	# -------------------------------------------------------------------------
	# 1. CENTRAL PLAZA ENHANCEMENTS (At Center Vector3(0, 0.61, 0))
	# -------------------------------------------------------------------------
	var plaza_group := Node3D.new()
	plaza_group.name = "CentralPlazaDetails"
	root_node.add_child(plaza_group)
	plaza_group.owner = root_node
	
	# Notice Board
	var nb := Node3D.new()
	nb.name = "PlazaNoticeBoard"
	nb.position = Vector3(3.2, 0.61, -3.5)
	nb.rotation_degrees.y = -35.0
	plaza_group.add_child(nb)
	nb.owner = root_node
	
	_create_box(nb, "PostL", Vector3(0.14, 2.2, 0.14), Vector3(-0.7, 1.1, 0), mat_timber, root_node)
	_create_box(nb, "PostR", Vector3(0.14, 2.2, 0.14), Vector3(0.7, 1.1, 0), mat_timber, root_node)
	_create_box(nb, "Roof", Vector3(1.7, 0.08, 0.4), Vector3(0, 2.2, 0), mat_timber, root_node)
	_create_box(nb, "Board", Vector3(1.4, 1.0, 0.06), Vector3(0, 1.4, 0), mat_timber, root_node)
	_create_box(nb, "Notice1", Vector3(0.35, 0.45, 0.02), Vector3(-0.35, 1.45, 0.04), mat_parchment, root_node)
	_create_box(nb, "Notice2", Vector3(0.4, 0.5, 0.02), Vector3(0.25, 1.4, 0.04), mat_parchment, root_node)
	_create_box(nb, "SealRaven", Vector3(0.08, 0.08, 0.03), Vector3(0.25, 1.6, 0.05), mat_cloth_burgundy, root_node)
	
	# Plaza Benches
	var bench1 := _create_bench(plaza_group, "PlazaBench_North", Vector3(-4.0, 0.61, -4.5), 45.0, mat_timber, root_node)
	var bench2 := _create_bench(plaza_group, "PlazaBench_South", Vector3(-3.5, 0.61, 4.5), 135.0, mat_timber, root_node)
	
	# Barrels & Crates clusters
	_create_barrel_cluster(plaza_group, "PlazaBarrels_East", Vector3(5.5, 0.61, 1.0), mat_timber, root_node)
	_create_barrel_cluster(plaza_group, "PlazaBarrels_West", Vector3(-6.0, 0.61, -1.5), mat_timber, root_node)
	
	# Plaza Lantern Posts
	_create_lantern_post(plaza_group, "PlazaLamp_NE", Vector3(4.5, 0.61, -4.0), mat_timber, root_node)
	_create_lantern_post(plaza_group, "PlazaLamp_SW", Vector3(-4.5, 0.61, 4.0), mat_timber, root_node)

	# -------------------------------------------------------------------------
	# 2. FIVE BRANCHING PATH DIRECTIONAL SIGNPOSTS (Matching Sketch)
	# -------------------------------------------------------------------------
	var signs_group := Node3D.new()
	signs_group.name = "FivePathSignposts"
	root_node.add_child(signs_group)
	signs_group.owner = root_node
	
	_create_signpost(signs_group, "Sign_Path1_Residential", Vector3(8.5, 0.61, -7.5), -45.0, "Path 1: Residential District", mat_timber, mat_parchment, root_node)
	_create_signpost(signs_group, "Sign_Path2_Harbour", Vector3(-7.5, 0.61, 6.0), 140.0, "Path 2: Harbour & Docks", mat_timber, mat_parchment, root_node)
	_create_signpost(signs_group, "Sign_Path3_Market", Vector3(2.5, 0.61, 9.0), 175.0, "Path 3: Market Bazaar", mat_timber, mat_parchment, root_node)
	_create_signpost(signs_group, "Sign_Path4_InnServices", Vector3(-9.5, 0.61, -1.0), -90.0, "Path 4: Inn & Clinic", mat_timber, mat_parchment, root_node)
	_create_signpost(signs_group, "Sign_Path5_AdminPass", Vector3(-6.0, 0.61, -7.5), -145.0, "Path 5: Town Hall & Pass", mat_timber, mat_parchment, root_node)

	# -------------------------------------------------------------------------
	# 3. EXPANDED MEDIEVAL HOUSES BESIDE THE FIVE PATHS
	# -------------------------------------------------------------------------
	var houses_group := Node3D.new()
	houses_group.name = "ExpandedHousesBesidePaths"
	root_node.add_child(houses_group)
	houses_group.owner = root_node
	
	# Path 1: Northern Residential Cottage
	_build_medieval_house(
		houses_group, "Path1_ResidentialCottage",
		Vector3(17.5, 0.90, -20.0), 25.0,
		Vector3(7.5, 4.5, 6.0), 3.2,
		mat_stone_found, mat_plaster, mat_timber, mat_burgundy, root_node
	)
	
	# Path 1: Bluff View Townhouse
	_build_medieval_house(
		houses_group, "Path1_BluffTownhouse",
		Vector3(23.5, 1.15, -17.0), -20.0,
		Vector3(8.0, 5.0, 6.5), 3.5,
		mat_stone_found, mat_plaster, mat_timber, mat_plum, root_node
	)
	
	# Path 2: Coastal Fisher's House & Net Loft (near harbour road descent)
	_build_medieval_house(
		houses_group, "Path2_FishermansLoft",
		Vector3(-31.0, 0.35, 9.5), 65.0,
		Vector3(7.0, 4.2, 5.5), 2.8,
		mat_stone_found, mat_plaster, mat_timber, mat_wine, root_node
	)
	
	# Path 3: Market Artisan Workshop (beside bazaar route)
	_build_medieval_house(
		houses_group, "Path3_ArtisanWorkshop",
		Vector3(9.5, 0.61, 14.0), -70.0,
		Vector3(7.0, 4.5, 6.0), 3.0,
		mat_stone_found, mat_plaster, mat_timber, mat_burgundy, root_node
	)
	
	# Path 4: Apothecary Annex & Herbalist Store (beside clinic/inn route)
	_build_medieval_house(
		houses_group, "Path4_ApothecaryAnnex",
		Vector3(-17.5, 0.61, 4.5), 20.0,
		Vector3(6.5, 4.0, 5.0), 2.8,
		mat_stone_found, mat_plaster, mat_timber, mat_plum, root_node
	)
	
	# Path 5: Outer Administrative Residence (beside Town Hall & Pass avenue)
	_build_medieval_house(
		houses_group, "Path5_AdministrativeResidence",
		Vector3(-14.5, 1.05, -14.0), -45.0,
		Vector3(7.5, 4.8, 6.0), 3.2,
		mat_stone_found, mat_plaster, mat_timber, mat_wine, root_node
	)

	# -------------------------------------------------------------------------
	# 4. MEDIEVAL ENVIRONMENTAL PROPS
	# -------------------------------------------------------------------------
	var props_group := Node3D.new()
	props_group.name = "MedievalProps"
	root_node.add_child(props_group)
	props_group.owner = root_node
	
	# Market stalls with awnings in Path 3 Market District
	_create_market_stall(props_group, "MarketStall_Produce", Vector3(5.5, 0.61, 7.5), 15.0, mat_timber, mat_cloth_burgundy, root_node)
	_create_market_stall(props_group, "MarketStall_Pottery", Vector3(1.0, 0.61, 13.0), -45.0, mat_timber, mat_parchment, root_node)
	
	# Wooden handcart
	_create_handcart(props_group, "Handcart_Market", Vector3(4.0, 0.61, 9.5), 30.0, mat_timber, root_node)
	
	# Harbour cargo barrels & dock crates along Path 2
	_create_barrel_cluster(props_group, "HarbourCargo_1", Vector3(-27.0, 0.40, 14.5), mat_timber, root_node)
	_create_barrel_cluster(props_group, "HarbourCargo_2", Vector3(-37.0, 0.18, 11.5), mat_timber, root_node)
	
	# Firewood stacks along Path 4 near Inn
	_create_firewood_stack(props_group, "InnFirewood", Vector3(-21.0, 0.61, -4.5), mat_timber, root_node)

	# Save packed scene
	var packed := PackedScene.new()
	var pack_err = packed.pack(root_node)
	assert(pack_err == OK, "Failed to pack VillageExpansion scene")
	var out_path = "res://scenes/village_expansion.tscn"
	var save_err = ResourceSaver.save(packed, out_path)
	assert(save_err == OK, "Failed to save to " + out_path)
	print("Successfully created VillageExpansion scene at: ", out_path)
	
	root_node.queue_free()
	quit(0)

# Helper functions
func _create_box(parent: Node, b_name: String, size: Vector3, pos: Vector3, mat: Material, owner_node: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = b_name
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	mi.owner = owner_node
	return mi

func _create_bench(parent: Node, b_name: String, pos: Vector3, rot_y: float, mat: Material, owner_node: Node) -> Node3D:
	var b := Node3D.new(); b.name = b_name; b.position = pos; b.rotation_degrees.y = rot_y
	parent.add_child(b); b.owner = owner_node
	_create_box(b, "Seat", Vector3(1.6, 0.08, 0.45), Vector3(0, 0.45, 0), mat, owner_node)
	_create_box(b, "Back", Vector3(1.6, 0.40, 0.06), Vector3(0, 0.70, -0.2), mat, owner_node)
	_create_box(b, "LegL", Vector3(0.08, 0.45, 0.4), Vector3(-0.65, 0.225, 0), mat, owner_node)
	_create_box(b, "LegR", Vector3(0.08, 0.45, 0.4), Vector3(0.65, 0.225, 0), mat, owner_node)
	return b

func _create_barrel_cluster(parent: Node, c_name: String, pos: Vector3, mat: Material, owner_node: Node) -> Node3D:
	var c := Node3D.new(); c.name = c_name; c.position = pos
	parent.add_child(c); c.owner = owner_node
	_create_cylinder(c, "Barrel1", 0.32, 0.32, 0.85, Vector3(0, 0.425, 0), mat, owner_node)
	_create_cylinder(c, "Barrel2", 0.32, 0.32, 0.85, Vector3(0.55, 0.425, 0.2), mat, owner_node)
	_create_box(c, "Crate1", Vector3(0.7, 0.6, 0.7), Vector3(-0.5, 0.3, 0.3), mat, owner_node)
	return c

func _create_cylinder(parent: Node, c_name: String, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material, owner_node: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = c_name
	var cm := CylinderMesh.new(); cm.top_radius = top_r; cm.bottom_radius = bot_r; cm.height = height
	mi.mesh = cm; mi.material_override = mat; mi.position = pos
	parent.add_child(mi); mi.owner = owner_node
	return mi

func _create_lantern_post(parent: Node, l_name: String, pos: Vector3, mat: Material, owner_node: Node) -> Node3D:
	var lp := Node3D.new(); lp.name = l_name; lp.position = pos
	parent.add_child(lp); lp.owner = owner_node
	_create_box(lp, "Post", Vector3(0.16, 3.2, 0.16), Vector3(0, 1.6, 0), mat, owner_node)
	_create_box(lp, "Arm", Vector3(0.6, 0.1, 0.1), Vector3(0.25, 3.1, 0), mat, owner_node)
	var lantern_mat := StandardMaterial3D.new(); lantern_mat.albedo_color = Color(1.0, 0.85, 0.45); lantern_mat.emission_enabled = true; lantern_mat.emission = Color(1.0, 0.8, 0.4)
	_create_box(lp, "Lantern", Vector3(0.22, 0.3, 0.22), Vector3(0.5, 2.9, 0), lantern_mat, owner_node)
	var light := OmniLight3D.new(); light.name = "Light"; light.light_color = Color(1.0, 0.85, 0.5); light.light_energy = 1.4; light.omni_range = 8.0; light.position = Vector3(0.5, 2.85, 0)
	lp.add_child(light); light.owner = owner_node
	return lp

func _create_signpost(parent: Node, s_name: String, pos: Vector3, rot_y: float, text: String, mat_timber: Material, mat_parchment: Material, owner_node: Node) -> Node3D:
	var sp := Node3D.new(); sp.name = s_name; sp.position = pos; sp.rotation_degrees.y = rot_y
	parent.add_child(sp); sp.owner = owner_node
	_create_box(sp, "Post", Vector3(0.14, 2.0, 0.14), Vector3(0, 1.0, 0), mat_timber, owner_node)
	_create_box(sp, "SignBoard", Vector3(1.1, 0.35, 0.05), Vector3(0.45, 1.8, 0), mat_timber, owner_node)
	_create_box(sp, "ParchmentFace", Vector3(1.0, 0.28, 0.02), Vector3(0.45, 1.8, 0.035), mat_parchment, owner_node)
	return sp

func _create_market_stall(parent: Node, s_name: String, pos: Vector3, rot_y: float, mat_wood: Material, mat_cloth: Material, owner_node: Node) -> Node3D:
	var ms := Node3D.new(); ms.name = s_name; ms.position = pos; ms.rotation_degrees.y = rot_y
	parent.add_child(ms); ms.owner = owner_node
	# Table counter
	_create_box(ms, "Counter", Vector3(2.2, 0.85, 0.9), Vector3(0, 0.425, 0), mat_wood, owner_node)
	# Posts
	_create_box(ms, "PostFL", Vector3(0.08, 2.2, 0.08), Vector3(-1.0, 1.1, 0.4), mat_wood, owner_node)
	_create_box(ms, "PostFR", Vector3(0.08, 2.2, 0.08), Vector3(1.0, 1.1, 0.4), mat_wood, owner_node)
	_create_box(ms, "PostBL", Vector3(0.08, 2.5, 0.08), Vector3(-1.0, 1.25, -0.4), mat_wood, owner_node)
	_create_box(ms, "PostBR", Vector3(0.08, 2.5, 0.08), Vector3(1.0, 1.25, -0.4), mat_wood, owner_node)
	# Sloped Awning (slopes forward from taller back posts to lower front posts)
	var awning := _create_box(ms, "Awning", Vector3(2.3, 0.06, 1.1), Vector3(0, 2.35, 0), mat_cloth, owner_node)
	awning.rotation_degrees.x = -12.0
	return ms

func _create_handcart(parent: Node, c_name: String, pos: Vector3, rot_y: float, mat_wood: Material, owner_node: Node) -> Node3D:
	var hc := Node3D.new(); hc.name = c_name; hc.position = pos; hc.rotation_degrees.y = rot_y
	parent.add_child(hc); hc.owner = owner_node
	_create_box(hc, "Bed", Vector3(1.4, 0.35, 0.9), Vector3(0, 0.4, 0), mat_wood, owner_node)
	_create_box(hc, "HandleL", Vector3(0.06, 0.06, 1.1), Vector3(-0.35, 0.45, 0.9), mat_wood, owner_node)
	_create_box(hc, "HandleR", Vector3(0.06, 0.06, 1.1), Vector3(0.35, 0.45, 0.9), mat_wood, owner_node)
	_create_cylinder(hc, "WheelL", 0.3, 0.3, 0.08, Vector3(-0.55, 0.3, 0), mat_wood, owner_node).rotation_degrees.z = 90
	_create_cylinder(hc, "WheelR", 0.3, 0.3, 0.08, Vector3(0.55, 0.3, 0), mat_wood, owner_node).rotation_degrees.z = 90
	return hc

func _create_firewood_stack(parent: Node, f_name: String, pos: Vector3, mat_wood: Material, owner_node: Node) -> Node3D:
	var fw := Node3D.new(); fw.name = f_name; fw.position = pos
	parent.add_child(fw); fw.owner = owner_node
	_create_box(fw, "Logs", Vector3(1.8, 0.8, 0.6), Vector3(0, 0.4, 0), mat_wood, owner_node)
	return fw

func _build_medieval_house(
	parent: Node, h_name: String,
	pos: Vector3, rot_y: float,
	size: Vector3, roof_pitch_height: float,
	mat_found: Material, mat_wall: Material, mat_timber: Material, mat_roof: Material,
	owner_node: Node
) -> Node3D:
	var house := Node3D.new(); house.name = h_name; house.position = pos; house.rotation_degrees.y = rot_y
	parent.add_child(house); house.owner = owner_node
	
	# Foundation
	var f_height: float = 1.0
	_create_box(house, "Foundation", Vector3(size.x, f_height, size.z), Vector3(0, f_height * 0.5, 0), mat_found, owner_node)
	
	# Main walls
	var wall_height: float = size.y - f_height
	_create_box(house, "Walls", Vector3(size.x - 0.2, wall_height, size.z - 0.2), Vector3(0, f_height + wall_height * 0.5, 0), mat_wall, owner_node)
	
	# Corner timber beams
	var hw: float = size.x * 0.5
	var hd: float = size.z * 0.5
	_create_box(house, "Beam_FL", Vector3(0.18, wall_height, 0.18), Vector3(-hw + 0.1, f_height + wall_height * 0.5, hd - 0.1), mat_timber, owner_node)
	_create_box(house, "Beam_FR", Vector3(0.18, wall_height, 0.18), Vector3(hw - 0.1, f_height + wall_height * 0.5, hd - 0.1), mat_timber, owner_node)
	_create_box(house, "Beam_BL", Vector3(0.18, wall_height, 0.18), Vector3(-hw + 0.1, f_height + wall_height * 0.5, -hd + 0.1), mat_timber, owner_node)
	_create_box(house, "Beam_BR", Vector3(0.18, wall_height, 0.18), Vector3(hw - 0.1, f_height + wall_height * 0.5, -hd + 0.1), mat_timber, owner_node)
	
	# Door & Window
	_create_box(house, "Door", Vector3(0.9, 1.8, 0.1), Vector3(0, f_height + 0.9, hd), mat_timber, owner_node)
	var win_mat := StandardMaterial3D.new(); win_mat.albedo_color = Color(1.0, 0.88, 0.5); win_mat.emission_enabled = true; win_mat.emission = Color(0.8, 0.65, 0.3)
	_create_box(house, "WindowL", Vector3(0.8, 0.9, 0.08), Vector3(-hw * 0.5, f_height + 1.8, hd), win_mat, owner_node)
	_create_box(house, "WindowR", Vector3(0.8, 0.9, 0.08), Vector3(hw * 0.5, f_height + 1.8, hd), win_mat, owner_node)
	
	# Steep triangular pitched roof
	var roof_node := Node3D.new(); roof_node.name = "RoofPitched"
	roof_node.position = Vector3(0, size.y, 0)
	house.add_child(roof_node); roof_node.owner = owner_node
	
	# Left slope & Right slope (steep pitch rising to ridge peak at center)
	var slope_len: float = sqrt(pow(hw + 0.5, 2) + pow(roof_pitch_height, 2))
	var pitch_angle: float = rad_to_deg(atan2(roof_pitch_height, hw + 0.5))
	
	var slope_l := _create_box(roof_node, "SlopeL", Vector3(slope_len, 0.18, size.z + 0.8), Vector3(-(hw + 0.5) * 0.5, roof_pitch_height * 0.5, 0), mat_roof, owner_node)
	slope_l.rotation_degrees.z = pitch_angle
	
	var slope_r := _create_box(roof_node, "SlopeR", Vector3(slope_len, 0.18, size.z + 0.8), Vector3((hw + 0.5) * 0.5, roof_pitch_height * 0.5, 0), mat_roof, owner_node)
	slope_r.rotation_degrees.z = -pitch_angle
	
	# Ridge cap
	_create_box(roof_node, "RidgeCap", Vector3(0.35, 0.25, size.z + 0.9), Vector3(0, roof_pitch_height + 0.1, 0), mat_timber, owner_node)
	
	# Gable wall infills
	_create_box(roof_node, "GableF", Vector3(size.x - 0.4, roof_pitch_height * 0.7, 0.15), Vector3(0, roof_pitch_height * 0.35, hd - 0.1), mat_wall, owner_node)
	_create_box(roof_node, "GableB", Vector3(size.x - 0.4, roof_pitch_height * 0.7, 0.15), Vector3(0, roof_pitch_height * 0.35, -hd + 0.1), mat_wall, owner_node)
	
	# StaticBody3D collision
	var sb := StaticBody3D.new(); sb.name = "Collision"
	var cs := CollisionShape3D.new(); var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(size.x, size.y + roof_pitch_height, size.z)
	cs.shape = box_shape; cs.position = Vector3(0, (size.y + roof_pitch_height) * 0.5, 0)
	sb.add_child(cs); house.add_child(sb); sb.owner = owner_node
	
	return house
