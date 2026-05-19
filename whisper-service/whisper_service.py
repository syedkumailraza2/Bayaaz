import io
import logging
import multiprocessing
import os

from flask import Flask, abort, jsonify, request
from faster_whisper import WhisperModel

MODEL_SIZE = os.getenv("WHISPER_MODEL", "small")
DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
DEFAULT_LANGUAGE = os.getenv("WHISPER_LANGUAGE", "ur")
SHARED_SECRET = os.getenv("WHISPER_SHARED_SECRET", "")
CPU_THREADS = int(
    os.getenv("WHISPER_CPU_THREADS", str(multiprocessing.cpu_count()))
)
MAX_UPLOAD_MB = int(os.getenv("WHISPER_MAX_UPLOAD_MB", "10"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("whisper")

log.info(
    "loading model=%s device=%s compute_type=%s cpu_threads=%d",
    MODEL_SIZE, DEVICE, COMPUTE_TYPE, CPU_THREADS,
)
model = WhisperModel(
    MODEL_SIZE,
    device=DEVICE,
    compute_type=COMPUTE_TYPE,
    cpu_threads=CPU_THREADS,
    num_workers=1,
)
log.info("model ready")

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = MAX_UPLOAD_MB * 1024 * 1024


@app.before_request
def auth_check():
    if request.path == "/health":
        return
    if not SHARED_SECRET:
        return
    if request.headers.get("X-Whisper-Secret", "") != SHARED_SECRET:
        abort(401)


@app.route("/health", methods=["GET"])
def health():
    return jsonify(
        {
            "status": "ok",
            "model": MODEL_SIZE,
            "device": DEVICE,
            "compute_type": COMPUTE_TYPE,
            "cpu_threads": CPU_THREADS,
        }
    )


@app.route("/transcribe", methods=["POST"])
def transcribe():
    if "audio" not in request.files:
        return jsonify({"success": False, "error": "missing audio file"}), 400

    audio_file = request.files["audio"]
    language = request.form.get("language", DEFAULT_LANGUAGE)
    beam_size = int(request.form.get("beam_size", "5"))
    use_vad = request.form.get("vad", "true").lower() == "true"
    initial_prompt = request.form.get("initial_prompt") or None

    audio_bytes = audio_file.read()
    if not audio_bytes:
        return jsonify({"success": False, "error": "empty audio"}), 400

    audio_io = io.BytesIO(audio_bytes)

    try:
        kwargs = {"language": language, "beam_size": beam_size}
        if initial_prompt:
            kwargs["initial_prompt"] = initial_prompt
        if use_vad:
            kwargs["vad_filter"] = True
            kwargs["vad_parameters"] = {"min_silence_duration_ms": 400}

        segments, info = model.transcribe(audio_io, **kwargs)

        seg_list = []
        text_parts = []
        for s in segments:
            text = s.text.strip()
            seg_list.append(
                {
                    "start": round(s.start, 3),
                    "end": round(s.end, 3),
                    "text": text,
                    "avg_logprob": round(s.avg_logprob, 3),
                    "no_speech_prob": round(s.no_speech_prob, 3),
                }
            )
            if text:
                text_parts.append(text)

        return jsonify(
            {
                "success": True,
                "text": " ".join(text_parts),
                "language": info.language,
                "language_probability": round(info.language_probability, 3),
                "duration": round(info.duration, 3),
                "segments": seg_list,
            }
        )
    except Exception as e:
        log.exception("transcribe failed")
        return jsonify({"success": False, "error": str(e)}), 500


if __name__ == "__main__":
    host = os.getenv("WHISPER_HOST", "127.0.0.1")
    port = int(os.getenv("WHISPER_PORT", "5001"))
    app.run(host=host, port=port, debug=False, threaded=False)
