#!/usr/bin/env bash
# Downloads model weights at build time so the first request after a
# cold start doesn't have to fetch them. Render's free tier has no
# persistent disk, so this runs on every fresh deploy.
set -euo pipefail

cd "$(dirname "$0")/.."

# ── Vosk model ───────────────────────────────────────────────────────────────
VOSK_MODEL_NAME="${VOSK_MODEL_NAME:-vosk-model-small-hi-0.22}"
VOSK_MODEL_URL="${VOSK_MODEL_URL:-https://alphacephei.com/vosk/models/${VOSK_MODEL_NAME}.zip}"

if [ ! -d "${VOSK_MODEL_NAME}" ]; then
  echo "→ fetching Vosk model ${VOSK_MODEL_NAME}"
  curl -fsSL -o vosk-model.zip "${VOSK_MODEL_URL}"
  unzip -q vosk-model.zip
  rm vosk-model.zip
else
  echo "→ Vosk model ${VOSK_MODEL_NAME} already present"
fi

# `vosk_service.py` reads VOSK_MODEL_PATH; this is the default it points at.
ln -sfn "${VOSK_MODEL_NAME}" model

# Vosk now serves both /ws and /transcribe — no Whisper weights to prefetch.
echo "✓ models ready"
