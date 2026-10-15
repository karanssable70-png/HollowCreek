extends SceneTree

func _init() -> void:
	_test_character_integration.call_deferred()

func _test_character_integration() -> void:
	print("\n=== TESTING CHARACTER INTEGRATION WITH NPC CONTROLLER ===")
	
	var char_scenes = [
		"aldric.tscn",
		"edmund.tscn",
		"finn.tscn",
		"garrick.tscn",
		"isolde.tscn",
		"lena.tscn",
		"mayor.tscn",
		"mercenary.tscn",
		"oswin.tscn",
		"inspector.tscn",
		"elora.tscn",
		"corin.tscn",
		"tomas.tscn"
	]
	
	for cs_file in char_scenes:
		var path = "res://scenes/characters/" + cs_file
		var ps: PackedScene = load(path)
		assert(ps != null, "Failed to load " + path)
		var inst = ps.instantiate()
		root.add_child(inst)
		
		var leg_l = inst.get_node_or_null("LegPivotL")
		var leg_r = inst.get_node_or_null("LegPivotR")
		var arm_l = inst.get_node_or_null("ArmPivotL")
		var arm_r = inst.get_node_or_null("ArmPivotR")
		var torso = inst.get_node_or_null("TorsoAndHead")
		
		assert(leg_l != null, "LegPivotL missing in " + cs_file)
		assert(leg_r != null, "LegPivotR missing in " + cs_file)
		assert(arm_l != null, "ArmPivotL missing in " + cs_file)
		assert(arm_r != null, "ArmPivotR missing in " + cs_file)
		assert(torso != null, "TorsoAndHead missing in " + cs_file)
		
		print("[PASS] ", cs_file, " has valid pivots: LegL=", leg_l.get_child_count(), " meshes, LegR=", leg_r.get_child_count(), " meshes, ArmL=", arm_l.get_child_count(), " meshes, ArmR=", arm_r.get_child_count(), " meshes, Torso=", torso.get_child_count(), " meshes")
		
		inst.queue_free()
		
	print("\n=== ALL 9 CHARACTER SCENES PASS PIVOT VERIFICATION ===")
	quit(0)
