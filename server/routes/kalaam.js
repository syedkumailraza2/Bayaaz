const express = require('express');
const jwt = require('jsonwebtoken');
const Kalaam = require('../model/Kalaam');
const User = require('../model/User');
const auth = require('../middleware/auth');
const r2 = require('../services/r2');

const router = express.Router();

// ─── Reference media ───────────────────────────────────────────────────────
// Reference audio/video lives in Cloudflare R2. The upload flow:
//   1. Client POSTs `/kalaams/:id/reference/presign` with `extension`.
//   2. Server returns a 10-minute presigned PUT URL and the final public URL.
//   3. Client PUTs file bytes directly to R2 over that URL.
//   4. Client POSTs `/kalaams/:id/reference` with the public URL to persist.
// We validate that the URL belongs to our configured R2 public base
// (`R2_PUBLIC_BASE_URL`) so a malicious client can't make us advertise an
// arbitrary host.
const ALLOWED_REF_EXTS = r2.ALLOWED_EXTS;

const isValidReferenceUrl = (raw) => r2.isManagedPublicUrl(raw);

// Resolves the requesting user id from a Bearer token if one is provided,
// otherwise returns null. Used by public endpoints so we can still compute
// `likedByMe` for signed-in clients without forcing auth on the route.
const tryAuth = (req) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return null;
  try {
    return jwt.verify(token, process.env.JWT_SECRET).id;
  } catch {
    return null;
  }
};

// Single User.findById to materialise the requester's saved set so list and
// detail responses can compute `savedByMe` for every item without a per-item
// query. Returns null when no user is signed in.
const loadSavedSet = async (userId) => {
  if (!userId) return null;
  const u = await User.findById(userId).select('savedKalaams').lean();
  if (!u || !Array.isArray(u.savedKalaams)) return new Set();
  return new Set(u.savedKalaams.map(id => id.toString()));
};

const fmt = (doc, userId, savedSet = null) =>
  Kalaam.formatForClient(doc, userId, savedSet);
const fmtMany = (docs, userId, savedSet = null) =>
  docs.map(d => fmt(d, userId, savedSet));

// Broadcast an engagement update (like / save / view) to everyone watching
// this kalaam's detail screen. The client joins `kalaam:<id>` on open and
// applies the patch optimistically + reconciles on the broadcast.
const emitKalaamEngagement = (req, kalaamId, patch) => {
  const io = req.app.get('io');
  if (!io) return;
  io.to(`kalaam:${kalaamId}`).emit('kalaam:engagement', {
    kalaamId: String(kalaamId),
    ...patch,
  });
};

// GET /api/kalaams — public feed with search, filter, and pagination
//   q?: free-text (title, poet, tags, lines)
//   tag?: exact tag match
//   category?: nauha | marsiya | qasida | qata
//   page?: 1-indexed (default 1)
//   limit?: page size (default 20, max 100)
router.get('/', async (req, res) => {
  try {
    const {
      q,
      tag,
      category,
      page: pageRaw = '1',
      limit: limitRaw = '20',
    } = req.query;

    const page = Math.max(1, parseInt(pageRaw, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(limitRaw, 10) || 20));

    const filter = { isPublic: true };
    if (category) filter.category = category;
    if (tag) filter.tags = tag;

    if (q && q.trim()) {
      const escaped = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(escaped, 'i');
      filter.$or = [
        { title: regex },
        { poet: regex },
        { tags: regex },
        { 'content.lines': regex },
      ];
    }

    const userId = tryAuth(req);
    const [items, total, savedSet] = await Promise.all([
      Kalaam.find(filter)
        .populate('author', 'name avatar')
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Kalaam.countDocuments(filter),
      loadSavedSet(userId),
    ]);

    res.json({
      items: fmtMany(items, userId, savedSet),
      page,
      limit,
      total,
      hasMore: page * limit < total,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/kalaams/saved — kalaams saved by current user
router.get('/saved', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate({
      path: 'savedKalaams',
      populate: { path: 'author', select: 'name avatar' },
      options: { sort: { createdAt: -1 } },
    });
    const saved = (user.savedKalaams || []).filter(
      k => k && (k.isPublic || k.author?._id?.toString() === req.user.id),
    );
    // Everything in this response is, by definition, saved by the requester.
    const savedSet = new Set(saved.map(k => k._id.toString()));
    res.json(fmtMany(saved, req.user.id, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/save — toggle save/unsave.
// Returns `{ saved, savedCount, savesCount }` where:
//   savedCount  = total kalaams the requester has saved (their library size)
//   savesCount  = total users who have saved THIS kalaam (the live counter)
router.post('/:id/save', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const kalaamId = req.params.id;
    const idx = user.savedKalaams.findIndex(
      id => id.toString() === kalaamId,
    );
    let saved;
    if (idx === -1) {
      user.savedKalaams.push(kalaamId);
      saved = true;
    } else {
      user.savedKalaams.splice(idx, 1);
      saved = false;
    }
    await user.save();

    // Re-aggregate the kalaam-level count from the source of truth (User
    // collection) instead of $inc'ing, so existing rows that predate the
    // savesCount field self-heal on first interaction and double-taps can't
    // drift the counter.
    const savesCount = await User.countDocuments({ savedKalaams: kalaamId });
    await Kalaam.findByIdAndUpdate(kalaamId, { savesCount }).catch(() => {});

    emitKalaamEngagement(req, kalaamId, { savesCount });

    res.json({ saved, savedCount: user.savedKalaams.length, savesCount });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/like — toggle like (auth required)
// Returns { liked: bool, likesCount: int } for cheap optimistic UI.
router.post('/:id/like', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });

    const uid = req.user.id;
    const idx = kalaam.likes.findIndex(x => x.toString() === uid);
    let liked;
    if (idx === -1) {
      kalaam.likes.push(uid);
      liked = true;
    } else {
      kalaam.likes.splice(idx, 1);
      liked = false;
    }
    await kalaam.save();
    const likesCount = kalaam.likes.length;
    emitKalaamEngagement(req, kalaam._id, { likesCount });
    res.json({ liked, likesCount });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/view — increment the read counter, but only once
// per authenticated user. Anonymous viewers see the current count without
// bumping (no abuse-proof way to identify them). The atomic $addToSet +
// conditional $inc keeps two concurrent views from the same user racing
// into a double bump.
router.post('/:id/view', async (req, res) => {
  try {
    const userId = tryAuth(req);
    if (!userId) {
      // No auth — return the current count without touching it.
      const k = await Kalaam.findById(req.params.id).select('reads');
      if (!k) return res.status(404).json({ message: 'Not found' });
      return res.json({ reads: k.reads || 0 });
    }

    // Atomically: add userId to readers (no-op if already present) AND
    // increment reads only when the user wasn't already a reader. Mongo
    // can't express that in a single `update` op, so we do a two-step
    // check-and-bump under the assumption that the readers set is the
    // source of truth.
    const before = await Kalaam.findOneAndUpdate(
      { _id: req.params.id, readers: { $ne: userId } },
      { $addToSet: { readers: userId }, $inc: { reads: 1 } },
      { new: true, select: 'reads' },
    );

    if (before) {
      // First-time view for this user — broadcast the new count to anyone
      // watching the detail screen.
      emitKalaamEngagement(req, before._id, { reads: before.reads });
      return res.json({ reads: before.reads });
    }

    // Either the kalaam doesn't exist or the user has already viewed it.
    const existing = await Kalaam.findById(req.params.id).select('reads');
    if (!existing) return res.status(404).json({ message: 'Not found' });
    return res.json({ reads: existing.reads || 0 });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/kalaams/:id/visibility — toggle public/private (owner only)
router.patch('/:id/visibility', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) return res.status(403).json({ message: 'Forbidden' });
    kalaam.isPublic = !kalaam.isPublic;
    await kalaam.save();
    await kalaam.populate('author', 'name avatar');
    const savedSet = await loadSavedSet(req.user.id);
    res.json(fmt(kalaam, req.user.id, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/kalaams/mine — current user's kalaams (public + private)
router.get('/mine', auth, async (req, res) => {
  try {
    const [kalaams, savedSet] = await Promise.all([
      Kalaam.find({ author: req.user.id })
        .populate('author', 'name avatar')
        .sort({ createdAt: -1 }),
      loadSavedSet(req.user.id),
    ]);

    res.json(fmtMany(kalaams, req.user.id, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/kalaams/:id
router.get('/:id', async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id).populate('author', 'name avatar');
    if (!kalaam) return res.status(404).json({ message: 'Kalaam not found' });

    const userId = tryAuth(req);

    if (!kalaam.isPublic) {
      if (!userId || kalaam.author._id.toString() !== userId) {
        return res.status(403).json({ message: 'Private kalaam' });
      }
    }

    const savedSet = await loadSavedSet(userId);
    res.json(fmt(kalaam, userId, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams — create
router.post('/', auth, async (req, res) => {
  try {
    const { title, content, category, isPublic, poet, tags } = req.body;
    const kalaam = await Kalaam.create({
      title,
      content,
      category,
      isPublic: isPublic !== undefined ? isPublic : true,
      poet,
      tags: Array.isArray(tags) ? tags : [],
      author: req.user.id,
    });
    await kalaam.populate('author', 'name avatar');
    // A freshly created kalaam can't be in anyone's saved list yet, so an
    // empty savedSet is correct (and skips the User lookup).
    res.status(201).json(fmt(kalaam, req.user.id, new Set()));
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT /api/kalaams/:id — update (owner only)
router.put('/:id', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) return res.status(403).json({ message: 'Forbidden' });

    const { title, content, category, isPublic, poet, tags } = req.body;
    Object.assign(kalaam, { title, content, category, isPublic, poet, tags: Array.isArray(tags) ? tags : kalaam.tags });
    await kalaam.save();
    await kalaam.populate('author', 'name avatar');
    const savedSet = await loadSavedSet(req.user.id);
    res.json(fmt(kalaam, req.user.id, savedSet));
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE /api/kalaams/:id — delete (owner only)
router.delete('/:id', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) return res.status(403).json({ message: 'Forbidden' });

    // The reference media (if any) lives in Supabase Storage; the client
    // is responsible for deleting the corresponding object before/after
    // this call. We just clear the DB pointer.
    await kalaam.deleteOne();
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/reference/presign — issue a short-lived signed URL
// the client can PUT the reference file bytes to directly on R2. R2 keys
// stay on the server.
//
// JSON body:
//   extension — file extension without leading dot ('m4a', 'mp4', etc.)
//
// Owner only. Returns `{ uploadUrl, publicUrl, key, contentType, expiresInSec }`.
// The client must PUT with `Content-Type: <contentType>` exactly, otherwise
// S3 rejects the signature.
router.post('/:id/reference/presign', auth, async (req, res) => {
  try {
    const { extension } = req.body || {};
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden' });
    }
    const presign = await r2.presignReferenceUpload({
      kalaamId: req.params.id,
      extension,
    });
    res.json(presign);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/reference — record a follow-voice reference URL.
// The client uploads the file to R2 (via the presigned URL from the
// `/presign` endpoint) first, then calls this endpoint with the resulting
// public URL.
//
// JSON body:
//   url         — R2 public URL (required, must match R2_PUBLIC_BASE_URL host)
//   sourceType  — 'audio_file' | 'video_file' | 'youtube'
//   sourceUrl?  — original YouTube URL, when sourceType=='youtube'
//   durationMs? — client-measured duration in ms
//   extension?  — file extension without leading dot (e.g. 'm4a')
//
// Owner only. Returns the updated kalaam with `referenceAudio.url`.
router.post('/:id/reference', auth, async (req, res) => {
  try {
    const { url, sourceType, sourceUrl, durationMs, extension } = req.body || {};
    if (!isValidReferenceUrl(url)) {
      return res
        .status(400)
        .json({ message: 'Invalid reference URL — must be on the configured R2 public host' });
    }

    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const safeSourceType = ['audio_file', 'video_file', 'youtube'].includes(sourceType)
      ? sourceType
      : 'audio_file';
    const safeDuration = Number.isFinite(parseInt(durationMs, 10))
      ? Math.max(0, parseInt(durationMs, 10))
      : 0;
    let safeExt = String(extension || '').toLowerCase().replace(/^\./, '');
    if (!ALLOWED_REF_EXTS.has(safeExt)) safeExt = 'm4a';

    kalaam.referenceAudio = {
      url,
      sourceType: safeSourceType,
      sourceUrl: sourceUrl || null,
      durationMs: safeDuration,
      extension: safeExt,
      uploadedAt: new Date(),
    };
    await kalaam.save();
    await kalaam.populate('author', 'name avatar');

    const savedSet = await loadSavedSet(req.user.id);
    res.json(fmt(kalaam, req.user.id, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/kalaams/:id/reference — clear the follow-voice reference pointer
// and delete the corresponding R2 object best-effort. R2 cleanup failures
// don't fail the request — the DB pointer is the source of truth, an
// orphaned object is a minor cost issue, not a correctness one.
router.delete('/:id/reference', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden' });
    }
    const previousUrl = kalaam.referenceAudio && kalaam.referenceAudio.url;
    kalaam.referenceAudio = null;
    await kalaam.save();
    if (previousUrl) {
      r2.deleteByPublicUrl(previousUrl).catch((err) => {
        console.warn('[r2] delete failed for', previousUrl, err.message);
      });
    }
    await kalaam.populate('author', 'name avatar');
    const savedSet = await loadSavedSet(req.user.id);
    res.json(fmt(kalaam, req.user.id, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
