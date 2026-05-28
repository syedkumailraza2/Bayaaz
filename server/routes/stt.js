const express = require('express');
const router = express.Router();
const multer = require('multer');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
});

const WHISPER_HTTP_URL =
  process.env.WHISPER_HTTP_URL || 'http://127.0.0.1:5002';
const WHISPER_TIMEOUT_MS = parseInt(process.env.WHISPER_TIMEOUT_MS || '60000', 10);

// POST /api/stt/transcribe
// Multipart body:  audio — WAV file (16kHz mono 16-bit PCM)
// Returns: { transcript: "..." }
router.post('/transcribe', upload.single('audio'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No audio provided' });

  // Use native FormData + Blob (Node 18+) so the multipart boundary is set
  // automatically — the form-data npm package conflicts with native fetch.
  const form = new FormData();
  form.append(
    'audio',
    new Blob([req.file.buffer], { type: 'audio/wav' }),
    'recording.wav',
  );
  // Forward the hint if provided — Whisper uses it as initial_prompt to bias
  // output toward Roman Urdu rather than English translation or Arabic script.
  if (req.body.hint) form.append('hint', req.body.hint);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), WHISPER_TIMEOUT_MS);

  try {
    const response = await fetch(`${WHISPER_HTTP_URL}/transcribe`, {
      method: 'POST',
      body: form,
      signal: controller.signal,
    });
    clearTimeout(timer);

    if (!response.ok) {
      const text = await response.text();
      return res.status(502).json({ error: `Whisper error: ${text}` });
    }

    const data = await response.json();
    return res.json({ transcript: data.transcript ?? '' });
  } catch (err) {
    clearTimeout(timer);
    if (err.name === 'AbortError') {
      return res.status(504).json({ error: 'Whisper timed out' });
    }
    console.error('[stt] error:', err.message);
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
