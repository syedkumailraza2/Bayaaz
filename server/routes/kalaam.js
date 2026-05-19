const express = require('express');
const jwt = require('jsonwebtoken');
const Kalaam = require('../model/Kalaam');
const User = require('../model/User');
const auth = require('../middleware/auth');

const router = express.Router();

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

const fmt = (doc, userId) => Kalaam.formatForClient(doc, userId);
const fmtMany = (docs, userId) => docs.map(d => fmt(d, userId));

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
    const [items, total] = await Promise.all([
      Kalaam.find(filter)
        .populate('author', 'name avatar')
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Kalaam.countDocuments(filter),
    ]);

    res.json({
      items: fmtMany(items, userId),
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
    res.json(fmtMany(saved, req.user.id));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/save — toggle save/unsave
router.post('/:id/save', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const kalaamId = req.params.id;
    const idx = user.savedKalaams.indexOf(kalaamId);
    let saved;
    if (idx === -1) {
      user.savedKalaams.push(kalaamId);
      saved = true;
    } else {
      user.savedKalaams.splice(idx, 1);
      saved = false;
    }
    await user.save();
    res.json({ saved, savedCount: user.savedKalaams.length });
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
    res.json({ liked, likesCount: kalaam.likes.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/kalaams/:id/view — increment read counter. No auth required so
// anonymous browsing still bumps the count; clients call this once per detail
// open so we don't double-count list scrolls.
router.post('/:id/view', async (req, res) => {
  try {
    const updated = await Kalaam.findByIdAndUpdate(
      req.params.id,
      { $inc: { reads: 1 } },
      { new: true, select: 'reads' },
    );
    if (!updated) return res.status(404).json({ message: 'Not found' });
    res.json({ reads: updated.reads });
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
    res.json(fmt(kalaam, req.user.id));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/kalaams/mine — current user's kalaams (public + private)
router.get('/mine', auth, async (req, res) => {
  try {
    const kalaams = await Kalaam.find({ author: req.user.id })
      .populate('author', 'name avatar')
      .sort({ createdAt: -1 });

    res.json(fmtMany(kalaams, req.user.id));
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

    res.json(fmt(kalaam, userId));
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
    res.status(201).json(fmt(kalaam, req.user.id));
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
    res.json(fmt(kalaam, req.user.id));
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

    await kalaam.deleteOne();
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
