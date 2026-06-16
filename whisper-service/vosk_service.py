"""Unified STT service — Vosk for both streaming and batch, on a single port.

Routes (one process, one bind port, one public URL):
    WS  /ws            streaming Vosk recognizer for majlis voice-follow
    POST /transcribe   Vosk batch transcription for listen mode
    GET /health        liveness probe

A single Vosk model serves both flows, so only one model is resident in RAM.
(/transcribe previously used faster-whisper, but that doubled model memory and
pushed small instances over their limit; Vosk handles batch WAVs fine.)

Run:
    uvicorn vosk_service:app --host 0.0.0.0 --port ${PORT:-5001}

Env:
    VOSK_MODEL_PATH     path to unzipped Vosk model (default ./model)
    VOSK_SAMPLE_RATE    default PCM rate (default 16000)
    PORT                bind port — informational only; the actual port
                        is set on the uvicorn command line (default 5001)
"""

import asyncio
import io
import json
import logging
import os
import urllib.request
import wave
from contextlib import asynccontextmanager
from typing import List, Optional

from fastapi import FastAPI, File, Form, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from vosk import KaldiRecognizer, Model, SetLogLevel

# ── Config ────────────────────────────────────────────────────────────────────

MODEL_PATH = os.getenv("VOSK_MODEL_PATH", "model")
DEFAULT_SAMPLE_RATE = int(os.getenv("VOSK_SAMPLE_RATE", "16000"))

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

# Single-model service: Vosk serves BOTH the streaming /ws path (practice mode)
# and the batch /transcribe path (listen mode). We used to load faster-whisper
# for /transcribe, but that doubled the resident model memory (~200MB+) and
# pushed small instances over their RAM limit. Vosk handles batch files fine —
# the kalaam matcher already transliterates Vosk's Devanagari output for Urdu.

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


# ── Vosk HTTP batch — listen mode ─────────────────────────────────────────────

def _vosk_transcribe_wav(audio_bytes: bytes) -> str:
    """Run a full WAV through a fresh Vosk recognizer and return the text.

    The client builds a 16kHz mono 16-bit PCM WAV before upload, which is
    exactly Vosk's required input — no decode/resample needed. If the bytes
    aren't a parseable WAV we fall back to treating them as raw PCM at the
    default sample rate.
    """
    try:
        wf = wave.open(io.BytesIO(audio_bytes), "rb")
        sample_rate = wf.getframerate()
        # Vosk needs mono 16-bit PCM. The client guarantees this; if a caller
        # sends something else, log it — recognition quality will suffer.
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2:
            log.warning(
                "transcribe: expected mono/16-bit, got channels=%d width=%d",
                wf.getnchannels(), wf.getsampwidth(),
            )
        rec = KaldiRecognizer(vosk_model, sample_rate)
        rec.SetWords(True)
        while True:
            frames = wf.readframes(4000)
            if not frames:
                break
            rec.AcceptWaveform(frames)
    except wave.Error:
        # Not a WAV container — feed the raw bytes as PCM at the default rate.
        log.warning("transcribe: unparseable WAV, treating as raw PCM")
        rec = KaldiRecognizer(vosk_model, DEFAULT_SAMPLE_RATE)
        rec.SetWords(True)
        rec.AcceptWaveform(audio_bytes)

    return json.loads(rec.FinalResult()).get("text", "")


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    # Accepted for backward-compat with the client's multipart form. Vosk has no
    # initial-prompt equivalent, so it's currently unused; phrase biasing would
    # need the full reference lines passed as a Vosk grammar instead.
    hint: Optional[str] = Form(default=None),
):
    audio_bytes = await audio.read()
    if not audio_bytes:
        return {"transcript": ""}

    try:
        # Vosk decoding is CPU-bound; offload to a thread so the event loop
        # stays free for concurrent /ws sessions.
        transcript = await asyncio.to_thread(_vosk_transcribe_wav, audio_bytes)
        log.info("vosk transcript: %r", transcript)
        return {"transcript": transcript}
    except Exception as e:
        log.exception("vosk transcription failed")
        return JSONResponse({"error": str(e)}, status_code=500)


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Local convenience runner. In production use:
    #   uvicorn vosk_service:app --host 0.0.0.0 --port $PORT
    import uvicorn
    port = int(os.getenv("PORT", "5001"))
    host = os.getenv("HOST", "0.0.0.0")
    log.info("starting unified stt service on %s:%d", host, port)
    uvicorn.run(app, host=host, port=port, log_level="info", ws_max_size=8 * 1024 * 1024)
