// Fuzzy matcher: given a Whisper transcript and a kalaam's stanza/line
// structure, find the line whose words best overlap the transcript.
// Strategy: normalize both sides to a stream of "key tokens", compute
// per-line scores, return the best with a confidence number.

// Urdu/Arabic-script letters mapped to a rough Latin equivalent. Whisper often
// transliterates Urdu speech to Roman Latin (e.g. "Mere Sher Abbaas") while the
// stored kalaam is in Arabic script — this table puts both into a common space.
// Short vowels are unwritten in Urdu, so the Latin we produce here is consonant-
// heavy; the matcher's Levenshtein tolerance absorbs the remaining vowel drift.
const URDU_TO_LATIN = {
  'ا': 'a', 'ب': 'b', 'پ': 'p', 'ت': 't', 'ٹ': 't', 'ث': 's',
  'ج': 'j', 'چ': 'ch', 'ح': 'h', 'خ': 'kh', 'د': 'd', 'ڈ': 'd',
  'ذ': 'z', 'ر': 'r', 'ڑ': 'r', 'ز': 'z', 'ژ': 'zh', 'س': 's',
  'ش': 'sh', 'ص': 's', 'ض': 'z', 'ط': 't', 'ظ': 'z', 'ع': 'a',
  'غ': 'gh', 'ف': 'f', 'ق': 'q', 'ک': 'k', 'ك': 'k', 'گ': 'g',
  'ل': 'l', 'م': 'm', 'ن': 'n', 'ں': 'n', 'و': 'o', 'ہ': 'h',
  'ھ': 'h', 'ۂ': 'h', 'ۃ': 'h', 'ء': '', 'ئ': 'y', 'ؤ': 'o',
  'ی': 'y', 'ے': 'e',
};

function transliterateUrdu(s) {
  let out = '';
  for (const ch of s) {
    out += URDU_TO_LATIN[ch] ?? ch;
  }
  return out;
}

// Devanagari (Hindi) → Latin. Needed because Vosk's Hindi model is the best
// open-source phonetic match for spoken Urdu, but it outputs Devanagari. The
// kalaam is stored in Arabic script and/or romanized Latin; this table puts
// Vosk's output into the same Latin space. We deliberately map the long vowel
// matra "ा" to single 'a' (not 'aa') to better match romanizations like
// "raat" → "rat" — the consonant-skeleton fallback absorbs the vowel drift.
const DEVANAGARI_TO_LATIN = {
  // Consonants
  'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'n',
  'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'n',
  'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
  'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
  'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
  'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'w',
  'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
  // Nukta variants (Urdu-origin sounds in Devanagari)
  'क़': 'q', 'ख़': 'kh', 'ग़': 'gh', 'ज़': 'z', 'ड़': 'r', 'ढ़': 'r', 'फ़': 'f',
  // Independent vowels
  'अ': 'a', 'आ': 'a', 'इ': 'i', 'ई': 'i', 'उ': 'u', 'ऊ': 'u',
  'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au', 'ऋ': 'r',
  // Vowel signs (matras)
  'ा': 'a', 'ि': 'i', 'ी': 'i', 'ु': 'u', 'ू': 'u',
  'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', 'ृ': 'r',
  // Modifiers
  'ं': 'n', 'ः': 'h', 'ँ': 'n',
  // Halant / nukta / avagraha — strip (silent / combiner)
  '्': '', '़': '', 'ऽ': '',
  // Digits (occasionally appear in transcripts)
  '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
  '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
};

function transliterateDevanagari(s) {
  let out = '';
  for (const ch of s) {
    out += DEVANAGARI_TO_LATIN[ch] ?? ch;
  }
  return out;
}

// Strip diacritics, kashidas, punctuation; transliterate Urdu→Latin so Whisper's
// romanized output and Arabic-script kalaam content meet in the same space;
// lowercase; collapse spaces.
function normalize(input) {
  if (!input) return '';
  let s = String(input);
  // Arabic diacritics (fatha/kasra/damma/etc.) and tatweel — drop before
  // transliteration so they don't leak through.
  s = s.replace(/[ً-ْٰـ]/g, '');
  // Normalize alif variants and ya/teh-marbuta variants first so the
  // transliteration table sees canonical letters.
  s = s.replace(/[آإأٱ]/g, 'ا');
  s = s.replace(/[يى]/g, 'ی');
  s = s.replace(/ة/g, 'ہ');
  // Transliterate Urdu (Arabic-script) and Hindi (Devanagari) to a Latin
  // approximation. Latin chars pass through unchanged; this is a no-op for
  // already-Roman transcripts. Order doesn't matter — the two ranges are
  // disjoint, so each pass only touches its own characters.
  s = transliterateUrdu(s);
  s = transliterateDevanagari(s);
  s = s.toLowerCase();
  // Punctuation + symbols (incl. Arabic question/comma)
  s = s.replace(/[.,!?;:"'`~()\[\]{}<>\-—_/\\|@#$%^&*+=۔،؟]/g, ' ');
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

// Strip short vowels (a/e/i/o/u). Whisper's Urdu transliteration drops them
// (since Urdu script doesn't write short vowels), so kalaam text "besar" and
// transliterated "bysr" share no characters under raw Levenshtein but agree
// on the consonant skeleton "bsr"/"bysr". Compare on the skeleton as a
// fallback after the strict checks.
function consonantSkeleton(s) {
  return s.replace(/[aeiou]/g, '');
}

function tokenMatch(a, b) {
  if (a === b) return true;
  const maxLen = Math.max(a.length, b.length);
  if (maxLen <= 2) return a === b;
  if (a.startsWith(b) || b.startsWith(a)) {
    const minLen = Math.min(a.length, b.length);
    // Both tokens must carry real information. 2-char tokens ("ka", "ho")
    // matching 5+ char tokens via prefix were a major false-positive source.
    if (minLen >= 3 && maxLen >= 4) return true;
  }
  const tol = Math.min(2, Math.floor(maxLen / 4));
  if (levenshtein(a, b) <= tol) return true;
  // Consonant-skeleton fallback for whisper's vowel-light Urdu romanizations.
  // Allow short skeletons too (≥2) — the strict 0.75 global score floor at
  // the matcher level keeps false-positive cross-stanza jumps in check.
  const ac = consonantSkeleton(a);
  const bc = consonantSkeleton(b);
  if (ac.length >= 2 && bc.length >= 2) {
    if (ac === bc) return true;
    if (ac.startsWith(bc) || bc.startsWith(ac)) return true;
    const cTol = Math.min(2, Math.floor(Math.max(ac.length, bc.length) / 3));
    if (levenshtein(ac, bc) <= cTol) return true;
  }
  return false;
}

// Build a flat list of lines with their (stanza, line) coords.
// IMPORTANT: stanza is the *array index* (0-based), not stanza.stanzaNumber,
// because the Flutter client uses the array index when rendering (see
// _adoptKalam in group_session_teleprompter.dart). Returning stanzaNumber
// here caused the client to highlight the wrong stanza when stanzaNumber
// didn't equal the array index (e.g., 1-indexed stanzaNumber 1..N vs
// 0-indexed sIdx 0..N-1). Host-tap already sends the array index, so this
// keeps voice and tap paths aligned.
function flattenKalaam(kalaam) {
  const out = [];
  if (!kalaam || !Array.isArray(kalaam.content)) return out;
  kalaam.content.forEach((stanza, sIdx) => {
    (stanza.lines || []).forEach((line, lIdx) => {
      out.push({
        stanza: sIdx,
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

  // Each kalaam line is a full bayt (~12-16 tokens) but a 3s recitation chunk
  // is only 3-5 tokens. Dividing by `max(transcript,line)` underscores correct
  // matches against long lines. Use `min` so the score reflects how much of
  // the *shorter* side matched, but require at least 2 hits to suppress
  // single-token false positives.
  if (hits < 2) return 0;
  const base = hits / Math.min(transcriptTokens.length, lineTokens.length);
  const runBonus = (maxRun / Math.max(transcriptTokens.length, 1)) * 0.15;
  return Math.min(1, base + runBonus);
}

// Main entry. Returns:
//   { stanza, line, score, matchedText, transcript } or null if no match
function matchTranscriptToKalaam(transcript, kalaam, {
  minScore = 0.4,
  advanceScore = null,   // minimum raw score required to advance to next line
  advanceMargin = 0.15,  // next line must beat current by at least this much
  fromStanza = null,
  fromLine = null,
  windowSize = 6,
} = {}) {
  const tTokens = tokens(transcript);
  if (tTokens.length === 0) return null;

  const flat = flattenKalaam(kalaam);
  if (flat.length === 0) return null;

  // Resolve start index
  let startIdx = 0;
  if (fromStanza != null && fromLine != null) {
    const idx = flat.findIndex(
      (l) => l.stanza === fromStanza && l.line === fromLine
    );
    if (idx >= 0) startIdx = idx;
  }

  // Use a higher bar to advance than to stay — prevents jumping ahead too early.
  const advThreshold = advanceScore ?? minScore + 0.15;

  const curScore = scoreLine(tTokens, flat[startIdx].tokens);
  const nxtIdx = startIdx + 1 < flat.length ? startIdx + 1 : null;
  const nxtScore = nxtIdx != null ? scoreLine(tTokens, flat[nxtIdx].tokens) : 0;

  let candidate;

  if (nxtIdx != null && nxtScore >= advThreshold && nxtScore >= curScore + advanceMargin) {
    // Next line passes the advance bar and clearly beats current → advance by 1
    candidate = { idx: nxtIdx, score: nxtScore };
  } else if (curScore >= minScore) {
    // Current line is good enough → stay
    candidate = { idx: startIdx, score: curScore };
  } else {
    // Neither current nor next matches — cursor has fallen behind.
    // Scan forward (nearest first) and take the first line that clears advThreshold.
    candidate = null;
    const catchUpEnd = Math.min(flat.length, startIdx + windowSize + 1);
    for (let i = startIdx + 2; i < catchUpEnd; i++) {
      const s = scoreLine(tTokens, flat[i].tokens);
      if (s >= advThreshold) {
        candidate = { idx: i, score: s };
        break;
      }
    }
    if (!candidate) return null;
  }

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
