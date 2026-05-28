const express = require('express');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const Kalaam = require('../model/Kalaam');
const User = require('../model/User');
const auth = require('../middleware/auth');

const router = express.Router();

// ─── Reference-audio upload storage ────────────────────────────────────────
// We persist reference recitations on the same disk the API runs on. Files
// are written to `<repo>/server/uploads/reference/<kalaamId>.<ext>` and
// served back via `app.use('/uploads', express.static(...))` (wired in
// index.js). The filename uses the kalaam id so a fresh upload overwrites
// the previous reference for that kalaam atomically.
const REFERENCE_DIR = path.join(__dirname, '..', 'uploads', 'reference');
fs.mkdirSync(REFERENCE_DIR, { recursive: true });

const ALLOWED_REF_EXTS = new Set([
  'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac',
  'mp4', 'mov', 'webm', 'mkv',
]);

const referenceStorage = multer.diskStorage({
  destination: (req, _file, cb) => cb(null, REFERENCE_DIR),
  filename: (req, file, cb) => {
    // Trust the picker-resolved extension from the client (sent as a form
    // field) over multer's MIME guess, because Android pickers regularly
    // ship audio with a generic `application/octet-stream` MIME.
    let ext = String(req.body.extension || '').toLowerCase().replace(/^\./, '');
    if (!ALLOWED_REF_EXTS.has(ext)) {
      ext = path.extname(file.originalname || '').replace('.', '').toLowerCase();
    }
    if (!ALLOWED_REF_EXTS.has(ext)) ext = 'm4a';
    cb(null, `${req.params.id}.${ext}`);
  },
});

const referenceUpload = multer({
  storage: referenceStorage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB hard cap
});

// Build the absolute URL the client should hit to fetch a reference file.
// Honour the proxy/Cloudflare host header (we set `trust proxy: true` in
// index.js) so the URL works in deployed environments.
const buildReferenceUrl = (req, filename) => {
  const base = `${req.protocol}://${req.get('host')}`;
  return `${base}/uploads/reference/${filename}`;
};

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

    // Remove the on-disk reference recitation, if any, so we don't leak
    // orphaned files into the uploads directory.
    if (kalaam.referenceAudio?.url) {
      const tail = kalaam.referenceAudio.url.split('/uploads/reference/')[1];
      if (tail) {
        const p = path.join(REFERENCE_DIR, tail);
        fs.promises.unlink(p).catch(() => {});
      }
    }
    await kalaam.deleteOne();
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/reference — upload a follow-voice reference file.
// Multipart fields:
//   audio       — the file blob (required)
//   sourceType  — 'audio_file' | 'video_file' | 'youtube'
//   sourceUrl?  — original YouTube URL, when sourceType=='youtube'
//   durationMs? — client-measured duration
//   extension?  — picker-resolved extension (no leading dot)
// Owner only. Returns the updated kalaam with `referenceAudio.url`.
router.post(
  '/:id/reference',
  auth,
  referenceUpload.single('audio'),
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: 'No audio uploaded' });
      const kalaam = await Kalaam.findById(req.params.id);
      if (!kalaam) {
        await fs.promises.unlink(req.file.path).catch(() => {});
        return res.status(404).json({ message: 'Not found' });
      }
      if (kalaam.author.toString() !== req.user.id) {
        await fs.promises.unlink(req.file.path).catch(() => {});
        return res.status(403).json({ message: 'Forbidden' });
      }

      // Replacing an existing reference: nuke the previous file on disk if
      // its filename differs (different extension produces a different
      // basename and our multer storage doesn't auto-clean it up).
      if (kalaam.referenceAudio?.url) {
        const oldTail = kalaam.referenceAudio.url.split('/uploads/reference/')[1];
        const newTail = path.basename(req.file.path);
        if (oldTail && oldTail !== newTail) {
          fs.promises.unlink(path.join(REFERENCE_DIR, oldTail)).catch(() => {});
        }
      }

      const filename = path.basename(req.file.path);
      const ext = path.extname(filename).replace('.', '');
      const sourceType = ['audio_file', 'video_file', 'youtube']
        .includes(req.body.sourceType)
        ? req.body.sourceType
        : 'audio_file';
      const durationMs = Number.isFinite(parseInt(req.body.durationMs, 10))
        ? Math.max(0, parseInt(req.body.durationMs, 10))
        : 0;

      kalaam.referenceAudio = {
        url: buildReferenceUrl(req, filename),
        sourceType,
        sourceUrl: req.body.sourceUrl || null,
        durationMs,
        extension: ext,
        uploadedAt: new Date(),
      };
      await kalaam.save();
      await kalaam.populate('author', 'name avatar');

      const savedSet = await loadSavedSet(req.user.id);
      res.json(fmt(kalaam, req.user.id, savedSet));
    } catch (err) {
      if (req.file?.path) {
        await fs.promises.unlink(req.file.path).catch(() => {});
      }
      res.status(500).json({ message: err.message });
    }
  },
);

// DELETE /api/kalaams/:id/reference — remove the follow-voice reference.
router.delete('/:id/reference', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden' });
    }
    if (kalaam.referenceAudio?.url) {
      const tail = kalaam.referenceAudio.url.split('/uploads/reference/')[1];
      if (tail) {
        fs.promises.unlink(path.join(REFERENCE_DIR, tail)).catch(() => {});
      }
    }
    kalaam.referenceAudio = null;
    await kalaam.save();
    await kalaam.populate('author', 'name avatar');
    const savedSet = await loadSavedSet(req.user.id);
    res.json(fmt(kalaam, req.user.id, savedSet));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
