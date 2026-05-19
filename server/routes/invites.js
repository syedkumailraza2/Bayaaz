const express = require('express');
const GroupInvite = require('../model/GroupInvite');
const Group = require('../model/Group');
const Session = require('../model/Session');
const auth = require('../middleware/auth');

const router = express.Router();

// POST /api/invites/:token/redeem — redeem an invite (auth required)
// permanent → add user to Group.members (idempotent), return { groupId, type: 'permanent' }
// guest     → return { groupId, activeSessionId, type: 'guest' }; do NOT add to group
router.post('/:token/redeem', auth, async (req, res) => {
  try {
    const invite = await GroupInvite.findOne({ token: req.params.token });
    if (!invite) return res.status(404).json({ message: 'Invite not found' });
    if (!invite.isUsable()) return res.status(410).json({ message: 'Invite expired or revoked' });

    const group = await Group.findById(invite.groupId);
    if (!group) return res.status(404).json({ message: 'Group no longer exists' });

    if (invite.type === 'permanent') {
      const already = group.members.some(m => m.toString() === req.user.id);
      if (!already) {
        group.members.push(req.user.id);
        group.roles.push({ userId: req.user.id, role: 'member' });
        await group.save();
      }
      if (!invite.usedBy.some(u => u.toString() === req.user.id)) {
        invite.usedBy.push(req.user.id);
        await invite.save();
      }
      return res.json({ type: 'permanent', groupId: group._id, groupName: group.name });
    }

    // guest
    const activeSession = await Session.findOne({ groupId: group._id, isActive: true });
    if (!invite.usedBy.some(u => u.toString() === req.user.id)) {
      invite.usedBy.push(req.user.id);
      await invite.save();
    }
    return res.json({
      type: 'guest',
      groupId: group._id,
      groupName: group.name,
      activeSessionId: activeSession ? activeSession._id : null,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/invites/:token — peek at an invite (used by share link landing screen)
router.get('/:token', auth, async (req, res) => {
  try {
    const invite = await GroupInvite.findOne({ token: req.params.token })
      .populate('groupId', 'name');
    if (!invite) return res.status(404).json({ message: 'Invite not found' });
    res.json({
      type: invite.type,
      groupId: invite.groupId ? invite.groupId._id : null,
      groupName: invite.groupId ? invite.groupId.name : null,
      expiresAt: invite.expiresAt,
      usable: invite.isUsable(),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
