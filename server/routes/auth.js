const express = require('express');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const User = require('../model/User');
const auth = require('../middleware/auth');

const router = express.Router();

// Verifies Google ID tokens. The token's `aud` must equal our Web client ID.
const googleClient = new OAuth2Client();

const signToken = (user) =>
  jwt.sign({ id: user._id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '30d' });

const userPayload = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  avatar: user.avatar || null,
});

// Light-weight URL validation. We don't want to be strict (lots of valid
// CDN/CORS-friendly hosts), but we should reject obvious garbage so the
// client doesn't render broken images everywhere.
const isLikelyUrl = (s) =>
  typeof s === 'string' &&
  s.length <= 2048 &&
  /^https?:\/\/\S+$/i.test(s.trim());

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { name, email, password, avatar } = req.body;
  if (!name || !email || !password)
    return res.status(400).json({ message: 'Name, email and password are required' });
  if (password.length < 6)
    return res.status(400).json({ message: 'Password must be at least 6 characters' });

  try {
    const exists = await User.findOne({ email });
    if (exists) return res.status(409).json({ message: 'Email already registered' });

    const cleanAvatar = avatar && isLikelyUrl(avatar) ? avatar.trim() : null;
    const user = await User.create({ name, email, password, avatar: cleanAvatar });
    res.status(201).json({ token: signToken(user), user: userPayload(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  console.log('Login Attempt!!!');
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ message: 'Email and password are required' });

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid email or password' });

    const match = await user.comparePassword(password);
    if (!match) return res.status(401).json({ message: 'Invalid email or password' });
    console.log('Login Successful!!!');

    res.json({ token: signToken(user), user: userPayload(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/auth/google — native Google Sign-In.
// The client (google_sign_in) obtains a Google ID token and posts it here.
// We verify it, then find-or-create the user and issue our own JWT — so the
// rest of the app's auth (Bearer token, /me, etc.) works unchanged.
router.post('/google', async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) return res.status(400).json({ message: 'idToken required' });
  if (!process.env.GOOGLE_WEB_CLIENT_ID)
    return res.status(500).json({ message: 'GOOGLE_WEB_CLIENT_ID not configured' });

  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_WEB_CLIENT_ID,
    });
    const { sub: googleId, email, name, picture, email_verified } = ticket.getPayload();
    if (!email || email_verified === false)
      return res.status(401).json({ message: 'Google account email not verified' });

    let user = await User.findOne({ $or: [{ googleId }, { email }] });
    if (!user) {
      user = await User.create({
        googleId,
        email,
        name: name || email.split('@')[0],
        avatar: picture || null,
        authProvider: 'google',
      });
    } else if (!user.googleId) {
      // Existing email/password account — link Google to it.
      user.googleId = googleId;
      if (!user.avatar && picture) user.avatar = picture;
      await user.save();
    }

    res.json({ token: signToken(user), user: userPayload(user) });
  } catch (err) {
    console.error('[auth/google] failed:', err.message);
    res.status(401).json({ message: 'Google sign-in failed' });
  }
});

// GET /api/auth/me — current profile (handy for refresh after avatar edits)
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({ user: userPayload(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/auth/me — update name and/or avatar URL. Pass `avatar: null` to
// clear the avatar (we'll fall back to the initial-letter circle on the UI).
router.patch('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (typeof req.body.name === 'string') {
      const next = req.body.name.trim();
      if (!next) return res.status(400).json({ message: 'Name cannot be empty' });
      user.name = next;
    }
    if (Object.prototype.hasOwnProperty.call(req.body, 'avatar')) {
      const v = req.body.avatar;
      if (v === null || v === '') {
        user.avatar = null;
      } else if (isLikelyUrl(v)) {
        user.avatar = v.trim();
      } else {
        return res.status(400).json({ message: 'Avatar must be a valid http(s) URL' });
      }
    }

    await user.save();
    res.json({ user: userPayload(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
