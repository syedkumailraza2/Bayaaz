"""STT service: Vosk WebSocket (group sessions) + Whisper HTTP (listen mode).

Vosk WebSocket (port 5001)
  Protocol unchanged — group session teleprompter streams raw PCM and gets
  partial/final transcripts back.  The Hindi model is kept for that flow.

Whisper HTTP (port 5002)
  POST /transcribe   multipart/form-data  field: audio (WAV file)
  Response: {"transcript": "..."}
  Uses faster-whisper with language="en" so Urdu speech comes back as Roman
  transliteration that can be compared directly against the kalaam reference text.

Env:
  VOSK_MODEL_PATH     path to unzipped Vosk model (default ./model)
  VOSK_HOST           WebSocket bind host (default 127.0.0.1)
  VOSK_PORT           WebSocket bind port (default 5001)
  VOSK_SAMPLE_RATE    default PCM rate (default 16000)
  WHISPER_MODEL_SIZE  faster-whisper model name (default "base")
  WHISPER_HTTP_PORT   HTTP bind port for Whisper endpoint (default 5002)
"""

import asyncio
import json
import logging
import os
import tempfile
import threading
from typing import List, Optional

import websockets
from flask import Flask, jsonify, request
from faster_whisper import WhisperModel
from vosk import KaldiRecognizer, Model, SetLogLevel

# ── Config ────────────────────────────────────────────────────────────────────

MODEL_PATH = os.getenv("VOSK_MODEL_PATH", "model")
HOST = os.getenv("VOSK_HOST", "127.0.0.1")
PORT = int(os.getenv("VOSK_PORT", "5001"))
DEFAULT_SAMPLE_RATE = int(os.getenv("VOSK_SAMPLE_RATE", "16000"))

WHISPER_MODEL_SIZE = os.getenv("WHISPER_MODEL_SIZE", "base")
WHISPER_HTTP_PORT = int(os.getenv("WHISPER_HTTP_PORT", "5002"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("stt")
SetLogLevel(-1)  # silence Kaldi/Vosk internal logs

# ── Vosk model (group sessions) ───────────────────────────────────────────────

log.info("loading vosk model from %s", MODEL_PATH)
if not os.path.isdir(MODEL_PATH):
    raise SystemExit(
        f"VOSK_MODEL_PATH={MODEL_PATH!r} does not exist. "
        "Download a model from https://alphacephei.com/vosk/models and "
        "symlink/copy it as ./model or set VOSK_MODEL_PATH."
    )
vosk_model = Model(MODEL_PATH)
log.info("vosk model loaded")

# ── Whisper model (listen mode) ───────────────────────────────────────────────

log.info("loading whisper model: %s", WHISPER_MODEL_SIZE)
whisper_model = WhisperModel(WHISPER_MODEL_SIZE, device="cpu", compute_type="int8")
log.info("whisper model loaded")

# ── Vosk WebSocket server ─────────────────────────────────────────────────────

def make_recognizer(sample_rate: int, grammar: Optional[List[str]]) -> KaldiRecognizer:
    if grammar:
        rec = KaldiRecognizer(
            vosk_model, sample_rate, json.dumps(grammar + ["[unk]"])
        )
    else:
        rec = KaldiRecognizer(vosk_model, sample_rate)
    rec.SetWords(True)
    return rec


async def recognize(ws):
    client = f"{ws.remote_address[0]}:{ws.remote_address[1]}"
    log.info("[%s] connected", client)

    sample_rate = DEFAULT_SAMPLE_RATE
    rec = make_recognizer(sample_rate, None)
    bytes_received = 0
    last_partial = ""

    try:
        async for message in ws:
            if isinstance(message, bytes):
                bytes_received += len(message)
                if rec.AcceptWaveform(message):
                    result = rec.Result()
                    try:
                        text = json.loads(result).get("text", "")
                    except Exception:
                        text = ""
                    if text:
                        log.info("[%s] final: %r", client, text)
                    await ws.send(result)
                    last_partial = ""
                else:
                    partial_raw = rec.PartialResult()
                    try:
                        partial = json.loads(partial_raw).get("partial", "")
                    except Exception:
                        partial = ""
                    if partial and partial != last_partial:
                        log.info("[%s] partial: %r", client, partial)
                        last_partial = partial
                        await ws.send(partial_raw)
                continue

            try:
                data = json.loads(message)
            except Exception:
                log.warning("[%s] non-JSON text frame: %r", client, message[:80])
                continue

            if data.get("eof") == 1:
                final = rec.FinalResult()
                try:
                    text = json.loads(final).get("text", "")
                except Exception:
                    text = ""
                log.info("[%s] eof — final: %r (bytes=%d)", client, text, bytes_received)
                await ws.send(final)
                break

            cfg = data.get("config")
            if isinstance(cfg, dict):
                sr = int(cfg.get("sample_rate", sample_rate))
                grammar = cfg.get("grammar") if isinstance(cfg.get("grammar"), list) else None
                sample_rate = sr
                rec = make_recognizer(sample_rate, grammar)
                log.info(
                    "[%s] reconfigured sample_rate=%d grammar=%s",
                    client,
                    sample_rate,
                    f"{len(grammar)} phrases" if grammar else "none",
                )

    except websockets.ConnectionClosed as e:
        log.info("[%s] disconnected (%s)", client, e.code)
    except Exception:
        log.exception("[%s] handler crashed", client)


async def run_vosk():
    log.info("vosk ws listening on ws://%s:%d", HOST, PORT)
    async with websockets.serve(
        recognize,
        HOST,
        PORT,
        max_size=8 * 1024 * 1024,
        ping_interval=20,
        ping_timeout=20,
    ):
        await asyncio.Future()

# ── Whisper Flask HTTP server ─────────────────────────────────────────────────

flask_app = Flask(__name__)


@flask_app.post("/transcribe")
def transcribe():
    if "audio" not in request.files:
        return jsonify({"error": "No audio file provided"}), 400

    audio_bytes = request.files["audio"].read()
    if not audio_bytes:
        return jsonify({"transcript": ""}), 200

    # Optional: first 1-2 lines of the kalaam in Roman script.
    # Feeding these as initial_prompt biases Whisper to produce Roman Urdu
    # output instead of translating to English or outputting Arabic script.
    hint = request.form.get("hint", "").strip()

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        segments, info = whisper_model.transcribe(
            tmp_path,
            # No explicit language — let Whisper detect naturally (Urdu audio
            # detected as "ur" keeps Arabic-script output, but initial_prompt
            # in Roman script overrides the output style to match the prompt).
            language=None,
            task="transcribe",
            initial_prompt=hint or None,
            beam_size=5,
            vad_filter=True,
            vad_parameters={"min_silence_duration_ms": 500},
        )
        transcript = " ".join(s.text.strip() for s in segments).strip()
        log.info(
            "whisper transcript: %r (lang=%s hint=%r)",
            transcript, info.language, hint[:40] if hint else None,
        )
        return jsonify({"transcript": transcript})
    except Exception as e:
        log.exception("whisper transcription failed")
        return jsonify({"error": str(e)}), 500
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


def run_flask():
    log.info("whisper http listening on http://%s:%d", HOST, WHISPER_HTTP_PORT)
    flask_app.run(
        host=HOST,
        port=WHISPER_HTTP_PORT,
        debug=False,
        use_reloader=False,
    )

# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Flask runs in a daemon thread; Vosk WebSocket runs in the main asyncio loop.
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()
    asyncio.run(run_vosk())
