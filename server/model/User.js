const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  // Password is only required for local (email/password) accounts. Google
  // accounts authenticate via a verified Google ID token, so they have none.
  password: { type: String, required: function () { return this.authProvider === 'local'; } },
  // 'local' = email+password, 'google' = Google Sign-In.
  authProvider: { type: String, enum: ['local', 'google'], default: 'local' },
  // Google's stable user id (the `sub` claim). Sparse+unique so multiple
  // local users (no googleId) don't collide on null.
  googleId: { type: String, unique: true, sparse: true, default: undefined },
  // Public-readable URL for the user's avatar image. Optional; the client
  // falls back to a coloured circle with the first letter of the name.
  avatar: { type: String, trim: true, default: null },
  savedKalaams: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Kalaam' }],
}, { timestamps: true });

userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

userSchema.methods.comparePassword = function (plain) {
  return bcrypt.compare(plain, this.password);
};

module.exports = mongoose.model('User', userSchema);
