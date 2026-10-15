extends SceneTree

func _init() -> void:
	_inspect_all.call_deferred()

func _inspect_all() -> void:
	print("\n================== DETAILED FBX CHARACTER ANALYSIS ==================")
	var files = [
		"Dockworker.fbx",
		"HarbourMaster.fbx",
		"Innkeeper.fbx",
		"killer.fbx",
		"Mayor.fbx",
		"Noblewoman.fbx",
		"Physician.fbx",
		"Victim.fbx"
	]
	
	for fname in files:
		var path = "res://assets/models/characters/" + fname
		var scn: PackedScene = load(path)
		if not scn:
			print("Could not load: ", path)
			continue
		var inst = scn.instantiate()
		root.add_child(inst)
		
		print("\n>>> CHARACTER: ", fname)
		var char_aabb = AABB()
		var first = true
		var non_char_nodes = []
		var char_nodes = []
		
		for child in inst.get_children():
			var nname = child.name.to_lower()
			if "camera" in nname or "floor" in nname or "backdrop" in nname or "label" in nname:
				non_char_nodes.append(child.name)
			else:
				char_nodes.append(child.name)
				if child is MeshInstance3D and child.mesh:
					var child_aabb = child.transform * child.mesh.get_aabb()
					if first:
						char_aabb = child_aabb
						first = false
					else:
						char_aabb = char_aabb.merge(child_aabb)
		
		print("  Non-character nodes (to strip): ", non_char_nodes)
		print("  Character mesh count: ", char_nodes.size())
		print("  Character Body Bounds: Y min=", "%.3f" % char_aabb.position.y, 
			  ", Y max=", "%.3f" % (char_aabb.position.y + char_aabb.size.y),
			  ", Height=", "%.3f" % char_aabb.size.y, "m",
			  ", Width=", "%.3f" % char_aabb.size.x, "m",
			  ", Depth=", "%.3f" % char_aabb.size.z, "m")
		print("  Body center XZ: (", "%.3f" % (char_aabb.position.x + char_aabb.size.x * 0.5), ", ", "%.3f" % (char_aabb.position.z + char_aabb.size.z * 0.5), ")")
		
		inst.queue_free()
		
	print("\n================== ANALYSIS COMPLETE ==================\n")
	quit(0)
