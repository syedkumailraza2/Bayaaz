"""Unified STT service — Vosk WebSocket + Whisper HTTP on a single port.

Routes (one process, one bind port, one public URL):
    WS  /ws            streaming Vosk recognizer for majlis voice-follow
    POST /transcribe   Whisper batch transcription for listen mode
    GET /health        liveness probe

The protocols are unchanged from the previous split-port build — only the
network layer was swapped from `websockets.serve` + Flask to FastAPI +
uvicorn so a single hosting platform port covers both flows.

Run:
    uvicorn vosk_service:app --host 0.0.0.0 --port ${PORT:-5001}

Env:
    VOSK_MODEL_PATH     path to unzipped Vosk model (default ./model)
    VOSK_SAMPLE_RATE    default PCM rate (default 16000)
    WHISPER_MODEL_SIZE  faster-whisper model name (default "base")
    PORT                bind port — informational only; the actual port
                        is set on the uvicorn command line (default 5001)
"""

import asyncio
import json
import logging
import os
import tempfile
import urllib.request
from contextlib import asynccontextmanager
from typing import List, Optional

from fastapi import FastAPI, File, Form, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from faster_whisper import WhisperModel
from vosk import KaldiRecognizer, Model, SetLogLevel

# ── Config ────────────────────────────────────────────────────────────────────

MODEL_PATH = os.getenv("VOSK_MODEL_PATH", "model")
DEFAULT_SAMPLE_RATE = int(os.getenv("VOSK_SAMPLE_RATE", "16000"))
WHISPER_MODEL_SIZE = os.getenv("WHISPER_MODEL_SIZE", "base")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("stt")
SetLogLevel(-1)  # silence Kaldi/Vosk internal logs

# ── Models (loaded once, shared across requests) ──────────────────────────────

log.info("loading vosk model from %s", MODEL_PATH)
if not os.path.isdir(MODEL_PATH):
    raise SystemExit(
        f"VOSK_MODEL_PATH={MODEL_PATH!r} does not exist. "
        "Download a model from https://alphacephei.com/vosk/models and "
        "symlink/copy it as ./model or set VOSK_MODEL_PATH."
    )
vosk_model = Model(MODEL_PATH)
log.info("vosk model loaded")

log.info("loading whisper model: %s", WHISPER_MODEL_SIZE)
whisper_model = WhisperModel(WHISPER_MODEL_SIZE, device="cpu", compute_type="int8")
log.info("whisper model loaded")

# ── Keep-alive (Render free tier sleeps after 15min idle) ─────────────────────
#
# Render's load balancer counts only requests that arrive through their
# public proxy as "activity", so the ping has to go to RENDER_EXTERNAL_URL,
# not to loopback. RENDER_EXTERNAL_URL is auto-injected by Render.
#
# Tweak the interval via KEEP_ALIVE_INTERVAL_SECONDS (default 600 = 10 min).
# Set DISABLE_KEEP_ALIVE=1 to turn it off (useful for paid plans that don't
# sleep, or when an external uptime monitor is doing the pinging).

KEEP_ALIVE_URL = os.getenv("RENDER_EXTERNAL_URL") or os.getenv("KEEP_ALIVE_URL")
KEEP_ALIVE_INTERVAL = int(os.getenv("KEEP_ALIVE_INTERVAL_SECONDS", "600"))
KEEP_ALIVE_DISABLED = os.getenv("DISABLE_KEEP_ALIVE") == "1"


async def _keep_alive_loop():
    target = f"{KEEP_ALIVE_URL.rstrip('/')}/health"
    log.info("keep-alive: pinging %s every %ds", target, KEEP_ALIVE_INTERVAL)
    while True:
        try:
            await asyncio.sleep(KEEP_ALIVE_INTERVAL)
            # Run the blocking urllib call in a thread so we don't park
            # the event loop on slow networks.
            await asyncio.to_thread(
                lambda: urllib.request.urlopen(target, timeout=10).read()
            )
        except asyncio.CancelledError:
            log.info("keep-alive: stopping")
            return
        except Exception as e:
            log.warning("keep-alive: ping failed: %s", e)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = None
    if KEEP_ALIVE_URL and not KEEP_ALIVE_DISABLED:
        task = asyncio.create_task(_keep_alive_loop())
    else:
        log.info(
            "keep-alive: disabled (RENDER_EXTERNAL_URL=%s disabled=%s)",
            bool(KEEP_ALIVE_URL),
            KEEP_ALIVE_DISABLED,
        )
    try:
        yield
    finally:
        if task is not None:
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass


# ── FastAPI app ───────────────────────────────────────────────────────────────

app = FastAPI(
    title="Bayaaz STT",
    docs_url=None,
    redoc_url=None,
    lifespan=lifespan,
)


@app.get("/health")
def health():
    return {"status": "ok"}


# ── Vosk WebSocket — majlis voice-follow ──────────────────────────────────────

def make_recognizer(sample_rate: int, grammar: Optional[List[str]]) -> KaldiRecognizer:
    if grammar:
        rec = KaldiRecognizer(
            vosk_model, sample_rate, json.dumps(grammar + ["[unk]"])
        )
    else:
        rec = KaldiRecognizer(vosk_model, sample_rate)
    rec.SetWords(True)
    return rec


@app.websocket("/ws")
async def ws_recognize(ws: WebSocket):
    await ws.accept()
    client = f"{ws.client.host}:{ws.client.port}" if ws.client else "?"
    log.info("[%s] connected", client)

    sample_rate = DEFAULT_SAMPLE_RATE
    rec = make_recognizer(sample_rate, None)
    bytes_received = 0
    last_partial = ""

    try:
        while True:
            message = await ws.receive()
            # FastAPI / Starlette delivers a dict — pick bytes or text manually.
            if message["type"] == "websocket.disconnect":
                break

            if (data_bytes := message.get("bytes")) is not None:
                bytes_received += len(data_bytes)
                if rec.AcceptWaveform(data_bytes):
                    result = rec.Result()
                    try:
                        text = json.loads(result).get("text", "")
                    except Exception:
                        text = ""
                    if text:
                        log.info("[%s] final: %r", client, text)
                    await ws.send_text(result)
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
                        await ws.send_text(partial_raw)
                continue

            text_frame = message.get("text")
            if not text_frame:
                continue

            try:
                data = json.loads(text_frame)
            except Exception:
                log.warning("[%s] non-JSON text frame: %r", client, text_frame[:80])
                continue

            if data.get("eof") == 1:
                final = rec.FinalResult()
                try:
                    text = json.loads(final).get("text", "")
                except Exception:
                    text = ""
                log.info("[%s] eof — final: %r (bytes=%d)", client, text, bytes_received)
                await ws.send_text(final)
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
    except WebSocketDisconnect as e:
        log.info("[%s] disconnected (%s)", client, e.code)
    except Exception:
        log.exception("[%s] handler crashed", client)


# ── Whisper HTTP — listen mode ────────────────────────────────────────────────

@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    hint: Optional[str] = Form(default=None),
):
    audio_bytes = await audio.read()
    if not audio_bytes:
        return {"transcript": ""}

    hint_text = (hint or "").strip()

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    def _transcribe_blocking():
        return whisper_model.transcribe(
            tmp_path,
            # No explicit language — let Whisper detect naturally (Urdu audio
            # detected as "ur" keeps Arabic-script output, but initial_prompt
            # in Roman script overrides the output style to match the prompt).
            language=None,
            task="transcribe",
            initial_prompt=hint_text or None,
            beam_size=5,
            vad_filter=True,
            vad_parameters={"min_silence_duration_ms": 500},
        )

    try:
        # faster-whisper is CPU-bound; offload to a thread so the event loop
        # stays free for concurrent /ws sessions.
        segments, info = await asyncio.to_thread(_transcribe_blocking)
        transcript = " ".join(s.text.strip() for s in segments).strip()
        log.info(
            "whisper transcript: %r (lang=%s hint=%r)",
            transcript, info.language, hint_text[:40] if hint_text else None,
        )
        return {"transcript": transcript}
    except Exception as e:
        log.exception("whisper transcription failed")
        return JSONResponse({"error": str(e)}, status_code=500)
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Local convenience runner. In production use:
    #   uvicorn vosk_service:app --host 0.0.0.0 --port $PORT
    import uvicorn
    port = int(os.getenv("PORT", "5001"))
    host = os.getenv("HOST", "0.0.0.0")
    log.info("starting unified stt service on %s:%d", host, port)
    uvicorn.run(app, host=host, port=port, log_level="info", ws_max_size=8 * 1024 * 1024)
