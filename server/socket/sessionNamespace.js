const jwt = require('jsonwebtoken');
const Session = require('../model/Session');
const Suggestion = require('../model/Suggestion');

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
          .populate('queue', 'title category author');
        if (session) {
          socket.emit('session:joined', { session });
        }
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- session:leave ---
    socket.on('session:leave', ({ sessionId }) => {
      socket.leave(`session:${sessionId}`);
    });

    // --- host:setKalam ---
    // Client sends: { sessionId, kalamId }
    // Only host may do this. Broadcast to all in room.
    socket.on('host:setKalam', async ({ sessionId, kalamId }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        // Find matching queue index
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

    // --- host:setStanza ---
    // Client sends: { sessionId, stanza, line }
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
    // Client sends: { sessionId, isPlaying }
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

    // --- host:queueUpdated ---
    // Client sends: { sessionId, queue: ['id1', 'id2', ...] }
    socket.on('host:queueUpdated', async ({ sessionId, queue }) => {
      try {
        const session = await Session.findById(sessionId);
        if (!session) return;
        if (session.hostId.toString() !== currentUserId) {
          return socket.emit('session:error', { message: 'Not the host' });
        }
        session.queue = queue;
        await session.save();
        io.to(`session:${sessionId}`).emit('session:queueUpdated', { queue });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    // --- member:suggest ---
    // Client sends: { sessionId, kalamId }
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

    // --- host:suggestionHandled ---
    // Client sends: { sessionId, suggestionId, status: 'accepted'|'rejected' }
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
          session.queue.push(suggestion.kalamId);
          await session.save();
          io.to(`session:${sessionId}`).emit('session:queueUpdated', { queue: session.queue.map(id => id.toString()) });
        }
        io.to(`session:${sessionId}`).emit('session:suggestionHandled', { suggestionId, status });
      } catch (err) {
        socket.emit('session:error', { message: err.message });
      }
    });

    socket.on('disconnect', () => {
      // No explicit cleanup needed — socket.io handles room cleanup on disconnect
    });
  });
};
