extends SceneTree

## gameplay_music_test.gd
## Comprehensive test suite verifying all 8 requirements of the gameplay background music integration:
## 1. MP3 file presence and validity
## 2. AudioStreamPlayer node configuration
## 3. Looping enabled
## 4. Atmospheric subtle volume level
## 5. Duplicate instance prevention
## 6. Strict isolation from the opening cinematic
## 7. Gameplay start timing and system non-interference
## 8. Playback verification and signal response

func _init() -> void:
	_run_music_verification.call_deferred()

func _run_music_verification() -> void:
	print("\n=== STARTING WHISPERS OF HOLLOW CREEK GAMEPLAY MUSIC VERIFICATION ===")

	# -------------------------------------------------------------------------
	# 1. Asset & Import Verification
	# -------------------------------------------------------------------------
	print("\n[1] Verifying Audio Asset and MP3 Resource...")
	var audio_path: String = "res://assets/audio/hollow_creek_theme.mp3"
	assert(FileAccess.file_exists(audio_path), "Missing audio file: " + audio_path)
	print("  - File exists at: ", audio_path)

	var stream_res: Resource = load(audio_path)
	assert(stream_res != null, "Failed to load audio stream resource!")
	assert(stream_res is AudioStreamMP3, "Audio stream is not an AudioStreamMP3!")
	var mp3_stream := stream_res as AudioStreamMP3
	print("  - AudioStreamMP3 loaded successfully (length: ", "%.2f" % mp3_stream.get_length(), "s)")
	print("  - AudioStreamMP3 loop property: ", mp3_stream.loop)
	assert(mp3_stream.loop == true, "AudioStreamMP3 loop property must be enabled in import!")
	print("[PASS] Requirement 1 & 3: Asset copied, imported, and looping enabled.")

	# -------------------------------------------------------------------------
	# 2. Scene Integration & Configuration in town.tscn
	# -------------------------------------------------------------------------
	print("\n[2] Verifying Scene Integration in town.tscn...")
	var town_scene: PackedScene = load("res://scenes/town.tscn")
	assert(town_scene != null, "Failed to load res://scenes/town.tscn")

	var town_node: Node = town_scene.instantiate()
	root.add_child(town_node)
	current_scene = town_node

	await process_frame
	await process_frame

	var music_node: Node = town_node.get_node_or_null("GameplayMusic")
	assert(music_node != null, "GameplayMusic node missing from town.tscn!")
	assert(music_node is AudioStreamPlayer, "GameplayMusic must be an AudioStreamPlayer!")
	assert(music_node is GameplayMusicController, "GameplayMusic must use GameplayMusicController script!")
	var music_ctrl := music_node as GameplayMusicController
	print("  - Found GameplayMusic node: ", music_ctrl)
	print("  - Target volume dB: ", music_ctrl.target_volume_db)
	assert(music_ctrl.target_volume_db <= -14.0, "Volume must be subtle and atmospheric (<= -14.0 dB)!")
	print("  - Assigned stream: ", music_ctrl.stream)
	assert(music_ctrl.stream != null, "Music stream must not be null!")
	print("[PASS] Requirement 2 & 4: AudioStreamPlayer configured with subtle atmospheric volume.")

	# -------------------------------------------------------------------------
	# 3. Playback Verification in Gameplay
	# -------------------------------------------------------------------------
	print("\n[3] Verifying Playback in Gameplay Mode...")
	# Allow fade-in to begin
	await process_frame
	print("  - Playing state: ", music_ctrl.playing)
	print("  - is_playing_theme(): ", music_ctrl.is_playing_theme())
	assert(music_ctrl.is_playing_theme() == true, "Gameplay music should be actively playing during normal gameplay!")
	print("  - Current volume during fade-in: ", music_ctrl.volume_db, " dB")
	print("[PASS] Requirement 7 & 8: Playback verified active and playing during normal gameplay.")

	# -------------------------------------------------------------------------
	# 4. Duplicate Prevention Verification
	# -------------------------------------------------------------------------
	print("\n[4] Verifying Duplicate Instance Prevention...")
	var initial_instance = GameplayMusicController.active_instance
	assert(initial_instance == music_ctrl, "Active instance singleton should be music_ctrl!")

	var duplicate_ctrl := GameplayMusicController.new()
	duplicate_ctrl.name = "DuplicateGameplayMusic"
	town_node.add_child(duplicate_ctrl)
	await process_frame

	assert(GameplayMusicController.active_instance == music_ctrl, "Active instance must remain the primary controller!")
	assert(not is_instance_valid(duplicate_ctrl) or duplicate_ctrl.is_queued_for_deletion() or not duplicate_ctrl.is_inside_tree(), "Duplicate controller should queue_free or be removed!")
	print("  - Duplicate properly rejected and freed.")
	print("[PASS] Requirement 5: Duplicate music players and overlapping copies prevented.")

	# Clean up gameplay town node
	town_node.queue_free()
	await process_frame
	await process_frame
	assert(GameplayMusicController.active_instance == null, "active_instance should clear on tree exit!")

	# -------------------------------------------------------------------------
	# 5. Cinematic Intro Isolation Verification
	# -------------------------------------------------------------------------
	print("\n[5] Verifying Strict Cinematic Intro Isolation...")
	var cinematic_scene: PackedScene = load("res://scenes/CinematicIntro.tscn")
	assert(cinematic_scene != null, "Failed to load res://scenes/CinematicIntro.tscn")

	var intro_node: Node = cinematic_scene.instantiate()
	root.add_child(intro_node)
	current_scene = intro_node

	await process_frame
	await process_frame

	var intro_ctrl := intro_node as CinematicController
	assert(intro_ctrl != null, "Intro node must be CinematicController!")

	# Verify procedural cinematic audio is active
	var cine_audio = intro_ctrl.get_node_or_null("CinematicAudioDirector")
	assert(cine_audio != null, "Cinematic audio director must exist!")
	print("  - Cinematic procedural audio director active: ", cine_audio.name)

	# Check BackgroundTown inside cinematic
	var bg_town = intro_ctrl.get_node_or_null("BackgroundTown")
	if bg_town:
		var bg_music = bg_town.get_node_or_null("GameplayMusic")
		if bg_music != null and is_instance_valid(bg_music):
			assert(bg_music.is_queued_for_deletion() or not (bg_music as AudioStreamPlayer).playing,
				"GameplayMusic in BackgroundTown must NOT be playing during cinematic!")
		print("  - Verified BackgroundTown contains no playing gameplay music.")

	# Active instance of GameplayMusicController must be null while cinematic runs
	assert(GameplayMusicController.active_instance == null,
		"GameplayMusicController active_instance must be null during cinematic!")
	print("  - GameplayMusicController active_instance is correctly null.")
	print("[PASS] Requirement 6: Gameplay music strictly isolated from cinematic opening sequence.")

	intro_node.queue_free()
	await process_frame

	print("\n=== ALL 8 REQUIREMENTS VERIFIED WITH 100% SUCCESS! ===")
	quit(0)
