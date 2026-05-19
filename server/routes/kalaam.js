const express = require('express');
const Kalaam = require('../model/Kalaam');
const User = require('../model/User');
const auth = require('../middleware/auth');

const router = express.Router();

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

    const [items, total] = await Promise.all([
      Kalaam.find(filter)
        .populate('author', 'name avatar')
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Kalaam.countDocuments(filter),
    ]);

    res.json({
      items,
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
    res.json(user.savedKalaams.filter(k => k && k.isPublic || k?.author?._id?.toString() === req.user.id));
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

// PATCH /api/kalaams/:id/visibility — toggle public/private (owner only)
router.patch('/:id/visibility', auth, async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id);
    if (!kalaam) return res.status(404).json({ message: 'Not found' });
    if (kalaam.author.toString() !== req.user.id) return res.status(403).json({ message: 'Forbidden' });
    kalaam.isPublic = !kalaam.isPublic;
    await kalaam.save();
    await kalaam.populate('author', 'name avatar');
    res.json(kalaam);
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

    res.json(kalaams);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/kalaams/:id
router.get('/:id', async (req, res) => {
  try {
    const kalaam = await Kalaam.findById(req.params.id).populate('author', 'name avatar');
    if (!kalaam) return res.status(404).json({ message: 'Kalaam not found' });

    // Block private kalaams from non-owners (simple check via optional auth header)
    if (!kalaam.isPublic) {
      const token = req.headers.authorization?.split(' ')[1];
      if (!token) return res.status(403).json({ message: 'Private kalaam' });
      const jwt = require('jsonwebtoken');
      let payload;
      try { payload = jwt.verify(token, process.env.JWT_SECRET); } catch { return res.status(403).json({ message: 'Private kalaam' }); }
      if (kalaam.author._id.toString() !== payload.id) return res.status(403).json({ message: 'Private kalaam' });
    }

    res.json(kalaam);
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
    res.status(201).json(kalaam);
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
    res.json(kalaam);
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
