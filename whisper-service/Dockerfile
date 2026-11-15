# Bayaaz STT (Vosk) — runs on x86_64 and ARM64 (Oracle Ampere A1).

# ── Stage 1: download the model (cached unless fetch-models.sh changes) ──────
FROM python:3.12-slim AS model
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl unzip ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY scripts/fetch-models.sh scripts/
RUN bash scripts/fetch-models.sh

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM python:3.12-slim
# libvosk.so links libatomic on ARM64; slim images don't ship it.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libatomic1 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --from=model /app/vosk-model-small-hi-0.22 /app/model
COPY vosk_service.py .

ENV VOSK_MODEL_PATH=/app/model \
    DISABLE_KEEP_ALIVE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5001/health', timeout=3)"

# One process on purpose: decoding is multi-threaded inside it (STT_THREADS),
# and extra uvicorn workers would each load another copy of the model.
CMD ["uvicorn", "vosk_service:app", "--host", "0.0.0.0", "--port", "5001", \
     "--ws-max-size", "8388608", "--proxy-headers", "--forwarded-allow-ips", "*"]
