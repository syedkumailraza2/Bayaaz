// Grant (or revoke) admin rights for a user by email.
//   node scripts/make-admin.js someone@example.com          # grant
//   node scripts/make-admin.js someone@example.com --revoke # revoke
// The user must have signed up (email or Google) at least once.
require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../model/User');

(async () => {
  const email = (process.argv[2] || '').trim().toLowerCase();
  const revoke = process.argv.includes('--revoke');
  if (!email || !email.includes('@')) {
    console.error('Usage: node scripts/make-admin.js <email> [--revoke]');
    process.exit(1);
  }
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const user = await User.findOneAndUpdate(
      { email },
      { $set: { role: revoke ? 'user' : 'admin' } },
      { new: true }
    );
    if (!user) {
      console.error(`No user found with email ${email}. Sign up in the app first.`);
      process.exitCode = 1;
    } else {
      console.log(`${user.email} is now role=${user.role}.`);
    }
  } catch (err) {
    console.error('Error:', err.message);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
})();
