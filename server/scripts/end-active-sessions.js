// One-off: force-end every active session. Used to clear stuck sessions
// when the UI can't reach the end endpoint. Safe to delete after running.
require('dotenv').config();
const mongoose = require('mongoose');
const Session = require('../model/Session');

(async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const active = await Session.find({ isActive: true }, '_id groupId hostId').lean();
    console.log(`Found ${active.length} active session(s):`);
    active.forEach((s) => console.log(`  - ${s._id} (group ${s.groupId})`));
    if (active.length === 0) {
      console.log('Nothing to do.');
    } else {
      const res = await Session.updateMany(
        { isActive: true },
        { $set: { isActive: false } }
      );
      console.log(`Set isActive=false on ${res.modifiedCount} session(s).`);
    }
  } catch (err) {
    console.error('Error:', err.message);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
})();
