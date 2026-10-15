class_name PlayerController
extends CharacterBody3D

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.0025
@export var gravity: float = 14.7

# Camera head bobbing
@export var head_bob_frequency: float = 2.4
@export var head_bob_amplitude: float = 0.05
var _bob_timer: float = 0.0

# Node references
var head: Node3D
var camera: Camera3D
var raycast: RayCast3D
var reticle_rect: ColorRect
var prompt_label: Label
var hud_canvas: CanvasLayer

# Mercenary body model references
var body_model: Node3D = null
var _body_leg_l: Node3D = null
var _body_leg_r: Node3D = null
var _body_arm_l: Node3D = null
var _body_arm_r: Node3D = null

# State
var is_dialogue_open: bool = false
var can_move: bool = true
var mouse_captured: bool = true
var current_interactable: Node = null

signal interaction_requested(target: Node)

func _ready() -> void:
	_ensure_input_mappings()
	_setup_hierarchy()
	_setup_hud()
	capture_mouse()
	if HouseInteriorManager.has_return_position and not HouseInteriorManager.is_inside_house and not _is_in_house_interior():
		global_position = HouseInteriorManager.return_player_position
		rotation.y = HouseInteriorManager.return_player_rotation_y
		HouseInteriorManager.has_return_position = false

func _ensure_input_mappings() -> void:
	_register_action_if_missing("move_forward", KEY_W)
	_register_action_if_missing("move_backward", KEY_S)
	_register_action_if_missing("move_left", KEY_A)
	_register_action_if_missing("move_right", KEY_D)
	_register_action_if_missing("jump", KEY_SPACE)
	_register_action_if_missing("sprint", KEY_SHIFT)
	_register_action_if_missing("interact", KEY_E)
	_register_action_if_missing("ui_cancel", KEY_ESCAPE)

func _register_action_if_missing(action_name: String, key_code: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev := InputEventKey.new()
		ev.physical_keycode = key_code
		InputMap.action_add_event(action_name, ev)

func _setup_hierarchy() -> void:
	# Ensure CollisionShape3D exists
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not col_shape:
		col_shape = CollisionShape3D.new()
		col_shape.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		col_shape.shape = capsule
		col_shape.position = Vector3(0, 0.9, 0)
		add_child(col_shape)
	
	# Head and Camera
	head = get_node_or_null("Head") as Node3D
	if not head:
		head = Node3D.new()
		head.name = "Head"
		head.position = Vector3(0, 1.65, 0)
		add_child(head)
	
	camera = head.get_node_or_null("Camera3D") as Camera3D
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.current = true
		camera.fov = 75.0
		head.add_child(camera)
		
	# RayCast for interaction
	raycast = head.get_node_or_null("InteractionRay") as RayCast3D
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "InteractionRay"
		raycast.target_position = Vector3(0, 0, -3.5)
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		head.add_child(raycast)

	# Setup full-body Inspector model (Inspector.fbx)
	body_model = get_node_or_null("BodyModel")
	if not body_model:
		var scn: PackedScene = load("res://scenes/characters/inspector.tscn")
		if scn:
			body_model = scn.instantiate()
			body_model.name = "BodyModel"
			add_child(body_model)
			_body_leg_l = body_model.get_node_or_null("LegPivotL")
			_body_leg_r = body_model.get_node_or_null("LegPivotR")
			_body_arm_l = body_model.get_node_or_null("ArmPivotL")
			_body_arm_r = body_model.get_node_or_null("ArmPivotR")
			
			# In first-person, hide head, hat, & facial meshes so they don't obstruct the camera view
			var torso_head = body_model.get_node_or_null("TorsoAndHead")
			if torso_head:
				for c in torso_head.get_children():
					var cn = c.name.to_lower()
					if "head" in cn or "hood" in cn or "hat" in cn or "face" in cn or "eye" in cn or "nose" in cn or "neck" in cn or "hair" in cn:
						c.visible = false

func _setup_hud() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "PlayerHUD"
	add_child(hud_canvas)
	
	var hud_control := Control.new()
	hud_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(hud_control)
	
	# Crosshair reticle (subtle dot)
	reticle_rect = ColorRect.new()
	reticle_rect.color = Color(1, 1, 1, 0.75)
	reticle_rect.custom_minimum_size = Vector2(4, 4)
	reticle_rect.size = Vector2(4, 4)
	reticle_rect.set_anchors_preset(Control.PRESET_CENTER)
	reticle_rect.position = -Vector2(2, 2)
	reticle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_control.add_child(reticle_rect)
	
	# Interaction prompt label
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.position = Vector2(-200, 30)
	prompt_label.size = Vector2(400, 40)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.text = ""
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style the prompt label
	var font_color := Color(1.0, 0.95, 0.75, 1.0)
	prompt_label.add_theme_color_override("font_color", font_color)
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.add_theme_font_size_override("font_size", 16)
	hud_control.add_child(prompt_label)

func _unhandled_input(event: InputEvent) -> void:
	if is_dialogue_open:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not mouse_captured:
			capture_mouse()
			return
			
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			release_mouse()
		else:
			capture_mouse()
		return
		
	if mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
		
	if event.is_action_pressed("interact") and current_interactable != null:
		_trigger_interaction()

func _physics_process(delta: float) -> void:
	if is_dialogue_open or not can_move:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
		
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			
	# Movement input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var target_speed: float = sprint_speed if is_sprinting else walk_speed
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
		
		# Head bobbing
		if is_on_floor():
			_bob_timer += delta * (target_speed * 1.5)
			camera.position.y = sin(_bob_timer) * head_bob_amplitude
			camera.position.x = cos(_bob_timer * 0.5) * (head_bob_amplitude * 0.5)
			if _body_leg_l and _body_leg_r:
				var leg_swing := sin(_bob_timer * 1.5) * 0.4
				_body_leg_l.rotation.x = leg_swing
				_body_leg_r.rotation.x = -leg_swing
	else:
		velocity.x = move_toward(velocity.x, 0, target_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, target_speed * 8.0 * delta)
		# Settle head bob
		camera.position.y = move_toward(camera.position.y, 0, delta)
		camera.position.x = move_toward(camera.position.x, 0, delta)
		if _body_leg_l and _body_leg_r:
			_body_leg_l.rotation.x = lerpf(_body_leg_l.rotation.x, 0.0, delta * 8.0)
			_body_leg_r.rotation.x = lerpf(_body_leg_r.rotation.x, 0.0, delta * 8.0)
		
	move_and_slide()
	_check_interaction()

func _check_interaction() -> void:
	if not raycast:
		return
		
	if raycast.is_colliding():
		var collider: Object = raycast.get_collider()
		var interactable := _find_interactable_ancestor(collider)
		if interactable != null:
			current_interactable = interactable
			if interactable.has_method("get_interaction_prompt"):
				prompt_label.text = interactable.get_interaction_prompt()
			else:
				prompt_label.text = "[E] Interact"
			reticle_rect.color = Color(1.0, 0.85, 0.3, 1.0)
			return
			
	current_interactable = null
	prompt_label.text = ""
	reticle_rect.color = Color(1, 1, 1, 0.75)

func _find_interactable_ancestor(node: Node) -> Node:
	var curr := node
	while curr != null:
		if curr.is_in_group("interactable") or curr.has_method("interact"):
			return curr
		curr = curr.get_parent()
	return null

func _trigger_interaction() -> void:
	if current_interactable != null and current_interactable.has_method("interact"):
		current_interactable.interact(self)
		emit_signal("interaction_requested", current_interactable)

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func set_dialogue_state(open: bool) -> void:
	is_dialogue_open = open
	if open:
		release_mouse()
		prompt_label.text = ""
	else:
		capture_mouse()

func _is_in_house_interior() -> bool:
	if HouseInteriorManager.is_inside_house:
		return true
	var root_node := get_tree().current_scene if get_tree() else null
	if root_node and (root_node.name == "HouseInterior" or root_node.has_node("RoomArchitecture")):
		return true
	var p: Node = self
	while p:
		if p.name == "HouseInterior" or p.has_node("RoomArchitecture"):
			return true
		p = p.get_parent()
	return false
