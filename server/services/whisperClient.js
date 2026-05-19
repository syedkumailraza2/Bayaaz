const axios = require('axios');
const FormData = require('form-data');

const WHISPER_URL = process.env.WHISPER_URL || 'http://127.0.0.1:5001';
const WHISPER_SECRET = process.env.WHISPER_SHARED_SECRET || '';
const WHISPER_TIMEOUT_MS = parseInt(process.env.WHISPER_TIMEOUT_MS || '15000', 10);

// Transcribe a single audio chunk by proxying to the Python service.
// `audioBuffer` is a Node Buffer of raw uploaded bytes.
// `initialPrompt` is the kalaam text (biases recognition toward known words).
async function transcribeChunk({
  audioBuffer,
  filename = 'chunk.m4a',
  language = 'ur',
  initialPrompt,
}) {
  const form = new FormData();
  form.append('audio', audioBuffer, { filename });
  form.append('language', language);
  if (initialPrompt) form.append('initial_prompt', initialPrompt);

  const headers = form.getHeaders();
  if (WHISPER_SECRET) headers['X-Whisper-Secret'] = WHISPER_SECRET;

  const { data } = await axios.post(`${WHISPER_URL}/transcribe`, form, {
    headers,
    timeout: WHISPER_TIMEOUT_MS,
    maxBodyLength: 25 * 1024 * 1024,
    maxContentLength: 25 * 1024 * 1024,
  });
  return data;
}

async function health() {
  const { data } = await axios.get(`${WHISPER_URL}/health`, { timeout: 2000 });
  return data;
}

module.exports = { transcribeChunk, health };
