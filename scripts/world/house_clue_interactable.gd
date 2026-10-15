class_name HouseClueInteractable
extends Area3D

## HouseClueInteractable
## Represents an interactable paper, ledger, drawer, or secret stash inside a villager's house.
## Implements the standard get_interaction_prompt() and interact() methods for PlayerController.
## Features 3D parchment visuals, glowing discovery beacons, and physical drawer animations.

@export var clue_id: String = ""
@export var prompt_text: String = "[E] Inspect Document"
@export var document_title: String = "DOCUMENT"
@export var document_subtitle: String = "Hollow Creek Investigation Clue"
@export_multiline var document_body: String = ""
@export_multiline var secret_summary: String = ""

# Drawer configuration
@export var is_drawer: bool = false
@export var is_drawer_open: bool = false
@export var drawer_node_path: NodePath
var drawer_target_node: Node3D = null

# Visual beacon and highlight
var _beacon_light: OmniLight3D = null
var _glow_phase: float = 0.0

signal clue_inspected(clue_id: String)

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	monitorable = true
	
	if not drawer_target_node and not drawer_node_path.is_empty() and has_node(drawer_node_path):
		drawer_target_node = get_node(drawer_node_path) as Node3D

	# Ensure CollisionShape3D exists so raycasts always hit this clue
	if not get_node_or_null("CollisionShape3D"):
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(0.65, 0.5, 0.65)
		col.shape = box
		add_child(col)

	# Setup beacon glow light if not already present
	_beacon_light = get_node_or_null("ClueBeaconLight") as OmniLight3D
	if not _beacon_light and not is_drawer:
		_beacon_light = OmniLight3D.new()
		_beacon_light.name = "ClueBeaconLight"
		_beacon_light.light_color = Color(1.0, 0.85, 0.35) # Warm gold
		_beacon_light.light_energy = 1.0
		_beacon_light.omni_range = 1.8
		_beacon_light.position = Vector3(0, 0.15, 0)
		add_child(_beacon_light)

func _process(delta: float) -> void:
	if _beacon_light and _beacon_light.visible:
		_glow_phase += delta * 3.0
		_beacon_light.light_energy = 0.8 + sin(_glow_phase) * 0.4

func get_interaction_prompt() -> String:
	if is_drawer and not is_drawer_open:
		if not prompt_text.is_empty() and prompt_text != "[E] Inspect Document":
			return prompt_text
		return "[E] Open Drawer"
	if is_drawer and is_drawer_open:
		return "[E] Inspect " + document_title
	if not prompt_text.is_empty():
		return prompt_text
	return "[E] Inspect " + document_title

func interact(player: Node) -> void:
	if is_drawer and not is_drawer_open:
		open_drawer()
		return
		
	# Open inspection modal
	var controller := _find_interior_controller()
	if controller and controller.has_method("open_document_reader"):
		controller.open_document_reader(document_title, document_subtitle, document_body, secret_summary, clue_id)
		clue_inspected.emit(clue_id)

func open_drawer() -> void:
	if is_drawer_open:
		return
	is_drawer_open = true
	prompt_text = "[E] Inspect " + document_title
	
	if drawer_target_node:
		drawer_target_node.position.z = 0.1
		var tween := create_tween()
		if tween:
			tween.tween_property(drawer_target_node, "position:z", 0.44, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Enable beacon inside drawer
	if _beacon_light:
		_beacon_light.visible = true
	else:
		_beacon_light = OmniLight3D.new()
		_beacon_light.name = "ClueBeaconLight"
		_beacon_light.light_color = Color(1.0, 0.85, 0.35)
		_beacon_light.light_energy = 1.2
		_beacon_light.omni_range = 1.5
		_beacon_light.position = Vector3(0, 0.15, 0.2)
		add_child(_beacon_light)
		
	print("[HouseClueInteractable] Drawer opened. Revealing document: %s" % document_title)

func _find_interior_controller() -> Node:
	var curr: Node = self
	while curr:
		if curr.has_method("open_document_reader"):
			return curr
		curr = curr.get_parent()
	return get_tree().current_scene
