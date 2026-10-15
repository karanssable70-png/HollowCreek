class_name EndingCutscene
extends Control

## EndingCutscene
## Plays atmospheric medieval illustrated ending cutscenes with Ken Burns camera motion,
## cinematic widescreen letterboxing, gothic subtitles, and a dramatic "GAME OVER" slate
## rendered using the Citadel of Blackrose font.
##
## Supported Endings:
## - DEFEAT_WRONG_GUESS: Triggered when player accuses an innocent villager.
## - VICTORY_HARBOUR_MASTER: Triggered when player accuses Harbour Master Garrick Thorne.

enum EndingType {
	DEFEAT_WRONG_GUESS,
	VICTORY_HARBOUR_MASTER
}

signal cutscene_started(ending_name: String)
signal scene_changed(scene_index: int, act_title: String)
signal cutscene_finished(ending_name: String)
signal game_over_displayed

@export var ending_type: EndingType = EndingType.DEFEAT_WRONG_GUESS
@export var scene_duration: float = 5.0
@export var transition_duration: float = 1.2
@export var allow_skip: bool = true
@export var auto_start: bool = true

# Font asset
const FONT_CITADEL: Font = preload("res://assets/fonts/citadel_of_blackrose.ttf")

# Texture assets
const TEX_SCENE1: Texture2D = preload("res://assets/scene1.png")
const TEX_SCENE2: Texture2D = preload("res://assets/scene2.png")
const TEX_SCENE3: Texture2D = preload("res://assets/scene3.png")
const TEX_SCENE4: Texture2D = preload("res://assets/scene4.png")

const TEX_SCENE_ONE: Texture2D = preload("res://assets/sceneone.png")
const TEX_SCENE_TWO: Texture2D = preload("res://assets/scenetwo.png")
const TEX_SCENE_THREE: Texture2D = preload("res://assets/scenethree.png")
const TEX_SCENE_FOUR: Texture2D = preload("res://assets/scenefour.png")

# Audio assets
const AUDIO_DEFEAT: AudioStream = preload("res://assets/cutscene_soundtrack.ogg")
const AUDIO_VICTORY: AudioStream = preload("res://assets/victory_soundtrack.ogg")

# Scene references
var background: ColorRect
var scene_viewport: Control
var vignette_overlay: ColorRect
var letterbox_top: ColorRect
var letterbox_bottom: ColorRect
var ui_root: Control
var act_label: Label
var subtitle_label: Label
var skip_hint: Label
var audio_player: AudioStreamPlayer
var black_fade: ColorRect

# Game Over Slate
var game_over_panel: PanelContainer
var game_over_title: Label
var game_over_sub: Label
var game_over_flavor: Label
var btn_replay: Button
var btn_continue: Button

# Runtime state
var active_scenes_data: Array[Dictionary] = []
var texture_rects: Array[TextureRect] = []
var current_scene_index: int = 0
var is_playing: bool = false
var is_finished: bool = false
var is_game_over_visible: bool = false
var current_tween: Tween = null
var camera_tween: Tween = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui_nodes()
	_setup_ending_data()
	
	if auto_start:
		get_tree().create_timer(0.2).timeout.connect(start_cutscene)

func _build_ui_nodes() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 1. Dark solid background
	background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.01, 0.012, 0.016, 1.0)
	add_child(background)
	
	# 2. Scene Viewport for image layering
	scene_viewport = Control.new()
	scene_viewport.name = "SceneViewport"
	scene_viewport.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene_viewport)
	
	# 3. Vignette Shader Overlay
	vignette_overlay = ColorRect.new()
	vignette_overlay.name = "VignetteOverlay"
	vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vig_shader: Shader = load("res://shaders/vignette.gdshader") as Shader
	if vig_shader:
		var mat := ShaderMaterial.new()
		mat.shader = vig_shader
		mat.set_shader_parameter("vignette_intensity", 0.90)
		mat.set_shader_parameter("vignette_opacity", 0.70)
		mat.set_shader_parameter("vignette_color", Color(0.015, 0.01, 0.025, 1.0))
		vignette_overlay.material = mat
	add_child(vignette_overlay)
	
	# 4. Cinematic Letterbox Bars
	var letterbox := Control.new()
	letterbox.name = "Letterbox"
	letterbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letterbox)
	
	letterbox_top = ColorRect.new()
	letterbox_top.name = "TopBar"
	letterbox_top.anchor_left = 0.0; letterbox_top.anchor_right = 1.0
	letterbox_top.offset_top = 0.0; letterbox_top.offset_bottom = 75.0
	letterbox_top.color = Color(0.0, 0.0, 0.0, 1.0)
	letterbox.add_child(letterbox_top)
	
	letterbox_bottom = ColorRect.new()
	letterbox_bottom.name = "BottomBar"
	letterbox_bottom.anchor_left = 0.0; letterbox_bottom.anchor_right = 1.0
	letterbox_bottom.anchor_top = 1.0; letterbox_bottom.anchor_bottom = 1.0
	letterbox_bottom.offset_top = -75.0; letterbox_bottom.offset_bottom = 0.0
	letterbox_bottom.color = Color(0.0, 0.0, 0.0, 1.0)
	letterbox.add_child(letterbox_bottom)
	
	# 5. UI Layer (Subtitles, Hints, Act Indicator)
	ui_root = Control.new()
	ui_root.name = "UI"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)
	
	act_label = Label.new()
	act_label.name = "ActLabel"
	act_label.offset_left = 32.0; act_label.offset_top = 24.0
	act_label.add_theme_font_size_override("font_size", 14)
	act_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55, 0.85))
	ui_root.add_child(act_label)
	
	skip_hint = Label.new()
	skip_hint.name = "SkipHint"
	skip_hint.anchor_left = 1.0; skip_hint.anchor_right = 1.0
	skip_hint.offset_left = -340.0; skip_hint.offset_top = 24.0
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_hint.add_theme_font_size_override("font_size", 13)
	skip_hint.add_theme_color_override("font_color", Color(0.70, 0.72, 0.75, 0.7))
	skip_hint.text = "[Space / Click] Next  •  [Esc] Skip"
	ui_root.add_child(skip_hint)
	
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.anchor_top = 1.0; subtitle_label.anchor_bottom = 1.0
	subtitle_label.anchor_left = 0.0; subtitle_label.anchor_right = 1.0
	subtitle_label.offset_top = -140.0; subtitle_label.offset_bottom = -90.0
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_label.add_theme_constant_override("outline_size", 3)
	subtitle_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.9))
	ui_root.add_child(subtitle_label)
	
	# 6. Audio Player
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AudioPlayer"
	audio_player.volume_db = -2.0
	add_child(audio_player)
	
	# 7. Dedicated "GAME OVER" Gothic Slate
	_build_game_over_slate()
	
	# 8. Fullscreen Black Fade
	black_fade = ColorRect.new()
	black_fade.name = "BlackFade"
	black_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	black_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black_fade)

func _build_game_over_slate() -> void:
	game_over_panel = PanelContainer.new()
	game_over_panel.name = "GameOverSlate"
	game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_panel.visible = false
	game_over_panel.modulate.a = 0.0
	
	var slate_style := StyleBoxFlat.new()
	slate_style.bg_color = Color(0.015, 0.018, 0.024, 0.94)
	slate_style.border_color = Color(0.45, 0.12, 0.14) if ending_type == EndingType.DEFEAT_WRONG_GUESS else Color(0.65, 0.50, 0.22)
	slate_style.set_border_width_all(2)
	game_over_panel.add_theme_stylebox_override("panel", slate_style)
	add_child(game_over_panel)
	
	var center_box := CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_panel.add_child(center_box)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.custom_minimum_size = Vector2(900, 480)
	center_box.add_child(vbox)
	
	# Giant GAME OVER in Citadel of Blackrose font
	game_over_title = Label.new()
	game_over_title.name = "GameOverTitle"
	game_over_title.text = "GAME OVER"
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if FONT_CITADEL:
		game_over_title.add_theme_font_override("font", FONT_CITADEL)
	game_over_title.add_theme_font_size_override("font_size", 102)
	
	if ending_type == EndingType.DEFEAT_WRONG_GUESS:
		game_over_title.add_theme_color_override("font_color", Color(0.92, 0.28, 0.28))
		game_over_title.add_theme_color_override("font_shadow_color", Color(0.40, 0.05, 0.07, 0.95))
		game_over_title.add_theme_color_override("font_outline_color", Color(0.08, 0.01, 0.02, 1.0))
	else:
		game_over_title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48))
		game_over_title.add_theme_color_override("font_shadow_color", Color(0.45, 0.32, 0.08, 0.95))
		game_over_title.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 1.0))
		
	game_over_title.add_theme_constant_override("shadow_offset_x", 4)
	game_over_title.add_theme_constant_override("shadow_offset_y", 4)
	game_over_title.add_theme_constant_override("outline_size", 6)
	vbox.add_child(game_over_title)
	
	# Divider line
	var hsep := HSeparator.new()
	vbox.add_child(hsep)
	
	# Subtitle description
	game_over_sub = Label.new()
	game_over_sub.name = "GameOverSub"
	game_over_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if FONT_CITADEL:
		game_over_sub.add_theme_font_override("font", FONT_CITADEL)
	game_over_sub.add_theme_font_size_override("font_size", 28)
	game_over_sub.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	vbox.add_child(game_over_sub)
	
	game_over_flavor = Label.new()
	game_over_flavor.name = "GameOverFlavor"
	game_over_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_flavor.add_theme_font_size_override("font_size", 14)
	game_over_flavor.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78))
	vbox.add_child(game_over_flavor)
	
	# Button navigation bar
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_hbox)
	
	btn_replay = Button.new()
	btn_replay.text = "  [R] Replay Cinematic Cutscene  "
	btn_replay.focus_mode = Control.FOCUS_NONE
	btn_replay.pressed.connect(start_cutscene)
	_style_button(btn_replay, Color(0.20, 0.22, 0.28))
	btn_hbox.add_child(btn_replay)
	
	btn_continue = Button.new()
	btn_continue.focus_mode = Control.FOCUS_NONE
	btn_continue.pressed.connect(_on_continue_pressed)
	if ending_type == EndingType.DEFEAT_WRONG_GUESS:
		btn_continue.text = "  [Enter] Return to Interrogation Chamber  "
		_style_button(btn_continue, Color(0.48, 0.15, 0.15))
	else:
		btn_continue.text = "  [Enter] Return to Hollow Creek Village  "
		_style_button(btn_continue, Color(0.18, 0.42, 0.20))
	btn_hbox.add_child(btn_continue)

func _style_button(btn: Button, bg_col: Color) -> void:
	btn.add_theme_font_size_override("font_size", 14)
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_color = bg_col.lightened(0.3)
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.content_margin_left = 16; st.content_margin_right = 16
	st.content_margin_top = 10; st.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", st)

func _setup_ending_data() -> void:
	active_scenes_data.clear()
	
	for child in scene_viewport.get_children():
		child.queue_free()
	texture_rects.clear()
	
	if ending_type == EndingType.DEFEAT_WRONG_GUESS:
		act_label.text = "HOLLOWCREEK: THE CONDEMNATION OF THE INNOCENT"
		audio_player.stream = AUDIO_DEFEAT
		game_over_sub.text = "AN INNOCENT WAS CONDEMNED   ·   THE KILLER WALKS FREE"
		game_over_flavor.text = "Under the weight of your false accusation, an innocent villager was led away in chains.\nHarbour Master Garrick Thorne slips into the shadows unnoticed, his debts erased and his contract complete.\nHollow Creek remains in the grip of the syndicate."
		
		active_scenes_data = [
			{
				"texture": TEX_SCENE1,
				"subtitle": "Act I: You've guessed wrong.",
				"z_start": 1.00, "z_end": 1.15, "pan_x": 0.0, "pan_y": -22.0
			},
			{
				"texture": TEX_SCENE2,
				"subtitle": "Act II: Led in chains through the high fortress gate...",
				"z_start": 1.02, "z_end": 1.16, "pan_x": 0.0, "pan_y": 18.0
			},
			{
				"texture": TEX_SCENE3,
				"subtitle": "Act III: Flashback: Embarking on the voyage into the sunset...",
				"z_start": 1.00, "z_end": 1.14, "pan_x": 30.0, "pan_y": -15.0
			},
			{
				"texture": TEX_SCENE4,
				"subtitle": "Act IV: Sailing into the crimson dusk, never to return.",
				"z_start": 1.15, "z_end": 1.02, "pan_x": 35.0, "pan_y": 0.0
			}
		]
	else:
		act_label.text = "HOLLOWCREEK: THE MASTERMIND BROUGHT TO JUSTICE"
		audio_player.stream = AUDIO_VICTORY
		game_over_sub.text = "JUSTICE HAS PREVAILED   ·   THE HARBOUR MASTER CONDEMNED"
		game_over_flavor.text = "Your sharp eye pierced through the web of lies and financial fraud.\nHarbour Master Garrick Thorne is led in irons to the high fortress to answer for Lord Aldric Vale's assassination.\nHollow Creek is finally delivered from fear and extortion."
		
		active_scenes_data = [
			{
				"texture": TEX_SCENE_ONE,
				"subtitle": "Act I: You've guessed it right.",
				"z_start": 1.00, "z_end": 1.15, "pan_x": 0.0, "pan_y": -20.0
			},
			{
				"texture": TEX_SCENE_TWO,
				"subtitle": "Act II: The prisoner is marched before the high court...",
				"z_start": 1.02, "z_end": 1.16, "pan_x": 0.0, "pan_y": 20.0
			},
			{
				"texture": TEX_SCENE_THREE,
				"subtitle": "Act III: Confined behind the fortress iron bars.",
				"z_start": 1.00, "z_end": 1.18, "pan_x": 0.0, "pan_y": -15.0
			},
			{
				"texture": TEX_SCENE_FOUR,
				"subtitle": "Act IV: The kingdom celebrates VICTORY!",
				"z_start": 1.14, "z_end": 1.02, "pan_x": 0.0, "pan_y": 0.0
			}
		]
		
	# Instantiate TextureRect layers
	for i in range(active_scenes_data.size()):
		var tr := TextureRect.new()
		tr.texture = active_scenes_data[i]["texture"]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.pivot_offset = Vector2(640, 360)
		tr.modulate.a = 1.0 if i == 0 else 0.0
		scene_viewport.add_child(tr)
		texture_rects.append(tr)

func start_cutscene() -> void:
	if is_playing:
		return
		
	is_playing = true
	is_finished = false
	is_game_over_visible = false
	current_scene_index = 0
	game_over_panel.visible = false
	game_over_panel.modulate.a = 0.0
	skip_hint.visible = true
	subtitle_label.visible = true
	
	for i in range(texture_rects.size()):
		texture_rects[i].modulate.a = 1.0 if i == 0 else 0.0
		texture_rects[i].scale = Vector2.ONE
		texture_rects[i].position = Vector2.ZERO
		
	if audio_player and audio_player.stream:
		audio_player.play()
		
	cutscene_started.emit("defeat" if ending_type == EndingType.DEFEAT_WRONG_GUESS else "victory")
	
	# Smooth fade in from black
	var fade_in := create_tween()
	fade_in.tween_property(black_fade, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC)
	
	play_scene(0)

func play_scene(index: int) -> void:
	if index >= active_scenes_data.size():
		finish_cutscene()
		return
		
	current_scene_index = index
	var active_tr := texture_rects[index]
	var data: Dictionary = active_scenes_data[index]
	
	scene_changed.emit(index, str(data.get("subtitle", "")))
	
	# Subtitle animation
	subtitle_label.text = str(data.get("subtitle", ""))
	var sub_tw := create_tween()
	subtitle_label.modulate.a = 0.0
	sub_tw.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)
	
	# Ken Burns pan & zoom
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true)
	
	var z_s: float = float(data.get("z_start", 1.0))
	var z_e: float = float(data.get("z_end", 1.15))
	var p_x: float = float(data.get("pan_x", 0.0))
	var p_y: float = float(data.get("pan_y", 0.0))
	
	active_tr.scale = Vector2(z_s, z_s)
	active_tr.position = Vector2.ZERO
	camera_tween.tween_property(active_tr, "scale", Vector2(z_e, z_e), scene_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(active_tr, "position", Vector2(p_x, p_y), scene_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Schedule crossfade
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	var hold_time := maxf(0.0, scene_duration - transition_duration)
	current_tween.tween_interval(hold_time)
	current_tween.tween_callback(func(): transition_to_next(index))

func transition_to_next(index: int) -> void:
	if not is_playing:
		return
		
	var next_index := index + 1
	if next_index >= active_scenes_data.size():
		finish_cutscene()
		return
		
	var curr_tr := texture_rects[index]
	var next_tr := texture_rects[next_index]
	
	var fade_tw := create_tween().set_parallel(true)
	fade_tw.tween_property(curr_tr, "modulate:a", 0.0, transition_duration).set_trans(Tween.TRANS_SINE)
	fade_tw.tween_property(next_tr, "modulate:a", 1.0, transition_duration).set_trans(Tween.TRANS_SINE)
	fade_tw.tween_property(subtitle_label, "modulate:a", 0.0, 0.5)
	
	play_scene(next_index)

func finish_cutscene() -> void:
	if is_finished:
		return
	is_playing = false
	is_finished = true
	
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	skip_hint.visible = false
	subtitle_label.visible = false
	cutscene_finished.emit("defeat" if ending_type == EndingType.DEFEAT_WRONG_GUESS else "victory")
	
	# Transition into the GAME OVER Slate
	_display_game_over()

func _display_game_over() -> void:
	is_game_over_visible = true
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	
	var tw := create_tween()
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): game_over_displayed.emit())

func skip_to_next_scene() -> void:
	if not is_playing or is_finished:
		return
		
	var next_idx := current_scene_index + 1
	if next_idx < active_scenes_data.size():
		var curr := texture_rects[current_scene_index]
		var nxt := texture_rects[next_idx]
		var skip_fade := create_tween().set_parallel(true)
		skip_fade.tween_property(curr, "modulate:a", 0.0, 0.25)
		skip_fade.tween_property(nxt, "modulate:a", 1.0, 0.25)
		play_scene(next_idx)
	else:
		finish_cutscene()

func _on_continue_pressed() -> void:
	if ending_type == EndingType.DEFEAT_WRONG_GUESS:
		get_tree().change_scene_to_file("res://scenes/interrogation_room.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/town.tscn")

func _input(event: InputEvent) -> void:
	if is_game_over_visible:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_R:
				start_cutscene()
			elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
				_on_continue_pressed()
		return
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if is_playing and allow_skip:
			finish_cutscene()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if is_playing and allow_skip:
			skip_to_next_scene()
