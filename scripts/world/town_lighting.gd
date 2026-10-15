class_name TownLighting
extends Node3D

## TownLighting
## Attached to TownWorld to drive dynamic day/night light emission and window glow.
## Operates on the static scene nodes in the hierarchy without generating or destroying any geometry.
## This allows designers and developers to freely move, duplicate, and drag-and-drop objects
## in the Godot 3D editor.

var _window_meshes: Array[MeshInstance3D] = []
var _lantern_meshes: Array[MeshInstance3D] = []
var _lantern_lights: Array[OmniLight3D] = []
var _forge_lights: Array[OmniLight3D] = []

var _mat_window_day: StandardMaterial3D
var _mat_window_night: StandardMaterial3D
var _mat_lantern_day: StandardMaterial3D
var _mat_lantern_night: StandardMaterial3D

func _ready() -> void:
	_init_dynamic_materials()
	_collect_lighting_nodes(self)
	_connect_day_night()

func _init_dynamic_materials() -> void:
	_mat_window_day = StandardMaterial3D.new()
	_mat_window_day.albedo_color = Color(0.28, 0.32, 0.40)
	_mat_window_day.roughness = 0.50
	
	_mat_window_night = StandardMaterial3D.new()
	_mat_window_night.albedo_color = Color(0.95, 0.78, 0.42)
	_mat_window_night.emission_enabled = true
	_mat_window_night.emission = Color(1.0, 0.78, 0.38)
	_mat_window_night.emission_energy_multiplier = 3.5
	_mat_window_night.roughness = 0.35
	
	_mat_lantern_day = StandardMaterial3D.new()
	_mat_lantern_day.albedo_color = Color(0.45, 0.35, 0.25)
	_mat_lantern_day.roughness = 0.70
	
	_mat_lantern_night = StandardMaterial3D.new()
	_mat_lantern_night.albedo_color = Color(1.0, 0.82, 0.42)
	_mat_lantern_night.emission_enabled = true
	_mat_lantern_night.emission = Color(1.0, 0.78, 0.32)
	_mat_lantern_night.emission_energy_multiplier = 4.0
	_mat_lantern_night.roughness = 0.35

func _collect_lighting_nodes(node: Node) -> void:
	if node is MeshInstance3D:
		var n_name := node.name.to_lower()
		if "win" in n_name or "glass" in n_name:
			_window_meshes.append(node)
		elif "lantern" in n_name or "torch" in n_name:
			_lantern_meshes.append(node)
	elif node is OmniLight3D:
		var p_name := node.get_parent().name.to_lower() if node.get_parent() else ""
		if "forge" in p_name or "hearth" in p_name or "coal" in p_name:
			_forge_lights.append(node)
		else:
			_lantern_lights.append(node)
			
	for child in node.get_children():
		_collect_lighting_nodes(child)

func _connect_day_night() -> void:
	await get_tree().process_frame
	var env_mgr := get_parent().get_node_or_null("EnvironmentManager")
	if env_mgr and env_mgr.has_signal("time_updated"):
		env_mgr.connect("time_updated", _on_time_updated)

func _on_time_updated(time_of_day: float, phase: String) -> void:
	var window_emission: float = 0.0
	var lantern_emission: float = 0.0
	var lantern_light_energy: float = 0.0

	match phase:
		"morning":
			window_emission = 0.15
			lantern_emission = 0.1
			lantern_light_energy = 0.3
		"afternoon":
			window_emission = 0.05
			lantern_emission = 0.0
			lantern_light_energy = 0.1
		"evening":
			var t := _get_evening_progress(time_of_day)
			window_emission = lerpf(0.3, 1.0, t)
			lantern_emission = lerpf(0.2, 1.0, t)
			lantern_light_energy = lerpf(0.5, 2.5, t)
		"night":
			window_emission = 1.0
			lantern_emission = 1.0
			lantern_light_energy = 2.8

	# Update window materials
	for wm in _window_meshes:
		if is_instance_valid(wm):
			if window_emission > 0.3:
				wm.material_override = _mat_window_night
				_mat_window_night.emission_energy_multiplier = lerpf(1.5, 4.0, window_emission)
			else:
				wm.material_override = _mat_window_day

	# Update lantern meshes
	for lm in _lantern_meshes:
		if is_instance_valid(lm):
			if lantern_emission > 0.3:
				lm.material_override = _mat_lantern_night
				_mat_lantern_night.emission_energy_multiplier = lerpf(1.5, 5.0, lantern_emission)
			else:
				lm.material_override = _mat_lantern_day

	# Update lantern point lights
	for ll in _lantern_lights:
		if is_instance_valid(ll):
			ll.light_energy = lantern_light_energy

	# Forge lights always glow but brighten at night
	for fl in _forge_lights:
		if is_instance_valid(fl):
			fl.light_energy = lerpf(1.5, 3.5, window_emission)

func _get_evening_progress(tod: float) -> float:
	var evening_start := 0.5
	var evening_end := 0.667
	if tod < evening_start: return 0.0
	if tod > evening_end: return 1.0
	return (tod - evening_start) / (evening_end - evening_start)
