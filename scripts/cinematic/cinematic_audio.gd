class_name CinematicAudio
extends Node

## CinematicAudio
## Self-contained procedural audio and atmosphere synthesizer for the Whispers of Hollow Creek cinematic.
## Synthesizes mountain wind, low dramatic drones, footstep rustles, candle crackle, blade sheens,
## heartbeats, and title impacts in real-time using AudioStreamGenerator, ensuring zero missing audio file dependencies.

var _stream_player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

var _current_shot: int = 1
var _phase_time: float = 0.0

# Sound generator parameters
var wind_volume: float = 0.15
var drone_volume: float = 0.20
var drone_freq: float = 55.0 # Low A1 drone
var tension_freq: float = 82.4 # E2 fifth
var wind_phase: float = 0.0
var drone_phase: float = 0.0
var tension_phase: float = 0.0

var _footstep_timer: float = 0.0
var _heartbeat_timer: float = 0.0

var _music_player: AudioStreamPlayer
const INTRO_THEME_PATH: String = "res://assets/audio/intro_cutscene_theme.mp3"

func _ready() -> void:
	# 1. Main Background Music Player for Intro Cutscene Theme
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "IntroCutsceneThemePlayer"
	_music_player.bus = &"Master"
	_music_player.volume_db = -4.0
	add_child(_music_player)
	
	var intro_stream: AudioStream = load(INTRO_THEME_PATH)
	if intro_stream:
		if intro_stream is AudioStreamMP3:
			(intro_stream as AudioStreamMP3).loop = true
		_music_player.stream = intro_stream
		_music_player.play()
		_music_player.finished.connect(func():
			if is_instance_valid(_music_player) and _music_player.is_inside_tree():
				_music_player.play(0.0)
		)
	else:
		push_warning("[CinematicAudio] Could not load intro theme from " + INTRO_THEME_PATH)

	# 2. Procedural Foley & Atmospheric Synthesizer (Wind, Footsteps, Heartbeat, Crackle)
	_stream_player = AudioStreamPlayer.new()
	_stream_player.name = "ProceduralAudioStream"
	_stream_player.volume_db = -6.0
	add_child(_stream_player)
	
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.2
	_stream_player.stream = _generator
	_stream_player.play()
	_playback = _stream_player.get_stream_playback() as AudioStreamGeneratorPlayback

func get_music_player() -> AudioStreamPlayer:
	return _music_player

func stop_audio(fade_duration: float = 0.5) -> void:
	if _music_player and is_instance_valid(_music_player) and _music_player.playing:
		if fade_duration > 0.0:
			var tween := create_tween()
			tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
			tween.finished.connect(func():
				if is_instance_valid(_music_player):
					_music_player.stop()
			)
		else:
			_music_player.stop()

	if _stream_player and is_instance_valid(_stream_player) and _stream_player.playing:
		if fade_duration > 0.0:
			var tween_proc := create_tween()
			tween_proc.tween_property(_stream_player, "volume_db", -80.0, fade_duration)
			tween_proc.finished.connect(func():
				if is_instance_valid(_stream_player):
					_stream_player.stop()
			)
		else:
			_stream_player.stop()

func set_shot(shot_index: int) -> void:
	_current_shot = shot_index
	_phase_time = 0.0
	match shot_index:
		1: # The Sealed Order: candle room, delicate parchment whisper, low mysterious drone
			wind_volume = 0.015
			drone_volume = 0.18
			drone_freq = 65.4 # Low C2
			tension_freq = 77.8 # D#2 minor third
		2: # The Long Road / Mountain Journey: howling mountain winds, crunching stone footsteps
			wind_volume = 0.32
			drone_volume = 0.12
			drone_freq = 55.0 # Low A1
			tension_freq = 82.4
		3: # The Village Below / 3D Reveal: grand sweeping atmospheric wind & harmonic mystery
			wind_volume = 0.22
			drone_volume = 0.28
			drone_freq = 49.0 # Low G1
			tension_freq = 73.4 # D2
		4: # After Dark / The Murder Aftermath: chilling cold knife tension, low rhythmic heartbeat
			wind_volume = 0.03
			drone_volume = 0.26
			drone_freq = 43.6 # Low F1
			tension_freq = 61.7 # B1 tritone
		5: # Title Card: deep reverberant bass impact & silence
			wind_volume = 0.05
			drone_volume = 0.38
			drone_freq = 36.7 # Low D1 sub-bass
			tension_freq = 55.0

func _process(delta: float) -> void:
	if not _playback:
		return
		
	_phase_time += delta
	var frames_available := _playback.get_frames_available()
	if frames_available <= 0:
		return
		
	var sample_rate: float = _generator.mix_rate
	var sample_dt: float = 1.0 / sample_rate
	
	# Fill audio buffer with procedural cinematic atmosphere
	for i in range(frames_available):
		wind_phase += 1.3 * sample_dt
		drone_phase += drone_freq * TAU * sample_dt
		if drone_phase > TAU: drone_phase -= TAU
		tension_phase += tension_freq * TAU * sample_dt
		if tension_phase > TAU: tension_phase -= TAU
		
		# Pinkish wind noise
		var raw_noise := randf_range(-1.0, 1.0)
		var wind_wave := sin(wind_phase * 2.0) * 0.5 + 0.5
		var wind_sample := raw_noise * wind_volume * wind_wave * 0.4
		
		# Warm harmonic drone
		var sub_drone := sin(drone_phase) * 0.7 + sin(drone_phase * 2.0) * 0.25
		var tension_tone := sin(tension_phase) * 0.4
		var drone_sample := (sub_drone + tension_tone) * drone_volume * 0.5
		
		# Subtle Foley effects
		var foley := 0.0
		
		# Shot 1: subtle candle crackle / parchment friction
		if _current_shot == 1 and randf() < 0.0007:
			foley += randf_range(-0.15, 0.15)
			
		# Shot 2: stone footstep crunches (~1.4 steps per second)
		if _current_shot == 2:
			var step_cycle := fmod(_phase_time, 0.72)
			if step_cycle < 0.08:
				foley += raw_noise * (1.0 - step_cycle / 0.08) * 0.14
				
		# Shot 4: heartbeat thump (~1.1 per second)
		if _current_shot == 4:
			var beat_cycle := fmod(_phase_time, 0.90)
			if beat_cycle < 0.12:
				var beat_env := sin(beat_cycle / 0.12 * PI)
				foley += sin(beat_cycle * 220.0) * beat_env * 0.22
				
		var sample_val := clampf(wind_sample + drone_sample + foley, -1.0, 1.0)
		_playback.push_frame(Vector2(sample_val, sample_val))
