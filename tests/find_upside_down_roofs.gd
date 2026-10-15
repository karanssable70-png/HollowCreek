extends SceneTree

func _init() -> void:
	_analyze.call_deferred()

func _analyze() -> void:
	print("\n=======================================================")
	print("=== ROOF ORIENTATION & PITCH DIRECTION CHECK ===")
	print("=======================================================\n")
	
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	var town: Node = town_scene.instantiate()
	root.add_child(town)
	
	await process_frame
	await process_frame
	
	var roofs: Array[Dictionary] = []
	_find_roof_nodes(town, roofs)
	
	print("Found %d roof/shed/porch/dormer mesh nodes.\n" % roofs.size())
	
	for r in roofs:
		var mi: MeshInstance3D = r["node"]
		var path: String = r["path"]
		var g_tf: Transform3D = mi.global_transform
		var mesh: Mesh = mi.mesh
		
		var verts: Array[Vector3] = []
		if mesh is ArrayMesh:
			var am := mesh as ArrayMesh
			for s in range(am.get_surface_count()):
				var arrays := am.surface_get_arrays(s)
				var v_arr: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				for v in v_arr:
					verts.append(g_tf * v)
		elif mesh is BoxMesh or mesh is PrimitiveMesh:
			var aabb := mesh.get_aabb()
			for cx in [-0.5, 0.5]:
				for cy in [-0.5, 0.5]:
					for cz in [-0.5, 0.5]:
						var lv := aabb.position + aabb.size * Vector3(cx + 0.5, cy + 0.5, cz + 0.5)
						verts.append(g_tf * lv)
		
		if verts.is_empty():
			continue
			
		var min_y := 1e9
		var max_y := -1e9
		var min_pt := Vector3.ZERO
		var max_pt := Vector3.ZERO
		
		for v in verts:
			if v.y < min_y:
				min_y = v.y
				min_pt = v
			if v.y > max_y:
				max_y = v.y
				max_pt = v
		
		var center := Vector3.ZERO
		for v in verts:
			center += v
		center /= float(verts.size())
		
		# Let's inspect the building parent
		var building: Node = mi.get_parent()
		var b_pos: Vector3 = center
		if building is Node3D:
			b_pos = (building as Node3D).global_position
		
		# For Shed/Porch roofs: check whether it slopes away from the building or towards the building!
		var lpath := path.to_lower()
		var is_shed_or_porch := ("shed" in lpath or "porch" in lpath) and not ("post" in lpath or "deck" in lpath or "step" in lpath)
		
		if is_shed_or_porch:
			# Find edge closest to building center vs furthest from building center
			var d_min := 1e9
			var d_max := -1e9
			var v_near := Vector3.ZERO
			var v_far := Vector3.ZERO
			for v in verts:
				var dist := Vector2(v.x - b_pos.x, v.z - b_pos.z).length()
				if dist < d_min:
					d_min = dist
					v_near = v
				if dist > d_max:
					d_max = dist
					v_far = v
					
			var slope_status := "OK (slopes away)"
			if v_near.y < v_far.y:
				slope_status = "!!! INVERTED / UPSIDE DOWN (slopes towards building! Wall Y=%.2f < Outer Y=%.2f) !!!" % [v_near.y, v_far.y]
				
			print("SHED/PORCH: %s" % path)
			print("   Wall edge Y: %.2f (dist %.2f) | Outer edge Y: %.2f (dist %.2f)" % [v_near.y, d_min, v_far.y, d_max])
			print("   Status: %s\n" % slope_status)
			
		# For Dormer roofs:
		var is_dormer := "dormer" in lpath and ("droof" in lpath or "roof" in lpath)
		if is_dormer:
			# Check ridge orientation: does ridge point towards building or sideways?
			# Find highest points
			var top_pts: Array[Vector3] = []
			for v in verts:
				if v.y > max_y - 0.05:
					top_pts.append(v)
			var ridge_dir := Vector3.ZERO
			if top_pts.size() >= 2:
				ridge_dir = (top_pts[0] - top_pts[-1]).normalized()
			print("DORMER ROOF: %s" % path)
			print("   Y range: [%.2f, %.2f] | Top points count: %d | Ridge dir: %s" % [min_y, max_y, top_pts.size(), ridge_dir])
			print("   Local rot: %s | Global rot: %s\n" % [mi.rotation_degrees, g_tf.basis.get_euler() * (180.0/PI)])
			
		# For Pitched roofs (like SlopeL/SlopeR or Main roofs):
		var is_slope := "slope" in lpath
		if is_slope:
			var parent_roof := mi.get_parent() as Node3D
			var roof_pos := parent_roof.global_position if parent_roof else center
			var d_min := 1e9
			var d_max := -1e9
			var v_inner := Vector3.ZERO
			var v_outer := Vector3.ZERO
			for v in verts:
				var dist := Vector2(v.x - roof_pos.x, v.z - roof_pos.z).length()
				if dist < d_min:
					d_min = dist
					v_inner = v
				if dist > d_max:
					d_max = dist
					v_outer = v
			var status := "OK"
			if v_inner.y < v_outer.y:
				status = "!!! INVERTED / FUNNEL (Inner ridge Y=%.2f < Outer eave Y=%.2f) !!!" % [v_inner.y, v_outer.y]
			print("SLOPE: %s" % path)
			print("   Inner Y: %.2f | Outer Y: %.2f | Status: %s\n" % [v_inner.y, v_outer.y, status])
			
		# For Gables
		var is_gable := "gable" in lpath
		if is_gable:
			print("GABLE: %s | Y: [%.2f, %.2f] | Pos: %s | Rot: %s" % [path, min_y, max_y, mi.position, mi.rotation_degrees])

	town.queue_free()
	quit(0)

func _find_roof_nodes(node: Node, out: Array[Dictionary]) -> void:
	if node is MeshInstance3D and node.is_visible_in_tree():
		var lp: String = node.name.to_lower()
		var pp: String = node.get_parent().name.to_lower() if node.get_parent() != null else ""
		if any_kw(lp) or any_kw(pp):
			out.append({"node": node, "path": str(node.get_path())})
	for c in node.get_children():
		_find_roof_nodes(c, out)

func any_kw(s: String) -> bool:
	for kw in ["roof", "dormer", "spire", "slope", "shed", "porch", "bayroof", "gable"]:
		if kw in s:
			return true
	return false
