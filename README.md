# HollowCreek: The Last Crossing 🌊🏰🗡️

An atmospheric 3D medieval murder mystery and detective interrogation game built with **Godot 4.7+** and an **AI-powered Smart NPC Interrogation Backend** (Qwen 3.5 / Gemini 3 Flash with SQLite episodic memory).

---

## 🧭 Story Premise

The High Court Inquisitor arrives in **Hollow Creek**, an isolated coastal hamlet shadowed by jagged cliffs and surrounded by deep, unforgiving waters. 

**Lord Aldric Vale**—the imperial magistrate who held extortionate debts and contested land deeds over the villagers—has been found murdered at the old harbor storehouse. The fatal strike was clean, precise, and delivered by a specialized weapon. 

Every resident in the valley holds a secret, an alibi, and a motive. Your task is to investigate every house, inspect physical ledgers and hidden stashes, summon suspects into the candlelit Interrogation Chamber, crack their alibis, and expose the true mastermind.

---

## 🌟 Key Features

### 1. 🏘️ 10 Designated Village Houses & Interior Puzzles
Every resident has their own designated house in Hollow Creek. Step up to any door and press **`[E]`** to enter their living room and uncover their hidden motives:
* **Tomas Reed (Town Guard):** Medical prescription revealing severe hypersomnia during his guard shift.
* **Dr. Edmund Wren (Physician):** Confidential patient registry and an anonymous blackmail letter detailing his falsified natural death report.
* **Harbour Master Garrick Thorne:** Port embezzlement dossiers, forged cargo tolls, and a one-way escape schooner ticket.
* **Corin Fletcher (Bazaar Merchant):** Disputed stall tax invoices and a Bailiff citation following his heated public brawl with Lord Aldric.
* **Lena Hart (The Lantern Inn):** A hidden drawer containing stolen silver coins and the victim's gold signet ring.
* **Finn Mercer (Dockworker):** Harbour slipway charts showing his presence at the docks hours before his scheduled shift.
* **Lady Isolde Sterling:** Ancient royal charters and eviction ultimatums proving Lord Aldric forcefully seized her family estate.
* **Oswin Grey (Town Steward):** Complete municipal tax audits and secret extortion directives from the victim.
* **Elora Nightshade (Herbalist):** Eyewitness diary of the bazaar fight and huge drying racks of potent purple nightshade herbs.
* **Mayor Eldridge:** Emergency municipal quarantine proclamations and private letters pleading with Aldric.

### 2. 🕯️ Atmospheric 3D Interrogation Chamber
* **Atmospheric Environment:** Dimly-lit stone chamber illuminated by an overhead iron pendant lamp, table candles, and back-door rim lighting.
* **Walk-In & Seating:** Summoned suspects physically walk through the heavy iron door and take the opposing chair.
* **Psychological Stress & Behavioral Anomalies:** Real-time stress meter tracking psychological composure (Calm → Elevated → High Anomaly → Critical Breakdown). Watch for behavioral anomalies (fidgeting, pupil constriction, voice tremors).
* **Physical Clues & Contradictions:** Confront suspects with the *Storehouse Master Key*, *Burnt Contract Scrap*, *Custom Triangular Stiletto*, and *Extortion Ledgers* to expose alibi contradictions and force confessions.

### 3. 🧠 Smart NPC Backend (Qwen 3.5 / Gemini 3 Flash)
* Deceptive NPC personalities that lie, deflect, and protect their secrets to confuse the investigator.
* SQLite episodic conversation memory database (`backend/milo_memory.sqlite3`).
* Automatic graceful fallback to procedural keyword deduction if the LLM backend is offline.

### 4. 🎬 Dual Cinematic Ending Cutscenes
* **Ending 1 (Defeat — False Accusation):** Plays immediately if you accuse an innocent villager. Includes dramatic Ken Burns cinematic motion, orchestral soundtrack, and a bold **GAME OVER** screen (*"AN INNOCENT WAS CONDEMNED · THE KILLER WALKS FREE"*).
* **Ending 2 (Victory — Harbour Master Condemned):** Plays immediately upon accusing the true mastermind, Harbour Master Garrick Thorne. Concludes with a regal bold **GAME OVER** screen in the medieval **Citadel of Blackrose** font (*"JUSTICE HAS PREVAILED · THE HARBOUR MASTER CONDEMNED"*).

---

## 🎮 Controls

| Action | Key / Input |
|---|---|
| **Move** | `W`, `A`, `S`, `D` |
| **Look around** | Mouse movement |
| **Sprint** | `Shift` |
| **Jump** | `Space` |
| **Interact / Open Door / Inspect Clue** | `E` |
| **Close Dialogue / Exit House / Menu** | `Escape` |
| **Recapture Mouse** | `Left Click` in viewport |
| **Ask Custom Question in Interrogation** | Type in prompt box and press `Enter` or `[ Question ]` |
| **Skip Ending Cutscene** | `Escape` or `Space` |

---

## 🚀 Setup & Running

### Requirements
* [Godot Engine 4.3+](https://godotengine.org/)
* [Python 3.10+](https://www.python.org/) (for Smart NPC Backend)
* *(Optional)* [Ollama](https://ollama.ai/) with `qwen3.5:4b` for local offline LLM inference.

### 1. Running the Game
Open the project directory in Godot 4 and press **`F5`** (or click **Play** in the top-right corner).
* **Town & Exploration Scene:** `res://scenes/town.tscn`
* **Interrogation Chamber Scene:** `res://scenes/interrogation_room.tscn`
* **Defeat Ending Cutscene:** `res://scenes/cinematic_cutscene.tscn`
* **Victory Ending Cutscene:** `res://scenes/cinematic_cutscene2.tscn`

### 2. Starting the Smart NPC Backend (Optional)
```bash
# Navigate to backend directory
cd backend

# Copy environment template
cp .env.example .env

# Edit .env with your Gemini API key or Ollama configuration:
# GEMINI_API_KEY=your_key_here
# OLLAMA_MODEL=qwen3.5:4b

# Launch the server
python server.py
```
The server will bind to `http://127.0.0.1:8765`. The Godot interrogation chamber will automatically connect to it for dynamic conversations.

---

## 🧪 Automated Headless Test Suite

Run the full verification suites directly from the console:
```bash
# Test 1: Full World, Terrain & NPC Dialogue Verification
godot --headless -s tests/test_suite.gd

# Test 2: All 10 House Interiors & Physical Clues
godot --headless -s tests/test_house_puzzles.gd

# Test 3: Interrogation Chamber Mechanics & Anomaly Systems
godot --headless -s tests/interrogation_room_test.gd

# Test 4: Dual Ending Cutscenes & Citadel of Blackrose Font
godot --headless -s tests/test_ending_cutscenes.gd
```

---

## 📜 License
MIT License. Created for the Murder Mystery Detective Experience.
