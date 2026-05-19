// Fuzzy matcher: given a Whisper transcript and a kalaam's stanza/line
// structure, find the line whose words best overlap the transcript.
// Strategy: normalize both sides to a stream of "key tokens", compute
// per-line scores, return the best with a confidence number.

// Strip diacritics, kashidas, punctuation; lowercase Latin; collapse spaces.
function normalize(input) {
  if (!input) return '';
  let s = String(input).toLowerCase();
  // Arabic diacritics (fatha/kasra/damma/etc.) and tatweel
  s = s.replace(/[ً-ْٰـ]/g, '');
  // Punctuation + symbols (incl. Arabic question/comma)
  s = s.replace(/[.,!?;:"'`~()\[\]{}<>\-—_/\\|@#$%^&*+=۔،؟]/g, ' ');
  // Normalize alif variants and ya/teh-marbuta variants
  s = s.replace(/[آإأٱ]/g, 'ا');
  s = s.replace(/[يى]/g, 'ی');
  s = s.replace(/ة/g, 'ہ');
  // Collapse whitespace
  return s.replace(/\s+/g, ' ').trim();
}

function tokens(s) {
  const n = normalize(s);
  if (!n) return [];
  return n.split(' ').filter((w) => w.length >= 2);
}

// Levenshtein for short token comparisons
function levenshtein(a, b) {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  const m = a.length;
  const n = b.length;
  let prev = new Array(n + 1);
  let cur = new Array(n + 1);
  for (let j = 0; j <= n; j++) prev[j] = j;
  for (let i = 1; i <= m; i++) {
    cur[0] = i;
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
    }
    [prev, cur] = [cur, prev];
  }
  return prev[n];
}

function tokenMatch(a, b) {
  if (a === b) return true;
  const maxLen = Math.max(a.length, b.length);
  if (maxLen <= 2) return a === b;
  if (a.startsWith(b) || b.startsWith(a)) {
    const minLen = Math.min(a.length, b.length);
    if (minLen >= 2) return true;
  }
  const tol = Math.min(2, Math.floor(maxLen / 4));
  return levenshtein(a, b) <= tol;
}

// Build a flat list of lines with their (stanza, line) coords.
function flattenKalaam(kalaam) {
  const out = [];
  if (!kalaam || !Array.isArray(kalaam.content)) return out;
  kalaam.content.forEach((stanza, sIdx) => {
    const stanzaNumber = typeof stanza.stanzaNumber === 'number' ? stanza.stanzaNumber : sIdx;
    (stanza.lines || []).forEach((line, lIdx) => {
      out.push({
        stanza: stanzaNumber,
        line: lIdx,
        tokens: tokens(line),
        text: line,
      });
    });
  });
  return out;
}

// Score: fraction of transcript tokens that appear in the line tokens
// (in any order), plus a small bonus for in-order contiguous matches.
function scoreLine(transcriptTokens, lineTokens) {
  if (!transcriptTokens.length || !lineTokens.length) return 0;
  let hits = 0;
  let inOrderRun = 0;
  let maxRun = 0;
  let lineCursor = 0;
  const consumed = new Array(lineTokens.length).fill(false);

  for (const t of transcriptTokens) {
    let found = false;
    for (let j = lineCursor; j < lineTokens.length; j++) {
      if (!consumed[j] && tokenMatch(t, lineTokens[j])) {
        consumed[j] = true;
        hits++;
        if (j === lineCursor) {
          inOrderRun++;
          maxRun = Math.max(maxRun, inOrderRun);
          lineCursor = j + 1;
        } else {
          inOrderRun = 1;
        }
        found = true;
        break;
      }
    }
    if (!found) {
      // try anywhere (out of order)
      for (let j = 0; j < lineCursor; j++) {
        if (!consumed[j] && tokenMatch(t, lineTokens[j])) {
          consumed[j] = true;
          hits++;
          inOrderRun = 0;
          found = true;
          break;
        }
      }
    }
    if (!found) inOrderRun = 0;
  }

  const base = hits / Math.max(transcriptTokens.length, lineTokens.length);
  const runBonus = (maxRun / Math.max(transcriptTokens.length, 1)) * 0.15;
  return Math.min(1, base + runBonus);
}

// Main entry. Returns:
//   { stanza, line, score, matchedText, transcript } or null if no match
function matchTranscriptToKalaam(transcript, kalaam, {
  minScore = 0.4,
  // Restrict search to a window around the previously known line, plus a
  // global fallback. Pass -1 to disable.
  fromStanza = null,
  fromLine = null,
  windowSize = 6,
} = {}) {
  const tTokens = tokens(transcript);
  if (tTokens.length === 0) return null;

  const flat = flattenKalaam(kalaam);
  if (flat.length === 0) return null;

  // Resolve start index for window search
  let startIdx = 0;
  if (fromStanza != null && fromLine != null) {
    const idx = flat.findIndex(
      (l) => l.stanza === fromStanza && l.line === fromLine
    );
    if (idx >= 0) startIdx = idx;
  }

  const tryRange = (lo, hi) => {
    let best = null;
    for (let i = lo; i < hi; i++) {
      const s = scoreLine(tTokens, flat[i].tokens);
      if (!best || s > best.score) {
        best = { idx: i, score: s };
      }
    }
    return best;
  };

  // 1) windowed search first
  let candidate = null;
  if (windowSize > 0) {
    const lo = Math.max(0, startIdx - 1);
    const hi = Math.min(flat.length, startIdx + windowSize + 1);
    candidate = tryRange(lo, hi);
  }

  // 2) global fallback if window result is weak
  if (!candidate || candidate.score < minScore) {
    const global = tryRange(0, flat.length);
    if (!candidate || (global && global.score > candidate.score)) {
      candidate = global;
    }
  }

  if (!candidate || candidate.score < minScore) return null;

  const m = flat[candidate.idx];
  return {
    stanza: m.stanza,
    line: m.line,
    score: Number(candidate.score.toFixed(3)),
    matchedText: m.text,
    transcript,
  };
}

module.exports = {
  matchTranscriptToKalaam,
  // exported for tests
  _normalize: normalize,
  _tokens: tokens,
  _flattenKalaam: flattenKalaam,
};
