class_name DialogueUI
extends CanvasLayer

var current_npc: Node = null
var current_player: Node = null

var panel: PanelContainer
var name_label: Label
var role_label: Label
var close_btn: Button
var history_label: RichTextLabel
var input_field: LineEdit
var send_btn: Button
var quick_topics_container: HBoxContainer

func _ready() -> void:
	add_to_group("dialogue_ui")
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Root dark overlay
	var overlay := Control.new()
	overlay.name = "DialogueControl"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Dimmed backdrop
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	
	# Center-bottom Dialogue Box
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.custom_minimum_size = Vector2(760, 360)
	panel.position = Vector2(-380, -390)
	
	# Style the panel with a dark parchment / slate look
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.12, 0.13, 0.16, 0.96)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.85, 0.72, 0.42, 0.9) # Gold border
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.content_margin_left = 24
	style_box.content_margin_right = 24
	style_box.content_margin_top = 18
	style_box.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style_box)
	overlay.add_child(panel)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)
	
	# Header Row (Name + Role + Close Button)
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var name_vbox := VBoxContainer.new()
	header_hbox.add_child(name_vbox)
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	name_label = Label.new()
	name_label.text = "NPC Name"
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.52))
	name_vbox.add_child(name_label)
	
	role_label = Label.new()
	role_label.text = "Role / Title"
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", Color(0.72, 0.75, 0.80))
	name_vbox.add_child(role_label)
	
	close_btn = Button.new()
	close_btn.text = " Close [Esc] "
	close_btn.pressed.connect(close_dialogue)
	header_hbox.add_child(close_btn)
	
	# Separator
	var hsep := HSeparator.new()
	main_vbox.add_child(hsep)
	
	# Dialogue History
	history_label = RichTextLabel.new()
	history_label.bbcode_enabled = true
	history_label.scroll_following = true
	history_label.custom_minimum_size = Vector2(0, 160)
	history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(history_label)
	
	# Quick topic buttons row
	quick_topics_container = HBoxContainer.new()
	quick_topics_container.add_theme_constant_override("separation", 8)
	main_vbox.add_child(quick_topics_container)
	_setup_quick_topic_buttons()
	
	# Input row (LineEdit + Ask Button)
	var input_hbox := HBoxContainer.new()
	input_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(input_hbox)
	
	input_field = LineEdit.new()
	input_field.placeholder_text = "Ask a question (e.g. 'victim', 'pass', 'murder', 'inn', 'sea')..."
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.text_submitted.connect(_on_input_submitted)
	input_hbox.add_child(input_field)
	
	send_btn = Button.new()
	send_btn.text = " Ask "
	send_btn.custom_minimum_size = Vector2(80, 0)
	send_btn.pressed.connect(_on_send_pressed)
	input_hbox.add_child(send_btn)

func _setup_quick_topic_buttons() -> void:
	for child in quick_topics_container.get_children():
		child.queue_free()
		
	var topics: Array[String] = [
		"Who are you?",
		"The Victim",
		"What happened?",
		"What do you think?",
		"Mountain Pass",
		"Can I leave?"
	]
	
	for topic in topics:
		var btn := Button.new()
		btn.text = topic
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): _ask_quick_topic(topic))
		quick_topics_container.add_child(btn)

func _ask_quick_topic(topic: String) -> void:
	send_question(topic)

func open_dialogue(npc: Node, player: Node = null) -> void:
	current_npc = npc
	current_player = player
	
	if current_player and current_player.has_method("set_dialogue_state"):
		current_player.set_dialogue_state(true)
	if current_npc and current_npc.has_method("set_dialogue_state"):
		current_npc.set_dialogue_state(true, current_player)
		
	name_label.text = npc.npc_name if "npc_name" in npc else "Stranger"
	role_label.text = npc.npc_role if "npc_role" in npc else "Villager"
	
	history_label.clear()
	var initial_greeting: String = npc.greeting if "greeting" in npc else "Hello."
	append_npc_message(name_label.text, initial_greeting)
	
	visible = true
	input_field.text = ""
	input_field.grab_focus()

func close_dialogue() -> void:
	visible = false
	if current_player and current_player.has_method("set_dialogue_state"):
		current_player.set_dialogue_state(false)
	if current_npc and current_npc.has_method("set_dialogue_state"):
		current_npc.set_dialogue_state(false)
	current_npc = null
	current_player = null

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_dialogue()
		get_viewport().set_input_as_handled()

func _on_input_submitted(text: String) -> void:
	send_question(text)

func _on_send_pressed() -> void:
	send_question(input_field.text)

func send_question(text: String) -> void:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return
		
	input_field.text = ""
	append_player_message(clean_text)
	
	if current_npc:
		var speaker: String = current_npc.npc_name if "npc_name" in current_npc else "Villager"
		var reply: String = ""
		if current_npc.has_method("ask_question"):
			reply = current_npc.ask_question(clean_text)
		else:
			reply = "..."
		append_npc_message(speaker, reply)

func append_player_message(text: String) -> void:
	history_label.append_text("[color=#8dc8ff][b]You:[/b][/color] " + text + "\n\n")

func append_npc_message(speaker: String, text: String) -> void:
	history_label.append_text("[color=#f4d06f][b]" + speaker + ":[/b][/color] " + text + "\n\n")
