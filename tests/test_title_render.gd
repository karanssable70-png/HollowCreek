extends SceneTree

# Renders the Title Card with Citadel of Blackrose font and captures a screenshot
func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var font_citadel: Font = load("res://assets/fonts/citadel_of_blackrose.ttf")
	
	var control := Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.custom_minimum_size = Vector2(1280, 720)
	control.size = Vector2(1280, 720)
	root.add_child(control)
	
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.012, 0.014, 0.018, 1.0)
	control.add_child(bg)
	
	var title := Label.new()
	title.text = "HOLLOWCREEK: THE LAST CROSSING"
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.offset_left = -600; title.offset_right = 600
	title.offset_top = -80; title.offset_bottom = 20
	if font_citadel:
		title.add_theme_font_override("font", font_citadel)
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	title.add_theme_color_override("font_shadow_color", Color(0.40, 0.04, 0.06, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.01, 0.02, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	control.add_child(title)

	var sub := Label.new()
	sub.text = "— A Medieval Murder Mystery —"
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.offset_left = -500; sub.offset_right = 500
	sub.offset_top = 40; sub.offset_bottom = 90
	if font_citadel:
		sub.add_theme_font_override("font", font_citadel)
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60, 0.85))
	sub.add_theme_color_override("font_shadow_color", Color(0.25, 0.03, 0.05, 0.9))
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	control.add_child(sub)

	await process_frame
	await process_frame

	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	img.save_png("res://tests/title_card_preview.png")
	print("Saved preview to tests/title_card_preview.png")
	quit(0)
