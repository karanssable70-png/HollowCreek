class_name SuspectDatabase
extends RefCounted

## SuspectDatabase
## Authoritative suspect dossiers, alibis, dark secrets, behavioral anomaly tells,
## and deceptive dialogue responses for HOLLOWCREEK: THE LAST CROSSING.
## Inspired by games like "No, I'm Not Human", "That's Not My Neighbor", and "Papers, Please".

static func get_all_suspects() -> Array[Dictionary]:
	return [
		get_suspect_data("garrick"),
		get_suspect_data("isolde"),
		get_suspect_data("edmund"),
		get_suspect_data("lena"),
		get_suspect_data("oswin"),
		get_suspect_data("finn"),
		get_suspect_data("mayor"),
		get_suspect_data("elara"),
		get_suspect_data("tomas"),
		get_suspect_data("corin")
	]

static func get_suspect_data(id: String) -> Dictionary:
	match id.to_lower():
		"garrick":
			return {
				"id": "garrick",
				"name": "Garrick Thorne",
				"role": "Harbour Master",
				"personality": "Authoritative, controlling, defensive, and secretive",
				"suspicious_trait": "Protects his reputation and becomes guarded about harbour finances after Aldric discovers his embezzlement.",
				"model_scene": "res://scenes/characters/garrick.tscn",
				"is_the_killer": true,
				"dark_secret": "Masterminded Lord Aldric's murder and hired the syndicate assassin to erase immense debts and seize monopoly over the harbor.",
				"alibi": "Claims he was tallying salt pork and grain manifests at the lower wharf office until fourth bell.",
				"alibi_contradiction": "The dock office was locked by Oswin at second bell. Garrick's personal iron key was used to enter the murder storehouse.",
				"behavioral_anomalies": [
					"Constantly checks heavy brass pocket watch with trembling fingers.",
					"Rapid pupil constriction whenever the storehouse is mentioned.",
					"Voice drops to an unnatural, rehearsed monotone when discussing Lord Aldric's death.",
					"Refuses to look at his right pocket where the storehouse key was kept."
				],
				"stress_baseline": 65,
				"greeting": "Detective. I'm a busy man with ships to clear. Ask what you must, but don't waste my time with tavern gossip.",
				"alibi_statement": "I was down at the wharf from dusk until fourth bell. Checking the salt pork manifests for the incoming schooner. The dock hands saw me by the crane.",
				"motive_statement": "Aldric? The man was an arrogant imperial leech, yes. Demanded heavy cuts of every crate passing through my docks. But I settle business with coins and fists, not a blade in the dark.",
				"clue_reactions": {
					"storehouse_iron_key": "Where did you... That's impossible. Only two keys exist—his lordship had one, and mine was... mine was misplaced yesterday!",
					"burnt_contract_scrap": "A raven seal? You're chasing capital phantoms, Detective. Half the trade guilds in the kingdom stamp their wax with ravens.",
					"stolen_stiletto": "A stiletto? A foreign assassin's blade. No fisherman or dock hand on this island carries a pig-sticker like that.",
					"debt_ledgers": "Aldric's numbers were fiction! He forged those ledgers to extort my family's wharf! He had no right to our generational docks!",
					"muddy_cliff_boots": "Mud? In a coastal town surrounded by rain and stone? Everyone has mud on their heels, Detective."
				},
				"secret_denial": "You're throwing wild accusations, inquisitor! I am a pillar of this community! You have no warrant to question my honor!",
				"secret_confession": "ENOUGH! Yes! I took the contract! Aldric was an extortionist who was going to seize my grandfather's harbor and leave my men starving! He bled us for ten years! The raven syndicate gave us a way out—a clean cut, one strike, and the island is free! You think the High Court cares about Hollow Creek? You'll never leave this rock to tell them!",
				"general_keywords": {
					"key|storehouse": "The old storehouse is municipal property. Lord Aldric used it for storing impounded cargo. I don't keep tabs on every lock on this island.",
					"assassin|contract|raven": "If an assassin crossed the water, ask the sentries at the gate. My boats are under strict quarantine.",
					"ship|schooner|escape": "The merchant schooner arrives tomorrow night. Once it drops anchor, I inspect the cargo and clear the departure list. That's my duty.",
					"aldric|lord": "Lord Aldric came from high court money. Looked down on every honest tradesman in the valley. Few tears will be shed at his wake."
				}
			}

		"isolde":
			return {
				"id": "isolde",
				"name": "Lady Isolde Sterling",
				"role": "Noblewoman",
				"personality": "Proud, calculating, composed, and resentful",
				"suspicious_trait": "Hides her anger over the land and money Aldric took from her.",
				"model_scene": "res://scenes/characters/isolde.tscn",
				"is_the_killer": false,
				"dark_secret": "Contested forged land deeds and stolen ancestral estate charters taken by Aldric. Confronted him on his terrace that night.",
				"alibi": "Claims she remained in her manor drawing room reviewing private correspondence all evening.",
				"alibi_contradiction": "Her maid Lena was not at the manor, and a witness saw a hooded figure matching her velvet cloak leaving Aldric's terrace at tenth bell.",
				"behavioral_anomalies": [
					"Fidgets compulsively with her heavy emerald signet ring.",
					"Sharp, disdainful sneer when questioned about commoners or finances.",
					"Takes sharp, shallow breaths whenever the word 'extortion' or 'charter' is spoken.",
					"Subtly rearranges her silk shawl to conceal her trembling hands."
				],
				"stress_baseline": 55,
				"greeting": "Detective. I trust this inquiry will be conducted with the decorum fitting my station, rather than the vulgarities of the village square.",
				"alibi_statement": "I retired to my drawing room immediately following supper. I was reviewing family correspondence by the hearth. My maid can confirm my presence.",
				"motive_statement": "Aldric was vulgar, ambitious, and utterly lacking in pedigree. He presumed to challenge centuries of Sterling family land grants. But assassination? Violence is the crude tool of peasants, not nobility.",
				"clue_reactions": {
					"debt_ledgers": "Those papers are abominable fabrications! Aldric had no lawful claim to the northern bluffs! The Sterling estate was granted by royal decree three generations ago!",
					"burnt_contract_scrap": "Barbaric. Some mercenary guild from the slums of the capital. I have no traffic with hired cutthroats.",
					"storehouse_iron_key": "Iron keys to salt warehouses? Speak to Garrick or the town bailiff. I do not soil my fingers with wharf locks.",
					"stolen_stiletto": "An ugly, barbaric weapon. Do you intend to wave every bloody utensil in front of highborn women, Detective?"
				},
				"secret_denial": "How dare you suggest I harbor secrets from a travelling inquisitor! My lineage is unblemished!",
				"secret_confession": "Be silent! Do not utter that in this room! Yes... Aldric uncovered forged signatures on our northern estate deeds. My late uncle altered the boundary stones thirty years ago. Aldric was blackmailing me for half our annual revenue! I went to his manor to threaten him with royal exposure, but he was already terrified—he said a syndicate shadow was watching him! I left him alive and terrified, I swear it!",
				"general_keywords": {
					"estate|land|deed": "The Sterling estate is sovereign under the old charters. Lord Aldric had no right to question my family's holdings.",
					"garrick|harbour": "Garrick is a crude brawler with salt in his veins. He owed thousands to the creditors. Ask him about unpaid tariffs.",
					"aldric": "A tyrant in fine velvet. He thought he could buy respectability on an isolated island."
				}
			}

		"edmund":
			return {
				"id": "edmund",
				"name": "Dr. Edmund Wren",
				"role": "Physician",
				"personality": "Clinical, analytical, reserved, and evasive",
				"suspicious_trait": "Relies on medical authority to maintain credibility; falsified Aldric's postmortem, though this alone does not prove murder.",
				"model_scene": "res://scenes/characters/edmund.tscn",
				"is_the_killer": false,
				"dark_secret": "Falsified Lord Aldric's postmortem report claiming natural cardiac death to maintain credibility or protect a patron; the report was found in his drawer.",
				"alibi": "Claims he was asleep in his clinic dispensary after cataloguing dried herbs and treating colic.",
				"alibi_contradiction": "The drafted postmortem citing 'natural causes' was found hidden in his private desk drawer, directly concealing the fatal stiletto puncture.",
				"behavioral_anomalies": [
					"Rapid involuntary blinking when looking directly at the detective.",
					"Constantly wipes fingertips with an alcohol-scented linen handkerchief.",
					"Nervously glances at his fingernails, checking for traces of dirt or chemicals.",
					"Swallows audibly whenever the word 'autopsy' or 'drawer' is uttered."
				],
				"stress_baseline": 60,
				"greeting": "Detective Wren at your service. If this is regarding Lord Aldric's post-mortem, my anatomical report has already been delivered to Mayor Eldridge.",
				"alibi_statement": "I spent the evening in my apothecary dispensary preparing willow-bark tincture. I retired to bed shortly after the church bells struck nine.",
				"motive_statement": "Aldric was my patron, Detective. He funded my clinic's imported reagents. His sudden demise is a severe medical and scientific setback for my practice.",
				"clue_reactions": {
					"autopsy_report": "My preliminary findings... medical science requires meticulous observation before trauma pathology is finalized. A single triangular stiletto wound entered the left ventricle.",
					"stolen_stiletto": "Fascinating blade... triangular cross-section prevents the wound from closing. Standard issue for military stealth corps. Whoever wielded this understood thoracic anatomy.",
					"burnt_contract_scrap": "Paper ashes? I am a physician, Detective, not a forensic chimney sweep."
				},
				"secret_denial": "I am a man of science! My reputation throughout the province is spotless! What are you insinuating?",
				"secret_confession": "Please... keep your voice down! Yes, I drafted a false certificate claiming cardiac failure! I was terrified the townsfolk would descend into wild panic, and Master Garrick pressured me to declare it natural! But I did not murder Aldric! The puncture wound was already cold when they called me to the storehouse!",
				"general_keywords": {
					"autopsy|body|wound": "The wound was clean and instantaneous. Lord Aldric did not suffer more than three heartbeats.",
					"poison|wolfsbane": "There was no poison in his system. His gastric contents were clear. The death was purely mechanical blood loss from the heart puncture.",
					"clinic|drawer|report": "My clinic is devoted to saving lives. Whatever drafts were in my drawer were preliminary clinical notes!"
				}
			}

		"lena":
			return {
				"id": "lena",
				"name": "Lena Hart",
				"role": "Innkeeper",
				"personality": "Sociable, observant, charming, and secretive",
				"suspicious_trait": "May deflect uncomfortable questions about Aldric's possessions; she steals from guests, which is suspicious but not proof of murder.",
				"model_scene": "res://scenes/characters/lena.tscn",
				"is_the_killer": false,
				"dark_secret": "Habitually steals silver coins and personal belongings from guests at the inn, and Aldric's coins were found in her quarters.",
				"alibi": "Claims she barred the tavern doors at sunset and slept peacefully in the upstairs loft after serving cider.",
				"alibi_contradiction": "Guests reported missing silver coins, and Aldric's personal purse and engraved silver coins were found hidden in her rooms.",
				"behavioral_anomalies": [
					"Arms tightly crossed over her chest in an intensely guarded defensive posture.",
					"Eyes dart sideways whenever the inn rooms or Aldric's possessions are mentioned.",
					"Constantly rubs a callous on her right thumb in a nervous fidget.",
					"Voice strains upward into high charm when insisting that she is completely honest."
				],
				"stress_baseline": 50,
				"greeting": "Evening, Detective. We don't get many royal inquisitors at The Lantern. What brings you to drag me out of my kitchen?",
				"alibi_statement": "I barred the tavern shutters when the fog rolled in at sundown. Drank a cup of chamomile and was snoring in my bed upstairs before tenth bell.",
				"motive_statement": "Aldric spent plenty of gold on fine port, but he had an ugly temper when he drank. Threw a pewter mug at my barmaid last fortnight. But tavern keepers don't kill their paying patrons.",
				"clue_reactions": {
					"burnt_contract_scrap": "Where did you find this? My hearth? Detective, customers toss all manner of trash, letters, and pipe rags into the tavern fire!",
					"debt_ledgers": "Aldric's debts? Ha! He threw money around like rainwater. Everyone knew he was mortgaged to the hilt.",
					"stolen_stiletto": "Mercy... that's a nasty weapon. Keep it away from me. We only keep carving knives in the pantry."
				},
				"secret_denial": "I run an honest inn! Ale, hot broth, and clean straw mattresses! What are you trying to pin on me?",
				"secret_confession": "Alright, quiet! Do you want the whole square to hear you?! Yes, I steal from the guests! A few silver royals here, an unattended ring there! When Aldric left his velvet coat in the parlor, I pocketed his silver coins! But that's petty thievery, not bloody murder! I was upstairs in bed when he went down to the storehouse, I swear on my mother's grave!",
				"general_keywords": {
					"inn|tavern|cellar": "The Lantern has stood for sixty years. Honest drinks for honest folk.",
					"coins|silver|steal": "Travelers misplace coins in taverns every day, Detective. Don't go casting dirty slurs on honest innkeepers.",
					"aldric": "He came in with bloodshot eyes and an arrogant sneer. He was a hated man long before someone stuck a blade in him."
				}
			}

		"oswin":
			return {
				"id": "oswin",
				"name": "Oswin Hale",
				"role": "Steward",
				"personality": "Formal, cautious, discreet, and calculating",
				"suspicious_trait": "Withholds information and has access to Aldric's accounts and household records.",
				"model_scene": "res://scenes/characters/oswin.tscn",
				"is_the_killer": false,
				"dark_secret": "Withholds town financial ledgers and records detailing Aldric's extortion and village debts to protect municipal stability.",
				"alibi": "Claims he was working alone in the Town Hall records archive until sunrise balancing grain tariffs.",
				"alibi_contradiction": "Three pages were freshly ripped out of the municipal audit ledger, and confidential accounts were concealed in his desk.",
				"behavioral_anomalies": [
					"Profuse perspiration across his forehead and upper lip, constantly dabbing with a sodden sleeve.",
					"Severe nervous stammer whenever numbers, accounts, or the treasury are referenced.",
					"Incessantly taps ink-stained fingers on the table in an erratic rhythm.",
					"Cannot maintain eye contact for more than three seconds before glancing down at his lap."
				],
				"stress_baseline": 75,
				"greeting": "D-Detective! Greetings. The municipal archives are at your complete disposal... naturally. How may the stewardship assist your inquiry?",
				"alibi_statement": "I was confined to the Town Hall archives! Auditing the autumn grain excise. The paperwork is mountainous, sir! I did not extinguish my desk lamp until the roosters crowed at dawn!",
				"motive_statement": "Lord Aldric oversaw the parish audits. He was... meticulous. Demanding. But our relationship was purely bureaucratic! Professional and courteous!",
				"clue_reactions": {
					"debt_ledgers": "Those ledgers! W-where did you retrieve those?! Those are confidential municipal records! They were locked in the archive safe!",
					"storehouse_iron_key": "The storehouse key... Master Garrick was supposed to return the duplicate to my desk three days ago. I filed a requisition note, I swear it!",
					"burnt_contract_scrap": "A syndicate contract? High treason... conspiracy against the crown... I know nothing of such horrors!"
				},
				"secret_denial": "My ledgers are balanced to the farthing! I have served Hollow Creek for twenty years without a blot on my ledger!",
				"secret_confession": "Mercy, Detective! Have mercy on me! Yes, I tore out the pages! The ledgers prove Garrick was drowning in debts and Aldric was extorting half the town! If those numbers leaked, the whole council would burn! But I didn't kill him! I'm an accountant, not an assassin!",
				"general_keywords": {
					"ledger|treasury|money": "The treasury is properly accounted for... minor rounding discrepancies, standard for coastal trade...",
					"mayor|townhall": "Mayor Eldridge is an honorable magistrate. He trusts my bookkeeping implicitly.",
					"garrick": "Master Garrick has been aggressive about port fees lately. He pressured me to alter the dock tariffs last month."
				}
			}

		"finn":
			return {
				"id": "finn",
				"name": "Finn Mercer",
				"role": "Dockworker",
				"personality": "Blunt, practical, wary, and hard-working",
				"suspicious_trait": "Discovered Aldric's body unusually early, making his reason for being there an important lead.",
				"model_scene": "res://scenes/characters/finn.tscn",
				"is_the_killer": false,
				"dark_secret": "Was at the docks hours before his shift started moving contraband crates with Corin; found the body unexpectedly.",
				"alibi": "Claims he was asleep on his cot in the fishermen's net shack all night.",
				"alibi_contradiction": "His shift officially begins at sunrise, but he was at the wharf two hours early with fresh contraband splinters on his coat.",
				"behavioral_anomalies": [
					"Rubs the back of his sun-weathered neck with a scarred, leathery hand.",
					"Glances repeatedly toward the chamber door, assessing escape routes.",
					"Shifts his heavy frame in the chair with an uneasy, predatory restlessness.",
					"Bites his cracked lower lip whenever the coastal cliffs or docks are mentioned."
				],
				"stress_baseline": 45,
				"greeting": "Look, chief. I'm just a boatman. I haul cod, mend ropes, and scrub decks. I don't know nothing about fine lords getting knifed.",
				"alibi_statement": "Was out cold in the net shack by the dry dock. Knocked back two pints of bitter ale and slept like a drowned stone until morning.",
				"motive_statement": "Lord Aldric never gave me so much as a copper coin or a backward glance. Lords and deckhands live in two different worlds, sir.",
				"clue_reactions": {
					"muddy_cliff_boots": "Those boots? Standard issue naval leather. Half the sailors in the Bay of Storms wear boots like that. Don't mean they're mine.",
					"ship_manifest": "The merchant schooner? Yeah, she's docking Night 3. Tide's right at midnight. Only way off this cursed rock until winter.",
					"storehouse_iron_key": "Garrick's key? Old Garrick guards that thing like his dead mother's locket. He wouldn't let a dock rat like me within ten paces of it."
				},
				"secret_denial": "I'm a simple fisherman! Work from sunup to sundown for scraps! You're barking up the wrong mast, Detective.",
				"secret_confession": "Alright, listen to me, and keep your voice quiet. Corin and I were hauling smuggled fruit crates into the dinghies before dawn! That's why I was there two hours early! While carrying a crate past the storehouse, I saw the door slightly ajar and saw Lord Aldric lying dead in a pool of blood! I panicked, dropped my nets, and ran for the alarm bell! I didn't kill him!",
				"general_keywords": {
					"boats|docks|sea": "The water's rough this time of year. Currents around the rocks will smash a dinghy to toothpicks if you don't know the reef.",
					"garrick": "Garrick runs a tight grip on the piers. If you don't grease his palm, your cargo rots on the wharf.",
					"early|body": "I told you, I found him when the bell rang. Ask the guards who hauled him away."
				}
			}

		"mayor":
			return {
				"id": "mayor",
				"name": "Mayor Eldridge",
				"role": "Village Mayor",
				"personality": "Pompous, political, defensive, and authoritative",
				"suspicious_trait": "Tolerated Aldric's extortion and took monthly allowances to look the other way.",
				"model_scene": "res://scenes/characters/mayor.tscn",
				"is_the_killer": false,
				"dark_secret": "Covered up Lord Aldric's extortion and racketeering syndicates for ten years in exchange for substantial political kickbacks.",
				"alibi": "Claims he was in his private study drafting the town winter ordinance.",
				"alibi_contradiction": "Aldric's private correspondence reveals a direct ledger of monthly payoffs to 'E.E.' stamped with the mayor's personal wax.",
				"behavioral_anomalies": [
					"Pompous, theatrical throat-clearing before answering difficult questions.",
					"Grips the carved arms of his chair until his knuckles turn porcelain white.",
					"Aggressive counter-questioning: tries to interrogate the detective instead.",
					"His voice wavers into an indignant squeak when the capital syndicates are brought up."
				],
				"stress_baseline": 70,
				"greeting": "Detective. As the chief civic magistrate of Hollow Creek, I expect this investigation to proceed expeditiously and without causing undue panic among the citizenry.",
				"alibi_statement": "I was in my private study at the residence, drafting municipal winter ordinances. My time is strictly accounted for by official civic duties.",
				"motive_statement": "Lord Aldric was an imperial envoy of the crown. His presence brought revenue, prestige, and trade guarantees. His murder is an assault on municipal order itself!",
				"clue_reactions": {
					"debt_ledgers": "Preposterous! These private ledgers are inadmissible hearsay! Aldric was an eccentric investor, nothing more!",
					"burnt_contract_scrap": "A syndicate assassin on my island? Monstrous! The gates must remain locked! No one leaves until this killer is swinging from the gallows!",
					"storehouse_iron_key": "The storehouse master key... Garrick is responsible for harbor property. If his key was used in this crime, he must account for it immediately."
				},
				"secret_denial": "I am the law in Hollow Creek, young inquisitor! Do not mistake your travelling mandate for sovereign authority over this council!",
				"secret_confession": "Quiet down, you fool! You want a peasant revolt in the square?! Yes... Aldric had influence with the capital ministry. He paid me monthly allowances to turn a blind eye to his trade tariffs. If the ministry learned I tolerated his syndicates, my governorship would be terminated! But I did NOT kill him! Having Aldric murdered brings the High Court directly to my doorstep—why would I invite my own ruin?!",
				"general_keywords": {
					"verdict|trial|law": "The evidence must be conclusive and incontrovertible before I pass sentence before the assembled town.",
					"lockdown|ship": "The island remains on total lockdown until Day 3. No boats depart without my signed seal.",
					"aldric": "A powerful man with dangerous friends in the capital. His death is a disaster for this township."
				}
			}

		"elara":
			return {
				"id": "elara",
				"name": "Elara Nightshade",
				"role": "Herbalist",
				"personality": "Independent, perceptive, guarded, and protective of her work",
				"suspicious_trait": "May be resentful if the draft backstory about Aldric taking her herbal research is retained; this motive needs confirmation.",
				"model_scene": "res://scenes/characters/elora.tscn",
				"is_the_killer": false,
				"dark_secret": "Sold a lethal vial of concentrated aconite (wolfsbane) extract to an unknown hooded customer behind the chapel.",
				"alibi": "Claims she was drying chamomile and lavender bundles in her cottage attic.",
				"alibi_contradiction": "Her stone mortar had fresh residues of ground monkshood, and she received 40 silver pieces with capital mint stamps.",
				"behavioral_anomalies": [
					"Keeps her hands buried deeply inside her wool sleeves.",
					"Faint aroma of crushed bitter almonds and sweet herbal oils clings to her.",
					"Speaks in a timid, fragile whisper, avoiding direct eye contact.",
					"Freezes completely still like a frightened deer whenever 'poison' is mentioned."
				],
				"stress_baseline": 65,
				"greeting": "Detective... please, I am only an herbalist. I gather fever tea and soothing salves for the sick. I know nothing of violence.",
				"alibi_statement": "I was in my drying attic all evening, hanging bundles of sweet lavender and sage. The smell gives me peace. I never left my garden gate.",
				"motive_statement": "Lord Aldric once threatened to burn my garden. He called my remedies 'witchcraft'. But Doctor Wren defended my salves. I bore his lordship no ill will.",
				"clue_reactions": {
					"stolen_stiletto": "Steel and blood... such terrible things. A blade cuts so violently. Plants... plants are far gentler, but far deadlier if misused.",
					"autopsy_report": "Doctor Wren confirmed no poison? Then... then the gods are merciful. No potion was swallowed...",
					"burnt_contract_scrap": "The raven sigil... a hooded traveler wore that same bird brooch when they bought my dried herbs last week..."
				},
				"secret_denial": "I am a simple healer! I only ease pain! Why are you looking at me with such cruel suspicion?",
				"secret_confession": "Forgive me, Mother! Forgive me! A stranger came to my garden gate three nights ago. Clad in a dark hooded travelling cloak with a raven clasp! He offered forty capital silver coins for two drams of pure wolfsbane tincture! I was starving, Detective... my winter supplies were empty! I sold it to him! When Aldric died, I thought my poison had killed him! But the autopsy says it was a dagger to the heart! My poison wasn't even used!",
				"general_keywords": {
					"corin|fight|argument|fletcher": "I saw Corin Fletcher and Lord Aldric having a terrible screaming fight by the fountain at dusk! Lord Aldric threatened to seize his bazaar stall and throw him into debtor's prison. Corin was furious and shouted that Aldric wouldn't live to see dawn!",
					"poison|wolfsbane|aconite|purple": "In my cottage workshop I cultivate various plants. I have stashes of purple nightshade (Atropa Purpurea). Harbour Master Garrick bought three vials under the pretext of killing wharf vermin!",
					"herbs|garden": "My cottage at the southern bend grows healing plants for the fishermen's children.",
					"stranger|hooded": "The traveler spoke with a clean capital accent. Tall, calm, cold eyes under a deep hood."
				}
			}

		"tomas":
			return {
				"id": "tomas",
				"name": "Tomas Reed",
				"role": "Town Guard",
				"personality": "Disciplined, watchful, dutiful, and guarded",
				"suspicious_trait": "Was on night shift when Aldric died, so his account of the timeline is important.",
				"model_scene": "res://scenes/characters/tomas.tscn",
				"is_the_killer": false,
				"dark_secret": "Suffers from severe hypersomnia and fell asleep, or accepted a pouch of silver coins to abandon the northern gate watchpost for forty-five minutes.",
				"alibi": "Claims he stood vigilant on sentry duty under the gate arch without blinking all night.",
				"alibi_contradiction": "The watchpost brazier was allowed to burn out, and gate logs show an unrecorded absence between second and third bells.",
				"behavioral_anomalies": [
					"Stands rigidly at military attention, even while seated, compensating for guilt.",
					"Swallows with a sharp click in his throat when the gate schedule is mentioned.",
					"Eyes twitch toward the corners of the room in rapid micro-glances.",
					"Clenches his jaw tightly until his cheek muscles bunch up."
				],
				"stress_baseline": 60,
				"greeting": "Sir! Guard Tomas Reed reporting! Northern gate is fully secured under Mayor Eldridge's lockdown order! No unauthorized passage!",
				"alibi_statement": "I was at my post under the northern arch all night, sir! Eyes on the pass, spear in hand! Not a fox crossed the boundary without my notice!",
				"motive_statement": "Lord Aldric was a dignitary of the crown. As a sworn guard of the township, my duty was to protect him. I failed to prevent his death, and that shame weighs heavy.",
				"clue_reactions": {
					"muddy_cliff_boots": "Sir, tracks near the storehouse? That path links to the old smuggler trail beneath the watchtower. I didn't see anyone take that route, sir!",
					"stolen_stiletto": "A lethal military dagger. That's capital assassin craft. No militia weapon on this island looks like that.",
					"burnt_contract_scrap": "A syndicate contract? Sweet saints... if they had mercenaries on the road, they must have slipped past in the darkness."
				},
				"secret_denial": "I have served this guard post with honor for six years! My father stood sentry on this wall before me!",
				"secret_confession": "Sir! I broke my oath! I am disgraced! A hooded man approached my post at second bell. He tossed a velvet pouch with fifty silver royals at my boots. He told me to go down to the inn for forty minutes and keep my eyes shut. I had debts, Detective... my sister is sick in the capital! I left the gate! When I returned, the brazier was dead and the storehouse door was ajar! I let the killer walk straight through the pass! Court-martial me, hang me, but that is the truth!",
				"general_keywords": {
					"gate|pass|guard": "The northern pass is the only overland route into the mountains. Steep cliffs and rocky trails.",
					"sentry|duty": "Town militia keeps three sentries posted day and night under normal orders.",
					"garrick": "Master Garrick was drinking at the tavern early in the afternoon, asking strange questions about the guard shifts."
				}
			}

		"corin":
			return {
				"id": "corin",
				"name": "Corin Fletcher",
				"role": "Bazaar Merchant",
				"personality": "Talkative, shrewd, irritable, and defensive",
				"suspicious_trait": "Had a public argument with Aldric two days before the murder after Aldric accused him of licking produce.",
				"model_scene": "res://scenes/characters/corin.tscn",
				"is_the_killer": false,
				"dark_secret": "Fences stolen jewelry, smuggled foreign goods, and counterfeit silver coins through false bottoms in his market fruit crates.",
				"alibi": "Claims he was asleep behind his vegetable stall in the bazaar square.",
				"alibi_contradiction": "Was seen by Lena loading crates into Finn's rowboat behind the fish warehouse at 1:00 AM.",
				"behavioral_anomalies": [
					"Speaks with rapid, breathless merchant patter to drown out awkward questions.",
					"Touches his left earlobe compulsively whenever fabricating a detail.",
					"Unnaturally wide, forced smile that does not reach his anxious eyes.",
					"Keeps bouncing his heel on the floor in a frantic, nervous rhythm."
				],
				"stress_baseline": 50,
				"greeting": "Well, well! The High Court's finest! Welcome, Detective! Fresh apples, turnips, rare dried dates—or are you here to buy information from honest Corin?",
				"alibi_statement": "I was fast asleep on my straw pallet right behind my turnip crates, sir! The bazaar gets peaceful after dark. Didn't hear a peep until the morning alarm bells!",
				"motive_statement": "Aldric? He was too grand for my little fruit stand. Only bought imported candied figs once, and complained about the price. No grudge here, sir!",
				"clue_reactions": {
					"stolen_stiletto": "Ooh, that's fine steel! Folded three times, Damascus finish... worth twenty crowns in the capital easily! Not that I deal in weapons, mind you!",
					"debt_ledgers": "Numbers and ledgers... that's Oswin's territory. Though I did hear Aldric owed money to every guild from here to the mainland.",
					"storehouse_iron_key": "That old lock on the storehouse is a rusted double-tumbler. Garrick has the key. Everyone down at the bazaar knows Garrick keeps it on his belt."
				},
				"secret_denial": "Me? A suspect? Detective, I sell turnips! I wouldn't hurt a sleeping field mouse!",
				"secret_confession": "Alright, stop glaring at me like that! You're making me sweat through my vest! Yes, I fence stolen rings and foreign rum! The false bottoms in my cabbage crates! I was down at the harbor at midnight delivering two crates of smuggled silk to Finn! But while I was hiding behind the barrels, I saw Harbour Master Garrick talking to a tall, hooded stranger near the storehouse! Garrick handed him a key—an iron key! I saw it glint in the moonlight! Garrick gave the killer the key to Aldric's door!",
				"general_keywords": {
					"fight|argument|elara|quarrel": "Aye, Aldric and I had a fierce row at dusk! He threatened to evict me and throw my wares in the gutter. Elora saw it from across the plaza. But that doesn't make me a killer!",
					"bazaar|market|stall": "The Central Bazaar is the beating heart of Hollow Creek! Gossip, trade, news—everything passes through here.",
					"garrick": "Garrick is swimming in debts. He talks tough, but the harbor master was desperate.",
					"finn": "Finn's a good lad. Works hard, keeps his mouth shut, knows the coastline like the palm of his hand."
				}
			}

		_:
			return {
				"id": "unknown",
				"name": "Villager",
				"role": "Townsperson",
				"model_scene": "",
				"is_the_killer": false,
				"dark_secret": "None",
				"alibi": "Was at home.",
				"alibi_contradiction": "None",
				"behavioral_anomalies": ["Nervous look."],
				"stress_baseline": 30,
				"greeting": "Hello, Detective.",
				"alibi_statement": "I was home all night.",
				"motive_statement": "I didn't know Lord Aldric.",
				"clue_reactions": {},
				"secret_denial": "I have nothing to hide.",
				"secret_confession": "I don't know anything!",
				"general_keywords": {}
			}
