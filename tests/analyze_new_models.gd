extends SceneTree

func _init() -> void:
	_analyze.call_deferred()

func _analyze() -> void:
	print("\n================== ANALYZING 4 NEW FBX MODELS ==================")
	var configs = {
		"inspector": "res://assets/models/characters/Inspector.fbx",
		"elora": "res://assets/models/characters/herbalist.fbx",
		"corin": "res://assets/models/characters/bazaarguy.fbx",
		"tomas": "res://assets/models/characters/Townguard.fbx"
	}
	
	for key in configs:
		var path = configs[key]
		var scn: PackedScene = load(path)
		assert(scn != null, "Failed to load " + path)
		var raw = scn.instantiate()
		root.add_child(raw)
		
		print("\n--- Model: ", key, " (", path, ") ---")
		var full_aabb = AABB()
		var first = true
		
		for child in raw.get_children():
			var nname = child.name.to_lower()
			if "camera" in nname or "ground" in nname or "plinth" in nname or "label" in nname:
				print("  [IGNORE]: ", child.name)
				continue
			if child is MeshInstance3D and child.mesh:
				var m_aabb = child.transform * child.mesh.get_aabb()
				if first:
					full_aabb = m_aabb
					first = false
				else:
					full_aabb = full_aabb.merge(m_aabb)
				print("  [MESH]: ", child.name, " pos: ", child.position, " aabb_y: [", m_aabb.position.y, " to ", m_aabb.position.y + m_aabb.size.y, "]")
		
		print("  TOTAL BODY AABB: Y [", full_aabb.position.y, " to ", full_aabb.position.y + full_aabb.size.y, "] Height: ", full_aabb.size.y, "m")
		raw.queue_free()
		
	quit(0)
