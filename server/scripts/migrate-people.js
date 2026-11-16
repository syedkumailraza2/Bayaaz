// One-time: turn each kalaam's free-text `poet` into `shayars` entries in the
// People table. Safe to re-run (skips kalaams that already have shayars).
//   node scripts/migrate-people.js            # dry run
//   node scripts/migrate-people.js --apply
require('dotenv').config({ quiet: true });
const mongoose = require('mongoose');
const Kalaam = require('../model/Kalaam');
const Person = require('../model/Person');

(async () => {
  const apply = process.argv.includes('--apply');
  await mongoose.connect(process.env.MONGO_URI);
  try {
    const todo = await Kalaam.find({
      poet: { $exists: true, $ne: '' },
      $or: [{ shayars: { $exists: false } }, { shayars: { $size: 0 } }],
    }).select('title poet shayars');
    console.log(`${todo.length} kalaam(s) to migrate${apply ? '' : ' (dry run)'}`);
    for (const k of todo) {
      const names = k.poet.split(',').map((n) => Person.cleanName(n)).filter(Boolean);
      console.log(`- ${k.title}: ${names.join(' | ')}`);
      if (!apply) continue;
      k.shayars = await Person.refsFromNames(names, { create: true });
      await k.save();
    }
    if (!apply) console.log('Re-run with --apply to write.');
  } finally {
    await mongoose.disconnect();
  }
})().catch((err) => { console.error(err); process.exit(1); });
