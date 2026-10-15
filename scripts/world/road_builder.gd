class_name RoadBuilder
extends RefCounted

## RoadBuilder
## Constructs an interconnected medieval stone road and path network matching
## the town layout sketches (Central City Bazaar, Western Loop via Lady X's house,
## Eastern Manor branch, and South-Western Harbour descent).
## All roads, slabs, and border stones are firmly grounded into the terrain
## with zero floating or levitation.

var materials: Dictionary = {}

func _init(mats: Dictionary = {}) -> void:
	materials = mats
	_ensure_materials()

## Ensures all required stone and accent materials exist in the dictionary.
func _ensure_materials() -> void:
	if not materials.has("stone_main"):
		materials["stone_main"] = _make_stone_mat(Color(0.42, 0.40, 0.38))
	if not materials.has("stone_warm"):
		materials["stone_warm"] = _make_stone_mat(Color(0.48, 0.44, 0.38))
	if not materials.has("stone_dark"):
		materials["stone_dark"] = _make_stone_mat(Color(0.32, 0.30, 0.28))
	if not materials.has("stone_tan"):
		materials["stone_tan"] = _make_stone_mat(Color(0.52, 0.48, 0.40))
	if not materials.has("stone_moss"):
		materials["stone_moss"] = _make_stone_mat(Color(0.35, 0.42, 0.32))
	if not materials.has("stone_border"):
		materials["stone_border"] = _make_stone_mat(Color(0.38, 0.36, 0.34))
	if not materials.has("bush"):
		materials["bush"] = _make_stone_mat(Color(0.25, 0.45, 0.20))

## Helper to create a StandardMaterial3D with stone roughness.
func _make_stone_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	return mat

## Public API: Builds the entire road and path network under the given parent node.
func build_road_network(parent: Node3D) -> void:
	var network := Node3D.new()
	network.name = "RoadNetwork"
	parent.add_child(network)
	
	_build_main_entrance_road(network)
	_build_village_square_paving(network)
	_build_western_loop_road(network)
	_build_lantern_inn_road(network)
	_build_garricks_forge_road(network)
	_build_town_hall_road(network)
	_build_harbour_road(network)
	_build_clinic_path(network)
	_build_old_storehouse_path(network)
	_build_doctor_and_cop_paths(network)
	_build_path_end_transitions(network)

# ==============================================================================
# ROAD SEGMENTS IMPLEMENTATION (Grounded flush with terrain)
# ==============================================================================

## 1. Main entrance road: wide (~5m) descending from mountain pass down into Bazaar.
func _build_main_entrance_road(network: Node3D) -> void:
	var mat: Material = materials["stone_main"]
	# Pass entrance (Z=-48) to gate area (Z=-34) at height 1.81 (sunk 3cm into 1.80 pass floor)
	_build_road_segment(network, "RoadEntrance_Gate", Vector3(0.0, 1.81, -48.0), Vector3(0.0, 1.81, -34.0), 5.0, mat, true)
	# Gate area down toward the central fork along the embankment slope
	_build_road_segment(network, "RoadEntrance_Slope", Vector3(0.0, 1.81, -34.0), Vector3(0.0, 1.15, -22.0), 5.0, mat, true)
	# Fork down to the northern edge of the City Bazaar
	_build_road_segment(network, "RoadEntrance_ToSquare", Vector3(0.0, 1.15, -22.0), Vector3(0.0, 0.61, -10.0), 5.0, mat, true)
	# Decorative slabs near the mountain entrance gate
	_build_intersection_stones(network, Vector3(0.0, 1.82, -34.0), 2.8)

## 2. City Bazaar / Village Square paving: ~27m diameter cobblestone plaza firmly embedded into plateau.
func _build_village_square_paving(network: Node3D) -> void:
	var square := Node3D.new()
	square.name = "VillageSquarePlaza"
	# Positioned at Y = 0.61 so bottom is at 0.57 (sunk 3cm into 0.60 grass plateau)
	square.position = Vector3(0.0, 0.61, 0.0)
	network.add_child(square)
	
	# Main cobblestone circular plaza mesh
	var mi := MeshInstance3D.new()
	mi.name = "PlazaMesh"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 13.5
	cyl.bottom_radius = 13.5
	cyl.height = 0.08
	cyl.radial_segments = 32
	mi.mesh = cyl
	mi.material_override = materials["stone_main"]
	square.add_child(mi)
	
	# Single cylinder collision body
	var sb := StaticBody3D.new()
	sb.name = "Collision"
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 13.5
	shape.height = 0.08
	col.shape = shape
	sb.add_child(col)
	square.add_child(sb)
	
	# Darker border stones ring around plaza edge (embedded into grass)
	var border_mat: Material = materials["stone_border"]
	var ring_radius := 13.4
	for i in range(14):
		var angle := float(i) * TAU / 14.0
		var stone := MeshInstance3D.new()
		stone.name = "SquareBorder_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(0.4, 0.12, 0.6)
		stone.mesh = box
		stone.material_override = border_mat
		stone.position = Vector3(cos(angle) * ring_radius, 0.02, sin(angle) * ring_radius)
		stone.rotation.y = -angle
		square.add_child(stone)
	
	# Stone slabs scattered near center around the village well
	var well_slabs := [
		{"pos": Vector3(1.7, 0.045, 0.9), "size": Vector3(1.2, 0.03, 0.9), "rot": 18.0, "mat": materials["stone_warm"]},
		{"pos": Vector3(-1.8, 0.045, 0.5), "size": Vector3(1.3, 0.03, 1.0), "rot": -25.0, "mat": materials["stone_dark"]},
		{"pos": Vector3(0.4, 0.045, -1.9), "size": Vector3(1.1, 0.03, 1.15), "rot": 40.0, "mat": materials["stone_tan"]},
		{"pos": Vector3(-0.9, 0.045, -1.7), "size": Vector3(1.0, 0.03, 0.85), "rot": -12.0, "mat": materials["stone_warm"]}
	]
	for idx in range(well_slabs.size()):
		var slab_data: Dictionary = well_slabs[idx]
		var slab := MeshInstance3D.new()
		slab.name = "WellSlab_%d" % idx
		var box := BoxMesh.new()
		box.size = slab_data["size"]
		slab.mesh = box
		slab.material_override = slab_data["mat"]
		slab.position = slab_data["pos"]
		slab.rotation_degrees.y = slab_data["rot"]
		square.add_child(slab)

## 3. Western Loop Road ("Lady X's Road"): Sweeping curved road from pass gate around west side.
func _build_western_loop_road(network: Node3D) -> void:
	var mat: Material = materials["stone_warm"]
	# Branch from gate west past Innkeeper's House
	_build_road_segment(network, "PathWeaver", Vector3(0.0, 1.81, -33.0), Vector3(-14.0, 1.15, -23.0), 3.8, mat, true)
	# Continue curving past Lady X's House down to The Inn
	_build_road_segment(network, "RoadWestLoop_Seg2", Vector3(-14.0, 1.15, -23.0), Vector3(-25.0, 0.75, -14.0), 3.8, mat, true)
	_build_road_segment(network, "RoadWestLoop_Seg3", Vector3(-25.0, 0.75, -14.0), Vector3(-23.0, 0.61, -3.0), 3.8, mat, true)

## 4. Road to The Inn: ~4.2m wide connecting City Bazaar west edge to The Inn front terrace.
func _build_lantern_inn_road(network: Node3D) -> void:
	var mat: Material = materials["stone_main"]
	_build_road_segment(network, "RoadInn_Seg1", Vector3(-8.0, 0.61, -1.0), Vector3(-16.0, 0.61, -1.8), 4.2, mat, true)
	_build_road_segment(network, "RoadInn_Seg2", Vector3(-16.0, 0.61, -1.8), Vector3(-23.5, 0.61, -2.5), 4.2, mat, true)

## 5. Road to Iron Works / Garrick's Forge: curves north-east along entrance fork.
func _build_garricks_forge_road(network: Node3D) -> void:
	var mat: Material = materials["stone_main"]
	# Fork from entrance road heading east toward Physician's Clinic & Forge
	_build_road_segment(network, "RoadForge_Seg1", Vector3(0.0, 1.15, -22.0), Vector3(13.0, 0.95, -17.5), 4.0, mat, true)
	_build_road_segment(network, "RoadForge_Seg2", Vector3(13.0, 0.95, -17.5), Vector3(24.5, 0.81, -11.5), 4.0, mat, true)

## 6. Road to Mayor's Residence (Town Hall): broad avenue connecting Bazaar east edge.
func _build_town_hall_road(network: Node3D) -> void:
	_build_road_segment(network, "RoadTownHall", Vector3(8.0, 0.61, 1.5), Vector3(23.5, 0.78, 2.0), 4.8, materials["stone_warm"], true)

## 7. Road to Harbour: curves west/south-west descending to the coastal pier.
func _build_harbour_road(network: Node3D) -> void:
	# Upper descent departing Bazaar southwest
	_build_road_segment(network, "RoadHarbour_Upper", Vector3(-7.0, 0.61, 5.0), Vector3(-18.0, 0.46, 10.0), 4.0, materials["stone_main"], true)
	# Mid descent segment heading toward coast
	_build_road_segment(network, "RoadHarbour_Mid", Vector3(-18.0, 0.46, 10.0), Vector3(-30.0, 0.28, 13.0), 3.8, materials["stone_warm"], true)
	# Lower shore segment arriving at western harbour dock
	_build_road_segment(network, "RoadHarbour_Lower", Vector3(-30.0, 0.28, 13.0), Vector3(-41.0, 0.12, 14.5), 3.2, materials["stone_dark"], false)
	# Decorative intersection slabs at the coastal fork
	_build_intersection_stones(network, Vector3(-18.0, 0.47, 10.0), 2.4)

## 8. Secondary path to Physician's Clinic: dark weathered stone branch.
func _build_clinic_path(network: Node3D) -> void:
	_build_road_segment(network, "PathClinic", Vector3(11.5, 1.05, -18.0), Vector3(12.0, 0.88, -14.8), 3.0, materials["stone_dark"], false)

func _build_detective_office_path(network: Node3D) -> void:
	_build_clinic_path(network)

## 9. Secondary path to Harbor Master's House (Storehouse): near the western coast.
func _build_old_storehouse_path(network: Node3D) -> void:
	var mat: Material = materials["stone_tan"]
	_build_road_segment(network, "PathStorehouse_Seg1", Vector3(-24.0, 0.38, 11.5), Vector3(-28.0, 0.48, 16.0), 2.5, mat, false)
	_build_road_segment(network, "PathStorehouse_Seg2", Vector3(-28.0, 0.48, 16.0), Vector3(-30.0, 0.58, 19.5), 2.5, mat, false)

## 10. Southern paths: Cop Station and Doctor's Cottage (Elara).
func _build_doctor_and_cop_paths(network: Node3D) -> void:
	# Path from Bazaar south toward Doctor's cottage
	_build_road_segment(network, "PathMiller", Vector3(2.0, 0.61, 8.5), Vector3(4.0, 0.61, 18.5), 2.8, materials["stone_warm"], true)
	# Path toward Cop Station
	_build_road_segment(network, "PathFisherman", Vector3(-12.0, 0.61, 8.0), Vector3(-13.5, 0.61, 16.5), 2.6, materials["stone_moss"], false)
	# Stepping stone garden trail in front of Doctor's herbalist cottage
	_build_stepping_stones(network, Vector3(4.0, 0.61, 18.5), Vector3(4.0, 0.61, 22.0), 5, materials["stone_moss"])

## 11. Decorative stepping stone extensions.
func _build_path_end_transitions(network: Node3D) -> void:
	_build_stepping_stones(network, Vector3(-26.5, 0.72, -14.0), Vector3(-28.0, 0.68, -14.0), 3, materials["stone_warm"])
	_build_stepping_stones(network, Vector3(-13.5, 0.61, 16.5), Vector3(-14.0, 0.61, 18.0), 2, materials["stone_dark"])

# ==============================================================================
# ROAD CONSTRUCTION HELPERS (Embedded flush into soil)
# ==============================================================================

## Creates a single box mesh road segment between two points with a StaticBody3D collider.
func _build_road_segment(
	parent: Node3D,
	road_name: String,
	start: Vector3,
	end: Vector3,
	width: float,
	mat: Material,
	with_borders: bool = false
) -> void:
	var delta := end - start
	var len_xz := Vector2(delta.x, delta.z).length()
	if len_xz < 0.001:
		return
	var total_len := delta.length()
	var mid := (start + end) * 0.5
	var yaw := atan2(delta.x, delta.z)
	var pitch := -atan2(delta.y, len_xz)
	
	var segment := Node3D.new()
	segment.name = road_name
	segment.position = mid
	segment.rotation = Vector3(pitch, yaw, 0.0)
	parent.add_child(segment)
	
	# Main road slab (height 0.08, sunk 3cm into ground so top is 5cm above surface)
	var mi := MeshInstance3D.new()
	mi.name = "RoadMesh"
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.08, total_len)
	mi.mesh = box
	mi.material_override = mat
	segment.add_child(mi)
	
	# StaticBody3D with BoxShape3D collision
	var sb := StaticBody3D.new()
	sb.name = "Collision"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.08, total_len)
	col.shape = shape
	sb.add_child(col)
	segment.add_child(sb)
	
	if with_borders:
		_add_borders_to_segment(segment, width, total_len)

## Adds small stone border blocks and sparse grass tufts sunk firmly into road edges.
func _add_borders_to_segment(segment: Node3D, width: float, total_len: float) -> void:
	var spacing := 4.2
	var count := int(total_len / spacing)
	if count < 1:
		count = 1
	
	var border_mat: Material = materials["stone_border"]
	var bush_mat: Material = materials["bush"]
	var half_w := width * 0.5
	
	for i in range(count):
		var z_pos := -total_len * 0.5 + (float(i) + 0.5) * (total_len / float(count))
		
		# Left edge border block (size 0.4 x 0.15 x 0.25, sunk 5.5cm into ground)
		var stone_l := MeshInstance3D.new()
		stone_l.name = "BorderL_%d" % i
		var box_l := BoxMesh.new()
		box_l.size = Vector3(0.4, 0.15, 0.25)
		stone_l.mesh = box_l
		stone_l.material_override = border_mat
		stone_l.position = Vector3(-half_w, 0.02, z_pos)
		stone_l.rotation_degrees.y = sin(float(i) * 1.5) * 5.0
		segment.add_child(stone_l)
		
		# Right edge border block
		var stone_r := MeshInstance3D.new()
		stone_r.name = "BorderR_%d" % i
		var box_r := BoxMesh.new()
		box_r.size = Vector3(0.4, 0.15, 0.25)
		stone_r.mesh = box_r
		stone_r.material_override = border_mat
		stone_r.position = Vector3(half_w, 0.02, z_pos)
		stone_r.rotation_degrees.y = -sin(float(i) * 1.5) * 5.0
		segment.add_child(stone_r)
		
		# Small grass tuft embedded in soil next to border
		if i % 2 == 1:
			var tuft := MeshInstance3D.new()
			tuft.name = "Tuft_%d" % i
			var sph := SphereMesh.new()
			sph.radius = 0.10
			sph.height = 0.16
			sph.radial_segments = 5
			sph.rings = 3
			tuft.mesh = sph
			tuft.material_override = bush_mat
			tuft.position = Vector3(-half_w - 0.08, 0.02, z_pos + (spacing * 0.35))
			segment.add_child(tuft)

## Creates individual small stone slabs embedded into lawn/soil.
func _build_stepping_stones(parent: Node3D, start: Vector3, end: Vector3, count: int, mat: Material) -> void:
	var container := Node3D.new()
	container.name = "SteppingStones"
	parent.add_child(container)
	
	var delta := end - start
	var dir := delta.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x)
	
	for i in range(count):
		var t := (float(i) + 0.5) / float(count)
		var base_pos := start.lerp(end, t)
		var lateral_offset := sin(float(i) * 2.1) * 0.18
		var pos := base_pos + perp * lateral_offset
		# Sunk slightly into grass (height 0.05, center at ground surface)
		var mi := MeshInstance3D.new()
		mi.name = "Step_%d" % i
		var box := BoxMesh.new()
		var w := 0.70 + sin(float(i) * 1.3) * 0.12
		var l := 0.58 + cos(float(i) * 1.7) * 0.10
		box.size = Vector3(w, 0.05, l)
		mi.mesh = box
		mi.material_override = mat
		mi.position = pos
		mi.rotation_degrees.y = sin(float(i) * 2.7) * 18.0
		container.add_child(mi)

## Scatters a few larger decorative slabs flush with ground around an intersection.
func _build_intersection_stones(parent: Node3D, center: Vector3, radius: float) -> void:
	var container := Node3D.new()
	container.name = "IntersectionStones"
	container.position = center
	parent.add_child(container)
	
	var offsets := [
		Vector3(radius * 0.40, 0.015, radius * 0.30),
		Vector3(-radius * 0.35, 0.015, -radius * 0.25),
		Vector3(radius * 0.20, 0.015, -radius * 0.45)
	]
	var sizes := [
		Vector3(0.75, 0.05, 0.60),
		Vector3(0.85, 0.05, 0.70),
		Vector3(0.65, 0.05, 0.80)
	]
	var mats := [
		materials["stone_warm"],
		materials["stone_dark"],
		materials["stone_tan"]
	]
	
	for i in range(offsets.size()):
		var mi := MeshInstance3D.new()
		mi.name = "Slab_%d" % i
		var box := BoxMesh.new()
		box.size = sizes[i]
		mi.mesh = box
		mi.material_override = mats[i % mats.size()]
		mi.position = offsets[i]
		mi.rotation_degrees.y = float(i * 37 + 15)
		container.add_child(mi)
