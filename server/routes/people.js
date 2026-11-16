const express = require('express');
const Person = require('../model/Person');
const Kalaam = require('../model/Kalaam');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// GET /api/people?q=nad&limit=10 — autocomplete for the admin editor.
// Names starting with the query rank first, then names containing it.
router.get('/', async (req, res) => {
  try {
    const q = Person.keyOf(req.query.q || '');
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 10));
    let people;
    if (!q) {
      people = await Person.find().sort({ nameKey: 1 }).limit(limit);
    } else {
      const prefix = await Person.find({ nameKey: new RegExp(`^${escapeRegex(q)}`) })
        .sort({ nameKey: 1 }).limit(limit);
      const rest = prefix.length < limit
        ? await Person.find({
          nameKey: new RegExp(escapeRegex(q)),
          _id: { $nin: prefix.map((p) => p._id) },
        }).sort({ nameKey: 1 }).limit(limit - prefix.length)
        : [];
      people = [...prefix, ...rest];
    }
    res.json(people.map((p) => p.toClient()));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/people { name } — add a person (admin). Returns the existing
// person if the name is already there (case-insensitive), with created=false.
router.post('/', auth, requireAdmin, async (req, res) => {
  try {
    const name = Person.cleanName(req.body && req.body.name);
    if (!name) return res.status(400).json({ message: 'Name is required' });
    if (name.length > 80) return res.status(400).json({ message: 'Name is too long' });
    const existing = await Person.resolve(name);
    const person = existing || (await Person.resolve(name, { create: true }));
    res.status(existing ? 200 : 201).json({ ...person.toClient(), created: !existing });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/people/:id { name } — fix a spelling (admin). Keeps the slug so
// existing links keep working, and updates the copies embedded in kalaams.
router.patch('/:id', auth, requireAdmin, async (req, res) => {
  try {
    const name = Person.cleanName(req.body && req.body.name);
    if (!name) return res.status(400).json({ message: 'Name is required' });
    const person = await Person.findById(req.params.id);
    if (!person) return res.status(404).json({ message: 'Not found' });
    const clash = await Person.findOne({ nameKey: Person.keyOf(name), _id: { $ne: person._id } });
    if (clash) return res.status(409).json({ message: `"${clash.name}" already exists` });

    person.name = name;
    person.nameKey = Person.keyOf(name);
    await person.save();
    for (const field of ['shayars', 'reciters']) {
      await Kalaam.updateMany(
        { [`${field}.person`]: person._id },
        { $set: { [`${field}.$[p].name`]: name } },
        { arrayFilters: [{ 'p.person': person._id }] },
      );
    }
    // Keep the legacy poet string in step for kalaams this person wrote.
    const written = await Kalaam.find({ 'shayars.person': person._id }).select('shayars poet');
    for (const k of written) {
      k.poet = k.shayars.map((p) => p.name).join(', ');
      await k.save();
    }
    res.json(person.toClient());
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
