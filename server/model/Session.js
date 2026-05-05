const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
  hostId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  currentKalamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam', default: null },
  currentStanza: { type: Number, default: 0 },
  currentLine: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  isPlaying: { type: Boolean, default: false },
  queue: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam' }],
  currentQueueIndex: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('Session', sessionSchema);
