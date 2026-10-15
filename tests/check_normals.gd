extends SceneTree

func _init() -> void:
	print("\n=== CHECKING MESH NORMALS ===")
	for path in [
		"res://resources/roofs/meshes/mesh_roof_inn.tres",
		"res://resources/roofs/meshes/mesh_roof_porch_inn.tres",
		"res://resources/roofs/meshes/mesh_roof_shed_forge.tres",
		"res://resources/roofs/meshes/mesh_roof_dormer.tres"
	]:
		var m: ArrayMesh = load(path)
		if m == null:
			print("Could not load ", path)
			continue
		var arrays = m.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var up_count := 0
		var down_count := 0
		for n in norms:
			if n.y > 0.05:
				up_count += 1
			elif n.y < -0.05:
				down_count += 1
		print("%s -> %d verts, %d normals (Up: %d, Down: %d)" % [
			path.get_file(), verts.size(), norms.size(), up_count, down_count
		])
	quit(0)
