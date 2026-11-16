const mongoose = require('mongoose');

// A shayar (poet) or nauha khwan (reciter). One shared table so the same
// person can be both, and so admins pick existing names instead of typing
// variants ("Nadeem Sarwar" vs "nadeem sarwar").
//
// Kalaams embed { person, name, slug } (see Kalaam.personRefSchema) so feeds
// and the website don't need a join; renaming a person updates those copies.

const personSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  // Case/space-insensitive identity: "  Nadeem   SARWAR " → "nadeem sarwar".
  nameKey: { type: String, required: true, unique: true },
  // URL segment for /<category>/<slug> pages on the website.
  slug: { type: String, required: true, unique: true },
}, { timestamps: true });

function cleanName(name) {
  return String(name || '').replace(/\s+/g, ' ').trim();
}

function keyOf(name) {
  return cleanName(name).toLowerCase();
}

function slugify(name) {
  return cleanName(name)
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
}

personSchema.statics.cleanName = cleanName;
personSchema.statics.keyOf = keyOf;

/** Find a person by name (case-insensitive), or create one if `create`. */
personSchema.statics.resolve = async function (rawName, { create = false } = {}) {
  const name = cleanName(rawName);
  if (!name) return null;
  const nameKey = keyOf(name);
  const existing = await this.findOne({ nameKey });
  if (existing || !create) return existing;

  // Urdu-script names slugify to '' — fall back to a short random id.
  const base = slugify(name) || `person-${new mongoose.Types.ObjectId().toString().slice(-6)}`;
  let slug = base;
  for (let n = 2; await this.exists({ slug }); n += 1) slug = `${base}-${n}`;
  try {
    return await this.create({ name, nameKey, slug });
  } catch (err) {
    // Lost a race with a concurrent create of the same name.
    if (err.code === 11000) return this.findOne({ nameKey });
    throw err;
  }
};

/**
 * Names (array, or comma-separated string) → embedded refs for a kalaam,
 * de-duplicated and in the given order. Unknown names are skipped unless
 * `create` (admins only), so regular users can't add people.
 */
personSchema.statics.refsFromNames = async function (names, { create = false } = {}) {
  const list = (Array.isArray(names) ? names : String(names || '').split(','))
    .map((n) => (n && typeof n === 'object' ? n.name : n))
    .map(cleanName)
    .filter(Boolean);
  const seen = new Set();
  const refs = [];
  for (const name of list) {
    const key = keyOf(name);
    if (seen.has(key)) continue;
    seen.add(key);
    const person = await this.resolve(name, { create });
    if (person) refs.push({ person: person._id, name: person.name, slug: person.slug });
  }
  return refs;
};

personSchema.methods.toClient = function () {
  return { id: String(this._id), name: this.name, slug: this.slug };
};

module.exports = mongoose.model('Person', personSchema);
