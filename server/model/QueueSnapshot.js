const mongoose = require('mongoose');

// Captured at the moment a session is ended (DELETE /api/sessions/:id).
// `items` is the sorted queue at end-of-session, intended for "load
// previous queue" on the next session start for the same group.
const queueSnapshotSchema = new mongoose.Schema(
  {
    groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
    sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Session', required: true },
    items: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam' }],
  },
  { timestamps: true }
);

queueSnapshotSchema.index({ groupId: 1, createdAt: -1 });

module.exports = mongoose.model('QueueSnapshot', queueSnapshotSchema);
