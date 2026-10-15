class_name InterrogationController
extends Node3D

## InterrogationController
## Manages the 3D interrogation chamber and dialogue anomaly deduction mechanics.
## Features:
## - Atmospheric 3D dimly-lit chamber with round table and 2 chairs
## - Dynamic suspect selector panel for all 10 suspects
## - Walk-in & seating sequence for summoned suspects
## - Interrogation dialogue system with behavioral anomaly alerts
## - Dark secrets, alibi contradictions, evidence confrontation, and murder accusation
## - Seamless return to Hollow Creek village

const SuspectDatabaseScript = preload("res://scripts/interrogation/suspect_database.gd")
const CinematicCharactersScript = preload("res://scripts/cinematic/cinematic_characters.gd")
const MysteryGameStateScript = preload("res://scripts/mystery/mystery_game_state.gd")

# 3D Node references
var room_root: Node3D
var active_camera: Camera3D
var suspect_chair: Node3D
var detective_chair: Node3D
var round_table: Node3D
var overhead_light: SpotLight3D
var table_omni_light: OmniLight3D
var ambient_audio_player: AudioStreamPlayer
var current_suspect_node: Node3D = null

# UI references
var hud_canvas: CanvasLayer
var suspect_buttons: Dictionary = {}
var active_suspect_data: Dictionary = {}
var suspect_states: Dictionary = {} # id -> {"status": "unquestioned", "stress": 50, "contradiction": false, "confessed": false}

var name_banner_label: Label
var role_banner_label: Label
var stress_progress: ProgressBar
var stress_label: Label
var anomaly_box: PanelContainer
var anomaly_label: Label
var dialogue_log: RichTextLabel
var dialogue_history: String = ""
var input_field: LineEdit
var action_btn_alibi: Button
var action_btn_motive: Button
var action_btn_evidence: Button
var action_btn_secret: Button
var action_btn_accuse: Button
var evidence_container: VBoxContainer
var evidence_panel: PanelContainer

# Smart NPC AI HTTP Bridge
var ai_http_request: HTTPRequest
var conversation_histories: Dictionary = {}
var _is_waiting_for_ai: bool = false

# Walk-in animation state
var _is_walking_in: bool = false
var _walk_time: float = 0.0
var _walk_duration: float = 2.0
var _walk_start_z: float = 4.2
var _walk_target_z: float = 1.25
var _is_transitioning_scene: bool = false
@export var auto_transition_on_accusation: bool = true

# Detective clues available for confrontation
var available_clues: Array[Dictionary] = [
	{"id": "storehouse_iron_key", "name": "Storehouse Master Key", "desc": "Only two keys exist: Lord Aldric's and Harbour Master Garrick's."},
	{"id": "burnt_contract_scrap", "name": "Burnt Contract Scrap", "desc": "Raven seal contract found in hearth: 'Contract complete upon sunset'."},
	{"id": "stolen_stiletto", "name": "Custom Triangular Stiletto", "desc": "Precision puncture weapon matching Dr. Wren's autopsy."},
	{"id": "debt_ledgers", "name": "Aldric's Extortion Ledgers", "desc": "Proves Garrick's debts, Isolde's disputed deeds, and town payoffs."},
	{"id": "autopsy_report", "name": "Physician's Post-Mortem", "desc": "Single fatal puncture to left ventricle. Zero poison swallowed."},
	{"id": "muddy_cliff_boots", "name": "Muddy Cliff Bootprints", "desc": "Fresh tracks from storehouse to square."}
]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_init_suspect_states()
	_setup_3d_environment()
	_setup_lighting()
	_setup_camera()
	_setup_audio()
	_setup_ui()
	
	ai_http_request = HTTPRequest.new()
	ai_http_request.name = "SmartNPCHttpRequest"
	ai_http_request.timeout = 15.0
	ai_http_request.request_completed.connect(_on_ai_chat_completed)
	add_child(ai_http_request)
	
	# Default: Summon Harbour Master Garrick Thorne on first entry
	summon_suspect("garrick")

func _init_suspect_states() -> void:
	var all_suspects: Array[Dictionary] = SuspectDatabaseScript.get_all_suspects()
	for s: Dictionary in all_suspects:
		var s_id: String = s["id"]
		suspect_states[s_id] = {
			"status": "unquestioned",
			"stress": s.get("stress_baseline", 50),
			"contradiction": false,
			"confessed": false,
			"accused": false
		}

# ===========================================================================
# 3D ENVIRONMENT SETUP
# ===========================================================================
func _setup_3d_environment() -> void:
	room_root = Node3D.new()
	room_root.name = "InterrogationChamber"
	add_child(room_root)

	var mat_stone := _create_material(Color(0.18, 0.17, 0.16), 0.92)
	var mat_wood_dark := _create_material(Color(0.14, 0.10, 0.07), 0.88)
	var mat_wood_table := _create_material(Color(0.24, 0.16, 0.10), 0.65)
	var mat_floor := _create_material(Color(0.12, 0.12, 0.13), 0.95)
	var mat_iron := _create_material(Color(0.08, 0.08, 0.09), 0.60, 0.85)

	# Floor (7m x 8m)
	_create_box(room_root, "Floor", Vector3(7.0, 0.3, 8.0), Vector3(0, -0.15, 0.5), mat_floor)
	
	# Ceiling with timber beams
	_create_box(room_root, "Ceiling", Vector3(7.0, 0.2, 8.0), Vector3(0, 3.6, 0.5), mat_wood_dark)
	for i in range(-2, 3):
		_create_box(room_root, "Beam_" + str(i), Vector3(7.0, 0.25, 0.22), Vector3(0, 3.48, float(i) * 1.6), mat_wood_dark)

	# 4 Walls
	_create_box(room_root, "WallBack", Vector3(7.0, 3.6, 0.3), Vector3(0, 1.8, 4.5), mat_stone) # Doorway wall
	_create_box(room_root, "WallFront", Vector3(7.0, 3.6, 0.3), Vector3(0, 1.8, -3.5), mat_stone) # Detective wall
	_create_box(room_root, "WallLeft", Vector3(0.3, 3.6, 8.0), Vector3(-3.5, 1.8, 0.5), mat_stone)
	_create_box(room_root, "WallRight", Vector3(0.3, 3.6, 8.0), Vector3(3.5, 1.8, 0.5), mat_stone)

	# Heavy arched oak door on back wall
	var door_frame := _create_box(room_root, "DoorFrame", Vector3(1.6, 2.7, 0.15), Vector3(0, 1.35, 4.38), mat_wood_dark)
	var door_panel := _create_box(door_frame, "DoorPanel", Vector3(1.35, 2.5, 0.08), Vector3(0, 0, 0.02), mat_wood_table)
	_create_box(door_panel, "DoorHandle", Vector3(0.08, 0.25, 0.12), Vector3(0.55, 0.0, 0.06), mat_iron)

	# Central Round Table
	round_table = Node3D.new()
	round_table.name = "RoundInterrogationTable"
	round_table.position = Vector3(0, 0, 0)
	room_root.add_child(round_table)

	# Table Top (Cylinder radius 1.05m, height 0.08m)
	_create_cylinder(round_table, "TableTop", 1.05, 1.05, 0.08, Vector3(0, 0.76, 0), mat_wood_table)
	# Center Pedestal
	_create_cylinder(round_table, "Pedestal", 0.18, 0.22, 0.72, Vector3(0, 0.36, 0), mat_wood_dark)
	# Base Cross Feet
	_create_box(round_table, "FootX", Vector3(1.1, 0.08, 0.18), Vector3(0, 0.04, 0), mat_wood_dark)
	_create_box(round_table, "FootZ", Vector3(0.18, 0.08, 1.1), Vector3(0, 0.04, 0), mat_wood_dark)

	# Table Props (Dossier, candle, inkwell)
	var mat_paper := _create_material(Color(0.88, 0.82, 0.70))
	var mat_candle := _create_material(Color(0.92, 0.90, 0.82))
	var mat_wax := _create_material(Color(0.68, 0.12, 0.14))

	_create_box(round_table, "DossierLeft", Vector3(0.38, 0.02, 0.26), Vector3(-0.25, 0.81, -0.45), mat_paper)
	_create_box(round_table, "DossierRight", Vector3(0.38, 0.02, 0.26), Vector3(0.15, 0.81, -0.45), mat_paper)
	_create_cylinder(round_table, "Inkwell", 0.04, 0.05, 0.07, Vector3(0.42, 0.84, -0.35), mat_iron)
	_create_cylinder(round_table, "CandlePewter", 0.03, 0.035, 0.14, Vector3(-0.45, 0.87, -0.25), mat_candle)
	_create_box(round_table, "SealedLetter", Vector3(0.22, 0.015, 0.15), Vector3(-0.15, 0.82, -0.20), mat_paper)
	_create_cylinder(round_table, "WaxSeal", 0.025, 0.025, 0.01, Vector3(-0.15, 0.83, -0.20), mat_wax)

	# Chairs
	detective_chair = _build_chair("DetectiveChair", Vector3(0, 0, -1.35), 0.0, mat_wood_dark)
	room_root.add_child(detective_chair)

	suspect_chair = _build_chair("SuspectChair", Vector3(0, 0, 1.25), 180.0, mat_wood_dark)
	room_root.add_child(suspect_chair)

func _build_chair(c_name: String, pos: Vector3, rot_y: float, mat: Material) -> Node3D:
	var chair := Node3D.new()
	chair.name = c_name
	chair.position = pos
	chair.rotation_degrees.y = rot_y

	# Seat (0.55m x 0.06m x 0.52m at Y=0.45m)
	_create_box(chair, "Seat", Vector3(0.55, 0.06, 0.52), Vector3(0, 0.45, 0), mat)
	# 4 Legs
	_create_box(chair, "LegFL", Vector3(0.06, 0.45, 0.06), Vector3(-0.22, 0.225, 0.20), mat)
	_create_box(chair, "LegFR", Vector3(0.06, 0.45, 0.06), Vector3(0.22, 0.225, 0.20), mat)
	_create_box(chair, "LegBL", Vector3(0.06, 0.45, 0.06), Vector3(-0.22, 0.225, -0.20), mat)
	_create_box(chair, "LegBR", Vector3(0.06, 0.45, 0.06), Vector3(0.22, 0.225, -0.20), mat)
	# High Backrest
	_create_box(chair, "Backrest", Vector3(0.52, 0.65, 0.05), Vector3(0, 0.80, -0.23), mat)
	_create_box(chair, "SpindleL", Vector3(0.05, 0.40, 0.05), Vector3(-0.20, 0.55, -0.23), mat)
	_create_box(chair, "SpindleR", Vector3(0.05, 0.40, 0.05), Vector3(0.20, 0.55, -0.23), mat)
	# Armrests
	_create_box(chair, "ArmL", Vector3(0.06, 0.04, 0.42), Vector3(-0.26, 0.68, 0.02), mat)
	_create_box(chair, "ArmR", Vector3(0.06, 0.04, 0.42), Vector3(0.26, 0.68, 0.02), mat)
	_create_box(chair, "ArmPostL", Vector3(0.04, 0.22, 0.04), Vector3(-0.26, 0.56, 0.20), mat)
	_create_box(chair, "ArmPostR", Vector3(0.04, 0.22, 0.04), Vector3(0.26, 0.56, 0.20), mat)

	return chair

# ===========================================================================
# LIGHTING & CAMERA
# ===========================================================================
func _setup_lighting() -> void:
	# Hanging Iron Conical Pendant
	var mat_iron := _create_material(Color(0.08, 0.08, 0.09), 0.60, 0.85)
	_create_cylinder(room_root, "PendantChain", 0.015, 0.015, 0.9, Vector3(0, 3.15, 0), mat_iron)
	_create_cylinder(room_root, "PendantShade", 0.10, 0.36, 0.25, Vector3(0, 2.65, 0), mat_iron)

	# Main overhead dramatic interrogation spotlight pointing down onto the round table
	overhead_light = SpotLight3D.new()
	overhead_light.name = "OverheadInterrogationSpot"
	overhead_light.position = Vector3(0, 2.50, 0)
	overhead_light.rotation_degrees = Vector3(-90.0, 0, 0)
	overhead_light.light_color = Color(1.0, 0.86, 0.64)
	overhead_light.light_energy = 3.6
	overhead_light.spot_range = 6.0
	overhead_light.spot_angle = 48.0
	overhead_light.shadow_enabled = true
	overhead_light.shadow_bias = 0.03
	room_root.add_child(overhead_light)

	# Subtle desk omni light for candle glow on documents
	table_omni_light = OmniLight3D.new()
	table_omni_light.name = "TableCandleGlow"
	table_omni_light.position = Vector3(-0.45, 0.98, -0.25)
	table_omni_light.light_color = Color(1.0, 0.72, 0.40)
	table_omni_light.light_energy = 1.4
	table_omni_light.omni_range = 3.2
	room_root.add_child(table_omni_light)

	# Cool ambient rim light from back door to rim suspect silhouette
	var rim_light := OmniLight3D.new()
	rim_light.name = "DoorwayRimLight"
	rim_light.position = Vector3(0, 2.4, 3.8)
	rim_light.light_color = Color(0.35, 0.42, 0.60)
	rim_light.light_energy = 0.9
	rim_light.omni_range = 5.0
	room_root.add_child(rim_light)

func _setup_camera() -> void:
	active_camera = Camera3D.new()
	active_camera.name = "DetectiveFirstPersonCamera"
	active_camera.current = true
	active_camera.fov = 54.0
	add_child(active_camera)
	active_camera.position = Vector3(0, 1.35, -1.35)
	active_camera.look_at(Vector3(0, 1.15, 1.25), Vector3.UP)

func _setup_audio() -> void:
	ambient_audio_player = AudioStreamPlayer.new()
	ambient_audio_player.name = "InterrogationChamberThemePlayer"
	ambient_audio_player.bus = &"Master"
	ambient_audio_player.volume_db = -6.0
	add_child(ambient_audio_player)
	
	# Load and play the dedicated Interrogation Chamber Theme MP3
	var chamber_stream: AudioStream = load("res://assets/audio/interrogation_chamber_theme.mp3")
	if chamber_stream:
		if chamber_stream is AudioStreamMP3:
			(chamber_stream as AudioStreamMP3).loop = true
		ambient_audio_player.stream = chamber_stream
		ambient_audio_player.play()
		ambient_audio_player.finished.connect(func():
			if is_instance_valid(ambient_audio_player) and ambient_audio_player.is_inside_tree():
				ambient_audio_player.play(0.0)
		)
	else:
		push_warning("[InterrogationController] Failed to load res://assets/audio/interrogation_chamber_theme.mp3")

# ===========================================================================
# UI BUILD (SUSPECT SELECTOR + INTERROGATION DASHBOARD)
# ===========================================================================
func _setup_ui() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "InterrogationHUD"
	hud_canvas.layer = 10
	add_child(hud_canvas)

	var root_control := Control.new()
	root_control.name = "UIRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(root_control)

	# -----------------------------------------------------------------------
	# 1. TOP STATUS BAR
	# -----------------------------------------------------------------------
	var top_bar := PanelContainer.new()
	top_bar.anchor_left = 0.0; top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0; top_bar.anchor_bottom = 0.0
	top_bar.offset_bottom = 54.0
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.012, 0.015, 0.022, 0.95)
	top_style.border_width_bottom = 2
	top_style.border_color = Color(0.55, 0.44, 0.28, 0.8)
	top_style.content_margin_left = 24.0; top_style.content_margin_right = 24.0
	top_bar.add_theme_stylebox_override("panel", top_style)
	root_control.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_bar.add_child(top_hbox)

	var title_vbox := VBoxContainer.new()
	top_hbox.add_child(title_vbox)
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bar_title := Label.new()
	bar_title.text = "HOLLOWCREEK: THE INTERROGATION CHAMBER"
	bar_title.add_theme_font_size_override("font_size", 16)
	bar_title.add_theme_color_override("font_color", Color(0.92, 0.78, 0.52))
	title_vbox.add_child(bar_title)

	var bar_sub := Label.new()
	bar_sub.text = "Inquisitor from High Court   ·   Examine behavioral anomalies and uncover the killer"
	bar_sub.add_theme_font_size_override("font_size", 11)
	bar_sub.add_theme_color_override("font_color", Color(0.70, 0.72, 0.76))
	title_vbox.add_child(bar_sub)

	# Return to village button
	var return_btn := Button.new()
	return_btn.text = "  ← Return to Village [Esc]  "
	return_btn.focus_mode = Control.FOCUS_NONE
	var ret_style := StyleBoxFlat.new()
	ret_style.bg_color = Color(0.22, 0.16, 0.12, 0.9)
	ret_style.border_color = Color(0.68, 0.52, 0.32)
	ret_style.set_border_width_all(1)
	ret_style.set_corner_radius_all(4)
	ret_style.content_margin_left = 12; ret_style.content_margin_right = 12
	return_btn.add_theme_stylebox_override("normal", ret_style)
	return_btn.pressed.connect(return_to_village)
	top_hbox.add_child(return_btn)

	# -----------------------------------------------------------------------
	# 2. LEFT PANEL — SUSPECT SELECTOR LIST
	# -----------------------------------------------------------------------
	var left_panel := PanelContainer.new()
	left_panel.anchor_left = 0.0; left_panel.anchor_right = 0.0
	left_panel.anchor_top = 0.0; left_panel.anchor_bottom = 1.0
	left_panel.offset_top = 64.0; left_panel.offset_left = 16.0
	left_panel.offset_right = 310.0; left_panel.offset_bottom = -16.0
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = Color(0.015, 0.018, 0.026, 0.94)
	left_style.border_color = Color(0.48, 0.40, 0.30, 0.7)
	left_style.set_border_width_all(1)
	left_style.set_corner_radius_all(8)
	left_style.content_margin_left = 14; left_style.content_margin_right = 14
	left_style.content_margin_top = 14; left_style.content_margin_bottom = 14
	left_panel.add_theme_stylebox_override("panel", left_style)
	root_control.add_child(left_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_vbox)

	var list_header := Label.new()
	list_header.text = "VILLAGE SUSPECTS"
	list_header.add_theme_font_size_override("font_size", 14)
	list_header.add_theme_color_override("font_color", Color(0.95, 0.82, 0.58))
	left_vbox.add_child(list_header)

	var list_sub := Label.new()
	list_sub.text = "Click to summon into the chamber:"
	list_sub.add_theme_font_size_override("font_size", 11)
	list_sub.add_theme_color_override("font_color", Color(0.68, 0.70, 0.75))
	left_vbox.add_child(list_sub)

	var hsep1 := HSeparator.new()
	left_vbox.add_child(hsep1)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(scroll)

	var buttons_vbox := VBoxContainer.new()
	buttons_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(buttons_vbox)

	var all_suspects := SuspectDatabaseScript.get_all_suspects()
	for s in all_suspects:
		var s_id: String = s["id"]
		var btn := Button.new()
		btn.text = s["name"] + "\n[" + s["role"] + "]"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = Color(0.08, 0.09, 0.12, 0.90)
		b_style.border_color = Color(0.35, 0.32, 0.28)
		b_style.set_border_width_all(1)
		b_style.set_corner_radius_all(4)
		b_style.content_margin_left = 10; b_style.content_margin_right = 10
		b_style.content_margin_top = 6; b_style.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", b_style)

		btn.pressed.connect(func(): summon_suspect(s_id))
		buttons_vbox.add_child(btn)
		suspect_buttons[s_id] = btn

	# -----------------------------------------------------------------------
	# 3. CENTER / BOTTOM PANEL — INTERROGATION DASHBOARD
	# -----------------------------------------------------------------------
	var center_panel := PanelContainer.new()
	center_panel.anchor_left = 0.5; center_panel.anchor_right = 0.5
	center_panel.anchor_top = 1.0; center_panel.anchor_bottom = 1.0
	center_panel.offset_left = -270.0; center_panel.offset_right = 480.0
	center_panel.offset_top = -370.0; center_panel.offset_bottom = -16.0
	var center_style := StyleBoxFlat.new()
	center_style.bg_color = Color(0.015, 0.020, 0.030, 0.94)
	center_style.border_color = Color(0.58, 0.48, 0.35, 0.85)
	center_style.set_border_width_all(1)
	center_style.set_corner_radius_all(10)
	center_style.content_margin_left = 18; center_style.content_margin_right = 18
	center_style.content_margin_top = 12; center_style.content_margin_bottom = 12
	center_panel.add_theme_stylebox_override("panel", center_style)
	root_control.add_child(center_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 8)
	center_panel.add_child(center_vbox)

	# Suspect Banner (Name, Role, Stress)
	var banner_hbox := HBoxContainer.new()
	center_vbox.add_child(banner_hbox)

	var name_vbox := VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_hbox.add_child(name_vbox)

	name_banner_label = Label.new()
	name_banner_label.text = "Garrick Thorne"
	name_banner_label.add_theme_font_size_override("font_size", 18)
	name_banner_label.add_theme_color_override("font_color", Color(0.96, 0.85, 0.55))
	name_vbox.add_child(name_banner_label)

	role_banner_label = Label.new()
	role_banner_label.text = "Harbour Master  ·  Seated opposite table"
	role_banner_label.add_theme_font_size_override("font_size", 12)
	role_banner_label.add_theme_color_override("font_color", Color(0.70, 0.72, 0.78))
	name_vbox.add_child(role_banner_label)

	# Stress Bar
	var stress_vbox := VBoxContainer.new()
	stress_vbox.custom_minimum_size = Vector2(180, 0)
	banner_hbox.add_child(stress_vbox)

	stress_label = Label.new()
	stress_label.text = "STRESS: 65% [ELEVATED]"
	stress_label.add_theme_font_size_override("font_size", 11)
	stress_label.add_theme_color_override("font_color", Color(0.90, 0.60, 0.30))
	stress_vbox.add_child(stress_label)

	stress_progress = ProgressBar.new()
	stress_progress.custom_minimum_size = Vector2(180, 12)
	stress_progress.value = 65
	stress_progress.max_value = 100
	stress_progress.show_percentage = false
	stress_vbox.add_child(stress_progress)

	# Behavioral Anomaly Box
	anomaly_box = PanelContainer.new()
	var anom_style := StyleBoxFlat.new()
	anom_style.bg_color = Color(0.18, 0.08, 0.06, 0.85)
	anom_style.border_color = Color(0.85, 0.35, 0.25, 0.8)
	anom_style.set_border_width_all(1)
	anom_style.set_corner_radius_all(4)
	anom_style.content_margin_left = 10; anom_style.content_margin_right = 10
	anom_style.content_margin_top = 4; anom_style.content_margin_bottom = 4
	anomaly_box.add_theme_stylebox_override("panel", anom_style)
	center_vbox.add_child(anomaly_box)

	anomaly_label = Label.new()
	anomaly_label.text = "[ANOMALY]: Constantly checks heavy brass watch with trembling fingers."
	anomaly_label.add_theme_font_size_override("font_size", 12)
	anomaly_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.55))
	anomaly_box.add_child(anomaly_label)

	# Dialogue Transcript
	dialogue_log = RichTextLabel.new()
	dialogue_log.bbcode_enabled = true
	dialogue_log.scroll_following = true
	dialogue_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_log.custom_minimum_size = Vector2(0, 140)
	center_vbox.add_child(dialogue_log)

	# Quick Action Buttons Row
	var actions_hbox := HBoxContainer.new()
	actions_hbox.add_theme_constant_override("separation", 6)
	center_vbox.add_child(actions_hbox)

	action_btn_alibi = _create_action_button("1. Question Alibi", Color(0.20, 0.28, 0.42))
	action_btn_alibi.pressed.connect(_on_alibi_pressed)
	actions_hbox.add_child(action_btn_alibi)

	action_btn_motive = _create_action_button("2. Question Motive", Color(0.28, 0.24, 0.38))
	action_btn_motive.pressed.connect(_on_motive_pressed)
	actions_hbox.add_child(action_btn_motive)

	action_btn_evidence = _create_action_button("3. Confront Evidence", Color(0.35, 0.25, 0.15))
	action_btn_evidence.pressed.connect(_toggle_evidence_panel)
	actions_hbox.add_child(action_btn_evidence)

	action_btn_secret = _create_action_button("4. Press on Secret", Color(0.45, 0.18, 0.18))
	action_btn_secret.pressed.connect(_on_press_secret_pressed)
	actions_hbox.add_child(action_btn_secret)

	action_btn_accuse = _create_action_button("5. ACCUSE AS KILLER!", Color(0.65, 0.12, 0.12))
	action_btn_accuse.pressed.connect(_on_accuse_pressed)
	actions_hbox.add_child(action_btn_accuse)

	# Freeform Question Input Row
	var input_hbox := HBoxContainer.new()
	input_hbox.add_theme_constant_override("separation", 8)
	center_vbox.add_child(input_hbox)

	input_field = LineEdit.new()
	input_field.placeholder_text = "Ask a question (e.g. key, stiletto, ledger, boots, alibi, poison, raven)..."
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.text_submitted.connect(_on_custom_question_submitted)
	input_hbox.add_child(input_field)

	var send_btn := Button.new()
	send_btn.text = " Question "
	send_btn.pressed.connect(func(): _on_custom_question_submitted(input_field.text))
	input_hbox.add_child(send_btn)

	# -----------------------------------------------------------------------
	# 4. EVIDENCE POPUP PANEL (Confronting with physical clues)
	# -----------------------------------------------------------------------
	evidence_panel = PanelContainer.new()
	evidence_panel.anchor_left = 0.5; evidence_panel.anchor_right = 0.5
	evidence_panel.anchor_top = 0.5; evidence_panel.anchor_bottom = 0.5
	evidence_panel.offset_left = 50.0; evidence_panel.offset_right = 440.0
	evidence_panel.offset_top = -220.0; evidence_panel.offset_bottom = 80.0
	evidence_panel.visible = false
	var ev_style := StyleBoxFlat.new()
	ev_style.bg_color = Color(0.02, 0.025, 0.035, 0.98)
	ev_style.border_color = Color(0.85, 0.65, 0.35)
	ev_style.set_border_width_all(2)
	ev_style.set_corner_radius_all(8)
	ev_style.content_margin_left = 16; ev_style.content_margin_right = 16
	ev_style.content_margin_top = 12; ev_style.content_margin_bottom = 12
	evidence_panel.add_theme_stylebox_override("panel", ev_style)
	root_control.add_child(evidence_panel)

	evidence_container = VBoxContainer.new()
	evidence_container.add_theme_constant_override("separation", 6)
	evidence_panel.add_child(evidence_container)

	var ev_title := Label.new()
	ev_title.text = "SELECT PHYSICAL EVIDENCE TO CONFRONT SUSPECT:"
	ev_title.add_theme_font_size_override("font_size", 12)
	ev_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	evidence_container.add_child(ev_title)

	for clue in available_clues:
		var c_id: String = clue["id"]
		var c_btn := Button.new()
		c_btn.text = clue["name"] + "\n— " + clue["desc"]
		c_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		c_btn.focus_mode = Control.FOCUS_NONE
		c_btn.add_theme_font_size_override("font_size", 11)
		c_btn.pressed.connect(func(): _confront_clue(c_id))
		evidence_container.add_child(c_btn)

	var close_ev_btn := Button.new()
	close_ev_btn.text = " Close Evidence "
	close_ev_btn.pressed.connect(func(): evidence_panel.visible = false)
	evidence_container.add_child(close_ev_btn)

func _create_action_button(b_text: String, bg_col: Color) -> Button:
	var btn := Button.new()
	btn.text = b_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_color = bg_col.lightened(0.3)
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.content_margin_top = 6; st.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", st)
	return btn

# ===========================================================================
# SUSPECT SUMMONING & WALK-IN LOGIC
# ===========================================================================
func summon_suspect(suspect_id: String) -> void:
	if _is_walking_in:
		return
	if active_suspect_data.get("id", "") == suspect_id and current_suspect_node != null:
		return

	active_suspect_data = SuspectDatabaseScript.get_suspect_data(suspect_id)
	var s_name: String = active_suspect_data.get("name", "Unknown")
	var s_role: String = active_suspect_data.get("role", "Villager")
	var s_personality: String = active_suspect_data.get("personality", "")

	name_banner_label.text = s_name
	if not s_personality.is_empty():
		role_banner_label.text = s_role + "  ·  [" + s_personality + "]"
	else:
		role_banner_label.text = s_role + "  ·  Questioning in progress"

	# Despawn previous suspect
	if current_suspect_node:
		current_suspect_node.queue_free()
		current_suspect_node = null

	evidence_panel.visible = false
	dialogue_history = ""
	dialogue_log.clear()
	_update_suspect_stress_ui()

	# Spawn new suspect at the doorway
	_spawn_suspect_model(suspect_id)

	# Trigger walk-in
	_is_walking_in = true
	_walk_time = 0.0
	_set_buttons_enabled(false)

	# Play door creak
	append_system_message("The iron latch lifts. " + s_name + " steps into the interrogation chamber.")

func _spawn_suspect_model(suspect_id: String) -> void:
	var scn_path: String = active_suspect_data.get("model_scene", "")
	var node: Node3D = null

	if not scn_path.is_empty() and ResourceLoader.exists(scn_path):
		var p_scn := load(scn_path) as PackedScene
		if p_scn:
			node = p_scn.instantiate() as Node3D

	if not node:
		# Fallback to procedural NPC model
		node = CinematicCharactersScript.build_mercenary(false)

	current_suspect_node = node
	current_suspect_node.name = "ActiveSuspect_" + suspect_id
	current_suspect_node.position = Vector3(0, 0, _walk_start_z)
	current_suspect_node.rotation_degrees.y = 180.0 # Facing forward into room
	room_root.add_child(current_suspect_node)

func _process(delta: float) -> void:
	# Subtle candle flicker
	if table_omni_light:
		table_omni_light.light_energy = 1.4 + sin(Time.get_ticks_msec() * 0.012) * 0.15

	# Camera micro-sway
	if active_camera:
		var t := Time.get_ticks_msec() * 0.001
		active_camera.position.x = sin(t * 0.8) * 0.01
		active_camera.position.y = 1.35 + cos(t * 1.1) * 0.008

	# Walk-in interpolation
	if _is_walking_in and current_suspect_node:
		_walk_time += delta
		var norm := clampf(_walk_time / _walk_duration, 0.0, 1.0)
		var smooth_norm := norm * norm * (3.0 - 2.0 * norm)

		current_suspect_node.position.z = lerpf(_walk_start_z, _walk_target_z, smooth_norm)

		# Animate walking limbs
		var leg_l = current_suspect_node.get_node_or_null("LegPivotL")
		var leg_r = current_suspect_node.get_node_or_null("LegPivotR")
		var arm_l = current_suspect_node.get_node_or_null("ArmPivotL")
		var arm_r = current_suspect_node.get_node_or_null("ArmPivotR")
		var leg_swing := sin(_walk_time * 8.0) * 0.35

		if leg_l: leg_l.rotation.x = leg_swing
		if leg_r: leg_r.rotation.x = -leg_swing
		if arm_l: arm_l.rotation.x = -leg_swing * 0.6
		if arm_r: arm_r.rotation.x = leg_swing * 0.6

		if norm >= 1.0:
			_is_walking_in = false
			_seat_suspect()

func _seat_suspect() -> void:
	if not current_suspect_node:
		return

	# Align with suspect chair
	current_suspect_node.position = Vector3(0, 0.0, 1.25)
	current_suspect_node.rotation_degrees.y = 180.0

	# Seated pose: knees bent under table, hands on armrests
	var leg_l = current_suspect_node.get_node_or_null("LegPivotL")
	var leg_r = current_suspect_node.get_node_or_null("LegPivotR")
	var arm_l = current_suspect_node.get_node_or_null("ArmPivotL")
	var arm_r = current_suspect_node.get_node_or_null("ArmPivotR")

	if leg_l: leg_l.rotation_degrees = Vector3(-80.0, 5.0, 0)
	if leg_r: leg_r.rotation_degrees = Vector3(-80.0, -5.0, 0)
	if arm_l: arm_l.rotation_degrees = Vector3(15.0, 0, 10.0)
	if arm_r: arm_r.rotation_degrees = Vector3(15.0, 0, -10.0)

	_set_buttons_enabled(true)

	var s_name: String = active_suspect_data.get("name", "Suspect")
	var s_greet: String = active_suspect_data.get("greeting", "Hello, Detective.")
	append_npc_message(s_name, s_greet)

	# Display initial anomaly
	_trigger_random_anomaly()

# ===========================================================================
# INTERROGATION ACTIONS & ANOMALY MECHANICS
# ===========================================================================
func _on_alibi_pressed() -> void:
	if active_suspect_data.is_empty(): return
	var s_name: String = active_suspect_data["name"]
	append_player_message("State your whereabouts during the murder of Lord Aldric Vale.")
	
	var reply: String = active_suspect_data.get("alibi_statement", "I was asleep.")
	append_npc_message(s_name, reply)
	
	_adjust_stress(10)
	_trigger_random_anomaly()

func _on_motive_pressed() -> void:
	if active_suspect_data.is_empty(): return
	var s_name: String = active_suspect_data["name"]
	append_player_message("What was your true connection to Lord Aldric? Did you harbor malice toward him?")
	
	var reply: String = active_suspect_data.get("motive_statement", "None.")
	append_npc_message(s_name, reply)
	
	_adjust_stress(10)
	_trigger_random_anomaly()

func _toggle_evidence_panel() -> void:
	evidence_panel.visible = not evidence_panel.visible

func _confront_clue(clue_id: String) -> void:
	evidence_panel.visible = false
	if active_suspect_data.is_empty(): return

	var s_name: String = active_suspect_data["name"]
	var s_id: String = active_suspect_data["id"]
	var reactions: Dictionary = active_suspect_data.get("clue_reactions", {})

	var clue_name: String = clue_id
	for c in available_clues:
		if c["id"] == clue_id:
			clue_name = c["name"]
			break

	append_player_message("I am presenting this evidence: [b]" + clue_name + "[/b]. How do you explain this?")

	if reactions.has(clue_id):
		var reply: String = reactions[clue_id]
		append_npc_message(s_name, reply)
		_adjust_stress(25)
		
		# Flag contradiction
		suspect_states[s_id]["contradiction"] = true
		append_anomaly_alert("CONTRADICTION EXPOSED: " + active_suspect_data.get("alibi_contradiction", "Story collapsed."))
	else:
		append_npc_message(s_name, "That means nothing to me, Detective. It has nothing to do with my affairs.")
		_adjust_stress(5)

func _on_press_secret_pressed() -> void:
	if active_suspect_data.is_empty(): return
	var s_name: String = active_suspect_data["name"]
	var s_id: String = active_suspect_data["id"]

	append_player_message("Stop lying to me. We have dissected your alibi. Confess your dark secret now!")

	var has_contradiction: bool = suspect_states[s_id].get("contradiction", false)
	var current_stress: int = suspect_states[s_id].get("stress", 50)

	if has_contradiction or current_stress >= 85:
		suspect_states[s_id]["confessed"] = true
		var confession: String = active_suspect_data.get("secret_confession", "I did it...")
		append_npc_message(s_name, confession)
		_adjust_stress(30)
		append_anomaly_alert("FULL CONFESSION UNLOCKED: " + active_suspect_data.get("dark_secret", ""))
	else:
		var denial: String = active_suspect_data.get("secret_denial", "I know nothing!")
		append_npc_message(s_name, denial)
		_adjust_stress(15)
		append_anomaly_alert("ANOMALY: Defensive counter-attack. Confront with physical evidence first!")

func _on_accuse_pressed() -> void:
	if active_suspect_data.is_empty(): return
	var s_name: String = active_suspect_data["name"]
	var s_id: String = active_suspect_data["id"]
	var is_killer: bool = active_suspect_data.get("is_the_killer", false)

	append_player_message("Under High Court authority, I formally ACCUSE YOU, " + s_name + ", OF THE MURDER OF LORD ALDRIC VALE!")

	if is_killer:
		# Killer exposed! (Harbour Master Garrick Thorne)
		append_npc_message(s_name, "You figured it out... damn you! Yes! I contracted the strike! But Hollow Creek belongs to the islanders now, not royal leeches!")
		append_system_message("══════════════════════════════════════════════════════════════")
		append_system_message("[b][color=#66ff66]★ CASE SOLVED! THE MASTERMIND IS BROUGHT TO JUSTICE! ★[/color][/b]")
		append_system_message("Harbour Master Garrick Thorne is convicted of orchestrating the assassination.")
		append_system_message("Town guards enter the chamber and secure the prisoner in irons.")
		append_system_message("══════════════════════════════════════════════════════════════")
		_adjust_stress(100)
		if auto_transition_on_accusation:
			_trigger_ending_cutscene("res://scenes/cinematic_cutscene2.tscn")
	else:
		# False accusation! (Player other than harbour master)
		append_npc_message(s_name, "Murder?! Have you lost your mind, Inquisitor?! I have my sins, but I am NO KILLER! The physical evidence doesn't match me!")
		append_anomaly_alert("FALSE ACCUSATION: " + s_name + " holds a dark secret, but is NOT the murderer!")
		_adjust_stress(20)
		if auto_transition_on_accusation:
			_trigger_ending_cutscene("res://scenes/cinematic_cutscene.tscn")

func _trigger_ending_cutscene(target_scene: String) -> void:
	if _is_transitioning_scene:
		return
	_is_transitioning_scene = true
	_set_buttons_enabled(false)
	if input_field and is_instance_valid(input_field):
		input_field.editable = false

	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		var canvas := CanvasLayer.new()
		canvas.layer = 120
		var fade := ColorRect.new()
		fade.color = Color(0, 0, 0, 0)
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(fade)
		get_tree().root.add_child(canvas)

		var tween := canvas.create_tween()
		tween.tween_property(fade, "color:a", 1.0, 0.6)
		if ambient_audio_player and is_instance_valid(ambient_audio_player) and ambient_audio_player.playing:
			var at := create_tween()
			at.tween_property(ambient_audio_player, "volume_db", -80.0, 0.6)
		tween.tween_callback(func():
			get_tree().change_scene_to_file(target_scene)
			canvas.queue_free()
		)
	)

func _on_custom_question_submitted(text: String) -> void:
	var q := text.strip_edges()
	if q.is_empty() or active_suspect_data.is_empty():
		return
	if _is_waiting_for_ai:
		return

	input_field.text = ""
	append_player_message(q)

	var s_id: String = active_suspect_data.get("id", "")
	if not conversation_histories.has(s_id):
		conversation_histories[s_id] = []

	conversation_histories[s_id].append({"role": "user", "text": q})

	# Feedback while waiting
	_is_waiting_for_ai = true
	input_field.editable = false
	input_field.placeholder_text = "Observing " + active_suspect_data.get("name", "suspect") + "'s reaction..."

	var payload := {
		"suspect_id": s_id,
		"history": conversation_histories[s_id],
		"turn_count": conversation_histories[s_id].size()
	}
	var json_str := JSON.stringify(payload)
	var headers := ["Content-Type: application/json"]

	var err := ai_http_request.request(
		"http://127.0.0.1:8765/chat",
		headers,
		HTTPClient.METHOD_POST,
		json_str
	)

	if err != OK:
		_is_waiting_for_ai = false
		input_field.editable = true
		input_field.placeholder_text = "Ask a question (e.g. key, stiletto, ledger, boots, alibi, poison, raven)..."
		_execute_local_fallback_question(q)

func _on_ai_chat_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_waiting_for_ai = false
	if input_field and is_instance_valid(input_field):
		input_field.editable = true
		input_field.placeholder_text = "Ask a question (e.g. key, stiletto, ledger, boots, alibi, poison, raven)..."

	var s_name: String = active_suspect_data.get("name", "Suspect")
	var s_id: String = active_suspect_data.get("id", "")

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var response_str := body.get_string_from_utf8()
		var json = JSON.new()
		var parse_err := json.parse(response_str)
		if parse_err == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			var reply: String = str(data.get("reply", "")).strip_edges()
			var stress_delta: int = int(data.get("stress_delta", 5))
			var anomaly = data.get("anomaly")

			if not reply.is_empty():
				append_npc_message(s_name, reply)
				_adjust_stress(stress_delta)

				if not conversation_histories.has(s_id):
					conversation_histories[s_id] = []
				conversation_histories[s_id].append({"role": "assistant", "text": reply})

				if anomaly != null and str(anomaly) != "" and str(anomaly) != "null":
					anomaly_label.text = "[ANOMALY DETECTED]: " + str(anomaly)
					append_anomaly_alert("BEHAVIORAL TELL: " + str(anomaly))
				else:
					_trigger_random_anomaly()
				return

	# Fallback if server returned non-200 or parse failed
	var last_q: String = ""
	if conversation_histories.has(s_id) and conversation_histories[s_id].size() > 0:
		last_q = conversation_histories[s_id][-1].get("text", "")
	_execute_local_fallback_question(last_q)

func _execute_local_fallback_question(q: String) -> void:
	var q_lower := q.to_lower()
	var s_name: String = active_suspect_data.get("name", "Suspect")
	var s_id: String = active_suspect_data.get("id", "")
	var keywords: Dictionary = active_suspect_data.get("general_keywords", {})
	var found_reply: String = ""

	for key: String in keywords.keys():
		var parts: Array = key.split("|")
		for kw: String in parts:
			if kw.strip_edges() in q_lower:
				found_reply = keywords[key]
				break
		if not found_reply.is_empty():
			break

	if found_reply.is_empty():
		var suspicious: String = active_suspect_data.get("suspicious_trait", "")
		if not suspicious.is_empty():
			found_reply = "I have told you all that concerns my affairs, Detective. " + suspicious
		else:
			found_reply = "I cannot help you with that, Detective. Ask about matters concerning my duties."

	append_npc_message(s_name, found_reply)
	if not conversation_histories.has(s_id):
		conversation_histories[s_id] = []
	conversation_histories[s_id].append({"role": "assistant", "text": found_reply})
	_adjust_stress(8)
	_trigger_random_anomaly()

# ===========================================================================
# ANOMALY & STRESS CONTROLLER
# ===========================================================================
func _trigger_random_anomaly() -> void:
	if active_suspect_data.is_empty(): return
	var anomalies: Array = active_suspect_data.get("behavioral_anomalies", [])
	if anomalies.size() > 0:
		var anom: String = str(anomalies[randi() % anomalies.size()])
		anomaly_label.text = "[ANOMALY DETECTED]: " + anom

func _adjust_stress(amount: int) -> void:
	if active_suspect_data.is_empty(): return
	var s_id: String = active_suspect_data["id"]
	var cur: int = suspect_states[s_id].get("stress", 50)
	var next_val := clampi(cur + amount, 0, 100)
	suspect_states[s_id]["stress"] = next_val
	_update_suspect_stress_ui()

func _update_suspect_stress_ui() -> void:
	if active_suspect_data.is_empty(): return
	var s_id: String = active_suspect_data["id"]
	var val: int = suspect_states[s_id].get("stress", 50)
	stress_progress.value = val

	if val < 40:
		stress_label.text = "STRESS: %d%% [CALM]" % val
		stress_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5))
	elif val < 70:
		stress_label.text = "STRESS: %d%% [ELEVATED]" % val
		stress_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	elif val < 90:
		stress_label.text = "STRESS: %d%% [HIGH ANOMALY]" % val
		stress_label.add_theme_color_override("font_color", Color(1.0, 0.50, 0.25))
	else:
		stress_label.text = "STRESS: %d%% [CRITICAL BREAKDOWN]" % val
		stress_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))

func _set_buttons_enabled(enabled: bool) -> void:
	action_btn_alibi.disabled = not enabled
	action_btn_motive.disabled = not enabled
	action_btn_evidence.disabled = not enabled
	action_btn_secret.disabled = not enabled
	action_btn_accuse.disabled = not enabled

# ===========================================================================
# MESSAGE TRANSCRIPT HELPERS
# ===========================================================================
func append_player_message(text: String) -> void:
	dialogue_history += "You (Detective): " + text + "\n\n"
	dialogue_log.append_text("[color=#8dc8ff][b]You (Detective):[/b][/color] " + text + "\n\n")

func append_npc_message(speaker: String, text: String) -> void:
	dialogue_history += speaker + ": " + text + "\n\n"
	dialogue_log.append_text("[color=#f4d06f][b]" + speaker + ":[/b][/color] " + text + "\n\n")

func append_anomaly_alert(text: String) -> void:
	dialogue_history += "► " + text + "\n\n"
	dialogue_log.append_text("[color=#ff6666][b]► " + text + "[/b][/color]\n\n")

func append_system_message(text: String) -> void:
	dialogue_history += text + "\n\n"
	dialogue_log.append_text("[color=#aaaaaa][i]" + text + "[/i][/color]\n\n")

func get_dialogue_text() -> String:
	return dialogue_history

# ===========================================================================
# RETURN TO VILLAGE TRANSITION
# ===========================================================================
func return_to_village() -> void:
	if _is_transitioning_scene:
		return
	_is_transitioning_scene = true

	print("[InterrogationChamber] Returning to Hollow Creek village...")

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade)
	get_tree().root.add_child(canvas)

	var tween := canvas.create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.45)
	if ambient_audio_player and is_instance_valid(ambient_audio_player) and ambient_audio_player.playing:
		var audio_tween := create_tween()
		audio_tween.tween_property(ambient_audio_player, "volume_db", -80.0, 0.45)
	tween.tween_callback(func():
		var err := get_tree().change_scene_to_file("res://scenes/town.tscn")
		if err != OK:
			print("ERROR: Failed to load town.tscn Code: ", err)
		canvas.queue_free()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if evidence_panel.visible:
			evidence_panel.visible = false
			get_viewport().set_input_as_handled()
		else:
			return_to_village()
			get_viewport().set_input_as_handled()

# ===========================================================================
# GEOMETRY HELPERS
# ===========================================================================
func _create_material(color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _create_box(parent: Node3D, b_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = b_name
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _create_cylinder(parent: Node3D, c_name: String, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = c_name
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
