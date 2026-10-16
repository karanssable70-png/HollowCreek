class_name GameplayMusicController
extends AudioStreamPlayer

## GameplayMusicController
## Manages background theme playback for Whispers of Hollow Creek during gameplay.
## Ensures seamless looping, balanced volume mixing (-6 dB matching cutscene/interrogation),
## smooth fade transitions, complete isolation from the cinematic sequence, and duplicate instance prevention.

signal music_started
signal music_stopped
signal music_faded_in

# Static singleton reference to prevent duplicate players or overlapping tracks across scene transitions
static var active_instance: GameplayMusicController = null

@export var music_stream: AudioStream = preload("res://assets/audio/hollow_creek_theme.mp3")
@export var target_volume_db: float = -6.0
@export var fade_in_duration: float = 1.8
@export var fade_out_duration: float = 1.0
@export var loop_enabled: bool = true
@export var auto_start_in_gameplay: bool = true

var _fade_tween: Tween = null
var _is_initialized: bool = false

func _enter_tree() -> void:
	# Immediately check if this node is inside the cinematic intro or background preview
	if _is_in_cinematic_or_menu():
		# Silence and remove to keep cinematic procedural audio completely isolated
		stop()
		return

	# Duplicate prevention: If an active instance already exists, eliminate duplicates
	if active_instance != null and is_instance_valid(active_instance) and active_instance != self:
		print("[GameplayMusic] Duplicate instance detected. Freeing duplicate to prevent audio overlap.")
		queue_free()
		return

	active_instance = self

func _ready() -> void:
	# Isolation check: Do not execute in opening cinematic or background preview instances
	if _is_in_cinematic_or_menu():
		stop()
		queue_free()
		return

	_setup_stream()

	if auto_start_in_gameplay:
		play_theme()

func _exit_tree() -> void:
	if active_instance == self:
		active_instance = null
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

## Check if this node is situated inside CinematicIntro, BackgroundTown, or a non-gameplay preview
func _is_in_cinematic_or_menu() -> bool:
	var curr: Node = self
	while curr:
		if curr.name == "CinematicIntro" or curr.name == "BackgroundTown":
			return true
		if curr.has_method("skip_cinematic"):
			return true
		curr = curr.get_parent()

	var current_scene := get_tree().current_scene if get_tree() else null
	if current_scene:
		if current_scene.name == "CinematicIntro" or current_scene.has_method("skip_cinematic"):
			return true
	return false

## Sets up the stream resource and ensures loop parameters are enforced
func _setup_stream() -> void:
	if stream == null:
		if music_stream != null:
			stream = music_stream
		else:
			stream = load("res://assets/audio/hollow_creek_theme.mp3")

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop_enabled

	# Fail-safe finished signal connection to guarantee infinite loop without gap
	if not finished.is_connected(_on_stream_finished):
		finished.connect(_on_stream_finished)

	bus = &"Master"
	_is_initialized = true

## Plays the background theme with smooth atmospheric fade-in
func play_theme(custom_fade: float = -1.0) -> void:
	if not _is_initialized:
		_setup_stream()

	if stream == null:
		push_warning("[GameplayMusic] No valid AudioStream assigned to GameplayMusicController.")
		return

	var fade: float = fade_in_duration if custom_fade < 0.0 else custom_fade

	if fade > 0.0:
		volume_db = -80.0
		play(0.0)
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "volume_db", target_volume_db, fade)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_fade_tween.finished.connect(func(): music_faded_in.emit())
	else:
		volume_db = target_volume_db
		play(0.0)

	music_started.emit()

## Stops the theme with an optional smooth fade-out
func stop_theme(custom_fade: float = -1.0) -> void:
	var fade: float = fade_out_duration if custom_fade < 0.0 else custom_fade

	if fade > 0.0 and playing:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "volume_db", -80.0, fade)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_fade_tween.finished.connect(func():
			stop()
			music_stopped.emit()
		)
	else:
		stop()
		music_stopped.emit()

## Sets the atmospheric target volume level
func set_theme_volume(vol_db: float) -> void:
	target_volume_db = vol_db
	if not (_fade_tween and _fade_tween.is_valid()):
		volume_db = target_volume_db

## Query whether the gameplay theme is currently playing
func is_playing_theme() -> bool:
	return playing

## Fail-safe signal handler for continuous looping
func _on_stream_finished() -> void:
	if loop_enabled and is_inside_tree() and not _is_in_cinematic_or_menu():
		play(0.0)
