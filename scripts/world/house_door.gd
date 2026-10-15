class_name HouseDoor
extends Area3D

## HouseDoor
## Interactive portal on designated village house facades.
## Interacting with this door transports the player into the 3D living room
## interior for that villager, containing medieval commodities and their secret puzzle.

@export var house_id: String = "tomas"
@export var house_name: String = "Tomas Reed's House"
@export var prompt_text: String = ""

var _is_transitioning: bool = false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	monitorable = true
	if prompt_text.is_empty():
		prompt_text = "[E] Enter " + house_name

func get_interaction_prompt() -> String:
	return prompt_text

func interact(player: Node) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	print("[HouseDoor] Entering %s (%s)..." % [house_name, house_id])
	
	# Save return coordinates for player in village
	HouseInteriorManager.current_house_id = house_id
	if player is Node3D:
		HouseInteriorManager.return_player_position = (player as Node3D).global_position
		HouseInteriorManager.return_player_rotation_y = (player as Node3D).rotation.y
		HouseInteriorManager.has_return_position = true
	HouseInteriorManager.is_inside_house = true
	
	# Release mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Fade village music
	if GameplayMusicController.active_instance and is_instance_valid(GameplayMusicController.active_instance):
		GameplayMusicController.active_instance.stop_theme(0.4)
		
	# Screen fade to black
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)
	
	var tween := canvas.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.4)
	tween.tween_callback(func():
		var err := get_tree().change_scene_to_file("res://scenes/house_interior.tscn")
		if err != OK:
			print("[HouseDoor] ERROR: Failed to load house_interior.tscn Code: ", err)
		canvas.queue_free()
	)
