const crypto = require('crypto');
const mongoose = require('mongoose');

// `permanent` invites add the redeemer to Group.members.
// `guest` invites only allow joining the currently-active session for
// the group; the redeemer is NOT added to the group.
const groupInviteSchema = new mongoose.Schema(
  {
    groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
    token: { type: String, required: true, unique: true, index: true },
    type: { type: String, enum: ['permanent', 'guest'], required: true },
    expiresAt: { type: Date, required: true, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    usedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    revoked: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// 16 url-safe bytes ≈ 22 chars; collision probability is negligible.
groupInviteSchema.statics.generateToken = function () {
  return crypto.randomBytes(16).toString('base64url');
};

groupInviteSchema.methods.isUsable = function () {
  if (this.revoked) return false;
  if (this.expiresAt && this.expiresAt < new Date()) return false;
  return true;
};

module.exports = mongoose.model('GroupInvite', groupInviteSchema);
