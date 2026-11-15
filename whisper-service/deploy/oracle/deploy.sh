#!/usr/bin/env bash
# Deploy / update the STT service on the Oracle VM. Run FROM YOUR MAC:
#   whisper-service/deploy/oracle/deploy.sh ubuntu@<vm-ip> [stt.mybayaaz.com]
# First run creates the VM's .env with a random STT_TOKEN and prints it.
set -euo pipefail

HOST="${1:?usage: deploy.sh ubuntu@<vm-ip> [domain]}"
DOMAIN="${2:-stt.mybayaaz.com}"
SRC="$(cd "$(dirname "$0")/../.." && pwd)"   # whisper-service/
REMOTE_DIR="bayaaz-stt"

echo "→ syncing $SRC → $HOST:~/$REMOTE_DIR"
rsync -az --delete \
  --exclude venv --exclude .venv --exclude __pycache__ --exclude .cache \
  --exclude '*.gguf' --exclude 'vosk-model-*' --exclude model \
  --exclude '*.wav' --exclude '*.aiff' --exclude .DS_Store \
  --exclude deploy/oracle/.env \
  "$SRC/" "$HOST:$REMOTE_DIR/"

ssh "$HOST" bash -s -- "$REMOTE_DIR" "$DOMAIN" <<'REMOTE'
set -euo pipefail
cd "$1/deploy/oracle"
if [ ! -f .env ]; then
  TOKEN=$(openssl rand -hex 32)
  printf 'STT_DOMAIN=%s\nSTT_TOKEN=%s\n' "$2" "$TOKEN" > .env
  chmod 600 .env
  echo "→ created .env — STT_TOKEN=$TOKEN  (set this on Render too)"
fi
docker compose up -d --build
docker compose ps
REMOTE

echo "✓ deployed. Check: curl https://$DOMAIN/health"
