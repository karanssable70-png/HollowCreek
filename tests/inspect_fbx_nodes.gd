extends SceneTree

func _init() -> void:
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
		var inst = scn.instantiate()
		print("\n=== " + fname + " ===")
		for child in inst.get_children():
			print("  ", child.name, " -> pos: ", child.position, " rot: ", child.rotation)
		inst.queue_free()
	quit(0)
