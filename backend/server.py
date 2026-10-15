"""
Hollow Creek: The Last Crossing — Smart NPC Interrogation Backend
Integrates Gemini (primary) with local Ollama Qwen 3.5 (local offline) and SQLite memory.
All 10 interrogation suspects possess unique personalities, suspicious traits,
dark secrets, and deceptive lying strategies to confound the detective.
"""
from __future__ import annotations

import json
import os
import random
import re
import shutil
import sqlite3
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import ProxyHandler, Request, build_opener, urlopen

ROOT = Path(__file__).resolve().parent
MEMORY_DB = ROOT / "milo_memory.sqlite3"

def load_env_file() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key, value = key.strip(), value.strip().strip('"').strip("'")
        if key:
            os.environ[key] = value

load_env_file()

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434").rstrip("/")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen3.5:4b")
OLLAMA_TIMEOUT = float(os.environ.get("OLLAMA_TIMEOUT_SECONDS", "8.0"))
OLLAMA_READY = False
_OLLAMA_START_LOCK = threading.Lock()
OLLAMA_HTTP = build_opener(ProxyHandler({}))

def get_suspect_from_db(suspect_id: str) -> dict:
    """Fetch suspect profile, personality, secret, and lie instructions from SQLite."""
    default_id = suspect_id.lower().strip() or "garrick"
    with sqlite3.connect(MEMORY_DB) as db:
        db.row_factory = sqlite3.Row
        cur = db.cursor()
        row = cur.execute("SELECT * FROM suspects WHERE id = ?", (default_id,)).fetchone()
        if not row:
            # Fallback by partial matching
            row = cur.execute("SELECT * FROM suspects WHERE name LIKE ? OR id LIKE ?", (f"%{default_id}%", f"%{default_id}%")).fetchone()
        if not row:
            row = cur.execute("SELECT * FROM suspects WHERE id = 'garrick'").fetchone()
    if row:
        return dict(row)
    return {
        "id": "garrick",
        "name": "Garrick Thorne",
        "role": "Harbour Master",
        "personality": "Authoritative, controlling, defensive, and secretive",
        "suspicious_trait": "Protects his reputation and becomes guarded about harbour finances after Aldric discovers his embezzlement.",
        "dark_secret": "Masterminded Lord Aldric's murder and hired the syndicate assassin to erase immense debts.",
        "alibi": "Claims he was tallying salt pork and grain manifests at the lower wharf office until fourth bell.",
        "alibi_contradiction": "The dock office was locked by Oswin at second bell. Garrick's key was used to enter the murder storehouse.",
        "lie_instructions": "Lie aggressively to protect your harbor authority. Deny having the key.",
        "is_the_killer": 1
    }

def get_all_suspects_from_db() -> list[dict]:
    with sqlite3.connect(MEMORY_DB) as db:
        db.row_factory = sqlite3.Row
        rows = db.execute("SELECT id, name, role, personality, suspicious_trait, is_the_killer FROM suspects").fetchall()
    return [dict(r) for r in rows]

def ensure_ollama_running() -> None:
    """Ensure Ollama local server is active, checking standard and AppData paths."""
    global OLLAMA_READY
    tags_url = f"{OLLAMA_URL}/api/tags"
    try:
        with OLLAMA_HTTP.open(tags_url, timeout=1.0) as response:
            json.loads(response.read().decode("utf-8"))
            return
    except (URLError, TimeoutError, json.JSONDecodeError):
        pass

    with _OLLAMA_START_LOCK:
        try:
            with OLLAMA_HTTP.open(tags_url, timeout=1.0) as response:
                json.loads(response.read().decode("utf-8"))
                return
        except (URLError, TimeoutError, json.JSONDecodeError):
            pass

        executable = shutil.which("ollama")
        if not executable:
            known_path = Path.home() / "AppData/Local/Programs/Ollama/ollama.exe"
            if known_path.is_file():
                executable = str(known_path)
        if not executable:
            raise RuntimeError("Ollama is not installed or not on PATH")

        options = {"stdin": subprocess.DEVNULL, "stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}
        if os.name == "nt":
            options["creationflags"] = subprocess.CREATE_NO_WINDOW
        subprocess.Popen([executable, "serve"], **options)
        
        deadline = time.monotonic() + 10.0
        while time.monotonic() < deadline:
            try:
                with OLLAMA_HTTP.open(tags_url, timeout=1.0) as response:
                    json.loads(response.read().decode("utf-8"))
                    return
            except (URLError, TimeoutError, json.JSONDecodeError):
                time.sleep(0.3)
    raise RuntimeError("Ollama local service did not start")

def build_suspect_system_prompt(suspect: dict) -> str:
    return f"""You are {suspect['name']}, the {suspect['role']} of Hollow Creek.
PERSONALITY: {suspect['personality']}
SUSPICIOUS TRAIT: {suspect['suspicious_trait']}
YOUR DARK SECRET: {suspect['dark_secret']}
YOUR CLAIMED ALIBI: {suspect['alibi']}

CONTEXT: You are being interrogated inside the village interrogation room by the traveling Detective investigating Lord Aldric Vale's brutal murder.
CRITICAL DECEPTION OBJECTIVES:
1. YOU MUST LIE, DEFLECT, OR EVADE TO PRESERVE YOUR SECRET!
2. Do NOT confess your crimes or secrets to the detective. Protect yourself and your reputation.
3. Stay strictly in character reflecting your personality ({suspect['personality']}).
4. Try to confuse the detective: shift blame, cast suspicion on other villagers (e.g. Isolde's disputed land, Corin's smuggled crates, Garrick's debts, Elara's poisons), or dismiss questions with excuses.
5. {suspect['lie_instructions']}
6. Keep your reply concise: exactly 1 to 3 atmospheric medieval sentences.

Return ONLY a valid JSON object with these exact fields:
{{"reply": "your in-character spoken response", "stress_delta": integer from -5 to +20, "anomaly": "short description of nervous tell or null"}}"""

def smart_fallback_reply(suspect: dict, last_question: str) -> dict:
    """Intelligent offline fallback engine grounded in character personality and evasion rules."""
    q = last_question.lower()
    s_name = suspect["name"]
    s_id = suspect["id"]
    
    # Specific deflection patterns per suspect
    if s_id == "garrick":
        if any(w in q for w in ["key", "storehouse", "lock"]):
            reply = "The storehouse key? I keep dozens of keys for cargo sheds. Mine was misplaced near the lower wharf yesterday, Detective. You're wasting time chasing iron when Lady Isolde had far more reason to see Aldric dead."
            stress = 15
            anomaly = "Fingers twitch near right coat pocket where the storehouse key was kept."
        elif any(w in q for w in ["money", "debt", "tariff", "embezzle", "ledger"]):
            reply = "My books are audited under maritime charter! Aldric was an imperial parasite trying to squeeze honest seamen dry. That doesn't make me an assassin."
            stress = 18
            anomaly = "Pupils sharply constrict; voice drops to an aggressive, rehearsed monotone."
        else:
            reply = "I'm the Harbour Master of this port. I was tallying pork barrels until fourth bell. If you want empty tavern tales, ask the gossipers up at the square."
            stress = 5
            anomaly = "Checks heavy brass pocket watch with trembling fingers."
            
    elif s_id == "isolde":
        if any(w in q for w in ["land", "deed", "charter", "money", "estate"]):
            reply = "The Ravenshade estate was granted by royal decree three generations ago. Aldric was a vulgar upstart waving forged boundary stones. A highborn woman settles debts in court, not in puddles of blood."
            stress = 15
            anomaly = "Fidgets compulsively with heavy emerald signet ring; takes a sharp, shallow breath."
        elif any(w in q for w in ["terrace", "night", "alibi", "visit"]):
            reply = "I was in my manor drawing room reviewing family correspondence by the hearth. What commoners claim to see through midnight fog is irrelevant hearsay."
            stress = 12
            anomaly = "Subtly rearranges silk shawl to conceal trembling hands."
        else:
            reply = "Detective, I trust this interrogation will be conducted with the decorum fitting my nobility, rather than the vulgar brawling of the docks."
            stress = 4
            anomaly = "Gives a cold, disdainful sneer."
            
    elif s_id == "edmund":
        if any(w in q for w in ["autopsy", "drawer", "report", "natural", "cause", "wound"]):
            reply = "Medical examination requires meticulous observation, not hasty village hysteria. Preliminary notations regarding cardiovascular failure are standard clinical practice before trauma pathology is finalized."
            stress = 16
            anomaly = "Adjusts spectacles nervously; avoids direct eye contact with the autopsy files."
        else:
            reply = "The thoracic wound was caused by a narrow triangular blade. If you seek venomous concoctions, you would be wiser to interrogate Elara Nightshade regarding her apothecary garden."
            stress = 6
            anomaly = "Taps clinical tweezers against the table with measured precision."
            
    elif s_id == "lena":
        if any(w in q for w in ["coin", "purse", "steal", "belonging", "silver", "room"]):
            reply = "Coins? At an inn? Why, travelers drop coppers under the tavern benches every evening! Honest Lena has kept hearth and bed for twenty years without a single blemish on her name!"
            stress = 15
            anomaly = "Laughs with an unnaturally shrill pitch; glances toward the floorboards."
        else:
            reply = "Have some hot spiced cider, Detective! Folks whisper plenty by my hearth—like Corin smuggling foreign contraband, or Guard Tomas dozing at his post."
            stress = 5
            anomaly = "Flashes a warm, overly theatrical tavern smile."
            
    elif s_id == "finn":
        if any(w in q for w in ["early", "shift", "boat", "smuggle", "crate"]):
            reply = "I haul timber and salt herring, mate. If a man comes down to grease his pulleys before sunrise, that's called an honest day's labor, not murder. Go badger the fancy lords."
            stress = 14
            anomaly = "Clenches calloused fists; shifts boot uncomfortably."
        else:
            reply = "I found his lordship lying stiff in the storehouse. I ran straight for the alarm bell like any god-fearing dockhand would. That's all I know."
            stress = 5
            anomaly = "Stares down at the stone floor with sullen, guarded eyes."
            
    elif s_id == "oswin":
        if any(w in q for w in ["ledger", "page", "account", "tax", "bribe"]):
            reply = "Estate audit ledgers are confidential under municipal council ordinance. Several sections are currently undergoing standard administrative reconciliation."
            stress = 14
            anomaly = "Straightens ledger papers with rigid, stiffened fingers."
        else:
            reply = "Lord Aldric's estate was deeply entangled in complex financial affairs. I advise the court to examine Master Garrick's harbor accounts with particular scrutiny."
            stress = 6
            anomaly = "Clears throat with a dry, mechanical cough."
            
    elif s_id == "elara":
        if any(w in q for w in ["poison", "herb", "wolfsbane", "aconite", "purple", "silver"]):
            reply = "I am a simple apothecary, Detective! I gather chamomile and soothing willow bark for the sick! I know nothing of poisons—why do you look upon my garden with such cruelty?"
            stress = 18
            anomaly = "Freezes completely still like a cornered deer; buries hands inside wool sleeves."
        else:
            reply = "The earth remembers every footprint, Detective. But I only saw Corin and Aldric having a terrible screaming quarrel by the fountain at dusk."
            stress = 5
            anomaly = "Speaks in a timid, fragile whisper with downcast eyes."
            
    elif s_id == "tomas":
        if any(w in q for w in ["sleep", "brazier", "leave", "post", "gate", "gap"]):
            reply = "Sir! Guard Tomas Reed stood sentry under the northern archway without breaking formation! Any rumor of extinguished braziers was merely a scheduled patrol along the rocky bluff!"
            stress = 16
            anomaly = "Swallows with an audible click; jaw muscles bunch up tightly."
        else:
            reply = "Sir! Northern gate is fully secured under Mayor Eldridge's lockdown order! No unauthorized cutthroat crossed my pass!"
            stress = 4
            anomaly = "Stands at rigid military attention in his seat."
            
    elif s_id == "corin":
        if any(w in q for w in ["fight", "argument", "yell", "quarrel", "false", "crate"]):
            reply = "An argument? That wasn't a fight, Detective, that was just spirited haggling over turnip prices! A merchant must defend his livelihood! I wouldn't harm a field mouse!"
            stress = 15
            anomaly = "Tugs nervously on left earlobe; bounces heel in frantic rhythm."
        else:
            reply = "Between you and me, Detective... while I was minding my stall, I saw Harbour Master Garrick handing an iron key to a cloaked stranger in the shadows! Ask Garrick about that!"
            stress = 8
            anomaly = "Displays a wide, strained merchant smile that doesn't reach anxious eyes."
            
    else:
        reply = f"I am doing my civic duty, Detective. Hollow Creek has many secrets, but Lord Aldric's killer walks among us. Look to the harbor and the storehouse."
        stress = 5
        anomaly = "Shifts uncomfortably under questioning."
        
    return {
        "reply": reply,
        "stress_delta": stress,
        "anomaly": anomaly,
        "source": "fallback"
    }

def extract_json_or_text(raw: str) -> dict:
    if not raw:
        return {"reply": "", "stress_delta": 5, "anomaly": None}
    cleaned = re.sub(r"<think>.*?</think>", "", raw, flags=re.DOTALL).strip()
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", cleaned, flags=re.DOTALL)
    if match:
        cleaned = match.group(1).strip()
    try:
        data = json.loads(cleaned)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    brace_match = re.search(r"(\{.*\})", cleaned, flags=re.DOTALL)
    if brace_match:
        try:
            data = json.loads(brace_match.group(1))
            if isinstance(data, dict):
                return data
        except Exception:
            pass
    return {"reply": cleaned, "stress_delta": 6, "anomaly": None}

def ollama_chat(suspect: dict, history: list[dict], turn_count: int) -> dict:
    ensure_ollama_running()
    system_text = build_suspect_system_prompt(suspect)
    
    messages = [{"role": "system", "content": system_text}]
    for item in history[-6:]:
        role = "user" if item.get("role") == "user" else "assistant"
        text = str(item.get("text", ""))[:800]
        if text:
            messages.append({"role": role, "content": text})
            
    payload = {
        "model": OLLAMA_MODEL,
        "messages": messages,
        "stream": False,
        "format": "json",
        "keep_alive": "60m",
        "options": {"temperature": 0.75, "num_predict": 120}
    }
    
    request = Request(
        f"{OLLAMA_URL}/api/chat",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    with OLLAMA_HTTP.open(request, timeout=OLLAMA_TIMEOUT) as response:
        result = json.loads(response.read().decode("utf-8"))
        
    raw_content = str(result.get("message", {}).get("content", "")).strip()
    parsed = extract_json_or_text(raw_content)
    reply = str(parsed.get("reply", "")).strip()[:600]
    if not reply:
        raise ValueError("Ollama returned empty reply")
        
    stress_delta = int(parsed.get("stress_delta", 5))
    anomaly = parsed.get("anomaly")
    
    global OLLAMA_READY
    OLLAMA_READY = True
    return {
        "reply": reply,
        "stress_delta": stress_delta,
        "anomaly": anomaly,
        "source": "ollama"
    }

def gemini_chat(suspect: dict, history: list[dict], turn_count: int) -> dict:
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key or api_key in ["your_key_here", "your_rotated_key_here"]:
        raise ValueError("Gemini API key not configured")
        
    candidate_models = [
        os.environ.get("GEMINI_MODEL", "gemini-3-flash-preview").strip(),
        "gemini-3-flash-preview",
        "gemini-3.1-flash-lite-preview",
        "gemini-3.8-flash"
    ]
    seen = set()
    models = [m for m in candidate_models if m and not (m in seen or seen.add(m))]
    
    system_text = build_suspect_system_prompt(suspect)
    contents = []
    for item in history[-6:]:
        role = "user" if item.get("role") == "user" else "model"
        text = str(item.get("text", ""))[:800]
        if text:
            contents.append({"role": role, "parts": [{"text": text}]})
            
    payload = {
        "systemInstruction": {"parts": [{"text": system_text}]},
        "contents": contents,
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.75,
            "maxOutputTokens": 1000
        }
    }
    
    last_err = None
    for model in models:
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
            request = Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urlopen(request, timeout=7.0) as response:
                result = json.loads(response.read().decode("utf-8"))
            answer = result["candidates"][0]["content"]["parts"][0]["text"]
            parsed = extract_json_or_text(answer)
            reply = str(parsed.get("reply", "")).strip()[:600]
            stress_delta = int(parsed.get("stress_delta", 5))
            anomaly = parsed.get("anomaly")
            return {
                "reply": reply,
                "stress_delta": stress_delta,
                "anomaly": anomaly,
                "source": f"gemini ({model})"
            }
        except Exception as e:
            last_err = e
            continue
            
    raise last_err or RuntimeError("Gemini request failed")

def process_interrogation_turn(data: dict) -> dict:
    suspect_id = str(data.get("suspect_id", "garrick")).lower().strip()
    suspect = get_suspect_from_db(suspect_id)
    
    raw_history = data.get("history", [])
    history = [{"role": str(i.get("role", "user")), "text": str(i.get("text", ""))} for i in raw_history if isinstance(i, dict)]
    turn_count = int(data.get("turn_count", 0))
    
    last_user_message = next((item["text"] for item in reversed(history) if item.get("role") == "user"), "")
    
    try:
        return gemini_chat(suspect, history, turn_count)
    except Exception as gemini_err:
        try:
            return ollama_chat(suspect, history, turn_count)
        except Exception as ollama_err:
            print(f"LLM generation failed ({type(ollama_err).__name__}). Using smart character fallback engine.", flush=True)
            return smart_fallback_reply(suspect, last_user_message)

def warm_ollama() -> None:
    try:
        ensure_ollama_running()
        print(f"Local Ollama service active: {OLLAMA_MODEL}", flush=True)
    except Exception as e:
        print(f"Ollama check notice ({type(e).__name__}): {e}", flush=True)

class InterrogationHandler(BaseHTTPRequestHandler):
    def _send(self, code: int, payload: dict) -> None:
        try:
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.end_headers()
            self.wfile.write(body)
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError, OSError):
            pass

    def do_OPTIONS(self) -> None:
        self._send(200, {"status": "ok"})

    def do_GET(self) -> None:
        if self.path == "/health":
            api_key = os.environ.get("GEMINI_API_KEY", "").strip()
            configured = bool(api_key and api_key not in ["your_key_here", "your_rotated_key_here"])
            self._send(200, {
                "status": "ok",
                "gemini_configured": configured,
                "ollama_ready": OLLAMA_READY,
                "ollama_model": OLLAMA_MODEL
            })
        elif self.path == "/suspects":
            suspects = get_all_suspects_from_db()
            self._send(200, {"suspects": suspects})
        else:
            self._send(404, {"error": "Not found"})

    def do_POST(self) -> None:
        if self.path != "/chat":
            self._send(404, {"error": "Not found"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length < 1 or length > 32_000:
                self._send(413, {"error": "Request too large"})
                return
            body = self.rfile.read(length)
            data = json.loads(body.decode("utf-8"))
            suspect_id = data.get("suspect_id", "unknown")
            print(f"[Interrogation] Question received for suspect '{suspect_id}'", flush=True)
            response = process_interrogation_turn(data)
            print(f"[Interrogation] Reply from '{suspect_id}' ({response.get('source')}): {response.get('reply')[:80]}...", flush=True)
            self._send(200, response)
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError, OSError):
            print("[Interrogation] Game client closed connection before reply could be delivered.", flush=True)
        except Exception as error:
            print(f"Interrogation server error: {error}", flush=True)
            try:
                self._send(500, {"error": str(error)})
            except Exception:
                pass

    def log_message(self, _format: str, *_args) -> None:
        return

if __name__ == "__main__":
    host = "127.0.0.1"
    port = int(os.environ.get("LOCAL_LLM_PORT", "8765"))
    print(f"Hollow Creek Smart Interrogation Backend listening on http://{host}:{port}")
    print(f"Active model target: {OLLAMA_MODEL} (Ollama URL: {OLLAMA_URL})", flush=True)
    warm_ollama()
    ThreadingHTTPServer((host, port), InterrogationHandler).serve_forever()
