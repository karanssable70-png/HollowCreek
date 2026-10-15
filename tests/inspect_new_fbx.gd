extends SceneTree

func _init() -> void:
	_inspect.call_deferred()

func _inspect() -> void:
	print("\n================== INSPECTING INSPECTOR.FBX ==================")
	var res = load("res://assets/models/characters/Inspector.fbx")
	if res is PackedScene:
		var inst = res.instantiate()
		print("Root: ", inst.name)
		for c in inst.get_children():
			print("  Child: ", c.name, " (", c.get_class(), ")")
		inst.queue_free()
	quit(0)
