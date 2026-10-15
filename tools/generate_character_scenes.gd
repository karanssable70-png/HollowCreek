extends SceneTree

func _init() -> void:
	_generate.call_deferred()

func _generate() -> void:
	print("\n=== GENERATING CHARACTER MODEL SCENES FROM FBX ===")
	
	DirAccess.make_dir_absolute("res://scenes/characters")
	
	var char_defs = [
		{"id": "finn", "name": "FinnMercer", "fbx": "Dockworker.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "garrick", "name": "GarrickThorne", "fbx": "HarbourMaster.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "lena", "name": "LenaHart", "fbx": "Innkeeper.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "mercenary", "name": "TheMercenary", "fbx": "killer.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "oswin", "name": "OswinHale", "fbx": "Mayor.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "isolde", "name": "LadyIsolde", "fbx": "Noblewoman.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "edmund", "name": "EdmundWren", "fbx": "Physician.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "aldric", "name": "LordAldric", "fbx": "Victim.fbx", "hip_y": 1.25, "shoulder_y": 2.25},
		{"id": "mayor", "name": "MayorEldridge", "fbx": "Mayor.fbx", "hip_y": 1.25, "shoulder_y": 2.25}
	]
	
	for def in char_defs:
		var fbx_path = "res://assets/models/characters/" + def["fbx"]
		var scn: PackedScene = load(fbx_path)
		if not scn:
			print("Error loading: ", fbx_path)
			continue
			
		var raw = scn.instantiate()
		
		# Root node for the character model
		var char_root := Node3D.new()
		char_root.name = def["name"]
		
		# Torso / Head container
		var torso_group := Node3D.new()
		torso_group.name = "TorsoAndHead"
		char_root.add_child(torso_group)
		torso_group.owner = char_root
		
		# Pivot nodes for animation
		var hip_y: float = def["hip_y"]
		var shoulder_y: float = def["shoulder_y"]
		
		var leg_pivot_l := Node3D.new()
		leg_pivot_l.name = "LegPivotL"
		leg_pivot_l.position = Vector3(-0.19, hip_y, 0.0)
		char_root.add_child(leg_pivot_l)
		leg_pivot_l.owner = char_root
		
		var leg_pivot_r := Node3D.new()
		leg_pivot_r.name = "LegPivotR"
		leg_pivot_r.position = Vector3(0.19, hip_y, 0.0)
		char_root.add_child(leg_pivot_r)
		leg_pivot_r.owner = char_root
		
		var arm_pivot_l := Node3D.new()
		arm_pivot_l.name = "ArmPivotL"
		arm_pivot_l.position = Vector3(-0.57, shoulder_y, 0.0)
		char_root.add_child(arm_pivot_l)
		arm_pivot_l.owner = char_root
		
		var arm_pivot_r := Node3D.new()
		arm_pivot_r.name = "ArmPivotR"
		arm_pivot_r.position = Vector3(0.57, shoulder_y, 0.0)
		char_root.add_child(arm_pivot_r)
		arm_pivot_r.owner = char_root
		
		var all_char_meshes = []
		var children = raw.get_children().duplicate()
		for child in children:
			var nname = child.name.to_lower()
			if "camera" in nname or "floor" in nname or "backdrop" in nname or "label" in nname or "grid" in nname or "ground" in nname:
				child.queue_free()
				continue
				
			child.owner = null
			raw.remove_child(child)
			all_char_meshes.append(child)
			
			# Assign to appropriate pivot or torso group
			if "l leg" in nname or "left leg" in nname or "l boot" in nname or "left boot" in nname:
				child.position -= leg_pivot_l.position
				leg_pivot_l.add_child(child)
				child.owner = char_root
			elif "r leg" in nname or "right leg" in nname or "r boot" in nname or "right boot" in nname:
				child.position -= leg_pivot_r.position
				leg_pivot_r.add_child(child)
				child.owner = char_root
			elif "l upper arm" in nname or "l cuff" in nname or "l hand" in nname or "left green sleeve" in nname or "left cream cuff" in nname or "left hand" in nname or "l arm" in nname:
				child.position -= arm_pivot_l.position
				arm_pivot_l.add_child(child)
				child.owner = char_root
			elif "r upper arm" in nname or "r cuff" in nname or "r hand" in nname or "right green sleeve" in nname or "right cream cuff" in nname or "right hand" in nname or "r arm" in nname:
				child.position -= arm_pivot_r.position
				arm_pivot_r.add_child(child)
				child.owner = char_root
			else:
				torso_group.add_child(child)
				child.owner = char_root
				
		# Measure total height & compute uniform scale so character stands 1.85m tall
		var full_aabb = AABB()
		var first = true
		for mi in all_char_meshes:
			if mi is MeshInstance3D and mi.mesh:
				# Mesh transform relative to char_root
				var mi_global_xform = mi.get_parent().transform * mi.transform
				var m_aabb = mi_global_xform * mi.mesh.get_aabb()
				if first:
					full_aabb = m_aabb
					first = false
				else:
					full_aabb = full_aabb.merge(m_aabb)
					
		var scale_factor: float = 1.85 / full_aabb.size.y
		char_root.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Offset Y so feet touch 0.0
		var y_min = full_aabb.position.y * scale_factor
		if y_min != 0.0:
			char_root.position.y = -y_min
			
		print("Generated: ", def["name"], " (Meshes: ", all_char_meshes.size(), ", Scale: ", "%.3f" % scale_factor, ", Base Y Offset: ", "%.3f" % char_root.position.y, ")")
		
		# Pack and save scene
		var packed := PackedScene.new()
		var pack_err = packed.pack(char_root)
		assert(pack_err == OK, "Failed to pack scene for " + def["name"])
		var out_path = "res://scenes/characters/" + def["id"] + ".tscn"
		var save_err = ResourceSaver.save(packed, out_path)
		assert(save_err == OK, "Failed to save scene to " + out_path)
		print("  -> Saved scene to: ", out_path)
		
		raw.queue_free()
		char_root.queue_free()
		
	print("\n=== CHARACTER SCENE GENERATION COMPLETE ===")
	quit(0)
