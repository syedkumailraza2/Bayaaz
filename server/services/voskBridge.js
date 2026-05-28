// Per-socket bridge to the Vosk WebSocket service.
//
// Flutter host streams raw 16-bit PCM frames over socket.io. For each
// host socket we open a dedicated WebSocket to Vosk, forward frames, and
// pipe partial+final transcripts through the fuzzy matcher. When the
// matcher confidently lands on a new (stanza, line) we broadcast
// `session:stanzaChanged` to the room — same downstream event the chunked
// upload path used, so members see no protocol change.

const WebSocket = require('ws');
const Session = require('../model/Session');
const Kalaam = require('../model/Kalaam');
const { splitKalaamHemistichs } = require('./hemistichSplit');
const { matchTranscriptToKalaam, _tokens } = require('./kalaamMatcher');

const VOSK_URL = process.env.VOSK_URL || 'ws://127.0.0.1:5001';
const SAMPLE_RATE = parseInt(process.env.VOSK_SAMPLE_RATE || '16000', 10);

// Persist cursor at most this often per session — every frame would hammer Mongo.
const VOICE_SAVE_INTERVAL_MS = 1500;
const _lastVoiceSaveAt = new Map();

// Per-socket bridge state.
// { ws, sessionId, kalaam, cursorStanza, cursorLine, lastEmittedKey }
const bridges = new Map();

function logTag(socketId, scopeId) {
  return `[vosk-bridge socket=${socketId.slice(0, 6)} scope=${String(scopeId).slice(-6)}]`;
}

// Build a closed-vocabulary grammar list from the kalaam tokens. Vosk
// uses this to constrain the decoder — much higher accuracy than open
// recognition when we know what the host is reading.
function grammarFromKalaam(kalaam) {
  const seen = new Set();
  (kalaam.content || []).forEach((stanza) => {
    (stanza.lines || []).forEach((line) => {
      _tokens(line).forEach((t) => seen.add(t));
    });
  });
  // Empty grammar means open recognition — only send a grammar when we
  // have enough vocabulary to be useful.
  return seen.size >= 4 ? Array.from(seen) : null;
}

// Shared bridge setup. The session-based path broadcasts cursor changes to
// the session room and persists them to Mongo. The solo path emits cursor
// changes only back to the calling socket (no session, no persistence) —
// it powers the single-user follow-my-voice teleprompter.
function _openBridge(socket, kalaam, scopeId, tag, onMatch) {
  const ws = new WebSocket(VOSK_URL);
  const state = {
    ws,
    scopeId,
    kalaam,
    cursorStanza: 0,
    cursorLine: 0,
    lastEmittedKey: '0:0',
    framesIn: 0,
    bytesIn: 0,
  };
  bridges.set(socket.id, state);

  ws.on('open', () => {
    console.log(`${tag} opened`);
    ws.send(JSON.stringify({ config: { sample_rate: SAMPLE_RATE } }));
    socket.emit('voice:ready', {});
  });

  ws.on('message', (raw) => {
    let data;
    try {
      data = JSON.parse(raw.toString());
    } catch {
      return;
    }
    const isFinal = typeof data.text === 'string';
    const text = (isFinal ? data.text : data.partial || '').trim();
    if (!text) return;

    const match = matchTranscriptToKalaam(text, state.kalaam, {
      minScore: isFinal ? 0.35 : 0.3,
      // Partials are noisier — require a stronger signal to advance.
      advanceScore: isFinal ? 0.50 : 0.55,
      advanceMargin: 0.15,
      fromStanza: state.cursorStanza,
      fromLine: state.cursorLine,
      windowSize: 6,
    });
    if (!match) {
      console.log(`${tag} ${isFinal ? 'final' : 'partial'} %j → no match`, text);
      return;
    }

    const key = `${match.stanza}:${match.line}`;
    if (key === state.lastEmittedKey) return;
    state.lastEmittedKey = key;
    state.cursorStanza = match.stanza;
    state.cursorLine = match.line;

    console.log(
      `${tag} ${isFinal ? 'final' : 'partial'} %j → (%d,%d) score=%s "%s"`,
      text, match.stanza, match.line, match.score, match.matchedText,
    );

    onMatch(match, isFinal);
  });

  ws.on('close', (code, reason) => {
    console.log(`${tag} closed code=%s reason=%s frames=%d bytes=%d`,
      code, reason?.toString() || '', state.framesIn, state.bytesIn);
    if (bridges.get(socket.id) === state) bridges.delete(socket.id);
  });

  ws.on('error', (err) => {
    console.error(`${tag} ws error:`, err.message);
    socket.emit('voice:error', { message: err.message });
  });

  return state;
}

async function startBridge(socket, io, sessionId, userId) {
  await stopBridge(socket);

  const session = await Session.findById(sessionId)
    .populate('currentKalamId', 'title content');
  if (!session) {
    socket.emit('voice:error', { message: 'Session not found' });
    return;
  }
  if (session.hostId.toString() !== userId) {
    socket.emit('voice:error', { message: 'Host only' });
    return;
  }
  if (!session.currentKalamId) {
    socket.emit('voice:error', { message: 'No current kalaam set' });
    return;
  }

  const kalaam = splitKalaamHemistichs(session.currentKalamId);
  const tag = logTag(socket.id, sessionId);

  const state = _openBridge(socket, kalaam, sessionId, tag, (match) => {
    io.to('session:' + sessionId).emit('session:stanzaChanged', {
      stanza: match.stanza,
      line: match.line,
    });

    const last = _lastVoiceSaveAt.get(sessionId) || 0;
    if (Date.now() - last >= VOICE_SAVE_INTERVAL_MS) {
      _lastVoiceSaveAt.set(sessionId, Date.now());
      Session.updateOne(
        { _id: sessionId },
        { currentStanza: match.stanza, currentLine: match.line }
      ).catch((err) => console.error(`${tag} persist failed:`, err.message));
    }
  });

  state.cursorStanza = session.currentStanza;
  state.cursorLine = session.currentLine;
  state.lastEmittedKey = `${session.currentStanza}:${session.currentLine}`;
}

// Solo (no session) follow-my-voice bridge. The Flutter practice screen
// streams PCM the same way, but cursor matches go straight back to the
// caller as `voice:soloStanzaChanged` instead of being broadcast to a room.
async function startSoloBridge(socket, kalaamId, userId) {
  await stopBridge(socket);

  if (!userId) {
    socket.emit('voice:error', { message: 'Not authenticated' });
    return;
  }
  if (!kalaamId) {
    socket.emit('voice:error', { message: 'kalaamId required' });
    return;
  }

  const kalaamDoc = await Kalaam.findById(kalaamId).select('title content');
  if (!kalaamDoc) {
    socket.emit('voice:error', { message: 'Kalaam not found' });
    return;
  }

  // Do NOT split hemistichs here — the practice screen renders the kalaam
  // from the regular kalaams API which doesn't apply the split. Keeping
  // the structure identical keeps the (stanza, line) coordinates the
  // matcher emits aligned with the client's flat _LineItem list.
  const kalaam = typeof kalaamDoc.toObject === 'function'
    ? kalaamDoc.toObject()
    : kalaamDoc;
  const tag = logTag(socket.id, kalaamId);

  _openBridge(socket, kalaam, kalaamId, tag, (match) => {
    socket.emit('voice:soloStanzaChanged', {
      stanza: match.stanza,
      line: match.line,
    });
  });
}

function pushFrame(socket, frame) {
  const state = bridges.get(socket.id);
  if (!state) return;
  if (state.ws.readyState !== WebSocket.OPEN) return;
  // socket.io delivers binary as Buffer in Node — pass through as-is.
  state.ws.send(frame);
  state.framesIn += 1;
  state.bytesIn += frame.length || 0;
}

async function stopBridge(socket) {
  const state = bridges.get(socket.id);
  if (!state) return;
  bridges.delete(socket.id);
  try {
    if (state.ws.readyState === WebSocket.OPEN) {
      state.ws.send(JSON.stringify({ eof: 1 }));
      // Give Vosk ~250ms to emit its FinalResult before we close.
      setTimeout(() => {
        try { state.ws.close(); } catch {}
      }, 250);
    } else {
      try { state.ws.close(); } catch {}
    }
  } catch {}
}

module.exports = { startBridge, startSoloBridge, pushFrame, stopBridge };
