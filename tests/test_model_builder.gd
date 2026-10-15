extends SceneTree

# Tests loading and organizing all 8 FBX models into animated NPC hierarchies
func _init() -> void:
	_test_models.call_deferred()

func _test_models() -> void:
	print("\n=== TESTING FBX MODEL EXTRACTION & PIVOT SETUP ===")
	
	var char_configs = {
		"finn": {"file": "Dockworker.fbx", "name": "Finn Mercer"},
		"garrick": {"file": "HarbourMaster.fbx", "name": "Garrick Thorne"},
		"lena": {"file": "Innkeeper.fbx", "name": "Lena Hart"},
		"mercenary": {"file": "killer.fbx", "name": "The Mercenary"},
		"oswin": {"file": "Mayor.fbx", "name": "Oswin Hale"},
		"isolde": {"file": "Noblewoman.fbx", "name": "Lady Isolde Ravenshade"},
		"edmund": {"file": "Physician.fbx", "name": "Edmund Wren"},
		"aldric": {"file": "Victim.fbx", "name": "Lord Aldric Vale"}
	}
	
	for cid in char_configs:
		var cfg = char_configs[cid]
		var fpath = "res://assets/models/characters/" + cfg["file"]
		var scn: PackedScene = load(fpath)
		assert(scn != null, "Could not load " + fpath)
		var raw = scn.instantiate()
		root.add_child(raw)
		
		var char_root := Node3D.new()
		char_root.name = "CharacterRoot_" + cid
		root.add_child(char_root)
		
		# Collect character meshes vs non-character nodes
		var leg_l_nodes = []
		var leg_r_nodes = []
		var arm_l_nodes = []
		var arm_r_nodes = []
		var body_nodes = []
		
		var children = raw.get_children().duplicate()
		for child in children:
			var nname = child.name.to_lower()
			if "camera" in nname or "floor" in nname or "backdrop" in nname or "label" in nname or "grid" in nname:
				continue
			
			raw.remove_child(child)
			
			# Identify limb vs body
			if "l leg" in nname or "left leg" in nname or "l boot" in nname or "left boot" in nname:
				leg_l_nodes.append(child)
			elif "r leg" in nname or "right leg" in nname or "r boot" in nname or "right boot" in nname:
				leg_r_nodes.append(child)
			elif "l upper arm" in nname or "l cuff" in nname or "l hand" in nname or "left green sleeve" in nname or "left cream cuff" in nname or "left hand" in nname or "l arm" in nname:
				arm_l_nodes.append(child)
			elif "r upper arm" in nname or "r cuff" in nname or "r hand" in nname or "right green sleeve" in nname or "right cream cuff" in nname or "right hand" in nname or "r arm" in nname:
				arm_r_nodes.append(child)
			else:
				body_nodes.append(child)
				
		print("Config [", cid, " - ", cfg["name"], "]:")
		print("  Leg L: ", leg_l_nodes.size(), " meshes")
		print("  Leg R: ", leg_r_nodes.size(), " meshes")
		print("  Arm L: ", arm_l_nodes.size(), " meshes")
		print("  Arm R: ", arm_r_nodes.size(), " meshes")
		print("  Body/Head/Torso: ", body_nodes.size(), " meshes")
		
		# Measure total height of character meshes
		var full_aabb = AABB()
		var first = true
		for n in (leg_l_nodes + leg_r_nodes + arm_l_nodes + arm_r_nodes + body_nodes):
			if n is MeshInstance3D and n.mesh:
				var m_aabb = n.transform * n.mesh.get_aabb()
				if first:
					full_aabb = m_aabb
					first = false
				else:
					full_aabb = full_aabb.merge(m_aabb)
		
		print("  Raw Height: ", "%.3f" % full_aabb.size.y, "m (Ymin: ", "%.3f" % full_aabb.position.y, ", Ymax: ", "%.3f" % (full_aabb.position.y + full_aabb.size.y), ")")
		var target_height = 1.85
		var scale_factor = target_height / full_aabb.size.y
		print("  Target scale factor: ", "%.4f" % scale_factor)
		
		raw.queue_free()
		char_root.queue_free()
		
	print("\n=== ALL 8 FBX MODELS SUCCESSFULLY VERIFIED AND CLASSIFIED ===")
	quit(0)
