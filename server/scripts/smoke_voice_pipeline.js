/*
 * Smoke test: drives whisperClient + kalaamMatcher with a real audio file
 * against a synthetic kalaam. Validates the same code paths the
 * /voice-chunk route hits, without needing Mongo, JWTs, or sockets.
 *
 * Run:
 *   node scripts/smoke_voice_pipeline.js /tmp/multi.aiff
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { transcribeChunk, health } = require('../services/whisperClient');
const { matchTranscriptToKalaam } = require('../services/kalaamMatcher');

const audioPath = process.argv[2];
if (!audioPath || !fs.existsSync(audioPath)) {
  console.error('usage: node scripts/smoke_voice_pipeline.js <audio-file>');
  process.exit(1);
}

const fakeKalaam = {
  title: 'Aye Mere Sher Abbas',
  content: [
    {
      stanzaNumber: 0,
      lines: [
        'عباس تیرے در سا دنیا میں در کہاں',
        'روکے زینب نے کہا اے میرے شیر عباس',
      ],
    },
    {
      stanzaNumber: 1,
      lines: [
        'پانی کے واسطے فرات کنارے گئے',
        'دشمنوں کے تیر کھائے میرے جان نثار',
      ],
    },
  ],
};

const promptText = fakeKalaam.content
  .map((s) => s.lines.join(' '))
  .join(' ');

(async () => {
  console.log('1. Whisper service health:');
  console.log('  ', await health());

  const audioBuffer = fs.readFileSync(audioPath);
  console.log(`\n2. Transcribing ${path.basename(audioPath)} (${audioBuffer.length} bytes)...`);

  const t0 = Date.now();
  const r = await transcribeChunk({
    audioBuffer,
    filename: path.basename(audioPath),
    language: 'ur',
    initialPrompt: promptText,
  });
  const elapsed = Date.now() - t0;

  console.log(`   transcript (${elapsed}ms): "${r.text}"`);
  console.log(`   lang=${r.language} prob=${r.language_probability} segments=${r.segments.length}`);
  for (const s of r.segments) {
    console.log(`   - [${s.start}–${s.end}] logprob=${s.avg_logprob} ns_prob=${s.no_speech_prob}`);
  }

  console.log('\n3. Fuzzy matching against kalaam:');
  const m = matchTranscriptToKalaam(r.text, fakeKalaam, {
    minScore: 0.4,
    fromStanza: 0,
    fromLine: 0,
    windowSize: 6,
  });
  console.log('  ', m);

  if (m) {
    console.log(`\n✅ Would broadcast session:stanzaChanged { stanza: ${m.stanza}, line: ${m.line} }`);
  } else {
    console.log('\n⚠️ No match — would NOT broadcast (transcript too noisy)');
  }
})().catch((e) => {
  console.error('SMOKE FAIL:', e.message);
  process.exit(1);
});
