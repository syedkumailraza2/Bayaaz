const User = require('../model/User');

// True when the given user id belongs to an admin. Reads the database rather
// than trusting a claim in the JWT, so revoking a role takes effect
// immediately instead of when the 30-day token expires.
async function isAdmin(userId) {
  if (!userId) return false;
  const u = await User.findById(userId).select('role').lean();
  return !!u && u.role === 'admin';
}

// Express middleware. Must run AFTER `auth` (needs req.user).
async function requireAdmin(req, res, next) {
  try {
    if (!(await isAdmin(req.user?.id))) {
      return res.status(403).json({ message: 'Admin access required' });
    }
    req.isAdmin = true;
    next();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = requireAdmin;
module.exports.isAdmin = isAdmin;
