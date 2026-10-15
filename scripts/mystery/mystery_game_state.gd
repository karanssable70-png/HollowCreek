class_name MysteryGameState
extends Node

## MysteryGameState
## Authoritative murder mystery game manager for HOLLOWCREEK: THE LAST CROSSING.
## Tracks:
## - 3-day countdown and island lockdown state
## - Authoritative clue discovery and inventory
## - NPC trust, suspicion, memories, and rumors
## - Evidence linking Garrick to the assassination
## - Evidence linking the player (The Mercenary) to the murder
## - Contradiction detection between testimonies
## - Mayor's evidence-based verdict evaluation
## - The 4 distinct game endings

signal day_advanced(new_day: int, days_left: int)
signal clue_discovered(clue_id: String, title: String)
signal contradiction_found(contradiction_id: String, details: String)
signal suspicion_changed(npc_id: String, new_level: float)
signal verdict_reached(ending_id: String, summary: String)

static var instance: MysteryGameState = null

# --- COUNTDOWN & LOCKDOWN ---
@export var current_day: int = 1
@export var max_days: int = 3
@export var is_lockdown_active: bool = true
@export var ship_arrived: bool = false

# --- PLAYER SUSPICION & GARRICK EXPOSURE ---
@export var player_overall_suspicion: float = 15.0 # 0 to 100
@export var garrick_exposure_level: float = 10.0   # 0 to 100
@export var isolde_suspicion: float = 25.0        # 0 to 100
@export var outsider_ghost_theory: float = 30.0   # 0 to 100

# --- DISCOVERED CLUES & EVIDENCE ---
var discovered_clues: Array[String] = []
var presented_evidence: Array[String] = []
var logged_contradictions: Array[String] = []

# --- NPC STATE REGISTRY ---
var npc_states: Dictionary = {
	"garrick": {"trust": 75.0, "suspicion": 10.0, "accused": "isolde", "memories": []},
	"isolde": {"trust": 30.0, "suspicion": 35.0, "accused": "garrick", "memories": []},
	"edmund": {"trust": 50.0, "suspicion": 20.0, "accused": "unknown", "memories": []},
	"lena": {"trust": 60.0, "suspicion": 15.0, "accused": "garrick", "memories": []},
	"oswin": {"trust": 40.0, "suspicion": 25.0, "accused": "garrick", "memories": []},
	"finn": {"trust": 65.0, "suspicion": 10.0, "accused": "unknown", "memories": []},
	"elara": {"trust": 55.0, "suspicion": 15.0, "accused": "unknown", "memories": []},
	"corin": {"trust": 70.0, "suspicion": 10.0, "accused": "unknown", "memories": []},
	"tomas": {"trust": 40.0, "suspicion": 30.0, "accused": "player", "memories": []},
	"mayor": {"trust": 50.0, "suspicion": 20.0, "accused": "unknown", "memories": []}
}

# --- CLUE DATABASE ---
var clue_definitions: Dictionary = {
	"stolen_stiletto": {
		"title": "Custom Triangular Stiletto",
		"desc": "The murder weapon matching Edmund's autopsy: single fatal puncture between 4th and 5th ribs.",
		"incriminates_player": 30.0,
		"incriminates_garrick": 15.0
	},
	"burnt_contract_scrap": {
		"title": "Burnt Contract Scrap (Raven Seal)",
		"desc": "Recovered from the inn hearth. Reads: 'Contract complete upon sunset'. Sigil matches capital syndicate.",
		"incriminates_player": 20.0,
		"incriminates_garrick": 25.0
	},
	"storehouse_iron_key": {
		"title": "Storehouse Master Key",
		"desc": "Only two keys exist for the murder scene: Lord Aldric's and Harbour Master Garrick's.",
		"incriminates_player": 10.0,
		"incriminates_garrick": 35.0
	},
	"autopsy_report": {
		"title": "Physician Wren's Post-Mortem",
		"desc": "Clean thoracic puncture to left ventricle. Zero poison. Professional military execution between 2nd and 3rd bells.",
		"incriminates_player": 15.0,
		"incriminates_garrick": 10.0
	},
	"debt_ledgers": {
		"title": "Aldric's Extortion Ledgers",
		"desc": "Oswin's financial accounts proving Garrick owed thousands in tariffs and Isolde had disputed land deeds.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 30.0
	},
	"muddy_cliff_boots": {
		"title": "Military Boot Prints",
		"desc": "Fresh mud tracks along the cliff path heading from the storehouse toward the square.",
		"incriminates_player": 25.0,
		"incriminates_garrick": 5.0
	},
	"ship_manifest": {
		"title": "Secret Harbour Schedule",
		"desc": "Details of the merchant schooner docking on Night 3, the only way off the island.",
		"incriminates_player": 5.0,
		"incriminates_garrick": 10.0
	},
	"tomas_hypersomnia_report": {
		"title": "Tomas's Hypersomnia Diagnosis",
		"desc": "Medical report from Tomas's drawer diagnosing severe chronic hypersomnia, proving he fell comatose on watch.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 0.0
	},
	"physician_falsified_autopsy": {
		"title": "Edmund's Falsified Autopsy Draft",
		"desc": "Autopsy draft from Dr. Edmund's drawer showing he crossed out murder to declare natural heart failure under blackmail.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 20.0
	},
	"garrick_embezzlement_records": {
		"title": "Garrick's Port Embezzlement Audit",
		"desc": "Audit dossier proving Lord Aldric caught Garrick stealing 4,200 crowns and threatened him with the gallows.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 40.0
	},
	"corin_bazaar_altercation": {
		"title": "Corin's Eviction Notice & Dispute",
		"desc": "Records of Lord Aldric's debt extortion and violent altercation with Corin at dusk witnessed by Elora.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 0.0
	},
	"lena_stolen_belongings": {
		"title": "Lord Aldric's Stolen Crest Purse & Ring",
		"desc": "Recovered from under Lena's floorboards; proves she pickpockets guests but did not commit homicide.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 0.0
	},
	"finn_early_clock_in": {
		"title": "Finn's 3:30 AM Watch Clock-In Slip",
		"desc": "Proves Finn arrived early in pitch darkness to secure his boat in the gale and stumbled onto the corpse.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 0.0
	},
	"isolde_land_transfer_decree": {
		"title": "Isolde's Foreclosure & Asset Seizure",
		"desc": "Decree showing Lord Aldric forcefully seized Lady Isolde's ancestral manor and northern vineyards.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 0.0
	},
	"oswin_master_ledger": {
		"title": "Oswin's Master Financial Ledger",
		"desc": "Village steward's master accounts detailing Aldric's extortion and debts over all citizens.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 25.0
	},
	"elara_purple_herbs_stash": {
		"title": "Elora's Purple Nightshade Stash",
		"desc": "Large supply of lethal paralytic nightshade matching poison in Aldric's body, sold to Garrick Thorne.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 35.0
	},
	"mayor_bribe_correspondence": {
		"title": "Mayor Eldridge's Kickback Letters",
		"desc": "Correspondence in the Mayor's secret house proving annual bribes to suppress council investigations.",
		"incriminates_player": 0.0,
		"incriminates_garrick": 15.0
	}
}

func _enter_tree() -> void:
	if instance == null:
		instance = self
	add_to_group("mystery_manager")

func _exit_tree() -> void:
	if instance == self:
		instance = null

## Discover a new clue in the world
func discover_clue(clue_id: String) -> void:
	if not discovered_clues.has(clue_id):
		discovered_clues.append(clue_id)
		var c_name: String = clue_definitions.get(clue_id, {}).get("title", clue_id)
		clue_discovered.emit(clue_id, c_name)
		print("[Mystery] New Clue Discovered: ", c_name)

## Present evidence to the Mayor at Town Hall
func present_evidence_to_mayor(clue_id: String) -> void:
	if not presented_evidence.has(clue_id):
		presented_evidence.append(clue_id)
		var c_data: Dictionary = clue_definitions.get(clue_id, {})
		player_overall_suspicion += c_data.get("incriminates_player", 0.0) * 0.5
		garrick_exposure_level += c_data.get("incriminates_garrick", 0.0)
		print("[Mystery] Evidence presented to Mayor Eldridge: ", clue_id)

## Record an NPC memory of an interaction
func add_npc_memory(npc_id: String, memory: String) -> void:
	if npc_states.has(npc_id):
		npc_states[npc_id]["memories"].append(memory)
		print("[Mystery] NPC [", npc_id, "] recorded memory: ", memory)

## Adjust NPC suspicion towards player
func adjust_suspicion(npc_id: String, delta: float) -> void:
	if npc_states.has(npc_id):
		npc_states[npc_id]["suspicion"] = clampf(npc_states[npc_id]["suspicion"] + delta, 0.0, 100.0)
		suspicion_changed.emit(npc_id, npc_states[npc_id]["suspicion"])
		_recalculate_overall_suspicion()

## Check for contradictions between statements
func report_contradiction(contradiction_id: String, details: String) -> void:
	if not logged_contradictions.has(contradiction_id):
		logged_contradictions.append(contradiction_id)
		contradiction_found.emit(contradiction_id, details)
		print("[Mystery] Contradiction Logged: ", details)

## Advance the 3-day countdown
func advance_day() -> void:
	current_day += 1
	var days_left: int = max_days - current_day
	if current_day >= max_days:
		ship_arrived = true
	day_advanced.emit(current_day, days_left)
	print("[Mystery] Dawn breaks on Day ", current_day, ". Days until ship arrival: ", days_left)

## Calculate the Mayor's evidence-based verdict using game logic
## Returns one of the 4 distinct endings
func evaluate_mayor_verdict() -> Dictionary:
	var score_player: float = player_overall_suspicion
	var score_garrick: float = garrick_exposure_level
	var score_isolde: float = isolde_suspicion
	
	# Evaluate physical evidence presented to Mayor
	if presented_evidence.has("stolen_stiletto"):
		score_player += 20.0
	if presented_evidence.has("muddy_cliff_boots"):
		score_player += 25.0
	if presented_evidence.has("burnt_contract_scrap"):
		score_garrick += 30.0
	if presented_evidence.has("storehouse_iron_key"):
		score_garrick += 35.0
	if presented_evidence.has("debt_ledgers"):
		score_garrick += 20.0
		score_isolde += 15.0
		
	# Contradictions add suspicion
	score_player += float(logged_contradictions.size()) * 8.0
	
	print("[Mystery Verdict] Scores: Player=", score_player, " Garrick=", score_garrick, " Isolde=", score_isolde)
	
	# Determine ending
	var ending_id: String = ""
	var ending_title: String = ""
	var ending_summary: String = ""
	
	# Ending 4: Mutual Destruction (both high suspicion)
	if score_player >= 70.0 and score_garrick >= 70.0:
		ending_id = "ending_mutual_destruction"
		ending_title = "Ending 4: Ashes on the Coast"
		ending_summary = "Mayor Eldridge unravels the conspiracy between Garrick and the hired assassin. Guards swarm both the docks and the tavern. Mutual ruin claims both the contractor and the mercenary."
	# Ending 3: Player Caught (player primary suspect)
	elif score_player >= 65.0 and score_player > score_garrick:
		ending_id = "ending_player_caught"
		ending_title = "Ending 3: The Gallows of Hollowcreek"
		ending_summary = "The accumulated forensic evidence and contradictions point definitively to you. Mayor Eldridge sentences you to the gallows before the town assembly."
	# Ending 2: Garrick Exposed (Garrick primary suspect, player escapes)
	elif score_garrick >= 60.0 and score_garrick > score_player:
		ending_id = "ending_garrick_exposed"
		ending_title = "Ending 2: The Contractor's Fall"
		ending_summary = "Mayor Eldridge finds Harbour Master Garrick Thorne guilty of masterminding the murder of Lord Aldric Vale. While the guards arrest Garrick, you slip aboard the incoming schooner unnoticed."
	# Ending 1: Perfect Escape / Framed Target (player clears suspicion)
	else:
		ending_id = "ending_perfect_escape"
		ending_title = "Ending 1: The Ghost of Hollowcreek"
		ending_summary = "With suspicion diverted toward shadowy outsiders and Lady Isolde's land disputes, the island lockdown lifts as the merchant ship docks. You depart Hollowcreek as a ghost in the fog, contract complete."
		
	verdict_reached.emit(ending_id, ending_summary)
	return {
		"ending_id": ending_id,
		"title": ending_title,
		"summary": ending_summary,
		"scores": {"player": score_player, "garrick": score_garrick, "isolde": score_isolde}
	}

func _recalculate_overall_suspicion() -> void:
	var total: float = 0.0
	for nid: String in npc_states:
		total += npc_states[nid]["suspicion"]
	player_overall_suspicion = total / float(npc_states.size())
