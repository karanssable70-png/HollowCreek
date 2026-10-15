class_name HouseInteriorManager
extends RefCounted

## HouseInteriorManager
## Authoritative registry for designated villager houses, living room interior configs,
## medieval puzzles, interactable drawers, and scattered evidence documents for HOLLOWCREEK.

static var current_house_id: String = "tomas"
static var return_player_position: Vector3 = Vector3(0, 1.2, 0)
static var return_player_rotation_y: float = 0.0
static var has_return_position: bool = false
static var is_inside_house: bool = false

static func get_house_data(house_id: String) -> Dictionary:
	match house_id.to_lower():
		"tomas":
			return {
				"id": "tomas",
				"owner_name": "Tomas Reed",
				"role": "Northern Gate Guard",
				"house_title": "Tomas Reed's Cottage",
				"village_pos": Vector3(8.0, 1.2, -26.0),
				"village_rot_y": 180.0,
				"puzzle_type": "drawer",
				"object_name": "Bedside Nightstand Drawer",
				"document_title": "CONFIDENTIAL MEDICAL REPORT — TOMAS REED",
				"document_subtitle": "Parish Infirmary Assessment & Fit-for-Duty Evaluation",
				"document_body": "PATIENT: Tomas Reed (Age 28, Sentry)\nPOST: Northern Mountain Gate Night Watch\n\nDIAGNOSIS: Severe Chronic Hypersomnia with Sudden Cataplectic Onset.\n\nCLINICAL OBSERVATION:\nPatient experiences irresistible bouts of deep, comatose sleep occurring without warning, lasting between four to seven continuous hours. Physical stimulation and alarm bells fail to rouse him during these episodes.\n\nINCIDENT LOG:\nFound unconscious across the northern gatehouse bench during the 3rd bell of the murder night. No signs of struggle or poison—purely neurological collapse.\n\nVERDICT:\nPatient is utterly unfit for solitary watch. Completely incapacitated through sleep during the time Lord Aldric was killed.",
				"secret_summary": "Medical report proves Tomas suffers from severe Hypersomnia. He did not let the killer through on purpose—he suffered an uncontrollable narcoleptic blackout during the murder watch.",
				"clue_id": "tomas_hypersomnia_report",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Sentry Duty Roster & Personal Diary",
						"title": "NORTHERN PASS SENTRY ROSTER & DIARY",
						"subtitle": "Gatehouse Logbook — Personal Entries by Tomas",
						"body": "SENTRY LOG — NIGHT WATCH:\n'Dusk bell passed. The mountain winds are freezing my fingers. My skull aches with that cursed numbness again... I can feel my eyes closing against my will. God help me if the Sergeant catches me asleep on post again. I keep a flask of cold well-water, but when the trance strikes, my limbs turn to lead. I prayed no one would cross the pass tonight.'",
						"summary": "Tomas's personal diary reveals his deep anxiety over falling into uncontrollable sleep seizures while on gate duty.",
						"pos": Vector3(0.4, 0.90, 0.1),
						"rot_y": 15.0,
						"clue_id": "tomas_duty_diary"
					},
					{
						"prompt": "[E] Inspect Herbal Tonic Prescription",
						"title": "HERBAL SLEEP TONIC PRESCRIPTION",
						"subtitle": "Apothecary Dispensary Slip for Tomas Reed",
						"body": "DISPENSARY NOTE — BROTHER TOMAS:\n'Prescribed by Dr. Edmund Wren, compounded by Elora Nightshade:\n- Concentrated dried skullcap, valerian root, and mountain mint infusion.\n- Take two spoonfuls at dusk to suppress nocturnal fits and involuntary cataplexy.'\n\nMARGINAL NOTE BY TOMAS:\n'The draughts do nothing. If anything, the blackouts grow deeper each night.'",
						"summary": "Prescription proves Tomas was desperately seeking medical treatment for his severe sleep seizures.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": -10.0,
						"clue_id": "tomas_prescription"
					}
				]
			}
			
		"physician", "edmund":
			return {
				"id": "physician",
				"owner_name": "Dr. Edmund Wren",
				"role": "Town Physician",
				"house_title": "Physician's Clinic & Living Quarters",
				"village_pos": Vector3(14.0, 0.9, -18.0),
				"village_rot_y": -35.0,
				"puzzle_type": "drawer",
				"object_name": "Physician's Apothecary Desk Drawer",
				"document_title": "DRAFT POST-MORTEM AUTOPSY — LORD ALDRIC VALE",
				"document_subtitle": "Confidential Preliminary Draft (Heavily Redacted)",
				"document_body": "SUBJECT: Lord Aldric Vale (Deceased)\nEXAMINER: Dr. Edmund Wren, Parish Physician\n\n[OFFICIAL DRAFT TO MAGISTRATES]:\n'Cause of death: Acute sudden heart failure resulting from natural apoplexy in his private quarters. No trauma or violence observed.'\n\n[STRIKETHROUGH & MARGINAL SCRIBBLINGS IN EDMUND'S HAND]:\n~CROSS THIS OUT!~ Do not mention the puncture between the 4th and 5th ribs. Do not mention the violet staining in the gastric lining.\n\n'If the High Magistrate smells murder, Garrick will disclose my theft of parish tithes and anatomical grave-robbing. Sign this as natural heart failure. Aldric was already dying of his own wickedness anyway.'\n\n[SEAL]: Unsigned draft, smeared with hurried ink droplets.",
				"secret_summary": "Physician Edmund was caught falsifying Lord Aldric's autopsy report to rule the murder a 'natural heart failure', coerced by blackmail over his parish grave-robbing.",
				"clue_id": "physician_falsified_autopsy",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Clinic Patient Ledger & Symptoms",
						"title": "PARISH CLINIC PATIENT REGISTRY",
						"subtitle": "Confidential Consultation Notes",
						"body": "CONSULTATION LOG — LORD ALDRIC VALE:\n'Patient presented twice in the past seven days complaining of acute abdominal spasms, dilated pupils, and erratic pulse. Observed violet discoloration on his tongue.\n\nDiagnosis: Progressive ingestion of belladonna / purple nightshade distillate. Someone has been dosing his evening wine for days before the blade struck him.'",
						"summary": "Medical records show Lord Aldric was already suffering from purple nightshade poisoning before he was assassinated.",
						"pos": Vector3(0.3, 0.90, 0.1),
						"rot_y": -20.0,
						"clue_id": "edmund_patient_notes"
					},
					{
						"prompt": "[E] Inspect Blackmail Threat Letter",
						"title": "ANONYMOUS BLACKMAIL LETTER TO DR. EDMUND",
						"subtitle": "Recovered from Clinic Bookshelf",
						"body": "TO DR. EDMUND WREN:\n'Doctor: The three corpses exhumed from the south churchyard did not bury themselves. Sign the certificate for Aldric as natural heart failure, or the town guard will inspect your dissecting cellar with pitchforks and torches.'\n\n[SEAL]: Stamped with an anchor signet in red wax.",
						"summary": "Blackmail letter proving Harbour Master Garrick coerced Dr. Edmund into falsifying the autopsy report.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": 5.0,
						"clue_id": "edmund_blackmail_letter"
					}
				]
			}
			
		"garrick":
			return {
				"id": "garrick",
				"owner_name": "Garrick Thorne",
				"role": "Harbour Master",
				"house_title": "Harbour Master's House & Port Office",
				"village_pos": Vector3(-18.0, 0.6, 26.0),
				"village_rot_y": -65.0,
				"puzzle_type": "audit_records",
				"object_name": "Port Customs Audit Chest & Maritime Desk",
				"document_title": "PORT CUSTOMS AUDIT & EMBEZZLEMENT DOSSIER",
				"document_subtitle": "Compiled by Lord Aldric Vale — Discrepancy Registry",
				"document_body": "AUDIT REPORT — HOLLOW CREEK WHARF & TOLL CRANE\nAUDITOR: Lord Aldric Vale\nSUBJECT: Harbour Master Garrick Thorne\n\nDISCREPANCIES UNCOVERED:\n- 4,200 Silver Crowns collected from foreign brandy and grain skiffs omitted from municipal registries over six months.\n- Forged cargo bills stamped with Garrick's official anchor seal.\n- Bribes accepted to bypass maritime inspection.\n\nALDRIC'S CONCLUDING WARNING:\n'Thorne: I hold your forged cargo receipts. The imperial magistrate on the incoming Friday schooner will receive this full dossier. Your commission is revoked and your neck is promised to the gallows tree. Settle your affairs.'",
				"secret_summary": "Records prove Garrick was caught embezzling 4,200 silver crowns by Lord Aldric, who was sending him to the gallows on the Friday ship—giving Garrick the primary motive to execute the hit.",
				"clue_id": "garrick_embezzlement_records",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Wharf Cargo & Toll Ledger",
						"title": "HOLLOW CREEK WHARF TOLL & CARGO LEDGER",
						"subtitle": "Port Receipts & Diverted Levies",
						"body": "WHARF INVOICES:\n- 14 Barrels of Spiced Rum (Unregistered)\n- 8 Crates of Foreign Silk (Levy Bypassed)\n\nMarginal note in Garrick's hand: 'Aldric is reviewing the warehouse ledgers tomorrow morning. If he balances the crane tallies against the capital bank drafts, I am ruined.'",
						"summary": "Ledger proves Garrick knew Lord Aldric was about to expose his massive financial embezzlement.",
						"pos": Vector3(0.4, 0.90, 0.1),
						"rot_y": 10.0,
						"clue_id": "garrick_wharf_ledger"
					},
					{
						"prompt": "[E] Inspect Schooner Passage Ticket",
						"title": "ONE-WAY ESCAPE PASSAGE TICKET",
						"subtitle": "Merchant Schooner 'The Albatross' — Midnight Clearance",
						"body": "PASSAGE VOUCHER:\n'One single first-class cabin reserved for passenger traveling under alias \"G. Vance\". Departure immediately upon midnight tide on Friday.'\n\n[ATTACHED NOTE]:\n'Once the deed is finished and the island lockdown is declared, board at lower slipway #3.'",
						"summary": "Passage ticket proving Garrick planned an immediate escape from Hollow Creek aboard the Friday ship after the murder.",
						"pos": Vector3(3.0, 0.72, 1.5),
						"rot_y": -45.0,
						"clue_id": "garrick_escape_ticket"
					}
				]
			}
			
		"corin":
			return {
				"id": "corin",
				"owner_name": "Corin Fletcher",
				"role": "Bazaar Merchant",
				"house_title": "Corin's Merchant House",
				"village_pos": Vector3(-10.0, 0.9, -16.0),
				"village_rot_y": 45.0,
				"puzzle_type": "merchant_ledger",
				"object_name": "Merchant Account Counter & Broken Scales",
				"document_title": "NOTICE OF EVICTION & DISPUTED DEBT DEMAND",
				"document_subtitle": "Bazaar Stall #4 — Vale Imperial Estate Notice",
				"document_body": "TO: Corin Fletcher, Street Merchant\nFROM: Lord Aldric Vale\n\n'By order of the landholder, your market license is immediately terminated due to delinquent tariff arrears of 180 guilders. All spice jars, silks, and market tables will be impounded at dawn.'\n\n[CORIN'S SCRIBBLINGS ON BACK OF NOTICE]:\n'Aldric screamed at me by the fountain at dusk. He mocked my dying father and kicked my wares into the gutter. I screamed back that he was a tyrant who would reap what he sowed.\n\nElora was standing across the square watching everything from her herb stall. She heard every word. God forgive me for wishing him dead, but I did not put steel to his throat.'",
				"secret_summary": "Corin had a violent public shouting match with Lord Aldric at dusk over eviction and extortionate stall taxes. Elora witnessed the altercation from her stall.",
				"clue_id": "corin_bazaar_altercation",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Bazaar Stall Account Invoices",
						"title": "CITY BAZAAR STALL TAX RECEIPTS",
						"subtitle": "Receipts & Extortionate Tariff Demands",
						"body": "MARKET LICENSING RECEIPTS:\n'Weekly fee increased from 4 silver shillings to 16 silver shillings by executive order of Lord Aldric Vale.'\n\nCorin's note: 'He wants to bankrupt every local vendor so his capital trade syndicate can seize the square.'",
						"summary": "Receipts showing Lord Aldric was driving Corin into bankruptcy through 300% market stall rent increases.",
						"pos": Vector3(0.3, 0.90, -0.1),
						"rot_y": -15.0,
						"clue_id": "corin_stall_receipts"
					},
					{
						"prompt": "[E] Inspect Town Bailiff Summons Notice",
						"title": "TOWN BAILIFF CITATION — PUBLIC DISORDER",
						"subtitle": "Municipal Court of Hollow Creek",
						"body": "CITATION FOR BRAWL & BREACH OF PEACE:\n'Corin Fletcher is cited for violent verbal altercation and threats of bodily harm against Lord Aldric Vale in the central plaza before sunset. Eyewitness testimony provided by Elora Nightshade.'",
						"summary": "Official court summons documenting Corin's public brawl and threats against the victim at dusk.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": 25.0,
						"clue_id": "corin_bailiff_summons"
					}
				]
			}
			
		"lena":
			return {
				"id": "lena",
				"owner_name": "Lena Vance",
				"role": "Innkeeper of The Lantern",
				"house_title": "Lena Vance's Residence (The Lantern Inn)",
				"village_pos": Vector3(-24.0, 0.7, -2.0),
				"village_rot_y": 90.0,
				"puzzle_type": "hidden_stash",
				"object_name": "Loose Floorboard Under Woven Hearth Rug",
				"document_title": "STOLEN VALUABLES CACHE — VICTIM'S BELONGINGS",
				"document_subtitle": "Hidden Cache Recovered from Lena's Floorboard",
				"document_body": "INVENTORY OF STOLEN ITEMS FOUND IN CACHE:\n\n1. Heavy Velvet Coin Pouch embossed with the gold raven crest of Lord Aldric Vale, containing 45 gold sovereigns.\n2. Carved Gold Signet Ring with Aldric's engraved monogram.\n3. Four silver dining spoons stamped from highborn traveler luggage.\n4. A traveler's pocket timepiece belonging to an imperial surveyor.\n\n[LENA'S HIDDEN DIARY SCRAP]:\n'Aldric stopped at the taproom for mulled wine before walking out to the ridge. He was drunk and haughty. Slipped his heavy pouch and ring into my apron while pouring his flagon. He never even noticed. A thief I may be, but a murderer I am not.'",
				"secret_summary": "Lord Aldric's stolen coin pouch and signet ring are hidden beneath Lena's floorboards. She pickpockets wealthy guests, explaining why she had his belongings without being the killer.",
				"clue_id": "lena_stolen_belongings",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect The Lantern Inn Guest Register",
						"title": "THE LANTERN INN DINING & ROOM REGISTER",
						"subtitle": "Evening Log for the Night of the Murder",
						"body": "INN REGISTER LOG:\n'Sunset: Lord Aldric Vale arrived unaccompanied. Ordered roast capon and double mulled wine. Paid from a fat velvet coin purse. Left at the fourth bell muttering that he had business at the eastern overlook.'",
						"summary": "Register confirms Lord Aldric dined at the inn with a heavy purse of gold just before he was killed.",
						"pos": Vector3(-0.4, 0.90, 0.1),
						"rot_y": 12.0,
						"clue_id": "lena_guest_register"
					},
					{
						"prompt": "[E] Inspect Traveler Theft Complaints",
						"title": "TRAVELER COMPLAINTS REGARDING MISSING COINS",
						"subtitle": "Unanswered Petitions Filed with Inn Management",
						"body": "PETITION TO MUNICIPAL COUNCIL:\n'Three merchant travelers petition regarding repeated nighttime thefts from locked rooms at The Lantern Inn. Purses cut, signet rings taken from nightstands. Lena Vance denies all allegations.'",
						"summary": "Multiple traveler complaints proving Lena operates a systematic pickpocketing ring inside the inn.",
						"pos": Vector3(2.4, 0.85, -0.6),
						"rot_y": -30.0,
						"clue_id": "lena_theft_complaints"
					}
				]
			}
			
		"finn":
			return {
				"id": "finn",
				"owner_name": "Finn Cole",
				"role": "Dockworker & Boatman",
				"house_title": "Finn Cole's Fisherman Cottage",
				"village_pos": Vector3(-14.0, 0.7, 18.0),
				"village_rot_y": -35.0,
				"puzzle_type": "duty_roster",
				"object_name": "Dock Shift Roster & Oil Lantern Bench",
				"document_title": "HARBOUR WATCH ROSTER & EARLY CLOCK-IN LOG",
				"document_subtitle": "Port Duty Slip — Lower Pier Maintenance",
				"document_body": "WORKER: Finn Cole\nASSIGNED SHIFT: Dawn Mooring Watch (06:00 AM – 14:00 PM)\nACTUAL TIME OF ARRIVAL: 03:30 AM (Pitch Darkness)\n\n[FINN'S WRITTEN CONFESSION TO HIMSELF]:\n'The sea gale was howling like a banshee. I was terrified my skiff would smash against the pilings, so I came down hours before my shift with a dark lantern to lash the lines tight.\n\nThat's when my boot kicked against something heavy by the salt shed. It was Lord Aldric, cold as mutton, blood pooling on the wet stones. I was so petrified they would hang me for being there that I ran home and pretended to wake up with the bell.'",
				"secret_summary": "Finn came to the docks hours early at 3:30 AM to secure his boat in the gale. He accidentally stumbled upon Aldric's body in the dark, explaining his suspicious early presence.",
				"clue_id": "finn_early_clock_in",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Coastal Mooring & Tide Chart",
						"title": "COASTAL TIDE CHARTS & SLIPWAY LOG",
						"subtitle": "Harbour Weather Advisory for Murder Night",
						"body": "HARBOURMASTER WEATHER ADVISORY:\n'Severe northern squall expected past midnight. All skiffs and rowboats must be lashed to double iron cleats. Heavy swells anticipated along the eastern storehouse foundation.'",
						"summary": "Weather log confirms severe storm conditions, corroborating Finn's reason for rushing to the docks early.",
						"pos": Vector3(0.4, 0.90, -0.1),
						"rot_y": -25.0,
						"clue_id": "finn_tide_chart"
					},
					{
						"prompt": "[E] Inspect Harbour Master Warning Note",
						"title": "GARRICK'S HARBOUR DISPATCH TO WHARF CREW",
						"subtitle": "Commandment Issued to Dockworkers",
						"body": "FROM HARBOUR MASTER GARRICK:\n'No worker is to wander near the eastern storehouse or speak to council magistrates without my express permission. Any loose lips regarding nighttime activities will find their fishing licenses permanently revoked.'",
						"summary": "Warning note proving Garrick threatened dockworkers to keep them from speaking to investigators.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": 15.0,
						"clue_id": "finn_garrick_warning"
					}
				]
			}
			
		"isolde":
			return {
				"id": "isolde",
				"owner_name": "Lady Isolde Sterling",
				"role": "Highborn Council Member",
				"house_title": "Lady Isolde's Sterling Estate",
				"village_pos": Vector3(-22.0, 1.0, -24.0),
				"village_rot_y": 70.0,
				"puzzle_type": "legal_decree",
				"object_name": "Gilded Mahogany Bureau & Secretaire",
				"document_title": "IMPERIAL DECREE OF PROPERTY FORECLOSURE & SEIZURE",
				"document_subtitle": "High Court of the Realm — Execution of Land Transfer",
				"document_body": "IN THE MATTER OF: Lord Aldric Vale vs. Lady Isolde Sterling\n\nJUDICIAL ORDER:\n'Whereas the boundary deeds and charter grants presented by the defendant Lady Isolde are determined to be fraudulent alterations of imperial border stones;\n\nIT IS HEREBY ORDERED that the entire Sterling Manor, the northern vineyard terraces, and all tenant revenues are forfeit and legally transferred into the permanent ownership of Lord Aldric Vale.'\n\n[EXECUTION NOTICE ATTACHED]:\n'Bailiffs shall execute the eviction of Lady Isolde upon the arrival of the Friday packet ship. All personal chattels to be impounded.'",
				"secret_summary": "Official legal decree proves Lord Aldric legally seized all of Lady Isolde's ancestral land, vineyards, and house, leaving her ruined and giving her a powerful motive of vengeance.",
				"clue_id": "isolde_land_transfer_decree",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Sterling Ancient Royal Charter",
						"title": "ROYAL CHARTER OF HOUSE STERLING",
						"subtitle": "Three-Generation Patent of Nobility",
						"body": "IMPERIAL PATENT — KING EDWARD IV:\n'Granted to Baron Geoffrey Sterling and his legitimate heirs: perpetual dominion over the Hollow Creek bluffs, vineyards, and tenant revenues.'\n\nMarginal note in Isolde's hand: 'Aldric forged false surveyor records to invalidate this holy parchment. He came here to steal our legacy.'",
						"summary": "Royal charter showing Lady Isolde's deep ancestral attachment to the lands Lord Aldric was confiscating.",
						"pos": Vector3(0.3, 0.90, 0.1),
						"rot_y": 18.0,
						"clue_id": "isolde_royal_charter"
					},
					{
						"prompt": "[E] Inspect Lord Aldric's Ultimatum Letter",
						"title": "LORD ALDRIC'S EVICTION ULTIMATUM",
						"subtitle": "Private Correspondence Delivered to Isolde",
						"body": "TO LADY ISOLDE STERLING:\n'Your nobility is an expired currency, Madame. Pack your gowns before Friday's tide. My bailiffs have strict orders to throw your belongings into the courtyard if you refuse to surrender the keys.'",
						"summary": "Cruel ultimatum from Lord Aldric establishing Isolde's intense personal hatred and motive for revenge.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": -12.0,
						"clue_id": "isolde_ultimatum"
					}
				]
			}
			
		"oswin":
			return {
				"id": "oswin",
				"owner_name": "Oswin Grey",
				"role": "Town Scribe & Steward",
				"house_title": "Oswin Grey's Scribe House",
				"village_pos": Vector3(-10.0, 0.8, 2.0),
				"village_rot_y": 15.0,
				"puzzle_type": "master_ledger",
				"object_name": "Archive Registry Desk & Scroll Shelves",
				"document_title": "MASTER FINANCIAL & SECRET REGISTRY OF HOLLOW CREEK",
				"document_subtitle": "Compiled by Town Steward Oswin Grey",
				"document_body": "CONFIDENTIAL AUDIT LEDGER OF ALL VILLAGE CITIZENS:\n\n- GARRICK THORNE: 4,200 crowns unaccounted for in port dues. Deeply indebted to syndicate loan sharks.\n- LADY ISOLDE: Land title contestation finalized; bankruptcy and total eviction imminent.\n- CORIN FLETCHER: Stall eviction warrant pending; debt of 180 guilders.\n- DR. EDMUND WREN: Clinic tithes falsified; questionable nocturnal exhumations noted in parish graveyard.\n- MAYOR ELDRIDGE: Municipal treasury kickbacks accepted to suppress council petitions.\n\n[OSWIN'S PERSONAL NOTE]:\n'Lord Aldric forced me to compile these secrets to blackmail everyone in Hollow Creek. I have no quarrel with any man, but this book holds the life and death of the entire valley.'",
				"secret_summary": "Oswin holds the master financial ledger containing debts, secrets, and extortion points of every single citizen in Hollow Creek under Lord Aldric's web.",
				"clue_id": "oswin_master_ledger",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Hollow Creek Tax Assessment Book",
						"title": "HOLLOW CREEK CITIZEN TAX AUDIT",
						"subtitle": "Municipal Debt Assessment Rolls",
						"body": "TOWN STEWARD REVENUE AUDIT:\n- Total debts owed to Lord Aldric Vale: 14,800 silver crowns.\n- Mortgages held by Vale Syndicate: 7 family cottages, 2 workshops, the fishing slipway.\n\nNote: 'Lord Aldric held financial control over virtually every home in the valley.'",
						"summary": "Tax rolls showing Lord Aldric had leveraged enormous debts over nearly every resident in Hollow Creek.",
						"pos": Vector3(0.4, 0.90, -0.1),
						"rot_y": -10.0,
						"clue_id": "oswin_tax_rolls"
					},
					{
						"prompt": "[E] Inspect Lord Aldric's Extortion Directive",
						"title": "LORD ALDRIC'S DIRECTIVE TO TOWN STEWARD",
						"subtitle": "Private Executive Order",
						"body": "TO STEWARD OSWIN GREY:\n'Compile the private liabilities and misdemeanors of every council member. If Thorne or Isolde raise objections to my port monopoly, give me the papers to break them. Fail me, and your own embezzlement of council ink funds will be disclosed.'",
						"summary": "Letter showing Lord Aldric coerced Oswin into compiling blackmail dossiers on all villagers.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": 20.0,
						"clue_id": "oswin_aldric_directive"
					}
				]
			}
			
		"elara":
			return {
				"id": "elara",
				"owner_name": "Elora Nightshade",
				"role": "Herbalist & Apothecary",
				"house_title": "Elora's Herbalist Cottage",
				"village_pos": Vector3(4.0, 0.7, 24.0),
				"village_rot_y": 180.0,
				"puzzle_type": "purple_herbs",
				"object_name": "Drying Alcove & Toxic Compounding Table",
				"document_title": "APOTHECARY DISPENSARY LOG & PURPLE HERB STASH",
				"document_subtitle": "Atropa Purpurea (Purple Nightshade) Registry",
				"document_body": "POISON LOG & MASSIVE HERB STASH FOUND:\nLarge bundles of dried purple blossoms and concentrated tincture vials of Purple Nightshade (*Atropa Purpurea*) line the workshop shelves.\n\n[HERBAL DISPENSARY LEDGER ENTRY]:\n'Three vials of concentrated Purple Nightshade distillate delivered to Harbour Master Garrick Thorne on Tuesday. Garrick claimed it was for poisoning black dock rats in the wharf cellars.\n\nI cautioned him: one single drop induces muscle paralysis and cardiac collapse within minutes.'\n\n[EYEWITNESS NOTE ON SOUGHT PERSONS]:\n'Also observed Corin Fletcher in a violent screaming altercation with Lord Aldric in the square at dusk. Corin looked ready to murder him on the spot.'",
				"secret_summary": "Elora holds large stashes of the potent purple paralytic nightshade found in Lord Aldric's body. Her ledger proves Garrick purchased 3 concentrated vials under false pretenses, and she witnessed Corin's fight with Aldric.",
				"clue_id": "elara_purple_herbs_stash",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Botanical Compendium & Salve Notes",
						"title": "COASTAL BOTANICAL COMPENDIUM",
						"subtitle": "Medicinal & Toxic Flora of Hollow Creek",
						"body": "BOTANICAL RECIPES:\n- Yarrow & St. John's Wort: For bleeding cuts and bruised bone.\n- Purple Nightshade (Atropa Purpurea): Toxic paralytic. Ingested orally, produces rapid cardiac slowing, violet tongue discoloration, and death within two hours.",
						"summary": "Herbal treatise detailing the fatal paralytic effects of the purple nightshade herbs found in her cottage.",
						"pos": Vector3(0.3, 0.90, 0.1),
						"rot_y": -22.0,
						"clue_id": "elara_botanical_notes"
					},
					{
						"prompt": "[E] Inspect Eyewitness Journal (Bazaar Fight)",
						"title": "ELORA'S EYEWITNESS JOURNAL (DUSK ALTERCATION)",
						"subtitle": "Personal Observation on Murder Night",
						"body": "EYEWITNESS NOTE — DUSK BY FOUNTAIN:\n'While packing my lavender baskets, I heard loud shouts. Corin Fletcher was in a violent screaming rage with Lord Aldric. Aldric told Corin he would sleep in the gutter by morning. Corin shouted back: \"You won't live to see dawn, you miserable leach!\" Everyone in the square stopped to stare.'",
						"summary": "Elora's written eyewitness testimony detailing the violent fight between Corin and Aldric at dusk.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": 10.0,
						"clue_id": "elara_eyewitness_journal"
					}
				]
			}
			
		"mayor":
			return {
				"id": "mayor",
				"owner_name": "Mayor Eldridge",
				"role": "Chief Magistrate",
				"house_title": "Mayor Eldridge's Secret House",
				"village_pos": Vector3(-30.0, 0.6, 20.0),
				"village_rot_y": 45.0,
				"puzzle_type": "bribe_box",
				"object_name": "Magistrate's Iron Strongbox & Writing Desk",
				"document_title": "CONFIDENTIAL BRIBE & EXTORTION CORRESPONDENCE",
				"document_subtitle": "Agreements Between Mayor Eldridge & Lord Aldric Vale",
				"document_body": "MAGISTRATE MUNICIPAL AGREEMENT:\n\n'In consideration of 500 gold crowns received annually from Lord Aldric Vale's private estate, the Office of the Chief Magistrate agrees:\n\n1. To dismiss all tenant complaints regarding disputed rent increases.\n2. To uphold all foreclosure and land seizure petitions filed by the Vale estate against local landholders.\n3. To enforce total harbor quarantine and lockdown upon any civil disturbance.'\n\n[MAYOR'S PRIVATE DRAFT]:\n'Aldric went too far. If the High Court investigator from the capital inspects these books, we will both swing from the same gibbet.'",
				"secret_summary": "Mayor Eldridge's secret house contains proof of bribery and conspiracy with Lord Aldric to dismiss villager petitions and enforce arbitrary lockdowns.",
				"clue_id": "mayor_bribe_correspondence",
				"scattered_papers": [
					{
						"prompt": "[E] Inspect Town Council Lockdown Proclamation",
						"title": "PROCLAMATION OF MUNICIPAL QUARANTINE",
						"subtitle": "Executive Order by Mayor Eldridge",
						"body": "EXECUTIVE ORDER:\n'Pursuant to the murder of Lord Aldric Vale, all mountain paths and coastal waters are declared under total martial quarantine. No soul may depart until court is convened upon arrival of the Friday magistrate packet.'",
						"summary": "Proclamation establishing Mayor Eldridge's total authority and the 3-day island lockdown.",
						"pos": Vector3(0.4, 0.90, -0.1),
						"rot_y": 14.0,
						"clue_id": "mayor_quarantine_decree"
					},
					{
						"prompt": "[E] Inspect Private Warning Draft to Aldric",
						"title": "MAYOR'S PRIVATE DRAFT LETTER TO ALDRIC",
						"subtitle": "Unsent Correspondence",
						"body": "TO ALDRIC VALE:\n'You are pushing Garrick and Isolde beyond endurance. If you seize Isolde's ancestral manor and hang Garrick on Friday, the village will riot. You promised me orderly profits, not a bloodbath. Call off your capital bailiffs before someone silences you.'",
						"summary": "Letter showing the Mayor warned Lord Aldric that his extortion was pushing the suspects toward murder.",
						"pos": Vector3(-2.0, 1.45, -2.7),
						"rot_y": -18.0,
						"clue_id": "mayor_warning_letter"
					}
				]
			}
			
		_:
			return {}
