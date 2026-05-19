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
const attachSessionHandlers = require('./socket/sessionNamespace');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
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

// Trust the Cloudflare/ngrok proxy so req.protocol and req.get('host')
// reflect the public URL when building outbound links.
app.set('trust proxy', true);

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/kalaams', kalaamRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/invites', inviteRoutes);

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

attachSessionHandlers(io);

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected');
    server.listen(process.env.PORT || 5000, () =>
      console.log(`Server running on port ${process.env.PORT || 5000}`)
    );
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });
