const express = require('express');
const mongoose = require('mongoose');
const multer = require('multer');
const Session = require('../model/Session');
const Group = require('../model/Group');
const Suggestion = require('../model/Suggestion');
const QueueSnapshot = require('../model/QueueSnapshot');
const Kalaam = require('../model/Kalaam');
const auth = require('../middleware/auth');
const { transcribeChunk } = require('../services/whisperClient');
const { matchTranscriptToKalaam } = require('../services/kalaamMatcher');

const router = express.Router();

// Voice-chunk uploads live in memory and stay small (<10MB / few-second clips).
const voiceUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

// Throttle DB persistence per session so high-rate voice updates don't hammer Mongo.
// Broadcasts are NOT throttled — they always fire.
const _lastVoiceSaveAt = new Map();
const VOICE_SAVE_INTERVAL_MS = 1000;

// Populate queueItems.kalaamId so clients receive the kalaam title/category
// inline with the queue without a second round-trip.
const QUEUE_ITEM_POPULATE = {
  path: 'queueItems.kalaamId',
  select: 'title category author poet',
};

function isHost(session, userId) {
  return session.hostId.toString() === userId;
}

// Re-emit the enriched queue to all room members after any queue mutation.
async function emitQueueUpdated(io, session) {
  if (!io) return;
  await session.populate(QUEUE_ITEM_POPULATE);
  io.to('session:' + session._id.toString()).emit('session:queueUpdated', {
    queueItems: session.queueItems,
    queue: session.queue, // legacy flat mirror
  });
}

// GET /api/sessions/:id — get full session detail
router.get('/:id', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id)
      .populate('currentKalamId', 'title category content poet author')
      .populate('queue', 'title category author')
      .populate(QUEUE_ITEM_POPULATE);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/kalam — set current kalam (host only)
router.patch('/:id/kalam', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const { kalamId } = req.body;
    session.currentKalamId = kalamId;
    session.currentStanza = 0;
    session.currentLine = 0;

    const queueIndex = session.queue.findIndex(q => q.toString() === kalamId);
    if (queueIndex !== -1) session.currentQueueIndex = queueIndex;

    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:kalamChanged', { kalamId });

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/stanza — update stanza/line position (host only)
router.patch('/:id/stanza', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const { stanza, line } = req.body;
    session.currentStanza = stanza;
    session.currentLine = line;
    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:stanzaChanged', { stanza, line });

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/sessions/:id/voice-chunk — host streams a short audio chunk;
// server transcribes via Whisper service, fuzzy-matches to the current
// kalaam's lines, broadcasts session:stanzaChanged, and persists cursor
// (throttled to 1/sec to spare Mongo).
//
// Multipart form fields:
//   audio       (file, required) — wav/m4a/ogg/etc., <10MB, a few seconds.
//   language    (optional, default 'ur')
//   min_score   (optional, default 0.4) — match confidence floor
//
// Response:
//   { ok, transcript, language_probability, match?: { stanza, line, score, matchedText }, advanced: bool }
router.post('/:id/voice-chunk', auth, voiceUpload.single('audio'), async (req, res) => {
  try {
    if (!req.file || !req.file.buffer || !req.file.buffer.length) {
      return res.status(400).json({ message: 'audio file required' });
    }

    const session = await Session.findById(req.params.id)
      .populate('currentKalamId', 'title content');
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });
    if (!session.currentKalamId) {
      return res.status(409).json({ message: 'No current kalaam set' });
    }

    const kalaam = session.currentKalamId;
    const language = req.body.language || 'ur';
    const minScore = parseFloat(req.body.min_score || '0.4');

    // Use the kalaam text as initial_prompt — biases Whisper toward known words.
    const promptText = (kalaam.content || [])
      .map((stanza) => (stanza.lines || []).join(' '))
      .join(' ')
      .slice(0, 1000); // Whisper prompt cap is ~224 tokens; keep generous slice.

    let transcription;
    try {
      transcription = await transcribeChunk({
        audioBuffer: req.file.buffer,
        filename: req.file.originalname || 'chunk.m4a',
        language,
        initialPrompt: promptText,
      });
    } catch (err) {
      console.error('[voice-chunk] whisper error:', err.message);
      return res.status(502).json({ message: 'Whisper service unavailable', error: err.message });
    }

    if (!transcription.success || !transcription.text) {
      return res.json({ ok: true, transcript: '', language_probability: transcription.language_probability ?? 0, advanced: false });
    }

    // Confidence gate: drop chunks the model itself isn't confident about.
    const worstSeg = (transcription.segments || []).reduce(
      (acc, s) => (acc == null || s.avg_logprob < acc ? s.avg_logprob : acc),
      null
    );
    const bestNoSpeech = (transcription.segments || []).reduce(
      (acc, s) => (acc == null || s.no_speech_prob < acc ? s.no_speech_prob : acc),
      null
    );
    const lowConfidence = worstSeg != null && worstSeg < -1.2;
    const isSilence = bestNoSpeech != null && bestNoSpeech > 0.7;
    if (lowConfidence || isSilence) {
      return res.json({
        ok: true,
        transcript: transcription.text,
        language_probability: transcription.language_probability,
        advanced: false,
        skipped: lowConfidence ? 'low_confidence' : 'silence',
      });
    }

    const match = matchTranscriptToKalaam(transcription.text, kalaam, {
      minScore,
      fromStanza: session.currentStanza,
      fromLine: session.currentLine,
      windowSize: 6,
    });

    let advanced = false;
    if (match && (match.stanza !== session.currentStanza || match.line !== session.currentLine)) {
      session.currentStanza = match.stanza;
      session.currentLine = match.line;
      advanced = true;

      // Broadcast immediately on every advance.
      const io = req.app.get('io');
      if (io) {
        io.to('session:' + req.params.id).emit('session:stanzaChanged', {
          stanza: match.stanza,
          line: match.line,
        });
      }

      // Persist at most once per VOICE_SAVE_INTERVAL_MS.
      const last = _lastVoiceSaveAt.get(req.params.id) || 0;
      if (Date.now() - last >= VOICE_SAVE_INTERVAL_MS) {
        _lastVoiceSaveAt.set(req.params.id, Date.now());
        await session.save();
      }
    }

    res.json({
      ok: true,
      transcript: transcription.text,
      language_probability: transcription.language_probability,
      match: match
        ? { stanza: match.stanza, line: match.line, score: match.score, matchedText: match.matchedText }
        : null,
      advanced,
    });
  } catch (err) {
    console.error('[voice-chunk] error:', err);
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/playstate — update play state (host only)
router.patch('/:id/playstate', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const { isPlaying } = req.body;
    session.isPlaying = isPlaying;
    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:playStateChanged', { isPlaying });

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/sessions/:id — end session (host only)
// Side effect: captures a QueueSnapshot of the final sorted queue so the
// group can "load previous queue" next session.
router.delete('/:id', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const sorted = session.sortedQueueItems();
    if (sorted.length > 0) {
      await QueueSnapshot.create({
        groupId: session.groupId,
        sessionId: session._id,
        items: sorted.map(i => i.kalaamId),
      });
    }

    session.isActive = false;
    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:ended', {});

    res.json({ message: 'Session ended' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/sessions/:id/queue — add kalam to queue (any group member)
// Adds as an enriched queueItem with addedBy + addedAt + empty votes.
router.post('/:id/queue', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const { kalamId } = req.body;
    const wasEmpty = session.queueItems.length === 0;
    const alreadyQueued = session.queueItems.some(i => i.kalaamId.toString() === kalamId);
    if (alreadyQueued) return res.status(400).json({ message: 'Already in queue' });

    session.queueItems.push({
      kalaamId,
      addedBy: req.user.id,
      addedAt: new Date(),
      votes: [],
      pinned: false,
      pinPosition: null,
    });

    if (wasEmpty && !session.currentKalamId) {
      session.currentKalamId = kalamId;
      session.currentStanza = 0;
      session.currentLine = 0;
    }

    await session.save();
    await session.populate(QUEUE_ITEM_POPULATE);

    const io = req.app.get('io');
    if (io) await emitQueueUpdated(io, session);

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/sessions/:id/queue/:kalamId — remove kalam from queue (host only)
router.delete('/:id/queue/:kalamId', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    session.queueItems = session.queueItems.filter(
      i => i.kalaamId.toString() !== req.params.kalamId
    );

    const maxIndex = session.queueItems.length - 1;
    if (maxIndex < 0) session.currentQueueIndex = 0;
    else if (session.currentQueueIndex > maxIndex) session.currentQueueIndex = maxIndex;

    await session.save();

    const io = req.app.get('io');
    if (io) await emitQueueUpdated(io, session);

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/sessions/:id/queue/:kalaamId/vote — toggle current user's upvote (any member)
router.post('/:id/queue/:kalaamId/vote', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const item = session.queueItems.find(i => i.kalaamId.toString() === req.params.kalaamId);
    if (!item) return res.status(404).json({ message: 'Queue item not found' });

    const userId = req.user.id;
    const idx = item.votes.findIndex(v => v.toString() === userId);
    if (idx === -1) item.votes.push(userId);
    else item.votes.splice(idx, 1);

    session.markModified('queueItems');
    await session.save();

    const io = req.app.get('io');
    if (io) await emitQueueUpdated(io, session);

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/queue/:kalaamId/pin — pin/unpin a queue item (host only)
// Body: { pinned: bool, pinPosition?: int }
router.patch('/:id/queue/:kalaamId/pin', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const { pinned, pinPosition } = req.body;
    const item = session.queueItems.find(i => i.kalaamId.toString() === req.params.kalaamId);
    if (!item) return res.status(404).json({ message: 'Queue item not found' });

    item.pinned = !!pinned;
    item.pinPosition = pinned ? (Number.isInteger(pinPosition) ? pinPosition : 0) : null;

    session.markModified('queueItems');
    await session.save();

    const io = req.app.get('io');
    if (io) await emitQueueUpdated(io, session);

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/queue/reorder — host reorders queue.
// Treated as "pin every item to its new index". Existing votes preserved.
// Body: { orderedIds: [kalaamId, ...] }
router.patch('/:id/queue/reorder', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const { orderedIds } = req.body;
    if (!Array.isArray(orderedIds)) return res.status(400).json({ message: 'orderedIds required' });

    orderedIds.forEach((kid, idx) => {
      const item = session.queueItems.find(i => i.kalaamId.toString() === kid);
      if (item) {
        item.pinned = true;
        item.pinPosition = idx;
      }
    });

    session.markModified('queueItems');
    await session.save();

    const io = req.app.get('io');
    if (io) await emitQueueUpdated(io, session);

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Shared advance implementation — also used by /queue/skip and the
// `host:advanceToNext` socket event handler.
async function advanceSession(session, io) {
  if (session.currentKalamId) {
    session.playedHistory.push({
      kalaamId: session.currentKalamId,
      finishedAt: new Date(),
    });
  }

  const sorted = session.sortedQueueItems();
  // The currently-playing kalaam is conceptually outside the queue; if it
  // also happens to be the queue head, skip it when picking the next one.
  const nextItem = sorted.find(
    i => !session.currentKalamId || i.kalaamId.toString() !== session.currentKalamId.toString()
  );

  if (nextItem) {
    session.currentKalamId = nextItem.kalaamId;
    session.queueItems = session.queueItems.filter(
      i => i.kalaamId.toString() !== nextItem.kalaamId.toString()
    );
  } else {
    session.currentKalamId = null;
  }
  session.currentStanza = 0;
  session.currentLine = 0;

  await session.save();
  await session.populate(QUEUE_ITEM_POPULATE);

  if (io) {
    io.to('session:' + session._id.toString()).emit('session:kalamChanged', {
      kalamId: session.currentKalamId ? session.currentKalamId.toString() : null,
      stanza: 0,
      line: 0,
    });
    await emitQueueUpdated(io, session);
  }
}

// POST /api/sessions/:id/advance — host advances to next kalaam in sorted queue.
router.post('/:id/advance', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });
    await advanceSession(session, req.app.get('io'));
    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/sessions/:id/queue/skip — legacy alias of /advance for old clients
router.post('/:id/queue/skip', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });
    await advanceSession(session, req.app.get('io'));
    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/sessions/:id/suggestions — list pending suggestions (legacy)
router.get('/:id/suggestions', auth, async (req, res) => {
  try {
    const suggestions = await Suggestion.find({ sessionId: req.params.id, status: 'pending' })
      .populate('kalamId', 'title category')
      .populate('suggestedBy', 'name');
    res.json(suggestions);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/sessions/:id/suggestions — suggest a kalam (legacy)
router.post('/:id/suggestions', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const { kalamId } = req.body;
    const suggestion = await Suggestion.create({
      sessionId: req.params.id,
      groupId: session.groupId,
      kalamId,
      suggestedBy: req.user.id,
    });

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:newSuggestion', { suggestion });

    res.status(201).json(suggestion);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/suggestions/:sid — accept/reject suggestion (legacy)
// Accept now adds the kalaam to queueItems with addedBy = suggester.
router.patch('/:id/suggestions/:sid', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (!isHost(session, req.user.id)) return res.status(403).json({ message: 'Host only' });

    const suggestion = await Suggestion.findById(req.params.sid);
    if (!suggestion) return res.status(404).json({ message: 'Suggestion not found' });

    const { status } = req.body;
    suggestion.status = status;
    await suggestion.save();

    if (status === 'accepted') {
      const already = session.queueItems.some(
        i => i.kalaamId.toString() === suggestion.kalamId.toString()
      );
      if (!already) {
        session.queueItems.push({
          kalaamId: suggestion.kalamId,
          addedBy: suggestion.suggestedBy,
          addedAt: new Date(),
          votes: [],
        });
        await session.save();
      }
    }

    const io = req.app.get('io');
    if (io) {
      io.to('session:' + req.params.id).emit('session:suggestionHandled', {
        suggestionId: req.params.sid,
        status,
      });
      if (status === 'accepted') await emitQueueUpdated(io, session);
    }

    res.json(suggestion);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
module.exports.advanceSession = advanceSession;
module.exports.emitQueueUpdated = emitQueueUpdated;
module.exports.QUEUE_ITEM_POPULATE = QUEUE_ITEM_POPULATE;
