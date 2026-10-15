extends SceneTree

# Builds the 4 new character scenes with standard pivots and scaling
func _init() -> void:
	_build_all.call_deferred()

func _classify_mesh(model_key: String, mesh_name: String) -> String:
	var s := mesh_name.to_lower()
	match model_key:
		"inspector":
			if "leg_l" in s or "boot_l" in s:
				return "leg_l"
			if "leg_r" in s or "boot_r" in s:
				return "leg_r"
			if "arm_l" in s or "glove_l" in s or "cuff_l" in s or "elbow_l" in s or "forearm_l" in s or "shoulder_l" in s:
				return "arm_l"
			if "arm_r" in s or "glove_r" in s or "cuff_r" in s or "elbow_r" in s or "forearm_r" in s or "shoulder_r" in s:
				return "arm_r"
			return "torso"

		"elora":
			if "left leg" in s or "left boot" in s:
				return "leg_l"
			if "right leg" in s or "right boot" in s:
				return "leg_r"
			if "left upper arm" in s or "left forearm" in s or "left cuff" in s or "left hand" in s:
				return "arm_l"
			if "right upper arm" in s or "right forearm" in s or "right cuff" in s or "right hand" in s:
				return "arm_r"
			return "torso"

		"corin":
			if "leg_l" in s or "boot_l" in s or "patch_l" in s:
				return "leg_l"
			if "leg_r" in s or "boot_r" in s or "patch_r" in s:
				return "leg_r"
			if "arm_l" in s or "glove_l" in s or "cuff_l" in s or "elbow_l" in s or "forearm_l" in s or "shoulder_l" in s:
				return "arm_l"
			if "arm_r" in s or "glove_r" in s or "cuff_r" in s or "elbow_r" in s or "forearm_r" in s or "shoulder_r" in s:
				return "arm_r"
			return "torso"

		"tomas":
			if "left upper leg" in s or "left shin" in s or "left knee" in s or "left boot" in s:
				return "leg_l"
			if "right upper leg" in s or "right shin" in s or "right knee" in s or "right boot" in s:
				return "leg_r"
			if "left shoulder" in s or "left upper arm" in s or "left red sleeve" in s or "left forearm" in s or "left bracer" in s or "left glove" in s or "spear" in s:
				return "arm_l"
			if "right shoulder" in s or "right upper arm" in s or "right red sleeve" in s or "right forearm" in s or "right bracer" in s or "right glove" in s:
				return "arm_r"
			return "torso"

	return "torso"

func _build_all() -> void:
	print("\n================== BUILDING 4 NEW CHARACTER SCENES ==================")
	
	var configs = {
		"inspector": {
			"source": "res://assets/models/characters/Inspector.fbx",
			"target_path": "res://scenes/characters/inspector.tscn",
			"root_name": "InspectorCharacter",
			"target_height": 1.85,
			"hip_l": Vector3(-0.205, 0.89, -0.015),
			"hip_r": Vector3(0.205, 0.89, -0.015),
			"shoulder_l": Vector3(-0.44, 1.75, -0.015),
			"shoulder_r": Vector3(0.44, 1.75, -0.015)
		},
		"elora": {
			"source": "res://assets/models/characters/herbalist.fbx",
			"target_path": "res://scenes/characters/elora.tscn",
			"root_name": "EloraNightshade",
			"target_height": 1.80,
			"hip_l": Vector3(-0.16, 0.89, 0.0),
			"hip_r": Vector3(0.16, 0.89, 0.0),
			"shoulder_l": Vector3(-0.43, 1.62, 0.0),
			"shoulder_r": Vector3(0.43, 1.62, 0.0)
		},
		"corin": {
			"source": "res://assets/models/characters/bazaarguy.fbx",
			"target_path": "res://scenes/characters/corin.tscn",
			"root_name": "CorinFletcher",
			"target_height": 1.80,
			"hip_l": Vector3(-0.205, 0.89, -0.015),
			"hip_r": Vector3(0.205, 0.89, -0.015),
			"shoulder_l": Vector3(-0.44, 1.75, -0.015),
			"shoulder_r": Vector3(0.44, 1.75, -0.015)
		},
		"tomas": {
			"source": "res://assets/models/characters/Townguard.fbx",
			"target_path": "res://scenes/characters/tomas.tscn",
			"root_name": "TomasReed",
			"target_height": 1.85,
			"custom_raw_height": 3.48,
			"hip_l": Vector3(-0.20, 1.22, 0.0),
			"hip_r": Vector3(0.20, 1.22, 0.0),
			"shoulder_l": Vector3(-0.56, 2.35, 0.0),
			"shoulder_r": Vector3(0.56, 2.35, 0.0)
		}
	}

	for key in configs:
		var cfg = configs[key]
		_build_character_scene(key, cfg)

	print("\n================== ALL 4 CHARACTER SCENES GENERATED ==================")
	quit(0)

func _build_character_scene(model_key: String, cfg: Dictionary) -> void:
	var path: String = cfg["source"]
	var target_path: String = cfg["target_path"]
	var scn: PackedScene = load(path)
	assert(scn != null, "Could not load " + path)
	var raw = scn.instantiate()
	root.add_child(raw)

	# 1. Collect meshes
	var leg_l_meshes = []
	var leg_r_meshes = []
	var arm_l_meshes = []
	var arm_r_meshes = []
	var torso_meshes = []

	var full_aabb = AABB()
	var first = true

	var children = raw.get_children().duplicate()
	for child in children:
		var nname: String = child.name.to_lower()
		if "camera" in nname or "ground" in nname or "plinth" in nname or "label" in nname:
			continue
		
		if child is MeshInstance3D and child.mesh:
			var m_aabb = child.transform * child.mesh.get_aabb()
			if first:
				full_aabb = m_aabb
				first = false
			else:
				full_aabb = full_aabb.merge(m_aabb)

			raw.remove_child(child)
			var cat := _classify_mesh(model_key, child.name)
			match cat:
				"leg_l":
					leg_l_meshes.append(child)
				"leg_r":
					leg_r_meshes.append(child)
				"arm_l":
					arm_l_meshes.append(child)
				"arm_r":
					arm_r_meshes.append(child)
				_:
					torso_meshes.append(child)

	var raw_height: float = cfg.get("custom_raw_height", full_aabb.size.y)
	var scale_factor: float = cfg["target_height"] / raw_height
	var offset_y: float = -full_aabb.position.y * scale_factor

	print("[%s] Classified Meshes:" % cfg["root_name"])
	print("  LegL: %d | LegR: %d | ArmL: %d | ArmR: %d | Torso: %d" % [
		leg_l_meshes.size(), leg_r_meshes.size(), arm_l_meshes.size(), arm_r_meshes.size(), torso_meshes.size()
	])
	print("  Raw Height: %.3fm -> Scaled: %.3fm (Scale: %.4f, OffsetY: %.4f)" % [
		raw_height, cfg["target_height"], scale_factor, offset_y
	])

	# 2. Build character hierarchy
	var char_root := Node3D.new()
	char_root.name = cfg["root_name"]
	char_root.transform = Transform3D(
		Vector3(scale_factor, 0, 0),
		Vector3(0, scale_factor, 0),
		Vector3(0, 0, scale_factor),
		Vector3(0, offset_y, 0)
	)

	var torso_node := Node3D.new()
	torso_node.name = "TorsoAndHead"
	char_root.add_child(torso_node)

	var leg_l_pivot := Node3D.new()
	leg_l_pivot.name = "LegPivotL"
	leg_l_pivot.position = cfg["hip_l"]
	char_root.add_child(leg_l_pivot)

	var leg_r_pivot := Node3D.new()
	leg_r_pivot.name = "LegPivotR"
	leg_r_pivot.position = cfg["hip_r"]
	char_root.add_child(leg_r_pivot)

	var arm_l_pivot := Node3D.new()
	arm_l_pivot.name = "ArmPivotL"
	arm_l_pivot.position = cfg["shoulder_l"]
	char_root.add_child(arm_l_pivot)

	var arm_r_pivot := Node3D.new()
	arm_r_pivot.name = "ArmPivotR"
	arm_r_pivot.position = cfg["shoulder_r"]
	char_root.add_child(arm_r_pivot)

	# 3. Attach meshes with relative transforms
	for m in torso_meshes:
		torso_node.add_child(m)

	for m in leg_l_meshes:
		m.position -= cfg["hip_l"]
		leg_l_pivot.add_child(m)

	for m in leg_r_meshes:
		m.position -= cfg["hip_r"]
		leg_r_pivot.add_child(m)

	for m in arm_l_meshes:
		m.position -= cfg["shoulder_l"]
		arm_l_pivot.add_child(m)

	for m in arm_r_meshes:
		m.position -= cfg["shoulder_r"]
		arm_r_pivot.add_child(m)

	# 4. Set node ownership for PackedScene serialization
	_set_owner_recursive(char_root, char_root)

	var packed := PackedScene.new()
	var pack_err := packed.pack(char_root)
	assert(pack_err == OK, "Failed to pack scene for " + cfg["root_name"])

	var save_err := ResourceSaver.save(packed, target_path)
	assert(save_err == OK, "Failed to save scene to " + target_path)
	print("  -> Saved scene successfully: ", target_path)

	raw.queue_free()
	char_root.queue_free()

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
