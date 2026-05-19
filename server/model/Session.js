const mongoose = require('mongoose');

// One entry per kalaam in the live queue.
//   votes: every user who upvoted this item (length == vote count).
//   pinned + pinPosition: host-pinned items occupy fixed slots and ignore
//     the vote-sort below them. pinPosition is an absolute index among
//     the pinned items only.
const queueItemSchema = new mongoose.Schema(
  {
    kalaamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam', required: true },
    addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    addedAt: { type: Date, default: Date.now },
    votes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    pinned: { type: Boolean, default: false },
    pinPosition: { type: Number, default: null },
  },
  { _id: true }
);

const sessionSchema = new mongoose.Schema(
  {
    groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
    hostId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    currentKalamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam', default: null },
    currentStanza: { type: Number, default: 0 },
    currentLine: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
    isPlaying: { type: Boolean, default: false },
    // Legacy flat queue, kept as a derived mirror for old clients that
    // still read `queue: [kalaamId]`. Always rebuilt from sortedQueueItems
    // before save via the pre-save hook below.
    queue: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam' }],
    currentQueueIndex: { type: Number, default: 0 },
    // New source of truth for the queue.
    queueItems: [queueItemSchema],
    // Append-only log of kalaams that have already played in this session.
    playedHistory: [
      {
        kalaamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam' },
        finishedAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

// Sort: pinned items (by pinPosition asc, then addedAt) come first,
// then unpinned items (by vote count desc, then addedAt asc).
function sortedQueueItems(items) {
  const pinned = items
    .filter((i) => i.pinned)
    .sort((a, b) => {
      const pa = a.pinPosition ?? Number.MAX_SAFE_INTEGER;
      const pb = b.pinPosition ?? Number.MAX_SAFE_INTEGER;
      if (pa !== pb) return pa - pb;
      return new Date(a.addedAt) - new Date(b.addedAt);
    });
  const unpinned = items
    .filter((i) => !i.pinned)
    .sort((a, b) => {
      const va = (a.votes || []).length;
      const vb = (b.votes || []).length;
      if (vb !== va) return vb - va;
      return new Date(a.addedAt) - new Date(b.addedAt);
    });
  return [...pinned, ...unpinned];
}

sessionSchema.methods.sortedQueueItems = function () {
  return sortedQueueItems(this.queueItems || []);
};

// Keep legacy `queue` mirror in sync so older clients keep working.
// Mongoose 7+ no longer passes `next` to pre-save hooks; use async instead.
sessionSchema.pre('save', async function () {
  if (this.isModified('queueItems') || this.isModified('queue')) {
    this.queue = this.sortedQueueItems().map((i) => i.kalaamId);
  }
});

module.exports = mongoose.model('Session', sessionSchema);
module.exports.sortedQueueItems = sortedQueueItems;
