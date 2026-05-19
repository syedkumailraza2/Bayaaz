const express = require('express');
const mongoose = require('mongoose');
const Group = require('../model/Group');
const Session = require('../model/Session');
const QueueSnapshot = require('../model/QueueSnapshot');
const GroupInvite = require('../model/GroupInvite');
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

// POST /api/groups/:id/sessions — start a new session for the group.
// Optional body: { loadFromSnapshotId } pre-populates queueItems from a past snapshot.
router.post('/:id/sessions', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });

    const existing = await Session.findOne({ groupId: req.params.id, isActive: true });
    if (existing) return res.status(400).json({ message: 'An active session already exists for this group' });

    let queueItems = [];
    const { loadFromSnapshotId, kalaamIds } = req.body || {};
    if (loadFromSnapshotId) {
      const snap = await QueueSnapshot.findById(loadFromSnapshotId);
      if (snap && snap.groupId.toString() === req.params.id) {
        queueItems = snap.items.map(kalaamId => ({
          kalaamId,
          addedBy: req.user.id,
          addedAt: new Date(),
          votes: [],
        }));
      }
    } else if (Array.isArray(kalaamIds) && kalaamIds.length > 0) {
      // Pre-populate the queue with the kalaams the host picked when starting.
      queueItems = kalaamIds.map(kalaamId => ({
        kalaamId,
        addedBy: req.user.id,
        addedAt: new Date(),
        votes: [],
      }));
    }

    // Seed the teleprompter on the first kalaam from the initial queue so
    // members joining immediately see content instead of a spinner.
    const firstKalaamId = queueItems.length > 0 ? queueItems[0].kalaamId : null;

    const session = await Session.create({
      groupId: req.params.id,
      hostId: req.user.id,
      isActive: true,
      queueItems,
      currentKalamId: firstKalaamId,
      currentStanza: 0,
      currentLine: 0,
    });
    res.status(201).json(session);
  } catch (err) {
    console.error('[startSession] error:', err);
    console.error('[startSession] stack:', err.stack);
    res.status(500).json({ message: err.message });
  }
});

// GET /api/groups/:id/queue-snapshots — list recent end-of-session snapshots
router.get('/:id/queue-snapshots', auth, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 10, 50);
    const snapshots = await QueueSnapshot.find({ groupId: req.params.id })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('items', 'title category author poet');
    res.json(snapshots);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

function isMember(group, userId) {
  return group.members.some(m => m.toString() === userId);
}

// POST /api/groups/:id/invites — create an invite link (any group member)
// Body: { type: 'permanent' | 'guest', ttlHours? }
router.post('/:id/invites', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Group not found' });
    if (!isMember(group, req.user.id)) return res.status(403).json({ message: 'Not a member' });

    const { type, ttlHours } = req.body || {};
    if (!['permanent', 'guest'].includes(type)) {
      return res.status(400).json({ message: 'type must be permanent or guest' });
    }

    const defaultTtl = type === 'guest' ? 24 : 24 * 7;
    const ttl = Number.isFinite(ttlHours) && ttlHours > 0 ? ttlHours : defaultTtl;
    const expiresAt = new Date(Date.now() + ttl * 60 * 60 * 1000);

    const token = GroupInvite.generateToken();
    const invite = await GroupInvite.create({
      groupId: req.params.id,
      token,
      type,
      expiresAt,
      createdBy: req.user.id,
    });

    // Build an https landing URL so the link is tappable in WhatsApp/etc.
    // The /i/:token route redirects to bayaaz://i/:token to open the app.
    const link = `${req.protocol}://${req.get('host')}/i/${invite.token}`;
    res.status(201).json({
      token: invite.token,
      type: invite.type,
      expiresAt: invite.expiresAt,
      link,
    });
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
