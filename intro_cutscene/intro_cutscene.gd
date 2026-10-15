extends Control

const MAIN_SCENE_PATH := "res://scenes/town.tscn"
const CINEMATIC_SCENE_PATH := "res://scenes/CinematicIntro.tscn"
const SHOT_SECONDS := 5.8
const FADE_SECONDS := 1.2

const SHOT_COPY := [
	{
		"chapter": "01   /   THE SEALED ORDER",
		"title": "A letter with one name",
		"caption": "One instruction. One target. Reach the village before dawn—and make sure they never leave it."
	},
	{
		"chapter": "02   /   THE LONG ROAD",
		"title": "Across the stone valley",
		"caption": "Grey peaks closed in on either side. With every mile, the village—and the order—came closer."
	},
	{
		"chapter": "03   /   THE VILLAGE BELOW",
		"title": "A quiet place to disappear",
		"caption": "From the ridge, the village looked peaceful. Somewhere below was the person named in the letter."
	},
	{
		"chapter": "04   /   AFTER DARK",
		"title": "The deed is done",
		"caption": "Under the moon, the last sound faded. The road ahead would be harder to leave than the one behind."
	}
]

@onready var shade: ColorRect = $Shade
@onready var chapter_label: Label = $BottomBar/Chapter
@onready var title_label: Label = $BottomBar/Title
@onready var caption_label: Label = $BottomBar/Caption
@onready var counter_label: Label = $TopBar/Counter
@onready var continue_button: Button = $ContinueButton
@onready var skip_button: Button = $SkipButton

var shots: Array[TextureRect] = []
var active_shot: TextureRect
var advance_requested := false
var entering_game := false
var showing_ending := false
var music_player: AudioStreamPlayer

func _ready() -> void:
	# Seamlessly delegate to the unified cinematic controller if available
	if ResourceLoader.exists(CINEMATIC_SCENE_PATH) and get_tree().current_scene == self:
		get_tree().change_scene_to_file(CINEMATIC_SCENE_PATH)
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Start Intro Cutscene Theme MP3
	music_player = AudioStreamPlayer.new()
	music_player.name = "IntroCutsceneMusicPlayer"
	music_player.bus = &"Master"
	music_player.volume_db = -4.0
	var intro_stream: AudioStream = load("res://assets/audio/intro_cutscene_theme.mp3")
	if intro_stream:
		if intro_stream is AudioStreamMP3:
			(intro_stream as AudioStreamMP3).loop = true
		music_player.stream = intro_stream
		add_child(music_player)
		music_player.play()
	
	shots.append($LetterImage as TextureRect)
	shots.append($TravelImage as TextureRect)
	shots.append($VillageImage as TextureRect)
	shots.append($AftermathImage as TextureRect)
	for shot in shots:
		shot.visible = false
		shot.modulate.a = 0.0
	continue_button.pressed.connect(_advance)
	skip_button.pressed.connect(_enter_game)
	await get_tree().process_frame
	for shot in shots:
		shot.pivot_offset = shot.size * 0.5
	await _play_sequence()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_enter_game()
	elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		_advance()

func _play_sequence() -> void:
	for index in range(shots.size()):
		if entering_game:
			return
		_show_shot(index)
		var start_time := Time.get_ticks_msec()
		while Time.get_ticks_msec() - start_time < int(SHOT_SECONDS * 1000.0) and not advance_requested and not entering_game:
			await get_tree().process_frame
		advance_requested = false
	if not entering_game:
		_show_ending()

func _show_shot(index: int) -> void:
	var next_shot := shots[index]
	var copy: Dictionary = SHOT_COPY[index]
	chapter_label.text = str(copy["chapter"])
	title_label.text = str(copy["title"])
	caption_label.text = str(copy["caption"])
	counter_label.text = "%02d   /   04" % (index + 1)
	continue_button.text = "CONTINUE   →"
	_animate_copy()
	if is_instance_valid(active_shot):
		var previous := active_shot
		var outgoing := create_tween()
		outgoing.tween_property(previous, "modulate:a", 0.0, FADE_SECONDS)
		outgoing.tween_callback(func() -> void: previous.visible = false)
	next_shot.visible = true
	var start_zoom := Vector2(1.075, 1.075)
	var end_zoom := Vector2(1.025, 1.025)
	next_shot.pivot_offset = next_shot.size * 0.5
	if index == 2:
		# Keep the village itself fixed in frame as the third image pushes in.
		next_shot.pivot_offset = Vector2(next_shot.size.x * 0.70, next_shot.size.y * 0.60)
		start_zoom = Vector2(1.04, 1.04)
		end_zoom = Vector2(1.34, 1.34)
	next_shot.scale = start_zoom
	next_shot.modulate.a = 0.0
	var incoming := create_tween().set_parallel(true)
	incoming.tween_property(next_shot, "modulate:a", 1.0, FADE_SECONDS)
	incoming.tween_property(next_shot, "scale", end_zoom, SHOT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_shot = next_shot

func _animate_copy() -> void:
	var labels: Array[Label] = [chapter_label, title_label, caption_label]
	for label in labels:
		label.modulate.a = 0.0
		create_tween().tween_property(label, "modulate:a", 1.0, 0.8)

func _show_ending() -> void:
	showing_ending = true
	chapter_label.text = "THE PROLOGUE ENDS HERE"
	title_label.text = "The village is waiting"
	caption_label.text = "The order brought you this far. What happens next is up to you."
	counter_label.text = "BEGIN   /   THE STORY"
	continue_button.text = "ENTER THE VILLAGE   →"
	skip_button.visible = false
	shade.color = Color(0.015, 0.02, 0.035, 0.58)
	_animate_copy()

func _advance() -> void:
	if entering_game:
		return
	if showing_ending:
		_enter_game()
	else:
		advance_requested = true

func _enter_game() -> void:
	if entering_game:
		return
	entering_game = true
	if music_player and is_instance_valid(music_player) and music_player.playing:
		var fade := create_tween()
		fade.tween_property(music_player, "volume_db", -80.0, 0.45)
	var error := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if error != OK:
		entering_game = false
		push_error("Could not open the main game scene: %s" % error_string(error))
