"""Vosk streaming STT WebSocket server.

Replaces the chunked Whisper HTTP service with true streaming recognition.

Protocol:
  - Client connects via WebSocket.
  - Optional first text frame: {"config": {"sample_rate": 16000, "grammar": [...]}}.
    `grammar` is a list of phrases — when set, the recognizer is constrained
    to that closed vocabulary (huge accuracy + speed win when we know the
    kalaam text up front).
  - Client streams raw 16-bit little-endian mono PCM as binary frames.
  - Server replies with JSON for each frame:
      {"partial": "..."} while the utterance is still in flight
      {"text": "...", "result": [...]} when the recognizer commits a chunk
  - Client sends {"eof": 1} to flush, then closes.

Env:
  VOSK_MODEL_PATH  filesystem path to an unzipped Vosk model (default ./model)
  VOSK_HOST        bind host (default 127.0.0.1)
  VOSK_PORT        bind port (default 5001)
  VOSK_SAMPLE_RATE default PCM rate if client doesn't override (default 16000)
"""

import asyncio
import json
import logging
import os
from typing import List, Optional

import websockets
from vosk import KaldiRecognizer, Model, SetLogLevel

MODEL_PATH = os.getenv("VOSK_MODEL_PATH", "model")
HOST = os.getenv("VOSK_HOST", "127.0.0.1")
PORT = int(os.getenv("VOSK_PORT", "5001"))
DEFAULT_SAMPLE_RATE = int(os.getenv("VOSK_SAMPLE_RATE", "16000"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("vosk")

# Vosk's native logger is extremely chatty (kaldi pipeline internals). -1 silences it.
SetLogLevel(-1)

log.info("loading vosk model from %s", MODEL_PATH)
if not os.path.isdir(MODEL_PATH):
    raise SystemExit(
        f"VOSK_MODEL_PATH={MODEL_PATH!r} does not exist. "
        "Download a model from https://alphacephei.com/vosk/models, "
        "unzip it, and either symlink it as ./model or point "
        "VOSK_MODEL_PATH at it."
    )
model = Model(MODEL_PATH)
log.info("model loaded")


def make_recognizer(sample_rate: int, grammar: Optional[List[str]]) -> KaldiRecognizer:
    if grammar:
        # Vosk's grammar mode locks the decoder to a closed vocabulary; the
        # second arg is JSON-encoded list of phrases + "[unk]" sentinel.
        rec = KaldiRecognizer(model, sample_rate, json.dumps(grammar + ["[unk]"]))
    else:
        rec = KaldiRecognizer(model, sample_rate)
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
                    # Only ship partials when they change — saves bandwidth and
                    # avoids redundant matcher runs on the Node side.
                    if partial and partial != last_partial:
                        log.info("[%s] partial: %r", client, partial)
                        last_partial = partial
                        await ws.send(partial_raw)
                continue

            # Text control frame
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
                    client, sample_rate, f"{len(grammar)} phrases" if grammar else "none",
                )
                continue

    except websockets.ConnectionClosed as e:
        log.info("[%s] disconnected (%s)", client, e.code)
    except Exception:
        log.exception("[%s] handler crashed", client)


async def main():
    log.info("listening on ws://%s:%d", HOST, PORT)
    async with websockets.serve(
        recognize,
        HOST,
        PORT,
        max_size=8 * 1024 * 1024,
        ping_interval=20,
        ping_timeout=20,
    ):
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    asyncio.run(main())
