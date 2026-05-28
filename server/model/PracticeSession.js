const mongoose = require('mongoose');

// One row per completed listen/practice attempt. The client also keeps a
// local copy in Isar (PracticeSessionRecord) — this server copy is what
// makes history, streak, and "best score" survive a reinstall or a switch
// to a second device. The aggregation (totals, streak, best) lives on
// PracticeMeta below so reads stay cheap.
const practiceSessionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  kalaam: { type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam', required: true, index: true },
  // Denormalised at write-time so history rendering doesn't need a populate
  // every time and survives an upstream kalaam delete.
  kalaamTitle: { type: String, default: '' },
  mode: { type: String, enum: ['solo', 'follow', 'listen', 'group'], default: 'listen' },
  sessionAt: { type: Date, default: Date.now, index: true },
  overallScore: { type: Number, default: 0, min: 0, max: 1 },
  accuracyScore: { type: Number, default: 0, min: 0, max: 1 },
  completionScore: { type: Number, default: 0, min: 0, max: 1 },
  flowScore: { type: Number, default: 0, min: 0, max: 1 },
  pauseScore: { type: Number, default: 0, min: 0, max: 1 },
  // Plain array of per-line accuracies (0..1). Stored as Numbers, not the
  // JSON string the client uses internally, so we can aggregate later.
  perLineScores: { type: [Number], default: [] },
  // Idempotency token the client mints so retries-after-offline don't
  // double-insert the same session.
  clientToken: { type: String, default: null, index: true, sparse: true },
}, { timestamps: true });

// Compound index drives the per-user "most recent first" history feed.
practiceSessionSchema.index({ user: 1, sessionAt: -1 });

module.exports = mongoose.model('PracticeSession', practiceSessionSchema);
