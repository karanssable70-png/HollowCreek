extends SceneTree

var report_file: FileAccess = null

func _init() -> void:
	report_file = FileAccess.open("res://roofs_report.txt", FileAccess.WRITE)
	log_line("\n=== INSPECTING ALL ROOFS IN TOWN SCENE ===")
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	var town = town_scene.instantiate()
	
	_inspect_node_recursive(town, "")
	
	log_line("\n=== INSPECTING COMPLETED ===")
	report_file.close()
	quit(0)

func log_line(msg: String) -> void:
	print(msg)
	if report_file:
		report_file.store_line(msg)

func _inspect_node_recursive(node: Node, path: String) -> void:
	var current_path = path + "/" + node.name if not path.is_empty() else node.name
	
	# Check if node name relates to roof
	var n_lower = node.name.to_lower()
	if "roof" in n_lower or "dormer" in n_lower or "spire" in n_lower or "eave" in n_lower or "gable" in n_lower or "slope" in n_lower:
		if node is Node3D:
			var node3d := node as Node3D
			var rot_deg = node3d.rotation_degrees
			var g_rot = node3d.global_rotation_degrees
			var scale = node3d.scale
			
			var mesh_info = ""
			if node is MeshInstance3D:
				var mi := node as MeshInstance3D
				if mi.mesh:
					var aabb := mi.mesh.get_aabb()
					mesh_info = " Mesh: %s AABB min_y=%.2f max_y=%.2f center_y=%.2f size=%s" % [
						mi.mesh.get_class(), aabb.position.y, aabb.position.y + aabb.size.y, aabb.position.y + aabb.size.y*0.5, aabb.size
					]
					
					# Check vertex normals if ArrayMesh
					if mi.mesh is ArrayMesh:
						var am := mi.mesh as ArrayMesh
						if am.get_surface_count() > 0:
							var arrays = am.surface_get_arrays(0)
							var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
							var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
							if normals.size() > 0:
								var up_count = 0
								var down_count = 0
								for n in normals:
									if n.y > 0.1:
										up_count += 1
									elif n.y < -0.1:
										down_count += 1
								mesh_info += " [Normals: up=%d, down=%d]" % [up_count, down_count]
							
							# Check if vertices at higher Y are narrower (pitched roof) or wider (upside down pyramid!)
							if verts.size() > 0:
								var min_y = 999999.0
								var max_y = -999999.0
								for v in verts:
									if v.y < min_y: min_y = v.y
									if v.y > max_y: max_y = v.y
								mesh_info += " [Verts Y: %.2f to %.2f]" % [min_y, max_y]
			
			log_line("ROOF NODE: %s | Pos: %s | Rot: %s | Scale: %s | %s" % [
				current_path, node3d.position, rot_deg, scale, mesh_info
			])
			
	for child in node.get_children():
		_inspect_node_recursive(child, current_path)
