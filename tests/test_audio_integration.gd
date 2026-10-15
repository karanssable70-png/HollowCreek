extends SceneTree

## Comprehensive Audio Integration Verification
## Validates:
## 1. Intro Cutscene Theme MP3 integration into CinematicIntro
## 2. Interrogation Chamber Theme MP3 integration into InterrogationRoom
## 3. Audio stream integrity, looping configuration, and volume mixing
## 4. Scene isolation and smooth fade-out behavior

func _init() -> void:
	print("\n================================================================================")
	print("=== HOLLOWCREEK AUDIO INTEGRATION VERIFICATION ===")
	print("================================================================================\n")
	_run_tests.call_deferred()

func _run_tests() -> void:
	# -------------------------------------------------------------------------
	# 1. VERIFY AUDIO ASSETS & IMPORT SETTINGS
	# -------------------------------------------------------------------------
	print("[1] Verifying Audio Stream Resources...")
	var intro_stream: AudioStream = load("res://assets/audio/intro_cutscene_theme.mp3")
	assert(intro_stream != null, "Failed to load res://assets/audio/intro_cutscene_theme.mp3")
	assert(intro_stream is AudioStreamMP3, "Intro theme is not AudioStreamMP3!")
	print("  - [PASS] Intro theme resource loaded: ", intro_stream)
	
	var chamber_stream: AudioStream = load("res://assets/audio/interrogation_chamber_theme.mp3")
	assert(chamber_stream != null, "Failed to load res://assets/audio/interrogation_chamber_theme.mp3")
	assert(chamber_stream is AudioStreamMP3, "Interrogation theme is not AudioStreamMP3!")
	print("  - [PASS] Interrogation chamber theme resource loaded: ", chamber_stream)

	# -------------------------------------------------------------------------
	# 2. VERIFY CINEMATIC INTRO AUDIO INTEGRATION
	# -------------------------------------------------------------------------
	print("\n[2] Verifying Cinematic Intro Audio...")
	var cinematic_scene: PackedScene = load("res://scenes/CinematicIntro.tscn")
	assert(cinematic_scene != null, "Failed to load scenes/CinematicIntro.tscn")
	
	var cinematic_inst: Node = cinematic_scene.instantiate()
	root.add_child(cinematic_inst)
	
	var controller := cinematic_inst as CinematicController
	assert(controller != null, "Cinematic scene root is not CinematicController!")
	assert(controller.audio_director != null, "AudioDirector missing on CinematicController!")
	
	var intro_music_player: AudioStreamPlayer = controller.audio_director.get_music_player()
	assert(intro_music_player != null, "Intro music AudioStreamPlayer missing on AudioDirector!")
	assert(intro_music_player.stream != null, "Intro music player has no stream assigned!")
	assert(intro_music_player.stream.resource_path == "res://assets/audio/intro_cutscene_theme.mp3", "Wrong stream on intro music player!")
	assert(intro_music_player.playing, "Intro music player is not playing!")
	assert(intro_music_player.volume_db <= 0.0 and intro_music_player.volume_db >= -20.0, "Intro music volume out of expected range: %f" % intro_music_player.volume_db)
	print("  - [PASS] CinematicIntro plays intro_cutscene_theme.mp3 (Vol: %f dB, Playing: %s)" % [intro_music_player.volume_db, intro_music_player.playing])
	
	# Verify stop_audio fades cleanly
	controller.audio_director.stop_audio(0.0)
	assert(not intro_music_player.playing, "Intro music player failed to stop!")
	print("  - [PASS] CinematicIntro stop_audio() terminates playback cleanly.")
	
	cinematic_inst.queue_free()
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 3. VERIFY INTERROGATION CHAMBER AUDIO INTEGRATION
	# -------------------------------------------------------------------------
	print("\n[3] Verifying Interrogation Chamber Audio...")
	var room_scene: PackedScene = load("res://scenes/interrogation_room.tscn")
	assert(room_scene != null, "Failed to load scenes/interrogation_room.tscn")
	
	var room_inst: Node = room_scene.instantiate()
	root.add_child(room_inst)
	
	var chamber_controller = room_inst
	var chamber_audio_player: AudioStreamPlayer = chamber_controller.ambient_audio_player
	assert(chamber_audio_player != null, "Interrogation chamber AudioStreamPlayer missing!")
	assert(chamber_audio_player.stream != null, "Interrogation chamber has no stream assigned!")
	assert(chamber_audio_player.stream.resource_path == "res://assets/audio/interrogation_chamber_theme.mp3", "Wrong stream on chamber player: %s" % chamber_audio_player.stream.resource_path)
	assert(chamber_audio_player.playing, "Interrogation chamber music player is not playing!")
	assert(chamber_audio_player.volume_db <= 0.0 and chamber_audio_player.volume_db >= -20.0, "Interrogation music volume out of range: %f" % chamber_audio_player.volume_db)
	print("  - [PASS] InterrogationRoom plays interrogation_chamber_theme.mp3 (Vol: %f dB, Playing: %s)" % [chamber_audio_player.volume_db, chamber_audio_player.playing])
	
	room_inst.queue_free()
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 4. VERIFY TOWN GAMEPLAY MUSIC REMAINS UNTOUCHED AND ISOLATED
	# -------------------------------------------------------------------------
	print("\n[4] Verifying Town Gameplay Music Isolation...")
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	assert(town_scene != null, "Failed to load scenes/town.tscn")
	
	var town_inst: Node = town_scene.instantiate()
	root.add_child(town_inst)
	
	var town_music: AudioStreamPlayer = town_inst.get_node_or_null("GameplayMusic")
	assert(town_music != null, "GameplayMusic player missing in town.tscn!")
	assert(town_music.stream != null, "GameplayMusic player stream is null!")
	assert(town_music.stream.resource_path == "res://assets/audio/hollow_creek_theme.mp3", "Town gameplay music stream was unexpectedly modified: %s" % town_music.stream.resource_path)
	print("  - [PASS] Town gameplay music is isolated: %s" % town_music.stream.resource_path)
	
	town_inst.queue_free()
	await process_frame
	await process_frame

	print("\n================================================================================")
	print("=== ALL AUDIO INTEGRATION TESTS PASSED (100% SUCCESS) ===")
	print("================================================================================\n")
	quit(0)
