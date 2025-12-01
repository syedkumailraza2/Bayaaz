const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, 'Username is required'],
    unique: true,
    trim: true,
    minlength: [3, 'Username must be at least 3 characters'],
    maxlength: [30, 'Username cannot exceed 30 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters']
  },
  profile: {
    firstName: { type: String, trim: true },
    lastName: { type: String, trim: true },
    avatar: { type: String },
    bio: { type: String, maxlength: 500 }
  },
  preferences: {
    theme: { type: String, enum: ['light', 'dark', 'auto'], default: 'light' },
    fontSize: { type: Number, default: 16, min: 12, max: 24 },
    autoSync: { type: Boolean, default: true },
    notifications: { type: Boolean, default: true }
  },
  subscription: {
    type: { type: String, enum: ['free', 'premium'], default: 'free' },
    startDate: { type: Date },
    endDate: { type: Date }
  },
  stats: {
    totalLyrics: { type: Number, default: 0 },
    totalCategories: { type: Number, default: 0 },
    storageUsed: { type: Number, default: 0 }, // in bytes
    lastLogin: { type: Date }
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();

  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Update stats method
userSchema.methods.updateStats = async function() {
  const Lyric = mongoose.model('Lyric');
  const Category = mongoose.model('Category');

  const lyricCount = await Lyric.countDocuments({ userId: this._id });
  const categoryCount = await Category.countDocuments({ userId: this._id });

  this.stats.totalLyrics = lyricCount;
  this.stats.totalCategories = categoryCount;
  this.stats.lastLogin = new Date();

  return this.save();
};

// Hide password in JSON
userSchema.methods.toJSON = function() {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

module.exports = mongoose.model('User', userSchema);