class_name InterrogationDoor
extends Area3D

## InterrogationDoor
## Interactive portal on the Town Hall double doors.
## Interacting with this door transports the player (the detective)
## into the interrogation chamber where suspects are questioned.

@export var target_scene_path: String = "res://scenes/interrogation_room.tscn"
@export var prompt_text: String = "[E] Enter Interrogation Chamber (Town Hall)"

var _is_transitioning: bool = false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	monitorable = true

func get_interaction_prompt() -> String:
	return prompt_text

func interact(player: Node) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	print("[InterrogationDoor] Player entered interrogation chamber from Town Hall.")
	
	# Release mouse before scene change
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Smoothly fade out village gameplay music
	if GameplayMusicController.active_instance and is_instance_valid(GameplayMusicController.active_instance):
		GameplayMusicController.active_instance.stop_theme(0.4)
	
	# Create fade to black
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
		var err := get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			print("[InterrogationDoor] ERROR: Failed to load ", target_scene_path, " Code: ", err)
		canvas.queue_free()
	)
