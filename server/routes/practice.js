const express = require('express');
const auth = require('../middleware/auth');
const PracticeSession = require('../model/PracticeSession');
const PracticeMeta = require('../model/PracticeMeta');

const router = express.Router();

// Clamp a numeric score to [0, 1]. Anything off the wire that's NaN or
// outside the range collapses to 0 so a malformed client can't poison
// aggregates.
const clamp01 = (n) => {
  const v = Number(n);
  if (!Number.isFinite(v)) return 0;
  return v < 0 ? 0 : v > 1 ? 1 : v;
};

// POST /api/practice/sessions
// Body: { kalaamId, kalaamTitle?, mode, sessionAt, overallScore,
//         accuracyScore, completionScore, flowScore, pauseScore,
//         perLineScores: [number], clientToken? }
//
// Idempotent on (user, clientToken): replays from the offline drain queue
// land on the same row and bump aggregates once, never twice.
router.post('/sessions', auth, async (req, res) => {
  try {
    const {
      kalaamId,
      kalaamTitle = '',
      mode = 'listen',
      sessionAt,
      overallScore,
      accuracyScore,
      completionScore,
      flowScore,
      pauseScore,
      perLineScores = [],
      clientToken = null,
    } = req.body || {};

    if (!kalaamId) {
      return res.status(400).json({ message: 'kalaamId required' });
    }

    if (clientToken) {
      const existing = await PracticeSession.findOne({
        user: req.user.id,
        clientToken,
      });
      if (existing) {
        const meta = await PracticeMeta.findOne({
          user: req.user.id,
          kalaam: kalaamId,
        });
        return res.json({ session: existing, meta });
      }
    }

    const overall = clamp01(overallScore);
    const session = await PracticeSession.create({
      user: req.user.id,
      kalaam: kalaamId,
      kalaamTitle: String(kalaamTitle || ''),
      mode: ['solo', 'follow', 'listen', 'group'].includes(mode) ? mode : 'listen',
      sessionAt: sessionAt ? new Date(sessionAt) : new Date(),
      overallScore: overall,
      accuracyScore: clamp01(accuracyScore),
      completionScore: clamp01(completionScore),
      flowScore: clamp01(flowScore),
      pauseScore: clamp01(pauseScore),
      perLineScores: Array.isArray(perLineScores)
        ? perLineScores.map(clamp01)
        : [],
      clientToken,
    });

    // Re-compute the aggregate row. We don't trust the client's running
    // streak — instead we walk from `lastPracticedAt`: ≤1 day → +1, else
    // reset to 1. Same rule as the Isar mirror.
    const existing = await PracticeMeta.findOne({
      user: req.user.id,
      kalaam: kalaamId,
    });
    const now = session.sessionAt;
    const weakLines = (session.perLineScores || [])
      .map((s, i) => (s < 0.5 ? i : -1))
      .filter((i) => i >= 0);

    let meta;
    if (!existing) {
      meta = await PracticeMeta.create({
        user: req.user.id,
        kalaam: kalaamId,
        totalSessions: 1,
        bestOverallScore: overall,
        lastPracticedAt: now,
        currentStreak: 1,
        longestStreak: 1,
        weakLineIndices: weakLines,
      });
    } else {
      const daysSince = existing.lastPracticedAt
        ? Math.floor(
            (now - existing.lastPracticedAt.getTime()) / (1000 * 60 * 60 * 24),
          )
        : Infinity;
      const streak = daysSince <= 1 ? existing.currentStreak + 1 : 1;
      existing.totalSessions += 1;
      existing.bestOverallScore = Math.max(existing.bestOverallScore, overall);
      existing.lastPracticedAt = now;
      existing.currentStreak = streak;
      existing.longestStreak = Math.max(existing.longestStreak, streak);
      existing.weakLineIndices = weakLines;
      await existing.save();
      meta = existing;
    }

    res.status(201).json({ session, meta });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/practice/sessions?kalaamId&limit
// History (most recent first) for the signed-in user, optionally filtered
// to a single kalaam.
router.get('/sessions', auth, async (req, res) => {
  try {
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const filter = { user: req.user.id };
    if (req.query.kalaamId) filter.kalaam = req.query.kalaamId;
    const sessions = await PracticeSession.find(filter)
      .sort({ sessionAt: -1 })
      .limit(limit);
    res.json({ sessions });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/practice/meta — every per-kalaam aggregate for this user.
// Lets the home screen render streaks / best scores without an N+1.
router.get('/meta', auth, async (req, res) => {
  try {
    const filter = { user: req.user.id };
    if (req.query.kalaamId) filter.kalaam = req.query.kalaamId;
    const rows = await PracticeMeta.find(filter);
    res.json({ meta: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
