extends SceneTree

func _init() -> void:
	_diagnose.call_deferred()

func _diagnose() -> void:
	print("\n=======================================================")
	print("=== DEEP ROOF ORIENTATION & GEOMETRY DIAGNOSIS TOOL ===")
	print("=======================================================\n")
	
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	assert(town_scene != null, "Could not load res://scenes/town.tscn")
	var town: Node = town_scene.instantiate()
	root.add_child(town)
	
	await process_frame
	await process_frame
	
	var inspected_count := 0
	var upside_down_count := 0
	
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_meshes(town, mesh_instances)
	
	print("Total MeshInstance3D nodes in scene: %d" % mesh_instances.size())
	
	for mi in mesh_instances:
		var node_path := str(mi.get_path())
		var lower_path := node_path.to_lower()
		
		# Check if related to roof
		var is_roof := false
		for kw in ["roof", "dormer", "spire", "slope", "gable", "shed", "eave", "porch", "bay"]:
			if kw in lower_path:
				is_roof = true
				break
		
		if not is_roof:
			continue
		
		# Skip hidden nodes (like disabled box eaves)
		if not mi.is_visible_in_tree():
			continue
			
		inspected_count += 1
		
		var global_tf := mi.global_transform
		var basis := global_tf.basis
		var origin := global_tf.origin
		
		# Check basis determinant / scale
		var det := basis.determinant()
		var scale := basis.get_scale()
		var rot_deg := basis.get_euler() * (180.0 / PI)
		
		# Check mesh type and vertex positions
		var mesh := mi.mesh
		if mesh == null:
			continue
			
		# Analyze vertices in world coordinates
		var min_y := 1e9
		var max_y := -1e9
		var center := Vector3.ZERO
		var vertex_count := 0
		var world_verts: Array[Vector3] = []
		var world_normals: Array[Vector3] = []
		
		if mesh is ArrayMesh:
			var am := mesh as ArrayMesh
			for s in range(am.get_surface_count()):
				var arrays := am.surface_get_arrays(s)
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for i in range(verts.size()):
					var wv := global_tf * verts[i]
					world_verts.append(wv)
					min_y = minf(min_y, wv.y)
					max_y = maxf(max_y, wv.y)
					center += wv
					vertex_count += 1
				if norms.size() > 0:
					for n in norms:
						var wn := (basis.inverse().transposed() * n).normalized()
						world_normals.append(wn)
		elif mesh is BoxMesh or mesh is PrimitiveMesh:
			# Get corners from AABB
			var aabb := mesh.get_aabb()
			for cx in [-0.5, 0.5]:
				for cy in [-0.5, 0.5]:
					for cz in [-0.5, 0.5]:
						var lv := aabb.position + aabb.size * Vector3(cx + 0.5, cy + 0.5, cz + 0.5)
						var wv := global_tf * lv
						world_verts.append(wv)
						min_y = minf(min_y, wv.y)
						max_y = maxf(max_y, wv.y)
						center += wv
						vertex_count += 1
		
		if vertex_count > 0:
			center /= float(vertex_count)
			
		# Check for upside-down indications:
		# Indication A: Negative scale along Y (inverted Y)
		var is_inverted_y := (basis.y.y < -0.1)
		
		# Indication B: Determinant is negative (reflection / inside-out)
		var is_negative_det := (det < 0.0)
		
		# Indication C: For BoxMesh slopes (like SlopeL and SlopeR):
		# If the inner edge (closer to building center) has lower Y than outer edge (eave), it's a funnel (upside down V)!
		var is_funnel := false
		if "slope" in lower_path and mi.get_parent() != null:
			var parent_3d := mi.get_parent() as Node3D
			if parent_3d:
				var parent_center := parent_3d.global_position
				# Compare vertices closer to parent_center vs further from parent_center in horizontal distance
				var inner_y_sum := 0.0
				var inner_y_cnt := 0
				var outer_y_sum := 0.0
				var outer_y_cnt := 0
				for wv in world_verts:
					var horiz_d := Vector2(wv.x - parent_center.x, wv.z - parent_center.z).length()
					if horiz_d < 1.5:
						inner_y_sum += wv.y
						inner_y_cnt += 1
					elif horiz_d > 2.5:
						outer_y_sum += wv.y
						outer_y_cnt += 1
				if inner_y_cnt > 0 and outer_y_cnt > 0:
					var avg_inner_y = inner_y_sum / float(inner_y_cnt)
					var avg_outer_y = outer_y_sum / float(outer_y_cnt)
					if avg_inner_y < avg_outer_y - 0.2:
						is_funnel = true
		
		# Indication D: Inverted slope for Shed / Porch / Dormer:
		# Normal points down instead of up (e.g. dot with Vector3.UP < -0.2)
		var has_downward_bias := false
		if world_normals.size() > 0:
			var up_dot_sum := 0.0
			for wn in world_normals:
				up_dot_sum += wn.y
			var avg_norm_y := up_dot_sum / float(world_normals.size())
			if avg_norm_y < -0.3:
				has_downward_bias = true
		
		# Indication E: Check Dormer roof orientation!
		# A dormer roof peak should be horizontal and gable should point outward from the main roof!
		var dormer_issue := false
		if "dormer" in lower_path and ("droof" in lower_path or "roof" in lower_path):
			# Let's inspect its basis and angles
			var local_rot := mi.rotation_degrees
			var parent_rot := (mi.get_parent() as Node3D).rotation_degrees if mi.get_parent() is Node3D else Vector3.ZERO
			# Check if peak is pointing downward
			var top_pts: Array[Vector3] = []
			for wv in world_verts:
				if wv.y > max_y - 0.1:
					top_pts.append(wv)
			# Top points should form a line (the ridge)
		
		var is_suspicious := is_inverted_y or is_negative_det or is_funnel or has_downward_bias
		
		if is_suspicious:
			upside_down_count += 1
			print("[SUSPICIOUS / UPSIDE DOWN] %s" % node_path)
			print("   Mesh: %s | Y range: [%.2f, %.2f] (height=%.2f) | Center: %s" % [
				mesh.get_class(), min_y, max_y, max_y - min_y, center
			])
			print("   Pos: %s | Rot: %s | GlobalRot: %s | Scale: %s | Det: %.2f" % [
				mi.position, mi.rotation_degrees, rot_deg, scale, det
			])
			print("   Flags: inv_y=%s, neg_det=%s, funnel=%s, down_bias=%s" % [
				is_inverted_y, is_negative_det, is_funnel, has_downward_bias
			])
		else:
			# Print sample for normal roofs
			if "droof" in lower_path or "shed" in lower_path or "porch" in lower_path or "bay" in lower_path or "slope" in lower_path:
				print("[NORMAL] %s | Pos: %s | Rot: %s | Y: [%.2f, %.2f]" % [
					node_path, mi.position, mi.rotation_degrees, min_y, max_y
				])
				
	print("\nSummary: Inspected %d roof meshes. Found %d suspicious/upside-down meshes." % [
		inspected_count, upside_down_count
	])
	
	town.queue_free()
	quit(0)

func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for c in node.get_children():
		_collect_meshes(c, out)
