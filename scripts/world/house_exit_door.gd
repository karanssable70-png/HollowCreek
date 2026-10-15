class_name HouseExitDoor
extends Area3D

## HouseExitDoor
## Interactive portal inside house living rooms.
## Allows the detective to return smoothly to Hollow Creek village.

@export var prompt_text: String = "[E] Exit to Hollow Creek Village"
var _is_transitioning: bool = false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	monitorable = true
	if not get_node_or_null("CollisionShape3D"):
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(1.8, 2.5, 1.2)
		col.shape = box
		add_child(col)

func get_interaction_prompt() -> String:
	return prompt_text

func interact(player: Node) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	print("[HouseExitDoor] Returning to village...")
	HouseInteriorManager.is_inside_house = false
	var controller := _find_interior_controller()
	if controller and controller.has_method("return_to_village"):
		controller.return_to_village()
	else:
		var err := get_tree().change_scene_to_file("res://scenes/town.tscn")
		if err != OK:
			print("ERROR: Failed to load town.tscn Code: ", err)

func _find_interior_controller() -> Node:
	var curr: Node = self
	while curr:
		if curr.has_method("return_to_village"):
			return curr
		curr = curr.get_parent()
	return get_tree().current_scene
