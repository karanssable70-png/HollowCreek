class_name HouseInteriorController
extends Node3D

## HouseInteriorController
## Manages 3D medieval living room environments for designated villager residences.
## Integrates full first-person detective player movement (res://scenes/player.tscn),
## atmospheric medieval commodities (fireplace, dining table, bed alcove, shelves, barrels),
## character-specific primary secret puzzles (drawers for Tomas & Edmund, purple herbs for Elora,
## stolen goods cache for Lena, desk dossiers for others), scattered interactable evidence papers,
## and an authentic parchment document inspection modal.

const HouseClueInteractableScript = preload("res://scripts/world/house_clue_interactable.gd")
const HouseExitDoorScript = preload("res://scripts/world/house_exit_door.gd")

# UI references
var hud_canvas: CanvasLayer
var doc_modal_panel: PanelContainer
var doc_title_label: Label
var doc_subtitle_label: Label
var doc_body_label: RichTextLabel
var doc_discovery_label: Label
var close_doc_btn: Button
var is_inspecting_doc: bool = false

# Player reference
var player_controller: PlayerController = null

# Active house data
var current_house_data: Dictionary = {}

# Drawer state
var is_drawer_open: bool = false
var drawer_mesh_node: Node3D = null

func _ready() -> void:
	HouseInteriorManager.is_inside_house = true
	var h_id: String = HouseInteriorManager.current_house_id
	if h_id.is_empty():
		h_id = "tomas"
	current_house_data = HouseInteriorManager.get_house_data(h_id)
	
	_build_room_geometry()
	_build_medieval_commodities()
	_build_house_specific_puzzle()
	_build_scattered_papers()
	_spawn_player()
	_setup_inspection_ui()
	_setup_lighting_and_audio()

# ===========================================================================
# 1. 3D MEDIEVAL LIVING ROOM ARCHITECTURE
# ===========================================================================
func _build_room_geometry() -> void:
	var room_root := Node3D.new()
	room_root.name = "RoomArchitecture"
	add_child(room_root)

	# Materials
	var mat_floor := StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.24, 0.16, 0.10) # Dark polished oak planks
	mat_floor.roughness = 0.75
	
	var mat_wall := StandardMaterial3D.new()
	mat_wall.albedo_color = Color(0.82, 0.78, 0.70) # Plastered wattle & daub
	mat_wall.roughness = 0.90
	
	var mat_timber := StandardMaterial3D.new()
	mat_timber.albedo_color = Color(0.18, 0.12, 0.08) # Aged dark oak beams
	mat_timber.roughness = 0.85
	
	var mat_stone := StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.35, 0.35, 0.33) # Rough hearthstone
	mat_stone.roughness = 0.95

	# Floor (8.4m x 6.4m, centered at origin)
	_create_static_box(room_root, "Floor", Vector3(8.4, 0.2, 6.4), Vector3(0, -0.1, 0), mat_floor)
	
	# Ceiling (Height: 3.4m)
	_create_static_box(room_root, "Ceiling", Vector3(8.4, 0.2, 6.4), Vector3(0, 3.5, 0), mat_timber)
	
	# Exposed ceiling beams across room
	for z_pos in [-2.0, -0.7, 0.7, 2.0]:
		_create_box(room_root, "CeilingBeam", Vector3(8.3, 0.25, 0.25), Vector3(0, 3.35, z_pos), mat_timber)

	# North Wall (Back wall, Z = -3.1)
	_create_static_box(room_root, "WallNorth", Vector3(8.4, 3.5, 0.2), Vector3(0, 1.65, -3.1), mat_wall)
	# South Wall (Front entrance, Z = +3.1)
	_create_static_box(room_root, "WallSouth", Vector3(8.4, 3.5, 0.2), Vector3(0, 1.65, 3.1), mat_wall)
	# West Wall (Hearth wall, X = -4.1)
	_create_static_box(room_root, "WallWest", Vector3(0.2, 3.5, 6.4), Vector3(-4.1, 1.65, 0), mat_wall)
	# East Wall (Window & alcove wall, X = +4.1)
	_create_static_box(room_root, "WallEast", Vector3(0.2, 3.5, 6.4), Vector3(4.1, 1.65, 0), mat_wall)

	# Timber vertical corner posts
	for x_pos in [-4.0, 4.0]:
		for z_pos in [-3.0, 3.0]:
			_create_box(room_root, "CornerPost", Vector3(0.28, 3.4, 0.28), Vector3(x_pos, 1.7, z_pos), mat_timber)
			
	# Front Entrance Doorway (Exit to Village)
	_build_exit_door(room_root, mat_timber, mat_stone)

func _build_exit_door(parent: Node3D, mat_timber: Material, mat_stone: Material) -> void:
	var door_frame := Node3D.new()
	door_frame.name = "FrontExitDoor"
	door_frame.position = Vector3(0, 0, 2.95)
	parent.add_child(door_frame)

	# Stone door surround
	_create_box(door_frame, "DoorSurroundL", Vector3(0.25, 2.4, 0.15), Vector3(-0.75, 1.2, 0), mat_stone)
	_create_box(door_frame, "DoorSurroundR", Vector3(0.25, 2.4, 0.15), Vector3(0.75, 1.2, 0), mat_stone)
	_create_box(door_frame, "DoorLintel", Vector3(1.75, 0.3, 0.18), Vector3(0, 2.4, 0), mat_stone)

	# Wooden plank door panel
	_create_box(door_frame, "DoorPanel", Vector3(1.25, 2.25, 0.08), Vector3(0, 1.12, 0.02), mat_timber)
	
	# Iron handle & cross latch
	var mat_iron := StandardMaterial3D.new()
	mat_iron.albedo_color = Color(0.12, 0.12, 0.12)
	mat_iron.metallic = 0.95
	mat_iron.roughness = 0.35
	_create_box(door_frame, "IronLatch", Vector3(0.12, 0.15, 0.06), Vector3(0.42, 1.1, -0.04), mat_iron)

	# Exit lantern
	var mat_lantern := StandardMaterial3D.new()
	mat_lantern.albedo_color = Color(1.0, 0.85, 0.3)
	mat_lantern.emission_enabled = true
	mat_lantern.emission = Color(1.0, 0.85, 0.3)
	mat_lantern.emission_energy_multiplier = 2.0
	_create_box(door_frame, "ExitLantern", Vector3(0.14, 0.22, 0.14), Vector3(0.65, 1.8, -0.1), mat_lantern)

	# HouseExitDoor interactable Area3D
	var exit_area = HouseExitDoorScript.new()
	exit_area.name = "ExitDoorInteractable"
	exit_area.prompt_text = "[E] Exit to Hollow Creek Village"
	
	var col := CollisionShape3D.new()
	col.name = "DoorCollisionShape"
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 2.5, 1.2)
	col.shape = box
	col.position = Vector3(0, 1.25, -0.4)
	exit_area.add_child(col)
	door_frame.add_child(exit_area)

# ===========================================================================
# 2. MEDIEVAL COMMODITIES (HEARTH, TABLE, CHAIRS, BED, SHELVES, BARRELS)
# ===========================================================================
func _build_medieval_commodities() -> void:
	var comm_root := Node3D.new()
	comm_root.name = "MedievalCommodities"
	add_child(comm_root)

	var mat_timber := StandardMaterial3D.new(); mat_timber.albedo_color = Color(0.22, 0.15, 0.09)
	var mat_stone := StandardMaterial3D.new(); mat_stone.albedo_color = Color(0.38, 0.36, 0.32)
	var mat_fire_hearth := StandardMaterial3D.new(); mat_fire_hearth.albedo_color = Color(0.12, 0.08, 0.06)
	var mat_cloth_red := StandardMaterial3D.new(); mat_cloth_red.albedo_color = Color(0.48, 0.12, 0.14)
	var mat_cloth_cream := StandardMaterial3D.new(); mat_cloth_cream.albedo_color = Color(0.85, 0.82, 0.74)
	var mat_iron := StandardMaterial3D.new(); mat_iron.albedo_color = Color(0.15, 0.15, 0.15); mat_iron.metallic = 0.9

	# --- 2A. STONE HEARTH & FIREPLACE (West Wall) ---
	var hearth := Node3D.new()
	hearth.name = "StoneFireplace"
	hearth.position = Vector3(-3.85, 0, 0)
	comm_root.add_child(hearth)

	_create_static_box(hearth, "HearthPillarL", Vector3(0.5, 2.2, 0.4), Vector3(0, 1.1, -1.0), mat_stone)
	_create_static_box(hearth, "HearthPillarR", Vector3(0.5, 2.2, 0.4), Vector3(0, 1.1, 1.0), mat_stone)
	_create_static_box(hearth, "HearthMantel", Vector3(0.65, 0.35, 2.6), Vector3(0, 2.2, 0), mat_stone)
	_create_static_box(hearth, "ChimneyFlue", Vector3(0.6, 1.1, 1.8), Vector3(0, 2.9, 0), mat_stone)
	_create_static_box(hearth, "FireboxBack", Vector3(0.25, 2.0, 1.8), Vector3(-0.15, 1.0, 0), mat_fire_hearth)
	
	# Logs & glowing fire embers
	var mat_embers := StandardMaterial3D.new()
	mat_embers.albedo_color = Color(1.0, 0.4, 0.05)
	mat_embers.emission_enabled = true
	mat_embers.emission = Color(1.0, 0.45, 0.1)
	mat_embers.emission_energy_multiplier = 3.5
	_create_box(hearth, "Embers", Vector3(0.35, 0.15, 0.9), Vector3(0.12, 0.08, 0), mat_embers)
	_create_box(hearth, "FireLog1", Vector3(0.12, 0.12, 0.8), Vector3(0.12, 0.15, 0), mat_timber)
	_create_box(hearth, "FireLog2", Vector3(0.10, 0.10, 0.75), Vector3(0.14, 0.24, -0.05), mat_timber)

	# Flickering firelight
	var fire_light := OmniLight3D.new()
	fire_light.name = "FireLight"
	fire_light.light_color = Color(1.0, 0.65, 0.3)
	fire_light.light_energy = 2.4
	fire_light.omni_range = 6.5
	fire_light.position = Vector3(0.25, 0.4, 0)
	hearth.add_child(fire_light)

	# --- 2B. DINING TABLE & CHAIRS (Center Room) ---
	var dining := Node3D.new()
	dining.name = "DiningTableSet"
	dining.position = Vector3(0, 0, 0.2)
	comm_root.add_child(dining)

	# Table Top (StaticBody3D) & 4 Legs
	_create_static_box(dining, "TableTop", Vector3(2.4, 0.10, 1.3), Vector3(0, 0.85, 0), mat_timber)
	for lx in [-1.0, 1.0]:
		for lz in [-0.5, 0.5]:
			_create_box(dining, "TableLeg", Vector3(0.12, 0.85, 0.12), Vector3(lx, 0.425, lz), mat_timber)

	# Woven floor rug under table
	_create_box(dining, "WovenRug", Vector3(3.2, 0.02, 2.2), Vector3(0, 0.01, 0), mat_cloth_red)

	# 2 High-back Dining Chairs (visual meshes without collision so player never gets stuck)
	_build_chair(dining, Vector3(0, 0, -0.9), 0.0, mat_timber)
	_build_chair(dining, Vector3(0, 0, 1.3), 180.0, mat_timber)

	# Tabletop dinnerware
	_create_box(dining, "PewterGoblet1", Vector3(0.10, 0.16, 0.10), Vector3(-0.7, 0.98, -0.25), mat_iron)
	_create_box(dining, "PewterGoblet2", Vector3(0.10, 0.16, 0.10), Vector3(0.7, 0.98, 0.25), mat_iron)
	_create_box(dining, "WoodenBowl", Vector3(0.28, 0.08, 0.28), Vector3(-0.35, 0.94, -0.15), mat_timber)
	
	# Table Candle with subtle flame light
	var candle := Node3D.new(); candle.name = "TableCandle"; candle.position = Vector3(-0.15, 0.90, 0.35); dining.add_child(candle)
	_create_box(candle, "CandleWax", Vector3(0.08, 0.20, 0.08), Vector3(0, 0.10, 0), mat_cloth_cream)
	var flame_mat := StandardMaterial3D.new(); flame_mat.albedo_color = Color(1.0, 0.8, 0.2); flame_mat.emission_enabled = true; flame_mat.emission = Color(1.0, 0.8, 0.2); flame_mat.emission_energy_multiplier = 3.0
	_create_box(candle, "Flame", Vector3(0.03, 0.05, 0.03), Vector3(0, 0.22, 0), flame_mat)
	var candle_light := OmniLight3D.new(); candle_light.light_color = Color(1.0, 0.85, 0.5); candle_light.light_energy = 1.0; candle_light.omni_range = 3.5; candle_light.position = Vector3(0, 0.3, 0); candle.add_child(candle_light)

	# --- 2C. SLEEPING ALCOVE / FOUR-POSTER BED (North-East Corner) ---
	var bed := Node3D.new(); bed.name = "BedAlcove"; bed.position = Vector3(2.8, 0, -2.0); comm_root.add_child(bed)
	_create_static_box(bed, "BedFrame", Vector3(2.2, 0.35, 1.5), Vector3(0, 0.25, 0), mat_timber)
	_create_box(bed, "Mattress", Vector3(2.0, 0.25, 1.4), Vector3(0, 0.48, 0), mat_cloth_cream)
	_create_box(bed, "Quilt", Vector3(1.5, 0.12, 1.42), Vector3(-0.25, 0.58, 0), mat_cloth_red)
	_create_box(bed, "Pillow", Vector3(0.42, 0.14, 0.7), Vector3(0.75, 0.65, 0), mat_cloth_cream)
	for bx in [-1.05, 1.05]:
		for bz in [-0.72, 0.72]:
			_create_box(bed, "BedPost", Vector3(0.12, 2.2, 0.12), Vector3(bx, 1.1, bz), mat_timber)

	# --- 2D. BOOKSHELF & CUPBOARDS (North Wall) ---
	var shelf := Node3D.new(); shelf.name = "WallCupboard"; shelf.position = Vector3(-2.0, 0, -2.95); comm_root.add_child(shelf)
	_create_static_box(shelf, "ShelfFrame", Vector3(1.8, 2.4, 0.45), Vector3(0, 1.2, 0), mat_timber)
	for sy in [0.7, 1.3, 1.9]:
		_create_box(shelf, "ShelfDivider", Vector3(1.7, 0.05, 0.4), Vector3(0, sy, 0.02), mat_timber)
	# Books and scrolls
	var mat_book_leather := StandardMaterial3D.new(); mat_book_leather.albedo_color = Color(0.35, 0.15, 0.12)
	_create_box(shelf, "Tome1", Vector3(0.12, 0.35, 0.28), Vector3(-0.55, 1.5, 0.05), mat_book_leather)
	_create_box(shelf, "Tome2", Vector3(0.10, 0.32, 0.28), Vector3(-0.42, 1.48, 0.05), mat_timber)
	_create_box(shelf, "Tome3", Vector3(0.14, 0.38, 0.28), Vector3(-0.28, 1.52, 0.05), mat_cloth_red)

	# --- 2E. STORAGE BARRELS & CRATES (South-East Corner) ---
	var storage := Node3D.new(); storage.name = "StorageCorner"; storage.position = Vector3(3.3, 0, 2.2); comm_root.add_child(storage)
	_build_barrel(storage, Vector3(0, 0, 0), mat_timber, mat_iron)
	_build_barrel(storage, Vector3(-0.7, 0, 0.2), mat_timber, mat_iron)
	_create_static_box(storage, "CrateWood", Vector3(0.7, 0.7, 0.7), Vector3(0.1, 0.35, -0.7), mat_timber)

func _build_chair(parent: Node3D, pos: Vector3, rot_y: float, mat_timber: Material) -> void:
	var chair := Node3D.new()
	chair.position = pos
	chair.rotation_degrees.y = rot_y
	parent.add_child(chair)
	_create_box(chair, "Seat", Vector3(0.55, 0.06, 0.55), Vector3(0, 0.45, 0), mat_timber)
	_create_box(chair, "BackRest", Vector3(0.55, 0.65, 0.06), Vector3(0, 0.78, -0.24), mat_timber)
	for cx in [-0.22, 0.22]:
		for cz in [-0.22, 0.22]:
			_create_box(chair, "Leg", Vector3(0.06, 0.45, 0.06), Vector3(cx, 0.225, cz), mat_timber)

func _build_barrel(parent: Node3D, pos: Vector3, mat_timber: Material, mat_iron: Material) -> void:
	var b := Node3D.new(); b.position = pos; parent.add_child(b)
	_create_static_box(b, "BarrelBody", Vector3(0.65, 0.85, 0.65), Vector3(0, 0.425, 0), mat_timber)
	_create_box(b, "HoopTop", Vector3(0.67, 0.05, 0.67), Vector3(0, 0.75, 0), mat_iron)
	_create_box(b, "HoopBottom", Vector3(0.67, 0.05, 0.67), Vector3(0, 0.15, 0), mat_iron)

# ===========================================================================
# 3. HOUSE-SPECIFIC PRIMARY PUZZLE SETUP
# ===========================================================================
func _build_house_specific_puzzle() -> void:
	var puzzle_root := Node3D.new()
	puzzle_root.name = "HouseSpecificPuzzle"
	add_child(puzzle_root)

	var p_type: String = current_house_data.get("puzzle_type", "drawer")
	var mat_desk := StandardMaterial3D.new(); mat_desk.albedo_color = Color(0.25, 0.16, 0.10)
	var mat_paper := StandardMaterial3D.new(); mat_paper.albedo_color = Color(0.92, 0.88, 0.78); mat_paper.roughness = 0.95
	var mat_glow := StandardMaterial3D.new(); mat_glow.albedo_color = Color(1.0, 0.9, 0.4); mat_glow.emission_enabled = true; mat_glow.emission = Color(1.0, 0.85, 0.3); mat_glow.emission_energy_multiplier = 2.0

	match p_type:
		"drawer":
			# ===================================================================
			# TOMAS REED (Hypersomnia Report) & PHYSICIAN (Falsified Autopsy)
			# User requirement: "interactable drawer where I can pick up the paper and then read the cause"
			# ===================================================================
			var desk := Node3D.new()
			desk.name = "InvestigationDesk"
			desk.position = Vector3(2.4, 0, 0.4)
			desk.rotation_degrees.y = -90.0
			puzzle_root.add_child(desk)

			# Desk body and table top
			_create_static_box(desk, "DeskTop", Vector3(1.6, 0.08, 0.85), Vector3(0, 0.82, 0), mat_desk)
			_create_static_box(desk, "DeskCabinetL", Vector3(0.45, 0.78, 0.75), Vector3(-0.55, 0.39, 0), mat_desk)
			_create_static_box(desk, "DeskLegR", Vector3(0.10, 0.78, 0.75), Vector3(0.70, 0.39, 0), mat_desk)

			# Desk Drawer: Starts closed (Z = 0.0). Slides forward when clicked!
			drawer_mesh_node = Node3D.new()
			drawer_mesh_node.name = "InteractableDrawer"
			drawer_mesh_node.position = Vector3(-0.55, 0.62, 0.0) # Closed position
			desk.add_child(drawer_mesh_node)

			# Drawer visual box
			_create_box(drawer_mesh_node, "DrawerBox", Vector3(0.40, 0.22, 0.65), Vector3(0, 0, 0), mat_desk)
			_create_box(drawer_mesh_node, "DrawerFront", Vector3(0.42, 0.24, 0.04), Vector3(0, 0, 0.33), mat_desk)
			_create_box(drawer_mesh_node, "DrawerHandle", Vector3(0.12, 0.04, 0.04), Vector3(0, 0, 0.36), mat_glow)

			# Secret Document inside the drawer
			_create_box(drawer_mesh_node, "ParchmentDoc", Vector3(0.28, 0.02, 0.38), Vector3(0, 0.06, 0), mat_paper)
			
			# Drawer HouseClueInteractable
			var drawer_clue = HouseClueInteractableScript.new()
			drawer_clue.name = "DrawerClueInteractable"
			drawer_clue.clue_id = current_house_data.get("clue_id", "")
			drawer_clue.is_drawer = true
			drawer_clue.drawer_target_node = drawer_mesh_node
			drawer_clue.prompt_text = "[E] Open " + current_house_data.get("object_name", "Bedside Nightstand Drawer")
			drawer_clue.document_title = current_house_data.get("document_title", "")
			drawer_clue.document_subtitle = current_house_data.get("document_subtitle", "")
			drawer_clue.document_body = current_house_data.get("document_body", "")
			drawer_clue.secret_summary = current_house_data.get("secret_summary", "")

			var col := CollisionShape3D.new()
			col.name = "DrawerColShape"
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.65, 0.5, 0.8)
			col.shape = shape
			col.position = Vector3(-0.55, 0.62, 0.2)
			drawer_clue.add_child(col)
			desk.add_child(drawer_clue)

		"purple_herbs":
			# ===================================================================
			# ELORA NIGHTSHADE (Massive Stashes of Purple Herbs & Poison Log)
			# User requirement: "inside her house we can find huge stashes of purple herbs"
			# ===================================================================
			var herb_station := Node3D.new()
			herb_station.name = "HerbWorkshop"
			herb_station.position = Vector3(2.4, 0, 0.4)
			herb_station.rotation_degrees.y = -90.0
			puzzle_root.add_child(herb_station)

			_create_static_box(herb_station, "Bench", Vector3(2.0, 0.82, 0.85), Vector3(0, 0.41, 0), mat_desk)

			# Stashes of Purple Nightshade Herbs (Glowing Violet / Purple)
			var mat_purple := StandardMaterial3D.new()
			mat_purple.albedo_color = Color(0.55, 0.12, 0.75) # Vivid Purple
			mat_purple.emission_enabled = true
			mat_purple.emission = Color(0.65, 0.18, 0.85)
			mat_purple.emission_energy_multiplier = 2.2
			mat_purple.roughness = 0.6

			# Multiple large bundles / stashes of purple blossoms
			for px in [-0.65, -0.4, 0.4, 0.65]:
				for pz in [-0.15, 0.15]:
					_create_box(herb_station, "PurpleHerbBundle", Vector3(0.22, 0.28, 0.22), Vector3(px, 0.96, pz), mat_purple)
			
			# Drying rack above workbench with hanging purple herbs
			_create_box(herb_station, "DryingRack", Vector3(1.8, 0.05, 0.05), Vector3(0, 1.85, 0), mat_desk)
			for hx in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				_create_box(herb_station, "HangingPurpleHerb", Vector3(0.12, 0.35, 0.12), Vector3(hx, 1.62, 0), mat_purple)

			# Violet point light casting purple aura over room
			var purple_light := OmniLight3D.new()
			purple_light.name = "PurpleLight"
			purple_light.light_color = Color(0.7, 0.25, 0.95)
			purple_light.light_energy = 2.0
			purple_light.omni_range = 4.0
			purple_light.position = Vector3(0, 1.2, 0)
			herb_station.add_child(purple_light)

			# Compounding ledger & inspectable paper
			_create_box(herb_station, "DispensaryLedger", Vector3(0.35, 0.04, 0.45), Vector3(0, 0.85, 0), mat_paper)
			
			var herb_clue = HouseClueInteractableScript.new()
			herb_clue.name = "HerbInteractable"
			herb_clue.clue_id = current_house_data.get("clue_id", "")
			herb_clue.prompt_text = "[E] Inspect Stashes of Purple Nightshade & Poison Log"
			herb_clue.document_title = current_house_data.get("document_title", "")
			herb_clue.document_subtitle = current_house_data.get("document_subtitle", "")
			herb_clue.document_body = current_house_data.get("document_body", "")
			herb_clue.secret_summary = current_house_data.get("secret_summary", "")

			var col := CollisionShape3D.new()
			col.name = "HerbColShape"
			var shape := BoxShape3D.new()
			shape.size = Vector3(2.2, 1.2, 1.2)
			col.shape = shape
			col.position = Vector3(0, 1.0, 0)
			herb_clue.add_child(col)
			herb_station.add_child(herb_clue)

		"hidden_stash":
			# ===================================================================
			# LENA VANCE (Stolen Valuables / Victim's Coins & Signet Ring)
			# User requirement: "some of the victims belongings like coins and other stuff can be found at her home"
			# ===================================================================
			var stash_spot := Node3D.new()
			stash_spot.name = "HiddenFloorboardStash"
			stash_spot.position = Vector3(-2.2, 0.02, 1.6)
			puzzle_root.add_child(stash_spot)

			# Displaced floorboard panel
			_create_box(stash_spot, "LooseBoard", Vector3(0.85, 0.04, 0.45), Vector3(0, 0.02, 0), mat_desk)
			
			# Golden velvet pouch & jewelry mesh
			var mat_gold := StandardMaterial3D.new(); mat_gold.albedo_color = Color(0.95, 0.78, 0.15); mat_gold.metallic = 0.9; mat_gold.roughness = 0.3
			var mat_velvet := StandardMaterial3D.new(); mat_velvet.albedo_color = Color(0.45, 0.08, 0.12)
			_create_box(stash_spot, "ValeCoinPouch", Vector3(0.24, 0.12, 0.22), Vector3(-0.15, 0.08, 0), mat_velvet)
			_create_box(stash_spot, "AldricSignetRing", Vector3(0.08, 0.04, 0.08), Vector3(0.18, 0.06, 0.05), mat_gold)

			var stash_clue = HouseClueInteractableScript.new()
			stash_clue.name = "StashInteractable"
			stash_clue.clue_id = current_house_data.get("clue_id", "")
			stash_clue.prompt_text = "[E] Inspect Hidden Floorboard Stash (Victim's Belongings)"
			stash_clue.document_title = current_house_data.get("document_title", "")
			stash_clue.document_subtitle = current_house_data.get("document_subtitle", "")
			stash_clue.document_body = current_house_data.get("document_body", "")
			stash_clue.secret_summary = current_house_data.get("secret_summary", "")

			var col := CollisionShape3D.new()
			col.name = "StashColShape"
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.2, 0.6, 1.0)
			col.shape = shape
			col.position = Vector3(0, 0.25, 0)
			stash_clue.add_child(col)
			stash_spot.add_child(stash_clue)

		_:
			# ===================================================================
			# PRIMARY DESK DOSSIER FOR GARRICK, CORIN, FINN, ISOLDE, OSWIN, MAYOR
			# ===================================================================
			var study_desk := Node3D.new()
			study_desk.name = "StudyDesk"
			study_desk.position = Vector3(2.4, 0, 0.4)
			study_desk.rotation_degrees.y = -90.0
			puzzle_root.add_child(study_desk)

			_create_static_box(study_desk, "DeskTop", Vector3(1.6, 0.08, 0.85), Vector3(0, 0.82, 0), mat_desk)
			_create_static_box(study_desk, "DeskLegL", Vector3(0.10, 0.78, 0.75), Vector3(-0.70, 0.39, 0), mat_desk)
			_create_static_box(study_desk, "DeskLegR", Vector3(0.10, 0.78, 0.75), Vector3(0.70, 0.39, 0), mat_desk)

			# The Secret Dossier / Ledger on table
			_create_box(study_desk, "DocumentMesh", Vector3(0.40, 0.03, 0.50), Vector3(0, 0.88, 0), mat_paper)
			_create_box(study_desk, "WaxSeal", Vector3(0.08, 0.02, 0.08), Vector3(0.12, 0.90, 0.15), mat_glow)

			var desk_clue = HouseClueInteractableScript.new()
			desk_clue.name = "DocumentInteractable"
			desk_clue.clue_id = current_house_data.get("clue_id", "")
			desk_clue.prompt_text = "[E] Inspect " + current_house_data.get("document_title", "Secret Document")
			desk_clue.document_title = current_house_data.get("document_title", "")
			desk_clue.document_subtitle = current_house_data.get("document_subtitle", "")
			desk_clue.document_body = current_house_data.get("document_body", "")
			desk_clue.secret_summary = current_house_data.get("secret_summary", "")

			var col := CollisionShape3D.new()
			col.name = "DeskColShape"
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.8, 1.0, 1.2)
			col.shape = shape
			col.position = Vector3(0, 0.9, 0)
			desk_clue.add_child(col)
			study_desk.add_child(desk_clue)

# ===========================================================================
# 4. SCATTERED EVIDENCE PAPERS & LEDGERS
# ===========================================================================
func _build_scattered_papers() -> void:
	var papers_root := Node3D.new()
	papers_root.name = "ScatteredEvidencePapers"
	add_child(papers_root)

	var papers: Array = current_house_data.get("scattered_papers", [])
	var mat_paper := StandardMaterial3D.new()
	mat_paper.albedo_color = Color(0.93, 0.89, 0.78)
	mat_paper.roughness = 0.95
	
	var mat_seal := StandardMaterial3D.new()
	mat_seal.albedo_color = Color(0.75, 0.20, 0.15) # Red wax seal
	mat_seal.roughness = 0.4

	for i in range(papers.size()):
		var p_data: Dictionary = papers[i]
		var pos: Vector3 = p_data.get("pos", Vector3.ZERO)
		var rot_y: float = p_data.get("rot_y", 0.0)

		var paper_node := Node3D.new()
		paper_node.name = "ScatteredPaper_%d" % i
		paper_node.position = pos
		paper_node.rotation_degrees.y = rot_y
		papers_root.add_child(paper_node)

		# 3D Stack of Parchment Sheets
		_create_box(paper_node, "ParchmentMesh", Vector3(0.32, 0.02, 0.24), Vector3(0, 0.01, 0), mat_paper)
		# Red wax seal on the document
		_create_box(paper_node, "WaxSeal", Vector3(0.06, 0.025, 0.06), Vector3(0.08, 0.022, 0.05), mat_seal)

		# Clue Interactable Area3D
		var clue_area = HouseClueInteractableScript.new()
		clue_area.name = "ClueInteractable"
		clue_area.clue_id = p_data.get("clue_id", "")
		clue_area.prompt_text = p_data.get("prompt", "[E] Inspect Document")
		clue_area.document_title = p_data.get("title", "INVESTIGATION NOTE")
		clue_area.document_subtitle = p_data.get("subtitle", "Hollow Creek Clue")
		clue_area.document_body = p_data.get("body", "")
		clue_area.secret_summary = p_data.get("summary", "")

		var col := CollisionShape3D.new()
		col.name = "PaperColShape"
		var box := BoxShape3D.new()
		box.size = Vector3(0.55, 0.45, 0.45)
		col.shape = box
		col.position = Vector3(0, 0.15, 0)
		clue_area.add_child(col)

		paper_node.add_child(clue_area)
		print("[HouseInterior] Spawned scattered evidence paper '%s' at %s" % [clue_area.document_title, pos])

# ===========================================================================
# 5. FIRST-PERSON PLAYER SETUP
# ===========================================================================
func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	if player_scene:
		var p_inst = player_scene.instantiate()
		p_inst.name = "Player"
		# Spawn at entrance looking North into the medieval living room
		p_inst.position = Vector3(0.0, 0.2, 2.0)
		p_inst.rotation_degrees.y = 180.0
		add_child(p_inst)
		player_controller = p_inst as PlayerController
		print("[HouseInterior] Player instantiated at entrance facing room.")
	else:
		push_error("[HouseInterior] ERROR: Failed to load res://scenes/player.tscn")

# ===========================================================================
# 6. DOCUMENT INSPECTION MODAL UI
# ===========================================================================
func _setup_inspection_ui() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "InteriorHUD"
	hud_canvas.layer = 15
	add_child(hud_canvas)

	# Atmospheric House Title Banner at top
	var banner := Label.new()
	banner.text = current_house_data.get("house_title", "Villager's House") + "  •  Explore & Inspect Evidence"
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.position.y = 16
	banner.custom_minimum_size.y = 32
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 15)
	banner.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7, 0.8))
	hud_canvas.add_child(banner)

	# Document reader parchment popup modal
	doc_modal_panel = PanelContainer.new()
	doc_modal_panel.name = "DocumentModal"
	doc_modal_panel.visible = false
	doc_modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	doc_modal_panel.position = Vector2(-360, -280)
	doc_modal_panel.size = Vector2(720, 560)
	hud_canvas.add_child(doc_modal_panel)

	# Parchment styling
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.96)
	style.border_color = Color(0.85, 0.68, 0.28, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 28; style.content_margin_right = 28
	style.content_margin_top = 22; style.content_margin_bottom = 22
	doc_modal_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	doc_modal_panel.add_child(vbox)

	doc_title_label = Label.new()
	doc_title_label.add_theme_font_size_override("font_size", 18)
	doc_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	doc_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(doc_title_label)

	doc_subtitle_label = Label.new()
	doc_subtitle_label.add_theme_font_size_override("font_size", 13)
	doc_subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	doc_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(doc_subtitle_label)

	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 14)
	vbox.add_child(sep1)

	doc_body_label = RichTextLabel.new()
	doc_body_label.bbcode_enabled = true
	doc_body_label.custom_minimum_size = Vector2(660, 310)
	doc_body_label.add_theme_font_size_override("normal_font_size", 14)
	doc_body_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.80))
	vbox.add_child(doc_body_label)

	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 12)
	vbox.add_child(sep2)

	doc_discovery_label = Label.new()
	doc_discovery_label.add_theme_font_size_override("font_size", 13)
	doc_discovery_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.45)) # Green clue alert
	doc_discovery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(doc_discovery_label)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	close_doc_btn = Button.new()
	close_doc_btn.text = "Take Note & Return to Room  [Space / ESC]"
	close_doc_btn.custom_minimum_size = Vector2(300, 38)
	close_doc_btn.pressed.connect(close_document_reader)
	btn_hbox.add_child(close_doc_btn)

func open_document_reader(title: String, subtitle: String, body: String, summary: String, c_id: String) -> void:
	is_inspecting_doc = true
	if player_controller:
		player_controller.can_move = false
		player_controller.release_mouse()

	doc_title_label.text = title
	doc_subtitle_label.text = subtitle
	doc_body_label.text = body
	doc_discovery_label.text = "[DISCOVERY LOGGED]: " + summary

	doc_modal_panel.visible = true

	# Register discovered clue in MysteryGameState if available
	if not c_id.is_empty():
		var mg = get_tree().root.get_node_or_null("Town/MysteryGameState")
		if not mg and MysteryGameState.instance:
			mg = MysteryGameState.instance
		if mg and mg.has_method("discover_clue"):
			mg.discover_clue(c_id)
		print("[HouseInterior] Discovered Clue Registered: %s" % c_id)

func close_document_reader() -> void:
	is_inspecting_doc = false
	doc_modal_panel.visible = false
	if player_controller:
		player_controller.can_move = true
		player_controller.capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if is_inspecting_doc:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
			close_document_reader()
			get_viewport().set_input_as_handled()

# ===========================================================================
# 7. RETURN TO VILLAGE TRANSITION
# ===========================================================================
func return_to_village() -> void:
	print("[HouseInterior] Returning player to Hollow Creek village...")
	HouseInteriorManager.is_inside_house = false
	
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade)
	get_tree().root.add_child(canvas)

	var tween := canvas.create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	tween.tween_callback(func():
		var err := get_tree().change_scene_to_file("res://scenes/town.tscn")
		if err != OK:
			print("ERROR: Failed to load town.tscn Code: ", err)
		canvas.queue_free()
	)

# ===========================================================================
# 8. LIGHTING & ATMOSPHERE
# ===========================================================================
func _setup_lighting_and_audio() -> void:
	# Subtle room ambient light
	var amb_light := OmniLight3D.new()
	amb_light.name = "CentralRoomLantern"
	amb_light.light_color = Color(1.0, 0.82, 0.6)
	amb_light.light_energy = 1.3
	amb_light.omni_range = 8.5
	amb_light.position = Vector3(0, 2.7, 0)
	add_child(amb_light)

	# Procedural audio stream player
	var audio_player := AudioStreamPlayer.new()
	audio_player.name = "HearthAtmosphereAudio"
	audio_player.volume_db = -10.0
	audio_player.bus = &"Master"
	add_child(audio_player)

# ===========================================================================
# GEOMETRY HELPERS
# ===========================================================================
func _create_box(parent: Node, b_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = b_name
	var box := BoxMesh.new(); box.size = size; mi.mesh = box
	if mat: mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _create_static_box(parent: Node, b_name: String, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = b_name
	sb.position = pos
	parent.add_child(sb)

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = size; mi.mesh = box
	if mat: mi.material_override = mat
	sb.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new(); shape.size = size; col.shape = shape
	sb.add_child(col)
	return sb
