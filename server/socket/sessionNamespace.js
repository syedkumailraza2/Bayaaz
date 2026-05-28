const jwt = require('jsonwebtoken');
const Session = require('../model/Session');
const Suggestion = require('../model/Suggestion');
const sessionsRoute = require('../routes/sessions');
const { splitKalaamHemistichs } = require('../services/hemistichSplit');
const voskBridge = require('../services/voskBridge');

const QUEUE_ITEM_POPULATE = sessionsRoute.QUEUE_ITEM_POPULATE;
const advanceSession = sessionsRoute.advanceSession;
const emitQueueUpdated = sessionsRoute.emitQueueUpdated;

module.exports = function attachSessionHandlers(io) {
  io.on('connection', (socket) => {
    // Verify JWT from handshake auth
    let currentUserId = null;
    try {
      const token = socket.handshake.auth?.token;
      if (token) {
        const payload = jwt.verify(token, process.env.JWT_SECRET);
        currentUserId = payload.id;
        socket.data.userId = payload.id;
      }
    } catch {
      // Invalid token — socket connects but userId is null; host events will fail auth checks
    }

    // --- session:join ---
    // Client sends: { sessionId }
    // Server: join room 'session:{sessionId}', emit 'session:joined' with full session state
    socket.on('session:join', async ({ sessionId }) => {
      try {
        socket.join(`session:${sessionId}`);
        const session = await Session.findById(sessionId)
          .populate('currentKalamId', 'title category content poet author')
          .populate('queue', 'title category author')
          .populate(QUEUE_ITEM_POPULATE);
        if (session) {
          const out = session.toObject();
          if (out.currentKalamId) out.currentKalamId = splitKalaamHemistichs(out.currentKalamId);
          socket.emit('session:joined', { session: out });
        }
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- session:leave ---
    socket.on('session:leave', ({ sessionId }) => {
      socket.leave(`session:${sessionId}`);
    });

    // --- group:join / group:leave ---
    // Lets the group detail screen receive group-level events
    // (session started/ended) without first opening the teleprompter.
    socket.on('group:join', ({ groupId }) => {
      if (typeof groupId === 'string' && groupId.length > 0) {
        socket.join(`group:${groupId}`);
      }
    });

    socket.on('group:leave', ({ groupId }) => {
      if (typeof groupId === 'string' && groupId.length > 0) {
        socket.leave(`group:${groupId}`);
      }
    });

    // --- kalaam:join / kalaam:leave ---
    // Subscribes the client to per-kalaam engagement broadcasts. The detail
    // screen joins on open and leaves on dispose so the like / save / view
    // counters update live across devices viewing the same kalaam.
    socket.on('kalaam:join', ({ kalaamId }) => {
      if (typeof kalaamId === 'string' && kalaamId.length > 0) {
        socket.join(`kalaam:${kalaamId}`);
      }
    });

    socket.on('kalaam:leave', ({ kalaamId }) => {
      if (typeof kalaamId === 'string' && kalaamId.length > 0) {
        socket.leave(`kalaam:${kalaamId}`);
      }
    });

    // --- host:setKalam ---
    socket.on('host:setKalam', async ({ sessionId, kalamId }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        const queueIndex = session.queue.findIndex(id => id.toString() === kalamId);
        session.currentKalamId = kalamId;
        session.currentStanza = 0;
        session.currentLine = 0;
        if (queueIndex >= 0) session.currentQueueIndex = queueIndex;
        await session.save();
        io.to(`session:${sessionId}`).emit('session:kalamChanged', { kalamId, stanza: 0, line: 0 });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- host:setStanza --- (line-by-line cursor for the teleprompter)
    socket.on('host:setStanza', async ({ sessionId, stanza, line }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        session.currentStanza = stanza;
        session.currentLine = line;
        await session.save();
        io.to(`session:${sessionId}`).emit('session:stanzaChanged', { stanza, line });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- host:setPlayState ---
    socket.on('host:setPlayState', async ({ sessionId, isPlaying }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        session.isPlaying = isPlaying;
        await session.save();
        io.to(`session:${sessionId}`).emit('session:playStateChanged', { isPlaying });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- host:queueUpdated --- LEGACY: accepts a flat [kalaamId] queue.
    // New clients should use REST endpoints for vote/pin/reorder instead.
    socket.on('host:queueUpdated', async ({ sessionId, queue }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        // Best-effort migration: treat each id as a pinned item in the given order.
        const existingById = new Map(
          session.queueItems.map(i => [i.kalaamId.toString(), i])
        );
        session.queueItems = queue.map((kid, idx) => {
          const existing = existingById.get(kid.toString());
          if (existing) {
            existing.pinned = true;
            existing.pinPosition = idx;
            return existing;
          }
          return {
            kalaamId: kid,
            addedBy: currentUserId,
            addedAt: new Date(),
            votes: [],
            pinned: true,
            pinPosition: idx,
          };
        });
        await session.save();
        await emitQueueUpdated(io, session);
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- member:vote --- toggle current user's upvote on a queue item
    socket.on('member:vote', async ({ sessionId, kalaamId }) => {
      try {
        if (!currentUserId) return socket.emit('session:error', { message: 'Not authenticated' });
        const session = await Session.findById(sessionId);
        if (!session) return;
        const item = session.queueItems.find(i => i.kalaamId.toString() === kalaamId);
        if (!item) return socket.emit('session:error', { message: 'Queue item not found' });

        const idx = item.votes.findIndex(v => v.toString() === currentUserId);
        if (idx === -1) item.votes.push(currentUserId);
        else item.votes.splice(idx, 1);

        session.markModified('queueItems');
        await session.save();
        await emitQueueUpdated(io, session);
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- host:pinQueueItem --- pin/unpin a single queue item
    // Payload: { sessionId, kalaamId, pinned, pinPosition? }
    socket.on('host:pinQueueItem', async ({ sessionId, kalaamId, pinned, pinPosition }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        const item = session.queueItems.find(i => i.kalaamId.toString() === kalaamId);
        if (!item) return socket.emit('session:error', { message: 'Queue item not found' });
        item.pinned = !!pinned;
        item.pinPosition = pinned ? (Number.isInteger(pinPosition) ? pinPosition : 0) : null;
        session.markModified('queueItems');
        await session.save();
        await emitQueueUpdated(io, session);
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- host:advanceToNext --- advance from current kalaam to sorted queue head
    socket.on('host:advanceToNext', async ({ sessionId }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        await advanceSession(session, io);
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- member:suggest --- legacy suggestion flow
    socket.on('member:suggest', async ({ sessionId, kalamId }) => {
      try {
        if (!currentUserId) return socket.emit('session:error', { message: 'Not authenticated' });
        const session = await Session.findById(sessionId);
        if (!session) return socket.emit('session:error', { message: 'Session not found' });
        const suggestion = await Suggestion.create({
          sessionId,
          groupId: session.groupId,
          kalamId,
          suggestedBy: currentUserId,
        });
        await suggestion.populate('kalamId', 'title category');
        await suggestion.populate('suggestedBy', 'name');
        io.to(`session:${sessionId}`).emit('session:newSuggestion', { suggestion });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- host:suggestionHandled --- legacy accept/reject
    socket.on('host:suggestionHandled', async ({ sessionId, suggestionId, status }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        const suggestion = await Suggestion.findById(suggestionId);
        if (!suggestion) return socket.emit('session:error', { message: 'Suggestion not found' });
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
            await emitQueueUpdated(io, session);
          }
        }
        io.to(`session:${sessionId}`).emit('session:suggestionHandled', { suggestionId, status });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- voice:start / voice:frame / voice:end ---
    // Host opens a streaming PCM channel to the Vosk bridge. Frames are
    // raw 16-bit little-endian mono PCM; the bridge runs the fuzzy matcher
    // on Vosk partials/finals and broadcasts `session:stanzaChanged`.
    socket.on('voice:start', async ({ sessionId }) => {
      if (!currentUserId) return socket.emit('voice:error', { message: 'Not authenticated' });
      if (!sessionId) return socket.emit('voice:error', { message: 'sessionId required' });
      try {
        await voskBridge.startBridge(socket, io, sessionId, currentUserId);
      } catch (err) {
        console.error('[voice:start] failed:', err.message);
        socket.emit('voice:error', { message: err.message });
      }
    });

    // --- voice:soloStart ---
    // Solo follow-my-voice for the single-user practice teleprompter. Takes
    // a kalaamId instead of a sessionId; matches go back to this socket only
    // as `voice:soloStanzaChanged`. Frames and ending reuse `voice:frame` /
    // `voice:end` since the bridge is keyed by socket.id.
    socket.on('voice:soloStart', async ({ kalaamId }) => {
      if (!currentUserId) return socket.emit('voice:error', { message: 'Not authenticated' });
      if (!kalaamId) return socket.emit('voice:error', { message: 'kalaamId required' });
      try {
        await voskBridge.startSoloBridge(socket, kalaamId, currentUserId);
      } catch (err) {
        console.error('[voice:soloStart] failed:', err.message);
        socket.emit('voice:error', { message: err.message });
      }
    });

    socket.on('voice:frame', (frame) => {
      // socket.io delivers binary as Node Buffer; pass through unchanged.
      if (!frame) return;
      voskBridge.pushFrame(socket, frame);
    });

    socket.on('voice:end', () => {
      voskBridge.stopBridge(socket);
    });

    socket.on('disconnect', () => {
      voskBridge.stopBridge(socket);
      // socket.io handles room cleanup on disconnect
    });
  });
};
