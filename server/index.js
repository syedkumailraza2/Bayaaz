require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const kalaamRoutes = require('./routes/kalaam');
const groupRoutes = require('./routes/groups');
const sessionRoutes = require('./routes/sessions');
const attachSessionHandlers = require('./socket/sessionNamespace');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Make io accessible in route handlers via req.app.get('io')
app.set('io', io);

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/kalaams', kalaamRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/sessions', sessionRoutes);

app.get('/health', (_, res) => res.json({ status: 'ok' }));

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
