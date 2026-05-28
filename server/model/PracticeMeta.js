const mongoose = require('mongoose');

// Aggregated practice analytics per (user, kalaam). Mirrors the Isar
// KalaamPracticeMeta row but lives on the server so streak / best score /
// "weak lines" survive a device wipe and can drive cross-device features
// later (leaderboard, coach hints, etc.). Updated atomically inside the
// POST /api/practice/sessions write so writes can't drift.
const practiceMetaSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  kalaam: { type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam', required: true, index: true },
  totalSessions: { type: Number, default: 0, min: 0 },
  bestOverallScore: { type: Number, default: 0, min: 0, max: 1 },
  lastPracticedAt: { type: Date, default: null },
  currentStreak: { type: Number, default: 0, min: 0 },
  longestStreak: { type: Number, default: 0, min: 0 },
  // Line indices (0-based) that landed below the accuracy threshold on
  // the most recent attempt. Used to nudge the "weak lines" coach view.
  weakLineIndices: { type: [Number], default: [] },
}, { timestamps: true });

// One meta row per user-kalaam pair.
practiceMetaSchema.index({ user: 1, kalaam: 1 }, { unique: true });

module.exports = mongoose.model('PracticeMeta', practiceMetaSchema);
