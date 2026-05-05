const express = require('express');
const mongoose = require('mongoose');
const Session = require('../model/Session');
const Group = require('../model/Group');
const Suggestion = require('../model/Suggestion');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /api/sessions/:id — get full session detail
router.get('/:id', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id)
      .populate('currentKalamId', 'title category content poet author')
      .populate('queue', 'title category author');
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
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

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
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

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
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

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
router.delete('/:id', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

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
router.post('/:id/queue', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const { kalamId } = req.body;
    const wasEmpty = session.queue.length === 0;

    session.queue.push(kalamId);

    if (wasEmpty) {
      session.currentKalamId = kalamId;
      session.currentQueueIndex = 0;
    }

    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:queueUpdated', { queue: session.queue });

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
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

    session.queue.pull(req.params.kalamId);

    const maxIndex = session.queue.length - 1;
    if (maxIndex < 0) {
      session.currentQueueIndex = 0;
    } else if (session.currentQueueIndex > maxIndex) {
      session.currentQueueIndex = maxIndex;
    }

    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:queueUpdated', { queue: session.queue });

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/sessions/:id/queue/reorder — reorder queue (host only)
router.patch('/:id/queue/reorder', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

    const { orderedIds } = req.body;
    session.queue = orderedIds.map(id => new mongoose.Types.ObjectId(id));

    await session.save();

    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:queueUpdated', { queue: session.queue });

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/sessions/:id/queue/skip — skip to next kalam in queue (host only)
router.post('/:id/queue/skip', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

    if (session.currentQueueIndex < session.queue.length - 1) {
      session.currentQueueIndex += 1;
      session.currentKalamId = session.queue[session.currentQueueIndex];
      session.currentStanza = 0;
      session.currentLine = 0;
    }

    await session.save();

    const kalamId = session.currentKalamId ? session.currentKalamId.toString() : null;
    const io = req.app.get('io');
    if (io) io.to('session:' + req.params.id).emit('session:kalamChanged', { kalamId });

    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/sessions/:id/suggestions — get pending suggestions for session
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

// POST /api/sessions/:id/suggestions — suggest a kalam (any group member)
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

// PATCH /api/sessions/:id/suggestions/:sid — accept or reject a suggestion (host only)
router.patch('/:id/suggestions/:sid', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (session.hostId.toString() !== req.user.id) return res.status(403).json({ message: 'Host only' });

    const suggestion = await Suggestion.findById(req.params.sid);
    if (!suggestion) return res.status(404).json({ message: 'Suggestion not found' });

    const { status } = req.body;
    suggestion.status = status;
    await suggestion.save();

    if (status === 'accepted') {
      session.queue.push(suggestion.kalamId);
      await session.save();
    }

    const io = req.app.get('io');
    if (io) {
      io.to('session:' + req.params.id).emit('session:suggestionHandled', {
        suggestionId: req.params.sid,
        status,
      });
    }

    res.json(suggestion);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
