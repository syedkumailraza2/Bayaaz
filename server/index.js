require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const { createClient } = require('redis');
const { createAdapter } = require('@socket.io/redis-adapter');

const authRoutes = require('./routes/auth');
const kalaamRoutes = require('./routes/kalaam');
const groupRoutes = require('./routes/groups');
const sessionRoutes = require('./routes/sessions');
const inviteRoutes = require('./routes/invites');
const sttRoutes = require('./routes/stt');
const practiceRoutes = require('./routes/practice');
const attachSessionHandlers = require('./socket/sessionNamespace');

// `VERCEL` is set automatically by Vercel's serverless runtime.
// On Vercel:
//   - long-lived sockets and setInterval don't work; we skip them.
//   - `app.listen()` is not called; Vercel wraps the exported app.
//   - Mongo connects lazily and is cached on the module so subsequent
//     warm invocations reuse the same client.
const isServerless = !!process.env.VERCEL;

const app = express();

// Trust the Cloudflare/Vercel/ngrok proxy so req.protocol and req.get('host')
// reflect the public URL when building outbound links.
app.set('trust proxy', true);

app.use(cors());
app.use(express.json({ limit: '1mb' }));

// ─── Socket.IO ─────────────────────────────────────────────────────────────
// Only attach Socket.IO when we run as a long-lived process. Vercel's
// serverless model doesn't hold WebSocket connections, so realtime
// features (majlis sync, voice follow) must be hosted elsewhere (Render,
// Railway, Fly, a self-hosted box). The REST endpoints below work on
// either deployment target.
let server;
let io;
if (!isServerless) {
  server = http.createServer(app);
  io = new Server(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });

  // Redis pub/sub adapter — lets Socket.IO broadcast across multiple Node
  // instances. Optional: if REDIS_URL is unset and the local Redis isn't
  // reachable, we fall back silently to in-memory broadcasting.
  (async function attachRedisAdapter() {
    const url = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
    try {
      const pubClient = createClient({ url });
      const subClient = pubClient.duplicate();
      pubClient.on('error', (err) => console.error('[redis pub] error:', err.message));
      subClient.on('error', (err) => console.error('[redis sub] error:', err.message));
      await Promise.all([pubClient.connect(), subClient.connect()]);
      io.adapter(createAdapter(pubClient, subClient));
      console.log(`Socket.IO Redis adapter attached (${url})`);
    } catch (err) {
      console.warn('Redis adapter not attached, falling back to in-memory:', err.message);
    }
  })();

  // Make io accessible in route handlers via req.app.get('io')
  app.set('io', io);
  attachSessionHandlers(io);
}

app.use('/api/auth', authRoutes);
app.use('/api/kalaams', kalaamRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/invites', inviteRoutes);
app.use('/api/stt', sttRoutes);
app.use('/api/practice', practiceRoutes);

app.get('/health', (_, res) => res.json({ status: 'ok' }));

// Invite landing page — WhatsApp and most chat apps only linkify http(s) URLs,
// so we hand out an https URL that bounces to the bayaaz:// custom scheme.
app.get('/i/:token', (req, res) => {
  const safeToken = encodeURIComponent(req.params.token);
  res.type('html').send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Opening Bayaaz...</title>
  <meta http-equiv="refresh" content="0;url=bayaaz://i/${safeToken}">
  <style>
    body{font-family:-apple-system,system-ui,sans-serif;background:#0f0f1a;color:#e2b96f;
      margin:0;height:100vh;display:flex;align-items:center;justify-content:center;
      flex-direction:column;text-align:center;padding:2rem}
    a{color:#e2b96f;text-decoration:underline}
  </style>
</head>
<body>
  <h2>Opening Bayaaz...</h2>
  <p>If the app doesn't open automatically, <a href="bayaaz://i/${safeToken}">tap here</a>.</p>
  <script>window.location.replace("bayaaz://i/${safeToken}");</script>
</body>
</html>`);
});

// ─── Mongo ─────────────────────────────────────────────────────────────────
// Cache the connection promise on the module so serverless cold starts
// re-use the same TCP pool across invocations.
let mongoPromise = null;
function connectMongo() {
  if (!mongoPromise) {
    mongoPromise = mongoose
      .connect(process.env.MONGO_URI, {
        serverSelectionTimeoutMS: 8000,
      })
      .then((m) => {
        console.log('MongoDB connected');
        return m;
      })
      .catch((err) => {
        // Reset so the next request retries — important on serverless.
        mongoPromise = null;
        throw err;
      });
  }
  return mongoPromise;
}

// Ensure every API request waits for Mongo before reaching the routes.
app.use(async (req, res, next) => {
  try {
    await connectMongo();
    next();
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    res.status(503).json({ message: 'Database unavailable' });
  }
});

if (!isServerless) {
  // Local / long-lived host: start the HTTP server.
  connectMongo()
    .then(() => {
      server.listen(process.env.PORT || 5000, () =>
        console.log(`Server running on port ${process.env.PORT || 5000}`)
      );
    })
    .catch((err) => {
      console.error('MongoDB connection error:', err);
      process.exit(1);
    });

  // Render's free tier spins services down after ~15 min idle; the first
  // cold request takes 30-50s. Self-ping /health every 5 min to keep
  // the dyno warm. We only run this on long-lived hosts because Vercel
  // serverless invocations are short-lived and the timer would never tick.
  const keepAliveUrl =
    process.env.RENDER_EXTERNAL_URL ||
    `http://127.0.0.1:${process.env.PORT || 5000}`;
  setInterval(async () => {
    try {
      const res = await fetch(`${keepAliveUrl}/health`);
      if (!res.ok) console.warn('[keep-alive] non-ok response:', res.status);
    } catch (err) {
      console.error('[keep-alive] ping failed:', err.message);
    }
  }, 5 * 60 * 1000);
}

module.exports = app;
