const express = require('express');
const mongoose = require('mongoose');
const Group = require('../model/Group');
const Session = require('../model/Session');
const auth = require('../middleware/auth');

const router = express.Router();

function isAdmin(group, userId) {
  return group.roles.some(r => r.userId.toString() === userId && r.role === 'admin');
}

// POST /api/groups — create a new group
router.post('/', auth, async (req, res) => {
  try {
    const { name } = req.body;
    const group = await Group.create({
      name,
      createdBy: req.user.id,
      members: [req.user.id],
      roles: [{ userId: req.user.id, role: 'admin' }],
    });
    await group.populate('members', 'name avatar');
    res.status(201).json(group);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/groups — all groups where current user is a member
router.get('/', auth, async (req, res) => {
  try {
    const groups = await Group.find({ members: req.user.id })
      .populate('members', 'name avatar')
      .sort({ createdAt: -1 });
    res.json(groups);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/groups/:id — get group detail
router.get('/:id', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id).populate('members', 'name avatar');
    if (!group) return res.status(404).json({ message: 'Group not found' });
    const isMember = group.members.some(m => m._id.toString() === req.user.id);
    if (!isMember) return res.status(403).json({ message: 'Not a member of this group' });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/groups/:id/members — add a member (admin only)
router.post('/:id/members', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });
    if (!isAdmin(group, req.user.id)) return res.status(403).json({ message: 'Admin only' });

    const { userId } = req.body;
    const alreadyMember = group.members.some(m => m.toString() === userId);
    if (alreadyMember) return res.status(400).json({ message: 'User is already a member' });

    group.members.push(userId);
    group.roles.push({ userId, role: 'member' });
    await group.save();
    await group.populate('members', 'name avatar');
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/groups/:id/members/:uid — remove a member (admin only)
router.delete('/:id/members/:uid', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });
    if (!isAdmin(group, req.user.id)) return res.status(403).json({ message: 'Admin only' });

    const { uid } = req.params;
    if (group.createdBy.toString() === uid) {
      return res.status(400).json({ message: 'Cannot remove the group creator' });
    }

    group.members = group.members.filter(m => m.toString() !== uid);
    group.roles = group.roles.filter(r => r.userId.toString() !== uid);
    await group.save();
    await group.populate('members', 'name avatar');
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/groups/:id/sessions — start a new session for the group
router.post('/:id/sessions', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });

    const existing = await Session.findOne({ groupId: req.params.id, isActive: true });
    if (existing) return res.status(400).json({ message: 'An active session already exists for this group' });

    const session = await Session.create({
      groupId: req.params.id,
      hostId: req.user.id,
      isActive: true,
    });
    res.status(201).json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/groups/:id/sessions/active — get the active session for a group
router.get('/:id/sessions/active', auth, async (req, res) => {
  try {
    const session = await Session.findOne({ groupId: req.params.id, isActive: true })
      .populate('currentKalamId', 'title category')
      .populate('queue', 'title category author');
    if (!session) return res.status(404).json({ message: 'No active session found' });
    res.json(session);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
