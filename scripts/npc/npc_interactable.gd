class_name NPCInteractable
extends CharacterBody3D

## NPCInteractable
## Represents an autonomous villager in HOLLOWCREEK: THE LAST CROSSING.
## Features:
## - Full support for supplied FBX character model scenes (with limb pivots)
## - Role-based daily schedules (Work / Duty vs. Stroll / Patrol phases)
## - Dynamic waypoint navigation along stone roads and off-road paths
## - Procedural walking and limb animation (swinging arms, legs, walk bob)
## - Smooth facing rotation when spoken to by the player
## - Authoritative keyword dialogue, evidence inquiry, and mystery progression

enum State {
	WORK,
	PATROLLING,
	PAUSED_AT_WAYPOINT,
	RETURNING_HOME,
	DIALOGUE
}

const MysteryGameStateScript = preload("res://scripts/mystery/mystery_game_state.gd")

# ---------------------------------------------------------------------------
# EXPORTED IDENTITY & APPEARANCE
# ---------------------------------------------------------------------------
@export var npc_id: String = "garrick"
@export var npc_name: String = "Garrick Thorne"
@export var npc_role: String = "Harbour Master"
@export var character_scene: PackedScene = null ## Optional dedicated FBX character scene (e.g. res://scenes/characters/garrick.tscn)
@export var clothing_color: Color = Color(0.18, 0.28, 0.42)
@export var accent_color: Color = Color(0.85, 0.82, 0.75)
@export var skin_color: Color = Color(0.92, 0.78, 0.65)
@export var hair_color: Color = Color(0.35, 0.22, 0.15)
@export var accessory_type: String = "sailor_cap"

@export_multiline var greeting: String = "Welcome to Hollowcreek."
@export_multiline var fallback_response: String = "I know nothing of that. You should ask around the square."

# ---------------------------------------------------------------------------
# EXPORTED MOVEMENT & PATROL SCHEDULE
# ---------------------------------------------------------------------------
@export var work_duration: float = 45.0
@export var stroll_duration: float = 25.0
@export var walk_speed: float = 1.35
@export var turn_speed: float = 6.0
@export var patrol_waypoints: Array[Vector3] = []
@export var pause_at_waypoint_time: float = 2.5
@export var return_to_work_post: bool = true
@export var start_in_patrol: bool = false

# ---------------------------------------------------------------------------
# RUNTIME STATE & MYSTERY THOUGHTS
# ---------------------------------------------------------------------------
var current_state: State = State.WORK
var state_timer: float = 0.0
var waypoint_pause_timer: float = 0.0
var current_waypoint_idx: int = 0
var home_position: Vector3
var home_rotation_y: float = 0.0

var dialogue_dict: Dictionary = {}
var character_mesh_root: Node3D = null

# Investigation / Murder Mystery Data
var known_clues: Array[String] = []
var suspicion_target: String = ""
var suspicion_level: float = 0.0
var current_thought: String = ""

# Internal navigation & animation helpers
var _pre_dialogue_state: State = State.WORK
var _dialogue_target: Node = null
var _stuck_timer: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _gravity: float = 9.8

# Procedural limb references (driven on either FBX or fallback models)
var _leg_pivot_l: Node3D = null
var _leg_pivot_r: Node3D = null
var _arm_pivot_l: Node3D = null
var _arm_pivot_r: Node3D = null
var _walk_anim_phase: float = 0.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	
	home_position = global_position
	home_rotation_y = rotation.y
	_last_position = global_position
	
	_build_dialogue_knowledge()
	_build_visual_mesh()
	_setup_collision()
	update_thought()
	
	if patrol_waypoints.is_empty():
		_init_default_waypoints()
		
	if start_in_patrol and patrol_waypoints.size() > 0:
		start_patrol()
	else:
		current_state = State.WORK
		state_timer = 0.0

# ---------------------------------------------------------------------------
# PHYSICS PROCESS (Navigation, Gravity, Limb Animation)
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	match current_state:
		State.DIALOGUE:
			velocity.x = 0.0
			velocity.z = 0.0
			_update_dialogue_facing(delta)
			_update_limb_animation(delta, false)
			move_and_slide()
			return

		State.WORK:
			velocity.x = 0.0
			velocity.z = 0.0
			
			var dist_to_home := Vector2(global_position.x - home_position.x, global_position.z - home_position.z).length()
			if dist_to_home > 0.4:
				var dir_home := (home_position - global_position)
				dir_home.y = 0.0
				dir_home = dir_home.normalized()
				velocity.x = dir_home.x * (walk_speed * 0.7)
				velocity.z = dir_home.z * (walk_speed * 0.7)
				var target_yaw := atan2(dir_home.x, dir_home.z)
				rotation.y = lerp_angle(rotation.y, target_yaw, delta * turn_speed)
				_update_limb_animation(delta, true)
			else:
				rotation.y = lerp_angle(rotation.y, home_rotation_y, delta * 3.0)
				_update_limb_animation(delta, false)
				
			state_timer += delta
			if work_duration > 0.0 and state_timer >= work_duration and patrol_waypoints.size() > 0:
				start_patrol()
			move_and_slide()

		State.PAUSED_AT_WAYPOINT:
			velocity.x = 0.0
			velocity.z = 0.0
			_update_limb_animation(delta, false)
			waypoint_pause_timer += delta
			if waypoint_pause_timer >= pause_at_waypoint_time:
				waypoint_pause_timer = 0.0
				current_waypoint_idx += 1
				if current_waypoint_idx >= patrol_waypoints.size():
					if return_to_work_post:
						current_state = State.RETURNING_HOME
					else:
						current_waypoint_idx = 0
						current_state = State.PATROLLING
				else:
					current_state = State.PATROLLING
			move_and_slide()

		State.PATROLLING:
			state_timer += delta
			if stroll_duration > 0.0 and state_timer >= stroll_duration and return_to_work_post:
				current_state = State.RETURNING_HOME
				return
				
			if current_waypoint_idx < patrol_waypoints.size():
				_navigate_towards(patrol_waypoints[current_waypoint_idx], delta)
			else:
				current_state = State.RETURNING_HOME
			move_and_slide()

		State.RETURNING_HOME:
			var arrived := _navigate_towards(home_position, delta, 0.5)
			if arrived:
				current_state = State.WORK
				state_timer = 0.0
				current_waypoint_idx = 0
			move_and_slide()

func _navigate_towards(target: Vector3, delta: float, arrive_dist: float = 0.8) -> bool:
	var delta_pos := target - global_position
	var dist_2d := Vector2(delta_pos.x, delta_pos.z).length()
	
	if dist_2d <= arrive_dist:
		velocity.x = 0.0
		velocity.z = 0.0
		if current_state == State.PATROLLING:
			current_state = State.PAUSED_AT_WAYPOINT
			waypoint_pause_timer = 0.0
		return true

	var dir := delta_pos.normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed

	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * turn_speed)

	_update_limb_animation(delta, true)

	var moved := (global_position - _last_position).length()
	if moved < 0.01 * delta:
		_stuck_timer += delta
		if _stuck_timer > 3.0:
			_stuck_timer = 0.0
			current_waypoint_idx = (current_waypoint_idx + 1) % maxi(1, patrol_waypoints.size())
	else:
		_stuck_timer = 0.0
	_last_position = global_position
	return false

func start_patrol() -> void:
	current_state = State.PATROLLING
	state_timer = 0.0
	current_waypoint_idx = 0
	waypoint_pause_timer = 0.0

func return_home() -> void:
	current_state = State.RETURNING_HOME

func is_walking() -> bool:
	return current_state == State.PATROLLING or current_state == State.RETURNING_HOME

# ---------------------------------------------------------------------------
# DIALOGUE & INTERACTION
# ---------------------------------------------------------------------------
func get_interaction_prompt() -> String:
	return "[E] Talk to " + npc_name + " (" + npc_role + ")"

func interact(player: Node) -> void:
	set_dialogue_state(true, player)
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui and dialogue_ui.has_method("open_dialogue"):
		dialogue_ui.open_dialogue(self, player)
	else:
		print("Talking to ", npc_name, ": ", greeting)

func set_dialogue_state(open: bool, player: Node = null) -> void:
	if open:
		if current_state != State.DIALOGUE:
			_pre_dialogue_state = current_state
		current_state = State.DIALOGUE
		velocity = Vector3.ZERO
		_dialogue_target = player
		if player:
			_face_node(player)
	else:
		_dialogue_target = null
		if _pre_dialogue_state == State.DIALOGUE:
			current_state = State.WORK
		else:
			current_state = _pre_dialogue_state

func _face_node(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	var dir: Vector3 = (node.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 0.05:
		rotation.y = atan2(dir.x, dir.z)

func _update_dialogue_facing(delta: float) -> void:
	if _dialogue_target and is_instance_valid(_dialogue_target):
		var dir: Vector3 = (_dialogue_target.global_position - global_position)
		dir.y = 0.0
		if dir.length() > 0.1:
			var target_yaw := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * turn_speed * 1.5, 0.0, 1.0))

func ask_question(question: String) -> String:
	var q := question.to_lower().strip_edges()
	if q.is_empty():
		return "Did you have a question for me?"
		
	# Check for thoughts or clues
	if "think" in q or "thought" in q or "clue" in q or "suspect" in q:
		return get_current_thought()

	# Check Mayor verdict inquiry
	if npc_id == "mayor" and ("verdict" in q or "judgment" in q or "trial" in q or "conclude" in q):
		if MysteryGameStateScript.instance != null:
			var v = MysteryGameStateScript.instance.evaluate_mayor_verdict()
			return "[MAYOR'S VERDICT - " + v["title"] + "]\n" + v["summary"]
		else:
			return "I am evaluating the accumulated testimonies. When the ship docks on Day 3, justice shall be delivered."

	# Check keywords
	for key: String in dialogue_dict.keys():
		var keywords: Array = key.split("|")
		for kw: String in keywords:
			if kw.strip_edges() in q:
				return dialogue_dict[key]
				
	return fallback_response

# ---------------------------------------------------------------------------
# AUTONOMOUS THOUGHTS & MYSTERY INTEGRATION
# ---------------------------------------------------------------------------
func add_clue(clue_id: String, _description: String = "") -> void:
	if not known_clues.has(clue_id):
		known_clues.append(clue_id)
		if MysteryGameStateScript.instance != null:
			MysteryGameStateScript.instance.discover_clue(clue_id)
		update_thought()

func update_thought() -> void:
	match npc_id:
		"garrick":
			if "burnt_contract_scrap" in known_clues:
				current_thought = "That burnt scrap from the fireplace... the raven seal points back to the capital. We need to stay quiet."
			else:
				current_thought = "Aldric owed me coin and threatened my docks. But I settle debts with words or fists, not a stiletto."
		"isolde":
			if "debt_ledgers" in known_clues:
				current_thought = "Aldric's forged land claims were an outrage, but assassination is a coward's tool. Someone framed this skillfully."
			else:
				current_thought = "A hired assassin stalks Hollowcreek. Every newcomer should be scrutinized by the Council."
		"edmund":
			if "autopsy_report" in known_clues:
				current_thought = "The single stab directly into the left ventricle was executed with chilling surgical precision. No amateur did this."
			else:
				current_thought = "Lord Aldric did not ingest poison. The wild rumors of wolfsbane are unscientific."
		"lena":
			if "burnt_contract_scrap" in known_clues:
				current_thought = "The burnt raven seal from my fireplace hearth... someone paid blood money for Lord Aldric's death."
			else:
				current_thought = "Aldric looked like a hunted man. Whoever he was running from, they followed him into Hollowcreek."
		"oswin":
			if "storehouse_iron_key" in known_clues:
				current_thought = "Only two keys open that storehouse: his lordship's and Harbour Master Garrick's. That cannot be ignored."
			else:
				current_thought = "Lord Aldric's financial ledgers hold dangerous secrets about tariffs, debts, and enemies."
		"finn":
			if "muddy_cliff_boots" in known_clues:
				current_thought = "Military-grade boots... I saw tracks by the tide pools heading from the storehouse toward the square."
			else:
				current_thought = "The boats are chained, but on night three the merchant schooner arrives. Strange shadows are pacing the docks."
		"elara":
			if "almond_scent" in known_clues:
				current_thought = "The faint scent of bitter almonds by the storehouse... yet Doctor Wren insists no poison was swallowed."
			else:
				current_thought = "The coastal wind carries a chill. Aldric kept whispering that 'the contractor has dispatched a ghost'."
		"corin":
			current_thought = "Everyone in the City Bazaar is jumpy. Every merchant is eyeing their neighbor like a suspect."
		"tomas":
			current_thought = "No one leaves town through the mountain pass or across the sea until Mayor Eldridge delivers the verdict."
		"mayor":
			current_thought = "The evidence must speak with undeniable clarity. I will not sentence anyone without proof."
		_:
			current_thought = "Strange times in Hollowcreek. Best keep my head down and mind my work."

func get_current_thought() -> String:
	if current_thought.is_empty():
		update_thought()
	return current_thought

# ---------------------------------------------------------------------------
# DEFAULT WAYPOINTS (Initialized if empty in scene)
# ---------------------------------------------------------------------------
func _init_default_waypoints() -> void:
	match npc_id:
		"garrick":
			# Harbour Master: Pier -> Warehouses -> Shore ramp -> Storehouse approach -> Docks
			patrol_waypoints = [
				Vector3(-42.0, 0.12, 18.0),
				Vector3(-38.0, 0.12, 12.0),
				Vector3(-30.0, 0.32, 13.0),
				Vector3(-28.0, 0.55, 16.0),
				Vector3(-30.0, 0.60, 18.5),
				Vector3(-34.0, 0.32, 14.0),
				Vector3(-40.0, 0.12, 14.5)
			]
		"isolde":
			# Lady Isolde: Manor terrace -> Residential lane -> Path 1 courtyard -> Bluff overlook -> Manor
			patrol_waypoints = [
				Vector3(-18.0, 1.15, -23.0),
				Vector3(-12.0, 0.95, -20.0),
				Vector3(-8.0, 0.85, -16.0),
				Vector3(-14.0, 1.05, -18.0),
				Vector3(-18.0, 1.15, -23.0)
			]
		"edmund":
			# Physician: Clinic -> Herb path -> Square north -> Clinic terrace
			patrol_waypoints = [
				Vector3(12.2, 0.92, -14.2),
				Vector3(8.0, 0.85, -12.0),
				Vector3(2.0, 0.72, -8.0),
				Vector3(6.0, 0.80, -10.0),
				Vector3(12.2, 0.92, -14.2)
			]
		"lena":
			# Innkeeper: Inn terrace -> Inn road -> Plaza West -> Central Well -> Inn
			patrol_waypoints = [
				Vector3(-14.0, 0.72, -1.8),
				Vector3(-18.0, 1.05, -2.0),
				Vector3(-14.0, 0.72, -1.8),
				Vector3(-6.0, 0.72, -1.0),
				Vector3(-2.0, 0.72, 0.0),
				Vector3(-6.0, 0.72, -1.0),
				Vector3(-9.72, 0.72, -2.0)
			]
		"oswin":
			# Steward: Town Hall steps -> Plaza East -> Archive desk -> Mayor terrace
			patrol_waypoints = [
				Vector3(20.0, 0.78, 2.0),
				Vector3(14.0, 0.68, 1.5),
				Vector3(8.0, 0.61, 1.0),
				Vector3(14.0, 0.68, 1.5),
				Vector3(20.0, 0.78, 2.0)
			]
		"finn":
			# Dockworker: Crane -> Mooring posts -> Salt barrels -> Wharf edge
			patrol_waypoints = [
				Vector3(-34.0, 0.22, 16.0),
				Vector3(-30.0, 0.25, 14.0),
				Vector3(-36.0, 0.20, 18.0),
				Vector3(-34.0, 0.22, 16.0)
			]
		"elara":
			# Herbalist: Herb garden -> Doctor's path -> Plaza South -> Cottage
			patrol_waypoints = [
				Vector3(4.0, 0.70, 21.0),
				Vector3(4.0, 0.70, 16.0),
				Vector3(2.5, 0.72, 11.0),
				Vector3(8.0, 0.70, 14.0),
				Vector3(4.0, 0.70, 18.6)
			]
		"corin":
			# Fruit Vendor: Stall -> Well -> Notice board -> Stall
			patrol_waypoints = [
				Vector3(4.0, 0.72, -2.5),
				Vector3(0.0, 0.72, 0.0),
				Vector3(4.5, 0.72, 4.5),
				Vector3(-3.0, 0.72, 4.0),
				Vector3(6.5, 0.72, -4.5)
			]
		"tomas":
			# Guard: Watchpost -> Gate arch -> Slope check -> Sentry post
			patrol_waypoints = [
				Vector3(0.0, 1.87, -33.5),
				Vector3(0.0, 1.55, -28.0),
				Vector3(0.0, 1.30, -22.0),
				Vector3(3.0, 1.25, -20.0),
				Vector3(0.0, 1.55, -28.0),
				Vector3(2.4, 1.85, -32.0)
			]
		"mayor":
			# Mayor: Council dais -> Town Hall balcony -> Plaza approach -> Archive
			patrol_waypoints = [
				Vector3(25.0, 0.85, 0.0),
				Vector3(22.0, 0.80, 1.5),
				Vector3(25.0, 0.85, 0.0)
			]

# ---------------------------------------------------------------------------
# DIALOGUE KNOWLEDGE INITIALIZATION
# ---------------------------------------------------------------------------
func _build_dialogue_knowledge() -> void:
	match npc_id:
		"garrick":
			greeting = "Keep your voice down, traveler. The sea's cold, and the guards are watching every skiff. What do you need at the docks?"
			fallback_response = "The tides don't wait, and neither do questions. Talk to someone in the plaza if you want empty rumors."
			dialogue_dict = {
				"who|garrick|thorne|harbour|master|name": "Garrick Thorne, Harbour Master of Hollowcreek. I manage the moorings, the salt warehouses, and every vessel that touches these waters. Or I did, before the council chained the hulls.",
				"aldric|victim|lord|dead|murder": "Aldric Vale is dead. A tragedy, some might say... but a man who builds a mountain of debts and enemies shouldn't be surprised when the mountain collapses on him.",
				"contract|hire|kill|assassin|job|secret": "Quiet, you fool! Walls have ears and Tomas has guards on every ridge. We spoke of a transaction, and you delivered. Now keep your head down. The merchant ship arrives in three days. Until then, you know nothing, and I hired no one.",
				"escape|boat|leave|ship|sea": "All rowboats are beached and chained by order of the Mayor. But on the third night, a schooner from the capital drops anchor past the shoals. Play your cards right, deflect suspicion, and we both walk out of Hollowcreek.",
				"isolde|ravenshade|noblewoman": "Lady Isolde despised Aldric. He held deeds to her family's northern estates. If the Mayor looks her way, it wouldn't take much to convince the town she had more reason than anyone to see him bled.",
				"edmund|physician|doctor": "Edmund Wren's a sharp physician. He inspected the body at the storehouse. Make sure his medical notes don't point towards capital craftsmanship.",
				"oswin|steward": "Oswin keeps Aldric's ledgers. He knows every coin Aldric extorted. If those books surface, my name might be in them under 'unpaid port levies'. If you find those records, burn them.",
				"mayor|eldridge|verdict|authority": "Mayor Eldridge holds court at the Town Hall. He's no fool—he weighs evidence, testimony, and contradictions. Give him a believable story, and he'll point the gallows away from us.",
				"finn|dockworker": "Finn's a loyal lad who unloads the crates. He keeps his mouth shut if you don't rattle him.",
				"elara|herbalist": "Elara knows every weed and flower on the cliffs. She saw someone near the storehouse at dusk. Let's hope she mistook a shadow for someone else.",
				"clues|evidence|stiletto": "If you left anything behind in that storehouse—a boot print, a scrap of paper—you'd best clean it up before the villagers bring it to Eldridge."
			}

		"isolde":
			greeting = "A stranger walks our streets while blood still stains the storehouse timbers. Speak, but choose your words with care."
			fallback_response = "Hollowcreek whispers too many falsehoods. Seek facts, not idle slander."
			dialogue_dict = {
				"who|isolde|ravenshade|lady|name": "I am Lady Isolde Ravenshade. My family held estates along these bluffs before this village even had a name. Lord Aldric thought he could wrest our legacy from us with fraudulent imperial contracts.",
				"aldric|victim|lord|dead|murder": "Aldric was a leech in silk. He came to Hollowcreek fleeing debts in the capital, yet had the gall to demand tribute from my household. His death is no grief to me—though having a killer roaming our lanes is an indignity I will not tolerate.",
				"motive|land|estate|heirloom": "I make no secret that I wanted Aldric ruined. Ruined by law, stripped of his fraudulent titles. But slipping a blade into his chest in a dark warehouse? That is the work of a hired gutter-rat, not a Ravenshade.",
				"garrick|harbour|master": "Garrick Thorne postures as a simple dockmaster, but his warehouse harbors more than salt mackerel. He owed Aldric thousands in unpaid tariffs and smuggled spirits. He had far more urgency to silence him than I ever did.",
				"edmund|physician": "Doctor Wren examined the wound. He told me privately the strike was surgically clean. An expert thrust, not the clumsy hacking of an angry peasant.",
				"oswin|steward": "Oswin was Aldric's shadow. He carried the ledgers. If anyone knows who Aldric feared most in his final days, it is Oswin.",
				"mayor|eldridge|verdict": "The Mayor must deliver justice based on truth. I have already given my account. I was in my manor garden until the evening bells.",
				"inn|lena": "Lena Hart pours ale and collects secrets. Ask her who Aldric met with behind the stables three nights ago.",
				"clues|evidence|suspect": "Someone was seen running along the cliff road wearing a heavy traveling cloak. We don't see many traveling cloaks in Hollowcreek... until today."
			}

		"edmund":
			greeting = "Mind the threshold, traveler. I have just concluded an examination of Lord Aldric's remains. What brings you to the clinic?"
			fallback_response = "Medicine requires precise anatomy, not village conjecture. Ask of symptoms and wounds, or ask elsewhere."
			dialogue_dict = {
				"who|edmund|wren|physician|doctor|name": "Edmund Wren, town physician and chirurgeon. I tend to fevers, fractures, and when tragedy strikes, the dead. Hollowcreek has never seen a trauma quite like this.",
				"aldric|victim|lord|dead|murder|autopsy|wound": "The fatal wound was delivered between the fourth and fifth ribs on the left anterior thoracic wall. The blade punctured the pericardium and pierced the left ventricle. Death occurred in less than ten seconds. It was executed with frightening anatomical precision.",
				"weapon|blade|knife|dagger|stiletto": "A narrow, double-edged triangular stiletto blade, approximately seven inches long. Not a butcher's knife, not an axe, and certainly not a blacksmith's heavy iron. A weapon designed specifically for covert assassination.",
				"time|death|hour|when": "Algor mortis and the state of lividity indicate he perished between the second and third bells of the night—roughly midnight. He was dead hours before the storehouse was opened at dawn.",
				"poison|toxic|cyanide|herbs": "Rumors abound that Elara poisoned him with wolfsbane or almond extract. I performed a gastric incision—there was no poison. His lungs and blood were clear. The blade alone killed him.",
				"garrick|harbour": "Garrick looked remarkably pale when I informed the council of the wound's angle. For a man who claims he knows nothing, he seemed desperate to learn if any fingerprints remained on the hilt.",
				"isolde|ravenshade": "Lady Isolde has the composure of a queen, but anger burns beneath. However, plunging a blade into an armed nobleman requires physical training that her ladyship simply does not possess.",
				"oswin|steward": "Oswin was visibly weeping when he identified the body. Or perhaps weeping for his lost patron. He handed me Aldric's personal effects, but the seal ring was missing.",
				"mayor|eldridge|verdict": "I have submitted my post-mortem parchment to Mayor Eldridge. He will evaluate my anatomical findings alongside the physical clues."
			}

		"lena":
			greeting = "Welcome to The Lantern Inn, stranger. Pull up a stool near the hearth. Folks are talking low today, but the cider's warm."
			fallback_response = "I hear a lot of chatter across the counter, but that doesn't ring a bell. Try asking around the square."
			dialogue_dict = {
				"who|lena|hart|innkeeper|inn|name": "Lena Hart! Proud owner of The Lantern Inn. I've poured drinks for sailors, merchants, lords, and rogues for twenty years. Everyone passes through my doors sooner or later.",
				"aldric|victim|lord|dead|murder": "Lord Aldric took my second-floor suite for the past fortnight. Arrogant man, but terrified. Two nights ago, he drank three flagons of dark wine, staring out the window toward the mountain pass like he was waiting for the reaper himself.",
				"papers|letter|burn|fireplace": "Late last night, before he slipped out, I saw him burning parchments in the common room hearth! I swept the ashes this morning and found a corner that didn't burn—had black wax and a raven crest on it. Whispered something about a contract.",
				"garrick|harbour": "Garrick Thorne came into the tavern two nights back. He and Aldric sat in that dark corner booth for an hour, arguing in hissed whispers. Garrick slammed his mug down and said, 'You won't live to see the next tide if you push me, Vale.' Now look who's dead.",
				"isolde|ravenshade": "Lady Isolde rarely steps foot in a common taproom, but her carriage boy was asking questions about Aldric's schedule just yesterday morning.",
				"finn|dockworker": "Finn comes in after sundown with tar on his knuckles. Good boy, keeps to himself. Mentioned seeing lantern light near the storehouse around midnight.",
				"edmund|physician": "Doctor Wren is a good man. When folks get sick, he's at their bedside. He told the taproom to stay calm, but nobody's sleeping with a killer in town.",
				"mayor|eldridge|verdict": "Mayor Eldridge has called a town council. By the third day, when the relief ship docks, he'll hold the final inquiry. God help whoever's found guilty."
			}

		"oswin":
			greeting = "I am in the midst of compiling Lord Aldric's estate records. Please, make your inquiries brief—we are in mourning and under lockdown."
			fallback_response = "That is not documented in the estate registries. Consult the villagers in the plaza."
			dialogue_dict = {
				"who|oswin|hale|steward|name": "Oswin Hale, chief steward to the late Lord Aldric Vale. I manage the financial accounts, correspondence, and household registries of his lordship's affairs.",
				"aldric|victim|lord|dead|murder": "His lordship was a man of noble birth, though entanglements in the imperial capital followed him to this coast. He believed Hollowcreek would offer sanctuary. Alas, a ruthless shadow found him even here.",
				"ledgers|debts|finances|money": "The estate books show significant friction. Lord Aldric was owed substantial sums by the Harbour Authority—Garrick Thorne, specifically. His lordship threatened to petition the High Magistrate to seize the docks if the debt was not settled by the end of the month.",
				"garrick|harbour": "Garrick Thorne had everything to gain from his lordship's demise. A mountain of debt vanished with a single knife stroke. Furthermore, Garrick holds the master iron key to that storehouse.",
				"isolde|ravenshade": "Lady Isolde was locked in dispute with his lordship over the northern bluff deeds. However, our correspondence shows they were negotiating a compromise. I find it difficult to believe her ladyship resorted to assassination.",
				"key|storehouse": "The Old Storehouse was deeded for maritime freight. Only two keys exist: one was on Lord Aldric's chain, and the second is kept by the Harbour Master, Garrick Thorne.",
				"contract|raven|seal": "A raven seal? That is the sigil of the Nightwing Syndicate in the capital! If Aldric received a contract bearing that mark, it means someone paid blood money for his execution.",
				"mayor|eldridge|verdict": "I have delivered the financial records and the storehouse inventory to Mayor Eldridge at the Town Hall. The evidence must guide his lordship's judgment."
			}

		"finn":
			greeting = "Watch your boots by the cargo nets, mate. Not much freight moving with the boats beached, but there's always ropes to mend."
			fallback_response = "I just haul timber and salt barrels. If you want town gossip, ask the folks up at the inn."
			dialogue_dict = {
				"who|finn|mercer|dockworker|docks|name": "Finn Mercer. I work the cranes and haul crates for Master Thorne. Tough work, salt air ruins your hands, but it pays honest copper.",
				"aldric|victim|lord|dead|murder": "Saw him once or twice strutting around the wharf with his nose in the air. Looked like a man who never lifted a crate in his life. Didn't know he was dead until the guards sounded the bell this dawn.",
				"garrick|thorne|boss": "Master Thorne is a hard boss, but fair. Yesterday he seemed anxious, pacing the dock and staring up at the mountain pass. Kept checking his pocket watch.",
				"midnight|night|seen|witness": "I was securing the mooring lines on Skiff Three around the second bell. Thought I heard boot steps on the wet gravel near the storehouse ramp. A tall figure in a dark traveling cloak... moved like a ghost, didn't make a sound. Then a lantern blinked twice from the wharf.",
				"boots|footprints": "Heavy boots. Not fishermen's calf-skin, and not clog shoes. Military leather, thick soles. Cut deep into the tide mud.",
				"boat|escape|ship": "No boats leave without Master Thorne's say-so. The chains have three padlocks. But the supply vessel from the mainland comes every month on the third day of the tide. That's the only way off this rock.",
				"storehouse|warehouse": "The Old Storehouse smells of dried cod and cedar. Master Thorne kept high-value goods locked up there. Had a big iron lock on the double oak doors."
			}

		"aldric":
			greeting = "[INSPECTION] Lord Aldric Vale lies motionless on the cold stone floor, a crimson pool congealed beneath his chest."
			fallback_response = "[INSPECTION] The victim's body is cold to the touch. No further words can be drawn from the dead."
			dialogue_dict = {
				"who|aldric|victim|inspect|examine": "[INSPECTION] Lord Aldric Vale lies motionless on the cold stone floor, a crimson pool congealed beneath his chest. A single triangular stiletto wound is visible through his embroidered beige doublet. Beside his outstretched hand lies an iron key. In his clenched fist is a torn corner of parchment bearing a faint raven impression. Footprints in drying mud lead toward the doorway.",
				"wound|chest|heart": "[INSPECTION] The wound is neat, narrow, and precise. A seven-inch stiletto pierced the chest directly through the left ventricle. There were no defensive cuts on his palms.",
				"key|storehouse": "[INSPECTION] A heavy iron key rests near his fingers. Identical in shape to the master key Garrick keeps at the Harbour Master's desk.",
				"paper|parchment|raven": "[INSPECTION] The charred fragment in his fist shows blackened edges and a red wax raven seal: '...shall be dispatched upon sunset'."
			}

		"mayor":
			greeting = "Citizens and travelers of Hollowcreek. Lord Aldric Vale has been murdered. Under village charter, the pass and harbour remain locked down. I am receiving all evidence and testimony. In three days, when the ship arrives, I shall deliver the final verdict."
			fallback_response = "Every scrap of evidence and witness statement must be brought to the Town Hall before court is convened."
			dialogue_dict = {
				"who|mayor|eldridge|authority|verdict|judge|name": "I am Mayor Eldridge. As senior magistrate of Hollowcreek, the responsibility for justice rests squarely upon my shoulders. I will not condemn an innocent soul, nor shall a ruthless assassin escape to the mainland.",
				"evidence|clues|report|testimony": "Bring me what you discover. Wounds from Edmund, records from Oswin, statements from the docks or the inn. Every scrap of parchment and contradiction will be weighed before judgment is rendered.",
				"verdict|accuse|judgment|trial": "When the ship docks on Day 3, I shall deliver the final verdict based upon the weight of accumulated evidence.",
				"garrick|harbour": "Garrick Thorne is a pillar of our harbour trade, yet whispers of financial ruin and bitter quarrels with the victim have reached my ears. If evidence connects him to the crime, his station will not shield him.",
				"isolde|ravenshade": "Lady Isolde had deep grievances regarding estate boundaries. Yet grievance alone does not constitute murder. I require material evidence.",
				"aldric|victim": "Lord Aldric sought refuge in our peaceful borough. That violence has violated Hollowcreek is an outrage that shall be answered before the gallows.",
				"lockdown|countdown|ship": "Three days. That is the time required for the imperial supply ship to reach our waters. The island remains sealed until that hour."
			}

		"elara":
			greeting = "Walk softly, traveler. The sea wind carries uneasy whispers today... Are you seeking healing remedies, or truth?"
			fallback_response = "The earth remembers every step we take. Be cautious of your footing in Hollowcreek, traveler."
			dialogue_dict = {
				"who|you|elara|name": "I am Elara. I gather herbs that cling to the coastal cliffs—chamomile, rosemary, and valerian. Plants speak if you take time to listen.",
				"aldric|victim|lord": "Lord Aldric came to me three days ago with trembling hands. He begged for valerian and concentrated poppy oil to help him sleep. He kept muttering that 'the contractor has dispatched a ghost'.",
				"corin|fight|argument|bazaar|dispute|fletcher": "At dusk, right before nightfall, I was packing my dried herb bundles by the central fountain. Corin Fletcher and Lord Aldric were having a furious, screaming argument! Lord Aldric shouted that he was evicting Corin from the bazaar and seizing all his wares. Corin was red-faced with rage and screamed that Aldric would not live to see the dawn!",
				"murder|kill|dead|death": "Death leaves a lingering chill. The storehouse sits near the cliffs where wild hemlock blooms. Some claimed to smell almond, but Doctor Wren says no poison was swallowed.",
				"cottage|herbs|plants|medicine|purple": "My cottage is south near the coastal path. I grow many remedies... some heal the heart, while others—like the purple nightshade—can stop it forever if mishandled.",
				"pass|mountain|road": "The northern pass is ancient. The wind howls through the canyon. You came from beyond the mountains... did you feel a shadow following you?",
				"garrick|harbour": "Garrick has a fierce temper, but his heart is simple iron, not malice. Yet he carries heavy debts.",
				"isolde|ravenshade": "Lady Isolde purchases lavender for her migraines. She is proud, but her sorrow runs deep.",
				"edmund|physician": "Doctor Wren is thorough. When he examined Aldric, he knew at once it was a stiletto blade, not my herbs."
			}

		"corin":
			greeting = "Fresh apples, salted mackerel, dried herbs! Best goods in the City Bazaar! ...Though between you and me, folks aren't doing much shopping with a killer on the loose."
			fallback_response = "I sell wares, not gossip! Well... maybe a little gossip. Try asking about the market, the victim, or the other villagers."
			dialogue_dict = {
				"who|you|corin|vendor|merchant|name": "Corin's the name! I run the produce and dry goods stall here in the City Bazaar. I see every face that crosses the cobblestones.",
				"aldric|victim|lord": "Lord Aldric was a ruthless tyrant. Threatened to seize my stall and throw me out of the village. I won't pretend I mourn him.",
				"fight|argument|quarrel|elara|dispute": "Aye, it's true... Aldric and I had a fierce shouting match by the fountain at dusk. He mocked my father and threw my account slates to the dirt. Elora the herbalist saw it all from across the plaza. But I swear on my mother's soul, I did not plunge steel into him!",
				"murder|kill|dead|death": "Dead in the storehouse! Word is, someone slipped a blade into his ribs without making a sound. Gives me shivers looking over toward the cliffs.",
				"bazaar|market|square|well": "The City Bazaar is usually buzzing. But today, everyone's whispering in corners. Garrick, Lena, Silas... even the guard Tomas looks jumpy.",
				"clues|evidence|suspect": "I saw someone in a dark cloak slipping behind the Town Hall just before the bell rang dusk. They were in a hurry, heading toward the east path."
			}

		"tomas":
			greeting = "Halt. State your business in Hollowcreek. The roads through the pass aren't safe, and by Council order, nobody leaves without inspection."
			fallback_response = "Keep moving and stay on the stone roads. If I catch you snooping around restricted buildings or the cliffs, you'll spend the night in the lockup."
			dialogue_dict = {
				"who|you|tomas|guard|name": "Sergeant Tomas, town guard. My duty is the security of Hollowcreek and safeguarding the northern mountain pass. It's the only land route in or out.",
				"aldric|victim|lord": "Lord Aldric was an aristocrat with many enemies. He arrived from the capital claiming he wanted peace by the sea. Clearly, his past caught up with him.",
				"murder|kill|dead|death": "His body was discovered at dawn in the eastern storehouse. The council ordered the northern pass sealed to outgoing travelers until Mayor Eldridge finishes his inquiry.",
				"pass|mountain|road|entrance": "The pass is walled in by sheer granite cliffs. No one enters or leaves without passing my watchpost. You are the only person who arrived through that pass today.",
				"garrick|harbour": "Garrick is down at the docks. He had words with Aldric in the square yesterday. If he swung a weapon, it wouldn't be in the shadows. Still, he's on the suspect list.",
				"leave|exit|gate": "No one leaves town. Not through the pass, and not across the water. Until the Mayor identifies the assassin, this whole island is locked down."
			}

# ---------------------------------------------------------------------------
# VISUAL MESH GENERATION (FBX SCENE OR PROCEDURAL FALLBACK)
# ---------------------------------------------------------------------------
func _build_visual_mesh() -> void:
	for c in get_children():
		if c.name == "CharacterModel" or c.name == "ProceduralMesh":
			c.queue_free()

	if character_scene != null:
		var model_inst := character_scene.instantiate() as Node3D
		model_inst.name = "CharacterModel"
		add_child(model_inst)
		character_mesh_root = model_inst
		
		# Hook up limb pivots for dynamic animation
		_leg_pivot_l = model_inst.get_node_or_null("LegPivotL")
		_leg_pivot_r = model_inst.get_node_or_null("LegPivotR")
		_arm_pivot_l = model_inst.get_node_or_null("ArmPivotL")
		_arm_pivot_r = model_inst.get_node_or_null("ArmPivotR")
		return

	# Fallback procedural mesh
	_build_procedural_fallback_mesh()

func _update_limb_animation(delta: float, is_moving: bool) -> void:
	if is_moving:
		_walk_anim_phase += delta * walk_speed * 4.5
		var swing: float = sin(_walk_anim_phase) * 0.35
		if _leg_pivot_l: _leg_pivot_l.rotation.x = swing
		if _leg_pivot_r: _leg_pivot_r.rotation.x = -swing
		if _arm_pivot_l: _arm_pivot_l.rotation.x = -swing * 0.7
		if _arm_pivot_r: _arm_pivot_r.rotation.x = swing * 0.7
		if character_mesh_root:
			character_mesh_root.position.y = abs(sin(_walk_anim_phase)) * 0.035
	else:
		if _leg_pivot_l: _leg_pivot_l.rotation.x = lerpf(_leg_pivot_l.rotation.x, 0.0, delta * 8.0)
		if _leg_pivot_r: _leg_pivot_r.rotation.x = lerpf(_leg_pivot_r.rotation.x, 0.0, delta * 8.0)
		if _arm_pivot_l: _arm_pivot_l.rotation.x = lerpf(_arm_pivot_l.rotation.x, 0.0, delta * 8.0)
		if _arm_pivot_r: _arm_pivot_r.rotation.x = lerpf(_arm_pivot_r.rotation.x, 0.0, delta * 8.0)
		if character_mesh_root:
			_walk_anim_phase += delta * 1.5
			character_mesh_root.position.y = sin(_walk_anim_phase) * 0.008

func _setup_collision() -> void:
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not col_shape:
		col_shape = CollisionShape3D.new()
		col_shape.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.45
		cap.height = 1.85
		col_shape.shape = cap
		col_shape.position = Vector3(0, 0.925, 0)
		add_child(col_shape)

func _build_procedural_fallback_mesh() -> void:
	character_mesh_root = Node3D.new()
	character_mesh_root.name = "ProceduralMesh"
	add_child(character_mesh_root)

	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = skin_color
	mat_skin.roughness = 0.85

	var mat_clothes := StandardMaterial3D.new()
	mat_clothes.albedo_color = clothing_color
	mat_clothes.roughness = 0.75

	var mat_accent := StandardMaterial3D.new()
	mat_accent.albedo_color = accent_color
	mat_accent.roughness = 0.80

	var mat_hair := StandardMaterial3D.new()
	mat_hair.albedo_color = hair_color
	mat_hair.roughness = 0.90

	var mat_boots := StandardMaterial3D.new()
	mat_boots.albedo_color = Color(0.18, 0.14, 0.12)
	mat_boots.roughness = 0.8

	# Torso
	var torso := MeshInstance3D.new()
	var torso_box := BoxMesh.new()
	torso_box.size = Vector3(0.55, 0.65, 0.30)
	torso.mesh = torso_box
	torso.material_override = mat_clothes
	torso.position = Vector3(0, 1.05, 0)
	character_mesh_root.add_child(torso)

	# Head
	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.36, 0.36, 0.36)
	head.mesh = head_box
	head.material_override = mat_skin
	head.position = Vector3(0, 1.55, 0)
	character_mesh_root.add_child(head)

	# Leg pivots
	_leg_pivot_l = Node3D.new(); _leg_pivot_l.name = "LegPivotL"
	_leg_pivot_l.position = Vector3(-0.15, 0.70, 0)
	character_mesh_root.add_child(_leg_pivot_l)
	var leg_l := MeshInstance3D.new(); var leg_box := BoxMesh.new()
	leg_box.size = Vector3(0.20, 0.55, 0.22); leg_l.mesh = leg_box; leg_l.material_override = mat_clothes
	leg_l.position = Vector3(0, -0.275, 0); _leg_pivot_l.add_child(leg_l)

	_leg_pivot_r = Node3D.new(); _leg_pivot_r.name = "LegPivotR"
	_leg_pivot_r.position = Vector3(0.15, 0.70, 0)
	character_mesh_root.add_child(_leg_pivot_r)
	var leg_r := MeshInstance3D.new(); leg_r.mesh = leg_box; leg_r.material_override = mat_clothes
	leg_r.position = Vector3(0, -0.275, 0); _leg_pivot_r.add_child(leg_r)

	# Arm pivots
	_arm_pivot_l = Node3D.new(); _arm_pivot_l.name = "ArmPivotL"
	_arm_pivot_l.position = Vector3(-0.36, 1.35, 0)
	character_mesh_root.add_child(_arm_pivot_l)
	var arm_l := MeshInstance3D.new(); var arm_box := BoxMesh.new()
	arm_box.size = Vector3(0.16, 0.60, 0.18); arm_l.mesh = arm_box; arm_l.material_override = mat_clothes
	arm_l.position = Vector3(0, -0.30, 0); _arm_pivot_l.add_child(arm_l)

	_arm_pivot_r = Node3D.new(); _arm_pivot_r.name = "ArmPivotR"
	_arm_pivot_r.position = Vector3(0.36, 1.35, 0)
	character_mesh_root.add_child(_arm_pivot_r)
	var arm_r := MeshInstance3D.new(); arm_r.mesh = arm_box; arm_r.material_override = mat_clothes
	arm_r.position = Vector3(0, -0.30, 0); _arm_pivot_r.add_child(arm_r)
