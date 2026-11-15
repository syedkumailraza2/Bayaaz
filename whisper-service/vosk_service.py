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
    STT_THREADS         decoder threads (default: CPU count)
    STT_MAX_STREAMS     concurrent /ws streams before refusing (default threads*8)
    STT_PARTIAL_INTERVAL_MS  min gap between partial results (default 300)
    STT_MAX_BACKLOG_SECONDS  audio a lagging stream may queue (default 3)
    STT_MAX_ACTIVE / STT_BEAM  decoder search width (default 4000 / 11)
    STT_TOKEN           shared secret required in the X-STT-Token header
    PORT                bind port — informational only; the actual port
                        is set on the uvicorn command line (default 5001)
"""

import asyncio
import io
import json
import logging
import os
import re
import shutil
import tempfile
import time
import urllib.request
import wave
from collections import deque
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from typing import List, Optional

import hmac

from fastapi import FastAPI, File, Form, Header, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from vosk import KaldiRecognizer, Model, SetLogLevel

# ── Config ────────────────────────────────────────────────────────────────────

MODEL_PATH = os.getenv("VOSK_MODEL_PATH", "model")
DEFAULT_SAMPLE_RATE = int(os.getenv("VOSK_SAMPLE_RATE", "16000"))

# Decoder threads. Vosk releases the GIL inside AcceptWaveform, so threads
# scale ~linearly across cores while sharing ONE copy of the model in RAM
# (separate uvicorn workers would each load their own ~200MB model).
STT_THREADS = int(os.getenv("STT_THREADS", "0")) or (os.cpu_count() or 1)
# Hard cap on concurrent /ws streams; extra connections are refused with
# close code 1013 ("try again later") instead of degrading everyone.
MAX_STREAMS = int(os.getenv("STT_MAX_STREAMS", "0")) or STT_THREADS * 8
# Send partial transcripts at most this often. Building a partial on every
# 100ms frame was ~3/4 of per-stream CPU in load tests.
PARTIAL_INTERVAL = float(os.getenv("STT_PARTIAL_INTERVAL_MS", "300")) / 1000
# If a stream falls further behind than this, drop its oldest audio rather
# than buffering without bound (memory) and lagging further (latency).
MAX_BACKLOG_SECONDS = float(os.getenv("STT_MAX_BACKLOG_SECONDS", "3"))
# Merge queued frames into one decoder call, up to this much audio.
MAX_BATCH_SECONDS = 1.0
# Decoder search width. Benchmarked on Hindi speech: 4000/11 used ~32% less
# CPU than the model default 7000/13 with an identical transcript; going
# lower gave no further saving. Set both to 0 to keep the model's own values.
# Shared secret with the backend (sent as the X-STT-Token header). Unset =
# no auth, fine for localhost; ALWAYS set it on a public host.
STT_TOKEN = os.getenv("STT_TOKEN", "")
MAX_ACTIVE = int(os.getenv("STT_MAX_ACTIVE", "4000"))
BEAM = float(os.getenv("STT_BEAM", "11"))

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


def _tuned_model_dir(src: str) -> str:
    """Return a model dir whose conf/model.conf has our decoder limits.

    Vosk only reads these from model.conf, so we build a throwaway overlay
    (symlinks to the big files + a patched copy of conf/) rather than
    editing the model in place.
    """
    if not MAX_ACTIVE or not BEAM:
        return src
    src = os.path.realpath(src)
    conf_dir = os.path.join(src, "conf")
    if not os.path.isfile(os.path.join(conf_dir, "model.conf")):
        return src
    out = tempfile.mkdtemp(prefix="vosk-model-")
    for entry in os.listdir(src):
        if entry != "conf":
            os.symlink(os.path.join(src, entry), os.path.join(out, entry))
    shutil.copytree(conf_dir, os.path.join(out, "conf"))
    path = os.path.join(out, "conf", "model.conf")
    with open(path) as f:
        conf = f.read()
    conf = re.sub(r"--max-active=\d+", f"--max-active={MAX_ACTIVE}", conf)
    conf = re.sub(r"--beam=[\d.]+", f"--beam={BEAM}", conf)
    with open(path, "w") as f:
        f.write(conf)
    return out


vosk_model = Model(_tuned_model_dir(MODEL_PATH))
decoder_pool = ThreadPoolExecutor(max_workers=STT_THREADS, thread_name_prefix="vosk")
active_streams = 0
log.info(
    "vosk model loaded (threads=%d max_streams=%d max_active=%s beam=%s)",
    STT_THREADS, MAX_STREAMS, MAX_ACTIVE or "model", BEAM or "model",
)

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
    return {"status": "ok", "streams": active_streams, "max_streams": MAX_STREAMS}


# ── Vosk WebSocket — majlis voice-follow ──────────────────────────────────────

def make_recognizer(sample_rate: int, grammar: Optional[List[str]]) -> KaldiRecognizer:
    if grammar:
        rec = KaldiRecognizer(
            vosk_model, sample_rate, json.dumps(grammar + ["[unk]"])
        )
    else:
        rec = KaldiRecognizer(vosk_model, sample_rate)
    # Word timings aren't used by the backend matcher (it reads text/partial).
    rec.SetWords(False)
    return rec


def _decode(rec: KaldiRecognizer, audio: bytes, want_partial: bool):
    """Runs in the decoder pool. Returns (final_json | None, partial_json | None)."""
    if rec.AcceptWaveform(audio):
        return rec.Result(), None
    return None, (rec.PartialResult() if want_partial else None)


def _authorized(token: Optional[str]) -> bool:
    return not STT_TOKEN or hmac.compare_digest(token or "", STT_TOKEN)


async def _run(fn, *args):
    return await asyncio.get_running_loop().run_in_executor(decoder_pool, fn, *args)


@app.websocket("/ws")
async def ws_recognize(ws: WebSocket):
    global active_streams
    if not _authorized(ws.headers.get("x-stt-token")):
        await ws.close(code=1008)  # policy violation — rejected before accept
        return
    await ws.accept()
    client = ws.headers.get("x-forwarded-for") or (
        f"{ws.client.host}:{ws.client.port}" if ws.client else "?")
    if active_streams >= MAX_STREAMS:
        log.warning("[%s] refused: %d/%d streams busy", client, active_streams, MAX_STREAMS)
        await ws.close(code=1013, reason="stt busy")
        return
    active_streams += 1
    log.info("[%s] connected (%d/%d streams)", client, active_streams, MAX_STREAMS)

    # The reader task only enqueues; the decoder loop below drains the queue
    # through the thread pool. Audio, config and eof share one queue so their
    # order is preserved.
    queue: deque = deque()
    wake = asyncio.Event()
    state = {"backlog": 0, "sample_rate": DEFAULT_SAMPLE_RATE, "closed": False}

    def push(item):
        queue.append(item)
        wake.set()

    async def reader():
        try:
            while True:
                message = await ws.receive()
                if message["type"] == "websocket.disconnect":
                    break
                if (data := message.get("bytes")) is not None:
                    push(("audio", data))
                    state["backlog"] += len(data)
                    cap = int(MAX_BACKLOG_SECONDS * state["sample_rate"] * 2)
                    dropped = 0
                    while state["backlog"] > cap and queue and queue[0][0] == "audio":
                        state["backlog"] -= len(queue[0][1])
                        dropped += len(queue.popleft()[1])
                    if dropped:
                        log.warning("[%s] behind — dropped %d bytes of old audio", client, dropped)
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
                    push(("eof", None))
                    break
                if isinstance(data.get("config"), dict):
                    cfg = data["config"]
                    state["sample_rate"] = int(cfg.get("sample_rate", state["sample_rate"]))
                    push(("config", cfg))
        except Exception:
            pass  # disconnect / transport error — the decoder loop drains and exits
        finally:
            state["closed"] = True
            wake.set()

    reader_task = asyncio.create_task(reader())
    rec = make_recognizer(DEFAULT_SAMPLE_RATE, None)
    bytes_received = 0
    last_partial = ""
    last_partial_at = 0.0

    try:
        while True:
            if not queue:
                if state["closed"]:
                    break
                wake.clear()
                await wake.wait()
                continue

            kind, payload = queue.popleft()

            if kind == "config":
                grammar = payload.get("grammar") if isinstance(payload.get("grammar"), list) else None
                rec = make_recognizer(state["sample_rate"], grammar)
                log.info(
                    "[%s] reconfigured sample_rate=%d grammar=%s", client, state["sample_rate"],
                    f"{len(grammar)} words" if grammar else "none",
                )
                continue

            if kind == "eof":
                final = await _run(rec.FinalResult)
                log.info("[%s] eof — final: %r (bytes=%d)", client,
                         json.loads(final).get("text", ""), bytes_received)
                await ws.send_text(final)
                break

            # Audio: merge whatever else is queued (when behind) into one call.
            chunks = [payload]
            size = len(payload)
            limit = int(MAX_BATCH_SECONDS * state["sample_rate"] * 2)
            while queue and queue[0][0] == "audio" and size < limit:
                nxt = queue.popleft()[1]
                chunks.append(nxt)
                size += len(nxt)
            state["backlog"] = max(0, state["backlog"] - size)
            bytes_received += size

            now = time.monotonic()
            want_partial = now - last_partial_at >= PARTIAL_INTERVAL
            final, partial_raw = await _run(_decode, rec, b"".join(chunks), want_partial)

            if final is not None:
                text = json.loads(final).get("text", "")
                if text:
                    log.info("[%s] final: %r", client, text)
                await ws.send_text(final)
                last_partial = ""
            elif partial_raw is not None:
                last_partial_at = now
                partial = json.loads(partial_raw).get("partial", "")
                if partial and partial != last_partial:
                    last_partial = partial
                    await ws.send_text(partial_raw)
    except (WebSocketDisconnect, RuntimeError) as e:
        log.info("[%s] disconnected (%s)", client, e)
    except Exception:
        log.exception("[%s] handler crashed", client)
    finally:
        active_streams -= 1
        reader_task.cancel()
        log.info("[%s] closed (%d/%d streams)", client, active_streams, MAX_STREAMS)


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
        while True:
            frames = wf.readframes(4000)
            if not frames:
                break
            rec.AcceptWaveform(frames)
    except wave.Error:
        # Not a WAV container — feed the raw bytes as PCM at the default rate.
        log.warning("transcribe: unparseable WAV, treating as raw PCM")
        rec = KaldiRecognizer(vosk_model, DEFAULT_SAMPLE_RATE)
        rec.AcceptWaveform(audio_bytes)

    return json.loads(rec.FinalResult()).get("text", "")


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    # Accepted for backward-compat with the client's multipart form. Vosk has no
    # initial-prompt equivalent, so it's currently unused; phrase biasing would
    # need the full reference lines passed as a Vosk grammar instead.
    hint: Optional[str] = Form(default=None),
    x_stt_token: Optional[str] = Header(default=None),
):
    if not _authorized(x_stt_token):
        return JSONResponse({"error": "unauthorized"}, status_code=401)
    audio_bytes = await audio.read()
    if not audio_bytes:
        return {"transcript": ""}

    try:
        # Vosk decoding is CPU-bound; offload to a thread so the event loop
        # stays free for concurrent /ws sessions.
        transcript = await _run(_vosk_transcribe_wav, audio_bytes)
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
