const express = require('express');
const mongoose = require('mongoose');
const Session = require('../model/Session');
const Group = require('../model/Group');
const Suggestion = require('../model/Suggestion');
const QueueSnapshot = require('../model/QueueSnapshot');
const Kalaam = require('../model/Kalaam');
const auth = require('../middleware/auth');
const { splitKalaamHemistichs } = require('../services/hemistichSplit');

// Apply hemistich-splitting to session.currentKalamId in place so the kalaam
// content the client renders matches the positions the matcher emits.
function applyHemistichSplit(session) {
  if (!session || !session.currentKalamId) return session;
  const split = splitKalaamHemistichs(session.currentKalamId);
  session.currentKalamId = split;
  return session;
}

const router = express.Router();

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
    const out = session.toObject();
    applyHemistichSplit(out);
    res.json(out);
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
    if (io) {
      io.to('session:' + req.params.id).emit('session:ended', {});
      // Tell anyone on the group screen the session is gone so their
      // "Join Session" button flips back to "Start Session" instantly.
      io.to('group:' + session.groupId.toString()).emit('group:sessionEnded', {
        groupId: session.groupId.toString(),
        sessionId: req.params.id,
      });
    }

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
